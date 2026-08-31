# Attendance Recording System (ARS)
## (Skilled, Semi-Skilled)
### Complete End-User Manual: Point of Contact (POC) & Sub User (Data Entry Operator)

```text
========================================================================================
OFFICIAL DOCUMENTATION — FOR INTERNAL USE ONLY
System: ARS — Attendance Recording System (Skilled, Semi-Skilled)
URL: http://windflower.lrde.com/Manpower_Attendance
Target Audience: Division Point of Contact (POC) Users & Sub Users (Data Entry Operators)
Authentication: Corporate Active Directory (LDAP SSO)
Document Version: 2.0 (Updated with Sub User Staging & POC Draft-to-Live Workflow)
Date: August 2026
========================================================================================
```

---

## 📖 Table of Contents

- [1. System Overview & Authentication](#1-system-overview--authentication)
  - [1.1 About the System](#11-about-the-system)
  - [1.2 User Roles & Responsibilities Summary](#12-user-roles--responsibilities-summary)
  - [1.3 Logging In & Domain Authentication](#13-logging-in--domain-authentication)
  - [1.4 Role Selection & In-Session Dynamic Role Switching](#14-role-selection--in-session-dynamic-role-switching)
  - [1.5 User Workspace & Navigation](#15-user-workspace--navigation)
- [2. Sub User (Data Entry Operator) Manual](#2-sub-user-data-entry-operator-manual)
  - [2.1 Sub User Overview & Scope Inheritance](#21-sub-user-overview--scope-inheritance)
  - [2.2 Entering Initial Attendance (Empty Boxes)](#22-entering-initial-attendance-empty-boxes)
  - [2.3 Saving Provisional Drafts (`AttendanceDraft`)](#23-saving-provisional-drafts-attendancedraft)
  - [2.4 Live-Cell Lock & Edit Protection](#24-live-cell-lock--edit-protection)
  - [2.5 Re-Editing Drafts Before Approval (Draft Remarks)](#25-re-editing-drafts-before-approval-draft-remarks)
  - [2.6 Sub User Boundaries & What Requires POC/Admin Action](#26-sub-user-boundaries--what-requires-pocadmin-action)
- [3. Point of Contact (POC / Regular User) Manual](#3-point-of-contact-poc--regular-user-manual)
  - [3.1 POC Role Overview & Authorized Scopes](#31-poc-role-overview--authorized-scopes)
  - [3.2 Empty Box Entry Restriction Explained](#32-empty-box-entry-restriction-explained)
  - [3.3 Reviewing Sub User Drafts (Amber Badges & Counters)](#33-reviewing-sub-user-drafts-amber-badges--counters)
  - [3.4 Re-Editing Saved Records & Drafts (Mandatory Reason Prompt)](#34-re-editing-saved-records--drafts-mandatory-reason-prompt)
  - [3.5 Committing Drafts to Live Production ("Submit Attendance")](#35-committing-drafts-to-live-production-submit-attendance)
  - [3.6 Allowed Editing Windows & Edit Policies (Set by Admin)](#36-allowed-editing-windows--edit-policies-set-by-admin)
- [4. Attendance Grid, Rules & Calculation Engines](#4-attendance-grid-rules--calculation-engines)
  - [4.1 Attendance Grid Cell Values & Badge Reference](#41-attendance-grid-cell-values--badge-reference)
  - [4.2 Keyboard Shortcuts & Quick Entry](#42-keyboard-shortcuts--quick-entry)
  - [4.3 Half-Day (`0.5`) Leave Rules & Cross-Month Pairing Engine](#43-half-day-05-leave-rules--cross-month-pairing-engine)
  - [4.4 Saturday Logic Explained & Monday-to-Friday Rule Engine](#44-saturday-logic-explained--monday-to-friday-rule-engine)
- [5. Leave Ledger, Remarks & Circulars](#5-leave-ledger-remarks--circulars)
  - [5.1 Viewing Monthly Leave Balances & History (`Ledger.aspx`)](#51-viewing-monthly-leave-balances--history-ledgeraspx)
  - [5.2 Sending Remarks & Correction Requests to Admin (`UserRemarks.aspx`)](#52-sending-remarks--correction-requests-to-admin-userremarksaspx)
  - [5.3 Viewing & Downloading Official Notices (`Notices.aspx`)](#53-viewing--downloading-official-notices-noticesaspx)
- [6. Quick Reference, Workflow Diagram & FAQ](#6-quick-reference-workflow-diagram--faq)
  - [6.1 Two-Tier Staging & Approval Workflow Diagram](#61-two-tier-staging--approval-workflow-diagram)
  - [6.2 Saturday Cut Comprehensive Reference Matrix](#62-saturday-cut-comprehensive-reference-matrix)
  - [6.3 Frequently Asked Questions (FAQ) & Troubleshooting](#63-frequently-asked-questions-faq--troubleshooting)

---

# 1. System Overview & Authentication

### 1.1 About the System
The **Attendance Recording System (ARS)** is an enterprise-grade, intranet-hosted web application for managing contract workforce attendance, leave ledgers, wage calculations, and compliance documentation for **Skilled** and **Semi-Skilled** personnel.

The system operates **100% offline within an air-gapped corporate network**, with zero dependencies on the public internet, and authenticates all users securely via **Windows Active Directory (LDAP SSO)**.

---

### 1.2 User Roles & Responsibilities Summary

ARS implements a multi-tier role hierarchy to separate **initial data entry**, **supervisory review**, and **administrative control**:

```
+---------------------------------------------------------------------------------------------------+
|                                  ARS USER ROLE COMPARISON                                         |
+----------------------+--------------------+-------------------------------------------------------+
| User Role            | Target Audience    | Core Capabilities & Operational Scope                 |
+----------------------+--------------------+-------------------------------------------------------+
| Sub User             | Data Entry         | • Performs initial data entry in empty calendar cells |
| (Role 6)             | Operators / Clerks | • Saves provisional attendance as staged Drafts       |
|                      |                    | • Cannot edit finalized live production records       |
|                      |                    | • Cannot submit drafts to live production             |
+----------------------+--------------------+-------------------------------------------------------+
| Point of Contact     | Division Officers  | • Cannot type into empty boxes (done by Sub User)     |
| (POC / Regular User) | & Supervisors      | • Reviews staged drafts submitted by Sub Users        |
| (Role 0)             |                    | • Modifies draft / live cells with mandatory reasons  |
|                      |                    | • Commits drafts to live production (Submit Live)     |
|                      |                    | • Monitors monthly leave ledger & sends Admin remarks |
+----------------------+--------------------+-------------------------------------------------------+
| Category Admin       | HR Managers &      | • Full direct live attendance editing & overrides     |
| & Super Admin        | System Admins      | • Manages employees, contracts, wages, and templates  |
| (Roles 1 & 4)        |                    | • Assigns Sub Users to Anchor POCs; sets edit windows |
+----------------------+--------------------+-------------------------------------------------------+
```

---

### 1.3 Logging In & Domain Authentication

1. Open your web browser (Chrome, Edge, or Firefox) and navigate to the official ARS URL:
   `http://windflower.lrde.com/Manpower_Attendance` (or the IP address provided by IT).
2. Enter your **Windows Domain Username** (login ID or PCNO) and **Password**.
3. Click **Sign In**.

```
+---------------------------------------------------------------+
|       ARS — Attendance Recording System (Skilled, Semi-Skilled)|
|                                                               |
|   Username (Domain / PCNO): [ 1002                          ] |
|   Password:                 [ •••••••••••••••••             ] |
|                                                               |
|                        [  SIGN IN  ]                          |
|                                                               |
|   * Authenticates securely against Corporate Active Directory |
+---------------------------------------------------------------+
```

> [!NOTE]
> **Authentication & Account Verification**:
> - Upon signing in, the system automatically pulls your official Name, Designation, and Division from the corporate HR database.
> - If your account has been revoked or unassigned, the system will display an **Access Denied** notification (`Role 3: Revoked POC`, `Role 7: Revoked Sub User`). Contact HR administration if your access needs restoration.

---

### 1.4 Role Selection & In-Session Dynamic Role Switching

#### A. Login Role Selection Modal (For Multi-Role Users)
If your user account is assigned multiple operational roles (e.g., you are both a **Point of Contact (POC)** for Division A and a **Sub User (Data Entry)** for Division B, or hold Admin privileges), the system presents an interactive **Role Selection Screen** immediately after password verification:

```
+-----------------------------------------------------------------------------------+
|                                SELECT ACTIVE ROLE                                 |
|         Choose the role mode you wish to operate in for this work session:        |
|                                                                                   |
|  [ 👤 Point of Contact (POC) - D-ADMIN                                  Switch -> ]
|     Manage division attendance, review drafts, and submit live records.           |
|                                                                                   |
|  [ ⌨️ Sub User (Data Entry) - Anchor: Alice Smith, Bob Jones            Switch -> ]
|     Enter daily attendance drafts for assigned Anchor POC scopes.                 |
+-----------------------------------------------------------------------------------+
```
Click any role tile to enter the workspace under that operating profile.

#### B. Switching Roles In-Session (Without Logging Out)
You do **not** need to log out to switch roles. At any time:
1. Click your **Profile Name** in the top-right navigation bar.
2. In the dropdown menu, locate the **Switch Role** section.
3. Click your desired role (e.g., switch from *Point of Contact (POC)* to *Sub User (Data Entry)*).
4. The page reloads cleanly with the new role permissions and division scopes active.

---

### 1.5 User Workspace & Navigation

After login, you arrive at the **My Workspace** Dashboard:

```
+---------------------------------------------------------------------------------------------------+
| ARS TopBar:  [🏢 ARS Logo]  [Attendance]  [Ledger]  [Remarks]  [Notices]    [🌙] [👤 User (POC)] [Logout] |
+---------------------------------------------------------------------------------------------------+
| PROFILE SIDEBAR           | WORKSPACE MODULE CARDS                                                |
| [Official Photo]          |                                                                       |
| Name: Hemanth Kumar       |  +--------------------+  +--------------------+                       |
| PCNO: 1001                |  |  📅 Attendance     |  |  📑 Leave Ledger   |                       |
| Role: USER (POC)          |  |  Mark & review     |  |  Track leave       |                       |
| Accessible Divisions:     |  |  division grid     |  |  balances & days   |                       |
| • AD-ADMIN                |  +--------------------+  +--------------------+                       |
| • D-ADMIN                 |  +--------------------+  +--------------------+                       |
| • D-KRM                   |  |  💬 Remarks        |  |  📢 Notices        |                       |
|                           |  |  Send corrections  |  |  View & download   |                       |
| Pending Drafts: [ 12 ]    |  |  to Admin inbox    |  |  official circulars|                       |
|                           |  +--------------------+  +--------------------+                       |
+---------------------------+-----------------------------------------------------------------------+
```

- **Top Navigation Bar**: Renders on all content pages to provide quick links and role switcher.
- **Pending Drafts Badge**: Renders a warning counter badge alerting POCs whenever Sub Users have staged new drafts awaiting review.

---

# 2. Sub User (Data Entry Operator) Manual

The **Sub User (Role 6)** is designed for fast, accurate initial data entry without the risk of accidentally corrupting finalized live production attendance.

### 2.1 Sub User Overview & Scope Inheritance
- A Sub User is linked to one or more **Anchor POCs** (`SubUserAnchor`).
- Sub Users automatically inherit the combined list of divisions and skill tiers assigned to their Anchor POCs.
- Sub Users **enter initial attendance** and save it into a provisional staging table (`AttendanceDraft`).

---

### 2.2 Entering Initial Attendance (Empty Boxes)
1. Log in or switch to **Sub User (Data Entry)** mode.
2. Open the **Attendance** page from the top navigation.
3. Select the target **Month**, **Year**, **Category**, and **Division** filters.
4. Locate the employee and day column. Empty calendar cells are fully editable white boxes.
5. Click the cell and enter the attendance value:
   - Press `1` $\rightarrow$ **Present (`1`)**
   - Press `0` $\rightarrow$ **Absent (`0`)**
   - Press `5` $\rightarrow$ **Half-Day (`0.5`)**
6. You can use keyboard **Arrow Keys** (`Left`, `Right`, `Up`, `Down`) to navigate between cells quickly like a spreadsheet.

---

### 2.3 Saving Provisional Drafts (`AttendanceDraft`)
1. After entering attendance for the required employees and dates, click **Save Attendance** (top right or bottom of the grid).
2. The system validates the entries and saves them into the staging database.
3. A green toast notification confirms: **"Draft saved successfully."**
4. The entered cells now display an **Amber / Yellow Draft Badge** indicating they are safely staged and pending POC review.

> [!IMPORTANT]
> **Drafts are Provisional**:
> Saving attendance in Sub User mode saves records to the `AttendanceDraft` staging table. These records are **not yet live** in the official payroll or certificate registers until committed by your Anchor POC.

---

### 2.4 Live-Cell Lock & Edit Protection

To safeguard official records, ARS implements strict **Live-Cell Protection**:

- Once an Anchor POC or Administrator has committed attendance records to the live production database (`Attendance` table), those cells are **permanently locked (read-only)** for Sub Users.
- Locked cells appear with a subtle grey background and a lock icon:
  `[ 1 ] (Readonly - Submitted live attendance cannot be edited by Sub Users)`
- If a Sub User attempts to click or type into a finalized live cell, the system blocks the input and displays a warning toast:
  > *"Submitted attendance cannot be edited by Sub Users. Contact your Anchor POC for corrections."*

---

### 2.5 Re-Editing Drafts Before Approval (Draft Remarks)
- While attendance is still in **Draft** state (prior to POC live submission), Sub Users can modify cell values freely.
- If modifying an already-saved draft cell, the system prompts for a brief **Edit Reason / Justification**.
- Enter a short description (e.g., *"Typo corrected from Absent to Present per site sign-in sheet"*) and click **Confirm**.
- Click **Save Attendance** to update the draft.

---

### 2.6 Sub User Boundaries & What Requires POC/Admin Action
| Action | Allowed for Sub User? | Who Can Perform It? |
| :--- | :---: | :--- |
| **Enter attendance into empty cells** | ✅ **YES** | Sub User (Data Entry) |
| **Save provisional drafts** | ✅ **YES** | Sub User (Data Entry) |
| **Edit unsubmitted draft cells** | ✅ **YES** | Sub User (with edit remark) |
| **Modify submitted live attendance** | ❌ **BLOCKED** | Anchor POC / Administrator |
| **Submit / Commit drafts to live DB** | ❌ **BLOCKED** | Anchor POC |
| **Declare official Public Holidays** | ❌ **BLOCKED** | Administrator |
| **Manage GLOBAL adjustment rows** | ❌ **BLOCKED** | Administrator |

---

# 3. Point of Contact (POC / Regular User) Manual

As a **Point of Contact (POC)**, you act as the **supervisor and reviewer** for your assigned division(s).

### 3.1 POC Role Overview & Authorized Scopes
- Scoped strictly to your authorized **Divisions** and **Categories** assigned by HR Administration.
- Responsible for reviewing draft attendance submitted by Sub Users, making verified adjustments, and submitting the records live to production.

---

### 3.2 Empty Box Entry Restriction Explained

> [!IMPORTANT]
> **Why Empty Cells Are Locked in POC Mode**:
> In accordance with organizational data integrity rules, **initial attendance entry must be performed in Sub User mode**. 
> - When operating in **POC Mode**, completely empty calendar cells display a **dashed border** with a tooltip:
>   `"Empty box: Initial data entry must be done by Sub User. Switch to Sub User role to enter data."`
> - If you try to click an empty box while in POC mode, a prompt will remind you to switch to Sub User mode.
> - If you are authorized as both POC and Sub User, simply click your name in the topbar and choose **Sub User (Data Entry)** to fill empty boxes, save as draft, and switch back to POC mode to submit.

---

### 3.3 Reviewing Sub User Drafts (Amber Badges & Counters)
When Sub Users save attendance, the POC is alerted in two ways:
1. **TopBar Notification & Dashboard Counter**: The profile card and top navigation display a yellow badge with the number of pending drafts (e.g., `Pending Drafts: 14`).
2. **Attendance Grid Visual Highlights**:
   - Draft cells display with an **Amber / Yellow border** and a `[Draft]` tag.
   - Cells show the staged value (e.g., `1`, `0`, `0.5`, `Paid`, `Unpaid`).

---

### 3.4 Re-Editing Saved Records & Drafts (Mandatory Reason Prompt)

POCs have the authority to edit both **unsubmitted drafts** and **already-saved live attendance** (within the allowed editing window).

Whenever a POC changes a previously entered attendance cell:
1. Click the cell (or press a new key: `1`, `0`, `5`).
2. The **Edit Reason Required** modal appears immediately:

```
+-----------------------------------------------------------------------------------+
|                             EDIT REASON REQUIRED                                  |
|   You are changing a saved attendance record for HEMANTH KUMAR (Day: 14).         |
|                                                                                   |
|   Reason for Change: *                                                            |
|   [ Employee was on authorized duty at site B per supervisor confirmation.      ] |
|                                                                                   |
|   Select / Common Reasons (Click to select):                                      |
|   [ Duty Slip Attached ]  [ Biometric Error ]  [ Typo Correction ]  [ Approved PL]|
|                                                                                   |
|                        [  ✓ Confirm Change  ]    [  ✕ Cancel  ]                   |
+-----------------------------------------------------------------------------------+
```
3. Type a clear reason or click one of the quick reason chips.
4. Click **Confirm Change**.
5. Click **Save Attendance** to save the updated values and audit reasons.

> [!NOTE]
> All edit reasons are logged into `AttPocEditRemarks` and `Attendance_Audit_Log` with your PCNO, timestamp, and previous/new values. Administrators can review this audit trail at any time.

---

### 3.5 Committing Drafts to Live Production ("Submit Attendance")

Once you have verified the month's attendance and drafts:
1. In the top-right action area of the **Attendance** page, click the **Submit Attendance** (or **Submit Live**) button.
2. The system merges all staged records from `AttendanceDraft` into the official production `Attendance` table.
3. Staged records are purged from the draft staging table and marked finalized.
4. The grid refreshes automatically with standard green/grey finalized badges.

```
+-----------------------------------------------------------------------------------+
| [Sub User Drafts]  === (POC Reviews & Clicks "Submit Attendance") ===>  [Live DB] |
| (AttendanceDraft)                                                    (Attendance) |
+-----------------------------------------------------------------------------------+
```

---

### 3.6 Allowed Editing Windows & Edit Policies (Set by Admin)

The Administrator controls how far back a POC can enter or modify attendance. This setting is defined per category:

| Policy Mode | Configuration Name | Operational Behavior |
| :---: | :--- | :--- |
| **Mode 0** | **Past N-Days Rolling Window** | You can edit dates within the last **N days** from today (e.g., past 3 days). Dates older than N days or future dates are locked. |
| **Mode 1** | **Strict Current Month Only** | You can edit any date of the **current calendar month** up to and including today. Future dates and previous months are locked. |
| **Mode 2** | **Grace Cutoff Day Window** | Current month is editable up to today. The **previous month** is editable only until the **Nth day** of the current month (e.g., up to the 3rd of May for April attendance). After the 3rd, the previous month is permanently locked. |

> [!WARNING]
> **Locked Past Dates**:
> If you need to correct attendance for a locked past month outside your allowed window, you cannot edit it in the grid. You must submit an **Attendance Correction Request** via the **Remarks** module to HR Administration (see [Section 5.2](#52-sending-remarks--correction-requests-to-admin-userremarksaspx)).

---

# 4. Attendance Grid, Rules & Calculation Engines

### 4.1 Attendance Grid Cell Values & Badge Reference

The calendar grid displays one column per calendar day and one row per contract worker. Each cell contains a primary status number and an optional descriptor label:

```
+---------------------------------------------------------------------------------------------------+
| Cell Display  | Value | Label Below Cell   | Complete Meaning & Payroll Effect                     |
+---------------+-------+--------------------+-------------------------------------------------------+
| [ 1 ]         | 1     | (none)             | Present — Employee worked their normal shift. Payable.|
+---------------+-------+--------------------+-------------------------------------------------------+
| [ 0 ]         | 0     | (none)             | Absent — Unexcused absence. Not payable.              |
+---------------+-------+--------------------+-------------------------------------------------------+
| [ 1 ]         | 1     | Paid               | Paid Leave — Authorized leave. Counts as 1 payable day|
|               |       |                    | and deducts 1 day from leave balance.                 |
+---------------+-------+--------------------+-------------------------------------------------------+
| [ 0 ]         | 0     | Unpaid             | Unpaid Leave — Approved absence without pay.          |
|               |       |                    | Not payable; no leave balance deduction.             |
+---------------+-------+--------------------+-------------------------------------------------------+
| [ 0.5 ]       | 0.5   | Carried (Half Day) | First Half-Day — Recorded & held as Carried. Counts as |
|               |       |                    | 1 payable day temporarily pending pairing.            |
+---------------+-------+--------------------+-------------------------------------------------------+
| [ 1 ]         | 1     | Paired Paid        | Second Half-Day Paired Paid — Combined pair counts as |
|               |       |                    | 1 payable day and deducts 1 full leave day.           |
+---------------+-------+--------------------+-------------------------------------------------------+
| [ 0 ]         | 0     | Paired Unpaid      | Second Half-Day Paired Unpaid — Second day is unpaid  |
|               |       |                    | (0 payable days); no leave deduction.                 |
+---------------+-------+--------------------+-------------------------------------------------------+
| [ 0 ]         | 0     | Auto Sat-Cut       | Auto Saturday Cut — Saturday cut due to absence during|
|               |       |                    | Mon–Fri working days of that week. Not payable.       |
+---------------+-------+--------------------+-------------------------------------------------------+
| [ H ]         | H     | Holiday            | Public Holiday — Declared organization holiday.       |
|               |       |                    | Credited as present and payable.                      |
+---------------+-------+--------------------+-------------------------------------------------------+
| [ 1 ] (Amber) | 1/0/HD| [Draft]            | Staged Draft — Provisional entry by Sub User.         |
|               |       |                    | Pending POC review and live submission.               |
+---------------+-------+--------------------+-------------------------------------------------------+
| [   ] (Dashed)| —     | (none)             | Empty Box — Initial entry reserved for Sub Users.     |
+---------------+-------+--------------------+-------------------------------------------------------+
```

---

### 4.2 Keyboard Shortcuts & Quick Entry

For maximum speed during attendance entry:
- **`1`**: Sets the cell to **Present (1)**.
- **`0`**: Sets the cell to **Absent (0)**.
- **`5`**: Sets the cell to **Half-Day (0.5)**.
- **`Arrow Keys` (`←`, `→`, `↑`, `↓`)**: Navigate smoothly across days and employees without using the mouse.
- **`Right-Click on Cell`**: Opens cell context menu (View Audit History / View Edit Remarks).

---

### 4.3 Half-Day (`0.5`) Leave Rules & Cross-Month Pairing Engine

ARS implements an automated **Two-Step Half-Day Pairing Engine** that tracks half-days chronologically across the worker's entire contract engagement, even across different calendar months:

#### Step 1: First Half-Day — "Carried"
- When a worker takes their first half-day, enter `0.5` (Press `5`).
- The cell displays `0.5` with the label **Half day** / **Carried**.
- The day is credited as **1 payable day** in the current month.
- **No leave balance is deducted yet** — the system holds it in memory awaiting a second half-day.

#### Step 2: Second Half-Day — "Paired" (Paid vs Unpaid)
When the employee takes their next half-day (in the same month or a subsequent month), the system resolves the pair:

```
+------------------+---------------------+----------------------+------------------+--------------------+
| Pairing Selected | First Half-Day Cell | Second Half-Day Cell | Leave Deduction  | Payable Days       |
+------------------+---------------------+----------------------+------------------+--------------------+
| Paired Paid      | Remains 0.5         | Shows 1 (Paired Paid)| -1.0 Leave Day   | Both days count as |
|                  | (Half Day)          |                      | from balance     | 1 payable day each |
+------------------+---------------------+----------------------+------------------+--------------------+
| Paired Unpaid    | Remains 0.5         | Shows 0 (Paired Unp) | 0 Leave Days     | First day payable, |
|                  | (Half Day)          |                      | (No deduction)   | Second day unpaid  |
+------------------+---------------------+----------------------+------------------+--------------------+
```

> [!NOTE]
> **Ledger Auto-Remark**:
> Once paired, the Leave Ledger automatically generates a remark:
> `"2 half days: 12-Jul-2026 & 18-Aug-2026"`, maintaining full audit traceability across months.

---

### 4.4 Saturday Logic Explained & Monday-to-Friday Rule Engine

Contract workforce agreements require full attendance across the 5 standard weekdays (Monday through Friday) to qualify for Saturday wages.

#### How Saturday Attendance is Evaluated:
After every attendance save, ARS automatically evaluates the Monday-to-Friday attendance for the week containing that Saturday. An employee is considered to have **"Came / Attended"** on a weekday if their cell has any of the following:
- Value = `1` (Present)
- Value = `0.5` (Half-Day / Carried)
- Leave Type = `Paid` (Paid Leave)
- Leave Type = `Paired Paid` or `Paired Unpaid`
- Day is a declared `Public Holiday`

#### Weekday Attendance Scenarios:
1. **Attended all 5 weekdays (Mon–Fri)**: $\rightarrow$ **Saturday is Present (`1`)** (Credited as payable).
2. **Absent on even ONE weekday without paid leave**: $\rightarrow$ **Saturday = Auto Sat-Cut (`0`)** (Unpaid).
3. **Mid-Week Joinee (Joined Tuesday–Friday)**: $\rightarrow$ Treated as **Auto Saturday Cut (`0`)** in that initial partial week.

> [!IMPORTANT]
> **Saturdays are Locked for POC & Sub Users**:
> Saturday cells are strictly computed by the system engine and cannot be manually edited by POCs or Sub Users. If an employee performed authorized compensatory duty on a Saturday despite an absence, notify HR via an **Attendance Correction Remark** so an Administrator can apply an authorized override.

---

# 5. Leave Ledger, Remarks & Circulars

### 5.1 Viewing Monthly Leave Balances & History (`Ledger.aspx`)

The **Leave Ledger** provides a real-time summary of attendance counts, leave deductions, and closing quotas for your assigned workers.

```
+---------------------------------------------------------------------------------------------------+
| S.No | ID   | Name          | Directorate | Opening | Paid | Half | Unpaid | Sat-Cut | Closing | Present | Final | Remarks       |
+------+------+---------------+-------------+---------+------+------+--------+---------+---------+---------+-------+---------------+
| 1    | 1001 | Hemanth Kumar | D-ADMIN     | 2.0     | 1.0  | 0.5  | 0      | 0       | 1.0     | 26.0    | 26.0  | 2 half days.. |
| 2    | 1004 | Aishwarya S   | D-ADMIN     | 3.0     | 0    | 0    | 1      | 1       | 3.0     | 24.0    | 24.0  | Joined 04-Aug |
+---------------------------------------------------------------------------------------------------+
```

#### Ledger Column Breakdown:
- **ID / Master ID**: Official security entry pass ID and system master identifier.
- **Directorate / Category**: Division and skill tier (*Skilled DEO, Semi-Skilled Attender*).
- **Opening Balance**: Leave days carried forward from the previous month (plus initial contract grants).
- **Paid Leaves Taken**: Authorized paid leave days consumed this month (including paired half-days).
- **Half-Days**: Unpaired carried half-days currently pending pairing.
- **Unpaid Absences**: Total unpaid absent days (does not deduct leave quota; reduces payable days).
- **Saturday Cuts**: Total number of Auto Saturday Cuts triggered this month.
- **Closing Balance**: Remaining leave quota ($\text{Opening} - \text{Paid Leaves Taken}$). Automatically carries forward to the next month.
- **Present Days**: Total computed payable days for the month (including global adjustments).
- **Final Days**: Final approved payable days used for billing and payroll certificates.
- **Remarks**: Auto-generated system notes (half-day pairing dates, join/resign events, admin overrides).

---

### 5.2 Sending Remarks & Correction Requests to Admin (`UserRemarks.aspx`)

Navigate to **Remarks** from the top menu or dashboard. Use this interface when you need HR Administration to adjust a locked past date, override a Saturday cut, or review special circumstances.

```
+-----------------------------------------------------------------------------------+
|                                 SUBMIT NEW REMARK                                 |
|                                                                                   |
|   Select Employee: [ 1001 - HEMANTH KUMAR (D-ADMIN)                             ] |
|   Select Date(s):  [ 2026-08-12 ] [ + Add Date ]                                  |
|                    Dates Added: [ 12-Aug-2026 ✕ ] [ 13-Aug-2026 ✕ ]               |
|                                                                                   |
|   Remark Type:                                                                    |
|   (•) Attendance Correction / Changes                                             |
|   ( ) Other Related Remarks                                                       |
|                                                                                   |
|   Reason / Description: *                                                         |
|   [ Employee was on authorized field trial duty. Kindly update status from       ] |
|   [ Absent (0) to Present (1). Duty slip attached with division supervisor.       ] |
|                                                                                   |
|                              [  ✉️ Send Remark  ]                                 |
+-----------------------------------------------------------------------------------+
```

#### Steps to Submit a Remark:
1. Select the **Employee** from your assigned division dropdown.
2. Select the **Date(s)** of concern using the date picker and click **Add**.
3. Choose the **Remark Type**:
   - **Attendance Correction / Changes**: Use when requesting a specific attendance status change on locked past dates.
   - **Other Related Remarks**: Use for general administrative communication, leave balance queries, or policy notifications.
4. Enter a detailed **Reason / Description**.
5. Click **Send Remark**. The request is delivered directly to the Administrator Remarks Inbox.
6. Track the status of your requests (*Pending Review* / *Resolved by Admin*) in the **My Sent Remarks** table below.

---

### 5.3 Viewing & Downloading Official Notices (`Notices.aspx`)

The **Notices** module displays official organizational announcements, administrative orders, and holiday circulars published by HR:
- Notices are sorted in reverse chronological order (newest first).
- Click **Read Notice / View Attachment** to view or download attached files (**PDF**, **Word**, **Excel**).
- You will only see circulars designated as visible to your division/role by HR Administration.

---

# 6. Quick Reference, Workflow Diagram & FAQ

### 6.1 Two-Tier Staging & Approval Workflow Diagram

```
                 +-------------------------------------------------------+
                 |              SUB USER (Data Entry Clerk)              |
                 |  • Keys daily attendance into empty calendar boxes    |
                 |  • Modifies drafts with audit reasons                 |
                 |  • Clicks [Save Attendance]                           |
                 +---------------------------+---------------------------+
                                             |
                                             v
                 +-------------------------------------------------------+
                 |          STAGING TABLE: AttendanceDraft               |
                 |  • Records stored with [Draft] yellow styling         |
                 |  • Live production records remain unchanged           |
                 +---------------------------+---------------------------+
                                             |
                               [System alerts POC]
                      (TopBar Counter & Pending Badges)
                                             |
                                             v
                 +-------------------------------------------------------+
                 |             ANCHOR POC (Division Supervisor)          |
                 |  • Reviews staged draft badges in Attendance Grid     |
                 |  • Edits draft / live cells with mandatory reasons    |
                 |  • Clicks [Submit Attendance / Submit Live]           |
                 +---------------------------+---------------------------+
                                             |
                                             v
                 +-------------------------------------------------------+
                 |           LIVE PRODUCTION DB: Attendance              |
                 |  • Drafts merged into official Attendance table       |
                 |  • Staging records purged from AttendanceDraft        |
                 |  • Live cells locked for Sub Users                    |
                 |  • Reflected in Ledger, Calculations & Certificates   |
                 +-------------------------------------------------------+
```

---

### 6.2 Saturday Cut Comprehensive Reference Matrix

| Mon | Tue | Wed | Thu | Fri | Saturday Result | Reason / Explanation |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **P** | **P** | **P** | **P** | **P** | **Present (1)** | Full attendance on all 5 weekdays. |
| **Absent** | **P** | **P** | **P** | **P** | **Auto Sat-Cut (0)** | Monday absence cuts Saturday. |
| **P** | **P** | **Absent** | **P** | **P** | **Auto Sat-Cut (0)** | Mid-week absence cuts Saturday. |
| **P** | **P** | **P** | **P** | **Absent** | **Auto Sat-Cut (0)** | Friday absence cuts Saturday. |
| **P** | **P** | **HD (Carried)** | **P** | **P** | **Present (1)** | Carried Half-Day counts as attended. |
| **P** | **P** | **HD (Paired)** | **P** | **P** | **Present (1)** | Paired Half-Day (Paid or Unpaid) counts as attended. |
| **P** | **P** | **PL (Paid)** | **P** | **P** | **Present (1)** | Authorized Paid Leave counts as attended. |
| **P** | **P** | **Holiday** | **P** | **P** | **Present (1)** | Public Holiday counts as attended. |
| — | **Joined** | **P** | **P** | **P** | **Auto Sat-Cut (0)** | Mid-week joinee was absent on Monday. |

---

### 6.3 Frequently Asked Questions (FAQ) & Troubleshooting

#### Q1: I am logged in as a POC. Why are empty calendar cells dashed and read-only?
**A:** Under ARS workflow rules, initial data entry into empty boxes is designated for **Sub Users (Data Entry Operators)**. If you need to enter initial attendance yourself, switch to your **Sub User** role using the topbar profile menu, enter the attendance, save as draft, and switch back to POC mode to submit live.

#### Q2: I am a Sub User. Why can't I edit certain cells that already show attendance?
**A:** Those cells contain **finalized live production attendance** that has already been submitted by a POC or saved by an Admin. To prevent data corruption, live cells are permanently locked for Sub Users. If a live cell is incorrect, ask your Anchor POC or HR Admin to correct it.

#### Q3: How do I know if my Sub User has saved attendance drafts?
**A:** When you log in as a POC, the top navigation bar displays a yellow pending drafts badge (e.g., `Pending Drafts: 8`), and cells in the Attendance grid will display with amber draft badges.

#### Q4: What is the difference between "Save Attendance" and "Submit Attendance"?
**A:** 
- **Save Attendance (in Sub User mode)**: Saves provisional entries into the `AttendanceDraft` staging table.
- **Submit Attendance (in POC mode)**: Merges all verified drafts into the live `Attendance` production table for payroll and document generation.

#### Q5: I tried to change an attendance value and a popup asked for a reason. What should I write?
**A:** Provide a brief, factual explanation for the audit log (e.g., *"Typo correction — employee was present at site"* or *"Duty slip verified"*). You can also click one of the quick pre-set reason buttons.

#### Q6: Why is Saturday showing as Auto Sat-Cut when the employee was present on Friday?
**A:** The system checks **ALL 5 weekdays (Monday through Friday)**, not just Friday. If the employee was absent on Tuesday, Wednesday, or Thursday without paid leave, Saturday is automatically cut. Check the entire Monday–Friday week.

#### Q7: An employee took a half-day in July and another in August. Will they be paired?
**A:** **Yes.** ARS tracks half-days chronologically across the entire contract period with zero month boundary restrictions. The July carried half-day will automatically pair with the August half-day when August attendance is saved.

#### Q8: A past month's attendance is locked and I cannot click any cells. How do I fix an error?
**A:** Navigate to **Remarks** (`UserRemarks.aspx`), click **New Remark**, select **Attendance Correction / Changes**, pick the employee and date(s), explain the correction needed, and click **Send Remark**. HR Administration will receive your request and apply the override.

---
```text
========================================================================================
End of Official User Manual — Attendance Recording System (ARS)
Point of Contact (POC) & Sub User Perspectives • LRDE / Windflower Intranet
========================================================================================
```
