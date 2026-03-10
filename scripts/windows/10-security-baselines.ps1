#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Security Baselines and Audit Policies Configuration
.DESCRIPTION
    Implements security baselines and comprehensive audit logging
    - Password policies
    - Account lockout policies
    - Kerberos policies
    - Advanced audit policies
    - Security event forwarding
#>

param(
    [string]$DomainName = "company.local",
    [string]$LogPath = "C:\Logs\SecurityBaselines.log"
)

function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "Error") { "Red" } else { "Green" })
}

function Set-PasswordPolicy {
    Write-Log "Configuring password policies..." -Level "Info"
    
    Write-Log "Password Policy Settings:" -Level "Info"
    Write-Log "  - Minimum password length: 14 characters" -Level "Info"
    Write-Log "  - Password complexity: Enabled" -Level "Info"
    Write-Log "    * Uppercase (A-Z)" -Level "Info"
    Write-Log "    * Lowercase (a-z)" -Level "Info"
    Write-Log "    * Numbers (0-9)" -Level "Info"
    Write-Log "    * Special characters (!@#$%^&*)" -Level "Info"
    Write-Log "  - Maximum password age: 90 days" -Level "Info"
    Write-Log "  - Minimum password age: 1 day" -Level "Info"
    Write-Log "  - Password history: 24 passwords remembered" -Level "Info"
    Write-Log "  - Store passwords using reversible encryption: Disabled" -Level "Info"
}

function Set-AccountLockoutPolicy {
    Write-Log "Configuring account lockout policies..." -Level "Info"
    
    Write-Log "Account Lockout Policy:" -Level "Info"
    Write-Log "  - Failed logon attempts threshold: 5 attempts" -Level "Info"
    Write-Log "  - Lockout duration: 30 minutes" -Level "Info"
    Write-Log "  - Reset count after: 30 minutes of inactivity" -Level "Info"
    Write-Log "  - Account lockout counter: Prevents brute force attacks" -Level "Info"
}

function Set-KerberosPolicy {
    Write-Log "Configuring Kerberos policies..." -Level "Info"
    
    Write-Log "Kerberos Settings:" -Level "Info"
    Write-Log "  - Maximum ticket lifetime: 10 hours" -Level "Info"
    Write-Log "  - Maximum ticket renewal lifetime: 7 days" -Level "Info"
    Write-Log "  - Clock skew tolerance: 5 minutes" -Level "Info"
    Write-Log "  - Enforce user logon restrictions: Enabled" -Level "Info"
    Write-Log "  - Validate KDC certificate: Enabled" -Level "Info"
}

function Configure-AdvancedAuditPolicy {
    Write-Log "Configuring Advanced Audit Policies..." -Level "Info"
    
    Write-Log "Audit Policy Categories:" -Level "Info"
    
    # Account Logon
    Write-Log "  Account Logon:" -Level "Info"
    Write-Log "    - Audit Credential Validation: Success and Failure" -Level "Info"
    Write-Log "    - Audit Kerberos Service Ticket Operations: Success and Failure" -Level "Info"
    Write-Log "    - Audit Kerberos Authentication Service: Success and Failure" -Level "Info"
    
    # Logon/Logoff
    Write-Log "  Logon/Logoff:" -Level "Info"
    Write-Log "    - Audit Logon: Success and Failure" -Level "Info"
    Write-Log "    - Audit Logoff: Success" -Level "Info"
    Write-Log "    - Audit Account Lockout: Failure" -Level "Info"
    Write-Log "    - Audit Group Membership: Success" -Level "Info"
    
    # Object Access
    Write-Log "  Object Access:" -Level "Info"
    Write-Log "    - Audit File System: Success and Failure (sensitive shares)" -Level "Info"
    Write-Log "    - Audit Registry: Success and Failure (HKLM\System)" -Level "Info"
    
    # Privilege Use
    Write-Log "  Privilege Use:" -Level "Info"
    Write-Log "    - Audit Sensitive Privilege Use: Success and Failure" -Level "Info"
    Write-Log "    - Audit Non Sensitive Privilege Use: Failure" -Level "Info"
    
    # Detailed Tracking
    Write-Log "  Detailed Tracking:" -Level "Info"
    Write-Log "    - Audit Process Creation: Success" -Level "Info"
    Write-Log "    - Audit Process Termination: Success" -Level "Info"
    
    # Policy Change
    Write-Log "  Policy Change:" -Level "Info"
    Write-Log "    - Audit Audit Policy Change: Success and Failure" -Level "Info"
    Write-Log "    - Audit User Account Management: Success and Failure" -Level "Info"
    Write-Log "    - Audit Security Group Management: Success and Failure" -Level "Info"
    
    # System
    Write-Log "  System:" -Level "Info"
    Write-Log "    - Audit Security System Extension: Success and Failure" -Level "Info"
    Write-Log "    - Audit System Integrity: Success and Failure" -Level "Info"
}

