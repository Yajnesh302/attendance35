# 01 — Login Page

**Files Covered:**
- `Login.aspx` — Frontend HTML/UI
- `Login.aspx.cs` — Server-side C# code-behind
- `Utils/ADHelper.cs` — Active Directory authentication helper (called from here)
- `Utils/DBHelper.cs` — Database helper (used for role/user data, covered in its own doc)
- `Web.config` — App configuration (connection strings, AD path, auth settings)

---

## What This Page Does

The Login page is the **entry point** to the entire ARS application. It handles:
1. Authenticating the user against **Active Directory (AD)**
2. Looking up what **access roles** that user has in the application's own database
3. If the user has **one role** → logs them in immediately
4. If the user has **multiple roles** → shows a **Role Selection panel** so they can pick which role to log in as
5. Setting up the **session** with name, division, role, etc.
6. Redirecting to `Dashboard.aspx` after successful login

---

## Web.config — How the App Is Configured

Before reading any code, understand the two critical configs:

```xml
<!-- Two database connections -->
<add name="CompanyDB"    connectionString="User Id=system;Password=root;Data Source=//127.0.0.1:1521/xe;..." />
<add name="AttendanceDB" connectionString="User Id=system;Password=root;Data Source=//127.0.0.1:1521/xe;..." />

<!-- Active Directory LDAP path -->
<add key="ADConnectionPath" value="LDAP://192.168.0.106/DC=ad01,DC=yajnesh,DC=com" />
```

- **CompanyDB** connects to Oracle DB where the company's HR data lives (table: `hrdata.empdetails`). This is the source of employee Name, Designation, Division.
- **AttendanceDB** connects to the same Oracle instance but stores all the application-specific data (AppUsers, Contracts, Attendance, etc.).
- **ADConnectionPath** points to the corporate Active Directory LDAP server. Used to authenticate username+password.
- `<authentication mode="Forms">` — ASP.NET Forms Authentication. All pages except `Static/` files are locked behind login (`<deny users="?" />`). The login page is `Login.aspx`.
- Session timeout and Forms auth ticket timeout are both set to **1440 minutes (24 hours)**.

---

## Login.aspx — The UI

### What Is On the Page

The page is a split two-column card:
- **Left side** — shows the LRDE logo and the app name "ARS".
- **Right side** — contains two panels, only one visible at a time:

#### Panel 1: pnlLoginForm (default, visible on page load)
- `txtUsername` — text box for username (auto-focused on page load)
- `txtPassword` — password box
- `btnLogin` — the Login button (triggers `btnLogin_Click` server-side)
- `lblError` — a red error message label, hidden by default, made visible when there is a problem

#### Panel 2: pnlRoleSelection (hidden by default, shown when user has multiple roles)
- Shows "Welcome, [Name]! Choose your active role:"
- `rptRoleOptions` — an ASP.NET Repeater that lists each available role as a clickable tile
- Each tile has: an icon, a title, a subtitle, and an arrow button
- `btnCancelRoleSelection` — "Back to Login" link to go back to Panel 1

### CSS / Style
Uses the SB Admin 2 Bootstrap-based theme (`Static/css/sb-admin-2.min.css`).
Custom `.role-selection-tile` styles create clickable role cards with hover animations (lift + blue border + arrow highlight).

### JavaScript (Bottom of Page)
```javascript
$(document).ready(function () {
    // 1. Clear localStorage (keeping theme preference) and sessionStorage on load
    //    This ensures any previous session data is wiped when user hits the login page
    localStorage.clear();  // keeps 'app-theme' key if it was set

    // 2. Auto-focus the username field
    $('#txtUsername').focus();

    // 3. Pressing Enter on the username field moves focus to password field
    $('#txtUsername').keypress(function (e) {
        if (e.which == 13) {
            e.preventDefault();
            $('#txtPassword').focus();
        }
    });
});
```

Why the localStorage clear? When a user logs out or lands on login, any leftover client-side state from a previous session should be wiped. The theme preference (`app-theme`) is preserved so the user does not have to re-select their preferred dark/light mode.

---

## Utils/ADHelper.cs — Active Directory Helper

**Purpose:** Validates a username+password against the corporate LDAP server and returns the user's PCNO (Personnel/Company Number — their unique employee ID).

### Method: AuthenticateAndGetPCNO(string username, string password)

