# Windows Server Configuration - Quick Reference Guide

## Script Overview

### Execution Order

```
1. 00-windows-setup.ps1 (FIRST - Foundation)
   └─ Creates AD Forest, OUs, shares, DNS, DHCP

2. Department Scripts (any order)
   ├─ 01-sales-config.ps1
   ├─ 02-design-config.ps1
   ├─ 03-production-config.ps1
   ├─ 04-accounting-config.ps1 (Warehouse)
   ├─ 05-hr-accounting-config.ps1
   └─ 06-management-it-config.ps1

3. Infrastructure Scripts
   ├─ 07-gpo-configuration.ps1
   ├─ 08-fileshare-permissions.ps1
   ├─ 09-print-services.ps1
   ├─ 10-security-baselines.ps1
   └─ 11-monitoring-backup.ps1
```

---

## Key Configuration Parameters

### Domain & Network
```powershell
$DomainName = "company.local"
$NetbiosName = "COMPANY"
$DCHostname = "DC01"
$DCIPAddress = "172.16.1.10"
$NetworkClass = "172.16.0.0"
$NetworkMask = "255.255.0.0"
```

### Storage Paths
```powershell
$ShareBaseDir = "E:\Shares"
$LogPath = "C:\Logs\ServerSetup.log"
```

### Monitoring & Backup
```powershell
$PrometheusServer = "172.16.1.20"
$PrometheusPort = 9090
$GrafanaServer = "172.16.1.25"
$GrafanaPort = 3000
```

---

## Department User Counts

| Department | Min | Max | Typical |
|------------|-----|-----|---------|
| Sales & Showroom | 10 | 15 | 13 |
| Design/Technical | 8 | 12 | 10 |
| Production | 25 | 40 | 32 |
| Warehouse & Logistics | 8 | 15 | 12 |
| Accounting/HR | 5 | 8 | 6 |
| Management/IT | 4 | 6 | 5 |
| **TOTAL** | **60** | **96** | **78** |

---

## File Shares Created

| Share Name | Path | Size | Department | Permissions |
|-----------|------|------|-----------|------------|
| Sales-Materials | E:\Shares\Sales-Materials | 100 GB | Sales | Modify |
| CAD-Projects | E:\Shares\CAD-Projects | 500 GB | Design | FullControl |
| Production-Schedules | E:\Shares\Production-Schedules | 50 GB | Production | Read |
| Inventory-DB | E:\Shares\Inventory-DB | 100 GB | Warehouse | Modify |
| Accounting-Finance | E:\Shares\Accounting-Finance | 50 GB | Accounting | Modify |
| HR-Personnel | E:\Shares\HR-Personnel | 30 GB | HR | Modify |
| IT-Resources | E:\Shares\IT-Resources | 100 GB | IT | FullControl |
| Company-Shared | E:\Shares\Company-Shared | 200 GB | All | Read |

---

## Printer Configuration

| Printer | Port | IP Address | Type | Department |
|---------|------|-----------|------|-----------|
| Sales-Printer | 9100 | 172.16.2.50 | A4 BW | Sales |
| Design-Printer | 9100 | 172.16.2.51 | Color/Large Format | Design |
| Production-Printer | 9100 | 172.16.2.52 | Multifunction | Production |
| Warehouse-LabelPrinter | 9100 | 172.16.2.53 | Industrial | Warehouse |
| Company-MainPrinter | 9100 | 172.16.2.60 | A4 BW | All |

---

## Security Groups per Department

Each department gets these groups:
- `{Dept}-SG-FileShare` - File share access
- `{Dept}-SG-Printers` - Printer access
- `{Dept}-SG-VPN` - VPN access (Sales)
- `{Dept}-SG-Admin` - Administrative access
- `{Dept}-SG-LocalAdmin` - Local admin on workstations
- `{Dept}-SG-{Department-Specific}` - Additional as needed

**Example (Sales):**
- Sales-Showroom-SG-FileShare
- Sales-Showroom-SG-Printers
- Sales-Showroom-SG-VPN

---

## Important Default Credentials

⚠️ **CHANGE BEFORE PRODUCTION**

| Account | Default | Notes |
|---------|---------|-------|
| Administrator | ChangeMe123!@# | Domain admin |
| User accounts | TempPassword123!@# | Users must change at first login |
| Service accounts | ServicePassword123!@# | Critical - change immediately |
| Veeam service | VeeamPassword123!@# | For backup operations |

---

## Security Policy Highlights

### Password Policy
- Minimum 14 characters
- Complexity required (Upper, Lower, Number, Special)
- Maximum age: 90 days
- History: 24 passwords

### Account Lockout
- Failed attempts: 5
- Lockout duration: 30 minutes
- Reset after: 30 minutes inactivity

### Audit Logging
- Logon events: Success & Failure
- File access: Sensitive shares only
- Privilege use: All elevated operations
- Retention: 90 days

### Advanced Security
- BitLocker: All critical servers
- LAPS: Automatic admin password rotation
- MFA: Required for Accounting/HR
- DLP: Financial/HR document protection

---

## Monitoring & Metrics

### Prometheus Exporters
- Windows Exporter (9182)
- Domain Controller metrics
- Disk, CPU, Memory, Network
- AD replication status

