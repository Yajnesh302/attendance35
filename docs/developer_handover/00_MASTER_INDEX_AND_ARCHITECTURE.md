# Chapter 00: Master Index & System Architecture

This document serves as the foundational architectural specification and developer handover reference for the **Attendance Management System (AMS)**. Any new software engineer or system administrator maintaining, debugging, or enhancing this application should begin here.

---

## 1. System Overview & Core Objectives

The **Attendance Management System (AMS)** is an enterprise-grade ASP.NET Web Forms web application backed by an **Oracle Database** and integrated with **Windows Active Directory (LDAP)**.

The system is designed for organizations managing large outsourced manpower forces across multiple divisions, vendor contracts, skill tiers, and statutory wage revisions.

### Key Capabilities
- **Multi-Role Authentication & Access Control:** Dual-mode authentication (Active Directory LDAP with Oracle DB user profile synchronization) supporting Super Admins, Category Admins, Directorate POCs (Point of Contact), and Sub Users (Data Entry).
- **Hierarchical Category & Tier Architecture:** Flexible organizational classification (Main Category -> Tiers/Skill Levels e.g. Skilled, Semi-Skilled, Unskilled) with fine-grained admin category ownership and cross-admin category delegation/sharing.
- **Dynamic Attendance Matrix & Rule Engine:** Monthly grid attendance recording, automatic Saturday rule calculation, holiday propagation, right-click cell edit remarks, and multi-tier edit/view restrictions (cutoff dates, allowed retrospective days).
- **Staged Sub-User Workflow:** Sub-users stage draft attendance records in `AttendanceDraft`; Anchor POCs review, verify, and commit them into live `Attendance`.
- **Manpower Vendor & Multi-Level Escalation Ecosystem:** Central vendor master linked to GeM (Government e-Marketplace) contracts, contract periods with auto-closing backgrounds, and dynamic multi-level contact escalation matrices.
- **Dynamic Payroll & Statutory Calculation Engine:** Automated wage calculation based on government wage orders, tier-specific rates, overtime rules, final days overrides, and statutory deductions (EPF, ESI, GST) with revision history.
- **Dynamic Certificate & Document Generation:** Automated production of legal documents including Satisfactory Certificates, Covering Letters, Attendance Certificates, and Format 8 with customizable placeholder templates.
- **Comprehensive Audit Trail & History Tracking:** Multi-level audit logging (`Attendance_Audit_Log`, `EmployeeActionLogs`, `AdminActionLog`, `ActionLog`) with pre/post JSON snapshots and undo capabilities.

---

## 2. Technology Stack & Specifications

| Component | Technology / Library | Specification / Version | Role in Application |
| :--- | :--- | :--- | :--- |
| **Framework** | Microsoft .NET Framework | `v4.5` (`System.Web`, WebForms) | Server-side execution runtime and page lifecycle engine |
| **Language** | C# | `5.0` / `.NET 4.5` syntax | Backend logic, event handlers, and data access layer |
| **Database** | Oracle Database | `11g R2` / `12c` / `19c` / `XE` | Relational persistence, sequences, triggers, composite indexes |
| **DB Driver** | `Oracle.ManagedDataAccess` | `4.121.2.0` (Fully managed) | Managed Oracle ADO.NET connection provider (zero Oracle Client install) |
| **Directory Service** | Microsoft Active Directory | LDAP `3.0` (`DirectorySearcher`) | Corporate Single Sign-On and employee directory lookup |
| **Authentication** | ASP.NET Forms Authentication | Cookies (`.ASPXAUTH`), 1440m timeout | Session tracking and authenticated route gating (`deny users="?"`) |
| **Frontend UI** | HTML5, Vanilla CSS3, JS | Responsive layout, modern CSS | Presentation layer, dynamic grid rendering, modals, DOM scripting |
| **Icons & Fonts** | FontAwesome 5 / 6, Google Fonts | Inter, Outfit, Roboto | Premium visual iconography and typography |
| **Web Server** | Microsoft IIS | `7.5` / `8.5` / `10.0` | Production HTTP server, static compression, MIME configuration |

---

## 3. Project Directory & File Structure

