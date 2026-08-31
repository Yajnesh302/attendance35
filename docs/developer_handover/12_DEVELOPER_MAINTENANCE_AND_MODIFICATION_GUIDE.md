# Chapter 12: Developer Recipe & Modification Handbook

This handbook provides practical, step-by-step recipes for future software engineers who need to maintain, modify, extend, or troubleshoot the **Attendance Management System (AMS)** without the original author.

---

## Recipe 1: How to Add a New Field to an Existing Table

**Scenario:** Suppose you need to add an `EmergencyContactPhone` column to the `Employees` table and display it on `Employee.aspx`.

### Step 1.1: Database Schema Migration
1. Connect to the Oracle database as `SYSTEM` or your schema owner.
2. Execute the ALTER statement:
   ```sql
   ALTER TABLE Employees ADD EmergencyContactPhone VARCHAR2(20) NULL;
   ```
3. Update [oracle_setup.sql](file:///e:/attendence/oracle_setup.sql) under the `CREATE TABLE Employees` definition so future fresh installations include the new column.

### Step 1.2: Update Action Logger JSON Capture
Because `ActionLogger.cs` serializes employee records for the undo engine, update [Utils/ActionLogger.cs](file:///e:/attendence/Utils/ActionLogger.cs):
- In `UndoAction(...)`, add the parameter mapping under `UPDATE Employees`:
  ```csharp
  cmd.Parameters.Add(new OracleParameter("EmergencyContactPhone", 
      empData.ContainsKey("EMERGENCYCONTACTPHONE") ? empData["EMERGENCYCONTACTPHONE"] : DBNull.Value));
  ```

### Step 1.3: Update Backend CRUD in `Employee.aspx.cs`
1. In `btnAdd_Click`: Read value from the new textbox `txtEmergencyPhone.Text.Trim()` and include `:EmergencyContactPhone` in the `INSERT INTO Employees` statement.
2. In `btnEdit_Click`: Include `EmergencyContactPhone = :EmergencyContactPhone` in the `UPDATE Employees` statement.
3. In `BindGrid()`: Add `e.EmergencyContactPhone` to the select list.

### Step 1.4: Update Frontend UI in `Employee.aspx`
Add the ASP.NET control inside the edit/create modal:
```html
<div class="form-group col-md-6">
    <label>Emergency Contact Phone</label>
    <asp:TextBox ID="txtEmergencyPhone" runat="server" CssClass="form-control" placeholder="+91 XXXXXXXXXX" />
</div>
```

---

## Recipe 2: How to Add a New Page / Module

**Scenario:** You are creating a new page called `Reports.aspx`.

### Step 2.1: Create Web Form & Code-Behind
1. Create `Reports.aspx`:
   ```html
   <%@ Page Title="System Reports" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Reports.aspx.cs" Inherits="AttendanceApp.Reports" %>
   <asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
       <div class="container-fluid">
           <h1 class="h3 mb-4 text-gray-800">System Reports</h1>
           <!-- Content here -->
       </div>
   </asp:Content>
   ```
2. Create `Reports.aspx.cs`:
   ```csharp
   using System;
   using System.Web.UI;
   using AttendanceApp.Utils;

   namespace AttendanceApp
   {
       public partial class Reports : Page
       {
           protected void Page_Load(object sender, EventArgs e)
           {
               if (!User.Identity.IsAuthenticated || Session["PCNO"] == null)
               {
                   Response.Redirect("Login.aspx");
                   return;
               }

               // Enforce Role Access Control (e.g. Admin only)
               int role = Convert.ToInt32(Session["Role"] ?? 0);
               if (role != 1 && role != 4)
               {
                   Response.Redirect("Dashboard.aspx");
                   return;
               }
           }
       }
   }
   ```

### Step 2.2: Register Navigation Link in `Site.Master`
Open [Site.Master](file:///e:/attendence/Site.Master) and add the menu item:
```html
<li class="nav-item">
    <a class="<%= GetNavClass("Reports.aspx") %>" href="Reports.aspx">
        <i class="fas fa-chart-bar mr-1"></i> Reports
    </a>
</li>
```
Open [Site.Master.cs](file:///e:/attendence/Site.Master.cs) and configure placeholder visibility if the page should be restricted to specific roles.

---

## Recipe 3: How to Modify Attendance Rules & Wage Formulas

### Altering the Saturday Rule
- Open [Attendance.aspx.cs](file:///e:/attendence/Attendance.aspx.cs).
- Locate the Saturday evaluation section inside `GetData`.
- Adjust the conditions checking whether Friday or Monday was an absent day (`StatusValue == 0`).

### Altering EPF / GST Statutory Ceilings
- Open [Wages.aspx](file:///e:/attendence/Wages.aspx) in your browser as Admin, or update the database directly:
  ```sql
  INSERT INTO StatutoryOrders (OrderId, EffectiveDate, EpfRate, EpfLimit, EpfCappedAmount, GstRate, CreatedBy)
  VALUES ('STAT/2026/02', TO_DATE('2026-06-01', 'YYYY-MM-DD'), 12.00, 21000.00, 2520.00, 18.00, '1001');
  ```
- All subsequent payroll runs will automatically pick up the new statutory rates effective from the designated date.

---

## Recipe 4: How to Configure & Debug Active Directory / LDAP

### Local Offline Testing Bypass
During local development without an active domain controller connection, [Utils/ADHelper.cs](file:///e:/attendence/Utils/ADHelper.cs) contains built-in bypass accounts:
- Username: `1001` or `admin` $\rightarrow$ Logs in as Admin (`PCNO = 1001`)
- Username: `1002` $\rightarrow$ Logs in as POC (`PCNO = 1002`)
- Username: `1003` $\rightarrow$ Logs in as POC (`PCNO = 1003`)
- Username: `1004` $\rightarrow$ Logs in as SubUser (`PCNO = 1004`)
*(Any password is accepted for bypass accounts during local testing).*

### Connecting to Production Domain Controller
1. Open [Web.config](file:///e:/attendence/Web.config).
2. Update the `ADConnectionPath` app setting:
   ```xml
   <add key="ADConnectionPath" value="LDAP://YOUR_DC_IP_OR_HOST/DC=company,DC=corp,DC=in" />
   ```
3. Ensure server firewall allows outbound TCP port `389` (LDAP) or `636` (LDAPS) to the Domain Controller.

---

## Recipe 5: Oracle Database Connection Troubleshooting

### Connection Pool Configuration in `Web.config`
```xml
<add name="AttendanceDB" 
     connectionString="User Id=system;Password=root;Data Source=//127.0.0.1:1521/xe;Min Pool Size=5;Max Pool Size=200;Connection Lifetime=120;Statement Cache Size=50;Incr Pool Size=5;Decr Pool Size=2;Validate Connection=false;" 
     providerName="Oracle.ManagedDataAccess.Client" />
```

### Critical ADO.NET Rules to Prevent Connection Leaks:
1. **Always wrap connections, commands, and readers in `using` blocks:**
   ```csharp
   using (OracleConnection conn = new OracleConnection(DBHelper.GetAttendanceDBConnection()))
   {
       conn.Open();
       using (OracleCommand cmd = new OracleCommand(sql, conn))
       {
           cmd.BindByName = true; // ALWAYS set BindByName = true in Oracle ADO.NET
           cmd.Parameters.Add(new OracleParameter("Param1", value));
           using (OracleDataReader reader = cmd.ExecuteReader())
           {
               while (reader.Read()) { ... }
           }
       }
   }
   ```
2. **Never leave DataReaders open without consuming or disposing them.**

---

## Recipe 6: Production Build & Deployment Checklist

When deploying changes to the production Windows IIS Server:

1. **Compile Solution:**
   Using MSBuild or Visual Studio:
   ```powershell
   & "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe" AttendanceApp.sln /p:Configuration=Release
   ```
2. **Deploy Files to IIS:**
   - Copy `bin/AttendanceApp.dll` and dependencies (`Oracle.ManagedDataAccess.dll`, `MySql.Data.dll`).
   - Copy all `.aspx`, `.Master`, and `.config` files.
   - Copy the `Static/` folder containing CSS, JS, and font assets.
3. **Set Folder Permissions:**
   Ensure `IIS_IUSRS` and `NETWORK SERVICE` have **Read & Execute** permissions on the application folder, and **Write** permissions on temporary upload folders if document attachments are saved locally.
4. **Update `Web.config` for Production:**
   - Set `<compilation debug="false" targetFramework="4.5" />`.
   - Update `connectionStrings` with production database credentials.
   - Update `ADConnectionPath` with corporate LDAP domain controllers.
