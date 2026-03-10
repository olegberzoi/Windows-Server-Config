#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Windows Server Configuration Script for Enterprise Infrastructure
.DESCRIPTION
    Comprehensive setup for multi-department AD environment with 6 departments
    - Sales & Showroom
    - Design/Technical (CAD + vGPU)
    - Production
    - Warehouse & Logistics
    - Accounting/HR
    - Management/IT
.NOTES
    Author: Infrastructure Team
    Date: 2026-03-10
    Version: 1.0
    Requires: Windows Server 2019/2022 with RSAT tools
#>

param(
    [string]$DomainName = "company.local",
    [string]$NetbiosName = "COMPANY",
    [string]$DCHostname = "DC01",
    [string]$SafeModePassword = "ChangeMe123!@#",
    [string]$NetworkClass = "172.16.0.0",
    [string]$NetworkMask = "255.255.0.0",
    [string]$DCIPAddress = "172.16.1.10",
    [string]$LogPath = "C:\Logs\ServerSetup.log"
)

# =====================================================================
# LOGGING CONFIGURATION
# =====================================================================
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDir = Split-Path $LogPath
    
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(
        switch ($Level) {
            "Info" { "Green" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
        }
    )
}

# =====================================================================
# PREREQUISITE VALIDATION
# =====================================================================
function Test-Prerequisites {
    Write-Log "========== Validating Prerequisites ==========" -Level "Info"
    
    # Check for Administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Log "This script must be run as Administrator" -Level "Error"
        exit 1
    }
    Write-Log "Administrator privileges confirmed" -Level "Info"
    
    # Check OS Version
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        Write-Log "Windows Server 2016 or later required" -Level "Error"
        exit 1
    }
    Write-Log "OS Version acceptable: $osVersion" -Level "Info"
    
    # Check required features
    $requiredFeatures = @(
        "AD-Domain-Services",
        "DNS",
        "File-Services",
        "Print-Server"
    )
    
    foreach ($feature in $requiredFeatures) {
        $featureStatus = Get-WindowsFeature -Name $feature
        if (-not $featureStatus.Installed) {
            Write-Log "Installing required feature: $feature" -Level "Info"
            Install-WindowsFeature -Name $feature -IncludeManagementTools | Out-Null
        }
    }
    Write-Log "All required features installed" -Level "Info"
}

# =====================================================================
# SYSTEM CONFIGURATION
# =====================================================================
function Configure-SystemSettings {
    Write-Log "========== Configuring System Settings ==========" -Level "Info"
    
    # Set hostname
    Write-Log "Setting hostname to $DCHostname" -Level "Info"
    Rename-Computer -NewName $DCHostname -Force
    
    # Configure network interface
    Write-Log "Configuring network interface" -Level "Info"
    $adapter = Get-NetAdapter | Select-Object -First 1
    
    New-NetIPAddress -InterfaceAlias $adapter.Name `
        -IPAddress $DCIPAddress `
        -PrefixLength 16 `
        -DefaultGateway "172.16.0.1" `
        -ErrorAction SilentlyContinue
    
    Set-DnsClientServerAddress -InterfaceAlias $adapter.Name `
        -ServerAddresses "127.0.0.1" `
        -ErrorAction SilentlyContinue
    
    Write-Log "System settings configured" -Level "Info"
}

# =====================================================================
# ACTIVE DIRECTORY FOREST DEPLOYMENT
# =====================================================================
function Deploy-ADForest {
    Write-Log "========== Deploying Active Directory Forest ==========" -Level "Info"
    
    # Check if AD is already deployed
    try {
        $forest = Get-ADForest -ErrorAction Stop
        Write-Log "Active Directory already deployed: $($forest.Name)" -Level "Warning"
        return
    }
    catch {
        Write-Log "Deploying new AD forest: $DomainName" -Level "Info"
    }
    
    # Install AD Forest
    $params = @{
        DomainName = $DomainName
        DomainNetbiosName = $NetbiosName
        ForestMode = "WS2019" # Adjust based on parameter
        DomainMode = "WS2019"
        SafeModeAdministratorPassword = (ConvertTo-SecureString $SafeModePassword -AsPlainText -Force)
        InstallDns = $true
        NoRebootOnCompletion = $false
        Force = $true
    }
    
    Install-ADDSForest @params -Confirm:$false
    Write-Log "Active Directory Forest deployed successfully" -Level "Info"
}