```text
e:\attendence/
│
├── Web.config                     # Central application configuration (DB strings, LDAP, Forms Auth)
├── Site.Master                    # Global master page (Top navigation, Sidebar, Role switcher, User badges)
├── Site.Master.cs                 # Master layout code-behind (Dynamic menu rendering, notices/remarks badge counts)
├── Site.Master.designer.cs        # Designer generated declarations for Master page controls
│
├── Login.aspx                     # Authentication gateway (LDAP/DB login + multi-role selector modal)
├── Login.aspx.cs                  # Login backend (AD binding, AppUsers role resolution, session initialization)
├── Login.aspx.designer.cs         # Designer generated declarations for Login controls
│
├── Dashboard.aspx                 # Central command dashboard (Metrics cards, quick action links, status overview)
├── Dashboard.aspx.cs              # Dashboard backend (Aggregated stats, active contracts, attendance percentages)
├── Dashboard.aspx.designer.cs     # Designer declarations for Dashboard
│
├── Attendance.aspx                # Daily/Monthly Attendance Matrix Grid
├── Attendance.aspx.cs             # Core Attendance engine (Punching, Auto-Saturday, Draft commit, Edit policies)
├── Attendance.aspx.designer.cs    # Designer declarations for Attendance
│
├── Employee.aspx                  # Employee Master & Stint Engagement Management
├── Employee.aspx.cs               # Employee lifecycle backend (Multi-stints, Leave credits/balance, Qualifications)
├── Employee.aspx.designer.cs      # Designer declarations for Employee
│
├── Contracts.aspx                 # GeM Contracts & Period Management
├── Contracts.aspx.cs              # Contract periods, tier mappings, period extensions, auto-close triggers
├── Contracts.aspx.designer.cs     # Designer declarations for Contracts
│
├── Vendors.aspx                   # Vendor Master Registry
├── Vendors.aspx.cs                # Vendor management, GeM mapping, multi-level contact escalation matrix
├── Vendors.aspx.designer.cs       # Designer declarations for Vendors
│
├── Calculation.aspx               # Wage Calculations & Overrides
├── Calculation.aspx.cs            # Monthly attendance wage engine, working days calculation, manual overrides
├── Calculation.aspx.designer.cs   # Designer declarations for Calculation
│
├── Wages.aspx                     # Statutory Payroll, Wage Orders & Registers
├── Wages.aspx.cs                  # Wage Orders revision, EPF/GST statutory rates, payroll registers, payslips
├── Wages.aspx.designer.cs         # Designer declarations for Wages
│
├── Documents.aspx                 # Document Generator & Template Engine
├── Documents.aspx.cs              # Satisfactory Certificate, Covering Letters, Format 8 generation & Word exports
├── Documents.aspx.designer.cs     # Designer declarations for Documents
│
├── AdminManagement.aspx           # System Administration & Hierarchical Categories
├── AdminManagement.aspx.cs        # MainCategory/Tiers builder, User roles, Sub-User anchors, Category sharing
├── AdminManagement.aspx.designer.cs # Designer declarations for AdminManagement
│
├── Settings.aspx                  # Application Settings & Edit Policies
├── Settings.aspx.cs               # Global view/edit restriction rules, cutoff dates, shift configs
├── Settings.aspx.designer.cs      # Designer declarations for Settings
│
├── Notices.aspx                   # Circulars & Notice Board
├── Notices.aspx.cs                # File uploads, official circular distribution, read receipt tracking
├── Notices.aspx.designer.cs       # Designer declarations for Notices
│
├── Remarks.aspx / UserRemarks.aspx # Attendance Remarks & POC-to-Admin Correction Workflow
├── Remarks.aspx.cs / UserRemarks.aspx.cs # Remark threads, admin resolution status, cell corrections
├── Remarks.aspx.designer.cs       # Designer declarations for Remarks
│
├── Ledger.aspx                    # Financial Vendor Ledger
├── Ledger.aspx.cs                 # Invoice deductions, bill reconciliation, vendor payments
├── Ledger.aspx.designer.cs        # Designer declarations for Ledger
│
├── Invoice.aspx                   # Billing invoice generation interface
│
├── Utils/
│   ├── DBHelper.cs                # Core Data Access Layer (ADO.NET, connection pooling, business queries, auto-close)
│   ├── ActionLogger.cs            # Centralized audit logger (Undo tracking, admin events, JSON snapshots)
│   └── ADHelper.cs                # Active Directory LDAP client (LDAP query, bind, credential verification)
│
├── Static/                        # Public static assets (CSS, JS, Fonts, Images)
├── oracle_setup.sql               # Complete Oracle DDL setup script (Tables, sequences, triggers, seed data)
├── db_setup.sql                   # Schema migration and testing DDL
└── docs/                          # Comprehensive developer documentation suite
```

