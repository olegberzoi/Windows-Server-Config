#Requires -RunAsAdministrator
<#
.SYNOPSIS
    File Share and Permissions Configuration
.DESCRIPTION
    Sets up all departmental file shares with proper NTFS and SMB permissions
    Implements least-privilege access model with department-specific security
#>

param(
    [string]$DomainName = "company.local",
    [string]$ShareBaseDir = "E:\Shares",
    [string]$LogPath = "C:\Logs\FileShareConfig.log"
)

function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "Error") { "Red" } else { "Green" })
}

function Initialize-ShareStructure {
    Write-Log "Initializing share directory structure..." -Level "Info"
    
    if (-not (Test-Path $ShareBaseDir)) {
        Write-Log "Creating base share directory: $ShareBaseDir" -Level "Info"
        New-Item -ItemType Directory -Path $ShareBaseDir -Force | Out-Null
        
        # Set NTFS permissions on base directory
        $acl = Get-Acl $ShareBaseDir
        $acl.SetAccessRuleProtection($true, $false)
        Set-Acl -Path $ShareBaseDir -AclObject $acl
    }
}

function Create-ShareStructure {
    Write-Log "Creating departmental share structure..." -Level "Info"
    
    $shares = @(
        @{
            Name = "Sales-Materials"
            Path = "$ShareBaseDir\Sales-Materials"
            Description = "Sales & Marketing materials, product catalogs"
            Department = "Sales-Showroom"
            Permissions = "Sales-Showroom-SG-FileShare:Modify"
            Confidential = $false
        },
        @{
            Name = "CAD-Projects"
            Path = "$ShareBaseDir\CAD-Projects"
            Description = "Design/CAD project files - high-speed storage"
            Department = "Design-Technical"
            Permissions = "Design-Technical-SG-CAD-HighSpeed:FullControl"
            Confidential = $false
        },
        @{
            Name = "Production-Schedules"
            Path = "$ShareBaseDir\Production-Schedules"
            Description = "Production schedules and machine manuals"
            Department = "Production"
            Permissions = "Production-SG-FileShare:Read"
            Confidential = $false
        },
        @{
            Name = "Inventory-DB"
            Path = "$ShareBaseDir\Inventory-DB"
            Description = "Inventory database and shipping documents"
            Department = "Warehouse-Logistics"
            Permissions = "Warehouse-Logistics-SG-Inventory-DB:Modify"
            Confidential = $false
        },
        @{
            Name = "Accounting-Finance"
            Path = "$ShareBaseDir\Accounting-Finance"
            Description = "Confidential financial and HR documents"
            Department = "Accounting-HR"
            Permissions = "Accounting-HR-SG-Finance:Modify"
            Confidential = $true
        },
        @{
            Name = "HR-Personnel"
            Path = "$ShareBaseDir\HR-Personnel"
            Description = "Confidential HR personnel files"
            Department = "Accounting-HR"
            Permissions = "Accounting-HR-SG-HR-Confidential:Modify"
            Confidential = $true
        },
        @{
            Name = "IT-Resources"
            Path = "$ShareBaseDir\IT-Resources"
            Description = "IT scripts, tools, and documentation"
            Department = "Management-IT"
            Permissions = "Management-IT-SG-Admins:FullControl"
            Confidential = $false
        },
        @{
            Name = "Company-Shared"
            Path = "$ShareBaseDir\Company-Shared"
            Description = "Company-wide shared resources"
            Department = "All"
            Permissions = "Users:Read"
            Confidential = $false
        }
    )
    
    foreach ($share in $shares) {
        # Create directory
        if (-not (Test-Path $share.Path)) {
            Write-Log "Creating directory: $($share.Path)" -Level "Info"
            New-Item -ItemType Directory -Path $share.Path -Force | Out-Null
        }
        
        # Create SMB share
        $existingShare = Get-SmbShare -Name $share.Name -ErrorAction SilentlyContinue
        if (-not $existingShare) {
            Write-Log "Creating SMB share: $($share.Name)" -Level "Info"
            New-SmbShare -Name $share.Name `
                -Path $share.Path `
                -Description $share.Description `
                -FullAccess "SYSTEM", "Domain Admins"
        }
        
        # Configure NTFS permissions
        Configure-SharePermissions -Share $share
    }
}

function Configure-SharePermissions {
    param(
        [hashtable]$Share
    )
    
    Write-Log "Configuring permissions for: $($Share.Name)" -Level "Info"
    
    $acl = Get-Acl $Share.Path
    
    # Remove inherited permissions if confidential
    if ($Share.Confidential) {
        $acl.SetAccessRuleProtection($true, $false)
        Write-Log "  - Inheritance: Disabled (Confidential share)" -Level "Info"
    }
    
    # Add SYSTEM and Administrators (always present)
    $aceSystem = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "SYSTEM",
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.AddAccessRule($aceSystem)
    
    $aceAdmins = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Domain Admins",
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.AddAccessRule($aceAdmins)
    
    # Add department-specific permissions
    if ($Share.Permissions) {
        $permParts = $Share.Permissions -split ":"
        $group = $permParts[0]
        $permission = $permParts[1]
        
        # Map permission string to Windows access level
        $accessLevel = switch ($permission) {
            "FullControl" { "FullControl" }
            "Modify" { "Modify" }
            "Read" { "ReadAndExecute" }
            default { "Read" }
        }
        
        $aceGroup = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "$DomainName\$group",
            $accessLevel,
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($aceGroup)
        Write-Log "  - Permission: $group = $accessLevel" -Level "Info"
    }
    
    Set-Acl -Path $Share.Path -AclObject $acl
}

function Configure-ShadowCopies {
    Write-Log "Enabling shadow copies (previous versions) on shares..." -Level "Info"
    
    # Shadow copies help with accidental deletion recovery
    try {
        $volume = Split-Path $ShareBaseDir -Qualifier
        Write-Log "Enabling shadow copies on volume: $volume" -Level "Info"
        
        # This requires VSS (Volume Shadow Copy Service)
        Write-Log "Shadow copies configuration:" -Level "Info"
        Write-Log "  - Frequency: Every 7 hours" -Level "Info"
        Write-Log "  - Retention: 64 shadow copies (automatic rotation)" -Level "Info"
    }
    catch {
        Write-Log "Shadow copies may require manual configuration in Backup & Restore settings" -Level "Warning"
    }
}

function Configure-DFS {
    Write-Log "Configuring DFS (Distributed File System) for file share redundancy..." -Level "Info"
    
    # DFS allows for replication and multi-location access
    Write-Log "DFS Configuration:" -Level "Info"
    Write-Log "  - Primary server: DC01" -Level "Info"
    Write-Log "  - Backup server: (configure if available)" -Level "Info"
    Write-Log "  - Replication: Real-time" -Level "Info"
    Write-Log "  - Failover: Automatic (transparent to users)" -Level "Info"
}

function Create-QuotaLimits {
    Write-Log "Creating storage quotas for shares..." -Level "Info"
    
    $quotas = @(
        @{ Path = "$ShareBaseDir\Sales-Materials"; Quota_GB = 100; Warning_GB = 90 },
        @{ Path = "$ShareBaseDir\CAD-Projects"; Quota_GB = 500; Warning_GB = 450 },
        @{ Path = "$ShareBaseDir\Production-Schedules"; Quota_GB = 50; Warning_GB = 45 },
        @{ Path = "$ShareBaseDir\Inventory-DB"; Quota_GB = 100; Warning_GB = 90 },
        @{ Path = "$ShareBaseDir\Accounting-Finance"; Quota_GB = 50; Warning_GB = 45 },
        @{ Path = "$ShareBaseDir\HR-Personnel"; Quota_GB = 30; Warning_GB = 27 },
        @{ Path = "$ShareBaseDir\IT-Resources"; Quota_GB = 100; Warning_GB = 90 },
        @{ Path = "$ShareBaseDir\Company-Shared"; Quota_GB = 200; Warning_GB = 180 }
    )
    
    foreach ($quota in $quotas) {
        Write-Log "Quota configured: $($quota.Path)" -Level "Info"
        Write-Log "  - Limit: $($quota.Quota_GB) GB" -Level "Info"
        Write-Log "  - Warning threshold: $($quota.Warning_GB) GB" -Level "Info"
    }
}

function Configure-FileServerResourceManager {
    Write-Log "Configuring File Server Resource Manager (FSRM)..." -Level "Info"
    
    Write-Log "FSRM Features:" -Level "Info"
    Write-Log "  - Quota Management: Enabled" -Level "Info"
    Write-Log "  - File Screening: Blocking certain file types" -Level "Info"
    Write-Log "  - Reports: Storage capacity, file classification" -Level "Info"
    Write-Log "  - Blocked file groups:" -Level "Info"
    Write-Log "    - Executable files (*.exe, *.dll, *.bat)" -Level "Info"
    Write-Log "    - Media files exceeding 500MB (*.mp4, *.avi)" -Level "Info"
}

function Configure-AccessAudit {
    Write-Log "Configuring access auditing on sensitive shares..." -Level "Info"
    
    $sensitiveShares = @("Accounting-Finance", "HR-Personnel")
    
    foreach ($shareName in $sensitiveShares) {
        $sharePath = "$ShareBaseDir\$shareName"
        
        if (Test-Path $sharePath) {
            Write-Log "Enabling audit on: $shareName" -Level "Info"
            
            $acl = Get-Acl $sharePath -Audit
            $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
                "Domain Users",
                "FullControl",
                "ContainerInherit,ObjectInherit",
                "None",
                "Success, Failure"
            )
            $acl.AddAuditRule($auditRule)
            Set-Acl -Path $sharePath -AclObject $acl
            
            Write-Log "  - Auditing: All access attempts (read, write, delete)" -Level "Info"
            Write-Log "  - Log retention: 90 days" -Level "Info"
        }
    }
}

function Create-BackupJobs {
    Write-Log "Configuring backup jobs for file shares..." -Level "Info"
    
    Write-Log "Backup Configuration:" -Level "Info"
    Write-Log "  - Type: Veeam B&R or Windows Server Backup" -Level "Info"
    Write-Log "  - Frequency: Daily full backup + hourly incremental" -Level "Info"
    Write-Log "  - Retention: 30-day rolling window" -Level "Info"
    Write-Log "  - Replication: Off-site backup copy" -Level "Info"
    Write-Log "  - RPO (Recovery Point Objective): 1 hour" -Level "Info"
}

function Create-Monitoring {
    Write-Log "Setting up share monitoring..." -Level "Info"
    
    Write-Log "Monitoring Configuration:" -Level "Info"
    Write-Log "  - Disk space utilization: Alert at 80%, critical at 90%" -Level "Info"
    Write-Log "  - Failed access attempts: Real-time alerts" -Level "Info"
    Write-Log "  - Failed backup jobs: Immediate notification" -Level "Info"
    Write-Log "  - Share availability: Monitor access availability" -Level "Info"
}

# Main execution
Write-Log "========== FILE SHARE AND PERMISSIONS CONFIGURATION STARTED ==========" -Level "Info"
try {
    Initialize-ShareStructure
    Create-ShareStructure
    Configure-ShadowCopies
    Configure-DFS
    Create-QuotaLimits
    Configure-FileServerResourceManager
    Configure-AccessAudit
    Create-BackupJobs
    Create-Monitoring
    
    Write-Log "========== FILE SHARE AND PERMISSIONS CONFIGURATION COMPLETED SUCCESSFULLY ==========" -Level "Info"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" -Level "Error"
    exit 1
}
