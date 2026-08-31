# Chapter 02: Core Utilities, Data Layer & Authentication Engine

This document provides a comprehensive technical breakdown of the foundational utilities in `AttendanceApp.Utils`:
1. [ADHelper.cs](file:///e:/attendence/Utils/ADHelper.cs) – Active Directory & LDAP Authentication
2. [ActionLogger.cs](file:///e:/attendence/Utils/ActionLogger.cs) – Reversible JSON Audit Logging & State Snapshots
3. [DBHelper.cs](file:///e:/attendence/Utils/DBHelper.cs) – Central Data Access Layer, Connection Pooling & Background Engine

---

## 1. ADHelper.cs (Active Directory / LDAP Authentication)

### Purpose & Architectural Role
`ADHelper` connects the application to corporate Microsoft Active Directory domain controllers using the `System.DirectoryServices` LDAP provider. It authenticates enterprise credentials and resolves the user's primary personnel computer number (`PCNO` / `EmployeeID`).

```
           [User Inputs: Username & Password]
                           |
                           v
              ADHelper.AuthenticateAndGetPCNO
                           |
            +--------------+--------------+
            |                             |
      (Local Bypass)               (LDAP Bind)
      User in [1001-1004]     DirectoryEntry(ldapPath)
            |                   .NativeObject (Auth)
            |                             |
            |                 DirectorySearcher Filter
            |                 (SAMAccountName={username})
            |                             |
            v                             v
       Return PCNO               Extract EmployeeID
```

### Method Signature & Implementation Details

#### `AuthenticateAndGetPCNO(string username, string password)`
- **Parameters:**
  - `username` (`string`): AD account login username (e.g. `"john.doe"`, `"1001"`).
  - `password` (`string`): User domain password.
- **Returns:** `string` (The user's unique `PCNO` / `EmployeeID`, e.g. `"1001"`).
- **Exceptions:** Throws `Exception` if credentials fail LDAP binding or search fails.

#### Key Mechanics:
1. **Local Test Bypass:**
   ```csharp
   if (username == "1001" || username.ToLower() == "admin" || username.ToLower() == "aadmin") return "1001";
   if (username == "1002") return "1002";
   if (username == "1003") return "1003";
   if (username == "1004") return "1004";
   ```
   *Rationale:* Permits developers to log in instantly during local workstation debugging without being connected to the corporate VPN / Domain Controller.
2. **Forced Native Authentication:**
   In .NET `DirectoryEntry`, creating the object does not hit the network until a native property is accessed. `ADHelper` forces instant authentication via:
   ```csharp
   object native = entry.NativeObject; // Forces synchronous LDAP bind
   ```
3. **Property Extraction & Fallback:**
   Queries `(SAMAccountName={username})` and loads property `"EmployeeID"`. If `EmployeeID` is not mapped in AD, it gracefully falls back to the username itself.

---

## 2. ActionLogger.cs (Undoable JSON Audit Logger)

### Purpose & Architectural Role
`ActionLogger` is a state-capturing audit mechanism for the Employee Master module. Whenever an employee is inserted, updated, extended, or deleted, `ActionLogger`:
1. Captures a full JSON snapshot of the employee master record and all historical engagement stints (`PreState`).
2. Performs the database operation.
3. Captures a full JSON snapshot of the modified state (`PostState`).
4. Allows administrators to click **Undo** on any previous action, safely rolling the employee and engagements back to the exact historical state without database corruption.

### Data Flow Diagram

```
[Employee Modification Triggered]
               |
               v
1. ActionLogger.CaptureEmployeeState(masterId) ---------> Generates PreState JSON
               |
2. Database UPDATE / INSERT / EXTEND Executed
               |
3. ActionLogger.CaptureEmployeeState(masterId) ---------> Generates PostState JSON
               |
4. ActionLogger.LogAction(type, masterId, desc, pre, post)
               |
               v
  Saved to EmployeeActionLogs (IsUndone = 0)
               |
     [User clicks "Undo Action"]
               |
               v
5. ActionLogger.UndoAction(logId, out error)
   - Checks if attendance or wage overrides exist
   - Re-inserts / updates pre-state records
   - Marks EmployeeActionLogs.IsUndone = 1 in atomic transaction
```

### Key Methods Breakdown

#### `CaptureEmployeeState(string masterId)`
- **Parameters:** `masterId` (`string`) – Employee `MasterId`.
- **Returns:** `string` (JSON string containing `{ "Employee": {...}, "Engagements": [...] }`).
- **Implementation:** Queries `Employees` and `EmployeeEngagements` (ordered by `StartDate ASC`), converts rows into dictionaries with formatted date strings (`"yyyy-MM-dd HH:mm:ss"`), and serializes them using `JavaScriptSerializer`.

#### `LogAction(string actionType, string masterId, string description, string preState, string postState)`
- **Parameters:**
  - `actionType` (`string`): e.g. `'INSERT'`, `'UPDATE'`, `'EXTEND'`, `'DELETE'`.
  - `masterId` (`string`): Target employee `MasterId`.
  - `description` (`string`): Human-readable log entry (e.g. `"Updated employee phone number and tier"`).
  - `preState` (`string`): Serialized JSON before change.
  - `postState` (`string`): Serialized JSON after change.
- **Implementation:** Inserts into `EmployeeActionLogs` with `IsUndone = 0`.

#### `UndoAction(int logId, out string errorMessage)`
- **Parameters:** `logId` (`int`), `out errorMessage` (`string`).
- **Returns:** `bool` (`true` if successfully reverted, `false` otherwise).
- **Safety Validations (Prevents Data Inconsistencies):**
  1. If `IsUndone == 1`, fails with *"This action is already undone"*.
  2. If `actionType == "BULK_LEAVE"`, blocks automated rollback (*"Bulk leave adjustments cannot be undone automatically"*).
  3. If rolling back an employee addition (`ADD`), verifies `SELECT COUNT(*) FROM Attendance WHERE EmpID = :EmpID`. If attendance records exist, blocks rollback (*"Cannot undo: attendance records already exist for this employee"*).
  4. If rolling back a contract extension / new engagement, checks if attendance or `CalculationOverrides` exist for that newly created engagement before deleting it.
  5. Atomically nullifies `Employees.CurrentEngagementId` first to bypass circular foreign key constraints during stint recreation, restores historical stint rows, restores master fields, sets `IsUndone = 1`, and commits the transaction.

---

## 3. DBHelper.cs (Data Access Layer & Background Engine)

`DBHelper` is the core data access engine of the application. It encapsulates connection management, parameterized query execution, background contract auto-closing, permission resolution, and business calculations.

### 3.1 Connection Management & Pooling
- **`GetCompanyDBConnection()`**: Reads connection string `"CompanyDB"` from `Web.config` (used for `hrdata.empdetails`).
- **`GetAttendanceDBConnection()`**: Reads connection string `"AttendanceDB"` from `Web.config` (used for all AMS application tables).

Both connection strings configure **Oracle Managed Connection Pooling**:
- `Min Pool Size=5`, `Max Pool Size=200`
- `Statement Cache Size=50` (caches compiled execution plans on Oracle server)
- `Connection Lifetime=120` seconds
- `Validate Connection=false` (avoids round-trip `SELECT 1 FROM DUAL` overhead on every connection fetch)

---

### 3.2 Automated Background Contract Closer (`AutoCloseExpiredContracts`)

```csharp
[ThreadStatic]
private static bool _inAutoClose;
private static DateTime _lastAutoCloseCheck = DateTime.MinValue;
private static readonly object _syncLock = new object();

public static void TriggerAutoCloseIfNeeded()
{
    if ((DateTime.UtcNow - _lastAutoCloseCheck).TotalSeconds < 1800) return;
    System.Threading.ThreadPool.QueueUserWorkItem(_ =>
    {
        try { AutoCloseExpiredContracts(false); } catch { }
    });
}
```

#### How It Works:
1. **Throttled Execution:** When page requests call `TriggerAutoCloseIfNeeded()`, the method checks if 30 minutes (1800s) have passed since the last run.
2. **Asynchronous Non-Blocking Execution:** Dispatches the task to the .NET `ThreadPool`, allowing the user's HTTP request to return immediately without delay.
3. **Database Transaction Routine (`AutoCloseExpiredContracts`):**
   - Finds all expired active contract periods:
     ```sql
     SELECT Id, EndDate FROM ContractPeriods WHERE Status = 'Active' AND EndDate < TRUNC(SYSDATE)
     ```
   - For each expired period:
     - Sets `ContractPeriods.Status = 'Closed'`.
     - Finds all active employee engagements under that period (`EndDate IS NULL`).
     - Updates engagements: `EndDate = :PeriodEndDate`, `EndReason = 'Contract Expired'`.
     - Updates employee master: `Status = 'Relieved'`, `ContractEndDate = :PeriodEndDate`.
   - All updates for each period execute inside an atomic `OracleTransaction`.

---

### 3.3 Core Execution Primitives

```csharp
public static DataTable ExecuteQuery(string connStr, string sql, params OracleParameter[] parameters)
public static int ExecuteNonQuery(string connStr, string sql, params OracleParameter[] parameters)
public static object ExecuteScalar(string connStr, string sql, params OracleParameter[] parameters)
```

#### Architecture Rules Enforced:
1. **Always Parameterized:** Prevents SQL injection across all inputs.
2. **Proper Disposal Pattern (`using` blocks):** Ensures `OracleConnection`, `OracleCommand`, and `OracleDataReader` instances are immediately closed and returned to the connection pool, preventing connection leaks.
3. **Named Parameter Binding:** Calls `cmd.BindByName = true;` to avoid Oracle's default positional parameter binding bugs when reusing parameters in complex SQL.

---

### 3.4 Multi-Role & Permission Resolution

#### `GetAvailableUserRoles(string pcno)`
Dynamically inspects `AppUsers`, `MainCategory`, `CategoryShareGrant`, and `UserDivisions` to produce a list of available `UserRoleOption` objects for a user.

| Evaluated Role | Condition Checked in Database | Role Code |
| :--- | :--- | :---: |
| **Super Administrator** | `Role = 4` in `AppUsers` and not revoked (`Role != 5`). | `4` |
| **Secondary Category Admin** | Active record in `CategoryShareGrant WHERE SharedWithPCNO = :PCNO AND IsActive = 1`. | `1` |
| **Primary Category Admin** | `MainCategory.AdminPCNO = :PCNO` OR explicit `Role = 1` in `AppUsers`. | `1` |
| **Regular User (POC)** | `Role = 0` in `AppUsers` OR user has divisions in `UserDivisions`. | `0` |
| **Sub User (Data Entry)** | `Role = 6` in `AppUsers` OR user has anchor mapping in `SubUserAnchor`. | `6` |

---

### 3.5 POC View & Edit Policy Resolution (`GetPocViewRestriction`)

```csharp
public static PocViewRestrictionInfo GetPocViewRestriction(string adminPcno, string pocPcno)
```

Enforces retrospective view and edit window policies configured in `MainCategory` and `Settings.aspx`:

```csharp
public class PocViewRestrictionInfo
{
    public bool IsRestricted { get; set; }
    public int ViewMode { get; set; }
    public int ViewMonthsAllowed { get; set; }
    public DateTime? ViewCutoffDate { get; set; }
    public int ViewAppliesTo { get; set; }
    public DateTime? MinAllowedDate { get; set; }
    public DateTime? MaxAllowedDate { get; set; }
    public string Description { get; set; }

    public bool IsMonthAllowed(int year, int month1Based)
    {
        if (!IsRestricted) return true;
        DateTime monthStart = new DateTime(year, month1Based, 1);
        DateTime monthEnd = new DateTime(year, month1Based, DateTime.DaysInMonth(year, month1Based));

        if (MinAllowedDate.HasValue && monthEnd < MinAllowedDate.Value) return false;
        if (MaxAllowedDate.HasValue && monthStart > MaxAllowedDate.Value) return false;
        return true;
    }
}
```

#### View Restriction Modes:
- **`ViewMode 0` (Unlimited):** POC can view all historical attendance months.
- **`ViewMode 1` (Fixed N Months):** POC can only navigate back `N` months from current date.
- **`ViewMode 2` (Strict Cutoff Date):** POC cannot view any month prior to `ViewCutoffDate`.
- **`ViewMode 3` (Combined):** Uses the most restrictive between `N` months and cutoff date.
- **`ViewMode 4` (Locked):** POC cannot view historical attendance.

---

### 3.6 Holiday Backfill Engine (`BackfillHolidaysForAllEmployees`)

```csharp
public static void BackfillHolidaysForAllEmployees(string connStr)
```
When an admin marks a global holiday (`EmpID = 'GLOBAL'` in `Attendance`), this method propagates that holiday record to all active employees whose engagement covers that date, ensuring employee wage calculations and working day totals automatically reflect declared public holidays.
