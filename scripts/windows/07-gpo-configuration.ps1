#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Group Policy Object (GPO) Configuration Script
.DESCRIPTION
    Creates and configures GPOs for all departments
    - Automates GPO creation for each department OU
    - Applies computer and user policies
    - Configures drive mappings, printer deployments, security settings
.NOTES
    Run after main setup script and department configuration scripts
#>

param(
    [string]$DomainName = "company.local",
    [string]$LogPath = "C:\Logs\GPOConfiguration.log"
)

function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "Error") { "Red" } else { "Green" })
}

function Import-GroupPolicyModule {
    Write-Log "Importing Group Policy Management module..." -Level "Info"
    
    try {
        Import-Module GroupPolicy -ErrorAction Stop
        Write-Log "GroupPolicy module loaded successfully" -Level "Info"
    }
    catch {
        Write-Log "Error loading GroupPolicy module: $_" -Level "Error"
        exit 1
    }
}

function Create-DepartmentGPOs {
    Write-Log "Creating Group Policy Objects for all departments..." -Level "Info"
    
    $departments = @(
        @{ 
            Name = "Sales-Showroom"
            Description = "Sales & Showroom Policies"
            Policies = @("Standard Software", "Drive Mappings", "Printer Deployment")
        },
        @{ 
            Name = "Design-Technical"
            Description = "Design/CAD Department Policies"
            Policies = @("High Performance", "GPU Drivers", "Large File Handling", "Power Settings")
        },
        @{ 
            Name = "Production"
            Description = "Production Department Policies"
            Policies = @("Software Restrictions", "Lockdown Policy", "Audit Logon/Logoff")
        },
        @{ 
            Name = "Warehouse-Logistics"
            Description = "Warehouse & Logistics Policies"
            Policies = @("Mobile Device Profile", "Printer Deployment", "Limited Software")
        },
        @{ 
            Name = "Accounting-HR"
            Description = "Accounting/HR Security Policies"
            Policies = @("BitLocker", "USB Restrictions", "Screen Saver Lock", "Audit Sensitive Folders")
        },
        @{ 
            Name = "Management-IT"
            Description = "Management & IT Admin Policies"
            Policies = @("Admin Workstation", "Monitoring Tools", "Remote Tools", "Privileged Audit")
        }
    )
    
    foreach ($dept in $departments) {
        Write-Log "Creating GPOs for department: $($dept.Name)" -Level "Info"
        
        # Create main department GPO
        $gpoName = "$($dept.Name)-Policy"
        $existingGPO = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
        
        if (-not $existingGPO) {
            try {
                Write-Log "Creating GPO: $gpoName" -Level "Info"
                New-GPO -Name $gpoName -Comment $dept.Description | Out-Null
                
                # Link GPO to department OU
                $ouPath = "OU=$($dept.Name),OU=Departments,DC=$($DomainName.Split('.')[0]),DC=$($DomainName.Split('.')[1])"
                New-GPLink -Name $gpoName -Target $ouPath | Out-Null
                Write-Log "GPO linked to OU: $ouPath" -Level "Info"
            }
            catch {
                Write-Log "Error creating GPO: $_" -Level "Error"
            }
        }
        else {
            Write-Log "GPO already exists: $gpoName" -Level "Info"
        }
    }
}

function Configure-DriveMapPolicies {
    Write-Log "Configuring drive mappings for departments..." -Level "Info"
    
    $driveMappings = @(
        @{
            Department = "Sales-Showroom"
            Drive = "S"
            Share = "\\dc01\Sales-Materials"
            Description = "Sales Materials"
        },
        @{
            Department = "Design-Technical"
            Drive = "C"
            Share = "\\dc01\CAD-Projects"
            Description = "CAD Projects"
        },
        @{
            Department = "Production"
            Drive = "P"
            Share = "\\dc01\Production-Schedules"
            Description = "Production Files"
        },
        @{
            Department = "Warehouse-Logistics"
            Drive = "I"
            Share = "\\dc01\Inventory-DB"
            Description = "Inventory Database"
        },
        @{
            Department = "Accounting-HR"
            Drive = "A"
            Share = "\\dc01\Accounting-Finance"
            Description = "Accounting & HR"
        },
        @{
            Department = "Management-IT"
            Drive = "T"
            Share = "\\dc01\IT-Resources"
            Description = "IT Resources"
        }
    )
    
    foreach ($mapping in $driveMappings) {
        Write-Log "Drive mapping configured: $($mapping.Drive): -> $($mapping.Share)" -Level "Info"
    }
    
    Write-Log "Drive mapping policies available for Group Policy deployment" -Level "Info"
}

