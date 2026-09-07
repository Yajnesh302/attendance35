# 04 — Dashboard.aspx + Dashboard.aspx.cs

**Files:**
- `Dashboard.aspx` — 1,025 lines (HTML/CSS/JS markup)
- `Dashboard.aspx.cs` — 190 lines (C# code-behind)

---

## What Is the Dashboard?

The Dashboard is the **home page** of the application. Every user lands here immediately after a successful login.

It is NOT a passive display page — it actively decides which modules to show based on the logged-in user's role. An admin sees a 3-page swipeable carousel with all modules. A regular user sees a simple 4-card grid with only their permitted modules.

It also checks for unread notices on every page load and shows an alert banner at the top if any exist.

---

## File Structure

`Dashboard.aspx` uses ASP.NET's **Master Page** pattern. It has three `<asp:Content>` blocks:
- `Content1` (TitleContent): Sets the browser tab title to "Dashboard"
- `Content2` (HeadContent): All the CSS styles for the Dashboard
- `Content3` (MainContent): The actual HTML content — the module cards, carousel, and JavaScript

The `<%@ Page %>` directive at the top ties this file to:
- `Site.Master` — the master page shell (navigation, header, sidebar)
- `Dashboard.aspx.cs` — the C# code-behind where `Page_Load` runs

---

## Code-Behind: Dashboard.aspx.cs

### Public Properties (used in the ASPX markup)

```csharp
public bool IsAdminRole { get; set; }
public bool IsSubUserMode { get; set; }
```

These two boolean properties are set in `Page_Load` and then read directly inside the ASPX markup using `<% if (IsAdminRole) { %>` tags. This is how ASP.NET WebForms allows C# logic to control which HTML blocks are rendered.

---

### `Page_Load(object sender, EventArgs e)` — The main entry point

```csharp
protected void Page_Load(object sender, EventArgs e)
```

This method runs on every request to `Dashboard.aspx`, whether it is a first visit (GET) or a form postback (POST).

**Step 1: Authentication guard**
```csharp
if (!User.Identity.IsAuthenticated)
{
    Response.Redirect("Login.aspx");
    return;
}
```
`User.Identity.IsAuthenticated` is set by ASP.NET's Forms Authentication system (when Login.aspx calls `FormsAuthentication.SetAuthCookie`). If the user is not authenticated (e.g. session expired or someone typed the URL directly), they are immediately redirected back to the login page. The `return` after the redirect is critical — without it, code after the redirect would still run.

**Step 2: Handle role-switch request**
```csharp
string switchRoleParam = Request.QueryString["switchRole"];
if (!string.IsNullOrEmpty(switchRoleParam))
{
    if (DBHelper.SwitchUserRole(pcno, switchRoleParam, Session))
    {
        Response.Redirect("Dashboard.aspx");
        return;
    }
}
```
If the URL contains `?switchRole=SomeRole` (added by Site.Master when user clicks the role-switcher), this block calls `DBHelper.SwitchUserRole(...)` to update the session to the new role. If the switch succeeds, it redirects to `Dashboard.aspx` without the query parameter. This produces a clean URL and forces the page to re-render fresh with the new role. If the switch fails (invalid role name), it silently continues — the user stays in their current role.

**Step 3: Read role from session and set properties**
```csharp
int role = Session["Role"] != null ? Convert.ToInt32(Session["Role"]) : 0;
string roleMode = Session["RoleMode"] != null ? Session["RoleMode"].ToString() : "";
IsAdminRole = (role == 1 || role == 4);
IsSubUserMode = (roleMode == "SubUser" || role == 6);
```
- `IsAdminRole = true` when role is 1 (Admin) or 4 (Super Admin)
- `IsSubUserMode = true` when RoleMode is "SubUser" OR the role number is 6 (explicit Sub User role)

These two properties control which HTML sections are rendered. They are `public` so the ASPX markup can read them.

**Step 4: Hide admin-only server controls (non-admin users only)**
```csharp
if (!IsPostBack)  // Only on the first full load, not on postbacks
{
    if (!IsAdminRole)
    {
        phAdmin_Emp.Visible       = false;
        phAdmin_Calc.Visible      = false;
        phAdmin_AdminMgmt.Visible = false;
        phAdmin_Settings.Visible  = false;
        phAdmin_Vendors.Visible   = false;
        phAdmin_Contracts.Visible = false;
        phAdmin_Wages.Visible     = false;
        phAdmin_Remarks.Visible   = false;
    }
    CheckUnreadNotices();
}
```
`!IsPostBack` means "only do this on the first page load, not when the user submits a form on this page." The Dashboard has no forms, so in practice this always runs. But it is good practice to include `!IsPostBack` checks to avoid redundant work.

The `phAdmin_*` variables are `<asp:PlaceHolder>` server controls defined in the ASPX markup. Setting `.Visible = false` tells ASP.NET to NOT render that block of HTML at all — it is completely absent from the HTML sent to the browser. This is different from CSS `display: none` (which sends the HTML but hides it). Server-side hiding is more secure because the HTML never reaches the client.

**Step 5: Check for unread notices**
```csharp
CheckUnreadNotices();
```
Called on every first page load to determine whether to show the notice alert banner.

---

### `CheckUnreadNotices()` — Determine if there are unread notices for this user

```csharp
private void CheckUnreadNotices()
```

This method checks the database for any notices that exist but have not yet been marked as "read" by the current user. If found, it shows a colored alert banner at the top of the page.

**First: Skip for Sub Users**
```csharp
string roleMode = Session["RoleMode"] != null ? Session["RoleMode"].ToString() : "";
if (roleMode == "SubUser")
{
    phUnreadNoticeAlert.Visible = false;
    return;
}
```
Sub Users (data entry operators) are not shown notice alerts. They have a limited interface and do not manage or read organizational notices.

**The query varies by role — three cases:**

**Case 1: Super Admin (role == 4)**
```sql
SELECT n.Id, n.Name, n.MainCategoryId, mc.Name AS MainCategoryName
FROM Notices n
LEFT JOIN MainCategory mc ON n.MainCategoryId = mc.Id
WHERE n.IsHidden = 0
  AND NOT EXISTS (
      SELECT 1 FROM NoticeReads nr
      WHERE nr.NoticeId = n.Id AND nr.PCNO = :PCNO
  )
ORDER BY n.UploadDate DESC
```
Super Admin sees ALL notices in the system (except hidden ones: `IsHidden = 0`). The `NOT EXISTS` subquery filters out any notice that already has a row in `NoticeReads` for this PCNO — meaning the Super Admin has already read/acknowledged it.

**Case 2: Admin (role == 1)**
```sql
SELECT n.Id, n.Name, n.MainCategoryId, mc.Name AS MainCategoryName
FROM Notices n
LEFT JOIN MainCategory mc ON n.MainCategoryId = mc.Id
WHERE n.IsHidden = 0
  AND (
      n.MainCategoryId IS NULL              -- global notices (no specific category)
      OR n.MainCategoryId IN (
          SELECT mc2.Id FROM MainCategory mc2
          WHERE {mcCond}                    -- category-specific filter (see below)
      )
  )
  AND NOT EXISTS (...)                      -- same unread filter
ORDER BY n.UploadDate DESC
```
Admins only see notices for:
- Notices with no category (`MainCategoryId IS NULL` — global company-wide notices)
- Notices belonging to their own categories

The `mcCond` part changes based on `roleMode`:
| RoleMode | Condition |
|---|---|
| "PrimaryAdmin" | `mc2.AdminPCNO = :PCNO` — categories this admin owns |
| "SecondaryAdmin" | `mc2.Id IN (SELECT ... FROM CategoryShareGrant WHERE SharedWithPCNO = :PCNO AND IsActive = 1)` — categories shared with this admin |
| Any other Admin mode | UNION of both conditions above (OR logic) |

This dynamic SQL is built using C# string interpolation (`$@"... {mcCond} ..."`) — the condition text is inserted into the query string before it runs.

**Case 3: Regular User / POC (role == 0)**
```sql
SELECT n.Id, n.Name, n.MainCategoryId, mc.Name AS MainCategoryName
FROM Notices n
LEFT JOIN MainCategory mc ON n.MainCategoryId = mc.Id
WHERE n.IsHidden = 0
  AND (
      n.MainCategoryId IS NULL         -- global notices
      OR n.MainCategoryId IN (
          SELECT t.MainCategoryId
          FROM Tiers t
          JOIN UserTiers ut ON t.Id = ut.TierId
          WHERE ut.PCNO = :PCNO        -- categories this POC is assigned to
      )
  )
  AND NOT EXISTS (...)
ORDER BY n.UploadDate DESC
```
A POC only sees notices for categories they have tiers in (via `UserTiers`). This ensures a POC assigned to "Skilled Workers" only sees notices posted for that category, not notices for "Drivers" or "Security Guards".

**After the query — building the banner text:**
```csharp
if (dtUnread != null && dtUnread.Rows.Count > 0)
{
    phUnreadNoticeAlert.Visible = true;
    int count = dtUnread.Rows.Count;

    // Collect unique category names from all unread notices
    List<string> mainCatNames = new List<string>();
    foreach (DataRow r in dtUnread.Rows)
    {
        string mcName = r["MainCategoryName"] != DBNull.Value ...
            ? r["MainCategoryName"].ToString() : "General";
        if (!mainCatNames.Contains(mcName))
            mainCatNames.Add(mcName);
    }
    string catLabel = string.Join(", ", mainCatNames); // e.g. "Skilled Workers, Drivers"

    // Build the badge (blue pill showing category names)
    litNoticeMainCatBadge.Text = "<span class='badge ...'>...</span>";

    // Build the message text
    if (count == 1)
        litNoticeAlertMessage.Text = "You have 1 unread announcement: \"Title\" for Category.";
    else
        litNoticeAlertMessage.Text = "You have N unread announcements for Category (Latest: \"Title\").";
}
else
{
    phUnreadNoticeAlert.Visible = false;
}
```

The `litNoticeMainCatBadge` and `litNoticeAlertMessage` are `<asp:Literal>` server controls — they inject raw HTML text into the page at those positions. `HttpUtility.HtmlEncode()` is used on any user-supplied text (like the notice title or category name) to prevent XSS attacks — for example, if a notice title contains `<script>`, `HtmlEncode` converts it to `&lt;script&gt;` which displays as text rather than executing as code.

---

## ASPX Markup: How the Page Renders

The `MainContent` block in the ASPX file has two major sections divided by an inline C# `if` block:

```html
<% if (IsAdminRole) { %>
    <!-- ADMIN: 3-page swipeable carousel -->
<% } else { %>
    <!-- USER/POC/SUBUSER: simple card grid -->
<% } %>
```

This `<% if %>` syntax is a **Render Block** — it runs at page rendering time (on the server). The server evaluates the condition and only sends the matching HTML to the browser. The other block is never sent.

---

## Admin View: 3-Page Swipeable Carousel

The admin carousel lives inside a `<div id="dashboardCarouselWrapper">` container. It has three pages (called "carousel pages") that slide horizontally.

### How the Carousel is Structured

```
dashboardCarouselWrapper
  └── dashboardCarouselTrack-container (overflow: hidden — clips pages outside view)
        └── dashboardCarouselTrack (CSS transform moves this left/right to show different pages)
              ├── Page 1 (active-page by default)
              ├── Page 2
              └── Page 3
  └── carouselDotsContainer (3 dot buttons at the bottom)
```

### Page 1: Daily Operations (4 Cards)

Shows the 4 most frequently used modules in a `dashboard-grid-4` (4 equal columns):

| Card | Theme Color | Links To | Admin-Only? |
|---|---|---|---|
| Employee | Indigo (purple) | Employee.aspx | Yes (`phAdmin_Emp`) |
| Attendance | Emerald (green) | Attendance.aspx | No (shown always) |
| Ledger | Sky (blue) | Ledger.aspx | No (shown always) |
| Remarks Inbox | Purple | Remarks.aspx | Yes (`phAdmin_Remarks`) |

The "Employee" and "Remarks Inbox" cards are wrapped in `<asp:PlaceHolder>` server controls. When `IsAdminRole = false`, the code-behind sets their `.Visible = false` and ASP.NET removes them from the HTML entirely.

### Page 2: Periodic Tasks & Notices (3 Cards)

Shown in a `dashboard-grid-3` (3 equal columns). The Calculation and Documents cards are inside `phAdmin_Calc` (hidden for non-admins). Notices is always visible.

| Card | Theme Color | Links To |
|---|---|---|
| Calculation | Amber (orange) | Calculation.aspx |
| Documents | Slate (grey) | Documents.aspx |
| Notices | Emerald | Notices.aspx |

### Page 3: System Administration (3 Cards + Sub-Panel)

Page 3 has two views that slide horizontally within the same page:

**Primary View** (`page3PrimaryView`) — 3 cards:
| Card | Theme Color | Links To |
|---|---|---|
| Admin Management | Rose (red) | AdminManagement.aspx |
| Settings | Slate | Settings.aspx |
| Service Provider | Amber | (clicking this opens the Sub-Panel, NOT a new page) |

**Sub-Panel View** (`page3SubPanel`) — appears when "Service Provider" is clicked, slides in from the right. Shows 3 sub-cards:
| Card | Theme Color | Links To |
|---|---|---|
| Vendors | Sky (blue) | Vendors.aspx |
| Contracts | Amber | Contracts.aspx |
| Wages & Statutory | Emerald | Wages.aspx |

The Sub-Panel has a "Back to System Administration" button that slides the primary view back in.

---

## Card HTML Structure

Every card uses the same HTML pattern:
```html
<a href="TargetPage.aspx" class="card-custom card-theme-COLORNAME">
    <div class="card-icon-box">
        <i class="fas fa-ICONNAME"></i>
    </div>
    <div class="card-content-body">
        <h3>Card Title</h3>
        <p>Short description of what this module does</p>
    </div>
    <div class="card-circle-arrow">
        <i class="fas fa-arrow-right"></i>
    </div>
    <svg class="card-wave-accent" viewBox="0 0 100 100" fill="currentColor">
        <path d="M0 50 Q 25 30, 50 50 T 100 50 L 100 100 L 0 100 Z" opacity="0.3"/>
    </svg>
</a>
```

- The entire card is an `<a>` tag — clicking anywhere on the card navigates to the target page
- `card-custom` provides the base structure (padding, border-radius, min-height, flex layout)
- `card-theme-COLORNAME` provides the color scheme (background gradient, border color, icon/text colors)
- `card-wave-accent` is an inline SVG at the bottom-right corner that creates a subtle wavy decorative background shape — purely visual
- On hover: the card lifts (`translateY(-6px)`), the icon box scales up, and the wave accent becomes more visible

**Available themes and their colors:**
| Theme Class | Primary Color | Used For |
|---|---|---|
| card-theme-indigo | Purple/Indigo | Employee |
| card-theme-emerald | Green | Attendance, Notices |
| card-theme-sky | Blue | Ledger, Vendors |
| card-theme-purple | Pink/Fuchsia | Remarks Inbox |
| card-theme-amber | Amber/Orange | Calculation, Contracts, Service Provider |
| card-theme-slate | Grey/Navy | Documents, Settings |
| card-theme-rose | Red/Pink | Admin Management |

---

## JavaScript: Carousel Logic

All the carousel behavior is controlled by a single `<script>` block inside the admin `<% if (IsAdminRole) %>` section. It runs on `DOMContentLoaded` (when the full DOM is ready).

### Variables

```javascript
var wrapper = document.getElementById('dashboardCarouselWrapper');   // outer container
var track   = document.getElementById('dashboardCarouselTrack');     // inner sliding track
var dots    = document.querySelectorAll('#carouselDotsContainer .carousel-dot'); // 3 dot buttons
var pages   = document.querySelectorAll('.dashboard-carousel-page'); // 3 page divs

var currentPage = 0;   // 0-indexed (0 = Page 1, 1 = Page 2, 2 = Page 3)
var totalPages  = 3;
var isScrolling = false;  // prevents rapid mouse-wheel page-skipping
```

---

### `updateCarousel()` — Apply current page state to the DOM

```javascript
function updateCarousel() {
    track.style.transform = 'translateX(-' + (currentPage * 100) + '%)';
    // ...update dots active state...
    // ...update pages active-page class...
    if (currentPage !== 2) resetPage3SubPanel();
}
```

This is the **single source of truth** for the carousel visual state. It does three things every time it is called:

1. **Moves the track** using CSS `transform: translateX(...)`:
   - Page 0: `translateX(0%)` — no movement (page 1 is visible)
   - Page 1: `translateX(-100%)` — track slides left by 100% (page 2 visible)
   - Page 2: `translateX(-200%)` — track slides left by 200% (page 3 visible)
   The CSS transition `0.45s cubic-bezier(0.16, 1, 0.3, 1)` on the track makes this slide smoothly.

2. **Updates dot indicators** — adds `active` class to the current page's dot (which makes it wider and purple), removes it from others.

3. **Updates page visibility** — adds `active-page` class to the current page div (which makes it `opacity: 1, pointer-events: auto`), removes it from others. This prevents accidentally clicking invisible card links on inactive pages.

4. **Resets Page 3 sub-panel** — if you navigate away from Page 3 while the Service Provider sub-panel is open, it automatically slides back to the primary view (no animation since the page is not visible anyway).

---

### `goToPage(index, immediate)` — Navigate to a specific page

```javascript
function goToPage(index, immediate) {
    if (index < 0) index = 0;
    if (index >= totalPages) index = totalPages - 1;
    currentPage = index;
    if (immediate) {
        // Temporarily disable transition for instant jumps (used on init)
        track.style.transition = 'none';
        updateCarousel();
        void track.offsetHeight; // force browser to recalculate layout
        track.style.transition = oldTrans;
    } else {
        updateCarousel();
    }
}
```

The `immediate` parameter disables the CSS transition momentarily, used during initialization (`updateCarousel()` call at the bottom) so the first page appears instantly without a visible slide animation.

`void track.offsetHeight` is a known browser technique to force a **layout flush** — it makes the browser process the "transition = none" before re-enabling the transition. Without this, browsers might batch the changes and the transition disable would be ignored.

---

### `resetPage3SubPanel(immediate)` — Reset Service Provider sub-panel

```javascript
function resetPage3SubPanel(immediate) {
    page3SubPanel.classList.remove('subpanel-visible');
    page3SubPanel.classList.add('subpanel-hidden-right');
    page3PrimaryView.classList.remove('subpanel-hidden-left');
    page3PrimaryView.classList.add('subpanel-visible');
}
```

Slides the primary view back into view and moves the sub-panel back off to the right. Used both by the "Back" button and automatically when navigating away from Page 3.

The CSS classes used:
- `.subpanel-visible` — `opacity: 1, transform: translateX(0), position: relative`
- `.subpanel-hidden-right` — `opacity: 0, transform: translateX(35px), position: absolute` — off to the right, invisible
- `.subpanel-hidden-left` — `opacity: 0, transform: translateX(-35px), position: absolute` — off to the left, invisible

The `position: absolute` on hidden panels prevents them from taking up layout space when not visible.

---

### Global Exports (`window.dashboardGoToPage`, `window.dashboardOpenServiceProvider`)

```javascript
window.dashboardGoToPage = goToPage;
window.dashboardOpenServiceProvider = function () {
    page3PrimaryView.classList.add('subpanel-hidden-left');
    page3SubPanel.classList.add('subpanel-visible');
    // ...
};
window.dashboardResetServiceProvider = resetPage3SubPanel;
```

These functions are attached to the global `window` object so that other scripts (specifically the **Interactive Tour** from Site.Master) can call them. For example, the tour might call `window.dashboardGoToPage(2)` to navigate to Page 3 as part of a step, or `window.dashboardOpenServiceProvider()` to open the sub-panel for a guided tour step.

---

### Navigation Input Handlers

**Dot Clicks:**
```javascript
dots.forEach(function (dot) {
    dot.addEventListener('click', function () {
        var pageIndex = parseInt(this.getAttribute('data-page'), 10);
        goToPage(pageIndex);
    });
});
```
Each dot has a `data-page` attribute (`0`, `1`, `2`). Clicking a dot calls `goToPage` with that index.

**Mouse Wheel Navigation (scroll over the carousel):**
```javascript
window.addEventListener('wheel', function (e) {
    var rect = wrapper.getBoundingClientRect();
    var isOverDashboard = (e.clientX >= rect.left && e.clientX <= rect.right &&
                           e.clientY >= rect.top  && e.clientY <= rect.bottom);
    if (!isOverDashboard) return;         // Only act if mouse is over carousel
    if (isScrolling) return;             // Debounce rapid scrolling
    if (Math.abs(e.deltaY) < 25) return; // Ignore tiny accidental scrolls

    if (e.deltaY > 0 && currentPage < totalPages - 1) {
        isScrolling = true;
        goToPage(currentPage + 1);
        setTimeout(function () { isScrolling = false; }, 400); // 400ms cooldown
    } else if (e.deltaY < 0 && currentPage > 0) {
        isScrolling = true;
        goToPage(currentPage - 1);
        setTimeout(function () { isScrolling = false; }, 400);
    }
}, { passive: true });
```
`deltaY > 0` = scroll down = go to next page. `deltaY < 0` = scroll up = go to previous page. `{ passive: true }` tells the browser that this listener will not call `preventDefault()`, allowing the browser to scroll the page normally without waiting for the listener to finish — important for performance.

**Touch/Swipe Support (mobile and touch screens):**
```javascript
wrapper.addEventListener('touchstart', function (e) {
    touchStartX = e.changedTouches[0].screenX;
}, { passive: true });

wrapper.addEventListener('touchend', function (e) {
    touchEndX = e.changedTouches[0].screenX;
    handleSwipe();
}, { passive: true });

function handleSwipe() {
    var diffX = touchEndX - touchStartX;
    if (Math.abs(diffX) > 40) {  // Must swipe at least 40px horizontally
        if (diffX < 0) goToPage(currentPage + 1); // Swipe left = next page
        else           goToPage(currentPage - 1); // Swipe right = prev page
    }
}
```
Records the X position where the finger was placed and where it was lifted. If the horizontal distance is more than 40px (to ignore tiny accidental touches), it navigates.

**Keyboard Arrow Keys:**
```javascript
document.addEventListener('keydown', function (e) {
    if (e.key === 'ArrowRight') goToPage(currentPage + 1);
    else if (e.key === 'ArrowLeft')  goToPage(currentPage - 1);
});
```
Allows navigation with keyboard arrow keys. `goToPage` already clamps the value to `[0, totalPages-1]`, so pressing ArrowLeft on page 1 or ArrowRight on page 3 does nothing.

---

## Regular User / POC / Sub User View

When `IsAdminRole == false`, the entire carousel is not rendered. Instead, a simpler layout is shown:

```html
<% if (!IsSubUserMode) { %>
    <!-- 4-card grid: Attendance, Ledger, Notices, Remarks -->
<% } else { %>
    <!-- 2-card grid: Attendance, Ledger (Sub User only sees data-entry modules) -->
<% } %>
```

The section title changes dynamically:
```html
<i class="fas <%= IsSubUserMode ? "fa-user-edit" : "fa-th-large" %>"></i>
<span><%= IsSubUserMode ? "Sub User Workspace (Data Entry)" : "My Workspace" %></span>
```
`<%= ... %>` is a **render expression** — it outputs the string value of the C# expression directly into the HTML.

**Regular User/POC sees 4 cards:**
- Attendance — "Mark, review & submit attendance"
- Ledger — "Track leave balance & adjustments"
- Notices — "View announcements & notices"
- Remarks (UserRemarks.aspx) — "View sent & report attendance corrections"

**Sub User sees only 2 cards:**
- Attendance — "Enter & save draft daily attendance" (different description!)
- Ledger — "Track leave balance & adjustments"

Sub Users do not see Notices or Remarks. They are data-entry operators, not full POC users.

---

## Unread Notice Alert Banner

Defined in the ASPX with:
```html
<asp:PlaceHolder ID="phUnreadNoticeAlert" runat="server" Visible="false">
    <div class="alert notice-alert-banner ...">
        ...
        <asp:Literal ID="litNoticeMainCatBadge" runat="server" />
        <asp:Literal ID="litNoticeAlertMessage" runat="server" />
        ...
        <a href="Notices.aspx">View Notices</a>
    </div>
</asp:PlaceHolder>
```

The `PlaceHolder` starts as `Visible="false"` (hidden by default). `CheckUnreadNotices()` in the code-behind sets it to `Visible = true` if there are unread notices, and fills the two `Literal` controls with the appropriate HTML text.

The banner appears at the top of the page for all roles (except Sub Users). It shows:
- A yellow "bullhorn" icon
- A blue badge showing the category name(s)
- A message like "You have 3 unread announcements for Skilled Workers (Latest: 'June Wage Revision')"
- A "View Notices" button linking to Notices.aspx

---

## Complete Flow on Every Page Load

```
Browser requests Dashboard.aspx
    |
    v
Site.Master.cs Page_Load runs first (session check, navigation setup, tour system)
    |
    v
Dashboard.aspx.cs Page_Load runs:
    1. Check FormsAuthentication → redirect to login if not authenticated
    2. Check ?switchRole param → switch role and redirect if present
    3. Read role/roleMode from Session → set IsAdminRole, IsSubUserMode
    4. On first load (!IsPostBack):
       a. Hide admin PlaceHolders if user is not admin
       b. Run CheckUnreadNotices() → query DB → show/hide notice alert banner
    |
    v
ASP.NET renders the ASPX markup:
    - <% if (IsAdminRole) %> → choose admin carousel OR user card grid
    - Server controls with Visible=false are completely omitted from output HTML
    - Literals (litNoticeMainCatBadge, litNoticeAlertMessage) inject built HTML text
    |
    v
Browser receives full HTML page:
    - CSS from HeadContent styles the cards and carousel
    - JavaScript (inside <% if (IsAdminRole) %>) sets up:
        * Dot click navigation
        * Mouse-wheel page switching
        * Touch swipe support
        * Keyboard arrow key navigation
        * Service Provider sub-panel show/hide
        * Global window.dashboardGoToPage (for Tour integration)
```

---

## Summary: All Controls and Properties

| C# Name | Type | Purpose |
|---|---|---|
| `IsAdminRole` | `public bool` property | Controls which HTML section renders (admin carousel vs user grid) |
| `IsSubUserMode` | `public bool` property | Controls Sub User vs regular user UI differences |
| `phUnreadNoticeAlert` | PlaceHolder | The unread notice alert banner container |
| `litNoticeMainCatBadge` | Literal | The blue category badge inside the notice alert |
| `litNoticeAlertMessage` | Literal | The alert message text ("You have N unread...") |
| `phAdmin_Emp` | PlaceHolder | Employee card (hidden for non-admins) |
| `phAdmin_Calc` | PlaceHolder | Calculation + Documents cards (hidden for non-admins) |
| `phAdmin_AdminMgmt` | PlaceHolder | Admin Management card (hidden for non-admins) |
| `phAdmin_Settings` | PlaceHolder | Settings card (hidden for non-admins) |
| `phAdmin_Vendors` | PlaceHolder | Vendors card (hidden for non-admins) |
| `phAdmin_Contracts` | PlaceHolder | Contracts card (hidden for non-admins) |
| `phAdmin_Wages` | PlaceHolder | Wages & Statutory card (hidden for non-admins) |
| `phAdmin_Remarks` | PlaceHolder | Remarks Inbox card (hidden for non-admins) |

---

*Next: See `05_Employee.md` for the Employee Master page — the most complex data-management page in the application.*
