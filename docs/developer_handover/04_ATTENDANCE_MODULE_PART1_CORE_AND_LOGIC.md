# Chapter 04: Attendance Management (Part 1: Core Grid & Business Logic)

This document provides a comprehensive technical breakdown of the core attendance matrix engine in [Attendance.aspx](file:///e:/attendence/Attendance.aspx) and [Attendance.aspx.cs](file:///e:/attendence/Attendance.aspx.cs).

---

## 1. Attendance Matrix Architecture

The Attendance module renders an interactive monthly grid matrix of contract employees versus days of the month (Days `1` through `28`/`29`/`30`/`31`).

```
+-------------------------------------------------------------------------------------------------------------------+
| FILTERS: Year [2026] | Month [May] | Category [Skilled DEO] | Division [D-ADMIN] | Search [Emp Name / ID]         |
+-------------------------------------------------------------------------------------------------------------------+
| Employee ID | Name         | Category | Div   | 01 | 02 | 03 | 04 | 05 | ... | 31 | Pres | Leaves | Abs | Days |
+-------------+--------------+----------+-------+----+----+----+----+----+-----+----+------+--------+-----+------+
| 1042        | John Doe     | Skilled  | D-ADM | P  | P  | P  | S  | H  | ... | P  | 22.0 |  2.0   | 0.0 | 26.0 |
| 1043        | Jane Smith   | Semi-Sk  | D-ADM | P  | P  | A  | S  | H  | ... | P  | 20.0 |  1.0   | 2.0 | 24.0 |
| GLOBAL      | System Hol.  | All      | Global| -  | -  | -  | -  | H  | ... | -  |  -   |   -    |  -  |  -   |
+-------------------------------------------------------------------------------------------------------------------+
```

---

## 2. Attendance Status Codes & Semantic Values

Every cell in `Attendance` or `AttendanceDraft` stores status using standardized values:

| Status Code (`StatusValue`) | Flag (`IsHoliday`) | Flag (`AutoSat`) | Leave String (`LeaveType`) | Grid Symbol | Semantic Meaning & Calculation Rule |
| :---: | :---: | :---: | :---: | :---: | :--- |
| `1.0` | `0` | `0` | `""` | `P` (Green) | **Present:** Employee attended duty for a full working shift. Contributes `+1.0` to Present Days. |
| `0.0` / `0` | `0` | `0` | `""` | `A` (Red) | **Absent:** Employee was absent from work without authorized paid leave. Contributes `+1.0` to Absent Days. |
| `2.0` | `0` | `0` | `"CL"` / `"EL"` | `L` (Yellow) | **Paid Leave:** Authorized leave deducted from employee's `LeaveBalance`. Contributes `+1.0` to Paid Leaves and is fully billable. |
| `3.0` | `0` | `0` | `"LWP"` | `UL` (Orange) | **Unpaid Leave (Leave Without Pay):** Authorized absence without pay. Not billable. |
| `NULL` | `1` | `0` | `""` | `H` (Blue) | **Declared Public Holiday:** Official national/gazetted holiday. Does not penalize attendance. |
| `NULL` | `0` | `1` | `""` | `S` (Purple) | **Auto-Saturday Absence:** Saturday automatically counted as absent under the 2-Saturday rule. |
| `0.5` | `0` | `0` | `"Carried"` / `"Pending"` | `½` (Cyan) | **Half-Day / Paired Leave:** Staged half-day absence waiting to be paired with another half-day. |

---

## 3. Core Business Rules & Attendance Math

### 3.1 Automatic Saturday Rule (2-Saturday Rule)
The establishment operates on an alternating Saturday schedule:
1. Employees are entitled to alternate Saturdays off if they have fulfilled minimum attendance on surrounding working days.
2. If an employee is absent on both Friday and Monday flanking an off-Saturday (the **Sandwich Rule**), the intervening Saturday is converted into an absent day (`AutoSat = 1`).
3. To compute Saturday eligibility correctly across month boundaries, `GetData` automatically queries trailing attendance from the previous month (`Day >= 24`):
   ```sql
   SELECT EmpID, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks 
   FROM Attendance 
   WHERE Year = :PYear AND Month = :PMonth AND Day >= 24
   ```

---

### 3.2 Global Holiday Declaration & Stint Propagation
When an administrator clicks the calendar header to declare an organization-wide holiday:
1. An entry is created for the system employee record `GLOBAL` (or tier-specific `GLOBAL_{TierId}`):
   ```sql
   INSERT INTO Attendance (EmpID, Year, Month, Day, StatusValue, IsHoliday, Remarks)
   VALUES ('GLOBAL', 2026, 4, 1, NULL, 1, 'May Day')
   ```
2. `DBHelper.BackfillHolidaysForAllEmployees` runs, checking each active employee's `EmployeeEngagements` dates (`StartDate <= TargetDate <= EndDate`).
3. Any employee whose stint covers that date automatically inherits the holiday, guaranteeing that working day formulas across payroll modules reflect the declared holiday.

---

### 3.3 Leave Accrual & Balance Deduction Engine
1. **Accrual Ledger (`EmployeeLeaveCredits`):** Leaves are not stored merely as static counters; they are credited via date-stamped transactions in `EmployeeLeaveCredits`.
2. **Dynamic Balance Resolution in `GetData`:**
   When loading attendance for month `M`, the system calculates available leave balance dynamically:
   $$\text{Resolved Balance} = \sum (\text{Credits with EffectiveDate} \le \text{Month End}) - \sum (\text{Paid Leaves consumed before Month Start})$$
3. **Carry-over Across Contract Periods:** When a new contract period commences, unused balances from the preceding stint are recorded in `Employees.PrevLeaveBalance` and `EmployeeEngagements.IsCarriedOver = 1`.

---

## 4. Server-Side Data Assembly (`GetData` Breakdown)

The AJAX method `GetData(int year, int month, string category, string division, string search)` in `Attendance.aspx.cs` constructs the complete dataset for the frontend in a single optimized payload:

```
[Client calls GetData via AJAX]
                 |
                 v
1. EnsureGlobalEmployeesExist()
                 |
2. Enforce POC View Restriction (PocViewRestrictionInfo)
   - If month is blocked by Cutoff Date / N-Months Rule -> Return Early Restricted Payload
                 |
3. Query Active Employees Matching Tier, Division & Search Scope
   - Early Exit Optimization: If 0 employees match, return empty payload immediately
                 |
4. Batch Query All Engagements for Matched Employees (Single SQL query)
                 |
5. Batch Query Historical Leaves & EmployeeLeaveCredits
                 |
6. Query Live Attendance Matrix for Year + Month
                 |
7. Overlay Declared Global Holidays
                 |
8. Overlay Staged Drafts from AttendanceDraft (Sub-user drafts)
                 |
9. Fetch Trailing Previous Month Data (Day >= 24) for Saturday calculations
                 |
10. Serialize to JSON and Return to Client Browser
```

### JSON Response Schema
```json
{
  "Employees": [
    {
      "MasterId": "EMP_1042",
      "ID": "1042",
      "Name": "John Doe",
      "Department": "D-ADMIN",
      "TierId": 1,
      "Category": "HR > Skilled (#DEO)",
      "JoinDate": "2025-01-01",
      "LeaveBalance": 12.0,
      "PrevLeaveBalance": 0.0
    }
  ],
  "Attendance": {
    "EMP_1042": {
      "1": { "Val": 1.0, "Holiday": false, "Leave": "", "AutoSat": false, "Remarks": "" },
      "2": { "Val": 1.0, "Holiday": false, "Leave": "", "AutoSat": false, "Remarks": "" }
    }
  },
  "EditDaysAllowed": 3,
  "EditMode": 1,
  "IsRestricted": false
}
```