Input:  username (string), password (string)
Output: pcno (string) — the employee number from AD, or throws an Exception on failure

#### Step 1: Local Testing Bypass
```csharp
if (username == "1001" || username.ToLower() == "admin" || username.ToLower() == "aadmin")
    return "1001";
if (username == "1002") return "1002";
if (username == "1003") return "1003";
if (username == "1004") return "1004";
```
These hardcoded bypasses allow developers to test locally WITHOUT a real AD connection. The usernames 1001-1004, "admin", and "aadmin" return fake PCNOs directly.

IMPORTANT for future developers: These bypass accounts skip real password validation too. Anyone who knows these usernames can log in with any password on a development machine. They should be disabled or guarded in production.

#### Step 2: Real AD Authentication
```csharp
string ldapPath = ConfigurationManager.AppSettings["ADConnectionPath"];
using (DirectoryEntry entry = new DirectoryEntry(ldapPath, username, password))
{
    object native = entry.NativeObject; // Forces credential check — throws if wrong password
    using (DirectorySearcher search = new DirectorySearcher(entry))
    {
        search.Filter = "(SAMAccountName=" + username + ")";
        search.PropertiesToLoad.Add("EmployeeID");
        SearchResult result = search.FindOne();
        // ... reads result.Properties["EmployeeID"]
    }
}
```
- `DirectoryEntry` with the username/password in the constructor does NOT immediately validate credentials. The credentials are only checked when you access `entry.NativeObject` — that is why that line is there (it is not unused).
- A `DirectorySearcher` then searches for the user by `SAMAccountName` (the Windows login username).
- The `EmployeeID` field in AD holds the PCNO. If it is missing (some test/local AD setups), the username itself is returned as a fallback.
- If the user does not exist in AD at all after auth succeeds, it throws an exception.

---

## Login.aspx.cs — Code-Behind Logic

### Page_Load
```csharp
protected void Page_Load(object sender, EventArgs e)
{
    if (!IsPostBack)
    {
        if (User.Identity.IsAuthenticated)
            Response.Redirect("Dashboard.aspx");
    }
}
```
On first page load (not a postback), if the user is already authenticated (has a valid Forms Auth cookie), they are immediately sent to `Dashboard.aspx`. This prevents the login page from showing to already-logged-in users.

---

### btnLogin_Click — Main Login Flow

This is the most important method. It runs when the user clicks Login.

#### Step 1 — Input Validation
```csharp
string username = txtUsername.Text.Trim();
string password = txtPassword.Text.Trim();
if (string.IsNullOrEmpty(username)) { ShowError("Username is required."); return; }
```

#### Step 2 — AD Authentication
```csharp
pcno = ADHelper.AuthenticateAndGetPCNO(username, password);
```
Calls ADHelper. If it throws (wrong password, network issue), the exception message is shown. If pcno comes back null or empty, "Invalid credentials" is shown.

#### Step 3 — Load Available Roles from DB
```csharp
roles = DBHelper.GetAvailableUserRoles(pcno);
```
This queries the AttendanceDB to figure out what roles this PCNO has. If roles comes back empty or null, the system does a fallback query to AppUsers to give a more specific error message.

Role number system — important to understand:

| Role # in DB | Meaning |
|---|---|
| 0 | Active Regular User (POC) |
| 1 | Active Category Admin (Primary or Secondary) |
| 2 | Revoked Admin (marker that admin access was removed) |
| 3 | Revoked POC (marker that POC access was removed) |
| 4 | Super Admin |
| 5 | Revoked Super Admin |
| 6 | Active Sub User (Data Entry only) |
| 7 | Revoked Sub User |

#### Step 4a — Single Role: Login Directly
```csharp
if (roles.Count == 1)
    CompleteUserLogin(pcno, roles[0], roles);
```

#### Step 4b — Multiple Roles: Show Role Selection Panel
The pending PCNO and roles list are saved in Session:
```csharp
Session["PendingPCNO"] = pcno;
Session["PendingRoles"] = roles;
```
Then the login form is hidden and the role selection panel is shown.

---

### rptRoleOptions_ItemCommand — When a Role Tile Is Clicked

