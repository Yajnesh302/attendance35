# Attendance Recording System (ARS) — Comprehensive Summary of Enhancements & Changes

**Document Date:** August 28, 2026  
**System Name:** Attendance Recording System (Skilled, Semi-Skilled) [ARS]  
**Target Solution:** `AttendanceApp.sln` (.NET Framework 4.8 / Oracle Managed ODP.NET / Vanilla JS & Bootstrap)

---

## Executive Summary

Today's work introduced significant functional enhancements, database schema extensions, and UX refinements to support **Sub Users (Data Entry Operators)**, **Draft-to-Live Attendance Staging**, **Multi-Role Switching Architecture**, **Strict Cell Editing Protections**, and **Complete System Rebranding to ARS (Skilled, Semi-Skilled)**.

This document details:
1. **Business Requirements & Objectives**
2. **Database Schema & Constraint Upgrades**
3. **Core Architectural & Logic Changes**
4. **Bug Fixes & System Stability Improvements**
5. **UI / UX Redesign & Rebranding**
6. **Detailed File Modification Matrix**

---

## 1. Requirements & Problem Statements

### Requirement 1: Sub User (Data Entry Operator) Role & Workflow
* **Objective:** Allow designated data entry operators (Sub Users) linked to a Point of Contact (Anchor POC) to enter and edit monthly attendance without directly altering live production records.
* **Workflow:**
  1. Sub Users enter attendance in a temporary **Draft** state (`AttendanceDraft` table).
  2. Sub Users can save drafts freely, but are strictly prohibited from modifying cells that have already been finalized/submitted live to production.
  3. The Anchor POC (or Admin) reviews drafts with visual draft indicators and commits them to live attendance via a one-click **"Submit Live"** action.
  4. Edit reason audits are captured for draft modifications and review changes (`AttPocEditRemarks` table).

### Requirement 2: Submit Button Cleanup for Admins & Super Admins
* **Problem:** Super Admins and Admins previously saw a "Submit Attendance" draft button, which is unnecessary and confusing because Administrators edit production live attendance directly.
* **Solution:** Hide the Submit Draft button for Admin (Role 1) and Super Admin (Role 4), displaying it exclusively for Regular Users / POCs (Role 0) who have pending drafts to merge.

### Requirement 3: Multi-Role Switching Architecture & UI Cleanup
* **Problem:** Users with multiple assigned roles (e.g., Primary Admin + POC, or POC + Sub User) had duplicate, clashing "Active Mode" role switchers on both the Dashboard and the top navigation bar. The dashboard buttons used postback triggers that broke state, and the dropdown menu text had low contrast on hover.
* **Solution:**
  - Removed duplicate switcher widgets from `Dashboard.aspx`.
  - Created a centralized URL-driven session engine (`DBHelper.SwitchUserRole()`).
  - Redesigned the topbar dropdown with dedicated high-contrast styles (`.topbar-role-dropdown`, `.topbar-role-item`) for light, hover, active, and dark modes.

### Requirement 4: Live-Cell Editing Protection for Sub Users
* **Problem:** When a Sub User opened an employee whose attendance was partially entered and saved live, typing into an empty cell caused existing live cells in that row to become editable due to DOM re-rendering.
* **Solution:** Embedded live-submitted state checks directly inside `getCellState()`, ensuring that any row re-render dynamically preserves `readonly` locks on all live-submitted cells.

### Requirement 5: Oracle Constraint & Deserialization Errors
* **Problems:**
  - Creating sub users caused `ORA-02290: check constraint (SYSTEM.SYS_C009993) violated` because legacy constraints restricted `AppUsers.Role` to values `0..5`.
  - Submitting drafts caused `Error submitting attendance drafts` due to missing WebMethod parameters and Oracle's 1000-element `IN (...)` limit.
* **Solutions:**
  - Dynamically removed outdated check constraints and expanded `AppUsers.Role` constraint to `Role IN (0, 1, 2, 3, 4, 5, 6, 7)`.
  - Fixed AJAX payload parameter binding and added 900-element batch chunking for Oracle SQL queries.

