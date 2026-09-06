# 02 — Site.Master (The Application Shell)

**Files Covered:**
- `Site.Master` — The HTML layout template and CSS/JS that wraps every page
- `Site.Master.cs` — The C# code-behind that runs on every page load

---

## What Is a Master Page?

In ASP.NET WebForms, a **Master Page** is a shared template. Think of it as the outer frame of the application. Every page in this app (Dashboard, Attendance, Employee, Contracts, etc.) is loaded *inside* Site.Master.

When a browser visits `Attendance.aspx`, what actually happens is:
1. Site.Master is rendered first (navbar, sidebar, etc.)
2. Inside the `<asp:ContentPlaceHolder ID="MainContent">` slot, the actual content of `Attendance.aspx` is injected
3. The full HTML output is a single merged page sent to the browser

So the Site.Master code runs on **every single page load** in the entire application. This is why it is extremely important to understand.

---

## How a Child Page Connects to Site.Master

At the top of every `.aspx` page file, you will see:
```asp
<%@ Page ... MasterPageFile="~/Site.Master" %>
```
And at the top of every `.aspx.cs` code-behind:
```csharp
public partial class Attendance : System.Web.UI.Page
```

The child page provides content for the placeholder slots defined in Site.Master:
- `HeadContent` — For page-specific CSS/JS injected into the `<head>`
- `TitleContent` — For the page title shown in the browser tab
- `MainContent` — For the actual page body content

---

## Site.Master HTML Structure

The full page layout is organized as follows:

```
<html>
  <head>
    [CSS: FontAwesome, SB Admin 2, dark-theme.css]
    [CSS: Tour popover styles, Toast styles, Navbar styles, Sidebar styles]
    [JS: FOUC prevention — apply dark/light theme BEFORE page paint]
    [JS: showToast() — global toast notification function]
    [HeadContent placeholder — child pages inject their CSS/JS here]
  </head>
  <body class="[attendance-page | dashboard-page | sticky-nav-page]">
    <form id="form1">
      <div id="wrapper" class="d-flex">
        
        [phSidebar — visible ONLY on Dashboard.aspx]
          └── LRDE Logo card
          └── User avatar (loaded from internal HR photo server)
          └── User name + designation + role badge
          └── Accessible divisions box (POC + Sub User only)

        <div id="content-wrapper">
          <nav class="navbar navbar-custom">  ← Always visible topbar
            └── Brand logo ("ARS")
            └── [phTopNav — visible on NON-dashboard pages]
                 └── Nav links: Dashboard, Employee Master, Attendance, Ledger, Calculation, Remarks, Documents
            └── Right side of navbar:
                 └── Tour button (Dashboard only)
                 └── Theme toggle (Dark/Light)
                 └── Welcome badge (user name + designation)
                 └── Role switcher dropdown (only if user has 2+ roles)
                 └── Notification bell (Admin only)
                 └── Logout button
          </nav>

          <div class="container-main">
            [MainContent placeholder — each child page renders here]
          </div>
        </div>

      </div>
    </form>

    [JS: Bootstrap, jQuery, SweetAlert2]
    [JS: Notification bell fetch logic (admin only)]
    [JS: Role switcher dropdown open/close]
    [JS: toggleAppTheme() — dark/light toggle]
    [JS: Welcome Tour engine — all tour steps defined here]
    [JS: Enter-key submit prevention for text inputs]
  </body>
</html>
```

---

## Site.Master.cs — Properties (Class-Level Fields)

These are declared at the top of the class and used throughout the page:

```csharp
protected int UnreadCount { get; private set; }
```
Count of unread remarks notifications. Populated for admins (Role 1 or 4) only. Shown on the notification bell badge.

```csharp
protected int PendingDraftCount { get; private set; }
```
Count of pending draft attendance entries that are waiting for a POC to review. Shown as a number badge on the "Attendance" nav link when logged in as a Regular User (POC).

```csharp
protected List<string> UserAllowedDivisions { get; private set; }
```
List of division names the current user is allowed to see (e.g. "D-MWES", "D-CES"). Shown as blue tags in the sidebar divisions box. Only populated for POC and Sub User roles.