```csharp
protected void rptRoleOptions_ItemCommand(object source, RepeaterCommandEventArgs e)
{
    if (e.CommandName == "SelectRole")
    {
        string selectedMode = e.CommandArgument.ToString(); // e.g. "PrimaryAdmin", "RegularUser"
        string pcno = Session["PendingPCNO"] as string;
        List<UserRoleOption> roles = Session["PendingRoles"] as List<UserRoleOption>;

        if (string.IsNullOrEmpty(pcno) || roles == null)
        {
            ShowError("Session expired. Please log in again.");
            return;
        }

        UserRoleOption targetRole = roles.Find(r => r.RoleMode == selectedMode);
        if (targetRole == null) targetRole = roles[0]; // Fallback to first role

        CompleteUserLogin(pcno, targetRole, roles);
    }
}
```
The `CommandArgument` on each tile in the Repeater is the `RoleMode` string (set in the ASPX: `CommandArgument='<%# Eval("RoleMode") %>'`). This string is matched against `Session["PendingRoles"]` to find the full `UserRoleOption` object.

---

### btnCancelRoleSelection_Click — Back to Login

```csharp
Session["PendingPCNO"] = null;
Session["PendingRoles"] = null;
pnlRoleSelection.Visible = false;
pnlLoginForm.Visible = true;
```
Clears the pending session keys and swaps panels back.

---

### CompleteUserLogin — Finalizes the Login (Private Helper)

This private method is called once a final role is decided (either automatically for single-role or after selection). It does four things:

#### 1. Load Allowed Divisions
```csharp
if (selectedRole.EffectiveRole != 1 && selectedRole.EffectiveRole != 4)
{
    DataTable dtDivs = DBHelper.ExecuteQuery(..., "SELECT DivisionName FROM UserDivisions WHERE PCNO = :PCNO", pcno);
    // If no divisions found, default to "D-USER"
}
```
Admins (Role 1, 4) have no division restriction. Other users are limited to their assigned divisions in the `UserDivisions` table.

#### 2. Fetch Name, Designation, Division from Company HR Database
```csharp
string queryDiv = "SELECT NAME, DESIGNATION, DIVNAME FROM hrdata.empdetails WHERE PCNO = :PCNO";
DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetCompanyDBConnection(), queryDiv, pcno);
```
`hrdata.empdetails` is a table in the CompanyDB (the company's main HR Oracle database, not the application's own DB). If the PCNO is not found in HR data (e.g. admin accounts not in HR), it falls back to hardcoded admin values or queries the `AppUsers` table.

#### 3. Set Session Variables
```csharp
Session["PCNO"]             = pcno;
Session["Role"]             = selectedRole.EffectiveRole;   // e.g. 0, 1, 4, 6
Session["RoleMode"]         = selectedRole.RoleMode;         // e.g. "PrimaryAdmin", "RegularUser"
Session["UserRoles"]        = availableRoles;                // full list, used for role-switch menu
Session["Name"]             = name;
Session["Designation"]      = designation;
Session["AllowedDivisions"] = allowedDivisions;
Session["Division"]         = ...; // first allowed division, or "D-ADMIN" for admins
```
These session variables are read by every other page in the application via `Site.Master.cs` on every page load.

#### 4. Update AppUsers Table Name + Set Auth Cookie + Redirect
```csharp
// Keep AppUsers.Name in sync with HR database name
int affected = DBHelper.ExecuteNonQuery(..., "UPDATE AppUsers SET Name = :Name WHERE PCNO = :PCNO", ...);
if (affected == 0)
{
    // First-time login: insert a new AppUsers row
    DBHelper.ExecuteNonQuery(..., "INSERT INTO AppUsers (PCNO, Name, Role) VALUES (...)", ...);
}

FormsAuthentication.SetAuthCookie(pcno, false); // false = session cookie, not persistent
Response.Redirect("Dashboard.aspx");
```
Every login syncs the user's display name in the local `AppUsers` table to whatever the HR DB says (so names stay current if someone changes their name in HR).
`FormsAuthentication.SetAuthCookie` creates the encrypted auth ticket cookie that all subsequent page requests use.

---

## DBHelper.GetAvailableUserRoles — How Roles Are Determined

Location: `Utils/DBHelper.cs` line ~1344

This method queries the `AppUsers` table for all role numbers assigned to the given PCNO and then builds a list of `UserRoleOption` objects.

### Role evaluation logic (in order):