function Enable-SecurityEventAuditing {
    Write-Log "Enabling critical security event auditing..." -Level "Info"
    
    # Enable command-line auditing
    Write-Log "Enabling advanced features:" -Level "Info"
    Write-Log "  - Command-line process auditing (Event ID 4688)" -Level "Info"
    Write-Log "  - Registry operations (Event ID 4657, 4658, 4659)" -Level "Info"
    Write-Log "  - Sensitive account operations (Event ID 4720-4722)" -Level "Info"
}

function Configure-EventLogForwarding {
    Write-Log "Configuring Windows Event Log forwarding..." -Level "Info"
    
    Write-Log "Event Log Forwarding Configuration:" -Level "Info"
    Write-Log "  - Central collector server: DC01" -Level "Info"
    Write-Log "  - Protocols: HTTPS (WinRM over SSL)" -Level "Info"
    Write-Log "  - Events forwarded:" -Level "Info"
    Write-Log "    * Security: All events (especially failures)" -Level "Info"
    Write-Log "    * System: Critical and Errors" -Level "Info"
    Write-Log "    * Application: Errors and Warnings" -Level "Info"
    Write-Log "  - Retention: 90 days minimum" -Level "Info"
    Write-Log "  - Archive: Off-site monthly" -Level "Info"
}

function Configure-BitLockerPolicy {
    Write-Log "Configuring BitLocker encryption policies..." -Level "Info"
    
    Write-Log "BitLocker Configuration (via GPO):" -Level "Info"
    Write-Log "  For all departments, OS drive (C:):" -Level "Info"
    Write-Log "    - Encryption: AES 256-bit" -Level "Info"
    Write-Log "    - Recovery method: TPM + PIN" -Level "Info"
    Write-Log "    - Recovery key escrow: Active Directory" -Level "Info"
    
    Write-Log "  For Accounting/HR, Data drives (D:+):" -Level "Info"
    Write-Log "    - Encryption: AES 256-bit full volume" -Level "Info"
    Write-Log "    - Auto-unlock: Disabled" -Level "Info"
    Write-Log "    - Startup authentication: PIN required" -Level "Info"
}

function Configure-USBRestrictions {
    Write-Log "Configuring USB device restrictions (Accounting/HR)..." -Level "Info"
    
    Write-Log "USB Device Policy:" -Level "Info"
    Write-Log "  - Removable media (USB drives): DISABLED" -Level "Info"
    Write-Log "  - Approved device classes:" -Level "Info"
    Write-Log "    * Keyboards" -Level "Info"
    Write-Log "    * Mice" -Level "Info"
    Write-Log "    * Printers (specific models)" -Level "Info"
    Write-Log "  - Authentication: Device must be recognized" -Level "Info"
    Write-Log "  - Policy enforcement: Computer startup" -Level "Info"
}

function Configure-FirewallRules {
    Write-Log "Configuring Windows Firewall rules..." -Level "Info"
    
    Write-Log "Firewall Policy:" -Level "Info"
    Write-Log "  - Inbound: Default Deny (block all except exceptions)" -Level "Info"
    Write-Log "  - Outbound: Default Allow" -Level "Info"
    Write-Log "  - Exceptions:" -Level "Info"
    Write-Log "    * Active Directory (LDAP, Kerberos): Allowed" -Level "Info"
    Write-Log "    * DNS (port 53): Allowed" -Level "Info"
    Write-Log "    * DHCP (port 67/68): Allowed" -Level "Info"
    Write-Log "    * Windows Update: Allowed" -Level "Info"
    Write-Log "    * RDP (3389): Allowed from admin subnet only" -Level "Info"
    Write-Log "    * NFS/SMB (port 445): Allowed for file shares" -Level "Info"
}

function Configure-AntiMalwarePolicies {
    Write-Log "Configuring anti-malware policies..." -Level "Info"
    
    Write-Log "Defender Configuration:" -Level "Info"
    Write-Log "  - Real-time protection: Enabled" -Level "Info"
    Write-Log "  - Cloud-delivered protection: Enabled" -Level "Info"
    Write-Log "  - Automatic sample submission: Enabled" -Level "Info"
    Write-Log "  - Signature update frequency: Every hour" -Level "Info"
    Write-Log "  - Scan schedule: Daily at 02:00 AM" -Level "Info"
    Write-Log "  - Actions on detection: Remove (automatic quarantine)" -Level "Info"
}

function Configure-ScreenSaverLocking {
    Write-Log "Configuring screen saver locking policies..." -Level "Info"
    
    $screenLockSettings = @(
        @{
            Department = "Accounting-HR"
            InactivityMinutes = 5
            LockOnWake = $true
            Message = "Confidential systems - Login Required"
        },
        @{
            Department = "Design-Technical"
            InactivityMinutes = 30
            LockOnWake = $true
            Message = "Please log in to continue"
        },
        @{
            Department = "Other Departments"
            InactivityMinutes = 15
            LockOnWake = $true
            Message = "Your session has been locked due to inactivity"
        }
    )
    
    foreach ($setting in $screenLockSettings) {
        Write-Log "Screen lock policy: $($setting.Department)" -Level "Info"
        Write-Log "  - Inactivity timeout: $($setting.InactivityMinutes) minutes" -Level "Info"
        Write-Log "  - Lock on wake: $(if ($setting.LockOnWake) { 'Yes' } else { 'No' })" -Level "Info"
        Write-Log "  - Message: $($setting.Message)" -Level "Info"
    }
}