### Requirement 6: Toast Notification & Loading Overlay Polish
* **Problems:**
  - Saving attendance displayed duplicate "Saved Successfully" toasts.
  - Saving attendance displayed a redundant "Loading Attendance Data..." overlay immediately after "Saving Attendance Data...".
  - Sub Users were prompted to "Switch to POC mode" upon saving drafts, which is invalid when the Sub User and POC are different individuals.
* **Solutions:**
  - Removed redundant `showPop()` double-calls and added 1.5s debounce deduplication in `showToast()`.
  - Removed redundant post-save `fetchData()` network calls and added silent mode flags (`fetchData(true)`).
  - Simplified Sub User draft save confirmation to `"Draft Saved Successfully"`.

### Requirement 7: Login Role Selection Tile Redesign
* **Problem:** When logging in with multiple roles, the role selection panel was vertically cramped, stacked on top of the login header, and pinched text into narrow columns.
* **Solution:** Replaced cramped button cards with modern, full-width interactive tiles (`.role-selection-tile`) with smooth hover micro-animations and unified single-header layout.

### Requirement 8: System Rebranding to ARS
* **Requirement:** Update all system titles and acronyms from **MSAS (Manpower Services Attendance System)** to **ARS (Attendance Recording System (Skilled, Semi-Skilled))**.
* **Applied To:** `Login.aspx`, `Site.Master`, `Dashboard.aspx`.

### Requirement 10: POC Empty Box Entry Restriction & Sub User Workflow Enforcement
* **Requirement:** Regular Users (POCs) should not be able to type initial data into empty boxes on the attendance grid. Empty cells are strictly reserved for Sub Users (Data Entry Operators). If a POC needs to enter brand new attendance, they must switch to the Sub User role (or have their Sub User enter it) and save as draft. Once data is entered (either in draft or the main table), the POC can review and edit that data in POC mode along with mandatory edit remarks.
* **Solution:**
  - In `Attendance.aspx` `getCellState()`, detected empty cells for POCs in POC mode (`isPocMode && !hasEnteredVal && !cell.Holiday`) and set `isReadonlyCell = true` with dashed border styling and a descriptive tooltip (`"Empty box: Initial data entry must be done by Sub User. Switch to Sub User role to enter data."`).
  - In `Attendance.aspx` `setVal()`, blocked attempts to edit empty cells by POCs with an informative warning toast prompt.
  - Allowed POCs to freely click and edit non-empty cells (drafts or live records), triggering the mandatory POC edit reason prompt modal (`Swal.fire`).
### Requirement 11: Main Live Table Precedence & Admin Draft Purge
* **Problem:** If a Sub User entered attendance into draft, and then an Admin logged in and entered/saved attendance directly for the same employee/cell, subsequent page loads by Sub User or POC loaded the stale draft from `AttendanceDraft`, overriding the Admin's saved live record.
* **Solution:**
  - In `Attendance.aspx.cs` `GetData()`, added live record precedence detection (`hasLiveRecord`). If the main live `Attendance` table already contains a saved value (`Val != null`, `Holiday == true`, or `Leave`), any draft row for that cell in `AttendanceDraft` is completely ignored and live data always wins.
  - In `Attendance.aspx.cs` `SaveData()`, ensured Admin saves (`role == 1 || role == 4`) always write directly to the live `Attendance` table and automatically execute `DELETE FROM AttendanceDraft WHERE EmpID = :EmpID AND Year = :Year AND Month = :Month AND Day = :Day` to purge any conflicting unsubmitted draft for that cell.
  - In `Utils/DBHelper.cs` `EnsureSchema()`, added an automated startup query purging any stale draft records where a live attendance record already exists.

---

## 2. Database Schema & Infrastructure Upgrades

