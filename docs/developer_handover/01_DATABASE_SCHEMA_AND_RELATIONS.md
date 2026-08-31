# Chapter 01: Complete Database Schema & Data Dictionary

This document provides a comprehensive, field-level data dictionary and entity-relationship model for the entire **Attendance Management System (AMS)** database schema.

---

## 1. Entity-Relationship Overview (Mermaid Diagram)

```mermaid
erDiagram
    AppUsers {
        VARCHAR2(50) PCNO PK
        VARCHAR2(200) Name
        NUMBER(1) Role PK
    }

    MainCategory {
        NUMBER Id PK
        VARCHAR2(100) Name UK
        VARCHAR2(50) AdminPCNO
        NUMBER EditDaysAllowed
        NUMBER(1) EditMode
        NUMBER(1) ViewMode
        NUMBER ViewMonthsAllowed
        DATE ViewCutoffDate
        NUMBER(1) ViewAppliesTo
    }

    Tiers {
        NUMBER Id PK
        NUMBER MainCategoryId FK
        VARCHAR2(100) TierName
        VARCHAR2(100) RoleLabel
        NUMBER SortOrder
    }

    UserTiers {
        VARCHAR2(50) PCNO PK
        NUMBER TierId PK, FK
    }

    CategoryShareGrant {
        NUMBER Id PK
        VARCHAR2(50) OwnerAdminPCNO
        VARCHAR2(50) SharedWithPCNO
        NUMBER MainCategoryId FK
        NUMBER TierId FK
        NUMBER(1) IsActive
        TIMESTAMP GrantedAt
    }

    Divisions {
        NUMBER Id PK
        VARCHAR2(100) Name UK
    }

    UserDivisions {
        VARCHAR2(50) PCNO PK
        VARCHAR2(100) DivisionName PK
        NUMBER DivId
    }

    SubUserAnchor {
        VARCHAR2(50) SubUserPCNO PK
        VARCHAR2(50) AnchorPocPCNO PK
        TIMESTAMP CreatedAt
        VARCHAR2(50) CreatedBy
    }

    Vendors {
        NUMBER Id PK
        VARCHAR2(50) MasterId UK
        VARCHAR2(150) Name UK
        VARCHAR2(100) GemId
        VARCHAR2(100) ContactName
        VARCHAR2(20) ContactPhone
        VARCHAR2(4000) Address
        NUMBER(1) IsActive
    }

    VendorContacts {
        NUMBER Id PK
        NUMBER VendorId FK
        NUMBER Priority UK
        VARCHAR2(100) ContactName
        VARCHAR2(20) ContactPhone
        VARCHAR2(200) ContactEmail
        VARCHAR2(4000) ContactAddress
        NUMBER SortOrder
    }

    ContractPeriods {
        NUMBER Id PK
        NUMBER TierId FK
        NUMBER VendorId FK
        VARCHAR2(100) GemId
        DATE StartDate UK
        DATE EndDate
        DATE DatedOn
        VARCHAR2(20) Status
        VARCHAR2(4000) Notes
    }

    ContractPeriodVendors {
        NUMBER Id PK
        NUMBER ContractPeriodId FK
        NUMBER VendorId FK
        NUMBER TierId FK
        NUMBER(1) IsActive
    }

    ContractExtensions {
        NUMBER Id PK
        NUMBER ContractPeriodId FK
        DATE OldEndDate
        DATE NewEndDate
        TIMESTAMP ExtensionDate
    }

    Employees {
        VARCHAR2(50) MasterId PK
        VARCHAR2(50) ID
        VARCHAR2(200) Name
        VARCHAR2(100) Department
        NUMBER DivId
        NUMBER TierId FK
        VARCHAR2(50) EmployeeHistoryId
        DATE OriginalJoinDate
        DATE JoinDate
        NUMBER LeaveBalance
        NUMBER PrevLeaveBalance
        VARCHAR2(20) Status
        DATE ResignDate
        DATE ContractEndDate
        NUMBER CurrentEngagementId FK
        VARCHAR2(50) Phone
        VARCHAR2(100) Email
        VARCHAR2(50) Aadhar
        VARCHAR2(4000) Address
        VARCHAR2(200) Qualification
        NUMBER Experience
        VARCHAR2(200) ExperienceIn
    }

    EmployeeEngagements {
        NUMBER Id PK
        VARCHAR2(50) EmpID FK
        NUMBER ContractPeriodId FK
        NUMBER TierId FK
        NUMBER VendorId FK
        VARCHAR2(100) Department
        NUMBER DivId
        DATE StartDate
        DATE EndDate
        VARCHAR2(50) EndReason
        NUMBER(1) IsCarriedOver
        NUMBER PrevEngagementId FK
        VARCHAR2(50) EmployeeId
    }

    EmployeeLeaveCredits {
        NUMBER Id PK
        VARCHAR2(50) EmpID FK
        NUMBER ContractPeriodId FK
        NUMBER Amount
        DATE EffectiveDate
        VARCHAR2(200) Remarks
    }

    Attendance {
        NUMBER Id PK
        VARCHAR2(50) EmpID FK, UK
        NUMBER EngagementId FK
        NUMBER ContractPeriodId FK
        NUMBER(4) Year UK
        NUMBER(2) Month UK
        NUMBER(2) Day UK
        NUMBER(1) StatusValue
        VARCHAR2(50) LeaveType
        NUMBER(1) IsHoliday
        NUMBER(1) AutoSat
        VARCHAR2(500) Remarks
    }

    AttendanceDraft {
        NUMBER Id PK
        VARCHAR2(50) EmpID FK, UK
        NUMBER EngagementId FK
        NUMBER ContractPeriodId FK
        NUMBER(4) Year UK
        NUMBER(2) Month UK
        NUMBER(2) Day UK
        NUMBER StatusValue
        VARCHAR2(50) LeaveType
        NUMBER(1) IsHoliday
        NUMBER(1) AutoSat
        VARCHAR2(500) Remarks
        VARCHAR2(50) EnteredByPCNO
        TIMESTAMP EnteredAt
        VARCHAR2(50) LastEditedByPCNO
        TIMESTAMP LastEditedAt
    }

    WageOrders {
        NUMBER Id PK
        VARCHAR2(100) OrderId
        NUMBER MainCategoryId FK
        DATE EffectiveDate
        VARCHAR2(4000) OrderDetails
        VARCHAR2(50) CreatedBy
        TIMESTAMP CreatedAt
    }

    CategoryWages {
        NUMBER Id PK
        NUMBER WageOrderId FK
        NUMBER TierId FK
        NUMBER(10,2) WageRate
        VARCHAR2(50) CreatedBy
        TIMESTAMP CreatedAt
    }

    StatutoryOrders {
        NUMBER Id PK
        VARCHAR2(100) OrderId
        DATE EffectiveDate
        NUMBER(5,2) EpfRate
        NUMBER(10,2) EpfLimit
        NUMBER(10,2) EpfCappedAmount
        NUMBER(5,2) GstRate
        VARCHAR2(4000) OrderDetails
        VARCHAR2(50) CreatedBy
        TIMESTAMP CreatedAt
    }

    MainCategory ||--o{ Tiers : "contains"
    Tiers ||--o{ ContractPeriods : "governs"
    Vendors ||--o{ ContractPeriods : "awards"
    Vendors ||--o{ VendorContacts : "has contacts"
    ContractPeriods ||--o{ ContractExtensions : "extended by"
    ContractPeriods ||--o{ ContractPeriodVendors : "associates"
    Tiers ||--o{ Employees : "categorizes"
    Employees ||--o{ EmployeeEngagements : "has history of"
    ContractPeriods ||--o{ EmployeeEngagements : "scopes"
    Employees ||--o{ EmployeeLeaveCredits : "credited with"
    Employees ||--o{ Attendance : "records"
    Employees ||--o{ AttendanceDraft : "drafted for"
    MainCategory ||--o{ WageOrders : "has wage revisions"
    WageOrders ||--o{ CategoryWages : "defines rates"
```

