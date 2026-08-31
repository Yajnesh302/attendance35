using System;
using System.Collections.Generic;
using System.Linq;
using System.Data;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Services;
using AttendanceApp.Utils;
using Oracle.ManagedDataAccess.Client;

namespace AttendanceApp
{
    public partial class Attendance : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!User.Identity.IsAuthenticated)
            {
                Response.Redirect("Login.aspx");
            }
        }

        private static bool _globalEmployeesEnsured = false;
        private static readonly object _globalEmpLock = new object();

        private static List<string> _cachedRecentRemarks = null;
        private static DateTime _lastRemarksCacheTime = DateTime.MinValue;
        private static readonly object _remarksLock = new object();

        private static List<string> GetCachedRecentRemarks()
        {
            if (_cachedRecentRemarks != null && (DateTime.UtcNow - _lastRemarksCacheTime).TotalMinutes < 30)
            {
                return _cachedRecentRemarks;
            }
            lock (_remarksLock)
            {
                if (_cachedRecentRemarks != null && (DateTime.UtcNow - _lastRemarksCacheTime).TotalMinutes < 30)
                {
                    return _cachedRecentRemarks;
                }
                var list = new List<string>();
                try
                {
                    string remQuery = @"
                        SELECT Remarks FROM (
                            SELECT Remarks, COUNT(*) as cnt 
                            FROM Attendance 
                            WHERE Remarks IS NOT NULL AND TRIM(Remarks) IS NOT NULL 
                            GROUP BY Remarks 
                            ORDER BY cnt DESC
                        ) WHERE ROWNUM <= 15";
                    DataTable dtRem = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), remQuery);
                    if (dtRem != null)
                    {
                        foreach (DataRow row in dtRem.Rows)
                        {
                            list.Add(row["Remarks"].ToString());
                        }
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("Error fetching recent remarks: " + ex.Message);
                }
                _cachedRecentRemarks = list;
                _lastRemarksCacheTime = DateTime.UtcNow;
                return list;
            }
        }

        private static void EnsureGlobalEmployeesExist()
        {
            if (_globalEmployeesEnsured) return;
            lock (_globalEmpLock)
            {
                if (_globalEmployeesEnsured) return;
                try
                {
                    string connStr = DBHelper.GetAttendanceDBConnection();
                    
                    // Ensure default 'GLOBAL' exists
                    string checkQuery = "SELECT COUNT(*) FROM Employees WHERE MasterId = 'GLOBAL'";
                    object countObj = DBHelper.ExecuteScalar(connStr, checkQuery);
                    int count = countObj != null && countObj != DBNull.Value ? Convert.ToInt32(countObj) : 0;
                    if (count == 0)
                    {
                        string insertQuery = @"
                            INSERT INTO Employees (MasterId, ID, Name, Department, TierId, Status, LeaveBalance) 
                            VALUES ('GLOBAL', 'GLOBAL', 'GLOBAL Adjustment', NULL, NULL, 'System', 0)";
                        DBHelper.ExecuteNonQuery(connStr, insertQuery);
                    }

                    // Ensure tier-specific 'GLOBAL_<TierId>' exists for all tiers
                    string catQuery = "SELECT Id, TierName FROM Tiers";
                    DataTable dtCats = DBHelper.ExecuteQuery(connStr, catQuery);
                    foreach (DataRow row in dtCats.Rows)
                    {
                        string tierId = row["Id"].ToString();
                        string tierName = row["TierName"].ToString();
                        string empId = "GLOBAL_" + tierId;
                        string checkCatQuery = "SELECT COUNT(*) FROM Employees WHERE MasterId = :EmpID";
                        object countCatObj = DBHelper.ExecuteScalar(connStr, checkCatQuery, new OracleParameter("EmpID", empId));
                        int countCat = countCatObj != null && countCatObj != DBNull.Value ? Convert.ToInt32(countCatObj) : 0;
                        if (countCat == 0)
                        {
                            string insertQuery = @"
                                INSERT INTO Employees (MasterId, ID, Name, Department, TierId, Status, LeaveBalance) 
                                VALUES (:MasterId, :ID, :Name, NULL, :TierId, 'System', 0)";
                            DBHelper.ExecuteNonQuery(connStr, insertQuery,
                                new OracleParameter("MasterId", empId),
                                new OracleParameter("ID", empId),
                                new OracleParameter("Name", "GLOBAL Adjustment (" + tierName + ")"),
                                new OracleParameter("TierId", Convert.ToInt32(tierId)));
                        }
                    }
                    // Fix status for any existing GLOBAL records in Employees table
                    DBHelper.ExecuteNonQuery(connStr, "UPDATE Employees SET Status = 'System' WHERE MasterId LIKE 'GLOBAL%'");
                    _globalEmployeesEnsured = true;
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("Error ensuring GLOBAL employees exist: " + ex.Message);
                }
            }
        }

        [WebMethod]
        public static string GetData(int year, int month, string category, string division, string search)
        {
            EnsureGlobalEmployeesExist();
            int role = Convert.ToInt32(HttpContext.Current.Session["Role"] ?? 0);
            string sessionDivision = HttpContext.Current.Session["Division"]?.ToString() ?? "";

            int editDaysAllowed = 0;
            int editMode = 0;
            bool isViewRestricted = false;
            string minViewDateStr = null;
            string maxViewDateStr = null;
            string viewRestrictionDesc = null;

            if (role != 1 && role != 4)
            {
                string pcno = HttpContext.Current.Session["PCNO"]?.ToString() ?? "";
                DataTable dtMode = null;
                if (!string.IsNullOrEmpty(category) && category != "All")
                {
                    int catTierId;
                    if (int.TryParse(category, out catTierId))
                    {
                        string qCat = @"
                            SELECT COALESCE(mc.EditDaysAllowed, 0) AS EditDaysAllowed,
                                   COALESCE(mc.EditMode, 0) AS EditMode
                            FROM Tiers t 
                            JOIN MainCategory mc ON t.MainCategoryId = mc.Id 
                            WHERE t.Id = :TierId";
                        dtMode = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), qCat, new OracleParameter("TierId", catTierId));
                    }
                }

                if (dtMode == null || dtMode.Rows.Count == 0)
                {
                    string qDays = @"
                        SELECT COALESCE(MAX(mc.EditDaysAllowed), 0) AS EditDaysAllowed,
                               COALESCE(MAX(mc.EditMode), 0) AS EditMode
                        FROM UserTiers ut 
                        JOIN Tiers t ON ut.TierId = t.Id 
                        JOIN MainCategory mc ON t.MainCategoryId = mc.Id 
                        WHERE ut.PCNO = :PCNO
                           OR ut.PCNO IN (SELECT AnchorPocPCNO FROM SubUserAnchor WHERE SubUserPCNO = :PCNO)";
                    dtMode = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), qDays, new OracleParameter("PCNO", pcno));
                }

                if (dtMode != null && dtMode.Rows.Count > 0 && dtMode.Rows[0]["EditDaysAllowed"] != DBNull.Value)
                {
                    editDaysAllowed = Convert.ToInt32(dtMode.Rows[0]["EditDaysAllowed"]);
                    editMode = Convert.ToInt32(dtMode.Rows[0]["EditMode"]);
                }

                // Check POC Viewable Month Restriction for Attendance page
                var viewInfo = DBHelper.GetPocViewRestriction(pcno, "Attendance", category);
                if (viewInfo.IsRestricted)
                {
                    isViewRestricted = true;
                    minViewDateStr = viewInfo.MinAllowedDate.HasValue ? viewInfo.MinAllowedDate.Value.ToString("yyyy-MM-dd") : null;
                    maxViewDateStr = viewInfo.MaxAllowedDate.HasValue ? viewInfo.MaxAllowedDate.Value.ToString("yyyy-MM-dd") : null;
                    viewRestrictionDesc = viewInfo.Description;

                    // If requested month (1-indexed: month + 1) is not allowed, block data retrieval immediately (0 database queries)
                    if (!viewInfo.IsMonthAllowed(year, month + 1))
                    {
                        var restrictedResult = new { 
                            IsRestricted = true, 
                            Status = "Restricted", 
                            Message = $"Access to {new DateTime(year, month + 1, 1):MMMM yyyy} attendance is restricted by your administrator ({viewInfo.Description}).",
                            Employees = new List<object>(), 
                            Attendance = new Dictionary<string, object>(), 
                            PrevAttendance = new Dictionary<string, object>(), 
                            Engagements = new List<object>(), 
                            FutureCarried = new Dictionary<string, object>(), 
                            RecentRemarks = new List<object>(), 
                            EditDaysAllowed = 0, 
                            EditMode = 0, 
                            PocEditRemarks = new Dictionary<string, object>(),
                            MinViewDate = minViewDateStr,
                            MaxViewDate = maxViewDateStr,
                            ViewRestrictionDesc = viewRestrictionDesc
                        };
                        return new JavaScriptSerializer().Serialize(restrictedResult);
                    }
                }
            }

            string empQuery = @"SELECT e.MasterId, e.ID, e.Name, e.Department, e.TierId,
                                       (SELECT mc.Name || ' > ' || t.TierName || NVL2(t.RoleLabel, ' (#' || t.RoleLabel || ')', '') FROM Tiers t JOIN MainCategory mc ON t.MainCategoryId = mc.Id WHERE t.Id = e.TierId) AS Category, 
                                       e.JoinDate, e.ResignDate, e.ContractEndDate, e.LeaveBalance, e.PrevLeaveBalance, ee.ContractPeriodId AS CurrentContractPeriodId
                                FROM Employees e
                                LEFT JOIN EmployeeEngagements ee ON e.CurrentEngagementId = ee.Id
                                 WHERE e.MasterId NOT LIKE 'GLOBAL%' AND e.Status <> 'System'
                                   AND (((e.Status IN ('Active', 'Upgraded', 'Downgraded', 'Transferred') AND (e.ContractEndDate IS NULL OR (EXTRACT(YEAR FROM e.ContractEndDate) > :Year OR (EXTRACT(YEAR FROM e.ContractEndDate) = :Year AND EXTRACT(MONTH FROM e.ContractEndDate) >= :Month))))
                                    OR (e.Status = 'ContractEnded' AND (e.ContractEndDate IS NULL OR (EXTRACT(YEAR FROM e.ContractEndDate) > :Year OR (EXTRACT(YEAR FROM e.ContractEndDate) = :Year AND EXTRACT(MONTH FROM e.ContractEndDate) >= :Month))))
                                    OR (e.Status = 'Resigned' AND (EXTRACT(YEAR FROM e.ResignDate) > :Year OR (EXTRACT(YEAR FROM e.ResignDate) = :Year AND EXTRACT(MONTH FROM e.ResignDate) >= :Month)))))";
            
            List<OracleParameter> parameters = new List<OracleParameter>
            {
                new OracleParameter("Year", year),
                new OracleParameter("Month", month + 1)
            };

            if (!string.IsNullOrEmpty(category) && category != "All")
            {
                empQuery += " AND e.TierId = :Cat";
                parameters.Add(new OracleParameter("Cat", Convert.ToInt32(category)));
            }

            if (role != 4)
            {
                string userPcno = HttpContext.Current.Session["PCNO"]?.ToString() ?? "";
                List<int> visibleTiers = DBHelper.GetVisibleTierIds(userPcno, role);
                if (visibleTiers.Count > 0)
                {
                    List<string> tierParams = new List<string>();
                    for (int i = 0; i < visibleTiers.Count; i++)
                    {
                        string paramName = "VTierId" + i;
                        tierParams.Add(":" + paramName);
                        parameters.Add(new OracleParameter(paramName, visibleTiers[i]));
                    }
                    empQuery += " AND e.TierId IN (" + string.Join(", ", tierParams) + ")";
                }
                else
                {
                    empQuery += " AND 1=0";
                }
            }

            if (role != 1 && role != 4)
            {
                var allowedDivs = HttpContext.Current.Session["AllowedDivisions"] as List<string>;
                if (allowedDivs != null && allowedDivs.Contains(division))
                {
                    empQuery += " AND e.Department LIKE :Div";
                    parameters.Add(new OracleParameter("Div", division + "%"));
                }
                else
                {
                    if (allowedDivs != null && allowedDivs.Count > 0)
                    {
                        List<string> divClauses = new List<string>();
                        for (int i = 0; i < allowedDivs.Count; i++)
                        {
                            string paramName = "Div" + i;
                            divClauses.Add("e.Department LIKE :" + paramName);
                            parameters.Add(new OracleParameter(paramName, allowedDivs[i] + "%"));
                        }
                        empQuery += " AND (" + string.Join(" OR ", divClauses) + ")";
                    }
                    else
                    {
                        empQuery += " AND 1=0";
                    }
                }
            }
            else
            {
                // Admin can filter by division
                if (!string.IsNullOrEmpty(division) && division != "All")
                {
                    empQuery += " AND e.Department = :Div";
                    parameters.Add(new OracleParameter("Div", division));
                }
            }

            if (!string.IsNullOrEmpty(search))
            {
                empQuery += " AND (UPPER(e.ID) LIKE UPPER(:Search) OR UPPER(e.Name) LIKE UPPER(:Search))";
                parameters.Add(new OracleParameter("Search", "%" + search + "%"));
            }

            empQuery += " ORDER BY e.Department ASC, e.Name ASC";

            DataTable dtEmp = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), empQuery, parameters.ToArray());

            // High-Speed Early Exit: If no employees match filters, return immediately without running 4 subsequent DB queries
            if (dtEmp == null || dtEmp.Rows.Count == 0)
            {
                var emptyResult = new { 
                    Employees = new List<object>(), 
                    Attendance = new Dictionary<string, object>(), 
                    PrevAttendance = new Dictionary<string, object>(), 
                    Engagements = new List<object>(), 
                    FutureCarried = new Dictionary<string, object>(), 
                    RecentRemarks = new List<object>(), 
                    EditDaysAllowed = editDaysAllowed, 
                    EditMode = editMode, 
                    PocEditRemarks = new Dictionary<string, object>(),
                    IsRestricted = isViewRestricted,
                    MinViewDate = minViewDateStr,
                    MaxViewDate = maxViewDateStr,
                    ViewRestrictionDesc = viewRestrictionDesc
                };
                return new JavaScriptSerializer().Serialize(emptyResult);
            }

            List<string> empIdList = new List<string>();
            foreach (DataRow r in dtEmp.Rows)
            {
                string mid = r["MasterId"]?.ToString();
                if (!string.IsNullOrEmpty(mid)) empIdList.Add(mid);
            }

            DateTime firstDay = new DateTime(year, month + 1, 1);
            DateTime lastDay = firstDay.AddMonths(1).AddDays(-1);

            // Fetch scoped engagements in 1 single clean query, indexed by EmpID
            string allEngSql;
            List<OracleParameter> engParams = new List<OracleParameter>();
            if (empIdList.Count <= 500)
            {
                List<string> pNames = new List<string>();
                for (int i = 0; i < empIdList.Count; i++)
                {
                    pNames.Add(":EngEmp" + i);
                    engParams.Add(new OracleParameter("EngEmp" + i, empIdList[i]));
                }
                allEngSql = @"
                    SELECT ee.Id, ee.EmpID, ee.ContractPeriodId, ee.TierId, ee.StartDate, ee.EndDate, ee.EndReason, cp.Status, cp.EndDate AS CpEndDate
                    FROM EmployeeEngagements ee
                    LEFT JOIN ContractPeriods cp ON ee.ContractPeriodId = cp.Id
                    WHERE ee.EmpID IN (" + string.Join(", ", pNames) + @")
                    ORDER BY ee.EmpID ASC, ee.StartDate ASC";
            }
            else
            {
                allEngSql = @"
                    SELECT ee.Id, ee.EmpID, ee.ContractPeriodId, ee.TierId, ee.StartDate, ee.EndDate, ee.EndReason, cp.Status, cp.EndDate AS CpEndDate
                    FROM EmployeeEngagements ee
                    LEFT JOIN ContractPeriods cp ON ee.ContractPeriodId = cp.Id
                    ORDER BY ee.EmpID ASC, ee.StartDate ASC";
            }
            DataTable dtAllEng = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), allEngSql, engParams.ToArray());

            Dictionary<string, List<DataRow>> engByEmp = new Dictionary<string, List<DataRow>>();
            Dictionary<string, DataRow> currEngByEmp = new Dictionary<string, DataRow>();
            Dictionary<string, DateTime> stintStartByEmp = new Dictionary<string, DateTime>();
            Dictionary<string, List<Tuple<int, DateTime>>> pastCpByEmp = new Dictionary<string, List<Tuple<int, DateTime>>>();
            List<object> engagements = new List<object>();

            if (dtAllEng != null)
            {
                foreach (DataRow er in dtAllEng.Rows)
                {
                    string eid = er["EmpID"].ToString();
                    if (!engByEmp.ContainsKey(eid)) engByEmp[eid] = new List<DataRow>();
                    engByEmp[eid].Add(er);

                    DateTime sDate = Convert.ToDateTime(er["StartDate"]);
                    DateTime? eDate = er["EndDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(er["EndDate"]) : null;
                    DateTime? cpEndDate = er["CpEndDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(er["CpEndDate"]) : null;

                    // Overlaps current month [firstDay, lastDay]?
                    if (sDate <= lastDay && (!eDate.HasValue || eDate.Value >= firstDay))
                    {
                        currEngByEmp[eid] = er;

                        DateTime? effectiveEndDate = null;
                        if (eDate.HasValue && cpEndDate.HasValue)
                            effectiveEndDate = eDate.Value < cpEndDate.Value ? eDate.Value : cpEndDate.Value;
                        else if (eDate.HasValue)
                            effectiveEndDate = eDate;
                        else if (cpEndDate.HasValue)
                            effectiveEndDate = cpEndDate;

                        engagements.Add(new {
                            EmpID = eid,
                            StartDate = sDate.ToString("yyyy-MM-dd"),
                            EndDate = effectiveEndDate.HasValue ? effectiveEndDate.Value.ToString("yyyy-MM-dd") : null,
                            Status = er["Status"] != DBNull.Value ? er["Status"].ToString() : "Active",
                            ContractPeriodId = er["ContractPeriodId"] != DBNull.Value ? (object)Convert.ToInt32(er["ContractPeriodId"]) : null
                        });
                    }
                }

                // Compute Stint Start Date per employee (stint after last 'RESIGNED') and pastCpByEmp
                foreach (var kvp in engByEmp)
                {
                    string eid = kvp.Key;
                    pastCpByEmp[eid] = new List<Tuple<int, DateTime>>();
                    DateTime maxResignEnd = new DateTime(1900, 1, 1);

                    for (int i = kvp.Value.Count - 1; i >= 0; i--)
                    {
                        DataRow er = kvp.Value[i];
                        string reason = er["EndReason"] != DBNull.Value ? er["EndReason"].ToString().ToUpper().Trim() : "";
                        if (reason == "RESIGNED" && er["EndDate"] != DBNull.Value)
                        {
                            DateTime rend = Convert.ToDateTime(er["EndDate"]);
                            if (rend > maxResignEnd) maxResignEnd = rend;
                        }
                        if (er["ContractPeriodId"] != DBNull.Value)
                        {
                            int cpVal = Convert.ToInt32(er["ContractPeriodId"]);
                            DateTime sDate = Convert.ToDateTime(er["StartDate"]);
                            pastCpByEmp[eid].Add(Tuple.Create(cpVal, sDate));
                        }
                    }

                    DateTime minStintStart = DateTime.MaxValue;
                    foreach (DataRow er in kvp.Value)
                    {
                        DateTime sDate = Convert.ToDateTime(er["StartDate"]);
                        if (sDate > maxResignEnd && sDate < minStintStart)
                        {
                            minStintStart = sDate;
                        }
                    }
                    stintStartByEmp[eid] = minStintStart != DateTime.MaxValue ? minStintStart : new DateTime(1900, 1, 1);
                }
            }

            // High-Speed Past Leaves Resolution (Replaces slow TO_DATE SQL joins with indexed seeks + O(1) memory lookup)
            Dictionary<string, Dictionary<string, double>> histByEmp = new Dictionary<string, Dictionary<string, double>>();
            Dictionary<string, Dictionary<string, int>> prevHalfCounts = new Dictionary<string, Dictionary<string, int>>();
            try
            {
                string pastLeavesSql;
                List<OracleParameter> pastParams = new List<OracleParameter>
                {
                    new OracleParameter("TY", year),
                    new OracleParameter("TM", month)
                };

                if (empIdList.Count <= 500)
                {
                    List<string> pNames = new List<string>();
                    for (int i = 0; i < empIdList.Count; i++)
                    {
                        pNames.Add(":PlEmp" + i);
                        pastParams.Add(new OracleParameter("PlEmp" + i, empIdList[i]));
                    }
                    pastLeavesSql = @"
                        SELECT a.EmpID, a.Year, a.Month, a.Day, a.StatusValue, a.LeaveType, a.ContractPeriodId
                        FROM Attendance a
                        WHERE ((a.Year < :TY) OR (a.Year = :TY AND a.Month < :TM))
                          AND a.EmpID NOT LIKE 'GLOBAL%'
                          AND a.Day > 0
                          AND a.EmpID IN (" + string.Join(", ", pNames) + @")
                          AND (
                              (a.StatusValue = 0 AND (a.LeaveType = 'Paid' OR a.LeaveType = 'Paired Paid'))
                              OR a.StatusValue = 0.5
                              OR a.LeaveType IN ('Carried', 'Paired Paid', 'Paired Unpaid', 'Pending Pairing')
                          )";
                }
                else
                {
                    pastLeavesSql = @"
                        SELECT a.EmpID, a.Year, a.Month, a.Day, a.StatusValue, a.LeaveType, a.ContractPeriodId
                        FROM Attendance a
                        WHERE ((a.Year < :TY) OR (a.Year = :TY AND a.Month < :TM))
                          AND a.EmpID NOT LIKE 'GLOBAL%'
                          AND a.Day > 0
                          AND (
                              (a.StatusValue = 0 AND (a.LeaveType = 'Paid' OR a.LeaveType = 'Paired Paid'))
                              OR a.StatusValue = 0.5
                              OR a.LeaveType IN ('Carried', 'Paired Paid', 'Paired Unpaid', 'Pending Pairing')
                          )";
                }

                DataTable dtPastLeaves = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), pastLeavesSql, pastParams.ToArray());

                if (dtPastLeaves != null)
                {
                    foreach (DataRow lr in dtPastLeaves.Rows)
                    {
                        string eid = lr["EmpID"].ToString();
                        int ly = Convert.ToInt32(lr["Year"]);
                        int lm = Convert.ToInt32(lr["Month"]);
                        int ld = Convert.ToInt32(lr["Day"]);
                        float? val = lr["StatusValue"] == DBNull.Value ? (float?)null : Convert.ToSingle(lr["StatusValue"]);
                        string ltype = lr["LeaveType"] == DBNull.Value ? "" : lr["LeaveType"].ToString().Trim();

                        DateTime attDate;
                        try { attDate = new DateTime(ly, lm + 1, ld); } catch { continue; }

                        DataRow matchedEng = null;
                        if (engByEmp.ContainsKey(eid))
                        {
                            foreach (DataRow er in engByEmp[eid])
                            {
                                DateTime sDate = Convert.ToDateTime(er["StartDate"]);
                                DateTime? eDate = er["EndDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(er["EndDate"]) : null;
                                if (attDate >= sDate && (!eDate.HasValue || attDate <= eDate.Value))
                                {
                                    matchedEng = er;
                                    break;
                                }
                            }
                        }

                        string cpKey = "null";
                        int? matchedCpId = null;
                        int? matchedTierId = null;
                        if (matchedEng != null)
                        {
                            if (matchedEng["ContractPeriodId"] != DBNull.Value)
                            {
                                matchedCpId = Convert.ToInt32(matchedEng["ContractPeriodId"]);
                                cpKey = matchedCpId.Value.ToString();
                            }
                            if (matchedEng["TierId"] != DBNull.Value)
                            {
                                matchedTierId = Convert.ToInt32(matchedEng["TierId"]);
                            }
                        }
                        else if (lr["ContractPeriodId"] != DBNull.Value)
                        {
                            matchedCpId = Convert.ToInt32(lr["ContractPeriodId"]);
                            cpKey = matchedCpId.Value.ToString();
                        }

                        // 1. PrevLeaves accumulation (PrevFull: StatusValue=0 & LeaveType='Paid', or LeaveType='Paired Paid')
                        if ((val.HasValue && val.Value == 0f && ltype == "Paid") || ltype == "Paired Paid")
                        {
                            if (!histByEmp.ContainsKey(eid)) histByEmp[eid] = new Dictionary<string, double>();
                            if (!histByEmp[eid].ContainsKey(cpKey)) histByEmp[eid][cpKey] = 0.0;
                            histByEmp[eid][cpKey] += 1.0;
                        }

                        // 2. PrevHalfCounts for pairing (within current stint, under same contract period/tier, before firstDay)
                        DateTime stintStart = stintStartByEmp.ContainsKey(eid) ? stintStartByEmp[eid] : new DateTime(1900, 1, 1);
                        if (attDate >= stintStart && attDate < firstDay)
                        {
                            if (ltype == "Carried" || ltype == "Paired Paid" || ltype == "Paired Unpaid" || ltype == "Pending Pairing")
                            {
                                DataRow currEng = currEngByEmp.ContainsKey(eid) ? currEngByEmp[eid] : null;
                                int? currCpId = (currEng != null && currEng["ContractPeriodId"] != DBNull.Value) ? (int?)Convert.ToInt32(currEng["ContractPeriodId"]) : null;
                                int? currTierId = (currEng != null && currEng["TierId"] != DBNull.Value) ? (int?)Convert.ToInt32(currEng["TierId"]) : null;

                                bool isMatch = false;
                                if (matchedCpId.HasValue && currCpId.HasValue && matchedCpId.Value == currCpId.Value)
                                    isMatch = true;
                                else if (!matchedCpId.HasValue && !currCpId.HasValue && matchedTierId.HasValue && currTierId.HasValue && matchedTierId.Value == currTierId.Value)
                                    isMatch = true;

                                if (isMatch)
                                {
                                    if (!prevHalfCounts.ContainsKey(eid)) prevHalfCounts[eid] = new Dictionary<string, int>();
                                    if (!prevHalfCounts[eid].ContainsKey(cpKey)) prevHalfCounts[eid][cpKey] = 0;
                                    prevHalfCounts[eid][cpKey] += 1;
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error resolving past leaves in GetData: " + ex.Message);
            }

            // Batch query ALL EmployeeLeaveCredits in 1 single roundtrip
            Dictionary<string, List<DataRow>> creditsByEmp = new Dictionary<string, List<DataRow>>();
            try
            {
                string allCreditsSql = "SELECT EmpID, ContractPeriodId, Amount, EffectiveDate FROM EmployeeLeaveCredits";
                DataTable dtAllCredits = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), allCreditsSql);
                if (dtAllCredits != null)
                {
                    foreach (DataRow cr in dtAllCredits.Rows)
                    {
                        string cid = cr["EmpID"].ToString();
                        if (!creditsByEmp.ContainsKey(cid)) creditsByEmp[cid] = new List<DataRow>();
                        creditsByEmp[cid].Add(cr);
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error batch fetching leave credits in GetData: " + ex.Message);
            }

            List<object> emps = new List<object>();
            foreach(DataRow dr in dtEmp.Rows)
            {
                string masterId = dr["MasterId"].ToString();
                double initialBalance = dr["LeaveBalance"] != DBNull.Value ? Convert.ToDouble(dr["LeaveBalance"]) : 0.0;
                double prevBalance = dr["PrevLeaveBalance"] != DBNull.Value ? Convert.ToDouble(dr["PrevLeaveBalance"]) : 0.0;
                object currentCpId = dr["CurrentContractPeriodId"];

                // Fetch past contract period from memory dictionary
                int? pastCpId = null;
                if (pastCpByEmp.ContainsKey(masterId))
                {
                    int currCpInt = (currentCpId != null && currentCpId != DBNull.Value) ? Convert.ToInt32(currentCpId) : -1;
                    foreach (var tup in pastCpByEmp[masterId])
                    {
                        if (tup.Item1 != currCpInt)
                        {
                            pastCpId = tup.Item1;
                            break;
                        }
                    }
                }

                double resolvedLeaveBalance = initialBalance;
                double resolvedPrevBalance = prevBalance;
                var creditsList = new List<object>();

                DateTime monthLastDay = new DateTime(year, month + 1, 1).AddMonths(1).AddDays(-1);

                if (creditsByEmp.ContainsKey(masterId))
                {
                    List<DataRow> empCredits = creditsByEmp[masterId];
                    foreach (DataRow cr in empCredits)
                    {
                        creditsList.Add(new {
                            ContractPeriodId = Convert.ToInt32(cr["ContractPeriodId"]),
                            Amount = Convert.ToDouble(cr["Amount"]),
                            EffectiveDate = Convert.ToDateTime(cr["EffectiveDate"]).ToString("yyyy-MM-dd")
                        });
                    }

                    // Calculate current Cp balance active in target month
                    if (currentCpId != DBNull.Value)
                    {
                        int currCpId = Convert.ToInt32(currentCpId);
                        double currSum = 0;
                        bool hasCredits = false;
                        foreach (DataRow cr in empCredits)
                        {
                            if (Convert.ToInt32(cr["ContractPeriodId"]) == currCpId)
                            {
                                hasCredits = true;
                                DateTime effDate = Convert.ToDateTime(cr["EffectiveDate"]);
                                if (effDate <= monthLastDay)
                                {
                                    currSum += Convert.ToDouble(cr["Amount"]);
                                }
                            }
                        }
                        if (hasCredits)
                        {
                            resolvedLeaveBalance = currSum;
                        }
                    }

                    // Calculate past Cp balance active in target month
                    if (pastCpId.HasValue)
                    {
                        double pastSum = 0;
                        bool hasPastCredits = false;
                        foreach (DataRow cr in empCredits)
                        {
                            if (Convert.ToInt32(cr["ContractPeriodId"]) == pastCpId.Value)
                            {
                                hasPastCredits = true;
                                DateTime effDate = Convert.ToDateTime(cr["EffectiveDate"]);
                                if (effDate <= monthLastDay)
                                {
                                    pastSum += Convert.ToDouble(cr["Amount"]);
                                }
                            }
                        }
                        if (hasPastCredits)
                        {
                            resolvedPrevBalance = pastSum;
                        }
                    }
                }

                // Build PrevLeaves dictionary for this employee from memory dictionary
                var prevLeaves = histByEmp.ContainsKey(masterId) ? histByEmp[masterId] : new Dictionary<string, double>();

                // Find active CP ID for the employee in the selected month from memory dictionary
                string activeCpIdStr = "null";
                double activeInitialBalance = resolvedLeaveBalance;
                if (engByEmp.ContainsKey(masterId))
                {
                    var engRows = engByEmp[masterId];
                    DataRow latestEng = null;
                    DateTime maxStart = DateTime.MinValue;
                    foreach (var er in engRows)
                    {
                        DateTime start = Convert.ToDateTime(er["StartDate"]);
                        if (start > maxStart)
                        {
                            maxStart = start;
                            latestEng = er;
                        }
                    }
                    if (latestEng != null && latestEng["ContractPeriodId"] != DBNull.Value)
                    {
                        int cpId = Convert.ToInt32(latestEng["ContractPeriodId"]);
                        activeCpIdStr = cpId.ToString();
                        
                        // Check if it matches current engagement
                        bool isCurrent = false;
                        if (currentCpId != DBNull.Value && Convert.ToInt32(currentCpId) == cpId)
                        {
                            isCurrent = true;
                        }
                        activeInitialBalance = isCurrent ? resolvedLeaveBalance : resolvedPrevBalance;
                    }
                }

                double prevUsed = prevLeaves.ContainsKey(activeCpIdStr) ? prevLeaves[activeCpIdStr] : 0.0;
                double openingBalance = activeInitialBalance - prevUsed;

                emps.Add(new { 
                    MasterId = masterId,
                    ID = dr["ID"].ToString(), 
                    Name = dr["Name"].ToString(), 
                    Dept = dr["Department"].ToString(),
                    Category = dr["Category"].ToString(),
                    TierId = dr["TierId"] != DBNull.Value ? (object)Convert.ToInt32(dr["TierId"]) : null,
                    JoinDate = dr["JoinDate"] != DBNull.Value ? Convert.ToDateTime(dr["JoinDate"]).ToString("yyyy-MM-dd") : null,
                    ResignDate = dr["ResignDate"] != DBNull.Value ? Convert.ToDateTime(dr["ResignDate"]).ToString("yyyy-MM-dd") : null,
                    ContractEndDate = dr["ContractEndDate"] != DBNull.Value ? Convert.ToDateTime(dr["ContractEndDate"]).ToString("yyyy-MM-dd") : null,
                    LeaveBalance = activeInitialBalance,
                    PrevLeaveBalance = resolvedPrevBalance,
                    CurrentLeaveBalance = resolvedLeaveBalance,
                    CurrentContractPeriodId = currentCpId != DBNull.Value ? (object)Convert.ToInt32(currentCpId) : null,
                    OpeningBalance = openingBalance,
                    PrevLeaves = prevLeaves,
                    PrevHalfCounts = prevHalfCounts.ContainsKey(masterId) ? prevHalfCounts[masterId] : new Dictionary<string, int>(),
                    Credits = creditsList
                });
            }

            string attQuery = @"
                SELECT EmpID, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks
                FROM Attendance 
                WHERE Year = :Year AND Month = :Month";
            DataTable dtAtt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), attQuery,
                new OracleParameter("Year", year),
                new OracleParameter("Month", month));

            // Structure: { EmpID: { Day: { Val, Holiday, Leave, AutoSat, Remarks, IsDraft, EnteredBy, EnteredAt, LastEditedBy, LastEditedAt } } }
            Dictionary<string, Dictionary<string, object>> attDict = new Dictionary<string, Dictionary<string, object>>();
            foreach(DataRow dr in dtAtt.Rows)
            {
                string empId = dr["EmpID"].ToString();
                int day = Convert.ToInt32(dr["Day"]);
                float? val = dr["StatusValue"] == DBNull.Value ? (float?)null : Convert.ToSingle(dr["StatusValue"]);
                bool isHoliday = Convert.ToInt32(dr["IsHoliday"]) == 1;
                bool autoSat = dr.Table.Columns.Contains("AutoSat") && dr["AutoSat"] != DBNull.Value ? Convert.ToInt32(dr["AutoSat"]) == 1 : false;
                string leave = dr["LeaveType"].ToString();
                string remarks = dr.Table.Columns.Contains("Remarks") && dr["Remarks"] != DBNull.Value ? dr["Remarks"].ToString() : "";

                if (!attDict.ContainsKey(empId))
                    attDict[empId] = new Dictionary<string, object>();

                attDict[empId][day.ToString()] = new { 
                    Val = val, 
                    Holiday = isHoliday, 
                    Leave = leave, 
                    AutoSat = autoSat, 
                    Remarks = remarks,
                    IsDraft = false,
                    EnteredBy = "",
                    EnteredAt = "",
                    LastEditedBy = "",
                    LastEditedAt = ""
                };
            }

            // Auto-propagate any declared month-level holidays across all visible employees (including newly added employees)
            var monthHolidays = new Dictionary<int, string>();
            foreach (DataRow dr in dtAtt.Rows)
            {
                if (dr["IsHoliday"] != DBNull.Value && Convert.ToInt32(dr["IsHoliday"]) == 1)
                {
                    int day = Convert.ToInt32(dr["Day"]);
                    string rem = dr.Table.Columns.Contains("Remarks") && dr["Remarks"] != DBNull.Value ? dr["Remarks"].ToString() : "";
                    if (!monthHolidays.ContainsKey(day) || (string.IsNullOrEmpty(monthHolidays[day]) && !string.IsNullOrEmpty(rem)))
                    {
                        monthHolidays[day] = rem;
                    }
                }
            }

            if (monthHolidays.Count > 0)
            {
                foreach (string empId in empIdList)
                {
                    if (!attDict.ContainsKey(empId))
                        attDict[empId] = new Dictionary<string, object>();

                    foreach (var hol in monthHolidays)
                    {
                        string dayKey = hol.Key.ToString();
                        if (!attDict[empId].ContainsKey(dayKey))
                        {
                            attDict[empId][dayKey] = new { 
                                Val = (float?)null, 
                                Holiday = true, 
                                Leave = "", 
                                AutoSat = false, 
                                Remarks = hol.Value,
                                IsDraft = false,
                                EnteredBy = "",
                                EnteredAt = "",
                                LastEditedBy = "",
                                LastEditedAt = ""
                            };
                        }
                        else
                        {
                            object existingObj = attDict[empId][dayKey];
                            var valProp = existingObj.GetType().GetProperty("Val");
                            var holProp = existingObj.GetType().GetProperty("Holiday");
                            var leaveProp = existingObj.GetType().GetProperty("Leave");

                            object existingVal = valProp != null ? valProp.GetValue(existingObj) : null;
                            bool existingHol = holProp != null && (bool)holProp.GetValue(existingObj);
                            string existingLeave = leaveProp != null ? (leaveProp.GetValue(existingObj) as string) : "";

                            if (!existingHol && existingVal == null && string.IsNullOrEmpty(existingLeave))
                            {
                                attDict[empId][dayKey] = new { 
                                    Val = (float?)null, 
                                    Holiday = true, 
                                    Leave = "", 
                                    AutoSat = false, 
                                    Remarks = hol.Value,
                                    IsDraft = false,
                                    EnteredBy = "",
                                    EnteredAt = "",
                                    LastEditedBy = "",
                                    LastEditedAt = ""
                                };
                            }
                        }
                    }
                }
            }

            // Overlay pending drafts from AttendanceDraft (POC, Sub User, and Super Admin view)
            int pendingDraftCount = 0;
            Dictionary<string, Dictionary<string, object>> draftDict = new Dictionary<string, Dictionary<string, object>>();
            HashSet<string> visibleEmpIds = new HashSet<string>(empIdList, StringComparer.OrdinalIgnoreCase);
            if (role != 1)
            {
                try
                {
                    string draftQuery = @"
                        SELECT EmpID, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks,
                               EnteredByPCNO, EnteredAt, LastEditedByPCNO, LastEditedAt
                        FROM AttendanceDraft
                        WHERE Year = :Year AND Month = :Month";
                    DataTable dtDraft = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), draftQuery,
                        new OracleParameter("Year", year),
                        new OracleParameter("Month", month));

                    if (dtDraft != null)
                    {
                        foreach (DataRow dr in dtDraft.Rows)
                        {
                            string empId = dr["EmpID"].ToString();
                            int day = Convert.ToInt32(dr["Day"]);
                            float? val = dr["StatusValue"] == DBNull.Value ? (float?)null : Convert.ToSingle(dr["StatusValue"]);
                            bool isHoliday = Convert.ToInt32(dr["IsHoliday"]) == 1;
                            bool autoSat = dr.Table.Columns.Contains("AutoSat") && dr["AutoSat"] != DBNull.Value ? Convert.ToInt32(dr["AutoSat"]) == 1 : false;
                            string leave = dr["LeaveType"].ToString();
                            string remarks = dr.Table.Columns.Contains("Remarks") && dr["Remarks"] != DBNull.Value ? dr["Remarks"].ToString() : "";
                            string enteredBy = dr.Table.Columns.Contains("EnteredByPCNO") && dr["EnteredByPCNO"] != DBNull.Value ? dr["EnteredByPCNO"].ToString() : "";
                            string enteredAt = dr.Table.Columns.Contains("EnteredAt") && dr["EnteredAt"] != DBNull.Value ? Convert.ToDateTime(dr["EnteredAt"]).ToString("yyyy-MM-dd HH:mm") : "";
                            string lastEditedBy = dr.Table.Columns.Contains("LastEditedByPCNO") && dr["LastEditedByPCNO"] != DBNull.Value ? dr["LastEditedByPCNO"].ToString() : "";
                            string lastEditedAt = dr.Table.Columns.Contains("LastEditedAt") && dr["LastEditedAt"] != DBNull.Value ? Convert.ToDateTime(dr["LastEditedAt"]).ToString("yyyy-MM-dd HH:mm") : "";

                            // Check if this cell already has a saved live record in Attendance (main table)
                            bool hasLiveRecord = false;
                            if (attDict.ContainsKey(empId) && attDict[empId].ContainsKey(day.ToString()))
                            {
                                object existingObj = attDict[empId][day.ToString()];
                                var valProp = existingObj.GetType().GetProperty("Val");
                                var holProp = existingObj.GetType().GetProperty("Holiday");
                                var leaveProp = existingObj.GetType().GetProperty("Leave");

                                object existingVal = valProp != null ? valProp.GetValue(existingObj) : null;
                                bool existingHol = holProp != null && (bool)holProp.GetValue(existingObj);
                                string existingLeave = leaveProp != null ? (leaveProp.GetValue(existingObj) as string) : "";

                                // If the main Attendance table has a saved status (Val != null, Leave, or Holiday):
                                if (existingVal != null || existingHol || (!string.IsNullOrEmpty(existingLeave) && existingLeave.Trim() != ""))
                                {
                                    hasLiveRecord = true;
                                }
                            }

                            // If the main live table has data, or it's a holiday, the main table's data ALWAYS takes precedence
                            if (isHoliday || hasLiveRecord)
                            {
                                continue; // Preserve live entry intact; ignore any obsolete draft for this cell
                            }

                            var draftCellObj = new { 
                                Val = val, 
                                Holiday = false, 
                                Leave = leave, 
                                AutoSat = autoSat, 
                                Remarks = remarks,
                                IsDraft = true,
                                EnteredBy = enteredBy,
                                EnteredAt = enteredAt,
                                LastEditedBy = lastEditedBy,
                                LastEditedAt = lastEditedAt
                            };

                            if (!draftDict.ContainsKey(empId))
                                draftDict[empId] = new Dictionary<string, object>();
                            draftDict[empId][day.ToString()] = draftCellObj;

                            // For POC (role == 0) and SubUser, merge draft directly into attDict by default
                            // For Super Admin (role == 4), drafts are kept in draftDict and toggled separately on frontend
                            if (role != 4)
                            {
                                if (!attDict.ContainsKey(empId))
                                    attDict[empId] = new Dictionary<string, object>();
                                attDict[empId][day.ToString()] = draftCellObj;
                            }

                            if (visibleEmpIds.Contains(empId) && (val != null || !string.IsNullOrEmpty(leave)))
                            {
                                pendingDraftCount++;
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("Error loading AttendanceDraft in GetData: " + ex.Message);
                }
            }

            // Fetch previous month trailing data for calcSat
            int prevMonth = month == 0 ? 11 : month - 1;
            int prevYear = month == 0 ? year - 1 : year;
            
            string prevAttQuery = "SELECT EmpID, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks FROM Attendance WHERE Year = :PYear AND Month = :PMonth AND Day >= 24";
            DataTable dtPrevAtt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), prevAttQuery,
                new OracleParameter("PYear", prevYear),
                new OracleParameter("PMonth", prevMonth));

            Dictionary<string, Dictionary<string, object>> prevAttDict = new Dictionary<string, Dictionary<string, object>>();
            foreach(DataRow dr in dtPrevAtt.Rows)
            {
                string empId = dr["EmpID"].ToString();
                int day = Convert.ToInt32(dr["Day"]);
                float? val = dr["StatusValue"] == DBNull.Value ? (float?)null : Convert.ToSingle(dr["StatusValue"]);
                bool isHoliday = Convert.ToInt32(dr["IsHoliday"]) == 1;
                bool autoSat = dr.Table.Columns.Contains("AutoSat") && dr["AutoSat"] != DBNull.Value ? Convert.ToInt32(dr["AutoSat"]) == 1 : false;
                string leave = dr["LeaveType"].ToString();
                string remarks = dr.Table.Columns.Contains("Remarks") && dr["Remarks"] != DBNull.Value ? dr["Remarks"].ToString() : "";

                if (!prevAttDict.ContainsKey(empId))
                    prevAttDict[empId] = new Dictionary<string, object>();

                prevAttDict[empId][day.ToString()] = new { Val = val, Holiday = isHoliday, Leave = leave, AutoSat = autoSat, Remarks = remarks };
            }

            // Fetch future carried/paired leaves using fast indexed query + memory resolution
            Dictionary<string, List<object>> futureCarried = new Dictionary<string, List<object>>();
            try
            {
                string futQuery = @"
                    SELECT a.EmpID, a.Year, a.Month, a.Day, a.StatusValue, a.LeaveType, a.ContractPeriodId
                    FROM Attendance a
                    WHERE ((a.Year > :TY) OR (a.Year = :TY AND a.Month > :TM))
                      AND a.EmpID NOT LIKE 'GLOBAL%'
                      AND a.Day > 0
                      AND a.LeaveType IN ('Carried', 'Paired Paid', 'Paired Unpaid', 'Pending Pairing')
                    ORDER BY a.Year ASC, a.Month ASC, a.Day ASC";

                DataTable dtFut = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), futQuery,
                    new OracleParameter("TY", year),
                    new OracleParameter("TM", month));

                if (dtFut != null)
                {
                    foreach (DataRow row in dtFut.Rows)
                    {
                        string id = row["EmpID"].ToString();
                        int y = Convert.ToInt32(row["Year"]);
                        int m = Convert.ToInt32(row["Month"]);
                        int d = Convert.ToInt32(row["Day"]);
                        float? val = row["StatusValue"] == DBNull.Value ? (float?)null : Convert.ToSingle(row["StatusValue"]);
                        string leave = row["LeaveType"] == DBNull.Value ? "" : row["LeaveType"].ToString();

                        DateTime attDate;
                        try { attDate = new DateTime(y, m + 1, d); } catch { continue; }
                        if (attDate <= lastDay) continue;

                        DataRow matchedEng = null;
                        if (engByEmp.ContainsKey(id))
                        {
                            foreach (DataRow er in engByEmp[id])
                            {
                                DateTime sDate = Convert.ToDateTime(er["StartDate"]);
                                DateTime? eDate = er["EndDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(er["EndDate"]) : null;
                                if (attDate >= sDate && (!eDate.HasValue || attDate <= eDate.Value))
                                {
                                    matchedEng = er;
                                    break;
                                }
                            }
                        }

                        int? cpIdVal = null;
                        int? matchedTierId = null;
                        if (matchedEng != null)
                        {
                            if (matchedEng["ContractPeriodId"] != DBNull.Value) cpIdVal = Convert.ToInt32(matchedEng["ContractPeriodId"]);
                            if (matchedEng["TierId"] != DBNull.Value) matchedTierId = Convert.ToInt32(matchedEng["TierId"]);
                        }
                        else if (row["ContractPeriodId"] != DBNull.Value)
                        {
                            cpIdVal = Convert.ToInt32(row["ContractPeriodId"]);
                        }

                        DataRow currEng = currEngByEmp.ContainsKey(id) ? currEngByEmp[id] : null;
                        int? currCpId = (currEng != null && currEng["ContractPeriodId"] != DBNull.Value) ? (int?)Convert.ToInt32(currEng["ContractPeriodId"]) : null;
                        int? currTierId = (currEng != null && currEng["TierId"] != DBNull.Value) ? (int?)Convert.ToInt32(currEng["TierId"]) : null;

                        bool isMatch = false;
                        if (cpIdVal.HasValue && currCpId.HasValue && cpIdVal.Value == currCpId.Value)
                            isMatch = true;
                        else if (!cpIdVal.HasValue && !currCpId.HasValue && matchedTierId.HasValue && currTierId.HasValue && matchedTierId.Value == currTierId.Value)
                            isMatch = true;

                        if (isMatch)
                        {
                            if (!futureCarried.ContainsKey(id))
                            {
                                futureCarried[id] = new List<object>();
                            }
                            futureCarried[id].Add(new { Year = y, Month = m, Day = d, Val = val, Leave = leave, ContractPeriodId = (object)cpIdVal });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error fetching future carried leaves: " + ex.Message);
            }

            List<string> recentRemarks = GetCachedRecentRemarks();

            // Load POC/SubUser edit remarks for this month (grouped by EmpID > Day > list of entries)
            // Structure: { "10001": { "5": [ { Remark, CreatedBy, CreatedAt, CreatedByRole } ] } }
            Dictionary<string, Dictionary<string, List<object>>> pocEditRemarks = new Dictionary<string, Dictionary<string, List<object>>>();
            try
            {
                EnsureAttPocEditRemarksTable();
                string pocQuery = "SELECT EmpID, Day, Remark, CreatedBy, CreatedAt, NVL(CreatedByRole, 'POC') AS CreatedByRole FROM AttPocEditRemarks WHERE Year = :Year AND Month = :Month ORDER BY CreatedAt ASC";
                DataTable dtPoc = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), pocQuery,
                    new OracleParameter("Year", year),
                    new OracleParameter("Month", month));
                foreach (DataRow row in dtPoc.Rows)
                {
                    string eid = row["EmpID"].ToString();
                    string dayKey = row["Day"].ToString();
                    string remark = row["Remark"].ToString();
                    string createdBy = row["CreatedBy"].ToString();
                    string createdAt = row["CreatedAt"] != DBNull.Value ? Convert.ToDateTime(row["CreatedAt"]).ToString("yyyy-MM-dd HH:mm") : "";
                    string createdByRole = row.Table.Columns.Contains("CreatedByRole") && row["CreatedByRole"] != DBNull.Value ? row["CreatedByRole"].ToString() : "POC";
                    if (!pocEditRemarks.ContainsKey(eid)) pocEditRemarks[eid] = new Dictionary<string, List<object>>();
                    if (!pocEditRemarks[eid].ContainsKey(dayKey)) pocEditRemarks[eid][dayKey] = new List<object>();
                    pocEditRemarks[eid][dayKey].Add(new { Remark = remark, CreatedBy = createdBy, CreatedAt = createdAt, CreatedByRole = createdByRole });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error fetching POC edit remarks: " + ex.Message);
            }

            string currentRoleMode = HttpContext.Current.Session["RoleMode"]?.ToString() ?? (role == 6 ? "SubUser" : role == 4 ? "SuperAdmin" : role == 1 ? "PrimaryAdmin" : "RegularUser");

            var result = new { 
                Employees = emps, 
                Attendance = attDict, 
                DraftAttendance = draftDict,
                PrevAttendance = prevAttDict, 
                Engagements = engagements, 
                FutureCarried = futureCarried, 
                RecentRemarks = recentRemarks, 
                EditDaysAllowed = editDaysAllowed, 
                EditMode = editMode, 
                PocEditRemarks = pocEditRemarks,
                IsRestricted = isViewRestricted,
                MinViewDate = minViewDateStr,
                MaxViewDate = maxViewDateStr,
                ViewRestrictionDesc = viewRestrictionDesc,
                PendingDraftCount = pendingDraftCount,
                CurrentRoleMode = currentRoleMode
            };
            return new JavaScriptSerializer().Serialize(result);
        }

        [WebMethod]
        public static string SaveData(int year, int month, string category, string data, string futureUpdates = null, string pocEditRemarks = null)
        {
            EnsureGlobalEmployeesExist();
            var dict = new JavaScriptSerializer().Deserialize<Dictionary<string, Dictionary<string, Dictionary<string, object>>>>(data);
            var futDict = string.IsNullOrEmpty(futureUpdates) || futureUpdates == "{}" ? null : new JavaScriptSerializer().Deserialize<Dictionary<string, Dictionary<string, Dictionary<string, object>>>>(futureUpdates);

            string validationError;
            if (!ValidateLeaveBalances(DBHelper.GetAttendanceDBConnection(), dict, futDict, year, month, out validationError))
            {
                var errObj = new { status = "error", message = validationError };
                return new JavaScriptSerializer().Serialize(errObj);
            }

            int role = Convert.ToInt32(HttpContext.Current.Session["Role"] ?? 0);
            string roleMode = HttpContext.Current.Session["RoleMode"]?.ToString() ?? (role == 6 ? "SubUser" : "RegularUser");
            string sessionPcno = HttpContext.Current.Session["PCNO"]?.ToString() ?? "Unknown";
            DateTime today = DateTime.Today;

            int editDaysAllowed = 0;
            int editMode = 0;
            if (role != 1 && role != 4)
            {
                string pcno = HttpContext.Current.Session["PCNO"]?.ToString() ?? "";
                var viewInfo = DBHelper.GetPocViewRestriction(pcno, "Attendance", category);
                if (viewInfo.IsRestricted && !viewInfo.IsMonthAllowed(year, month + 1))
                {
                    var errObj = new { status = "error", message = $"Cannot save attendance: Access to {new DateTime(year, month + 1, 1):MMMM yyyy} is restricted by your administrator ({viewInfo.Description})." };
                    return new JavaScriptSerializer().Serialize(errObj);
                }

                DataTable dtMode = null;
                if (!string.IsNullOrEmpty(category) && category != "All")
                {
                    int catTierId;
                    if (int.TryParse(category, out catTierId))
                    {
                        string qCat = @"
                            SELECT COALESCE(mc.EditDaysAllowed, 0) AS EditDaysAllowed,
                                   COALESCE(mc.EditMode, 0) AS EditMode
                            FROM Tiers t 
                            JOIN MainCategory mc ON t.MainCategoryId = mc.Id 
                            WHERE t.Id = :TierId";
                        dtMode = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), qCat, new OracleParameter("TierId", catTierId));
                    }
                }

                if (dtMode == null || dtMode.Rows.Count == 0)
                {
                    string qDays = @"
                        SELECT COALESCE(MAX(mc.EditDaysAllowed), 0) AS EditDaysAllowed,
                               COALESCE(MAX(mc.EditMode), 0) AS EditMode
                        FROM UserTiers ut 
                        JOIN Tiers t ON ut.TierId = t.Id 
                        JOIN MainCategory mc ON t.MainCategoryId = mc.Id 
                        WHERE ut.PCNO = :PCNO
                           OR ut.PCNO IN (SELECT AnchorPocPCNO FROM SubUserAnchor WHERE SubUserPCNO = :PCNO)";
                    dtMode = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), qDays, new OracleParameter("PCNO", pcno));
                }

                if (dtMode != null && dtMode.Rows.Count > 0 && dtMode.Rows[0]["EditDaysAllowed"] != DBNull.Value)
                {
                    editDaysAllowed = Convert.ToInt32(dtMode.Rows[0]["EditDaysAllowed"]);
                    editMode = Convert.ToInt32(dtMode.Rows[0]["EditMode"]);
                }
            }

            DateTime minAllowedDate = today.AddDays(-editDaysAllowed);
            string connStr = DBHelper.GetAttendanceDBConnection();

            using (OracleConnection conn = new OracleConnection(connStr))
            {
                conn.Open();
                using (OracleTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        if (roleMode == "SubUser")
                        {
                            // 1. Guard against modifying cells that already have submitted live attendance or holidays
                            string liveCheckSql = @"
                                SELECT EmpID, Day FROM Attendance 
                                WHERE Year = :Year AND Month = :Month AND (StatusValue IS NOT NULL OR IsHoliday = 1)";
                            HashSet<string> liveSubmittedCells = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                            using (OracleCommand chkCmd = new OracleCommand(liveCheckSql, conn))
                            {
                                chkCmd.Transaction = trans;
                                chkCmd.Parameters.Add(new OracleParameter("Year", year));
                                chkCmd.Parameters.Add(new OracleParameter("Month", month));
                                using (OracleDataReader rdr = chkCmd.ExecuteReader())
                                {
                                    while (rdr.Read())
                                    {
                                        liveSubmittedCells.Add(rdr["EmpID"].ToString() + "_" + rdr["Day"].ToString());
                                    }
                                }
                            }

                            // Query existing draft cells so we know if a cell is being created or re-edited
                            string draftCheckSql = "SELECT EmpID, Day FROM AttendanceDraft WHERE Year = :Year AND Month = :Month";
                            HashSet<string> draftExistingCells = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                            using (OracleCommand chkDraftCmd = new OracleCommand(draftCheckSql, conn))
                            {
                                chkDraftCmd.Transaction = trans;
                                chkDraftCmd.Parameters.Add(new OracleParameter("Year", year));
                                chkDraftCmd.Parameters.Add(new OracleParameter("Month", month));
                                using (OracleDataReader rdr = chkDraftCmd.ExecuteReader())
                                {
                                    while (rdr.Read())
                                    {
                                        draftExistingCells.Add(rdr["EmpID"].ToString() + "_" + rdr["Day"].ToString());
                                    }
                                }
                            }

                            string mergeDraftSql = @"
                                MERGE INTO AttendanceDraft t
                                USING (
                                    SELECT :EmpID as EmpID, :Year as Year, :Month as Month, :Day as Day,
                                           :Val as StatusValue, :Holiday as IsHoliday, :Leave as LeaveType,
                                           :AutoSat as AutoSat, :Remarks as Remarks,
                                           :PCNO as PCNO, SYSTIMESTAMP as TS
                                    FROM DUAL
                                ) s
                                ON (t.EmpID = s.EmpID AND t.Year = s.Year AND t.Month = s.Month AND t.Day = s.Day)
                                WHEN MATCHED THEN
                                  UPDATE SET t.StatusValue = s.StatusValue, t.IsHoliday = s.IsHoliday, t.LeaveType = s.LeaveType,
                                             t.AutoSat = s.AutoSat, t.Remarks = s.Remarks,
                                             t.LastEditedByPCNO = s.PCNO, t.LastEditedAt = s.TS
                                WHEN NOT MATCHED THEN
                                  INSERT (EmpID, Year, Month, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks, EnteredByPCNO, EnteredAt, LastEditedByPCNO, LastEditedAt)
                                  VALUES (s.EmpID, s.Year, s.Month, s.Day, s.StatusValue, s.IsHoliday, s.LeaveType, s.AutoSat, s.Remarks, s.PCNO, s.TS, s.PCNO, s.TS)";

                            string delDraftSql = "DELETE FROM AttendanceDraft WHERE EmpID = :EmpID AND Year = :Year AND Month = :Month AND Day = :Day";

                            using (OracleCommand draftCmd = new OracleCommand(mergeDraftSql, conn))
                            using (OracleCommand delDraftCmd = new OracleCommand(delDraftSql, conn))
                            {
                                draftCmd.Transaction = trans;
                                var pEmpID = draftCmd.Parameters.Add("EmpID", OracleDbType.Varchar2);
                                var pYear = draftCmd.Parameters.Add("Year", OracleDbType.Int32);
                                var pMonth = draftCmd.Parameters.Add("Month", OracleDbType.Int32);
                                var pDay = draftCmd.Parameters.Add("Day", OracleDbType.Int32);
                                var pVal = draftCmd.Parameters.Add("Val", OracleDbType.Single);
                                var pHoliday = draftCmd.Parameters.Add("Holiday", OracleDbType.Int32);
                                var pLeave = draftCmd.Parameters.Add("Leave", OracleDbType.Varchar2);
                                var pAutoSat = draftCmd.Parameters.Add("AutoSat", OracleDbType.Int32);
                                var pRemarks = draftCmd.Parameters.Add("Remarks", OracleDbType.Varchar2);
                                var pPCNO = draftCmd.Parameters.Add("PCNO", OracleDbType.Varchar2);

                                delDraftCmd.Transaction = trans;
                                var pDelEmpID = delDraftCmd.Parameters.Add("EmpID", OracleDbType.Varchar2);
                                var pDelYear = delDraftCmd.Parameters.Add("Year", OracleDbType.Int32);
                                var pDelMonth = delDraftCmd.Parameters.Add("Month", OracleDbType.Int32);
                                var pDelDay = delDraftCmd.Parameters.Add("Day", OracleDbType.Int32);

                                foreach (var empKvp in dict)
                                {
                                    string empId = empKvp.Key;
                                    if (empId.StartsWith("GLOBAL", StringComparison.OrdinalIgnoreCase))
                                    {
                                        continue; // Sub users do not manage global adjustment records
                                    }

                                    foreach (var dayKvp in empKvp.Value)
                                    {
                                        int day = Convert.ToInt32(dayKvp.Key);
                                        if (day <= 0) continue;
                                        string cellKey = empId + "_" + day;

                                        var cell = dayKvp.Value;
                                        object val = cell.ContainsKey("Val") && cell["Val"] != null ? cell["Val"] : DBNull.Value;
                                        bool isHoliday = cell.ContainsKey("Holiday") && cell["Holiday"] != null ? Convert.ToBoolean(cell["Holiday"]) : false;
                                        string leave = cell.ContainsKey("Leave") && cell["Leave"] != null ? cell["Leave"].ToString() : "";
                                        bool autoSat = cell.ContainsKey("AutoSat") && cell["AutoSat"] != null ? Convert.ToBoolean(cell["AutoSat"]) : false;
                                        string remarks = cell.ContainsKey("Remarks") && cell["Remarks"] != null ? cell["Remarks"].ToString() : "";

                                        // Sub Users must never save holidays as drafts — holidays are live calendar declarations.
                                        if (isHoliday)
                                        {
                                            if (draftExistingCells.Contains(cellKey))
                                            {
                                                pDelEmpID.Value = empId;
                                                pDelYear.Value = year;
                                                pDelMonth.Value = month;
                                                pDelDay.Value = day;
                                                delDraftCmd.ExecuteNonQuery();
                                            }
                                            continue;
                                        }

                                        // Sub User cannot overwrite submitted live cells — skip them silently
                                        if (liveSubmittedCells.Contains(cellKey) && !draftExistingCells.Contains(cellKey))
                                        {
                                            continue;
                                        }

                                        if (role != 1 && role != 4)
                                        {
                                            try
                                            {
                                                DateTime checkDate = new DateTime(year, month + 1, day);
                                                if (editMode == 1)
                                                {
                                                    if (checkDate > today || checkDate.Year != today.Year || checkDate.Month != today.Month) continue;
                                                }
                                                else if (editMode == 2)
                                                {
                                                    DateTime prevMonth = today.AddMonths(-1);
                                                    bool isCurrentMonth = (checkDate.Year == today.Year && checkDate.Month == today.Month);
                                                    int graceCutoffDay = editDaysAllowed > 0 ? editDaysAllowed : 3;
                                                    bool isPrevMonthAllowed = (checkDate.Year == prevMonth.Year && checkDate.Month == prevMonth.Month && today.Day <= graceCutoffDay);

                                                    if ((!isCurrentMonth && !isPrevMonthAllowed) || checkDate > today) continue;
                                                }
                                                else
                                                {
                                                    if (checkDate > today || checkDate < minAllowedDate) continue;
                                                }
                                            }
                                            catch { continue; }
                                        }

                                        bool hasContent = (val != DBNull.Value) || !string.IsNullOrEmpty(leave) || !string.IsNullOrEmpty(remarks);

                                        if (!hasContent)
                                        {
                                            if (draftExistingCells.Contains(cellKey))
                                            {
                                                // If draft cell was cleared by user, delete from AttendanceDraft
                                                pDelEmpID.Value = empId;
                                                pDelYear.Value = year;
                                                pDelMonth.Value = month;
                                                pDelDay.Value = day;
                                                delDraftCmd.ExecuteNonQuery();
                                            }
                                            continue;
                                        }

                                        pEmpID.Value = empId;
                                        pYear.Value = year;
                                        pMonth.Value = month;
                                        pDay.Value = day;
                                        pVal.Value = val != DBNull.Value ? (object)Convert.ToSingle(val) : DBNull.Value;
                                        pHoliday.Value = 0;
                                        pLeave.Value = leave ?? "";
                                        pAutoSat.Value = autoSat ? 1 : 0;
                                        pRemarks.Value = remarks ?? "";
                                        pPCNO.Value = sessionPcno;

                                        draftCmd.ExecuteNonQuery();
                                    }
                                }
                            }

                            // Save remarks with CreatedByRole = 'SubUser'
                            if (!string.IsNullOrEmpty(pocEditRemarks) && pocEditRemarks != "{}" && pocEditRemarks != "null")
                            {
                                EnsureAttPocEditRemarksTable();
                                var pocDict = new JavaScriptSerializer().Deserialize<Dictionary<string, Dictionary<string, List<string>>>>(pocEditRemarks);
                                string insQuery = @"INSERT INTO AttPocEditRemarks (EmpID, Year, Month, Day, RemarkType, Remark, CreatedBy, CreatedByRole) 
                                    VALUES (:EmpID, :Year, :Month, :Day, 'SubUserDraftEdit', :Remark, :CreatedBy, 'SubUser')";

                                using (OracleCommand pocCmd = new OracleCommand(insQuery, conn))
                                {
                                    pocCmd.Transaction = trans;
                                    var pPocEmpID = pocCmd.Parameters.Add("EmpID", OracleDbType.Varchar2);
                                    var pPocYear = pocCmd.Parameters.Add("Year", OracleDbType.Int32);
                                    var pPocMonth = pocCmd.Parameters.Add("Month", OracleDbType.Int32);
                                    var pPocDay = pocCmd.Parameters.Add("Day", OracleDbType.Int32);
                                    var pPocRemark = pocCmd.Parameters.Add("Remark", OracleDbType.Varchar2);
                                    var pPocCreatedBy = pocCmd.Parameters.Add("CreatedBy", OracleDbType.Varchar2);

                                    foreach (var empKvp in pocDict)
                                    {
                                        string eid = empKvp.Key;
                                        foreach (var dayKvp in empKvp.Value)
                                        {
                                            int d = Convert.ToInt32(dayKvp.Key);
                                            foreach (string remark in dayKvp.Value)
                                            {
                                                if (string.IsNullOrWhiteSpace(remark)) continue;
                                                pPocEmpID.Value = eid;
                                                pPocYear.Value = year;
                                                pPocMonth.Value = month;
                                                pPocDay.Value = d;
                                                pPocRemark.Value = remark;
                                                pPocCreatedBy.Value = sessionPcno;

                                                pocCmd.ExecuteNonQuery();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        else
                        {
                            // --- REGULAR USER (POC) or ADMIN MODE ---
                            // Check existing draft cells
                            string draftCheckSql = "SELECT EmpID, Day FROM AttendanceDraft WHERE Year = :Year AND Month = :Month";
                            HashSet<string> draftExistingCells = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                            using (OracleCommand chkDraftCmd = new OracleCommand(draftCheckSql, conn))
                            {
                                chkDraftCmd.Transaction = trans;
                                chkDraftCmd.Parameters.Add(new OracleParameter("Year", year));
                                chkDraftCmd.Parameters.Add(new OracleParameter("Month", month));
                                using (OracleDataReader rdr = chkDraftCmd.ExecuteReader())
                                {
                                    while (rdr.Read())
                                    {
                                        draftExistingCells.Add(rdr["EmpID"].ToString() + "_" + rdr["Day"].ToString());
                                    }
                                }
                            }

                            // Check existing live cells (for POC validation)
                            string liveCheckSql = "SELECT EmpID, Day FROM Attendance WHERE Year = :Year AND Month = :Month AND (StatusValue IS NOT NULL OR IsHoliday = 1)";
                            HashSet<string> liveExistingCells = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                            using (OracleCommand chkLiveCmd = new OracleCommand(liveCheckSql, conn))
                            {
                                chkLiveCmd.Transaction = trans;
                                chkLiveCmd.Parameters.Add(new OracleParameter("Year", year));
                                chkLiveCmd.Parameters.Add(new OracleParameter("Month", month));
                                using (OracleDataReader rdr = chkLiveCmd.ExecuteReader())
                                {
                                    while (rdr.Read())
                                    {
                                        liveExistingCells.Add(rdr["EmpID"].ToString() + "_" + rdr["Day"].ToString());
                                    }
                                }
                            }

                            // 1. Live Attendance MERGE command
                            string mergeSql = @"
                                MERGE INTO Attendance t
                                USING (
                                    SELECT :EmpID as EmpID, :Year as Year, :Month as Month, :Day as Day,
                                           :Val as StatusValue, :Holiday as IsHoliday, :Leave as LeaveType,
                                           :AutoSat as AutoSat, :Remarks as Remarks
                                    FROM DUAL
                                ) s
                                ON (t.EmpID = s.EmpID AND t.Year = s.Year AND t.Month = s.Month AND t.Day = s.Day)
                                WHEN MATCHED THEN
                                  UPDATE SET t.StatusValue = s.StatusValue, t.IsHoliday = s.IsHoliday, t.LeaveType = s.LeaveType,
                                             t.AutoSat = s.AutoSat, t.Remarks = s.Remarks
                                WHEN NOT MATCHED THEN
                                  INSERT (EmpID, Year, Month, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks)
                                  VALUES (s.EmpID, s.Year, s.Month, s.Day, s.StatusValue, s.IsHoliday, s.LeaveType, s.AutoSat, s.Remarks)";

                            // 2. Draft Attendance MERGE command (if POC is saving edits to an unsubmitted draft cell)
                            string mergeDraftSql = @"
                                MERGE INTO AttendanceDraft t
                                USING (
                                    SELECT :EmpID as EmpID, :Year as Year, :Month as Month, :Day as Day,
                                           :Val as StatusValue, :Holiday as IsHoliday, :Leave as LeaveType,
                                           :AutoSat as AutoSat, :Remarks as Remarks,
                                           :PCNO as PCNO, SYSTIMESTAMP as TS
                                    FROM DUAL
                                ) s
                                ON (t.EmpID = s.EmpID AND t.Year = s.Year AND t.Month = s.Month AND t.Day = s.Day)
                                WHEN MATCHED THEN
                                  UPDATE SET t.StatusValue = s.StatusValue, t.IsHoliday = s.IsHoliday, t.LeaveType = s.LeaveType,
                                             t.AutoSat = s.AutoSat, t.Remarks = s.Remarks,
                                             t.LastEditedByPCNO = s.PCNO, t.LastEditedAt = s.TS
                                WHEN NOT MATCHED THEN
                                  INSERT (EmpID, Year, Month, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks, EnteredByPCNO, EnteredAt, LastEditedByPCNO, LastEditedAt)
                                  VALUES (s.EmpID, s.Year, s.Month, s.Day, s.StatusValue, s.IsHoliday, s.LeaveType, s.AutoSat, s.Remarks, s.PCNO, s.TS, s.PCNO, s.TS)";

                            // 3. Draft Attendance DELETE command (for Admins saving to live table)
                            string delDraftSql = "DELETE FROM AttendanceDraft WHERE EmpID = :EmpID AND Year = :Year AND Month = :Month AND Day = :Day";

                            using (OracleCommand mergeCmd = new OracleCommand(mergeSql, conn))
                            using (OracleCommand draftCmd = new OracleCommand(mergeDraftSql, conn))
                            using (OracleCommand delDraftCmd = new OracleCommand(delDraftSql, conn))
                            {
                                mergeCmd.Transaction = trans;
                                var pEmpID = mergeCmd.Parameters.Add("EmpID", OracleDbType.Varchar2);
                                var pYear = mergeCmd.Parameters.Add("Year", OracleDbType.Int32);
                                var pMonth = mergeCmd.Parameters.Add("Month", OracleDbType.Int32);
                                var pDay = mergeCmd.Parameters.Add("Day", OracleDbType.Int32);
                                var pVal = mergeCmd.Parameters.Add("Val", OracleDbType.Single);
                                var pHoliday = mergeCmd.Parameters.Add("Holiday", OracleDbType.Int32);
                                var pLeave = mergeCmd.Parameters.Add("Leave", OracleDbType.Varchar2);
                                var pAutoSat = mergeCmd.Parameters.Add("AutoSat", OracleDbType.Int32);
                                var pRemarks = mergeCmd.Parameters.Add("Remarks", OracleDbType.Varchar2);

                                draftCmd.Transaction = trans;
                                var pDEmpID = draftCmd.Parameters.Add("EmpID", OracleDbType.Varchar2);
                                var pDYear = draftCmd.Parameters.Add("Year", OracleDbType.Int32);
                                var pDMonth = draftCmd.Parameters.Add("Month", OracleDbType.Int32);
                                var pDDay = draftCmd.Parameters.Add("Day", OracleDbType.Int32);
                                var pDVal = draftCmd.Parameters.Add("Val", OracleDbType.Single);
                                var pDHoliday = draftCmd.Parameters.Add("Holiday", OracleDbType.Int32);
                                var pDLeave = draftCmd.Parameters.Add("Leave", OracleDbType.Varchar2);
                                var pDAutoSat = draftCmd.Parameters.Add("AutoSat", OracleDbType.Int32);
                                var pDRemarks = draftCmd.Parameters.Add("Remarks", OracleDbType.Varchar2);
                                var pDPCNO = draftCmd.Parameters.Add("PCNO", OracleDbType.Varchar2);

                                delDraftCmd.Transaction = trans;
                                var pDelEmpID = delDraftCmd.Parameters.Add("EmpID", OracleDbType.Varchar2);
                                var pDelYear = delDraftCmd.Parameters.Add("Year", OracleDbType.Int32);
                                var pDelMonth = delDraftCmd.Parameters.Add("Month", OracleDbType.Int32);
                                var pDelDay = delDraftCmd.Parameters.Add("Day", OracleDbType.Int32);

                                foreach (var empKvp in dict)
                                {
                                    string empId = empKvp.Key;
                                    if (empId.StartsWith("GLOBAL", StringComparison.OrdinalIgnoreCase))
                                    {
                                        EnsureGlobalEmployeeExists(empId);
                                    }

                                    foreach (var dayKvp in empKvp.Value)
                                    {
                                        int day = Convert.ToInt32(dayKvp.Key);
                                        string cellKey = empId + "_" + day;
                                        
                                        if (role != 1 && role != 4)
                                        {
                                            try
                                             {
                                                DateTime checkDate = new DateTime(year, month + 1, day);
                                                if (editMode == 1)
                                                {
                                                    if (checkDate > today || checkDate.Year != today.Year || checkDate.Month != today.Month) continue;
                                                }
                                                else if (editMode == 2)
                                                {
                                                    DateTime prevMonth = today.AddMonths(-1);
                                                    bool isCurrentMonth = (checkDate.Year == today.Year && checkDate.Month == today.Month);
                                                    int graceCutoffDay = editDaysAllowed > 0 ? editDaysAllowed : 3;
                                                    bool isPrevMonthAllowed = (checkDate.Year == prevMonth.Year && checkDate.Month == prevMonth.Month && today.Day <= graceCutoffDay);

                                                    if ((!isCurrentMonth && !isPrevMonthAllowed) || checkDate > today) continue;
                                                }
                                                else
                                                {
                                                    if (checkDate > today || checkDate < minAllowedDate) continue;
                                                }
                                            }
                                            catch { continue; }
                                        }

                                        var cell = dayKvp.Value;
                                        object val = cell.ContainsKey("Val") && cell["Val"] != null ? cell["Val"] : DBNull.Value;
                                        bool isHoliday = cell.ContainsKey("Holiday") && cell["Holiday"] != null ? Convert.ToBoolean(cell["Holiday"]) : false;
                                        string leave = cell.ContainsKey("Leave") && cell["Leave"] != null ? cell["Leave"].ToString() : "";
                                        bool autoSat = cell.ContainsKey("AutoSat") && cell["AutoSat"] != null ? Convert.ToBoolean(cell["AutoSat"]) : false;
                                        string remarks = cell.ContainsKey("Remarks") && cell["Remarks"] != null ? cell["Remarks"].ToString() : "";
                                        bool hasContent = (val != DBNull.Value) || !string.IsNullOrEmpty(leave) || isHoliday || !string.IsNullOrEmpty(remarks);
                                        bool isDraft = cell.ContainsKey("IsDraft") && cell["IsDraft"] != null ? Convert.ToBoolean(cell["IsDraft"]) : false;

                                        // If Super Admin (role == 4) is viewing a draft cell, do NOT push it to live table and do NOT delete it from AttendanceDraft
                                        if (role == 4 && isDraft && !isHoliday)
                                        {
                                            continue;
                                        }

                                        // If this cell has NO content and was never submitted to live Attendance table,
                                        // skip it so we DO NOT overwrite or delete any pending SubUser draft in AttendanceDraft!
                                        if (!hasContent && !liveExistingCells.Contains(cellKey))
                                        {
                                            continue;
                                        }

                                        // Regular User (POC) cannot create brand new entries on empty cells; they must be entered in Sub User mode
                                        if (role == 0 && roleMode != "SubUser")
                                        {
                                            bool hadExistingDraft = draftExistingCells.Contains(cellKey);
                                            bool hadExistingLive = liveExistingCells.Contains(cellKey);
                                            if (!hadExistingDraft && !hadExistingLive && !isHoliday)
                                            {
                                                continue; // Skip brand new entry attempts by POC
                                            }
                                        }

                                        // For Admin (role == 1 || role == 4): ALWAYS write to live Attendance table and purge draft ONLY when actual content is entered
                                        if (role == 1 || role == 4)
                                        {
                                            pEmpID.Value = empId;
                                            pYear.Value = year;
                                            pMonth.Value = month;
                                            pDay.Value = day;
                                            pVal.Value = val != DBNull.Value ? (object)Convert.ToSingle(val) : DBNull.Value;
                                            pHoliday.Value = isHoliday ? 1 : 0;
                                            pLeave.Value = leave ?? "";
                                            pAutoSat.Value = autoSat ? 1 : 0;
                                            pRemarks.Value = remarks ?? "";

                                            mergeCmd.ExecuteNonQuery();

                                            // Only delete from AttendanceDraft if the admin actually entered/committed content into this cell
                                            if (hasContent && draftExistingCells.Contains(cellKey))
                                            {
                                                pDelEmpID.Value = empId;
                                                pDelYear.Value = year;
                                                pDelMonth.Value = month;
                                                pDelDay.Value = day;
                                                delDraftCmd.ExecuteNonQuery();
                                            }
                                        }
                                        else
                                        {
                                            // For POC (role == 0): If this cell was an existing unsubmitted draft, update it in AttendanceDraft
                                            if (draftExistingCells.Contains(cellKey))
                                            {
                                                pDEmpID.Value = empId;
                                                pDYear.Value = year;
                                                pDMonth.Value = month;
                                                pDDay.Value = day;
                                                pDVal.Value = val != DBNull.Value ? (object)Convert.ToSingle(val) : DBNull.Value;
                                                pDHoliday.Value = isHoliday ? 1 : 0;
                                                pDLeave.Value = leave ?? "";
                                                pDAutoSat.Value = autoSat ? 1 : 0;
                                                pDRemarks.Value = remarks ?? "";
                                                pDPCNO.Value = sessionPcno;

                                                draftCmd.ExecuteNonQuery();
                                            }
                                            else
                                            {
                                                pEmpID.Value = empId;
                                                pYear.Value = year;
                                                pMonth.Value = month;
                                                pDay.Value = day;
                                                pVal.Value = val != DBNull.Value ? (object)Convert.ToSingle(val) : DBNull.Value;
                                                pHoliday.Value = isHoliday ? 1 : 0;
                                                pLeave.Value = leave ?? "";
                                                pAutoSat.Value = autoSat ? 1 : 0;
                                                pRemarks.Value = remarks ?? "";

                                                mergeCmd.ExecuteNonQuery();
                                            }
                                        }
                                    }
                                }
                            }

                            // 2. Future updates MERGE command
                            if (futDict != null && futDict.Count > 0)
                            {
                                string futMergeQuery = @"
                                    MERGE INTO Attendance t
                                    USING (SELECT :EmpID as EmpID, :Year as Year, :Month as Month, :Day as Day, :Val as StatusValue, :Leave as LeaveType FROM DUAL) s
                                    ON (t.EmpID = s.EmpID AND t.Year = s.Year AND t.Month = s.Month AND t.Day = s.Day)
                                    WHEN MATCHED THEN
                                      UPDATE SET t.StatusValue = s.StatusValue, t.LeaveType = s.LeaveType
                                    WHEN NOT MATCHED THEN
                                      INSERT (EmpID, Year, Month, Day, StatusValue, LeaveType, IsHoliday, AutoSat, Remarks)
                                      VALUES (s.EmpID, s.Year, s.Month, s.Day, s.StatusValue, s.LeaveType, 0, 0, '')";

                                using (OracleCommand futCmd = new OracleCommand(futMergeQuery, conn))
                                {
                                    futCmd.Transaction = trans;
                                    var pFutEmpID = futCmd.Parameters.Add("EmpID", OracleDbType.Varchar2);
                                    var pFutYear = futCmd.Parameters.Add("Year", OracleDbType.Int32);
                                    var pFutMonth = futCmd.Parameters.Add("Month", OracleDbType.Int32);
                                    var pFutDay = futCmd.Parameters.Add("Day", OracleDbType.Int32);
                                    var pFutVal = futCmd.Parameters.Add("Val", OracleDbType.Single);
                                    var pFutLeave = futCmd.Parameters.Add("Leave", OracleDbType.Varchar2);

                                    foreach (var empKvp in futDict)
                                    {
                                        string empId = empKvp.Key;
                                        if (empId.StartsWith("GLOBAL", StringComparison.OrdinalIgnoreCase))
                                        {
                                            EnsureGlobalEmployeeExists(empId);
                                        }

                                        foreach (var dateKvp in empKvp.Value)
                                        {
                                            var cell = dateKvp.Value;
                                            int fYear = Convert.ToInt32(cell["Year"]);
                                            int fMonth = Convert.ToInt32(cell["Month"]);
                                            int fDay = Convert.ToInt32(cell["Day"]);
                                            object val = cell.ContainsKey("Val") && cell["Val"] != null ? cell["Val"] : DBNull.Value;
                                            string leave = cell.ContainsKey("Leave") && cell["Leave"] != null ? cell["Leave"].ToString() : "";

                                            pFutEmpID.Value = empId;
                                            pFutYear.Value = fYear;
                                            pFutMonth.Value = fMonth;
                                            pFutDay.Value = fDay;
                                            pFutVal.Value = val != DBNull.Value ? (object)Convert.ToSingle(val) : DBNull.Value;
                                            pFutLeave.Value = leave ?? "";

                                            futCmd.ExecuteNonQuery();
                                        }
                                    }
                                }
                            }

                            // 3. Save POC edit remarks if provided
                            if (!string.IsNullOrEmpty(pocEditRemarks) && pocEditRemarks != "{}" && pocEditRemarks != "null")
                            {
                                EnsureAttPocEditRemarksTable();
                                string roleLabel = (role == 1 || role == 4) ? "Admin" : "POC";
                                var pocDict = new JavaScriptSerializer().Deserialize<Dictionary<string, Dictionary<string, List<string>>>>(pocEditRemarks);
                                string insQuery = @"INSERT INTO AttPocEditRemarks (EmpID, Year, Month, Day, RemarkType, Remark, CreatedBy, CreatedByRole) 
                                    VALUES (:EmpID, :Year, :Month, :Day, 'POCEdit', :Remark, :CreatedBy, :CreatedByRole)";

                                using (OracleCommand pocCmd = new OracleCommand(insQuery, conn))
                                {
                                    pocCmd.Transaction = trans;
                                    var pPocEmpID = pocCmd.Parameters.Add("EmpID", OracleDbType.Varchar2);
                                    var pPocYear = pocCmd.Parameters.Add("Year", OracleDbType.Int32);
                                    var pPocMonth = pocCmd.Parameters.Add("Month", OracleDbType.Int32);
                                    var pPocDay = pocCmd.Parameters.Add("Day", OracleDbType.Int32);
                                    var pPocRemark = pocCmd.Parameters.Add("Remark", OracleDbType.Varchar2);
                                    var pPocCreatedBy = pocCmd.Parameters.Add("CreatedBy", OracleDbType.Varchar2);
                                    var pPocCreatedByRole = pocCmd.Parameters.Add("CreatedByRole", OracleDbType.Varchar2);

                                    foreach (var empKvp in pocDict)
                                    {
                                        string eid = empKvp.Key;
                                        foreach (var dayKvp in empKvp.Value)
                                        {
                                            int d = Convert.ToInt32(dayKvp.Key);
                                            foreach (string remark in dayKvp.Value)
                                            {
                                                if (string.IsNullOrWhiteSpace(remark)) continue;
                                                pPocEmpID.Value = eid;
                                                pPocYear.Value = year;
                                                pPocMonth.Value = month;
                                                pPocDay.Value = d;
                                                pPocRemark.Value = remark;
                                                pPocCreatedBy.Value = sessionPcno;
                                                pPocCreatedByRole.Value = roleLabel;

                                                pocCmd.ExecuteNonQuery();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        trans.Commit();
                    }
                    catch (Exception ex)
                    {
                        trans.Rollback();
                        System.Diagnostics.Debug.WriteLine("Error in SaveData transaction: " + ex.Message);
                        var errObj = new { status = "error", message = "Save failed: " + ex.Message };
                        return new JavaScriptSerializer().Serialize(errObj);
                    }
                }
            }

            if (roleMode != "SubUser")
            {
                try
                {
                    RecalculateNextMonthSaturdays(year, month, category);
                }
                catch { }
            }

            string successMsg = (roleMode == "SubUser") 
                ? "Draft saved successfully." 
                : "Saved successfully.";

            return new JavaScriptSerializer().Serialize(new { status = "success", message = successMsg });
        }

        private static string BuildEmpIdFilter(List<string> empIds, string paramPrefix, List<OracleParameter> paramList, string colPrefix = "")
        {
            if (empIds == null || empIds.Count == 0) return "";

            string colName = string.IsNullOrEmpty(colPrefix) ? "EmpID" : (colPrefix + ".EmpID");
            List<string> orClauses = new List<string>();
            int chunkSize = 900;
            for (int i = 0; i < empIds.Count; i += chunkSize)
            {
                var chunk = empIds.GetRange(i, Math.Min(chunkSize, empIds.Count - i));
                List<string> pNames = new List<string>();
                for (int j = 0; j < chunk.Count; j++)
                {
                    string pName = paramPrefix + "_" + (i + j);
                    pNames.Add(":" + pName);
                    paramList.Add(new OracleParameter(pName, chunk[j]));
                }
                orClauses.Add(colName + " IN (" + string.Join(", ", pNames) + ")");
            }
            return " AND (" + string.Join(" OR ", orClauses) + ")";
        }

        [WebMethod]
        public static string SubmitDrafts(int year, int month, string category, string division, string empIdsJson)
        {
            int role = Convert.ToInt32(HttpContext.Current.Session["Role"] ?? 0);
            string roleMode = HttpContext.Current.Session["RoleMode"]?.ToString() ?? "";
            string sessionPcno = HttpContext.Current.Session["PCNO"]?.ToString() ?? "Unknown";

            if (role == 1 || role == 4)
            {
                return new JavaScriptSerializer().Serialize(new { status = "error", message = "Permission denied: Admins manage live attendance directly; draft submission is for Regular Users (POCs) only." });
            }

            if (roleMode == "SubUser")
            {
                return new JavaScriptSerializer().Serialize(new { status = "error", message = "Permission denied: Sub Users cannot submit attendance to live. Please request your POC to review and submit." });
            }

            List<string> targetEmpIds = null;
            if (!string.IsNullOrEmpty(empIdsJson) && empIdsJson != "[]" && empIdsJson != "null")
            {
                try { targetEmpIds = new JavaScriptSerializer().Deserialize<List<string>>(empIdsJson); } catch { }
            }

            string connStr = DBHelper.GetAttendanceDBConnection();
            using (OracleConnection conn = new OracleConnection(connStr))
            {
                conn.Open();
                using (OracleTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        // Check how many drafts exist for the target scope (excluding holidays)
                        string countSql = "SELECT COUNT(*) FROM AttendanceDraft d WHERE d.Year = :Year AND d.Month = :Month AND (d.StatusValue IS NOT NULL OR d.LeaveType IS NOT NULL OR d.Remarks IS NOT NULL) AND (d.IsHoliday = 0 OR d.IsHoliday IS NULL)";
                        List<OracleParameter> countParams = new List<OracleParameter>
                        {
                            new OracleParameter("Year", year),
                            new OracleParameter("Month", month)
                        };
                        string cntEmpFilter = BuildEmpIdFilter(targetEmpIds, "CntEmp", countParams, "d");
                        countSql += cntEmpFilter;

                        int draftCount = 0;
                        using (OracleCommand countCmd = new OracleCommand(countSql, conn))
                        {
                            countCmd.Transaction = trans;
                            countCmd.Parameters.AddRange(countParams.ToArray());
                            object cntObj = countCmd.ExecuteScalar();
                            draftCount = (cntObj != null && cntObj != DBNull.Value) ? Convert.ToInt32(cntObj) : 0;
                        }

                        if (draftCount == 0)
                        {
                            return new JavaScriptSerializer().Serialize(new { status = "info", message = "No pending drafts found to submit.", submittedCount = 0 });
                        }

                        // Merge drafts into live Attendance (only valid standard columns matching Attendance schema)
                        List<OracleParameter> mergeParams = new List<OracleParameter>
                        {
                            new OracleParameter("Year", year),
                            new OracleParameter("Month", month)
                        };
                        string mergeEmpFilter = BuildEmpIdFilter(targetEmpIds, "DrEmp", mergeParams, "d");

                        string mergeSql = @"
                            MERGE INTO Attendance t
                            USING (
                                SELECT d.EmpID, d.Year, d.Month, d.Day, d.StatusValue, d.IsHoliday, d.LeaveType,
                                       d.AutoSat, d.Remarks
                                FROM AttendanceDraft d
                                WHERE d.Year = :Year AND d.Month = :Month " + mergeEmpFilter + @"
                            ) s
                            ON (t.EmpID = s.EmpID AND t.Year = s.Year AND t.Month = s.Month AND t.Day = s.Day)
                            WHEN MATCHED THEN
                              UPDATE SET t.StatusValue = s.StatusValue, t.IsHoliday = s.IsHoliday, t.LeaveType = s.LeaveType,
                                         t.AutoSat = s.AutoSat, t.Remarks = s.Remarks
                            WHEN NOT MATCHED THEN
                              INSERT (EmpID, Year, Month, Day, StatusValue, IsHoliday, LeaveType, AutoSat, Remarks)
                              VALUES (s.EmpID, s.Year, s.Month, s.Day, s.StatusValue, s.IsHoliday, s.LeaveType, s.AutoSat, s.Remarks)";

                        using (OracleCommand mergeCmd = new OracleCommand(mergeSql, conn))
                        {
                            mergeCmd.Transaction = trans;
                            mergeCmd.Parameters.AddRange(mergeParams.ToArray());
                            mergeCmd.ExecuteNonQuery();
                        }

                        // Delete submitted drafts from AttendanceDraft
                        List<OracleParameter> delParams = new List<OracleParameter>
                        {
                            new OracleParameter("Year", year),
                            new OracleParameter("Month", month)
                        };
                        string delEmpFilter = BuildEmpIdFilter(targetEmpIds, "DelEmp", delParams);

                        string delSql = "DELETE FROM AttendanceDraft WHERE Year = :Year AND Month = :Month " + delEmpFilter;

                        using (OracleCommand delCmd = new OracleCommand(delSql, conn))
                        {
                            delCmd.Transaction = trans;
                            delCmd.Parameters.AddRange(delParams.ToArray());
                            delCmd.ExecuteNonQuery();
                        }

                        trans.Commit();

                        try
                        {
                            RecalculateNextMonthSaturdays(year, month, category);
                        }
                        catch { }

                        return new JavaScriptSerializer().Serialize(new { 
                            status = "success", 
                            message = $"Successfully submitted {draftCount} attendance record{(draftCount == 1 ? "" : "s")} to the live system.",
                            submittedCount = draftCount 
                        });
                    }
                    catch (Exception ex)
                    {
                        trans.Rollback();
                        System.Diagnostics.Debug.WriteLine("Error submitting drafts: " + ex.Message);
                        return new JavaScriptSerializer().Serialize(new { status = "error", message = "Submission failed: " + ex.Message });
                    }
                }
            }
        }

        [WebMethod]
        public static string ClearPocEditRemark(string empId, int year, int month, int day)
        {
            int role = Convert.ToInt32(HttpContext.Current.Session["Role"] ?? 0);
            if (role != 1 && role != 4)
            {
                return "{\"status\":\"error\", \"message\":\"Permission denied: Admin only.\"}";
            }

            try
            {
                EnsureAttPocEditRemarksTable();
                string connStr = DBHelper.GetAttendanceDBConnection();
                string delQuery = "DELETE FROM AttPocEditRemarks WHERE EmpID = :EmpID AND Year = :Year AND Month = :Month AND Day = :Day";
                DBHelper.ExecuteNonQuery(connStr, delQuery,
                    new OracleParameter("EmpID", empId),
                    new OracleParameter("Year", year),
                    new OracleParameter("Month", month),
                    new OracleParameter("Day", day));

                return "{\"status\":\"success\"}";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error clearing POC edit remark: " + ex.Message);
                return "{\"status\":\"error\", \"message\":\"" + ex.Message.Replace("\"", "'") + "\"}";
            }
        }

        private static bool _attPocEditRemarksTableEnsured = false;
        private static readonly object _pocTableLock = new object();

        /// <summary>Ensures AttPocEditRemarks table exists; creates it if absent (safe for existing DBs).</summary>
        private static void EnsureAttPocEditRemarksTable()
        {
            if (_attPocEditRemarksTableEnsured) return;
            lock (_pocTableLock)
            {
                if (_attPocEditRemarksTableEnsured) return;
                string connStr = DBHelper.GetAttendanceDBConnection();
                try
                {
                    // Oracle stores table names in uppercase; AttPocEditRemarks => ATTPOCEDITREMARKS
                    object cnt = DBHelper.ExecuteScalar(connStr, "SELECT COUNT(*) FROM user_tables WHERE UPPER(table_name) = 'ATTPOCEDITREMARKS'");
                    if (Convert.ToInt32(cnt) == 0)
                    {
                        string createSql = @"
                            CREATE TABLE AttPocEditRemarks (
                                Id          NUMBER          PRIMARY KEY,
                                EmpID       VARCHAR2(50)    NOT NULL,
                                Year        NUMBER          NOT NULL,
                                Month       NUMBER          NOT NULL,
                                Day         NUMBER          NOT NULL,
                                RemarkType  VARCHAR2(50)    DEFAULT 'POCEdit' NOT NULL,
                                Remark      VARCHAR2(1000)  NOT NULL,
                                CreatedBy   VARCHAR2(100)   NOT NULL,
                                CreatedByRole VARCHAR2(50)  DEFAULT 'POC' NOT NULL,
                                CreatedAt   TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL
                            )";
                        DBHelper.ExecuteNonQuery(connStr, createSql);
                        DBHelper.ExecuteNonQuery(connStr, "CREATE SEQUENCE SEQ_AttPocEditRemarks START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE");
                        DBHelper.ExecuteNonQuery(connStr, @"
                            CREATE OR REPLACE TRIGGER TRG_AttPocEditRemarks
                            BEFORE INSERT ON AttPocEditRemarks
                            FOR EACH ROW
                            BEGIN
                                IF :NEW.Id IS NULL THEN
                                    SELECT SEQ_AttPocEditRemarks.NEXTVAL INTO :NEW.Id FROM DUAL;
                                END IF;
                            END;");
                    }
                    else
                    {
                        try
                        {
                            object colCnt = DBHelper.ExecuteScalar(connStr, "SELECT COUNT(*) FROM user_tab_cols WHERE UPPER(table_name) = 'ATTPOCEDITREMARKS' AND UPPER(column_name) = 'CREATEDBYROLE'");
                            if (Convert.ToInt32(colCnt) == 0)
                            {
                                DBHelper.ExecuteNonQuery(connStr, "ALTER TABLE AttPocEditRemarks ADD (CreatedByRole VARCHAR2(50) DEFAULT 'POC')");
                            }
                        }
                        catch { }
                    }
                    _attPocEditRemarksTableEnsured = true;
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("EnsureAttPocEditRemarksTable error: " + ex.Message);
                }
            }
        }

        private static readonly HashSet<string> _knownGlobalEmployees = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private static readonly object _knownGlobalLock = new object();

        private static void EnsureGlobalEmployeeExists(string globalEmpId)
        {
            if (string.IsNullOrEmpty(globalEmpId)) return;
            lock (_knownGlobalLock)
            {
                if (_knownGlobalEmployees.Contains(globalEmpId)) return;
            }
            try
            {
                string checkQuery = "SELECT COUNT(*) FROM Employees WHERE MasterId = :MasterId";
                object countObj = DBHelper.ExecuteScalar(DBHelper.GetAttendanceDBConnection(), checkQuery, new OracleParameter("MasterId", globalEmpId));
                int count = Convert.ToInt32(countObj ?? 0);
                if (count == 0)
                {
                    string insertEmp = @"
                        INSERT INTO Employees (MasterId, ID, Name, EmployeeHistoryId, Status)
                        VALUES (:MasterId, :ID, :Name, :HistoryId, 'System')";
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), insertEmp,
                        new OracleParameter("MasterId", globalEmpId),
                        new OracleParameter("ID", globalEmpId),
                        new OracleParameter("Name", "System Global Adjustment (" + globalEmpId + ")"),
                        new OracleParameter("HistoryId", globalEmpId));
                }
                else
                {
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), "UPDATE Employees SET Status = 'System' WHERE MasterId = :MasterId", new OracleParameter("MasterId", globalEmpId));
                }
                lock (_knownGlobalLock)
                {
                    _knownGlobalEmployees.Add(globalEmpId);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("EnsureGlobalEmployeeExists error: " + ex.Message);
            }
        }

        private struct AttCell
        {
            public float? Val;
            public bool IsHoliday;
            public string LeaveType;
            public bool AutoSat;
        }

        private class EngagementRange
        {
            public DateTime StartDate { get; set; }
            public DateTime? EndDate { get; set; }
        }

        private static void RecalculateNextMonthSaturdays(int year, int month, string category)
        {
            int nextMonth = month == 11 ? 0 : month + 1;
            int nextYear = month == 11 ? year + 1 : year;

            DateTime firstDayOfNextMonth = new DateTime(nextYear, nextMonth + 1, 1);
            int firstSatDay = -1;
            for (int d = 1; d <= 7; d++)
            {
                DateTime dt = new DateTime(nextYear, nextMonth + 1, d);
                if (dt.DayOfWeek == DayOfWeek.Saturday)
                {
                    firstSatDay = d;
                    break;
                }
            }

            if (firstSatDay == -1 || firstSatDay > 5)
            {
                return;
            }

            DateTime nextSatDate = new DateTime(nextYear, nextMonth + 1, firstSatDay);

            string empQuery = @"
                SELECT MasterId, JoinDate, ResignDate
                FROM Employees
                WHERE Status IN ('Active', 'Upgraded', 'Downgraded', 'ContractEnded', 'Resigned', 'Transferred')";
            if (category != "All")
            {
                empQuery += " AND Category = :Category";
            }

            List<OracleParameter> empParams = new List<OracleParameter>();
            if (category != "All")
            {
                empParams.Add(new OracleParameter("Category", category));
            }

            DataTable dtEmp = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), empQuery, empParams.ToArray());
            if (dtEmp.Rows.Count == 0) return;

            string engQuery = @"
                SELECT ee.EmpID, ee.StartDate, ee.EndDate, cp.EndDate AS CpEndDate
                FROM EmployeeEngagements ee
                JOIN ContractPeriods cp ON ee.ContractPeriodId = cp.Id
                WHERE ee.StartDate <= :SatDate AND (ee.EndDate IS NULL OR ee.EndDate >= :SatDate)";
            DataTable dtEng = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), engQuery, 
                new OracleParameter("SatDate", nextSatDate));

            Dictionary<string, List<EngagementRange>> engDict = new Dictionary<string, List<EngagementRange>>();
            foreach (DataRow dr in dtEng.Rows)
            {
                string empId = dr["EmpID"].ToString();
                DateTime startDate = Convert.ToDateTime(dr["StartDate"]);
                DateTime? eeEndDate = dr["EndDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(dr["EndDate"]) : null;
                DateTime? cpEndDate = dr["CpEndDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(dr["CpEndDate"]) : null;
                
                DateTime? effectiveEndDate = null;
                if (eeEndDate.HasValue && cpEndDate.HasValue)
                {
                    effectiveEndDate = eeEndDate.Value < cpEndDate.Value ? eeEndDate.Value : cpEndDate.Value;
                }
                else if (eeEndDate.HasValue)
                {
                    effectiveEndDate = eeEndDate;
                }
                else if (cpEndDate.HasValue)
                {
                    effectiveEndDate = cpEndDate;
                }

                if (!engDict.ContainsKey(empId))
                    engDict[empId] = new List<EngagementRange>();

                engDict[empId].Add(new EngagementRange { StartDate = startDate, EndDate = effectiveEndDate });
            }

            string nextAttQuery = @"
                SELECT EmpID, Day, StatusValue, IsHoliday, LeaveType, AutoSat
                FROM Attendance
                WHERE Year = :Year AND Month = :Month AND Day <= :SatDay";
            DataTable dtNextAtt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), nextAttQuery,
                new OracleParameter("Year", nextYear),
                new OracleParameter("Month", nextMonth),
                new OracleParameter("SatDay", firstSatDay));

            Dictionary<string, Dictionary<int, AttCell>> nextAttDict = new Dictionary<string, Dictionary<int, AttCell>>();
            foreach (DataRow dr in dtNextAtt.Rows)
            {
                string empId = dr["EmpID"].ToString();
                int day = Convert.ToInt32(dr["Day"]);
                float? val = dr["StatusValue"] == DBNull.Value ? (float?)null : Convert.ToSingle(dr["StatusValue"]);
                bool isHoliday = Convert.ToInt32(dr["IsHoliday"]) == 1;
                string leave = dr["LeaveType"].ToString();
                bool autoSat = dr.Table.Columns.Contains("AutoSat") && dr["AutoSat"] != DBNull.Value ? Convert.ToInt32(dr["AutoSat"]) == 1 : false;

                if (!nextAttDict.ContainsKey(empId))
                    nextAttDict[empId] = new Dictionary<int, AttCell>();

                nextAttDict[empId][day] = new AttCell { Val = val, IsHoliday = isHoliday, LeaveType = leave, AutoSat = autoSat };
            }

            int daysInCurrMonth = DateTime.DaysInMonth(year, month + 1);
            int earliestPrevDay = daysInCurrMonth + (firstSatDay - 5);

            string currAttQuery = @"
                SELECT EmpID, Day, StatusValue, IsHoliday, LeaveType
                FROM Attendance
                WHERE Year = :Year AND Month = :Month AND Day >= :EarliestDay";
            DataTable dtCurrAtt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), currAttQuery,
                new OracleParameter("Year", year),
                new OracleParameter("Month", month),
                new OracleParameter("EarliestDay", earliestPrevDay));

            Dictionary<string, Dictionary<int, AttCell>> currAttDict = new Dictionary<string, Dictionary<int, AttCell>>();
            foreach (DataRow dr in dtCurrAtt.Rows)
            {
                string empId = dr["EmpID"].ToString();
                int day = Convert.ToInt32(dr["Day"]);
                float? val = dr["StatusValue"] == DBNull.Value ? (float?)null : Convert.ToSingle(dr["StatusValue"]);
                bool isHoliday = Convert.ToInt32(dr["IsHoliday"]) == 1;
                string leave = dr["LeaveType"].ToString();

                if (!currAttDict.ContainsKey(empId))
                    currAttDict[empId] = new Dictionary<int, AttCell>();

                currAttDict[empId][day] = new AttCell { Val = val, IsHoliday = isHoliday, LeaveType = leave };
            }

            foreach (DataRow row in dtEmp.Rows)
            {
                string empId = row["MasterId"].ToString();

                if (!nextAttDict.ContainsKey(empId) || !nextAttDict[empId].ContainsKey(firstSatDay) || !nextAttDict[empId][firstSatDay].AutoSat)
                {
                    continue;
                }

                DateTime? joinDate = row["JoinDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(row["JoinDate"]) : null;
                DateTime? resignDate = row["ResignDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(row["ResignDate"]) : null;

                List<EngagementRange> empEngs = engDict.ContainsKey(empId) ? engDict[empId] : new List<EngagementRange>();

                bool ok = true;
                DateTime monday = nextSatDate.AddDays(-5);
                DateTime friday = nextSatDate.AddDays(-1);

                if (joinDate.HasValue && joinDate.Value.Date > monday.Date && joinDate.Value.Date <= friday.Date)
                {
                    ok = false;
                }
                else
                {
                    for (int k = 1; k <= 5; k++)
                    {
                        DateTime c = nextSatDate.AddDays(-k);

                        bool isOutOfBoundsWeek = true;
                        foreach (var eng in empEngs)
                        {
                            if (c.Date >= eng.StartDate.Date && (!eng.EndDate.HasValue || c.Date <= eng.EndDate.Value.Date))
                            {
                                isOutOfBoundsWeek = false;
                                break;
                            }
                        }
                        if (isOutOfBoundsWeek) continue;

                        float? v = null;
                        string l = "";
                        bool isHol = false;

                        if (c.Month - 1 == nextMonth)
                        {
                            if (nextAttDict.ContainsKey(empId) && nextAttDict[empId].ContainsKey(c.Day))
                            {
                                v = nextAttDict[empId][c.Day].Val;
                                l = nextAttDict[empId][c.Day].LeaveType;
                                isHol = nextAttDict[empId][c.Day].IsHoliday;
                            }
                        }
                        else
                        {
                            if (currAttDict.ContainsKey(empId) && currAttDict[empId].ContainsKey(c.Day))
                            {
                                v = currAttDict[empId][c.Day].Val;
                                l = currAttDict[empId][c.Day].LeaveType;
                                isHol = currAttDict[empId][c.Day].IsHoliday;
                            }
                        }

                        bool came = (v == 1f) || (v == 0.5f) || (l == "Paid") || (l == "Carried") || (l == "Paired Paid") || (l == "Paired Unpaid") || (isHol == true);
                        if (!came)
                        {
                            ok = false;
                            break;
                        }
                    }
                }

                float newVal = ok ? 1f : 0f;
                float? currentVal = nextAttDict[empId][firstSatDay].Val;

                if (currentVal != newVal)
                {
                    string updateQuery = @"
                        UPDATE Attendance 
                        SET StatusValue = :Val 
                        WHERE EmpID = :EmpID AND Year = :Year AND Month = :Month AND Day = :Day";
                    DBHelper.ExecuteNonQuery(DBHelper.GetAttendanceDBConnection(), updateQuery,
                        new OracleParameter("Val", newVal),
                        new OracleParameter("EmpID", empId),
                        new OracleParameter("Year", nextYear),
                        new OracleParameter("Month", nextMonth),
                        new OracleParameter("Day", firstSatDay));
                }
            }
        }


        [WebMethod]
        public static string GetCategories()
        {
            int role = Convert.ToInt32(System.Web.HttpContext.Current.Session["Role"] ?? 0);
            string pcno = System.Web.HttpContext.Current.Session["PCNO"]?.ToString() ?? "";
            DataTable dt = DBHelper.GetVisibleTiersDataTable(pcno, role);
            List<string> list = new List<string>();
            foreach (DataRow dr in dt.Rows)
            {
                list.Add(dr["TierId"].ToString() + ":" + dr["DisplayName"].ToString());
            }
            return new JavaScriptSerializer().Serialize(list);
        }

        [WebMethod]
        public static string GetDivisions()
        {
            int role = Convert.ToInt32(HttpContext.Current.Session["Role"] ?? 0);
            string pcno = HttpContext.Current.Session["PCNO"]?.ToString() ?? "";
            
            List<string> list = new List<string>();
            if (role == 1 || role == 4)
            {
                DataTable dt = DBHelper.GetCompanyDivisionsDataTable();
                foreach (DataRow dr in dt.Rows)
                {
                    list.Add(dr["Name"].ToString());
                }
            }
            else
            {
                string query = "SELECT DivisionName FROM UserDivisions WHERE PCNO = :PCNO ORDER BY DivisionName ASC";
                DataTable dt = DBHelper.ExecuteQuery(DBHelper.GetAttendanceDBConnection(), query, new OracleParameter("PCNO", pcno));
                foreach (DataRow dr in dt.Rows)
                {
                    list.Add(dr["DivisionName"].ToString());
                }
            }
            return new JavaScriptSerializer().Serialize(list);
        }

        private static bool ValidateLeaveBalances(
            string connStr, 
            Dictionary<string, Dictionary<string, Dictionary<string, object>>> dict, 
            Dictionary<string, Dictionary<string, Dictionary<string, object>>> futDict, 
            int year, 
            int month, 
            out string errorMessage)
        {
            errorMessage = "";
            foreach (var empId in dict.Keys)
            {
                if (empId.StartsWith("GLOBAL")) continue;

                string empSql = @"
                    SELECT e.Name, e.LeaveBalance, e.PrevLeaveBalance, ee.ContractPeriodId AS CurrentContractPeriodId
                    FROM Employees e
                    LEFT JOIN EmployeeEngagements ee ON e.CurrentEngagementId = ee.Id
                    WHERE e.MasterId = :MasterId";
                
                DataTable dtEmp = DBHelper.ExecuteQuery(connStr, empSql, new OracleParameter("MasterId", empId));
                if (dtEmp.Rows.Count == 0) continue;
                
                string empName = dtEmp.Rows[0]["Name"].ToString();

                string engSql = "SELECT Id, StartDate, EndDate, ContractPeriodId FROM EmployeeEngagements WHERE EmpID = :MasterId";
                DataTable dtEng = DBHelper.ExecuteQuery(connStr, engSql, new OracleParameter("MasterId", empId));

                Func<DateTime, int?> getCpIdForDate = (date) => {
                    foreach (DataRow er in dtEng.Rows)
                    {
                        DateTime start = Convert.ToDateTime(er["StartDate"]);
                        DateTime? end = er["EndDate"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(er["EndDate"]) : null;
                        if (date >= start && (!end.HasValue || date <= end.Value))
                        {
                            return er["ContractPeriodId"] != DBNull.Value ? (int?)Convert.ToInt32(er["ContractPeriodId"]) : null;
                        }
                    }
                    return null;
                };

                // Identify unique CPs touched by these updates
                HashSet<int?> touchedCps = new HashSet<int?>();
                foreach (var dayKvp in dict[empId])
                {
                    touchedCps.Add(getCpIdForDate(new DateTime(year, month + 1, Convert.ToInt32(dayKvp.Key))));
                }
                if (futDict != null && futDict.ContainsKey(empId))
                {
                    foreach (var dateKvp in futDict[empId])
                    {
                        var cell = dateKvp.Value;
                        touchedCps.Add(getCpIdForDate(new DateTime(Convert.ToInt32(cell["Year"]), Convert.ToInt32(cell["Month"]) + 1, Convert.ToInt32(cell["Day"]))));
                    }
                }

                foreach (var targetCpId in touchedCps)
                {
                    if (!targetCpId.HasValue) continue;

                    string dbSql = @"
                        SELECT a.Year, a.Month, a.Day, a.StatusValue, a.LeaveType, a.IsHoliday
                        FROM Attendance a
                        JOIN EmployeeEngagements ee ON a.EmpID = ee.EmpID
                          AND TO_DATE(a.Year || '-' || (a.Month + 1) || '-' || a.Day, 'YYYY-MM-DD') >= ee.StartDate
                          AND (ee.EndDate IS NULL OR TO_DATE(a.Year || '-' || (a.Month + 1) || '-' || a.Day, 'YYYY-MM-DD') <= ee.EndDate)
                        WHERE a.EmpID = :MasterId AND ee.ContractPeriodId = :CpId";
                    
                    DataTable dtDb = DBHelper.ExecuteQuery(connStr, dbSql, 
                        new OracleParameter("MasterId", empId),
                        new OracleParameter("CpId", targetCpId.Value));

                    // Get all leave credits for this employee under targetCpId
                    string creditSql = "SELECT Amount, EffectiveDate FROM EmployeeLeaveCredits WHERE EmpID = :MasterId AND ContractPeriodId = :CpId";
                    DataTable dtCredits = DBHelper.ExecuteQuery(connStr, creditSql, 
                        new OracleParameter("MasterId", empId),
                        new OracleParameter("CpId", targetCpId.Value));
                    
                    bool useCreditsTable = dtCredits.Rows.Count > 0;

                    // Combine all attendance records for this CP:
                    // 1. Existing DB records
                    // 2. New updates from dict
                    // 3. New updates from futDict
                    // We will map Date -> LeaveWeight
                    Dictionary<DateTime, double> allLeaves = new Dictionary<DateTime, double>();

                    // Add existing DB records
                    foreach (DataRow row in dtDb.Rows)
                    {
                        int yVal = Convert.ToInt32(row["Year"]);
                        int mVal = Convert.ToInt32(row["Month"]);
                        int dVal = Convert.ToInt32(row["Day"]);
                        DateTime date = new DateTime(yVal, mVal + 1, dVal);

                        bool isHoliday = row["IsHoliday"] != DBNull.Value && Convert.ToInt32(row["IsHoliday"]) == 1;
                        if (isHoliday) continue;

                        double val = row["StatusValue"] != DBNull.Value ? Convert.ToDouble(row["StatusValue"]) : 0.0;
                        string leaveType = row["LeaveType"] != DBNull.Value ? row["LeaveType"].ToString() : "";

                        double weight = 0.0;
                        if (val == 0.0 && leaveType == "Paid") weight = 1.0;
                        else if (leaveType == "Paired Paid") weight = 1.0;

                        allLeaves[date] = weight;
                    }

                    // Overwrite/Add from dict (current month updates)
                    foreach (var dayKvp in dict[empId])
                    {
                        int day = Convert.ToInt32(dayKvp.Key);
                        DateTime date = new DateTime(year, month + 1, day);
                        
                        int? cpId = getCpIdForDate(date);
                        if (cpId != targetCpId.Value) continue;

                        var cell = dayKvp.Value;
                        double weight = 0.0;
                        if (cell.ContainsKey("Holiday") && Convert.ToBoolean(cell["Holiday"]))
                        {
                            weight = 0.0;
                        }
                        else
                        {
                            object valObj = cell.ContainsKey("Val") ? cell["Val"] : null;
                            string leaveType = cell.ContainsKey("Leave") && cell["Leave"] != null ? cell["Leave"].ToString() : "";
                            double val = 0.0;
                            if (valObj != null && double.TryParse(valObj.ToString(), out val))
                            {
                                if (val == 0.0 && leaveType == "Paid") weight = 1.0;
                            }
                            if (leaveType == "Paired Paid") weight = 1.0;
                        }

                        allLeaves[date] = weight;
                    }

                    // Overwrite/Add from futDict (future updates)
                    if (futDict != null && futDict.ContainsKey(empId))
                    {
                        foreach (var dateKvp in futDict[empId])
                        {
                            var cell = dateKvp.Value;
                            int fYear = Convert.ToInt32(cell["Year"]);
                            int fMonth = Convert.ToInt32(cell["Month"]);
                            int fDay = Convert.ToInt32(cell["Day"]);
                            DateTime date = new DateTime(fYear, fMonth + 1, fDay);

                            int? cpId = getCpIdForDate(date);
                            if (cpId != targetCpId.Value) continue;

                            double weight = 0.0;
                            object valObj = cell.ContainsKey("Val") ? cell["Val"] : null;
                            string leaveType = cell.ContainsKey("Leave") && cell["Leave"] != null ? cell["Leave"].ToString() : "";
                            double val = 0.0;
                            if (valObj != null && double.TryParse(valObj.ToString(), out val))
                            {
                                if (val == 0.0 && leaveType == "Paid") weight = 1.0;
                            }
                            if (leaveType == "Paired Paid") weight = 1.0;

                            allLeaves[date] = weight;
                        }
                    }

                    // Now, validate chronologically!
                    var sortedDates = allLeaves.Keys.OrderBy(d => d).ToList();
                    
                    foreach (var date in sortedDates)
                    {
                        double weightAtDate = allLeaves[date];
                        if (weightAtDate == 0.0) continue; // No leave taken, no check needed for this date

                        // Sum leaves taken on or before this date
                        double leavesUsed = 0.0;
                        foreach (var prevDate in sortedDates)
                        {
                            if (prevDate <= date)
                            {
                                leavesUsed += allLeaves[prevDate];
                            }
                        }

                        // Get total credits active on or before this date
                        double allowedCredits = 0.0; 
                        if (useCreditsTable)
                        {
                            double creditSum = 0.0;
                            foreach (DataRow cr in dtCredits.Rows)
                            {
                                DateTime effDate = Convert.ToDateTime(cr["EffectiveDate"]);
                                if (effDate <= date)
                                {
                                    creditSum += Convert.ToDouble(cr["Amount"]);
                                }
                            }
                            allowedCredits = creditSum;
                        }
                        else
                        {
                            object currentCpIdObj = dtEmp.Rows[0]["CurrentContractPeriodId"];
                            bool isCurrentCp = currentCpIdObj != DBNull.Value && Convert.ToInt32(currentCpIdObj) == targetCpId.Value;
                            string balanceCol = isCurrentCp ? "LeaveBalance" : "PrevLeaveBalance";
                            allowedCredits = dtEmp.Rows[0][balanceCol] != DBNull.Value ? Convert.ToDouble(dtEmp.Rows[0][balanceCol]) : 0.0;
                        }

                        if (leavesUsed > allowedCredits)
                        {
                            errorMessage = string.Format(
                                "Validation Error: Employee {0} ({1}) would exceed paid leave limit on {2:yyyy-MM-dd}. Leaves used up to this date: {3} days, allowed credits: {4} days.",
                                empName, empId, date, leavesUsed, allowedCredits);
                            return false;
                        }
                    }
                }
            }
            return true;
        }
    }
}