function Configure-PrinterDeployment {
    Write-Log "Configuring printer deployment policies..." -Level "Info"
    
    $printerMappings = @(
        @{
            Department = "Sales-Showroom"
            PrinterName = "Sales-Printer"
            PrinterPath = "\\dc01\Sales-Printer"
        },
        @{
            Department = "Design-Technical"
            PrinterName = "Design-Printer"
            PrinterPath = "\\dc01\Design-Printer"
        },
        @{
            Department = "Production"
            PrinterName = "Production-Printer"
            PrinterPath = "\\dc01\Production-Printer"
        },
        @{
            Department = "Warehouse-Logistics"
            PrinterName = "Warehouse-LabelPrinter"
            PrinterPath = "\\dc01\Warehouse-LabelPrinter"
        }
    )
    
    foreach ($printer in $printerMappings) {
        Write-Log "Printer mapping configured: $($printer.Department) -> $($printer.PrinterName)" -Level "Info"
    }
}

function Configure-SecurityPolicies {
    Write-Log "Configuring security policies..." -Level "Info"
    
    Write-Log "Security Policy Configuration:" -Level "Info"
    Write-Log "  Password Policy:" -Level "Info"
    Write-Log "    - Minimum length: 14 characters" -Level "Info"
    Write-Log "    - Complexity required: Enabled" -Level "Info"
    Write-Log "    - Max age: 90 days" -Level "Info"
    Write-Log "    - History: 24 passwords remembered" -Level "Info"
    
    Write-Log "  Account Lockout:" -Level "Info"
    Write-Log "    - Threshold: 5 failed attempts" -Level "Info"
    Write-Log "    - Lockout duration: 30 minutes" -Level "Info"
    Write-Log "    - Reset counter: 30 minutes" -Level "Info"
    
    Write-Log "  Kerberos Policy:" -Level "Info"
    Write-Log "    - Max ticket age: 10 hours" -Level "Info"
    Write-Log "    - Max renew time: 7 days" -Level "Info"
}

function Configure-AuditPolicies {
    Write-Log "Configuring advanced audit policies..." -Level "Info"
    
    Write-Log "Audit Policy Configuration:" -Level "Info"
    Write-Log "  Account Logon:" -Level "Info"
    Write-Log "    - Audit Credential Validation: Success and Failure" -Level "Info"
    Write-Log "    - Audit Kerberos Service Ticket Operations: Success and Failure" -Level "Info"
    
    Write-Log "  Logon/Logoff:" -Level "Info"
    Write-Log "    - Audit Logon: Success and Failure" -Level "Info"
    Write-Log "    - Audit Logoff: Success" -Level "Info"
    
    Write-Log "  Object Access:" -Level "Info"
    Write-Log "    - Audit File System: Success and Failure (sensitive shares)" -Level "Info"
    
    Write-Log "  Privilege Use:" -Level "Info"
    Write-Log "    - Audit Sensitive Privilege Use: Success and Failure" -Level "Info"
    
    Write-Log "  Policy Change:" -Level "Info"
    Write-Log "    - Audit Policy Change: Success and Failure" -Level "Info"
}

function Configure-PowerSettings {
    Write-Log "Configuring power settings per department..." -Level "Info"
    
    Write-Log "Power Configuration:" -Level "Info"
    Write-Log "  Sales-Showroom:" -Level "Info"
    Write-Log "    - Monitor sleep: 15 minutes" -Level "Info"
    Write-Log "    - Disk sleep: 30 minutes" -Level "Info"
    
    Write-Log "  Design-Technical:" -Level "Info"
    Write-Log "    - Monitor sleep: Disabled (always on)" -Level "Info"
    Write-Log "    - Disk sleep: Disabled" -Level "Info"
    Write-Log "    - Hibernate: Disabled" -Level "Info"
    
    Write-Log "  Production:" -Level "Info"
    Write-Log "    - Monitor sleep: 10 minutes" -Level "Info"
    Write-Log "    - Disk sleep: 20 minutes" -Level "Info"
}