---

## 2. Table-by-Table Data Dictionary

### 2.1 User Authentication, Access Control & Divisions

#### `AppUsers`
Stores authorized login accounts and access roles.
- **Primary Key:** `(PCNO, Role)` (Allows a single user to hold multiple distinct roles).

| Column Name | Data Type | Nullable | Default | Description & Values |
| :--- | :--- | :---: | :---: | :--- |
| `PCNO` | `VARCHAR2(50)` | No | - | Employee computer/personnel number (matches AD / LDAP). |
| `Name` | `VARCHAR2(200)` | No | - | User display name. |
| `Role` | `NUMBER(1)` | No | `0` | **Role Codes:**<br>`0` = Regular User (POC)<br>`1` = Category Admin<br>`2` = Revoked Admin<br>`3` = Revoked POC<br>`4` = Super Admin<br>`5` = Revoked Super Admin<br>`6` = Sub User (Data Entry)<br>`7` = Revoked Sub User |

#### `Divisions`
Master list of organizational departments and divisions.
- **Primary Key:** `Id` (Sequence: `SEQ_Divisions`, Trigger: `TRG_Divisions`)
- **Unique Key:** `Name`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Auto-increment unique division ID. |
| `Name` | `VARCHAR2(100)` | No | - | Division name (e.g. `'D-ADMIN'`, `'D-KRM'`, `'D-ASR'`). |

#### `UserDivisions`
Maps regular users (POCs) and Sub Users to the specific divisions they are allowed to manage.
- **Primary Key:** `(PCNO, DivisionName)`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `PCNO` | `VARCHAR2(50)` | No | - | User PCNO. |
| `DivisionName`| `VARCHAR2(100)` | No | - | Name of authorized division. |
| `DivId` | `NUMBER` | Yes | `NULL` | Optional foreign key link to `Divisions.Id`. |

#### `SubUserAnchor`
Maps a Sub User (data entry clerk) to one or more Anchor POCs whose division/tier scope they inherit.
- **Primary Key:** `(SubUserPCNO, AnchorPocPCNO)`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `SubUserPCNO` | `VARCHAR2(50)` | No | - | PCNO of the Sub User (Role `6`). |
| `AnchorPocPCNO`| `VARCHAR2(50)` | No | - | PCNO of the Anchor POC (Role `0`). |
| `CreatedAt` | `TIMESTAMP` | No | `SYSTIMESTAMP`| Timestamp when link was established. |
| `CreatedBy` | `VARCHAR2(50)` | No | - | PCNO of Admin who established the assignment. |

