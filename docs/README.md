# Attendance Management System (AMS) — Developer Handover & System Architecture Documentation

Welcome to the complete developer handover and technical architecture suite for the **Attendance Management System (AMS)**.

This documentation has been systematically generated to ensure that any software engineer can fully understand, debug, maintain, and extend the entire application independently without requiring assistance from the original author.

---

## 📚 Master Chapter Index

| Chapter | Title | Focus Area & Key Topics |
| :---: | :--- | :--- |
| **[00](file:///e:/attendence/docs/developer_handover/00_MASTER_INDEX_AND_ARCHITECTURE.md)** | **Master Index & System Architecture** | High-level system topology, technology stack (.NET 4.5 WebForms, C#, Oracle, LDAP), request lifecycle, session dictionary, and role hierarchy (Roles 0–7). |
| **[01](file:///e:/attendence/docs/developer_handover/01_DATABASE_SCHEMA_AND_RELATIONS.md)** | **Complete Database Schema & Data Dictionary** | Complete ER diagram, 25+ Oracle tables, fields, constraints, foreign keys, sequences, triggers, composite indexes, and seed records. |
| **[02](file:///e:/attendence/docs/developer_handover/02_CORE_UTILITIES_DBHELPER_LOGGER_AD.md)** | **Core Utilities, Data Layer & Authentication Engine** | Deep dive into `DBHelper.cs` (connection pooling, background auto-closing), `ActionLogger.cs` (reversible JSON state snapshots), and `ADHelper.cs` (LDAP binding). |
| **[03](file:///e:/attendence/docs/developer_handover/03_AUTHENTICATION_AND_LAYOUT_LOGIN_SITEMASTER.md)** | **Authentication & Global Layout Engine** | `Login.aspx` + `Login.aspx.cs` authentication flow, role selection modal, session setup, and `Site.Master` dynamic navigation/notification badges. |
| **[04](file:///e:/attendence/docs/developer_handover/04_ATTENDANCE_MODULE_PART1_CORE_AND_LOGIC.md)** | **Attendance Management (Part 1: Core Grid & Business Logic)** | Monthly attendance grid matrix, status codes (P, A, L, UL, H, S), Auto-Saturday rule, public holiday backfill, and working days calculations. |
| **[05](file:///e:/attendence/docs/developer_handover/05_ATTENDANCE_MODULE_PART2_DRAFTS_PERMISSIONS_AUDIT.md)** | **Attendance Management (Part 2: Sub-User Drafts & Auditing)** | Staged sub-user draft pipeline (`AttendanceDraft`), Anchor POC review/commit, retrospective edit window policies, right-click cell remarks, and audit trail. |
| **[06](file:///e:/attendence/docs/developer_handover/06_EMPLOYEE_MANAGEMENT_MODULE.md)** | **Employee Lifecycle & Master Management** | Employee master records, multi-stint engagements (`EmployeeEngagements`), contract extensions, leave credit ledger (`EmployeeLeaveCredits`), resignations, and undo history. |
| **[07](file:///e:/attendence/docs/developer_handover/07_CONTRACTS_AND_VENDORS_MODULE.md)** | **Contracts & Vendor Ecosystem** | Vendor registry, dynamic multi-level escalation contacts (`VendorContacts`), GeM contract periods (`ContractPeriods`), extensions, and background auto-close. |
| **[08](file:///e:/attendence/docs/developer_handover/08_CALCULATION_AND_WAGES_PAYROLL_MODULE.md)** | **Payroll Calculations, Wage Orders & Statutory Engine** | Government wage orders (`WageOrders`, `CategoryWages`), statutory EPF/GST math (`StatutoryOrders`), attendance reconciliation, and manual overrides (`CalculationOverrides`). |
| **[09](file:///e:/attendence/docs/developer_handover/09_DOCUMENT_GENERATION_AND_TEMPLATES.md)** | **Automated Document Generation & Certificate Engine** | Dynamic generation of Satisfactory Certificates, Covering Letters, Format 8, and Attendance Certificates using customizable placeholder templates (`CertificateTemplates`). |
| **[10](file:///e:/attendence/docs/developer_handover/10_ADMIN_MANAGEMENT_AND_SECURITY_POLICIES.md)** | **Administration, Hierarchical Categories & Security Policies** | User role administration (`AppUsers`), division assignments (`UserDivisions`), sub-user anchors (`SubUserAnchor`), category sharing (`CategoryShareGrant`), and edit/view policies. |
| **[11](file:///e:/attendence/docs/developer_handover/11_NOTICES_REMARKS_AND_LEDGER_MODULES.md)** | **Communication, Notices, Remarks & Financial Ledger** | Official circulars board with read receipts (`Notices`, `NoticeReads`), POC-to-Admin attendance correction request tickets (`AttendanceRemarks`), and financial ledger. |
| **[12](file:///e:/attendence/docs/developer_handover/12_DEVELOPER_MAINTENANCE_AND_MODIFICATION_GUIDE.md)** | **Developer Recipe & Modification Handbook** | Step-by-step recipes: Adding new DB fields, adding new pages, altering wage formulas, configuring LDAP, Oracle pooling troubleshooting, and deployment guide. |

---

## 🛠️ Quick Start Guide for New Developers

1. **Prerequisites:**
   - Microsoft Visual Studio 2019+ or MSBuild (.NET Framework 4.5)
   - Oracle Database 11g R2 / 12c / 19c / XE
   - Microsoft IIS (for production deployment)
2. **Database Setup:**
   Run [oracle_setup.sql](file:///e:/attendence/oracle_setup.sql) as `SYSTEM` in your Oracle SQL client.
3. **Local Authentication:**
   Log in with username `1001` (Admin) or `1002` (POC). Any password is accepted under local offline testing mode.
