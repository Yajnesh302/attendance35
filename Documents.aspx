<%@ Page Title="Documents" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
    CodeBehind="Documents.aspx.cs" Inherits="AttendanceApp.Documents" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>

    <asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
        Documents & Certificates
    </asp:Content>

    <asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
        <meta charset="utf-8" />
        <script src="Static/js/xlsx.full.min.js?v=1.2.0"></script>
        <style>
            .control-panel-card {
                background: white;
                border-radius: 12px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
                border: 1px solid #e2e8f0;
                padding: 24px;
                margin-bottom: 24px;
            }

            .filter-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 16px;
                margin-bottom: 16px;
            }

            .form-label-bold {
                font-weight: 700;
                color: #334155;
                font-size: 0.85rem;
                margin-bottom: 6px;
                display: block;
            }

            .form-control-custom {
                height: 38px !important;
                font-size: 0.9rem;
                border-radius: 6px;
                border: 1px solid #cbd5e1;
                color: #1e293b;
                font-weight: 500;
                width: 100%;
                padding: 6px 12px;
                box-sizing: border-box;
                background-color: #f8fafc;
            }

            .form-control-custom:focus {
                border-color: #4f46e5;
                box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.15);
                background-color: #ffffff;
                outline: none;
            }

            /* Checkbox Toggles block */
            .settings-section-title {
                font-size: 0.8rem;
                font-weight: 700;
                text-transform: uppercase;
                letter-spacing: 0.05em;
                color: #64748b;
                margin-bottom: 10px;
                border-bottom: 1px solid #f1f5f9;
                padding-bottom: 4px;
            }

            .checkbox-group {
                display: flex;
                flex-wrap: wrap;
                gap: 12px 20px;
                margin-bottom: 16px;
            }

            .checkbox-item {
                display: inline-flex;
                align-items: center;
                font-size: 0.88rem;
                font-weight: 600;
                color: #475569;
                cursor: pointer;
                user-select: none;
            }

            .checkbox-item input[type="checkbox"] {
                margin-right: 8px;
                width: 16px;
                height: 16px;
                accent-color: #4f46e5;
                cursor: pointer;
            }

            .btn-action-container {
                display: flex;
                gap: 12px;
                justify-content: flex-end;
                margin-top: 16px;
                border-top: 1px solid #f1f5f9;
                padding-top: 16px;
            }

            .settings-info-panel {
                color: #64748b;
                font-size: 0.78rem;
                line-height: 1.5;
                background-color: #f8fafc;
                padding: 10px;
                border-radius: 6px;
                border: 1px solid #e2e8f0;
                width: 100%;
                box-sizing: border-box;
            }

            .settings-parameter-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
                gap: 16px;
                margin-bottom: 16px;
                background-color: #f8fafc;
                padding: 16px;
                border-radius: 8px;
                border: 1px solid #e2e8f0;
            }

            /* Local dark theme overrides to prevent browser cache issues */
            html.theme-dark .settings-parameter-grid {
                background-color: #1e2233 !important;
                border-color: #2d3348 !important;
            }

            html.theme-dark .settings-info-panel {
                background-color: #1e2233 !important;
                border-color: #2d3348 !important;
                color: #cbd5e1 !important;
            }

            /* Placeholders Drawer styling */

            .placeholders-drawer {
                position: fixed;
                top: 0;
                right: -400px;
                width: 380px;
                height: 100vh;
                background-color: #ffffff;
                box-shadow: -10px 0 30px rgba(0, 0, 0, 0.1);
                border-left: 1px solid #e2e8f0;
                z-index: 100000;
                transition: right 0.35s cubic-bezier(0.4, 0, 0.2, 1);
                display: flex;
                flex-direction: column;
            }

            .placeholders-drawer.open {
                right: 0;
            }

            /* Wages Alternate Service Charge Drawer */
            .wages-sidebar-drawer {
                position: fixed;
                top: 0;
                right: -480px;
                width: 440px;
                max-width: 95vw;
                height: 100vh;
                background-color: #ffffff;
                box-shadow: -10px 0 35px rgba(0, 0, 0, 0.15);
                border-left: 1px solid #e2e8f0;
                z-index: 100000;
                transition: right 0.35s cubic-bezier(0.4, 0, 0.2, 1);
                display: flex;
                flex-direction: column;
            }

            .wages-sidebar-drawer.open {
                right: 0;
            }

            .drawer-header {
                padding: 20px;
                border-bottom: 1px solid #f1f5f9;
                display: flex;
                align-items: center;
                justify-content: space-between;
                background-color: #f8fafc;
            }

            .drawer-content {
                padding: 20px;
                overflow-y: auto;
                flex: 1;
            }

            .drawer-close-btn {
                background: none;
                border: none;
                font-size: 1.5rem;
                font-weight: 700;
                color: #64748b;
                cursor: pointer;
                line-height: 1;
                padding: 4px 8px;
                border-radius: 4px;
                transition: all 0.15s ease;
            }

            .drawer-close-btn:hover {
                background-color: #e2e8f0;
                color: #0f172a;
            }

            .drawer-overlay {
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
                background-color: rgba(15, 23, 42, 0.4);
                backdrop-filter: blur(2px);
                z-index: 99999;
                display: none;
            }

            /* Alternate Service Charge Overlay - No blur and transparent so main bill remains completely clear */
            #wagesAltDrawerOverlay,
            html.theme-dark #wagesAltDrawerOverlay {
                background-color: transparent !important;
                backdrop-filter: none !important;
                -webkit-backdrop-filter: none !important;
            }

            html.theme-dark .placeholders-drawer,
            html.theme-dark .wages-sidebar-drawer {
                background-color: #161922 !important;
                border-left-color: #2d3348 !important;
                box-shadow: -10px 0 35px rgba(0, 0, 0, 0.6) !important;
                color: #e2e8f0 !important;
            }

            html.theme-dark .drawer-header {
                background-color: #1e2233 !important;
                border-bottom-color: #2d3348 !important;
            }

            html.theme-dark .drawer-close-btn:hover {
                background-color: #2d3348 !important;
                color: #f1f5f9 !important;
            }

            html.theme-dark .drawer-overlay {
                background-color: rgba(0, 0, 0, 0.6) !important;
            }

            .btn-custom {
                height: 38px;
                padding: 0 20px;
                font-size: 0.9rem;
                font-weight: 700;
                border-radius: 6px;
                border: none;
                display: inline-flex;
                align-items: center;
                gap: 8px;
                cursor: pointer;
                transition: all 0.15s ease;
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
            }

            .btn-custom:hover {
                transform: translateY(-1px);
            }

            .btn-load {
                background-color: #4f46e5;
                color: white;
            }

            .btn-load:hover {
                background-color: #3730a3;
                box-shadow: 0 4px 12px rgba(79, 70, 229, 0.25);
            }

            .btn-print {
                background-color: #10b981;
                color: white;
            }

            .btn-print:hover {
                background-color: #059669;
                box-shadow: 0 4px 12px rgba(16, 185, 129, 0.25);
            }

            .btn-excel {
                background-color: #f59e0b;
                color: white;
            }

            .btn-excel:hover {
                background-color: #d97706;
                box-shadow: 0 4px 12px rgba(245, 158, 11, 0.25);
            }

            /* -- Preview sheet styling (A4 representation) -- */
            .preview-container {
                background-color: #f1f5f9;
                padding: 30px 10px;
                border-radius: 12px;
                border: 1px dashed #cbd5e1;
                margin-top: 20px;
            }

            .preview-sheet {
                background: white;
                padding: 60px 50px;
                border-radius: 8px;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
                max-width: 1050px;
                margin: 0 auto;
                color: #000000 !important;
                font-family: 'Times New Roman', Times, serif;
                min-height: 800px;
                border: 1px solid #e2e8f0;
                box-sizing: border-box;
            }

            .sheet-editable-hdr {
                text-align: center;
                margin-bottom: 24px;
                outline: none;
                padding: 4px;
                border-radius: 4px;
                transition: background 0.15s;
            }

            .sheet-editable-hdr:hover {
                background-color: #f8fafc;
                box-shadow: 0 0 0 1px #cbd5e1;
            }

            .sheet-editable-hdr:focus {
                background-color: #ffffff;
                box-shadow: 0 0 0 2px #4f46e5;
            }

            .sheet-title {
                font-size: 1.85rem;
                font-weight: bold;
                letter-spacing: 0.12em;
                margin-bottom: 20px;
                text-transform: uppercase;
            }

            .sheet-desc {
                font-size: 1.08rem;
                line-height: 1.7;
                text-align: justify;
                margin-bottom: 12px;
            }

            #repTitle1,
            #repTitle2 {
                font-size: 14pt !important;
                font-weight: bold !important;
                text-align: center !important;
                text-transform: none !important;
                letter-spacing: normal !important;
                line-height: 1.5 !important;
            }

            /* Attendance certificate: top two sentences centred at 14pt */
            #certDesc1,
            #certDesc2 {
                font-size: 14pt !important;
                text-align: center !important;
                line-height: 1.6 !important;
            }

            .sat-paragraph-wrap {
                margin-bottom: 24px;
                font-size: 1.15rem;
                line-height: 1.8;
                text-align: left;
            }

            .cov-paragraph-wrap {
                margin-bottom: 50px;
                text-align: left;
                text-indent: 48px;
                line-height: 1.6;
            }


            /* Certificate Table layout */
            .table-cert-print {
                width: 100%;
                border-collapse: collapse !important;
                margin: 24px 0;
                font-size: 1.15rem;
                color: #000 !important;
                border: 1.5px solid #000000 !important;
                table-layout: fixed !important;
            }

            .table-cert-print th,
            #certTable th,
            #reportTable th {
                border: 1.5px solid #000000 !important;
                padding: 5px 8px !important;
                font-weight: bold;
                text-transform: uppercase;
                font-size: 1.0rem;
                background-color: #f8fafc !important;
                text-align: center;
                vertical-align: middle;
                white-space: normal !important;
                word-wrap: break-word !important;
                overflow-wrap: break-word !important;
                word-break: break-word !important;
            }

            .table-cert-print td,
            #certTable td,
            #reportTable td {
                border: 1px solid #000000 !important;
                padding: 5px 8px !important;
                text-align: center;
                vertical-align: middle;
                outline: none;
                word-wrap: break-word !important;
                overflow-wrap: break-word !important;
            }

            .table-cert-print td:focus {
                background-color: #eff6ff !important;
                box-shadow: inset 0 0 0 2px #3b82f6;
            }

            .table-cert-print td.text-left {
                text-align: left;
            }

            /* Column widths for screen */
            .table-cert-print .col-sno,
            .table-cert-print .rep-col-sno {
                width: 5%;
            }

            .table-cert-print .col-id,
            .table-cert-print .rep-col-id {
                width: 5%;
            }

            .table-cert-print .col-name,
            .table-cert-print .rep-col-name {
                width: 27%;
                text-align: left;
            }

            .table-cert-print .col-final,
            .table-cert-print .rep-col-final {
                width: 9%;
            }

            .table-cert-print .col-paid,
            .table-cert-print .rep-col-paid {
                width: 7%;
            }

            .table-cert-print .col-unpaid,
            .table-cert-print .rep-col-unpaid {
                width: 8%;
            }

            .table-cert-print .col-satcut,
            .table-cert-print .rep-col-satcut {
                width: 8%;
            }

            .table-cert-print .col-remarks,
            .table-cert-print .rep-col-remarks {
                width: 31%;
                text-align: left;
            }



            #wagesTable {
                border: 1px solid #000000 !important;
                border-collapse: collapse !important;
            }

            #wagesTable th,
            #wagesTable td {
                border: 1px solid #000000 !important;
            }

            /* Signatures block */
            .signature-section {
                display: flex;
                justify-content: space-between;
                margin-top: 80px;
                padding: 0 16px;
            }

            .sig-block {
                text-align: center;
                width: 280px;
                border-top: 1.5px solid #000000;
                padding-top: 8px;
                font-size: 0.9rem;
                font-weight: bold;
                outline: none;
                border-radius: 4px;
            }

            .sig-block:hover {
                background-color: #f8fafc;
                box-shadow: 0 0 0 1px #cbd5e1;
            }

            .sig-block:focus {
                background-color: #ffffff;
                box-shadow: 0 0 0 2px #4f46e5;
            }

            /* Global Toast Styles */
            #toast-container {
                position: fixed;
                top: 24px;
                right: 24px;
                display: flex;
                flex-direction: column;
                gap: 12px;
                z-index: 200000 !important;
                pointer-events: none;
            }

            .modern-toast {
                display: flex;
                align-items: center;
                gap: 14px;
                background: rgba(255, 255, 255, 0.95);
                backdrop-filter: blur(12px) saturate(180%);
                border-radius: 12px;
                padding: 14px 20px;
                min-width: 320px;
                max-width: 420px;
                color: #1e293b;
                font-size: 0.92rem;
                font-weight: 600;
                box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), inset 0 0 0 1px rgba(255, 255, 255, 0.5);
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
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .toast-success {
                border-left-color: #10b981;
                background: rgba(240, 253, 250, 0.98);
            }

            .toast-success .toast-icon {
                color: #10b981;
            }

            .toast-warning {
                border-left-color: #f59e0b;
                background: rgba(255, 251, 235, 0.98);
            }

            .toast-warning .toast-icon {
                color: #f59e0b;
            }

            .toast-error {
                border-left-color: #ef4444;
                background: rgba(254, 242, 242, 0.98);
            }

            .toast-error .toast-icon {
                color: #ef4444;
            }

            .toast-close-btn {
                background: transparent;
                border: none;
                color: #94a3b8;
                cursor: pointer;
                font-size: 1.2rem;
                margin-left: auto;
                line-height: 1;
            }

            /* Loader block */
            #previewLoader {
                display: none;
                text-align: center;
                padding: 60px;
                color: #4f46e5;
                font-weight: bold;
            }

            /* -- Document Hub Grid Styling -- */
            .hub-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
                gap: 20px;
                margin-bottom: 24px;
            }

            .hub-card {
                background: white;
                border-radius: 12px;
                border: 1px solid #e2e8f0;
                padding: 24px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.03);
                cursor: pointer;
                transition: all 0.2s ease-in-out;
                display: flex;
                flex-direction: column;
                position: relative;
                text-decoration: none !important;
                box-sizing: border-box;
            }

            .hub-card:hover {
                transform: translateY(-4px);
                box-shadow: 0 10px 20px rgba(79, 70, 229, 0.08);
                border-color: #4f46e5;
            }

            .hub-card-icon {
                width: 46px;
                height: 46px;
                border-radius: 10px;
                background: rgba(79, 70, 229, 0.08);
                color: #4f46e5;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 1.3rem;
                margin-bottom: 16px;
                transition: all 0.2s ease;
            }

            .hub-card:hover .hub-card-icon {
                background: #4f46e5;
                color: white;
            }

            .hub-card-title {
                font-size: 1.05rem;
                font-weight: 700;
                color: #1e293b;
                margin-bottom: 8px;
            }

            .hub-card-desc {
                font-size: 0.84rem;
                color: #64748b;
                line-height: 1.5;
                margin-bottom: 20px;
                flex-grow: 1;
            }

            .hub-card-btn {
                font-size: 0.84rem;
                font-weight: 700;
                color: #4f46e5;
                display: inline-flex;
                align-items: center;
                gap: 4px;
            }

            .hub-card.disabled {
                cursor: not-allowed;
                opacity: 0.65;
                background: #f8fafc;
                border-color: #cbd5e1;
            }

            .hub-card.disabled:hover {
                transform: none;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.03);
                border-color: #cbd5e1;
            }

            .hub-card.disabled .hub-card-icon {
                background: #e2e8f0;
                color: #94a3b8;
            }

            .hub-card-badge {
                position: absolute;
                top: 12px;
                right: 12px;
                background: #e2e8f0;
                color: #475569;
                font-size: 0.68rem;
                font-weight: 700;
                padding: 2px 8px;
                border-radius: 20px;
                text-transform: uppercase;
            }

            /* -- Print Media Styles -- */
            @media print {
                @page {
                    size: A4 portrait;
                    margin: 6mm 10mm;
                }

                html,
                body,
                form,
                #wrapper,
                #content-wrapper,
                #content,
                .container-main {
                    background: white !important;
                    background-color: white !important;
                    color: black !important;
                    border: none !important;
                    box-shadow: none !important;
                    padding: 0 !important;
                    margin: 0 !important;
                }

                .app-sidebar,
                .navbar-custom,
                .container-main>h2,
                .container-main>hr,
                .control-panel-card,
                #toast-container,
                .btn-print-hide {
                    display: none !important;
                }

                .container-main {
                    padding: 0 !important;
                    margin: 0 !important;
                    background-color: transparent !important;
                }

                .preview-container {
                    background: transparent !important;
                    border: none !important;
                    padding: 0 !important;
                    margin: 0 !important;
                    box-shadow: none !important;
                }

                #printSheet,
                #reportPrintSheet {
                    border: none !important;
                    box-shadow: none !important;
                    padding: 0 !important;
                    margin: 0 !important;
                    width: 100% !important;
                    max-width: 100% !important;
                }

                #satisfactoryPrintSheet {
                    border: none !important;
                    box-shadow: none !important;
                    padding: 40px 50px !important;
                    margin: 0 auto !important;
                    width: 100% !important;
                    max-width: 100% !important;
                    box-sizing: border-box !important;
                    background: white !important;
                    font-size: 14pt !important;
                    line-height: 1.8 !important;
                }

                .sat-header-img-wrap {
                    margin-bottom: 25pt !important;
                }

                .sat-date-wrap {
                    margin-bottom: 25pt !important;
                }

                .sat-title-wrap {
                    margin-bottom: 25pt !important;
                    font-size: 14pt !important;
                }

                .sat-paragraph-wrap {
                    margin-bottom: 25pt !important;
                    font-size: 14pt !important;
                    line-height: 1.8 !important;
                    text-align: justify !important;
                }

                #satParagraph3.sat-paragraph-wrap {
                    margin-bottom: 50pt !important;
                }

                .sat-sig-wrap {
                    margin-top: 0 !important;
                }

                #coveringLetterPrintSheet {
                    border: none !important;
                    box-shadow: none !important;
                    padding: 40px 50px !important;
                    margin: 0 auto !important;
                    width: 100% !important;
                    max-width: 100% !important;
                    box-sizing: border-box !important;
                    background: white !important;
                    font-family: Arial, Helvetica, sans-serif !important;
                    font-size: 1.15rem !important;
                    line-height: 1.8 !important;
                }

                #wagesPrintSheet {
                    border: none !important;
                    box-shadow: none !important;
                    padding: 40px 50px !important;
                    margin: 0 auto !important;
                    width: 100% !important;
                    max-width: 100% !important;
                    box-sizing: border-box !important;
                    background: transparent !important;
                }

                /* Hide the signature section on print */
                .signature-section {
                    display: none !important;
                }

                /* Shrink typography and margins to fit on a single page */
                .sheet-title {
                    font-size: 1.3rem !important;
                    margin-bottom: 8px !important;
                }

                .sheet-desc {
                    font-size: 0.85rem !important;
                    margin-bottom: 4px !important;
                    line-height: 1.4 !important;
                    text-align: justify !important;
                }

                /* Attendance certificate: keep top sentences centred and 14pt on print */
                #certDesc1,
                #certDesc2 {
                    font-size: 14pt !important;
                    text-align: center !important;
                    line-height: 1.6 !important;
                }

                /* Style and shrink table for print to fit 50 rows on page 1 */
                .table-cert-print {
                    margin: 4px 0 !important;
                    font-size: 11.5pt !important;
                    border-collapse: collapse !important;
                    border: 1.5px solid #000000 !important;
                    width: 100% !important;
                    table-layout: fixed !important;
                }

                /* Explicit column widths for print (sum to 100%) */
                .table-cert-print .col-sno,
                .table-cert-print .rep-col-sno {
                    width: 5% !important;
                }

                .table-cert-print .col-id,
                .table-cert-print .rep-col-id {
                    width: 5% !important;
                }

                .table-cert-print .col-name,
                .table-cert-print .rep-col-name {
                    width: 27% !important;
                    text-align: left !important;
                }

                .table-cert-print .col-final,
                .table-cert-print .rep-col-final {
                    width: 9% !important;
                }

                .table-cert-print .col-paid,
                .table-cert-print .rep-col-paid {
                    width: 7% !important;
                }

                .table-cert-print .col-unpaid,
                .table-cert-print .rep-col-unpaid {
                    width: 8% !important;
                }

                .table-cert-print .col-satcut,
                .table-cert-print .rep-col-satcut {
                    width: 8% !important;
                }

                .table-cert-print .col-remarks,
                .table-cert-print .rep-col-remarks {
                    width: 31% !important;
                    text-align: left !important;
                }

                .table-cert-print th,
                #certTable th,
                #reportTable th {
                    font-size: 11.5pt !important;
                    font-weight: bold !important;
                    background-color: #f1f5f9 !important;
                    padding: 3px 5px !important;
                    white-space: normal !important;
                    word-wrap: break-word !important;
                    overflow-wrap: break-word !important;
                    word-break: break-word !important;
                }

                .table-cert-print th,
                #certTable th,
                #reportTable th,
                .table-cert-print td,
                #certTable td,
                #reportTable td {
                    padding: 1.5px 3.5px !important;
                    border: 1.5px solid #000000 !important;
                    /* Force solid thick borders on print */
                    line-height: 1.1 !important;
                    -webkit-print-color-adjust: exact !important;
                    print-color-adjust: exact !important;
                    word-wrap: break-word !important;
                    overflow-wrap: break-word !important;
                }

                #wagesTable {
                    border: 1.5px solid #000000 !important;
                    border-collapse: collapse !important;
                }

                #wagesTable th,
                #wagesTable td {
                    border: 1px solid #000000 !important;
                    padding: 6px 8px !important;
                    -webkit-print-color-adjust: exact !important;
                    print-color-adjust: exact !important;
                }
            }
        </style>
    </asp:Content>

    <asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
        <div id="toast-container"></div>

        <h2 class="mb-0 text-dark font-weight-bold btn-print-hide" id="pageMainHeader">Document Hub</h2>
        <hr class="btn-print-hide" style="border-color:#e2e8f0; margin-bottom: 24px;" />

        <!-- Document Selection Hub -->
        <div id="documentHubView" class="btn-print-hide">
            <h5 class="text-dark font-weight-bold mb-3" style="color: #475569;"><i
                    class="fas fa-file-alt mr-2 text-primary"></i>Document Generators</h5>
            <div class="hub-grid mb-4">
                <div class="hub-card" onclick="selectDocument('attendance-cert')">
                    <div class="hub-card-icon"><i class="fas fa-file-signature"></i></div>
                    <h5 class="hub-card-title">Attendance Certificate</h5>
                    <p class="hub-card-desc">Generate monthly attendance certificates for GeM contract vendors including
                        leaves, Saturday cuts, and auto-remarks.</p>
                    <span class="hub-card-btn">Open Generator <i class="fas fa-arrow-right ml-1"></i></span>
                </div>

                <div class="hub-card" onclick="selectDocument('satisfactory-cert')">
                    <div class="hub-card-icon"><i class="fas fa-clipboard-check"></i></div>
                    <h5 class="hub-card-title">Satisfactory Certificate</h5>
                    <p class="hub-card-desc">Generate monthly contractor satisfactory performance certificates with
                        custom headers, employee counts, and signatories.</p>
                    <span class="hub-card-btn">Open Generator <i class="fas fa-arrow-right ml-1"></i></span>
                </div>

                <div class="hub-card" onclick="selectDocument('covering-letter')">
                    <div class="hub-card-icon"><i class="fas fa-envelope-open-text"></i></div>
                    <h5 class="hub-card-title">Covering Letter</h5>
                    <p class="hub-card-desc">Generate monthly contractor covering letters with dynamically compiled
                        reference numbers, subjects, body paragraphs, and recipients.</p>
                    <span class="hub-card-btn">Open Generator <i class="fas fa-arrow-right ml-1"></i></span>
                </div>

                <div class="hub-card" onclick="selectDocument('wages-calc')">
                    <div class="hub-card-icon" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;"><i
                            class="fas fa-calculator"></i></div>
                    <h5 class="hub-card-title">Wages Calculation</h5>
                    <p class="hub-card-desc">Generate contractor monthly wages bill calculation statement with daily
                        wage rate group totals, EPF capping, service charges, and GST.</p>
                    <span class="hub-card-btn">Open Generator <i class="fas fa-arrow-right ml-1"></i></span>
                </div>

                <div class="hub-card" onclick="selectDocument('attendance-report')">
                    <div class="hub-card-icon" style="background: rgba(14, 165, 233, 0.1); color: #0ea5e9;"><i
                            class="fas fa-file-invoice"></i></div>
                    <h5 class="hub-card-title">Attendance Report</h5>
                    <p class="hub-card-desc">Generate monthly attendance reports with custom 2-line header templates,
                        selectable columns, and automatic stint/remarks details.</p>
                    <span class="hub-card-btn">Open Generator <i class="fas fa-arrow-right ml-1"></i></span>
                </div>
            </div>

            <h5 class="text-dark font-weight-bold mb-3 mt-4" style="color: #475569;"><i
                    class="fas fa-cog mr-2 text-secondary"></i>Administration</h5>
            <div class="hub-grid">
                <div class="hub-card" onclick="selectDocument('template-settings')">
                    <div class="hub-card-icon" style="background: rgba(99, 102, 241, 0.1); color: #6366f1;"><i
                            class="fas fa-sliders-h"></i></div>
                    <h5 class="hub-card-title">Template Settings</h5>
                    <p class="hub-card-desc">Manage global word sentence templates, paragraph layouts, header lines, and
                        placeholders across all documents in one place.</p>
                    <span class="hub-card-btn">Open Settings <i class="fas fa-arrow-right ml-1"></i></span>
                </div>
            </div>
        </div>

        <!-- Attendance Report Workspace -->
        <div id="attendanceReportWorkspace" style="display: none;">
            <button type="button" class="btn-custom btn-print-hide mb-4" onclick="goBackToHub()"
                style="background-color: #64748b; color: white; display: inline-flex; align-items: center; gap: 8px; margin-bottom: 20px; border: none; border-radius: 6px; padding: 0 16px; height: 38px; font-weight: 700; cursor: pointer; transition: all 0.15s ease; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
                <i class="fas fa-arrow-left"></i> Back to Document Hub
            </button>

            <!-- Control panel card -->
            <div class="control-panel-card btn-print-hide">
                <h5 class="font-weight-bold text-dark mb-3"><i class="fas fa-sliders-h mr-2 text-primary"></i>Attendance
                    Report Configuration</h5>

                <div class="filter-grid">
                    <div>
                        <label class="form-label-bold">Year</label>
                        <select id="repYear" class="form-control-custom" onchange="onReportFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Month</label>
                        <select id="repMonth" class="form-control-custom" onchange="onReportFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Category</label>
                        <select id="repCategory" class="form-control-custom" onchange="onReportFilterChange()"></select>
                    </div>
                    <div id="repContractGroup" style="display: none;">
                        <label class="form-label-bold">Contract Period</label>
                        <select id="repContract" class="form-control-custom"
                            onchange="onReportContractChange()"></select>
                    </div>
                    <div id="repDatedOnGroup" style="display: none;">
                        <label class="form-label-bold">Dated On (Editable)</label>
                        <input type="text" id="repDatedOnInput" class="form-control-custom"
                            oninput="onRepTemplateSelectChange()" />
                    </div>
                </div>

                <!-- Templates and Headers Settings -->
                <div class="settings-section-title mt-4">Heading Layout Settings</div>
                <div class="filter-grid mt-2">
                    <div>
                        <label class="form-label-bold">Template Layout</label>
                        <select id="repTemplateSelect" class="form-control-custom"
                            onchange="onRepTemplateSelectChange()">
                            <option value="tpl1">Template 1: Worker Attendance Report</option>
                            <option value="tpl2">Template 2: Performance Summary Statement</option>
                        </select>
                    </div>
                    <div style="grid-column: span 2;">
                        <label class="form-label-bold">Heading Line 1 (Editable)</label>
                        <input type="text" id="repHeadingLine1" class="form-control-custom"
                            oninput="updateReportHeaderPreview()" />
                    </div>
                </div>
                <div class="filter-grid mt-2">
                    <div style="grid-column: span 3;">
                        <label class="form-label-bold">Heading Line 2 (Editable)</label>
                        <input type="text" id="repHeadingLine2" class="form-control-custom"
                            oninput="updateReportHeaderPreview()" />
                    </div>
                </div>

                <!-- Columns Checklist -->
                <div class="settings-section-title mt-4">Select Columns to Display</div>
                <div class="checkbox-group">
                    <label class="checkbox-item"><input type="checkbox" id="repColSNo" checked
                            onchange="toggleReportColumn('rep-col-sno', this.checked)" /> Sl.No</label>
                    <label class="checkbox-item"><input type="checkbox" id="repColID"
                            onchange="toggleReportColumn('rep-col-id', this.checked)" /> ID</label>
                    <label class="checkbox-item"><input type="checkbox" id="repColMasterID"
                            onchange="toggleReportColumn('rep-col-masterid', this.checked)" /> Master ID</label>
                    <label class="checkbox-item"><input type="checkbox" id="repColName" checked
                            onchange="toggleReportColumn('rep-col-name', this.checked)" /> Employee Name</label>
                    <label class="checkbox-item"><input type="checkbox" id="repColPresent" 
                            onchange="toggleReportColumn('rep-col-present', this.checked)" /> Present Days</label>
                    <label class="checkbox-item"><input type="checkbox" id="repColFinal" checked
                            onchange="toggleReportColumn('rep-col-final', this.checked)" /> Total Days</label>
                    <label class="checkbox-item"><input type="checkbox" id="repColPaid"
                            onchange="toggleReportColumn('rep-col-paid', this.checked)" /> Paid Leaves</label>
                    <label class="checkbox-item"><input type="checkbox" id="repColUnpaid"
                            onchange="toggleReportColumn('rep-col-unpaid', this.checked)" /> Unpaid Leaves</label>
                    <label class="checkbox-item"><input type="checkbox" id="repColSatCut"
                            onchange="toggleReportColumn('rep-col-satcut', this.checked)" /> Saturday Cut</label>
                    <label class="checkbox-item"><input type="checkbox" id="repColRemarks" checked
                            onchange="toggleReportColumn('rep-col-remarks', this.checked)" /> Remarks</label>
                </div>

                <!-- Auto-Remarks Checklist -->
                <div class="settings-section-title mt-2">Auto-Remarks Options</div>
                <div class="checkbox-group">
                    <label class="checkbox-item"><input type="checkbox" id="repRemJoinResign" checked
                            onchange="rebuildReportRemarksColumn()" /> Auto-include Join/Resign Dates</label>
                    <label class="checkbox-item"><input type="checkbox" id="repRemOverride"
                            onchange="rebuildReportRemarksColumn()" /> Auto-include Overrides Reason</label>
                    <label class="checkbox-item"><input type="checkbox" id="repRemPairs"
                            onchange="rebuildReportRemarksColumn()" /> Auto-include Leave Pair Remarks</label>
                    <label class="checkbox-item"><input type="checkbox" id="repRemSatEdit"
                            onchange="rebuildReportRemarksColumn()" /> Auto-include Saturday Edit Remarks</label>
                    <label class="checkbox-item"><input type="checkbox" id="repRemCellSpecific"
                            onchange="rebuildReportRemarksColumn()" /> Auto-include Cell-Specific Remarks</label>
                </div>

                <!-- Buttons -->
                <div class="btn-action-container">
                    <button type="button" class="btn-custom btn-load" onclick="loadReportData()"><i
                            class="fas fa-sync-alt"></i> Load Data</button>
                    <button type="button" class="btn-custom btn-print" onclick="window.print()"><i
                            class="fas fa-print"></i> Print</button>
                    <button type="button" class="btn-custom btn-excel" onclick="exportReportToExcel()"><i
                            class="fas fa-file-excel"></i> Export Excel</button>
                </div>
            </div>

            <!-- Preview Container -->
            <div class="preview-container" id="reportPreviewArea" style="display: none;">
                <div class="preview-sheet" id="reportPrintSheet">

                    <!-- Document Headers -->
                    <div id="repTitle1" class="sheet-editable-hdr sheet-title" contenteditable="true"
                        style="margin-bottom: 8px;">
                        ATTENDANCE REPORT
                    </div>

                    <div id="repTitle2" class="sheet-editable-hdr sheet-desc" contenteditable="true"
                        style="font-weight: bold; margin-bottom: 20px; font-size: 0.95rem;">
                        Heading Line 2 Content
                    </div>

                    <!-- Employee table grid -->
                    <table class="table-cert-print" id="reportTable">
                        <thead>
                            <tr>
                                <th class="rep-col-sno">Sl.<br />No</th>
                                <th class="rep-col-id" style="display: none;">ID</th>
                                <th class="rep-col-masterid" style="display: none;">Master ID</th>
                                <th class="rep-col-name" style="text-align: left; padding-left: 20px;">Name</th>
                                <th class="rep-col-present">Present</th>
                                <th class="rep-col-final" style="display: none;">Total<br />Days</th>
                                <th class="rep-col-paid" style="display: none;">Paid</th>
                                <th class="rep-col-unpaid" style="display: none;">Unpaid</th>
                                <th class="rep-col-satcut" style="display: none;">Sat<br />Cut</th>
                                <th class="rep-col-remarks" style="text-align: left;">Remarks</th>
                            </tr>
                        </thead>
                        <tbody>
                            <!-- Populated dynamically via JS -->
                    </table>

                </div>
            </div>
        </div>

        <!-- Attendance Certificate Generator Workspace -->
        <div id="attendanceCertWorkspace" style="display: none;">
            <button type="button" class="btn-custom btn-print-hide mb-4" onclick="goBackToHub()"
                style="background-color: #64748b; color: white; display: inline-flex; align-items: center; gap: 8px; margin-bottom: 20px; border: none; border-radius: 6px; padding: 0 16px; height: 38px; font-weight: 700; cursor: pointer; transition: all 0.15s ease; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
                <i class="fas fa-arrow-left"></i> Back to Document Hub
            </button>

            <!-- Control panel card -->
            <div class="control-panel-card btn-print-hide">
                <h5 class="font-weight-bold text-dark mb-3"><i
                        class="fas fa-sliders-h mr-2 text-primary"></i>Configuration Panel</h5>

                <div class="filter-grid">
                    <div>
                        <label class="form-label-bold">Year</label>
                        <select id="year" class="form-control-custom" onchange="onFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Month</label>
                        <select id="month" class="form-control-custom" onchange="onFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Category</label>
                        <select id="category" class="form-control-custom" onchange="onFilterChange()"></select>
                    </div>
                    <div id="contractGroup" style="display: none;">
                        <label class="form-label-bold">Contract Period</label>
                        <select id="contract" class="form-control-custom" onchange="onContractChange()"></select>
                    </div>
                </div>

                <div class="filter-grid mt-2">
                    <div>
                        <label class="form-label-bold">Vendor Name (Editable)</label>
                        <input type="text" id="vendorName" class="form-control-custom"
                            oninput="updateHeaderPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Vendor Address (Editable)</label>
                        <input type="text" id="vendorAddress" class="form-control-custom"
                            oninput="updateHeaderPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">GeM Contract No (Editable)</label>
                        <input type="text" id="gemContractNo" class="form-control-custom"
                            oninput="updateHeaderPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Contract Date (Editable)</label>
                        <input type="text" id="gemContractDate" class="form-control-custom"
                            oninput="updateHeaderPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Dated On (Editable)</label>
                        <input type="text" id="certDatedOnInput" class="form-control-custom"
                            oninput="updateHeaderPreview()" />
                    </div>
                </div>



                <!-- Columns Checklist -->
                <div class="settings-section-title mt-4">Select Columns to Display</div>
                <div class="checkbox-group">
                    <label class="checkbox-item"><input type="checkbox" id="colSNo" checked
                            onchange="toggleColumn('col-sno', this.checked)" /> Sl.No</label>
                    <label class="checkbox-item"><input type="checkbox" id="colID" checked
                            onchange="toggleColumn('col-id', this.checked)" /> ID</label>
                    <label class="checkbox-item"><input type="checkbox" id="colMasterID"
                            onchange="toggleColumn('col-masterid', this.checked)" /> Master ID</label>
                    <label class="checkbox-item"><input type="checkbox" id="colName" checked
                            onchange="toggleColumn('col-name', this.checked)" /> Employee Name</label>
                    <label class="checkbox-item"><input type="checkbox" id="colPresent"
                            onchange="toggleColumn('col-present', this.checked)" /> Present Days</label>
                    <label class="checkbox-item"><input type="checkbox" id="colFinal" checked
                            onchange="toggleColumn('col-final', this.checked)" /> Total Days</label>
                    <label class="checkbox-item"><input type="checkbox" id="colPaid" checked
                            onchange="toggleColumn('col-paid', this.checked)" /> Paid Leaves</label>
                    <label class="checkbox-item"><input type="checkbox" id="colUnpaid" checked
                            onchange="toggleColumn('col-unpaid', this.checked)" /> Unpaid Leaves</label>
                    <label class="checkbox-item"><input type="checkbox" id="colSatCut" checked
                            onchange="toggleColumn('col-satcut', this.checked)" /> Saturday Cut</label>
                    <label class="checkbox-item"><input type="checkbox" id="colRemarks" checked
                            onchange="toggleColumn('col-remarks', this.checked)" /> Remarks</label>
                </div>

                <!-- Auto-Remarks Checklist -->
                <div class="settings-section-title mt-2">Auto-Remarks Builder Options</div>
                <div class="checkbox-group">
                    <label class="checkbox-item"><input type="checkbox" id="remJoinResign" checked
                            onchange="rebuildRemarksColumn()" /> Auto-include Join/Resign Dates</label>
                    <label class="checkbox-item"><input type="checkbox" id="remOverride" checked
                            onchange="rebuildRemarksColumn()" /> Auto-include Overrides Reason</label>
                    <label class="checkbox-item"><input type="checkbox" id="remPairs" checked
                            onchange="rebuildRemarksColumn()" /> Auto-include Leave Pair Remarks</label>
                    <label class="checkbox-item"><input type="checkbox" id="remSatEdit" checked
                            onchange="rebuildRemarksColumn()" /> Auto-include Saturday Edit Remarks</label>
                    <label class="checkbox-item"><input type="checkbox" id="remCellSpecific" checked
                            onchange="rebuildRemarksColumn()" /> Auto-include Cell-Specific Remarks</label>
                </div>

                <!-- Buttons -->
                <div class="btn-action-container">
                    <button type="button" class="btn-custom btn-load" onclick="loadData()"><i
                            class="fas fa-sync-alt"></i> Load Data</button>
                    <button type="button" class="btn-custom btn-print" onclick="window.print()"><i
                            class="fas fa-print"></i> Print</button>
                    <button type="button" class="btn-custom btn-excel" onclick="exportToExcel()"><i
                            class="fas fa-file-excel"></i> Export Excel</button>
                </div>
            </div>

            <!-- Loader -->
            <div id="previewLoader">
                <i class="fas fa-spinner fa-spin fa-3x"></i>
                <div class="mt-3">Fetching attendance data and rendering certificate...</div>
            </div>

            <!-- Preview Container -->
            <div class="preview-container" id="previewArea" style="display: none;">
                <div class="preview-sheet" id="printSheet">

                    <!-- Document Headers -->
                    <div id="certTitle" class="sheet-editable-hdr sheet-title" contenteditable="true">
                        CERTIFICATE
                    </div>

                    <div id="certDesc1" class="sheet-editable-hdr sheet-desc" contenteditable="true">
                        This is certify that DEO (Skilled) under GeM Contract No: GEMC-511687761569464, dated:
                        17-Oct-2025
                    </div>

                    <div id="certDesc2" class="sheet-editable-hdr sheet-desc" contenteditable="true">
                        M/s. VISHAL MANPOWER & SECURITY CONSULTANTS, Mangalore worked as following, for the period from
                        01-May-2026 to 31-May-2026
                    </div>

                    <!-- Employee table grid -->
                    <table class="table-cert-print" id="certTable">
                        <thead>
                            <tr>
                                <th class="col-sno">Sl.<br />No</th>
                                <th class="col-id">ID</th>
                                <th class="col-masterid" style="display: none;">Master ID</th>
                                <th class="col-name" style="text-align: left; padding-left: 20px;">Name</th>
                                <th class="col-present" style="display: none;">Present</th>
                                <th class="col-final">Total<br />Days</th>
                                <th class="col-paid">Paid</th>
                                <th class="col-unpaid">Unpaid</th>
                                <th class="col-satcut">Sat<br />Cut</th>
                                <th class="col-remarks" style="text-align: left;">Remarks</th>
                            </tr>
                        </thead>
                        <tbody>
                            <!-- Populated dynamically via JS -->
                        </tbody>
                    </table>

                    <!-- Signature block -->
                    <div class="signature-section">
                        <div class="sig-block" contenteditable="true">
                            Signature of Contractor /<br />Vendor Representative
                        </div>
                        <div class="sig-block" contenteditable="true">
                            Controlling Officer /<br />Authorized Signature
                        </div>
                    </div>

                </div>
            </div>
        </div>

        <!-- Satisfactory Certificate Generator Workspace -->
        <div id="satisfactoryCertWorkspace" style="display: none;">
            <button type="button" class="btn-custom btn-print-hide mb-4" onclick="goBackToHub()"
                style="background-color: #64748b; color: white; display: inline-flex; align-items: center; gap: 8px; margin-bottom: 20px; border: none; border-radius: 6px; padding: 0 16px; height: 38px; font-weight: 700; cursor: pointer; transition: all 0.15s ease; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
                <i class="fas fa-arrow-left"></i> Back to Document Hub
            </button>

            <!-- Control panel card -->
            <div class="control-panel-card btn-print-hide">
                <h5 class="font-weight-bold text-dark mb-3"><i
                        class="fas fa-sliders-h mr-2 text-primary"></i>Satisfactory Certificate Configuration</h5>

                <div class="filter-grid">
                    <div>
                        <label class="form-label-bold">Year</label>
                        <select id="satYear" class="form-control-custom" onchange="onSatFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Month</label>
                        <select id="satMonth" class="form-control-custom" onchange="onSatFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Category</label>
                        <select id="satCategory" class="form-control-custom" onchange="onSatFilterChange()"></select>
                    </div>
                    <div id="satContractGroup" style="display: none;">
                        <label class="form-label-bold">Contract Period</label>
                        <select id="satContract" class="form-control-custom" onchange="onSatContractChange()"></select>
                    </div>
                </div>

                <div class="filter-grid mt-2">
                    <div>
                        <label class="form-label-bold">Vendor Name (Editable)</label>
                        <input type="text" id="satVendorNameInput" class="form-control-custom"
                            oninput="updateSatPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Vendor Address (Editable)</label>
                        <input type="text" id="satVendorAddressInput" class="form-control-custom"
                            oninput="updateSatPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">GeM Contract No (Editable)</label>
                        <input type="text" id="satGemNoInput" class="form-control-custom"
                            oninput="updateSatPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Contract Date (Editable)</label>
                        <input type="text" id="satContractDateInput" class="form-control-custom"
                            oninput="updateSatPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Dated On (Editable)</label>
                        <input type="text" id="satDatedOnInput" class="form-control-custom"
                            oninput="updateSatPreview()" />
                    </div>
                </div>

                <div class="filter-grid mt-2">
                    <div>
                        <label class="form-label-bold">Contract Duration/Period (e.g. Two years)</label>
                        <input type="text" id="satDurationInput" class="form-control-custom" value="Two years"
                            oninput="updateSatPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">w.e.f. Date (e.g. 24 Oct 2025)</label>
                        <input type="text" id="satWefInput" class="form-control-custom" oninput="updateSatPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Services Description</label>
                        <input type="text" id="satServicesInput" class="form-control-custom"
                            value="Human Resource Outsourcing Services" oninput="updateSatPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Employee Count</label>
                        <input type="number" id="satEmpCountInput" class="form-control-custom"
                            oninput="updateSatPreview()" />
                    </div>
                </div>


                <!-- Buttons -->
                <div class="btn-action-container">
                    <button type="button" class="btn-custom btn-load" onclick="loadSatData()"><i
                            class="fas fa-sync-alt"></i> Load Data</button>
                    <button type="button" class="btn-custom btn-print" onclick="window.print()"><i
                            class="fas fa-print"></i> Print</button>
                    <button type="button" class="btn-custom"
                        style="background: linear-gradient(135deg, #10b981, #059669); color: #fff;"
                        onclick="downloadSatAsDoc()"><i class="fas fa-file-word"></i> Download as DOC</button>
                </div>
            </div>

            <!-- Loader -->
            <div id="satPreviewLoader"
                style="display: none; text-align: center; padding: 60px; color: #4f46e5; font-weight: bold;">
                <i class="fas fa-spinner fa-spin fa-3x"></i>
                <div class="mt-3">Fetching contract details and rendering certificate...</div>
            </div>

            <!-- Preview Container -->
            <div class="preview-container" id="satPreviewArea" style="display: none;">
                <div class="preview-sheet" id="satisfactoryPrintSheet"
                    style="font-family: Arial, Helvetica, sans-serif; color: #000000; font-size: 14pt; line-height: 1.8; text-align: left; padding: 50px 70px;">
                    <!-- Header Image -->
                    <div class="sat-header-img-wrap" style="text-align: center; margin-bottom: 25pt;">
                        <img id="satPreviewHeaderImage" src="Static/images/satisfactory_header.png"
                            style="width: 100%; display: block;" />
                    </div>

                    <!-- Date -->
                    <div class="sat-date-wrap" style="text-align: right; margin-bottom: 25pt;">
                        Date: &nbsp;&nbsp;&nbsp;&nbsp;<span id="satPreviewDate" contenteditable="true">July 2026</span>
                    </div>

                    <!-- Title -->
                    <div class="sat-title-wrap"
                        style="text-align: center; margin-bottom: 25pt; font-weight: bold; font-size: 14pt; text-decoration: underline; letter-spacing: 0.05em;">
                        SATISFACTORY CERTIFICATE
                    </div>

                    <!-- Paragraph 1 -->
                    <div id="satParagraph1" class="sat-paragraph-wrap" style="margin-bottom: 25pt; text-align: justify;"
                        contenteditable="true">
                        This is to certify that M/s. <b>[Vendor Name]</b>, [Vendor Address] is engaged as an Industry
                        Partner in our Establishment to provide Services towards <b>[Services Description]</b> for a
                        period of [Period] w.e.f. [w.e.f. Date] against GeM Contract No. <b>[GeM Contract No]</b> dated
                        [Contract Date].
                    </div>

                    <!-- Paragraph 2 -->
                    <div id="satParagraph2" class="sat-paragraph-wrap" style="margin-bottom: 25pt; text-align: justify;"
                        contenteditable="true">
                        The Industry Partner provided <b>[Count]</b> Contract Employees and found working
                        satisfactorily.
                    </div>

                    <!-- Paragraph 3 (2 blank lines before signatory) -->
                    <div id="satParagraph3" class="sat-paragraph-wrap" style="margin-bottom: 50pt; text-align: justify;"
                        contenteditable="true">
                        The service provided by the Industry Partner from [Start Date] to [End Date] is found
                        satisfactory.
                    </div>

                    <!-- Signatory Block -->
                    <div class="sat-sig-wrap" style="text-align: right;">
                        <div class="sat-sig-inner" style="display: inline-block; text-align: center;">
                            <div id="satPreviewSignatory" contenteditable="true" style="font-weight: bold;">(Raajita B
                                Reddy)</div>
                            <div id="satPreviewDesignation" contenteditable="true">Scientist 'F'</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Covering Letter Generator Workspace -->
        <div id="coveringLetterWorkspace" style="display: none;">
            <button type="button" class="btn-custom btn-print-hide mb-4" onclick="goBackToHub()"
                style="background-color: #64748b; color: white; display: inline-flex; align-items: center; gap: 8px; margin-bottom: 20px; border: none; border-radius: 6px; padding: 0 16px; height: 38px; font-weight: 700; cursor: pointer; transition: all 0.15s ease; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
                <i class="fas fa-arrow-left"></i> Back to Document Hub
            </button>

            <!-- Control panel card -->
            <div class="control-panel-card btn-print-hide">
                <h5 class="font-weight-bold text-dark mb-3"><i class="fas fa-sliders-h mr-2 text-primary"></i>Covering
                    Letter Configuration</h5>

                <div class="filter-grid">
                    <div>
                        <label class="form-label-bold">Year</label>
                        <select id="covYear" class="form-control-custom" onchange="onCovFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Month</label>
                        <select id="covMonth" class="form-control-custom" onchange="onCovFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Category</label>
                        <select id="covCategory" class="form-control-custom" onchange="onCovFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Directorate</label>
                        <select id="covDivision" class="form-control-custom" onchange="onCovFilterChange()"></select>
                    </div>
                    <div id="covContractGroup" style="display: none;">
                        <label class="form-label-bold">Contract Period</label>
                        <select id="covContract" class="form-control-custom" onchange="onCovContractChange()"></select>
                    </div>
                </div>

                <div class="btn-action-container">
                    <button type="button" class="btn-custom btn-print" onclick="window.print()"><i
                            class="fas fa-print"></i> Print</button>
                    <button type="button" class="btn-custom btn-excel" onclick="downloadCovAsDoc()"
                        style="background-color: #3b82f6; color: white;"><i class="fas fa-file-word"></i> Download
                        Word</button>
                </div>
            </div>

            <!-- Preview Container -->
            <div class="preview-container" id="covPreviewArea" style="display: none;">
                <div class="preview-sheet" id="coveringLetterPrintSheet"
                    style="font-family: Arial, Helvetica, sans-serif; color: #000000; font-size: 1.15rem; line-height: 1.8; text-align: left; padding: 50px 70px;">
                    <!-- Internal Phone Line -->
                    <div class="cov-phone-wrap" style="text-align: left; margin-bottom: 12px;">
                        Phone No (Internal): <span id="covPreviewPhone" contenteditable="true">2312</span>
                    </div>

                    <!-- Ref Number & Date Block -->
                    <div class="cov-ref-date-wrap"
                        style="display: flex; justify-content: space-between; margin-bottom: 30px;">
                        <div>No: <span id="covPreviewRefNo" contenteditable="true">49805/HRD/HM/2026</span></div>
                        <div><span id="covPreviewDate" contenteditable="true">June
                                2026</span></div>
                    </div>

                    <!-- Division Name -->
                    <div class="cov-division-wrap" style="text-align: center; font-weight: bold; margin-bottom: 10px;">
                        <span id="covPreviewDivision" contenteditable="true">D-KRM</span>
                    </div>

                    <!-- Subject Title -->
                    <div class="cov-subject-wrap"
                        style="text-align: center; font-weight: bold; margin-bottom: 24px; text-transform: uppercase;">
                        <span id="covPreviewSubject" contenteditable="true">HIRING OF MANPOWER SERVICES</span>
                    </div>

                    <!-- Body Paragraph -->
                    <div id="covParagraph" class="cov-paragraph-wrap"
                        style="margin-bottom: 50px; text-align: left; text-indent: 48px; line-height: 1.6;"
                        contenteditable="true">
                        The copies of the Attendance report along with the wage calculation for skilled category
                        Contract Employees from M/s. Vishal Manpower & Security Consultants, Mangalore for the period of
                        01st May 2026 to 31st May 2026 is enclosed. This is for purpose of their payment processing
                        please.
                    </div>

                    <!-- Signatory Section -->
                    <div class="cov-sig-wrap"
                        style="margin-top: 60px; margin-bottom: 60px; text-align: right; line-height: 1.5;">
                        <div class="cov-sig-inner" style="display: inline-block; text-align: center;">
                            <div id="covPreviewSignatory" contenteditable="true" style="font-weight: bold;">Usha Nandini
                                AA</div>
                            <div id="covPreviewDesignation" contenteditable="true">TO C</div>
                            <div id="covPreviewAuthority" contenteditable="true">For GD, D-KRM</div>
                        </div>
                    </div>

                    <!-- Recipient Section -->
                    <div id="covRecipient" class="cov-recipient-wrap"
                        style="text-align: left; line-height: 1.5; font-weight: bold; margin-top: 40px;"
                        contenteditable="true">
                        To,<br />D-FMM/Purchase
                    </div>
                </div>
            </div>
        </div>

        <!-- Wages Calculation Workspace -->
        <div id="wagesCalcWorkspace" style="display: none;">
            <button type="button" class="btn-custom btn-print-hide mb-4" onclick="goBackToHub()"
                style="background-color: #64748b; color: white; display: inline-flex; align-items: center; gap: 8px; margin-bottom: 20px; border: none; border-radius: 6px; padding: 0 16px; height: 38px; font-weight: 700; cursor: pointer; transition: all 0.15s ease; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
                <i class="fas fa-arrow-left"></i> Back to Document Hub
            </button>

            <!-- Control panel card -->
            <div class="control-panel-card btn-print-hide">
                <h5 class="font-weight-bold text-dark mb-3"><i class="fas fa-sliders-h mr-2 text-primary"></i>Wages
                    Calculation Configuration</h5>

                <!-- Attendance Completeness Warning Banner -->
                <div id="wagesAttendanceWarning" class="alert alert-warning mb-3" style="display: none; border-left: 5px solid #f59e0b; background-color: #fffbeb; border-color: #fde68a; color: #92400e; padding: 14px 18px; border-radius: 8px; box-shadow: 0 2px 6px rgba(245, 158, 11, 0.08);">
                    <div style="display: flex; align-items: flex-start; gap: 12px;">
                        <i class="fas fa-exclamation-triangle" style="font-size: 1.4rem; color: #d97706; margin-top: 2px; flex-shrink: 0;"></i>
                        <div style="flex-grow: 1;">
                            <div style="font-weight: 700; font-size: 0.95rem; color: #92400e; margin-bottom: 4px;" id="wagesWarningTitle">
                                Attendance Incompleteness Warning
                            </div>
                            <div id="wagesWarningDetails" style="font-size: 0.88rem; line-height: 1.5; color: #78350f;">
                            </div>
                            <div style="margin-top: 6px; font-size: 0.8rem; color: #b45309; font-style: italic;">
                                Please review attendance in the Attendance page before finalizing wages.
                            </div>
                        </div>
                        <button type="button" onclick="document.getElementById('wagesAttendanceWarning').style.display='none'" style="background: none; border: none; color: #92400e; cursor: pointer; font-size: 1.25rem; line-height: 1; padding: 0 4px;" title="Dismiss Warning">&times;</button>
                    </div>
                </div>

                <div class="filter-grid">
                    <div>
                        <label class="form-label-bold">Year</label>
                        <select id="wagesYear" class="form-control-custom" onchange="onWagesFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Month</label>
                        <select id="wagesMonth" class="form-control-custom" onchange="onWagesFilterChange()"></select>
                    </div>
                    <div>
                        <label class="form-label-bold">Category</label>
                        <select id="wagesCategory" class="form-control-custom"
                            onchange="onWagesFilterChange()"></select>
                    </div>
                    <div id="wagesContractGroup" style="display: none;">
                        <label class="form-label-bold">Contract Period</label>
                        <select id="wagesContract" class="form-control-custom"
                            onchange="onWagesContractChange()"></select>
                    </div>
                </div>

                <!-- Parameters Grid -->
                <div class="filter-grid mt-2">
                    <div>
                        <label class="form-label-bold">Daily Wage Rate (Rs)</label>
                        <input type="number" id="wagesDailyRate" class="form-control-custom" step="any" readonly="readonly" style="background-color: #f1f5f9; cursor: not-allowed;"
                            oninput="updateWagesPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">EPF Rate (%)</label>
                        <input type="number" id="wagesEpfRate" class="form-control-custom" step="any" value="13" readonly="readonly" style="background-color: #f1f5f9; cursor: not-allowed;"
                            oninput="updateWagesPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">EPF Wage Limit (Rs)</label>
                        <input type="number" id="wagesEpfLimit" class="form-control-custom" step="any" value="15000" readonly="readonly" style="background-color: #f1f5f9; cursor: not-allowed;"
                            oninput="updateWagesPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">EPF Capped Amount (Rs)</label>
                        <input type="number" id="wagesEpfCappedAmount" class="form-control-custom" step="any"
                            value="1950" readonly="readonly" style="background-color: #f1f5f9; cursor: not-allowed;" oninput="updateWagesPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Service Charge (%)</label>
                        <input type="number" id="wagesServiceChargeRate" class="form-control-custom" step="any"
                            value="3.85" oninput="updateWagesPreview()" />
                        <div id="wagesAltScStatusNotice" style="display: none; margin-top: 6px; font-size: 0.78rem; color: #b45309; font-weight: 600; background: #fef3c7; border: 1px solid #fde68a; border-radius: 6px; padding: 4px 8px;">
                            <i class="fas fa-check-circle text-success mr-1"></i> Alternate SC: <strong>Rs. <span id="wagesAltScAppliedAmount">0.00</span></strong>
                            <span style="margin-left: 6px;">
                                <a href="javascript:void(0)" onclick="toggleWagesAltDrawer()" style="color: #b45309; text-decoration: underline; font-weight: 700;">Edit</a>
                                &nbsp;|&nbsp;
                                <a href="javascript:void(0)" onclick="revertToStandardServiceCharge()" style="color: #dc2626; text-decoration: underline; font-weight: 700;">Revert</a>
                            </span>
                        </div>
                    </div>
                    <div>
                        <label class="form-label-bold">GST (%)</label>
                        <input type="number" id="wagesGstRate" class="form-control-custom" step="any" value="18" readonly="readonly" style="background-color: #f1f5f9; cursor: not-allowed;"
                            oninput="updateWagesPreview()" />
                    </div>
                </div>

                <!-- Wages Header Placeholders (Editable) -->
                <div class="filter-grid mt-2"
                    style="border-top: 1px solid #e2e8f0; padding-top: 12px; margin-top: 12px;">
                    <div>
                        <label class="form-label-bold">Contract No (Editable)</label>
                        <input type="text" id="wagesContractNoInput" class="form-control-custom"
                            oninput="updateWagesPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Contract Date (Editable)</label>
                        <input type="text" id="wagesContractDateInput" class="form-control-custom"
                            oninput="updateWagesPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Extra Code (Editable)</label>
                        <input type="text" id="wagesExtraCodeInput" class="form-control-custom" value="(2GM0286/KRMD)"
                            oninput="updateWagesPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Dated On (Editable)</label>
                        <input type="text" id="wagesDatedOnInput" class="form-control-custom"
                            oninput="updateWagesPreview()" />
                    </div>
                </div>

                <div class="filter-grid mt-2">
                    <div>
                        <label class="form-label-bold">Category Desc (Editable)</label>
                        <input type="text" id="wagesCategoryDescInput" class="form-control-custom"
                            oninput="updateWagesPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Contract Period (Editable)</label>
                        <input type="text" id="wagesPeriodInput" class="form-control-custom"
                            oninput="updateWagesPreview()" />
                    </div>
                </div>

                <div class="filter-grid mt-2">
                    <div>
                        <label class="form-label-bold">Vendor Name (Editable)</label>
                        <input type="text" id="wagesVendorNameInput" class="form-control-custom"
                            oninput="updateWagesPreview()" />
                    </div>
                    <div>
                        <label class="form-label-bold">Vendor Address (Editable)</label>
                        <input type="text" id="wagesVendorAddressInput" class="form-control-custom"
                            oninput="updateWagesPreview()" />
                    </div>
                </div>



                <div class="btn-action-container mt-3" style="display: flex; flex-wrap: wrap; gap: 10px; align-items: center;">
                    <button type="button" class="btn-custom btn-load" onclick="loadWagesData()"><i
                            class="fas fa-sync-alt"></i> Load Data</button>
                    <button type="button" class="btn-custom btn-print" onclick="window.print()"><i
                            class="fas fa-print"></i> Print</button>
                    <button type="button" class="btn-custom btn-excel" onclick="exportWagesToExcel()"><i
                            class="fas fa-file-excel"></i> Export Excel</button>
                    <button type="button" class="btn-custom btn-print-hide" id="btnOpenWagesAltDrawer" onclick="toggleWagesAltDrawer()"
                        style="background-color: #f59e0b; color: white; display: inline-flex; align-items: center; gap: 8px; margin-left: auto;">
                        <i class="fas fa-calculator"></i> Alternate Service Charge
                        <span id="wagesAltScBadge" style="display: none; background: #10b981; color: white; font-size: 0.72rem; padding: 2px 7px; border-radius: 10px; font-weight: bold; margin-left: 4px;">
                            <i class="fas fa-check"></i> Applied
                        </span>
                    </button>
                </div>
            </div>

            <!-- Wages Loader -->
            <div id="wagesLoader"
                style="display: none; text-align: center; padding: 60px; color: #4f46e5; font-weight: bold;">
                <i class="fas fa-spinner fa-spin fa-3x"></i>
                <div class="mt-3">Fetching wages data and rendering statement...</div>
            </div>

            <!-- Preview Container -->
            <div class="preview-container" id="wagesPreviewArea" style="display: none;">
                <div class="preview-sheet" id="wagesPrintSheet"
                    style="font-family: Arial, Helvetica, sans-serif; color: #000000; font-size: 1.05rem; line-height: 1.6; text-align: left; padding: 40px 50px; background: white; border: 1px solid #e2e8f0; box-shadow: 0 4px 12px rgba(0,0,0,0.05); max-width: 800px; margin: 0 auto 30px auto;">

                    <!-- Wages Calculation Header -->
                    <div
                        style="font-size: 0.95rem; line-height: 1.5; margin-bottom: 25px; font-weight: bold; text-align: center;">
                        <div id="wagesHeaderContract" style="margin-bottom: 4px;">Contract No.
                            [Contract No] Dt. [Contract Date]</div>
                        <div id="wagesHeaderCategory" style="margin-bottom: 4px;">Manpower
                            Services - [Category Name] - [People Count] No.s</div>
                        <div id="wagesHeaderPeriod" style="margin-bottom: 4px;">Contract Period
                            [Start Date] to [End Date]</div>
                        <div id="wagesHeaderVendor" style="margin-bottom: 4px;">[Vendor Name],
                            [Vendor Address]</div>
                        <div id="wagesHeaderPayment"
                            style="margin-bottom: 4px; border-bottom: 2px solid #000000; padding-bottom: 10px; font-size: 1rem;">
                            Payment for the period [Start Date] to [End Date]</div>
                    </div>

                    <!-- Wages Main Table -->
                    <table
                        style="width: 100%; border-collapse: collapse; margin-bottom: 25px; font-size: 0.95rem; border: 1px solid #000000;"
                        id="wagesTable">
                        <thead>
                            <tr style="background-color: #f8fafc; font-weight: bold; border-bottom: 2px solid #000000;">
                                <th style="border: 1px solid #000000; padding: 8px; text-align: center; width: 8%;">Sl No.</th>
                                <th style="border: 1px solid #000000; padding: 8px; text-align: left;">Description</th>
                                <th id="wagesColCHeader"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right; width: 22%;">Payment per person/per month Rs981/-PD</th>
                                <th style="border: 1px solid #000000; padding: 8px; text-align: center; width: 12%;">No of people</th>
                                <th style="border: 1px solid #000000; padding: 8px; text-align: center; width: 15%;">No of Days/Individual</th>
                                <th style="border: 1px solid #000000; padding: 8px; text-align: right; width: 22%;">Total No. of working days</th>
                            </tr>
                        </thead>
                        <tbody id="wagesTableBody">
                            <!-- Dynamic Rows -->
                        </tbody>
                        <tfoot>
                            <!-- Row 15: Footer Row (Total No of People & Total No of Days) -->
                            <tr style="font-weight: bold; border-top: 2px solid #000000; background-color: #f8fafc;">
                                <td colspan="2" style="border: 1px solid #000000; padding: 8px;"></td>
                                <td style="border: 1px solid #000000; padding: 8px; text-align: right;">Total No of People</td>
                                <td id="wagesTotalPeople"
                                    style="border: 1px solid #000000; padding: 8px; text-align: center;">0</td>
                                <td style="border: 1px solid #000000; padding: 8px; text-align: center;">Total No of Days</td>
                                <td id="wagesTotalDays"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right;">0</td>
                            </tr>
                            <!-- Row 16: Wages total calculation (981*1195) -->
                            <tr>
                                <td colspan="2" style="border: 1px solid #000000; padding: 8px;"></td>
                                <td id="wagesFormulaDesc"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right; font-weight: bold;">Wages Total</td>
                                <td colspan="2" style="border: 1px solid #000000; padding: 8px;"></td>
                                <td id="wagesAmountWages"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right;">0.00</td>
                            </tr>
                            <!-- Row 17: EPF Capped (EPF @13%for 46 persons) -->
                            <tr>
                                <td colspan="3" style="border: 1px solid #000000; padding: 8px;"></td>
                                <td id="wagesFormulaEpfCapped" colspan="2"
                                    style="border: 1px solid #000000; padding: 8px; text-align: left;">EPF @13% for 0 persons</td>
                                <td id="wagesAmountEpfCapped"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right;">0.00</td>
                            </tr>
                            <!-- Row 18: EPF Actual (EPF @13%for 2 person) -->
                            <tr>
                                <td colspan="3" style="border: 1px solid #000000; padding: 8px;"></td>
                                <td id="wagesFormulaEpfActual" colspan="2"
                                    style="border: 1px solid #000000; padding: 8px; text-align: left;">EPF @13% for 0 persons</td>
                                <td id="wagesAmountEpfActual"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right;">0.00</td>
                            </tr>
                            <!-- Row 19: Sub Total -->
                            <tr style="font-weight: bold; background-color: #f8fafc;">
                                <td colspan="3" style="border: 1px solid #000000; padding: 8px;"></td>
                                <td colspan="2" style="border: 1px solid #000000; padding: 8px; text-align: left;">Sub Total</td>
                                <td id="wagesAmountSubTotal"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right;">0.00</td>
                            </tr>
                            <!-- Row 20: Service Charge -->
                            <tr>
                                <td colspan="3" style="border: 1px solid #000000; padding: 8px;"></td>
                                <td id="wagesFormulaServiceCharge" colspan="2"
                                    style="border: 1px solid #000000; padding: 8px; text-align: left;">Service Charge @3.85%</td>
                                <td id="wagesAmountServiceCharge"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right;">0.00</td>
                            </tr>
                            <!-- Row 21: GST -->
                            <tr>
                                <td colspan="4" style="border: 1px solid #000000; padding: 8px;"></td>
                                <td id="wagesFormulaGst"
                                    style="border: 1px solid #000000; padding: 8px; text-align: center;">GST @18%</td>
                                <td id="wagesAmountGst"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right;">0.00</td>
                            </tr>
                            <!-- Row 22: Total Cost Per Month -->
                            <tr style="font-weight: bold; background-color: #f1f5f9; font-size: 1.05rem;">
                                <td colspan="3" style="border: 1px solid #000000; padding: 8px;"></td>
                                <td colspan="2" style="border: 1px solid #000000; padding: 8px; text-align: left;">Total Cost Per Month</td>
                                <td id="wagesAmountGrandTotal"
                                    style="border: 1px solid #000000; padding: 8px; text-align: right; color: #4f46e5;">0.00</td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
        </div>

        <!-- Template Settings Workspace -->
        <div id="templateSettingsWorkspace" style="display: none;">
            <button type="button" class="btn-custom btn-print-hide mb-4" onclick="goBackToHub()"
                style="background-color: #64748b; color: white; display: inline-flex; align-items: center; gap: 8px; margin-bottom: 20px; border: none; border-radius: 6px; padding: 0 16px; height: 38px; font-weight: 700; cursor: pointer; transition: all 0.15s ease; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
                <i class="fas fa-arrow-left"></i> Back to Document Hub
            </button>
            <button type="button" class="btn-custom btn-print-hide mb-4" onclick="togglePlaceholdersDrawer()"
                style="background-color: #4f46e5; color: white; display: inline-flex; align-items: center; gap: 8px; margin-bottom: 20px; border: none; border-radius: 6px; padding: 0 16px; height: 38px; font-weight: 700; cursor: pointer; margin-left: 10px; transition: all 0.15s ease; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
                <i class="fas fa-info-circle"></i> View Placeholders Guide
            </button>

            <div class="control-panel-card btn-print-hide" style="margin-top: 10px; margin-bottom: 0; width: 100%; box-sizing: border-box;">
                <h5 class="font-weight-bold text-dark mb-4"><i class="fas fa-sliders-h mr-2 text-primary"></i>Global
                    Document Templates</h5>

                <!-- Tabs Navigation -->
                <div class="template-tabs"
                    style="display: flex; flex-wrap: wrap; gap: 8px; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px; margin-bottom: 24px;">
                    <button type="button" class="tab-btn active" onclick="switchTemplateTab(event, 'tab-attendance')"
                        style="padding: 8px 16px; font-weight: 700; border: none; background: none; color: #4f46e5; border-bottom: 2px solid #4f46e5; cursor: pointer; transition: all 0.15s ease;">Attendance
                        Certificate</button>
                    <button type="button" class="tab-btn" onclick="switchTemplateTab(event, 'tab-satisfactory')"
                        style="padding: 8px 16px; font-weight: 600; border: none; background: none; color: #64748b; cursor: pointer; transition: all 0.15s ease;">Satisfactory
                        Certificate</button>
                    <button type="button" class="tab-btn" onclick="switchTemplateTab(event, 'tab-covering')"
                        style="padding: 8px 16px; font-weight: 600; border: none; background: none; color: #64748b; cursor: pointer; transition: all 0.15s ease;">Covering
                        Letter</button>
                    <button type="button" class="tab-btn" onclick="switchTemplateTab(event, 'tab-wages')"
                        style="padding: 8px 16px; font-weight: 600; border: none; background: none; color: #64748b; cursor: pointer; transition: all 0.15s ease;">Wages
                        Calculation</button>
                    <button type="button" class="tab-btn" onclick="switchTemplateTab(event, 'tab-report')"
                        style="padding: 8px 16px; font-weight: 600; border: none; background: none; color: #64748b; cursor: pointer; transition: all 0.15s ease;">Attendance
                        Report</button>
                    <button type="button" class="tab-btn" onclick="switchTemplateTab(event, 'tab-poc-report')"
                        style="padding: 8px 16px; font-weight: 600; border: none; background: none; color: #64748b; cursor: pointer; transition: all 0.15s ease;"><i class="fas fa-file-invoice-dollar mr-1"></i>POC Monthly Report</button>
                </div>

                <!-- Tab: Attendance Certificate -->
                <div id="tab-attendance" class="tab-content">
                    <div
                        style="display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 16px; margin-bottom: 12px;">
                        <div>
                            <label class="form-label-bold">Sentence 1 Template</label>
                            <textarea id="txtTplDesc1" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;"
                                oninput="updateHeaderPreview()">This is certify that DEO ({Category}) under GeM Contract No: {ContractNo}, dated: {ContractDate}, Dated On: {DatedOn}</textarea>

                        </div>
                        <div>
                            <label class="form-label-bold">Sentence 2 Template</label>
                            <textarea id="txtTplDesc2" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;"
                                oninput="updateHeaderPreview()">M/s. {VendorName}, {VendorAddress} worked as following, for the period from {StartDate} to {EndDate}</textarea>

                        </div>
                    </div>
                    <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
                        <button type="button" class="btn-custom btn-load"
                            style="background-color: #6366f1; color: white;" onclick="saveTpl()"><i
                                class="fas fa-save"></i> Save Attendance Templates</button>
                    </div>
                </div>

                <!-- Tab: Satisfactory Certificate -->
                <div id="tab-satisfactory" class="tab-content" style="display: none;">
                    <div
                        style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin-bottom: 12px;">
                        <div>
                            <label class="form-label-bold">Paragraph 1 Template</label>
                            <textarea id="txtSatTplDesc1" class="form-control-custom"
                                style="height: 120px; min-height: 100px; resize: vertical;"
                                oninput="updateSatPreview()">This is to certify that M/s. <b>{VendorName}</b>, {VendorAddress} is engaged as an Industry Partner in our Establishment to provide Services towards <b>{Services}</b> for a period of {Duration} w.e.f. {WefDate} against GeM Contract No. <b>{ContractNo}</b> dated {ContractDate}, Dated On: {DatedOn}.</textarea>

                        </div>
                        <div>
                            <label class="form-label-bold">Paragraph 2 Template</label>
                            <textarea id="txtSatTplDesc2" class="form-control-custom"
                                style="height: 120px; min-height: 100px; resize: vertical;"
                                oninput="updateSatPreview()">The Industry Partner provided <b>{EmpCount}</b> Contract Employees and found working satisfactorily.</textarea>

                        </div>
                        <div>
                            <label class="form-label-bold">Paragraph 3 Template</label>
                            <textarea id="txtSatTplDesc3" class="form-control-custom"
                                style="height: 120px; min-height: 100px; resize: vertical;"
                                oninput="updateSatPreview()">The service provided by the Industry Partner from {StartDate} to {EndDate} is found satisfactory.</textarea>

                        </div>
                    </div>

                    <div class="filter-grid mt-3">
                        <div>
                            <label class="form-label-bold">Signatory PCNO</label>
                            <div style="display: flex; gap: 8px;">
                                <input type="text" id="satSignatoryPcnoInput" class="form-control-custom" placeholder="e.g. 1004" />
                                <button type="button" class="btn-custom" onclick="fetchSignatoryDetails()" style="margin: 0; white-space: nowrap; padding: 6px 12px; height: 38px; background: #4f46e5; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer;"><i class="fas fa-search"></i> Fetch</button>
                            </div>
                        </div>
                        <div>
                            <label class="form-label-bold">Signatory Name</label>
                            <input type="text" id="satSignatoryInput" class="form-control-custom"
                                value="(Raajita B Reddy)" oninput="updateSatPreview()" />
                        </div>
                        <div>
                            <label class="form-label-bold">Signatory Designation</label>
                            <input type="text" id="satDesignationInput" class="form-control-custom"
                                value="Scientist 'F'" oninput="updateSatPreview()" />
                        </div>
                        <div>
                            <label class="form-label-bold">Upload Header Image</label>
                            <div style="display: flex; gap: 8px;">
                                <input type="file" id="satHeaderUploadInput" class="form-control-custom"
                                    accept="image/*" onchange="handleSatHeaderUpload(this)" style="padding: 4px;" />
                                <button type="button" class="btn btn-outline-secondary" onclick="resetSatHeaderImage()"
                                    style="height: 38px; border-radius: 6px;" title="Reset Default Header"><i
                                        class="fas fa-undo"></i></button>
                            </div>
                        </div>
                    </div>



                    <!-- Layout & Formatting Settings -->
                    <hr style="border-color:#e2e8f0; margin: 16px 0;" />
                    <h6 class="font-weight-bold text-dark mb-3"><i
                            class="fas fa-text-height mr-2 text-primary"></i>Layout &amp; Formatting</h6>
                    <div class="filter-grid mb-3">
                        <div>
                            <label class="form-label-bold">Font Size (pt)</label>
                            <input type="number" id="satFontSizeInput" class="form-control-custom" value="14" min="8"
                                max="24" step="1" oninput="previewSatLayout()" />
                            <small style="color: #64748b; font-size: 0.75rem; display: block; margin-top: 4px;">Body
                                text font size in points. Applies to all text in the certificate.</small>
                        </div>
                        <div>
                            <label class="form-label-bold">Section Spacing (pt)</label>
                            <input type="number" id="satSectionSpacingInput" class="form-control-custom" value="25"
                                min="0" max="100" step="1" oninput="previewSatLayout()" />
                            <small style="color: #64748b; font-size: 0.75rem; display: block; margin-top: 4px;">Space
                                between each section (header->date, date->title, title->paragraph, between
                                paragraphs).</small>
                        </div>
                        <div>
                            <label class="form-label-bold">Space Before Signatory (pt)</label>
                            <input type="number" id="satSigSpacingInput" class="form-control-custom" value="50" min="0"
                                max="200" step="1" oninput="previewSatLayout()" />
                            <small style="color: #64748b; font-size: 0.75rem; display: block; margin-top: 4px;">Space
                                after the last paragraph before the signatory name block (2 blank lines = 50pt at 14pt
                                font).</small>
                        </div>
                    </div>

                    <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
                        <button type="button" class="btn-custom btn-load"
                            style="background-color: #6366f1; color: white;" onclick="saveSatTpl()"><i
                                class="fas fa-save"></i> Save Satisfactory Templates</button>
                    </div>

                </div>

                <!-- Tab: Covering Letter -->
                <div id="tab-covering" class="tab-content" style="display: none;">
                    <div class="filter-grid">
                        <div>
                            <label class="form-label-bold">Internal Phone No.</label>
                            <input type="text" id="covPhoneInput" class="form-control-custom"
                                oninput="updateCovPreview()" />
                        </div>
                        <div>
                            <label class="form-label-bold">Reference Number Template</label>
                            <input type="text" id="covRefNoInput" class="form-control-custom"
                                oninput="updateCovPreview()" />
                        </div>
                        <div>
                            <label class="form-label-bold">Subject Heading</label>
                            <input type="text" id="covSubjectInput" class="form-control-custom"
                                oninput="updateCovPreview()" />
                        </div>
                    </div>

                    <div class="filter-grid mt-2">
                        <div>
                            <label class="form-label-bold">Signatory PCNO</label>
                            <div style="display: flex; gap: 8px;">
                                <input type="text" id="covSignatoryPcnoInput" class="form-control-custom" placeholder="e.g. 1004" />
                                <button type="button" class="btn-custom" onclick="fetchCovSignatoryDetails()" style="margin: 0; white-space: nowrap; padding: 6px 12px; height: 38px; background: #4f46e5; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer;"><i class="fas fa-search"></i> Fetch</button>
                            </div>
                        </div>
                        <div>
                            <label class="form-label-bold">Signatory Name</label>
                            <input type="text" id="covSignatoryInput" class="form-control-custom"
                                oninput="updateCovPreview()" />
                        </div>
                        <div>
                            <label class="form-label-bold">Signatory Designation</label>
                            <input type="text" id="covDesignationInput" class="form-control-custom"
                                oninput="updateCovPreview()" />
                        </div>
                        <div>
                            <label class="form-label-bold">Signatory Authority Template</label>
                            <input type="text" id="covAuthorityInput" class="form-control-custom"
                                oninput="updateCovPreview()" />
                        </div>
                    </div>

                    <div
                        style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 12px; margin-bottom: 12px;">
                        <div>
                            <label class="form-label-bold">Recipient Block Template</label>
                            <textarea id="covRecipientInput" class="form-control-custom"
                                style="height: 100px; min-height: 80px; resize: vertical;"
                                oninput="updateCovPreview()"></textarea>
                        </div>
                        <div>
                            <label class="form-label-bold">Body Paragraph Template</label>
                            <textarea id="covBodyInput" class="form-control-custom"
                                style="height: 100px; min-height: 80px; resize: vertical;"
                                oninput="updateCovPreview()"></textarea>
                        </div>
                    </div>



                    <!-- Layout & Formatting Settings -->
                    <hr style="border-color:#e2e8f0; margin: 16px 0;" />
                    <h6 class="font-weight-bold text-dark mb-3"><i
                            class="fas fa-text-height mr-2 text-primary"></i>Layout &amp; Formatting</h6>
                    <div class="filter-grid mb-3">
                        <div>
                            <label class="form-label-bold">Font Size (pt)</label>
                            <input type="number" id="covFontSizeInput" class="form-control-custom" value="12" min="8"
                                max="24" step="1" oninput="previewCovLayout()" />
                            <small style="color: #64748b; font-size: 0.75rem; display: block; margin-top: 4px;">Body
                                text font size in points. Applies to all text in the covering letter.</small>
                        </div>
                        <div>
                            <label class="form-label-bold">Section Spacing (pt)</label>
                            <input type="number" id="covSectionSpacingInput" class="form-control-custom" value="24"
                                min="0" max="100" step="1" oninput="previewCovLayout()" />
                            <small style="color: #64748b; font-size: 0.75rem; display: block; margin-top: 4px;">Space
                                between each section (phone->ref, ref->division, division->subject, subject->body).</small>
                        </div>
                        <div>
                            <label class="form-label-bold">Space Before Signatory (pt)</label>
                            <input type="number" id="covSigSpacingInput" class="form-control-custom" value="50" min="0"
                                max="200" step="1" oninput="previewCovLayout()" />
                            <small style="color: #64748b; font-size: 0.75rem; display: block; margin-top: 4px;">Space
                                after the body paragraph before the signatory name block.</small>
                        </div>
                    </div>

                    <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
                        <button type="button" class="btn-custom btn-load" onclick="saveCovTpl()"
                            style="background-color: #6366f1; color: white;"><i class="fas fa-save"></i> Save Covering
                            Letter Templates</button>
                    </div>

                </div>

                <!-- Tab: Wages Calculation -->
                <div id="tab-wages" class="tab-content" style="display: none;">
                    <div class="settings-parameter-grid">
                        <div>
                            <label class="form-label-bold">Wages Category (from Database)</label>
                            <select id="wagesTplCategorySelect" class="form-control-custom"
                                onchange="onWagesTplCategoryChange()">
                                <option value="">Loading categories...</option>
                            </select>
                            <small style="color: #64748b; font-size: 0.75rem; display: block; margin-top: 4px;">Categories loaded directly from database tiers.</small>
                        </div>
                        <div>
                            <label class="form-label-bold">Default Category Description (Saved globally for selected category)</label>
                            <div style="display: flex; gap: 8px;">
                                <input type="text" id="wagesTplCategoryDescInput" class="form-control-custom" oninput="onWagesTplCategoryDescInput()" />
                                <button type="button" class="btn-custom" onclick="saveWagesCurrentCategoryDesc()" style="margin: 0; white-space: nowrap; padding: 6px 14px; height: 38px; background: #4f46e5; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer;" title="Save Category Description">
                                    <i class="fas fa-save mr-1"></i> Save
                                </button>
                            </div>
                        </div>

                    </div>

                    <div
                        style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin-bottom: 12px;">
                        <div>
                            <label class="form-label-bold">Line 1 Template (Contract Info)</label>
                            <textarea id="txtWagesTplContract" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;"
                                oninput="updateWagesPreview()"></textarea>

                        </div>
                        <div>
                            <label class="form-label-bold">Line 2 Template (Category & Strength)</label>
                            <textarea id="txtWagesTplCategory" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;"
                                oninput="updateWagesPreview()"></textarea>

                        </div>
                        <div>
                            <label class="form-label-bold">Line 3 Template (Contract Period)</label>
                            <textarea id="txtWagesTplPeriod" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;"
                                oninput="updateWagesPreview()"></textarea>

                        </div>
                        <div>
                            <label class="form-label-bold">Line 4 Template (Vendor)</label>
                            <textarea id="txtWagesTplVendor" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;"
                                oninput="updateWagesPreview()"></textarea>

                        </div>
                        <div>
                            <label class="form-label-bold">Line 5 Template (Payment Period)</label>
                            <textarea id="txtWagesTplPayment" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;"
                                oninput="updateWagesPreview()"></textarea>

                        </div>
                    </div>

                    <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
                        <button type="button" class="btn-custom btn-load"
                            style="background-color: #6366f1; color: white;" onclick="saveWagesTpl()"><i
                                class="fas fa-save"></i> Save Wages Templates</button>
                    </div>
                </div>

                <!-- Tab: Attendance Report -->
                <div id="tab-report" class="tab-content" style="display: none;">
                    <div
                        style="display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 16px; margin-bottom: 12px;">
                        <div>
                            <label class="form-label-bold">Heading Line 1 Template (Standard Layout)</label>
                            <textarea id="txtRepTpl1Heading1" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;">ATTENDANCE REPORT OF CONTRACTOR WORKERS FOR THE MONTH OF {Month} {Year}</textarea>

                        </div>
                        <div>
                            <label class="form-label-bold">Heading Line 2 Template (Standard Layout)</label>
                            <textarea id="txtRepTpl1Heading2" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;">Name of Vendor: M/s. {VendorName} | GeM Contract No: {ContractNo}</textarea>

                        </div>
                    </div>
                    <div
                        style="display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 16px; margin-bottom: 12px; margin-top: 12px;">
                        <div>
                            <label class="form-label-bold">Heading Line 1 Template (Summary Layout)</label>
                            <textarea id="txtRepTpl2Heading1" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;">MONTHLY STATEMENT OF CONTRACTOR WORKERS ATTENDANCE</textarea>

                        </div>
                        <div>
                            <label class="form-label-bold">Heading Line 2 Template (Summary Layout)</label>
                            <textarea id="txtRepTpl2Heading2" class="form-control-custom"
                                style="height: 60px; min-height: 60px; resize: vertical;">Category: {Category} | Contract Period: {ContractPeriod} | GeM Contract: {ContractNo}</textarea>

                        </div>
                    </div>
                    <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
                        <button type="button" class="btn-custom btn-load"
                            style="background-color: #6366f1; color: white;" onclick="saveReportTpl()"><i
                                class="fas fa-save"></i> Save Report Templates</button>
                    </div>
                </div>

                <!-- Tab: POC Monthly Report -->
                <div id="tab-poc-report" class="tab-content" style="display: none;">
                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 18px; margin-bottom: 20px;">
                        <h6 class="font-weight-bold text-dark mb-3"><i class="fas fa-heading mr-2 text-primary"></i>Top Header Lines (Lines 1 &amp; 2)</h6>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 16px; margin-bottom: 14px;">
                            <div>
                                <label class="form-label-bold">Line 1 Template (Vendor Name)</label>
                                <textarea id="txtPocRepTopLine1" class="form-control-custom" style="height: 60px; min-height: 60px; resize: vertical;" placeholder="M/s {VendorName}">M/s {VendorName}</textarea>
                            </div>
                            <div>
                                <label class="form-label-bold">Line 2 Template (Recommendation Header)</label>
                                <textarea id="txtPocRepTopLine2" class="form-control-custom" style="height: 60px; min-height: 60px; resize: vertical;" placeholder="MONTHLY REPORT AND RECOMMENDATION ON HIRING OF MANPOWER SERVICES FOR MAKING PAYMENT FOR THE MONTH OF {Month:upper} - {Year}">MONTHLY REPORT AND RECOMMENDATION ON HIRING OF MANPOWER SERVICES FOR MAKING PAYMENT FOR THE MONTH OF {Month:upper} - {Year}</textarea>
                            </div>
                        </div>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px;">
                            <div>
                                <label class="form-label-bold">Top Lines Font Size (pt)</label>
                                <input type="number" id="pocRepTopFontSizeInput" class="form-control-custom" value="11" min="8" max="24" step="1" />
                            </div>
                            <div>
                                <label class="form-label-bold">Top Lines Alignment</label>
                                <select id="pocRepTopAlignInput" class="form-control-custom">
                                    <option value="center" selected="selected">Center</option>
                                    <option value="left">Left</option>
                                    <option value="right">Right</option>
                                </select>
                            </div>
                        </div>
                    </div>

                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 18px; margin-bottom: 20px;">
                        <h6 class="font-weight-bold text-dark mb-2"><i class="fas fa-user-tag mr-2 text-primary"></i>Manpower Column Settings (Category Description)</h6>
                        <div style="font-size: 0.8rem; color: #64748b; margin-bottom: 14px;">
                            Select any category present in the database to configure the exact role/designation to display in the <strong>Manpower</strong> column of the report (e.g. <code>DEO</code> for Skilled, <code>Office Assistant</code> for Semi-Skilled).
                        </div>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 16px; margin-bottom: 8px;">
                            <div>
                                <label class="form-label-bold">Select Category (from Database)</label>
                                <select id="pocRepCategorySelect" class="form-control-custom" onchange="onPocRepCategoryChange()">
                                    <option value="">Loading categories...</option>
                                </select>
                                <small style="color: #64748b; font-size: 0.75rem; display: block; margin-top: 4px;">Categories loaded directly from database tiers.</small>
                            </div>
                            <div>
                                <label class="form-label-bold">Manpower Description for Selected Category</label>
                                <div style="display: flex; gap: 8px;">
                                    <input type="text" id="pocRepCategoryDescInput" class="form-control-custom" placeholder="e.g. DEO, Office Assistant" oninput="onPocRepCategoryDescInput()" />
                                    <button type="button" class="btn-custom" onclick="savePocRepCurrentCategoryDesc()" style="margin: 0; white-space: nowrap; padding: 6px 14px; height: 38px; background: #4f46e5; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer;" title="Save Category Description">
                                        <i class="fas fa-save mr-1"></i> Save
                                    </button>
                                </div>
                                <small style="color: #64748b; font-size: 0.75rem; display: block; margin-top: 4px;">Template key: <code>PocRepManpower_&lt;Category&gt;</code></small>
                            </div>
                        </div>
                    </div>

                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 18px; margin-bottom: 16px;">
                        <h6 class="font-weight-bold text-dark mb-3"><i class="fas fa-file-signature mr-2 text-primary"></i>Bottom Certification &amp; Signatures</h6>
                        <div style="display: grid; grid-template-columns: 1fr; gap: 16px; margin-bottom: 14px;">
                            <div>
                                <label class="form-label-bold">Certification Statement (Paragraph below table)</label>
                                <textarea id="txtPocRepCertParagraph" class="form-control-custom" style="height: 80px; min-height: 60px; resize: vertical;">It is certified that the above mentioned individuals have worked during office hours on the number of days as mentioned against their names and the individuals have received their previous month salary &amp; EPF contribution from the service provider.</textarea>
                            </div>
                            <div>
                                <label class="form-label-bold">Signatures &amp; Recipient Template</label>
                                <textarea id="txtPocRepSignatures" class="form-control-custom" style="height: 90px; min-height: 60px; resize: vertical;">(Point of Contact)
