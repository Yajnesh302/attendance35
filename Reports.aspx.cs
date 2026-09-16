using System;
using System.Web;
using System.Web.UI;

namespace AttendanceApp
{
    public partial class Reports : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!User.Identity.IsAuthenticated || Session["PCNO"] == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            string roleMode = Session["RoleMode"]?.ToString() ?? "";
            int role = Convert.ToInt32(Session["Role"] ?? 0);
            if (roleMode == "SubUser" || role == 6)
            {
                Response.Redirect("Dashboard.aspx");
                return;
            }
        }
    }
}