1. **Super Admin** (Role 4, not revoked with 5) — RoleMode = "SuperAdmin", EffectiveRole = 4
2. **Secondary (Shared) Category Admin** — If there are rows in `CategoryShareGrant` for this PCNO and the user is not revoked-admin (Role 2) — RoleMode = "SecondaryAdmin", EffectiveRole = 1
3. **Primary Category Admin** — If they own a `MainCategory` row (via AdminPCNO) or are assigned Role 1 (and not a guest/shared user) — RoleMode = "PrimaryAdmin", EffectiveRole = 1
4. **Regular User (POC)** — If Role 0 is assigned or they have entries in `UserDivisions` and are not a sub-user — RoleMode = "RegularUser", EffectiveRole = 0. AND automatically also gets RoleMode = "SubUser", EffectiveRole = 6 (every active POC implicitly gets sub-user mode)
5. **Explicit Sub User** (in `SubUserAnchor` or assigned Role 6, not revoked with Role 7) — RoleMode = "SubUser", EffectiveRole = 6

### UserRoleOption class (DBHelper.cs line ~1780)
```csharp
[Serializable]
public class UserRoleOption
{
    public string RoleMode { get; set; }   // "PrimaryAdmin", "SecondaryAdmin", "RegularUser", "SuperAdmin", "SubUser"
    public string Title { get; set; }      // Human-readable name shown on the role tile
    public string Subtitle { get; set; }  // Extra info (categories owned, divisions, etc.)
    public int EffectiveRole { get; set; } // The numeric role stored in Session["Role"]
    public string Icon { get; set; }       // FontAwesome class, shown as icon on the tile
    public string BadgeColor { get; set; } // Background color of the avatar on the tile
}
```
It is marked [Serializable] so it can be stored in ASP.NET Session state.

---

## Data Flow Summary

```
User types username + password
         |
         v
   ADHelper.AuthenticateAndGetPCNO()
         |
   [Connects to LDAP at 192.168.0.106]
   [Validates credentials via entry.NativeObject]
   [Reads EmployeeID field from AD user account]
         |
         v
       PCNO (e.g. "10047")
         |
         v
   DBHelper.GetAvailableUserRoles(pcno)
         |
   [Queries AppUsers WHERE PCNO = '10047']
   [Queries CategoryShareGrant, MainCategory, UserDivisions, SubUserAnchor]
         |
         v
   List<UserRoleOption>
         |
    0 items        1 item            2+ items
   (access denied) (login directly)  (show role selection panel)
                       |                      |
                       +----------+-----------+
                                  v
                 CompleteUserLogin(pcno, selectedRole, allRoles)
                                  |
                 [Queries CompanyDB: hrdata.empdetails for Name/Designation/Division]
                 [Queries AttendanceDB: UserDivisions for allowed divisions]
                 [Sets Session variables]
                 [Updates AppUsers.Name in DB]
                 [FormsAuthentication.SetAuthCookie(pcno, false)]
                                  |
                                  v
                           Dashboard.aspx
```

---

## Tables Touched at Login

| Table | Database | What Happens |
|---|---|---|
| `AppUsers` | AttendanceDB | Read to get roles; Name updated on login |
| `UserDivisions` | AttendanceDB | Read to get divisions for non-admin users |
| `CategoryShareGrant` | AttendanceDB | Read to check if user has shared category access |
| `MainCategory` | AttendanceDB | Read to check if user owns a category |
| `SubUserAnchor` | AttendanceDB | Read to check if user is registered as sub-user |
| `hrdata.empdetails` | CompanyDB | Read to get Name, Designation, DivName |

---

## Common Issues / Gotchas

1. **AD Connection fails** — If the machine running IIS cannot reach 192.168.0.106, the entire ADHelper call will throw a network exception. The user will see "AD Error: [message]".
2. **PCNO not in AppUsers** — If the PCNO returned from AD does not exist in AppUsers at all, GetAvailableUserRoles returns an empty list and access is denied. The admin must add the user via the Admin Management page first.
3. **Local bypass accounts (1001-1004)** — These skip AD entirely and are intended for offline development only.
4. **Session["PendingPCNO"] expiry** — If the user stays on the Role Selection panel for a very long time and the session times out, clicking a role tile will hit the "Session expired" guard and revert to the login form.
5. **hrdata.empdetails not found** — If CompanyDB is unavailable, the name/designation/division fetch fails silently (logged to Debug output). Fallback values are used and login still completes.

---

*Next: See 02_SiteMaster.md for the Site.Master (navigation/layout shell) documentation.*