---

### 2.2 Hierarchical Categories & Sharing

#### `MainCategory`
Top-level organizational domain (e.g. "HR", "Technical Support", "Security").
- **Primary Key:** `Id` (Sequence: `SEQ_MainCategory`, Trigger: `TRG_MainCategory`)
- **Unique Key:** `Name`

| Column Name | Data Type | Nullable | Default | Description & Business Rules |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique category ID. |
| `Name` | `VARCHAR2(100)` | No | - | Category title (e.g. `'HR'`). |
| `AdminPCNO` | `VARCHAR2(50)` | Yes | `NULL` | PCNO of Primary Admin who owns this category. |
| `EditDaysAllowed`| `NUMBER` | No | `0` | Number of retrospective days POCs can edit attendance (`0` = current day only). |
| `EditMode` | `NUMBER(1)` | No | `0` | `0` = Unlimited, `1` = Strict window, `2` = Locked. |
| `ViewMode` | `NUMBER(1)` | No | `0` | `0` = Unlimited, `1` = Fixed N months, `2` = Strict Cutoff Date, `3` = Combined rule, `4` = Locked. |
| `ViewMonthsAllowed`| `NUMBER`| No | `2` | Number of historical months accessible in view mode `1`. |
| `ViewCutoffDate` | `DATE` | Yes | `NULL` | Explicit historical calendar cutoff date for view mode `2`. |
| `ViewAppliesTo` | `NUMBER(1)` | No | `0` | `0` = Apply to Regular Users (POCs) only, `1` = Apply to all non-superadmins. |

#### `Tiers`
Sub-classifications / skill levels under a MainCategory (e.g. "Skilled", "Semi-Skilled", "Unskilled").
- **Primary Key:** `Id` (Sequence: `SEQ_Tiers`, Trigger: `TRG_Tiers`)
- **Foreign Key:** `MainCategoryId` -> `MainCategory.Id` (`ON DELETE CASCADE`)
- **Unique Constraint:** `(MainCategoryId, TierName, RoleLabel)`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique Tier ID. |
| `MainCategoryId`| `NUMBER` | No | - | Parent MainCategory ID. |
| `TierName` | `VARCHAR2(100)` | No | - | Skill designation (e.g. `'Skilled'`). |
| `RoleLabel` | `VARCHAR2(100)` | Yes | `NULL` | Optional functional title (e.g. `'DEO'`). |
| `SortOrder` | `NUMBER` | Yes | `0` | UI display sort order. |

#### `UserTiers`
Maps regular users (POCs) to specific allowed tiers.
- **Primary Key:** `(PCNO, TierId)`
- **Foreign Key:** `TierId` -> `Tiers.Id` (`ON DELETE CASCADE`)

#### `CategoryShareGrant`
Permits a Primary Admin to delegate management of a MainCategory (or specific Tier) to another Admin.
- **Primary Key:** `Id` (Sequence: `SEQ_CategoryShareGrant`, Trigger: `TRG_CategoryShareGrant`)
- **Foreign Keys:** `MainCategoryId` -> `MainCategory.Id`, `TierId` -> `Tiers.Id`
- **Unique Constraint:** `(OwnerAdminPCNO, SharedWithPCNO, MainCategoryId, TierId)`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique share record ID. |
| `OwnerAdminPCNO`| `VARCHAR2(50)` | No | - | Primary Admin granting access. |
| `SharedWithPCNO`| `VARCHAR2(50)` | No | - | Secondary Admin receiving access. |
| `MainCategoryId`| `NUMBER` | No | - | Main category ID being shared. |
| `TierId` | `NUMBER` | Yes | `NULL` | Optional specific Tier ID (NULL = all tiers in category). |
| `IsActive` | `NUMBER(1)` | No | `1` | `1` = Active grant, `0` = Revoked/Inactive. |
| `GrantedAt` | `TIMESTAMP` | No | `SYSTIMESTAMP`| Timestamp when grant was created. |

---

### 2.3 Vendors & GeM Contract Periods

#### `Vendors`
Contractor / Manpower supply agencies.
- **Primary Key:** `Id` (Sequence: `SEQ_Vendors`, Trigger: `TRG_Vendors`)
- **Unique Keys:** `MasterId`, `Name`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique vendor ID. |
| `MasterId` | `VARCHAR2(50)` | No | - | Unique alphanumeric vendor identifier code. |
| `Name` | `VARCHAR2(150)`| No | - | Vendor agency name (e.g. `'M/s ABC Enterprises'`). |
| `GemId` | `VARCHAR2(100)`| Yes | `NULL` | Government e-Marketplace vendor seller ID. |
| `ContactName` | `VARCHAR2(100)`| Yes | `NULL` | Primary legacy contact name. |
| `ContactPhone` | `VARCHAR2(20)` | Yes | `NULL` | Primary legacy phone number. |
| `Address` | `VARCHAR2(4000)`| Yes | `NULL` | Full registered office address. |
| `IsActive` | `NUMBER(1)` | No | `1` | `1` = Active vendor, `0` = Blacklisted / Inactive. |