### 2.1 Role Expansion in `AppUsers`
- **Role 6**: `Sub User (Active)` — linked to an Anchor POC.
- **Role 7**: `Sub User (Revoked)`.
- **Anchor POC Linkage**: `AnchorPocPCNO` and `AllowedDivisions` columns store the operational scope of each Sub User.
- **Dynamic Constraint Normalization**: `DBHelper.EnsureAppUsersRoleConstraint()` automatically purges legacy constraint names (`SYS_C009993`, etc.) and enforces `Role IN (0, 1, 2, 3, 4, 5, 6, 7)`.

### 2.2 Table: `AttendanceDraft`
Stores staged attendance records before approval:
```sql
CREATE TABLE AttendanceDraft (
    EmpID           VARCHAR2(50) NOT NULL,
    Year            NUMBER(4) NOT NULL,
    Month           NUMBER(2) NOT NULL,
    Day             NUMBER(2) NOT NULL,
    StatusValue     NUMBER(3,1),
    IsHoliday       NUMBER(1) DEFAULT 0,
    LeaveType       VARCHAR2(50),
    AutoSat         NUMBER(1) DEFAULT 0,
    Remarks         VARCHAR2(500),
    EnteredByPCNO   VARCHAR2(50),
    EnteredAt       TIMESTAMP DEFAULT SYSTIMESTAMP,
    LastEditedByPCNO VARCHAR2(50),
    LastEditedAt    TIMESTAMP,
    CONSTRAINT PK_AttendanceDraft PRIMARY KEY (EmpID, Year, Month, Day)
);
```

### 2.3 Table: `AttPocEditRemarks`
Maintains audit logs for draft edits and POC review changes:
```sql
CREATE TABLE AttPocEditRemarks (
    Id            NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    EmpID         VARCHAR2(50) NOT NULL,
    Year          NUMBER(4) NOT NULL,
    Month         NUMBER(2) NOT NULL,
    Day           NUMBER(2) NOT NULL,
    RemarkType    VARCHAR2(50) DEFAULT 'POCEdit',
    Remark        VARCHAR2(1000) NOT NULL,
    CreatedBy     VARCHAR2(50) NOT NULL,
    CreatedAt     TIMESTAMP DEFAULT SYSTIMESTAMP,
    CreatedByRole VARCHAR2(50) DEFAULT 'POC'
);
```

---

## 3. Core Logic & Architecture Implementations

```
                                  ┌────────────────────────────────┐
                                  │      Sub User (Role 6)         │
                                  └───────────────┬────────────────┘
                                                  │ Enters attendance
                                                  ▼
                                  ┌────────────────────────────────┐
                                  │   AttendanceDraft (Staged)     │
                                  │  - Live cells strictly locked  │
                                  │  - Reason prompts on edits     │
                                  └───────────────┬────────────────┘
                                                  │ Drafts visible with yellow styling
                                                  ▼
┌───────────────────────────┐     ┌────────────────────────────────┐
│   Admin / Super Admin     │     │      Anchor POC (Role 0)       │
│  (Roles 1, 4 - Live Data) │     │ - Reviews staged draft badges  │
└─────────────┬─────────────┘     │ - Clicks [Submit Live]         │
              │                   └───────────────┬────────────────┘
              │ Direct Save                       │ Merges drafts to live
              ▼                                   ▼
        ┌───────────────────────────────────────────────┐
        │             Attendance (Live DB)              │
        │ - Production records finalized                │
        └───────────────────────────────────────────────┘
```

### 3.1 Sub User Live Lock Engine (`Attendance.aspx`)
- Inside `getCellState()`, every cell evaluates:
  ```javascript
  const isSubUser = (parseInt(role) === 6 || roleMode === "SubUser");
  const isLiveSubmittedCell = isSubUser && cell && cell.Val !== null && cell.Val !== undefined && cell.IsDraft === false;
  if (isLiveSubmittedCell) {
      isReadonlyCell = true; // Lock persists across any row re-render
  }
  ```
- In `setVal()`, an explicit guard immediately blocks and toasts any attempt to modify live records:
  ```javascript
  if (isSubUser && attendanceData[id]?.[day]?.IsDraft === false) {
      showToast("Submitted attendance cannot be edited by Sub Users.", "warning");
      return;
  }
  ```

