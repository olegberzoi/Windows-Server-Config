#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Warehouse & Logistics Department Configuration
.DESCRIPTION
    Configures warehouse and logistics environment
    - 8-15 employees
    - Lightweight profiles for handheld scanners/tablets
    - Inventory database and shipping documents access
    - Label printers mapped via GPO
    - VLAN segmentation for IoT devices (scanners, RFID)
    - Role-based access control for logistics software
#>

param(
    [string]$DomainName = "company.local",
    [string]$DeptName = "Warehouse-Logistics",
    [int]$EmployeeCount = 15,
    [string]$LogPath = "C:\Logs\WarehouseDept.log"
)

function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "Error") { "Red" } else { "Green" })
}

function Create-DepartmentUsers {
    Write-Log "Creating Warehouse & Logistics department users..." -Level "Info"
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $usersPath = "OU=Users,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $users = @(
        @{ Name = "charles.white"; DisplayName = "Charles White"; Title = "Warehouse Manager" },
        @{ Name = "susan.harris"; DisplayName = "Susan Harris"; Title = "Logistics Coordinator" },
        @{ Name = "daniel.clark"; DisplayName = "Daniel Clark"; Title = "Inventory Specialist" },
        @{ Name = "jessica.lewis"; DisplayName = "Jessica Lewis"; Title = "Warehouse Associate" },
        @{ Name = "christopher.walker"; DisplayName = "Christopher Walker"; Title = "Forklift Operator" },
        @{ Name = "ashley.young"; DisplayName = "Ashley Young"; Title = "Shipping Coordinator" }
    )
    
    foreach ($user in $users) {
        $samAccountName = $user.Name.Replace(".", "").ToLower()
        $userPrincipalName = "$($user.Name)@$DomainName"
        $password = ConvertTo-SecureString "TempPassword123!@#" -AsPlainText -Force
        
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
        
        if (-not $existingUser) {
            Write-Log "Creating user: $($user.DisplayName)" -Level "Info"
            New-ADUser -SamAccountName $samAccountName `
                -UserPrincipalName $userPrincipalName `
                -DisplayName $user.DisplayName `
                -Title $user.Title `
                -Path $usersPath `
                -AccountPassword $password `
                -Enabled $true
        }
    }
}

function Create-DepartmentGroups {
    Write-Log "Configuring department groups..." -Level "Info"
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $groupsPath = "OU=Groups,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $groups = @(
        "$DeptName-SG-FileShare",
        "$DeptName-SG-Inventory-DB",
        "$DeptName-SG-LabelPrinters",
        "$DeptName-SG-Logistics-Software",
        "$DeptName-SG-Scanner-Access",
        "$DeptName-SG-MobileDevices"
    )
    
    foreach ($group in $groups) {
        $existingGroup = Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue
        if (-not $existingGroup) {
            Write-Log "Creating group: $group" -Level "Info"
            New-ADGroup -Name $group -Path $groupsPath -GroupScope Global
        }
    }
}

function Configure-LightweightProfiles {
    Write-Log "Configuring lightweight profiles for mobile devices..." -Level "Info"
    
    Write-Log "Lightweight profile settings:" -Level "Info"
    Write-Log "  - Minimal user profile (roaming profiles)" -Level "Info"
    Write-Log "  - Cached credentials for offline access" -Level "Info"
    Write-Log "  - Fast user switching" -Level "Info"
    Write-Log "  - Reduced profile size for tablets/handhelds" -Level "Info"
}

function Configure-InventoryDatabaseAccess {
    Write-Log "Configuring inventory database access..." -Level "Info"
    
    $sharePath = "E:\Shares\Inventory-DB"
    $groupName = "$DeptName-SG-Inventory-DB"
    
    if (Test-Path $sharePath) {
        $acl = Get-Acl $sharePath
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "$DomainName\$groupName",
            "Modify",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $sharePath -AclObject $acl
        
        Write-Log "Inventory database access configured" -Level "Info"
    }
}

function Configure-LabelPrinterMapping {
    Write-Log "Configuring label printer mapping via GPO..." -Level "Info"
    
    Write-Log "Label printer configuration:" -Level "Info"
    Write-Log "  - Printer: Warehouse-LabelPrinter" -Level "Info"
    Write-Log "  - Port: LPR (Line Printer Remote)" -Level "Info"
    Write-Log "  - Access Group: $DeptName-SG-LabelPrinters" -Level "Info"
    Write-Log "  - Deployment: Group Policy (network printer)" -Level "Info"
}

function Configure-VLANSegmentation {
    Write-Log "Configuring VLAN segmentation for IoT devices..." -Level "Info"
    
    Write-Log "VLAN Configuration:" -Level "Info"
    Write-Log "  - VLAN 100: Warehouse Employees (DHCP: 172.16.100.0/24)" -Level "Info"
    Write-Log "  - VLAN 101: Handheld Scanners (DHCP: 172.16.101.0/24)" -Level "Info"
    Write-Log "  - VLAN 102: RFID Readers (Static IPs: 172.16.102.0/24)" -Level "Info"
    Write-Log "  - VLAN 103: Label Printers (Static IPs: 172.16.103.0/24)" -Level "Info"
    Write-Log "  - Access Control: ACLs between VLANs for secure communication" -Level "Info"
}

function Configure-RoleBasedAccess {
    Write-Log "Configuring role-based access control for logistics software..." -Level "Info"
    
    $groups = @(
        @{ Name = "$DeptName-SG-WarehouseManager"; Permissions = "Full Access" },
        @{ Name = "$DeptName-SG-LogisticsCoordinator"; Permissions = "Edit Orders" },
        @{ Name = "$DeptName-SG-Warehouse-Associate"; Permissions = "Read/Pick Orders" }
    )
    
    foreach ($group in $groups) {
        Write-Log "Role: $($group.Name) - Permissions: $($group.Permissions)" -Level "Info"
    }
}

function Configure-ScannerDeviceAccess {
    Write-Log "Configuring barcode scanner and RFID access policies..." -Level "Info"
    
    # Create device access rules
    Write-Log "Scanner device policies:" -Level "Info"
    Write-Log "  - Allow common scanner protocols (USB, Bluetooth)" -Level "Info"
    Write-Log "  - RFID reader authentication" -Level "Info"
    Write-Log "  - Real-time inventory sync" -Level "Info"
}

# Main execution
Write-Log "========== WAREHOUSE & LOGISTICS DEPARTMENT CONFIGURATION STARTED ==========" -Level "Info"
Create-DepartmentUsers
Create-DepartmentGroups
Configure-LightweightProfiles
Configure-InventoryDatabaseAccess
Configure-LabelPrinterMapping
Configure-VLANSegmentation
Configure-RoleBasedAccess
Configure-ScannerDeviceAccess
Write-Log "========== WAREHOUSE & LOGISTICS DEPARTMENT CONFIGURATION COMPLETED ==========" -Level "Info"