#### `VendorContacts`
Dynamic multi-level contact escalation matrix per vendor.
- **Primary Key:** `Id` (Sequence: `SEQ_VendorContacts`, Trigger: `TRG_VendorContacts`)
- **Foreign Key:** `VendorId` -> `Vendors.Id` (`ON DELETE CASCADE`)
- **Unique Constraint:** `(VendorId, Priority)`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique contact ID. |
| `VendorId` | `NUMBER` | No | - | Parent vendor ID. |
| `Priority` | `NUMBER` | No | - | Escalation level: `1` = Primary, `2` = Escalation L2, `3` = L3. |
| `ContactName` | `VARCHAR2(100)`| No | - | Contact person name. |
| `ContactPhone` | `VARCHAR2(20)` | No | - | Contact phone / mobile number. |
| `ContactEmail` | `VARCHAR2(200)`| Yes | `NULL` | Email address (Mandatory for Priority `1`). |
| `ContactAddress`| `VARCHAR2(4000)`| Yes | `NULL` | Postal address (Mandatory for Priority `1`). |
| `SortOrder` | `NUMBER` | Yes | `0` | Display ordering. |

#### `ContractPeriods`
GeM contract execution periods tied to specific Tiers and Vendors.
- **Primary Key:** `Id` (Sequence: `SEQ_ContractPeriods`, Trigger: `TRG_ContractPeriods`)
- **Foreign Keys:** `TierId` -> `Tiers.Id` (`ON DELETE CASCADE`), `VendorId` -> `Vendors.Id`
- **Unique Constraint:** `(TierId, StartDate)`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique contract period ID. |
| `TierId` | `NUMBER` | No | - | Skill tier under contract. |
| `VendorId` | `NUMBER` | No | - | Awarded vendor contractor ID. |
| `GemId` | `VARCHAR2(100)`| Yes | `NULL` | GeM Contract Order Number (e.g. `'GEMC-5116877...'`). |
| `StartDate` | `DATE` | No | - | Contract commencement date. |
| `EndDate` | `DATE` | Yes | `NULL` | Contract expiration date (auto-closed when past). |
| `DatedOn` | `DATE` | Yes | `NULL` | Formal contract signing / execution date. |
| `Status` | `VARCHAR2(20)` | No | `'Active'` | `'Active'` or `'Closed'`. |
| `Notes` | `VARCHAR2(4000)`| Yes | `NULL` | Administrative contract remarks. |

#### `ContractPeriodVendors`
Associates additional or consortium vendors attached to a contract period.
- **Primary Key:** `Id` (Sequence: `SEQ_ContractPeriodVendors`, Trigger: `TRG_ContractPeriodVendors`)
- **Foreign Keys:** `ContractPeriodId` -> `ContractPeriods.Id` (`ON DELETE CASCADE`), `VendorId` -> `Vendors.Id`, `TierId` -> `Tiers.Id` (`ON DELETE CASCADE`)

#### `ContractExtensions`
Audit history of contract end date extensions.
- **Primary Key:** `Id` (Sequence: `SEQ_ContractExtensions`, Trigger: `TRG_ContractExtensions`)
- **Foreign Key:** `ContractPeriodId` -> `ContractPeriods.Id` (`ON DELETE CASCADE`)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique extension log ID. |
| `ContractPeriodId`| `NUMBER` | No | - | Target contract period ID. |
| `OldEndDate` | `DATE` | Yes | `NULL` | Expiration date prior to extension. |
| `NewEndDate` | `DATE` | No | - | New extended expiration date. |
| `ExtensionDate`| `TIMESTAMP` | No | `SYSTIMESTAMP`| Timestamp when extension was recorded. |

---

### 2.4 Employee Master & Engagements

#### `Employees`
Master record for contract employees.
- **Primary Key:** `MasterId` (Unique immutable employee key, e.g. `'EMP_1004'`)
- **Foreign Keys:** `TierId` -> `Tiers.Id` (`ON DELETE CASCADE`), `CurrentEngagementId` -> `EmployeeEngagements.Id`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `MasterId` | `VARCHAR2(50)` | No | - | System-generated immutable master key. |
| `ID` | `VARCHAR2(50)` | No | - | Organizational badge / token number. |
| `Name` | `VARCHAR2(200)`| No | - | Full legal employee name. |
| `Department` | `VARCHAR2(100)`| Yes | `NULL` | Division name text. |
| `DivId` | `NUMBER` | Yes | `NULL` | Normalized link to `Divisions.Id`. |
| `TierId` | `NUMBER` | Yes | `NULL` | Current skill tier ID. |
| `EmployeeHistoryId`| `VARCHAR2(50)`| No | - | Persistent UUID/hash linking historical stints across contracts. |
| `OriginalJoinDate` | `DATE` | Yes | `NULL` | First date employee entered the establishment. |
| `JoinDate` | `DATE` | Yes | `NULL` | Current contract stint commencement date. |
| `LeaveBalance` | `NUMBER` | No | `0` | Current available paid leave balance. |
| `PrevLeaveBalance` | `NUMBER` | No | `0` | Carried over balance from preceding contract periods. |
| `Status` | `VARCHAR2(20)` | No | `'Active'` | `'Active'`, `'Resigned'`, `'Relieved'`, or `'System'`. |
| `ResignDate` | `DATE` | Yes | `NULL` | Formal relieving / resignation date. |
| `ContractEndDate` | `DATE` | Yes | `NULL` | Expected end date under current contract stint. |
| `CurrentEngagementId`| `NUMBER`| Yes | `NULL` | Foreign key pointer to active `EmployeeEngagements.Id`. |
| `Phone` | `VARCHAR2(50)` | Yes | `NULL` | Contact telephone number. |
| `Email` | `VARCHAR2(100)`| Yes | `NULL` | Email address. |
| `Aadhar` | `VARCHAR2(50)` | Yes | `NULL` | National identification / Aadhar number. |
| `Address` | `VARCHAR2(4000)`| Yes | `NULL` | Residential address. |
| `Qualification`| `VARCHAR2(200)`| Yes | `NULL` | Educational qualification (e.g. `'B.Sc Computer Science'`). |
| `Experience` | `NUMBER` | Yes | `NULL` | Total relevant experience in years (e.g. `4.5`). |
| `ExperienceIn` | `VARCHAR2(200)`| Yes | `NULL` | Domain of expertise (e.g. `'Data Entry / MS Office'`). |

