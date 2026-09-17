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
            padding: 20px 24px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.04);
            margin-bottom: 24px;
        }

        /* Toolbar Header: Title & Main Actions */
        .toolbar-header-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 16px;
            padding-bottom: 16px;
            border-bottom: 1px solid #f1f5f9;
            margin-bottom: 16px;
        }

        .toolbar-title-wrap {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .btn-action-back {
            height: 38px;
            padding: 0 16px;
            background: #f8fafc;
            color: #475569 !important;
            border: 1.5px solid #e2e8f0;
            border-radius: 10px;
            font-weight: 700;
            font-size: 0.85rem;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
            text-decoration: none !important;
        }

        .btn-action-back:hover {
            background: #f1f5f9;
            color: #0f172a !important;
            border-color: #cbd5e1;
            transform: translateX(-2px);
        }

        .toolbar-title-content {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .toolbar-title {
            margin: 0;
            font-size: 1.12rem;
            font-weight: 800;
            color: #0f172a;
            display: flex;
            align-items: center;
        }

        .toolbar-subtitle {
            font-size: 0.78rem;
            font-weight: 600;
            color: #64748b;
        }

        .toolbar-actions-wrap {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
        }

        .btn-toolbar-btn {
            height: 38px;
            padding: 0 15px;
            background: #ffffff;
            color: #334155 !important;
            border: 1.5px solid #cbd5e1;
            border-radius: 9px;
            font-weight: 700;
            font-size: 0.85rem;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            transition: all 0.15s ease;
            text-decoration: none !important;
        }

        .btn-toolbar-btn:hover {
            background: #f8fafc;
            border-color: #94a3b8;
            color: #0f172a !important;
        }

        .toolbar-btn-divider {
            width: 1px;
            height: 24px;
            background: #e2e8f0;
            margin: 0 4px;
        }

        /* Primary Filters Grid - Generous, well-spaced layout */
        .filter-main-grid {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            gap: 16px;
            margin-bottom: 16px;
        }

        .filter-cell {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .filter-cell-year {
            width: 110px;
            flex-shrink: 0;
        }

        .filter-cell-month {
            width: 160px;
            flex-shrink: 0;
        }

        .filter-cell-cat {
            flex: 1 1 240px;
            min-width: 210px;
        }

        .filter-cell-contract {
            flex: 2 1 380px;
            min-width: 290px;
        }

        .filter-label {
            font-size: 0.8rem;
            font-weight: 700;
            color: #334155;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            letter-spacing: 0.2px;
            margin: 0;
        }

        .form-select-custom, .form-input-custom {
            height: 40px;
            border-radius: 9px;
            border: 1.5px solid #cbd5e1;
            padding: 0 12px;
            font-size: 0.88rem;
            font-weight: 600;
            color: #0f172a;
            background-color: #ffffff;
            transition: all 0.15s ease;
            outline: none;
            width: 100%;
        }

        .form-select-custom:focus, .form-input-custom:focus {
            border-color: #6366f1;
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.15);
        }

        .form-select-custom option:disabled {
            color: #94a3b8 !important;
            background-color: #f1f5f9 !important;
            cursor: not-allowed !important;
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

        /* Subpanel: Suggested Payment Dates & Notice */
        .toolbar-subpanel {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 12px 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 16px;
        }

        .subpanel-dates-group {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 16px;
        }

        .subpanel-badge-label {
            font-size: 0.8rem;
            font-weight: 800;
            color: #475569;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .date-picker-inline {
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .date-picker-tag {
            font-size: 0.82rem;
            font-weight: 700;
            color: #334155;
            cursor: pointer;
            user-select: none;
            display: inline-flex;
            align-items: center;
        }

        .date-input-unified {
            display: inline-flex;
            align-items: center;
            background: #ffffff;
            border: 1.5px solid #cbd5e1;
            border-radius: 8px;
            padding: 0 6px 0 10px;
            height: 36px;
            box-shadow: inset 0 1px 2px rgba(0,0,0,0.03);
            transition: all 0.15s ease;
        }

        .date-input-unified:focus-within {
            border-color: #6366f1;
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.15);
        }

        .date-input-unified input[type="date"] {
            border: none !important;
            outline: none !important;
            background: transparent !important;
            font-size: 0.85rem;
            font-weight: 600;
            color: #0f172a;
            padding: 0 4px;
            cursor: pointer;
            height: 100%;
        }

        .btn-date-clear-inline {
            border: none;
            background: transparent;
            color: #94a3b8;
            cursor: pointer;
            padding: 2px 5px;
            border-radius: 4px;
            font-size: 0.85rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            transition: all 0.15s ease;
        }

        .btn-date-clear-inline:hover {
            color: #ef4444;
            background: #fee2e2;
        }

        .subpanel-notice {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 0.82rem;
            color: #1e40af;
            background: #eff6ff;
            border: 1px solid #bfdbfe;
            border-left: 3.5px solid #2563eb;
            border-radius: 7px;
            padding: 6px 12px;
            line-height: 1.4;
            max-width: 620px;
        }

        .subpanel-notice-icon {
            font-size: 0.95rem;
            color: #2563eb;
            flex-shrink: 0;
        }

        .subpanel-notice-text strong {
            color: #1e3a8a;
        }

        /* Dark Theme Overrides for Toolbar */
        html.theme-dark .report-toolbar-card {
            background: #151821 !important;
            border-color: #2d3348 !important;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.35) !important;
        }

        html.theme-dark .toolbar-header-row {
            border-bottom-color: #252a3a !important;
        }

        html.theme-dark .btn-action-back {
            background: #1e2233 !important;
            border-color: #3d4460 !important;
            color: #cbd5e1 !important;
        }

        html.theme-dark .btn-action-back:hover {
            background: #252a3a !important;
            color: #f1f5f9 !important;
            border-color: #6366f1 !important;
        }

        html.theme-dark .toolbar-title {
            color: #f1f5f9 !important;
        }

        html.theme-dark .toolbar-subtitle {
            color: #94a3b8 !important;
        }

        html.theme-dark .btn-toolbar-btn {
            background: #1e2233 !important;
            border-color: #3d4460 !important;
            color: #cbd5e1 !important;
        }

        html.theme-dark .btn-toolbar-btn:hover {
            background: #252a3a !important;
            border-color: #6366f1 !important;
            color: #818cf8 !important;
        }

        html.theme-dark .toolbar-btn-divider {
            background: #2d3348 !important;
        }

        html.theme-dark .filter-label {
            color: #cbd5e1 !important;
        }

        html.theme-dark .toolbar-subpanel {
            background: #1a1d27 !important;
            border-color: #2d3348 !important;
        }

        html.theme-dark .subpanel-badge-label {
            color: #94a3b8 !important;
        }

        html.theme-dark .date-picker-tag {
            color: #cbd5e1 !important;
        }

        html.theme-dark .date-input-unified {
            background: #161922 !important;
            border-color: #3d4460 !important;
        }

        html.theme-dark .date-input-unified input[type="date"] {
            color: #e2e8f0 !important;
        }

        html.theme-dark .btn-date-clear-inline {
            color: #94a3b8 !important;
        }

        html.theme-dark .btn-date-clear-inline:hover {
            color: #f87171 !important;
            background: rgba(239, 68, 68, 0.2) !important;
        }

        html.theme-dark .subpanel-notice {
            background: rgba(37, 99, 235, 0.12) !important;
            border-color: rgba(59, 130, 246, 0.25) !important;
            border-left-color: #60a5fa !important;
            color: #93c5fd !important;
        }

        html.theme-dark .subpanel-notice-icon {
            color: #60a5fa !important;
        }

        html.theme-dark .subpanel-notice-text strong {
            color: #bfdbfe !important;
        }

        html.theme-dark .form-select-custom option:disabled {
            color: #64748b !important;
            background-color: #1e293b !important;
            cursor: not-allowed !important;
        }

        .col-dropdown-title {
            color: #0f172a;
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
            padding: 0 18px 40px 18px;
        }

        .landscape-sheet {
            width: 100%;
            max-width: 1150px;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.06);
            border-radius: 6px;
            padding: 36px 54px;
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
            margin-top: 60px;
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

        /* ── DARK THEME STYLES (Screen View) ── */
        @media screen {
            html.theme-dark .report-toolbar-card {
                background: #1a1d27;
                border-color: #2d3348;
                box-shadow: 0 4px 16px rgba(0, 0, 0, 0.35);
            }

            html.theme-dark .btn-action-secondary {
                background: #252a3a !important;
                color: #cbd5e1 !important;
                border-color: #3d4460 !important;
                box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25);
            }

            html.theme-dark .btn-action-secondary:hover {
                background: #2e354a !important;
                color: #818cf8 !important;
                border-color: #6366f1 !important;
            }

            html.theme-dark .filter-label {
                color: #94a3b8;
            }

            html.theme-dark .form-select-custom,
            html.theme-dark .form-input-custom {
                background-color: #161922 !important;
                color: #e2e8f0 !important;
                border-color: #3d4460 !important;
            }

            html.theme-dark .form-select-custom:focus,
            html.theme-dark .form-input-custom:focus {
                background-color: #1e2233 !important;
                border-color: #818cf8 !important;
                box-shadow: 0 0 0 3px rgba(129, 140, 248, 0.25) !important;
            }

            html.theme-dark .form-select-custom option {
                background-color: #161922;
                color: #e2e8f0;
            }

            html.theme-dark .btn-date-clear {
                background: #252a3a !important;
                border-color: #3d4460 !important;
                color: #94a3b8 !important;
            }

            html.theme-dark .btn-date-clear:hover {
                background: #2e354a !important;
                border-color: #ef4444 !important;
                color: #f87171 !important;
            }

            html.theme-dark .btn-date-clear i {
                color: #94a3b8 !important;
            }

            html.theme-dark .btn-date-clear:hover i {
                color: #f87171 !important;
            }

            html.theme-dark .btn-report-refresh {
                background: #252a3a !important;
                border-color: #3d4460 !important;
                color: #cbd5e1 !important;
            }

            html.theme-dark .btn-report-refresh:hover {
                background: #2e354a !important;
                border-color: #6366f1 !important;
                color: #818cf8 !important;
            }

            html.theme-dark .col-dropdown-menu {
                background: #1a1d27;
                border-color: #2d3348;
                box-shadow: 0 15px 35px rgba(0, 0, 0, 0.55);
            }

            html.theme-dark .col-dropdown-title {
                color: #f1f5f9 !important;
            }

            html.theme-dark .col-dropdown-menu .border-bottom {
                border-color: #2d3348 !important;
            }

            html.theme-dark .col-item-label {
                color: #cbd5e1;
            }

            html.theme-dark .col-item-label:hover {
                background: #252a3a;
                color: #818cf8;
            }

            html.theme-dark .col-item-label input[type="checkbox"] {
                accent-color: #6366f1;
            }

            html.theme-dark .report-notice-banner {
                background: rgba(37, 99, 235, 0.14);
                border-color: rgba(59, 130, 246, 0.3);
                border-left-color: #60a5fa;
                color: #93c5fd;
            }

            html.theme-dark .report-notice-icon {
                color: #60a5fa;
            }

            html.theme-dark .report-notice-text strong {
                color: #bfdbfe;
            }

            html.theme-dark .report-notice-text em {
                color: #93c5fd;
            }

            /* Sheet View in Dark Mode (Screen only) */
            html.theme-dark .landscape-viewport {
                background: transparent;
            }

            html.theme-dark .landscape-sheet {
                background: #1a1d27 !important;
                border-color: #2d3348 !important;
                color: #e2e8f0 !important;
                box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5) !important;
            }

            html.theme-dark .rep-top-line1,
            html.theme-dark .rep-top-line2,
            html.theme-dark .rep-directorate-line,
            html.theme-dark .rep-cert-paragraph,
            html.theme-dark .rep-signatures-wrap,
            html.theme-dark .rep-to-block,
            html.theme-dark .rep-sig-left,
            html.theme-dark .rep-sig-right {
                color: #e2e8f0 !important;
            }

            html.theme-dark .rep-table {
                border-color: #3d4460 !important;
            }

            html.theme-dark .rep-table th {
                background-color: #1e2233 !important;
                color: #f1f5f9 !important;
                border-color: #3d4460 !important;
            }

            html.theme-dark .rep-table th #lblPrevMonSalary,
            html.theme-dark .rep-table th #lblPrevMonEpf {
                color: #94a3b8 !important;
            }

            html.theme-dark .rep-table th i.text-primary {
                color: #818cf8 !important;
            }

            html.theme-dark .rep-table td {
                background-color: #1a1d27 !important;
                color: #cbd5e1 !important;
                border-color: #2d3348 !important;
            }

            html.theme-dark .rep-table tr:hover td {
                background-color: #202534 !important;
            }

            html.theme-dark .rep-table td.col-cat,
            html.theme-dark .rep-table td.col-manpower,
            html.theme-dark .rep-table td.col-cat-manpower {
                background-color: #161922 !important;
                color: #f1f5f9 !important;
            }

            html.theme-dark .cell-inline-date {
                background-color: #161922 !important;
                border-color: #3d4460 !important;
                color: #e2e8f0 !important;
            }

            html.theme-dark .cell-inline-date:hover {
                background-color: #1e2233 !important;
                border-color: #818cf8 !important;
            }

            html.theme-dark .cell-inline-date:focus {
                background-color: #1e2233 !important;
                border-color: #818cf8 !important;
                box-shadow: 0 0 0 2px rgba(129, 140, 248, 0.25) !important;
            }

            html.theme-dark input[type="date"]::-webkit-calendar-picker-indicator {
                filter: invert(0.85);
            }
        }

        /* PRINT MEDIA STYLES - Exact Landscape Layout */
        @media print {
            @page {
                size: landscape;
                margin: 8mm 12mm 8mm 12mm;
            }

            html,
            body,
            form,
            #page-top,
            #wrapper,
            #content-wrapper,
            #content,
            .container-main,
            .container-fluid,
            .landscape-viewport,
            .landscape-sheet {
                background: #ffffff !important;
                background-color: #ffffff !important;
                color: #000000 !important;
                border: none !important;
                box-shadow: none !important;
                outline: none !important;
                padding: 0 !important;
                margin: 0 !important;
                min-height: auto !important;
                height: auto !important;
                width: 100% !important;
                max-width: 100% !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            #wrapper,
            #content-wrapper,
            #content {
                display: block !important;
                overflow: visible !important;
            }

            body.sticky-nav-page,
            body.sticky-nav-page #content-wrapper,
            body.sticky-nav-page #content,
            body.sticky-nav-page .container-main,
            body .container-main,
            .container-main {
                margin: 0 !important;
                margin-top: 0 !important;
                margin-bottom: 0 !important;
                padding: 0 !important;
                padding-top: 0 !important;
                padding-bottom: 0 !important;
                min-height: 0 !important;
                min-height: auto !important;
                height: auto !important;
                background: #ffffff !important;
                background-color: #ffffff !important;
            }

            html.theme-dark,
            html.theme-dark body,
            html.theme-dark form,
            html.theme-dark #page-top,
            html.theme-dark #wrapper,
            html.theme-dark #content-wrapper,
            html.theme-dark #content,
            html.theme-dark .container-main,
            html.theme-dark .container-fluid,
            html.theme-dark .landscape-viewport,
            html.theme-dark .landscape-sheet {
                background: #ffffff !important;
                background-color: #ffffff !important;
                color: #000000 !important;
            }

            html.theme-dark .rep-top-line1,
            html.theme-dark .rep-top-line2,
            html.theme-dark .rep-directorate-line,
            html.theme-dark .rep-cert-paragraph,
            html.theme-dark .rep-signatures-wrap,
            html.theme-dark .rep-to-block,
            html.theme-dark .rep-sig-left,
            html.theme-dark .rep-sig-right,
            html.theme-dark .rep-table th,
            html.theme-dark .rep-table td {
                color: #000000 !important;
                background-color: #ffffff !important;
            }

            .no-print,
            .report-toolbar-card,
            .btn-action-primary,
            .btn-action-word,
            .btn-action-secondary,
            .navbar,
            .navbar-custom,
            .app-sidebar,
            #toast-container,
            .topbar,
            #tourSpotlightRing,
            #tourTooltipPopover,
            .modal,
            .modal-backdrop {
                display: none !important;
                visibility: hidden !important;
                height: 0 !important;
                min-height: 0 !important;
                margin: 0 !important;
                padding: 0 !important;
                border: none !important;
                box-shadow: none !important;
            }

            .print-only {
                display: inline !important;
                font-family: Arial, sans-serif !important;
                font-size: 10pt !important;
                color: #000000 !important;
            }

            .rep-top-line1,
            .rep-top-line2,
            .rep-directorate-line {
                page-break-inside: avoid !important;
                break-inside: avoid !important;
                page-break-after: avoid !important;
                break-after: avoid !important;
            }

            .landscape-viewport {
                padding: 0 !important;
                margin: 0 !important;
                overflow: visible !important;
                display: block !important;
                width: 100% !important;
                min-height: auto !important;
                background: #ffffff !important;
                background-color: #ffffff !important;
                page-break-inside: auto !important;
                break-inside: auto !important;
            }

            .landscape-sheet {
                border: none !important;
                box-shadow: none !important;
                border-radius: 0 !important;
                padding: 0 !important;
                max-width: 100% !important;
                width: 100% !important;
                margin: 0 !important;
                min-height: auto !important;
                background: #ffffff !important;
                background-color: #ffffff !important;
                display: block !important;
                page-break-inside: auto !important;
                break-inside: auto !important;
            }

            .cell-inline-date {
                display: none !important;
            }

            .rep-table {
                page-break-before: auto !important;
                break-before: auto !important;
                page-break-inside: auto !important;
                break-inside: auto !important;
                background-color: #ffffff !important;
                border: 0.5pt solid #000000 !important;
                width: 100% !important;
            }

            .rep-table th,
            .rep-table td {
                background-color: #ffffff !important;
                color: #000000 !important;
                border: 0.5pt solid #000000 !important;
            }

            .rep-table th {
                font-weight: bold !important;
                text-align: center !important;
                background-color: #ffffff !important;
            }

            .rep-table thead {
                display: table-header-group !important;
                page-break-inside: avoid !important;
                break-inside: avoid !important;
                page-break-after: avoid !important;
                break-after: avoid !important;
            }

            .rep-table tbody {
                display: table-row-group !important;
                page-break-inside: auto !important;
                break-inside: auto !important;
            }

            .rep-table tr {
                page-break-inside: avoid !important;
                break-inside: avoid !important;
                page-break-after: auto !important;
                break-after: auto !important;
                background-color: #ffffff !important;
            }

            .rep-cert-paragraph,
            .rep-signatures-wrap,
            .rep-to-block {
                page-break-inside: avoid !important;
                break-inside: avoid !important;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid" style="padding: 0 16px;">
        
        <!-- NON-PRINTING ACTION TOOLBAR -->
        <div class="report-toolbar-card no-print">
            <!-- TOOLBAR HEADER: TITLE & ACTIONS -->
            <div class="toolbar-header-row">
                <div class="toolbar-title-wrap">
                    <a href="Reports.aspx" class="btn-action-back" title="Return to Reports Hub">
                        <i class="fas fa-arrow-left"></i>
                        <span>Reports Hub</span>
                    </a>
                    <div class="toolbar-title-content">
                        <h5 class="toolbar-title">
                            <i class="fas fa-file-invoice-dollar mr-2 text-primary"></i> Monthly Attendance &amp; Recommendation Report
                        </h5>
                        <span class="toolbar-subtitle">Official monthly verification, recommendation &amp; voucher generator</span>
                    </div>
                </div>

                <div class="toolbar-actions-wrap">
                    <!-- Column Visibility Dropdown -->
                    <div style="position: relative;">
                        <button type="button" class="btn-toolbar-btn" onclick="toggleColDropdown(event)" title="Toggle Columns">
                            <i class="fas fa-columns"></i>
                            <span>Columns</span>
                            <i class="fas fa-chevron-down ml-1" style="font-size: 0.72rem; opacity: 0.7;"></i>
                        </button>
                        <div class="col-dropdown-menu" id="colDropdownMenu">
                            <div class="d-flex justify-content-between align-items-center mb-2 pb-1 border-bottom">
                                <span class="font-weight-bold col-dropdown-title" style="font-size: 0.8rem;">Column Visibility</span>
                                <button type="button" class="btn btn-link btn-sm p-0 font-weight-bold" style="font-size: 0.75rem;" onclick="resetAllColumns()">Show All</button>
                            </div>
                            <label class="col-item-label"><input type="checkbox" id="chk_col-cat-manpower" checked onchange="toggleCol('col-cat-manpower', this.checked)" /> <span>Category / Manpower</span></label>
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

                    <!-- Refresh Button -->
                    <button type="button" class="btn-toolbar-btn" onclick="loadReportData()" title="Refresh Report Data">
                        <i class="fas fa-sync-alt"></i>
                        <span>Refresh</span>
                    </button>

                    <div class="toolbar-btn-divider"></div>

                    <!-- Print Button -->
                    <button type="button" class="btn-action-primary" onclick="triggerLandscapePrint()" title="Print in Landscape Orientation">
                        <i class="fas fa-print"></i>
                        <span>Print (Landscape)</span>
                    </button>

                    <!-- Export to Word Button -->
                    <button type="button" class="btn-action-word" onclick="triggerWordExport()" title="Download editable Word Document (.doc)">
                        <i class="fas fa-file-word"></i>
                        <span>Export to Word</span>
                    </button>
                </div>
            </div>

            <!-- PRIMARY FILTERS ROW (Spacious, 4 items only) -->
            <div class="filter-main-grid">
                <div class="filter-cell filter-cell-year">
                    <label class="filter-label" for="ddlYear">
                        <i class="far fa-calendar text-primary"></i> Year
                    </label>
                    <select id="ddlYear" class="form-select-custom" onchange="onYearChange()"></select>
                </div>

                <div class="filter-cell filter-cell-month">
                    <label class="filter-label" for="ddlMonth">
                        <i class="far fa-calendar-alt text-primary"></i> Month
                    </label>
                    <select id="ddlMonth" class="form-select-custom" onchange="onMonthChange()">
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

                <div class="filter-cell filter-cell-cat">
                    <label class="filter-label" for="ddlCategory">
                        <i class="fas fa-layer-group text-primary"></i> Category / Tier
                    </label>
                    <select id="ddlCategory" class="form-select-custom" onchange="onCategoryChange()"></select>
                </div>

                <div class="filter-cell filter-cell-contract">
                    <label class="filter-label" for="ddlContract">
                        <i class="fas fa-file-contract text-primary"></i> Contract / Vendor
                    </label>
                    <select id="ddlContract" class="form-select-custom" onchange="loadReportData()"></select>
                </div>
            </div>

            <!-- SUBPANEL: SUGGESTED PAYMENT DATES & NOTICE -->
            <div class="toolbar-subpanel">
                <div class="subpanel-dates-group">
                    <span class="subpanel-badge-label">
                        <i class="fas fa-sliders-h text-primary mr-1"></i> Suggested Payment Dates:
                    </span>

                    <!-- Bulk Salary Date -->
                    <div class="date-picker-inline" title="Click to select Previous Month Salary Date to auto-fill rows">
                        <span class="date-picker-tag" onclick="openDateInput('txtMasterSalaryDate')">
                            <i class="fas fa-money-bill-wave text-primary mr-1"></i> Salary Date:
                        </span>
                        <div class="date-input-unified">
                            <input type="date" id="txtMasterSalaryDate" onchange="applyMasterSalaryDate(this.value)" onclick="handleDateInputClick(event, this)" title="Click to select Previous Month Salary Date" />
                            <button type="button" class="btn-date-clear-inline" onclick="clearMasterSalaryDate()" title="Clear Salary Date">
                                <i class="fas fa-times"></i>
                            </button>
                        </div>
                    </div>

                    <!-- Bulk EPF Date -->
                    <div class="date-picker-inline" title="Click to select Previous Month EPF Date to auto-fill rows">
                        <span class="date-picker-tag" onclick="openDateInput('txtMasterEpfDate')">
                            <i class="fas fa-shield-alt text-success mr-1"></i> EPF Date:
                        </span>
                        <div class="date-input-unified">
                            <input type="date" id="txtMasterEpfDate" onchange="applyMasterEpfDate(this.value)" onclick="handleDateInputClick(event, this)" title="Click to select Previous Month EPF Date" />
                            <button type="button" class="btn-date-clear-inline" onclick="clearMasterEpfDate()" title="Clear EPF Date">
                                <i class="fas fa-times"></i>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Integrated Notice Banner -->
                <div class="subpanel-notice">
                    <i class="fas fa-info-circle subpanel-notice-icon"></i>
                    <div class="subpanel-notice-text">
                        <strong>Notice:</strong> <em>Total man days attended</em> includes only actual office working days attended. Declared public holidays, paid leaves, and weekly offs are excluded.
                    </div>
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

                <!-- 9-COLUMN REPORT TABLE -->
                <table class="rep-table" id="reportTable">
                    <thead>
                        <tr>
                            <th class="col-cat-manpower" style="width: 12%;">Category / Manpower</th>
                            <th class="col-id" style="width: 6%;">ID No.</th>
                            <th class="col-name" style="width: 18%;">Name of the Individual</th>
                            <th class="col-attended" style="width: 8%;">Total no. of man days attended <i class="fas fa-info-circle text-primary no-print ml-1" style="font-size: 0.8rem; cursor: help;" title="Notice: Total attended days counts only actual working days attended; it does not include public holidays, paid leave, or weekly offs."></i></th>
                            <th class="col-not-attended" style="width: 8%;">Total no. of days not attended</th>
                            <th class="col-remarks" style="width: 19%;">Remarks</th>
                            <th class="col-salary-date" id="thSalaryDate" style="width: 9.5%;">Received date of Previous Month<br />Salary<br /><span id="lblPrevMonSalary">( May)</span></th>
                            <th class="col-epf-date" id="thEpfDate" style="width: 9.5%;">Received date of Previous Month EPF Contribution<br /><span id="lblPrevMonEpf">( May)</span></th>
                            <th class="col-sig" style="width: 10%;">Signature of the Individual</th>
                        </tr>
                    </thead>
                    <tbody id="reportTableBody">
                        <tr>
                            <td colspan="9" style="padding: 30px; color: #64748b;">
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
        let isUserPoc = false;
        let columnVisibility = {
            'col-cat-manpower': true,
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

                isUserPoc = (data.IsPoc === true);

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

                // Apply POC view restriction constraints for initial selection
                applyPocViewRestrictions();

                // Trigger contracts and initial report load
                onCategoryChange();
            })
            .catch(() => {
                showToast("Failed to initialize report parameters.", "error");
            });
        }

        function getSelectedCategoryInfo() {
            const catSelect = document.getElementById('ddlCategory');
            if (!catSelect || !catSelect.value) return null;
            const tid = parseInt(catSelect.value);
            return currentCategories.find(c => c.TierId === tid) || null;
        }

        function applyPocViewRestrictions() {
            const ySelect = document.getElementById('ddlYear');
            const mSelect = document.getElementById('ddlMonth');
            if (!ySelect || !mSelect) return;

            const catInfo = getSelectedCategoryInfo();
            const isRestricted = isUserPoc && catInfo && catInfo.IsRestricted;

            if (!isRestricted) {
                // Remove all restrictions
                Array.from(ySelect.options).forEach(opt => {
                    opt.disabled = false;
                    opt.style.color = '';
                    opt.style.backgroundColor = '';
                });
                Array.from(mSelect.options).forEach(opt => {
                    opt.disabled = false;
                    opt.style.color = '';
                    opt.style.backgroundColor = '';
                });
                return;
            }

            const minD = catInfo.MinAllowedDate ? new Date(catInfo.MinAllowedDate + 'T00:00:00') : null;
            const maxD = catInfo.MaxAllowedDate ? new Date(catInfo.MaxAllowedDate + 'T23:59:59') : null;

            // 1. Filter Years
            let firstValidYear = null;
            Array.from(ySelect.options).forEach(opt => {
                const y = parseInt(opt.value);
                const yStart = new Date(y, 0, 1, 0, 0, 0);
                const yEnd = new Date(y, 11, 31, 23, 59, 59);

                let allowed = true;
                if (minD && yEnd < minD) allowed = false;
                if (maxD && yStart > maxD) allowed = false;

                opt.disabled = !allowed;
                if (!allowed) {
                    opt.style.color = '#94a3b8';
                    opt.style.backgroundColor = document.documentElement.classList.contains('theme-dark') ? '#1e293b' : '#f1f5f9';
                } else {
                    opt.style.color = '';
                    opt.style.backgroundColor = '';
                    if (firstValidYear === null) firstValidYear = opt.value;
                }
            });

            // If selected year is disabled, select first valid year
            if (ySelect.options[ySelect.selectedIndex] && ySelect.options[ySelect.selectedIndex].disabled && firstValidYear !== null) {
                ySelect.value = firstValidYear;
            }

            // 2. Filter Months for selected Year
            const curY = parseInt(ySelect.value);
            let firstValidMonth = null;
            Array.from(mSelect.options).forEach(opt => {
                const m = parseInt(opt.value); // 1 to 12
                const mStart = new Date(curY, m - 1, 1, 0, 0, 0);
                const mEnd = new Date(curY, m, 0, 23, 59, 59);

                let allowed = true;
                if (minD && mEnd < minD) allowed = false;
                if (maxD && mStart > maxD) allowed = false;

                opt.disabled = !allowed;
                if (!allowed) {
                    opt.style.color = '#94a3b8';
                    opt.style.backgroundColor = document.documentElement.classList.contains('theme-dark') ? '#1e293b' : '#f1f5f9';
                } else {
                    opt.style.color = '';
                    opt.style.backgroundColor = '';
                    if (firstValidMonth === null) firstValidMonth = opt.value;
                }
            });

            // If selected month is disabled, select first valid month
            if (mSelect.options[mSelect.selectedIndex] && mSelect.options[mSelect.selectedIndex].disabled && firstValidMonth !== null) {
                mSelect.value = firstValidMonth;
            }
        }

        function onYearChange() {
            applyPocViewRestrictions();
            const year = parseInt(document.getElementById('ddlYear').value);
            const month = parseInt(document.getElementById('ddlMonth').value);
            updateDefaultMasterDates(year, month);
            onCategoryChange();
        }

        function onMonthChange() {
            applyPocViewRestrictions();
            const year = parseInt(document.getElementById('ddlYear').value);
            const month = parseInt(document.getElementById('ddlMonth').value);
            updateDefaultMasterDates(year, month);
            loadReportData();
        }

        function onFilterChange() {
            onYearChange();
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
            applyPocViewRestrictions();
            const year = parseInt(document.getElementById('ddlYear').value);
            const month = parseInt(document.getElementById('ddlMonth').value);
            const tierId = parseInt(document.getElementById('ddlCategory').value);

            if (!year || !month || !tierId) return;
            updateDefaultMasterDates(year, month);

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
            tbody.innerHTML = `<tr><td colspan="9" style="padding: 35px; color: #64748b;"><i class="fas fa-spinner fa-spin mr-2"></i> Generating report data...</td></tr>`;

            fetch('MonthlyAttendanceReport.aspx/GetReportData', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ year: year, month: month, tierId: tierId, contractPeriodId: contractId })
            })
            .then(r => r.json())
            .then(res => {
                const data = JSON.parse(res.d || "{}");
                if (data.status === "error") {
                    tbody.innerHTML = `<tr><td colspan="9" style="padding: 25px; color: #ef4444;"><i class="fas fa-exclamation-triangle mr-2"></i> ${data.message}</td></tr>`;
                    return;
                }

                currentReportData = data;
                renderReportView(data);
            })
            .catch(err => {
                tbody.innerHTML = `<tr><td colspan="9" style="padding: 25px; color: #ef4444;">Failed to load attendance report.</td></tr>`;
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

            // 7. Render Table Rows with Merged Category / Manpower Cell
            const tbody = document.getElementById('reportTableBody');
            tbody.innerHTML = '';

            const emps = data.Employees || [];
            if (emps.length === 0) {
                tbody.innerHTML = `<tr><td colspan="9" style="padding: 30px; color: #94a3b8;"><i class="fas fa-info-circle mr-2"></i> No active employees found for this category and division during the selected month.</td></tr>`;
                return;
            }

            const masterSalaryDate = document.getElementById('txtMasterSalaryDate').value || "";
            const masterEpfDate = document.getElementById('txtMasterEpfDate').value || "";

            let catText = (data.CategoryName || '').trim();
            let manText = (data.ManpowerDesc || '').trim();
            let displayText = '';

            if (catText && manText) {
                if (catText.toLowerCase() === manText.toLowerCase()) {
                    displayText = catText;
                } else {
                    displayText = catText + ' / ' + manText;
                }
            } else {
                displayText = catText || manText || '';
            }

            emps.forEach((emp, index) => {
                const tr = document.createElement('tr');

                // If first row, render merged Category / Manpower cell spanning all rows
                if (index === 0) {
                    const tdCatMan = document.createElement('td');
                    tdCatMan.className = 'col-cat-manpower cell-center cell-bold';
                    tdCatMan.rowSpan = emps.length;
                    tdCatMan.textContent = displayText;
                    tr.appendChild(tdCatMan);
                }

                // ID No.
                const tdId = document.createElement('td');
                tdId.className = 'col-id cell-center';
                tdId.textContent = emp.ID;
                tr.appendChild(tdId);

                // Name
                const tdName = document.createElement('td');
                tdName.className = 'col-name cell-left';
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
                tdRem.className = 'col-remarks cell-left';
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
                    <table class="sig-table" style="width: 100%; border: none !important; border-collapse: collapse; margin-top: 8pt; margin-bottom: 6pt; mso-margin-top-alt: 8pt; mso-margin-bottom-alt: 6pt;">
                        <tr>
                            <td style="border: none !important; text-align: left; font-family: Arial, sans-serif; font-size: 10pt; font-weight: bold; width: 50%; vertical-align: top; padding: 0; mso-margin-top-alt: 0; mso-margin-bottom-alt: 0;">${leftText}</td>
                            <td style="border: none !important; text-align: right; font-family: Arial, sans-serif; font-size: 10pt; font-weight: bold; width: 50%; vertical-align: top; padding: 0; mso-margin-top-alt: 0; mso-margin-bottom-alt: 0;">${rightText}</td>
                        </tr>
                    </table>
                `;
            }

            // Adjust To block indentation and spacing for Word
            const toBlock = clone.querySelector('#toBlockEl');
            if (toBlock) {
                toBlock.querySelectorAll('div').forEach((div, idx) => {
                    if (idx > 0) {
                        div.style.paddingLeft = '20pt';
                    }
                    div.style.margin = '0';
                    div.style.msoMarginTopAlt = '0';
                    div.style.msoMarginBottomAlt = '0';
                });
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
  size: 11.69in 8.27in;
  mso-page-orientation: landscape;
  margin: 0.3in 0.5in 0.3in 0.5in;
  mso-header-margin: 0.15in;
  mso-footer-margin: 0.15in;
}
div.Section1 { page: Section1; }
body {
  font-family: Arial, sans-serif;
  font-size: 10pt;
  color: #000000;
  margin: 0;
  padding: 0;
}
p, div {
  margin: 0;
  padding: 0;
  mso-margin-top-alt: 0;
  mso-margin-bottom-alt: 0;
  mso-line-height-rule: at-least;
}
.rep-top-line1 {
  font-family: Arial, sans-serif !important;
  font-weight: bold !important;
  font-size: 11pt !important;
  text-align: center !important;
  margin: 0 0 2pt 0 !important;
  mso-margin-bottom-alt: 2pt;
  line-height: 1.15;
}
.rep-top-line2 {
  font-family: Arial, sans-serif !important;
  font-weight: bold !important;
  font-size: 10pt !important;
  text-align: center !important;
  margin: 0 0 4pt 0 !important;
  mso-margin-bottom-alt: 4pt;
  line-height: 1.15;
}
.rep-directorate-line {
  font-family: Arial, sans-serif !important;
  font-weight: bold !important;
  font-size: 10pt !important;
  text-align: left !important;
  margin: 0 0 4pt 0 !important;
  mso-margin-bottom-alt: 4pt;
}
table.rep-table {
  border-collapse: collapse;
  width: 100%;
  margin-top: 2pt;
  margin-bottom: 6pt;
  mso-margin-top-alt: 2pt;
  mso-margin-bottom-alt: 6pt;
  border: 0.5pt solid #000000;
  mso-table-lspace: 0pt;
  mso-table-rspace: 0pt;
}
table.rep-table th, table.rep-table td {
  border: 0.5pt solid #000000;
  padding: 2.5pt 3.5pt;
  vertical-align: middle;
  mso-margin-top-alt: 0;
  mso-margin-bottom-alt: 0;
  line-height: 1.12;
}
table.rep-table th {
  font-family: Arial, sans-serif;
  font-size: 9pt;
  font-weight: bold;
  text-align: center;
  background-color: #ffffff;
}
table.rep-table td {
  font-family: Arial, sans-serif;
  font-size: 9pt;
  text-align: center;
}
.cell-left { text-align: left !important; }
.cell-center { text-align: center !important; }
.cell-right { text-align: right !important; }
.cell-bold { font-weight: bold !important; }
.rep-cert-paragraph {
  font-family: Arial, sans-serif !important;
  font-size: 9.5pt !important;
  text-align: left !important;
  margin: 5pt 0 8pt 0 !important;
  mso-margin-top-alt: 5pt;
  mso-margin-bottom-alt: 8pt;
  line-height: 1.2;
}
table.sig-table {
  width: 100%;
  border-collapse: collapse;
  border: none !important;
  margin-top: 8pt;
  margin-bottom: 6pt;
  mso-margin-top-alt: 8pt;
  mso-margin-bottom-alt: 6pt;
}
table.sig-table td {
  border: none !important;
  padding: 0;
  font-family: Arial, sans-serif;
  font-size: 10pt;
  font-weight: bold;
  vertical-align: top;
  mso-margin-top-alt: 0;
  mso-margin-bottom-alt: 0;
}
.rep-to-block {
  font-family: Arial, sans-serif;
  font-size: 10pt;
  text-align: left;
  margin-top: 6pt;
  mso-margin-top-alt: 6pt;
  line-height: 1.15;
}
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
