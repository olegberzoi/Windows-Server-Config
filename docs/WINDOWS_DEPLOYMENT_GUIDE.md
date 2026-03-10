# Windows Server Enterprise Infrastructure Deployment Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Pre-Deployment Checklist](#pre-deployment-checklist)
4. [Installation Order](#installation-order)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [Troubleshooting](#troubleshooting)
7. [Maintenance](#maintenance)
8. [Disaster Recovery](#disaster-recovery)

---

## Overview

This comprehensive Windows Server configuration provides enterprise infrastructure for 70-100+ employees across 6 departments:

- **Sales & Showroom**: 10-15 employees - Kiosk/demo PCs, limited install rights
- **Design/Technical**: 8-12 employees - CAD workstations with vGPU support
- **Production**: 25-40 employees - Locked-down systems, ERP integration, shift tracking
- **Warehouse & Logistics**: 8-15 employees - Mobile/tablet profiles, inventory management, VLAN segmentation
- **Accounting/HR**: 5-8 employees - Maximum security with BitLocker, MFA, DLP
- **Management/IT**: 4-6 employees - Admin tiering, privileged access management

### Key Features
- ✅ Multi-tenant Active Directory with department OUs
- ✅ Group Policy enforcement per department
- ✅ Role-based file share access control
- ✅ Centralized printer management with quotas
- ✅ Security baselines (BitLocker, LAPS, audit logging)
- ✅ Prometheus/Grafana monitoring
- ✅ Veeam backup and disaster recovery
- ✅ DLP and MFA for sensitive departments

---

## Architecture

### Network Layout

```
Domain: company.local
Forest Functional Level: Windows Server 2019+

Network Classes:
├─ 172.16.0.0/16 (Primary network)
│  ├─ 172.16.0.1 - Router/Gateway
│  ├─ 172.16.1.10 - DC01 (Primary Domain Controller)
│  ├─ 172.16.1.20 - Prometheus Server
│  └─ 172.16.1.25 - Grafana Server
│
├─ File Shares:
│  ├─ E:\Shares\Sales-Materials
│  ├─ E:\Shares\CAD-Projects
│  ├─ E:\Shares\Production-Schedules
│  ├─ E:\Shares\Inventory-DB
│  ├─ E:\Shares\Accounting-Finance
│  └─ E:\Shares\IT-Resources
│
└─ VLAN Configuration (Warehouse):
   ├─ VLAN 100: Warehouse Employees (172.16.100.0/24)
   ├─ VLAN 101: Handheld Scanners (172.16.101.0/24)
   ├─ VLAN 102: RFID Readers (172.16.102.0/24)
   └─ VLAN 103: Label Printers (172.16.103.0/24)
```

### Organizational Unit (OU) Structure

```
company.local
├── Departments
│   ├── Sales-Showroom
│   │   ├── Users
│   │   ├── Computers
│   │   ├── Groups
│   │   └── ServiceAccounts
│   ├── Design-Technical
│   ├── Production
│   ├── Warehouse-Logistics
│   ├── Accounting-HR
│   └── Management-IT
```

---

## Pre-Deployment Checklist

### Hardware Requirements
- [ ] Windows Server 2019 or 2022 (minimum 2 vCPU, 8 GB RAM)
- [ ] Static IP address assigned: 172.16.1.10
- [ ] E: drive/volume for file shares (minimum 1 TB)
- [ ] Network connectivity to all subnets
- [ ] Backup storage (NAS or SAN) for Veeam

### Software Requirements
- [ ] Windows Server Datacenter or Standard edition
- [ ] .NET Framework 4.7.2+
- [ ] PowerShell 5.1+
- [ ] RSAT (Remote Server Administration Tools)
- [ ] Group Policy Management Console (GPMC)

### Network Planning
- [ ] DHCP pool configured: 172.16.100.1 - 172.16.200.254
- [ ] DNS forwarders configured (external DNS)
- [ ] Firewall rules defined per department
- [ ] NTP (time synchronization) server specified
- [ ] VLAN trunk configured on network switches

### Documentation
- [ ] Admin credentials stored securely (password manager)
- [ ] Network topology diagram created
- [ ] Contact list for key personnel
- [ ] Backup of domain join passwords

---

## Installation Order

### Phase 1: Foundation (30-45 minutes)

#### Step 1: Run Main Setup Script
```powershell
cd C:\scripts\windows
./00-windows-setup.ps1 -DomainName "company.local" -DCIPAddress "172.16.1.10"
```

**What it does:**
- Validates prerequisites and OS version
- Installs required Windows features
- Deploys Active Directory Forest
- Creates OUs for all 6 departments
- Creates security groups
- Establishes file shares
- Configures DNS zones
- Initializes DHCP

**Reboot required:** Multiple reboots will occur (answer N when prompted for immediate reboot, reboot manually after script completion)

#### Step 2: Verify AD Forest
```powershell
# Check forest and domain setup
Get-ADForest
Get-ADDomain

# Verify OUs created
Get-ADOrganizationalUnit -Filter * | Select Name, DistinguishedName
```

### Phase 2: Department Configuration (60 minutes)

Run department scripts in any order:

```powershell
# Sales & Showroom
./01-sales-config.ps1 -DomainName "company.local"

# Design/Technical
./02-design-config.ps1 -DomainName "company.local"

# Production
./03-production-config.ps1 -DomainName "company.local"

# Warehouse & Logistics
./04-accounting-config.ps1 -DomainName "company.local"  # (This is actually warehouse config)

# Accounting & HR
./05-hr-accounting-config.ps1 -DomainName "company.local"

# Management & IT
./06-management-it-config.ps1 -DomainName "company.local"
```

**What it does for each:**
- Creates department users
- Creates security groups
- Sets up department-specific configurations
- Assigns relevant permissions

### Phase 3: Infrastructure Configuration (90 minutes)

#### Step 3: Configure Group Policies
```powershell
./07-gpo-configuration.ps1 -DomainName "company.local"
```

**Creates:**
- Department-level GPOs
- Drive mappings per department
- Printer deployments
- Security policies
- Power management
- Software restrictions

#### Step 4: Setup File Shares & Permissions
```powershell
./08-fileshare-permissions.ps1 -ShareBaseDir "E:\Shares"
```

**Creates:**
- Share directories with NTFS permissions
- Shadow copies for recovery
- Quotas per share
- Access audit trails

#### Step 5: Configure Print Services
```powershell
./09-print-services.ps1 -PrintServerHostname "DC01"
```

**Sets up:**
- Printer ports for all devices
- Print quotas per department
- GPO-based printer deployment
- Print job accounting

#### Step 6: Apply Security Baselines
```powershell
./10-security-baselines.ps1 -DomainName "company.local"
```

**Implements:**
- Password policies (14 chars, complexity, 90-day age)
- Account lockout (5 attempts, 30 min lockout)
- BitLocker policies
- USB restrictions (Accounting/HR)
- Advanced audit policies
- LAPS (Local Admin Password Solution)

#### Step 7: Configure Monitoring & Backup
```powershell
./11-monitoring-backup.ps1 -PrometheusServer "172.16.1.20" -GrafanaServer "172.16.1.25"
```

**Establishes:**
- Prometheus Windows Exporter agents
- Grafana dashboard templates
- Veeam backup jobs
- Disaster recovery procedures
- Alerting rules

---

## Post-Deployment Configuration

### 1. Client Workstation Join

Join workstations to the domain:

```powershell
# Using GUI:
Settings → System → About → Join to Domain

# Or via PowerShell:
Add-Computer -DomainName "company.local" -Credential "COMPANY\Administrator" -Restart
```

### 2. Update Group Policies on Clients

```powershell
# On client machines (requires Admin):
gpupdate /force /boot

# Verify applied policies:
Get-GPResultantSetOfPolicy -ReportType Html -Path "C:\GPReport.html"
```

### 3. Reset User Passwords

Users must change their initial temporary password on first login:

```powershell
# For bulk password reset:
$password = ConvertTo-SecureString "TempPassword123!@#" -AsPlainText -Force
$users = Get-ADUser -Filter "Department -eq 'Sales'" -SearchBase "OU=Users,OU=Sales-Showroom,OU=Departments,DC=company,DC=local"

foreach ($user in $users) {
    Set-ADAccountPassword -Identity $user -NewPassword $password -Reset
    Set-ADUser -Identity $user -ChangePasswordAtLogon $true
}
```

### 4. Test File Share Access

```powershell
# From client workstation:
# Map sales share
New-PSDrive -Name S -PSProvider FileSystem -Root "\\DC01\Sales-Materials" -Credential "COMPANY\salesperson1"

# Test access
Test-Path S:\
```

### 5. Configure Printer Drivers on Printers

Connect to network printers and:
1. Set IP addressing (DHCP or static)
2. Set printer name to match share name
3. Configure SNMPv3 for monitoring
4. Enable secure protocols (HTTPS)

### 6. Deploy Monitoring Agents

**On DC01:**
```powershell
# Install Windows Exporter
wget https://github.com/prometheus-community/windows_exporter/releases/download/v0.24.0/windows_exporter-0.24.0-amd64.msi
msiexec /i windows_exporter-0.24.0-amd64.msi --quiet

# Verify running
Get-Service windows_exporter
```

### 7. Configure Veeam Integration

1. Install Veeam Backup & Replication console
2. Create backup jobs for each VM
3. Set daily full + hourly incremental schedule
4. Configure replication to secondary site
5. Test restore procedures

### 8. Initial System Test

```powershell
# Verify core services
Get-Service ADDataStore, NTDS, DNS, DHCP, W32Time -ErrorAction SilentlyContinue

# Check AD replication
repadmin /replsummary

# Verify file shares
Get-SmbShare | Select Name, Path, Description

# Confirm printers
Get-Printer
```

---

## Troubleshooting

### AD Forest Deployment Issues

**Error: "Forest or domain already exists"**
```powershell
# Check existing forest
Get-ADForest
# If already installed, skip deployment step or remove and reinstall
```

**Error: "DNS zone not created"**
```powershell
# Manually create zone after forest deployment
Add-DnsServerPrimaryZone -Name "company.local" -ZoneFile "company.local.dns"
```

### Group Policy Not Applying

```powershell
# Force GPO update on client
gpupdate /force /boot

# Check applied policies
gpresult /h report.html /scope:computer

# Verify GPO linked to OU
Get-GPInheritance -Target "OU=Sales-Showroom,OU=Departments,DC=company,DC=local"
```

### File Share Access Denied

```powershell
# Check NTFS permissions
Get-Acl "E:\Shares\Sales-Materials" | Format-List

# Verify user is in group
Get-ADUser -Identity "johndoe" -Properties MemberOf
```

### Printer Not Connecting

```powershell
# Test network connectivity to printer
Test-NetConnection -ComputerName 172.16.2.50 -Port 9100

# Check printer queue
Get-PrinterQueue

# View recent print errors
Get-EventLog -LogName "Print Service" -Newest 10
```

### Users Can't Join Domain

```powershell
# Verify DC is reachable
nslookup company.local
Resolve-DnsName DC01.company.local

# Check AD authentication
Get-ADUser -Identity "Administrator"

# Verify OU exists
Get-ADOrganizationalUnit -Filter "Name -eq 'Sales-Showroom'"
```

### Backup Jobs Failing

```powershell
# Check Veeam service
Get-Service Veeam* | Select Status

# Test backup network connectivity
Test-NetConnection -ComputerName 172.16.1.10 -Port 6160

# Check C: drive space (backups need temp space)
Get-Volume C
```

---

## Maintenance

### Weekly Tasks

- [ ] Check backup job status (all completed successfully)
- [ ] Monitor disk space on E: share (alert at 80%)
- [ ] Review failed logon attempts (Event Log)
- [ ] Verify all services running:
  ```powershell
  Get-Service NTDS, DNS, DHCP, SPOOLER, W32Time
  ```

### Monthly Tasks

- [ ] Test disaster recovery procedures
- [ ] Verify FSMO role holders
  ```powershell
  netdom query fsmo
  ```
- [ ] Run AD health check
  ```powershell
  Import-Module ActiveDirectory
  Get-ADDomainController | Select Name, OperatingSystem
  ```
- [ ] Review audit logs for security events
- [ ] Update firewall rules based on access logs

### Quarterly Tasks

- [ ] Full AD backup test (restore to test environment)
- [ ] Disaster recovery drill (failover to secondary DC)
- [ ] Capacity planning review (growth projections)
- [ ] Security policy review and updates
- [ ] User access reviews (remove stale accounts)

### Annual Tasks

- [ ] Windows Server patching and testing
- [ ] AD forest/domain functional level upgrade assessment
- [ ] Security hardening review
- [ ] Backup strategy evaluation
- [ ] Documentation and runbooks update

---

## Disaster Recovery

### Recovery Time Objectives (RTO)

| Component | RTO | RPO |
|-----------|-----|-----|
| Domain Controller | 4 hours | 1 hour |
| File Servers | 2 hours | 1 hour |
| User Workstations | Not applicable | 1 day * |
| File Shares | 15 minutes | 1 hour |

*Workstations can be reimaged from standard image; per-user data on file shares

### Failover Procedures

#### DC Failure
1. Boot secondary DC (if present) or restore from backup
2. Seize FSMO roles:
   ```powershell
   Move-ADDirectoryServerOperationMasterRole -Identity NewDC -OperationMasterRole SchemaMaster,DomainNamingMaster,PDCEmulator,RIDMaster,InfrastructureMaster
   ```
3. Update clients to use new DC in DNS suffix search
4. Restore primary DC from backup

#### File Share Failure
1. Initiate Veeam restore to alternate location
2. Verify file integrity
3. Update share path in GPO (if necessary)
4. Allow users to access recovered share

#### Complete Site Failure
1. Activate secondary site infrastructure
2. Update DNS records to secondary IP addresses
3. Notify all users of access method changes
4. Begin primary site recovery

---

## Support Contacts

**Infrastructure Team:** infrastructure@company.local  
**Primary Admin:** [Admin Name]  
**Backup Admin:** [Backup Admin Name]  
**After-hours Emergency:** [Emergency Phone]

---

## Change Log

| Date | Change | Owner | Approver |
|------|--------|-------|----------|
| 2026-03-10 | Initial deployment | Infrastructure | CTO |
|      |        |         |         |

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-10  
**Next Review:** 2026-09-10
