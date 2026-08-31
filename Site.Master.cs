using System;
using System.Collections.Generic;
using System.Data;
using System.Web.Security;
using AttendanceApp.Utils;
using Oracle.ManagedDataAccess.Client;

namespace AttendanceApp
{
    public partial class SiteMaster : System.Web.UI.MasterPage
    {
        protected int UnreadCount { get; private set; }
        protected int PendingDraftCount { get; private set; }
        protected List<string> UserAllowedDivisions { get; private set; }
        protected List<string> UserAllowedCategories { get; private set; }
        protected List<string> UserAnchorPocs { get; private set; }
        public List<UserRoleOption> AvailableUserRoles { get; private set; }
        public string CurrentRoleMode { get; private set; }
        public string CurrentRoleTitle { get; private set; }
        public string CurrentRoleIcon { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Auto close expired contracts on page load
            try
            {
                AttendanceApp.Utils.DBHelper.AutoCloseExpiredContracts();
            }
            catch { }

            if (Session["PCNO"] == null && Page.User.Identity.IsAuthenticated)
            {
                // Session was lost (e.g., app rebuild) but auth cookie remains. Force logout.
                FormsAuthentication.SignOut();
                Response.Redirect("Login.aspx");
                return;
            }

            string pcno = Session["PCNO"] != null ? Session["PCNO"].ToString() : "";

            // Handle role switch parameter from any page
            string switchRoleParam = Request.QueryString["switchRole"];
            if (!string.IsNullOrEmpty(switchRoleParam) && !string.IsNullOrEmpty(pcno))
            {
                if (DBHelper.SwitchUserRole(pcno, switchRoleParam, Session))
                {
                    string rawPath = Request.Url.AbsolutePath;
                    Response.Redirect(rawPath);
                    return;
                }
            }

            string roleMode = Session["RoleMode"] != null ? Session["RoleMode"].ToString() : "";
            int role = Session["Role"] != null ? Convert.ToInt32(Session["Role"]) : 0;

            CurrentRoleMode = roleMode;
            AvailableUserRoles = Session["UserRoles"] as List<UserRoleOption>;
            if (AvailableUserRoles == null || AvailableUserRoles.Count == 0)
            {
                if (!string.IsNullOrEmpty(pcno))
                {
                    AvailableUserRoles = DBHelper.GetAvailableUserRoles(pcno);
                    Session["UserRoles"] = AvailableUserRoles;
                }
            }

            if (AvailableUserRoles != null && AvailableUserRoles.Count > 0)
            {
                var curObj = AvailableUserRoles.Find(r => string.Equals(r.RoleMode, roleMode, StringComparison.OrdinalIgnoreCase)) ?? AvailableUserRoles[0];
                CurrentRoleTitle = curObj.Title;
                CurrentRoleIcon = curObj.Icon;
            }

            // Query unread remarks count for admin (server-side, no extra round-trip)
            if (role == 1 || role == 4)
            {
                try
                {
                    string sql = "SELECT COUNT(DISTINCT ar.SubmittedBy || '_' || ar.EmpID || '_' || ar.Message || '_' || TO_CHAR(ar.CreatedAt, 'YYYYMMDDHH24MISS')) FROM AttendanceRemarks ar WHERE ar.IsRead = 0";
                    object result = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), sql);
                    UnreadCount = result != null && result != System.DBNull.Value ? Convert.ToInt32(result) : 0;
                }
                catch { UnreadCount = 0; }
            }

            if (role == 1 || role == 4)
            {
                lblUserName.InnerText = (role == 4) ? "Super Admin" : "Administrator";
                myfw.Attributes["class"] = "fas fa-user-shield text-success";
                phEmployeeMaster.Visible = true;
                phCalculation.Visible = true;
            }
            else if (roleMode == "SubUser" || role == 6)
            {
                lblUserName.InnerText = "Sub User";
                myfw.Attributes["class"] = "fas fa-user-edit text-warning";
                phEmployeeMaster.Visible = false;
                phCalculation.Visible = false;

                // Load User Accessible Divisions & Categories for Sub User
                try
                {
                    UserAllowedDivisions = new List<string>();
                    string sqlDivs = "SELECT DivisionName FROM UserDivisions WHERE PCNO = :PCNO ORDER BY DivisionName ASC";
                    DataTable dtDivs = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), sqlDivs, new OracleParameter("PCNO", pcno));
                    foreach (DataRow row in dtDivs.Rows)
                    {
                        if (row["DivisionName"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["DivisionName"].ToString()))
                        {
                            UserAllowedDivisions.Add(row["DivisionName"].ToString());
                        }
                    }