---

## 4. Architectural Data Flow & Request Lifecycle

The diagram below illustrates how user requests flow through IIS, Forms Authentication, Active Directory, Application Code-Behind, the Data Access Layer, and the Oracle Database:

```
+-----------------------------------------------------------------------------------+
|                                  CLIENT BROWSER                                    |
|              (Sends HTTP/HTTPS Requests, Renders WebForms HTML / DOM)              |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                              MICROSOFT IIS WEB SERVER                             |
|       - Request Filtering (Max 2GB uploads: maxAllowedContentLength=2147483648)   |
|       - Static Content Compression (Gzip / Deflate for CSS, JS, WOFF2)            |
|       - Default Document Routing (Routes unauthenticated users to Login.aspx)     |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                           ASP.NET PIPELINE (Web.config)                           |
|       - FormsAuthenticationModule: Checks .ASPXAUTH session cookie                |
|       - Authorization Rule: <deny users="?" /> (Blocks unauthenticated access)    |
|       - Static Exception: <location path="Static"><allow users="*"/></location>   |
+--------------------+------------------------------------+-------------------------+
                     |                                    |
  [If Unauthenticated / Login Request]           [If Authenticated Request]
                     |                                    |
                     v                                    v
+---------------------------------------+  +----------------------------------------+
|          Login.aspx / .cs             |  |        Target Page (.aspx / .cs)       |
|  1. Capture Username & Password       |  |  (Attendance, Employee, Contracts, etc)|
|  2. ADHelper.cs -> Authenticate LDAP  |  |  1. Page_Load / PostBack Event Handlers|
|  3. Query hrdata.empdetails (Profile) |  |  2. Validate Session Variables         |
|  4. Query AppUsers -> Get Roles       |  |  3. Enforce Role & Division Scope      |
|  5. If multiple roles -> Show Modal   |  |  4. Render Site.Master Navigation      |
|  6. FormsAuthentication.SetAuthCookie |  +-------------------+--------------------+
|  7. Initialize Session Variables      |                      |
|  8. Redirect to Dashboard.aspx        |                      |
+---------------------------------------+                      |
                                                               |
                                                               v
+-----------------------------------------------------------------------------------+
|                        DATA ACCESS LAYER (Utils/DBHelper.cs)                      |
|       - Oracle Managed Connection Pooling (AttendanceDB & CompanyDB)              |
|       - Parameterized Command Execution (Prevents SQL Injection)                  |
|       - AutoCloseExpiredContracts Background ThreadPool Worker                    |
|       - ActionLogger.cs: Audit trail logging with Pre/Post state snapshots        |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                            ORACLE RELATIONAL DATABASE                             |
|       - SYSTEM Schema: Application Tables, Sequences, Triggers, Indexes           |
|       - HRDATA Schema: empdetails table (Employee name, designation, division)   |
+-----------------------------------------------------------------------------------+
```

---

## 5. Security Model & Role Hierarchy

The application defines a strict integer-based role hierarchy stored in `AppUsers.Role`. In addition to explicit roles, users can hold primary/secondary admin privileges through category ownership or cross-admin sharing.

### Complete Role Definition Matrix

| Role Code | Role Mode Name | Display Title | Access Scope & Responsibilities | Revocation Pair Code |
| :---: | :--- | :--- | :--- | :---: |
| **`4`** | `SuperAdmin` | Super Administrator | Global master access. Can configure system settings, view all divisions/categories, create/revoke admins, and perform database maintenance. | **`5`** (Revoked Super Admin) |
| **`1`** | `PrimaryAdmin` | Primary Category Admin | Manages owned Main Categories (`MainCategory.AdminPCNO = :PCNO`) and their child tiers. Full access to employees, attendance, contracts, wages, and documents within owned categories. | **`2`** (Revoked Admin) |
| **`1`** | `SecondaryAdmin` | Secondary Admin (Shared) | Access granted via `CategoryShareGrant` from a Primary Admin. Can manage attendance and operations for delegated categories. | **`2`** (Revoked Admin) |
| **`0`** | `RegularUser` | Directorate POC | Point of Contact for specific divisions (`UserDivisions`). Can view/edit daily attendance for employees in their division within configured edit windows (`EditDaysAllowed`, `ViewCutoffDate`). | **`3`** (Revoked POC) |
| **`6`** | `SubUser` | Sub User (Data Entry) | Restricted data-entry clerk linked to one or more Anchor POCs (`SubUserAnchor`). Can only input draft attendance in `AttendanceDraft`; cannot modify live attendance directly. | **`7`** (Revoked Sub User) |

