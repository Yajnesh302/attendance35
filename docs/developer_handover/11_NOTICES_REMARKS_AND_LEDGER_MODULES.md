# Chapter 11: Communication, Notices, Remarks & Financial Ledger

This document details the communication circulars board ([Notices.aspx](file:///e:/attendence/Notices.aspx)), the attendance correction remark ticket system ([Remarks.aspx](file:///e:/attendence/Remarks.aspx) / [UserRemarks.aspx](file:///e:/attendence/UserRemarks.aspx)), and the vendor financial accounting register ([Ledger.aspx](file:///e:/attendence/Ledger.aspx)).

---

## 1. Circulars & Notice Board ([Notices.aspx](file:///e:/attendence/Notices.aspx))

The **Notice Board Module** enables administrators to distribute official policy circulars, statutory orders, and document attachments to regular users with guaranteed read tracking.

```
+-----------------------------------------------------------------------------------+
|  Notices Table                                                                    |
|  - Id (PK), Name (Subject), FilePath (PDF/Doc attachment), NoticeText (NCLOB)     |
|  - Category ('Statutory', 'General'), IsHidden (0/1), UploadDate, MainCategoryId  |
+-----------------------------------------+-----------------------------------------+
                                          |
                               (1 : N Read Receipts)
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|  NoticeReads Table                                                                |
|  - NoticeId (FK -> Notices.Id), PCNO (User ID), ReadAt (Timestamp)                |
+-----------------------------------------------------------------------------------+
```

### Key Capabilities:
1. **Targeted Scoping:** Notices can be posted globally (visible to all users) or scoped specifically to an owned `MainCategoryId`.
2. **Read Receipts Tracking:** When a user opens a circular, the system inserts a record into `NoticeReads(NoticeId, PCNO, ReadAt)`. Administrators can view who read each notice and at what timestamp.
3. **File Attachments:** Securely uploads PDF/Word attachments to server directories and delivers them via authenticated handlers.

---

## 2. Attendance Correction Request Workflow ([Remarks.aspx](file:///e:/attendence/Remarks.aspx) / [UserRemarks.aspx](file:///e:/attendence/UserRemarks.aspx))

When historical attendance dates are locked by edit window policies, Regular Users (POCs) submit formal **Attendance Remarks / Correction Requests** to administrators.

```
+-----------------------------------------------------------------------------------+
|                           REGULAR USER (POC)                                      |
|  1. Opens UserRemarks.aspx                                                        |
|  2. Selects Employee & Date Coordinate (EmpID, RemarkDate)                        |
|  3. Enters Justification Message ("Employee was on official duty at site")        |
|  4. Inserts into AttendanceRemarks (IsRead = 0)                                   |
+-----------------------------------------+-----------------------------------------+
                                          |
                        [Site.Master alerts Administrator]
                        (Unread Count Badge on Top Bell Icon)
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                         CATEGORY ADMINISTRATOR                                    |
|  1. Opens Remarks.aspx (Admin Inbox)                                              |
|  2. Reviews pending correction requests for their owned MainCategory              |
|  3. Opens Attendance.aspx to make the manual adjustment                           |
|  4. Clicks "Mark as Read / Resolved" (Updates AttendanceRemarks.IsRead = 1)       |
+-----------------------------------------------------------------------------------+
```

---

## 3. Financial Vendor Ledger ([Ledger.aspx](file:///e:/attendence/Ledger.aspx))

`Ledger.aspx` provides an accounting audit of billed invoices, statutory deductions, payments, and balance reconciliations across manpower agencies.

### Capabilities:
- Summarizes gross billed wages, EPF employer contributions, GST amounts, and agency service commissions per vendor and contract period.
- Tracks penalties, deduction adjustments, and net disbursement figures.
- Generates downloadable financial audit spreadsheets for internal finance reviews.
