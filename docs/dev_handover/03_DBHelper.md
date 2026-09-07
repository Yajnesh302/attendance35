# 03 — DBHelper.cs (The Core Data Access Layer)

**File:** `Utils/DBHelper.cs` — 1,791 lines

---

## What Is DBHelper?

`DBHelper` is a **static utility class** — meaning you never create an object of it; you call its methods directly like `DBHelper.ExecuteQuery(...)`. It handles **every single database operation** in the entire application.

No other file opens an Oracle connection on its own — they all go through DBHelper. Think of it as the gatekeeper between the application code and the Oracle database.

It also handles several important background jobs on every page load:
- Auto-closes expired contracts
- Self-repairs the database schema if columns or tables are missing
- Keeps the local Divisions table in sync with the company HR database
- Manages retry logic when database connections fail temporarily
- Controls what date range a POC user is allowed to view

---

## Two Database Connections

```csharp
public static string GetCompanyDBConnection()
{
    return ConfigurationManager.ConnectionStrings["CompanyDB"].ConnectionString;
}

public static string GetAttendanceDBConnection()
{
    return ConfigurationManager.ConnectionStrings["AttendanceDB"].ConnectionString;
}
```

These two methods return Oracle connection strings from `Web.config`. Every other method in DBHelper accepts a connection string as its first argument, so you can target either database.

| Connection | Used For |
|---|---|
| `GetCompanyDBConnection()` | Reading HR data from `hrdata.empdetails` (name, designation, division) |
| `GetAttendanceDBConnection()` | All app data — Employees, Attendance, Contracts, AppUsers, etc. |

Both point to the same Oracle XE instance (`127.0.0.1:1521/xe`) but are kept separate because they represent two distinct data domains: the company HR system vs. the application's own data.

---

## Section 1: The Three Core Query Methods

These are the methods called thousands of times across the app. Every single page uses them.

---

### `ExecuteQuery` — Run a SELECT, get a DataTable back

```csharp
public static DataTable ExecuteQuery(string connectionString, string query, params OracleParameter[] parameters)
```

**Input:**
- `connectionString` — which database to connect to
- `query` — the SQL SELECT statement
- `parameters` — any number of Oracle bind parameters (optional, due to `params` keyword)

**Output:** A `DataTable` containing all the rows returned by the query.

**How it works, step by step:**
1. If connecting to AttendanceDB: calls `EnsureSchema()` (auto-adds missing columns) and `TriggerAutoCloseIfNeeded()` (checks for expired contracts)
2. Wraps the whole operation in `RunWithRetry()` — so if the DB connection drops temporarily, it retries up to 3 times automatically
3. Opens an `OracleConnection` using `using` blocks (guarantees the connection is closed and disposed even if an error occurs)
4. Creates an `OracleCommand` with `BindByName = true`
5. Clones the parameters before passing them (explained in CloneParameters section)
6. Uses `OracleDataAdapter.Fill(dt)` to execute the query and fill a DataTable
7. Returns the DataTable

> **What is BindByName?** By default, Oracle matches parameters by their position in the SQL string. Setting `BindByName = true` makes them match by name (`:PCNO`, `:Dept`, etc.). This prevents subtle bugs when the order of parameters changes.

**Example usage from any page:**
```csharp
DataTable dt = DBHelper.ExecuteQuery(
    DBHelper.GetAttendanceDBConnection(),
    "SELECT MasterId, Name FROM Employees WHERE Department = :Dept",
    new OracleParameter("Dept", "D-CES")
);
foreach (DataRow row in dt.Rows)
{
    string name = row["Name"].ToString();
}
```

---

### `ExecuteNonQuery` — Run an INSERT, UPDATE, or DELETE

```csharp
public static int ExecuteNonQuery(string connectionString, string query, params OracleParameter[] parameters)
```

**Output:** The number of rows affected (e.g. `1` if one row was updated, `0` if nothing matched the WHERE clause).

Same structure as `ExecuteQuery` but uses `cmd.ExecuteNonQuery()`. Use this when you do not expect rows back — just a confirmation of how many rows changed.

**Example:**
```csharp
int rowsAffected = DBHelper.ExecuteNonQuery(
    DBHelper.GetAttendanceDBConnection(),
    "UPDATE Employees SET Name = :Name WHERE MasterId = :Id",
    new OracleParameter("Name", "Rajan"),
    new OracleParameter("Id", "10047")
);
```

---

### `ExecuteScalar` — Run a query and get a single value back

```csharp
public static object ExecuteScalar(string connectionString, string query, params OracleParameter[] parameters)
```

**Output:** A single `object` — the value from the first column of the first row. Must be cast to the correct type.

Used when you want a COUNT, SUM, MAX, or any single value:
```csharp
object result = DBHelper.ExecuteScalar(
    DBHelper.GetAttendanceDBConnection(),
    "SELECT COUNT(*) FROM Employees WHERE Status = 'Active'"
);
int count = result != null ? Convert.ToInt32(result) : 0;
```

> **Always null-check the result.** If the query returns no rows, `ExecuteScalar` returns `null`. If the column value is a DB NULL, it returns `DBNull.Value`. Always check both before converting, otherwise you will get a NullReferenceException.

---

## Section 2: Retry and Error-Handling Infrastructure

---

