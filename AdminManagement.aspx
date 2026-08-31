<%@ Page Title="Admin Management" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="AdminManagement.aspx.cs" Inherits="AttendanceApp.AdminManagement" EnableEventValidation="false" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Admin Management
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .admin-container {
            margin-top: 10px;
        }
        
        /* Custom styled Confirm Dialog Modal for Revoking Admin */
        #revokeConfirmModal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(15, 23, 42, 0.4);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            z-index: 100000;
            align-items: center;
            justify-content: center;
            opacity: 0;
            transition: opacity 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        }
        
        .confirm-modal-box {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 16px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25), inset 0 0 0 1px rgba(255, 255, 255, 0.6);
            width: 480px;
            max-width: 90%;
            transform: scale(0.92);
            transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
            overflow: hidden;
            font-family: 'Segoe UI', system-ui, sans-serif;
            border: 1px solid rgba(226, 232, 240, 0.8);
        }
        
        .confirm-modal-header {
            background: #f8fafc;
            padding: 20px 24px;
            border-bottom: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            gap: 14px;
        }
        
        .confirm-modal-icon-container {
            background: #fee2e2;
            color: #dc2626;
            width: 42px;
            height: 42px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 6px -1px rgba(220, 38, 38, 0.1);
        }
        
        .confirm-modal-title {
            font-size: 1.25rem;
            font-weight: 700;
            color: #0f172a;
            letter-spacing: -0.01em;
        }
        
        .confirm-modal-body {
            padding: 24px;
            font-size: 1rem;
            line-height: 1.6;
            color: #334155;
        }
        
        .confirm-modal-footer {
            background: #f8fafc;
            padding: 16px 24px;
            border-top: 1px solid #e2e8f0;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }
        
        .btn-modal-action {
            padding: 10px 18px;
            font-size: 0.88rem;
            font-weight: 600;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            border: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        
        .btn-modal-cancel {
            border: 1px solid #cbd5e1;
            background: white;
            color: #475569;
        }
        .btn-modal-cancel:hover {
            background: #f1f5f9;
            color: #1e293b;
            border-color: #94a3b8;
        }
        
        .btn-modal-revoke {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            color: white;
            box-shadow: 0 4px 12px rgba(239, 68, 68, 0.25);
        }
        .btn-modal-revoke:hover {
            box-shadow: 0 6px 16px rgba(239, 68, 68, 0.35);
            transform: translateY(-1px);
            color: white !important;
        }

        /* Custom Tabs Styling */
        .nav-tabs .nav-link {
            border: 1px solid transparent;
            color: #64748b !important;
            font-size: 0.9rem;
            transition: all 0.2s ease;
            padding: 10px 20px;
        }
        .nav-tabs .nav-link:hover {
            color: #4f46e5 !important;
            border-color: #f1f5f9 #f1f5f9 transparent;
            background-color: #fafbfc;
        }
        .nav-tabs .nav-link.active {
            border-color: #e2e8f0 #e2e8f0 #fff !important;
            background-color: #fff !important;
            color: #4f46e5 !important;
            font-weight: 700 !important;
            box-shadow: 0 -2px 6px rgba(0,0,0,0.02);
        }
        
        /* Division checklist custom styles */
        .division-checklist ul {
            list-style-type: none;
            padding-left: 0;
            margin-bottom: 0;
        }
        .division-checklist li {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 6px 12px;
            border-radius: 6px;
            transition: background-color 0.15s ease;
        }
        .division-checklist li:hover {
            background-color: #f1f5f9;
        }
        .division-checklist input[type="checkbox"] {
            width: 18px;
            height: 18px;
            cursor: pointer;
            accent-color: #4f46e5;
            margin-top: 0;
        }
        .division-checklist label {
            margin-bottom: 0;
            cursor: pointer;
            font-weight: 600;
            color: #334155;
            font-size: 0.9rem;
            user-select: none;
        }
        
        /* Readonly textbox style for editing mode */
        .form-control[readonly] {
            background-color: #f1f5f9 !important;
            color: #64748b !important;
            cursor: not-allowed;
            border-color: #cbd5e1 !important;
        }

        /* Custom Indigo Badge Style for Super Admin */
        .bg-indigo {
            background-color: #4f46e5 !important;
            color: #ffffff !important;
        }
    </style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="m-0 text-dark font-weight-bold">Admin & User Registry</h2>
    </div>
    <hr class="mb-4" />
    
    <asp:HiddenField ID="hfActiveTab" runat="server" Value="NonAdmins" />
    
    <div class="row admin-container">
        <!-- Grid Registry and Forms side-by-side -->
        <div class="col-12 mb-4">
            <div class="card shadow-sm border-0 rounded-lg">
                <div class="card-header py-3 text-white d-flex justify-content-between align-items-center" style="background: linear-gradient(180deg,#4f46e5 10%,#3730a3 100%);">
                    <h5 class="m-0 font-weight-bold"><i class="fas fa-users-cog mr-2"></i> User Access Control Registry</h5>
                </div>
                <div class="card-body p-4 bg-white text-dark">
                    <!-- TABS NAVIGATION -->
                    <ul class="nav nav-tabs mb-4" id="adminTabs" role="tablist" style="border-bottom: 1px solid #e2e8f0;">
                        <li class="nav-item" id="liTabNonAdmins" runat="server">
                            <asp:LinkButton ID="btnTabNonAdmins" runat="server" OnClick="btnTabNonAdmins_Click"
                                             CssClass="nav-link"
                                             style="font-weight: 600; border-radius: 8px 8px 0 0; margin-right: 4px;">
                                Regular Users (POC) <span class="badge bg-secondary text-white ml-1" style="font-size: 0.75rem; padding: 3px 8px;"><%= GetNonAdminCount() %></span>
                            </asp:LinkButton>
                        </li>
                        <li class="nav-item" id="liTabSubUsers" runat="server">
                            <asp:LinkButton ID="btnTabSubUsers" runat="server" OnClick="btnTabSubUsers_Click"
                                             CssClass="nav-link"
                                             style="font-weight: 600; border-radius: 8px 8px 0 0; margin-right: 4px;">
                                Sub Users <span class="badge bg-primary text-white ml-1" style="font-size: 0.75rem; padding: 3px 8px;"><%= GetSubUserCount() %></span>
                            </asp:LinkButton>
                        </li>
                        <li class="nav-item" id="liTabAdmins" runat="server">
                            <asp:LinkButton ID="btnTabAdmins" runat="server" OnClick="btnTabAdmins_Click"
                                             CssClass="nav-link"
                                             style="font-weight: 600; border-radius: 8px 8px 0 0; margin-right: 4px;">
                                System Administrators <span class="badge bg-success text-white ml-1" style="font-size: 0.75rem; padding: 3px 8px;"><%= GetAdminCount() %></span>
                            </asp:LinkButton>
                        </li>
                        <li class="nav-item" id="liTabSuperAdmins" runat="server">
                            <asp:LinkButton ID="btnTabSuperAdmins" runat="server" OnClick="btnTabSuperAdmins_Click"
                                             CssClass="nav-link"
                                             style="font-weight: 600; border-radius: 8px 8px 0 0; margin-right: 4px;">
                                Super Administrators <span class="badge bg-indigo text-white ml-1" style="font-size: 0.75rem; padding: 3px 8px;"><%= GetSuperAdminCount() %></span>
                            </asp:LinkButton>
                        </li>
                        <li class="nav-item" id="liTabShareGrants" runat="server">
                            <asp:LinkButton ID="btnTabShareGrants" runat="server" OnClick="btnTabShareGrants_Click"
                                             CssClass="nav-link"
                                             style="font-weight: 600; border-radius: 8px 8px 0 0; margin-right: 4px;">
                                Category Sharing <span class="badge bg-info text-white ml-1" style="font-size: 0.75rem; padding: 3px 8px;"><%= GetShareGrantsCount() %></span>
                            </asp:LinkButton>
                        </li>
                    </ul>

                    <asp:Label ID="lblGridMessage" runat="server" Visible="false" CssClass="alert d-block mb-3" role="alert"></asp:Label>
                    
                    <div class="row">
                        <!-- Left column: User Registry Grid -->
                        <div class="col-lg-7 col-xl-8 mb-4">
                            <div class="table-responsive bg-white rounded shadow-sm border" style="border-radius: 12px; overflow: hidden;">
                                <%-- Admin and Users Grid --%>
                                <asp:GridView ID="gvAdminUsers" runat="server" AutoGenerateColumns="False" 
                                              CssClass="table table-hover align-middle mb-0" 
                                              DataKeyNames="PCNO" OnRowCommand="gvAdminUsers_RowCommand" GridLines="None"
                                              Visible="true">
                                    <Columns>
                                        <asp:BoundField DataField="PCNO" HeaderText="PCNO" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold py-3 px-3 border-bottom" ItemStyle-CssClass="align-middle font-weight-bold py-3 px-3" />
                                        <asp:BoundField DataField="Name" HeaderText="Name" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold py-3 px-3 border-bottom" ItemStyle-CssClass="align-middle py-3 px-3" NullDisplayText="N/A" />
                                        <asp:TemplateField HeaderText="Access / Mappings" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold py-3 px-3 border-bottom" ItemStyle-CssClass="align-middle py-3 px-3">
                                            <ItemTemplate>
                                                <%# GetAccessMappingHtml(Container.DataItem) %>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Actions" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold text-center py-3 px-3 border-bottom" ItemStyle-CssClass="text-center align-middle py-3 px-3">
                                            <ItemTemplate>
                                                 <!-- Revoke Button -->
                                                 <asp:LinkButton ID="lnkRevoke" runat="server" CommandName="RevokeAdmin" 
                                                                 CommandArgument='<%# Eval("PCNO") %>' 
                                                                 CssClass="btn btn-danger btn-sm font-weight-bold text-white px-3 py-1"
                                                                 OnClientClick='<%# "return confirmRevoke(this, \"" + Eval("Name") + "\", \"" + Eval("PCNO") + "\");" %>'
                                                                 Visible='<%# (hfActiveTab.Value == "Admins" && (Convert.ToInt32(Eval("Role")) == 1 || Convert.ToInt32(Eval("Role")) == 0)) || (hfActiveTab.Value == "SuperAdmins" && Convert.ToInt32(Eval("Role")) == 4) || (hfActiveTab.Value == "NonAdmins" && Convert.ToInt32(Eval("Role")) != 3) || (hfActiveTab.Value == "SubUsers" && Convert.ToInt32(Eval("Role")) == 6) %>'
                                                                 style="border-radius: 4px; box-shadow: 0 2px 4px rgba(220,38,38,0.15);">
                                                     <i class="fas fa-user-minus mr-1"></i> Revoke
                                                 </asp:LinkButton>
                                                 <!-- Grant Button -->
                                                 <asp:LinkButton ID="lnkGrant" runat="server" CommandName="GrantAdmin" 
                                                                 CommandArgument='<%# Eval("PCNO") %>' 
                                                                 CssClass="btn btn-success btn-sm font-weight-bold text-white px-3 py-1"
                                                                 Visible='<%# (hfActiveTab.Value == "Admins" && Convert.ToInt32(Eval("Role")) == 2) || (hfActiveTab.Value == "SuperAdmins" && Convert.ToInt32(Eval("Role")) == 5) || (hfActiveTab.Value == "NonAdmins" && Convert.ToInt32(Eval("Role")) == 3) || (hfActiveTab.Value == "SubUsers" && Convert.ToInt32(Eval("Role")) == 7) %>'
                                                                 style="border-radius: 4px; box-shadow: 0 2px 4px rgba(16,185,129,0.15);">
                                                     <i class="fas fa-user-plus mr-1"></i> Grant
                                                 </asp:LinkButton>
                                                  <!-- Edit Divisions & Tiers Button -->
                                                  <asp:LinkButton ID="lnkEdit" runat="server" CommandName="EditUserDivs" 
                                                                  CommandArgument='<%# Eval("PCNO") %>' 
                                                                  CssClass="btn btn-primary btn-sm font-weight-bold text-white px-3 py-1 ml-2"
                                                                  Visible='<%# hfActiveTab.Value == "NonAdmins" && Convert.ToInt32(Eval("Role")) != 3 %>'
                                                                  style="border-radius: 4px; background-color: #3b82f6; border-color: #3b82f6; box-shadow: 0 2px 4px rgba(59,130,246,0.15);">
                                                      <i class="fas fa-edit mr-1"></i> Edit
                                                  </asp:LinkButton>
                                                  <!-- Edit Sub User Button -->
                                                  <asp:LinkButton ID="lnkEditSubUser" runat="server" CommandName="EditSubUser" 
                                                                  CommandArgument='<%# Eval("PCNO") %>' 
                                                                  CssClass="btn btn-primary btn-sm font-weight-bold text-white px-3 py-1 ml-2"
                                                                  Visible='<%# hfActiveTab.Value == "SubUsers" && Convert.ToInt32(Eval("Role")) == 6 %>'
                                                                  style="border-radius: 4px; background-color: #0284c7; border-color: #0284c7; box-shadow: 0 2px 4px rgba(2,132,199,0.15);">
                                                      <i class="fas fa-edit mr-1"></i> Edit
                                                  </asp:LinkButton>
                                                 <!-- Edit Admin Categories Button (Super Admin only) -->
                                                  <asp:LinkButton ID="lnkEditAdminCat" runat="server" CommandName="EditAdminCategory" 
                                                                  CommandArgument='<%# Eval("PCNO") %>' 
                                                                  CssClass="btn btn-primary btn-sm font-weight-bold text-white px-3 py-1 ml-2"
                                                                  Visible='<%# hfActiveTab.Value == "Admins" && Convert.ToInt32(Session["Role"]) == 4 && (Convert.ToInt32(Eval("Role")) == 1 || Convert.ToInt32(Eval("Role")) == 0 || Convert.ToInt32(Eval("Role")) == 2) %>'
                                                                  style="border-radius: 4px; background-color: #3b82f6; border-color: #3b82f6; box-shadow: 0 2px 4px rgba(59,130,246,0.15);">
                                                      <i class="fas fa-edit mr-1"></i> Edit
                                                  </asp:LinkButton>
                                                <!-- Delete Button -->
                                                <asp:LinkButton ID="lnkDelete" runat="server" CommandName="DeleteUser" 
                                                                CommandArgument='<%# Eval("PCNO") %>' 
                                                                CssClass="btn btn-danger btn-sm font-weight-bold text-white px-3 py-1 ml-2"
                                                                OnClientClick='<%# "return confirmDelete(this, \"" + Eval("Name") + "\", \"" + Eval("PCNO") + "\");" %>'
                                                                Visible='<%# (hfActiveTab.Value == "Admins" && Convert.ToInt32(Eval("Role")) == 2) || (hfActiveTab.Value == "SuperAdmins" && Convert.ToInt32(Eval("Role")) == 5) || (hfActiveTab.Value == "NonAdmins" && Convert.ToInt32(Eval("Role")) == 3) || (hfActiveTab.Value == "SubUsers" && Convert.ToInt32(Eval("Role")) == 7) %>'
                                                                style="border-radius: 4px; box-shadow: 0 2px 4px rgba(220,38,38,0.15);">
                                                    <i class="fas fa-trash-alt mr-1"></i> Delete
                                                </asp:LinkButton>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                    <EmptyDataTemplate>
                                        <div class="text-center p-4 text-muted">
                                            No records found in this category.
                                        </div>
                                    </EmptyDataTemplate>
                                </asp:GridView>

                                <%-- Category Share Grants Grid --%>
                                <asp:GridView ID="gvShareGrants" runat="server" AutoGenerateColumns="False" 
                                              CssClass="table table-hover align-middle mb-0" 
                                              DataKeyNames="Id" OnRowCommand="gvShareGrants_RowCommand" GridLines="None"
                                              Visible="false">
                                    <Columns>
                                        <asp:BoundField DataField="OwnerName" HeaderText="Owner Admin" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold py-3 px-3 border-bottom" ItemStyle-CssClass="align-middle py-3 px-3" />
                                        <asp:BoundField DataField="SharedWithName" HeaderText="Shared With Admin" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold py-3 px-3 border-bottom" ItemStyle-CssClass="align-middle py-3 px-3" />
                                        <asp:BoundField DataField="CategoryName" HeaderText="Category" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold py-3 px-3 border-bottom" ItemStyle-CssClass="align-middle py-3 px-3" />
                                        <asp:BoundField DataField="TierName" HeaderText="Scope" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold py-3 px-3 border-bottom" ItemStyle-CssClass="align-middle py-3 px-3 text-muted" />
                                        <asp:TemplateField HeaderText="Status" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold py-3 px-3 border-bottom" ItemStyle-CssClass="align-middle py-3 px-3">
                                            <ItemTemplate>
                                                <%# Convert.ToInt32(Eval("IsActive")) == 1 ? "<span class='badge bg-success text-white px-2 py-1' style='font-size:0.75rem;'><i class='fas fa-check-circle mr-1'></i>Active</span>" : "<span class='badge bg-secondary text-white px-2 py-1' style='font-size:0.75rem;'>Revoked</span>" %>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Actions" HeaderStyle-CssClass="bg-light text-gray-800 font-weight-bold text-center py-3 px-3 border-bottom" ItemStyle-CssClass="text-center align-middle py-3 px-3">
                                             <ItemTemplate>
                                                 <asp:LinkButton ID="lnkEditShare" runat="server" CommandName="EditShare" 
                                                                 CommandArgument='<%# Eval("OwnerAdminPCNO") + "|" + Eval("SharedWithPCNO") + "|" + Eval("MainCategoryId") + "|" + Eval("Id") %>' 
                                                                 CssClass="btn btn-primary btn-sm font-weight-bold text-white px-3 py-1 mr-2"
                                                                 Visible='<%# IsShareOwner(Eval("OwnerAdminPCNO")) %>'
                                                                 style="border-radius: 4px;">
                                                     <i class="fas fa-edit mr-1"></i>Edit
                                                 </asp:LinkButton>
                                                <asp:LinkButton ID="lnkToggleShare" runat="server" CommandName="ToggleShare" 
                                                                CommandArgument='<%# Eval("OwnerAdminPCNO") + "|" + Eval("SharedWithPCNO") + "|" + Eval("MainCategoryId") + "|" + Eval("Id") %>' 
                                                                CssClass='<%# Convert.ToInt32(Eval("IsActive")) == 1 ? "btn btn-danger btn-sm font-weight-bold text-white px-3 py-1" : "btn btn-success btn-sm font-weight-bold text-white px-3 py-1" %>'
                                                                Visible='<%# IsShareOwner(Eval("OwnerAdminPCNO")) %>'
                                                                style="border-radius: 4px;">
                                                    <%# Convert.ToInt32(Eval("IsActive")) == 1 ? "<i class='fas fa-user-slash mr-1'></i>Revoke" : "<i class='fas fa-user-check mr-1'></i>Re-grant" %>
                                                </asp:LinkButton>
                                                <asp:LinkButton ID="lnkDeleteShare" runat="server" CommandName="DeleteShare" 
                                                                CommandArgument='<%# Eval("OwnerAdminPCNO") + "|" + Eval("SharedWithPCNO") + "|" + Eval("MainCategoryId") + "|" + Eval("Id") %>' 
                                                                CssClass="btn btn-outline-danger btn-sm font-weight-bold px-3 py-1 ml-2"
                                                                Visible='<%# IsShareOwner(Eval("OwnerAdminPCNO")) %>'
                                                                OnClientClick="return confirm('Are you sure you want to permanently delete this sharing grant?');"
                                                                style="border-radius: 4px;">
                                                    <i class="fas fa-trash-alt mr-1"></i>Delete
                                                </asp:LinkButton>
                                             </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                    <EmptyDataTemplate>
                                        <div class="text-center p-4 text-muted">
                                            No category sharing grants configured.
                                        </div>
                                    </EmptyDataTemplate>
                                </asp:GridView>
                            </div>
                        </div>

                        <!-- Right Column: Add/Edit Forms -->
                        <div class="col-lg-5 col-xl-4 mb-4">
                            <!-- Add Admin User Form -->
                            <asp:PlaceHolder ID="phAdminForm" runat="server" Visible="false">
                                <div class="card shadow-sm border rounded-lg">
                                    <div class="card-header py-3 text-white" style="background: linear-gradient(135deg, #4f46e5 0%, #3730a3 100%); border-radius: 8px 8px 0 0;">
                                        <h6 class="m-0 font-weight-bold" id="adminFormTitle" runat="server"><i class="fas fa-user-shield mr-2"></i> Add New Admin User</h6>
                                    </div>
                                    <div class="card-body p-4 bg-light text-dark">
                                        <div class="form-group mb-3">
                                            <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">PCNO (Employee ID):</label>
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text bg-white text-muted"><i class="fas fa-id-badge"></i></span>
                                                </div>
                                                <asp:TextBox ID="txtAdminPCNO" runat="server" CssClass="form-control" placeholder="e.g. 1004" oninput="onAdminPcnoInput(this.value)" autocomplete="off" style="border-radius: 0 6px 6px 0; font-weight:600;"></asp:TextBox>
                                            </div>
                                            <div id="adminPcnoLookupFeedback" class="mt-1" style="min-height: 20px;"></div>
                                        </div>
                                        <div class="form-group mb-4">
                                            <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">Full Name:</label>
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text bg-white text-muted"><i class="fas fa-user"></i></span>
                                                </div>
                                                <asp:TextBox ID="txtAdminName" runat="server" CssClass="form-control" placeholder="e.g. Alice Smith" style="border-radius: 0 6px 6px 0; font-weight:600;"></asp:TextBox>
                                            </div>
                                        </div>
                                        <div>
                                            <asp:Button ID="btnAddAdmin" runat="server" Text="Create Admin User" CssClass="btn btn-primary btn-block font-weight-bold py-2 shadow-sm" OnClick="btnAddAdmin_Click" style="background: linear-gradient(135deg, #4f46e5 0%, #3730a3 100%); border: none; border-radius: 6px; font-size: 0.95rem;" />
                                        </div>
                                    </div>
                                </div>
                            </asp:PlaceHolder>

                             <!-- Edit Admin Category Form (Super Admin only) -->
                             <asp:PlaceHolder ID="phEditAdminCategoriesForm" runat="server" Visible="false">
                                 <div class="card shadow-sm border rounded-lg mb-4">
                                     <div ID="editAdminHeader" runat="server" class="card-header py-3 text-white" style="background: linear-gradient(135deg, #4f46e5 0%, #3730a3 100%); border-radius: 8px 8px 0 0;">
                                         <h6 ID="editAdminTitle" runat="server" class="m-0 font-weight-bold"><i class="fas fa-user-edit mr-2"></i> Edit Admin Main Categories</h6>
                                     </div>
                                     <div class="card-body p-4 bg-light text-dark">
                                         <div class="form-group mb-3">
                                             <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">PCNO (Employee ID):</label>
                                             <asp:TextBox ID="txtEditAdminPCNO" runat="server" CssClass="form-control" ReadOnly="true" style="border-radius: 6px; padding: 10px;"></asp:TextBox>
                                         </div>
                                         <div class="form-group mb-3">
                                             <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">Full Name:</label>
                                             <asp:TextBox ID="txtEditAdminName" runat="server" CssClass="form-control" ReadOnly="true" style="border-radius: 6px; padding: 10px;"></asp:TextBox>
                                         </div>
                                         <div class="form-group mb-4">
                                             <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">Assign Main Category:</label>
                                             <asp:DropDownList ID="ddlEditAdminCategory" runat="server" CssClass="form-control" style="border-radius: 6px; padding: 10px;"></asp:DropDownList>
                                         </div>
                                         <div class="d-flex align-items-center">
                                             <asp:Button ID="btnCancelAdminEdit" runat="server" Text="Cancel" CssClass="btn btn-secondary font-weight-bold py-2 mr-2" OnClick="btnCancelAdminEdit_Click" style="border-radius: 6px; flex: 1; font-size: 0.95rem;" />
                                             <asp:Button ID="btnSaveAdminCategories" runat="server" Text="Save Categories" CssClass="btn btn-primary font-weight-bold py-2" OnClick="btnSaveAdminCategories_Click" style="background: linear-gradient(135deg, #4f46e5 0%, #3730a3 100%); border: none; border-radius: 6px; flex: 2; font-size: 0.95rem;" />
                                         </div>
                                     </div>
                                 </div>
                             </asp:PlaceHolder>

                            <!-- Add/Update Regular User Form -->
                            <asp:PlaceHolder ID="phUserForm" runat="server" Visible="false">
                                <div class="card shadow-sm border rounded-lg">
                                    <div ID="userFormHeader" runat="server" class="card-header py-3 text-white" style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); border-radius: 8px 8px 0 0;">
                                        <h6 ID="userFormTitle" runat="server" class="m-0 font-weight-bold"><i class="fas fa-user mr-2"></i> Add Regular User</h6>
                                    </div>
                                    <div class="card-body p-4 bg-light text-dark">
                                        <div class="form-group mb-3">
                                            <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">PCNO (Employee ID):</label>
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text bg-white text-muted"><i class="fas fa-id-badge"></i></span>
                                                </div>
                                                <asp:TextBox ID="txtUserPCNO" runat="server" CssClass="form-control" placeholder="e.g. 1005" oninput="onRegularUserPcnoInput(this.value)" autocomplete="off" style="border-radius: 0 6px 6px 0; font-weight:600;"></asp:TextBox>
                                            </div>
                                            <div id="userPcnoLookupFeedback" class="mt-1" style="min-height: 20px;"></div>
                                        </div>
                                        <div class="form-group mb-3">
                                            <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">Full Name:</label>
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text bg-white text-muted"><i class="fas fa-user"></i></span>
                                                </div>
                                                <asp:TextBox ID="txtUserName" runat="server" CssClass="form-control" placeholder="e.g. Bob Jones" style="border-radius: 0 6px 6px 0; font-weight:600;"></asp:TextBox>
                                            </div>
                                        </div>
                                        <div class="form-group mb-3">
                                            <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">Allowed Divisions (Access Control):</label>
                                            <div class="border rounded p-3 division-checklist" style="max-height: 180px; overflow-y: auto; background-color: #f8fafc; border-color: #cbd5e1; border-radius: 6px;">
                                                <asp:CheckBoxList ID="cblUserDivisions" runat="server" CssClass="w-100" RepeatLayout="UnorderedList">
                                                </asp:CheckBoxList>
                                            </div>
                                        </div>
                                        <div class="form-group mb-4">
                                            <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">Allowed Category Tiers (Access Control):</label>
                                            <div class="border rounded p-3 division-checklist" style="max-height: 180px; overflow-y: auto; background-color: #f8fafc; border-color: #cbd5e1; border-radius: 6px;">
                                                <asp:CheckBoxList ID="cblUserTiers" runat="server" CssClass="w-100" RepeatLayout="UnorderedList">
                                                </asp:CheckBoxList>
                                            </div>
                                        </div>
                                        <div class="d-flex align-items-center">
                                            <asp:Button ID="btnCancelUserEdit" runat="server" Text="Cancel" CssClass="btn btn-secondary font-weight-bold py-2 mr-2" OnClick="btnCancelUserEdit_Click" Visible="false" style="border-radius: 6px; flex: 1; font-size: 0.95rem;" />
                                            <asp:Button ID="btnAddUser" runat="server" Text="Save Regular User" CssClass="btn btn-primary font-weight-bold py-2" OnClick="btnAddUser_Click" style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); border: none; border-radius: 6px; flex: 2; font-size: 0.95rem;" />
                                        </div>
                                    </div>
                                </div>
                            </asp:PlaceHolder>

                            <!-- Add Explicit Sub User Form -->
                            <asp:PlaceHolder ID="phSubUserForm" runat="server" Visible="false">
                                <div class="card shadow-sm border rounded-lg">
                                    <div ID="subUserFormHeader" runat="server" class="card-header py-3 text-white" style="background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%); border-radius: 8px 8px 0 0;">
                                        <h6 ID="subUserFormTitle" runat="server" class="m-0 font-weight-bold"><i class="fas fa-user-edit mr-2"></i> Add Explicit Sub User</h6>
                                    </div>
                                    <div class="card-body p-4 bg-light text-dark">
                                        <div class="form-group mb-3">
                                            <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">PCNO (Employee ID):</label>
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text bg-white text-muted"><i class="fas fa-id-badge"></i></span>
                                                </div>
                                                <asp:TextBox ID="txtSubUserPCNO" runat="server" CssClass="form-control" placeholder="e.g. 1008" oninput="onSubUserPcnoInput(this.value)" autocomplete="off" style="border-radius: 0 6px 6px 0; font-weight:600;"></asp:TextBox>
                                            </div>
                                            <div id="subUserPcnoLookupFeedback" class="mt-1" style="min-height: 20px;"></div>
                                        </div>
                                        <div class="form-group mb-3">
                                            <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.9rem;">Full Name:</label>
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text bg-white text-muted"><i class="fas fa-user"></i></span>
                                                </div>
                                                <asp:TextBox ID="txtSubUserName" runat="server" CssClass="form-control" placeholder="e.g. Sarah Connor" style="border-radius: 0 6px 6px 0; font-weight:600;"></asp:TextBox>
                                            </div>
                                        </div>
                                        <div class="form-group mb-3">
                                            <div class="d-flex justify-content-between align-items-center mb-1">
                                                <label class="form-label font-weight-bold text-gray-800 m-0" style="font-size: 0.9rem;">
                                                    <i class="fas fa-anchor text-primary mr-1"></i> Anchor POC(s) (Regular Users):
                                                </label>
                                                <div>
                                                    <button type="button" class="btn btn-sm btn-link p-0 mr-2 font-weight-bold text-primary" style="font-size: 0.78rem;" onclick="selectAllAnchorPocs(true)">Select All</button>
                                                    <button type="button" class="btn btn-sm btn-link p-0 font-weight-bold text-muted" style="font-size: 0.78rem;" onclick="selectAllAnchorPocs(false)">Clear</button>
                                                </div>
                                            </div>
                                            <!-- Live Search for Anchor POCs -->
                                            <div class="input-group input-group-sm mb-2 shadow-sm">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text bg-white text-muted border-right-0" style="border-radius: 6px 0 0 6px;"><i class="fas fa-search"></i></span>
                                                </div>
                                                <input type="text" id="txtSearchAnchorPOC" class="form-control border-left-0" placeholder="Search POC by name or PC number..." oninput="filterAnchorPocs(this.value)" autocomplete="off" style="border-radius: 0 6px 6px 0; font-size: 0.82rem;" />
                                                <div class="input-group-append" id="btnClearSearchPoc" style="display: none;">
                                                    <button type="button" class="btn btn-outline-secondary btn-sm" onclick="clearPocSearch()" title="Clear search" style="border-radius: 0 6px 6px 0; border-left: none;"><i class="fas fa-times"></i></button>
                                                </div>
                                            </div>
                                            <div id="anchorPocsContainer" style="max-height: 180px; overflow-y: auto; background: #fff; padding: 8px; border: 1px solid #cbd5e1; border-radius: 6px;">
                                                <asp:CheckBoxList ID="cblAnchorPOCs" runat="server" CssClass="w-100 division-checklist" RepeatLayout="UnorderedList" onclick="onAnchorPocCheckboxChange()"></asp:CheckBoxList>
                                                <div id="pocsNoMatchMessage" class="text-center text-muted p-2" style="display: none; font-size: 0.8rem;">
                                                    <i class="fas fa-info-circle mr-1"></i> No matching Anchor POCs found.
                                                </div>
                                            </div>
                                            <small class="text-muted d-block mt-1" style="font-size: 0.78rem;">You can select one or multiple Anchor POCs. The Sub User will inherit the combined division and tier scopes of all chosen POCs.</small>
                                        </div>
                                        <div id="divAnchorScopePreview" class="form-group mb-4" style="display: none;">
                                            <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.85rem;">Inherited Scope Preview:</label>
                                            <div class="p-2 border rounded bg-white" style="font-size: 0.8rem; line-height: 1.5; color: #475569; border-radius: 6px;">
                                                <div><strong>Divisions:</strong> <span id="lblPreviewDivs" class="text-primary font-weight-bold">—</span></div>
                                                <div class="mt-1"><strong>Tiers:</strong> <span id="lblPreviewTiers" class="text-dark font-weight-bold">—</span></div>
                                            </div>
                                        </div>
                                        <div class="d-flex align-items-center">
                                            <asp:Button ID="btnCancelSubUserEdit" runat="server" Text="Cancel" CssClass="btn btn-secondary font-weight-bold py-2 mr-2" OnClick="btnCancelSubUserEdit_Click" Visible="false" style="border-radius: 6px; flex: 1; font-size: 0.95rem;" />
                                            <asp:Button ID="btnSaveSubUser" runat="server" Text="Create Sub User" CssClass="btn btn-primary btn-block font-weight-bold py-2 shadow-sm" OnClick="btnSaveSubUser_Click" style="background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%); border: none; border-radius: 6px; font-size: 0.95rem;" />
                                        </div>
                                    </div>
                                </div>
                            </asp:PlaceHolder>

                             <!-- Share Category Access Form -->
                             <asp:PlaceHolder ID="phShareForm" runat="server" Visible="false">
                                 <div class="card shadow-sm border-0 rounded-lg">
                                     <div class="card-header py-3 text-white" style="background: linear-gradient(135deg, #059669 0%, #047857 100%); border-radius: 8px 8px 0 0;">
                                         <div class="d-flex justify-content-between align-items-center">
                                             <h6 class="m-0 font-weight-bold" style="font-size: 1rem;"><i class="fas fa-share-alt mr-2"></i> Share Category Access</h6>
                                             <span class="badge" style="background: rgba(255,255,255,0.25); color: #fff; font-size: 0.72rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px;">Secondary Admin</span>
                                         </div>
                                         <small class="d-block text-white-50 mt-1" style="font-size: 0.78rem;">Delegate category or tier management to another administrator</small>
                                     </div>
                                     <div class="card-body p-4 bg-light text-dark">
                                         <%-- Hidden fields for tier data, mode, and selections --%>
                                         <asp:HiddenField ID="hfSelectedTierIds" runat="server" />
                                         <asp:HiddenField ID="hfShareFullCategory" runat="server" Value="true" />
                                         <asp:HiddenField ID="hfShareGuestMode" runat="server" Value="existing" />
                                         <asp:HiddenField ID="hfEditShareId" runat="server" />

                                         <!-- Step 1: Select Category -->
                                         <div class="form-group mb-3">
                                             <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.88rem;">
                                                 <i class="fas fa-layer-group text-success mr-1"></i> 1. Select Category to Share:
                                             </label>
                                             <asp:DropDownList ID="ddlShareCategory" runat="server" CssClass="form-control" onchange="onCategoryDropdownChange(this)" style="border-radius: 6px; padding: 8px 12px; font-weight: 600;"></asp:DropDownList>
                                         </div>

                                         <!-- Step 2: Access Scope -->
                                         <div class="form-group mb-3">
                                             <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.88rem;">
                                                 <i class="fas fa-sliders-h text-success mr-1"></i> 2. Access Scope:
                                             </label>
                                             <div class="border rounded p-3" style="background:#f8fafc; border-color:#cbd5e1; border-radius:8px;">
                                                 <div class="custom-control custom-switch">
                                                     <input type="checkbox" class="custom-control-input" id="chkShareFullCategoryHtml" checked onchange="onShareScopeChange(this)" />
                                                     <label class="custom-control-label font-weight-bold text-gray-900" for="chkShareFullCategoryHtml" style="cursor:pointer; font-size: 0.9rem;">
                                                         Grant access to Entire Category (All Tiers)
                                                     </label>
                                                 </div>
                                                 <small class="text-muted d-block mt-1" style="font-size: 0.78rem;">Allows the secondary admin to manage all current and future tiers in this category.</small>
                                                 
                                                 <div id="divShareTiers" style="display: none; margin-top: 12px; padding-top: 10px; border-top: 1px solid #e2e8f0;">
                                                     <div class="d-flex justify-content-between align-items-center mb-2">
                                                         <label class="font-weight-bold text-gray-800 m-0" style="font-size: 0.82rem;"><i class="fas fa-tags mr-1 text-primary"></i> Select Allowed Tiers:</label>
                                                         <div>
                                                             <button type="button" class="btn btn-sm btn-link p-0 mr-2 font-weight-bold text-primary" style="font-size: 0.78rem;" onclick="selectAllTiers(true)">Select All</button>
                                                             <button type="button" class="btn btn-sm btn-link p-0 font-weight-bold text-muted" style="font-size: 0.78rem;" onclick="selectAllTiers(false)">Clear</button>
                                                         </div>
                                                     </div>
                                                     <div id="tiersContainer" style="max-height: 160px; overflow-y: auto; background: #fff; padding: 8px; border: 1px solid #cbd5e1; border-radius: 6px;">
                                                         <asp:CheckBoxList ID="cblShareTiers" runat="server" CssClass="w-100 division-checklist" RepeatLayout="UnorderedList"></asp:CheckBoxList>
                                                     </div>
                                                 </div>
                                             </div>
                                         </div>

                                         <!-- Step 3: Assign Administrator -->
                                         <div class="form-group mb-4">
                                             <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.88rem;">
                                                 <i class="fas fa-user-shield text-success mr-1"></i> 3. Assign Administrator:
                                             </label>

                                             <!-- Segmented Toggle Switch -->
                                             <div class="btn-group btn-group-toggle w-100 mb-3 shadow-sm" style="border-radius: 8px; overflow: hidden; border: 1px solid #10b981;">
                                                 <button type="button" id="btnModeExisting" class="btn btn-sm btn-success font-weight-bold py-2" style="flex: 1; border-radius: 0;" onclick="setGuestMode('existing')">
                                                     <i class="fas fa-list mr-1"></i> Select Existing Admin
                                                 </button>
                                                 <button type="button" id="btnModeNew" class="btn btn-sm btn-outline-success font-weight-bold py-2" style="flex: 1; border-radius: 0;" onclick="setGuestMode('new')">
                                                     <i class="fas fa-user-plus mr-1"></i> Enter New PC Number
                                                 </button>
                                             </div>

                                             <!-- Mode A: Existing Admin Dropdown -->
                                             <div id="divGuestExisting" style="display: block;">
                                                 <asp:DropDownList ID="ddlShareGuestAdmin" runat="server" CssClass="form-control" style="border-radius: 6px; padding: 8px 12px; font-weight: 600;"></asp:DropDownList>
                                                 <small class="text-muted d-block mt-1" style="font-size: 0.78rem;">Choose from administrators currently registered in the system.</small>
                                             </div>

                                             <!-- Mode B: New Admin PCNO Input -->
                                             <div id="divGuestNew" class="border rounded p-3" style="display: none; background: #f8fafc; border-color: #cbd5e1; border-radius: 8px;">
                                                 <div class="form-group mb-2">
                                                     <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.82rem;">PC Number (Employee ID):</label>
                                                     <div class="input-group">
                                                         <div class="input-group-prepend">
                                                             <span class="input-group-text bg-white text-muted"><i class="fas fa-id-badge"></i></span>
                                                         </div>
                                                         <asp:TextBox ID="txtShareGuestPCNO" runat="server" CssClass="form-control" placeholder="e.g. 1005" oninput="onGuestPcnoInput(this.value)" autocomplete="off" style="border-radius: 0 6px 6px 0; font-weight: 600;"></asp:TextBox>
                                                     </div>
                                                     <div id="pcnoLookupFeedback" class="mt-1" style="min-height: 20px;"></div>
                                                 </div>
                                                 <div class="form-group mb-0">
                                                     <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.82rem;">Full Name:</label>
                                                     <div class="input-group">
                                                         <div class="input-group-prepend">
                                                             <span class="input-group-text bg-white text-muted"><i class="fas fa-user"></i></span>
                                                         </div>
                                                         <asp:TextBox ID="txtShareGuestName" runat="server" CssClass="form-control" placeholder="e.g. Jane Doe" style="border-radius: 0 6px 6px 0; font-weight: 600;"></asp:TextBox>
                                                     </div>
                                                 </div>
                                             </div>
                                         </div>

                                         <!-- Action Buttons -->
                                         <div style="display: flex; gap: 10px;">
                                             <asp:Button ID="btnCancelShareEdit" runat="server" Text="Cancel" CssClass="btn btn-secondary font-weight-bold py-2 shadow-sm" Visible="false" style="border-radius: 6px; font-size: 0.95rem; flex: 1;" OnClick="btnCancelShareEdit_Click" />
                                             <asp:Button ID="btnCreateShare" runat="server" Text="Grant Category Access" CssClass="btn btn-success font-weight-bold py-2 shadow-sm" style="flex: 2; background: linear-gradient(135deg, #10b981 0%, #047857 100%); border: none; border-radius: 6px; font-size: 0.95rem;" OnClick="btnCreateShare_Click" OnClientClick="return prepareShareSubmit()" />
                                         </div>
                                     </div>
                                 </div>
                             </asp:PlaceHolder>
                        </div>
                    </div>
                </div>
            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Custom Revoke Confirm Modal -->
    <div id="revokeConfirmModal">
        <div class="confirm-modal-box">
            <div class="confirm-modal-header" style="background: #fef2f2; border-bottom: 1px solid #fee2e2;">
                <div class="confirm-modal-icon-container">
                    <i class="fas fa-user-shield"></i>
                </div>
                <span class="confirm-modal-title">Revoke Admin Access</span>
            </div>
            <div class="confirm-modal-body">
                <span id="revokeConfirmPrompt">Are you sure you want to revoke administrator access for</span> <strong id="revokeAdminName" class="text-dark"></strong> (PCNO: <span id="revokeAdminPcno" class="text-secondary"></span>)?
                <div id="revokeConfirmDesc" style="margin-top: 12px; font-size: 0.88rem; color: #64748b; line-height: 1.5;">
                    This user will no longer be able to access the admin management, configurations, or calculation tools. Their details will be kept in the registry for future promotions.
                </div>
            </div>
            <div class="confirm-modal-footer">
                <button id="btnRevokeModalCancel" type="button" class="btn-modal-action btn-modal-cancel">Cancel</button>
                <button id="btnRevokeModalConfirm" type="button" class="btn-modal-action btn-modal-revoke">Revoke Access</button>
            </div>
        </div>
    </div>

    <!-- Custom Delete Confirm Modal -->
    <div id="deleteConfirmModal" style="display: none; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(15, 23, 42, 0.4); backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px); z-index: 100000; align-items: center; justify-content: center; opacity: 0; transition: opacity 0.3s cubic-bezier(0.16, 1, 0.3, 1);">
        <div class="confirm-modal-box">
            <div class="confirm-modal-header" style="background: #fef2f2; border-bottom: 1px solid #fee2e2;">
                <div class="confirm-modal-icon-container" style="background: #fee2e2; color: #dc2626;">
                    <i class="fas fa-trash-alt"></i>
                </div>
                <span class="confirm-modal-title">Delete User from Registry</span>
            </div>
            <div class="confirm-modal-body">
                Are you sure you want to permanently delete <strong id="deleteAdminName" class="text-dark"></strong> (PCNO: <span id="deleteAdminPcno" class="text-secondary"></span>) from the registry?
                <div style="margin-top: 12px; font-size: 0.88rem; color: #64748b; line-height: 1.5;">
                    This will completely remove their record from the administrative database table (`AppUsers`). They will no longer appear in the Non-Admins registry.
                </div>
            </div>
            <div class="confirm-modal-footer">
                <button id="btnDeleteModalCancel" type="button" class="btn-modal-action btn-modal-cancel">Cancel</button>
                <button id="btnDeleteModalConfirm" type="button" class="btn-modal-action btn-modal-revoke">Delete</button>
            </div>
        </div>
    </div>

    <script>
        let targetCommand = null;

        function confirmRevoke(element, name, pcno) {
            const modal = document.getElementById("revokeConfirmModal");
            const adminNameSpan = document.getElementById("revokeAdminName");
            const adminPcnoSpan = document.getElementById("revokeAdminPcno");
            const btnConfirm = document.getElementById("btnRevokeModalConfirm");
            const btnCancel = document.getElementById("btnRevokeModalCancel");

            if (!modal || !adminNameSpan || !adminPcnoSpan) return true;

            adminNameSpan.textContent = name;
            adminPcnoSpan.textContent = pcno;

            // Customize modal text dynamically based on the active tab
            const activeTab = document.getElementById('<%= hfActiveTab.ClientID %>').value;
            const titleSpan = modal.querySelector(".confirm-modal-title");
            const promptSpan = document.getElementById("revokeConfirmPrompt");
            const descDiv = document.getElementById("revokeConfirmDesc");
            const icon = modal.querySelector(".confirm-modal-icon-container i");

            if (activeTab === "Admins") {
                if (titleSpan) titleSpan.textContent = "Revoke Admin Access";
                if (promptSpan) promptSpan.textContent = "Are you sure you want to revoke administrator access for";
                if (descDiv) descDiv.textContent = "This user will no longer be able to access the admin management, configurations, or calculation tools. Their details will be kept in the registry for future promotions.";
                if (icon) icon.className = "fas fa-user-shield";
            } else {
                if (titleSpan) titleSpan.textContent = "Revoke User Access";
                if (promptSpan) promptSpan.textContent = "Are you sure you want to revoke regular user access for";
                if (descDiv) descDiv.textContent = "This user will no longer be able to access the attendance or ledger views. Their details and division mappings will be preserved in the registry.";
                if (icon) icon.className = "fas fa-user-minus";
            }
            
            // Save the postback script/href to execute if confirmed
            const originalHref = element.getAttribute("href");
            targetCommand = () => {
                if (originalHref.startsWith("javascript:")) {
                    // Eval the postback script
                    eval(originalHref.substring(11));
                } else {
                    // Navigate or click
                    window.location.href = originalHref;
                }
            };

            // Show modal
            modal.style.display = "flex";
            modal.offsetHeight; // trigger reflow
            modal.style.opacity = "1";
            modal.querySelector(".confirm-modal-box").style.transform = "scale(1)";

            btnCancel.onclick = () => {
                closeRevokeModal();
            };

            btnConfirm.onclick = () => {
                closeRevokeModal();
                if (targetCommand) targetCommand();
            };

            function closeRevokeModal() {
                modal.style.opacity = "0";
                modal.querySelector(".confirm-modal-box").style.transform = "scale(0.92)";
                setTimeout(() => {
                    modal.style.display = "none";
                }, 250);
            }

            return false; // Prevent immediate postback
        }

        function confirmDelete(element, name, pcno) {
            const modal = document.getElementById("deleteConfirmModal");
            const adminNameSpan = document.getElementById("deleteAdminName");
            const adminPcnoSpan = document.getElementById("deleteAdminPcno");
            const btnConfirm = document.getElementById("btnDeleteModalConfirm");
            const btnCancel = document.getElementById("btnDeleteModalCancel");

            if (!modal || !adminNameSpan || !adminPcnoSpan) return true;

            adminNameSpan.textContent = name;
            adminPcnoSpan.textContent = pcno;
            
            // Save the postback script/href to execute if confirmed
            const originalHref = element.getAttribute("href");
            targetCommand = () => {
                if (originalHref.startsWith("javascript:")) {
                    // Eval the postback script
                    eval(originalHref.substring(11));
                } else {
                    // Navigate or click
                    window.location.href = originalHref;
                }
            };

            // Show modal
            modal.style.display = "flex";
            modal.offsetHeight; // trigger reflow
            modal.style.opacity = "1";
            modal.querySelector(".confirm-modal-box").style.transform = "scale(1)";

            btnCancel.onclick = () => {
                closeDeleteModal();
            };

            btnConfirm.onclick = () => {
                closeDeleteModal();
                if (targetCommand) targetCommand();
            };

            function closeDeleteModal() {
                modal.style.opacity = "0";
                modal.querySelector(".confirm-modal-box").style.transform = "scale(0.92)";
                setTimeout(() => {
                    modal.style.display = "none";
                }, 250);
            }

            return false; // Prevent immediate postback
        }

        // Toggle Segmented Control between Existing Admin and New PCNO
        function setGuestMode(mode) {
            var hfMode = document.getElementById('<%= hfShareGuestMode.ClientID %>');
            var btnExisting = document.getElementById("btnModeExisting");
            var btnNew = document.getElementById("btnModeNew");
            var divExisting = document.getElementById("divGuestExisting");
            var divNew = document.getElementById("divGuestNew");

            if (hfMode) hfMode.value = mode;

            if (mode === 'new') {
                if (btnNew) {
                    btnNew.className = "btn btn-sm btn-success font-weight-bold py-2";
                }
                if (btnExisting) {
                    btnExisting.className = "btn btn-sm btn-outline-success font-weight-bold py-2";
                }
                if (divNew) divNew.style.display = "block";
                if (divExisting) divExisting.style.display = "none";
                
                var txtPcno = document.getElementById('<%= txtShareGuestPCNO.ClientID %>');
                if (txtPcno && !txtPcno.readOnly) txtPcno.focus();
            } else {
                if (btnExisting) {
                    btnExisting.className = "btn btn-sm btn-success font-weight-bold py-2";
                }
                if (btnNew) {
                    btnNew.className = "btn btn-sm btn-outline-success font-weight-bold py-2";
                }
                if (divExisting) divExisting.style.display = "block";
                if (divNew) divNew.style.display = "none";
            }
        }

        // Asynchronously load tiers when user changes category without page reload
        function onCategoryDropdownChange(sel) {
            var catId = sel.value;
            if (!catId) return;

            $.ajax({
                type: "POST",
                url: "AdminManagement.aspx/GetTiersForCategory",
                data: JSON.stringify({ categoryId: parseInt(catId, 10) }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    if (res && res.d && res.d.success) {
                        var tiers = res.d.tiers || [];
                        var container = document.getElementById("tiersContainer");
                        if (!container) return;

                        if (tiers.length === 0) {
                            container.innerHTML = '<div class="text-muted p-2" style="font-size:0.82rem;">No tiers defined for this category. Full category access will apply.</div>';
                            return;
                        }

                        var ul = document.createElement("ul");
                        ul.className = "w-100 division-checklist";
                        ul.style.listStyle = "none";
                        ul.style.paddingLeft = "0";
                        ul.style.marginBottom = "0";

                        tiers.forEach(function (t, idx) {
                            var li = document.createElement("li");
                            li.style.display = "flex";
                            li.style.alignItems = "center";
                            li.style.gap = "8px";
                            li.style.padding = "4px 8px";
                            li.style.borderRadius = "4px";

                            var chk = document.createElement("input");
                            chk.type = "checkbox";
                            chk.value = t.id;
                            chk.id = "chkShareTierDynamic_" + t.id;
                            chk.style.width = "16px";
                            chk.style.height = "16px";
                            chk.style.cursor = "pointer";

                            var lbl = document.createElement("label");
                            lbl.htmlFor = chk.id;
                            lbl.textContent = t.name;
                            lbl.style.marginBottom = "0";
                            lbl.style.cursor = "pointer";
                            lbl.style.fontWeight = "600";
                            lbl.style.fontSize = "0.85rem";
                            lbl.style.color = "#334155";

                            li.appendChild(chk);
                            li.appendChild(lbl);
                            ul.appendChild(li);
                        });

                        container.innerHTML = "";
                        container.appendChild(ul);
                    }
                },
                error: function (err) {
                    console.log("Error loading tiers: ", err);
                }
            });
        }

        // Live real-time PCNO Lookup with debounce (Zero page reloads)
        var lookupTimers = {};
        function genericPcnoLookup(val, nameBoxId, feedbackId) {
            if (lookupTimers[feedbackId]) clearTimeout(lookupTimers[feedbackId]);
            var feedback = document.getElementById(feedbackId);
            var nameBox = document.getElementById(nameBoxId);

            var cleanVal = (val || "").trim();
            if (!cleanVal) {
                if (feedback) feedback.innerHTML = "";
                return;
            }

            if (feedback) {
                feedback.innerHTML = '<span class="text-muted" style="font-size:0.75rem;"><i class="fas fa-spinner fa-spin mr-1"></i> Checking PC Number...</span>';
            }

            lookupTimers[feedbackId] = setTimeout(function () {
                $.ajax({
                    type: "POST",
                    url: "AdminManagement.aspx/LookupUser",
                    data: JSON.stringify({ pcno: cleanVal }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        if (res && res.d && res.d.success) {
                            if (res.d.found) {
                                if (nameBox) nameBox.value = res.d.name;
                                if (feedback) {
                                    feedback.innerHTML = '<span class="badge bg-success text-white px-2 py-1" style="font-size:0.75rem;"><i class="fas fa-check-circle mr-1"></i> Found: ' + res.d.name + '</span>';
                                }
                            } else {
                                if (feedback) {
                                    feedback.innerHTML = '<span class="badge bg-info text-white px-2 py-1" style="font-size:0.75rem;"><i class="fas fa-user-plus mr-1"></i> New user: Enter full name below</span>';
                                }
                            }
                        }
                    },
                    error: function () {
                        if (feedback) feedback.innerHTML = "";
                    }
                });
            }, 300);
        }

        function onGuestPcnoInput(val) {
            genericPcnoLookup(val, '<%= txtShareGuestName.ClientID %>', 'pcnoLookupFeedback');
        }

        function onAdminPcnoInput(val) {
            genericPcnoLookup(val, '<%= txtAdminName.ClientID %>', 'adminPcnoLookupFeedback');
        }

        function onRegularUserPcnoInput(val) {
            genericPcnoLookup(val, '<%= txtUserName.ClientID %>', 'userPcnoLookupFeedback');
        }

        function onSubUserPcnoInput(val) {
            if (lookupTimers["subUserPcnoLookupFeedback"]) clearTimeout(lookupTimers["subUserPcnoLookupFeedback"]);
            var feedback = document.getElementById("subUserPcnoLookupFeedback");
            var nameBox = document.getElementById('<%= txtSubUserName.ClientID %>');
            var btnSave = document.getElementById('<%= btnSaveSubUser.ClientID %>');
            var titleHeader = document.getElementById('<%= subUserFormTitle.ClientID %>');
            var container = document.getElementById("anchorPocsContainer");

            var cleanVal = (val || "").trim();
            if (!cleanVal) {
                if (feedback) feedback.innerHTML = "";
                return;
            }

            if (feedback) {
                feedback.innerHTML = '<span class="text-muted" style="font-size:0.75rem;"><i class="fas fa-spinner fa-spin mr-1"></i> Looking up Sub User details...</span>';
            }

            lookupTimers["subUserPcnoLookupFeedback"] = setTimeout(function () {
                $.ajax({
                    type: "POST",
                    url: "AdminManagement.aspx/LookupSubUser",
                    data: JSON.stringify({ pcno: cleanVal }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (res) {
                        if (res && res.d && res.d.success) {
                            if (res.d.found) {
                                if (nameBox && res.d.name) nameBox.value = res.d.name;
                                
                                // Auto-check all existing assigned anchor POCs
                                if (container && res.d.anchors && res.d.anchors.length > 0) {
                                    var chks = container.querySelectorAll("input[type='checkbox']");
                                    chks.forEach(function (c) {
                                        var v = c.value;
                                        if (!v) {
                                            var parentLi = c.closest("li");
                                            if (parentLi) {
                                                var lbl = parentLi.querySelector("label");
                                                if (lbl && lbl.getAttribute("for")) {
                                                    v = c.getAttribute("value") || "";
                                                }
                                            }
                                        }
                                        if (res.d.anchors.indexOf(v) !== -1) {
                                            c.checked = true;
                                        }
                                    });
                                }

                                onAnchorPocCheckboxChange();

                                if (res.d.isSubUser || (res.d.anchors && res.d.anchors.length > 0)) {
                                    if (btnSave) btnSave.value = "Update Sub User";
                                    if (titleHeader) titleHeader.innerHTML = '<i class="fas fa-user-edit mr-2"></i> Update Sub User';
                                    if (feedback) {
                                        var countStr = res.d.anchors ? res.d.anchors.length : 0;
                                        feedback.innerHTML = '<span class="badge bg-success text-white px-2 py-1" style="font-size:0.75rem;"><i class="fas fa-check-circle mr-1"></i> Existing Sub User: ' + (res.d.name || cleanVal) + ' (' + countStr + ' Anchor POC(s) linked)</span>';
                                    }
                                } else {
                                    if (feedback) {
                                        feedback.innerHTML = '<span class="badge bg-info text-white px-2 py-1" style="font-size:0.75rem;"><i class="fas fa-user-check mr-1"></i> Found: ' + res.d.name + '</span>';
                                    }
                                }
                            } else {
                                if (feedback) {
                                    feedback.innerHTML = '<span class="badge bg-secondary text-white px-2 py-1" style="font-size:0.75rem;"><i class="fas fa-user-plus mr-1"></i> New Sub User: Enter full name below</span>';
                                }
                            }
                        }
                    },
                    error: function () {
                        if (feedback) feedback.innerHTML = "";
                    }
                });
            }, 300);
        }

        function filterAnchorPocs(val) {
            var filter = (val || "").trim().toLowerCase();
            var container = document.getElementById("anchorPocsContainer");
            var clearBtn = document.getElementById("btnClearSearchPoc");
            var noMatch = document.getElementById("pocsNoMatchMessage");
            
            if (clearBtn) {
                clearBtn.style.display = filter ? "block" : "none";
            }

            if (!container) return;
            var listItems = container.querySelectorAll("li");
            var visibleCount = 0;

            listItems.forEach(function (li) {
                var text = (li.textContent || li.innerText || "").toLowerCase();
                if (!filter || text.indexOf(filter) !== -1) {
                    li.style.display = "";
                    visibleCount++;
                } else {
                    li.style.display = "none";
                }
            });

            if (noMatch) {
                noMatch.style.display = (listItems.length > 0 && visibleCount === 0) ? "block" : "none";
            }
        }

        function clearPocSearch() {
            var searchInput = document.getElementById("txtSearchAnchorPOC");
            if (searchInput) {
                searchInput.value = "";
                filterAnchorPocs("");
                searchInput.focus();
            }
        }

        function selectAllAnchorPocs(select) {
            var container = document.getElementById("anchorPocsContainer");
            if (container) {
                var listItems = container.querySelectorAll("li");
                listItems.forEach(function (li) {
                    if (li.style.display !== "none") {
                        var chk = li.querySelector("input[type='checkbox']");
                        if (chk) chk.checked = select;
                    }
                });
            }
            onAnchorPocCheckboxChange();
        }

        function onAnchorPocCheckboxChange() {
            var container = document.getElementById("anchorPocsContainer");
            if (!container) return;
            var checkedPcnos = [];
            var chks = container.querySelectorAll("input[type='checkbox']:checked");
            chks.forEach(function (c) {
                var val = c.value;
                if (!val) {
                    var parentLi = c.closest("li");
                    if (parentLi) {
                        var lbl = parentLi.querySelector("label");
                        if (lbl && lbl.getAttribute("for")) {
                            val = c.getAttribute("value") || "";
                        }
                    }
                }
                if (val) checkedPcnos.push(val);
            });

            var previewDiv = document.getElementById("divAnchorScopePreview");
            var lblDivs = document.getElementById("lblPreviewDivs");
            var lblTiers = document.getElementById("lblPreviewTiers");

            if (checkedPcnos.length === 0) {
                if (previewDiv) previewDiv.style.display = "none";
                return;
            }

            if (previewDiv) previewDiv.style.display = "block";
            if (lblDivs) lblDivs.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Loading divisions...';
            if (lblTiers) lblTiers.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Loading tiers...';

            $.ajax({
                type: "POST",
                url: "AdminManagement.aspx/GetAnchorPocScope",
                data: JSON.stringify({ pocPcnos: checkedPcnos.join(",") }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    if (res && res.d && res.d.success) {
                        if (lblDivs) lblDivs.textContent = res.d.divisions || "None";
                        if (lblTiers) lblTiers.textContent = res.d.tiers || "None";
                    } else {
                        if (lblDivs) lblDivs.textContent = "Error loading divisions";
                        if (lblTiers) lblTiers.textContent = "Error loading tiers";
                    }
                },
                error: function () {
                    if (lblDivs) lblDivs.textContent = "Error loading divisions";
                    if (lblTiers) lblTiers.textContent = "Error loading tiers";
                }
            });
        }

        function selectAllTiers(select) {
            var container = document.getElementById("tiersContainer");
            if (container) {
                var chks = container.querySelectorAll("input[type='checkbox']");
                chks.forEach(function (c) { c.checked = select; });
            }
        }

        function onShareScopeChange(chk) {
            var divTiers = document.getElementById("divShareTiers");
            var hfFull = document.getElementById('<%= hfShareFullCategory.ClientID %>');
            if (chk.checked) {
                if (divTiers) divTiers.style.display = "none";
                if (hfFull) hfFull.value = "true";
            } else {
                if (divTiers) divTiers.style.display = "block";
                if (hfFull) hfFull.value = "false";
            }
        }

        function prepareShareSubmit() {
            var chkFull = document.getElementById("chkShareFullCategoryHtml");
            var hfFull = document.getElementById('<%= hfShareFullCategory.ClientID %>');
            var hfSelected = document.getElementById('<%= hfSelectedTierIds.ClientID %>');
            
            if (chkFull && chkFull.checked) {
                if (hfFull) hfFull.value = "true";
                if (hfSelected) hfSelected.value = "";
                return true;
            }
            
            if (hfFull) hfFull.value = "false";
            
            // Get selected tiers from the container (both server-side and dynamically loaded)
            var selectedIds = [];
            var container = document.getElementById("tiersContainer");
            if (container) {
                var checkboxes = container.querySelectorAll("input[type='checkbox']");
                checkboxes.forEach(function(cb) {
                    if (cb.checked && cb.value) {
                        selectedIds.push(cb.value);
                    }
                });
            }
            
            if (selectedIds.length === 0) {
                alert("Please select at least one tier to share, or enable 'entire category'.");
                return false;
            }
            
            if (hfSelected) hfSelected.value = selectedIds.join(",");
            return true;
        }

        // On page load, initialize the share scope and guest mode visibility
        document.addEventListener("DOMContentLoaded", function() {
            var chkFull = document.getElementById("chkShareFullCategoryHtml");
            var hfFull = document.getElementById('<%= hfShareFullCategory.ClientID %>');
            if (hfFull && hfFull.value !== "") {
                if (chkFull) {
                    chkFull.checked = (hfFull.value === "true");
                }
            }
            if (chkFull) {
                onShareScopeChange(chkFull);
            }

            var hfMode = document.getElementById('<%= hfShareGuestMode.ClientID %>');
            if (hfMode && hfMode.value) {
                setGuestMode(hfMode.value);
            }
        });
    </script>
</asp:Content>
