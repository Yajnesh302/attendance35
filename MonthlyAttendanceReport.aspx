<%@ Page Title="Monthly Attendance Report" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="MonthlyAttendanceReport.aspx.cs" Inherits="AttendanceApp.MonthlyAttendanceReport" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Monthly Attendance &amp; Recommendation Report
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* Modern Control Toolbar */
        .report-toolbar-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 16px;
            padding: 18px 22px;
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.04);
            margin-bottom: 24px;
        }

        .filter-row {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            gap: 14px;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .filter-label {
            font-size: 0.78rem;
            font-weight: 800;
            color: #334155;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .form-select-custom, .form-input-custom {
            height: 38px;
            border-radius: 8px;
            border: 1.5px solid #cbd5e1;
            padding: 0 12px;
            font-size: 0.88rem;
            font-weight: 600;
            color: #0f172a;
            background-color: #ffffff;
            transition: all 0.15s ease;
            outline: none;
        }

        .form-select-custom:focus, .form-input-custom:focus {
            border-color: #6366f1;
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.15);
        }

        /* Action Buttons */
        .btn-action-primary {
            height: 38px;
            padding: 0 18px;
            background: linear-gradient(135deg, #4f46e5, #4338ca);
            color: #ffffff !important;
            border: none;
            border-radius: 8px;
            font-weight: 700;
            font-size: 0.88rem;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(79, 70, 229, 0.25);
            transition: all 0.2s ease;
            text-decoration: none !important;
        }

        .btn-action-primary:hover {
            background: linear-gradient(135deg, #4338ca, #3730a3);
            transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(79, 70, 229, 0.35);
        }

        .btn-action-word {
            height: 38px;
            padding: 0 18px;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            color: #ffffff !important;
            border: none;
            border-radius: 8px;
            font-weight: 700;
            font-size: 0.88rem;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);
            transition: all 0.2s ease;
        }

        .btn-action-word:hover {
            background: linear-gradient(135deg, #1d4ed8, #1e40af);
            transform: translateY(-1px);
        }

        .btn-action-secondary {
            height: 38px;
            padding: 0 16px;
            background: #f1f5f9;
            color: #475569 !important;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-weight: 700;
            font-size: 0.88rem;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
            text-decoration: none !important;
        }

        .btn-action-secondary:hover {
            background: #e2e8f0;
            color: #0f172a !important;
        }

        /* Column Selector Dropdown Menu */
        .col-dropdown-menu {
            display: none;
            position: absolute;
            top: 100%;
            right: 0;
            z-index: 1000;
            min-width: 290px;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            padding: 12px;
            box-shadow: 0 15px 30px rgba(0,0,0,0.12);
            margin-top: 6px;
        }

        .col-dropdown-menu.show {
            display: block;
        }

        .col-item-label {
            display: flex;
            align-items: center;
            gap: 9px;
            padding: 6px 8px;
            font-size: 0.82rem;
            font-weight: 600;
            color: #1e293b;
            cursor: pointer;
            border-radius: 6px;
            user-select: none;
            transition: background 0.15s;
            margin-bottom: 2px;
        }

        .col-item-label:hover {
            background: #f8fafc;
        }

        /* Master Landscape Sheet Wrapper */
        .landscape-viewport {
            width: 100%;
            overflow-x: auto;
            display: flex;
            justify-content: center;
            padding-bottom: 40px;
        }

        .landscape-sheet {
            width: 100%;
            max-width: 1150px;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.06);
            border-radius: 6px;
            padding: 36px 44px;
            box-sizing: border-box;
            font-family: Arial, sans-serif !important;
            color: #000000 !important;
        }

        /* Typography matching Word document */
        .rep-top-line1 {
            font-family: Arial, sans-serif !important;
            font-weight: bold !important;
            margin-bottom: 6px;
            line-height: 1.3;
        }

        .rep-top-line2 {
            font-family: Arial, sans-serif !important;
            font-weight: bold !important;
            margin-bottom: 12px;
            line-height: 1.35;
        }

        .rep-directorate-line {
            font-family: Arial, sans-serif !important;
            font-weight: bold !important;
            font-size: 11pt;
            margin-bottom: 10px;
            text-align: left;
        }

        /* Grid Table matching Word document exactly */
        .rep-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            margin-bottom: 16px;
            border: 0.5pt solid #000000;
            font-family: Arial, sans-serif !important;
        }

        .rep-table th, .rep-table td {
            border: 0.5pt solid #000000;
            padding: 5px 6px;
            font-size: 10pt;
            vertical-align: middle;
            font-family: Arial, sans-serif !important;
            color: #000000;
        }

        .rep-table th {
            font-weight: bold;
            text-align: center;
            background-color: #ffffff;
            line-height: 1.25;
        }

        .rep-table td {
            line-height: 1.3;
            text-align: center;
        }

        .cell-left { text-align: left !important; }
        .cell-center { text-align: center !important; }
        .cell-right { text-align: right !important; }
        .cell-bold { font-weight: bold !important; }

        /* Editable Date Inputs inside cells */
        .cell-date-wrap {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 100%;
            position: relative;
        }

        .cell-inline-date {
            border: 1px solid #cbd5e1;
            background: #f8fafc;
            width: 100%;
            max-width: 130px;
            height: 27px;
            text-align: center;
            font-family: Arial, sans-serif !important;
            font-size: 8.5pt;
            font-weight: 500;
            color: #0f172a;
            padding: 1px 3px;
            border-radius: 5px;
            outline: none;
            transition: all 0.15s ease;
            cursor: pointer;
        }

        .cell-inline-date:hover {
            border-color: #6366f1;
            background-color: #ffffff;
        }

        .cell-inline-date:focus {
            border-color: #4f46e5;
            background-color: #ffffff;
            box-shadow: 0 0 0 2px rgba(79, 70, 229, 0.2);
        }

        .print-only {
            display: none;
        }

        /* Calendar Picker Indicator Styling */
        input[type="date"] {
            cursor: pointer;
        }

        input[type="date"]::-webkit-calendar-picker-indicator {
            cursor: pointer;
            opacity: 0.85;
            padding: 2px;
            border-radius: 4px;
            transition: all 0.15s ease;
        }

        input[type="date"]::-webkit-calendar-picker-indicator:hover {
            opacity: 1;
            background-color: rgba(99, 102, 241, 0.1);
        }

        /* Bottom Certificate & Signatures */
        .rep-cert-paragraph {
            font-family: Arial, sans-serif !important;
            line-height: 1.5;
            margin-top: 14px;
            margin-bottom: 24px;
        }

        .rep-signatures-wrap {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-top: 20px;
            font-family: Arial, sans-serif !important;
            line-height: 1.4;
        }

        .rep-sig-left {
            text-align: left;
        }

        .rep-sig-right {
            text-align: right;
        }

        .rep-to-block {
            margin-top: 24px;
            text-align: left;
            font-family: Arial, sans-serif !important;
            line-height: 1.4;
        }

        /* PRINT MEDIA STYLES - Exact Landscape Layout */
        @media print {
            @page {
                size: landscape;
                margin: 8mm 12mm 8mm 12mm;
            }

            body, html {
                background: #ffffff !important;
                color: #000000 !important;
                margin: 0 !important;
                padding: 0 !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .no-print, .report-toolbar-card, .btn-action-primary, .btn-action-word, .btn-action-secondary,
            .navbar, .navbar-custom, .app-sidebar, #toast-container, .topbar {
                display: none !important;
            }

            .print-only {
                display: inline !important;
                font-family: Arial, sans-serif !important;
                font-size: 10pt !important;
                color: #000000 !important;
            }

            .container-main, .container-fluid {
                padding: 0 !important;
                margin: 0 !important;
                max-width: 100% !important;
            }

            .landscape-viewport {
                padding: 0 !important;
                overflow: visible !important;
                display: block !important;
            }

            .landscape-sheet {
                border: none !important;
                box-shadow: none !important;
                padding: 0 !important;
                max-width: 100% !important;
                width: 100% !important;
                margin: 0 !important;
            }

            .cell-inline-date {
                display: none !important;
            }

            .rep-table {
                page-break-inside: auto;
            }

            .rep-table tr {
                page-break-inside: avoid;
                page-break-after: auto;
            }

            .rep-table thead {
                display: table-header-group;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid p-0">
        
        <!-- NON-PRINTING ACTION TOOLBAR -->
        <div class="report-toolbar-card no-print">
            <div class="d-flex align-items-center justify-content-between flex-wrap mb-3" style="gap: 12px;">
                <div class="d-flex align-items-center" style="gap: 12px;">
                    <a href="Reports.aspx" class="btn-action-secondary" title="Return to Reports Hub">
                        <i class="fas fa-arrow-left"></i> Reports Hub
                    </a>
                    <h5 class="m-0 font-weight-bold text-dark">
                        <i class="fas fa-file-invoice-dollar mr-2 text-primary"></i> Monthly Attendance &amp; Recommendation Report
                    </h5>
                </div>
                <div class="d-flex align-items-center" style="gap: 10px;">
                    <!-- Column Visibility Dropdown -->
                    <div style="position: relative;">
                        <button type="button" class="btn-action-secondary" onclick="toggleColDropdown(event)" title="Toggle Columns">
                            <i class="fas fa-columns"></i> Columns <i class="fas fa-chevron-down ml-1" style="font-size: 0.75rem;"></i>
                        </button>
                        <div class="col-dropdown-menu" id="colDropdownMenu">
                            <div class="d-flex justify-content-between align-items-center mb-2 pb-1 border-bottom">
                                <span class="font-weight-bold text-dark" style="font-size: 0.8rem;">Column Visibility</span>
                                <button type="button" class="btn btn-link btn-sm p-0 font-weight-bold" style="font-size: 0.75rem;" onclick="resetAllColumns()">Show All</button>
                            </div>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-cat" checked onchange="toggleCol('col-cat', this.checked)" /> <span>Category</span></label>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-manpower" checked onchange="toggleCol('col-manpower', this.checked)" /> <span>Manpower</span></label>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-id" checked onchange="toggleCol('col-id', this.checked)" /> <span>ID No.</span></label>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-name" checked onchange="toggleCol('col-name', this.checked)" /> <span>Name of the Individual</span></label>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-attended" checked onchange="toggleCol('col-attended', this.checked)" /> <span>Total man days attended</span></label>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-not-attended" checked onchange="toggleCol('col-not-attended', this.checked)" /> <span>Total days not attended</span></label>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-remarks" checked onchange="toggleCol('col-remarks', this.checked)" /> <span>Remarks</span></label>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-salary-date" checked onchange="toggleCol('col-salary-date', this.checked)" /> <span>Salary Received Date</span></label>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-epf-date" checked onchange="toggleCol('col-epf-date', this.checked)" /> <span>EPF Received Date</span></label>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-sig" checked onchange="toggleCol('col-sig', this.checked)" /> <span>Signature of Individual</span></label>
                        </div>
                    </div>

                    <!-- Print Button -->
                    <button type="button" class="btn-action-primary" onclick="triggerLandscapePrint()" title="Print in Landscape Orientation">
                        <i class="fas fa-print"></i> Print (Landscape)
                    </button>

                    <!-- Export to Word Button -->
                    <button type="button" class="btn-action-word" onclick="triggerWordExport()" title="Download editable Word Document (.doc)">
                        <i class="fas fa-file-word"></i> Export to Word
                    </button>
                </div>
            </div>

            <!-- FILTERS & BULK DATE CONTROLS -->
            <div class="filter-row">
                <div class="filter-group">
                    <label class="filter-label">Year</label>
                    <select id="ddlYear" class="form-select-custom" onchange="onFilterChange()" style="width: 100px;"></select>
                </div>

                <div class="filter-group">
                    <label class="filter-label">Month</label>
                    <select id="ddlMonth" class="form-select-custom" onchange="onFilterChange()" style="width: 130px;">
                        <option value="1">January</option>
                        <option value="2">February</option>
                        <option value="3">March</option>
                        <option value="4">April</option>
                        <option value="5">May</option>
                        <option value="6">June</option>
                        <option value="7">July</option>
                        <option value="8">August</option>
                        <option value="9">September</option>
                        <option value="10">October</option>
                        <option value="11">November</option>
                        <option value="12">December</option>
                    </select>
                </div>

                <div class="filter-group">
                    <label class="filter-label">Category</label>
                    <select id="ddlCategory" class="form-select-custom" onchange="onCategoryChange()" style="min-width: 180px;"></select>
                </div>

                <div class="filter-group">
                    <label class="filter-label">Contract / Vendor</label>
                    <select id="ddlContract" class="form-select-custom" onchange="loadReportData()" style="min-width: 240px;"></select>
                </div>

                <!-- Bulk Salary Date -->
                <div class="filter-group">
                    <label class="filter-label" for="txtMasterSalaryDate" onclick="openDateInput('txtMasterSalaryDate')" style="cursor: pointer;" title="Click to select Previous Month Salary Date from calendar">
                        <i class="fas fa-calendar-alt text-primary" style="cursor: pointer;"></i> Previous Salary Date
                    </label>
                    <div style="display: inline-flex; align-items: center; gap: 4px;">
                        <input type="date" id="txtMasterSalaryDate" class="form-select-custom" style="width: 145px; cursor: pointer;" onchange="applyMasterSalaryDate(this.value)" onclick="handleDateInputClick(event, this)" title="Click to select Previous Month Salary Date from calendar" />
                        <button type="button" class="btn btn-sm btn-outline-secondary" onclick="clearMasterSalaryDate()" title="Clear Salary Date" style="height: 38px; padding: 0 9px; border-radius: 8px; border-color: #cbd5e1; background: #ffffff;">
                            <i class="fas fa-times text-muted"></i>
                        </button>
                    </div>
                </div>

                <!-- Bulk EPF Date -->
                <div class="filter-group">
                    <label class="filter-label" for="txtMasterEpfDate" onclick="openDateInput('txtMasterEpfDate')" style="cursor: pointer;" title="Click to select Previous Month EPF Date from calendar">
                        <i class="fas fa-calendar-check text-success" style="cursor: pointer;"></i> Previous EPF Date
                    </label>
                    <div style="display: inline-flex; align-items: center; gap: 4px;">
                        <input type="date" id="txtMasterEpfDate" class="form-select-custom" style="width: 145px; cursor: pointer;" onchange="applyMasterEpfDate(this.value)" onclick="handleDateInputClick(event, this)" title="Click to select Previous Month EPF Date from calendar" />
                        <button type="button" class="btn btn-sm btn-outline-secondary" onclick="clearMasterEpfDate()" title="Clear EPF Date" style="height: 38px; padding: 0 9px; border-radius: 8px; border-color: #cbd5e1; background: #ffffff;">
                            <i class="fas fa-times text-muted"></i>
                        </button>
                    </div>
                </div>

                <div class="filter-group ml-auto">
                    <button type="button" class="btn btn-light font-weight-bold" onclick="loadReportData()" style="height: 38px; border: 1.5px solid #cbd5e1; border-radius: 8px;">
                        <i class="fas fa-sync-alt mr-1"></i> Refresh
                    </button>
                </div>
            </div>
        </div>

        <!-- MASTER LANDSCAPE SHEET VIEW -->
        <div class="landscape-viewport">
            <div class="landscape-sheet" id="landscapeSheet">
                
                <!-- TOP LINE 1: Vendor Name -->
                <div id="topLine1El" class="rep-top-line1" style="font-size: 11pt; text-align: center;">
                    M/s VISHAL MANPOWER &amp; SECURITY CONSULTANTS
                </div>

                <!-- TOP LINE 2: Recommendation Header -->
                <div id="topLine2El" class="rep-top-line2" style="font-size: 11pt; text-align: center;">
                    MONTHLY REPORT AND RECOMMENDATION ON HIRING OF MANPOWER SERVICES FOR MAKING PAYMENT FOR THE MONTH OF JUN - 2026
                </div>

                <!-- TOP LINE 3: Directorate -->
                <div id="directorateEl" class="rep-directorate-line">
                    Directorate: D-KRM
                </div>

                <!-- 10-COLUMN REPORT TABLE -->
                <table class="rep-table" id="reportTable">
                    <thead>
                        <tr>
                            <th class="col-cat" style="width: 9%;">Category</th>
                            <th class="col-manpower" style="width: 9%;">Manpower</th>
                            <th class="col-id" style="width: 6%;">ID No.</th>
                            <th class="col-name" style="width: 16%;">Name of the Individual</th>
                            <th class="col-attended" style="width: 9%;">Total no. of man days attended</th>
                            <th class="col-not-attended" style="width: 8%;">Total no. of days not attended</th>
                            <th class="col-remarks" style="width: 18%;">Remarks</th>
                            <th class="col-salary-date" id="thSalaryDate" style="width: 9%;">Received date of Previous Month<br />Salary<br /><span id="lblPrevMonSalary">( May)</span></th>
                            <th class="col-epf-date" id="thEpfDate" style="width: 9%;">Received date of Previous Month EPF Contribution<br /><span id="lblPrevMonEpf">( May)</span></th>
                            <th class="col-sig" style="width: 7%;">Signature of the Individual</th>
                        </tr>
                    </thead>
                    <tbody id="reportTableBody">
                        <tr>
                            <td colspan="10" style="padding: 30px; color: #64748b;">
                                <i class="fas fa-spinner fa-spin mr-2"></i> Loading report data...
                            </td>
                        </tr>
                    </tbody>
                </table>

                <!-- BOTTOM CERTIFICATION PARAGRAPH -->
                <div id="certParagraphEl" class="rep-cert-paragraph" style="font-size: 11pt; text-align: left;">
                    It is certified that the above mentioned individuals have worked during office hours on the number of days as mentioned against their names and the individuals have received their previous month salary &amp; EPF contribution from the service provider.
                </div>

                <!-- BOTTOM SIGNATURES SECTION -->
                <div class="rep-signatures-wrap" id="signaturesWrapEl" style="font-size: 11pt;">
                    <div class="rep-sig-left bold" id="sigDirectorEl">
                        Signature of Group Director
                    </div>
                    <div class="rep-sig-right" id="sigPocEl">
                        (Point of Contact)
                    </div>
                </div>

                <!-- RECIPIENT TO BLOCK -->
                <div class="rep-to-block" id="toBlockEl" style="font-size: 11pt;">
                    <div>To</div>
                    <div style="padding-left: 28px;" id="toDirectorateEl">D-KRM</div>
                </div>

            </div>
        </div>

    </div>

    <!-- CLIENT SCRIPT LOGIC -->
    <script>
        let currentCategories = [];
        let currentReportData = null;
        let columnVisibility = {
            'col-cat': true,
            'col-manpower': true,
            'col-id': true,
            'col-name': true,
            'col-attended': true,
            'col-not-attended': true,
            'col-remarks': true,
            'col-salary-date': true,
            'col-epf-date': true,
            'col-sig': true
        };

        document.addEventListener('DOMContentLoaded', () => {
            initPage();

            // Close column dropdown on outside click
            document.addEventListener('click', (e) => {
                const drop = document.getElementById('colDropdownMenu');
                if (drop && !e.target.closest('.col-dropdown-menu') && !e.target.closest('button[onclick*="toggleColDropdown"]')) {
                    drop.classList.remove('show');
                }
            });
        });

        function toggleColDropdown(e) {
            e.stopPropagation();
            const drop = document.getElementById('colDropdownMenu');
            if (drop) drop.classList.toggle('show');
        }

        function initPage() {
            fetch('MonthlyAttendanceReport.aspx/GetInitData', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            })
            .then(r => r.json())
            .then(res => {
                const data = JSON.parse(res.d || "{}");
                if (data.status === "error") {
                    showToast(data.message || "Failed to initialize page.", "error");
                    return;
                }

                // Populate Years (CurrentYear - 2 to CurrentYear + 1)
                const ySelect = document.getElementById('ddlYear');
                ySelect.innerHTML = '';
                const curY = data.CurrentYear;
                for (let y = curY - 2; y <= curY + 1; y++) {
                    const opt = document.createElement('option');
                    opt.value = y;
                    opt.textContent = y;
                    if (y === curY) opt.selected = true;
                    ySelect.appendChild(opt);
                }

                // Populate Months
                const mSelect = document.getElementById('ddlMonth');
                mSelect.value = data.CurrentMonth;

                // Pre-fill suggested Salary & EPF dates (4th and 14th of the report month)
                updateDefaultMasterDates(curY, data.CurrentMonth);

                // Populate Categories
                currentCategories = data.Categories || [];
                const cSelect = document.getElementById('ddlCategory');
                cSelect.innerHTML = '';
                currentCategories.forEach((cat, idx) => {
                    const opt = document.createElement('option');
                    opt.value = cat.TierId;
                    opt.textContent = cat.DisplayName;
                    if (idx === 0) opt.selected = true;
                    cSelect.appendChild(opt);
                });

                // Trigger contracts and initial report load
                onCategoryChange();
            })
            .catch(() => {
                showToast("Failed to initialize report parameters.", "error");
            });
        }

        function onFilterChange() {
            const year = parseInt(document.getElementById('ddlYear').value);
            const month = parseInt(document.getElementById('ddlMonth').value);
            updateDefaultMasterDates(year, month);
            onCategoryChange();
        }

        function updateDefaultMasterDates(year, month) {
            const yStr = String(year);
            const mStr = String(month).padStart(2, '0');
            const txtSal = document.getElementById('txtMasterSalaryDate');
            const txtEpf = document.getElementById('txtMasterEpfDate');
            if (txtSal) txtSal.value = `${yStr}-${mStr}-04`;
            if (txtEpf) txtEpf.value = `${yStr}-${mStr}-14`;
        }

        function formatDateToDDMMYYYY(val) {
            if (!val) return '';
            const parts = val.split('-');
            if (parts.length === 3 && parts[0].length === 4) {
                return `${parts[2]}-${parts[1]}-${parts[0]}`;
            }
            return val;
        }

        // Opens date picker when clicking label or icon
        function openDateInput(id) {
            const el = typeof id === 'string' ? document.getElementById(id) : id;
            if (el && el.showPicker) {
                try {
                    el.showPicker();
                } catch (err) {
                    el.focus();
                }
            } else if (el) {
                el.focus();
            }
        }

        // Handles click on date input: if indicator clicked, browser natively opens picker.
        // If blank space/text clicked, showPicker() opens picker.
        function handleDateInputClick(e, input) {
            if (!input) input = e.target;
            const threshold = Math.max(input.offsetWidth - 34, 0);
            if (e.offsetX > threshold) {
                // Clicked directly on the native calendar icon; let browser open it natively
                return;
            }
            // Clicked on blank space or text area; invoke showPicker
            if (input.showPicker) {
                try {
                    input.showPicker();
                } catch (err) {
                    // Ignore if already opening
                }
            }
        }

        function onRowDateChange(input) {
            const wrap = input.closest('.cell-date-wrap');
            if (wrap) {
                const printSpan = wrap.querySelector('.date-print-text');
                if (printSpan) {
                    printSpan.textContent = formatDateToDDMMYYYY(input.value);
                }
            }
        }

        function escapeHtml(text) {
            if (!text) return '';
            return String(text)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#039;');
        }

        // Dynamically renders Signatures & Recipient according to CertificateTemplates
        function renderSignaturesAndRecipient(signaturesText, defaultDirectorate, fontSize, align) {
            if (!signaturesText) {
                signaturesText = "(Point of Contact)\nSignature of Group Director\nTo\n    " + (defaultDirectorate || "D-KRM");
            }

            const rawLines = signaturesText.split(/\r?\n/).map(l => l.trimEnd());
            
            // Find where recipient block begins (line starting with "to")
            let toIndex = -1;
            for (let i = 0; i < rawLines.length; i++) {
                const trimmed = rawLines[i].trim();
                if (trimmed.toLowerCase() === 'to' || trimmed.toLowerCase().startsWith('to:') || trimmed.toLowerCase().startsWith('to ')) {
                    toIndex = i;
                    break;
                }
            }

            let sigLines = [];
            let toLines = [];

            if (toIndex !== -1) {
                sigLines = rawLines.slice(0, toIndex).filter(l => l.trim().length > 0);
                toLines = rawLines.slice(toIndex).filter(l => l.trim().length > 0);
            } else {
                sigLines = rawLines.filter(l => l.trim().length > 0);
                toLines = ["To", "    " + (defaultDirectorate || "D-KRM")];
            }

            // Process Signatures:
            let leftSig = "Signature of Group Director";
            let rightSig = "(Point of Contact)";

            if (sigLines.length === 1) {
                if (sigLines[0].toLowerCase().includes("point of contact") || sigLines[0].toLowerCase().includes("poc")) {
                    rightSig = escapeHtml(sigLines[0].trim());
                    leftSig = "";
                } else {
                    leftSig = escapeHtml(sigLines[0].trim());
                    rightSig = "";
                }
            } else if (sigLines.length >= 2) {
                const pocIdx = sigLines.findIndex(l => l.toLowerCase().includes("point of contact") || l.toLowerCase().includes("poc"));
                if (pocIdx !== -1) {
                    rightSig = escapeHtml(sigLines[pocIdx].trim());
                    const remaining = sigLines.filter((_, idx) => idx !== pocIdx);
                    leftSig = remaining.map(l => escapeHtml(l.trim())).join("<br/>");
                } else {
                    // Line 0 is right, line 1+ is left
                    rightSig = escapeHtml(sigLines[0].trim());
                    leftSig = sigLines.slice(1).map(l => escapeHtml(l.trim())).join("<br/>");
                }
            }

            // Update Signatures DOM
            const sigWrap = document.getElementById('signaturesWrapEl');
            const sigDirectorEl = document.getElementById('sigDirectorEl');
            const sigPocEl = document.getElementById('sigPocEl');

            if (sigDirectorEl) sigDirectorEl.innerHTML = leftSig;
            if (sigPocEl) sigPocEl.innerHTML = rightSig;
            if (sigWrap) {
                sigWrap.style.fontSize = (fontSize || "11") + "pt";
            }

            // Process Recipient (To block)
            const toBlockEl = document.getElementById('toBlockEl');
            if (toBlockEl) {
                toBlockEl.style.fontSize = (fontSize || "11") + "pt";
                toBlockEl.style.textAlign = align || "left";
                
                let toHtml = "";
                toLines.forEach((line, idx) => {
                    const trimmed = line.trim();
                    if (idx === 0 && (trimmed.toLowerCase() === 'to' || trimmed.toLowerCase() === 'to:')) {
                        toHtml += `<div>${escapeHtml(trimmed)}</div>`;
                    } else if (idx === 0) {
                        toHtml += `<div>${escapeHtml(trimmed)}</div>`;
                    } else {
                        toHtml += `<div style="padding-left: 28px;">${escapeHtml(trimmed)}</div>`;
                    }
                });
                toBlockEl.innerHTML = toHtml;
            }
        }

        function onCategoryChange() {
            const year = parseInt(document.getElementById('ddlYear').value);
            const month = parseInt(document.getElementById('ddlMonth').value);
            const tierId = parseInt(document.getElementById('ddlCategory').value);

            if (!year || !month || !tierId) return;

            fetch('MonthlyAttendanceReport.aspx/GetContracts', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ year: year, month: month, tierId: tierId })
            })
            .then(r => r.json())
            .then(res => {
                const list = JSON.parse(res.d || "[]");
                const conSelect = document.getElementById('ddlContract');
                conSelect.innerHTML = '';
                if (list.length === 0) {
                    const opt = document.createElement('option');
                    opt.value = 0;
                    opt.textContent = "Default Active Vendor";
                    conSelect.appendChild(opt);
                } else {
                    list.forEach((con, idx) => {
                        const opt = document.createElement('option');
                        opt.value = con.Id;
                        opt.textContent = con.DisplayName;
                        if (idx === 0) opt.selected = true;
                        conSelect.appendChild(opt);
                    });
                }

                loadReportData();
            })
            .catch(() => {
                loadReportData();
            });
        }

        function loadReportData() {
            const year = parseInt(document.getElementById('ddlYear').value);
            const month = parseInt(document.getElementById('ddlMonth').value);
            const tierId = parseInt(document.getElementById('ddlCategory').value);
            const contractId = parseInt(document.getElementById('ddlContract').value || 0);

            if (!year || !month || !tierId) return;

            const tbody = document.getElementById('reportTableBody');
            tbody.innerHTML = `<tr><td colspan="10" style="padding: 35px; color: #64748b;"><i class="fas fa-spinner fa-spin mr-2"></i> Generating report data...</td></tr>`;

            fetch('MonthlyAttendanceReport.aspx/GetReportData', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ year: year, month: month, tierId: tierId, contractPeriodId: contractId })
            })
            .then(r => r.json())
            .then(res => {
                const data = JSON.parse(res.d || "{}");
                if (data.status === "error") {
                    tbody.innerHTML = `<tr><td colspan="10" style="padding: 25px; color: #ef4444;"><i class="fas fa-exclamation-triangle mr-2"></i> ${data.message}</td></tr>`;
                    return;
                }

                currentReportData = data;
                renderReportView(data);
            })
            .catch(err => {
                tbody.innerHTML = `<tr><td colspan="10" style="padding: 25px; color: #ef4444;">Failed to load attendance report.</td></tr>`;
            });
        }

        function renderReportView(data) {
            // 1. Top Line 1 (Vendor)
            const t1 = document.getElementById('topLine1El');
            t1.textContent = data.Line1;
            t1.style.fontSize = (data.TopFontSize || "11") + "pt";
            t1.style.textAlign = data.TopAlign || "center";

            // 2. Top Line 2 (Recommendation Header)
            const t2 = document.getElementById('topLine2El');
            t2.textContent = data.Line2;
            t2.style.fontSize = (data.TopFontSize || "11") + "pt";
            t2.style.textAlign = data.TopAlign || "center";

            // 3. Top Line 3 (Directorate)
            const dirEl = document.getElementById('directorateEl');
            dirEl.textContent = "Directorate: " + data.Directorate;

            // 4. Previous Month Label in Table Header
            document.getElementById('lblPrevMonSalary').textContent = `( ${data.PrevMonthName})`;
            document.getElementById('lblPrevMonEpf').textContent = `( ${data.PrevMonthName})`;

            // 5. Certification Paragraph
            const certEl = document.getElementById('certParagraphEl');
            certEl.textContent = data.CertParagraph;
            certEl.style.fontSize = (data.BottomFontSize || "11") + "pt";
            certEl.style.textAlign = data.BottomAlign || "left";

            // 6. Signatures & Recipient Block (dynamically rendered from template)
            renderSignaturesAndRecipient(data.Signatures, data.Directorate, data.BottomFontSize, data.BottomAlign);

            // 7. Render Table Rows with Merged Category & Manpower Cells
            const tbody = document.getElementById('reportTableBody');
            tbody.innerHTML = '';

            const emps = data.Employees || [];
            if (emps.length === 0) {
                tbody.innerHTML = `<tr><td colspan="10" style="padding: 30px; color: #94a3b8;"><i class="fas fa-info-circle mr-2"></i> No active employees found for this category and division during the selected month.</td></tr>`;
                return;
            }

            const masterSalaryDate = document.getElementById('txtMasterSalaryDate').value || "";
            const masterEpfDate = document.getElementById('txtMasterEpfDate').value || "";

            emps.forEach((emp, index) => {
                const tr = document.createElement('tr');

                // If first row, render merged Category & Manpower cells spanning all rows
                if (index === 0) {
                    const tdCat = document.createElement('td');
                    tdCat.className = 'col-cat cell-center cell-bold';
                    tdCat.rowSpan = emps.length;
                    tdCat.textContent = data.CategoryName;
                    tr.appendChild(tdCat);

                    const tdMan = document.createElement('td');
                    tdMan.className = 'col-manpower cell-center cell-bold';
                    tdMan.rowSpan = emps.length;
                    tdMan.textContent = data.ManpowerDesc;
                    tr.appendChild(tdMan);
                }

                // ID No.
                const tdId = document.createElement('td');
                tdId.className = 'col-id cell-center';
                tdId.textContent = emp.ID;
                tr.appendChild(tdId);

                // Name
                const tdName = document.createElement('td');
                tdName.className = 'col-name cell-center';
                tdName.textContent = emp.Name;
                tr.appendChild(tdName);

                // Days Attended
                const tdAtt = document.createElement('td');
                tdAtt.className = 'col-attended cell-center';
                tdAtt.textContent = emp.PresentDays;
                tr.appendChild(tdAtt);

                // Days Not Attended
                const tdNotAtt = document.createElement('td');
                tdNotAtt.className = 'col-not-attended cell-center';
                tdNotAtt.textContent = emp.AbsentDays;
                tr.appendChild(tdNotAtt);

                // Remarks
                const tdRem = document.createElement('td');
                tdRem.className = 'col-remarks cell-center';
                tdRem.textContent = emp.Remarks;
                tr.appendChild(tdRem);

                // Salary Date (Editable cell with calendar picker)
                const isNewJoiner = emp.JoinedCurrentMonth;
                const rowSalVal = isNewJoiner ? "" : masterSalaryDate;
                const rowEpfVal = isNewJoiner ? "" : masterEpfDate;
                const rowSalDisplay = formatDateToDDMMYYYY(rowSalVal);
                const rowEpfDisplay = formatDateToDDMMYYYY(rowEpfVal);

                const tdSal = document.createElement('td');
                tdSal.className = 'col-salary-date cell-center';
                tdSal.innerHTML = `
                    <div class="cell-date-wrap">
                        <input type="date" class="cell-inline-date row-salary-date no-print" value="${rowSalVal}" onchange="onRowDateChange(this)" onclick="handleDateInputClick(event, this)" title="Click to select Salary Date from calendar" />
                        <span class="print-only date-print-text">${rowSalDisplay}</span>
                    </div>`;
                tr.appendChild(tdSal);

                // EPF Date (Editable cell with calendar picker)
                const tdEpf = document.createElement('td');
                tdEpf.className = 'col-epf-date cell-center';
                tdEpf.innerHTML = `
                    <div class="cell-date-wrap">
                        <input type="date" class="cell-inline-date row-epf-date no-print" value="${rowEpfVal}" onchange="onRowDateChange(this)" onclick="handleDateInputClick(event, this)" title="Click to select EPF Date from calendar" />
                        <span class="print-only date-print-text">${rowEpfDisplay}</span>
                    </div>`;
                tr.appendChild(tdEpf);

                // Signature cell (Blank for physical signing)
                const tdSig = document.createElement('td');
                tdSig.className = 'col-sig cell-center';
                tdSig.innerHTML = `&nbsp;`;
                tr.appendChild(tdSig);

                tbody.appendChild(tr);
            });

            // Re-apply any active column hiding
            applyColumnVisibility();
        }

        // Apply bulk Salary Date to all employee rows
        function applyMasterSalaryDate(val) {
            const formatted = formatDateToDDMMYYYY(val);
            document.querySelectorAll('.row-salary-date').forEach(input => {
                input.value = val;
                const wrap = input.closest('.cell-date-wrap');
                if (wrap) {
                    const printSpan = wrap.querySelector('.date-print-text');
                    if (printSpan) printSpan.textContent = formatted;
                }
            });
        }

        // Apply bulk EPF Date to all employee rows
        function applyMasterEpfDate(val) {
            const formatted = formatDateToDDMMYYYY(val);
            document.querySelectorAll('.row-epf-date').forEach(input => {
                input.value = val;
                const wrap = input.closest('.cell-date-wrap');
                if (wrap) {
                    const printSpan = wrap.querySelector('.date-print-text');
                    if (printSpan) printSpan.textContent = formatted;
                }
            });
        }

        function clearMasterSalaryDate() {
            document.getElementById('txtMasterSalaryDate').value = '';
            applyMasterSalaryDate('');
        }

        function clearMasterEpfDate() {
            document.getElementById('txtMasterEpfDate').value = '';
            applyMasterEpfDate('');
        }

        // Column Visibility Toggles
        function toggleCol(colClass, isVisible) {
            columnVisibility[colClass] = isVisible;
            applyColumnVisibility();
        }

        function applyColumnVisibility() {
            for (const [colClass, isVisible] of Object.entries(columnVisibility)) {
                const elements = document.querySelectorAll('.' + colClass);
                elements.forEach(el => {
                    el.style.display = isVisible ? '' : 'none';
                });
            }
        }

        function resetAllColumns() {
            for (const colClass of Object.keys(columnVisibility)) {
                columnVisibility[colClass] = true;
                const chk = document.getElementById('chk_' + colClass);
                if (chk) chk.checked = true;
            }
            applyColumnVisibility();
        }

        // Print Landscape
        function triggerLandscapePrint() {
            window.print();
        }

        // Word Export (.doc)
        function triggerWordExport() {
            if (!currentReportData) {
                showToast("No report data available to export.", "warning");
                return;
            }

            // Clone sheet to generate clean Word HTML without input boxes or hidden columns
            const sheet = document.getElementById('landscapeSheet');
            const clone = sheet.cloneNode(true);

            // Replace date inputs with clean plain text (dd-MM-yyyy) in the clone
            clone.querySelectorAll('.col-salary-date').forEach(td => {
                const input = td.querySelector('.row-salary-date');
                const val = input ? input.value : '';
                const formatted = formatDateToDDMMYYYY(val);
                td.innerHTML = formatted || '&nbsp;';
            });

            clone.querySelectorAll('.col-epf-date').forEach(td => {
                const input = td.querySelector('.row-epf-date');
                const val = input ? input.value : '';
                const formatted = formatDateToDDMMYYYY(val);
                td.innerHTML = formatted || '&nbsp;';
            });

            // Remove any form controls / buttons / inputs / print-only spans from the clone
            clone.querySelectorAll('input, button, select, .no-print').forEach(el => el.remove());

            // Remove hidden columns from the clone
            for (const [colClass, isVisible] of Object.entries(columnVisibility)) {
                if (!isVisible) {
                    clone.querySelectorAll('.' + colClass).forEach(el => el.remove());
                }
            }

            // Word-compatible signatures table (tables work reliably in Word; flexbox does not)
            const sigWrap = clone.querySelector('#signaturesWrapEl');
            if (sigWrap) {
                const leftEl = sigWrap.querySelector('#sigDirectorEl');
                const rightEl = sigWrap.querySelector('#sigPocEl');
                const leftText = leftEl ? leftEl.innerHTML : 'Signature of Group Director';
                const rightText = rightEl ? rightEl.innerHTML : '(Point of Contact)';
                sigWrap.outerHTML = `
                    <table style="width: 100%; border: none !important; margin-top: 28px; margin-bottom: 20px;">
                        <tr>
                            <td style="border: none !important; text-align: left; font-family: Arial, sans-serif; font-size: 11pt; font-weight: bold; width: 50%; vertical-align: top;">${leftText}</td>
                            <td style="border: none !important; text-align: right; font-family: Arial, sans-serif; font-size: 11pt; font-weight: bold; width: 50%; vertical-align: top;">${rightText}</td>
                        </tr>
                    </table>
                `;
            }

            const month = document.getElementById('ddlMonth').options[document.getElementById('ddlMonth').selectedIndex].text;
            const year = document.getElementById('ddlYear').value;

            // Generate self-contained Word Document HTML with Word-compatible XML namespace & landscape layout
            const docContent = `
<html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<!--[if gte mso 9]>
<xml>
 <w:WordDocument>
  <w:View>Print</w:View>
  <w:DoNotOptimizeForBrowser/>
 </w:WordDocument>
</xml>
<![endif]-->
<style>
@page Section1 {
  size: 11.0in 8.5in;
  mso-page-orientation: landscape;
  margin: 0.4in 0.8in 0.6in 0.8in;
  mso-header-margin: 0.4in;
  mso-footer-margin: 0.4in;
}
div.Section1 { page: Section1; }
body { font-family: Arial, sans-serif; font-size: 11pt; color: #000000; margin: 0; padding: 0; }
.rep-top-line1 { font-family: Arial, sans-serif; font-weight: bold; font-size: 11pt; text-align: center; margin-bottom: 6px; }
.rep-top-line2 { font-family: Arial, sans-serif; font-weight: bold; font-size: 11pt; text-align: center; margin-bottom: 12px; }
.rep-directorate-line { font-family: Arial, sans-serif; font-weight: bold; font-size: 11pt; text-align: left; margin-bottom: 10px; }
table { border-collapse: collapse; width: 100%; margin-top: 10px; margin-bottom: 16px; border: 0.5pt solid #000000; }
table, th, td { border: 0.5pt solid #000000; }
th { font-family: Arial, sans-serif; font-size: 10pt; font-weight: bold; text-align: center; vertical-align: middle; padding: 4px 6px; background-color: #ffffff; }
td { font-family: Arial, sans-serif; font-size: 10pt; vertical-align: middle; padding: 4px 6px; text-align: center; }
.cell-left { text-align: left !important; }
.cell-center { text-align: center !important; }
.cell-right { text-align: right !important; }
.cell-bold { font-weight: bold !important; }
.rep-cert-paragraph { font-family: Arial, sans-serif; font-size: 11pt; text-align: left; margin-top: 14px; margin-bottom: 24px; line-height: 1.4; }
.rep-to-block { font-family: Arial, sans-serif; font-size: 11pt; text-align: left; margin-top: 24px; line-height: 1.4; }
</style>
</head>
<body>
<div class="Section1">
${clone.innerHTML}
</div>
</body>
</html>`;

            try {
                // Direct Client-Side Blob Download (Instant, 100% reliable, zero form/server conflicts)
                const blob = new Blob(['\ufeff', docContent], { type: 'application/msword;charset=utf-8' });
                const url = URL.createObjectURL(blob);
                const downloadLink = document.createElement('a');
                downloadLink.href = url;
                downloadLink.download = `Attendance_Recommendation_Report_${month}_${year}.doc`;
                document.body.appendChild(downloadLink);
                downloadLink.click();
                document.body.removeChild(downloadLink);
                setTimeout(() => URL.revokeObjectURL(url), 1000);
                showToast("Word document generated and downloaded successfully!", "success");
            } catch (err) {
                console.error("Export to Word failed:", err);
                showToast("Failed to generate Word document.", "error");
            }
        }
    </script>
</asp:Content>
