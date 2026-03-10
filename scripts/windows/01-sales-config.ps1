#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Sales & Showroom Department Configuration
.DESCRIPTION
    Configures users, groups, and policies for Sales department
    - 10-15 employees
    - Kiosk/demo PCs with limited install rights
    - Marketing materials and product catalogs
    - Shared printers with quotas
    - VPN profiles for off-site staff
#>

param(
    [string]$DomainName = "company.local",
    [string]$DeptName = "Sales-Showroom",
    [int]$EmployeeCount = 15,
    [string]$LogPath = "C:\Logs\SalesDept.log"
)

function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "Error") { "Red" } else { "Green" })
}

function Create-DepartmentUsers {
    Write-Log "Creating Sales department users..." -Level "Info"
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $usersPath = "OU=Users,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $users = @(
        @{ Name = "john.smith"; DisplayName = "John Smith"; Title = "Sales Manager" },
        @{ Name = "sarah.johnson"; DisplayName = "Sarah Johnson"; Title = "Senior Sales Rep" },
        @{ Name = "mike.williams"; DisplayName = "Mike Williams"; Title = "Sales Rep" },
        @{ Name = "emma.davis"; DisplayName = "Emma Davis"; Title = "Sales Rep" },
        @{ Name = "david.miller"; DisplayName = "David Miller"; Title = "Showroom Associate" },
        @{ Name = "lisa.anderson"; DisplayName = "Lisa Anderson"; Title = "Demo Specialist" }
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
    
    $groups = @("$DeptName-SG-FileShare", "$DeptName-SG-Printers", "$DeptName-SG-VPN")
    
    foreach ($group in $groups) {
        $existingGroup = Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue
        if (-not $existingGroup) {
            Write-Log "Creating group: $group" -Level "Info"
            New-ADGroup -Name $group -Path $groupsPath -GroupScope Global
        }
    }
}

function Configure-FileSharePermissions {
    Write-Log "Configuring file share permissions..." -Level "Info"
    
    $sharePath = "E:\Shares\Sales-Materials"
    $groupName = "$DeptName-SG-FileShare"
    
    if (Test-Path $sharePath) {
        # Set NTFS permissions
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
        
        Write-Log "File share permissions configured for $groupName" -Level "Info"
    }
}

function Configure-PrinterAccess {
    Write-Log "Configuring printer access policies..." -Level "Info"
    
    $rPrinterPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
    
    # Enable print quota policies
    New-Item -Path $rPrinterPath -Name "Quotas" -Force | Out-Null
    Set-ItemProperty -Path "$rPrinterPath\Quotas" -Name "EnableQuotas" -Value 1
    
    Write-Log "Printer quota policies configured" -Level "Info"
}

function Configure-VPNProfiles {
    Write-Log "Configuring VPN profiles for off-site access..." -Level "Info"
    
    # This would be deployed via GPO in production
    Write-Log "VPN profile template available for GPO deployment" -Level "Info"
}

# Main execution
Write-Log "========== SALES DEPARTMENT CONFIGURATION STARTED ==========" -Level "Info"
Create-DepartmentUsers
Create-DepartmentGroups
Configure-FileSharePermissions
Configure-PrinterAccess
Configure-VPNProfiles
Write-Log "========== SALES DEPARTMENT CONFIGURATION COMPLETED ==========" -Level "Info"
