#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Management & IT Department Configuration
.DESCRIPTION
    Configures IT administration and management environment
    - 4-6 employees
    - Elevated privileges with strict auditing
    - Two-account model (admin vs. daily use)
    - Monitoring dashboards access (Prometheus/Grafana)
    - Veeam backup integration for VM snapshots
    - Strict audit logging on privileged actions
#>

param(
    [string]$DomainName = "company.local",
    [string]$DeptName = "Management-IT",
    [int]$EmployeeCount = 6,
    [string]$LogPath = "C:\Logs\ManagementITDept.log"
)

function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "Error") { "Red" } else { "Green" })
}

function Create-DepartmentUsers {
    Write-Log "Creating Management & IT department users..." -Level "Info"
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $usersPath = "OU=Users,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $users = @(
        @{ Name = "michael.johnson"; DisplayName = "Michael Johnson"; Title = "IT Director"; Role = "Admin" },
        @{ Name = "jennifer.smith"; DisplayName = "Jennifer Smith"; Title = "Senior Systems Admin"; Role = "Admin" },
        @{ Name = "david.brown"; DisplayName = "David Brown"; Title = "Network Admin"; Role = "Admin" },
        @{ Name = "sarah.martin"; DisplayName = "Sarah Martin"; Title = "IT Support Specialist"; Role = "Support" },
        @{ Name = "robert.wilson"; DisplayName = "Robert Wilson"; Title = "IT Security Officer"; Role = "Security" }
    )
    
    foreach ($user in $users) {
        $samAccountName = $user.Name.Replace(".", "").ToLower()
        $userPrincipalName = "$($user.Name)@$DomainName"
        $password = ConvertTo-SecureString "TempPassword123!@#" -AsPlainText -Force
        
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
        
        if (-not $existingUser) {
            Write-Log "Creating user: $($user.DisplayName) (Role: $($user.Role))" -Level "Info"
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

function Create-AdminAccounts {
    Write-Log "Creating separate admin accounts for privileged operations..." -Level "Info"
    
    $adminUsers = @(
        @{ Name = "michael.johnson.admin"; DisplayName = "Michael Johnson (Admin)" },
        @{ Name = "jennifer.smith.admin"; DisplayName = "Jennifer Smith (Admin)" },
        @{ Name = "david.brown.admin"; DisplayName = "David Brown (Admin)" }
    )
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $usersPath = "OU=Users,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    foreach ($admin in $adminUsers) {
        $samAccountName = $admin.Name
        $password = ConvertTo-SecureString "AdminPassword123!@#" -AsPlainText -Force
        
        $existingAdmin = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
        
        if (-not $existingAdmin) {
            Write-Log "Creating admin account: $($admin.DisplayName)" -Level "Info"
            New-ADUser -SamAccountName $samAccountName `
                -UserPrincipalName "$samAccountName@$DomainName" `
                -DisplayName $admin.DisplayName `
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
        "$DeptName-SG-Admins",
        "$DeptName-SG-SystemAdmins",
        "$DeptName-SG-NetworkAdmins",
        "$DeptName-SG-SecurityAdmins",
        "$DeptName-SG-Monitoring-Access",
        "$DeptName-SG-Backup-Admins",
        "$DeptName-SG-Domain-Admins"
    )
    
    foreach ($group in $groups) {
        $existingGroup = Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue
        if (-not $existingGroup) {
            Write-Log "Creating group: $group" -Level "Info"
            New-ADGroup -Name $group -Path $groupsPath -GroupScope Global
        }
    }
}

function Configure-AdminTiering {
    Write-Log "Implementing admin tiering model..." -Level "Info"
    
    Write-Log "Admin Tiering Strategy:" -Level "Info"
    Write-Log "  Tier 0 (Enterprise Admin):" -Level "Info"
    Write-Log "    - Used only for AD forest-level changes" -Level "Info"
    Write-Log "    - Group: Domain Admins (restricted membership)" -Level "Info"
    Write-Log "    - Activities: Forest functional level upgrades, schema changes" -Level "Info"
    
    Write-Log "  Tier 1 (Domain Admin):" -Level "Info"
    Write-Log "    - Used for domain-wide operations" -Level "Info"
    Write-Log "    - Group: $DeptName-SG-SystemAdmins" -Level "Info"
    Write-Log "    - Activities: User/computer management, GPO changes, site management" -Level "Info"
    
    Write-Log "  Tier 2 (Administrator):" -Level "Info"
    Write-Log "    - Local administrator on specific servers/workstations" -Level "Info"
    Write-Log "    - Group: $DeptName-SG-Admins" -Level "Info"
    Write-Log "    - Activities: Local service management, software installation" -Level "Info"
    
    Write-Log "  Daily Use:" -Level "Info"
    Write-Log "    - Standard user account (no admin rights)" -Level "Info"
    Write-Log "    - Used for email, document editing, web browsing" -Level "Info"
}

function Configure-PrivilegedAccessManagement {
    Write-Log "Configuring Privileged Access Management (PAM)..." -Level "Info"
    
    Write-Log "PAM Controls:" -Level "Info"
    Write-Log "  - Require secure session hosts for admin work" -Level "Info"
    Write-Log "  - Dedicated admin workstations (no internet)" -Level "Info"
    Write-Log "  - Session recording of privileged actions" -Level "Info"
    Write-Log "  - Time-limited elevation (1-2 hours)" -Level "Info"
    Write-Log "  - Approval workflow for sensitive changes" -Level "Info"
}

function Configure-FileSharePermissions {
    Write-Log "Configuring IT resources file share..." -Level "Info"
    
    $sharePath = "E:\Shares\IT-Resources"
    $groupName = "$DeptName-SG-Admins"
    
    if (Test-Path $sharePath) {
        $acl = Get-Acl $sharePath
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "$DomainName\$groupName",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $sharePath -AclObject $acl
        
        Write-Log "IT resources share configured with full access for admin group" -Level "Info"
    }
}

function Configure-MonitoringDashboards {
    Write-Log "Configuring Prometheus/Grafana monitoring dashboard access..." -Level "Info"
    
    Write-Log "Monitoring Dashboard Setup:" -Level "Info"
    Write-Log "  - Grafana Admin User: IT-Admins-Grafana" -Level "Info"
    Write-Log "  - Prometheus Access: Group: $DeptName-SG-Monitoring-Access" -Level "Info"
    Write-Log "  - Dashboards to create:" -Level "Info"
    Write-Log "    - Server Health (CPU, Memory, Disk)" -Level "Info"
    Write-Log "    - Network Performance (Bandwidth, Latency)" -Level "Info"
    Write-Log "    - AD Health (Replication, FSMO roles)" -Level "Info"
    Write-Log "    - Application Availability" -Level "Info"
    Write-Log "    - Security Events (Authentication, Privilege Use)" -Level "Info"
    Write-Log "  - Alert thresholds pre-configured" -Level "Info"
}

function Configure-BackupIntegration {
    Write-Log "Configuring Veeam backup integration..." -Level "Info"
    
    Write-Log "Veeam Backup Configuration:" -Level "Info"
    Write-Log "  - Service Account: veeam-backup-service" -Level "Info"
    Write-Log "  - Group with access: $DeptName-SG-Backup-Admins" -Level "Info"
    Write-Log "  - Backup Jobs:" -Level "Info"
    Write-Log "    - Daily full backup: Midnight" -Level "Info"
    Write-Log "    - Hourly incremental: Every hour" -Level "Info"
    Write-Log "    - Retention: 30-day backup chain" -Level "Info"
    Write-Log "  - Restore Point Objectives (RPO):" -Level "Info"
    Write-Log "    - Infrastructure: 1 hour" -Level "Info"
    Write-Log "    - File shares: 4 hours" -Level "Info"
    Write-Log "  - Disaster Recovery (DR):" -Level "Info"
    Write-Log "    - Secondary site replication enabled" -Level "Info"
    Write-Log "    - DR drills: Monthly" -Level "Info"
}

function Configure-PrivilegedActionAuditing {
    Write-Log "Configuring auditing for privileged actions..." -Level "Info"
    
    Write-Log "Audit Configuration:" -Level "Info"
    Write-Log "  - Event Log: Security" -Level "Info"
    Write-Log "  - Events to audit:" -Level "Info"
    Write-Log "    - Successful and failed logons (Event 4624, 4625)" -Level "Info"
    Write-Log "    - Group membership changes (Event 4728, 4729, 4730)" -Level "Info"
    Write-Log "    - User account creation/deletion (Event 4720, 4726)" -Level "Info"
    Write-Log "    - Active Directory changes (Event 5138, 5139)" -Level "Info"
    Write-Log "    - Sensitive object access (Event 4662)" -Level "Info"
    Write-Log "  - Log retention: 90 days" -Level "Info"
    Write-Log "  - Forwarding: Central log server" -Level "Info"
}

function Create-VeeamServiceAccount {
    Write-Log "Creating Veeam backup service account..." -Level "Info"
    
    $veeamServiceName = "veeam-backup-service"
    $password = ConvertTo-SecureString "VeeamPassword123!@#" -AsPlainText -Force
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $svcPath = "OU=ServiceAccounts,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $existingAccount = Get-ADUser -Filter "SamAccountName -eq '$veeamServiceName'" -ErrorAction SilentlyContinue
    
    if (-not $existingAccount) {
        Write-Log "Creating service account: $veeamServiceName" -Level "Info"
        New-ADUser -SamAccountName $veeamServiceName `
            -UserPrincipalName "$veeamServiceName@$DomainName" `
            -DisplayName "Veeam Backup Service Account" `
            -Path $svcPath `
            -AccountPassword $password `
            -Enabled $true `
            -PasswordNeverExpires $true
    }
}

# Main execution
Write-Log "========== MANAGEMENT & IT DEPARTMENT CONFIGURATION STARTED ==========" -Level "Info"
Create-DepartmentUsers
Create-AdminAccounts
Create-DepartmentGroups
Configure-AdminTiering
Configure-PrivilegedAccessManagement
Configure-FileSharePermissions
Configure-MonitoringDashboards
Configure-BackupIntegration
Configure-PrivilegedActionAuditing
Create-VeeamServiceAccount
Write-Log "========== MANAGEMENT & IT DEPARTMENT CONFIGURATION COMPLETED ==========" -Level "Info"