### `IsTransientError(Exception ex)` — Is this error worth retrying?

```csharp
private static bool IsTransientError(Exception ex)
```

Decides whether a database error is a temporary problem (connection issue) or a permanent problem (bad SQL, constraint violation).

**Returns `false` — do NOT retry — for these Oracle errors:**

| Oracle Error | Meaning |
|---|---|
| ORA-00904 | Invalid column name — your SQL references a non-existent column |
| ORA-00942 | Table or view does not exist |
| ORA-00001 | Unique constraint violated — duplicate value |
| ORA-02291 | Parent key not found — FK violation on insert |
| ORA-02292 | Child record found — FK violation on delete |
| ORA-01400 | Cannot insert NULL into NOT NULL column |
| ORA-00936 | Missing expression — malformed SQL |
| ORA-00933 | SQL command not properly ended — malformed SQL |

**Returns `true` — retry is worthwhile — for everything else** (network errors, connection timeouts, temporary DB unavailability).

Why this matters: if your SQL has a typo, retrying 3 times wastes time and delays the error by seconds. Only genuinely temporary failures should be retried.

---

### `RunWithRetry<T>(Func<T> operation, int maxRetries = 3, int delayMs = 500)`

```csharp
private static T RunWithRetry<T>(Func<T> operation, int maxRetries = 3, int delayMs = 500)
```

Executes a database operation. If it throws a transient error, waits and tries again.

**Exponential backoff timing:**
- Attempt 1 fails → wait 500ms x 1 = 500ms
- Attempt 2 fails → wait 500ms x 2 = 1,000ms
- Attempt 3 fails → throw the error to the caller (give up)

`Func<T>` means "a function that returns T". Callers pass a C# lambda (anonymous function) containing their database code. This allows `RunWithRetry` to execute and re-execute any block of code without each method needing its own retry logic.

---

### `CloneParameters(OracleParameter[] parameters)` — Why parameters must be cloned

```csharp
private static OracleParameter[] CloneParameters(OracleParameter[] parameters)
```

**The problem it solves:** Once you add an `OracleParameter` object to an `OracleCommand`, that parameter is "owned" by that command. When the command is disposed (which happens inside the `using` block after each attempt), the parameter objects become stale. If `RunWithRetry` then tries again with the same original parameter objects, Oracle throws an error saying the parameter already belongs to a different command.

**The solution:** Before adding parameters to a command, create fresh copies of them. Every retry attempt gets its own fresh set of parameter objects, and the originals passed by the caller remain untouched.

What it copies per parameter: `ParameterName`, `Value`, `DbType`, `Direction`, `IsNullable`, `Size`, `SourceColumn`, `SourceVersion`.

---

## Section 3: Auto-Close Expired Contracts

These methods run automatically in the background during normal page usage.

---

### Throttling fields: `_lastAutoCloseCheck`, `_inAutoClose`, `_syncLock`

- `_lastAutoCloseCheck` — stores the `DateTime` of the last auto-close run. Starts at `DateTime.MinValue` so the first request always triggers it.
- `_inAutoClose` — decorated with `[ThreadStatic]`, meaning each thread has its own independent copy. Prevents the same thread from calling `AutoCloseExpiredContracts` recursively (e.g. if the method itself calls `ExecuteQuery`, which would call `TriggerAutoCloseIfNeeded` again).
- `_syncLock` — a regular object used as a lock. Ensures only ONE thread at a time can check and update `_lastAutoCloseCheck`. This prevents two simultaneous page requests from both deciding to run auto-close at exactly the same moment.

> **What is `[ThreadStatic]`?** IIS serves many concurrent requests on multiple threads. A normal `static` field is shared across ALL threads. `[ThreadStatic]` gives each thread its own separate copy of the variable, so one thread's in-progress flag does not affect another thread.

---

### `TriggerAutoCloseIfNeeded()` — Throttled background trigger

```csharp
public static void TriggerAutoCloseIfNeeded()
{
    if ((DateTime.UtcNow - _lastAutoCloseCheck).TotalSeconds < 1800) return;
    System.Threading.ThreadPool.QueueUserWorkItem(_ =>
    {
        try { AutoCloseExpiredContracts(false); } catch { }
    });
}
```

Called by all three core query methods when connecting to AttendanceDB.

If more than 30 minutes (1800 seconds) have passed since the last check:
- Queues `AutoCloseExpiredContracts` on the **.NET thread pool** (a pool of background worker threads managed by .NET)
- The current page request returns immediately — it does NOT wait for auto-close to finish
- Auto-close runs silently in the background while the user's page loads normally

Result: auto-close runs approximately every 30 minutes, triggered by normal page usage, with no need for a scheduled task or Windows service.

---

### `AutoCloseExpiredContracts(bool force = false)` — The main contract-closing logic

```csharp
public static void AutoCloseExpiredContracts(bool force = false)
```

**Step 1: Guard against recursion and enforce the 30-minute throttle**
```csharp
if (_inAutoClose) return;
if (!force && (DateTime.UtcNow - _lastAutoCloseCheck).TotalSeconds < 1800) return;
lock (_syncLock) { _lastAutoCloseCheck = DateTime.UtcNow; }
_inAutoClose = true;
```