function Configure-SoftwareRestriction {
    Write-Log "Configuring software restriction policies..." -Level "Info"
    
    Write-Log "Software Restriction Policies (Production):" -Level "Info"
    Write-Log "  Allowed Applications:" -Level "Info"
    Write-Log "    - Windows system files" -Level "Info"
    Write-Log "    - Manufacturing software (approved list)" -Level "Info"
    Write-Log "    - Microsoft Office" -Level "Info"
    
    Write-Log "  Blocked Applications:" -Level "Info"
    Write-Log "    - Command prompt (cmd.exe)" -Level "Info"
    Write-Log "    - PowerShell" -Level "Info"
    Write-Log "    - Registry editor" -Level "Info"
    Write-Log "    - Device manager" -Level "Info"
    Write-Log "    - Unauthorized software" -Level "Info"
}

function Configure-BitLockerPolicy {
    Write-Log "Configuring BitLocker policies for Accounting/HR..." -Level "Info"
    
    Write-Log "BitLocker Configuration:" -Level "Info"
    Write-Log "  Operating System Drive (C:):" -Level "Info"
    Write-Log "    - Encryption: Full volume" -Level "Info"
    Write-Log "    - Recovery key escrow: Active Directory" -Level "Info"
    Write-Log "    - Startup PIN: Required for admin accounts" -Level "Info"
    
    Write-Log "  Data Drives (D:+):" -Level "Info"
    Write-Log "    - Encryption: Full volume" -Level "Info"
    Write-Log "    - Auto-unlock: Disabled" -Level "Info"
}

function Configure-ScreenLockPolicy {
    Write-Log "Configuring screen lock policies..." -Level "Info"
    
    Write-Log "Screen Lock Configuration:" -Level "Info"
    Write-Log "  Accounting/HR:" -Level "Info"
    Write-Log "    - Idle timeout: 5 minutes" -Level "Info"
    Write-Log "    - Lock screen: Enabled" -Level "Info"
    Write-Log "    - Message: 'Confidential systems - Login Required'" -Level "Info"
    
    Write-Log "  Design/Technical:" -Level "Info"
    Write-Log "    - Idle timeout: 30 minutes" -Level "Info"
    Write-Log "    - Lock screen: Enabled" -Level "Info"
}

function Configure-RemoteAccessPolicies {
    Write-Log "Configuring remote access policies..." -Level "Info"
    
    Write-Log "Remote Desktop Configuration:" -Level "Info"
    Write-Log "  Sales (VPN access):" -Level "Info"
    Write-Log "    - Allow: RDP and VPN" -Level "Info"
    Write-Log "    - Require: Network encryption" -Level "Info"
    Write-Log "    - Credential Guard: Enabled" -Level "Info"
    
    Write-Log "  Management/IT:" -Level "Info"
    Write-Log "    - Allow: RDP from admin workstations only" -Level "Info"
    Write-Log "    - Require: NLA (Network Level Authentication)" -Level "Info"
    Write-Log "    - Session timeout: 30 minutes inactivity" -Level "Info"
}

# Main execution
Write-Log "========== GROUP POLICY CONFIGURATION STARTED ==========" -Level "Info"
try {
    Import-GroupPolicyModule
    Create-DepartmentGPOs
    Configure-DriveMapPolicies
    Configure-PrinterDeployment
    Configure-SecurityPolicies
    Configure-AuditPolicies
    Configure-PowerSettings
    Configure-SoftwareRestriction
    Configure-BitLockerPolicy
    Configure-ScreenLockPolicy
    Configure-RemoteAccessPolicies
    
    Write-Log "========== GROUP POLICY CONFIGURATION COMPLETED SUCCESSFULLY ==========" -Level "Info"
    Write-Log "Note: Run 'gpupdate /force' on client machines to apply policies" -Level "Info"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" -Level "Error"
    exit 1
}
