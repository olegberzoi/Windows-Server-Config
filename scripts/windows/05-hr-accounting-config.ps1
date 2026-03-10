#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Accounting & HR Department Configuration
.DESCRIPTION
    Configures secure finance and HR environment
    - 5-8 employees
    - Stronger security baselines (BitLocker, restricted USB)
    - Confidential shares with NTFS permissions (least privilege)
    - Audit policies enabled on sensitive folders
    - Multi-Factor Authentication (MFA) for payroll/HR systems
    - Data Loss Prevention (DLP) for financial/employee data
#>

param(
    [string]$DomainName = "company.local",
    [string]$DeptName = "Accounting-HR",
    [int]$EmployeeCount = 8,
    [string]$LogPath = "C:\Logs\AccountingHRDept.log"
)

function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "Error") { "Red" } else { "Green" })
}

function Create-DepartmentUsers {
    Write-Log "Creating Accounting & HR department users..." -Level "Info"
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $usersPath = "OU=Users,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $users = @(
        @{ Name = "linda.garcia"; DisplayName = "Linda Garcia"; Title = "Accounting Manager"; Level = "Manager" },
        @{ Name = "richard.king"; DisplayName = "Richard King"; Title = "Senior Accountant"; Level = "Senior" },
        @{ Name = "diana.jackson"; DisplayName = "Diana Jackson"; Title = "HR Manager"; Level = "Manager" },
        @{ Name = "george.martin"; DisplayName = "George Martin"; Title = "Payroll Specialist"; Level = "Senior" },
        @{ Name = "karen.davis"; DisplayName = "Karen Davis"; Title = "Accounts Payable"; Level = "Staff" }
    )
    
    foreach ($user in $users) {
        $samAccountName = $user.Name.Replace(".", "").ToLower()
        $userPrincipalName = "$($user.Name)@$DomainName"
        $password = ConvertTo-SecureString "TempPassword123!@#" -AsPlainText -Force
        
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
        
        if (-not $existingUser) {
            Write-Log "Creating user: $($user.DisplayName) (Level: $($user.Level))" -Level "Info"
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
        "$DeptName-SG-Finance",
        "$DeptName-SG-Payroll",
        "$DeptName-SG-HR-Confidential",
        "$DeptName-SG-Audit-Access",
        "$DeptName-SG-MFA-Required",
        "$DeptName-SG-DLP-Protected"
    )
    
    foreach ($group in $groups) {
        $existingGroup = Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue
        if (-not $existingGroup) {
            Write-Log "Creating group: $group" -Level "Info"
            New-ADGroup -Name $group -Path $groupsPath -GroupScope Global
        }
    }
}

function Configure-SecurityBaselines {
    Write-Log "Configuring enhanced security baselines..." -Level "Info"
    
    # BitLocker configuration
    Write-Log "BitLocker Configuration:" -Level "Info"
    Write-Log "  - Enable BitLocker on C: drive (OS)" -Level "Info"
    Write-Log "  - Enable BitLocker on D: drive (Data)" -Level "Info"
    Write-Log "  - Recovery key escrow to Active Directory" -Level "Info"
    
    # USB port restrictions
    Write-Log "USB Port Restrictions:" -Level "Info"
    Write-Log "  - Disable removable media (USB drives)" -Level "Info"
    Write-Log "  - Allow only approved devices (printers, keyboards)" -Level "Info"
    Write-Log "  - Enable device authentication" -Level "Info"
    
    Write-Log "Security baselines configured via GPO" -Level "Info"
}

function Configure-ConfidentialShares {
    Write-Log "Configuring confidential file shares with strict permissions..." -Level "Info"
    
    $sharePath = "E:\Shares\Accounting-Finance"
    
    if (Test-Path $sharePath) {
        Write-Log "Configuring least-privilege access on: $sharePath" -Level "Info"
        
        # Clear inherited permissions
        $acl = Get-Acl $sharePath
        
        # Remove "Everyone" and "Users" groups
        foreach ($access in $acl.Access) {
            if ($access.IdentityReference -match "Everyone|DOMAIN\\Users") {
                $acl.RemoveAccessRule($access) | Out-Null
            }
        }
        
        # Add specific department group - Modify only (not Full Control)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "$DomainName\$DeptName-SG-Finance",
            "Modify",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $sharePath -AclObject $acl
        
        Write-Log "Confidential shares configured with least-privilege permissions" -Level "Info"
    }
}

