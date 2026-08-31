# Chapter 05: Attendance Management (Part 2: Sub-User Drafts, Edit Policies & Auditing)

This document covers the advanced workflows of the Attendance module: the staged sub-user draft pipeline, edit/view restriction policies, right-click cell edit remarks, audit history tracking, and reporting.

---

## 1. Staged Sub-User Draft Pipeline

To maintain data integrity and prevent unauthorized direct modifications to live production attendance, AMS implements a **Two-Tier Staging Workflow**:

```
+-----------------------------------------------------------------------------------+
|                            SUB USER (Data Entry Clerk)                             |
|  1. Keys in daily attendance on Attendance.aspx (RoleMode = "SubUser")            |
|  2. Calls SaveDraftAttendance(...)                                                |
|  3. Writes/Merges into AttendanceDraft table (EnteredByPCNO, EnteredAt)          |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                        STAGING TABLE: AttendanceDraft                             |
|  Stores provisional attendance records: StatusValue, LeaveType, EnteredBy, etc.   |
|  Live Attendance table remains UNMODIFIED                                         |
+-----------------------------------------+-----------------------------------------+
                                          |
                        [Site.Master alerts Anchor POC]
                        (Pending Drafts Badge Indicator)
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                          ANCHOR POC (Point of Contact)                            |
|  1. Reviews provisional cells (rendered with amber draft indicator badge)         |
|  2. Modifies cell values or remarks if needed (LastEditedByPCNO, LastEditedAt)    |
|  3. Clicks "Commit / Submit Drafts" or "Reject Drafts"                            |
+--------------------+------------------------------------+-------------------------+
                     |                                    |
            [If Approved & Committed]             [If Rejected / Cleared]
                     |                                    |
                     v                                    v
+---------------------------------------+  +----------------------------------------+
|      Live Table: Attendance           |  |        Purge from AttendanceDraft      |
|  1. Inserts/Updates live Attendance   |  |  Deleted from AttendanceDraft table    |
|  2. Purges records from Draft table   |  |  No changes pushed to live table       |
|  3. Inserts into Attendance_Audit_Log |  +----------------------------------------+
+---------------------------------------+
```

### 1.1 Draft Database Merge Statement
When a Sub User saves drafts, `Attendance.aspx.cs` executes an atomic Oracle `MERGE`:
```sql
MERGE INTO AttendanceDraft t
USING (
    SELECT :EmpID as EmpID, :Year as Year, :Month as Month, :Day as Day,
           :Val as StatusValue, :Holiday as IsHoliday, :Leave as LeaveType,
           :AutoSat as AutoSat, :Remarks as Remarks,
           :PCNO as PCNO, SYSTIMESTAMP as TS
    FROM DUAL
) s
ON (t.EmpID = s.EmpID AND t.Year = s.Year AND t.Month = s.Month AND t.Day = s.Day)
WHEN MATCHED THEN
  UPDATE SET t.StatusValue = s.StatusValue, t.IsHoliday = s.IsHoliday, t.LeaveType = s.LeaveType,
             t.AutoSat = s.AutoSat, t.Remarks = s.Remarks,
             t.LastEditedByPCNO = s.PCNO, t.LastEditedAt = s.TS
WHEN NOT MATCHED THEN
  INSERT (EmpID, Year, Month, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks, EnteredByPCNO, EnteredAt, LastEditedByPCNO, LastEditedAt)
  VALUES (s.EmpID, s.Year, s.Month, s.Day, s.StatusValue, s.IsHoliday, s.LeaveType, s.AutoSat, s.Remarks, s.PCNO, s.TS, s.PCNO, s.TS);
```

---

## 2. Multi-Tier Edit Policies & Retrospective Rules

Administrators configure attendance edit windows in `MainCategory` and `Settings.aspx`. `Attendance.aspx.cs` rigorously enforces these rules during both cell click edits and batch saves:

```csharp
DateTime checkDate = new DateTime(year, month + 1, day);
DateTime today = DateTime.Today;

if (editMode == 1) // Mode 1: Strict Current Month Only
{
    if (checkDate > today || checkDate.Year != today.Year || checkDate.Month != today.Month)
        continue; // Block edit
}
else if (editMode == 2) // Mode 2: Grace Cutoff Day Rule (e.g. 3rd of next month)
{
    DateTime prevMonth = today.AddMonths(-1);
    bool isCurrentMonth = (checkDate.Year == today.Year && checkDate.Month == today.Month);
    int graceCutoffDay = editDaysAllowed > 0 ? editDaysAllowed : 3;
    bool isPrevMonthAllowed = (checkDate.Year == prevMonth.Year && checkDate.Month == prevMonth.Month && today.Day <= graceCutoffDay);

    if ((!isCurrentMonth && !isPrevMonthAllowed) || checkDate > today)
        continue; // Block edit
}
else // Mode 0: Retrospective Days Window
{
    DateTime minAllowedDate = today.AddDays(-editDaysAllowed);
    if (checkDate > today || checkDate < minAllowedDate)
        continue; // Block edit
}
```

### Policy Summary Table

| Mode Code | Policy Name | Rule Mechanics & Limitations |
| :---: | :--- | :--- |
| **`0`** | **Retrospective Days Window** | POC can only edit dates within the last `EditDaysAllowed` days (e.g. `3` days back from today). Cannot edit future dates. |
| **`1`** | **Strict Current Month** | POC can edit any day in the current calendar month up to today. All previous months are permanently locked. |
| **`2`** | **Grace Cutoff Day** | POC can edit the previous month only up to the `N`th day of the current month (e.g. up to the 3rd of May for April attendance). After the 3rd, April is locked. |

---

## 3. Right-Click Cell Edit Remarks (`AttPocEditRemarks`)

Whenever a POC or Sub User edits a cell outside normal real-time marking, the frontend triggers a modal requiring a mandatory **Justification Remark**.

- **Table:** `AttPocEditRemarks`
- **Fields Captured:** `EmpID`, `Year`, `Month`, `Day`, `RemarkType`, `Remark`, `CreatedBy` (PCNO), `CreatedByRole` (`'POC'` or `'SubUser'`), `CreatedAt`.
- **Display:** Cells with attached remarks render a small red corner triangle. Hovering or right-clicking displays the full chronological explanation thread.

---

## 4. Comprehensive Attendance Audit Trail (`Attendance_Audit_Log`)

Every single change to a production attendance cell (whether made via individual cell click, batch save, draft commit, or administrator override) is recorded in `Attendance_Audit_Log`.

### Log Schema & Trigger Mechanics
```sql
CREATE TABLE Attendance_Audit_Log (
    Id          NUMBER PRIMARY KEY,
    LogTime     TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    EmpID       VARCHAR2(50),
    Year        NUMBER(4),
    Month       NUMBER(2),
    Day         NUMBER(2),
    OldValue    NUMBER(1),
    NewValue    NUMBER(1),
    ChangedBy   VARCHAR2(100),
    Reason      VARCHAR2(500)
);
```

### Timeline Inspection (`GetAuditHistory`)
Frontend users can right-click any cell and select **View Audit History**. The server queries:
```sql
SELECT LogTime, OldValue, NewValue, ChangedBy, Reason 
FROM Attendance_Audit_Log 
WHERE EmpID = :EmpID AND Year = :Year AND Month = :Month AND Day = :Day 
ORDER BY LogTime DESC
```
This returns a chronological timeline showing who changed the status, the previous vs new value, and the timestamp.

---

## 5. Excel & Report Export Pipeline

`Attendance.aspx.cs` provides high-speed, server-side Excel export for monthly attendance sheets:
1. **Dynamic Grid Construction:** Iterates all filtered employees and day columns (1..31).
2. **Formula & Totals Inclusion:** Appends summary columns on the right:
   - Total Present Days ($\sum P$)
   - Total Paid Leaves ($\sum L$)
   - Total Unpaid Leaves / Absents ($\sum A + \sum UL$)
   - Final Billable Working Days
3. **MIME Response Streaming:** Sets `Content-Type: application/vnd.ms-excel` with `Content-Disposition: attachment; filename="Attendance_Report_{Category}_{Month}_{Year}.xls"`.