#### `EmployeeEngagements`
Historical employment stints linking employees to specific contract periods, tiers, and vendors.
- **Primary Key:** `Id` (Sequence: `SEQ_EmployeeEngagements`, Trigger: `TRG_EmployeeEngagements`)
- **Foreign Keys:** `EmpID` -> `Employees.MasterId` (`ON DELETE CASCADE`), `ContractPeriodId` -> `ContractPeriods.Id` (`ON DELETE SET NULL`), `VendorId` -> `Vendors.Id`, `TierId` -> `Tiers.Id` (`ON DELETE CASCADE`), `PrevEngagementId` -> `EmployeeEngagements.Id`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique stint engagement ID. |
| `EmpID` | `VARCHAR2(50)` | No | - | Employee `MasterId`. |
| `ContractPeriodId`| `NUMBER`| Yes | `NULL` | Contract period under which this stint ran. |
| `TierId` | `NUMBER` | No | - | Skill tier classification for this stint. |
| `VendorId` | `NUMBER` | No | - | Vendor supplier during this stint. |
| `Department` | `VARCHAR2(100)`| Yes | `NULL` | Department name during this stint. |
| `DivId` | `NUMBER` | Yes | `NULL` | Division ID during this stint. |
| `StartDate` | `DATE` | No | - | Stint commencement date. |
| `EndDate` | `DATE` | Yes | `NULL` | Stint conclusion date (NULL if currently active). |
| `EndReason` | `VARCHAR2(50)` | Yes | `NULL` | Reason for stint conclusion (`'Contract Expired'`, `'Resigned'`). |
| `IsCarriedOver`| `NUMBER(1)` | No | `0` | `1` = Leave balance carried over from previous stint. |
| `PrevEngagementId`| `NUMBER` | Yes | `NULL` | Link to immediately preceding engagement stint. |
| `EmployeeId` | `VARCHAR2(50)` | Yes | `NULL` | Historical employee token/ID during this stint. |

#### `EmployeeLeaveCredits`
Explicit leave credit ledger for accruals and credit revisions.
- **Primary Key:** `Id` (Sequence: `SEQ_EmployeeLeaveCredits`, Trigger: `TRG_EmployeeLeaveCredits`)
- **Foreign Keys:** `EmpID` -> `Employees.MasterId` (`ON DELETE CASCADE`), `ContractPeriodId` -> `ContractPeriods.Id` (`ON DELETE CASCADE`)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique credit transaction ID. |
| `EmpID` | `VARCHAR2(50)` | No | - | Employee `MasterId`. |
| `ContractPeriodId`| `NUMBER`| No | - | Target contract period ID. |
| `Amount` | `NUMBER` | No | - | Number of leave days credited (e.g. `2.5`). |
| `EffectiveDate`| `DATE` | No | - | Date on which credit becomes active. |
| `Remarks` | `VARCHAR2(200)`| Yes | `NULL` | Administrative reason for credit. |

---

### 2.5 Attendance Matrix & Staging

#### `Attendance`
Live production daily attendance matrix records.
- **Primary Key:** `Id` (Sequence: `SEQ_Attendance`, Trigger: `TRG_Attendance`)
- **Foreign Keys:** `EmpID` -> `Employees.MasterId`, `EngagementId` -> `EmployeeEngagements.Id`, `ContractPeriodId` -> `ContractPeriods.Id`
- **Unique Constraint:** `(EmpID, Year, Month, Day)`

| Column Name | Data Type | Nullable | Default | Description & Status Codes |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique attendance record ID. |
| `EmpID` | `VARCHAR2(50)` | No | - | Target employee `MasterId`. |
| `EngagementId` | `NUMBER` | Yes | `NULL` | Active stint engagement ID. |
| `ContractPeriodId`| `NUMBER`| Yes | `NULL` | Active contract period ID. |
| `Year` | `NUMBER(4)` | No | - | Calendar year (e.g. `2026`). |
| `Month` | `NUMBER(2)` | No | - | Month index (`0` = January, `11` = December). |
| `Day` | `NUMBER(2)` | No | - | Day of month (`1` to `31`). |
| `StatusValue` | `NUMBER(1)` | Yes | `NULL` | **Status Codes:**<br>`1` = Present<br>`0` = Absent<br>`2` = Paid Leave (CL/EL)<br>`3` = Unpaid Leave (LWP)<br>`NULL` = Unmarked / Non-working |
| `LeaveType` | `VARCHAR2(50)` | Yes | `NULL` | Specific leave type string (e.g. `'CL'`, `'RH'`). |
| `IsHoliday` | `NUMBER(1)` | Yes | `0` | `1` = National / Declared public holiday. |
| `AutoSat` | `NUMBER(1)` | Yes | `0` | `1` = Automatically counted as absent under the 2-Saturday Rule. |
| `Remarks` | `VARCHAR2(500)`| Yes | `NULL` | Remarks (e.g. holiday title or Saturday override reason). |