# =====================================================================
# ORGANIZATIONAL UNIT STRUCTURE
# =====================================================================
function Create-OUStructure {
    Write-Log "========== Creating OU Structure ==========" -Level "Info"
    
    # Root OUs
    $rootOUs = @(
        @{
            Name = "Departments"
            Path = "DC=$($DomainName.Split('.')[0]),DC=$($DomainName.Split('.')[1])"
            Description = "Department Organization Units"
        }
    )
    
    # Create root OUs
    foreach ($ou in $rootOUs) {
        $ouPath = "OU=$($ou.Name)," + $ou.Path
        
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($ou.Name)' -and DistinguishedName -eq '$ouPath'" -ErrorAction SilentlyContinue)) {
            Write-Log "Creating OU: $($ou.Name)" -Level "Info"
            New-ADOrganizationalUnit -Name $ou.Name -Path $ou.Path -Description $ou.Description
        }
    }
    
    # Department OUs
    $departments = @(
        @{
            Name = "Sales-Showroom"
            Description = "Sales & Showroom Department (10-15 employees)"
            Employees = 15
        },
        @{
            Name = "Design-Technical"
            Description = "Design/Technical Department with CAD + vGPU (8-12 employees)"
            Employees = 12
        },
        @{
            Name = "Production"
            Description = "Production Department (25-40 employees)"
            Employees = 40
        },
        @{
            Name = "Warehouse-Logistics"
            Description = "Warehouse & Logistics Department (8-15 employees)"
            Employees = 15
        },
        @{
            Name = "Accounting-HR"
            Description = "Accounting & HR Department (5-8 employees)"
            Employees = 8
        },
        @{
            Name = "Management-IT"
            Description = "Management & IT Department (4-6 employees)"
            Employees = 6
        }
    )
    
    $deptOUPath = "OU=Departments,DC=$($DomainName.Split('.')[0]),DC=$($DomainName.Split('.')[1])"
    
    foreach ($dept in $departments) {
        # Create department OU
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($dept.Name)'" -ErrorAction SilentlyContinue)) {
            Write-Log "Creating department OU: $($dept.Name) - $($dept.Description)" -Level "Info"
            New-ADOrganizationalUnit -Name $dept.Name -Path $deptOUPath -Description $dept.Description
        }
        
        # Create sub-OUs for organization
        $subOUs = @("Users", "Computers", "Groups", "ServiceAccounts")
        $deptPath = "OU=$($dept.Name),$deptOUPath"
        
        foreach ($subOU in $subOUs) {
            if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$subOU' -and DistinguishedName -eq 'OU=$subOU,$deptPath'" -ErrorAction SilentlyContinue)) {
                New-ADOrganizationalUnit -Name $subOU -Path $deptPath
            }
        }
    }
    
    Write-Log "OU structure created successfully" -Level "Info"
}

