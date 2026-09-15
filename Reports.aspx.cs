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
        }
    }
}