**Step 2: Find all active contract periods whose end date has passed**
```sql
SELECT Id, EndDate FROM ContractPeriods
WHERE Status = 'Active' AND EndDate < TRUNC(SYSDATE)
```
`TRUNC(SYSDATE)` strips the time portion so it compares dates only (midnight today).

**Step 3: For each expired period, run everything inside a transaction:**

a. Mark the contract period as Closed:
```sql
UPDATE ContractPeriods SET Status = 'Closed' WHERE Id = :Id
```

b. Find all employee engagements under this period that are still open (`EndDate IS NULL` means "currently active"):
```sql
SELECT Id, EmpID FROM EmployeeEngagements
WHERE ContractPeriodId = :PeriodId AND EndDate IS NULL
```

c. For each active engagement:
- Close the engagement record:
```sql
UPDATE EmployeeEngagements SET EndDate = :EndDate, EndReason = 'ContractEnd' WHERE Id = :Id
```
- Update the Employee master to reflect the ended contract:
```sql
UPDATE Employees
SET CurrentEngagementId = NULL, ContractEndDate = :EndDate, Status = 'ContractEnded'
WHERE MasterId = :MasterId AND CurrentEngagementId = :Id
```

d. **Commit** the transaction if all steps succeeded. **Rollback** if anything failed.

> **Why use a transaction here?** If closing the engagement succeeds but updating the Employee master fails (e.g. a network hiccup between the two statements), the data would be inconsistent — the engagement would be closed but the employee would still appear as active. A transaction guarantees all-or-nothing: either all three updates commit together, or none of them do.

---

## Section 4: Schema Auto-Repair

---

### `EnsureSchema()` — Automatically adds missing columns, tables, and indexes

```csharp
public static void EnsureSchema()
```

**When it runs:** Called by all three core query methods every time they connect to AttendanceDB. However, a static flag `_schemaEnsured` prevents it from doing any real work after the first successful run. Uses `lock(_schemaLock)` so only one thread runs the actual schema check during app startup.

**What problem it solves:** The application has been developed incrementally. New columns and tables were added as new features were built. If someone sets up the app using an older `oracle_setup.sql`, they will be missing newer columns. Rather than requiring a manual database migration script to be run, `EnsureSchema` automatically detects what is missing and adds it.

**Key columns it ensures exist:**

| Table | Column | Type | Purpose |
|---|---|---|---|
| Employees | TierId | NUMBER | Links employee to their wage category tier |
| Employees | EmployeeHistoryId | VARCHAR2(50) | Tracks an employee across multiple contract periods |
| Employees | CurrentEngagementId | NUMBER | Which EmployeeEngagements row is currently active |
| EmployeeEngagements | TierId | NUMBER | Which tier this engagement belongs to |
| ContractPeriods | TierId | NUMBER | Which tier this contract period belongs to |
| Notices | NoticeText | NCLOB | The rich-text body content of a notice |
| Notices | Category | VARCHAR2(100) | Notice category label |
| Notices | MainCategoryId | NUMBER | Links notice to a MainCategory |
| AttendanceRemarks | MainCategoryId | NUMBER | Which category a remark belongs to |
| MainCategory | AdminPCNO | VARCHAR2(50) | The PCNO of the admin who owns this category |
| MainCategory | EditDaysAllowed | NUMBER | How many days back a POC can edit attendance |
| MainCategory | EditMode | NUMBER(1) | Edit window type (0 = rolling days, 1 = fixed period) |
| MainCategory | ViewMode | NUMBER | POC view restriction type (0=none, 1=current month, 2=last N months, 3=active contract, 4=from cutoff) |
| MainCategory | ViewMonthsAllowed | NUMBER | For ViewMode=2: how many months back a POC can view |
| MainCategory | ViewCutoffDate | DATE | For ViewMode=4: the fixed date from which POC can view |
| MainCategory | ViewAppliesTo | NUMBER(1) | 0=both Attendance+Ledger, 1=Attendance only, 2=Ledger only |
| AppUsers | Name | VARCHAR2(100) | Stored display name for the user |

**Tables it creates if missing:**
- `UserDivisions` — maps POC users (by PCNO) to division names they can access
- `NoticeReads` — tracks which notices each user has read (to show unread count)
- `AttendanceDraft` — attendance entries submitted by Sub Users, pending POC approval
- `SubUserAnchor` — links Sub Users to their anchor POC(s)

**Indexes it creates (22 total). Selected examples:**

| Index | Table | Columns | Purpose |
|---|---|---|---|
| IDX_ATT_YEAR_MONTH | Attendance | Year, Month, StatusValue, EmpID | Fast monthly attendance queries |
| IDX_ATT_EMP_DATE | Attendance | EmpID, Year, Month | Fast per-employee date lookups |
| IDX_EMP_TIER_STATUS | Employees | TierId, Status | Filter employees by category and status |
| IDX_CP_TIER_STATUS | ContractPeriods | TierId, Status, StartDate, EndDate | Find active contract periods by tier |
| IDX_USERTIERS_PCNO | UserTiers | PCNO, TierId | Fast POC tier access checks |
| IDX_CATSHARE_SHARED | CategoryShareGrant | SharedWithPCNO, IsActive | Fast Secondary Admin permission checks |
| IDX_LEAVECRED_EMP | EmployeeLeaveCredits | EmpID, ContractPeriodId, EffectiveDate | Ledger leave balance queries |