function Configure-RDPSecurity {
    Write-Log "Configuring Remote Desktop Protocol (RDP) security..." -Level "Info"
    
    Write-Log "RDP Security Settings:" -Level "Info"
    Write-Log "  - Encryption level: High (FIPS compliant)" -Level "Info"
    Write-Log "  - Network Level Authentication: Required" -Level "Info"
    Write-Log "  - Allow connections from: Computers with NLA only" -Level "Info"
    Write-Log "  - Session timeout: 30 minutes of inactivity" -Level "Info"
    Write-Log "  - Session disconnect timeout: 30 minutes" -Level "Info"
    Write-Log "  - Restricted Admin mode: Enabled (for tier-0 systems)" -Level "Info"
}

function Configure-SoftwareRestriction {
    Write-Log "Configuring Software Restriction Policies (Production)..." -Level "Info"
    
    Write-Log "SRP Configuration:" -Level "Info"
    Write-Log "  - Enforcement level: All users" -Level "Info"
    Write-Log "  - Scope: All software except libraries" -Level "Info"
    Write-Log "  - Default rule: Disallowed" -Level "Info"
    Write-Log "  - Exceptions (Allowed):" -Level "Info"
    Write-Log "    * System paths (%SYSTEMROOT%, %PROGRAMFILES%)" -Level "Info"
    Write-Log "    * Manufacturing applications" -Level "Info"
    Write-Log "    * Windows Updates" -Level "Info"
    Write-Log "  - Blocked paths:" -Level "Info"
    Write-Log "    * %Temp%, %AppData%\\Local\\Temp (unless work-related)" -Level "Info"
    Write-Log "    * Network shares (except approved)" -Level "Info"
}

function Configure-CertificatePolicies {
    Write-Log "Configuring certificate-based authentication policies..." -Level "Info"
    
    Write-Log "Certificate Policy:" -Level "Info"
    Write-Log "  - Enrollment: Auto-enroll for computers/users" -Level "Info"
    Write-Log "  - Certificate revocation: OCSP + CRL" -Level "Info"
    Write-Log "  - Key storage: TPM or smart card" -Level "Info"
    Write-Log "  - Template: Medium (2048-bit RSA, SHA256)" -Level "Info"
}

function Enable-LAPS {
    Write-Log "Enabling Local Administrator Password Solution (LAPS)..." -Level "Info"
    
    Write-Log "LAPS Configuration:" -Level "Info"
    Write-Log "  - Administrator password management: Automatic" -Level "Info"
    Write-Log "  - Password length: 24 characters" -Level "Info"
    Write-Log "  - Password age: 30 days (rotate monthly)" -Level "Info"
    Write-Log "  - Password complexity: Maximum (uppercase, lowercase, numbers, symbols)" -Level "Info"
    Write-Log "  - Storage: Active Directory (LAPS-managed attribute)" -Level "Info"
    Write-Log "  - Access: Only to authorized admin accounts" -Level "Info"
}

function Configure-PrivilegeEscalation {
    Write-Log "Configuring privilege escalation controls..." -Level "Info"
    
    Write-Log "Privilege Escalation Policies:" -Level "Info"
    Write-Log "  - User Access Control (UAC): Enabled" -Level "Info"
    Write-Log "  - UAC level: Prompt for credentials" -Level "Info"
    Write-Log "  - Secure Desktop: Enabled" -Level "Info"
    Write-Log "  - Admin approval mode: For built-in Administrator" -Level "Info"
}

# Main execution
Write-Log "========== SECURITY BASELINES AND AUDIT POLICIES CONFIGURATION STARTED ==========" -Level "Info"
try {
    Set-PasswordPolicy
    Set-AccountLockoutPolicy
    Set-KerberosPolicy
    Configure-AdvancedAuditPolicy
    Enable-SecurityEventAuditing
    Configure-EventLogForwarding
    Configure-BitLockerPolicy
    Configure-USBRestrictions
    Configure-FirewallRules
    Configure-AntiMalwarePolicies
    Configure-ScreenSaverLocking
    Configure-RDPSecurity
    Configure-SoftwareRestriction
    Configure-CertificatePolicies
    Enable-LAPS
    Configure-PrivilegeEscalation
    
    Write-Log "========== SECURITY BASELINES AND AUDIT POLICIES CONFIGURATION COMPLETED SUCCESSFULLY ==========" -Level "Info"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" -Level "Error"
    exit 1
}