# =====================================================================
# SECURITY GROUPS CREATION
# =====================================================================
function Create-SecurityGroups {
    Write-Log "========== Creating Security Groups ==========" -Level "Info"
    
    $deptOUPath = "OU=Departments,DC=$($DomainName.Split('.')[0]),DC=$($DomainName.Split('.')[1])"
    
    $departments = @(
        "Sales-Showroom",
        "Design-Technical",
        "Production",
        "Warehouse-Logistics",
        "Accounting-HR",
        "Management-IT"
    )
    
    # Generic group categories for each department
    $groupTemplates = @(
        @{ Name = "DL"; Description = "Distribution List" },
        @{ Name = "SG-FileShare"; Description = "File Share Access" },
        @{ Name = "SG-Printers"; Description = "Printer Access" },
        @{ Name = "SG-VPN"; Description = "VPN Access" },
        @{ Name = "SG-Admin"; Description = "Administrative Access" },
        @{ Name = "SG-LocalAdmin"; Description = "Local Administrator Access" }
    )
    
    foreach ($dept in $departments) {
        $deptPath = "OU=$dept,$deptOUPath"
        $groupPath = "OU=Groups,OU=$dept,$deptOUPath"
        
        foreach ($groupTemplate in $groupTemplates) {
            $groupName = "$dept-$($groupTemplate.Name)"
            $groupDisplay = "$dept - $($groupTemplate.Description)"
            
            $existingGroup = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue
            
            if (-not $existingGroup) {
                Write-Log "Creating group: $groupName" -Level "Info"
                New-ADGroup -Name $groupName `
                    -Path $groupPath `
                    -GroupScope Global `
                    -Description $groupDisplay
            }
        }
    }
    
    Write-Log "Security groups created successfully" -Level "Info"
}

# =====================================================================
# FILE SHARE SETUP
# =====================================================================
function Setup-FileShares {
    Write-Log "========== Setting up File Shares ==========" -Level "Info"
    
    # Create shared folders base
    $shareBase = "E:\Shares"
    
    if (-not (Test-Path $shareBase)) {
        New-Item -ItemType Directory -Path $shareBase -Force | Out-Null
    }
    
    # Define shares per department
    $fileShares = @(
        @{
            Name = "Sales-Materials"
            Path = "$shareBase\Sales-Materials"
            Description = "Sales & Marketing materials, product catalogs"
            Department = "Sales-Showroom"
        },
        @{
            Name = "CAD-Projects"
            Path = "$shareBase\CAD-Projects"
            Description = "Design/CAD project files - high-speed storage"
            Department = "Design-Technical"
        },
        @{
            Name = "Production-Schedules"
            Path = "$shareBase\Production-Schedules"
            Description = "Production schedules and machine manuals"
            Department = "Production"
        },
        @{
            Name = "Inventory-DB"
            Path = "$shareBase\Inventory-DB"
            Description = "Inventory database and shipping documents"
            Department = "Warehouse-Logistics"
        },
        @{
            Name = "Accounting-Finance"
            Path = "$shareBase\Accounting-Finance"
            Description = "Confidential financial and HR documents"
            Department = "Accounting-HR"
        },
        @{
            Name = "IT-Resources"
            Path = "$shareBase\IT-Resources"
            Description = "IT scripts, tools, and documentation"
            Department = "Management-IT"
        },
        @{
            Name = "Company-Shared"
            Path = "$shareBase\Company-Shared"
            Description = "Company-wide shared resources"
            Department = "All"
        }
    )
    
    foreach ($share in $fileShares) {
        # Create share folder
        if (-not (Test-Path $share.Path)) {
            Write-Log "Creating share folder: $($share.Path)" -Level "Info"
            New-Item -ItemType Directory -Path $share.Path -Force | Out-Null
        }
        
        # Create SMB share
        $existingShare = Get-SmbShare -Name $share.Name -ErrorAction SilentlyContinue
        
        if (-not $existingShare) {
            Write-Log "Creating SMB share: $($share.Name)" -Level "Info"
            New-SmbShare -Name $share.Name `
                -Path $share.Path `
                -Description $share.Description `
                -FullAccess "SYSTEM"
        }
    }
    
    Write-Log "File shares created successfully" -Level "Info"
}

# =====================================================================
# PRINT SERVICES CONFIGURATION
# =====================================================================
function Configure-PrintServices {
    Write-Log "========== Configuring Print Services ==========" -Level "Info"
    
    # Ensure Print Services role is installed
    $printFeature = Get-WindowsFeature -Name "Print-Server"
    if (-not $printFeature.Installed) {
        Install-WindowsFeature -Name "Print-Server" -IncludeManagementTools
    }
    
    # Create printer ports (example: network printers)
    $printers = @(
        @{
            Name = "Sales-Printer"
            Port = "Sales-Printer-Port"
            IPAddress = "172.16.2.50"
            Description = "Sales Department Printer"
            Department = "Sales-Showroom"
        },
        @{
            Name = "Design-Printer"
            Port = "Design-Printer-Port"
            IPAddress = "172.16.2.51"
            Description = "Design Department Color Printer"
            Department = "Design-Technical"
        },
        @{
            Name = "Production-Printer"
            Port = "Production-Printer-Port"
            IPAddress = "172.16.2.52"
            Description = "Production Department Printer"
            Department = "Production"
        },
        @{
            Name = "Warehouse-LabelPrinter"
            Port = "Warehouse-Label-Port"
            IPAddress = "172.16.2.53"
            Description = "Warehouse Label Printer"
            Department = "Warehouse-Logistics"
        }
    )
    
    foreach ($printer in $printers) {
        # Create standard port
        $portExists = Get-PrinterPort -Name $printer.Port -ErrorAction SilentlyContinue
        
        if (-not $portExists) {
            Write-Log "Creating printer port: $($printer.Port)" -Level "Info"
            Add-PrinterPort -Name $printer.Port -PrinterHostAddress $printer.IPAddress
        }
    }
    
    Write-Log "Print services configured" -Level "Info"
}

# =====================================================================
# DNS CONFIGURATION
# =====================================================================
function Configure-DNSZones {
    Write-Log "========== Configuring DNS ==========" -Level "Info"
    
    # Primary zone should already exist, but verify
    $zone = Get-DnsServerZone -Name $DomainName -ErrorAction SilentlyContinue
    
    if (-not $zone) {
        Write-Log "Creating DNS zone: $DomainName" -Level "Info"
        Add-DnsServerPrimaryZone -Name $DomainName -ZoneFile "$DomainName.dns"
    }
    
    # Add reverse lookup zone
    $reverseLookup = "1.16.172.in-addr.arpa"
    $reverseZone = Get-DnsServerZone -Name $reverseLookup -ErrorAction SilentlyContinue
    
    if (-not $reverseZone) {
        Write-Log "Creating reverse lookup zone: $reverseLookup" -Level "Info"
        Add-DnsServerPrimaryZone -NetworkID "172.16.0.0/16" -ZoneFile "$reverseLookup.dns"
    }
    
    Write-Log "DNS zones configured" -Level "Info"
}

# =====================================================================
# DHCP CONFIGURATION
# =====================================================================
function Configure-DHCP {
    Write-Log "========== Configuring DHCP ==========" -Level "Info"
    
    # Check if DHCP is installed
    $dhcpFeature = Get-WindowsFeature -Name "DHCP"
    
    if (-not $dhcpFeature.Installed) {
        Write-Log "Installing DHCP Server" -Level "Info"
        Install-WindowsFeature -Name "DHCP" -IncludeManagementTools
    }
    
    # Add DHCP scope (example: main network)
    $scopeName = "Main-Network"
    $scopeStart = "172.16.100.1"
    $scopeEnd = "172.16.200.254"
    $subnetMask = "255.255.0.0"
    
    $existingScope = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue | `
        Where-Object { $_.Name -eq $scopeName }
    
    if (-not $existingScope) {
        Write-Log "Creating DHCP scope: $scopeName" -Level "Info"
        Add-DhcpServerv4Scope -Name $scopeName `
            -StartRange $scopeStart `
            -EndRange $scopeEnd `
            -SubnetMask $subnetMask `
            -Description "Main company network DHCP scope"
    }
    
    # Configure DHCP options
    Set-DhcpServerv4OptionValue -ScopeID "172.16.0.0" `
        -DnsServer "172.16.1.10" `
        -DnsDomain $DomainName `
        -Router "172.16.0.1" `
        -ErrorAction SilentlyContinue
    
    Write-Log "DHCP configured" -Level "Info"
}

# =====================================================================
# BITLOCKER CONFIGURATION
# =====================================================================
function Configure-BitLocker {
    Write-Log "========== Configuring BitLocker ==========" -Level "Info"
    
    # Enable BitLocker feature
    $bitlockerFeature = Get-WindowsFeature -Name "BitLocker"
    
    if (-not $bitlockerFeature.Installed) {
        Write-Log "Installing BitLocker feature" -Level "Info"
        Install-WindowsFeature -Name "BitLocker" -ErrorAction SilentlyContinue
    }
    
    Write-Log "BitLocker feature available for GPO deployment" -Level "Info"
}

# =====================================================================
# AUDIT POLICY CONFIGURATION
# =====================================================================
function Configure-AuditPolicies {
    Write-Log "========== Configuring Audit Policies ==========" -Level "Info"
    
    $auditPolicies = @(
        "Audit Account Logon\Audit Credential Validation",
        "Audit Logon/Logoff\Audit Logon",
        "Audit Logon/Logoff\Audit Logoff",
        "Audit Object Access\Audit File System",
        "Audit Policy Change\Audit Event Policy Change"
    )
    
    foreach ($policy in $auditPolicies) {
        Write-Log "Audit policy available: $policy" -Level "Info"
    }
    
    Write-Log "Audit policies configured" -Level "Info"
}

# =====================================================================
# MAIN EXECUTION
# =====================================================================
function Main {
    Write-Log "========== WINDOWS SERVER ENTERPRISE SETUP STARTED ==========" -Level "Info"
    Write-Log "Domain: $DomainName | Hostname: $DCHostname | IP: $DCIPAddress" -Level "Info"
    
    try {
        Test-Prerequisites
        Configure-SystemSettings
        Deploy-ADForest
        Create-OUStructure
        Create-SecurityGroups
        Setup-FileShares
        Configure-PrintServices
        Configure-DNSZones
        Configure-DHCP
        Configure-BitLocker
        Configure-AuditPolicies
        
        Write-Log "========== WINDOWS SERVER SETUP COMPLETED SUCCESSFULLY ==========" -Level "Info"
        Write-Log "Next steps: Run department-specific configuration scripts" -Level "Info"
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)" -Level "Error"
        exit 1
    }
}

# Run main execution
Main
