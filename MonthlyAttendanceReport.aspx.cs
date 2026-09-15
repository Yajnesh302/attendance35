using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Services;
using System.Web.UI;
using AttendanceApp.Utils;
using Oracle.ManagedDataAccess.Client;

namespace AttendanceApp
{
    public partial class MonthlyAttendanceReport : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!User.Identity.IsAuthenticated || Session["PCNO"] == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            if (Request.HttpMethod == "POST" && Request.Form["exportWordAction"] == "1")
            {
                ExportToWordDocument();
            }
        }

        private void ExportToWordDocument()
        {
            string htmlContent = Request.Form["exportHtmlContent"] ?? "";
            string monthYearStr = Request.Form["exportMonthYear"] ?? "Report";

            Response.Clear();
            Response.Buffer = true;
            Response.AddHeader("content-disposition", "attachment;filename=Attendance_Recommendation_Report_" + monthYearStr.Replace(" ", "_") + ".doc");
            Response.Charset = "utf-8";
            Response.ContentType = "application/msword";

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("<html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>");
            sb.AppendLine("<head>");
            sb.AppendLine("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">");
            sb.AppendLine("<!--[if gte mso 9]>");
            sb.AppendLine("<xml>");
            sb.AppendLine(" <w:WordDocument>");
            sb.AppendLine("  <w:View>Print</w:View>");
            sb.AppendLine("  <w:DoNotOptimizeForBrowser/>");
            sb.AppendLine(" </w:WordDocument>");
            sb.AppendLine("</xml>");
            sb.AppendLine("<![endif]-->");
            sb.AppendLine("<style>");
            sb.AppendLine("@page Section1 {");
            sb.AppendLine("  size: 11.0in 8.5in;");
            sb.AppendLine("  mso-page-orientation: landscape;");
            sb.AppendLine("  margin: 0.4in 0.8in 0.6in 0.8in;");
            sb.AppendLine("  mso-header-margin: 0.4in;");
            sb.AppendLine("  mso-footer-margin: 0.4in;");
            sb.AppendLine("}");
            sb.AppendLine("div.Section1 { page: Section1; }");
            sb.AppendLine("body { font-family: Arial, sans-serif; font-size: 11pt; color: #000000; margin: 0; padding: 0; }");
            sb.AppendLine("table { border-collapse: collapse; width: 100%; margin-top: 14px; margin-bottom: 14px; }");
            sb.AppendLine("table, th, td { border: 0.5pt solid #000000; }");
            sb.AppendLine("th { font-family: Arial, sans-serif; font-size: 10pt; font-weight: bold; text-align: center; vertical-align: middle; padding: 4px 6px; }");
            sb.AppendLine("td { font-family: Arial, sans-serif; font-size: 10pt; vertical-align: middle; padding: 4px 6px; text-align: center; }");
            sb.AppendLine(".text-left { text-align: left !important; }");
            sb.AppendLine(".text-center { text-align: center !important; }");
            sb.AppendLine(".text-right { text-align: right !important; }");
            sb.AppendLine(".bold { font-weight: bold; }");
            sb.AppendLine("</style>");
            sb.AppendLine("</head>");
            sb.AppendLine("<body>");
            sb.AppendLine("<div class=\"Section1\">");
            sb.AppendLine(htmlContent);
            sb.AppendLine("</div>");
            sb.AppendLine("</body>");
            sb.AppendLine("</html>");

            Response.Output.Write(sb.ToString());
            Response.Flush();
            Response.End();
        }

        [WebMethod]
        public static string GetInitData()
        {
            if (HttpContext.Current.Session["PCNO"] == null) return "{\"status\":\"error\",\"message\":\"Session expired\"}";

            try
            {
                string pcno = HttpContext.Current.Session["PCNO"].ToString();
                int role = Convert.ToInt32(HttpContext.Current.Session["Role"] ?? 0);

                DataTable dtTiers = DBHelper.GetVisibleTiersDataTable(pcno, role);
                var categoryList = new List<object>();

                // Get category descriptions from CertificateTemplates
                string qTpl = "SELECT TemplateKey, TemplateValue FROM CertificateTemplates WHERE TemplateKey LIKE 'PocRepManpower_%' OR TemplateKey LIKE 'WagesDesc_%'";
                DataTable dtTpl = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), qTpl);
                var descDict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                foreach (DataRow r in dtTpl.Rows)
                {
                    descDict[r["TemplateKey"].ToString()] = r["TemplateValue"].ToString();
                }

                foreach (DataRow row in dtTiers.Rows)
                {
                    int tierId = Convert.ToInt32(row["TierId"]);
                    string disp = row["DisplayName"].ToString();
                    string cleanTier = disp;
                    if (cleanTier.Contains(" › "))
                    {
                        var parts = cleanTier.Split(new string[] { " › " }, StringSplitOptions.None);
                        cleanTier = parts[parts.Length - 1].Trim();
                    }
                    string safeTier = cleanTier.Replace("-", "_").Replace(" ", "_");

                    // Look for manpower description: 1. PocRepManpower_Tier_ 2. PocRepManpower_<safeTier> 3. RoleLabel 4. WagesDesc_ 5. PocRepManpower_Default
                    string manpowerDesc = "DEO";
                    string tierKey = "PocRepManpower_Tier_" + tierId;
                    string catKey = "PocRepManpower_" + safeTier;

                    if (descDict.ContainsKey(tierKey) && !string.IsNullOrWhiteSpace(descDict[tierKey]))
                    {
                        manpowerDesc = descDict[tierKey].Trim();
                    }
                    else if (descDict.ContainsKey(catKey) && !string.IsNullOrWhiteSpace(descDict[catKey]))
                    {
                        manpowerDesc = descDict[catKey].Trim();
                    }
                    else if (row.Table.Columns.Contains("RoleLabel") && row["RoleLabel"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["RoleLabel"].ToString()))
                    {
                        manpowerDesc = row["RoleLabel"].ToString().Trim();
                    }
                    else if (descDict.ContainsKey("WagesDesc_" + safeTier) && !string.IsNullOrWhiteSpace(descDict["WagesDesc_" + safeTier]))
                    {
                        manpowerDesc = descDict["WagesDesc_" + safeTier].Trim();
                    }
                    else if (descDict.ContainsKey("PocRepManpower_Default") && !string.IsNullOrWhiteSpace(descDict["PocRepManpower_Default"]))
                    {
                        manpowerDesc = descDict["PocRepManpower_Default"].Trim();
                    }
                    else if (cleanTier.Equals("Semi-Skilled", StringComparison.OrdinalIgnoreCase) || cleanTier.Equals("Semi Skilled", StringComparison.OrdinalIgnoreCase))
                    {
                        manpowerDesc = "Office Assistant";
                    }
                    else if (cleanTier.Equals("Skilled", StringComparison.OrdinalIgnoreCase))
                    {
                        manpowerDesc = "DEO";
                    }

                    categoryList.Add(new
                    {
                        TierId = tierId,
                        DisplayName = disp,
                        CleanName = cleanTier,
                        ManpowerDesc = manpowerDesc
                    });
                }

                // Default date: Current local time
                DateTime now = DateTime.Now;

                return new JavaScriptSerializer().Serialize(new
                {
                    status = "success",
                    CurrentYear = now.Year,
                    CurrentMonth = now.Month, // 1-indexed (1 = Jan, 12 = Dec)
                    Categories = categoryList
                });
            }
            catch (Exception ex)
            {
                return new JavaScriptSerializer().Serialize(new { status = "error", message = ex.Message });
            }
        }

        [WebMethod]
        public static string GetContracts(int year, int month, int tierId)
        {
            if (HttpContext.Current.Session["PCNO"] == null) return "[]";

            try
            {
                DateTime firstDay = new DateTime(year, month, 1);
                DateTime lastDay = firstDay.AddMonths(1).AddDays(-1);

                string query = @"
                    SELECT cp.Id, cp.GemId, cp.StartDate, cp.EndDate, cp.Status, 
                           v.Name AS VendorName, v.Address AS VendorAddress, cp.DatedOn AS VendorDatedOn
                    FROM ContractPeriods cp 
                    JOIN Vendors v ON cp.VendorId = v.Id 
                    WHERE cp.TierId = :TierId 
                      AND cp.StartDate <= :LastDay 
                      AND (cp.EndDate IS NULL OR cp.EndDate >= :FirstDay)
                    ORDER BY CASE WHEN cp.Status = 'Active' THEN 0 ELSE 1 END, cp.StartDate DESC";

                DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query,
                    new OracleParameter("TierId", tierId),
                    new OracleParameter("LastDay", lastDay),
                    new OracleParameter("FirstDay", firstDay));

                var list = new List<object>();
                foreach (DataRow row in dt.Rows)
                {
                    DateTime start = Convert.ToDateTime(row["StartDate"]);
                    string endStr = row["EndDate"] != DBNull.Value ? Convert.ToDateTime(row["EndDate"]).ToString("dd-MMM-yyyy") : "onwards";
                    list.Add(new
                    {
                        Id = Convert.ToInt32(row["Id"]),
                        VendorName = row["VendorName"].ToString(),
                        VendorAddress = row["VendorAddress"] != DBNull.Value ? row["VendorAddress"].ToString() : "",
                        Status = row["Status"].ToString(),
                        DisplayName = $"{row["VendorName"]} ({row["Status"]} - {start:dd-MMM-yyyy} to {endStr})"
                    });
                }

                return new JavaScriptSerializer().Serialize(list);
            }
            catch (Exception)
            {
                return "[]";
            }
        }

        [WebMethod]
        public static string GetReportData(int year, int month, int tierId, int contractPeriodId)
        {
            if (HttpContext.Current.Session["PCNO"] == null) return "{\"status\":\"error\",\"message\":\"Session expired\"}";

            try
            {
                string pcno = HttpContext.Current.Session["PCNO"].ToString();
                int role = Convert.ToInt32(HttpContext.Current.Session["Role"] ?? 0);

                DateTime monthStart = new DateTime(year, month, 1);
                DateTime monthEnd = monthStart.AddMonths(1).AddDays(-1);
                DateTime prevMonthDate = monthStart.AddMonths(-1);
                string prevMonthName = prevMonthDate.ToString("MMMM");
                string curMonthNameUpper = monthStart.ToString("MMM", CultureInfo.InvariantCulture).ToUpper();

                // 1. Get POC accessible divisions
                List<string> allowedDivisions = HttpContext.Current.Session["AllowedDivisions"] as List<string>;
                if (allowedDivisions == null || allowedDivisions.Count == 0)
                {
                    string divSql = "SELECT DivisionName FROM UserDivisions WHERE PCNO = :PCNO";
                    DataTable dtDiv = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), divSql, new OracleParameter("PCNO", pcno));
                    allowedDivisions = new List<string>();
                    foreach (DataRow dr in dtDiv.Rows)
                    {
                        allowedDivisions.Add(dr["DivisionName"].ToString());
                    }
                }
                string directorateStr = allowedDivisions.Count > 0 ? string.Join(", ", allowedDivisions) : "D-KRM";

                // 2. Fetch Templates (including POC report templates and WagesDesc templates)
                string tplSql = "SELECT TemplateKey, TemplateValue FROM CertificateTemplates WHERE TemplateKey LIKE 'PocRep%' OR TemplateKey LIKE 'WagesDesc%'";
                DataTable dtTpl = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), tplSql);
                Dictionary<string, string> tplDict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                foreach (DataRow r in dtTpl.Rows)
                {
                    tplDict[r["TemplateKey"].ToString()] = r["TemplateValue"].ToString();
                }

                string topLine1Tpl = tplDict.ContainsKey("PocRepTopLine1") ? tplDict["PocRepTopLine1"] : "M/s {VendorName}";
                string topLine2Tpl = tplDict.ContainsKey("PocRepTopLine2") ? tplDict["PocRepTopLine2"] : "MONTHLY REPORT AND RECOMMENDATION ON HIRING OF MANPOWER SERVICES FOR MAKING PAYMENT FOR THE MONTH OF {Month:upper} - {Year}";
                string topFontSize = tplDict.ContainsKey("PocRepTopFontSize") ? tplDict["PocRepTopFontSize"] : "11";
                string topAlign = tplDict.ContainsKey("PocRepTopAlign") ? tplDict["PocRepTopAlign"] : "center";
                string certParagraph = tplDict.ContainsKey("PocRepCertParagraph") ? tplDict["PocRepCertParagraph"] : "It is certified that the above mentioned individuals have worked during office hours on the number of days as mentioned against their names and the individuals have received their previous month salary & EPF contribution from the service provider.";
                string signaturesTpl = tplDict.ContainsKey("PocRepSignatures") ? tplDict["PocRepSignatures"] : "(Point of Contact)\r\nSignature of Group Director\r\nTo\r\n    {Directorate}";
                string bottomFontSize = tplDict.ContainsKey("PocRepBottomFontSize") ? tplDict["PocRepBottomFontSize"] : "11";
                string bottomAlign = tplDict.ContainsKey("PocRepBottomAlign") ? tplDict["PocRepBottomAlign"] : "left";

                // 3. Resolve Vendor Name
                string vendorName = "VISHAL MANPOWER & SECURITY CONSULTANTS";
                if (contractPeriodId > 0)
                {
                    string vSql = "SELECT v.Name FROM ContractPeriods cp JOIN Vendors v ON cp.VendorId = v.Id WHERE cp.Id = :CId";
                    object vObj = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), vSql, new OracleParameter("CId", contractPeriodId));
                    if (vObj != null && vObj != DBNull.Value) vendorName = vObj.ToString();
                }
                else
                {
                    string vSql = @"
                        SELECT v.Name FROM ContractPeriods cp 
                        JOIN Vendors v ON cp.VendorId = v.Id 
                        WHERE cp.TierId = :TierId 
                          AND cp.StartDate <= :LastDay 
                          AND (cp.EndDate IS NULL OR cp.EndDate >= :FirstDay)
                        ORDER BY CASE WHEN cp.Status = 'Active' THEN 0 ELSE 1 END, cp.StartDate DESC";
                    object vObj = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), vSql,
                        new OracleParameter("TierId", tierId),
                        new OracleParameter("LastDay", monthEnd),
                        new OracleParameter("FirstDay", monthStart));
                    if (vObj != null && vObj != DBNull.Value) vendorName = vObj.ToString();
                }

                // Format Top Line 1 & Line 2
                string line1Text = topLine1Tpl.Replace("{VendorName}", vendorName);
                if (!line1Text.StartsWith("M/s", StringComparison.OrdinalIgnoreCase) && !line1Text.StartsWith("M/S", StringComparison.OrdinalIgnoreCase))
                {
                    line1Text = "M/s " + line1Text;
                }

                string line2Text = topLine2Tpl
                    .Replace("{Month:upper}", curMonthNameUpper)
                    .Replace("{Month}", monthStart.ToString("MMM", CultureInfo.InvariantCulture))
                    .Replace("{MonthFull}", monthStart.ToString("MMMM", CultureInfo.InvariantCulture))
                    .Replace("{Year}", year.ToString());

                string signaturesText = signaturesTpl
                    .Replace("{Directorate}", directorateStr)
                    .Replace("{directorate}", directorateStr)
                    .Replace("{Division}", directorateStr)
                    .Replace("{division}", directorateStr);

                // 4. Resolve Category & Manpower Description
                string catName = "Skilled";
                string manpowerDesc = "DEO";
                string catQuery = "SELECT TierName, RoleLabel FROM Tiers WHERE Id = :TierId";
                DataTable dtCat = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), catQuery, new OracleParameter("TierId", tierId));
                if (dtCat.Rows.Count > 0)
                {
                    catName = dtCat.Rows[0]["TierName"].ToString();
                    string safeCat = catName.Replace("-", "_").Replace(" ", "_");

                    // 1. Check POC Report Manpower Template: PocRepManpower_Tier_<TierId>
                    string tierKey = "PocRepManpower_Tier_" + tierId;
                    // 2. Check POC Report Manpower Template: PocRepManpower_<SafeCategory>
                    string pocKey = "PocRepManpower_" + safeCat;

                    if (tplDict.ContainsKey(tierKey) && !string.IsNullOrWhiteSpace(tplDict[tierKey]))
                    {
                        manpowerDesc = tplDict[tierKey].Trim();
                    }
                    else if (tplDict.ContainsKey(pocKey) && !string.IsNullOrWhiteSpace(tplDict[pocKey]))
                    {
                        manpowerDesc = tplDict[pocKey].Trim();
                    }
                    // 3. Check Tier RoleLabel
                    else if (dtCat.Rows[0]["RoleLabel"] != DBNull.Value && !string.IsNullOrWhiteSpace(dtCat.Rows[0]["RoleLabel"].ToString()))
                    {
                        manpowerDesc = dtCat.Rows[0]["RoleLabel"].ToString().Trim();
                    }
                    // 4. Check CertificateTemplates WagesDesc_<SafeCategory>
                    else if (tplDict.ContainsKey("WagesDesc_" + safeCat) && !string.IsNullOrWhiteSpace(tplDict["WagesDesc_" + safeCat]))
                    {
                        manpowerDesc = tplDict["WagesDesc_" + safeCat].Trim();
                    }
                    // 5. Check PocRepManpower_Default
                    else if (tplDict.ContainsKey("PocRepManpower_Default") && !string.IsNullOrWhiteSpace(tplDict["PocRepManpower_Default"]))
                    {
                        manpowerDesc = tplDict["PocRepManpower_Default"].Trim();
                    }
                    // 6. Fallbacks
                    else if (catName.Equals("Semi-Skilled", StringComparison.OrdinalIgnoreCase) || catName.Equals("Semi Skilled", StringComparison.OrdinalIgnoreCase))
                    {
                        manpowerDesc = "Office Assistant";
                    }
                    else if (catName.Equals("Skilled", StringComparison.OrdinalIgnoreCase))
                    {
                        manpowerDesc = "DEO";
                    }
                }

                // 5. Query Employees under this Category and POC's allowed divisions
                string empQuery = @"
                    SELECT e.MasterId, e.ID, e.Name, e.Department, e.JoinDate, e.ResignDate, e.ContractEndDate
                    FROM Employees e
                    WHERE e.TierId = :TierId 
                      AND e.MasterId NOT LIKE 'GLOBAL%' 
                      AND e.Status <> 'System'
                      AND (e.JoinDate IS NULL OR e.JoinDate <= :MonthEnd)
                      AND (e.ContractEndDate IS NULL OR e.ContractEndDate >= :MonthStart)
                      AND (e.ResignDate IS NULL OR e.ResignDate >= :MonthStart)";

                List<OracleParameter> empParams = new List<OracleParameter>
                {
                    new OracleParameter("TierId", tierId),
                    new OracleParameter("MonthEnd", monthEnd),
                    new OracleParameter("MonthStart", monthStart)
                };

                if (role != 1 && role != 4 && allowedDivisions.Count > 0)
                {
                    List<string> divClauses = new List<string>();
                    for (int i = 0; i < allowedDivisions.Count; i++)
                    {
                        string pName = "Div" + i;
                        divClauses.Add("e.Department LIKE :" + pName);
                        empParams.Add(new OracleParameter(pName, allowedDivisions[i] + "%"));
                    }
                    empQuery += " AND (" + string.Join(" OR ", divClauses) + ")";
                }

                empQuery += " ORDER BY LPAD(e.ID, 10, '0') ASC, e.Name ASC";
                DataTable dtEmp = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), empQuery, empParams.ToArray());

                // 6. Query Attendance for all matched employees in this Year & Month (Oracle Attendance.Month is 0-indexed: 0=Jan, 7=Aug, 11=Dec)
                var employeeRows = new List<object>();
                int totalDaysInMonth = DateTime.DaysInMonth(year, month);
                int dbMonth = month - 1;

                // Batch load attendance from Attendance (main table) for this month
                string attSql = @"
                    SELECT EmpID, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks 
                    FROM Attendance 
                    WHERE Year = :Year AND Month = :Month";
                DataTable dtAtt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), attSql,
                    new OracleParameter("Year", year),
                    new OracleParameter("Month", dbMonth));

                Dictionary<string, Dictionary<int, DataRow>> attByEmp = new Dictionary<string, Dictionary<int, DataRow>>(StringComparer.OrdinalIgnoreCase);
                if (dtAtt != null)
                {
                    foreach (DataRow dr in dtAtt.Rows)
                    {
                        string eid = dr["EmpID"].ToString();
                        int d = Convert.ToInt32(dr["Day"]);
                        if (!attByEmp.ContainsKey(eid)) attByEmp[eid] = new Dictionary<int, DataRow>();
                        attByEmp[eid][d] = dr;
                    }
                }

                // Also overlay AttendanceDraft for any pending draft cells not yet finalized in Attendance
                try
                {
                    string draftSql = @"
                        SELECT EmpID, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks 
                        FROM AttendanceDraft 
                        WHERE Year = :Year AND Month = :Month";
                    DataTable dtDraft = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), draftSql,
                        new OracleParameter("Year", year),
                        new OracleParameter("Month", dbMonth));

                    if (dtDraft != null)
                    {
                        foreach (DataRow dr in dtDraft.Rows)
                        {
                            string eid = dr["EmpID"].ToString();
                            int d = Convert.ToInt32(dr["Day"]);
                            if (!attByEmp.ContainsKey(eid)) attByEmp[eid] = new Dictionary<int, DataRow>();
                            // If live record doesn't already have status, or if draft provides it:
                            if (!attByEmp[eid].ContainsKey(d))
                            {
                                attByEmp[eid][d] = dr;
                            }
                        }
                    }
                }
                catch (Exception) { /* AttendanceDraft table safety */ }

                foreach (DataRow row in dtEmp.Rows)
                {
                    string empId = row["MasterId"].ToString();
                    string empDisplayId = row["ID"].ToString();
                    string empName = row["Name"].ToString();
                    DateTime? joinDate = row["JoinDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(row["JoinDate"]) : null;
                    DateTime? resignDate = row["ResignDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(row["ResignDate"]) : null;

                    Dictionary<int, DataRow> dayMap = attByEmp.ContainsKey(empId) ? attByEmp[empId] : new Dictionary<int, DataRow>();

                    // Check if employee has ANY non-AutoSat attendance recorded in this month
                    bool hasEmployeeMonthData = false;
                    foreach (var kvp in dayMap)
                    {
                        DataRow ar = kvp.Value;
                        int autoSat = ar.Table.Columns.Contains("AutoSat") && ar["AutoSat"] != DBNull.Value ? Convert.ToInt32(ar["AutoSat"]) : 0;
                        double? val = ar["StatusValue"] != DBNull.Value ? (double?)Convert.ToDouble(ar["StatusValue"]) : null;
                        string ltype = ar["LeaveType"] != DBNull.Value ? ar["LeaveType"].ToString().Trim() : "";

                        if (autoSat == 0 && (val.HasValue || !string.IsNullOrEmpty(ltype)))
                        {
                            hasEmployeeMonthData = true;
                            break;
                        }
                    }

                    double presentDays = 0;
                    double absentDays = 0;
                    List<int> absentDateList = new List<int>();
                    List<int> halfDayDateList = new List<int>();

                    if (hasEmployeeMonthData)
                    {
                        for (int day = 1; day <= totalDaysInMonth; day++)
                        {
                            DateTime date = new DateTime(year, month, day);

                            // Don't count Saturdays and Sundays
                            if (date.DayOfWeek == DayOfWeek.Saturday || date.DayOfWeek == DayOfWeek.Sunday)
                            {
                                continue;
                            }

                            // Check stint eligibility
                            if (joinDate.HasValue && date.Date < joinDate.Value.Date)
                            {
                                continue;
                            }
                            if (resignDate.HasValue && date.Date > resignDate.Value.Date)
                            {
                                absentDays += 1.0;
                                continue;
                            }

                            if (dayMap.ContainsKey(day))
                            {
                                DataRow ar = dayMap[day];
                                int isHol = ar["IsHoliday"] != DBNull.Value ? Convert.ToInt32(ar["IsHoliday"]) : 0;
                                string ltype = ar["LeaveType"] != DBNull.Value ? ar["LeaveType"].ToString().Trim() : "";
                                double? val = ar["StatusValue"] != DBNull.Value ? (double?)Convert.ToDouble(ar["StatusValue"]) : null;

                                if (isHol == 1)
                                {
                                    // Declared Office Holiday: counted as present/attended (office closed, not absent)
                                    presentDays += 1.0;
                                    continue;
                                }

                                // Half day detection:
                                // StatusValue is 0.5 OR LeaveType is Carried / Pending Pairing / Paired Paid / Paired Unpaid / contains Half
                                bool isHalfDay = false;
                                if (val.HasValue && Math.Abs(val.Value - 0.5) < 0.05)
                                {
                                    isHalfDay = true;
                                }
                                else if (ltype.Equals("Carried", StringComparison.OrdinalIgnoreCase) ||
                                         ltype.Equals("Pending Pairing", StringComparison.OrdinalIgnoreCase) ||
                                         ltype.Equals("Paired Paid", StringComparison.OrdinalIgnoreCase) ||
                                         ltype.Equals("Paired Unpaid", StringComparison.OrdinalIgnoreCase) ||
                                         ltype.IndexOf("half", StringComparison.OrdinalIgnoreCase) >= 0)
                                {
                                    isHalfDay = true;
                                }

                                if (isHalfDay)
                                {
                                    presentDays += 0.5;
                                    absentDays += 0.5;
                                    halfDayDateList.Add(day);
                                }
                                else if (val.HasValue && Math.Abs(val.Value - 1.0) < 0.01)
                                {
                                    presentDays += 1.0;
                                }
                                else if ((val.HasValue && Math.Abs(val.Value - 0.0) < 0.01) ||
                                         ltype.Equals("Paid", StringComparison.OrdinalIgnoreCase) ||
                                         ltype.Equals("Unpaid", StringComparison.OrdinalIgnoreCase) ||
                                         (val.HasValue && (val.Value == 2.0 || val.Value == 3.0)))
                                {
                                    // In POC raw view: when POC marks 0, or leave is marked Paid/Unpaid, it's considered absent (1 day not attended)
                                    absentDays += 1.0;
                                    absentDateList.Add(day);
                                }
                                else
                                {
                                    // Unmarked weekday: not recorded, do not default to present
                                }
                            }
                            else
                            {
                                // Unmarked weekday: not recorded, do not default to present
                            }
                        }
                    }

                    // Format Present Days (e.g. 21, 20, 06, or 19.5, 20.5)
                    string formattedPresent = presentDays % 1 == 0 
                        ? ((int)presentDays).ToString("D2") 
                        : presentDays.ToString("0.0", CultureInfo.InvariantCulture);

                    // Format Absent Days (e.g. 01, 02, 16, or 0.5, 1.5, or -)
                    string formattedAbsent = "-";
                    if (absentDays > 0)
                    {
                        formattedAbsent = absentDays % 1 == 0 
                            ? ((int)absentDays).ToString("D2") 
                            : absentDays.ToString("0.0", CultureInfo.InvariantCulture);
                    }

                    // Format Remarks
                    string remarks = BuildRemarksString(absentDateList, halfDayDateList, joinDate, resignDate, year, month);
                    bool isJoinedCurrentMonth = (joinDate.HasValue && joinDate.Value.Year == year && joinDate.Value.Month == month);

                    employeeRows.Add(new
                    {
                        ID = empDisplayId,
                        Name = empName,
                        PresentDays = formattedPresent,
                        AbsentDays = formattedAbsent,
                        Remarks = remarks,
                        JoinedCurrentMonth = isJoinedCurrentMonth
                    });
                }

                return new JavaScriptSerializer().Serialize(new
                {
                    status = "success",
                    Line1 = line1Text,
                    Line2 = line2Text,
                    Directorate = directorateStr,
                    TopFontSize = topFontSize,
                    TopAlign = topAlign,
                    CategoryName = catName,
                    ManpowerDesc = manpowerDesc,
                    PrevMonthName = prevMonthName,
                    CertParagraph = certParagraph,
                    Signatures = signaturesText,
                    BottomFontSize = bottomFontSize,
                    BottomAlign = bottomAlign,
                    Employees = employeeRows
                });
            }
            catch (Exception ex)
            {
                return new JavaScriptSerializer().Serialize(new { status = "error", message = ex.Message });
            }
        }

        private static string BuildRemarksString(List<int> absentDates, List<int> halfDayDates, DateTime? joinDate, DateTime? resignDate, int year, int month)
        {
            List<string> remarksParts = new List<string>();
            string monName = new DateTime(year, month, 1).ToString("MMM", CultureInfo.InvariantCulture);

            // 1. Join Date in this month
            if (joinDate.HasValue && joinDate.Value.Year == year && joinDate.Value.Month == month)
            {
                string jDay = GetDayWithOrdinal(joinDate.Value.Day, true);
                remarksParts.Add($"Join on {jDay} {monName} {year}");
            }

            // 2. Resign Date in this month
            if (resignDate.HasValue && resignDate.Value.Year == year && resignDate.Value.Month == month)
            {
                string rDay = GetDayWithOrdinal(resignDate.Value.Day, true);
                remarksParts.Add($"Resigned on {rDay} {monName} {year}");
            }

            // 3. Full-day Absences
            if (absentDates != null && absentDates.Count > 0)
            {
                absentDates.Sort();
                string leavePattern = FormatDatesList(absentDates, monName, year);
                remarksParts.Add($"Leave taken on {leavePattern}");
            }

            // 4. Half-day Absences
            if (halfDayDates != null && halfDayDates.Count > 0)
            {
                halfDayDates.Sort();
                string halfDayPattern = FormatDatesList(halfDayDates, monName, year);
                remarksParts.Add($"Half day taken on {halfDayPattern}");
            }

            if (remarksParts.Count == 0) return "";
            return string.Join(", ", remarksParts);
        }

        private static string FormatDatesList(List<int> days, string monName, int year)
        {
            if (days.Count == 1)
            {
                return $"{GetDayWithOrdinal(days[0], true)} {monName} {year}";
            }

            // Check if contiguous range
            bool isContiguous = true;
            for (int i = 1; i < days.Count; i++)
            {
                // Count non-weekends between
                DateTime prev = new DateTime(year, DateTime.ParseExact(monName, "MMM", CultureInfo.InvariantCulture).Month, days[i - 1]);
                DateTime curr = new DateTime(year, DateTime.ParseExact(monName, "MMM", CultureInfo.InvariantCulture).Month, days[i]);

                // Check calendar days gap: only weekends in between are allowed for contiguous range
                int gap = (curr - prev).Days;
                if (gap == 1) continue;
                if (gap == 3 && prev.DayOfWeek == DayOfWeek.Friday && curr.DayOfWeek == DayOfWeek.Monday) continue;

                isContiguous = false;
                break;
            }

            if (isContiguous && days.Count > 2)
            {
                return $"{GetDayWithOrdinal(days[0], true)} to {GetDayWithOrdinal(days[days.Count - 1], true)} {monName} {year}";
            }

            if (days.Count == 2)
            {
                return $"{GetDayWithOrdinal(days[0], true)} & {GetDayWithOrdinal(days[1], false)} {monName} {year}";
            }

            // List of multiple days
            List<string> parts = new List<string>();
            for (int i = 0; i < days.Count; i++)
            {
                if (i == days.Count - 1 && parts.Count > 0)
                {
                    parts[parts.Count - 1] = parts[parts.Count - 1] + " & " + GetDayWithOrdinal(days[i], false);
                }
                else
                {
                    parts.Add(GetDayWithOrdinal(days[i], true));
                }
            }
            return string.Join(", ", parts) + $" {monName} {year}";
        }

        private static string GetDayWithOrdinal(int day, bool padZero)
        {
            string sDay = padZero ? day.ToString("D2") : day.ToString();
            switch (day % 100)
            {
                case 11:
                case 12:
                case 13:
                    return sDay + "th";
            }
            switch (day % 10)
            {
                case 1: return sDay + "st";
                case 2: return sDay + "th"; // matching sample '02th' from Word document
                case 3: return sDay + "rd";
                default: return sDay + "th";
            }
        }
    }
}
