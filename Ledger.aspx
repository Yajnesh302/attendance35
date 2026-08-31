<%@ Page Title="Leave Ledger" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Ledger.aspx.cs" Inherits="AttendanceApp.Ledger" %>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="TitleContent" runat="server">Leave Ledger</asp:Content>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <script src="Static/js/xlsx.full.min.js?v=1.2.0"></script>
    <script src="Static/js/exceljs.min.js?v=1.0.0"></script>

    <style>
        /* Modern dark text colors for enhanced legibility */
        h2, .h2, 
        .panel, 
        .form-control,
        body {
            color: #0f172a !important; /* Extremely dark slate text */
        }
        
        /* Modern Premium Panel Container */
        .panel {
            background: white;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
            margin-bottom: 20px;
            border: 1px solid #f1f5f9;
        }
        
        /* Modern Premium Table Styling */
        .table-custom {
            border-collapse: separate !important;
            border-spacing: 0 !important;
            width: 100% !important;
            border: none !important; /* Managed by the outer responsive container border */
            background-color: #fff;
        }
        .table-custom th {
            background-color: #f8fafc !important; /* Soft slate gray */
            color: #475569 !important; /* Slate color */
            font-size: 0.8rem !important;
            text-transform: uppercase !important;
            letter-spacing: 0.06em !important;
            font-weight: 700 !important;
            padding: 14px 20px !important;
            border-top: none !important;
            border-bottom: 2px solid #e2e8f0 !important;
            border-left: none !important;
            border-right: 1px solid #e2e8f0 !important; /* Clean vertical line in header */
            vertical-align: middle !important;
        }
        .table-custom th:last-child {
            border-right: none !important;
        }
        .table-custom td {
            padding: 14px 20px !important;
            color: #334155 !important; /* Charcoal slate */
            font-size: 0.92rem !important;
            font-weight: 500 !important;
            border-bottom: 1px solid #e2e8f0 !important; /* Horizontal separating lines */
            border-left: none !important;
            border-right: 1px solid #f1f5f9 !important; /* Soft vertical separating lines */
            vertical-align: middle !important;
        }
        .table-custom td:last-child {
            border-right: none !important;
        }
        .table-custom tr:last-child td {
            border-bottom: none !important; /* Remove bottom border on the last row */
        }
        .table-custom tr {
            transition: background-color 0.2s ease;
        }
        .table-custom tr:hover {
            background-color: #eef2ff !important; /* Distinct light indigo hover */
        }
        .table-custom tr:nth-child(even) {
            background-color: #fbfcfd;
        }
        
        /* Make sure Red highlights stay bold and legible */
        .table-custom td[style*="Red"], 
        .table-custom td[style*="red"],
        .table-custom td[style*="color:Red"],
        .table-custom td[style*="color:red"],
        .table-custom td[style*="color: Red"] {
            color: #ef4444 !important;
            font-weight: 700 !important;
        }

        /* Elegant Toast Container at Top Right */
        #toast-container {
            position: fixed;
            top: 24px;
            right: 24px;
            display: flex;
            flex-direction: column;
            gap: 12px;
            z-index: 200000;
            pointer-events: none;
        }
        
        .modern-toast {
            display: flex;
            align-items: center;
            gap: 14px;
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(12px) saturate(180%);
            -webkit-backdrop-filter: blur(12px) saturate(180%);
            border-radius: 12px;
            padding: 14px 20px;
            min-width: 320px;
            max-width: 420px;
            color: #1e293b;
            font-size: 0.92rem;
            font-weight: 600;
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04), inset 0 0 0 1px rgba(255, 255, 255, 0.5);
            transform: translateX(120%);
            transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.3s ease;
            opacity: 0;
            pointer-events: auto;
            border-left: 6px solid #64748b;
        }
        
        .modern-toast.toast-show {
            transform: translateX(0);
            opacity: 1;
        }
        
        .modern-toast.toast-hide {
            transform: translateY(-20px) scale(0.9);
            opacity: 0;
        }
        
        .toast-icon {
            font-size: 1.35rem;
            flex-shrink: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        /* Toast Alert States with Curated Color Accents */
        .toast-success {
            border-left-color: #10b981;
            background: rgba(240, 253, 250, 0.95);
        }
        .toast-success .toast-icon {
            color: #10b981;
        }
        
        .toast-error {
            border-left-color: #ef4444;
            background: rgba(254, 242, 242, 0.95);
        }
        .toast-error .toast-icon {
            color: #ef4444;
        }
        
        .toast-warning {
            border-left-color: #f59e0b;
            background: rgba(255, 251, 235, 0.95);
        }
        .toast-warning .toast-icon {
            color: #f59e0b;
        }
        
        .toast-info {
            border-left-color: #3b82f6;
            background: rgba(239, 246, 255, 0.95);
        }
        .toast-info .toast-icon {
            color: #3b82f6;
        }
        
        .toast-close-btn {
            background: transparent;
            border: none;
            color: #94a3b8;
            cursor: pointer;
            font-size: 1.2rem;
            padding: 2px;
            line-height: 1;
            transition: color 0.15s ease;
            margin-left: auto;
        }
        .toast-close-btn:hover {
            color: #475569;
        }

        #loadingOverlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(255, 255, 255, 0.7);
            backdrop-filter: blur(4px);
            -webkit-backdrop-filter: blur(4px);
            z-index: 99999;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            font-family: 'Segoe UI', system-ui, sans-serif;
        }
        .spinner-border-custom {
            width: 3.5rem;
            height: 3.5rem;
            border: 5px solid #e2e8f0;
            border-top: 5px solid #4f46e5;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* Info Badges for top right */
        .d-flex.align-items-center.gap-2 {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .info-badge {
            display: inline-flex;
            align-items: center;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 700;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.04);
            border: 1px solid;
            font-family: 'Segoe UI', system-ui, sans-serif;
            transition: all 0.2s ease;
        }
        .badge-holiday {
            background-color: #fee2e2;
            color: #dc2626;
            border-color: #fca5a5;
        }
        .badge-holiday:hover {
            background-color: #fef2f2;
            transform: translateY(-1px);
        }
        .badge-adjust {
            background-color: #f3e8ff;
            color: #7e22ce;
            border-color: #d8b4fe;
        }
        .badge-adjust:hover {
            background-color: #faf5ff;
            transform: translateY(-1px);
        }

        /* Remarks Column Styling */
        .remarks-col {
            max-width: 250px;
            width: 250px;
            padding: 8px 12px !important;
        }
        .remarks-list {
            display: flex;
            flex-direction: column;
            gap: 6px;
            max-height: 160px;
            overflow-y: auto;
            scrollbar-width: thin;
            scrollbar-color: #cbd5e1 #f1f5f9;
            padding-right: 4px;
        }
        .remarks-list::-webkit-scrollbar {
            width: 6px;
        }
        .remarks-list::-webkit-scrollbar-track {
            background: #f1f5f9;
            border-radius: 4px;
        }
        .remarks-list::-webkit-scrollbar-thumb {
            background-color: #cbd5e1;
            border-radius: 4px;
        }
        .remarks-list::-webkit-scrollbar-thumb:hover {
            background-color: #94a3b8;
        }
        .remarks-item {
            background-color: #f8fafc;
            border-left: 3px solid #0ea5e9;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8rem;
            color: #334155;
            font-weight: 500;
            line-height: 1.3;
            word-break: break-word;
            white-space: normal;
            transition: all 0.2s ease;
            text-align: left;
        }
        .remarks-item:hover {
            background-color: #f0f9ff;
            border-left-color: #0284c7;
            transform: translateX(1px);
        }
        
        /* Interactive sort headers styling */
        .sortable-header {
            position: relative;
            transition: background-color 0.2s ease;
        }
        .sortable-header:hover {
            background-color: #cbd5e1 !important;
            color: #0f172a !important;
        }

        .ledger-sticky-panel {
            position: sticky;
            top: 60px;
            z-index: 1010;
            background-color: #fff;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }
        .table-custom th {
            position: sticky !important;
            top: var(--ledger-table-top, 140px) !important;
            z-index: 990 !important;
        }

        /* Control Bar & Input Styling Matching Attendance.aspx */
        .calc-controls-container {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            justify-content: space-between;
            width: 100%;
        }
        .calc-left-group {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            flex-grow: 1;
        }
        .calc-control-item {
            margin-right: 12px;
            margin-bottom: 6px;
            min-width: 110px;
            flex: 1 1 auto;
        }
        .calc-control-item-category {
            margin-right: 12px;
            margin-bottom: 6px;
            min-width: 160px;
            flex: 1.5 1 auto;
        }
        .calc-right-group {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            margin-bottom: 6px;
        }
        
        .calc-left-group select.form-control, 
        .calc-left-group input.form-control {
            height: 38px !important;
            font-size: 0.9rem;
            border-radius: 4px;
            border: 1px solid #d1d3e2;
            color: #111827;
            font-weight: 500;
            box-shadow: inset 0 1px 2px rgba(0,0,0,0.05);
        }
        .calc-left-group select.form-control:focus, 
        .calc-left-group input.form-control:focus {
            border-color: #4f46e5;
            box-shadow: 0 0 0 0.2rem rgba(79,70,229,0.25);
        }

        /* Modern Floating Rich Tooltips for Export Actions */
        .export-tooltip-wrapper {
            position: relative;
            display: inline-flex;
            align-items: center;
        }
        .export-tooltip-wrapper .custom-tooltip-box {
            visibility: hidden;
            opacity: 0;
            position: absolute;
            top: calc(100% + 10px);
            left: 50%;
            transform: translateX(-50%) translateY(-6px);
            width: 280px;
            background: #0f172a;
            color: #f8fafc;
            text-align: left;
            padding: 12px 14px;
            border-radius: 10px;
            box-shadow: 0 12px 28px -4px rgba(0, 0, 0, 0.35), 0 8px 12px -6px rgba(0, 0, 0, 0.2);
            font-size: 0.825rem;
            line-height: 1.45;
            z-index: 2000;
            pointer-events: none;
            transition: opacity 0.2s cubic-bezier(0.16, 1, 0.3, 1), transform 0.2s cubic-bezier(0.16, 1, 0.3, 1), visibility 0.2s;
            border: 1px solid rgba(255, 255, 255, 0.15);
        }
        /* Upward arrow pointing to the button */
        .export-tooltip-wrapper .custom-tooltip-box::after {
            content: "";
            position: absolute;
            bottom: 100%;
            left: 50%;
            margin-left: -6px;
            border-width: 6px;
            border-style: solid;
            border-color: transparent transparent #0f172a transparent;
        }
        .export-tooltip-wrapper:hover .custom-tooltip-box,
        .export-tooltip-wrapper:focus-within .custom-tooltip-box {
            visibility: visible;
            opacity: 1;
            transform: translateX(-50%) translateY(0);
        }
        .tooltip-card-title {
            display: flex;
            align-items: center;
            gap: 7px;
            font-weight: 800;
            font-size: 0.85rem;
            margin-bottom: 6px;
        }
        .tooltip-card-desc {
            color: #cbd5e1;
            font-size: 0.785rem;
            margin-bottom: 0;
            line-height: 1.4;
        }
    </style>

    <div id="toast-container"></div>

    <div id="loadingOverlay">
        <div class="spinner-border-custom" role="status"></div>
        <div style="margin-top: 16px; font-size: 1.1rem; font-weight: 700; color: #0f172a;">Loading Ledger Data...</div>
    </div>

    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2><i class="fas fa-book text-info mr-2"></i>Leave Ledger</h2>
        <div class="d-flex align-items-center gap-2">
            <asp:Panel ID="pnlHolidayBadge" runat="server" CssClass="info-badge badge-holiday" Visible="false">
                <i class="fas fa-calendar-alt mr-1"></i> Holidays: <asp:Label ID="lblHolidays" runat="server"></asp:Label>
            </asp:Panel>
            <asp:Panel ID="pnlGlobalAdjustBadge" runat="server" CssClass="info-badge badge-adjust" Visible="false">
                <i class="fas fa-adjust mr-1"></i> Global Adjust: <asp:Label ID="lblGlobalAdjust" runat="server"></asp:Label>
            </asp:Panel>
        </div>
    </div>

    <div class="card shadow-sm border-0 rounded-lg mb-3 ledger-sticky-panel">
        <div class="card-body py-2 px-3 bg-white text-dark">
            <div class="calc-controls-container">
                <!-- Left Side: Dropdowns and Search inputs -->
                <div class="calc-left-group">
                    <!-- Year selector -->
                    <div class="calc-control-item">
                        <label class="form-label font-weight-bold mb-1 text-gray-800">
                            <i class="fas fa-calendar mr-1 text-primary"></i> Year
                        </label>
                        <asp:DropDownList ID="ddlYear" runat="server" CssClass="form-control" AutoPostBack="true" onchange="if (typeof updateLedgerMonthYearConstraints === 'function') updateLedgerMonthYearConstraints(activeMinViewDate, activeMaxViewDate); showLoading();"></asp:DropDownList>
                    </div>
                    
                    <!-- Month selector -->
                    <div class="calc-control-item">
                        <label class="form-label font-weight-bold mb-1 text-gray-800">
                            <i class="fas fa-calendar-alt mr-1 text-primary"></i> Month
                        </label>
                        <asp:DropDownList ID="ddlMonth" runat="server" CssClass="form-control" AutoPostBack="true" onchange="showLoading();">
                            <asp:ListItem Value="1">Jan</asp:ListItem>
                            <asp:ListItem Value="2">Feb</asp:ListItem>
                            <asp:ListItem Value="3">Mar</asp:ListItem>
                            <asp:ListItem Value="4">Apr</asp:ListItem>
                            <asp:ListItem Value="5">May</asp:ListItem>
                            <asp:ListItem Value="6">Jun</asp:ListItem>
                            <asp:ListItem Value="7">Jul</asp:ListItem>
                            <asp:ListItem Value="8">Aug</asp:ListItem>
                            <asp:ListItem Value="9">Sep</asp:ListItem>
                            <asp:ListItem Value="10">Oct</asp:ListItem>
                            <asp:ListItem Value="11">Nov</asp:ListItem>
                            <asp:ListItem Value="12">Dec</asp:ListItem>
                        </asp:DropDownList>
                    </div>
                    
                    <!-- Category selector -->
                    <div class="calc-control-item-category">
                        <label class="form-label font-weight-bold mb-1 text-gray-800">
                            <i class="fas fa-th-list mr-1 text-primary"></i> Category
                        </label>
                        <asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-control" AutoPostBack="true" onchange="showLoading();" OnSelectedIndexChanged="ddlCategory_SelectedIndexChanged">
                            <asp:ListItem Value="All">All Categories</asp:ListItem>
                        </asp:DropDownList>
                    </div>

                    <!-- Contract Period selector -->
                    <asp:PlaceHolder ID="phContract" runat="server" Visible="false">
                        <div class="calc-control-item-category">
                            <label class="form-label font-weight-bold mb-1 text-gray-800">
                                <i class="fas fa-file-contract mr-1 text-primary"></i> Contract Period
                            </label>
                            <asp:DropDownList ID="ddlContract" runat="server" CssClass="form-control" AutoPostBack="true" onchange="showLoading();">
                            </asp:DropDownList>
                        </div>
                    </asp:PlaceHolder>
                    
                    <!-- Search input -->
                    <div class="calc-control-item-category" style="min-width: 220px;">
                        <label class="form-label font-weight-bold mb-1 text-gray-800">
                            <i class="fas fa-search mr-1 text-primary"></i> Search
                        </label>
                        <div class="input-group">
                            <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" placeholder="Search name / ID..."></asp:TextBox>
                            <div class="input-group-append">
                                <button type="button" class="btn btn-primary" onclick="showLoading(); document.getElementById('<%= btnGenerate.ClientID %>').click();" title="Search Database" style="height: 38px;">
                                    <i class="fas fa-search"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-auto" style="display: none;">
                        <asp:Button ID="btnGenerate" runat="server" Text="Generate" CssClass="btn btn-primary" OnClick="btnGenerate_Click" />
                    </div>
                </div>

                <!-- Right Side: Export Buttons -->
                <div class="calc-right-group">
                    <asp:PlaceHolder ID="phExportButtons" runat="server">
                        <div class="d-flex align-items-center gap-2">
                            <div class="export-tooltip-wrapper">
                                <button type="button" class="btn btn-outline-success d-inline-flex align-items-center font-weight-bold" onclick="exportExcel()" style="height: 38px;">
                                    <i class="fas fa-file-excel mr-2 text-success"></i>
                                    <span>Export Attendance</span>
                                </button>
                                <div class="custom-tooltip-box">
                                    <div class="tooltip-card-title text-success">
                                        <i class="fas fa-calendar-check"></i> Complete Attendance Data
                                    </div>
                                    <div class="tooltip-card-desc">
                                        Exports full month daily attendance (Days 1 to 31) with sticky date headers, present counts (1), and color tags (Green: Paid, Red: Unpaid, Yellow: Half/Carried).
                                    </div>
                                </div>
                            </div>
                            <div class="export-tooltip-wrapper">
                                <button type="button" class="btn btn-outline-primary d-inline-flex align-items-center font-weight-bold" onclick="exportSummaryExcel()" style="height: 38px;">
                                    <i class="fas fa-table mr-2 text-primary"></i>
                                    <span>Export Ledger</span>
                                </button>
                                <div class="custom-tooltip-box">
                                    <div class="tooltip-card-title text-primary">
                                        <i class="fas fa-file-invoice"></i> Leave Ledger Details
                                    </div>
                                    <div class="tooltip-card-desc">
                                        Exports the 15-column summary table (Opening balance, Paid, Half, Unpaid, Sat Cut, Closing, Present, Final & Remarks) for all currently filtered rows.
                                    </div>
                                </div>
                            </div>
                        </div>
                    </asp:PlaceHolder>
                </div>
            </div>
        </div>
    </div>

    <asp:Label ID="lblLedgerMessage" runat="server" Visible="false" CssClass="d-block mb-3"></asp:Label>

    <div class="table-responsive bg-white rounded-lg shadow-sm border" style="border-radius: 12px; overflow: visible !important;">
        <asp:GridView ID="gvLedger" runat="server" AutoGenerateColumns="False" CssClass="table table-hover table-custom mb-0" ClientIDMode="Static">
            <Columns>
                <asp:TemplateField HeaderText="S.No">
                    <ItemTemplate>
                        <%# Container.DataItemIndex + 1 %>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="ID" HeaderText="ID" />
                <asp:BoundField DataField="MasterID" HeaderText="Master ID" />
                <asp:BoundField DataField="Name" HeaderText="Name" ItemStyle-Font-Bold="true" />
                <asp:BoundField DataField="Department" HeaderText="Directorate" />
                <asp:BoundField DataField="Category" HeaderText="Category" />
                <asp:BoundField DataField="Opening" HeaderText="Opening" DataFormatString="{0:0.0}" />
                <asp:BoundField DataField="Paid" HeaderText="Paid (-)" ItemStyle-ForeColor="Red" />
                <asp:BoundField DataField="Half" HeaderText="Half" />
                <asp:BoundField DataField="Unpaid" HeaderText="Unpaid" />
                <asp:BoundField DataField="SatCut" HeaderText="Sat Cut" />
                <asp:BoundField DataField="Closing" HeaderText="Closing" DataFormatString="{0:0.0}" ItemStyle-CssClass="fw-bold bg-light" />
                <asp:BoundField DataField="PresentDays" HeaderText="Present" DataFormatString="{0:0.0}" />
                <asp:BoundField DataField="FinalDays" HeaderText="Final" DataFormatString="{0:0.0}" />
                <asp:TemplateField HeaderText="Remarks" ItemStyle-HorizontalAlign="Left" ItemStyle-CssClass="remarks-col">
                    <ItemTemplate>
                        <%# FormatRemarks(Eval("Remarks")) %>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <script>
        let activeMinViewDate = '<%= GetPocMinViewDateJson() %>';
        let activeMaxViewDate = '<%= GetPocMaxViewDateJson() %>';
        let userRole = <%= Convert.ToInt32(Session["Role"] ?? 0) %>;

        function updateLedgerMonthYearConstraints(minDateStr, maxDateStr) {
            if (userRole == 1 || userRole == 4) return; // Admins unrestricted
            if (!minDateStr && !maxDateStr) return; // Unrestricted

            const ddlY = document.getElementById('<%= ddlYear.ClientID %>');
            const ddlM = document.getElementById('<%= ddlMonth.ClientID %>');
            if (!ddlY || !ddlM) return;

            const minD = minDateStr ? new Date(minDateStr + 'T00:00:00') : null;
            const maxD = maxDateStr ? new Date(maxDateStr + 'T23:59:59') : null;
            const currentY = parseInt(ddlY.value);

            // 1. Update Month Selector Options for currently selected Year
            let firstValidMonth = null;
            Array.from(ddlM.options).forEach(opt => {
                const mIdx = parseInt(opt.value); // 1 to 12
                const optStart = new Date(currentY, mIdx - 1, 1, 0, 0, 0);
                const optEnd = new Date(currentY, mIdx, 0, 23, 59, 59);

                let allowed = true;
                if (minD && optEnd < minD) allowed = false;
                if (maxD && optStart > maxD) allowed = false;

                opt.disabled = !allowed;
                if (!allowed) {
                    opt.style.color = '#94a3b8';
                    opt.style.backgroundColor = '#f1f5f9';
                    opt.style.cursor = 'not-allowed';
                } else {
                    opt.style.color = '';
                    opt.style.backgroundColor = '';
                    opt.style.cursor = '';
                    if (firstValidMonth === null) firstValidMonth = opt.value;
                }
            });

            // If current selected month is disabled, switch to first valid month
            if (ddlM.options[ddlM.selectedIndex] && ddlM.options[ddlM.selectedIndex].disabled && firstValidMonth !== null) {
                ddlM.value = firstValidMonth;
            }

            // 2. Update Year Selector Options
            Array.from(ddlY.options).forEach(opt => {
                const yVal = parseInt(opt.value);
                const yStart = new Date(yVal, 0, 1, 0, 0, 0);
                const yEnd = new Date(yVal, 11, 31, 23, 59, 59);

                let allowed = true;
                if (minD && yEnd < minD) allowed = false;
                if (maxD && yStart > maxD) allowed = false;

                opt.disabled = !allowed;
                if (!allowed) {
                    opt.style.color = '#94a3b8';
                    opt.style.backgroundColor = '#f1f5f9';
                    opt.style.cursor = 'not-allowed';
                } else {
                    opt.style.color = '';
                    opt.style.backgroundColor = '';
                    opt.style.cursor = '';
                }
            });
        }

        function showLoading() {
            const overlay = document.getElementById("loadingOverlay");
            if (overlay) {
                overlay.style.display = "flex";
            }
        }

        function hideLoading() {
            const overlay = document.getElementById("loadingOverlay");
            if (overlay) {
                overlay.style.display = "none";
            }
        }

        // Upgraded Toast Notification System
        function showToast(msg, type = 'info') {
            let container = document.getElementById("toast-container");
            if (!container) {
                container = document.createElement("div");
                container.id = "toast-container";
                document.body.appendChild(container);
            }

            const toast = document.createElement("div");
            toast.className = `modern-toast toast-${type}`;
            
            let iconClass = "fas fa-info-circle";
            if (type === "success") iconClass = "fas fa-check-circle";
            else if (type === "warning") iconClass = "fas fa-exclamation-triangle";
            else if (type === "error") iconClass = "fas fa-times-circle";

            toast.innerHTML = `
                <div class="toast-icon"><i class="${iconClass}"></i></div>
                <div style="flex-grow: 1; padding-right: 8px;">${msg}</div>
                <button type="button" class="toast-close-btn" onclick="this.parentElement.classList.remove('toast-show'); setTimeout(() => this.parentElement.remove(), 400);">&times;</button>
            `;

            container.appendChild(toast);
            
            // Trigger reflow to run transition
            toast.offsetHeight;
            toast.classList.add("toast-show");

            // Auto dismiss
            setTimeout(() => {
                if (toast.parentElement) {
                    toast.classList.remove("toast-show");
                    toast.classList.add("toast-hide");
                    setTimeout(() => {
                        toast.remove();
                    }, 400);
                }
            }, 4000);
        }

        function showPop(msg) {
            let type = "info";
            let lowerMsg = msg.toLowerCase();
            if (lowerMsg.includes("success") || lowerMsg.includes("loaded")) {
                type = "success";
            } else if (lowerMsg.includes("error") || lowerMsg.includes("fail") || lowerMsg.includes("invalid")) {
                type = "error";
            } else if (lowerMsg.includes("warning")) {
                type = "warning";
            }
            showToast(msg, type);
        }

        document.addEventListener('keydown', function(event) {
            if (event.keyCode === 13 && event.target.tagName === 'INPUT') {
                event.preventDefault();
                if (event.target.id === '<%= txtSearch.ClientID %>') {
                    const btnGen = document.getElementById('<%= btnGenerate.ClientID %>');
                    if (btnGen) {
                        showLoading();
                        btnGen.click();
                    }
                }
                return false;
            }
        });

        function updateSNo() {
            const gvLedger = document.getElementById('gvLedger');
            if (!gvLedger) return;
            const rows = gvLedger.querySelectorAll('tr:not(:first-child)');
            let sNo = 1;
            rows.forEach(function(row) {
                if (row.style.display !== 'none' && row.cells.length > 0) {
                    row.cells[0].textContent = sNo++;
                }
            });
        }

        function sortGrid(colIdx, dir) {
            const gvLedger = document.getElementById('gvLedger');
            if (!gvLedger) return;
            const tbody = gvLedger.querySelector('tbody') || gvLedger;
            const rows = Array.from(gvLedger.querySelectorAll('tr:not(:first-child)'));
            
            rows.sort((a, b) => {
                const cellA = a.cells[colIdx];
                const cellB = b.cells[colIdx];
                if (!cellA || !cellB) return 0;
                
                const valA = cellA.innerText.trim().toLowerCase();
                const valB = cellB.innerText.trim().toLowerCase();
                
                // Try numeric sort if both values are valid numbers
                const numA = parseFloat(valA);
                const numB = parseFloat(valB);
                if (!isNaN(numA) && !isNaN(numB)) {
                    return dir === 'asc' ? numA - numB : numB - numA;
                }
                
                return dir === 'asc' ? valA.localeCompare(valB) : valB.localeCompare(valA);
            });
            
            // Re-append sorted rows to the tbody
            rows.forEach(row => tbody.appendChild(row));
            
            // Re-sequence serial numbers
            updateSNo();
        }

        function adjustStickyHeaderPosition() {
            const panel = document.querySelector('.ledger-sticky-panel');
            if (panel) {
                const height = panel.offsetHeight;
                document.documentElement.style.setProperty('--ledger-table-top', (60 + height) + 'px');
            }
        }
        window.addEventListener('resize', adjustStickyHeaderPosition);
        window.addEventListener('load', adjustStickyHeaderPosition);
        document.addEventListener('DOMContentLoaded', adjustStickyHeaderPosition);

        // Real-time client-side table row filtering and page-load notifications
        document.addEventListener("DOMContentLoaded", () => {
            if (typeof updateLedgerMonthYearConstraints === 'function') {
                updateLedgerMonthYearConstraints(activeMinViewDate, activeMaxViewDate);
            }

            const txtSearch = document.getElementById('<%= txtSearch.ClientID %>');
            const gvLedger = document.getElementById('gvLedger');
            
            if (txtSearch && gvLedger) {
                txtSearch.addEventListener('input', function() {
                    const query = this.value.toLowerCase().trim();
                    const rows = gvLedger.getElementsByTagName('tr');
                    
                    // Start from index 1 to skip header row
                    for (let i = 1; i < rows.length; i++) {
                        const row = rows[i];
                        if (row.cells.length < 5) continue; // Skip pager or empty rows
                        
                        const idText = row.cells[1] ? row.cells[1].innerText.toLowerCase() : '';
                        const masterIdText = row.cells[2] ? row.cells[2].innerText.toLowerCase() : '';
                        const nameText = row.cells[3] ? row.cells[3].innerText.toLowerCase() : '';
                        const deptText = row.cells[4] ? row.cells[4].innerText.toLowerCase() : '';
                        
                        if (idText.includes(query) || masterIdText.includes(query) || nameText.includes(query) || deptText.includes(query)) {
                            row.style.display = '';
                        } else {
                            row.style.display = 'none';
                        }
                    }
                    updateSNo();
                });
            }

            // Add sorting capability to headers: ID (1), Name (3), Directorate (4), Category (5)
            if (gvLedger) {
                const sortableIndices = [1, 3, 4, 5];
                const headerRow = gvLedger.querySelector('tr:first-child');
                if (headerRow) {
                    sortableIndices.forEach(index => {
                        const th = headerRow.cells[index];
                        if (th) {
                            th.style.cursor = 'pointer';
                            th.style.userSelect = 'none';
                            th.classList.add('sortable-header');
                            // Add Sort Icon container
                            th.innerHTML = th.textContent.trim() + ' <span class="sort-icon ml-1" style="color: #94a3b8; font-size: 0.75rem;"><i class="fas fa-sort"></i></span>';
                            th.setAttribute('data-sort-index', index);
                            th.setAttribute('data-sort-dir', 'none');
                            
                            th.addEventListener('click', function() {
                                const colIdx = parseInt(this.getAttribute('data-sort-index'));
                                let currentDir = this.getAttribute('data-sort-dir');
                                let nextDir = (currentDir === 'asc') ? 'desc' : 'asc';
                                
                                // Reset all other headers
                                sortableIndices.forEach(idx => {
                                    const otherTh = headerRow.cells[idx];
                                    if (otherTh && idx !== colIdx) {
                                        otherTh.setAttribute('data-sort-dir', 'none');
                                        const icon = otherTh.querySelector('.sort-icon i');
                                        if (icon) {
                                            icon.className = 'fas fa-sort';
                                            icon.style.color = '#94a3b8';
                                        }
                                    }
                                });
                                
                                // Set current header direction
                                this.setAttribute('data-sort-dir', nextDir);
                                const icon = this.querySelector('.sort-icon i');
                                if (icon) {
                                    icon.className = (nextDir === 'asc') ? 'fas fa-sort-up' : 'fas fa-sort-down';
                                    icon.style.color = '#4f46e5'; // active color
                                }
                                
                                // Perform sort
                                sortGrid(colIdx, nextDir);
                            });
                        }
                    });
                }
            }

            // Check if this page load is a postback (e.g. dropdown changed or search submitted)
            const isPostBack = <%= Page.IsPostBack.ToString().ToLower() %>;
            if (isPostBack) {
                const year = document.getElementById('<%= ddlYear.ClientID %>').value;
                const monthSelect = document.getElementById('<%= ddlMonth.ClientID %>');
                const monthText = monthSelect.options[monthSelect.selectedIndex].text;
                const category = document.getElementById('<%= ddlCategory.ClientID %>').value;
                
                let text = `Loaded ledger for ${monthText} ${year} (${category})`;
                <% if (ddlContract.Visible) { %>
                    const contractSelect = document.getElementById('<%= ddlContract.ClientID %>');
                    if (contractSelect && contractSelect.selectedIndex >= 0) {
                        text += ` - ${contractSelect.options[contractSelect.selectedIndex].text}`;
                    }
                <% } %>
                showPop(text + " successfully!");
            }
            
            // Show loading on page unload (postback submit)
            const form = document.getElementById('form1');
            if (form) {
                form.addEventListener('submit', function() {
                    showLoading();
                });
            }
        });

        async function exportExcel() {
            const yVal = document.getElementById('<%= ddlYear.ClientID %>').value;
            const mVal = document.getElementById('<%= ddlMonth.ClientID %>').value;
            const catVal = document.getElementById('<%= ddlCategory.ClientID %>').value;
            const searchVal = document.getElementById('<%= txtSearch.ClientID %>').value;
            
            let contractVal = "";
            const contractEl = document.getElementById('<%= ddlContract.ClientID %>');
            if (contractEl && contractEl.style.display !== "none") {
                contractVal = contractEl.value;
            }

            showLoading();

            try {
                const response = await fetch('Ledger.aspx/GetFullAttendanceSheetData', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=utf-8' },
                    body: JSON.stringify({
                        year: parseInt(yVal),
                        month: parseInt(mVal),
                        category: catVal,
                        contract: contractVal,
                        search: searchVal
                    })
                });

                if (!response.ok) {
                    throw new Error("HTTP " + response.status + ": " + response.statusText);
                }

                const data = await response.json();
                hideLoading();

                let res = data.d;
                if (typeof res === "string") {
                    res = JSON.parse(res);
                }
                if (!res || !res.success) {
                    alert("Error: " + (res && res.error ? res.error : "Failed to fetch attendance data"));
                    return;
                }
                if (!res.rows || res.rows.length === 0) {
                    alert("No data available to export!");
                    return;
                }

                const days = res.daysInMonth;
                const monthName = res.monthName;
                const year = res.year;

                if (typeof ExcelJS !== "undefined") {
                    const wb = new ExcelJS.Workbook();
                    wb.creator = "Attendance System";
                    wb.created = new Date();

                    const ws = wb.addWorksheet("Attendance Sheet", {
                        views: [
                            { state: 'frozen', ySplit: 2, activePane: 'bottomLeft', topLeftCell: 'A3' }
                        ]
                    });

                    // Base employee columns
                    const baseColumns = [
                        { header: "S.No", width: 7 },
                        { header: "Emp ID", width: 12 },
                        { header: "Master ID", width: 14 },
                        { header: "Name", width: 26 },
                        { header: "Directorate", width: 22 },
                        { header: "Category", width: 24 }
                    ];

                    // Date columns: 1, 2, 3...
                    for (let d = 1; d <= days; d++) {
                        baseColumns.push({ header: String(d), width: 14 });
                    }

                    // Summary columns
                    baseColumns.push(
                        { header: "Opening", width: 10 },
                        { header: "Paid (-)", width: 10 },
                        { header: "Half", width: 8 },
                        { header: "Unpaid", width: 10 },
                        { header: "Sat Cut", width: 10 },
                        { header: "Closing", width: 10 },
                        { header: "Present", width: 10 },
                        { header: "Final", width: 10 },
                        { header: "Remarks", width: 35 }
                    );

                    const totalCols = baseColumns.length;

                    // Row 1: Merged Title Header
                    const titleRow = ws.addRow([`Complete Monthly Attendance Sheet - ${monthName} ${year}`]);
                    ws.mergeCells(1, 1, 1, totalCols);
                    titleRow.height = 30;
                    const titleCell = ws.getCell(1, 1);
                    titleCell.font = { name: 'Calibri', size: 14, bold: true, color: { argb: 'FFFFFFFF' } };
                    titleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E293B' } };
                    titleCell.alignment = { horizontal: 'center', vertical: 'middle' };

                    // Row 2: Column Headers
                    const headerTitles = baseColumns.map(c => c.header);
                    const headerRow = ws.addRow(headerTitles);
                    headerRow.height = 24;

                    for (let c = 1; c <= totalCols; c++) {
                        const cell = headerRow.getCell(c);
                        cell.font = { name: 'Calibri', size: 11, bold: true, color: { argb: 'FFFFFFFF' } };
                        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF0284C7' } };
                        cell.alignment = { horizontal: 'center', vertical: 'middle', wrapText: true };
                        cell.border = {
                            top: { style: 'thin', color: { argb: 'FFCBD5E1' } },
                            bottom: { style: 'medium', color: { argb: 'FF0F172A' } },
                            left: { style: 'thin', color: { argb: 'FFCBD5E1' } },
                            right: { style: 'thin', color: { argb: 'FFCBD5E1' } }
                        };
                    }

                    // Set column widths
                    for (let c = 1; c <= totalCols; c++) {
                        ws.getColumn(c).width = baseColumns[c - 1].width;
                    }

                    // Add Data Rows
                    res.rows.forEach((r, idx) => {
                        const rowVals = [
                            idx + 1,
                            r.ID,
                            r.MasterId,
                            r.Name,
                            r.Department,
                            r.Category
                        ];

                        for (let d = 0; d < days; d++) {
                            let st = r.DailyStatus[d] || "-";
                            rowVals.push(st === "1" ? 1 : st);
                        }

                        rowVals.push(
                            r.Opening,
                            r.Paid,
                            r.Half,
                            r.Unpaid,
                            r.SatCut,
                            r.Closing,
                            r.PresentDays,
                            r.FinalDays,
                            r.Remarks
                        );

                        const dataRow = ws.addRow(rowVals);
                        dataRow.height = 20;

                        // Style cells in the row
                        for (let c = 1; c <= totalCols; c++) {
                            const cell = dataRow.getCell(c);
                            const val = cell.value;
                            const valStr = String(val || "").trim();

                            cell.font = { name: 'Calibri', size: 10, color: { argb: 'FF0F172A' } };
                            cell.border = {
                                top: { style: 'thin', color: { argb: 'FFE2E8F0' } },
                                bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
                                left: { style: 'thin', color: { argb: 'FFE2E8F0' } },
                                right: { style: 'thin', color: { argb: 'FFE2E8F0' } }
                            };

                            if (c === 4 || c === 5 || c === 6 || c === totalCols) {
                                cell.alignment = { horizontal: 'left', vertical: 'middle' };
                            } else {
                                cell.alignment = { horizontal: 'center', vertical: 'middle' };
                            }

                            // Day columns formatting & colors (cols 7 to 6 + days)
                            if (c >= 7 && c <= (6 + days)) {
                                if (val === 1 || valStr === "1" || valStr.toLowerCase() === "present") {
                                    cell.value = 1;
                                    cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: 'FF0F172A' } };
                                } else if (valStr === "Paid Leave" || valStr === "Paired Paid" || valStr.toLowerCase() === "paid") {
                                    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFDCFCE7' } }; // Light Green
                                    cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: 'FF166534' } }; // Dark Green
                                } else if (valStr === "Unpaid Leave" || valStr === "Paired Unpaid" || valStr === "Absent" || valStr.toLowerCase() === "unpaid") {
                                    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFEE2E2' } }; // Light Red
                                    cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: 'FF991B1B' } }; // Dark Red
                                } else if (valStr === "Half Day" || valStr === "Carried" || valStr === "Pending Pairing") {
                                    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFEF9C3' } }; // Light Yellow
                                    cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: 'FF854D0E' } }; // Golden Brown
                                } else if (valStr === "Holiday") {
                                    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E7FF' } }; // Soft Indigo
                                    cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: 'FF3730A3' } }; // Dark Indigo
                                } else if (valStr === "-") {
                                    cell.font = { name: 'Calibri', size: 10, color: { argb: 'FF94A3B8' } };
                                }
                            }

                            // Numeric Summary columns formatting
                            const closingColIdx = totalCols - 3;
                            const paidColIdx = 7 + days + 1;
                            if (c === closingColIdx) {
                                cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF1F5F9' } };
                                cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: 'FF0F172A' } };
                            } else if (c === paidColIdx) {
                                cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: 'FFDC2626' } };
                            }
                        }
                    });

                    const buffer = await wb.xlsx.writeBuffer();
                    const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
                    const url = window.URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = `Complete_Attendance_Sheet_${monthName}_${year}.xlsx`;
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                    window.URL.revokeObjectURL(url);
                } else {
                    // Fallback to SheetJS
                    const AOA = [];
                    AOA.push([`Complete Monthly Attendance Sheet - ${monthName} ${year}`]);
                    const headers = ["S.No", "Emp ID", "Master ID", "Name", "Directorate", "Category"];
                    for (let d = 1; d <= days; d++) headers.push(String(d));
                    headers.push("Opening", "Paid (-)", "Half", "Unpaid", "Sat Cut", "Closing", "Present", "Final", "Remarks");
                    AOA.push(headers);

                    res.rows.forEach((r, idx) => {
                        const row = [idx + 1, r.ID, r.MasterId, r.Name, r.Department, r.Category];
                        for (let d = 0; d < days; d++) {
                            let st = r.DailyStatus[d] || "-";
                            row.push(st === "1" ? 1 : st);
                        }
                        row.push(r.Opening, r.Paid, r.Half, r.Unpaid, r.SatCut, r.Closing, r.PresentDays, r.FinalDays, r.Remarks);
                        AOA.push(row);
                    });

                    const ws = XLSX.utils.aoa_to_sheet(AOA);
                    const wb = XLSX.utils.book_new();
                    ws["!merges"] = [{ s: { r: 0, c: 0 }, e: { r: 0, c: headers.length - 1 } }];
                    ws["!freeze"] = { xSplit: "0", ySplit: "2", topLeftCell: "A3", activePane: "bottomLeft", state: "frozen" };
                    XLSX.utils.book_append_sheet(wb, ws, "Attendance Sheet");
                    XLSX.writeFile(wb, `Complete_Attendance_Sheet_${monthName}_${year}.xlsx`);
                }
            } catch (err) {
                hideLoading();
                console.error("Export Error:", err);
                alert("Error generating complete attendance sheet: " + err.message);
            }
        }

        async function exportSummaryExcel() {
            const gv = document.getElementById("gvLedger");
            if (!gv || gv.rows.length <= 1) {
                alert("No ledger data available to export!");
                return;
            }

            const ySelect = document.getElementById('<%= ddlYear.ClientID %>');
            const mSelect = document.getElementById('<%= ddlMonth.ClientID %>');
            const yVal = ySelect ? ySelect.options[ySelect.selectedIndex].text : '';
            const mVal = mSelect ? mSelect.options[mSelect.selectedIndex].text : '';

            if (typeof ExcelJS !== "undefined") {
                const wb = new ExcelJS.Workbook();
                wb.creator = "Attendance System";
                wb.created = new Date();

                const ws = wb.addWorksheet("Ledger Summary", {
                    views: [
                        { state: 'frozen', ySplit: 2, activePane: 'bottomLeft', topLeftCell: 'A3' }
                    ]
                });

                const headerRowEl = gv.rows[0];
                const headers = [];
                for (let c = 0; c < headerRowEl.cells.length; c++) {
                    headers.push(headerRowEl.cells[c].innerText.replace(/[▲▼]/g, '').trim());
                }
                const totalCols = headers.length;

                // Row 1: Merged Title
                const titleRow = ws.addRow([`Leave Ledger Summary - ${mVal} ${yVal}`]);
                ws.mergeCells(1, 1, 1, totalCols);
                titleRow.height = 30;
                const titleCell = ws.getCell(1, 1);
                titleCell.font = { name: 'Calibri', size: 14, bold: true, color: { argb: 'FFFFFFFF' } };
                titleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E293B' } };
                titleCell.alignment = { horizontal: 'center', vertical: 'middle' };

                // Row 2: Column Headers
                const headerRow = ws.addRow(headers);
                headerRow.height = 24;
                for (let c = 1; c <= totalCols; c++) {
                    const cell = headerRow.getCell(c);
                    cell.font = { name: 'Calibri', size: 11, bold: true, color: { argb: 'FFFFFFFF' } };
                    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF0284C7' } };
                    cell.alignment = { horizontal: 'center', vertical: 'middle' };
                    cell.border = {
                        top: { style: 'thin', color: { argb: 'FFCBD5E1' } },
                        bottom: { style: 'medium', color: { argb: 'FF0F172A' } },
                        left: { style: 'thin', color: { argb: 'FFCBD5E1' } },
                        right: { style: 'thin', color: { argb: 'FFCBD5E1' } }
                    };
                }

                // Set column widths
                const colWidths = [6, 11, 14, 26, 22, 24, 10, 10, 8, 10, 10, 11, 10, 10, 35];
                for (let c = 1; c <= totalCols; c++) {
                    ws.getColumn(c).width = colWidths[c - 1] || 15;
                }

                // Data rows
                let sNo = 1;
                for (let r = 1; r < gv.rows.length; r++) {
                    const row = gv.rows[r];
                    if (row.style.display === "none") continue;
                    if (row.cells.length < totalCols) continue;

                    const rowData = [];
                    for (let c = 0; c < row.cells.length; c++) {
                        let cellText = row.cells[c].innerText.trim();
                        if (c === 0) {
                            rowData.push(sNo++);
                        } else if (c >= 6 && c <= 13) {
                            let num = parseFloat(cellText);
                            rowData.push(isNaN(num) ? cellText : num);
                        } else {
                            rowData.push(cellText);
                        }
                    }

                    const dataRow = ws.addRow(rowData);
                    dataRow.height = 20;

                    for (let c = 1; c <= totalCols; c++) {
                        const cell = dataRow.getCell(c);
                        cell.font = { name: 'Calibri', size: 10, color: { argb: 'FF0F172A' } };
                        cell.border = {
                            top: { style: 'thin', color: { argb: 'FFE2E8F0' } },
                            bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
                            left: { style: 'thin', color: { argb: 'FFE2E8F0' } },
                            right: { style: 'thin', color: { argb: 'FFE2E8F0' } }
                        };

                        if (c === 4 || c === 5 || c === 6 || c === totalCols) {
                            cell.alignment = { horizontal: 'left', vertical: 'middle' };
                        } else {
                            cell.alignment = { horizontal: 'center', vertical: 'middle' };
                        }

                        if (c === 8) {
                            cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: 'FFDC2626' } };
                        } else if (c === 12) {
                            cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF1F5F9' } };
                            cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: 'FF0F172A' } };
                        }
                    }
                }

                const buffer = await wb.xlsx.writeBuffer();
                const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `Leave_Ledger_Summary_${mVal}_${yVal}.xlsx`;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                window.URL.revokeObjectURL(url);
            } else {
                // Fallback to SheetJS
                const AOA = [];
                AOA.push([`Leave Ledger Summary - ${mVal} ${yVal}`]);
                const headerRow = gv.rows[0];
                const headers = [];
                for (let c = 0; c < headerRow.cells.length; c++) {
                    headers.push(headerRow.cells[c].innerText.replace(/[▲▼]/g, '').trim());
                }
                AOA.push(headers);

                let sNo = 1;
                for (let r = 1; r < gv.rows.length; r++) {
                    const row = gv.rows[r];
                    if (row.style.display === "none") continue;
                    if (row.cells.length < headers.length) continue;

                    const rowData = [];
                    for (let c = 0; c < row.cells.length; c++) {
                        let cellText = row.cells[c].innerText.trim();
                        if (c === 0) rowData.push(sNo++);
                        else if (c >= 6 && c <= 13) {
                            let num = parseFloat(cellText);
                            rowData.push(isNaN(num) ? cellText : num);
                        } else rowData.push(cellText);
                    }
                    AOA.push(rowData);
                }

                const ws = XLSX.utils.aoa_to_sheet(AOA);
                const wb = XLSX.utils.book_new();
                ws["!merges"] = [{ s: { r: 0, c: 0 }, e: { r: 0, c: headers.length - 1 } }];
                ws["!freeze"] = { xSplit: "0", ySplit: "2", topLeftCell: "A3", activePane: "bottomLeft", state: "frozen" };
                XLSX.utils.book_append_sheet(wb, ws, "Ledger Summary");
                XLSX.writeFile(wb, `Leave_Ledger_Summary_${mVal}_${yVal}.xlsx`);
            }
        }
    </script>
</asp:Content>
