# Chapter 03: Authentication & Global Layout Engine

This document details the authentication gateway ([Login.aspx](file:///e:/attendence/Login.aspx) / [Login.aspx.cs](file:///e:/attendence/Login.aspx.cs)) and the global master layout template ([Site.Master](file:///e:/attendence/Site.Master) / [Site.Master.cs](file:///e:/attendence/Site.Master.cs)).

---

## 1. Authentication Lifecycle ([Login.aspx.cs](file:///e:/attendence/Login.aspx.cs))

The authentication engine integrates Windows Active Directory (LDAP), Oracle database profile lookups, dynamic multi-role selection, and ASP.NET Forms Authentication cookies.

### 1.1 Complete Login Execution Flow

```
[User submits Username & Password on Login.aspx]
                        |
                        v
              1. btnLogin_Click Event
                        |
                        v
        2. ADHelper.AuthenticateAndGetPCNO(user, pass)
                        |
            +-----------+-----------+
            | (Failure)             | (Success)
            v                       v
      Show Error Modal         PCNO Resolved (e.g. "1001")
                                    |
                                    v
            3. DBHelper.GetAvailableUserRoles(pcno)
                                    |
            +-----------------------+-----------------------+
            | (0 Roles - Revoked)   | (1 Role)              | (Multiple Roles)
            v                       v                       v
  Inspect AppUsers              Direct Login            Show Role Selection Modal
  Show Revocation Message   CompleteUserLogin(...)      pnlRoleSelection.Visible=true
                                                            |
                                                [User clicks Role card in Repeater]
                                                            |
                                                            v
                                                rptRoleOptions_ItemCommand
                                                            |
                                                            v
                                                CompleteUserLogin(...)
```

---

### 1.2 Multi-Role Selection & Revocation Detection

When a user has access to more than one functional role (for example, a user who is both a **Primary Admin** for HR and a **POC** for Division D-ADMIN), the system does not force them into an arbitrary role.

1. **Role Options Evaluation:**
   `DBHelper.GetAvailableUserRoles(pcno)` generates a list of `UserRoleOption` models:
   ```csharp
   public class UserRoleOption
   {
       public string RoleMode { get; set; }     // "SuperAdmin", "PrimaryAdmin", "SecondaryAdmin", "RegularUser", "SubUser"
       public string Title { get; set; }        // e.g. "Primary Category Admin"
       public string Subtitle { get; set; }     // e.g. "Category Owner (HR)"
       public int EffectiveRole { get; set; }   // 4, 1, 0, or 6
       public string Icon { get; set; }         // e.g. "fas fa-user-shield"
       public string BadgeColor { get; set; }   // e.g. "#4f46e5"
   }
   ```
2. **Interactive Selection UI:**
   If `roles.Count > 1`, `Login.aspx` hides `pnlLoginForm` and displays `pnlRoleSelection` containing an ASP.NET `<asp:Repeater ID="rptRoleOptions">`.
3. **Revocation Inspection Logic:**
   If `roles.Count == 0`, `Login.aspx.cs` queries `AppUsers` to distinguish between unassigned accounts and explicitly revoked accounts:
   - `Role 5`: *"Access denied. Your super administrator access has been revoked."*
   - `Role 2`: *"Access denied. Your administrator access has been revoked."*
   - `Role 3`: *"Access denied. Your regular user (POC) access has been revoked."*
   - `Role 7`: *"Access denied. Your sub user access has been revoked."*

---

### 1.3 User Profile Synchronization & Session Initialization

Once the active role is chosen, `CompleteUserLogin(pcno, selectedRole, availableRoles)` executes:

```csharp
private void CompleteUserLogin(string pcno, UserRoleOption selectedRole, List<UserRoleOption> availableRoles)
{
    // 1. Fetch authorized divisions from UserDivisions for POC / SubUser
    List<string> allowedDivisions = new List<string>();
    if (selectedRole.EffectiveRole != 1 && selectedRole.EffectiveRole != 4)
    {
        string queryDivs = "SELECT DivisionName FROM UserDivisions WHERE PCNO = :PCNO";
        DataTable dtDivs = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), queryDivs, new OracleParameter("PCNO", pcno));
        foreach (DataRow row in dtDivs.Rows)
            allowedDivisions.Add(row["DivisionName"].ToString());
    }

    // 2. Fetch Name & Designation from Company HR database (hrdata.empdetails)
    string queryDiv = "SELECT NAME, DESIGNATION, DIVNAME FROM hrdata.empdetails WHERE PCNO = :PCNO AND ROWNUM <= 1";
    DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetCompanyDBConnection(), queryDiv, new OracleParameter("PCNO", pcno));
    if (dt.Rows.Count > 0)
    {
        name        = dt.Rows[0]["NAME"].ToString();
        designation = dt.Rows[0]["DESIGNATION"].ToString();
        division    = dt.Rows[0]["DIVNAME"].ToString();
    }

    // 3. Initialize Session Variables
    Session["PCNO"] = pcno;
    Session["Role"] = selectedRole.EffectiveRole;
    Session["RoleMode"] = selectedRole.RoleMode;
    Session["UserRoles"] = availableRoles;
    Session["Name"] = name;
    Session["Designation"] = designation;
    Session["AllowedDivisions"] = allowedDivisions;
    Session["Division"] = division;

    // 4. Upsert User Name in AppUsers for local caching
    string updateNameQuery = "UPDATE AppUsers SET Name = :Name WHERE PCNO = :PCNO";
    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), updateNameQuery,
        new OracleParameter("Name", name), new OracleParameter("PCNO", pcno));

    // 5. Issue Forms Authentication Cookie and Redirect
    FormsAuthentication.SetAuthCookie(pcno, false);
    Response.Redirect("Dashboard.aspx");
}
```

---

## 2. Global Layout & Master Page Engine ([Site.Master.cs](file:///e:/attendence/Site.Master.cs))

`Site.Master` wraps every authenticated page in the system. It enforces layout switching, dynamic navigation filtering, unread notification badges, and instant in-session role switching.

### 2.1 Dual Layout System: Sidebar vs TopNav

The layout dynamically adapts based on the active page:
- **On `Dashboard.aspx`:** The left **Collapsible Sidebar** is rendered (`phSidebar.Visible = true; phTopNav.Visible = false;`), providing an executive overview and quick navigation cards.
- **On Content Pages (`Attendance.aspx`, `Employee.aspx`, etc.):** The compact **Top Navigation Bar** is rendered (`phSidebar.Visible = false; phTopNav.Visible = true;`), maximizing horizontal screen width for large data grids and matrix tables.

---

### 2.2 In-Session Dynamic Role Switching

Users with multiple assigned roles can switch their active operating role on any page without logging out:
1. The user clicks a different role from the top-right profile dropdown.
2. The browser navigates to `?switchRole={TargetRoleMode}`.
3. `Site.Master.cs` intercepts the request:
   ```csharp
   string switchRoleParam = Request.QueryString["switchRole"];
   if (!string.IsNullOrEmpty(switchRoleParam) && !string.IsNullOrEmpty(pcno))
   {
       if (DBHelper.SwitchUserRole(pcno, switchRoleParam, Session))
       {
           Response.Redirect(Request.Url.AbsolutePath); // Reloads page cleanly with new role
           return;
       }
   }
   ```

---

### 2.3 Role-Based Navigation Visibility Matrix

`Site.Master` selectively shows or hides menus based on `Session["Role"]` and `Session["RoleMode"]`:

| Navigation Item | Target Page | SuperAdmin (`4`) | Admin (`1`) | POC (`0`) | Sub User (`6`) |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Dashboard** | `Dashboard.aspx` | Visible | Visible | Visible | Visible |
| **Attendance** | `Attendance.aspx` | Full Matrix | Full Matrix | Division Scoped | Staged Drafts Only |
| **Employees** | `Employee.aspx` | Visible | Visible | **Hidden** | **Hidden** |
| **Contracts** | `Contracts.aspx` | Visible | Visible | **Hidden** | **Hidden** |
| **Vendors** | `Vendors.aspx` | Visible | Visible | **Hidden** | **Hidden** |
| **Calculation** | `Calculation.aspx` | Visible | Visible | **Hidden** | **Hidden** |
| **Wages & Statutory** | `Wages.aspx` | Visible | Visible | **Hidden** | **Hidden** |
| **Documents** | `Documents.aspx` | Visible | Visible | **Hidden** | **Hidden** |
| **Admin Management** | `AdminManagement.aspx` | Full Access | Category Scoped | **Hidden** | **Hidden** |
| **Settings** | `Settings.aspx` | Visible | Visible | **Hidden** | **Hidden** |
| **Notices** | `Notices.aspx` | Post & View | Post & View | View Only | View Only |
| **Remarks** | `Remarks.aspx` / `UserRemarks` | Resolution Inbox | Resolution Inbox | Submit Request | Submit Request |

---

### 2.4 Real-Time Notification & Badge Indicators

`Site.Master.cs` computes notification badges on `Page_Load`:

1. **Admin Unread Remarks Badge (`UnreadCount`):**
   ```sql
   SELECT COUNT(DISTINCT ar.SubmittedBy || '_' || ar.EmpID || '_' || ar.Message || '_' || TO_CHAR(ar.CreatedAt, 'YYYYMMDDHH24MISS'))
   FROM AttendanceRemarks ar 
   WHERE ar.IsRead = 0
   ```
   Renders a red badge count on the top notification bell icon (`phNotifBell`).

2. **POC Pending Drafts Badge (`PendingDraftCount`):**
   ```sql
   SELECT COUNT(*) 
   FROM AttendanceDraft ad
   JOIN Employees e ON ad.EmpID = e.MasterId
   WHERE e.Division IN (SELECT DivisionName FROM UserDivisions WHERE PCNO = :PCNO)
   ```
   Alerts Directorate POCs when their assigned Sub Users have staged new attendance entries requiring review and commitment.

---

### 2.5 Safe Logout Execution (`btnLogout_Click`)

```csharp
protected void btnLogout_Click(object sender, EventArgs e)
{
    Session.Clear();
    Session.Abandon();
    FormsAuthentication.SignOut();
    Response.Redirect("Login.aspx");
}
```
*Guarantees:* Wipes in-memory session data, clears ASP.NET session ID, invalidates `.ASPXAUTH` authentication ticket, and redirects client to the login page.
