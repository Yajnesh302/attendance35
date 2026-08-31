<%@ Page Title="Settings" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Settings.aspx.cs" Inherits="AttendanceApp.Settings" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Settings & Configurations
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .settings-container {
            margin-top: 10px;
        }
        .card-header-gradient {
            background: linear-gradient(180deg, #4f46e5 10%, #3730a3 100%);
        }
        .table-custom-settings th {
            background-color: #f8fafc;
            color: #334155;
            font-weight: 700;
            border-bottom: 2px solid #e2e8f0;
            padding: 12px 16px;
        }
        .table-custom-settings td {
            color: #0f172a;
            vertical-align: middle !important;
            padding: 12px 16px;
        }
        .action-column {
            width: 180px;
            text-align: center;
        }
        .list-group-item-action {
            cursor: pointer;
            transition: all 0.2s ease;
            color: #334155;
        }
        .list-group-item-action:hover {
            background-color: #f1f5f9;
            color: #4f46e5;
            padding-left: 24px;
        }
        .list-group-item-action.active {
            padding-left: 24px;
        }
        .history-table-container {
            max-height: 280px;
            overflow-y: auto;
            border-radius: 0 0 6px 6px;
        }
        .history-table-container th {
            position: sticky;
            top: 0;
            background-color: #f8fafc !important;
            z-index: 10;
            box-shadow: inset 0 -1px 0 #e2e8f0;
        }
    </style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Settings & Configurations</h2>
    <hr />
    
    <asp:HiddenField ID="hfActiveTab" runat="server" ClientIDMode="Static" Value="divisions" />

    <div class="row settings-container">
        <!-- Sidebar Menu Column -->
        <div class="col-md-3 mb-4">
            <div class="card shadow-sm border-0 rounded-lg">
                <div class="card-header py-3 text-white card-header-gradient">
                    <h6 class="m-0 font-weight-bold"><i class="fas fa-sliders-h mr-2"></i> Settings Menu</h6>
                </div>
                <div class="list-group list-group-flush" id="settings-menu">
                    <a href="javascript:void(0);" onclick="switchTab('divisions')" id="tab-divisions" class="list-group-item list-group-item-action font-weight-bold py-3">
                        <i class="fas fa-building mr-2"></i> Directorates
                    </a>
                    <a href="javascript:void(0);" onclick="switchTab('categories')" id="tab-categories" class="list-group-item list-group-item-action font-weight-bold py-3">
                        <i class="fas fa-tags mr-2"></i> Categories
                    </a>
                    <a href="javascript:void(0);" onclick="switchTab('editwindow')" id="tab-editwindow" class="list-group-item list-group-item-action font-weight-bold py-3">
                        <i class="fas fa-calendar-alt mr-2 text-info"></i> POC Edit Window
                    </a>
                    <a href="javascript:void(0);" onclick="switchTab('undo')" id="tab-undo" class="list-group-item list-group-item-action font-weight-bold py-3">
                        <i class="fas fa-undo mr-2 text-danger"></i> Undo Manager
                    </a>
                    <a href="javascript:void(0);" onclick="switchTab('backup')" id="tab-backup" class="list-group-item list-group-item-action font-weight-bold py-3">
                        <i class="fas fa-database mr-2 text-warning"></i> Backup & Restore
                    </a>
                </div>
            </div>
        </div>

        <!-- Settings Content Column -->
        <div class="col-md-9 mb-4">
            <!-- Directorate Management Panel -->
            <div id="panel-divisions" class="card shadow-sm border-0 rounded-lg" style="display:none;">
                <div class="card-header py-3 text-white card-header-gradient">
                    <h5 class="m-0 font-weight-bold"><i class="fas fa-building mr-2"></i> Directorate List</h5>
                </div>
                <div class="card-body p-4 bg-white text-dark">
                    <div class="alert alert-info py-2 px-3 mb-3 small">
                        <i class="fas fa-info-circle mr-2"></i> Directorates are synchronized directly from Company Database (Read-Only).
                    </div>

                    <!-- Directorate GridView -->
                    <div class="table-responsive">
                        <asp:GridView ID="gvDivisions" runat="server" AutoGenerateColumns="False" 
                                      CssClass="table table-bordered table-hover table-custom-settings mb-0" 
                                      GridLines="None">
                            <Columns>
                                <asp:TemplateField HeaderText="S.No" ItemStyle-Width="60" ItemStyle-CssClass="text-center" HeaderStyle-CssClass="text-center">
                                    <ItemTemplate>
                                        <%# Container.DataItemIndex + 1 %>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Directorate Name">
                                    <ItemTemplate>
                                        <asp:Label ID="lblDivName" runat="server" Text='<%# Eval("Name") %>' Font-Bold="true"></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                            <EmptyDataTemplate>
                                <div class="text-center p-3 text-muted">
                                    No directorates configured.
                                </div>
                            </EmptyDataTemplate>
                        </asp:GridView>
                    </div>
                </div>
            </div>

            <!-- Category Management Panel -->
            <div id="panel-categories" class="card shadow-sm border-0 rounded-lg" style="display:none;">
                <div class="card-header py-3 text-white card-header-gradient">
                    <h5 class="m-0 font-weight-bold"><i class="fas fa-tags mr-2"></i> Category & Tier Management</h5>
                </div>
                <div class="card-body p-4 bg-white text-dark">
                    <asp:PlaceHolder ID="phNoMainCategory" runat="server" Visible="false">
                        <div class="alert alert-info border-0 shadow-sm rounded-lg mb-4" style="background-color: #eff6ff; color: #1e3a8a;">
                            <h5><i class="fas fa-info-circle mr-2"></i> No Main Category Configured</h5>
                            As an administrator, you must first define and own exactly one Main Category (e.g. <strong>HR</strong>, <strong>Cook</strong>, <strong>Driver</strong>, etc.).
                        </div>
                        <div class="form-group mb-3">
                            <label class="form-label font-weight-bold text-gray-800">Main Category Name:</label>
                            <div class="input-group">
                                <asp:TextBox ID="txtMainCategoryName" runat="server" CssClass="form-control" placeholder="e.g. HR" MaxLength="100"></asp:TextBox>
                                <div class="input-group-append">
                                    <asp:Button ID="btnCreateMainCategory" runat="server" Text="Create Main Category" CssClass="btn btn-primary px-4" OnClick="btnCreateMainCategory_Click" style="background-color: #4f46e5; border-color: #4f46e5;" />
                                </div>
                            </div>
                        </div>
                    </asp:PlaceHolder>

                    <asp:HiddenField ID="hfSuperAdminSelectedMCId" runat="server" />
                    <asp:PlaceHolder ID="phMainCategoryOwned" runat="server" Visible="false">
                        <div class="mb-3">
                            <asp:DropDownList ID="ddlAdminSelectCategory" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlAdminSelectCategory_SelectedIndexChanged" CssClass="form-control font-weight-bold" Visible="false" style="max-width: 400px; border-radius: 6px; border-color: #6366f1;">
                            </asp:DropDownList>
                        </div>
                        <div class="d-flex justify-content-between align-items-center mb-4 pb-3 border-bottom">
                            <div>
                                <span class="text-muted" style="font-size: 0.85rem; font-weight: 600;">SELECTED MAIN CATEGORY</span>
                                <h4 class="font-weight-bold text-indigo mb-0">
                                    <asp:Label ID="lblMainCategoryDisplay" runat="server" Text="HR"></asp:Label>
                                </h4>
                            </div>
                            <div>
                                <asp:PlaceHolder ID="btnRenameMCTrigger" runat="server">
                                    <button type="button" class="btn btn-sm btn-outline-secondary font-weight-bold px-3" onclick="$('#divRenameMC').slideToggle();">
                                        <i class="fas fa-edit mr-1"></i> Rename Category
                                    </button>
                                </asp:PlaceHolder>
                                <asp:LinkButton ID="btnSuperAdminCloseEditor" runat="server" CssClass="btn btn-sm btn-secondary font-weight-bold px-3 ml-2" OnClick="btnSuperAdminCloseEditor_Click" Visible="false">
                                    <i class="fas fa-times-circle mr-1"></i> Close Editor
                                </asp:LinkButton>
                            </div>
                        </div>

                        <div id="divRenameMC" style="display:none;" class="card border p-3 mb-4 bg-light">
                            <label class="form-label font-weight-bold text-gray-800">New Main Category Name:</label>
                            <div class="input-group">
                                <asp:TextBox ID="txtRenameMC" runat="server" CssClass="form-control" MaxLength="100"></asp:TextBox>
                                <div class="input-group-append">
                                    <asp:Button ID="btnRenameMC" runat="server" Text="Rename" CssClass="btn btn-success px-4" OnClick="btnRenameMC_Click" />
                                </div>
                            </div>
                        </div>

                        <!-- Add Tier Form -->
                        <asp:PlaceHolder ID="pnlAddTierForm" runat="server">
                            <h5 class="font-weight-bold text-gray-800 mb-3"><i class="fas fa-layer-group mr-1 text-primary"></i> Add Sub-Category Tier</h5>
                            <div class="row mb-4">
                                <div class="col-md-5 mb-2">
                                    <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.85rem;">Tier Name (Required):</label>
                                    <asp:TextBox ID="txtNewTierName" runat="server" CssClass="form-control form-control-sm" placeholder="e.g. Skilled" MaxLength="100"></asp:TextBox>
                                </div>
                                <div class="col-md-5 mb-2">
                                    <label class="form-label font-weight-bold text-gray-800" style="font-size: 0.85rem;">Role Label (Optional):</label>
                                    <asp:TextBox ID="txtNewRoleLabel" runat="server" CssClass="form-control form-control-sm" placeholder="e.g. Office Assistant" MaxLength="100"></asp:TextBox>
                                </div>
                                <div class="col-md-2 mb-2 d-flex align-items-end">
                                    <asp:Button ID="btnAddTier" runat="server" Text="Add Tier" CssClass="btn btn-primary btn-sm btn-block font-weight-bold" OnClick="btnAddTier_Click" style="background-color: #4f46e5; border-color: #4f46e5; height: 31px;" />
                                </div>
                            </div>
                        </asp:PlaceHolder>

                        <!-- Tiers GridView -->
                        <div class="table-responsive">
                            <asp:GridView ID="gvTiers" runat="server" AutoGenerateColumns="False" 
                                          CssClass="table table-bordered table-hover table-custom-settings mb-0" 
                                          DataKeyNames="Id" 
                                          OnRowEditing="gvTiers_RowEditing" 
                                          OnRowCancelingEdit="gvTiers_RowCancelingEdit" 
                                          OnRowUpdating="gvTiers_RowUpdating" 
                                          OnRowDeleting="gvTiers_RowDeleting" 
                                          OnRowDataBound="gvTiers_RowDataBound"
                                          OnRowCommand="gvTiers_RowCommand"
                                          GridLines="None">
                                <Columns>
                                    <asp:TemplateField HeaderText="Sort Order" ItemStyle-CssClass="text-center align-middle" HeaderStyle-CssClass="text-center" ItemStyle-Width="140px">
                                        <ItemTemplate>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <span class="badge badge-light border text-dark font-weight-bold mr-2" style="font-size: 0.85rem; padding: 4px 8px;" title="Current Sort Position">
                                                    #<%# Container.DataItemIndex + 1 %>
                                                </span>
                                                <asp:LinkButton ID="btnMoveUp" runat="server" CommandName="MoveUp" CommandArgument='<%# Eval("Id") %>' 
                                                                CssClass="btn btn-sm btn-outline-secondary py-0 px-2" Title="Move Up" style="border-radius: 4px;">
                                                    <i class="fas fa-arrow-up text-primary"></i>
                                                </asp:LinkButton>
                                                <asp:LinkButton ID="btnMoveDown" runat="server" CommandName="MoveDown" CommandArgument='<%# Eval("Id") %>' 
                                                                CssClass="btn btn-sm btn-outline-secondary py-0 px-2" Title="Move Down" style="border-radius: 4px;">
                                                    <i class="fas fa-arrow-down text-primary"></i>
                                                </asp:LinkButton>
                                            </div>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:TextBox ID="txtSortOrder" runat="server" Text='<%# Bind("SortOrder") %>' CssClass="form-control form-control-sm text-center" TextMode="Number" style="width: 70px; margin: 0 auto;"></asp:TextBox>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Tier Name">
                                        <ItemTemplate>
                                            <asp:Label ID="lblTierName" runat="server" Text='<%# Eval("TierName") %>' Font-Bold="true"></asp:Label>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:TextBox ID="txtTierName" runat="server" Text='<%# Bind("TierName") %>' CssClass="form-control form-control-sm" MaxLength="100"></asp:TextBox>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Role Label">
                                        <ItemTemplate>
                                            <asp:Label ID="lblRoleLabel" runat="server" Text='<%# Eval("RoleLabel") ?? "None" %>' CssClass='<%# Eval("RoleLabel") == DBNull.Value ? "text-muted font-italic" : "" %>'></asp:Label>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:TextBox ID="txtRoleLabel" runat="server" Text='<%# Bind("RoleLabel") %>' CssClass="form-control form-control-sm" MaxLength="100"></asp:TextBox>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Actions" ItemStyle-CssClass="action-column">
                                        <ItemTemplate>
                                            <div class="d-flex justify-content-center gap-2">
                                                <asp:LinkButton ID="btnEditTier" runat="server" CommandName="Edit" CssClass="btn btn-sm btn-outline-primary py-1 px-2">
                                                    <i class="fas fa-edit"></i> Edit
                                                </asp:LinkButton>
                                                <asp:LinkButton ID="btnDeleteTier" runat="server" CommandName="Delete" CssClass="btn btn-sm btn-outline-danger py-1 px-2" 
                                                                OnClientClick='<%# "return confirmDelete(this, \"" + Eval("TierName") + "\", \"tier\");" %>'>
                                                    <i class="fas fa-trash"></i> Delete
                                                </asp:LinkButton>
                                            </div>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <div class="d-flex justify-content-center gap-2">
                                                <asp:LinkButton ID="btnUpdateTier" runat="server" CommandName="Update" CssClass="btn btn-sm btn-success py-1 px-2">
                                                    <i class="fas fa-check"></i> Save
                                                </asp:LinkButton>
                                                <asp:LinkButton ID="btnCancelTier" runat="server" CommandName="Cancel" CssClass="btn btn-sm btn-secondary py-1 px-2">
                                                    <i class="fas fa-times"></i> Cancel
                                                </asp:LinkButton>
                                            </div>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                                <EmptyDataTemplate>
                                    <div class="text-center p-3 text-muted">
                                        No tiers defined for this category. Add at least one tier above.
                                    </div>
                                </EmptyDataTemplate>
                            </asp:GridView>
                        </div>
                    </asp:PlaceHolder>

                    <asp:PlaceHolder ID="phSuperAdminCategories" runat="server" Visible="false">
                        <div class="alert alert-primary border-0 shadow-sm rounded-lg mb-4" style="background-color: #eff6ff; color: #1e3a8a;">
                            <h5><i class="fas fa-crown mr-2"></i> Global Category Directory</h5>
                            As a Super Administrator, you have full read access to all configured Main Categories and their respective Tiers in the system.
                        </div>
                        <div class="table-responsive">
                            <asp:GridView ID="gvGlobalCategories" runat="server" AutoGenerateColumns="False" 
                                          CssClass="table table-bordered table-hover table-custom-settings mb-0" 
                                          DataKeyNames="Id" OnRowCommand="gvGlobalCategories_Command" GridLines="None">
                                <Columns>
                                    <asp:BoundField DataField="MainCategoryName" HeaderText="Main Category" ItemStyle-Font-Bold="true" />
                                    <asp:BoundField DataField="AdminName" HeaderText="Owner Admin" />
                                    <asp:BoundField DataField="TiersList" HeaderText="Configured Tiers" NullDisplayText="None" />
                                    <asp:TemplateField HeaderText="Actions" ItemStyle-CssClass="text-center align-middle" HeaderStyle-CssClass="text-center">
                                        <ItemTemplate>
                                            <asp:LinkButton ID="btnConfigureCategory" runat="server" CommandName="ConfigureMC" CommandArgument='<%# Eval("Id") %>' CssClass="btn btn-sm btn-outline-primary py-1 px-3 font-weight-bold" style="border-radius: 4px;">
                                                <i class="fas fa-cog mr-1"></i> Edit & Manage Tiers
                                            </asp:LinkButton>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                                <EmptyDataTemplate>
                                    <div class="text-center p-3 text-muted">
                                        No Main Categories configured in the system.
                                    </div>
                                </EmptyDataTemplate>
                            </asp:GridView>
                        </div>
                    </asp:PlaceHolder>
                </div>
            </div>



            <!-- Undo Manager Panel -->
            <div id="panel-undo" class="card shadow-sm border-0 rounded-lg" style="display:none;">
                <div class="card-header py-3 text-white card-header-gradient">
                    <h5 class="m-0 font-weight-bold"><i class="fas fa-undo mr-2"></i> Undo Manager</h5>
                </div>
                <div class="card-body p-4 bg-white text-dark">
                    <div class="alert alert-info border-0 shadow-sm rounded-lg d-flex align-items-center mb-4" style="background-color: #f0fdf4; color: #166534;">
                        <i class="fas fa-info-circle mr-3 fa-lg" style="color: #15803d;"></i>
                        <div>
                            <strong>Sequential Rollbacks:</strong> Undoing an action on an employee with subsequent active changes will automatically prompt and roll back all linked actions in reverse chronological order.
                        </div>
                    </div>
                    <div class="table-responsive">
                        <asp:GridView ID="gvActionLogs" runat="server" AutoGenerateColumns="False" 
                                      CssClass="table table-bordered table-hover table-custom-settings mb-0" 
                                      DataKeyNames="Id" 
                                      OnRowCommand="gvActionLogs_RowCommand"
                                      GridLines="None">
                            <Columns>
                                <asp:BoundField DataField="ActionTime" HeaderText="Time" DataFormatString="{0:yyyy-MM-dd HH:mm:ss}" />
                                <asp:BoundField DataField="ActionType" HeaderText="Action" ItemStyle-Font-Bold="true" />
                                <asp:BoundField DataField="Description" HeaderText="Description" />
                                <asp:TemplateField HeaderText="Status">
                                    <ItemTemplate>
                                        <asp:Label ID="lblStatus" runat="server" 
                                                   Text='<%# Convert.ToInt32(Eval("IsUndone")) == 1 ? "Undone" : "Active" %>' 
                                                   CssClass='<%# Convert.ToInt32(Eval("IsUndone")) == 1 ? "badge badge-secondary py-1 px-2" : "badge badge-success py-1 px-2" %>' />
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Actions" ItemStyle-CssClass="action-column">
                                    <ItemTemplate>
                                        <asp:LinkButton ID="btnUndo" runat="server" 
                                                        CommandName="UndoCommand" 
                                                        CommandArgument='<%# Eval("Id") %>' 
                                                        CssClass="btn btn-sm btn-outline-danger py-1 px-2" 
                                                        Visible='<%# Convert.ToInt32(Eval("IsUndone")) == 0 %>'
                                                        OnClientClick='<%# "return confirmUndo(this, \"" + Eval("Description") + "\");" %>'>
                                            <i class="fas fa-undo"></i> Undo
                                        </asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                            <EmptyDataTemplate>
                                <div class="text-center p-3 text-muted">
                                    No changes logged recently.
                                </div>
                            </EmptyDataTemplate>
                        </asp:GridView>
                    </div>
                </div>
            </div>
            
            <!-- Backup & Restore Panel -->
            <div id="panel-backup" class="card shadow-sm border-0 rounded-lg" style="display:none;">
                <div class="card-header py-3 text-white card-header-gradient">
                    <h5 class="m-0 font-weight-bold"><i class="fas fa-database mr-2"></i> Database Backup & Restore</h5>
                </div>
                <div class="card-body p-4 bg-white text-dark">
                    <div class="row">
                        <!-- Export Column -->
                        <div class="col-md-6 mb-4">
                            <div class="card h-100 border shadow-sm">
                                <div class="card-body d-flex flex-column justify-content-between">
                                    <div>
                                        <h5 class="card-title font-weight-bold text-primary"><i class="fas fa-download mr-2"></i> Export Database</h5>
                                        <p class="card-text text-muted">
                                            Download a complete backup of the database containing all current dynamic data (employees, attendance records, leave history, contracts, vendors, action logs, settings, etc.) as a single JSON file.
                                        </p>
                                    </div>
                                    <div class="mt-4">
                                        <asp:Button ID="btnExportBackup" runat="server" Text="Export & Download Backup" CssClass="btn btn-primary btn-block font-weight-bold py-2" OnClick="btnExportBackup_Click" style="background-color: #4f46e5; border-color: #4f46e5;" />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Restore Column -->
                        <div class="col-md-6 mb-4">
                            <div class="card h-100 border shadow-sm">
                                <div class="card-body d-flex flex-column justify-content-between">
                                    <div>
                                        <h5 class="card-title font-weight-bold text-danger"><i class="fas fa-upload mr-2"></i> Restore Database</h5>
                                        <p class="card-text text-muted">
                                            Upload a previously exported database JSON backup file to restore the entire system state. 
                                        </p>
                                        <div class="alert alert-warning border-0 p-2 rounded-lg d-flex align-items-start mb-3" style="background-color: #fffbeb; color: #b45309; font-size: 0.875rem;">
                                            <i class="fas fa-exclamation-triangle mr-2 mt-1"></i>
                                            <div>
                                                <strong>WARNING:</strong> This action will permanently erase all existing database records and replace them with the data from the backup file.
                                            </div>
                                        </div>
                                        <div class="form-group mb-0">
                                            <label for="fuBackupFile" class="font-weight-bold text-muted" style="font-size: 0.85rem;">Select JSON Backup File</label>
                                            <asp:FileUpload ID="fuBackupFile" runat="server" CssClass="form-control-file border p-2 rounded bg-light" />
                                        </div>
                                    </div>
                                    <div class="mt-4">
                                        <asp:Button ID="btnRestoreBackup" runat="server" Text="Restore Database" CssClass="btn btn-danger btn-block font-weight-bold py-2" OnClick="btnRestoreBackup_Click" OnClientClick="return confirmRestore(this);" />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- POC View & Edit Window Settings Panel -->
            <div id="panel-editwindow" class="card shadow-sm border-0 rounded-lg" style="display:none;">
                <div class="card-header py-3 text-white card-header-gradient" style="background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%); border-radius: 8px 8px 0 0;">
                    <h5 class="m-0 font-weight-bold"><i class="fas fa-user-lock mr-2"></i> POC View & Edit Permissions Settings</h5>
                </div>
                <div class="card-body p-4 bg-white text-dark">
                    <p class="text-muted mb-4" style="font-size: 0.9rem;">
                        Configure past attendance editing rules and historical month visibility for Regular Users (POCs).
                        <br /><strong>1. Past Edit Window:</strong> Controls how far back POCs can modify attendance cells (Past X Days vs Current Month Only).
                        <br /><strong>2. Viewable Data Scope:</strong> Controls how many historical months POCs can see in Attendance and/or Ledger pages.
                    </p>

                    <%-- Category Admin Panel (Role = 1) --%>
                    <asp:Panel ID="pnlCategoryAdminEditDays" runat="server" Visible="false">
                        <div class="card bg-light border mb-4">
                            <div class="card-body">
                                <h6 class="font-weight-bold text-dark mb-3"><i class="fas fa-user-shield text-info mr-2"></i> Your Category View & Edit Settings</h6>
                                <asp:Repeater ID="rptCategoryEditDays" runat="server" OnItemDataBound="rptCategoryEditDays_ItemDataBound" OnItemCommand="rptCategoryEditDays_ItemCommand">
                                    <ItemTemplate>
                                        <div class="card bg-white border rounded-lg shadow-sm mb-4 p-3 poc-cat-settings-card" style="border-left: 4px solid #0284c7 !important;">
                                            <div class="d-flex justify-content-between align-items-center mb-3 pb-2 border-bottom flex-wrap" style="gap: 10px;">
                                                <h6 class="m-0 font-weight-bold text-dark" style="font-size: 1.05rem;">
                                                    <i class="fas fa-layer-group text-primary mr-1"></i> Category: <span class="text-primary"><%# Eval("Name") %></span>
                                                </h6>
                                                <div>
                                                    <asp:HiddenField ID="hfCatId" runat="server" Value='<%# Eval("Id") %>' />
                                                    <asp:Button ID="btnSaveCatDays" runat="server" Text="Save Settings" CommandName="SaveEditDays" CssClass="btn btn-info font-weight-bold px-4 shadow-sm" style="background-color: #0284c7; border-color: #0284c7; border-radius: 6px;" />
                                                </div>
                                            </div>

                                            <div class="row">
                                                <!-- Section 1: Past Attendance Edit Window -->
                                                <div class="col-lg-6 border-right pr-lg-4 mb-3 mb-lg-0">
                                                    <div class="p-2 rounded bg-light border mb-3">
                                                        <span class="font-weight-bold text-dark" style="font-size: 0.88rem;">
                                                            <i class="fas fa-calendar-check text-success mr-1"></i> 1. Past Attendance Edit Window
                                                        </span>
                                                        <div class="text-muted" style="font-size: 0.78rem;">Limit how many days in the past POCs can enter/edit attendance.</div>
                                                    </div>
                                                    <div class="form-group mb-2">
                                                        <label class="font-weight-bold text-gray-800" style="font-size: 0.85rem;">Edit Window Rule:</label>
                                                        <asp:DropDownList ID="ddlEditMode" runat="server" CssClass="form-control font-weight-bold edit-mode-select" onchange="toggleEditModeRow(this)" style="border-radius: 6px;">
                                                            <asp:ListItem Value="0">Days Window (Past X Days)</asp:ListItem>
                                                            <asp:ListItem Value="1">Current Month Only (Till Date)</asp:ListItem>
                                                            <asp:ListItem Value="2">Current Month & Prev Month (Till Nth Date of Current Month)</asp:ListItem>
                                                        </asp:DropDownList>
                                                    </div>
                                                    <div class="form-group mb-0 edit-days-wrapper">
                                                        <label class="font-weight-bold text-gray-800 edit-days-label" style="font-size: 0.85rem;">Past Days Allowed (0 - 31):</label>
                                                        <div class="input-group">
                                                            <asp:TextBox ID="txtEditDays" runat="server" Text='<%# Eval("EditDaysAllowed") %>' CssClass="form-control font-weight-bold edit-days-input" TextMode="Number" min="0" max="31" style="border-radius: 6px 0 0 6px;"></asp:TextBox>
                                                            <div class="input-group-append">
                                                                <span class="input-group-text font-weight-bold edit-days-suffix" style="border-radius: 0 6px 6px 0;">Days</span>
                                                            </div>
                                                        </div>
                                                        <small class="text-muted edit-days-help d-block mt-1" style="font-size: 0.76rem;"></small>
                                                    </div>
                                                </div>

                                                <!-- Section 2: POC Viewable Months / Data Window -->
                                                <div class="col-lg-6 pl-lg-4">
                                                    <div class="p-2 rounded bg-light border mb-3">
                                                        <span class="font-weight-bold text-dark" style="font-size: 0.88rem;">
                                                            <i class="fas fa-eye text-primary mr-1"></i> 2. POC Viewable Month / Data Window
                                                        </span>
                                                        <div class="text-muted" style="font-size: 0.78rem;">Limit which historical months POCs can see.</div>
                                                    </div>
                                                    <div class="form-group mb-2">
                                                        <label class="font-weight-bold text-gray-800" style="font-size: 0.85rem;">Viewable Months Scope:</label>
                                                        <asp:DropDownList ID="ddlViewMode" runat="server" CssClass="form-control font-weight-bold view-mode-select" onchange="toggleViewModeRow(this)" style="border-radius: 6px;">
                                                            <asp:ListItem Value="0">All Months (Unrestricted)</asp:ListItem>
                                                            <asp:ListItem Value="1">Current Month Only</asp:ListItem>
                                                            <asp:ListItem Value="2">Current & Previous Month (Last N Months)</asp:ListItem>
                                                            <asp:ListItem Value="3">This Contract Period (Active Contract)</asp:ListItem>
                                                            <asp:ListItem Value="4">From Specific Month Onwards (Cutoff Date)</asp:ListItem>
                                                        </asp:DropDownList>
                                                    </div>
                                                    
                                                    <!-- Dynamic Input: Months Count (for Mode 2) -->
                                                    <div class="form-group mb-2 view-months-wrapper" style="display:none;">
                                                        <label class="font-weight-bold text-gray-800" style="font-size: 0.85rem;">Number of Past Months (e.g. 2 for current + 1 prev):</label>
                                                        <div class="input-group">
                                                            <asp:TextBox ID="txtViewMonths" runat="server" Text='<%# Eval("ViewMonthsAllowed") != DBNull.Value ? Eval("ViewMonthsAllowed") : "2" %>' CssClass="form-control font-weight-bold" TextMode="Number" min="1" max="60" style="border-radius: 6px 0 0 6px;"></asp:TextBox>
                                                            <div class="input-group-append">
                                                                <span class="input-group-text font-weight-bold" style="border-radius: 0 6px 6px 0;">Months</span>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <!-- Dynamic Input: Cutoff Date / Start Month (for Mode 4) -->
                                                    <div class="form-group mb-2 view-cutoff-wrapper" style="display:none;">
                                                        <label class="font-weight-bold text-gray-800" style="font-size: 0.85rem;">Cutoff Start Date / Month:</label>
                                                        <asp:TextBox ID="txtViewCutoffDate" runat="server" Text='<%# Eval("ViewCutoffDate") != DBNull.Value && Eval("ViewCutoffDate") != null ? Convert.ToDateTime(Eval("ViewCutoffDate")).ToString("yyyy-MM-dd") : "" %>' CssClass="form-control font-weight-bold" TextMode="Date" style="border-radius: 6px;"></asp:TextBox>
                                                        <small class="text-muted">POCs will only see data from this month onwards (e.g. 2026-06-01 for June 2026).</small>
                                                    </div>

                                                    <!-- Target Pages / Applies To -->
                                                    <div class="form-group mb-0 view-applies-wrapper">
                                                        <label class="font-weight-bold text-gray-800" style="font-size: 0.85rem;">Restriction Applies To:</label>
                                                        <asp:DropDownList ID="ddlViewAppliesTo" runat="server" CssClass="form-control font-weight-bold" style="border-radius: 6px;">
                                                            <asp:ListItem Value="0">Both Attendance & Ledger Pages</asp:ListItem>
                                                            <asp:ListItem Value="1">Attendance Page Only</asp:ListItem>
                                                            <asp:ListItem Value="2">Ledger Page Only</asp:ListItem>
                                                        </asp:DropDownList>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </div>
                    </asp:Panel>

                    <%-- Super Admin Panel (Role = 4) --%>
                    <asp:Panel ID="pnlSuperAdminEditDays" runat="server" Visible="false">
                        <h6 class="font-weight-bold text-dark mb-3"><i class="fas fa-crown text-warning mr-2"></i> All Category Admins & Edit/View Permissions</h6>
                        <div class="table-responsive">
                            <asp:GridView ID="gvAllCategoryEditDays" runat="server" AutoGenerateColumns="False" 
                                          CssClass="table table-bordered table-hover table-custom-settings mb-0" 
                                          DataKeyNames="Id" 
                                          OnRowDataBound="gvAllCategoryEditDays_RowDataBound"
                                          OnRowEditing="gvAllCategoryEditDays_RowEditing" 
                                          OnRowCancelingEdit="gvAllCategoryEditDays_RowCancelingEdit" 
                                          OnRowUpdating="gvAllCategoryEditDays_RowUpdating" 
                                          GridLines="None">
                                <Columns>
                                    <asp:TemplateField HeaderText="Main Category">
                                        <ItemTemplate>
                                            <asp:Label ID="lblCatName" runat="server" Text='<%# Eval("Name") %>' Font-Bold="true"></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Category Admin">
                                        <ItemTemplate>
                                            <asp:Label ID="lblAdminName" runat="server" Text='<%# FormatAdminDisplay(Eval("AdminName"), Eval("AdminPCNO")) %>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Edit Window Rule">
                                        <ItemTemplate>
                                            <%# FormatEditModeDisplay(Eval("EditMode"), Eval("EditDaysAllowed")) %>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <div class="d-flex align-items-center" style="gap: 8px;">
                                                <asp:DropDownList ID="ddlEditMode" runat="server" CssClass="form-control form-control-sm font-weight-bold edit-mode-select" onchange="toggleEditModeRow(this)" style="max-width: 220px; border-radius: 6px;">
                                                    <asp:ListItem Value="0">Days Window</asp:ListItem>
                                                    <asp:ListItem Value="1">Current Month (Till Date)</asp:ListItem>
                                                    <asp:ListItem Value="2">Current + Prev Month (Till Nth)</asp:ListItem>
                                                </asp:DropDownList>
                                                <div class="input-group input-group-sm edit-days-wrapper" style="max-width: 130px;">
                                                    <asp:TextBox ID="txtEditDaysAllowed" runat="server" Text='<%# Bind("EditDaysAllowed") %>' CssClass="form-control text-center font-weight-bold edit-days-input" TextMode="Number" min="0" max="31" style="border-radius: 6px 0 0 6px;"></asp:TextBox>
                                                    <div class="input-group-append">
                                                        <span class="input-group-text font-weight-bold edit-days-suffix" style="border-radius: 0 6px 6px 0;">Days</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Viewable Months Scope">
                                        <ItemTemplate>
                                            <%# FormatViewModeDisplay(Eval("ViewMode"), Eval("ViewMonthsAllowed"), Eval("ViewCutoffDate")) %>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <div class="d-flex flex-column" style="gap: 6px;">
                                                <asp:DropDownList ID="ddlViewMode" runat="server" CssClass="form-control form-control-sm font-weight-bold view-mode-select" onchange="toggleViewModeRow(this)" style="border-radius: 6px;">
                                                    <asp:ListItem Value="0">All Months (Unrestricted)</asp:ListItem>
                                                    <asp:ListItem Value="1">Current Month Only</asp:ListItem>
                                                    <asp:ListItem Value="2">Current & Previous (Last N Months)</asp:ListItem>
                                                    <asp:ListItem Value="3">This Contract Period</asp:ListItem>
                                                    <asp:ListItem Value="4">From Specific Month</asp:ListItem>
                                                </asp:DropDownList>
                                                <div class="input-group input-group-sm view-months-wrapper" style="display:none; max-width: 140px;">
                                                    <asp:TextBox ID="txtViewMonthsAllowed" runat="server" Text='<%# Bind("ViewMonthsAllowed") %>' CssClass="form-control text-center font-weight-bold" TextMode="Number" min="1" max="60" style="border-radius: 6px 0 0 6px;"></asp:TextBox>
                                                    <div class="input-group-append">
                                                        <span class="input-group-text font-weight-bold" style="border-radius: 0 6px 6px 0;">Mos</span>
                                                    </div>
                                                </div>
                                                <div class="view-cutoff-wrapper" style="display:none;">
                                                    <asp:TextBox ID="txtViewCutoffDate" runat="server" Text='<%# Eval("ViewCutoffDate") != DBNull.Value && Eval("ViewCutoffDate") != null ? Convert.ToDateTime(Eval("ViewCutoffDate")).ToString("yyyy-MM-dd") : "" %>' CssClass="form-control form-control-sm font-weight-bold" TextMode="Date" style="border-radius: 6px;"></asp:TextBox>
                                                </div>
                                            </div>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Applies To">
                                        <ItemTemplate>
                                            <%# FormatViewAppliesToDisplay(Eval("ViewAppliesTo")) %>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:DropDownList ID="ddlViewAppliesTo" runat="server" CssClass="form-control form-control-sm font-weight-bold" style="border-radius: 6px;">
                                                <asp:ListItem Value="0">Both Pages</asp:ListItem>
                                                <asp:ListItem Value="1">Attendance Only</asp:ListItem>
                                                <asp:ListItem Value="2">Ledger Only</asp:ListItem>
                                            </asp:DropDownList>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Actions" ItemStyle-CssClass="action-column text-center">
                                        <ItemTemplate>
                                            <asp:LinkButton ID="btnEdit" runat="server" CommandName="Edit" CssClass="btn btn-sm btn-outline-info py-1 px-3" style="border-radius: 6px;" ToolTip="Edit Settings">
                                                <i class="fas fa-edit"></i> Edit
                                            </asp:LinkButton>
                                        </ItemTemplate>
                                        <EditItemTemplate>
                                            <asp:LinkButton ID="btnUpdate" runat="server" CommandName="Update" CssClass="btn btn-sm btn-success py-1 px-2 mr-1" style="border-radius: 6px;" ToolTip="Save Changes">
                                                <i class="fas fa-check"></i> Save
                                            </asp:LinkButton>
                                            <asp:LinkButton ID="btnCancel" runat="server" CommandName="Cancel" CssClass="btn btn-sm btn-secondary py-1 px-2" style="border-radius: 6px;" ToolTip="Cancel">
                                                <i class="fas fa-times"></i> Cancel
                                            </asp:LinkButton>
                                        </EditItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                        </div>
                    </asp:Panel>
                </div>
            </div>
        </div>
    </div>

    <script>
        function toggleEditModeRow(selectEl) {
            if (!selectEl) return;
            var container = selectEl.closest('.form-group') || selectEl.closest('div.d-flex') || selectEl.closest('.col-lg-6') || selectEl.closest('td') || selectEl.closest('.poc-cat-settings-card');
            if (!container) return;
            var daysGroup = container.querySelector('.edit-days-wrapper') || (container.parentElement ? container.parentElement.querySelector('.edit-days-wrapper') : null);
            var labelEl = container.querySelector('.edit-days-label') || (container.parentElement ? container.parentElement.querySelector('.edit-days-label') : null);
            var suffixEl = container.querySelector('.edit-days-suffix') || (container.parentElement ? container.parentElement.querySelector('.edit-days-suffix') : null);
            var helpEl = container.querySelector('.edit-days-help') || (container.parentElement ? container.parentElement.querySelector('.edit-days-help') : null);
            var inputEl = container.querySelector('.edit-days-input') || (daysGroup ? daysGroup.querySelector('input') : null);

            if (daysGroup) {
                if (selectEl.value === '1') {
                    daysGroup.style.display = 'none';
                    if (helpEl) helpEl.style.display = 'none';
                } else if (selectEl.value === '2') {
                    daysGroup.style.display = selectEl.closest('.form-group') ? 'block' : 'flex';
                    if (labelEl) labelEl.innerText = "Prev Month Grace Cutoff Day (1 - 31):";
                    if (suffixEl) suffixEl.innerText = "Day of Month";
                    if (helpEl) {
                        helpEl.innerText = "Previous month remains editable until this date of the current month (e.g. 3 = open till 3rd).";
                        helpEl.style.display = 'block';
                    }
                    if (inputEl) {
                        inputEl.min = "1";
                        inputEl.max = "31";
                        if (!inputEl.value || inputEl.value === "0") inputEl.value = "3";
                    }
                } else {
                    daysGroup.style.display = selectEl.closest('.form-group') ? 'block' : 'flex';
                    if (labelEl) labelEl.innerText = "Past Days Allowed (0 - 30):";
                    if (suffixEl) suffixEl.innerText = "Days";
                    if (helpEl) {
                        helpEl.innerText = "POCs can edit attendance for this number of days prior to today.";
                        helpEl.style.display = 'block';
                    }
                    if (inputEl) {
                        inputEl.min = "0";
                        inputEl.max = "30";
                    }
                }
            }
        }

        function toggleViewModeRow(selectEl) {
            if (!selectEl) return;
            var container = selectEl.closest('.col-lg-6') || selectEl.closest('div.d-flex') || selectEl.closest('td') || selectEl.closest('.poc-cat-settings-card');
            if (!container) return;
            var monthsGroup = container.querySelector('.view-months-wrapper');
            var cutoffGroup = container.querySelector('.view-cutoff-wrapper');
            var val = selectEl.value;

            if (monthsGroup) {
                monthsGroup.style.display = (val === '2') ? (selectEl.closest('td') ? 'flex' : 'block') : 'none';
            }
            if (cutoffGroup) {
                cutoffGroup.style.display = (val === '4') ? 'block' : 'none';
            }
        }

        function initEditModeToggles() {
            var editSelects = document.querySelectorAll('.edit-mode-select');
            editSelects.forEach(function(sel) {
                toggleEditModeRow(sel);
            });
            var viewSelects = document.querySelectorAll('.view-mode-select');
            viewSelects.forEach(function(sel) {
                toggleViewModeRow(sel);
            });
        }

        document.addEventListener('DOMContentLoaded', initEditModeToggles);

        let deleteTarget = null;
        function confirmDelete(sender, name, type) {
            if (deleteTarget === sender) {
                deleteTarget = null;
                return true; // Allow postback
            }
            
            Swal.fire({
                title: 'Delete Confirmation',
                text: `Are you sure you want to delete the ${type} '${name}'? This action cannot be undone.`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#ef4444',
                cancelButtonColor: '#64748b',
                confirmButtonText: 'Yes, delete it!',
                cancelButtonText: 'Cancel',
                customClass: {
                    popup: 'shadow-lg rounded-lg border-0 bg-white text-dark',
                    title: 'font-weight-bold text-dark',
                    confirmButton: 'btn btn-danger font-weight-bold px-4 py-2',
                    cancelButton: 'btn btn-secondary font-weight-bold px-4 py-2 ml-2'
                },
                buttonsStyling: false
            }).then((result) => {
                if (result.isConfirmed) {
                    deleteTarget = sender;
                    sender.click(); // Re-trigger the click event
                }
            });
            
            return false; // Block immediate postback
        }

        let undoTarget = null;
        function confirmUndo(sender, desc) {
            if (undoTarget === sender) {
                undoTarget = null;
                return true; // Allow postback
            }
            
            Swal.fire({
                title: 'Undo Confirmation',
                text: `Are you sure you want to undo: "${desc}"? This will roll back the change and any subsequent active changes for this employee in reverse order.`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#ef4444',
                cancelButtonColor: '#64748b',
                confirmButtonText: 'Yes, Undo!',
                cancelButtonText: 'Cancel',
                customClass: {
                    popup: 'shadow-lg rounded-lg border-0 bg-white text-dark',
                    title: 'font-weight-bold text-dark',
                    confirmButton: 'btn btn-danger font-weight-bold px-4 py-2',
                    cancelButton: 'btn btn-secondary font-weight-bold px-4 py-2 ml-2'
                },
                buttonsStyling: false
            }).then((result) => {
                if (result.isConfirmed) {
                    undoTarget = sender;
                    sender.click(); // Re-trigger the click event
                }
            });
            
            return false; // Block immediate postback
        }

        let restoreTarget = null;
        function confirmRestore(sender) {
            if (restoreTarget === sender) {
                restoreTarget = null;
                return true; // Allow postback
            }

            const fileUpload = document.getElementById('<%= fuBackupFile.ClientID %>');
            if (!fileUpload || !fileUpload.files || fileUpload.files.length === 0) {
                Swal.fire({
                    title: 'No File Selected',
                    text: 'Please select a valid database JSON backup file before attempting to restore.',
                    icon: 'warning',
                    confirmButtonColor: '#4f46e5'
                });
                return false;
            }

            const fileName = fileUpload.files[0].name;
            if (!fileName.toLowerCase().endsWith('.json')) {
                Swal.fire({
                    title: 'Invalid File Format',
                    text: 'Only .json files are accepted for database restoration.',
                    icon: 'error',
                    confirmButtonColor: '#4f46e5'
                });
                return false;
            }

            Swal.fire({
                title: 'CRITICAL WARNING',
                html: 'This operation will <strong style="color: #dc2626;">permanently delete</strong> all current employees, attendance, contracts, and settings.<br/><br/>They will be overwritten with the backup file data. <strong>This action cannot be undone. Are you absolutely sure?</strong>',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc2626',
                cancelButtonColor: '#64748b',
                confirmButtonText: 'Yes, proceed',
                cancelButtonText: 'Cancel'
            }).then((result) => {
                if (result.isConfirmed) {
                    Swal.fire({
                        title: 'Final Confirmation',
                        html: 'To proceed, please type <strong style="color: #dc2626;">RESTORE</strong> below to confirm:',
                        input: 'text',
                        inputPlaceholder: 'RESTORE',
                        showCancelButton: true,
                        confirmButtonColor: '#dc2626',
                        cancelButtonColor: '#64748b',
                        confirmButtonText: 'Confirm Restore',
                        cancelButtonText: 'Cancel',
                        preConfirm: (inputValue) => {
                            if (inputValue !== 'RESTORE') {
                                Swal.showValidationMessage('You must type "RESTORE" exactly to confirm.');
                            }
                            return inputValue;
                        }
                    }).then((finalResult) => {
                        if (finalResult.isConfirmed && finalResult.value === 'RESTORE') {
                            restoreTarget = sender;
                            sender.click(); // Re-trigger postback
                        }
                    });
                }
            });

            return false; // Block immediate postback
        }

        function switchTab(tabName) {
            // Update hidden field value
            const hf = document.getElementById('hfActiveTab');
            if (hf) hf.value = tabName;
            
            // Remove active classes from all menu items
            document.querySelectorAll('#settings-menu a').forEach(el => {
                el.classList.remove('active', 'text-white');
                el.style.backgroundColor = '';
                
                const icon = el.querySelector('i');
                if (icon) {
                    // Reset colors of icons
                    if (el.id === 'tab-divisions') {
                        icon.className = 'fas fa-building mr-2 text-primary';
                    } else if (el.id === 'tab-categories') {
                        icon.className = 'fas fa-tags mr-2 text-success';
                    } else if (el.id === 'tab-wages') {
                        icon.className = 'fas fa-coins mr-2 text-success';
                    } else if (el.id === 'tab-editwindow') {
                        icon.className = 'fas fa-calendar-alt mr-2 text-info';
                    } else if (el.id === 'tab-undo') {
                        icon.className = 'fas fa-undo mr-2 text-danger';
                    } else if (el.id === 'tab-backup') {
                        icon.className = 'fas fa-database mr-2 text-warning';
                    }
                }
            });
            
            // Hide all panels
            const panelDiv = document.getElementById('panel-divisions');
            const panelCat = document.getElementById('panel-categories');
            const panelWages = document.getElementById('panel-wages');
            const panelEdit = document.getElementById('panel-editwindow');
            const panelUndo = document.getElementById('panel-undo');
            const panelBackup = document.getElementById('panel-backup');
            if (panelDiv) panelDiv.style.display = 'none';
            if (panelCat) panelCat.style.display = 'none';
            if (panelWages) panelWages.style.display = 'none';
            if (panelEdit) panelEdit.style.display = 'none';
            if (panelUndo) panelUndo.style.display = 'none';
            if (panelBackup) panelBackup.style.display = 'none';

            // Show selected panel & make menu item active
            if (tabName === 'divisions') {
                if (panelDiv) panelDiv.style.display = 'block';
                const menuEl = document.getElementById('tab-divisions');
                if (menuEl) {
                    menuEl.classList.add('active', 'text-white');
                    menuEl.style.backgroundColor = '#4f46e5';
                    const icon = menuEl.querySelector('i');
                    if (icon) icon.className = 'fas fa-building mr-2 text-white';
                }
            } else if (tabName === 'categories') {
                if (panelCat) panelCat.style.display = 'block';
                const menuEl = document.getElementById('tab-categories');
                if (menuEl) {
                    menuEl.classList.add('active', 'text-white');
                    menuEl.style.backgroundColor = '#4f46e5';
                    const icon = menuEl.querySelector('i');
                    if (icon) icon.className = 'fas fa-tags mr-2 text-white';
                }
            } else if (tabName === 'wages') {
                if (panelWages) panelWages.style.display = 'block';
                const menuEl = document.getElementById('tab-wages');
                if (menuEl) {
                    menuEl.classList.add('active', 'text-white');
                    menuEl.style.backgroundColor = '#4f46e5';
                    const icon = menuEl.querySelector('i');
                    if (icon) icon.className = 'fas fa-coins mr-2 text-white';
                }
            } else if (tabName === 'editwindow') {
                if (panelEdit) panelEdit.style.display = 'block';
                const menuEl = document.getElementById('tab-editwindow');
                if (menuEl) {
                    menuEl.classList.add('active', 'text-white');
                    menuEl.style.backgroundColor = '#4f46e5';
                    const icon = menuEl.querySelector('i');
                    if (icon) icon.className = 'fas fa-calendar-alt mr-2 text-white';
                }
            } else if (tabName === 'undo') {
                if (panelUndo) panelUndo.style.display = 'block';
                const menuEl = document.getElementById('tab-undo');
                if (menuEl) {
                    menuEl.classList.add('active', 'text-white');
                    menuEl.style.backgroundColor = '#4f46e5';
                    const icon = menuEl.querySelector('i');
                    if (icon) icon.className = 'fas fa-undo mr-2 text-white';
                }
            } else if (tabName === 'backup') {
                if (panelBackup) panelBackup.style.display = 'block';
                const menuEl = document.getElementById('tab-backup');
                if (menuEl) {
                    menuEl.classList.add('active', 'text-white');
                    menuEl.style.backgroundColor = '#4f46e5';
                    const icon = menuEl.querySelector('i');
                    if (icon) icon.className = 'fas fa-database mr-2 text-white';
                }
            }
        }
        
        // Initialize on page load
        document.addEventListener('DOMContentLoaded', function() {
            const urlParams = new URLSearchParams(window.location.search);
            const tabParam = urlParams.get('tab');
            const hf = document.getElementById('hfActiveTab');
            
            let activeTab = 'divisions';
            if (tabParam) {
                activeTab = tabParam.toLowerCase();
            } else if (hf && hf.value) {
                activeTab = hf.value;
            }
            switchTab(activeTab);
        });

        // Handle page reloads / postbacks (ASP.NET WebForms specific)
        if (typeof window.Sys !== 'undefined' && typeof window.Sys.WebForms !== 'undefined') {
            var prm = Sys.WebForms.PageRequestManager.getInstance();
            prm.add_endRequest(function() {
                const urlParams = new URLSearchParams(window.location.search);
                const tabParam = urlParams.get('tab');
                const hf = document.getElementById('hfActiveTab');
                
                let activeTab = 'divisions';
                if (tabParam) {
                    activeTab = tabParam.toLowerCase();
                } else if (hf && hf.value) {
                    activeTab = hf.value;
                }
                switchTab(activeTab);
            });
        }
    </script>
</asp:Content>