**Sequence cache tuning:** Ensures all 14 Oracle sequences have `CACHE 20`. An Oracle sequence without caching does a disk I/O on every `NEXTVAL` call. With `CACHE 20`, Oracle pre-allocates 20 IDs in memory at once. Under 100+ concurrent users, this makes a measurable difference.

**Purges stale draft records on first run:**
```sql
DELETE FROM AttendanceDraft d
WHERE d.IsHoliday = 1
   OR (d.StatusValue IS NULL AND (d.LeaveType IS NULL OR TRIM(d.LeaveType) = '')
       AND (d.Remarks IS NULL OR TRIM(d.Remarks) = ''))
   OR EXISTS (
       SELECT 1 FROM Attendance a
       WHERE a.EmpID = d.EmpID AND a.Year = d.Year AND a.Month = d.Month AND a.Day = d.Day
         AND (a.StatusValue IS NOT NULL OR a.IsHoliday = 1 OR ...)
   )
```
Cleans out: holiday drafts (holidays are auto-populated, not drafted), blank/empty drafts, and drafts that have already been approved and committed to the Attendance table.

---

### `EnsureColumnExists(conn, tableName, columnName, alterSql)`

```csharp
private static void EnsureColumnExists(OracleConnection conn, string tableName, string columnName, string alterSql)
```

Queries `USER_TAB_COLUMNS` — Oracle's system view that lists all columns across all tables in the current user's schema. If the column is absent, runs the provided `ALTER TABLE ... ADD (...)` SQL. Errors are caught silently: logged to `Debug.WriteLine` but never thrown.

---

### `EnsureTableExists(conn, tableName, createTableSql)`

```csharp
private static void EnsureTableExists(OracleConnection conn, string tableName, string createTableSql)
```

Queries `USER_TABLES` — Oracle's system view of all tables in the current schema. If the table is missing, runs the `CREATE TABLE` SQL.

---

### `EnsureIndexExists(conn, indexName, createIndexSql)`

```csharp
private static void EnsureIndexExists(OracleConnection conn, string indexName, string createIndexSql)
```

Queries `USER_INDEXES`. If the index does not exist, runs `CREATE INDEX`. Two specific Oracle errors are silently ignored:
- `ORA-01408` — another index on the same column(s) already exists
- `ORA-00955` — an object with the same name already exists
Both are harmless: the index already exists in some form.

---

### `EnsureSequenceCache(conn, seqName, cacheSize = 20)`

```csharp
private static void EnsureSequenceCache(OracleConnection conn, string seqName, int cacheSize = 20)
```

Queries `USER_SEQUENCES` for the current `CACHE_SIZE` of a sequence. If it is less than 20, runs `ALTER SEQUENCE ... CACHE 20`. Applied to all 14 sequences in the app to prevent ID-generation bottlenecks under concurrent load.

---

### `EnsureAppUsersCompositePrimaryKey(conn)` — Migrate AppUsers for multi-role support

```csharp
private static void EnsureAppUsersCompositePrimaryKey(OracleConnection conn)
```

**Background:** Originally `AppUsers` had a single-column primary key on `PCNO` only, meaning one user could only have one role. When multi-role support was added (a person can simultaneously be a POC and a Sub User, for example), the design changed: `AppUsers` can have multiple rows per PCNO — one per role. So the PK needed to become `(PCNO, Role)` combined.

**What it does:**
1. Queries `USER_CONSTRAINTS` to check if the current PK covers only one column
2. If yes (old schema): drops the old single-column PK using `CASCADE` — this also drops any foreign key constraints referencing it from other tables
3. Deduplicates any `(PCNO, Role)` pairs that may have ended up with duplicate rows
4. Creates the new composite PK: `ALTER TABLE AppUsers ADD PRIMARY KEY (PCNO, Role)`

---

### `EnsureAppUsersRoleConstraint(conn)` — Expand allowed Role values to 0-7

```csharp
public static void EnsureAppUsersRoleConstraint(OracleConnection conn)
```

The `AppUsers.Role` column has a `CHECK` constraint limiting which values are valid. The original constraint only allowed 0-3. As roles 4 (SuperAdmin), 5 (Revoked SuperAdmin), 6 (SubUser), and 7 (Revoked SubUser) were added, the constraint needed updating.

**Steps:**
1. Drops known named constraints by name (`CHK_APPUSERS_ROLE`, `SYS_C009993`, etc.)
2. Dynamically queries `USER_CONSTRAINTS` for any remaining CHECK or system-generated constraints on AppUsers and drops them
3. Ensures `PCNO VARCHAR2(50) NOT NULL` and `Role NUMBER(1) NOT NULL` constraints are set
4. Adds the expanded CHECK: `Role IN (0, 1, 2, 3, 4, 5, 6, 7)`

---

## Section 5: Division Sync — Keeping Divisions in Sync with HR Data

The application needs to know what company divisions exist (e.g. "D-CES", "D-MWES") for employee assignment, user permission filters, and dropdowns. This data comes from the company HR Oracle database (`hrdata.empdetails`). Since querying the HR DB on every page is slow, the data is cached locally in an AttendanceDB table called `Divisions`.

---

### `EnsureDivisionsTableExists()` — Creates the Divisions table if missing

```csharp
public static void EnsureDivisionsTableExists()
```

