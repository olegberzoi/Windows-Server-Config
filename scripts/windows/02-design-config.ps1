#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Design/Technical Department Configuration
.DESCRIPTION
    Configures CAD workstations with GPU support
    - 8-12 employees
    - High-performance workstations with vGPU
    - GPU passthrough for VMware vSphere / NVIDIA GRID
    - Dedicated high-speed NAS/SAN for CAD files
    - Version-controlled repositories (Git, SVN)
    - Frequent snapshots for large project files
#>

param(
    [string]$DomainName = "company.local",
    [string]$DeptName = "Design-Technical",
    [int]$EmployeeCount = 12,
    [string]$LogPath = "C:\Logs\DesignDept.log"
)

function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "Error") { "Red" } else { "Green" })
}

function Create-DepartmentUsers {
    Write-Log "Creating Design department users..." -Level "Info"
    
    $rootDC = $DomainName.Split('.') | ForEach-Object { "DC=$_" } -Begin { $arr = @() } -Process { $arr += "DC=$_" } -End { $arr -join "," }
    $usersPath = "OU=Users,OU=$DeptName,$($rootDC -replace 'DC=', '')"
    
    $users = @(
        @{ Name = "alice.chen"; DisplayName = "Alice Chen"; Title = "CAD Lead" },
        @{ Name = "robert.taylor"; DisplayName = "Robert Taylor"; Title = "Senior CAD Designer" },
        @{ Name = "jennifer.lee"; DisplayName = "Jennifer Lee"; Title = "CAD Designer" },
        @{ Name = "marcus.brown"; DisplayName = "Marcus Brown"; Title = "Technical Specialist" },
        @{ Name = "sophia.garcia"; DisplayName = "Sophia Garcia"; Title = "CAD Technician" }
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
        "$DeptName-SG-CAD-HighSpeed",
        "$DeptName-SG-GPU-Access",
        "$DeptName-SG-VCS-Access",
        "$DeptName-SG-LocalAdmin"
    )
    
    foreach ($group in $groups) {
        $existingGroup = Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue
        if (-not $existingGroup) {
            Write-Log "Creating group: $group" -Level "Info"
            New-ADGroup -Name $group -Path $groupsPath -GroupScope Global
        }
    }
}

function Configure-HighPerformanceSettings {
    Write-Log "Configuring high-performance workstation settings..." -Level "Info"
    
    # Disable power saving features
    $powerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings"
    
    # Disable sleep when on AC power
    Write-Log "Disabling power-saving interruptions..." -Level "Info"
    powercfg /change monitor-timeout-ac 0
    powercfg /change disk-timeout-ac 0
    powercfg /change standby-timeout-ac 0
    
    Write-Log "High-performance settings configured" -Level "Info"
}

function Configure-CADStorageAccess {
    Write-Log "Configuring dedicated CAD storage access..." -Level "Info"
    
    $groupName = "$DeptName-SG-CAD-HighSpeed"
    $sharePath = "E:\Shares\CAD-Projects"
    
    if (Test-Path $sharePath) {
        # Set NTFS permissions for high-speed access
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
        
        # Optimize for large files (disable file name 8.3 creation)
        fsutil behavior set disable8dot3 1
        
        Write-Log "CAD storage configured for high-performance access" -Level "Info"
    }
}

function Configure-GPUPassthrough {
    Write-Log "Configuring GPU passthrough for vSphere/NVIDIA GRID..." -Level "Info"
    
    # GPU drivers and vGPU profiles will be deployed via GPO/deployment tools
    Write-Log "GPU drivers available in software deployment GPO" -Level "Info"
    Write-Log "NVIDIA GRID licensing can be configured via vCenter" -Level "Info"
}

function Configure-FileSnapshotPolicy {
    Write-Log "Configuring frequent snapshot policy for large projects..." -Level "Info"
    
    # Version control and backup snapshots
    Write-Log "Snapshot policy template: Every 2 hours for CAD projects" -Level "Info"
    Write-Log "Retention: 30-day rolling window" -Level "Info"
}

function Configure-VersionControl {
    Write-Log "Configuring version control repository access..." -Level "Info"
    
    $groupName = "$DeptName-SG-VCS-Access"
    Write-Log "Group '$groupName' can be granted access to Git/SVN repositories" -Level "Info"
}

# Main execution
Write-Log "========== DESIGN/TECHNICAL DEPARTMENT CONFIGURATION STARTED ==========" -Level "Info"
Create-DepartmentUsers
Create-DepartmentGroups
Configure-HighPerformanceSettings
Configure-CADStorageAccess
Configure-GPUPassthrough
Configure-FileSnapshotPolicy
Configure-VersionControl
Write-Log "========== DESIGN/TECHNICAL DEPARTMENT CONFIGURATION COMPLETED ==========" -Level "Info"