```csharp
protected List<string> UserAllowedCategories { get; private set; }
```
List of category/tier names the current user can access (e.g. "Skilled", "Semi-Skilled"). Shown as green tags in the sidebar. Only for POC and Sub User roles.

```csharp
protected List<string> UserAnchorPocs { get; private set; }
```
For Sub User only — the names of the POC(s) this Sub User is anchored to. An anchor POC is the "supervisor" POC whose data the sub user can assist with drafting.

```csharp
public List<UserRoleOption> AvailableUserRoles { get; private set; }
```
All the roles this user can operate as (loaded from Session or re-fetched from DB). Used to build the role-switcher dropdown in the navbar.

```csharp
public string CurrentRoleMode { get; private set; }   // e.g. "PrimaryAdmin"
public string CurrentRoleTitle { get; private set; }  // e.g. "Primary Category Admin"
public string CurrentRoleIcon { get; private set; }   // e.g. "fas fa-user-shield"
```
These three hold the display info for the currently active role, used to populate the role switcher button in the navbar.

---

## Site.Master.cs — Page_Load (The Core Method)

This method runs on **every single page request** in the application (because Site.Master is loaded on every page). It is the central control room for the whole app. Let us walk through it step by step.

### Step 1: Auto-Close Expired Contracts
```csharp
AttendanceApp.Utils.DBHelper.AutoCloseExpiredContracts();
```
Every page load triggers a check: are there any active contracts whose end date has passed? If yes, they are automatically closed in the database. This is a background maintenance task that runs silently on every page load. If it fails, the error is swallowed (empty catch block) so it never interrupts the user.

---

### Step 2: Session Guard — Detect Lost Session
```csharp
if (Session["PCNO"] == null && Page.User.Identity.IsAuthenticated)
{
    FormsAuthentication.SignOut();
    Response.Redirect("Login.aspx");
    return;
}
```
**What this handles:** If the IIS application pool restarts (which clears all in-memory Sessions), but the user's browser still has a valid Forms Auth cookie, they would otherwise reach a page with no session data. This guard detects that scenario: "auth cookie says logged in, but Session is empty" → force a logout and redirect to Login.aspx.

This is essential because if you deployed new code mid-session, all sessions are lost. Without this guard, users would get `NullReferenceException` errors everywhere.

---

### Step 3: Handle Role Switch URL Parameter
```csharp
string switchRoleParam = Request.QueryString["switchRole"];
if (!string.IsNullOrEmpty(switchRoleParam) && !string.IsNullOrEmpty(pcno))
{
    if (DBHelper.SwitchUserRole(pcno, switchRoleParam, Session))
    {
        Response.Redirect(Request.Url.AbsolutePath); // Reload same page without the ?switchRole= param
        return;
    }
}
```
**How role switching works:** When the user clicks a role in the role-switcher dropdown in the navbar, the link they are clicking is built like this (see Site.Master HTML line ~1285):
```
href="[current page URL]?switchRole=PrimaryAdmin"
```

So when they click "Switch to Sub User", they navigate to e.g. `Attendance.aspx?switchRole=SubUser`.

On the next page load, Site.Master (which runs first) sees the `?switchRole=` query parameter, calls `DBHelper.SwitchUserRole()` which updates the Session variables (`Role`, `RoleMode`, etc.) for the new role, then redirects to the same URL but *without* the query parameter (clean URL). The page then reloads with the new role in effect.

---

