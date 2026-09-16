<%@ Page Title="Reports Hub" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Reports.aspx.cs" Inherits="AttendanceApp.Reports" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Reports Hub
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .reports-header-wrap {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 24px;
            flex-wrap: wrap;
            gap: 16px;
        }

        .reports-title-box {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .reports-icon-circle {
            width: 48px;
            height: 48px;
            border-radius: 14px;
            background: linear-gradient(135deg, #f59e0b, #d97706);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.35rem;
            box-shadow: 0 4px 14px rgba(217, 119, 6, 0.35);
        }

        .reports-page-title {
            font-size: 1.6rem;
            font-weight: 800;
            color: #0f172a;
            margin: 0;
            letter-spacing: -0.02em;
        }

        .reports-page-sub {
            font-size: 0.85rem;
            color: #64748b;
            margin: 2px 0 0 0;
            font-weight: 500;
        }

        .btn-back-dash {
            background: #ffffff;
            color: #475569;
            border: 1px solid #cbd5e1;
            padding: 8px 18px;
            border-radius: 10px;
            font-size: 0.88rem;
            font-weight: 700;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.2s ease;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }

        .btn-back-dash:hover {
            background: #f1f5f9;
            color: #0f172a;
            text-decoration: none;
            transform: translateX(-2px);
        }

        /* Reports Grid */
        .reports-hub-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 380px));
            gap: 24px;
            margin-top: 10px;
        }

        .report-hub-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 20px;
            padding: 28px 24px 22px 24px;
            text-decoration: none !important;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            min-height: 270px;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            position: relative;
            overflow: hidden;
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.03);
        }

        .report-hub-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 18px 36px rgba(0, 0, 0, 0.09);
            border-color: #cbd5e1;
        }

        .report-card-icon-wrap {
            width: 54px;
            height: 54px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.4rem;
            margin-bottom: 16px;
        }

        .icon-wrap-amber {
            background: rgba(245, 158, 11, 0.12);
            color: #d97706;
            border: 1px solid rgba(245, 158, 11, 0.25);
        }

        .report-card-title {
            font-size: 1.22rem;
            font-weight: 800;
            color: #0f172a;
            margin: 0 0 6px 0;
            line-height: 1.3;
        }

        .report-card-subtitle {
            font-size: 0.8rem;
            font-weight: 700;
            color: #d97706;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-bottom: 10px;
        }

        .report-card-desc {
            font-size: 0.86rem;
            color: #475569;
            line-height: 1.55;
            margin-bottom: 20px;
            font-weight: 500;
        }

        .report-card-footer-action {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding-top: 14px;
            border-top: 1px solid #f1f5f9;
            color: #4f46e5;
            font-weight: 700;
            font-size: 0.88rem;
        }

        .report-card-footer-action i {
            transition: transform 0.2s ease;
        }

        .report-hub-card:hover .report-card-footer-action i {
            transform: translateX(4px);
        }

        /* ── Dark Theme Overrides for Reports Hub ── */
        html.theme-dark .reports-page-title {
            color: #f1f5f9;
        }

        html.theme-dark .reports-page-sub {
            color: #94a3b8;
        }

        html.theme-dark .btn-back-dash {
            background: #1e2233;
            color: #cbd5e1;
            border-color: #3d4460;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
        }

        html.theme-dark .btn-back-dash:hover {
            background: #252a3a;
            color: #818cf8;
            border-color: #6366f1;
            transform: translateX(-2px);
        }

        html.theme-dark .report-hub-card {
            background: #1a1d27;
            border-color: #2d3348;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.35);
        }

        html.theme-dark .report-hub-card:hover {
            background: #1e2233;
            border-color: #6366f1;
            box-shadow: 0 16px 32px rgba(0, 0, 0, 0.5), 0 0 24px rgba(99, 102, 241, 0.2);
            transform: translateY(-5px);
        }

        html.theme-dark .icon-wrap-amber {
            background: rgba(245, 158, 11, 0.16);
            color: #fbbf24;
            border-color: rgba(245, 158, 11, 0.35);
        }

        html.theme-dark .report-card-title {
            color: #f1f5f9;
        }

        html.theme-dark .report-card-subtitle {
            color: #f59e0b;
        }

        html.theme-dark .report-card-desc {
            color: #94a3b8;
        }

        html.theme-dark .report-card-footer-action {
            border-top-color: #2d3348;
            color: #818cf8;
        }

        html.theme-dark .report-hub-card:hover .report-card-footer-action {
            color: #a5b4fc;
        }
    </style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid p-0">
        <!-- Header Section -->
        <div class="reports-header-wrap">
            <div class="reports-title-box">
                <div class="reports-icon-circle">
                    <i class="fas fa-file-invoice-dollar"></i>
                </div>
                <div>
                    <h1 class="reports-page-title">Reports Hub</h1>
                    <p class="reports-page-sub">Access official manpower recommendation statements and statutory compliance reports</p>
                </div>
            </div>
            <div>
                <a href="Dashboard.aspx" class="btn-back-dash">
                    <i class="fas fa-arrow-left"></i> Back to Dashboard
                </a>
            </div>
        </div>

        <!-- Reports Cards Grid -->
        <div class="reports-hub-grid">
            <!-- 1. Monthly Attendance & Recommendation Report -->
            <a href="MonthlyAttendanceReport.aspx" class="report-hub-card">
                <div>
                    <div class="report-card-icon-wrap icon-wrap-amber">
                        <i class="fas fa-file-invoice-dollar"></i>
                    </div>
                    <div class="report-card-subtitle">Monthly Manpower Services</div>
                    <h3 class="report-card-title">Monthly Attendance Report</h3>
                    <p class="report-card-desc">
                        Official monthly recommendation and attendance statement for making payment. Generates days attended, non-attended, dynamic leave remarks, previous month salary/EPF dates, and individual signature registers in official landscape format.
                    </p>
                </div>
                <div class="report-card-footer-action">
                    <span>Open Report Generator</span>
                    <i class="fas fa-arrow-right"></i>
                </div>
            </a>
        </div>
    </div>
</asp:Content>
