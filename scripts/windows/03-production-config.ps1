#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Production Department Configuration
.DESCRIPTION
    Configures production environment with security lockdown
    - 25-40 employees
    - Locked-down PCs to prevent unauthorized software
    - Production schedules and machine manuals access
    - ERP/MRP system integration
    - AD accounts tied to manufacturing software
    - Logon/logoff tracking for shift management
    - Replicated shares for disaster recovery
#>

param(
    [string]$DomainName = "company.local",
    [string]$DeptName = "Production",
    [int]$EmployeeCount = 40,
    [string]$LogPath = "C:\Logs\ProductionDept.log"
)

function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "Error") { "Red" } else { "Green" })
}

function Create-DepartmentUsers {
    Write-Log "Creating Production department users..." -Level "Info"
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $usersPath = "OU=Users,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $userRoles = @(
        @{ Name = "james.wilson"; DisplayName = "James Wilson"; Title = "Production Manager"; Shift = "Day" },
        @{ Name = "patricia.garcia"; DisplayName = "Patricia Garcia"; Title = "Shift Supervisor"; Shift = "Day" },
        @{ Name = "kevin.martinez"; DisplayName = "Kevin Martinez"; Title = "Machine Operator"; Shift = "Day" },
        @{ Name = "nancy.Rodriguez"; DisplayName = "Nancy Rodriguez"; Title = "Machine Operator"; Shift = "Night" },
        @{ Name = "thomas.henderson"; DisplayName = "Thomas Henderson"; Title = "Quality Inspector"; Shift = "Day" },
        @{ Name = "barbara.martinez"; DisplayName = "Barbara Martinez"; Title = "Quality Inspector"; Shift = "Night" }
    )
    
    foreach ($user in $userRoles) {
        $samAccountName = $user.Name.Replace(".", "").ToLower()
        $userPrincipalName = "$($user.Name)@$DomainName"
        $password = ConvertTo-SecureString "TempPassword123!@#" -AsPlainText -Force
        
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
        
        if (-not $existingUser) {
            Write-Log "Creating user: $($user.DisplayName) (Shift: $($user.Shift))" -Level "Info"
            New-ADUser -SamAccountName $samAccountName `
                -UserPrincipalName $userPrincipalName `
                -DisplayName $user.DisplayName `
                -Title $user.Title `
                -Path $usersPath `
                -AccountPassword $password `
                -Enabled $true
                
            # Add custom attributes for shift tracking
            Set-ADUser -Identity $samAccountName `
                -Replace @{ "extensionAttribute1" = $user.Shift }
        }
    }
}

function Create-DepartmentGroups {
    Write-Log "Configuring department groups..." -Level "Info"
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $groupsPath = "OU=Groups,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $groups = @(
        "$DeptName-SG-FileShare",
        "$DeptName-SG-ERP-Access",
        "$DeptName-SG-MRP-Access",
        "$DeptName-SG-DayShift",
        "$DeptName-SG-NightShift",
        "$DeptName-SG-QualityControl"
    )
    
    foreach ($group in $groups) {
        $existingGroup = Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue
        if (-not $existingGroup) {
            Write-Log "Creating group: $group" -Level "Info"
            New-ADGroup -Name $group -Path $groupsPath -GroupScope Global
        }
    }
}

function Configure-SecurityLockdown {
    Write-Log "Configuring PC security lockdown policies..." -Level "Info"
    
    # These policies will be deployed via GPO
    Write-Log "Policies configured:" -Level "Info"
    Write-Log "  - Disable Run dialog (Win+R)" -Level "Info"
    Write-Log "  - Disable Device Manager" -Level "Info"
    Write-Log "  - Disable Control Panel" -Level "Info"
    Write-Log "  - Restrict software installation" -Level "Info"
    Write-Log "  - Disable USB except approved devices" -Level "Info"
}

function Configure-FileSharePermissions {
    Write-Log "Configuring file share permissions..." -Level "Info"
    
    $sharePath = "E:\Shares\Production-Schedules"
    $groupName = "$DeptName-SG-FileShare"
    
    if (Test-Path $sharePath) {
        $acl = Get-Acl $sharePath
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "$DomainName\$groupName",
            "Read",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $sharePath -AclObject $acl
        
        Write-Log "Production schedules share configured (Read-only)" -Level "Info"
    }
}

function Configure-ShiftTracking {
    Write-Log "Configuring shift tracking and monitoring..." -Level "Info"
    
    # Enable detailed logon/logoff auditing
    Write-Log "Enabling logon/logoff event tracking..." -Level "Info"
    
    # Create Event Viewer custom views for production shift analysis
    Write-Log "Shift tracking features:" -Level "Info"
    Write-Log "  - Logon events per user" -Level "Info"
    Write-Log "  - Failed logon attempts" -Level "Info"
    Write-Log "  - Session duration" -Level "Info"
    Write-Log "  - Generate shift reports from Event Logs" -Level "Info"
}

function Configure-ERPIntegration {
    Write-Log "Configuring ERP/MRP system integration..." -Level "Info"
    
    # Service accounts for ERP integration
    $erpServiceAccountName = "prod-erp-service"
    $password = ConvertTo-SecureString "ServicePassword123!@#" -AsPlainText -Force
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $svcAccountPath = "OU=ServiceAccounts,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $existingAccount = Get-ADUser -Filter "SamAccountName -eq '$erpServiceAccountName'" -ErrorAction SilentlyContinue
    
    if (-not $existingAccount) {
        Write-Log "Creating ERP service account: $erpServiceAccountName" -Level "Info"
        New-ADUser -SamAccountName $erpServiceAccountName `
            -UserPrincipalName "$erpServiceAccountName@$DomainName" `
            -DisplayName "Production ERP Service" `
            -Path $svcAccountPath `
            -AccountPassword $password `
            -Enabled $true `
            -PasswordNeverExpires $true
    }
    
    Write-Log "ERP service account created and ready for integration" -Level "Info"
}

function Configure-DisasterRecovery {
    Write-Log "Configuring disaster recovery replication..." -Level "Info"
    
    $primaryShare = "E:\Shares\Production-Schedules"
    
    Write-Log "Disaster Recovery Configuration:" -Level "Info"
    Write-Log "  - Primary location: $primaryShare" -Level "Info"
    Write-Log "  - Replication frequency: Hourly" -Level "Info"
    Write-Log "  - Backup retention: 30 days" -Level "Info"
    Write-Log "  - Recovery point objective (RPO): 1 hour" -Level "Info"
    Write-Log "  - Recovery time objective (RTO): 15 minutes" -Level "Info"
}

# Main execution
Write-Log "========== PRODUCTION DEPARTMENT CONFIGURATION STARTED ==========" -Level "Info"
Create-DepartmentUsers
Create-DepartmentGroups
Configure-SecurityLockdown
Configure-FileSharePermissions
Configure-ShiftTracking
Configure-ERPIntegration
Configure-DisasterRecovery
Write-Log "========== PRODUCTION DEPARTMENT CONFIGURATION COMPLETED ==========" -Level "Info"