### Step 4: Read Role From Session and Set Display Properties
```csharp
string roleMode = Session["RoleMode"] != null ? Session["RoleMode"].ToString() : "";
int role = Session["Role"] != null ? Convert.ToInt32(Session["Role"]) : 0;

CurrentRoleMode = roleMode;
AvailableUserRoles = Session["UserRoles"] as List<UserRoleOption>;
```
The current role info is read from Session. If for some reason `Session["UserRoles"]` is null (e.g. session restored but incomplete), it re-fetches from the database:
```csharp
if (AvailableUserRoles == null || AvailableUserRoles.Count == 0)
{
    AvailableUserRoles = DBHelper.GetAvailableUserRoles(pcno);
    Session["UserRoles"] = AvailableUserRoles;
}
```
Then the current role's title and icon are found and stored:
```csharp
var curObj = AvailableUserRoles.Find(r => r.RoleMode == roleMode) ?? AvailableUserRoles[0];
CurrentRoleTitle = curObj.Title;
CurrentRoleIcon  = curObj.Icon;
```
These three (`CurrentRoleTitle`, `CurrentRoleIcon`, `CurrentRoleMode`) are used directly in the HTML of Site.Master to render the role switcher button.

---

### Step 5: Load Role-Specific Data

This is a big if/else block that does different things depending on who the user is.

#### Branch A: Admin or Super Admin (Role 1 or Role 4)
```csharp
if (role == 1 || role == 4)
{
    // Unread remarks count (badge on bell icon)
    string sql = "SELECT COUNT(DISTINCT ...) FROM AttendanceRemarks ar WHERE ar.IsRead = 0";
    UnreadCount = ...;

    // Set sidebar label and icon
    lblUserName.InnerText = (role == 4) ? "Super Admin" : "Administrator";
    myfw.Attributes["class"] = "fas fa-user-shield text-success";

    // Show Employee Master and Calculation nav links
    phEmployeeMaster.Visible = true;
    phCalculation.Visible = true;
}
```
- **UnreadCount**: Counts distinct unread remarks using a compound key (submitter + employee + message + timestamp). This prevents the same remark appearing multiple times. Shown on the bell icon badge.
- **Employee Master + Calculation links**: These two nav items are only visible to Admin and Super Admin. They are hidden for POC and Sub User. This control happens here.

---

#### Branch B: Sub User (RoleMode = "SubUser" or Role = 6)
```csharp
else if (roleMode == "SubUser" || role == 6)
{
    lblUserName.InnerText = "Sub User";
    myfw.Attributes["class"] = "fas fa-user-edit text-warning";
    phEmployeeMaster.Visible = false;
    phCalculation.Visible = false;

    // Load divisions accessible to this sub user
    UserAllowedDivisions = ...; // from UserDivisions table

    // Load categories/tiers accessible to this sub user
    UserAllowedCategories = ...; // from UserTiers JOIN Tiers

    // Load anchor POC(s) for this sub user
    UserAnchorPocs = ...; // from SubUserAnchor JOIN AppUsers
}
```
- **UserAllowedDivisions**: Queried from `UserDivisions WHERE PCNO = :PCNO`. Shown as blue badges in the sidebar.
- **UserAllowedCategories**: Queried by joining `UserTiers` with `Tiers` table on `TierId`. Shown as green badges in sidebar.
- **UserAnchorPocs**: Queried from `SubUserAnchor` table, joined with `AppUsers` to get POC name. The result is formatted as "Name (PCNO)" and shown as yellow badges in sidebar. This tells the sub user whose attendance data they are assisting.

---

#### Branch C: Regular User / POC (fallback — everything else)
```csharp
else
{
    lblUserName.InnerText = "User (POC)";
    myfw.Attributes["class"] = "fas fa-user";
    phEmployeeMaster.Visible = false;
    phCalculation.Visible = false;

    // Load divisions (same as Sub User)
    UserAllowedDivisions = ...; // from UserDivisions table

    // Load categories (same as Sub User)
    UserAllowedCategories = ...; // from UserTiers JOIN Tiers

    // Count pending draft records waiting for this POC to review
    string sqlDrafts = @"
        SELECT COUNT(*)
        FROM AttendanceDraft ad
        JOIN Employees e ON ad.EmpID = e.MasterId
        WHERE e.Department IN (SELECT DivisionName FROM UserDivisions WHERE PCNO = :PCNO)";
    PendingDraftCount = ...;
}
```
- **PendingDraftCount**: Counts how many rows exist in `AttendanceDraft` for employees in this POC's divisions. This number appears as a yellow badge on the "Attendance" nav link. It's a visual reminder that sub users have submitted draft entries awaiting the POC's review and approval.