If the `Divisions` table does not exist in AttendanceDB:
1. Creates it: `Divisions (Id NUMBER PRIMARY KEY, Name VARCHAR2(100) NOT NULL UNIQUE)`
2. Creates `SEQ_Divisions` sequence for auto-incrementing IDs
3. Creates trigger `TRG_Divisions` — fires before each INSERT; if `Id` is NULL, assigns `SEQ_Divisions.NEXTVAL` automatically

Uses `_divisionsTableEnsured` static flag (with lock) — the actual work happens only once per app lifetime.

---

### `EnsureDivisionExists(string dept)` — Ensure one division name exists locally

```csharp
public static void EnsureDivisionExists(string dept)
```

Called when saving an employee record. Ensures the employee's `Department` value has a matching entry in the local `Divisions` table. If not found, inserts it. This is non-fatal — if it fails, the employee save still proceeds.

---

### `SyncCompanyDivisions(bool force = false)` — Full HR-to-local sync

```csharp
public static void SyncCompanyDivisions(bool force = false)
```

**Throttled:** At most once every 15 minutes, enforced by `_lastDivSyncTime` and `_divSyncLock`.

**Step 1:** Ensure `DivId` columns exist on `UserDivisions`, `Employees`, and `EmployeeEngagements` tables — these foreign-key-style columns link each record to the canonical division by numeric ID instead of just a name string.

**Step 2: Safe schema probe of the HR database**
```sql
SELECT * FROM hrdata.empdetails WHERE 1=0
```
`WHERE 1=0` returns zero rows but the DataAdapter fills the column schema into a DataTable. This lets the code detect whether `DIVID` and `DIVSTATUS` columns exist in this version of the HR system without throwing exceptions. Different server installations may have different HR DB schema versions.

**Step 3:** Build the division query dynamically based on what columns exist:
```sql
SELECT DISTINCT
    [divid AS id,]                    -- only if DIVID column exists
    CASE
        WHEN INSTR(divname, '/', 1, 1) <> 0
        THEN SUBSTR(divname, 1, INSTR(divname, '/', 1, 1) - 1)
        ELSE divname
    END AS name
FROM hrdata.empdetails
WHERE divname IS NOT NULL AND divname != '*'
  [AND divstatus = 'Y']               -- only if DIVSTATUS column exists
ORDER BY name ASC
```
The `CASE` expression strips everything from the first `/` onwards. For example: "D-CES/AVIONICS" becomes "D-CES", "D-MWES/GROUP-A" becomes "D-MWES".

**Step 4:** For each division from HR, upsert into the local `Divisions` table using Oracle's `MERGE INTO ... USING DUAL`:
```sql
MERGE INTO Divisions d
USING (SELECT :Id AS Id, :Name AS Name FROM DUAL) s
ON (d.Id = s.Id)
WHEN MATCHED THEN UPDATE SET d.Name = s.Name WHERE d.Name <> s.Name
WHEN NOT MATCHED THEN INSERT (Id, Name) VALUES (s.Id, s.Name)
```
`USING ... FROM DUAL` is an Oracle technique to provide a single-row "virtual table" for the MERGE source.

**Step 5: Backfill DivId foreign key columns** only if null values exist (checked first with `ROWNUM <= 1` for performance). Updates by matching name case-insensitively, including the `Name/%` prefix pattern.

---

### `GetCompanyDivisionsDataTable()` — Get all divisions for dropdown lists

```csharp
public static DataTable GetCompanyDivisionsDataTable()
```

Used by pages that need to show a list of divisions in dropdowns (Employee Master, Admin Management, Settings).

**Three-tier fallback strategy:**

1. **Fast path (normal case):** Read from local `Divisions` table. If it has rows, return immediately. If 15+ minutes have elapsed since last sync, queue a background sync (non-blocking — does not delay the page).

2. **Local table is empty:** Run `SyncCompanyDivisions(force: true)` synchronously to populate it, then read from local table.

3. **Both local table and sync failed:** Fall back to querying `hrdata.empdetails` in the Company HR DB directly. If that also fails, return an empty DataTable with the correct `Id` and `Name` columns so callers do not crash on a missing column.

This design ensures the page always gets a list of divisions no matter what.

---

## Section 6: Tier/Category Visibility

Tiers are wage categories (e.g. "Skilled", "Semi-Skilled"). They belong to a `MainCategory` (e.g. "LRDE Skilled Workers"). These methods decide which tiers a given user can see based on their role.

---

### `GetVisibleTiersDataTable(string pcno, int role)` — Which tiers can this user access?

```csharp
public static DataTable GetVisibleTiersDataTable(string pcno, int role)
```

**Returns:** DataTable with two columns:
- `TierId` — the numeric ID of the tier
- `DisplayName` — formatted as `"MainCategory › TierName (#RoleLabel)"` — shown in dropdowns

**Request-level caching:** Uses `HttpContext.Current.Items` as a cache key-value store that exists only for the current HTTP request. If this method is called multiple times in one page load, the second call returns the cached result instantly without a database round-trip. The cache is automatically discarded when the request ends.

**Role-based query logic:**

