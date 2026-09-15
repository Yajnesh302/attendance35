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
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
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

        .report-card-badge {
            font-size: 0.72rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 4px 10px;
            border-radius: 20px;
            display: inline-block;
            margin-bottom: 16px;
        }

        .badge-active-rep {
            background: #fef3c7;
            color: #92400e;
            border: 1px solid #fde68a;
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

        /* Coming Soon Placeholder Card */
        .report-placeholder-card {
            border: 2px dashed #cbd5e1;
            background: rgba(248, 250, 252, 0.6);
            border-radius: 20px;
            padding: 28px 24px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            text-align: center;
            min-height: 270px;
            color: #94a3b8;
        }

        .report-placeholder-icon {
            font-size: 2.2rem;
            color: #cbd5e1;
            margin-bottom: 12px;
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
                    <span class="report-card-badge badge-active-rep">
                        <i class="fas fa-check-circle mr-1"></i> Active Report
                    </span>
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

            <!-- 2. Future Placeholder Card -->
            <div class="report-placeholder-card">
                <div class="report-placeholder-icon">
                    <i class="fas fa-layer-group"></i>
                </div>
                <h5 style="font-weight: 700; color: #64748b; margin-bottom: 6px;">More Reports Coming Soon</h5>
                <p style="font-size: 0.84rem; color: #94a3b8; max-width: 260px; margin: 0;">
                    Additional analytical, statutory, and audit workforce reports will appear here as they are introduced.
                </p>
            </div>
        </div>
    </div>
</asp:Content>