---

### Step 6: Control Sidebar vs Top Navigation Visibility
```csharp
string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
bool isDashboard = currentPage.Equals("Dashboard.aspx", ...);

if (isDashboard)
{
    phSidebar.Visible = true;   // Show the left sidebar
    phTopNav.Visible = false;   // Hide the top nav links
}
else
{
    phSidebar.Visible = false;  // Hide the left sidebar
    phTopNav.Visible = true;    // Show the top nav links
}
```
This is why the Dashboard looks different from all other pages:
- **Dashboard** = has the left sidebar with the user photo and divisions. No nav links at top (they are replaced by the dashboard's own cards).
- **Every other page** = no sidebar. Instead, shows nav links (Dashboard / Employee Master / Attendance / Ledger / etc.) in the topbar.

---

### Step 7: Control Which Nav Items Are Visible
```csharp
int currentRole = Convert.ToInt32(Session["Role"] ?? 0);
phNavAdminLinks.Visible = (currentRole == 1 || currentRole == 4);
phNotifBell.Visible     = (currentRole == 1 || currentRole == 4);
phStartTour.Visible     = isDashboard;
```
- `phNavAdminLinks` wraps the "Remarks" and "Documents" nav links. Only admins and super admins see these.
- `phNotifBell` is the notification bell icon in the navbar. Only admins see it.
- `phStartTour` is the question-mark tour button. It is only shown on the Dashboard page.

---

## Helper Methods in Site.Master.cs

### `GetNavClass(string pageName)` — Active Page Highlighting
```csharp
protected string GetNavClass(string pageName)
{
    string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
    if (currentPage.Equals(pageName, StringComparison.OrdinalIgnoreCase))
        return "nav-link active";
    return "nav-link";
}
```
Called from the HTML like this:
```html
<a class='<%= GetNavClass("Attendance.aspx") %>' href="Attendance.aspx">Attendance</a>
```
If you are currently on Attendance.aspx, the class becomes `"nav-link active"` (white background, indigo text). On any other page, it is just `"nav-link"` (dim). This is how the current active page is highlighted in the navbar.

---

### `GetRoleBadgeBg(string mode)` and `GetRoleBadgeColor(string mode)` — Role Icon Colors
```csharp
public string GetRoleBadgeBg(string mode)
{
    if (mode == "SuperAdmin")     return "rgba(245, 158, 11, 0.25)";  // amber
    if (mode == "PrimaryAdmin")   return "rgba(79, 70, 229, 0.25)";   // indigo
    if (mode == "SecondaryAdmin") return "rgba(2, 132, 199, 0.25)";   // sky blue
    if (mode == "SubUser")        return "rgba(2, 132, 199, 0.25)";   // sky blue
    return "rgba(100, 116, 139, 0.25)"; // slate (default/POC)
}

public string GetRoleBadgeColor(string mode)
{
    if (mode == "SuperAdmin")     return "#fbbf24";  // amber
    if (mode == "PrimaryAdmin")   return "#a5b4fc";  // indigo
    if (mode == "SecondaryAdmin") return "#7dd3fc";  // sky blue
    if (mode == "SubUser")        return "#7dd3fc";  // sky blue
    return "#cbd5e1"; // slate (default/POC)
}
```
Used in the HTML to dynamically color the icon box in the role-switcher button based on which role is currently active. So Super Admin gets a gold-tinted icon, Primary Admin gets indigo, etc.

---

### `btnLogout_Click` — Logout Handler
```csharp
protected void btnLogout_Click(object sender, EventArgs e)
{
    Session.Clear();    // Remove all session variables
    Session.Abandon();  // Destroy the session object
    FormsAuthentication.SignOut(); // Delete the auth cookie
    Response.Redirect("Login.aspx");
}
```
The Logout button is defined in the HTML as:
```html
<asp:LinkButton ID="btnLogout" runat="server"
    OnClick="btnLogout_Click"
    OnClientClick="var _t=localStorage.getItem('app-theme'); localStorage.clear(); if(_t) localStorage.setItem('app-theme',_t); sessionStorage.clear();">
    Logout
</asp:LinkButton>
```
Two things happen when the user clicks Logout:
1. **Client-side (OnClientClick)**: JavaScript runs first. It clears localStorage and sessionStorage. The theme preference is saved and restored so the user does not have to pick dark/light mode again after re-login.
2. **Server-side (OnClick)**: `btnLogout_Click` runs. It clears and destroys the Session, removes the auth cookie, and redirects to Login.aspx.

---

## JavaScript in Site.Master — Every Function Explained

### FOUC Prevention (Runs Before Page Paint)
```javascript
(function(){
    var t = localStorage.getItem('app-theme');
    if (t === 'dark') document.documentElement.classList.add('theme-dark');
    else document.documentElement.classList.add('theme-light');
})();
```
FOUC = Flash of Unstyled Content. If the page loaded in light mode and then JavaScript switched to dark mode, you would see a brief white flash. This script runs in the `<head>` before any CSS is applied, so by the time the browser renders anything, the correct theme class is already on the `<html>` element.

---

### `showToast(msg, type)` — Global Toast Notification
```javascript
function showToast(msg, type = 'info') { ... }
```
A global function available on every page. Any page can call `showToast("Saved!", "success")` to show a small pop-up notification in the top-right corner of the screen. It auto-dismisses after 4 seconds.

Types and their colors:
| Type | Color |
|---|---|
| `success` | Green (emerald) |
| `error` | Red |
| `warning` | Amber/orange |
| `info` | Blue (default) |

How it works internally:
1. Creates or finds the `#toast-container` div (fixed to top-right of screen)
2. Creates a `<div class="modern-toast toast-[type]">` with an icon and the message
3. Appends it to the container
4. Triggers a CSS reflow via `toast.offsetHeight` (forces browser to register the element before running the animation)
5. Adds class `toast-show` which triggers the slide-in CSS transition
6. After 4 seconds, removes `toast-show` and adds `toast-hide` (slide-up fade-out), then removes the element after 400ms

---

### `toggleAppTheme()` — Dark/Light Mode Toggle
```javascript
function toggleAppTheme() {
    var html = document.documentElement;
    var icon = document.getElementById('themeIcon');
    if (html.classList.contains('theme-dark')) {
        html.classList.remove('theme-dark');
        html.classList.add('theme-light');
        localStorage.setItem('app-theme', 'light');
        icon.className = 'fas fa-moon';  // Moon icon = currently light mode
    } else {
        html.classList.remove('theme-light');
        html.classList.add('theme-dark');
        localStorage.setItem('app-theme', 'dark');
        icon.className = 'fas fa-sun';   // Sun icon = currently dark mode
    }
}
```
Toggles between `theme-dark` and `theme-light` CSS classes on the `<html>` element. The `dark-theme.css` file uses `html.theme-dark ...` selectors to override colors. The preference is saved in `localStorage` so it persists across sessions.

The icon logic: when you ARE in dark mode, the button shows a sun icon (click to go light). When you are in light mode, the button shows a moon icon (click to go dark). This is intentional — the icon represents what you will switch TO, not what you are currently in.

---

### Notification Bell — `toggleNotifDrop(e)` and `loadNotifDrop()`
This code only runs for Admin/Super Admin (wrapped in a server-side `if (jsRole == 1 || jsRole == 4)` block, so the JavaScript is not even emitted to the browser for non-admin users).

```javascript
window.toggleNotifDrop = function (e) {
    e.stopPropagation(); // Prevent the click from bubbling up to document
    var drop = document.getElementById('notifDropdown');
    var isOpen = drop.classList.contains('open');
    if (isOpen) {
        drop.classList.remove('open');
    } else {
        drop.classList.add('open');
        if (!dropLoaded) { loadNotifDrop(); dropLoaded = true; } // Load only once
    }
};
```
`dropLoaded` is a variable that starts as `false`. When the bell is clicked for the first time, `loadNotifDrop()` fetches the data via AJAX. After that, `dropLoaded` becomes `true` so the fetch is not repeated on every open.

```javascript
function loadNotifDrop() {
    fetch('Remarks.aspx/GetAllRemarks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: '{}'
    })
    .then(r => r.json())
    .then(data => {
        var all = JSON.parse(data.d); // ASP.NET WebMethod wraps JSON in .d property
        var unread = all.filter(r => !r.IsRead); // Only show unread items
        // Build HTML for the dropdown list
        var preview = unread.slice(0, 5); // Show max 5
        // Update the badge count and list
    });
}
```
This calls `Remarks.aspx/GetAllRemarks` — a WebMethod defined in `Remarks.aspx.cs`. ASP.NET WebMethods return JSON wrapped in a `{ d: "..." }` envelope, so you see `data.d` and then `JSON.parse()` on the value.

The `esc(s)` function in this code is a simple HTML-escaping helper to prevent XSS (cross-site scripting). Any user-entered text (like a remark message) is run through `esc()` before being inserted into the HTML.

---

### Role Switcher Dropdown — `toggleTopRoleDropdown(e)`
```javascript
window.toggleTopRoleDropdown = function (e) {
    e.stopPropagation();
    var wrap = e.currentTarget.closest('.topbar-role-dropdown');
    var menu = wrap.querySelector('.topbar-role-menu');
    var isOpen = menu.classList.contains('show');

    // Close all other open role dropdowns first
    document.querySelectorAll('.topbar-role-dropdown.show, .topbar-role-menu.show').forEach(m => m.classList.remove('show'));

    if (!isOpen) {
        wrap.classList.add('show');
        menu.classList.add('show');
    }
};
```
Opens or closes the role-switcher dropdown. Clicking anywhere outside the dropdown closes it (handled by the global `document.addEventListener('click', ...)` listener below this).

---

### Welcome Tour System

The tour system is a custom-built interactive walkthrough. No third-party library is used.

**Data structure:** Each tour step is an object:
```javascript
{
    selector: '.dashboard-header-title',  // CSS selector of the element to highlight
    fallbackSelector: '.navbar-brand',     // Fallback if primary selector not found
    tag: 'System Overview',               // Small tag badge shown in tooltip header
    icon: 'fas fa-tachometer-alt',        // Icon for the tooltip
    iconColor: '#4f46e5',
    title: 'Attendance Recording System', // Tooltip title
    text: 'Welcome to ARS! ...',          // Tooltip description
    beforeStep: function() { ... }        // Optional: runs before this step renders
                                          // Used to navigate carousel pages on Dashboard
}
```

**`triggerSiteTour()`** — Entry point called by the ? button:
- If NOT on Dashboard.aspx → redirect to `Dashboard.aspx?startTour=true`
- If already on Dashboard → call `startWelcomeTour()` directly

**`startWelcomeTour()`**:
1. Calls `endTour()` to clean up any previous tour
2. Calls `ensureTourElements()` to create the spotlight ring and tooltip popover divs if they don't exist
3. Filters the `tourSteps` array — only keeps steps where the target element actually exists on the current page (`.filter(step => !!document.querySelector(step.selector))`)
4. Sets `currentTourStep = 0` and calls `renderTourStep()`

**`renderTourStep()`**:
1. Calls `step.beforeStep()` if defined (e.g. switches to the right page in the Dashboard carousel)
2. Finds the target element with `document.querySelector(step.selector)`
3. If element not found → skips to next step
4. Checks if the element is in view; if not, scrolls to it
5. Calls `applyTourSpotlight(targetEl, step)`
6. Runs the same positioning logic again after 50ms, 150ms, and 300ms delays to handle layout shifts after `beforeStep` completes

**`applyTourSpotlight(targetEl, step)`**:
1. Gets the bounding rect of the target element (`getBoundingClientRect()`)
2. Positions the `#tourSpotlightRing` div over the element (with 6px padding). The ring has a CSS box-shadow that creates a dark overlay over the entire rest of the page while showing the element clearly.
3. Builds the popover HTML (header, progress bar, title, description, Back/Next/Skip buttons)
4. Calculates the best position for the tooltip — normally below the element, but flips above if there is not enough space below.

**`endTour()`**: Removes keyboard listeners, hides the ring and tooltip.

**Keyboard controls**: Arrow Right / Enter = Next step. Arrow Left = Previous step. Escape = End tour.

**Auto-start**: If the URL contains `?startTour=true` (from the redirect in `triggerSiteTour()`), the tour auto-starts after a 400ms delay. The `?startTour=true` param is then removed from the URL using `history.replaceState()` so a page refresh doesn't restart the tour.

---

### Enter Key Prevention
```javascript
document.addEventListener('keydown', function(e) {
    if (e.key === 'Enter' || e.keyCode === 13) {
        var target = e.target;
        if (target && target.tagName === 'INPUT' && (target.type === 'text' || ...)) {
            if (target.id === 'overrideDaysInput' || target.id === 'overrideRemarksInput') {
                e.preventDefault();
                document.getElementById('btnOverrideSave').click(); // Submit override form
            } else if (target.id === 'search' && typeof onSearchInput === 'function') {
                e.preventDefault();
                onSearchInput(); // Trigger search function
            }
        }
    }
});
```
By default in HTML forms, pressing Enter in any text input triggers a form submit. In this app that would be disruptive (it could reload the whole page). This global listener intercepts Enter keystrokes. For specific fields (`overrideDaysInput`, `overrideRemarksInput`) it clicks the correct save button. For the `search` input it triggers `onSearchInput()`. For all other inputs it does nothing (which means pressing Enter in a random text box does not accidentally submit the form).

---

## Body Class — How Pages Get Different Layouts

At the top of the `<body>` tag in Site.Master, there is inline server-side code:
```asp
<%
    string bodyClass = "";
    string rawUrl = Request.RawUrl.ToLower();
    if (rawUrl.Contains("attendance.aspx")) {
        bodyClass = "attendance-page";
    } else if (rawUrl.Contains("dashboard.aspx") || rawUrl.Contains("dashboard")) {
        bodyClass = "dashboard-page";
    } else {
        bodyClass = "sticky-nav-page";
    }
%>
<body id="page-top" class="<%= bodyClass %>">
```

| Page | Body Class | Effect |
|---|---|---|
| Attendance.aspx | `attendance-page` | Navbar is `static-top` (not sticky — it scrolls away with the page) |
| Dashboard.aspx | `dashboard-page` | Has sidebar layout |
| All others | `sticky-nav-page` | Navbar is `sticky-top` (always visible at top), content gets a 60px top margin |

The Attendance page's navbar is not sticky because the attendance grid is very wide and the user scrolls a lot; keeping the nav in the way would take up screen space.

---

## The Sidebar (Dashboard Only)

The sidebar (`phSidebar`) is only visible on Dashboard.aspx.

### User Photo
```html
<img src="http://windflower.lrde.com/empphotos/Dsc_<%= Session["PCNO"] %>.jpg"
     onerror="this.onerror=null; this.src='Static/Images/default_avatar.png';" />
```
The photo is fetched from the internal company web server using the PCNO. For example, PCNO `10047` tries to load `Dsc_10047.jpg`. If the photo does not exist on the server (404 or network error), the `onerror` handler sets the `src` to the default avatar image. The `this.onerror=null` prevents an infinite loop if the default avatar itself fails to load.

### Role Badge and Divisions Box
```asp
<% int sideRole = Convert.ToInt32(Session["Role"] ?? 0);
   string sideRoleMode = Session["RoleMode"]?.ToString() ?? "";
   if (sideRole == 0 || sideRole == 6 || sideRoleMode == "SubUser") { %>
<div class="sidebar-divisions-box">
    <!-- Show anchor POCs for Sub Users -->
    <!-- Show accessible divisions (blue badges) -->
    <!-- Show accessible categories (green badges) -->
</div>
<% } %>
```
The divisions box is only shown for POC (Role 0) and Sub User (Role 6 or RoleMode = "SubUser"). Admins do not see it because they have access to everything and showing "All Divisions" is not informative.

---

## Role Switcher Dropdown (Navbar, Right Side)

Only rendered if the user has 2 or more available roles:
```asp
<% if (AvailableUserRoles != null && AvailableUserRoles.Count > 1) { %>
    <div class="dropdown topbar-role-dropdown">
        <button ...>
            [current role icon + title + chevron]
        </button>
        <div class="dropdown-menu topbar-role-menu">
            <% foreach (var rOpt in AvailableUserRoles) {
                bool isCur = rOpt.RoleMode == CurrentRoleMode;
                string switchHref = Request.Url.AbsolutePath + "?switchRole=" + rOpt.RoleMode;
            %>
                <a href="<%= switchHref %>" class="topbar-role-item <%= isCur ? "is-active" : "" %>">
                    [role icon + title + subtitle + Active badge or Switch arrow]
                </a>
            <% } %>
        </div>
    </div>
<% } %>
```
Each role in the list is a simple `<a href>` link. Clicking it navigates to the current page URL with `?switchRole=RoleName` appended. Site.Master's `Page_Load` then handles this parameter on the next request (Step 3 above).

---

## ContentPlaceholders — How Pages Inject Their Content

Site.Master defines three `ContentPlaceHolder` elements that child pages fill:

| PlaceHolder ID | Where in Page | Purpose |
|---|---|---|
| `TitleContent` | Inside `<title>` tag in `<head>` | Page-specific browser tab title |
| `HeadContent` | End of `<head>` | Page-specific CSS and JavaScript |
| `MainContent` | Inside `.container-main` div | The actual page content |

Example — in `Attendance.aspx`:
```asp
<asp:Content ContentPlaceHolderID="TitleContent" runat="server">Attendance</asp:Content>

<asp:Content ContentPlaceHolderID="HeadContent" runat="server">
    <link href="..." rel="stylesheet" />
    <script src="..."></script>
</asp:Content>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
    <h2>Attendance</h2>
    ... rest of attendance page HTML ...
</asp:Content>
```

---

## Summary of What Site.Master Controls on Every Page

| Feature | Controlled How |
|---|---|
| Auto-close expired contracts | `Page_Load` → `DBHelper.AutoCloseExpiredContracts()` |
| Session guard / forced logout | `Page_Load` checks `Session["PCNO"]` vs auth cookie |
| Role switch handling | `?switchRole=` query param → `DBHelper.SwitchUserRole()` |
| Navbar visibility (links shown/hidden) | `phNavAdminLinks.Visible`, `phEmployeeMaster.Visible`, etc. |
| Sidebar vs topnav | `isDashboard` → `phSidebar.Visible` / `phTopNav.Visible` |
| Active nav link highlighting | `GetNavClass()` method |
| Role icon/color in role switcher | `GetRoleBadgeBg()` / `GetRoleBadgeColor()` |
| Notification bell badge count | `UnreadCount` from SQL query |
| Pending draft count badge | `PendingDraftCount` from SQL query |
| Logout | `btnLogout_Click` → `Session.Clear()` + `FormsAuthentication.SignOut()` |
| Dark/light theme | `toggleAppTheme()` + localStorage |
| Toast notifications | `showToast()` — used by all child pages |
| Interactive welcome tour | Full tour engine embedded here |

---

## Tables Touched by Site.Master on Every Page Load

| Table | Why |
|---|---|
| `Contracts` | `AutoCloseExpiredContracts()` — mark expired contracts as closed |
| `AttendanceRemarks` | Count unread remarks for admin bell badge |
| `UserDivisions` | Load accessible divisions for POC and Sub User sidebar |
| `UserTiers` + `Tiers` | Load accessible categories for POC and Sub User sidebar |
| `SubUserAnchor` + `AppUsers` | Load anchor POC names for Sub User sidebar |
| `AttendanceDraft` + `Employees` | Count pending draft records for POC badge |
| `AppUsers` | Fallback role reload if `Session["UserRoles"]` is null |
| `CategoryShareGrant` + `MainCategory` | Part of fallback role reload |

---

*Next: See `03_DBHelper.md` for the Database Helper — the core data access layer used by every page.*