                    UserAllowedCategories = new List<string>();
                    string sqlCats = @"
                        SELECT DISTINCT t.TierName
                        FROM UserTiers ut 
                        JOIN Tiers t ON ut.TierId = t.Id 
                        WHERE ut.PCNO = :PCNO
                        ORDER BY t.TierName ASC";
                    DataTable dtCats = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), sqlCats, new OracleParameter("PCNO", pcno));
                    foreach (DataRow row in dtCats.Rows)
                    {
                        if (row["TierName"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["TierName"].ToString()))
                        {
                            UserAllowedCategories.Add(row["TierName"].ToString());
                        }
                    }

                    UserAnchorPocs = new List<string>();
                    string sqlAnchors = @"
                        SELECT NVL(u.Name, sa.AnchorPocPCNO) AS PocName, sa.AnchorPocPCNO
                        FROM SubUserAnchor sa
                        LEFT JOIN AppUsers u ON sa.AnchorPocPCNO = u.PCNO AND (u.Role = 0 OR u.Role = 3)
                        WHERE sa.SubUserPCNO = :PCNO
                        ORDER BY u.Name ASC";
                    DataTable dtAnchors = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), sqlAnchors, new OracleParameter("PCNO", pcno));
                    foreach (DataRow row in dtAnchors.Rows)
                    {
                        string pName = row["PocName"].ToString();
                        string pPcno = row["AnchorPocPCNO"].ToString();
                        UserAnchorPocs.Add(string.Format("{0} ({1})", pName, pPcno));
                    }
                }
                catch { }
            }
            else
            {
                lblUserName.InnerText = "User (POC)";
                myfw.Attributes["class"] = "fas fa-user";
                phEmployeeMaster.Visible = false;
                phCalculation.Visible = false;

                // Load User Accessible Divisions & Categories for Regular User (POC)
                try
                {
                    UserAllowedDivisions = new List<string>();
                    string sqlDivs = "SELECT DivisionName FROM UserDivisions WHERE PCNO = :PCNO ORDER BY DivisionName ASC";
                    DataTable dtDivs = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), sqlDivs, new OracleParameter("PCNO", pcno));
                    foreach (DataRow row in dtDivs.Rows)
                    {
                        if (row["DivisionName"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["DivisionName"].ToString()))
                        {
                            UserAllowedDivisions.Add(row["DivisionName"].ToString());
                        }
                    }

                    UserAllowedCategories = new List<string>();
                    string sqlCats = @"
                        SELECT DISTINCT t.TierName
                        FROM UserTiers ut 
                        JOIN Tiers t ON ut.TierId = t.Id 
                        WHERE ut.PCNO = :PCNO
                        ORDER BY t.TierName ASC";
                    DataTable dtCats = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), sqlCats, new OracleParameter("PCNO", pcno));
                    foreach (DataRow row in dtCats.Rows)
                    {
                        if (row["TierName"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["TierName"].ToString()))
                        {
                            UserAllowedCategories.Add(row["TierName"].ToString());
                        }
                    }

                    // Query pending drafts for POC review
                    string sqlDrafts = @"
                        SELECT COUNT(*) 
                        FROM AttendanceDraft ad
                        JOIN Employees e ON ad.EmpID = e.MasterId
                        WHERE e.Department IN (SELECT DivisionName FROM UserDivisions WHERE PCNO = :PCNO)";
                    object draftRes = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), sqlDrafts, new OracleParameter("PCNO", pcno));
                    PendingDraftCount = draftRes != null && draftRes != DBNull.Value ? Convert.ToInt32(draftRes) : 0;
                }
                catch { }
            }

            // Toggle sidebar and top nav visibility based on the page
            string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
            bool isDashboard = currentPage.Equals("Dashboard.aspx", StringComparison.OrdinalIgnoreCase) ||
                               currentPage.Equals("Dashboard", StringComparison.OrdinalIgnoreCase);

            if (isDashboard)
            {
                phSidebar.Visible = true;
                phTopNav.Visible = false;
            }
            else
            {
                phSidebar.Visible = false;
                phTopNav.Visible = true;
            }

            int currentRole = Convert.ToInt32(Session["Role"] ?? 0);
            phNavAdminLinks.Visible = (currentRole == 1 || currentRole == 4);
            phNotifBell.Visible     = (currentRole == 1 || currentRole == 4);
            phStartTour.Visible     = isDashboard;
        }

        public string GetRoleBadgeBg(string mode)
        {
            if (string.Equals(mode, "SuperAdmin", StringComparison.OrdinalIgnoreCase)) return "rgba(245, 158, 11, 0.25)";
            if (string.Equals(mode, "PrimaryAdmin", StringComparison.OrdinalIgnoreCase)) return "rgba(79, 70, 229, 0.25)";
            if (string.Equals(mode, "SecondaryAdmin", StringComparison.OrdinalIgnoreCase)) return "rgba(2, 132, 199, 0.25)";
            if (string.Equals(mode, "SubUser", StringComparison.OrdinalIgnoreCase)) return "rgba(2, 132, 199, 0.25)";
            return "rgba(100, 116, 139, 0.25)";
        }

        public string GetRoleBadgeColor(string mode)
        {
            if (string.Equals(mode, "SuperAdmin", StringComparison.OrdinalIgnoreCase)) return "#fbbf24";
            if (string.Equals(mode, "PrimaryAdmin", StringComparison.OrdinalIgnoreCase)) return "#a5b4fc";
            if (string.Equals(mode, "SecondaryAdmin", StringComparison.OrdinalIgnoreCase)) return "#7dd3fc";
            if (string.Equals(mode, "SubUser", StringComparison.OrdinalIgnoreCase)) return "#7dd3fc";
            return "#cbd5e1";
        }

        protected string GetNavClass(string pageName)
        {
            string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
            if (currentPage.Equals(pageName, StringComparison.OrdinalIgnoreCase))
            {
                return "nav-link active";
            }
            return "nav-link";
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            Session.Clear();
            Session.Abandon();
            FormsAuthentication.SignOut();
            Response.Redirect("Login.aspx");
        }
    }
}