Signature of Group Director
To
    {Directorate}</textarea>
                            </div>
                        </div>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px;">
                            <div>
                                <label class="form-label-bold">Bottom Section Font Size (pt)</label>
                                <input type="number" id="pocRepBottomFontSizeInput" class="form-control-custom" value="11" min="8" max="24" step="1" />
                            </div>
                            <div>
                                <label class="form-label-bold">Bottom Section Alignment</label>
                                <select id="pocRepBottomAlignInput" class="form-control-custom">
                                    <option value="left" selected="selected">Left</option>
                                    <option value="center">Center</option>
                                    <option value="right">Right</option>
                                </select>
                            </div>
                        </div>
                    </div>

                    <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
                        <button type="button" class="btn-custom btn-load" style="background-color: #6366f1; color: white;" onclick="savePocReportTpl()">
                            <i class="fas fa-save"></i> Save POC Monthly Report Templates
                        </button>
                    </div>
                </div>

                </div>
            </div>
        </div>

        <!-- Alternate Service Charge Drawer Overlay -->
        <div id="wagesAltDrawerOverlay" class="drawer-overlay" onclick="closeWagesAltDrawer()"></div>

        <!-- Right: Wages Alternate Service Charge Drawer -->
        <div id="wagesAltServiceChargeDrawer" class="wages-sidebar-drawer btn-print-hide">
            <div class="drawer-header" style="background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%); border-bottom: 2px solid #e2e8f0; padding: 16px 20px;">
                <div style="display: flex; align-items: center; gap: 10px;">
                    <div style="width: 38px; height: 38px; border-radius: 8px; background: rgba(245, 158, 11, 0.15); color: #d97706; display: flex; align-items: center; justify-content: center; font-size: 1.15rem;">
                        <i class="fas fa-calculator"></i>
                    </div>
                    <div>
                        <h6 class="font-weight-bold text-dark mb-0" style="font-size: 0.96rem;">Alternate Service Charge</h6>
                        <div style="font-size: 0.74rem; color: #64748b;">Calculate from tender/base daily rate</div>
                    </div>
                </div>
                <button type="button" class="drawer-close-btn" onclick="closeWagesAltDrawer()">&times;</button>
            </div>

            <div class="drawer-content" style="padding: 18px 20px; overflow-y: auto;">
                <!-- Info Alert -->
                <div style="background-color: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 12px; margin-bottom: 16px; font-size: 0.79rem; color: #1e40af; line-height: 1.5;">
                    <i class="fas fa-info-circle mr-1"></i>
                    Enter the base/tender amount for each day. The subtotal and service charge will be calculated for the selected category employees based on their working days.
                </div>

                <!-- Applied Status Banner -->
                <div id="wagesAltAppliedBanner" style="display: none; background: #ecfdf5; border: 1.5px solid #6ee7b7; border-radius: 8px; padding: 10px 14px; margin-bottom: 16px; font-size: 0.82rem; color: #065f46; line-height: 1.5;">
                    <div style="font-weight: 700; display: flex; align-items: center; gap: 6px;">
                        <i class="fas fa-check-circle" style="color: #10b981;"></i>
                        <span>Alternate Service Charge is currently APPLIED to this bill</span>
                    </div>
                    <div id="wagesAltAppliedMetaText" style="font-size: 0.74rem; color: #047857; margin-top: 3px;">
                        Saved in database for this period and category.
                    </div>
                </div>

                <!-- Main Input: Amount for each day -->
                <div style="background: #ffffff; border: 1.5px solid #cbd5e1; border-radius: 10px; padding: 14px 16px; margin-bottom: 16px; box-shadow: 0 2px 6px rgba(0,0,0,0.03);">
                    <label class="form-label-bold" style="color: #0f172a; font-size: 0.88rem; margin-bottom: 3px;">
                        <i class="fas fa-coins text-warning mr-1"></i> Amount for Each Day (Rs. / day) <span class="text-danger">*</span>
                    </label>
                    <div style="font-size: 0.74rem; color: #64748b; margin-bottom: 8px;">
                        Tender/base daily rate used to compute subtotal &amp; service charge
                    </div>
                    <div style="position: relative;">
                        <span style="position: absolute; left: 12px; top: 50%; transform: translateY(-50%); font-weight: bold; color: #64748b; font-size: 0.95rem;">Rs.</span>
                        <input type="number" id="wagesAltDailyRate" class="form-control-custom" step="any" placeholder="e.g., 800"
                            style="padding-left: 42px; font-size: 1.05rem; font-weight: 700; color: #0f172a; border-color: #3b82f6;"
                            oninput="calculateAltServiceCharge()" />
                    </div>
                </div>

                <!-- Configurable Parameters Section (editable service charge, epf, epf cap) -->
                <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px; margin-bottom: 16px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                        <div style="font-weight: 700; font-size: 0.8rem; color: #334155; text-transform: uppercase; letter-spacing: 0.04em;">
                            <i class="fas fa-sliders-h text-primary mr-1"></i> Configurable Rates &amp; EPF
                        </div>
                        <button type="button" class="btn btn-sm btn-link p-0" onclick="resetAltDrawerToMainDefaults()" style="font-size: 0.74rem; color: #4f46e5; text-decoration: none; font-weight: 600;">
                            <i class="fas fa-undo mr-1"></i> Reset to Defaults
                        </button>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 10px;">
                        <div>
                            <label class="form-label-bold" style="font-size: 0.76rem;">Service Charge (%)</label>
                            <input type="number" id="wagesAltScRate" class="form-control-custom" step="any" value="3.85"
                                oninput="this.dataset.userEdited='true'; calculateAltServiceCharge()" />
                        </div>
                        <div>
                            <label class="form-label-bold" style="font-size: 0.76rem;">EPF Rate (%)</label>
                            <input type="number" id="wagesAltEpfRate" class="form-control-custom" step="any" value="13"
                                oninput="this.dataset.userEdited='true'; onAltEpfParamsChange()" />
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                        <div>
                            <label class="form-label-bold" style="font-size: 0.76rem;">EPF Wage Limit (Rs)</label>
                            <input type="number" id="wagesAltEpfLimit" class="form-control-custom" step="any" value="15000"
                                oninput="this.dataset.userEdited='true'; onAltEpfParamsChange()" />
                        </div>
                        <div>
                            <label class="form-label-bold" style="font-size: 0.76rem;">EPF Capped Amount (Rs)</label>
                            <input type="number" id="wagesAltEpfCappedAmount" class="form-control-custom" step="any" value="1950"
                                oninput="this.dataset.manualOverride='true'; calculateAltServiceCharge()" />
                        </div>
                    </div>
                </div>

                <!-- Live Breakdown Results Card -->
                <div id="wagesAltBreakdownCard" style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px 16px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.03);">
                    <div style="font-weight: 700; font-size: 0.8rem; color: #334155; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 0.04em;">
                        <i class="fas fa-chart-pie text-info mr-1"></i> Calculation Breakdown
                    </div>

                    <div id="wagesAltNoDataNotice" style="display: block; text-align: center; color: #94a3b8; font-size: 0.82rem; padding: 16px 0;">
                        <i class="fas fa-coins fa-2x mb-2 d-block" style="color: #cbd5e1;"></i>
                        Enter an alternate daily rate to calculate service charge.
                    </div>

                    <div id="wagesAltDataContainer" style="display: none;">
                        <div style="font-size: 0.8rem; line-height: 1.75;">
                            <div style="display: flex; justify-content: space-between; border-bottom: 1px dashed #e2e8f0; padding-bottom: 3px; margin-bottom: 3px;">
                                <span style="color: #64748b;">Selected Category:</span>
                                <span id="wagesAltCatName" style="font-weight: 600; color: #0f172a;">-</span>
                            </div>
                            <div style="display: flex; justify-content: space-between; border-bottom: 1px dashed #e2e8f0; padding-bottom: 3px; margin-bottom: 3px;">
                                <span style="color: #64748b;">People / Working Days:</span>
                                <span style="font-weight: 600; color: #0f172a;"><span id="wagesAltPeopleCount">0</span> persons / <span id="wagesAltTotalDays">0</span> days</span>
                            </div>
                            <div style="display: flex; justify-content: space-between; border-bottom: 1px dashed #e2e8f0; padding-bottom: 3px; margin-bottom: 3px;">
                                <span style="color: #64748b;">Alternate Wages (<span id="wagesAltWagesFormula">0*0</span>):</span>
                                <span id="wagesAltWagesTotal" style="font-weight: 600; color: #0f172a;">Rs. 0.00</span>
                            </div>
                            <div style="display: flex; justify-content: space-between; border-bottom: 1px dashed #e2e8f0; padding-bottom: 3px; margin-bottom: 3px;">
                                <span style="color: #64748b;" id="wagesAltEpfCappedLabel">EPF Capped:</span>
                                <span id="wagesAltEpfCappedTotal" style="font-weight: 600; color: #0f172a;">Rs. 0.00</span>
                            </div>
                            <div style="display: flex; justify-content: space-between; border-bottom: 1px dashed #e2e8f0; padding-bottom: 3px; margin-bottom: 3px;">
                                <span style="color: #64748b;" id="wagesAltEpfActualLabel">EPF Actual:</span>
                                <span id="wagesAltEpfActualTotal" style="font-weight: 600; color: #0f172a;">Rs. 0.00</span>
                            </div>
                            <div style="display: flex; justify-content: space-between; background: #f8fafc; padding: 7px 10px; border-radius: 6px; margin: 8px 0; font-weight: 700;">
                                <span style="color: #334155;">Alternate Sub Total:</span>
                                <span id="wagesAltSubTotal" style="color: #0f172a; font-size: 0.92rem;">Rs. 0.00</span>
                            </div>
                        </div>

                        <!-- Generated Service Charge Highlight Box -->
                        <div style="background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%); border: 1.5px solid #6ee7b7; border-radius: 8px; padding: 12px 14px; margin-top: 10px; text-align: center;">
                            <div style="font-size: 0.76rem; font-weight: 700; color: #047857; text-transform: uppercase; letter-spacing: 0.04em; margin-bottom: 2px;">
                                <i class="fas fa-check-circle mr-1"></i> Generated Alternate Service Charge
                            </div>
                            <div id="wagesAltGeneratedScAmount" style="font-size: 1.45rem; font-weight: 800; color: #065f46;">
                                Rs. 0.00
                            </div>
                            <div id="wagesAltScRateFormula" style="font-size: 0.74rem; color: #047857; margin-top: 2px;">
                                @ 3.85% of Alternate Sub Total
                            </div>
                        </div>

                        <!-- Group Days Breakdown Collapsible -->
                        <div style="margin-top: 12px;">
                            <a href="javascript:void(0)" onclick="toggleAltGroupTable()" style="font-size: 0.76rem; font-weight: 600; color: #4f46e5; text-decoration: none; display: inline-flex; align-items: center; gap: 4px;">
                                <span id="altGroupToggleIcon"><i class="fas fa-chevron-down"></i></span> View Group Details Table
                            </a>
                            <div id="altGroupTableContainer" style="display: none; margin-top: 8px; max-height: 180px; overflow-y: auto; border: 1px solid #e2e8f0; border-radius: 6px;">
                                <table style="width: 100%; font-size: 0.74rem; border-collapse: collapse;">
                                    <thead style="background: #f1f5f9; font-weight: 700; position: sticky; top: 0;">
                                        <tr>
                                            <th style="padding: 5px; text-align: center; border-bottom: 1px solid #cbd5e1;">Days</th>
                                            <th style="padding: 5px; text-align: center; border-bottom: 1px solid #cbd5e1;">People</th>
                                            <th style="padding: 5px; text-align: right; border-bottom: 1px solid #cbd5e1;">Total Days</th>
                                            <th style="padding: 5px; text-align: right; border-bottom: 1px solid #cbd5e1;">Pay/Person</th>
                                            <th style="padding: 5px; text-align: center; border-bottom: 1px solid #cbd5e1;">EPF Type</th>
                                        </tr>
                                    </thead>
                                    <tbody id="altGroupTableBody"></tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Configuration & Actions -->
                <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px 16px; margin-bottom: 16px;">
                    <label style="display: flex; align-items: center; gap: 10px; cursor: pointer; margin-bottom: 12px; font-weight: 700; color: #1e293b; font-size: 0.85rem;">
                        <input type="checkbox" id="chkUseAltServiceCharge" style="width: 18px; height: 18px; cursor: pointer; accent-color: #10b981;"
                            onchange="onToggleAltServiceCharge(this.checked)" />
                        <span>Use Alternate Service Charge in Main Bill</span>
                    </label>

                    <div style="display: flex; flex-direction: column; gap: 8px;">
                        <button type="button" class="btn-custom" onclick="applyAltServiceChargeToMain()"
                            style="background-color: #10b981; color: white; justify-content: center; width: 100%; font-size: 0.86rem; height: 38px;">
                            <i class="fas fa-check mr-1"></i> Apply to Main Bill &amp; Close
                        </button>
                        <button type="button" class="btn-custom" onclick="revertToStandardServiceCharge()"
                            style="background-color: #64748b; color: white; justify-content: center; width: 100%; font-size: 0.83rem; height: 34px;">
                            <i class="fas fa-undo mr-1"></i> Revert to Standard Calculation
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Backdrop Overlay -->
        <div id="drawerOverlay" class="drawer-overlay" onclick="closePlaceholdersDrawer()"></div>

        <!-- Right: Global Placeholders Guide Drawer -->
        <div id="placeholdersDrawer" class="placeholders-drawer btn-print-hide">
            <div class="drawer-header">
                <h6 class="font-weight-bold text-dark mb-0" style="display: inline-flex; align-items: center; gap: 8px;">
                    <i class="fas fa-info-circle text-primary"></i> Global Placeholders Guide
                </h6>
                <button type="button" class="drawer-close-btn" onclick="closePlaceholdersDrawer()">&times;</button>
            </div>
            <div class="drawer-content">
                <p style="color: #64748b; font-size: 0.8rem; line-height: 1.5; margin-bottom: 16px;">
                    You can use <strong>any</strong> placeholder in <strong>any</strong> document template. They are replaced dynamically based on the selected contract period and month.
                </p>
                <div style="padding-right: 4px;">
                    <!-- Dynamic Math & Offset Placeholders (+ / -) -->
                    <div style="background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%); border: 1px solid #86efac; border-radius: 8px; padding: 12px 14px; margin-bottom: 14px;">
                        <div style="font-size: 0.8rem; font-weight: 800; color: #166534; display: flex; align-items: center; gap: 6px; margin-bottom: 6px;">
                            <i class="fas fa-calculator"></i> Dynamic Math &amp; Offset Placeholders (+ / -)
                        </div>
                        <div style="font-size: 0.74rem; color: #15803d; line-height: 1.5;">
                            Add <code>+N</code> or <code>-N</code> directly to placeholders across all documents:<br />
                            &bull; <code>{Date}</code> &rarr; Today's date (e.g. <code>07-Sep-2026</code>) | <code>{Date-1}</code> &rarr; Yesterday (<code>06-Sep-2026</code>)<br />
                            &bull; <code>{Month-1}</code> &rarr; Previous month (e.g. <code>April</code> when May is selected)<br />
                            &bull; <code>{MONTH-1}</code> or <code>{Month-1:upper}</code> &rarr; <code>APRIL</code><br />
                            &bull; <code>{Month-1:short}</code> &rarr; <code>Apr</code><br />
                            &bull; <code>{Year-1}</code> &rarr; Previous year (e.g. <code>2025</code> when 2026 is selected)<br />
                            &bull; <code>{EmpCount-1}</code> &rarr; Active count minus 1 (e.g. <code>13</code> when 14)<br />
                            &bull; <code>{StartDate-1}</code> / <code>{EndDate-1}</code> &rarr; Previous month's start &amp; end dates<br />
                            &bull; <code>{WorkingDays-1}</code> &rarr; Working days minus 1
                        </div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{Category}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Category Name (lowercase)</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>skilled</code>, <code>semi-skilled</code></div>
                    </div>
                    
                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{CategoryDesc}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Category Description</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>Data Entry Operators (Skilled)</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{VendorName}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Vendor Name</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>Vishal Manpower Services</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{VendorAddress}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Vendor Office Address</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{ContractNo}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">GeM Contract Number</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{ContractDate}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Contract Date / Start Date</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{DatedOn}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Contract "Dated On" Date</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{StartDate}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Start Date of Month (Default)</div>
                        <div style="font-size: 0.72rem; color: #64748b;">Formats adapt to document type automatically.</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{EndDate}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">End Date of Month (Default)</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.334155; color: #334155; font-weight: 700; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">{StartDateShort}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Short Start Date (Fixed)</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>01-May-2026</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.334155; color: #334155; font-weight: 700; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">{EndDateShort}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Short End Date (Fixed)</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>31-May-2026</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.334155; color: #334155; font-weight: 700; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">{StartDateSpace}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Space Start Date (Fixed)</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>01 May 2026</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.334155; color: #334155; font-weight: 700; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">{EndDateSpace}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Space End Date (Fixed)</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>31 May 2026</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.334155; color: #334155; font-weight: 700; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">{StartDateLong}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Long Start Date (Fixed)</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>01st May 2026</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #334155; font-weight: 700; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">{EndDateLong}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Long End Date (Fixed)</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>31st May 2026</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{Date}</code> / <code style="font-size: 0.85rem; color: #059669; font-weight: 700; background: #d1fae5; padding: 2px 6px; border-radius: 4px;">{DATE}</code> / <code style="font-size: 0.85rem; color: #16a34a; font-weight: 700; background: #dcfce7; padding: 2px 6px; border-radius: 4px;">{Date-1}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Today's Date &amp; Day Offsets</div>
                        <div style="font-size: 0.72rem; color: #64748b;">
                            <code>{Date}</code> &rarr; e.g. <code>07-Sep-2026</code> &nbsp;|&nbsp; <code>{Date-1}</code> &rarr; <code>06-Sep-2026</code> &nbsp;|&nbsp; <code>{Day}</code> &rarr; <code>07</code>
                        </div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{Month}</code> / <code style="font-size: 0.85rem; color: #059669; font-weight: 700; background: #d1fae5; padding: 2px 6px; border-radius: 4px;">{MONTH}</code> / <code style="font-size: 0.85rem; color: #16a34a; font-weight: 700; background: #dcfce7; padding: 2px 6px; border-radius: 4px;">{Month-1}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Selected Month Name &amp; Offsets</div>
                        <div style="font-size: 0.72rem; color: #64748b;">
                            <code>{Month}</code> &rarr; <code>May</code> &nbsp;|&nbsp; <code>{Month-1}</code> &rarr; <code>April</code> &nbsp;|&nbsp; <code>{MONTH-1}</code> &rarr; <code>APRIL</code>
                        </div>
                    </div>

                    <!-- Global Case Modifiers Callout -->
                    <div style="background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%); border: 1px solid #bfdbfe; border-radius: 8px; padding: 10px 12px; margin-bottom: 12px;">
                        <div style="font-size: 0.78rem; font-weight: 800; color: #1e40af; display: flex; align-items: center; gap: 5px; margin-bottom: 4px;">
                            <i class="fas fa-font"></i> Global Capitalization Modifiers
                        </div>
                        <div style="font-size: 0.72rem; color: #1d4ed8; line-height: 1.45;">
                            Add <code>:upper</code> (or write any placeholder in ALL CAPS) to capitalize any value:<br />
                            &bull; <code>{Category:upper}</code> or <code>{CATEGORY}</code> &rarr; <code>SKILLED</code><br />
                            &bull; <code>{VendorName:upper}</code> or <code>{VENDORNAME}</code> &rarr; <code>VISHAL MANPOWER...</code><br />
                            &bull; <code>{Month:short:upper}</code> &rarr; <code>MAY</code> / <code>AUG</code>
                        </div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{Year}</code> / <code style="font-size: 0.85rem; color: #16a34a; font-weight: 700; background: #dcfce7; padding: 2px 6px; border-radius: 4px;">{Year-1}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Selected Year &amp; Offsets</div>
                        <div style="font-size: 0.72rem; color: #64748b;"><code>{Year}</code> &rarr; <code>2026</code> &nbsp;|&nbsp; <code>{Year-1}</code> &rarr; <code>2025</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{Division}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Directorate Name</div>
                        <div style="font-size: 0.72rem; color: #64748b;">e.g., <code>AD-Admin</code></div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{Services}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Services Description</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{Duration}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Contract Period / Duration</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{WefDate}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">With Effect From (w.e.f.) Date</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{EmpCount}</code> / <code style="font-size: 0.85rem; color: #16a34a; font-weight: 700; background: #dcfce7; padding: 2px 6px; border-radius: 4px;">{EmpCount-1}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Employees strength (Count) &amp; Offsets</div>
                        <div style="font-size: 0.72rem; color: #64748b;">(Also matches <code>{PeopleCount}</code> | <code>{EmpCount-1}</code> subtracts 1)</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{Period}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Contract Period Range</div>
                    </div>

                    <div class="placeholder-guide-item" style="border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; margin-bottom: 10px;">
                        <code style="font-size: 0.85rem; color: #4f46e5; font-weight: 700; background: #e0e7ff; padding: 2px 6px; border-radius: 4px;">{WorkingDays}</code>
                        <div style="font-size: 0.78rem; color: #334155; font-weight: 600; margin-top: 4px;">Working Days (Excl. Sundays)</div>
                    </div>

                </div>
            </div>
        </div>

        <script src="Static/js/documents.js?v=<%= DateTime.Now.Ticks %>"></script>
    </asp:Content>
