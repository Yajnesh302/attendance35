using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using Oracle.ManagedDataAccess.Client;
using AttendanceApp.Utils;

namespace AttendanceApp
{
    public partial class AdminManagement : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!User.Identity.IsAuthenticated)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            int role = Convert.ToInt32(Session["Role"] ?? 0);
            if (role != 1 && role != 4)
            {
                Response.Redirect("Dashboard.aspx");
                return;
            }

            if (!IsPostBack)
            {
                // Set default tab based on role
                hfActiveTab.Value = "NonAdmins";

                // Configure tabs visibility
                if (role == 4) // Super Admin
                {
                    liTabAdmins.Visible = true;
                    liTabSuperAdmins.Visible = true;
                    liTabShareGrants.Visible = true;
                    liTabNonAdmins.Visible = true;
                }
                else // Regular Admin
                {
                    liTabAdmins.Visible = false;
                    liTabSuperAdmins.Visible = false;
                    liTabShareGrants.Visible = true;
                    liTabNonAdmins.Visible = true;
                }

                PopulateUserDivisions();
                PopulateUserTiersChecklist();
                PopulateShareCategories();
                PopulateShareGuestAdmins();
                BindAdminGrid();
            }
        }

        #region Navigation & Counts

        protected void btnTabNonAdmins_Click(object sender, EventArgs e)
        {
            hfActiveTab.Value = "NonAdmins";
            BindAdminGrid();
        }

        protected void btnTabSubUsers_Click(object sender, EventArgs e)
        {
            hfActiveTab.Value = "SubUsers";
            BindAdminGrid();
        }

        protected void btnTabAdmins_Click(object sender, EventArgs e)
        {
            hfActiveTab.Value = "Admins";
            BindAdminGrid();
        }

        protected void btnTabSuperAdmins_Click(object sender, EventArgs e)
        {
            hfActiveTab.Value = "SuperAdmins";
            BindAdminGrid();
        }

        protected void btnTabShareGrants_Click(object sender, EventArgs e)
        {
            hfActiveTab.Value = "ShareGrants";
            ResetShareForm();
            BindAdminGrid();
        }

        private void ClearCountCache()
        {
            ViewState["AdminCount"] = null;
            ViewState["NonAdminCount"] = null;
            ViewState["SubUserCount"] = null;
            ViewState["SuperAdminCount"] = null;
            ViewState["ShareGrantsCount"] = null;
        }

        public int GetSubUserCount()
        {
            if (ViewState["SubUserCount"] != null) return (int)ViewState["SubUserCount"];
            try
            {
                string q = "SELECT COUNT(DISTINCT PCNO) FROM AppUsers WHERE Role = 6 OR Role = 7";
                object res = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), q);
                int count = res != null ? Convert.ToInt32(res) : 0;
                ViewState["SubUserCount"] = count;
                return count;
            }
            catch { return 0; }
        }

        public int GetAdminCount()
        {
            if (ViewState["AdminCount"] != null) return (int)ViewState["AdminCount"];
            try
            {
                string q = @"SELECT COUNT(DISTINCT u.PCNO) FROM AppUsers u 
                             WHERE (u.Role = 1 OR u.Role = 2)
                               AND (
                                   EXISTS (SELECT 1 FROM MainCategory mc WHERE mc.AdminPCNO = u.PCNO)
                                   OR NOT EXISTS (SELECT 1 FROM CategoryShareGrant sg WHERE sg.SharedWithPCNO = u.PCNO)
                               )";
                object res = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), q);
                int count = res != null ? Convert.ToInt32(res) : 0;
                ViewState["AdminCount"] = count;
                return count;
            }
            catch { return 0; }
        }

        public int GetNonAdminCount()
        {
            if (ViewState["NonAdminCount"] != null) return (int)ViewState["NonAdminCount"];
            try
            {
                int role = Convert.ToInt32(Session["Role"] ?? 0);
                string pcno = Session["PCNO"]?.ToString() ?? "";

                string q;
                OracleParameter[] pars;
                if (role == 4)
                {
                    q = @"SELECT COUNT(DISTINCT u.PCNO) FROM AppUsers u 
                          WHERE (u.Role = 0 OR u.Role = 3 OR (u.PCNO IN (SELECT PCNO FROM UserDivisions) AND NOT EXISTS (SELECT 1 FROM AppUsers au WHERE au.PCNO = u.PCNO AND au.Role IN (1,2,4,5,6,7)))) 
                            AND (u.Role NOT IN (1, 2, 4, 5, 6, 7))";
                    pars = new OracleParameter[0];
                }
                else
                {
                    q = @"SELECT COUNT(DISTINCT u.PCNO) FROM AppUsers u
                          WHERE (u.Role = 0 OR u.Role = 3 OR (u.PCNO IN (SELECT PCNO FROM UserDivisions) AND NOT EXISTS (SELECT 1 FROM AppUsers au WHERE au.PCNO = u.PCNO AND au.Role IN (1,2,4,5,6,7))))
                            AND (u.Role NOT IN (1, 2, 4, 5, 6, 7))
                            AND (
                                u.PCNO IN (
                                    SELECT ut.PCNO FROM UserTiers ut 
                                    WHERE ut.TierId IN (
                                        SELECT t2.Id FROM Tiers t2 
                                        JOIN MainCategory mc2 ON t2.MainCategoryId = mc2.Id 
                                        WHERE mc2.AdminPCNO = :PCNO 
                                           OR mc2.Id IN (SELECT sg.MainCategoryId FROM CategoryShareGrant sg WHERE sg.SharedWithPCNO = :PCNO AND sg.IsActive = 1)
                                    )
                                )
                                OR NOT EXISTS (SELECT 1 FROM UserTiers ut2 WHERE ut2.PCNO = u.PCNO)
                            )";
                    pars = new OracleParameter[] { new OracleParameter("PCNO", pcno) };
                }
                object res = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), q, pars);
                int count = res != null ? Convert.ToInt32(res) : 0;
                ViewState["NonAdminCount"] = count;
                return count;
            }
            catch { return 0; }
        }

        public int GetSuperAdminCount()
        {
            if (ViewState["SuperAdminCount"] != null) return (int)ViewState["SuperAdminCount"];
            try
            {
                string q = "SELECT COUNT(*) FROM AppUsers WHERE Role = 4 OR Role = 5";
                object res = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), q);
                int count = res != null ? Convert.ToInt32(res) : 0;
                ViewState["SuperAdminCount"] = count;
                return count;
            }
            catch { return 0; }
        }

        public int GetShareGrantsCount()
        {
            if (ViewState["ShareGrantsCount"] != null) return (int)ViewState["ShareGrantsCount"];
            try
            {
                int role = Convert.ToInt32(Session["Role"] ?? 0);
                string pcno = Session["PCNO"]?.ToString() ?? "";
                string q;
                OracleParameter[] pars;
                if (role == 4)
                {
                    q = "SELECT COUNT(*) FROM CategoryShareGrant";
                    pars = new OracleParameter[0];
                }
                else
                {
                    q = "SELECT COUNT(*) FROM CategoryShareGrant WHERE OwnerAdminPCNO = :PCNO OR SharedWithPCNO = :PCNO";
                    pars = new OracleParameter[] { new OracleParameter("PCNO", pcno) };
                }
                object res = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), q, pars);
                int count = res != null ? Convert.ToInt32(res) : 0;
                ViewState["ShareGrantsCount"] = count;
                return count;
            }
            catch { return 0; }
        }

        #endregion

        #region Populating Lists

        private void PopulateUserDivisions()
        {
            try
            {
                cblUserDivisions.Items.Clear();
                DataTable dt = DBHelper.GetCompanyDivisionsDataTable();
                foreach (DataRow row in dt.Rows)
                {
                    string divName = row["Name"].ToString();
                    string divId = (row.Table.Columns.Contains("Id") && row["Id"] != DBNull.Value) ? row["Id"].ToString() : "";
                    string val = !string.IsNullOrEmpty(divId) ? (divId + "|" + divName) : divName;
                    cblUserDivisions.Items.Add(new System.Web.UI.WebControls.ListItem(divName, val));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error populating divisions: " + ex.Message);
            }
        }

        private void PopulateUserTiersChecklist()
        {
            try
            {
                cblUserTiers.Items.Clear();
                int role = Convert.ToInt32(Session["Role"] ?? 0);
                string pcno = Session["PCNO"]?.ToString() ?? "";

                DataTable dt = DBHelper.GetVisibleTiersDataTable(pcno, role);
                foreach (DataRow row in dt.Rows)
                {
                    cblUserTiers.Items.Add(new System.Web.UI.WebControls.ListItem(row["DisplayName"].ToString(), row["TierId"].ToString()));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error populating tiers: " + ex.Message);
            }
        }

        private void PopulateAnchorPOCs()
        {
            try
            {
                List<string> selectedValues = new List<string>();
                foreach (System.Web.UI.WebControls.ListItem item in cblAnchorPOCs.Items)
                {
                    if (item.Selected) selectedValues.Add(item.Value);
                }

                cblAnchorPOCs.Items.Clear();

                int role = Convert.ToInt32(Session["Role"] ?? 0);
                string pcno = Session["PCNO"]?.ToString() ?? "";

                string q;
                OracleParameter[] pars;
                if (role == 4)
                {
                    q = @"SELECT DISTINCT u.PCNO, u.Name 
                          FROM AppUsers u 
                          WHERE u.Role = 0 
                          ORDER BY u.Name ASC";
                    pars = new OracleParameter[0];
                }
                else
                {
                    q = @"SELECT DISTINCT u.PCNO, u.Name 
                          FROM AppUsers u 
                          WHERE u.Role = 0 
                            AND (
                                u.PCNO IN (
                                    SELECT ut.PCNO FROM UserTiers ut 
                                    WHERE ut.TierId IN (
                                        SELECT t2.Id FROM Tiers t2 
                                        JOIN MainCategory mc2 ON t2.MainCategoryId = mc2.Id 
                                        WHERE mc2.AdminPCNO = :PCNO 
                                           OR mc2.Id IN (SELECT sg.MainCategoryId FROM CategoryShareGrant sg WHERE sg.SharedWithPCNO = :PCNO AND sg.IsActive = 1)
                                    )
                                )
                                OR NOT EXISTS (SELECT 1 FROM UserTiers ut2 WHERE ut2.PCNO = u.PCNO)
                            )
                          ORDER BY u.Name ASC";
                    pars = new OracleParameter[] { new OracleParameter("PCNO", pcno) };
                }

                DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), q, pars);
                foreach (DataRow row in dt.Rows)
                {
                    string p = row["PCNO"].ToString();
                    string nm = row["Name"].ToString();
                    var item = new System.Web.UI.WebControls.ListItem(nm + " (" + p + ")", p);
                    if (selectedValues.Contains(p)) item.Selected = true;
                    cblAnchorPOCs.Items.Add(item);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error populating anchor POCs: " + ex.Message);
            }
        }

        private void PopulateShareCategories()
        {
            try
            {
                // Save current selection if any
                string prevSelectedCat = ddlShareCategory.SelectedValue;

                ddlShareCategory.Items.Clear();
                string pcno = Session["PCNO"]?.ToString() ?? "";
                int role = Convert.ToInt32(Session["Role"] ?? 0);

                // Get target guest PCNO
                string targetGuestPCNO = "";
                if (!string.IsNullOrEmpty(txtShareGuestPCNO.Text.Trim()))
                {
                    targetGuestPCNO = txtShareGuestPCNO.Text.Trim();
                }
                else if (!string.IsNullOrEmpty(ddlShareGuestAdmin.SelectedValue))
                {
                    targetGuestPCNO = ddlShareGuestAdmin.SelectedValue;
                }

                string query;
                List<OracleParameter> pars = new List<OracleParameter>();
                if (role == 4)
                {
                    query = "SELECT Id, Name FROM MainCategory";
                    if (!string.IsNullOrEmpty(targetGuestPCNO))
                    {
                        query += " WHERE AdminPCNO IS NULL OR AdminPCNO != :GuestPCNO";
                        pars.Add(new OracleParameter("GuestPCNO", targetGuestPCNO));
                    }
                    query += " ORDER BY Name ASC";
                }
                else
                {
                    query = "SELECT Id, Name FROM MainCategory WHERE AdminPCNO = :PCNO";
                    pars.Add(new OracleParameter("PCNO", pcno));
                    if (!string.IsNullOrEmpty(targetGuestPCNO))
                    {
                        query += " AND (AdminPCNO IS NULL OR AdminPCNO != :GuestPCNO)";
                        pars.Add(new OracleParameter("GuestPCNO", targetGuestPCNO));
                    }
                    query += " ORDER BY Name ASC";
                }

                DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query, pars.ToArray());
                
                foreach (DataRow row in dt.Rows)
                {
                    ddlShareCategory.Items.Add(new System.Web.UI.WebControls.ListItem(row["Name"].ToString(), row["Id"].ToString()));
                }

                if (ddlShareCategory.Items.Count > 0)
                {
                    // Try to restore previous selection if it is still valid
                    if (!string.IsNullOrEmpty(prevSelectedCat) && ddlShareCategory.Items.FindByValue(prevSelectedCat) != null)
                    {
                        ddlShareCategory.SelectedValue = prevSelectedCat;
                    }
                    else
                    {
                        ddlShareCategory.SelectedIndex = 0;
                    }
                    PopulateShareTiers(Convert.ToInt32(ddlShareCategory.SelectedValue));
                    PopulateShareGuestAdmins();
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error populating share categories: " + ex.Message);
            }
        }

        private void PopulateShareTiers(int mcId)
        {
            try
            {
                cblShareTiers.Items.Clear();
                string query = "SELECT Id, TierName || NVL2(RoleLabel, ' (#' || RoleLabel || ')', '') AS DisplayName FROM Tiers WHERE MainCategoryId = :MCId ORDER BY SortOrder ASC, TierName ASC";
                DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("MCId", mcId));
                foreach (DataRow row in dt.Rows)
                {
                    cblShareTiers.Items.Add(new System.Web.UI.WebControls.ListItem(row["DisplayName"].ToString(), row["Id"].ToString()));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error populating share tiers: " + ex.Message);
            }
        }

        protected void ddlShareCategory_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (!string.IsNullOrEmpty(ddlShareCategory.SelectedValue))
            {
                PopulateShareTiers(Convert.ToInt32(ddlShareCategory.SelectedValue));
                PopulateShareGuestAdmins();
            }
        }

        protected void ddlShareGuestAdmin_SelectedIndexChanged(object sender, EventArgs e)
        {
            txtShareGuestPCNO.Text = "";
            txtShareGuestName.Text = "";
            PopulateShareCategories();
        }

        protected void txtShareGuestPCNO_TextChanged(object sender, EventArgs e)
        {
            PopulateShareCategories();
        }

        private void PopulateShareGuestAdmins()
        {
            try
            {
                string prevSelectedGuest = ddlShareGuestAdmin.SelectedValue;

                ddlShareGuestAdmin.Items.Clear();
                string pcno = Session["PCNO"]?.ToString() ?? "";
                int role = Convert.ToInt32(Session["Role"] ?? 0);

                string categoryOwnerPCNO = "";
                string selectedCatVal = ddlShareCategory.SelectedValue;
                if (!string.IsNullOrEmpty(selectedCatVal))
                {
                    int catId = Convert.ToInt32(selectedCatVal);
                    string qOwner = "SELECT AdminPCNO FROM MainCategory WHERE Id = :Id";
                    object res = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), qOwner, new OracleParameter("Id", catId));
                    categoryOwnerPCNO = res != null ? res.ToString() : "";
                }

                string query;
                List<OracleParameter> pars = new List<OracleParameter>();
                if (role == 4)
                {
                    query = "SELECT PCNO, Name || ' (' || PCNO || ')' AS DisplayName FROM AppUsers WHERE Role = 1";
                    if (!string.IsNullOrEmpty(categoryOwnerPCNO))
                    {
                        query += " AND PCNO != :OwnerPCNO";
                        pars.Add(new OracleParameter("OwnerPCNO", categoryOwnerPCNO));
                    }
                    query += " ORDER BY Name ASC";
                }
                else
                {
                    query = "SELECT PCNO, Name || ' (' || PCNO || ')' AS DisplayName FROM AppUsers WHERE Role = 1 AND PCNO != :PCNO";
                    pars.Add(new OracleParameter("PCNO", pcno));
                    if (!string.IsNullOrEmpty(categoryOwnerPCNO))
                    {
                        query += " AND PCNO != :OwnerPCNO";
                        pars.Add(new OracleParameter("OwnerPCNO", categoryOwnerPCNO));
                    }
                    query += " ORDER BY Name ASC";
                }

                DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query, pars.ToArray());
                
                foreach (DataRow row in dt.Rows)
                {
                    ddlShareGuestAdmin.Items.Add(new System.Web.UI.WebControls.ListItem(row["DisplayName"].ToString(), row["PCNO"].ToString()));
                }

                if (ddlShareGuestAdmin.Items.Count > 0)
                {
                    if (!string.IsNullOrEmpty(prevSelectedGuest) && ddlShareGuestAdmin.Items.FindByValue(prevSelectedGuest) != null)
                    {
                        ddlShareGuestAdmin.SelectedValue = prevSelectedGuest;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error populating guest admins: " + ex.Message);
            }
        }

        #endregion

        #region Grid Binding

        private void BindAdminGrid()
        {
            try
            {
                lblGridMessage.Visible = false;
                string activeTab = string.IsNullOrEmpty(hfActiveTab.Value) ? "NonAdmins" : hfActiveTab.Value;
                int role = Convert.ToInt32(Session["Role"] ?? 0);
                string pcno = Session["PCNO"]?.ToString() ?? "";

                // Form toggles
                phUserForm.Visible = (activeTab == "NonAdmins" && (role == 1 || role == 4));
                phSubUserForm.Visible = (activeTab == "SubUsers" && (role == 1 || role == 4));
                phAdminForm.Visible = ((activeTab == "Admins" || activeTab == "SuperAdmins") && role == 4 && string.IsNullOrEmpty(txtEditAdminPCNO.Text));
                phEditAdminCategoriesForm.Visible = (activeTab == "Admins" && role == 4 && !string.IsNullOrEmpty(txtEditAdminPCNO.Text));
                phShareForm.Visible = (activeTab == "ShareGrants" && (role == 1 || role == 4));

                if (phSubUserForm.Visible)
                {
                    PopulateAnchorPOCs();
                }

                if (phShareForm.Visible)
                {
                    PopulateShareCategories();
                    PopulateShareGuestAdmins();
                }

                // Grid toggles
                gvAdminUsers.Visible = (activeTab != "ShareGrants");
                gvShareGrants.Visible = (activeTab == "ShareGrants");

                // Toggle tabs CSS
                btnTabNonAdmins.CssClass = (activeTab == "NonAdmins") ? "nav-link active" : "nav-link";
                btnTabSubUsers.CssClass = (activeTab == "SubUsers") ? "nav-link active" : "nav-link";
                btnTabAdmins.CssClass = (activeTab == "Admins") ? "nav-link active" : "nav-link";
                btnTabSuperAdmins.CssClass = (activeTab == "SuperAdmins") ? "nav-link active" : "nav-link";
                btnTabShareGrants.CssClass = (activeTab == "ShareGrants") ? "nav-link active" : "nav-link";

                if (phAdminForm.Visible)
                {
                    adminFormTitle.InnerHtml = (activeTab == "SuperAdmins") ? "<i class=\"fas fa-crown mr-2\"></i> Add Super Admin User" : "<i class=\"fas fa-user-shield mr-2\"></i> Add System Admin User";
                    btnAddAdmin.Text = (activeTab == "SuperAdmins") ? "Save Super Admin" : "Save Primary Admin";
                }

                if (activeTab == "ShareGrants")
                {
                    string query = @"
                        SELECT MIN(sg.Id) AS Id,
                               sg.OwnerAdminPCNO, 
                               sg.SharedWithPCNO, 
                               sg.MainCategoryId,
                               MAX(sg.IsActive) AS IsActive,
                               NVL(u1.Name, sg.OwnerAdminPCNO) || ' (' || sg.OwnerAdminPCNO || ')' AS OwnerName, 
                               NVL(u2.Name, sg.SharedWithPCNO) || ' (' || sg.SharedWithPCNO || ')' AS SharedWithName,
                               mc.Name AS CategoryName,
                               CASE 
                                 WHEN COUNT(CASE WHEN sg.TierId IS NULL THEN 1 END) > 0 THEN 'Entire Category'
                                 ELSE LISTAGG(t.TierName, ', ') WITHIN GROUP (ORDER BY t.SortOrder, t.TierName)
                               END AS TierName
                        FROM CategoryShareGrant sg
                        LEFT JOIN (SELECT PCNO, MAX(Name) AS Name FROM AppUsers GROUP BY PCNO) u1 ON sg.OwnerAdminPCNO = u1.PCNO
                        LEFT JOIN (SELECT PCNO, MAX(Name) AS Name FROM AppUsers GROUP BY PCNO) u2 ON sg.SharedWithPCNO = u2.PCNO
                        JOIN MainCategory mc ON sg.MainCategoryId = mc.Id
                        LEFT JOIN Tiers t ON sg.TierId = t.Id
                        WHERE :Role = 4
                           OR sg.OwnerAdminPCNO = :PCNO
                           OR sg.SharedWithPCNO = :PCNO
                        GROUP BY sg.OwnerAdminPCNO, sg.SharedWithPCNO, sg.MainCategoryId, u1.Name, u2.Name, mc.Name
                        ORDER BY mc.Name ASC, MIN(sg.Id) DESC";

                    DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query,
                        new OracleParameter("Role", role),
                        new OracleParameter("PCNO", pcno));
                        
                    gvShareGrants.DataSource = dt;
                    gvShareGrants.DataBind();
                }
                else
                {
                    string query = "";
                    OracleParameter[] pars = null;

                    if (activeTab == "NonAdmins")
                    {
                        query = @"
                            SELECT u.PCNO, u.Name, u.Role, 
                                   (SELECT LISTAGG(ud.DivisionName, ', ') WITHIN GROUP (ORDER BY ud.DivisionName ASC) FROM UserDivisions ud WHERE ud.PCNO = u.PCNO) AS AllowedDivisions,
                                   (SELECT LISTAGG(mc.Name || ' › ' || t.TierName || NVL2(t.RoleLabel, ' (#' || t.RoleLabel || ')', ''), ', ') WITHIN GROUP (ORDER BY mc.Name ASC, t.SortOrder ASC) FROM UserTiers ut JOIN Tiers t ON ut.TierId = t.Id JOIN MainCategory mc ON t.MainCategoryId = mc.Id WHERE ut.PCNO = u.PCNO) AS AllowedTiers
                            FROM AppUsers u
                            WHERE (u.Role = 0 OR u.Role = 3)
                              AND (
                                  :Role = 4
                                  OR u.PCNO IN (
                                      SELECT ut.PCNO FROM UserTiers ut 
                                      WHERE ut.TierId IN (
                                          SELECT t2.Id FROM Tiers t2 
                                          JOIN MainCategory mc2 ON t2.MainCategoryId = mc2.Id 
                                          WHERE mc2.AdminPCNO = :PCNO 
                                             OR mc2.Id IN (SELECT sg.MainCategoryId FROM CategoryShareGrant sg WHERE sg.SharedWithPCNO = :PCNO AND sg.IsActive = 1)
                                      )
                                  )
                                  OR NOT EXISTS (SELECT 1 FROM UserTiers ut2 WHERE ut2.PCNO = u.PCNO)
                              )
                            ORDER BY u.Name ASC";
                        pars = new OracleParameter[] {
                            new OracleParameter("Role", role),
                            new OracleParameter("PCNO", pcno)
                        };
                    }
                    else if (activeTab == "SubUsers")
                    {
                        query = @"
                            SELECT u.PCNO, u.Name, u.Role, 
                                   (SELECT LISTAGG(ud.DivisionName, ', ') WITHIN GROUP (ORDER BY ud.DivisionName ASC) FROM (SELECT DISTINCT PCNO, DivisionName FROM UserDivisions) ud WHERE ud.PCNO = u.PCNO) AS AllowedDivisions,
                                   (SELECT LISTAGG(mc.Name || ' › ' || t.TierName || NVL2(t.RoleLabel, ' (#' || t.RoleLabel || ')', ''), ', ') WITHIN GROUP (ORDER BY mc.Name ASC, t.SortOrder ASC) FROM (SELECT DISTINCT PCNO, TierId FROM UserTiers) ut JOIN Tiers t ON ut.TierId = t.Id JOIN MainCategory mc ON t.MainCategoryId = mc.Id WHERE ut.PCNO = u.PCNO) AS AllowedTiers,
                                   (SELECT LISTAGG(NVL(u2.Name, sa.AnchorPocPCNO) || ' (' || sa.AnchorPocPCNO || ')', ', ') WITHIN GROUP (ORDER BY u2.Name ASC)
                                    FROM SubUserAnchor sa
                                    LEFT JOIN AppUsers u2 ON sa.AnchorPocPCNO = u2.PCNO AND (u2.Role = 0 OR u2.Role = 3)
                                    WHERE sa.SubUserPCNO = u.PCNO) AS AnchorPocNames
                            FROM AppUsers u
                            WHERE (u.Role = 6 OR u.Role = 7)
                            ORDER BY u.Name ASC";
                        pars = new OracleParameter[0];
                    }
                    else if (activeTab == "Admins")
                    {
                        query = @"SELECT u.PCNO, u.Name, u.Role, NULL AS AllowedDivisions, NULL AS AllowedTiers, 
                                         (SELECT LISTAGG(mc.Name, ', ') WITHIN GROUP (ORDER BY mc.Name ASC) FROM MainCategory mc WHERE mc.AdminPCNO = u.PCNO) AS OwnedCategories 
                                  FROM AppUsers u 
                                  WHERE (u.Role = 1 OR u.Role = 2)
                                    AND (
                                        EXISTS (SELECT 1 FROM MainCategory mc WHERE mc.AdminPCNO = u.PCNO)
                                        OR NOT EXISTS (SELECT 1 FROM CategoryShareGrant sg WHERE sg.SharedWithPCNO = u.PCNO)
                                    )
                                  ORDER BY u.Name ASC";
                        pars = new OracleParameter[0];
                    }
                    else if (activeTab == "SuperAdmins")
                    {
                        query = "SELECT PCNO, Name, Role, NULL AS AllowedDivisions, NULL AS AllowedTiers FROM AppUsers WHERE Role = 4 OR Role = 5 ORDER BY Name ASC";
                        pars = new OracleParameter[0];
                    }

                    DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query, pars);
                    gvAdminUsers.DataSource = dt;
                    gvAdminUsers.DataBind();
                }
            }
            catch (Exception ex)
            {
                ShowGridMessage("Error loading grid data: " + ex.Message, false);
            }
        }

        public bool IsShareOwner(object ownerPcno)
        {
            int role = Session["Role"] != null ? Convert.ToInt32(Session["Role"]) : 0;
            if (role == 4) return true; // Super Admin can manage all share grants!
            string pcno = Session["PCNO"] != null ? Session["PCNO"].ToString() : "";
            return ownerPcno != null && ownerPcno.ToString() == pcno;
        }

        protected string GetAccessMappingHtml(object dataItem)
        {
            DataRowView rowView = dataItem as DataRowView;
            if (rowView == null) return "";
            DataRow row = rowView.Row;

            string activeTab = hfActiveTab.Value;
            int role = row.Table.Columns.Contains("Role") && row["Role"] != DBNull.Value ? Convert.ToInt32(row["Role"]) : 0;

            if (activeTab == "NonAdmins")
            {
                string divs = row.Table.Columns.Contains("AllowedDivisions") && row["AllowedDivisions"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["AllowedDivisions"].ToString()) ? row["AllowedDivisions"].ToString() : "None";
                string tiers = row.Table.Columns.Contains("AllowedTiers") && row["AllowedTiers"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["AllowedTiers"].ToString()) ? row["AllowedTiers"].ToString() : "None";
                return string.Format("Divisions: <strong>{0}</strong><br/>Tiers: <strong>{1}</strong>", HttpUtility.HtmlEncode(divs), HttpUtility.HtmlEncode(tiers));
            }
            else if (activeTab == "SubUsers")
            {
                string statusBadge = (role == 6)
                    ? "<span class='badge bg-primary text-white px-2 py-1' style='font-size:0.75rem;'><i class='fas fa-check-circle mr-1'></i>Active Sub User</span>"
                    : "<span class='badge bg-danger text-white px-2 py-1' style='font-size:0.75rem;'><i class='fas fa-times-circle mr-1'></i>Access Revoked</span>";
                
                string anchorInfo = "";
                if (row.Table.Columns.Contains("AnchorPocNames") && row["AnchorPocNames"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["AnchorPocNames"].ToString()))
                {
                    string pocNames = row["AnchorPocNames"].ToString();
                    anchorInfo = string.Format("<br/>Anchor POC(s): <strong>{0}</strong>", HttpUtility.HtmlEncode(pocNames));
                }

                string divs = row.Table.Columns.Contains("AllowedDivisions") && row["AllowedDivisions"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["AllowedDivisions"].ToString()) ? row["AllowedDivisions"].ToString() : "None";
                return string.Format("Status: {0}{1}<br/>Divisions: <strong>{2}</strong>", statusBadge, anchorInfo, HttpUtility.HtmlEncode(divs));
            }
            else if (activeTab == "Admins")
            {
                string statusBadge = (role == 1)
                    ? "<span class='badge bg-success text-white px-2 py-1' style='font-size:0.75rem;'><i class='fas fa-check-circle mr-1'></i>Active Admin</span>"
                    : "<span class='badge bg-danger text-white px-2 py-1' style='font-size:0.75rem;'><i class='fas fa-times-circle mr-1'></i>Access Revoked</span>";
                string cats = row.Table.Columns.Contains("OwnedCategories") && row["OwnedCategories"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["OwnedCategories"].ToString()) ? row["OwnedCategories"].ToString() : "None";
                return string.Format("Status: {0}<br/>Main Categories: <strong>{1}</strong>", statusBadge, HttpUtility.HtmlEncode(cats));
            }
            else
            {
                if (role == 1)
                    return "<span class='badge bg-success text-white px-2 py-1' style='font-size:0.75rem;'><i class='fas fa-check-circle mr-1'></i>Active Admin</span>";
                if (role == 4)
                    return "<span class='badge bg-indigo text-white px-2 py-1' style='font-size:0.75rem;'><i class='fas fa-crown mr-1'></i>Super Admin</span>";
                return "<span class='badge bg-danger text-white px-2 py-1' style='font-size:0.75rem;'><i class='fas fa-times-circle mr-1'></i>Access Revoked</span>";
            }
        }

        #endregion

        #region Actions & Submissions

        protected void btnAddAdmin_Click(object sender, EventArgs e)
        {
            string pcno = txtAdminPCNO.Text.Trim();
            string name = txtAdminName.Text.Trim();
            string activeTab = hfActiveTab.Value;

            if (string.IsNullOrEmpty(pcno) || string.IsNullOrEmpty(name))
            {
                ShowAdminMessage("PCNO and Name are required.", false);
                return;
            }

            int targetRole = (activeTab == "SuperAdmins") ? 4 : 1;
            int revokedRole = (targetRole == 4) ? 5 : 2;

            try
            {
                DBHelper.EnsureSchema();

                // Clean up any previously revoked state for this role
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO AND Role = :RevokedRole", 
                    new OracleParameter("PCNO", pcno),
                    new OracleParameter("RevokedRole", revokedRole));

                // Update name across any existing role records for this PCNO
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "UPDATE AppUsers SET Name = :Name WHERE PCNO = :PCNO",
                    new OracleParameter("Name", name),
                    new OracleParameter("PCNO", pcno));

                string queryUser = @"
                    MERGE INTO AppUsers t
                    USING (SELECT :PCNO as PCNO, :Name as Name, :Role as Role FROM DUAL) s
                    ON (t.PCNO = s.PCNO AND t.Role = s.Role)
                    WHEN MATCHED THEN
                      UPDATE SET t.Name = s.Name
                    WHEN NOT MATCHED THEN
                      INSERT (PCNO, Name, Role) VALUES (s.PCNO, s.Name, s.Role)";
                
                OracleParameter[] paramsUser = new OracleParameter[] {
                    new OracleParameter("PCNO", pcno),
                    new OracleParameter("Name", name),
                    new OracleParameter("Role", targetRole)
                };

                try
                {
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), queryUser, paramsUser);
                }
                catch (Exception exMerge)
                {
                    if (exMerge.Message.Contains("ORA-00001"))
                    {
                        string updateFallback = "UPDATE AppUsers SET Name = :Name WHERE PCNO = :PCNO AND Role = :Role";
                        int uCount = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), updateFallback,
                            new OracleParameter("Name", name),
                            new OracleParameter("PCNO", pcno),
                            new OracleParameter("Role", targetRole));
                        if (uCount == 0)
                        {
                            DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "INSERT INTO AppUsers (PCNO, Name, Role) VALUES (:PCNO, :Name, :Role)",
                                new OracleParameter("PCNO", pcno),
                                new OracleParameter("Name", name),
                                new OracleParameter("Role", targetRole));
                        }
                    }
                    else
                    {
                        throw;
                    }
                }

                string typeLabel = (targetRole == 4) ? "Super Admin" : "Admin";
                ShowAdminMessage($"{typeLabel} user '{name}' (PCNO: {pcno}) has been successfully created/updated.", true);
                
                txtAdminPCNO.Text = "";
                txtAdminName.Text = "";

                ClearCountCache();
                BindAdminGrid();
            }
            catch (Exception ex)
            {
                ShowAdminMessage("Error: " + ex.Message, false);
            }
        }

        protected void btnAddUser_Click(object sender, EventArgs e)
        {
            string pcno = txtUserPCNO.Text.Trim();
            string name = txtUserName.Text.Trim();
            
            if (string.IsNullOrEmpty(pcno) || string.IsNullOrEmpty(name))
            {
                ShowAdminMessage("PCNO and Name are required.", false);
                return;
            }
            
            List<string> selectedDivs = new List<string>();
            foreach (System.Web.UI.WebControls.ListItem item in cblUserDivisions.Items)
            {
                if (item.Selected) selectedDivs.Add(item.Value);
            }
            
            List<int> selectedTiers = new List<int>();
            foreach (System.Web.UI.WebControls.ListItem item in cblUserTiers.Items)
            {
                if (item.Selected) selectedTiers.Add(Convert.ToInt32(item.Value));
            }

            if (selectedDivs.Count == 0)
            {
                ShowAdminMessage("Please select at least one division for the user.", false);
                return;
            }

            if (selectedTiers.Count == 0)
            {
                ShowAdminMessage("Please select at least one tier for the user.", false);
                return;
            }
            
            try
            {
                DBHelper.EnsureSchema();

                // Clean up any previously revoked POC state
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO AND Role = 3",
                    new OracleParameter("PCNO", pcno));

                // Update name across any existing role records for this PCNO
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "UPDATE AppUsers SET Name = :Name WHERE PCNO = :PCNO",
                    new OracleParameter("Name", name),
                    new OracleParameter("PCNO", pcno));

                // 1. Save AppUsers
                string queryUser = @"
                    MERGE INTO AppUsers t
                    USING (SELECT :PCNO as PCNO, :Name as Name, 0 as Role FROM DUAL) s
                    ON (t.PCNO = s.PCNO AND t.Role = s.Role)
                    WHEN MATCHED THEN
                      UPDATE SET t.Name = s.Name
                    WHEN NOT MATCHED THEN
                      INSERT (PCNO, Name, Role) VALUES (s.PCNO, s.Name, s.Role)";
                
                try
                {
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), queryUser, 
                        new OracleParameter("PCNO", pcno),
                        new OracleParameter("Name", name));
                }
                catch (Exception exMerge)
                {
                    if (exMerge.Message.Contains("ORA-00001"))
                    {
                        string updateFallback = "UPDATE AppUsers SET Name = :Name WHERE PCNO = :PCNO AND Role = 0";
                        int uCount = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), updateFallback,
                            new OracleParameter("Name", name),
                            new OracleParameter("PCNO", pcno));
                        if (uCount == 0)
                        {
                            DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "INSERT INTO AppUsers (PCNO, Name, Role) VALUES (:PCNO, :Name, 0)",
                                new OracleParameter("PCNO", pcno),
                                new OracleParameter("Name", name));
                        }
                    }
                    else
                    {
                        throw;
                    }
                }

                // 2. Save UserDivisions
                string deleteDivs = "DELETE FROM UserDivisions WHERE PCNO = :PCNO";
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), deleteDivs, new OracleParameter("PCNO", pcno));

                string insertDiv = "INSERT INTO UserDivisions (PCNO, DivId, DivisionName) VALUES (:PCNO, :DivId, :Div)";
                foreach (string val in selectedDivs)
                {
                    string[] parts = val.Split('|');
                    string divIdStr = parts.Length > 1 ? parts[0] : "";
                    string divName = parts.Length > 1 ? parts[1] : parts[0];
                    int divIdParsed = 0;
                    object divIdObj = (!string.IsNullOrEmpty(divIdStr) && int.TryParse(divIdStr, out divIdParsed)) ? (object)divIdParsed : DBNull.Value;

                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertDiv, 
                        new OracleParameter("PCNO", pcno),
                        new OracleParameter("DivId", divIdObj),
                        new OracleParameter("Div", divName));
                }

                // 3. Save UserTiers
                string deleteTiers = "DELETE FROM UserTiers WHERE PCNO = :PCNO";
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), deleteTiers, new OracleParameter("PCNO", pcno));

                string insertTier = "INSERT INTO UserTiers (PCNO, TierId) VALUES (:PCNO, :TierId)";
                foreach (int tierId in selectedTiers)
                {
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertTier,
                        new OracleParameter("PCNO", pcno),
                        new OracleParameter("TierId", tierId));
                }

                ShowAdminMessage($"Regular user '{name}' (PCNO: {pcno}) has been successfully saved.", true);
                
                // Clear fields
                txtUserPCNO.Text = "";
                txtUserName.Text = "";
                txtUserPCNO.ReadOnly = false;
                btnAddUser.Text = "Save Regular User";
                btnCancelUserEdit.Visible = false;
                
                foreach (System.Web.UI.WebControls.ListItem item in cblUserDivisions.Items) item.Selected = false;
                foreach (System.Web.UI.WebControls.ListItem item in cblUserTiers.Items) item.Selected = false;

                userFormTitle.InnerHtml = "<i class=\"fas fa-user mr-2\"></i> Add Regular User";
                userFormHeader.Style["background"] = "linear-gradient(135deg, #0f172a 0%, #1e293b 100%)";

                ClearCountCache();
                BindAdminGrid();
            }
            catch (Exception ex)
            {
                ShowAdminMessage("Error saving regular user: " + ex.Message, false);
            }
        }

        protected void btnCancelUserEdit_Click(object sender, EventArgs e)
        {
            txtUserPCNO.Text = "";
            txtUserPCNO.ReadOnly = false;
            txtUserName.Text = "";
            foreach (System.Web.UI.WebControls.ListItem item in cblUserDivisions.Items) item.Selected = false;
            foreach (System.Web.UI.WebControls.ListItem item in cblUserTiers.Items) item.Selected = false;
            
            btnAddUser.Text = "Save Regular User";
            btnCancelUserEdit.Visible = false;

            userFormTitle.InnerHtml = "<i class=\"fas fa-user mr-2\"></i> Add Regular User";
            userFormHeader.Style["background"] = "linear-gradient(135deg, #0f172a 0%, #1e293b 100%)";
        }

        protected void btnSaveSubUser_Click(object sender, EventArgs e)
        {
            string subUserPcno = txtSubUserPCNO.Text.Trim();
            string subUserName = txtSubUserName.Text.Trim();
            List<string> selectedAnchorPcnos = new List<string>();
            foreach (System.Web.UI.WebControls.ListItem item in cblAnchorPOCs.Items)
            {
                if (item.Selected && !string.IsNullOrWhiteSpace(item.Value))
                {
                    selectedAnchorPcnos.Add(item.Value.Trim());
                }
            }

            if (string.IsNullOrEmpty(subUserPcno) || string.IsNullOrEmpty(subUserName))
            {
                ShowAdminMessage("PCNO and Name are required for the Sub User.", false);
                return;
            }

            if (selectedAnchorPcnos.Count == 0)
            {
                ShowAdminMessage("Please select at least one Anchor POC (Regular User).", false);
                return;
            }

            try
            {
                DBHelper.EnsureSchema();
                DBHelper.EnsureAppUsersRoleConstraint();

                // 1. Clean up any previously revoked sub user state for this PCNO
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO AND Role = 7",
                    new OracleParameter("PCNO", subUserPcno));

                // Update name across all roles for this PCNO
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "UPDATE AppUsers SET Name = :Name WHERE PCNO = :PCNO",
                    new OracleParameter("Name", subUserName),
                    new OracleParameter("PCNO", subUserPcno));

                // 2. Save AppUsers with Role = 6
                string queryUser = @"
                    MERGE INTO AppUsers t
                    USING (SELECT :PCNO as PCNO, :Name as Name, 6 as Role FROM DUAL) s
                    ON (t.PCNO = s.PCNO AND t.Role = s.Role)
                    WHEN MATCHED THEN
                      UPDATE SET t.Name = s.Name
                    WHEN NOT MATCHED THEN
                      INSERT (PCNO, Name, Role) VALUES (s.PCNO, s.Name, s.Role)";

                try
                {
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), queryUser,
                        new OracleParameter("PCNO", subUserPcno),
                        new OracleParameter("Name", subUserName));
                }
                catch
                {
                    string updateFallback = "UPDATE AppUsers SET Name = :Name WHERE PCNO = :PCNO AND Role = 6";
                    int uCount = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), updateFallback,
                        new OracleParameter("Name", subUserName),
                        new OracleParameter("PCNO", subUserPcno));
                    if (uCount == 0)
                    {
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "INSERT INTO AppUsers (PCNO, Name, Role) VALUES (:PCNO, :Name, 6)",
                            new OracleParameter("PCNO", subUserPcno),
                            new OracleParameter("Name", subUserName));
                    }
                }

                // 3. Save SubUserAnchor records (one row per selected Anchor POC)
                string currentUser = Session["PCNO"]?.ToString() ?? "ADMIN";
                
                // Clear existing anchors for this sub user
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), 
                    "DELETE FROM SubUserAnchor WHERE SubUserPCNO = :SubUserPCNO",
                    new OracleParameter("SubUserPCNO", subUserPcno));

                string insertAnchorSql = "INSERT INTO SubUserAnchor (SubUserPCNO, AnchorPocPCNO, CreatedBy) VALUES (:SubUserPCNO, :AnchorPocPCNO, :CreatedBy)";
                foreach (string aPcno in selectedAnchorPcnos)
                {
                    try
                    {
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertAnchorSql,
                            new OracleParameter("SubUserPCNO", subUserPcno),
                            new OracleParameter("AnchorPocPCNO", aPcno),
                            new OracleParameter("CreatedBy", currentUser));
                    }
                    catch { }
                }

                // 4. Combined copy of UserDivisions from ALL selected Anchor POCs
                string deleteDivs = "DELETE FROM UserDivisions WHERE PCNO = :PCNO";
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), deleteDivs, new OracleParameter("PCNO", subUserPcno));

                string copyDivs = @"
                    INSERT INTO UserDivisions (PCNO, DivId, DivisionName)
                    SELECT DISTINCT :NewPCNO, DivId, DivisionName
                    FROM UserDivisions
                    WHERE PCNO IN (SELECT AnchorPocPCNO FROM SubUserAnchor WHERE SubUserPCNO = :NewPCNO)";
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), copyDivs,
                    new OracleParameter("NewPCNO", subUserPcno));

                // 5. Combined copy of UserTiers from ALL selected Anchor POCs
                string deleteTiers = "DELETE FROM UserTiers WHERE PCNO = :PCNO";
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), deleteTiers, new OracleParameter("PCNO", subUserPcno));

                string copyTiers = @"
                    INSERT INTO UserTiers (PCNO, TierId)
                    SELECT DISTINCT :NewPCNO, TierId
                    FROM UserTiers
                    WHERE PCNO IN (SELECT AnchorPocPCNO FROM SubUserAnchor WHERE SubUserPCNO = :NewPCNO)";
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), copyTiers,
                    new OracleParameter("NewPCNO", subUserPcno));

                ShowAdminMessage($"Sub User '{subUserName}' (PCNO: {subUserPcno}) has been successfully saved with {selectedAnchorPcnos.Count} Anchor POC(s).", true);

                // Reset form
                txtSubUserPCNO.Text = "";
                txtSubUserPCNO.ReadOnly = false;
                txtSubUserName.Text = "";
                foreach (System.Web.UI.WebControls.ListItem item in cblAnchorPOCs.Items) item.Selected = false;
                btnCancelSubUserEdit.Visible = false;
                btnSaveSubUser.Text = "Create Sub User";
                subUserFormTitle.InnerHtml = "<i class=\"fas fa-user-edit mr-2\"></i> Add Explicit Sub User";

                ClearCountCache();
                BindAdminGrid();
            }
            catch (Exception ex)
            {
                ShowAdminMessage("Error saving sub user: " + ex.Message, false);
            }
        }

        protected void btnCancelSubUserEdit_Click(object sender, EventArgs e)
        {
            txtSubUserPCNO.Text = "";
            txtSubUserPCNO.ReadOnly = false;
            txtSubUserName.Text = "";
            foreach (System.Web.UI.WebControls.ListItem item in cblAnchorPOCs.Items) item.Selected = false;
            btnCancelSubUserEdit.Visible = false;
            btnSaveSubUser.Text = "Create Sub User";
            subUserFormTitle.InnerHtml = "<i class=\"fas fa-user-edit mr-2\"></i> Add Explicit Sub User";
        }

        protected void btnCreateShare_Click(object sender, EventArgs e)
        {
            string categoryVal = ddlShareCategory.SelectedValue;
            bool isFull = (hfShareFullCategory.Value == "true");

            string mode = hfShareGuestMode.Value; // "existing" or "new"
            string inputPcno = txtShareGuestPCNO.Text.Trim();
            string inputName = txtShareGuestName.Text.Trim();
            string guestPcno = "";

            if (mode == "new" || (!string.IsNullOrEmpty(inputPcno) && string.IsNullOrEmpty(ddlShareGuestAdmin.SelectedValue)))
            {
                if (string.IsNullOrEmpty(inputPcno))
                {
                    ShowAdminMessage("Please enter the PC Number of the new guest admin.", false);
                    return;
                }
                if (string.IsNullOrEmpty(inputName))
                {
                    ShowAdminMessage("Please enter the full name of the new guest admin.", false);
                    return;
                }
                guestPcno = inputPcno;

                try
                {
                    // Clean up any revoked admin state (Role = 2)
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO AND Role = 2",
                        new OracleParameter("PCNO", inputPcno));

                    // Update user name across all roles
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "UPDATE AppUsers SET Name = :Name WHERE PCNO = :PCNO",
                        new OracleParameter("Name", inputName),
                        new OracleParameter("PCNO", inputPcno));

                    // Create or update the admin role = 1 record
                    string queryUser = @"
                        MERGE INTO AppUsers t
                        USING (SELECT :PCNO as PCNO, :Name as Name, 1 as Role FROM DUAL) s
                        ON (t.PCNO = s.PCNO AND t.Role = s.Role)
                        WHEN MATCHED THEN
                          UPDATE SET t.Name = s.Name
                        WHEN NOT MATCHED THEN
                          INSERT (PCNO, Name, Role) VALUES (s.PCNO, s.Name, s.Role)";

                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), queryUser,
                        new OracleParameter("PCNO", inputPcno),
                        new OracleParameter("Name", inputName));

                    // Refresh dropdown lists
                    PopulateShareGuestAdmins();
                }
                catch (Exception ex)
                {
                    ShowAdminMessage("Error creating guest admin user: " + ex.Message, false);
                    return;
                }
            }
            else
            {
                guestPcno = ddlShareGuestAdmin.SelectedValue;
            }

            if (string.IsNullOrEmpty(guestPcno) || string.IsNullOrEmpty(categoryVal))
            {
                ShowAdminMessage("Please select a category and guest Admin (or enter new admin details).", false);
                return;
            }

            int categoryId = Convert.ToInt32(categoryVal);
            string ownerPcno = "";
            int role = Convert.ToInt32(Session["Role"] ?? 0);
            if (role == 4)
            {
                string qOwner = "SELECT AdminPCNO FROM MainCategory WHERE Id = :Id";
                object resOwner = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), qOwner, new OracleParameter("Id", categoryId));
                if (resOwner != null && resOwner != DBNull.Value && !string.IsNullOrEmpty(resOwner.ToString()))
                {
                    ownerPcno = resOwner.ToString();
                }
                else
                {
                    ownerPcno = Session["PCNO"]?.ToString() ?? "SUPERADMIN";
                }
            }
            else
            {
                ownerPcno = Session["PCNO"]?.ToString() ?? "";
            }

            if (string.IsNullOrEmpty(ownerPcno))
            {
                ownerPcno = Session["PCNO"]?.ToString() ?? "SUPERADMIN";
            }

            if (!string.IsNullOrEmpty(guestPcno) && guestPcno == ownerPcno)
            {
                ShowAdminMessage("This administrator is already the owner of the selected category and does not need sharing access.", false);
                return;
            }

            try
            {
                if (!string.IsNullOrEmpty(hfEditShareId.Value))
                {
                    int editId = Convert.ToInt32(hfEditShareId.Value);
                    string getExistingQuery = "SELECT OwnerAdminPCNO, SharedWithPCNO, MainCategoryId FROM CategoryShareGrant WHERE Id = :Id";
                    DataTable dtExisting = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), getExistingQuery, new OracleParameter("Id", editId));
                    if (dtExisting.Rows.Count > 0)
                    {
                        string oPcno = dtExisting.Rows[0]["OwnerAdminPCNO"].ToString();
                        string sPcno = dtExisting.Rows[0]["SharedWithPCNO"].ToString();
                        string mcId = dtExisting.Rows[0]["MainCategoryId"].ToString();
                        
                        // Delete all category share grants between this owner, guest, and main category so that the new scope overrides it completely
                        string cleanupSql = "DELETE FROM CategoryShareGrant WHERE OwnerAdminPCNO = :Owner AND SharedWithPCNO = :Guest AND MainCategoryId = :MCId";
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), cleanupSql,
                            new OracleParameter("Owner", oPcno),
                            new OracleParameter("Guest", sPcno),
                            new OracleParameter("MCId", Convert.ToInt32(mcId)));
                    }
                }

                if (isFull)
                {
                    // Check if already shared
                    string checkSql = "SELECT COUNT(*) FROM CategoryShareGrant WHERE OwnerAdminPCNO = :Owner AND SharedWithPCNO = :Guest AND MainCategoryId = :MCId AND TierId IS NULL";
                    int exists = Convert.ToInt32(DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), checkSql,
                        new OracleParameter("Owner", ownerPcno),
                        new OracleParameter("Guest", guestPcno),
                        new OracleParameter("MCId", categoryId)));

                    if (exists > 0)
                    {
                        // Enable it
                        string updateSql = "UPDATE CategoryShareGrant SET IsActive = 1 WHERE OwnerAdminPCNO = :Owner AND SharedWithPCNO = :Guest AND MainCategoryId = :MCId AND TierId IS NULL";
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), updateSql,
                            new OracleParameter("Owner", ownerPcno),
                            new OracleParameter("Guest", guestPcno),
                            new OracleParameter("MCId", categoryId));
                    }
                    else
                    {
                        string insertSql = "INSERT INTO CategoryShareGrant (OwnerAdminPCNO, SharedWithPCNO, MainCategoryId, TierId, IsActive) VALUES (:Owner, :Guest, :MCId, NULL, 1)";
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertSql,
                            new OracleParameter("Owner", ownerPcno),
                            new OracleParameter("Guest", guestPcno),
                            new OracleParameter("MCId", categoryId));
                    }
                }
                else
                {
                    // Parse tier IDs from hidden field
                    string[] tierIdsStr = hfSelectedTierIds.Value.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (string tidStr in tierIdsStr)
                    {
                        int tierId = Convert.ToInt32(tidStr);

                        string checkSql = "SELECT COUNT(*) FROM CategoryShareGrant WHERE OwnerAdminPCNO = :Owner AND SharedWithPCNO = :Guest AND MainCategoryId = :MCId AND TierId = :TierId";
                        int exists = Convert.ToInt32(DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), checkSql,
                            new OracleParameter("Owner", ownerPcno),
                            new OracleParameter("Guest", guestPcno),
                            new OracleParameter("MCId", categoryId),
                            new OracleParameter("TierId", tierId)));

                        if (exists > 0)
                        {
                            string updateSql = "UPDATE CategoryShareGrant SET IsActive = 1 WHERE OwnerAdminPCNO = :Owner AND SharedWithPCNO = :Guest AND MainCategoryId = :MCId AND TierId = :TierId";
                            DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), updateSql,
                                new OracleParameter("Owner", ownerPcno),
                                new OracleParameter("Guest", guestPcno),
                                new OracleParameter("MCId", categoryId),
                                new OracleParameter("TierId", tierId));
                        }
                        else
                        {
                            string insertSql = "INSERT INTO CategoryShareGrant (OwnerAdminPCNO, SharedWithPCNO, MainCategoryId, TierId, IsActive) VALUES (:Owner, :Guest, :MCId, :TierId, 1)";
                            DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertSql,
                                new OracleParameter("Owner", ownerPcno),
                                new OracleParameter("Guest", guestPcno),
                                new OracleParameter("MCId", categoryId),
                                new OracleParameter("TierId", tierId));
                        }
                    }
                }

                ShowAdminMessage(!string.IsNullOrEmpty(hfEditShareId.Value) ? "Category access has been updated successfully." : "Category access has been shared successfully.", true);
                ResetShareForm();
                BindAdminGrid();
            }
            catch (Exception ex)
            {
                ShowAdminMessage("Error sharing/updating category: " + ex.Message, false);
            }
        }

        protected void gvAdminUsers_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            string activeTab = hfActiveTab.Value;
            if (e.CommandName == "RevokeAdmin")
            {
                string targetPcno = e.CommandArgument.ToString();
                string currentPcno = Session["PCNO"]?.ToString() ?? "";
                int currentRole = Convert.ToInt32(Session["Role"] ?? 0);

                // Prevent revoking the role that corresponds to the active session
                if (targetPcno == currentPcno)
                {
                    if (activeTab == "SuperAdmins" && currentRole == 4)
                    {
                        ShowGridMessage("You cannot revoke your own Super Administrator access while logged in as Super Admin.", false);
                        return;
                    }
                    else if (activeTab == "Admins" && currentRole == 1)
                    {
                        ShowGridMessage("You cannot revoke your own Administrator access while logged in as Admin.", false);
                        return;
                    }
                }

                try
                {
                    if (activeTab == "Admins")
                    {
                        string clearOwnershipSql = "UPDATE MainCategory SET AdminPCNO = NULL WHERE AdminPCNO = :PCNO";
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), clearOwnershipSql, new OracleParameter("PCNO", targetPcno));

                        string query = "UPDATE AppUsers SET Role = 2 WHERE PCNO = :PCNO AND Role = 1";
                        int count = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", targetPcno));
                        if (count == 0)
                        {
                            string insertRevoked = "INSERT INTO AppUsers (PCNO, Name, Role) VALUES (:PCNO, (SELECT NVL(MIN(Name), :PCNO2) FROM AppUsers WHERE PCNO = :PCNO3), 2)";
                            try { DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertRevoked, new OracleParameter("PCNO", targetPcno), new OracleParameter("PCNO2", targetPcno), new OracleParameter("PCNO3", targetPcno)); } catch { }
                        }
                        ShowGridMessage($"System Administrator access for PCNO {targetPcno} has been successfully revoked.", true);
                    }
                    else if (activeTab == "NonAdmins")
                    {
                        string query = "UPDATE AppUsers SET Role = 3 WHERE PCNO = :PCNO AND Role = 0";
                        int count = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", targetPcno));
                        if (count == 0)
                        {
                            string insertRevoked = "INSERT INTO AppUsers (PCNO, Name, Role) VALUES (:PCNO, (SELECT NVL(MIN(Name), :PCNO2) FROM AppUsers WHERE PCNO = :PCNO3), 3)";
                            try { DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertRevoked, new OracleParameter("PCNO", targetPcno), new OracleParameter("PCNO2", targetPcno), new OracleParameter("PCNO3", targetPcno)); } catch { }
                        }
                        ShowGridMessage($"Regular User (POC) access for PCNO {targetPcno} has been successfully revoked.", true);
                    }
                    else if (activeTab == "SubUsers")
                    {
                        string query = "UPDATE AppUsers SET Role = 7 WHERE PCNO = :PCNO AND Role = 6";
                        int count = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", targetPcno));
                        if (count == 0)
                        {
                            string insertRevoked = "INSERT INTO AppUsers (PCNO, Name, Role) VALUES (:PCNO, (SELECT NVL(MIN(Name), :PCNO2) FROM AppUsers WHERE PCNO = :PCNO3), 7)";
                            try { DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertRevoked, new OracleParameter("PCNO", targetPcno), new OracleParameter("PCNO2", targetPcno), new OracleParameter("PCNO3", targetPcno)); } catch { }
                        }
                        ShowGridMessage($"Sub User access for PCNO {targetPcno} has been successfully revoked.", true);
                    }
                    else if (activeTab == "SuperAdmins")
                    {
                        string query = "UPDATE AppUsers SET Role = 5 WHERE PCNO = :PCNO AND Role = 4";
                        int count = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", targetPcno));
                        if (count == 0)
                        {
                            string insertRevoked = "INSERT INTO AppUsers (PCNO, Name, Role) VALUES (:PCNO, (SELECT NVL(MIN(Name), :PCNO2) FROM AppUsers WHERE PCNO = :PCNO3), 5)";
                            try { DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertRevoked, new OracleParameter("PCNO", targetPcno), new OracleParameter("PCNO2", targetPcno), new OracleParameter("PCNO3", targetPcno)); } catch { }
                        }
                        ShowGridMessage($"Super Administrator access for PCNO {targetPcno} has been successfully revoked.", true);
                    }
                    ClearCountCache();
                    BindAdminGrid();
                }
                catch (Exception ex)
                {
                    ShowGridMessage("Error revoking access: " + ex.Message, false);
                }
            }
            else if (e.CommandName == "GrantAdmin")
            {
                string targetPcno = e.CommandArgument.ToString();
                try
                {
                    if (activeTab == "Admins")
                    {
                        string query = "UPDATE AppUsers SET Role = 1 WHERE PCNO = :PCNO AND Role = 2";
                        int count = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", targetPcno));
                        if (count == 0)
                        {
                            string mergeAdmin = @"
                                MERGE INTO AppUsers t
                                USING (SELECT :PCNO as PCNO, (SELECT NVL(MIN(Name), :PCNO2) FROM AppUsers WHERE PCNO = :PCNO3) as Name, 1 as Role FROM DUAL) s
                                ON (t.PCNO = s.PCNO AND t.Role = s.Role)
                                WHEN NOT MATCHED THEN
                                    INSERT (PCNO, Name, Role) VALUES (s.PCNO, s.Name, s.Role)";
                            DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), mergeAdmin,
                                new OracleParameter("PCNO", targetPcno),
                                new OracleParameter("PCNO2", targetPcno),
                                new OracleParameter("PCNO3", targetPcno));
                        }
                        ShowGridMessage($"System Administrator access for PCNO {targetPcno} has been successfully restored.", true);
                    }
                    else if (activeTab == "NonAdmins")
                    {
                        string query = "UPDATE AppUsers SET Role = 0 WHERE PCNO = :PCNO AND Role = 3";
                        int count = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", targetPcno));
                        if (count == 0)
                        {
                            string mergePoc = @"
                                MERGE INTO AppUsers t
                                USING (SELECT :PCNO as PCNO, (SELECT NVL(MIN(Name), :PCNO2) FROM AppUsers WHERE PCNO = :PCNO3) as Name, 0 as Role FROM DUAL) s
                                ON (t.PCNO = s.PCNO AND t.Role = s.Role)
                                WHEN NOT MATCHED THEN
                                    INSERT (PCNO, Name, Role) VALUES (s.PCNO, s.Name, s.Role)";
                            DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), mergePoc,
                                new OracleParameter("PCNO", targetPcno),
                                new OracleParameter("PCNO2", targetPcno),
                                new OracleParameter("PCNO3", targetPcno));
                        }
                        ShowGridMessage($"Regular User (POC) access for PCNO {targetPcno} has been successfully restored.", true);
                    }
                    else if (activeTab == "SubUsers")
                    {
                        string query = "UPDATE AppUsers SET Role = 6 WHERE PCNO = :PCNO AND Role = 7";
                        int count = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", targetPcno));
                        if (count == 0)
                        {
                            string mergeSub = @"
                                MERGE INTO AppUsers t
                                USING (SELECT :PCNO as PCNO, (SELECT NVL(MIN(Name), :PCNO2) FROM AppUsers WHERE PCNO = :PCNO3) as Name, 6 as Role FROM DUAL) s
                                ON (t.PCNO = s.PCNO AND t.Role = s.Role)
                                WHEN NOT MATCHED THEN
                                    INSERT (PCNO, Name, Role) VALUES (s.PCNO, s.Name, s.Role)";
                            DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), mergeSub,
                                new OracleParameter("PCNO", targetPcno),
                                new OracleParameter("PCNO2", targetPcno),
                                new OracleParameter("PCNO3", targetPcno));
                        }
                        ShowGridMessage($"Sub User access for PCNO {targetPcno} has been successfully restored.", true);
                    }
                    else if (activeTab == "SuperAdmins")
                    {
                        string query = "UPDATE AppUsers SET Role = 4 WHERE PCNO = :PCNO AND Role = 5";
                        int count = DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", targetPcno));
                        if (count == 0)
                        {
                            string mergeSuper = @"
                                MERGE INTO AppUsers t
                                USING (SELECT :PCNO as PCNO, (SELECT NVL(MIN(Name), :PCNO2) FROM AppUsers WHERE PCNO = :PCNO3) as Name, 4 as Role FROM DUAL) s
                                ON (t.PCNO = s.PCNO AND t.Role = s.Role)
                                WHEN NOT MATCHED THEN
                                    INSERT (PCNO, Name, Role) VALUES (s.PCNO, s.Name, s.Role)";
                            DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), mergeSuper,
                                new OracleParameter("PCNO", targetPcno),
                                new OracleParameter("PCNO2", targetPcno),
                                new OracleParameter("PCNO3", targetPcno));
                        }
                        ShowGridMessage($"Super Administrator access for PCNO {targetPcno} has been successfully restored.", true);
                    }
                    ClearCountCache();
                    BindAdminGrid();
                }
                catch (Exception ex)
                {
                    ShowGridMessage("Error restoring access: " + ex.Message, false);
                }
            }
            else if (e.CommandName == "DeleteUser")
            {
                string targetPcno = e.CommandArgument.ToString();
                string currentPcno = Session["PCNO"]?.ToString() ?? "";
                int currentRole = Convert.ToInt32(Session["Role"] ?? 0);

                if (targetPcno == currentPcno)
                {
                    if (activeTab == "SuperAdmins" && currentRole == 4)
                    {
                        ShowGridMessage("You cannot delete your own Super Administrator account while logged in as Super Admin.", false);
                        return;
                    }
                    else if (activeTab == "Admins" && currentRole == 1)
                    {
                        ShowGridMessage("You cannot delete your own Administrator account while logged in as Admin.", false);
                        return;
                    }
                }

                try
                {
                    if (activeTab == "NonAdmins")
                    {
                        // Delete ONLY POC mappings and POC role
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM UserDivisions WHERE PCNO = :PCNO", new OracleParameter("PCNO", targetPcno));
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM UserTiers WHERE PCNO = :PCNO", new OracleParameter("PCNO", targetPcno));
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO AND (Role = 0 OR Role = 3)", new OracleParameter("PCNO", targetPcno));
                        ShowGridMessage($"Regular User (POC) record for PCNO {targetPcno} has been permanently deleted from the registry.", true);
                    }
                    else if (activeTab == "SubUsers")
                    {
                        // Delete ONLY Sub User mappings and Sub User role
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM SubUserAnchor WHERE SubUserPCNO = :PCNO", new OracleParameter("PCNO", targetPcno));
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM UserDivisions WHERE PCNO = :PCNO", new OracleParameter("PCNO", targetPcno));
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM UserTiers WHERE PCNO = :PCNO", new OracleParameter("PCNO", targetPcno));
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO AND (Role = 6 OR Role = 7)", new OracleParameter("PCNO", targetPcno));
                        ShowGridMessage($"Sub User record for PCNO {targetPcno} has been permanently deleted from the registry.", true);
                    }
                    else if (activeTab == "Admins")
                    {
                        // Delete ONLY Admin category ownership/shares and Admin role
                        string clearOwnershipSql = "UPDATE MainCategory SET AdminPCNO = NULL WHERE AdminPCNO = :PCNO";
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), clearOwnershipSql, new OracleParameter("PCNO", targetPcno));
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM CategoryShareGrant WHERE SharedWithPCNO = :PCNO OR OwnerAdminPCNO = :PCNO", new OracleParameter("PCNO", targetPcno));
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO AND (Role = 1 OR Role = 2)", new OracleParameter("PCNO", targetPcno));
                        ShowGridMessage($"System Administrator record for PCNO {targetPcno} has been permanently deleted from the registry.", true);
                    }
                    else if (activeTab == "SuperAdmins")
                    {
                        // Delete ONLY Super Admin role
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO AND (Role = 4 OR Role = 5)", new OracleParameter("PCNO", targetPcno));
                        ShowGridMessage($"Super Administrator record for PCNO {targetPcno} has been permanently deleted from the registry.", true);
                    }

                    ClearCountCache();
                    BindAdminGrid();
                }
                catch (Exception ex)
                {
                    ShowGridMessage("Error deleting user: " + ex.Message, false);
                }
            }
            else if (e.CommandName == "EditUserDivs")
            {
                string targetPcno = e.CommandArgument.ToString();
                try
                {
                    string queryUser = "SELECT PCNO, Name FROM AppUsers WHERE PCNO = :PCNO";
                    DataTable dtUser = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), queryUser, new OracleParameter("PCNO", targetPcno));
                    if (dtUser.Rows.Count > 0)
                    {
                        txtUserPCNO.Text = dtUser.Rows[0]["PCNO"].ToString();
                        txtUserPCNO.ReadOnly = true;
                        txtUserName.Text = dtUser.Rows[0]["Name"].ToString();
                        
                        foreach (System.Web.UI.WebControls.ListItem item in cblUserDivisions.Items) item.Selected = false;
                        foreach (System.Web.UI.WebControls.ListItem item in cblUserTiers.Items) item.Selected = false;
                        
                        // Set divisions
                        string queryDivs = "SELECT DivId, DivisionName FROM UserDivisions WHERE PCNO = :PCNO";
                        DataTable dtDivs = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), queryDivs, new OracleParameter("PCNO", targetPcno));
                        List<string> userDivNames = new List<string>();
                        List<string> userDivIds = new List<string>();
                        foreach (DataRow row in dtDivs.Rows)
                        {
                            userDivNames.Add(row["DivisionName"].ToString());
                            if (row["DivId"] != DBNull.Value) userDivIds.Add(row["DivId"].ToString());
                        }

                        foreach (System.Web.UI.WebControls.ListItem item in cblUserDivisions.Items)
                        {
                            string[] parts = item.Value.Split('|');
                            string idStr = parts.Length > 1 ? parts[0] : "";
                            string nameStr = parts.Length > 1 ? parts[1] : parts[0];
                            if ((!string.IsNullOrEmpty(idStr) && userDivIds.Contains(idStr)) || userDivNames.Contains(nameStr))
                            {
                                item.Selected = true;
                            }
                        }

                        // Set tiers
                        string queryTiers = "SELECT TierId FROM UserTiers WHERE PCNO = :PCNO";
                        DataTable dtTiers = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), queryTiers, new OracleParameter("PCNO", targetPcno));
                        foreach (DataRow row in dtTiers.Rows)
                        {
                            string tId = row["TierId"].ToString();
                            System.Web.UI.WebControls.ListItem item = cblUserTiers.Items.FindByValue(tId);
                            if (item != null) item.Selected = true;
                        }
                        
                        btnAddUser.Text = "Update Regular User";
                        btnCancelUserEdit.Visible = true;
                        
                        userFormTitle.InnerHtml = "<i class=\"fas fa-user-edit mr-2\"></i> Edit Regular User";
                        userFormHeader.Style["background"] = "linear-gradient(135deg, #4f46e5 0%, #3730a3 100%)";

                        ShowAdminMessage($"Editing details for user '{txtUserName.Text}'.", true);
                    }
                }
                catch (Exception ex)
                {
                    ShowGridMessage("Error loading user details: " + ex.Message, false);
                }
            }
            else if (e.CommandName == "EditSubUser")
            {
                string targetPcno = e.CommandArgument.ToString();
                try
                {
                    string queryUser = "SELECT PCNO, Name FROM AppUsers WHERE PCNO = :PCNO";
                    DataTable dtUser = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), queryUser, new OracleParameter("PCNO", targetPcno));
                    if (dtUser.Rows.Count > 0)
                    {
                        txtSubUserPCNO.Text = dtUser.Rows[0]["PCNO"].ToString();
                        txtSubUserPCNO.ReadOnly = true;
                        txtSubUserName.Text = dtUser.Rows[0]["Name"].ToString();

                        // Always refresh anchor POC list
                        PopulateAnchorPOCs();

                        // Clear selections
                        foreach (System.Web.UI.WebControls.ListItem item in cblAnchorPOCs.Items)
                        {
                            item.Selected = false;
                        }

                        // Query all currently assigned anchor POCs for this sub user
                        string qAnchors = "SELECT AnchorPocPCNO FROM SubUserAnchor WHERE SubUserPCNO = :PCNO";
                        DataTable dtAnchors = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), qAnchors, new OracleParameter("PCNO", targetPcno));
                        foreach (DataRow aRow in dtAnchors.Rows)
                        {
                            string aPcno = aRow["AnchorPocPCNO"].ToString();
                            System.Web.UI.WebControls.ListItem item = cblAnchorPOCs.Items.FindByValue(aPcno);
                            if (item != null)
                            {
                                item.Selected = true;
                            }
                        }

                        btnSaveSubUser.Text = "Update Sub User";
                        btnCancelSubUserEdit.Visible = true;
                        subUserFormTitle.InnerHtml = "<i class=\"fas fa-user-edit mr-2\"></i> Edit Sub User";

                        ClientScript.RegisterStartupScript(this.GetType(), "initAnchorScopePreview", "setTimeout(function() { onAnchorPocCheckboxChange(); }, 150);", true);

                        ShowAdminMessage($"Editing details for Sub User '{txtSubUserName.Text}'.", true);
                    }
                }
                catch (Exception ex)
                {
                    ShowGridMessage("Error loading Sub User details: " + ex.Message, false);
                }
            }
            else if (e.CommandName == "EditAdminCategory")
            {
                string targetPcno = e.CommandArgument.ToString();
                try
                {
                    string queryUser = "SELECT PCNO, Name FROM AppUsers WHERE PCNO = :PCNO";
                    DataTable dtUser = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), queryUser, new OracleParameter("PCNO", targetPcno));
                    if (dtUser.Rows.Count > 0)
                    {
                        txtEditAdminPCNO.Text = dtUser.Rows[0]["PCNO"].ToString();
                        txtEditAdminName.Text = dtUser.Rows[0]["Name"].ToString();

                        ddlEditAdminCategory.Items.Clear();
                        ddlEditAdminCategory.Items.Add(new System.Web.UI.WebControls.ListItem("None (No Category)", ""));

                        string queryCats = @"
                            SELECT Id, Name 
                            FROM MainCategory 
                            WHERE AdminPCNO IS NULL 
                               OR AdminPCNO = :PCNO 
                            ORDER BY Name ASC";
                        DataTable dtCats = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), queryCats, new OracleParameter("PCNO", targetPcno));
                        foreach (DataRow row in dtCats.Rows)
                        {
                            ddlEditAdminCategory.Items.Add(new System.Web.UI.WebControls.ListItem(row["Name"].ToString(), row["Id"].ToString()));
                        }

                        // Set the selected value to the currently owned category (if any)
                        string queryOwned = "SELECT Id FROM MainCategory WHERE AdminPCNO = :PCNO AND ROWNUM <= 1";
                        object ownedIdVal = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), queryOwned, new OracleParameter("PCNO", targetPcno));
                        if (ownedIdVal != null && ownedIdVal != DBNull.Value)
                        {
                            string mcId = ownedIdVal.ToString();
                            System.Web.UI.WebControls.ListItem item = ddlEditAdminCategory.Items.FindByValue(mcId);
                            if (item != null)
                            {
                                ddlEditAdminCategory.SelectedValue = mcId;
                            }
                        }
                        else
                        {
                            ddlEditAdminCategory.SelectedValue = "";
                        }

                        BindAdminGrid();
                        ShowAdminMessage($"Loaded main category access details for admin '{txtEditAdminName.Text}'.", true);
                    }
                }
                catch (Exception ex)
                {
                    ShowGridMessage("Error loading admin category details: " + ex.Message, false);
                }
            }
        }

        private void CleanUpOrphanedAdmin(string guestPcno)
        {
            try
            {
                if (string.IsNullOrEmpty(guestPcno)) return;

                // Check if they own any categories
                string checkOwn = "SELECT COUNT(*) FROM MainCategory WHERE AdminPCNO = :PCNO";
                int ownCount = Convert.ToInt32(DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), checkOwn, new OracleParameter("PCNO", guestPcno)));

                // Check if they have other active share grants
                string checkGrants = "SELECT COUNT(*) FROM CategoryShareGrant WHERE SharedWithPCNO = :PCNO AND IsActive = 1";
                int grantsCount = Convert.ToInt32(DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), checkGrants, new OracleParameter("PCNO", guestPcno)));

                // Check if they have an explicit Admin role in AppUsers
                string checkAdminRole = "SELECT COUNT(*) FROM AppUsers WHERE PCNO = :PCNO AND (Role = 1 OR Role = 2)";
                int adminRoleCount = Convert.ToInt32(DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), checkAdminRole, new OracleParameter("PCNO", guestPcno)));

                if (ownCount == 0 && grantsCount == 0 && adminRoleCount > 0)
                {
                    // Check if they have other roles (Super Admin, POC Role 0/3, SubUser Role 6/7) or UserDivisions
                    string checkOtherRoles = "SELECT COUNT(*) FROM AppUsers WHERE PCNO = :PCNO AND Role NOT IN (1, 2)";
                    int otherRolesCount = Convert.ToInt32(DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), checkOtherRoles, new OracleParameter("PCNO", guestPcno)));

                    string checkDivs = "SELECT COUNT(*) FROM UserDivisions WHERE PCNO = :PCNO";
                    int divCount = Convert.ToInt32(DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), checkDivs, new OracleParameter("PCNO", guestPcno)));

                    // Delete the Admin role row (1 or 2) created for guest category sharing
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO AND (Role = 1 OR Role = 2)", new OracleParameter("PCNO", guestPcno));

                    // Only if they have NO other roles and NO divisions, clean up orphan entirely
                    if (otherRolesCount == 0 && divCount == 0)
                    {
                        DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "DELETE FROM AppUsers WHERE PCNO = :PCNO", new OracleParameter("PCNO", guestPcno));
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error cleaning up orphaned admin: " + ex.Message);
            }
        }

        private void EnsureGuestAdminUser(string guestPcno, string guestName = null)
        {
            try
            {
                if (string.IsNullOrEmpty(guestPcno)) return;

                string queryUser = @"
                    MERGE INTO AppUsers t
                    USING (SELECT :PCNO as PCNO, NVL(:Name, (SELECT MIN(Name) FROM AppUsers WHERE PCNO = :PCNO2)) as Name, 1 as Role FROM DUAL) s
                    ON (t.PCNO = s.PCNO AND t.Role = s.Role)
                    WHEN MATCHED THEN
                      UPDATE SET t.Name = NVL(s.Name, t.Name)
                    WHEN NOT MATCHED THEN
                      INSERT (PCNO, Name, Role) VALUES (s.PCNO, NVL(s.Name, s.PCNO), s.Role)";

                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), queryUser,
                    new OracleParameter("PCNO", guestPcno),
                    new OracleParameter("Name", (object)guestName ?? DBNull.Value),
                    new OracleParameter("PCNO2", guestPcno));
            }
            catch { }
        }

        protected void btnCancelShareEdit_Click(object sender, EventArgs e)
        {
            ResetShareForm();
        }

        private void ResetShareForm()
        {
            hfEditShareId.Value = "";
            hfShareGuestMode.Value = "existing";
            txtShareGuestPCNO.Text = "";
            txtShareGuestPCNO.ReadOnly = false;
            txtShareGuestName.Text = "";

            PopulateShareCategories();

            hfShareFullCategory.Value = "true";
            hfSelectedTierIds.Value = "";
            btnCreateShare.Text = "Grant Category Access";
            btnCancelShareEdit.Visible = false;
        }

        protected void gvShareGrants_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            string arg = e.CommandArgument != null ? e.CommandArgument.ToString() : "";
            string[] parts = arg.Split('|');
            string ownerPcno = parts.Length > 0 ? parts[0] : "";
            string guestPcno = parts.Length > 1 ? parts[1] : "";
            string mcIdStr = parts.Length > 2 ? parts[2] : "";
            int parsedId = 0;
            int id = parts.Length > 3 ? Convert.ToInt32(parts[3]) : (int.TryParse(arg, out parsedId) ? parsedId : 0);

            if (e.CommandName == "ToggleShare")
            {
                try
                {
                    int categoryId = Convert.ToInt32(mcIdStr);
                    string checkStatusSql = "SELECT MAX(IsActive) FROM CategoryShareGrant WHERE OwnerAdminPCNO = :Owner AND SharedWithPCNO = :Guest AND MainCategoryId = :MCId";
                    object resStatus = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), checkStatusSql,
                        new OracleParameter("Owner", ownerPcno),
                        new OracleParameter("Guest", guestPcno),
                        new OracleParameter("MCId", categoryId));
                    int currentStatus = (resStatus != null && resStatus != DBNull.Value) ? Convert.ToInt32(resStatus) : 0;
                    int newStatus = (currentStatus == 1) ? 0 : 1;

                    string updateSql = "UPDATE CategoryShareGrant SET IsActive = :NewStatus WHERE OwnerAdminPCNO = :Owner AND SharedWithPCNO = :Guest AND MainCategoryId = :MCId";
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), updateSql,
                        new OracleParameter("NewStatus", newStatus),
                        new OracleParameter("Owner", ownerPcno),
                        new OracleParameter("Guest", guestPcno),
                        new OracleParameter("MCId", categoryId));

                    if (newStatus == 0)
                    {
                        CleanUpOrphanedAdmin(guestPcno);
                    }
                    else
                    {
                        EnsureGuestAdminUser(guestPcno);
                    }

                    ClearCountCache();
                    ShowGridMessage("Category sharing grant status updated.", true);
                    BindAdminGrid();
                }
                catch (Exception ex)
                {
                    ShowGridMessage("Error toggling share grant: " + ex.Message, false);
                }
            }
            else if (e.CommandName == "DeleteShare")
            {
                try
                {
                    int categoryId = Convert.ToInt32(mcIdStr);

                    string deleteSql = "DELETE FROM CategoryShareGrant WHERE OwnerAdminPCNO = :Owner AND SharedWithPCNO = :Guest AND MainCategoryId = :MCId";
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), deleteSql,
                        new OracleParameter("Owner", ownerPcno),
                        new OracleParameter("Guest", guestPcno),
                        new OracleParameter("MCId", categoryId));

                    if (!string.IsNullOrEmpty(guestPcno))
                    {
                        CleanUpOrphanedAdmin(guestPcno);
                    }

                    ClearCountCache();
                    ShowGridMessage("Category sharing grant deleted successfully.", true);
                    BindAdminGrid();
                }
                catch (Exception ex)
                {
                    ShowGridMessage("Error deleting share grant: " + ex.Message, false);
                }
            }
            else if (e.CommandName == "EditShare")
            {
                try
                {
                    int categoryId = Convert.ToInt32(mcIdStr);

                    // Store representative Edit ID
                    hfEditShareId.Value = id.ToString();
                    hfShareGuestMode.Value = "new";

                    // Find Name from AppUsers
                    string nameQuery = "SELECT Name FROM AppUsers WHERE PCNO = :PCNO";
                    object nameVal = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), nameQuery, new OracleParameter("PCNO", guestPcno));

                    txtShareGuestPCNO.Text = guestPcno;
                    txtShareGuestPCNO.ReadOnly = true;
                    txtShareGuestName.Text = nameVal != null ? nameVal.ToString() : "";

                    PopulateShareCategories();

                    System.Web.UI.WebControls.ListItem mcItem = ddlShareCategory.Items.FindByValue(mcIdStr);
                    if (mcItem != null)
                    {
                        ddlShareCategory.SelectedValue = mcIdStr;
                    }

                    // Populate tiers for this category
                    PopulateShareTiers(categoryId);

                    // Query all tier grants for this group
                    string grantsSql = "SELECT TierId FROM CategoryShareGrant WHERE OwnerAdminPCNO = :Owner AND SharedWithPCNO = :Guest AND MainCategoryId = :MCId";
                    DataTable dtGrants = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), grantsSql,
                        new OracleParameter("Owner", ownerPcno),
                        new OracleParameter("Guest", guestPcno),
                        new OracleParameter("MCId", categoryId));

                    bool isFullCategory = false;
                    List<string> selectedTiers = new List<string>();

                    foreach (DataRow row in dtGrants.Rows)
                    {
                        if (row["TierId"] == DBNull.Value)
                        {
                            isFullCategory = true;
                            break;
                        }
                        else
                        {
                            selectedTiers.Add(row["TierId"].ToString());
                        }
                    }

                    if (isFullCategory)
                    {
                        hfShareFullCategory.Value = "true";
                        hfSelectedTierIds.Value = "";
                        foreach (System.Web.UI.WebControls.ListItem item in cblShareTiers.Items)
                        {
                            item.Selected = false;
                        }
                    }
                    else
                    {
                        hfShareFullCategory.Value = "false";
                        hfSelectedTierIds.Value = string.Join(",", selectedTiers);
                        foreach (System.Web.UI.WebControls.ListItem item in cblShareTiers.Items)
                        {
                            item.Selected = selectedTiers.Contains(item.Value);
                        }
                    }

                    btnCreateShare.Text = "Update Category Access";
                    btnCancelShareEdit.Visible = true;

                    ShowGridMessage($"Loaded access settings for guest Admin '{txtShareGuestName.Text}'. You can now adjust their scope and save changes.", true);
                }
                catch (Exception ex)
                {
                    ShowGridMessage("Error loading share grant details: " + ex.Message, false);
                }
            }
        }

        #endregion

        protected void btnCancelAdminEdit_Click(object sender, EventArgs e)
        {
            txtEditAdminPCNO.Text = "";
            txtEditAdminName.Text = "";
            ddlEditAdminCategory.Items.Clear();
            BindAdminGrid();
        }

        protected void btnSaveAdminCategories_Click(object sender, EventArgs e)
        {
            int role = Convert.ToInt32(Session["Role"] ?? 0);
            if (role != 4)
            {
                ShowAdminMessage("Only Super Admins can edit Main Category access for administrators.", false);
                return;
            }

            string adminPcno = txtEditAdminPCNO.Text.Trim();
            if (string.IsNullOrEmpty(adminPcno))
            {
                ShowAdminMessage("No administrator selected for editing.", false);
                return;
            }

            string selectedMcIdStr = ddlEditAdminCategory.SelectedValue;

            try
            {
                // 1. Unassign all categories currently owned by this admin
                string unassignSql = "UPDATE MainCategory SET AdminPCNO = NULL WHERE AdminPCNO = :PCNO";
                DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), unassignSql, new OracleParameter("PCNO", adminPcno));

                // 2. Assign the admin to the newly selected category (if not None)
                if (!string.IsNullOrEmpty(selectedMcIdStr))
                {
                    int mcId = Convert.ToInt32(selectedMcIdStr);
                    string assignSql = "UPDATE MainCategory SET AdminPCNO = :PCNO WHERE Id = :MCId";
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), assignSql,
                        new OracleParameter("PCNO", adminPcno),
                        new OracleParameter("MCId", mcId));
                }

                ShowAdminMessage("Administrator Main Category access successfully updated.", true);
                
                // Clear and refresh
                txtEditAdminPCNO.Text = "";
                txtEditAdminName.Text = "";
                ddlEditAdminCategory.Items.Clear();
                
                BindAdminGrid();
            }
            catch (Exception ex)
            {
                ShowAdminMessage("Error saving administrator category: " + ex.Message, false);
            }
        }

        private void ShowAdminMessage(string msg, bool success)
        {
            string type = success ? "success" : "error";
            string cleanMessage = msg.Replace("'", "\\'").Replace("\r", "").Replace("\n", " ");
            string script = string.Format("showToast('{0}', '{1}');", cleanMessage, type);
            ClientScript.RegisterStartupScript(this.GetType(), "toast_" + Guid.NewGuid().ToString("N"), script, true);
        }

        private void ShowGridMessage(string msg, bool success)
        {
            string type = success ? "success" : "error";
            string cleanMessage = msg.Replace("'", "\\'").Replace("\r", "").Replace("\n", " ");
            string script = string.Format("showToast('{0}', '{1}');", cleanMessage, type);
            ClientScript.RegisterStartupScript(this.GetType(), "toast_" + Guid.NewGuid().ToString("N"), script, true);
        }

        #region Ajax WebMethods

        [System.Web.Services.WebMethod]
        public static object LookupUser(string pcno)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(pcno))
                {
                    return new { success = false, message = "PCNO is empty" };
                }

                string cleanPcno = pcno.Trim();

                // 1. Check AppUsers table (local attendance application registry)
                try
                {
                    string query = "SELECT Name FROM AppUsers WHERE PCNO = :PCNO AND Name IS NOT NULL AND ROWNUM <= 1";
                    object res = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", cleanPcno));

                    if (res != null && res != DBNull.Value && !string.IsNullOrWhiteSpace(res.ToString()))
                    {
                        return new { success = true, found = true, name = res.ToString().Trim(), source = "AppUsers" };
                    }
                }
                catch { }

                // 2. Check Company HR database (hrdata.empdetails) for central employee records
                try
                {
                    string hrQuery = "SELECT NAME FROM hrdata.empdetails WHERE PCNO = :PCNO AND ROWNUM <= 1";
                    object hrRes = DBHelper.ExecuteScalar(DBHelper.GetCompanyDBConnection(), hrQuery, new OracleParameter("PCNO", cleanPcno));

                    if (hrRes != null && hrRes != DBNull.Value && !string.IsNullOrWhiteSpace(hrRes.ToString()))
                    {
                        return new { success = true, found = true, name = hrRes.ToString().Trim(), source = "CompanyDB" };
                    }
                }
                catch { }

                return new { success = true, found = false, name = "" };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        [System.Web.Services.WebMethod]
        public static object LookupSubUser(string pcno)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(pcno))
                {
                    return new { success = false, message = "PCNO is empty" };
                }

                string cleanPcno = pcno.Trim();

                // 1. Check name & role in AppUsers
                string qUser = "SELECT Name, Role FROM AppUsers WHERE PCNO = :PCNO AND ROWNUM <= 1";
                DataTable dtUser = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), qUser, new OracleParameter("PCNO", cleanPcno));
                string name = "";
                bool isSubUser = false;
                if (dtUser.Rows.Count > 0)
                {
                    name = dtUser.Rows[0]["Name"] != DBNull.Value ? dtUser.Rows[0]["Name"].ToString().Trim() : "";
                    int role = dtUser.Rows[0]["Role"] != DBNull.Value ? Convert.ToInt32(dtUser.Rows[0]["Role"]) : 0;
                    isSubUser = (role == 6 || role == 7);
                }
                else
                {
                    // Fallback to Employees / HR
                    try
                    {
                        object empName = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), 
                            "SELECT EmpName FROM Employees WHERE EmpID = :PCNO AND ROWNUM <= 1",
                            new OracleParameter("PCNO", cleanPcno));
                        if (empName != null && empName != DBNull.Value) name = empName.ToString().Trim();
                    }
                    catch { }

                    if (string.IsNullOrEmpty(name))
                    {
                        try
                        {
                            object hrName = DBHelper.ExecuteScalar(DBHelper.GetCompanyDBConnection(), 
                                "SELECT NAME FROM hrdata.empdetails WHERE PCNO = :PCNO AND ROWNUM <= 1",
                                new OracleParameter("PCNO", cleanPcno));
                            if (hrName != null && hrName != DBNull.Value) name = hrName.ToString().Trim();
                        }
                        catch { }
                    }
                }

                // 2. Fetch all currently assigned Anchor POCs
                List<string> assignedAnchors = new List<string>();
                string qAnchors = "SELECT AnchorPocPCNO FROM SubUserAnchor WHERE SubUserPCNO = :PCNO";
                DataTable dtAnchors = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), qAnchors, new OracleParameter("PCNO", cleanPcno));
                foreach (DataRow r in dtAnchors.Rows)
                {
                    if (r["AnchorPocPCNO"] != DBNull.Value)
                    {
                        assignedAnchors.Add(r["AnchorPocPCNO"].ToString().Trim());
                    }
                }

                return new 
                { 
                    success = true, 
                    found = !string.IsNullOrEmpty(name) || assignedAnchors.Count > 0, 
                    name = name, 
                    isSubUser = isSubUser,
                    anchors = assignedAnchors 
                };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        [System.Web.Services.WebMethod]
        public static object GetTiersForCategory(int categoryId)
        {
            try
            {
                string query = "SELECT Id, TierName || NVL2(RoleLabel, ' (#' || RoleLabel || ')', '') AS DisplayName FROM Tiers WHERE MainCategoryId = :MCId ORDER BY SortOrder ASC, TierName ASC";
                DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("MCId", categoryId));

                var list = new List<object>();
                foreach (DataRow r in dt.Rows)
                {
                    list.Add(new
                    {
                        id = r["Id"].ToString(),
                        name = r["DisplayName"].ToString()
                    });
                }

                return new { success = true, tiers = list };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        [System.Web.Services.WebMethod]
        public static object GetAnchorPocScope(string pocPcnos)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(pocPcnos)) return new { success = false, divisions = "", tiers = "" };
                string[] pcnoArray = pocPcnos.Split(new char[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries)
                                             .Select(p => p.Trim())
                                             .Where(p => !string.IsNullOrEmpty(p))
                                             .ToArray();

                if (pcnoArray.Length == 0) return new { success = false, divisions = "", tiers = "" };

                List<string> paramPlaceholders = new List<string>();
                List<OracleParameter> divParams = new List<OracleParameter>();
                List<OracleParameter> tierParams = new List<OracleParameter>();

                for (int i = 0; i < pcnoArray.Length; i++)
                {
                    string pName = "P" + i;
                    paramPlaceholders.Add(":" + pName);
                    divParams.Add(new OracleParameter(pName, pcnoArray[i]));
                    tierParams.Add(new OracleParameter(pName, pcnoArray[i]));
                }

                string inClause = string.Join(", ", paramPlaceholders);

                string qDivs = string.Format(@"SELECT LISTAGG(DivisionName, ', ') WITHIN GROUP (ORDER BY DivisionName) AS Divs 
                                 FROM (SELECT DISTINCT DivisionName FROM UserDivisions WHERE PCNO IN ({0}))", inClause);
                object resDivs = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), qDivs, divParams.ToArray());
                string divs = (resDivs != null && resDivs != DBNull.Value) ? resDivs.ToString() : "None";

                string qTiers = string.Format(@"
                    SELECT LISTAGG(ScopeName, ', ') WITHIN GROUP (ORDER BY ScopeName) AS Tiers
                    FROM (
                        SELECT DISTINCT (mc.Name || ' › ' || t.TierName) AS ScopeName
                        FROM UserTiers ut
                        JOIN Tiers t ON ut.TierId = t.Id
                        JOIN MainCategory mc ON t.MainCategoryId = mc.Id
                        WHERE ut.PCNO IN ({0})
                    )", inClause);
                object resTiers = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), qTiers, tierParams.ToArray());
                string tiers = (resTiers != null && resTiers != DBNull.Value) ? resTiers.ToString() : "None";

                return new { success = true, divisions = divs, tiers = tiers };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        #endregion
    }
}