| User Type | What They See |
|---|---|
| Super Admin (role = 4) | ALL tiers in the system, no filter |
| Primary Admin (role=1, RoleMode="PrimaryAdmin") | Tiers belonging to categories where `MainCategory.AdminPCNO = :PCNO` |
| Secondary Admin (role=1, RoleMode="SecondaryAdmin") | Tiers granted via `CategoryShareGrant` — either whole-category grants (`TierId IS NULL`) or specific individual tier grants (`TierId IS NOT NULL`) |
| Any other Admin (role=1) | Union of Primary + Secondary (both sets combined) |
| Regular User / POC / Sub User | Only tiers in `UserTiers` table where `PCNO = :PCNO` — explicitly assigned |

The `DisplayName` is built with Oracle's `NVL2` function:
```sql
mc.Name || ' > ' || t.TierName || NVL2(t.RoleLabel, ' (#' || t.RoleLabel || ')', '')
```
`NVL2(expr, value_if_not_null, value_if_null)` — if `RoleLabel` has a value, append `" (#RoleLabel)"`. If it is null, append nothing.

---

### `GetVisibleTierIds(string pcno, int role)` — Just the ID list

```csharp
public static List<int> GetVisibleTierIds(string pcno, int role)
```

Wraps `GetVisibleTiersDataTable` and extracts only the `TierId` integers into a `List<int>`. Also cached per request. Used in WHERE clauses to filter database queries to only the tiers a user is allowed to see, e.g.:
```sql
WHERE ee.TierId IN (1, 3, 7)  -- only the visible tier IDs
```

---

## Section 7: Holiday Backfill

When a holiday is declared in the system, an attendance record with `IsHoliday = 1` is created. But employees hired after the holiday was created also need that record. These methods handle the backfill.

---

### `BackfillHolidaysForEmployee(string masterId)` — Add existing holidays for one new employee

```csharp
public static void BackfillHolidaysForEmployee(string masterId)
```

Called from the Employee page when a new employee is registered.

**What it inserts:** For every holiday already in the system, if:
1. The holiday date falls within the employee's engagement period (between `ee.StartDate` and `ee.EndDate`)
2. The employee does not already have an attendance record for that date

Then it inserts a row: `(EmpID, Year, Month, Day, StatusValue=NULL, IsHoliday=1, LeaveType='', AutoSat=0, Remarks)`.

**Important date arithmetic note:**
```sql
TO_DATE(h.Year || '-' || (h.Month + 1) || '-' || h.Day, 'YYYY-MM-DD')
```
`Month + 1` is needed because the app stores months as 0-indexed (0 = January, 11 = December) but Oracle's `TO_DATE` with format `'YYYY-MM-DD'` expects 1-indexed months (1 = January, 12 = December).

Skips any `MasterId` starting with "GLOBAL" — those are special system-level entries used to store global holiday declarations, not real employee records.

---

### `BackfillHolidaysForAllEmployees()` — Bulk holiday backfill for all employees

```csharp
public static void BackfillHolidaysForAllEmployees()
```

Same logic as above but done in a single SQL statement using `CROSS JOIN` — joining every employee with every holiday, then filtering with `WHERE EXISTS` and `WHERE NOT EXISTS` to insert only the needed combinations. Called from the Attendance page when an admin marks a new public holiday, so that all employees automatically get the holiday record for that day.

---

## Section 8: Role Management

---

### `SwitchUserRole(string pcno, string targetMode, HttpSessionState session)` — Change active role mid-session

```csharp
public static bool SwitchUserRole(string pcno, string targetMode, System.Web.SessionState.HttpSessionState session)
```

Called by `Site.Master.cs` when it detects a `?switchRole=` query parameter in the URL. See `02_SiteMaster.md` for the full flow of how this is triggered.

**Step-by-step:**
1. Calls `GetAvailableUserRoles(pcno)` to get all roles this user can use (fresh from DB)
2. Searches the list for a role matching `targetMode` (e.g. `"SubUser"`, `"PrimaryAdmin"`)
3. If not found: returns `false` — the caller (Site.Master) does nothing
4. If found:
   - Sets `session["Role"]` = `selectedRole.EffectiveRole` (the numeric role number)
   - Sets `session["RoleMode"]` = `selectedRole.RoleMode` (the string mode)
   - Sets `session["UserRoles"]` = the full role list (for later use in Site.Master)
5. For non-admin roles: loads `AllowedDivisions` from `UserDivisions WHERE PCNO = :PCNO` and sets `session["Division"]` and `session["AllowedDivisions"]`. If no divisions found, defaults to `"D-USER"` as a fallback.
6. For admin/super-admin: sets `session["Division"]` to `"D-SUPERADMIN"` or `"D-ADMIN"` (these are convention values, not real divisions)
7. Returns `true` — Site.Master will redirect to the same page without the `?switchRole=` parameter

---

## Section 9: POC View Restriction

This feature is configured by the admin through the **Settings page**. It controls how far back in history a POC (Regular User) can view attendance records and ledger data for their assigned employees.

---

### `GetPocViewRestriction(string pcno, string targetPage, string categoryFilter)` — What date range can this POC access?

```csharp
public static PocViewRestrictionInfo GetPocViewRestriction(
    string pcno,
    string targetPage = "Attendance",
    string categoryFilter = null)
```

**Called by:** `Attendance.aspx.cs` and `Ledger.aspx.cs` to enforce month visibility limits for POC users. Admins and Super Admins always bypass this — the restriction is POC-only.