#### `AttendanceDraft`
Staging table where Sub Users enter provisional attendance before Anchor POC approval.
- **Primary Key:** `Id` (Sequence: `SEQ_AttendanceDraft`, Trigger: `TRG_AttendanceDraft`)
- **Foreign Keys:** `EmpID` -> `Employees.MasterId`, `EngagementId` -> `EmployeeEngagements.Id`, `ContractPeriodId` -> `ContractPeriods.Id`
- **Unique Constraint:** `(EmpID, Year, Month, Day)`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique draft entry ID. |
| `EmpID` | `VARCHAR2(50)` | No | - | Employee `MasterId`. |
| `Year`, `Month`, `Day`| `NUMBER` | No | - | Date coordinates. |
| `StatusValue` | `NUMBER` | Yes | `NULL` | Provisional status code (`1`, `0`, `2`, `3`). |
| `EnteredByPCNO`| `VARCHAR2(50)` | Yes | `NULL` | PCNO of Sub User who keyed in the draft. |
| `EnteredAt` | `TIMESTAMP` | No | `SYSTIMESTAMP`| Initial draft entry timestamp. |
| `LastEditedByPCNO`| `VARCHAR2(50)`| Yes | `NULL` | PCNO of last modifier. |
| `LastEditedAt` | `TIMESTAMP` | No | `SYSTIMESTAMP`| Last modification timestamp. |

---

### 2.6 Payroll, Statutory & Wage Orders

#### `WageOrders`
Government / Directorate minimum wage notification orders.
- **Primary Key:** `Id` (Sequence: `SEQ_WageOrders`, Trigger: `TRG_WageOrders`)
- **Foreign Key:** `MainCategoryId` -> `MainCategory.Id` (`ON DELETE CASCADE`)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique wage order ID. |
| `OrderId` | `VARCHAR2(100)`| No | - | Official order notification reference (e.g. `'WO/2026/04'`). |
| `MainCategoryId`| `NUMBER` | No | - | Main category governed by this order. |
| `EffectiveDate`| `DATE` | No | - | Date order takes statutory effect. |
| `OrderDetails` | `VARCHAR2(4000)`| Yes | `NULL` | Government circular details / gazette text. |
| `CreatedBy` | `VARCHAR2(50)` | No | - | PCNO of administrator who recorded order. |
| `CreatedAt` | `TIMESTAMP` | Yes | `CURRENT_TIMESTAMP`| Record timestamp. |

#### `CategoryWages`
Daily / monthly wage rate mapped to each Tier under a Wage Order.
- **Primary Key:** `Id` (Sequence: `SEQ_CategoryWages`, Trigger: `TRG_CategoryWages`)
- **Foreign Keys:** `WageOrderId` -> `WageOrders.Id` (`ON DELETE CASCADE`), `TierId` -> `Tiers.Id` (`ON DELETE CASCADE`)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique rate ID. |
| `WageOrderId` | `NUMBER` | No | - | Parent wage order ID. |
| `TierId` | `NUMBER` | No | - | Governed skill tier ID. |
| `WageRate` | `NUMBER(10,2)` | No | - | Monetary wage rate (e.g. `980.50` per day). |

#### `StatutoryOrders`
EPF, ESI, and GST statutory deduction rates and ceilings.
- **Primary Key:** `Id` (Sequence: `SEQ_StatutoryOrders`, Trigger: `TRG_StatutoryOrders`)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique statutory revision ID. |
| `OrderId` | `VARCHAR2(100)`| No | - | Government notification reference. |
| `EffectiveDate`| `DATE` | No | - | Date revision takes effect. |
| `EpfRate` | `NUMBER(5,2)` | No | - | EPF percentage rate (e.g. `13.00`%). |
| `EpfLimit` | `NUMBER(10,2)` | No | - | Maximum statutory wage ceiling for EPF (e.g. `15000.00`). |
| `EpfCappedAmount`| `NUMBER(10,2)`| No | - | Maximum monthly capped EPF contribution (e.g. `1950.00`). |
| `GstRate` | `NUMBER(5,2)` | No | `18.00` | GST percentage rate (e.g. `18.00`%). |
| `OrderDetails` | `VARCHAR2(4000)`| Yes | `NULL` | Statutory notes / gazette citations. |