### 3.2 Draft-to-Live Merge Engine (`Attendance.aspx.cs`)
- `SubmitDrafts(int year, int month, string category, string empIdsJson)`:
  1. Parses the target `EmpID` list.
  2. Uses `BuildEmpIdFilter` with 900-item chunks to prevent Oracle query limits.
  3. Merges `AttendanceDraft` records into `Attendance` table using `MERGE INTO Attendance t USING AttendanceDraft s...`.
  4. Deletes merged draft records from `AttendanceDraft`.
  5. Commits the transaction and updates the audit log.

### 3.3 Centralized Role Switch Engine (`Utils/DBHelper.cs`)
- Method: `DBHelper.SwitchUserRole(pcno, targetMode, session)`
- Transitions `Session["Role"]`, `Session["RoleMode"]`, `Session["UserRoles"]`, `Session["AllowedDivisions"]`, and `Session["Division"]` atomically.
- Invoked seamlessly via direct query parameter: `?switchRole=ModeName`.

---

## 4. UI / UX Redesigns & Rebranding

### 4.1 Login Role Selection (`Login.aspx`)
- **Before:** Squeezed buttons inside stacked card boxes with duplicate welcome headers.
- **After:**
  - Modern full-width interactive tiles (`.role-selection-tile`) with icon avatars and transition arrows.
  - Hover elevation (`translateY(-2px)`, subtle shadow).
  - Clean separation: credential header only shows during login; role selection displays dedicated header.

### 4.2 Topbar Active Mode Switcher (`Site.Master`)
- **Before:** Duplicate widgets in dashboard; topbar text unreadable on hover.
- **After:**
  - Single source of truth in top navigation.
  - Dedicated classes (`.topbar-role-dropdown`, `.topbar-role-menu`, `.topbar-role-item`).
  - High-contrast states:
    - **Hover**: `#f8fafc` background, `#4338ca` deep indigo title, `#334155` dark subtitle, and animated `"Switch →"` pill badge.
    - **Active**: `#f5f3ff` background, `#3730a3` title, and `"✓ Active"` pill badge.
    - **Dark Theme**: `#1e293b` background with `#f8fafc` text.

### 4.3 Clean Toast & Loading Feedback
- Single toast on save: `"Saved Successfully"` for Admin/POC; `"Draft Saved Successfully"` for Sub Users.
- Deduplication debounce (1.5s) inside `showToast()`.
- Removed secondary `"Loading Attendance Data..."` overlay after saving.

### 4.4 System Rebranding Matrix
| Location | Old Branding | New Branding |
| :--- | :--- | :--- |
| **Login Title** | `MSAS - Manpower Services Attendance System Login` | `ARS - Attendance Recording System (Skilled, Semi-Skilled) Login` |
| **Login Logo Card** | `MSAS` / `Manpower Services Attendance System` | `ARS` / `Attendance Recording System (Skilled, Semi-Skilled)` |
| **Site.Master Title** | `- Manpower Services Attendance System (MSAS)` | `- Attendance Recording System (Skilled, Semi-Skilled) (ARS)` |
| **Site.Master Sidebar** | `MSAS` / `Manpower Services Attendance System` | `ARS` / `Attendance Recording System (Skilled, Semi-Skilled)` |
| **Site.Master Topbar** | `Manpower Services Attendance System` / `MSAS` | `Attendance Recording System (Skilled, Semi-Skilled)` / `ARS` |
| **Dashboard Header** | `Manpower Services Attendance System` | `Attendance Recording System` |
| **Dashboard Subtitle** | `MSAS` / `Enterprise Contract Workforce & Attendance Operations` | `ARS` / `Skilled, Semi-Skilled` |