### Dual Role Resolution & Role Switcher
If a single user (e.g. PCNO `1001`) is configured both as a Primary Admin for Category A and a POC for Division B, or has shared categories, `Login.aspx` will automatically present the **Role Selection Modal** upon login. The user selects their operating identity for that session, which sets `Session["Role"]` and `Session["RoleMode"]`.

---

## 6. Session State Variable Dictionary

Every authenticated session relies on standardized session keys set during login in `Login.aspx.cs` and utilized across all `.aspx.cs` code-behind pages:

| Session Key | Data Type | Populated By | Purpose & Expected Values |
| :--- | :--- | :--- | :--- |
| `Session["PCNO"]` | `string` | `Login.CompleteUserLogin` | Unique employee personal computer number / ID (e.g. `"1001"`, `"EMP045"`). |
| `Session["Role"]` | `int` | `Login.CompleteUserLogin` | Active effective role code: `4` (SuperAdmin), `1` (Admin), `0` (POC), `6` (SubUser). |
| `Session["RoleMode"]` | `string` | `Login.CompleteUserLogin` | Active identity string: `"SuperAdmin"`, `"PrimaryAdmin"`, `"SecondaryAdmin"`, `"RegularUser"`, `"SubUser"`. |
| `Session["Name"]` | `string` | `Login.CompleteUserLogin` | Full display name resolved from `hrdata.empdetails` or `AppUsers` (e.g. `"John Doe"`). |
| `Session["Designation"]`| `string` | `Login.CompleteUserLogin` | Corporate job designation from `hrdata.empdetails` (e.g. `"Scientist 'F'"`). |
| `Session["Division"]` | `string` | `Login.CompleteUserLogin` | Primary division identifier of the logged-in user (e.g. `"D-ADMIN"`, `"D-KRM"`). |
| `Session["AllowedDivisions"]` | `List<string>`| `Login.CompleteUserLogin` | List of all division names the POC / SubUser is authorized to manage from `UserDivisions`. |
| `Session["UserRoles"]` | `List<UserRoleOption>`| `Login.CompleteUserLogin` | All role options available to this user account (enables dynamic role switching without re-entering credentials). |
| `Session["PendingPCNO"]` | `string` | `Login.btnLogin_Click` | Temporary PCNO held during multi-role selection prior to session completion. |
| `Session["PendingRoles"]`| `List<UserRoleOption>`| `Login.btnLogin_Click` | Temporary list of role choices presented in `Login.aspx` repeater. |

---

## 7. Web.config Configuration Reference

The application configuration is managed via `Web.config`:

### Database Connection Strings
```xml
<connectionStrings>
  <!-- CompanyDB: Connects to corporate HR schema (hrdata.empdetails) for profile lookups -->
  <add name="CompanyDB" 
       connectionString="User Id=system;Password=root;Data Source=//127.0.0.1:1521/xe;Min Pool Size=2;Max Pool Size=100;Connection Lifetime=120;Statement Cache Size=20;Validate Connection=false;" 
       providerName="Oracle.ManagedDataAccess.Client" />

  <!-- AttendanceDB: Connects to main AMS application database (Attendance, Employees, Contracts, etc.) -->
  <add name="AttendanceDB" 
       connectionString="User Id=system;Password=root;Data Source=//127.0.0.1:1521/xe;Min Pool Size=5;Max Pool Size=200;Connection Lifetime=120;Statement Cache Size=50;Incr Pool Size=5;Decr Pool Size=2;Validate Connection=false;" 
       providerName="Oracle.ManagedDataAccess.Client" />
</connectionStrings>
```

### Active Directory LDAP Settings
```xml
<appSettings>
  <add key="ValidationSettings:UnobtrusiveValidationMode" value="None" />
  <!-- ADConnectionPath: LDAP server URI used by ADHelper.cs for user authentication -->
  <add key="ADConnectionPath" value="LDAP://192.168.0.106/DC=ad01,DC=yajnesh,DC=com" />
</appSettings>
```