**Request-level caching** — cached in `HttpContext.Current.Items` with a key that includes `pcno`, `targetPage`, and `categoryFilter`.

**Step 1:** Query all `MainCategory` records the PCNO has access to, including through Sub User anchors:
```sql
SELECT DISTINCT mc.Id, mc.Name, mc.ViewMode, mc.ViewMonthsAllowed, mc.ViewCutoffDate, mc.ViewAppliesTo
FROM UserTiers ut
JOIN Tiers t ON ut.TierId = t.Id
JOIN MainCategory mc ON t.MainCategoryId = mc.Id
WHERE ut.PCNO = :PCNO
   OR ut.PCNO IN (SELECT AnchorPocPCNO FROM SubUserAnchor WHERE SubUserPCNO = :PCNO)
```
The second `OR` clause includes categories that are accessible to this user because they are a Sub User anchored to a POC who has those categories.

**Step 2: Optionally filter by category** — if `categoryFilter` is provided (e.g. the page is only showing one specific category), the query adds a `WHERE mc.Id = :CatId OR mc.Name = :CatName` condition.

**Step 3: Check which page this restriction applies to** using `ViewAppliesTo`:
- `0` = restriction applies to both Attendance and Ledger
- `1` = restriction applies to Attendance page only
- `2` = restriction applies to Ledger page only
If the restriction does not apply to the `targetPage`, it is skipped.

**Step 4: Compute the allowed date range for each applicable category based on `ViewMode`:**

| ViewMode | What It Means | Min Allowed Date | Max Allowed Date |
|---|---|---|---|
| 0 | No restriction | None (unlimited past) | None (unlimited future) |
| 1 | Current month only | 1st of current month | Last day of current month |
| 2 | Last N months | 1st of (current month minus N-1 months) | Last day of current month |
| 3 | Active contract period | Start of the active contract | End of the active contract |
| 4 | From a specific cutoff date onwards | 1st of the configured cutoff month | None (unlimited future) |

**ViewMode 3 in detail:** When the mode is "Active Contract Period", the method runs an extra query:
```sql
SELECT MIN(cp.StartDate) AS MinStart, MAX(cp.EndDate) AS MaxEnd
FROM ContractPeriods cp
JOIN Tiers t ON cp.TierId = t.Id
WHERE t.MainCategoryId = :CatId
  AND cp.Status = 'Active'
  AND cp.StartDate <= :Today AND (cp.EndDate IS NULL OR cp.EndDate >= :Today)
```
This finds the date span of the currently active contract period for this category.

**Step 5: Merge boundaries across multiple categories**
If a POC has access to more than one category, each may have a different restriction. The final boundary is the **most expansive (widest) union** of all category ranges:
- `MinAllowedDate` = the EARLIEST minimum across all categories
- `MaxAllowedDate` = the LATEST maximum across all categories

This is generous by design: if even one of the POC's categories allows a month, the POC can view that month.

**Step 6:** Caches the `PocViewRestrictionInfo` result in `HttpContext.Current.Items` and returns it.

---

### `PocViewRestrictionInfo` — The result data class

```csharp
[Serializable]
public class PocViewRestrictionInfo
{
    public bool IsRestricted { get; set; }         // false = no restriction applies at all
    public int ViewMode { get; set; }              // 0-4, the restriction type
    public int ViewMonthsAllowed { get; set; }     // For Mode 2: how many months back
    public DateTime? ViewCutoffDate { get; set; }  // For Mode 4: the specific cutoff date
    public int ViewAppliesTo { get; set; }         // 0=both, 1=Attendance only, 2=Ledger only
    public DateTime? MinAllowedDate { get; set; }  // Earliest date the POC can view (null = no limit)
    public DateTime? MaxAllowedDate { get; set; }  // Latest date the POC can view (null = no limit)
    public string Description { get; set; }        // Human-readable label shown in the UI
}
```

Marked `[Serializable]` because ASP.NET Session may serialize objects to disk or a database depending on the session state provider configuration.

**The `IsMonthAllowed(int year, int month1Based)` method:**

```csharp
public bool IsMonthAllowed(int year, int month1Based)
{
    if (!IsRestricted) return true;   // No restriction — always allow

    DateTime monthStart = new DateTime(year, month1Based, 1);
    DateTime monthEnd   = new DateTime(year, month1Based, DateTime.DaysInMonth(year, month1Based));

    // The entire month must not end before the allowed window starts
    if (MinAllowedDate.HasValue && monthEnd < MinAllowedDate.Value)
        return false;

    // The entire month must not start after the allowed window ends
    if (MaxAllowedDate.HasValue && monthStart > MaxAllowedDate.Value)
        return false;

    return true;
}
```

Note: `month1Based` means the month parameter is 1-indexed (January = 1). This is the standard .NET `DateTime` convention. Called in `Attendance.aspx.cs` and `Ledger.aspx.cs` for every month in the month-picker dropdown to decide whether to show or hide it for the current POC user.

---

### `UserRoleOption` — The role data class

