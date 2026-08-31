using System;
using System.Collections.Generic;
using System.Data;
using System.Web;
using AttendanceApp.Utils;
using Oracle.ManagedDataAccess.Client;

namespace AttendanceApp
{
    public partial class Dashboard : System.Web.UI.Page
    {
        public bool IsAdminRole { get; set; }
        public bool IsSubUserMode { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!User.Identity.IsAuthenticated)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            string pcno = Session["PCNO"] != null ? Session["PCNO"].ToString() : "";

            // Handle direct role switch parameter
            string switchRoleParam = Request.QueryString["switchRole"];
            if (!string.IsNullOrEmpty(switchRoleParam))
            {
                if (DBHelper.SwitchUserRole(pcno, switchRoleParam, Session))
                {
                    Response.Redirect("Dashboard.aspx");
                    return;
                }
            }

            int role = Session["Role"] != null ? Convert.ToInt32(Session["Role"]) : 0;
            string roleMode = Session["RoleMode"] != null ? Session["RoleMode"].ToString() : "";
            IsAdminRole = (role == 1 || role == 4);
            IsSubUserMode = (roleMode == "SubUser" || role == 6);

            if (!IsPostBack)
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
        }

        private void CheckUnreadNotices()
        {
            try
            {
                string roleMode = Session["RoleMode"] != null ? Session["RoleMode"].ToString() : "";
                if (roleMode == "SubUser")
                {
                    phUnreadNoticeAlert.Visible = false;
                    return;
                }

                int role = Session["Role"] != null ? Convert.ToInt32(Session["Role"]) : 0;
                string pcno = Session["PCNO"] != null ? Session["PCNO"].ToString() : "";
                if (string.IsNullOrEmpty(pcno)) return;

                string query;
                DataTable dtUnread;

                if (role == 4) // Super Admin
                {
                    query = @"
                        SELECT n.Id, n.Name, n.MainCategoryId, mc.Name AS MainCategoryName
                        FROM Notices n
                        LEFT JOIN MainCategory mc ON n.MainCategoryId = mc.Id
                        WHERE n.IsHidden = 0
                          AND NOT EXISTS (
                              SELECT 1 FROM NoticeReads nr 
                              WHERE nr.NoticeId = n.Id AND nr.PCNO = :PCNO
                          )
                        ORDER BY n.UploadDate DESC";
                    dtUnread = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", pcno));
                }
                else if (role == 1) // Admin
                {
                    string mcCond = "";
                    if (roleMode == "PrimaryAdmin")
                    {
                        mcCond = "mc2.AdminPCNO = :PCNO";
                    }
                    else if (roleMode == "SecondaryAdmin")
                    {
                        mcCond = "mc2.Id IN (SELECT sg.MainCategoryId FROM CategoryShareGrant sg WHERE sg.SharedWithPCNO = :PCNO AND sg.IsActive = 1)";
                    }
                    else
                    {
                        mcCond = "(mc2.AdminPCNO = :PCNO OR mc2.Id IN (SELECT sg.MainCategoryId FROM CategoryShareGrant sg WHERE sg.SharedWithPCNO = :PCNO AND sg.IsActive = 1))";
                    }

                    query = $@"
                        SELECT n.Id, n.Name, n.MainCategoryId, mc.Name AS MainCategoryName
                        FROM Notices n
                        LEFT JOIN MainCategory mc ON n.MainCategoryId = mc.Id
                        WHERE n.IsHidden = 0
                          AND (
                              n.MainCategoryId IS NULL
                              OR n.MainCategoryId IN (
                                  SELECT mc2.Id FROM MainCategory mc2 
                                  WHERE {mcCond}
                              )
                          )
                          AND NOT EXISTS (
                              SELECT 1 FROM NoticeReads nr 
                              WHERE nr.NoticeId = n.Id AND nr.PCNO = :PCNO
                          )
                        ORDER BY n.UploadDate DESC";
                    dtUnread = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", pcno));
                }
                else // Regular user / POC
                {
                    query = @"
                        SELECT n.Id, n.Name, n.MainCategoryId, mc.Name AS MainCategoryName
                        FROM Notices n
                        LEFT JOIN MainCategory mc ON n.MainCategoryId = mc.Id
                        WHERE n.IsHidden = 0
                          AND (
                              n.MainCategoryId IS NULL
                              OR n.MainCategoryId IN (
                                  SELECT t.MainCategoryId 
                                  FROM Tiers t 
                                  JOIN UserTiers ut ON t.Id = ut.TierId 
                                  WHERE ut.PCNO = :PCNO
                              )
                          )
                          AND NOT EXISTS (
                              SELECT 1 FROM NoticeReads nr 
                              WHERE nr.NoticeId = n.Id AND nr.PCNO = :PCNO
                          )
                        ORDER BY n.UploadDate DESC";
                    dtUnread = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", pcno));
                }

                if (dtUnread != null && dtUnread.Rows.Count > 0)
                {
                    phUnreadNoticeAlert.Visible = true;
                    int count = dtUnread.Rows.Count;
                    
                    List<string> mainCatNames = new List<string>();
                    foreach (DataRow r in dtUnread.Rows)
                    {
                        string mcName = r["MainCategoryName"] != DBNull.Value && !string.IsNullOrEmpty(r["MainCategoryName"].ToString()) 
                            ? r["MainCategoryName"].ToString() 
                            : "General";
                        if (!mainCatNames.Contains(mcName))
                            mainCatNames.Add(mcName);
                    }

                    string catLabel = string.Join(", ", mainCatNames);
                    litNoticeMainCatBadge.Text = "<span class='badge badge-info' style='font-size:0.75rem; background:#3b82f6; color:#fff;'><i class='fas fa-layer-group mr-1'></i>" + HttpUtility.HtmlEncode(catLabel) + "</span>";
                    
                    string firstTitle = dtUnread.Rows[0]["Name"].ToString();
                    if (count == 1)
                    {
                        litNoticeAlertMessage.Text = string.Format("You have 1 unread announcement: <strong>\"{0}\"</strong> for <strong>{1}</strong>.", HttpUtility.HtmlEncode(firstTitle), HttpUtility.HtmlEncode(catLabel));
                    }
                    else
                    {
                        litNoticeAlertMessage.Text = string.Format("You have <strong>{0}</strong> unread announcements for <strong>{1}</strong> (Latest: \"{2}\").", count, HttpUtility.HtmlEncode(catLabel), HttpUtility.HtmlEncode(firstTitle));
                    }
                }
                else
                {
                    phUnreadNoticeAlert.Visible = false;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error checking unread notices: " + ex.Message);
            }
        }
    }
}