#### `CalculationOverrides`
Manual adjustments to final billable working days prior to wage disbursement.
- **Primary Key:** `(Year, Month, TierId, EmpID)`
- **Foreign Keys:** `EmpID` -> `Employees.MasterId`, `TierId` -> `Tiers.Id` (`ON DELETE CASCADE`)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Year`, `Month`| `NUMBER` | No | - | Month coordinates. |
| `TierId` | `NUMBER` | No | - | Target skill tier ID. |
| `EmpID` | `VARCHAR2(50)` | No | - | Target employee `MasterId`. |
| `FinalDays` | `NUMBER(5,2)` | Yes | `NULL` | Manually overridden billable days (e.g. `24.50`). |
| `Remarks` | `VARCHAR2(500)`| Yes | `NULL` | Mandatory reason for adjustment. |

---

### 2.7 Notices, Remarks & Communication

#### `Notices`
Official circulars, orders, and documents posted by administrators.
- **Primary Key:** `Id` (Sequence: `SEQ_Notices`, Trigger: `TRG_Notices`)
- **Foreign Key:** `MainCategoryId` -> `MainCategory.Id` (`NULL` = Global to all categories)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique notice ID. |
| `Name` | `VARCHAR2(255)`| No | - | Notice title / subject. |
| `FilePath` | `VARCHAR2(500)`| Yes | `NULL` | Server file path for uploaded PDF/Doc attachments. |
| `NoticeText` | `NCLOB` | Yes | `NULL` | Extended announcement body text. |
| `Category` | `VARCHAR2(100)`| Yes | `'General'` | Category tag (e.g. `'Statutory'`, `'General'`). |
| `IsHidden` | `NUMBER(1)` | No | `0` | `1` = Archived / Hidden from users. |
| `UploadDate` | `TIMESTAMP` | No | `SYSTIMESTAMP`| Posting timestamp. |
| `MainCategoryId`| `NUMBER`| Yes | `NULL` | Target main category scope. |

#### `NoticeReads`
Tracks read receipts and read timestamps by user PCNO.
- **Primary Key:** `(NoticeId, PCNO)`
- **Foreign Key:** `NoticeId` -> `Notices.Id` (`ON DELETE CASCADE`)

#### `AttendanceRemarks`
Correction requests submitted by POCs to Admins regarding locked attendance.
- **Primary Key:** `Id` (Sequence: `SEQ_AttendanceRemarks`, Trigger: `TRG_AttendanceRemarks`)
- **Foreign Key:** `MainCategoryId` -> `MainCategory.Id`

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique remark ticket ID. |
| `SubmittedBy` | `VARCHAR2(100)`| No | - | PCNO of submitting POC. |
| `SenderName` | `VARCHAR2(200)`| No | - | Display name of submitting POC. |
| `EmpID` | `VARCHAR2(50)` | No | - | Target employee `MasterId`. |
| `RemarkDate` | `DATE` | No | - | Date coordinate in question. |
| `Message` | `VARCHAR2(1000)`| No | - | Explanation of requested correction. |
| `IsRead` | `NUMBER(1)` | No | `0` | `0` = Unread by Admin, `1` = Reviewed. |
| `CreatedAt` | `TIMESTAMP` | No | `SYSTIMESTAMP`| Submission timestamp. |

#### `AttPocEditRemarks`
Stores right-click POC edit explanations entered on attendance cells.
- **Primary Key:** `Id` (Sequence: `SEQ_AttPocEditRemarks`, Trigger: `TRG_AttPocEditRemarks`)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique cell remark ID. |
| `EmpID` | `VARCHAR2(50)` | No | - | Target employee `MasterId`. |
| `Year`, `Month`, `Day`| `NUMBER` | No | - | Date coordinates. |
| `RemarkType` | `VARCHAR2(50)` | No | `'POCEdit'` | Remark category classification. |
| `Remark` | `VARCHAR2(1000)`| No | - | Justification text. |
| `CreatedBy` | `VARCHAR2(100)`| No | - | PCNO of editor. |
| `CreatedByRole`| `VARCHAR2(50)` | No | `'POC'` | Operating role at time of edit. |
| `CreatedAt` | `TIMESTAMP` | No | `SYSTIMESTAMP`| Edit timestamp. |

---

### 2.8 Comprehensive Audit Trails

#### `Attendance_Audit_Log`
Tracks cell-level attendance modifications.
- **Primary Key:** `Id` (Sequence: `SEQ_AttendanceAuditLog`, Trigger: `TRG_AttendanceAuditLog`)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique audit log ID. |
| `LogTime` | `TIMESTAMP` | No | `SYSTIMESTAMP`| Action timestamp. |
| `EmpID` | `VARCHAR2(50)` | Yes | `NULL` | Target employee `MasterId`. |
| `Year`, `Month`, `Day`| `NUMBER` | Yes | `NULL` | Date coordinates. |
| `OldValue` | `NUMBER(1)` | Yes | `NULL` | Previous attendance status code. |
| `NewValue` | `NUMBER(1)` | Yes | `NULL` | New attendance status code. |
| `ChangedBy` | `VARCHAR2(100)`| Yes | `NULL` | PCNO of user who performed modification. |
| `Reason` | `VARCHAR2(500)`| Yes | `NULL` | Stated justification. |

#### `EmployeeActionLogs`
Tracks employee profile modifications with undoable pre/post JSON states.
- **Primary Key:** `Id` (Sequence: `SEQ_EmployeeActionLogs`, Trigger: `TRG_EmployeeActionLogs`)

| Column Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `Id` | `NUMBER` | No | `SEQ` | Unique log ID. |
| `ActionTime` | `TIMESTAMP` | No | `SYSTIMESTAMP`| Timestamp of action. |
| `ActionType` | `VARCHAR2(50)` | No | - | `'INSERT'`, `'UPDATE'`, `'DELETE'`, `'EXTEND'`. |
| `EmpMasterId` | `VARCHAR2(50)` | No | - | Target employee `MasterId`. |
| `Description` | `VARCHAR2(500)` | No | - | Human-readable change summary. |
| `PreState` | `CLOB` | Yes | `NULL` | JSON snapshot of employee before modification. |
| `PostState` | `CLOB` | Yes | `NULL` | JSON snapshot of employee after modification. |
| `IsUndone` | `NUMBER(1)` | No | `0` | `1` = Action was subsequently reverted/undone. |

#### `AdminActionLog` & `ActionLog`
General administrative and system-wide action audit trails recording `ActionType`, `PerformedBy`, `TargetId`, `PreState`, and `PostState`.

---

### 2.9 Document & Certificate Templates

#### `CertificateTemplates`
Stores dynamic wording and boilerplate templates for generated legal documents.
- **Primary Key:** `TemplateKey`

| Key | Purpose / Usage | Sample Template Value |
| :--- | :--- | :--- |
| `AttDesc1` | Attendance Certificate Header | `This is certify that DEO ({Category}) under GeM Contract No: {ContractNo}, dated: {ContractDate}, Dated On: {DatedOn}` |
| `AttDesc2` | Attendance Vendor Details | `M/s. {VendorName}, {VendorAddress} worked as following, for the period from {StartDate} to {EndDate}` |
| `SatDesc1` | Satisfactory Certificate Opening | `This is to certify that M/s. <b>{VendorName}</b>, {VendorAddress} is engaged as an Industry Partner...` |
| `SatDesc2` | Satisfactory Manpower Count | `The Industry Partner provided <b>{EmpCount}</b> Contract Employees and found working satisfactorily.` |
| `SatSignatory` | Satisfactory Cert Authority | `(Raajita B Reddy)` |
| `CovSubject` | Covering Letter Subject | `HIRING OF MANPOWER SERVICES` |
| `CovBody` | Covering Letter Text | `The copies of the Attendance report along with the wage calculation for {Category} category...` |

---

## 3. High-Performance Composite Indexes

To maintain sub-second response times with 100–500+ concurrent users and large historical datasets, the schema enforces the following composite indexes:

```sql
-- 1. Attendance Fast Monthly Range Queries
CREATE INDEX IDX_ATT_YEAR_MONTH    ON Attendance (Year, Month, StatusValue, EmpID);
CREATE INDEX IDX_ATT_EMP_DATE      ON Attendance (EmpID, Year, Month);
CREATE INDEX IDX_ATT_PERIOD        ON Attendance (ContractPeriodId);