```csharp
[Serializable]
public class UserRoleOption
{
    public string RoleMode { get; set; }    // Internal key: "PrimaryAdmin", "RegularUser", "SubUser", "SuperAdmin"
    public string Title { get; set; }       // Display title shown in the role-switcher tile, e.g. "Primary Category Admin"
    public string Subtitle { get; set; }    // Subtitle shown below the title, e.g. "Category Owner for Skilled Workers"
    public int EffectiveRole { get; set; }  // The numeric Role value stored in Session["Role"] (0, 1, 4, or 6)
    public string Icon { get; set; }        // FontAwesome icon CSS class for the tile avatar, e.g. "fas fa-user-shield"
    public string BadgeColor { get; set; }  // Hex color string for the avatar background, e.g. "#4f46e5"
}
```

`[Serializable]` for the same reason as `PocViewRestrictionInfo` — stored in Session.

---

## Summary: Full Method Reference

| Method | Access | Returns | Purpose |
|---|---|---|---|
| `GetCompanyDBConnection()` | public | string | HR database connection string |
| `GetAttendanceDBConnection()` | public | string | App database connection string |
| `ExecuteQuery(...)` | public | DataTable | Run SELECT query |
| `ExecuteNonQuery(...)` | public | int | Run INSERT/UPDATE/DELETE |
| `ExecuteScalar(...)` | public | object | Run query, get single value |
| `RunWithRetry<T>(...)` | private | T | Retry wrapper (3 attempts, exponential backoff) |
| `IsTransientError(...)` | private | bool | Should this error be retried? |
| `CloneParameters(...)` | private | OracleParameter[] | Clone params for retry safety |
| `AutoCloseExpiredContracts(...)` | public | void | Close all contracts past EndDate |
| `TriggerAutoCloseIfNeeded()` | public | void | Throttled trigger (every 30 min) |
| `EnsureSchema()` | public | void | Auto-add missing columns/tables/indexes |
| `EnsureColumnExists(...)` | private | void | Add a column if missing |
| `EnsureTableExists(...)` | private | void | Create a table if missing |
| `EnsureIndexExists(...)` | private | void | Create an index if missing |
| `EnsureSequenceCache(...)` | private | void | Ensure sequences have CACHE 20 |
| `EnsureAppUsersCompositePrimaryKey(...)` | private | void | Upgrade AppUsers PK to (PCNO, Role) |
| `EnsureAppUsersRoleConstraint(...)` | public | void | Expand Role CHECK constraint to 0-7 |
| `EnsureDivisionsTableExists()` | public | void | Create Divisions table if missing |
| `EnsureDivisionExists(...)` | public | void | Ensure one division name is in the table |
| `SyncCompanyDivisions(...)` | public | void | Sync divisions from HR DB (throttled 15 min) |
| `GetCompanyDivisionsDataTable()` | public | DataTable | Get all divisions with 3-tier fallback |
| `GetVisibleTiersDataTable(...)` | public | DataTable | Tiers visible to user (role-scoped, request-cached) |
| `GetVisibleTierIds(...)` | public | List<int> | Tier IDs visible to user (request-cached) |
| `BackfillHolidaysForEmployee(...)` | public | void | Add all existing holidays for one new employee |
| `BackfillHolidaysForAllEmployees()` | public | void | Bulk-add all missing holidays for all employees |
| `GetAvailableUserRoles(...)` | public | List<UserRoleOption> | All roles a PCNO can use (see Login doc) |
| `SwitchUserRole(...)` | public | bool | Change active role in session |
| `GetPocViewRestriction(...)` | public | PocViewRestrictionInfo | Date range restriction for a POC user |

---

## Key Design Patterns in DBHelper

**1. Static class, no instances**
All methods are `static`. You never write `new DBHelper()`. Call `DBHelper.ExecuteQuery(...)` directly. This is correct because DBHelper holds no per-request state — it just provides utility functions.

**2. Double-checked locking**
For one-time startup operations:
```csharp
if (flag) return;           // Fast path: 99.9% of requests skip here with no lock overhead
lock (lockObj) {
    if (flag) return;       // Re-check inside lock: prevents race between two threads that
                            // both passed the outer check at the same millisecond
    // Do the one-time work
    flag = true;
}
```

**3. Request-level caching via HttpContext.Current.Items**
`GetVisibleTiersDataTable` and `GetPocViewRestriction` use `HttpContext.Current.Items`, a dictionary attached to the current HTTP request. Perfect for methods that might be called multiple times per page load — the expensive DB call only happens once.

**4. `params OracleParameter[]` for flexible method signatures**
```csharp
// No parameters
DBHelper.ExecuteQuery(conn, "SELECT * FROM Employees");

// One parameter
DBHelper.ExecuteQuery(conn, "SELECT * FROM Employees WHERE MasterId = :Id",
    new OracleParameter("Id", "10047"));

// Multiple parameters
DBHelper.ExecuteQuery(conn, "SELECT * FROM Employees WHERE Dept = :D AND Status = :S",
    new OracleParameter("D", "D-CES"),
    new OracleParameter("S", "Active"));
```

**5. Graceful degradation everywhere**
Nearly every maintenance method (EnsureSchema, SyncCompanyDivisions, AutoCloseExpiredContracts) has `try/catch` at multiple levels. Errors are written to `System.Diagnostics.Debug.WriteLine` (visible in Visual Studio Output window during development) but never bubble up to crash the user's page. Background tasks are optional enhancements — the core page functionality must always work even if they fail.

---

*Next: See `04_Dashboard.md` for the Dashboard page — the landing page every user sees after login.*
