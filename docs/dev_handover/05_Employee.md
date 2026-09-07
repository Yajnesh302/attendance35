# 05 — Employee.aspx + Employee.aspx.cs (The Employee Master)

**Files:**
- `Employee.aspx` — 238,625 bytes (HTML/CSS/JS markup)
- `Employee.aspx.cs` — 3,657 lines / 208,150 bytes (C# code-behind)

This is the **largest and most complex page** in the application.

---

## What Does This Page Do?

The Employee Master is the central HR record-keeping page. It allows admins to:
1. **Add** new employees (manually or by bulk CSV/Excel import)
2. **Edit** existing employee details (name, contact info, leave balance, etc.)
3. **Change an employee's status** — Resign or Transfer (directorate change)
4. **Track engagement history** — a full timeline of every contract period and directorate an employee has ever belonged to
5. **Apply bulk leave adjustments** — add or reset leave balances for entire groups of employees at once
6. **View/Edit individual leave credit entries** — the detailed breakdown of every leave credit transaction

> **Frontend Note:** The **Delete** button is intentionally **not shown** in the employee grid. There is also **no Upgrade/Downgrade option** in the status dropdown — only **Resign** and **Transfer** are exposed to the user. The C# code-behind still contains handlers for delete, upgrade, and downgrade (legacy code), but since the frontend controls that trigger them are removed/hidden, they cannot be invoked by regular use.

Only admins (role = 1 or role = 4) can access this page. Regular users (POC/Sub Users) are shown an "Access Denied" page.

---

## Inner Helper Class: `ParsedImportRow`

```csharp
private class ParsedImportRow
{
    public int RowNum { get; set; }
    public string Id { get; set; }
    public string Name { get; set; }
    public string Dept { get; set; }
    public string JoinDate { get; set; }
    public float Leave { get; set; }
    public string Qualification { get; set; }
    public float? Experience { get; set; }
    public string ExperienceIn { get; set; }
    public string Phone { get; set; }
    public string Email { get; set; }
    public string Aadhar { get; set; }
    public string Address { get; set; }
    public string RowCat { get; set; }
}
```

This is a simple data-transfer class used only within the bulk import process. After each row in the uploaded file is validated, its data is stored in one of these objects. Then the actual database inserts happen separately, in a second pass over the validated list. This two-pass design ensures that if **any** row fails validation, **no rows** are inserted — the user gets the error message and can fix their file before re-uploading.

`Experience` is `float?` (nullable float) — if the value is missing from the CSV it is stored as `null` rather than `0`, which are distinct values in the database (`NULL` vs `0`).

---

## Page_Load — Entry Point and Access Control

```csharp
protected void Page_Load(object sender, EventArgs e)
```

**Step 1: Authentication guard**
```csharp
if (!User.Identity.IsAuthenticated || Session["PCNO"] == null)
{
    System.Web.Security.FormsAuthentication.SignOut();
    Response.Redirect("Login.aspx");
    return;
}
```
If the user is not authenticated OR session has expired (PCNO is null), signs out and redirects. Signing out first clears the authentication cookie so the browser cannot silently re-authenticate.

**Step 2: Role enforcement**
```csharp
int role = Convert.ToInt32(Session["Role"] ?? 0);
if (role != 1 && role != 4)
{
    Response.Write("<!DOCTYPE html>...<h2>Access Denied</h2>...");
    Response.End();
    return;
}
```
If the role is not Admin (1) or Super Admin (4), the server writes a complete self-contained HTML "Access Denied" page directly into the response and terminates. This is different from a redirect — it sends a full page without returning a redirect status code. The HTML includes animated CSS (glassmorphism card, spinning icon) for a polished look even for the error page.

**Step 3: First-load initialization**
```csharp
if (!IsPostBack)
{
    PopulateDropdowns();
    BindResignedEmployees();
    PopulateDeleteEmployeeDropdown();
    BindGrid();
}
```
On the very first page load (not a postback from button clicks), four methods run to populate all the data the page needs. On postbacks (e.g. clicking "Add Employee"), `Page_Load` runs again but skips this block — each button's event handler re-calls specific methods as needed.

---

## `PopulateDropdowns()` — Fill All Dropdown Lists

```csharp
private void PopulateDropdowns()
```

Fills six dropdown lists from the database. All use the same two data sources: divisions and tiers.

**Divisions (from `DBHelper.GetCompanyDivisionsDataTable()`):**
- `ddlDept` — the Department/Division picker in the "Add/Edit Employee" form
- `ddlFilterDiv` — the division filter above the employee grid
- `ddlBulkLeaveDivision` — the division filter for bulk leave operations

**Tiers (from `DBHelper.GetVisibleTiersDataTable(pcno, role)`):**
- `ddlCat` — the Category/Tier picker in the "Add/Edit Employee" form
- `ddlImportCat` — the category picker in the "Import from CSV" panel
- `ddlFilter` — the category filter above the employee grid
- `ddlBulkLeaveCategory` — the category filter for bulk leave operations

**Preserving the selected filter value:** When `PopulateDropdowns` is called after a save/update (which re-calls it), the currently selected filter value would be lost because `DataBind()` resets the dropdown. The code saves and restores the selected value:
```csharp
string selectedFilter = ddlFilter.SelectedValue;  // save
ddlFilter.Items.Clear();
// ... add items ...
if (ddlFilter.Items.FindByValue(selectedFilter) != null)
    ddlFilter.SelectedValue = selectedFilter;  // restore
```

---

## `BindGrid()` — Load the Employee Table

```csharp
private void BindGrid()
```

Builds and executes the SQL query to populate the `gvEmployees` GridView. This is called on every filter change, search, tab switch, and after every add/edit/delete operation.

**Reading the current filters:**
- `ddlFilter.SelectedValue` — category/tier filter (or "All")
- `ddlFilterDiv.SelectedValue` — division filter (or "All")
- `txtSearch.Text` — free-text search (matches ID or Name, case-insensitive)
- `hfActiveTab.Value` — "Active" or "Resigned" (which tab is open)
- `ddlFilterStatus.SelectedValue` — status sub-filter (Active, ContractEnded, etc.)

**The `catSelect` sub-query:**
```sql
(SELECT mc.Name || ' › ' || t.TierName || NVL2(t.RoleLabel, ' (#' || t.RoleLabel || ')', '')
 FROM Tiers t JOIN MainCategory mc ON t.MainCategoryId = mc.Id
 WHERE t.Id = e.TierId) AS Category
```
This is an Oracle **inline scalar sub-query** — it runs once per row and returns the formatted category display name. Used so the grid shows "Skilled Workers › Welder" instead of a raw TierId number.

**Active tab query (Status IN Active/Upgraded/Downgraded/ContractEnded/Transferred):**
```sql
SELECT e.MasterId, e.ID, e.Name, e.Department, [catSelect], 
       NVL(e.OriginalJoinDate, e.JoinDate) AS JoinDate, 
       e.LeaveBalance, e.PrevLeaveBalance, e.Status,
       e.Experience, e.ExperienceIn, e.Qualification,
       ee.StartDate AS CurrentEngStartDate
FROM Employees e
LEFT JOIN EmployeeEngagements ee ON e.CurrentEngagementId = ee.Id
WHERE e.MasterId NOT LIKE 'GLOBAL%'   -- exclude system-level global holiday rows
  AND e.Status <> 'System'
  AND e.Status IN ('Active','Upgraded','Downgraded','ContractEnded','Transferred')
```
`NVL(OriginalJoinDate, JoinDate)` returns OriginalJoinDate if it has a value, otherwise JoinDate. This ensures rejoining employees show their original first-ever join date in the grid.

**Resigned tab query:** Much more complex — uses two `NOT EXISTS` sub-queries to show only the **latest** resigned stint per employee. Why? An employee can rejoin and resign multiple times, creating multiple rows in the Employees table with the same `EmployeeHistoryId`. The resigned tab should only show the most recent resigned row:

```sql
AND NOT EXISTS (
    -- Exclude if this person has an ACTIVE record (they've already rejoined)
    SELECT 1 FROM Employees e2 LEFT JOIN Tiers t2 ON e2.TierId = t2.Id
    WHERE NVL(e2.EmployeeHistoryId, e2.MasterId) = NVL(e.EmployeeHistoryId, e.MasterId)
      AND e2.Status IN ('Active','Upgraded','Downgraded','ContractEnded','Transferred')
)
AND NOT EXISTS (
    -- Exclude if there's a NEWER resigned row for the same person
    SELECT 1 FROM Employees e3 LEFT JOIN Tiers t3 ON e3.TierId = t3.Id
    WHERE NVL(e3.EmployeeHistoryId, e3.MasterId) = NVL(e.EmployeeHistoryId, e.MasterId)
      AND e3.Status = 'Resigned'
      AND (NVL(e3.ResignDate, e3.JoinDate) > NVL(e.ResignDate, e.JoinDate)
           OR (NVL(e3.ResignDate, e3.JoinDate) = NVL(e.ResignDate, e.JoinDate) 
               AND e3.MasterId > e.MasterId))
)
```

**Role-based scoping — every query includes this block:**
```sql
AND (
    :IsSuper = 1
    OR (NVL(ee.TierId, e.TierId) IS NOT NULL AND NVL(ee.TierId, e.TierId) IN (
        SELECT t.Id FROM Tiers t
        JOIN MainCategory mc ON t.MainCategoryId = mc.Id
        LEFT JOIN UserTiers ut ON t.Id = ut.TierId AND :Role = 0
        WHERE (:Role = 4)
           OR (:Role = 1 AND {adminCatCond})
           OR (:Role = 0 AND ut.PCNO = :PCNO)
    ))
)
```
This single WHERE clause handles all three role types:
- Super Admin: `IsSuper = 1` → entire condition is true → no category filter
- Admin: filtered by the `adminCatCond` condition (which varies by Primary/Secondary Admin)
- Regular User: filtered by their `UserTiers` assignments

`adminCatCond` is built dynamically in C# as a string before the query runs, based on `Session["RoleMode"]`.

---

## `btnAddEmployee_Click` — Add OR Update Employee

```csharp
protected void btnAddEmployee_Click(object sender, EventArgs e)
```

This single handler covers both **adding a new employee** and **updating an existing one**, depending on whether `hfEditOldID.Value` is empty or not.

**Reading form values:**
All inputs from the employee modal form are read:
- `txtEmpID.Text` — the visible Employee ID (e.g. PCNO)
- `txtEmpName.Text` — employee full name
- `ddlDept.SelectedValue` — department/division
- `ddlCat.SelectedValue` — tier/category (numeric TierId)
- `txtJoinDate.Text` — join date
- `txtLeaveBalance.Text` — initial leave balance (float)
- Optional: phone, email, Aadhar, address, qualification, experience (years), experience details

**Validation: Phone**
```csharp
if (!System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\d{10}$"))
    ShowMessage("Phone number must be exactly 10 digits.", false, "employeeModal");
```
The regex `^\d{10}$` means: exactly 10 digits from start to end. The `^` and `$` anchors prevent partial matches like "12345678901234" from passing.

**Validation: Aadhar duplicate check**
If the Aadhar number is 12 digits (a valid Aadhar), checks the database for any other employee with the same Aadhar (after stripping spaces and hyphens). The check uses:
```sql
REPLACE(REPLACE(e.Aadhar, ' ', ''), '-', '') = :Aadhar
```
This normalizes stored Aadhar values to match regardless of how they were originally formatted. Excludes the current employee being edited (by MasterId and EmployeeHistoryId — the HistoryId check prevents false positives when the same person rejoins).

### Branch 1: `hfEditOldID` is empty → **ADD mode**

```csharp
string masterId = GenerateNextMasterId();
string historyId = masterId;
```
A new numeric MasterId is generated and also used as the `EmployeeHistoryId`. If this is a **Rejoin**:
```csharp
if (chkIsRejoining.Checked && !string.IsNullOrEmpty(ddlRejoiningEmployee.SelectedValue))
{
    string oldMasterId = ddlRejoiningEmployee.SelectedValue;
    // Fetch the old employee's EmployeeHistoryId and OriginalJoinDate
    historyId = dtHist.Rows[0]["EmployeeHistoryId"].ToString(); // re-use old history chain
    originalJoinDate = dtHist.Rows[0]["OriginalJoinDate"];      // preserve original first join
}
```
The rejoin inherits the old `EmployeeHistoryId` so both the old resigned record and the new rejoin record are linked under the same history chain. The `OriginalJoinDate` is also preserved — the employee's first-ever join date stays intact across multiple stints.

**Duplicate ID check:**
```sql
SELECT COUNT(*) FROM Employees WHERE ID = :ID AND TierId = :TierId
AND Status IN ('Active','Upgraded','Downgraded','ContractEnded','Transferred')
AND MasterId != :MasterId
```
Checks: does this Employee ID (PCNO) already exist as an active employee in the same category? Duplicates in different categories are allowed (different contract contexts).

**INSERT query:**
```sql
INSERT INTO Employees (MasterId, ID, Name, Department, TierId, EmployeeHistoryId,
    JoinDate, OriginalJoinDate, LeaveBalance, PrevLeaveBalance, Status,
    Phone, Email, Aadhar, Address, Qualification, Experience, ExperienceIn)
VALUES (..., 'ContractEnded')
```
Note the initial `Status = 'ContractEnded'` — a newly registered employee has no active engagement yet. The next line calls `AutoEnrollActiveContract(...)` which, if an active contract period exists for this tier, creates the engagement and upgrades Status to 'Active' in a transaction.

**After INSERT:**
```csharp
AutoEnrollActiveContract(masterId, id, tierId, dept, joinDate);
SyncIndividualLeaveCredits(conn, masterId, leave, 0);
ActionLogger.LogAction("ADD", masterId, "Registered...", preState, postState);
```

### Branch 2: `hfEditOldID` has a value → **UPDATE mode**

**Department locking:** If the employee has an active engagement (`CurrentEngagementId IS NOT NULL`), the department is NOT allowed to change. The form UI disables the dropdown, and the server-side code also ignores the submitted department value:
```csharp
bool hasActiveEng = drCurrent["CurrentEngagementId"] != DBNull.Value;
if (hasActiveEng)
    dept = drCurrent["Department"].ToString(); // override whatever was submitted
```
Department changes are only done through the "Transfer" status change flow (which creates a new engagement row).

**UPDATE query (key detail):**
```sql
UPDATE Employees
SET ID = :ID, Name = :Name, Department = :Dept, TierId = :TierId,
    OriginalJoinDate = :OriginalJoinDate,
    JoinDate = CASE WHEN CurrentEngagementId IS NULL THEN :JoinDate ELSE JoinDate END,
    LeaveBalance = :Leave, ...
WHERE MasterId = :MasterId
```
`JoinDate` is only updated if `CurrentEngagementId IS NULL` (no active engagement). If the employee is actively engaged, their JoinDate for the current stint is protected from accidental changes.

**Sync engagement Employee ID:** After updating the employee's ID in the Employees table, also syncs it in the EmployeeEngagements table for the current contract period:
```sql
UPDATE EmployeeEngagements
SET EmployeeId = :NewId
WHERE EmpID = :MasterId
  AND ContractPeriodId = (
      SELECT cp_ee.ContractPeriodId FROM EmployeeEngagements cp_ee
      WHERE cp_ee.Id = (SELECT e_sub.CurrentEngagementId FROM Employees e_sub WHERE e_sub.MasterId = :MasterId)
  )
```
> **This is the fix for the duplicate ledger entries bug.** Previously, if an employee had 2 engagements in the same contract period, only one engagement would have its `EmployeeId` updated. This query correctly targets only engagements in the **current** contract period, not all engagements. However, the WHERE clause still only updates one row per contract period — if two engagements exist under the same contract period, both need updating. The proper fix is to remove the `ContractPeriodId` inner join condition so ALL engagements where EmpID = MasterId get their EmployeeId updated.

---

## `btnImport_Click` — Bulk CSV/Excel Import

```csharp
protected void btnImport_Click(object sender, EventArgs e)
```

Accepts either:
1. An uploaded CSV file (`fileCSV.PostedFile`)
2. JSON data from `hfImportData.Value` — this is populated when the user uses the in-browser Excel parser (JavaScript reads the .xlsx file client-side and sends parsed rows as JSON, bypassing file upload size limits)

**Two-pass validation then insert:**

**Pass 1: Validate all rows first**
A local `Action<...> validateRow` lambda is defined that checks each row:
- Employee ID is not blank
- Name is not blank
- Department is not blank
- Department exists in company divisions (case-insensitive check against `validCompanyDivs` HashSet)
- JoinDate is not blank and is a valid parseable date

If any row fails, an exception is thrown with a descriptive message including row number and field name. The `catch` in `btnImport_Click` shows this to the user and stops. No rows are inserted.

If all rows pass, they are stored in `validatedRows` list.

**Pass 2: Insert all validated rows**
```csharp
foreach (var r in validatedRows)
{
    ProcessImportedRow(r.Id, r.Name, r.Dept, ...);
}
```

**JSON path (primary):** The `hfImportData.Value` is a JSON string like:
```json
[[col0header,col1header,...],[val0,val1,...],[val0,val1,...]]
```
The `rows[0]` is skipped (it's the header). From `rows[1]` onwards, each sub-array is mapped to columns by position index.

**CSV fallback:** If no JSON data is present, reads the uploaded file line by line using `StreamReader`, splits by comma. This is simpler but limited to comma-separated, no multi-line values or quoted commas.

The **column mapping** for import (0-indexed):
| Index | Field |
|---|---|
| 0 | Employee ID |
| 1 | Name |
| 2 | Department |
| 3 | Join Date |
| 4 | Leave Balance |
| 5 | Qualification |
| 6 | Experience (years) |
| 7 | Experience Details |
| 8 | Phone |
| 9 | Email |
| 10 | Aadhar |
| 11 | Address |
| 12 | Category (optional — overrides dropdown selection per-row) |

---

## `ResolveTierId(rowCat, defaultCat, pcno, role)` — Flexible Category Matching

```csharp
private int ResolveTierId(string rowCat, string defaultCat, string pcno, int role)
```

When importing, the user can optionally put a category name in column 12 of each row. This method tries to match that string against all visible tiers, accepting any of these formats:
- Numeric TierId (e.g. `"3"`)
- Full display name (e.g. `"Skilled Workers › Welder"`)
- Just the tier name (e.g. `"Welder"`)
- Colon separator (e.g. `"Skilled Workers:Welder"`)
- Dash separator (e.g. `"Skilled Workers - Welder"`)

If no match is found, falls back to `defaultCat` — the category selected in the dropdown at the top of the import panel.

---

## `ProcessImportedRow(...)` — Insert One Imported Employee

```csharp
private void ProcessImportedRow(string id, string name, string dept, ...)
```

**Skips if duplicate:** Checks if an active employee with this ID already exists in this tier:
```sql
SELECT COUNT(*) FROM Employees
WHERE ID = :ID AND TierId = :TierId
AND Status IN ('Active','Upgraded','Downgraded','ContractEnded','Transferred')
```
If count > 0, this row is silently skipped (not an error — the import just moves on to the next row).

**Case normalization of division:** Looks up the department name in the company divisions list and uses the canonical case from the database (e.g. corrects "d-ces" to "D-CES").

**Assigns sequential MasterIds:** Uses a local counter `currentNextMaster` that starts at `MAX(existing MasterId) + 1`. Passed by `ref` so each call increments it. Avoids DB sequence calls for batch performance.

**Calls `FormatExperienceIn(experienceIn)`** before inserting — normalizes multiline experience text to use `\r\n` line endings with "- " bullet prefix.

After each successful insert: calls `AutoEnrollActiveContract(...)` and `SyncIndividualLeaveCredits(...)` just like the single-employee add flow.

---

## `FormatExperienceIn(string expIn)` — Normalize Experience Text

```csharp
private string FormatExperienceIn(string expIn)
```

Accepts experience details in any of these formats: newline-separated, semicolon-separated, or pipe-separated. Normalizes to `\r\n`-separated lines with `"- "` prefix for each bullet point.

Example: `"Welding|Cutting|Assembly"` → `"- Welding\r\n- Cutting\r\n- Assembly"`

---

## `GenerateNextMasterId()` — Auto-Increment Master ID

```csharp
private string GenerateNextMasterId()
```

Queries ALL existing MasterIds, finds the highest numeric one, and returns `max + 1`. Starts at 10001 if no numeric MasterIds exist yet.

Why not use an Oracle sequence? Because MasterIds can contain non-numeric values (the system has a special "GLOBAL" MasterId). Using a sequence would cause collisions if non-numeric IDs were mixed in. This brute-force MAX+1 approach is safe but slower — acceptable since it only runs on employee adds, not on bulk queries.

---

## `AutoEnrollActiveContract(masterId, empId, tierId, department, joinDate)` — Automatically Enroll in Active Contract

```csharp
private void AutoEnrollActiveContract(...)
```

Called immediately after inserting a new employee. Checks if there is an active contract period for the employee's tier:
```sql
SELECT Id, VendorId, StartDate FROM ContractPeriods
WHERE TierId = :TierId AND Status = 'Active'
```

If an active contract exists, creates an engagement record and links the employee to it:

**Transaction (steps 1-3 must all succeed or all roll back):**

1. **INSERT into EmployeeEngagements** — creates the new engagement record. Uses `RETURNING Id INTO :NewEngagementId` to capture the auto-generated ID in one round-trip.

```sql
INSERT INTO EmployeeEngagements
    (EmpID, ContractPeriodId, TierId, VendorId, Department, StartDate, EmployeeId)
VALUES (...)
RETURNING Id INTO :NewEngagementId
```

2. **UPDATE Employees** — sets `CurrentEngagementId = newEngagementId` and `Status = 'Active'`.

3. **Commit** or **Rollback** if anything failed.

4. After commit: calls `DBHelper.BackfillHolidaysForEmployee(masterId)` — adds all existing public holidays to the employee's attendance record.

**Vendor validation:** If the ContractPeriod's VendorId is 0 or invalid, falls back to any vendor in the Vendors table. If no vendor exists at all, the auto-enroll is aborted (the employee stays at 'ContractEnded' status, and the admin must manually assign them via the Contracts page).

**Date clamping:** If the employee's JoinDate is before the contract period's start date, the engagement StartDate is set to the contract period's start date instead:
```csharp
if (parsedJoinDate < cpStartDate)
    parsedJoinDate = cpStartDate;
```

---

## `ddlStatus_SelectedIndexChanged` — Status Change Handler

```csharp
protected void ddlStatus_SelectedIndexChanged(object sender, EventArgs e)
```

Fires when the admin changes the status dropdown inside a grid row. Currently, the only two status options exposed in the frontend dropdown are **Resigned** and **Transferred**. The code-behind also contains logic for `Upgraded` and `Downgraded`, but these are not shown in the UI at present.

**Finding which row triggered it:**
```csharp
DropDownList ddl = (DropDownList)sender;
GridViewRow row = (GridViewRow)ddl.NamingContainer;
HiddenField hfEmpID = (HiddenField)row.FindControl("hfEmpID");
```
In ASP.NET GridViews, each row's controls share the same `NamingContainer` — the `GridViewRow`. `FindControl()` finds a control within that specific row, not across the entire page. This is how the handler knows which employee's row triggered the event.

**Guards:**
- Resigned employees cannot be set to Upgraded/Downgraded/Transferred
- Active/ContractEnded cannot be manually set (unless coming from a transition status)

**Branch: `Upgraded` or `Downgraded` — Category Transition (Backend only — not exposed in current UI)**

This code path exists in the backend but is not reachable via the current frontend. If re-enabled in future, this handles moving an employee from one wage tier to another (e.g. promoted from "Fitter" tier to "Senior Fitter" tier).

The category and transition date must have been pre-filled by the JavaScript in the modal (`hfChangeCategory`, `hfChangeDate`, `hfChangeEmpId` hidden fields).

**Inside a transaction:**
1. Validate new Employee ID is unique in the target category
2. Fetch current employee details (department, current engagement ID, vendor)
3. If no active engagement, fall back to the last closed engagement
4. Validate transition date > engagement start date
5. Find the active contract for the NEW category/tier
6. Validate vendor (with multiple fallbacks)
7. **Close old engagement:** `UPDATE EmployeeEngagements SET EndDate = :EndDate, EndReason = 'Upgraded/Downgraded'`
8. **Create new engagement** in the new tier with `IsCarriedOver = 1, PrevEngagementId = oldEngagementId`
9. **Update Employees master:** new TierId, new CurrentEngagementId, new EmployeeId, Status = 'Active'
10. **Commit**, then `BackfillHolidaysForEmployee`

`IsCarriedOver = 1` marks the new engagement as a continuation (not a fresh start). `PrevEngagementId` links back to the closed engagement, creating an auditable chain.

**Branch: `Transferred` — Division/Department Change**

Same structure as Upgrade/Downgrade but changes `Department` instead of `TierId`. The same category and tier are retained; only the directorate changes.

**Branch: `Resigned`**

1. Gets `CurrentEngagementId`
2. If engagement exists: closes it (`EndDate = resignDate, EndReason = 'Resigned'`) and sets `CurrentEngagementId = NULL`
3. Updates Employees: `Status = 'Resigned', ResignDate = :Date`
4. Commits transaction

**Branch: `ContractEnded`**

Same as Resigned but no resign date and `EndReason = 'ContractEnded'`. This is set automatically by `DBHelper.AutoCloseExpiredContracts` but can also be manually triggered.

---

## `gvEmployees_RowDataBound` — Style Each Grid Row on Load

```csharp
protected void gvEmployees_RowDataBound(object sender, GridViewRowEventArgs e)
```

Fires for each row as the GridView renders. Does two things:

**1. Apply status badge colors to the status dropdown:**
- Resigned → `badge-resigned` (strikethrough row)
- Upgraded → `badge-upgraded`
- Downgraded → `badge-downgraded`
- ContractEnded → `badge-contractended`
- Transferred → `badge-transferred`
- Active → `badge-active`

Also **disables invalid status transitions** in the dropdown:
- A Resigned employee cannot be set to Active (must rejoin) — `item.Enabled = false`
- ContractEnded option is only shown as current status, not as a selectable target

**2. Add client-side data attributes to the row `<tr>` element:**
```csharp
e.Row.Attributes["data-joindate"] = jd;        // ISO date for JS sort/filter
e.Row.Attributes["data-resigndate"] = rd;
e.Row.Attributes["data-experience"] = exp;
e.Row.Attributes["data-qualification"] = qual;
e.Row.Attributes["data-experiencein"] = expIn;
```
These `data-*` attributes are read by JavaScript for client-side advanced filtering and sorting — filtering by date range, experience, qualification, etc. without a server round-trip.

---

## `gvEmployees_RowCommand` — Handle Grid Action Buttons

```csharp
protected void gvEmployees_RowCommand(object sender, GridViewCommandEventArgs e)
```

Handles command names from buttons/links inside the GridView. Currently the frontend only wires up two commands:

**`"EditEmp"`:** Loads employee data into the edit form.
- Fetches the employee record by MasterId
- Fills all form fields (ID, name, department, category, join date, phone, etc.)
- For LeaveBalance: runs an extra query to get the **initial contract balance** from `EmployeeLeaveCredits` (not the current running balance):
```sql
SELECT NVL(elc.Amount, 0)
FROM EmployeeLeaveCredits elc
JOIN Employees e ON elc.EmpID = e.MasterId
JOIN EmployeeEngagements ee ON e.CurrentEngagementId = ee.Id AND elc.ContractPeriodId = ee.ContractPeriodId
WHERE elc.EmpID = :MasterId AND elc.Remarks = 'Contract Initial Balance'
```
- If employee has active engagement: disables Department and Category dropdowns, shows help text explaining why
- Sets button text to "Update Employee", shows Cancel button
- Opens the employee modal via `ShowMessage()`

**`"ViewHistory"`:** Calls `OpenHistoryModal(masterId)`.

> **Note:** The `"DeleteEmp"` command handler also exists in the code-behind (from an earlier version of the page), but the button that triggers it has been **removed from the frontend**. The Danger Zone delete panel (using `ddlDeleteEmployee` dropdown + `btnConfirmDelete`) is the only active delete path. The `gvEmployees_RowCommand` `"DeleteEmp"` branch is dead code that cannot be triggered by normal use.

---

## `OpenHistoryModal(masterId)` — Build and Inject Employee History

```csharp
private void OpenHistoryModal(string masterId)
```

Builds a JSON structure and sends it to the browser via a JavaScript function call.

**What it fetches:**
1. Employee master info (name, dates, contact details)
2. Full engagement history across ALL stints (uses `EmployeeHistoryId` to find all rows for this person):
```sql
SELECT ee.Id, ee.EmpID, [Category formula], ee.StartDate, ee.EndDate, ee.EndReason,
       ee.IsCarriedOver, ee.PrevEngagementId, ee.EmployeeId, ee.Department,
       v.Name AS VendorName, v.MasterId AS VendorMasterId,
       cp.StartDate AS ContractStart, cp.EndDate AS ContractEnd
FROM EmployeeEngagements ee
JOIN Vendors v ON v.Id = ee.VendorId
LEFT JOIN ContractPeriods cp ON cp.Id = ee.ContractPeriodId
WHERE ee.EmpID IN (
    SELECT MasterId FROM Employees
    WHERE EmployeeHistoryId = (
        SELECT EmployeeHistoryId FROM Employees WHERE MasterId = :MasterId
    )
)
ORDER BY ee.StartDate ASC, ee.Id ASC
```
The nested sub-query finds the HistoryId of the current employee, then finds ALL employee records (past and present stints) sharing that HistoryId, then finds all their engagements.

**Building the JSON manually:**
The code uses `StringBuilder` to build a JSON array by hand rather than using a serializer. This avoids creating objects just to serialize them, and allows fine-grained control:
```csharp
sb.AppendFormat("\"cat\":\"{0}\",", EscapeJs(cat));
```

**Injecting into the browser via RegisterStartupScript:**
```csharp
string script = string.Format("openHistoryModal({0}, {1});", empJson, sb.ToString());
ClientScript.RegisterStartupScript(this.GetType(), "hist_" + Guid.NewGuid().ToString("N"), script, true);
```
`RegisterStartupScript` injects a `<script>` block at the bottom of the page, which runs immediately when the browser receives the HTML. The GUID in the key ensures no two script registrations collide. This calls the client-side `openHistoryModal(empData, historyArray)` JavaScript function, which renders the timeline UI.

---

## `EscapeJs(string s)` — Escape for JavaScript String Literals

```csharp
private static string EscapeJs(string s)
{
    return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("'", "\\'")
             .Replace("\r\n", "\\n").Replace("\r", "").Replace("\n", "\\n");
}
```

When manually building JSON strings, any value that contains quotes or newlines would break the JavaScript string literal. This method escapes them:
- `\` → `\\` (must be first, otherwise double-escaping later steps)
- `"` → `\"` (avoids breaking out of the JSON string)
- `'` → `\'` (protects single-quoted JS strings)
- Newlines → `\n` (JavaScript string escape for line break)

---

## `btnSubmitBulkLeave_Click` — Bulk Leave Adjustment

```csharp
protected void btnSubmitBulkLeave_Click(object sender, EventArgs e)
```

Applies a leave adjustment (positive or negative float) to ALL active employees matching the selected category and division filters.

**Validation:**
- Amount must be a valid float
- Effective date must be a valid date
- Remarks must not be empty

**Target employees:**
```sql
SELECT e.MasterId, ee.ContractPeriodId
FROM Employees e
JOIN EmployeeEngagements ee ON e.CurrentEngagementId = ee.Id
WHERE e.Status <> 'Resigned'
[AND e.Category = :Category]
[AND e.Department = :Division]
```

**Transaction: for each employee:**
1. INSERT into `EmployeeLeaveCredits` — creates an audit record
2. UPDATE `Employees.LeaveBalance += :Amount` — updates the running balance

Uses pre-built Oracle commands with parameter objects set per-loop rather than creating new command objects each iteration — much faster for large batches.

---

## `btnResetBulkLeave_Click` — Bulk Leave Reset to Zero

```csharp
protected void btnResetBulkLeave_Click(object sender, EventArgs e)
```

Same flow as `btnSubmitBulkLeave_Click`, but instead of adding an amount, sets `LeaveBalance = 0` for each employee and inserts a **negative credit** equal to the current balance (to cancel it out in the audit trail):

```csharp
float currentBalance = Convert.ToSingle(row["LeaveBalance"]);
if (Math.Abs(currentBalance) > 0.001f) // skip if already 0
{
    float amountToAdjust = -currentBalance; // negative of whatever they have
    // INSERT credit record with negative amount
    // UPDATE Employees SET LeaveBalance = 0
}
```

`Math.Abs(currentBalance) > 0.001f` — uses a tiny epsilon instead of `== 0` because floating point comparisons with exact zero can be unreliable.

---

## `SyncIndividualLeaveCredits(connStr, masterId, initialBalance, prevBalance)` — Sync Leave Credit Records

```csharp
private void SyncIndividualLeaveCredits(string connStr, string masterId, double initialBalance, double prevBalance)
```

Called after every add or update. Ensures the `EmployeeLeaveCredits` table has a "Contract Initial Balance" record for the employee's current engagement and their most recent past engagement.

**Why is this needed?** The Employee form shows `txtLeaveBalance` which the admin sets directly. But the authoritative source of truth for leave balances is `EmployeeLeaveCredits`. This method bridges the two by inserting or updating the "Contract Initial Balance" row.

**For the current contract period:**
- If a "Contract Initial Balance" credit exists: UPDATE its Amount to `initialBalance`
- If no such credit exists: INSERT one with `EffectiveDate = engagement start date`
- After updating: recalculate `SUM(EmployeeLeaveCredits) WHERE ContractPeriodId = currentCpId` and sync it to `Employees.LeaveBalance`

**For the most recent past contract period (if any):**
- Same logic but uses `prevBalance` — the previous contract's initial balance
- Only writes if `prevBalance > 0` (avoids zeroing out legitimate past credits)

**Duplicate prevention:** The query returns all existing "Contract Initial Balance" rows ordered by Id. The first is kept and updated; any extras are deleted. This prevents accumulation of duplicate rows that could corrupt the balance sum.

---

## WebMethod: `GetEmployeeLeaveTimeline(masterId)` — Leave Credit Timeline for Sidebar

```csharp
[System.Web.Services.WebMethod]
public static string GetEmployeeLeaveTimeline(string masterId)
```

Called via JavaScript AJAX (`PageMethods.GetEmployeeLeaveTimeline(...)`) when the admin opens the leave credits breakdown panel for an employee.

Returns a JSON object:
```json
{
  "status": "success",
  "empName": "Rajan Kumar",
  "currentCpId": 5,
  "currentCpDetails": "01-Jan-2024 to 31-Dec-2024",
  "categoryName": "Skilled Workers › Welder",
  "initialBalance": 18,
  "otherCreditsSum": 2.5,
  "totalBalance": 20.5,
  "credits": [
    { "id": 1, "amount": 18, "effectiveDate": "2024-01-01", "remarks": "Contract Initial Balance", "isInitial": true, "isCurrentCp": true, "contractLabel": "..." },
    ...
  ]
}
```

`[System.Web.Services.WebMethod]` marks this as callable from JavaScript via ASP.NET's `PageMethods` AJAX mechanism. It must be `public static` — static because WebMethods cannot access instance members (no `this` available). The connection string is fetched via `DBHelper.GetAttendanceDBConnection()` directly.

---

## WebMethod: `SaveEmployeeLeaveCredit(...)` — Create or Update a Leave Credit

```csharp
[System.Web.Services.WebMethod]
public static string SaveEmployeeLeaveCredit(string masterId, int? creditId, double amount, string effectiveDate, string remarks)
```

If `creditId` is provided (> 0): UPDATEs the existing credit row.
If no `creditId`: INSERTs a new credit row linked to the employee's current active contract period.

After either operation: recalculates `SUM(EmployeeLeaveCredits)` for the active contract period and syncs it to `Employees.LeaveBalance`.

**Protection for the initial balance row:** If editing a "Contract Initial Balance" record, the remarks are forced to stay as "Contract Initial Balance" even if the admin passed different remarks — this preserves the system-generated label.

---

## WebMethod: `DeleteEmployeeLeaveCredit(creditId, masterId)` — Delete a Leave Credit

```csharp
[System.Web.Services.WebMethod]
public static string DeleteEmployeeLeaveCredit(int creditId, string masterId)
```

If the credit is a "Contract Initial Balance" row: does NOT hard-delete it. Instead sets `Amount = 0`. This preserves the audit record and prevents the initial balance from going "missing" which could confuse balance calculations.

For all other credit rows: hard-deletes and recalculates the balance.

---

## WebMethod: `CheckAadharMatch(aadharNumber, currentMasterId)` — Real-Time Aadhar Lookup

```csharp
[System.Web.Services.WebMethod]
public static string CheckAadharMatch(string aadharNumber, string currentMasterId)
```

Called via JavaScript as the admin types in the Aadhar field (on blur). If a 12-digit Aadhar is found in the database (belonging to a different employee/history chain), returns full details of the matching employee including their engagement history. This lets the admin see who this Aadhar belongs to before registering a potentially duplicate person.

Returns JSON with `{ matched: true, employee: {...}, history: [...] }` or `{ matched: false }`.

---

## WebMethod: `GetEmployeeHistoryModalData(masterId)` — AJAX History for Modal

```csharp
[System.Web.Services.WebMethod]
public static string GetEmployeeHistoryModalData(string masterId)
```

A duplicate of `OpenHistoryModal` but as a WebMethod that returns JSON instead of injecting a script. Used by JavaScript when opening the history modal via an AJAX call (no postback required). Returns the same data structure:
- Employee master info
- Full engagement history (all stints, all contract periods, all categories/vendors)

---

## `ShowMessage(msg, success, showModalId)` — Toast Notification System

```csharp
private void ShowMessage(string msg, bool success, string showModalId = null)
```

Injects a JavaScript call to `showToast('message', 'success|error')` via `RegisterStartupScript`. The toast system is defined in `Site.Master` and shows a floating notification in the top-right corner.

If `showModalId` is provided (e.g. `"employeeModal"`): also re-opens that Bootstrap modal so the user remains in their current context (e.g. validation error while the Add Employee modal is open — the modal stays visible with the error).

Special handling for edit mode: if in edit mode (`hfEditOldID` is set), also calls `loadLeaveCreditsBreakdown(masterId)` from JavaScript — reloads the leave credits panel with the editing employee's data.

---

## `BindResignedEmployees()` — Populate the Rejoin Dropdown

```csharp
private void BindResignedEmployees()
```

Populates `ddlRejoiningEmployee` — the dropdown shown when "Is Rejoining" is checked. Shows all resigned employees, but only the **most recent resigned stint per person** (using `ROW_NUMBER()` OVER PARTITION):

```sql
SELECT MasterId, Name, Department, TierId, ... ResignDate
FROM (
    SELECT ...,
           ROW_NUMBER() OVER (
               PARTITION BY NVL(EmployeeHistoryId, MasterId)
               ORDER BY NVL(ResignDate, JoinDate) DESC, JoinDate DESC, MasterId DESC
           ) as rn
    FROM Employees
    WHERE MasterId NOT LIKE 'GLOBAL%' AND Status <> 'System'
)
WHERE rn = 1 AND Status = 'Resigned'
ORDER BY ResignDate DESC NULLS LAST, Name ASC
```

`ROW_NUMBER() OVER (PARTITION BY ...)` is an Oracle analytic function — within each group of rows sharing the same `EmployeeHistoryId`, it assigns sequential row numbers ordered by resign date. `WHERE rn = 1` keeps only the most recent resigned row per history chain.

Also serializes all resigned employee data to JSON and stores in `hfResignedEmployeesJson` hidden field — this lets JavaScript auto-fill the form when the admin selects an employee from the dropdown (name, phone, email, Aadhar, etc. are pre-filled from the previous stint without a round-trip).

---

## `PopulateDeleteEmployeeDropdown()` — Fill the "Danger Zone" Delete Dropdown

```csharp
private void PopulateDeleteEmployeeDropdown()
```

Populates `ddlDeleteEmployee` with all employees the current user can see (scoped by role/tier). Displays as: `"Rajan Kumar (PCNO12345 - Master: 10047)"`.

Used by the Danger Zone panel where the admin can select an employee and confirm deletion of their entire record.

---

## `btnConfirmDelete_Click` — Confirm and Execute Employee Deletion

```csharp
protected void btnConfirmDelete_Click(object sender, EventArgs e)
```

Same deletion sequence as `gvEmployees_RowCommand` / `"DeleteEmp"` — deletes in cascade order: CalculationOverrides → Attendance → NULL CurrentEngagementId → EmployeeEngagements → Employees.

Logs the action via `ActionLogger.LogAction("DELETE", ...)` before deleting (pre-state is captured before any deletions).

---

## `GetActiveCount()` and `GetResignedCount()` — Tab Counters

```csharp
protected string GetActiveCount()
protected string GetResignedCount()
```

Return count strings used in the tab labels (e.g. "Active (42)" and "Resigned (3)"). Both apply the same role-scoping WHERE clause as `BindGrid`. The resigned count uses the same `NOT EXISTS` de-duplication logic. These methods are called from `<%= GetActiveCount() %>` expressions directly in the ASPX markup.

---

## `btnTabActive_Click` / `btnTabResigned_Click` — Tab Switch Handlers

```csharp
protected void btnTabActive_Click(object sender, EventArgs e)
{
    hfActiveTab.Value = "Active";
    // Reset status filter if it was set to 'Resigned' (which is only valid on Resigned tab)
    if (ddlFilterStatus.SelectedValue == "Resigned") ddlFilterStatus.SelectedValue = "All";
    BindGrid();
}
```

Sets `hfActiveTab.Value` to control which query branch `BindGrid()` uses. A HiddenField (`hfActiveTab`) persists the tab state across postbacks (the value is included in the page's ViewState).

---

## `ddlFilter_SelectedIndexChanged` / `ddlFilterDiv_SelectedIndexChanged` / `btnSearch_Click`

All three are simple one-liners that call `BindGrid()`. The filter state is already in the dropdown/textbox controls when the postback fires, so `BindGrid()` just reads them.

---

## `ResetForm()` — Clear the Employee Add/Edit Form

```csharp
private void ResetForm()
```

Clears all form inputs and restores the form to its default "Add" state:
- All text boxes → empty
- `hfEditOldID.Value = ""` — switches back to Add mode
- `txtMasterID.Text = "(Auto-Generated)"` — shows placeholder
- `chkIsRejoining.Checked = false` / `Enabled = true`
- `txtEmpID.Enabled = true` / `txtJoinDate.Enabled = true` (re-enables for adds)
- `ddlDept.Enabled = true` / `ddlCat.Enabled = true`
- `lblDeptHelp.Style["display"] = "none"` / same for `lblCatHelp`
- `btnAddEmployee.Text = "Add Employee"` / `btnCancelEdit.Visible = false`

---

## Summary: All Methods

| Method | Access | Trigger | Purpose |
|---|---|---|---|
| `Page_Load` | protected | Every page load | Auth guard, access control, first-load init |
| `PopulateDropdowns` | private | First load + after saves | Fill all 6 dropdown lists |
| `BindGrid` | private | Every filter change/save/tab switch | Load employee table from DB |
| `GetActiveCount` | protected | ASPX expression | Tab counter for active employees |
| `GetResignedCount` | protected | ASPX expression | Tab counter for resigned employees |
| `btnAddEmployee_Click` | protected | Add/Update button | INSERT or UPDATE employee record |
| `btnImport_Click` | protected | Import button | Bulk CSV/JSON employee import |
| `btnSubmitBulkLeave_Click` | protected | Bulk leave button | Add leave to all matching employees |
| `btnResetBulkLeave_Click` | protected | Bulk reset button | Zero out leave for all matching employees |
| `btnTabActive_Click` | protected | Active tab link | Switch to active employee view |
| `btnTabResigned_Click` | protected | Resigned tab link | Switch to resigned employee view |
| `btnSearch_Click` | protected | Search button | Re-bind grid with search text |
| `btnCancelEdit_Click` | protected | Cancel button | Reset form and cancel edit |
| `btnConfirmDelete_Click` | protected | Delete confirm button | Hard-delete employee from danger zone |
| `ddlFilter_SelectedIndexChanged` | protected | Category filter change | Re-bind grid |
| `ddlFilterDiv_SelectedIndexChanged` | protected | Division filter change | Re-bind grid |
| `ddlFilterStatus_SelectedIndexChanged` | protected | Status filter change | Re-bind grid |
| `ddlStatus_SelectedIndexChanged` | protected | Grid row status change | Resign/Transfer/Upgrade/Downgrade |
| `gvEmployees_RowDataBound` | protected | GridView row render | Apply status badge styling + data-* attributes |
| `gvEmployees_RowCommand` | protected | Grid row button click | Edit / ViewHistory (Delete is dead code — button removed from frontend) |
| `gvEmployees_RowDeleting` | protected | GridView delete (unused) | Empty handler (placeholder) |
| `btnHiddenEditTrigger_Click` | protected | JS-triggered hidden button | Load edit form from JS context |
| `OpenHistoryModal` | private | RowCommand ViewHistory | Build and inject JS history modal data |
| `AutoEnrollActiveContract` | private | After employee add | Enroll new employee in active contract |
| `BindResignedEmployees` | private | First load + after saves | Populate rejoin dropdown |
| `PopulateDeleteEmployeeDropdown` | private | First load + after saves | Populate danger zone delete dropdown |
| `GenerateNextMasterId` | private | Add mode | Generate next sequential MasterId |
| `SyncIndividualLeaveCredits` | private | After add/edit | Sync EmployeeLeaveCredits with LeaveBalance |
| `ProcessImportedRow` | private | Import loop | Insert one validated import row |
| `ResolveTierId` | private | Import | Match row's category text to TierId |
| `FormatExperienceIn` | private | Import | Normalize experience text bullets |
| `ResetForm` | private | After save/cancel | Clear all form inputs |
| `ShowMessage` | private | After every operation | Inject toast + re-open modal |
| `EscapeJs` | private static | History JSON build | Escape strings for JS literal safety |
| `GetEmployeeLeaveTimeline` | WebMethod | AJAX from JS | Leave credit timeline for sidebar panel |
| `SaveEmployeeLeaveCredit` | WebMethod | AJAX from JS | Create or update one leave credit |
| `DeleteEmployeeLeaveCredit` | WebMethod | AJAX from JS | Delete (or zero) one leave credit |
| `CheckAadharMatch` | WebMethod | AJAX on Aadhar blur | Check if Aadhar already registered |
| `GetEmployeeHistoryModalData` | WebMethod | AJAX from JS | Employee history JSON for AJAX modal |

---

*Next: See `06_Attendance.md` for the Attendance page.*