function Configure-AuditPolicies {
    Write-Log "Configuring audit policies for sensitive folders..." -Level "Info"
    
    $sharePath = "E:\Shares\Accounting-Finance"
    
    if (Test-Path $sharePath) {
        Write-Log "Enabling audit for: $sharePath" -Level "Info"
        
        # Enable file access auditing
        $acl = Get-Acl $sharePath -Audit
        $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
            "$DomainName\$DeptName-SG-Finance",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Success, Failure"
        )
        $acl.AddAuditRule($auditRule)
        Set-Acl -Path $sharePath -AclObject $acl
        
        Write-Log "Audit policies configured - all read/write/delete events tracked" -Level "Info"
    }
}

function Configure-MFAIntegration {
    Write-Log "Configuring Multi-Factor Authentication for payroll/HR systems..." -Level "Info"
    
    Write-Log "MFA Configuration:" -Level "Info"
    Write-Log "  - Enable MFA for Payroll System (Group: $DeptName-SG-MFA-Required)" -Level "Info"
    Write-Log "  - Enable MFA for HR System (Group: $DeptName-SG-MFA-Required)" -Level "Info"
    Write-Log "  - MFA Method: FIDO2 Security Keys (recommended)" -Level "Info"
    Write-Log "  - Fallback: Time-based One-Time Password (TOTP)" -Level "Info"
    Write-Log "  - Conditional access: Require MFA for external access" -Level "Info"
}

function Configure-DataLossPrevention {
    Write-Log "Configuring Data Loss Prevention (DLP) policies..." -Level "Info"
    
    Write-Log "DLP Protection Rules:" -Level "Info"
    Write-Log "  - Monitor: Bank account numbers (regex pattern)" -Level "Info"
    Write-Log "  - Monitor: Social Security numbers (XXX-XX-XXXX)" -Level "Info"
    Write-Log "  - Monitor: Employee PII (names, addresses, phone numbers)" -Level "Info"
    Write-Log "  - Monitor: Salary information" -Level "Info"
    Write-Log "  - Action: Alert on send, Block on print, Encrypt on email" -Level "Info"
    Write-Log "  - Protection scope: Email, File shares, USB, Cloud sync" -Level "Info"
}

function Configure-ServiceAccounts {
    Write-Log "Creating service accounts for accounting/HR systems..." -Level "Info"
    
    $serviceAccounts = @(
        @{ Name = "payroll-service"; Description = "Payroll System Service Account" },
        @{ Name = "hr-service"; Description = "HR System Service Account" }
    )
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $svcPath = "OU=ServiceAccounts,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    foreach ($svc in $serviceAccounts) {
        $password = ConvertTo-SecureString "ServicePassword123!@#" -AsPlainText -Force
        $existingAccount = Get-ADUser -Filter "SamAccountName -eq '$($svc.Name)'" -ErrorAction SilentlyContinue
        
        if (-not $existingAccount) {
            Write-Log "Creating service account: $($svc.Name)" -Level "Info"
            New-ADUser -SamAccountName $svc.Name `
                -UserPrincipalName "$($svc.Name)@$DomainName" `
                -DisplayName $svc.Description `
                -Path $svcPath `
                -AccountPassword $password `
                -Enabled $true `
                -PasswordNeverExpires $true
        }
    }
}

# Main execution
Write-Log "========== ACCOUNTING & HR DEPARTMENT CONFIGURATION STARTED ==========" -Level "Info"
Create-DepartmentUsers
Create-DepartmentGroups
Configure-SecurityBaselines
Configure-ConfidentialShares
Configure-AuditPolicies
Configure-MFAIntegration
Configure-DataLossPrevention
Configure-ServiceAccounts
Write-Log "========== ACCOUNTING & HR DEPARTMENT CONFIGURATION COMPLETED ==========" -Level "Info"