### Session & Request Limits
- **Forms Authentication Timeout:** `1440` minutes (24 hours).
- **Session Timeout:** `1440` minutes.
- **Max Request Length (`maxRequestLength`):** `2097151` KB (~2 GB) allowing large bulk document and certificate uploads.
- **Execution Timeout (`executionTimeout`):** `3600` seconds (1 hour) for heavy background calculations and bulk data imports.
- **JSON Max Length (`maxJsonLength`):** `2147483647` characters (2 GB) for large AJAX attendance grids and payslip JSON payloads.

---

## 8. Master Chapter Index for Developers

To learn or modify specific components of the Attendance Management System, refer to the corresponding chapters in this documentation suite:

- **[Chapter 01: Complete Database Schema & Data Dictionary](file:///e:/attendence/docs/developer_handover/01_DATABASE_SCHEMA_AND_RELATIONS.md)**
  *All 25+ Oracle tables, column specifications, sequences, triggers, composite indexes, and relational ER diagram.*
- **[Chapter 02: Core Data Access Layer & Utilities](file:///e:/attendence/docs/developer_handover/02_CORE_UTILITIES_DBHELPER_LOGGER_AD.md)**
  *Deep dive into `DBHelper.cs`, `ActionLogger.cs`, and `ADHelper.cs`.*
- **[Chapter 03: Authentication & Global Layout Engine](file:///e:/attendence/docs/developer_handover/03_AUTHENTICATION_AND_LAYOUT_LOGIN_SITEMASTER.md)**
  *`Login.aspx` + `Site.Master` lifecycle, navigation menus, and session management.*
- **[Chapter 04: Attendance Management (Part 1: Core Grid & Business Logic)](file:///e:/attendence/docs/developer_handover/04_ATTENDANCE_MODULE_PART1_CORE_AND_LOGIC.md)**
  *`Attendance.aspx` matrix rendering, Auto-Saturday rule, holidays, and punch status calculation.*
- **[Chapter 05: Attendance Management (Part 2: Drafts, Edit Policies & Auditing)](file:///e:/attendence/docs/developer_handover/05_ATTENDANCE_MODULE_PART2_DRAFTS_PERMISSIONS_AUDIT.md)**
  *`AttendanceDraft` sub-user workflow, POC cutoffs, right-click remarks, and audit logs.*
- **[Chapter 06: Employee Lifecycle & Master Registry](file:///e:/attendence/docs/developer_handover/06_EMPLOYEE_MANAGEMENT_MODULE.md)**
  *`Employee.aspx` multi-stints, leave credit transactions, carry-over balance logic, and qualifications.*
- **[Chapter 07: Contracts & Vendor Ecosystem](file:///e:/attendence/docs/developer_handover/07_CONTRACTS_AND_VENDORS_MODULE.md)**
  *`Contracts.aspx` & `Vendors.aspx`, multi-level contact matrix, contract extensions, and auto-close triggers.*
- **[Chapter 08: Payroll Calculations & Wage Orders](file:///e:/attendence/docs/developer_handover/08_CALCULATION_AND_WAGES_PAYROLL_MODULE.md)**
  *`Calculation.aspx` & `Wages.aspx`, statutory EPF/GST math, wage orders, overrides, and payslips.*
- **[Chapter 09: Automated Document Generation & Certificate Engine](file:///e:/attendence/docs/developer_handover/09_DOCUMENT_GENERATION_AND_TEMPLATES.md)**
  *`Documents.aspx` & `Invoice.aspx`, template placeholder engines, Satisfactory Certificates, and Format 8.*
- **[Chapter 10: Administration, Hierarchical Categories & Security Policies](file:///e:/attendence/docs/developer_handover/10_ADMIN_MANAGEMENT_AND_SECURITY_POLICIES.md)**
  *`AdminManagement.aspx` & `Settings.aspx`, category/tier hierarchy, sub-user anchors, and category sharing.*
- **[Chapter 11: Communication, Notices, Remarks & Financial Ledger](file:///e:/attendence/docs/developer_handover/11_NOTICES_REMARKS_AND_LEDGER_MODULES.md)**
  *`Notices.aspx`, `Remarks.aspx`, `UserRemarks.aspx`, and `Ledger.aspx`.*
- **[Chapter 12: Developer Recipe & Modification Handbook](file:///e:/attendence/docs/developer_handover/12_DEVELOPER_MAINTENANCE_AND_MODIFICATION_GUIDE.md)**
  *Step-by-step how-to recipes for adding fields, creating new pages, altering wage formulas, and debugging.*
