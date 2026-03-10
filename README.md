# Windows Server Enterprise Configuration Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://www.microsoft.com/powershell)
[![Windows Server: 2019+](https://img.shields.io/badge/Windows%20Server-2019%2B-0078D4.svg)](https://www.microsoft.com/windows-server)

A **comprehensive, production-ready PowerShell configuration suite** for deploying enterprise Windows Server infrastructure across multiple departments. Includes Active Directory setup, GPO management, file shares, print services, security baselines, monitoring integration, and disaster recovery procedures.

## 🎯 Features

### ✨ Complete Enterprise Infrastructure
- **Active Directory Forest** - Multi-tenant domain design (company.local)
- **6 Department OUs** - Separate organizational units per department with GPO inheritance
- **DNS & DHCP** - Automated network configuration (172.16.0.0/16)
- **File Shares** - 8 departmental shares (1+ TB) with NTFS permissions
- **Print Services** - 5 network printers with quota management
- **Security Baselines** - BitLocker, LAPS, audit logging, DLP policies
- **Monitoring** - Prometheus + Grafana integration
- **Backup/DR** - Veeam integration with RTO/RPO definitions

### 🏢 Department Configurations
- **Sales & Showroom** (10-15 users) - VPN, kiosk policies, limited installs
- **Design/Technical** (8-12 users) - CAD workstations, vGPU, high-speed storage
- **Production** (25-40 users) - PC lockdown, ERP integration, shift tracking
- **Warehouse & Logistics** (8-15 users) - Mobile profiles, VLAN IoT segmentation
- **Accounting & HR** (5-8 users) - BitLocker, MFA, DLP, confidential audit trails
- **Management/IT** (4-6 users) - Admin tiering, PAM, privileged access auditing

### 🔒 Security Features
- Password policies (14 chars, complexity, 90-day age)
- Account lockout (5 attempts, 30 min lockout)
- BitLocker encryption on sensitive systems
- USB device restrictions (Accounting/HR)
- LAPS (Local Administrator Password Solution)
- Multi-Factor Authentication ready
- Advanced Windows Event Auditing
- Data Loss Prevention (DLP) policies

## 📦 What's Included

```
windows-server-config/
├── scripts/
│   └── windows/
│       ├── 00-windows-setup.ps1              # Main foundation script
│       ├── 01-sales-config.ps1
│       ├── 02-design-config.ps1
│       ├── 03-production-config.ps1
│       ├── 04-accounting-config.ps1
│       ├── 05-hr-accounting-config.ps1
│       ├── 06-management-it-config.ps1
│       ├── 07-gpo-configuration.ps1
│       ├── 08-fileshare-permissions.ps1
│       ├── 09-print-services.ps1
│       ├── 10-security-baselines.ps1
│       └── 11-monitoring-backup.ps1
├── docs/
│   ├── WINDOWS_DEPLOYMENT_GUIDE.md           # Full deployment guide
│   ├── WINDOWS_QUICK_REFERENCE.md            # Quick reference
│   └── WINDOWS_ARCHITECTURE.md               # Architecture diagrams
└── README.md                                  # This file
```

## 🚀 Quick Start

### Prerequisites
- Windows Server 2019 or later
- Administrator privileges
- PowerShell 5.1+
- Static IP address (172.16.1.10 recommended)
- 1+ TB storage for file shares

### Installation (3-4 hours)

```powershell
# 1. Run main setup (45 minutes)
cd scripts\windows
.\00-windows-setup.ps1 -DomainName "company.local" -DCIPAddress "172.16.1.10"

# Reboot system when prompted

# 2. Run department configuration scripts (60 minutes)
.\01-sales-config.ps1
.\02-design-config.ps1
.\03-production-config.ps1
.\04-accounting-config.ps1
.\05-hr-accounting-config.ps1
.\06-management-it-config.ps1

# 3. Configure infrastructure (90 minutes)
.\07-gpo-configuration.ps1
.\08-fileshare-permissions.ps1
.\09-print-services.ps1
.\10-security-baselines.ps1
.\11-monitoring-backup.ps1
```

### Detailed Documentation

| Document | Purpose |
|----------|---------|
| [WINDOWS_DEPLOYMENT_GUIDE.md](docs/WINDOWS_DEPLOYMENT_GUIDE.md) | Complete step-by-step deployment with troubleshooting (10,000+ words) |
| [WINDOWS_QUICK_REFERENCE.md](docs/WINDOWS_QUICK_REFERENCE.md) | Quick commands and configuration reference (4,000+ words) |
| [WINDOWS_ARCHITECTURE.md](docs/WINDOWS_ARCHITECTURE.md) | System architecture and design documentation (6,000+ words) |

## 📊 Infrastructure Overview

### Network Layout
```
Internet
  └─→ Firewall
      └─→ Corporate Network (172.16.0.0/16)
          ├─→ DC01 (172.16.1.10) - Primary Domain Controller
          │   ├─ Active Directory
          │   ├─ DNS & DHCP
          │   ├─ File Shares (E:\Shares)
          │   └─ Print Server
          ├─→ Prometheus (172.16.1.20)
          ├─→ Grafana (172.16.1.25)
          ├─→ User Subnets (172.16.100-200.0/24)
          │   ├─ Sales (100)
          │   ├─ Design (101)
          │   ├─ Production (102)
          │   ├─ Warehouse (103)
          │   ├─ Accounting (104)
          │   └─ IT/Management (105)
          └─→ Network Printers (172.16.2.50-60)
```

### Organizational Units
```
company.local
└─ Departments/
   ├─ Sales-Showroom/
   │   ├─ Users/
   │   ├─ Computers/
   │   ├─ Groups/
   │   └─ ServiceAccounts/
   ├─ Design-Technical/
   ├─ Production/
   ├─ Warehouse-Logistics/
   ├─ Accounting-HR/
   └─ Management-IT/
```

## 🔑 Default Configuration Parameters

```powershell
$DomainName = "company.local"
$NetbiosName = "COMPANY"
$DCHostname = "DC01"
$DCIPAddress = "172.16.1.10"
$NetworkClass = "172.16.0.0"
$NetworkMask = "255.255.0.0"
$ShareBaseDir = "E:\Shares"
$PrometheusServer = "172.16.1.20"
$GrafanaServer = "172.16.1.25"
```

All parameters can be customized by modifying script variables.

## 📋 Deployment Checklist

- [ ] Windows Server 2019+ machine prepared
- [ ] Static IP configured (172.16.1.10)
- [ ] E: drive available for file shares (1+ TB)
- [ ] Network connectivity verified
- [ ] RSAT tools installed
- [ ] PowerShell execution policy set: `Set-ExecutionPolicy RemoteSigned`
- [ ] Run 00-windows-setup.ps1
- [ ] Reboot after setup completes
- [ ] Run all department scripts
- [ ] Run infrastructure scripts
- [ ] Join client workstations to domain
- [ ] Test file share and printer access

## 🔐 Security Policies

### Default Password Policy
- Minimum Length: 14 characters
- Complexity: Enabled (Upper, Lower, Number, Special)
- Maximum Age: 90 days
- History: 24 passwords remembered

### Account Lockout
- Failed Attempts: 5
- Lockout Duration: 30 minutes
- Reset Counter: 30 minutes inactivity

### Advanced Security
- **BitLocker**: Required for Accounting/HR
- **LAPS**: Automatic admin password rotation
- **MFA**: Available for Accounting/HR systems
- **DLP**: Financial/sensitive data protection
- **Audit Logging**: 90-day retention

## 📈 Monitoring & Alerting

### Prometheus Dashboards
1. Server Health (CPU, Memory, Disk I/O)
2. Active Directory Health (Replication, FSMO)
3. Network Performance (Bandwidth, Latency)
4. Application Availability (Service status)
5. Security Events (Failed logons, lockouts)
6. Backup Status (Job health, RPO)
7. Department Resource Usage

### Alert Thresholds
- CPU > 80% for 5 min → Warning
- Memory > 85% for 5 min → Warning
- Disk < 10% free → Critical
- Failed logons > 10 in 5 min → Critical
- AD Replication failure → Critical
- Backup job failure → Critical

## 💾 Backup & Disaster Recovery

### Backup Jobs
| Job | Target | Schedule | Retention | RPO |
|-----|--------|----------|-----------|-----|
| DC-FullBackup | NAS | Daily 23:00 | 30 days | 1 hour |
| FileServer-Incremental | NAS | Hourly + Full Sun | 30 days | 1 hour |
| Database-Backup | SAN | Every 4 hours | 7 days | 4 hours |

### Recovery Objectives
- **RTO** (Recovery Time Objective): 4 hours for critical systems
- **RPO** (Recovery Point Objective): 1 hour for file services
- **Off-site Backup**: 4 hours behind primary
- **DR Drills**: Monthly

## 🛠️ Customization

### Change Domain Name
Edit each script and update:
```powershell
-DomainName "yourdomain.local"
```

### Modify Network Configuration
```powershell
$NetworkClass = "192.168.0.0"
$DCIPAddress = "192.168.1.10"
$NetworkMask = "255.255.0.0"
```

### Adjust User Counts Per Department
Modify the `$EmployeeCount` parameter in each department script:
```powershell
.\01-sales-config.ps1 -EmployeeCount 20
```

## 📝 Logging

All scripts generate comprehensive logs:
```
C:\Logs\ServerSetup.log                    # Main setup
C:\Logs\SalesDept.log                      # Department configs
C:\Logs\GPOConfiguration.log               # GPO setup
C:\Logs\FileShareConfig.log                # File share setup
C:\Logs\PrintServiceConfig.log             # Print service setup
C:\Logs\SecurityBaselines.log              # Security policies
C:\Logs\MonitoringBackupConfig.log         # Monitoring setup
```

## 🐛 Troubleshooting

### Forest Already Exists
```powershell
Get-ADForest
# If present, skip deployment or remove and reinstall
```

### GPO Not Applying
```powershell
# Force update on client
gpupdate /force /boot

# Check applied policies
gpresult /h report.html /scope:computer
```

### File Share Access Denied
```powershell
# Verify user in group
Get-ADUser -Identity "username" -Properties MemberOf

# Check NTFS permissions
Get-Acl "E:\Shares\Sales-Materials" | Format-List
```

### Printer Won't Connect
```powershell
# Test connectivity
Test-NetConnection -ComputerName 172.16.2.50 -Port 9100

# Check printer queue
Get-PrinterQueue
```

For more troubleshooting, see [WINDOWS_DEPLOYMENT_GUIDE.md](docs/WINDOWS_DEPLOYMENT_GUIDE.md#troubleshooting).

## 📚 Additional Resources

- [Active Directory Design Guide](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/plan/ad-ds-design-and-planning)
- [Group Policy Overview](https://docs.microsoft.com/en-us/windows-server/identity/group-policy/group-policy-overview)
- [Windows Server Security](https://docs.microsoft.com/en-us/windows-server/security/security-and-assurance)
- [Veeam Backup Documentation](https://www.veeam.com/documentation)
- [Prometheus + Grafana Monitoring](https://prometheus.io/)

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/YourFeature`)
3. Commit changes (`git commit -m 'Add YourFeature'`)
4. Push to branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) file for details.

## ⚠️ Important Notes

### Pre-Production Testing
- Test all scripts in a lab environment first
- Review and customize all default passwords
- Verify network configuration matches your environment
- Test disaster recovery procedures before production

### Default Credentials
⚠️ **CHANGE BEFORE PRODUCTION USE**
- Administrator: `ChangeMe123!@#`
- User Accounts: `TempPassword123!@#` (users must change at first login)
- Service Accounts: `ServicePassword123!@#`
- Veeam Service: `VeeamPassword123!@#`

### Compliance
This configuration aligns with:
- ISO 27001 (Information Security Management)
- SOC 2 (Security & Availability Controls)
- GDPR (Data Privacy Requirements)
- HIPAA (Healthcare Compliance - if applicable)
- PCI-DSS (Payment Card Security - if applicable)

## 📞 Support

For issues, questions, or suggestions:
1. Check the [troubleshooting guide](docs/WINDOWS_DEPLOYMENT_GUIDE.md#troubleshooting)
2. Review the [quick reference](docs/WINDOWS_QUICK_REFERENCE.md)
3. Open an issue on GitHub
4. Contact the infrastructure team

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-10 | Initial release |

## 🎉 Acknowledgments

Built with best practices from:
- Microsoft Windows Server documentation
- Enterprise security standards
- Real-world deployment experience
- Community feedback and contributions

---

**Ready to deploy?** Start with [WINDOWS_DEPLOYMENT_GUIDE.md](docs/WINDOWS_DEPLOYMENT_GUIDE.md)

For a quick reference, see [WINDOWS_QUICK_REFERENCE.md](docs/WINDOWS_QUICK_REFERENCE.md)

For architecture details, see [WINDOWS_ARCHITECTURE.md](docs/WINDOWS_ARCHITECTURE.md)
