# Chapter 06: Employee Lifecycle & Master Management Module

This document provides complete technical specifications for the Employee Master and Stint Engagement module ([Employee.aspx](file:///e:/attendence/Employee.aspx) / [Employee.aspx.cs](file:///e:/attendence/Employee.aspx.cs)).

---

## 1. Architectural Role & Access Control

The **Employee Management Module** governs the full lifecycle of contract personnel: initial registration, bulk onboarding, multi-stint engagement contracts, leave credit management, qualification tracking, contract extensions, resignations, rejoining, and reversible audit history.

### Access Restrictions
- **Authorized Roles:** Only **Super Administrators (Role 4)** and **Category Administrators (Role 1)** can access `Employee.aspx`.
- **Enforcement:** If a Regular User (POC) or Sub User attempts direct navigation to `Employee.aspx`, `Page_Load` rejects the request, terminates execution via `Response.End()`, and displays an *Access Denied* security warning card.

---

## 2. Relational Architecture & Engagement Stints

An employee's lifecycle is modeled across four interconnected tables:

```
+-----------------------------------------------------------------------------------+
|                                 Employees Table                                   |
|  - MasterId (Immutable PK: "EMP_1042")                                            |
|  - EmployeeHistoryId (Persistent UUID tracking employee across years/rejoins)      |
|  - CurrentEngagementId (Pointer to active EmployeeEngagements stint)               |
|  - Status: 'Active', 'Resigned', 'Relieved', 'System'                             |
|  - Qualifications, Total Experience, Phone, Email, Aadhar, Address                |
+--------------------+------------------------------------+-------------------------+
                     |                                    |
            (1 : N Engagements)                  (1 : N Leave Credits)
                     |                                    |
                     v                                    v
+---------------------------------------+  +----------------------------------------+
|       EmployeeEngagements Table       |  |      EmployeeLeaveCredits Table        |
|  - Id (PK)                            |  |  - Id (PK)                             |
|  - EmpID (FK -> Employees.MasterId)   |  |  - EmpID (FK -> Employees.MasterId)    |
|  - ContractPeriodId (FK)              |  |  - ContractPeriodId (FK)               |
|  - TierId (FK) & VendorId (FK)        |  |  - Amount (e.g. +2.5 days)             |
|  - StartDate & EndDate                |  |  - EffectiveDate (Date credit active)  |
|  - EndReason ('Contract Expired',etc) |  |  - Remarks ('Monthly Accrual', etc)    |
|  - PrevEngagementId (Chain pointer)   |  +----------------------------------------+
|  - IsCarriedOver (1 = Balance carried)|
+---------------------------------------+
```

---

## 3. Core Employee Lifecycle Operations

### 3.1 Single Employee Creation (`btnAdd_Click`)
1. **Input Capture:** Reads ID, Name, Division/Department, Tier (`ddlCat`), Join Date, Initial Leave Balance, Qualifications, Experience, Aadhar, and Contact info.
2. **Contract Period Binding:** Queries active `ContractPeriods` for the chosen Tier to resolve the active `ContractPeriodId` and awarded `VendorId`.
3. **Atomic Persistence:**
   - Generates unique `MasterId` and `EmployeeHistoryId`.
   - Inserts `Employees` record.
   - Inserts initial `EmployeeEngagements` record (`StartDate = JoinDate`, `EndDate = ContractPeriod.EndDate`).
   - Links `Employees.CurrentEngagementId = EmployeeEngagements.Id`.
4. **Audit Logging:** Captures post-state snapshot and logs action via `ActionLogger.LogAction("ADD", masterId, ...)`.

---

### 3.2 Bulk CSV/Excel Onboarding (`btnBulkImport_Click`)
1. **File Ingestion:** Accepts CSV or Excel files (`.csv`, `.xlsx`).
2. **Schema Parsing (`ParsedImportRow`):** Validates columns: `ID`, `Name`, `Department`, `JoinDate`, `LeaveBalance`, `Qualification`, `Experience`, `Phone`, `Email`, `Aadhar`, `Address`.
3. **Duplicate Detection:** Checks if `ID` or `MasterId` already exists. Existing employees are updated; new employees are inserted with fresh engagement stints.

---

### 3.3 Contract Extension & Renewal (`btnExtendContract_Click`)
When an employee's contract is renewed or extended:
1. `PreState` is captured via `ActionLogger.CaptureEmployeeState(masterId)`.
2. If the employee remains in the same Tier and Contract Period, `Employees.ContractEndDate` and `EmployeeEngagements.EndDate` are updated.
3. If a new GeM contract period has started:
   - The old engagement is closed (`EndDate = OldPeriodEndDate`, `EndReason = 'Period Renewal'`).
   - A new `EmployeeEngagements` record is created linking `PrevEngagementId = OldEngagement.Id`.
   - Remaining leave balance is carried over (`IsCarriedOver = 1`).
4. `PostState` is captured and logged (`ActionLogger.LogAction("EXTEND", ...)`).

---

### 3.4 Resignation & Relieving (`btnResign_Click`)
1. Captures `ResignDate` and Reason.
2. Updates `Employees.Status = 'Resigned'` and `Employees.ResignDate`.
3. Closes active `EmployeeEngagements` stint: `EndDate = ResignDate`, `EndReason = 'Resigned'`.

---

### 3.5 Rejoining a Relieved Employee (`btnRejoin_Click`)
When an ex-employee rejoins under a new contract:
1. Resolves historical record by matching `MasterId` or `Aadhar`.
2. Preserves original `EmployeeHistoryId` and `OriginalJoinDate`.
3. Sets `Employees.Status = 'Active'` and updates `JoinDate = NewRejoinDate`.
4. Spawns a new `EmployeeEngagements` row with `PrevEngagementId` pointing to their prior stint.

---

### 3.6 Bulk Leave Credit Ledger (`btnApplyBulkLeave_Click`)
Allows administrators to credit paid leaves (e.g. `+1.5` or `+2.5` days) across all employees in a Tier/Division:
1. Iterates all matching active employees.
2. Inserts transactions into `EmployeeLeaveCredits`:
   ```sql
   INSERT INTO EmployeeLeaveCredits (EmpID, ContractPeriodId, Amount, EffectiveDate, Remarks)
   VALUES (:EmpID, :ContractPeriodId, :Amount, :EffectiveDate, :Remarks)
   ```
3. Updates `Employees.LeaveBalance = LeaveBalance + :Amount`.

---

## 4. Undo Engine & State Rollback Integration

`Employee.aspx` features a **Reversible Audit Log Tab**. Administrators can view recent operations and click **Undo**:

```csharp
protected void rptActionLogs_ItemCommand(object source, RepeaterCommandEventArgs e)
{
    if (e.CommandName == "Undo")
    {
        int logId = Convert.ToInt32(e.CommandArgument);
        string errorMessage;
        if (ActionLogger.UndoAction(logId, out errorMessage))
        {
            ShowMessage("Action successfully undone and historical state restored.", true);
            BindGrid();
        }
        else
        {
            ShowMessage("Undo failed: " + errorMessage, false);
        }
    }
}
```

*Guarantees:* Safely checks foreign key dependencies (attendance, payroll overrides) before rolling back employee fields and engagement stints.