-- 2. Employee Engagements Stints
CREATE INDEX IDX_ENG_PERIOD_END    ON EmployeeEngagements (ContractPeriodId, EndDate);
CREATE INDEX IDX_ENG_EMP_TIER      ON EmployeeEngagements (EmpID, TierId);
CREATE INDEX IDX_ENG_DATES         ON EmployeeEngagements (StartDate, EndDate);

-- 3. Employee Master Lookups & Status
CREATE INDEX IDX_EMP_TIER_STATUS   ON Employees (TierId, Status);
CREATE INDEX IDX_EMP_DIV_STATUS    ON Employees (DivId, Status);
CREATE INDEX IDX_EMP_HIST_ID       ON Employees (EmployeeHistoryId);
CREATE INDEX IDX_EMP_CURR_ENG      ON Employees (CurrentEngagementId);

-- 4. Contract Periods & Active Status
CREATE INDEX IDX_CP_TIER_STATUS    ON ContractPeriods (TierId, Status, StartDate, EndDate);

-- 5. Permission & Security Lookups
CREATE INDEX IDX_USERTIERS_PCNO    ON UserTiers (PCNO, TierId);
CREATE INDEX IDX_USERDIVS_PCNO     ON UserDivisions (PCNO, DivId);
CREATE INDEX IDX_CATSHARE_SHARED   ON CategoryShareGrant (SharedWithPCNO, IsActive);

-- 6. Communication & Audit History
CREATE INDEX IDX_NOTICES_CAT_DATE  ON Notices (Category, UploadDate);
CREATE INDEX IDX_ATTREM_EMP_DATE   ON AttendanceRemarks (EmpID, RemarkDate);
CREATE INDEX IDX_LEAVECRED_EMP     ON EmployeeLeaveCredits (EmpID, ContractPeriodId, EffectiveDate);
CREATE INDEX IDX_POCREM_YEAR_MONTH ON AttPocEditRemarks (Year, Month, EmpID);
```

---

## 4. Special System Seed Records

1. **Global Adjustment Master (`Employees`):**
   ```sql
   INSERT INTO Employees (MasterId, ID, Name, Department, TierId, EmployeeHistoryId, Status, LeaveBalance) 
   VALUES ('GLOBAL', 'GLOBAL', 'GLOBAL Adjustment', NULL, NULL, 'GLOBAL', 'System', 0);
   ```
   *Purpose:* Used by `Attendance.aspx` when an administrator declares a global holiday or organization-wide non-working day across all contract employees simultaneously.
