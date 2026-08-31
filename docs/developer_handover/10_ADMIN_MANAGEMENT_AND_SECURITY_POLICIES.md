# Chapter 10: Administration, Hierarchical Categories & Security Policies

This document details the user role administration engine ([AdminManagement.aspx](file:///e:/attendence/AdminManagement.aspx) / [AdminManagement.aspx.cs](file:///e:/attendence/AdminManagement.aspx.cs)) and the organizational settings interface ([Settings.aspx](file:///e:/attendence/Settings.aspx) / [Settings.aspx.cs](file:///e:/attendence/Settings.aspx.cs)).

---

## 1. User Administration & Role Lifecycle ([AdminManagement.aspx](file:///e:/attendence/AdminManagement.aspx))

The **Admin Management Module** controls all system access grants, user accounts, division scopes, and cross-admin delegation.

```
+-----------------------------------------------------------------------------------+
| TABS: [Non-Admins (POCs)] | [Sub Users] | [Admins] | [Super Admins] | [Share Grants] |
+-----------------------------------------------------------------------------------+
```

### 1.1 Role Management & Integer State Machine
Access is governed by integer codes stored in `AppUsers.Role`. Revoking an account does not delete data; it transitions the account into its corresponding **Revoked State Code**, immediately terminating active sessions while preserving historical audit trails:

```
[Super Admin: 4] <---- Revoke / Grant ----> [Revoked Super Admin: 5]
[Admin: 1]       <---- Revoke / Grant ----> [Revoked Admin: 2]
[POC User: 0]    <---- Revoke / Grant ----> [Revoked POC User: 3]
[Sub User: 6]    <---- Revoke / Grant ----> [Revoked Sub User: 7]
```

### 1.2 POC Division & Tier Mapping
When creating or editing a Regular User (POC):
- **Authorized Divisions (`UserDivisions`):** Checkboxes specify which directorates (e.g. `'D-ADMIN'`, `'D-KRM'`) the POC can view and mark attendance for.
- **Allowed Tiers (`UserTiers`):** Checkboxes specify which skill tiers (e.g. Skilled DEO, Unskilled Attender) within those divisions are visible to the POC.

### 1.3 Sub User Anchor Assignment (`SubUserAnchor`)
Sub Users do not have standalone division mappings; they inherit their operational scope directly from their assigned **Anchor POCs**:
```sql
INSERT INTO SubUserAnchor (SubUserPCNO, AnchorPocPCNO, CreatedAt, CreatedBy)
VALUES (:SubUserPCNO, :AnchorPocPCNO, SYSTIMESTAMP, :AdminPCNO);
```

### 1.4 Cross-Admin Category Sharing (`CategoryShareGrant`)
A Primary Admin can delegate category management to another Admin without transferring master ownership:
- **Table:** `CategoryShareGrant`
- **Fields:** `OwnerAdminPCNO`, `SharedWithPCNO`, `MainCategoryId`, `TierId` (NULL = all tiers), `IsActive`.
- **Effect:** The guest admin sees a **Secondary Admin (Shared)** card in their login role selection modal.

---

## 2. Hierarchical Category & Tier Builder ([Settings.aspx](file:///e:/attendence/Settings.aspx))

`Settings.aspx` enables administrators to structure the organizational manpower hierarchy.

```
+-----------------------------------------------------------------------------------+
|                               MainCategory (e.g. "HR")                            |
|                            Owned by Primary Admin (PCNO 1001)                     |
+-----------------------------------------+-----------------------------------------+
                                          |
                         +----------------+----------------+
                         |                                 |
                         v                                 v
                 Tier 1: Skilled                   Tier 2: Unskilled
                 (RoleLabel: "#DEO")               (RoleLabel: "#Attender")
                 SortOrder: 1                      SortOrder: 2
```

### Category Ownership Rules:
1. **Super Administrator (Role 4):** Has global visibility over all Main Categories and Tiers across the organization.
2. **Primary Administrator (Role 1):** Can manage, edit, and create Tiers only under Main Categories they explicitly own (`MainCategory.AdminPCNO = :PCNO`).
3. **Secondary Administrator:** Can view and manage attendance for shared categories but cannot delete the parent category.

---

## 3. Global Edit & View Policy Rules (`Settings.aspx`)

Configures system-wide security constraints enforced across attendance grids:

```
+-----------------------------------------------------------------------------------+
|                         ATTENDANCE EDIT & VIEW POLICIES                           |
+-------------------+---------------------------------------------------------------+
| Setting           | Configuration Options & Descriptions                          |
+-------------------+---------------------------------------------------------------+
| Edit Mode         | Mode 0: Retrospective Days Window (e.g. past 3 days)         |
|                   | Mode 1: Strict Current Calendar Month Only                    |
|                   | Mode 2: Grace Cutoff Day (e.g. 3rd of following month)        |
+-------------------+---------------------------------------------------------------+
| View Mode         | Mode 0: Unlimited Historical Viewing                          |
|                   | Mode 1: Fixed N Historical Months (e.g. past 2 months)        |
|                   | Mode 2: Strict Calendar Cutoff Date (e.g. no views < 2026-01)  |
|                   | Mode 3: Combined Most Restrictive                             |
+-------------------+---------------------------------------------------------------+
| View Applies To   | 0 = Apply to Regular Users (POCs) only                        |
|                   | 1 = Apply to all non-SuperAdmins                              |
+-------------------+---------------------------------------------------------------+
```

---

## 4. System Action Audit Logs (`AdminActionLog` & `ActionLog`)

`Settings.aspx` includes an audit viewer querying `AdminActionLog` and `ActionLog` to inspect administrative operations (e.g. user creation, role revocations, category updates, and batch configuration modifications).