### 1.12 Multi-Anchor POC Linkage for Sub Users
- **Requirement:** Allow a single Sub User to be anchored to multiple Regular Users (POCs) simultaneously so they can manage data entry across scopes belonging to multiple POCs.
- **Implementation:**
  - Database schema: `SubUserAnchor` table uses a composite Primary Key `(SubUserPCNO, AnchorPocPCNO)` (`CONSTRAINT PK_SubUserAnchor PRIMARY KEY (SubUserPCNO, AnchorPocPCNO)`).
  - Admin Management UI: Replaced single-select dropdown with multi-select CheckBoxList (`cblAnchorPOCs`) with **Select All** and **Clear** helpers.
  - Sub User Grid: Displays all linked POC names in the grid (`Anchor POC(s): Alice Smith (1002), Bob Jones (1003)`).
  - Scope Synchronization: When saving or updating a Sub User, copies the union of all divisions and tiers from all linked Anchor POCs into `UserDivisions` and `UserTiers`.
  - Added full Sub User edit support via `EditSubUser` row command in `AdminManagement.aspx`.

---

## 5. File Modification Matrix

| File Path | Nature of Changes |
| :--- | :--- |
| [Login.aspx](file:///e:/attendence/Login.aspx) | Redesigned role selection into interactive tiles; updated branding to ARS (Skilled, Semi-Skilled). |
| [Login.aspx.cs](file:///e:/attendence/Login.aspx.cs) | Preserved tile commands and user role selection routing. |
| [Site.Master](file:///e:/attendence/Site.Master) | Replaced dropdown styles with high-contrast `.topbar-role-*` classes; updated branding across topbar and sidebar. |
| [Site.Master.cs](file:///e:/attendence/Site.Master.cs) | Implemented `AvailableUserRoles`, `CurrentRoleMode`, `CurrentRoleTitle`, `CurrentRoleIcon`, and badge color helpers. |
| [Dashboard.aspx](file:///e:/attendence/Dashboard.aspx) | Removed duplicate role switcher widget; updated header to `Attendance Recording System` and subtitle to `Skilled, Semi-Skilled`. |
| [Dashboard.aspx.cs](file:///e:/attendence/Dashboard.aspx.cs) | Removed redundant role switcher binding and postback event handlers. |
| [Attendance.aspx](file:///e:/attendence/Attendance.aspx) | Integrated Sub User live lock in `getCellState()`; removed Submit button for Admin/Super Admin; removed duplicate `showPop` and post-save `fetchData` loading overlays; added toast debounce. |
| [Attendance.aspx.cs](file:///e:/attendence/Attendance.aspx.cs) | Implemented `AttendanceDraft` staging and merge logic; added batch chunking for Oracle `IN (...)` queries; simplified Sub User save response message. |
| [AdminManagement.aspx](file:///e:/attendence/AdminManagement.aspx) | Added Sub Users management tab with multi-select Anchor POCs, scope preview, and Sub User edit buttons. |
| [AdminManagement.aspx.designer.cs](file:///e:/attendence/AdminManagement.aspx.designer.cs) | Updated `cblAnchorPOCs` control declaration. |
| [AdminManagement.aspx.cs](file:///e:/attendence/AdminManagement.aspx.cs) | Added multi-anchor POC persistence, union scope calculation, Sub User editing, and updated `GetAnchorPocScope` WebMethod. |
| [Utils/DBHelper.cs](file:///e:/attendence/Utils/DBHelper.cs) | Updated `SubUserAnchor` table definition with `PK_SubUserAnchor (SubUserPCNO, AnchorPocPCNO)` in `EnsureSchema()`. |
| [oracle_setup.sql](file:///e:/attendence/oracle_setup.sql) | Updated DDL scripts with `CONSTRAINT PK_SubUserAnchor PRIMARY KEY (SubUserPCNO, AnchorPocPCNO)`. |

---

## 6. Build & Verification Status

- **Compilation Command:** `msbuild AttendanceApp.csproj /t:Build /p:Configuration=Debug`
- **Result:** **`Build Succeeded. 0 Warning(s), 0 Error(s)`**
- **Knowledge Graph Synchronization:** Updated via `graphify update .` (All AST nodes synchronized).