### Grafana Dashboards
1. Server Health (CPU, Memory, Disk I/O)
2. Active Directory Health (Replication, FSMO)
3. Network Performance (Bandwidth, Latency)
4. Application Availability (Service status)
5. Security Events (Failed logons, lockouts)
6. Backup Status (Job health, RPO)
7. Department Resource Usage

### Alert Thresholds
- CPU > 80% for 5 minutes → Warning
- Memory > 85% for 5 minutes → Warning
- Disk < 10% free → Critical
- Failed logons > 10 in 5 min → Critical
- AD Replication failure → Critical
- Backup failure → Critical

---

## Backup Configuration

### Backup Jobs
| Job | Target | Schedule | Retention | RPO |
|-----|--------|----------|-----------|-----|
| DC-FullBackup | NAS-Backup | Daily 23:00 | 30 days | 1 hour |
| FileServer-Incremental | NAS-Backup | Hourly + Full Sun | 30 days | 1 hour |
| Database-Backup | Fast-SAN | Every 4 hours | 7 days | 4 hours |

### Recovery Point Objectives (RPO)
- Critical systems: 1 hour
- File services: 1 hour
- General workstations: 1 day
- Off-site copy: 4 hours behind

---

## VLAN Configuration (Warehouse Only)

| VLAN | Network | Purpose | Devices |
|------|---------|---------|---------|
| 100 | 172.16.100.0/24 | Warehouse Staff | Workstations |
| 101 | 172.16.101.0/24 | Handheld Scanners | Mobile devices |
| 102 | 172.16.102.0/24 | RFID Readers | IoT devices |
| 103 | 172.16.103.0/24 | Label Printers | Printers |

---

## GPO Hierarchy

```
company.local
├── Organization Policy (Default Domain Policy)
│   ├── Sales-Showroom-Policy
│   │   ├── Drive mappings: S: → Sales-Materials
│   │   ├── Printers: Sales-Printer
│   │   └── Power settings: 15 min sleep
│   ├── Design-Technical-Policy
│   │   ├── Drive mappings: C: → CAD-Projects
│   │   ├── High-performance settings (no sleep)
│   │   └── GPU driver deployment
│   ├── Production-Policy
│   │   ├── Software restrictions (allowlist)
│   │   ├── Command shell disabled
│   │   └── Audit logon/logoff
│   ├── Warehouse-Logistics-Policy
│   │   ├── Mobile device profiles
│   │   └── Label printer access
│   ├── Accounting-HR-Policy
│   │   ├── BitLocker enforcement
│   │   ├── USB restrictions
│   │   └── Screen lock (5 min idle)
│   └── Management-IT-Policy
│       ├── Remote tools deployment
│       ├── Monitoring agent installation
│       └── Privileged access controls
```

---

## Common Commands

### Check AD Status
```powershell
Get-ADForest
Get-ADDomain
Get-ADDomainController
```

### Manage Users
```powershell
# Create user
New-ADUser -Name "John Smith" -SamAccountName "jsmith" -Path "OU=Users,OU=Sales-Showroom,OU=Departments,DC=company,DC=local"

# Reset password
Set-ADAccountPassword -Identity "jsmith" -NewPassword (ConvertTo-SecureString "NewPass123!@#" -AsPlainText -Force) -Reset

# Add to group
Add-ADGroupMember -Identity "Sales-Showroom-SG-FileShare" -Members "jsmith"
```

### Update Group Policies
```powershell
# On server
gpupdate /force

# On clients
gpupdate /force /boot

# Check applied policies
gpresult /h report.html /scope:computer
```

### Troubleshoot Replication
```powershell
repadmin /replsummary
repadmin /showrepl
```

### Check Services
```powershell
Get-Service NTDS, DNS, DHCP, SPOOLER, W32Time
```

---

## File Share Access Examples

### Map Share (PowerShell)
```powershell
New-PSDrive -Name S -PSProvider FileSystem -Root "\\DC01\Sales-Materials" `
  -Credential "COMPANY\username" -Persist
```

### Map Share (Windows Explorer)
```
This PC → Map network drive
Folder: \\DC01\Sales-Materials
☑ Reconnect at sign-in
```

---

## Disaster Recovery Checklist

- [ ] Backup jobs configured and running daily
- [ ] Off-site replication tested
- [ ] Secondary DC prepared (if applicable)
- [ ] Runbooks documented
- [ ] Recovery procedures tested monthly
- [ ] FSMO roles roles understood
- [ ] Emergency contacts posted
- [ ] Boot recovery media available

---

## Support Resources

| Resource | Location |
|----------|----------|
| Deployment Guide | `docs/WINDOWS_DEPLOYMENT_GUIDE.md` |
| Scripts | `scripts/windows/*.ps1` |
| Logs | `C:\Logs\*.log` |
| AD Schema | `%SystemRoot%\System32\config\AD` |
| Group Policies | `%SystemRoot%\System32\GroupPolicy` |

---

**Quick Start:**
```powershell
cd C:\scripts\windows
.\00-windows-setup.ps1 -DomainName "company.local"
```

Reboot after script completion, then run department configuration scripts.
