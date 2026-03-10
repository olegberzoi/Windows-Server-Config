# Windows Server Enterprise Architecture & Feature Matrix

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     COMPANY.LOCAL INFRASTRUCTURE                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │            ACTIVE DIRECTORY DESIGN LAYER                     │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │ Forest: company.local | Domain: company.local              │   │
│  │ Functional Level: Windows Server 2019+                      │   │
│  │ Primary DC: DC01 (172.16.1.10)                              │   │
│  │ Secondary DC: [Optional - Pre-configured]                   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │         ORGANIZATIONAL UNIT STRUCTURE                        │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │ Departments/                                                 │   │
│  │  ├─ Sales-Showroom/          ├─ Users              ├─ Computers
│  │  ├─ Design-Technical/         ├─ Groups            ├─ ServiceAcct
│  │  ├─ Production/                                              │   │
│  │  ├─ Warehouse-Logistics/                                     │   │
│  │  ├─ Accounting-HR/                                           │   │
│  │  └─ Management-IT/                                           │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │           DISTRIBUTED INFRASTRUCTURE SERVICES                │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │  DNS (BIND)       │  DHCP (ISC DHCP)   │  File Services     │   │
│  │  - Primary Zone   │  - Pool: 172.16.   │  - SMB/CIFS        │   │
│  │  - Reverse Lookup │    100-200/24      │  - NFS (optional)  │   │
│  │  - Forwarders     │  - Domain suffix   │  - DFS Replication │   │
│  │  - Dynamic Update │  - Options: DNS    │  - Quotas & Audit  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │              DEPARTMENTAL RESOURCE LAYER                     │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │                                                                │   │
│  │ ┌─────────────────────────────────────────────────────────┐  │   │
│  │ │ Sales & Showroom (10-15 users)                          │  │   │
│  │ │ ├─ GPO: Kiosk/demo policies, limited installs          │  │   │
│  │ │ ├─ Files: Sales-Materials share (marketing, catalogs) │  │   │
│  │ │ ├─ Printers: Sales-Printer (A4 B/W)                    │  │   │
│  │ │ └─ Access: VPN profiles for off-site staff             │  │   │
│  │ └─────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  │ ┌─────────────────────────────────────────────────────────┐  │   │
│  │ │ Design/Technical (8-12 users) - CAD + GPU              │  │   │
│  │ │ ├─ Workstations: High-performance with vGPU            │  │   │
│  │ │ ├─ Storage: Dedicated NAS/SAN (E:\CAD-Projects)       │  │   │
│  │ │ │  └─ 500 GB quota, fast replication                   │  │   │
│  │ │ ├─ Tools: Git, SVN repositories                        │  │   │
│  │ │ ├─ Snapshots: Frequent (2-hour intervals)             │  │   │
│  │ │ └─ GPU: NVIDIA GRID vGPU pools (VMware vSphere)        │  │   │
│  │ └─────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  │ ┌─────────────────────────────────────────────────────────┐  │   │
│  │ │ Production (25-40 users)                                │  │   │
│  │ │ ├─ PC Lockdown: No unauthorized software               │  │   │
│  │ │ ├─ Files: Production-Schedules, machine manuals        │  │   │
│  │ │ ├─ ERP/MRP: AD authentication integration              │  │   │
│  │ │ ├─ Shift Tracking: Logon/logoff monitoring             │  │   │
│  │ │ └─ DR: Hourly replicated shares                        │  │   │
│  │ └─────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  │ ┌─────────────────────────────────────────────────────────┐  │   │
│  │ │ Warehouse & Logistics (8-15 users)                      │  │   │
│  │ │ ├─ Devices: Lightweight profiles (tablets, scanners)   │  │   │
│  │ │ ├─ Files: Inventory-DB, shipping documents             │  │   │
│  │ │ ├─ Printers: Label printer (Zebra)                     │  │   │
│  │ │ ├─ Network: VLANs for IoT (scanners, RFID)            │  │   │
│  │ │ │  └─ VLAN 101: Scanners (172.16.101.0/24)            │  │   │
│  │ │ │  └─ VLAN 102: RFID (172.16.102.0/24)                │  │   │
│  │ │ │  └─ VLAN 103: Printers (172.16.103.0/24)            │  │   │
│  │ │ └─ Access: Role-based logistics software               │  │   │
│  │ └─────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  │ ┌─────────────────────────────────────────────────────────┐  │   │
│  │ │ Accounting & HR (5-8 users) - HIGH SECURITY            │  │   │
│  │ │ ├─ Encryption: BitLocker on all drives                 │  │   │
│  │ │ ├─ Files: Confidential shares (least privilege)        │  │   │
│  │ │ ├─ Audit: All folder access tracked                    │  │   │
│  │ │ ├─ MFA: Required for payroll/HR systems                │  │   │
│  │ │ ├─ DLP: Financial/employee data protection             │  │   │
│  │ │ ├─ USB: Disabled (security devices only)               │  │   │
│  │ │ └─ Screen Lock: Auto-lock at 5 min idle                │  │   │
│  │ └─────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  │ ┌─────────────────────────────────────────────────────────┐  │   │
│  │ │ Management & IT (4-6 users) - ADMIN TIER               │  │   │
│  │ │ ├─ Accounts: Two-account model (user + admin split)   │  │   │
│  │ │ ├─ Privileges: Admin tiering (Tier 0/1/2)             │  │   │
│  │ │ ├─ Monitoring: Prometheus/Grafana access               │  │   │
│  │ │ ├─ Backup: Veeam backup admin integration              │  │   │
│  │ │ ├─ Audit: Strict logging of privileged actions         │  │   │
│  │ │ └─ Security: LAPS auto-password rotation               │  │   │
│  │ └─────────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │            SECURITY & COMPLIANCE LAYER                       │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │  Authentication     │  Encryption          │  Audit Logging  │   │
│  │  ├─ Kerberos        │  ├─ BitLocker       │  ├─ Logons       │   │
│  │  ├─ LDAP            │  ├─ TLS/HTTPS       │  ├─ Privilege Use│   │
│  │  ├─ MFA (Ad/HR)     │  ├─ EFS             │  ├─ File Access  │   │
│  │  └─ Smart Cards     │  └─ IPSec           │  └─ Policy Change│   │
│  │  (Optional)         │                      │                  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │          MONITORING & BACKUP INFRASTRUCTURE                  │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │                                                                │   │
│  │  Monitoring Stack:        Backup Stack:                       │   │
│  │  ├─ Prometheus    (9090)  ├─ Veeam B&R Console              │   │
│  │  ├─ Grafana       (3000)  ├─ Backup Proxy                    │   │
│  │  ├─ Windows Exp.  (9182)  ├─ Cloud Connect                   │   │
│  │  └─ AlertManager          ├─ Storage (NAS/SAN)               │   │
│  │                            └─ DR Site (Off-prem)             │   │
│  │                                                                │   │
│  │  Key Metrics:             Recovery Objectives:                │   │
│  │  ├─ CPU, Memory, Disk     ├─ RTO: 4 hrs (critical)       │   │
│  │  ├─ Network I/O            ├─ RPO: 1 hour                   │   │
│  │  ├─ AD Replication         ├─ Daily backups + hourly inc.   │   │
│  │  ├─ Failed Logons          ├─ 30-day retention              │   │
│  │  └─ Service Health         └─ Quarterly DR drills           │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Feature Matrix by Department

| Feature | Sales | Design | Production | Warehouse | Accounting | IT/Mgmt |
|---------|-------|--------|-----------|-----------|-----------|--------|
| **User Count** | 10-15 | 8-12 | 25-40 | 8-15 | 5-8 | 4-6 |
| **OU & GPO** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **File Shares** | ✓ Marketing | ✓ CAD (500GB) | ✓ Schedules | ✓ Inventory | ✓ Finance | ✓ IT Resources |
| **Printers** | ✓ A4 | ✓ Color/Large | ✓ Multi-func | ✓ Label | ✗ Company-wide | ✗ Company-wide |
| **GPU/vGPU** | ✗ | ✓ NVIDIA GRID | ✗ | ✗ | ✗ | ✗ |
| **High-Perf Storage** | ✗ | ✓ Dedicated NAS | ✗ | ✗ | ✗ | ✗ |
| **Mobile Profiles** | ✗ | ✗ | ✗ | ✓ Tablets | ✗ | ✗ |
| **VLAN Segmentation** | ✗ | ✗ | ✗ | ✓ 4 VLANs | ✗ | ✗ |
| **PC Lockdown** | Limited | ✗ | ✓ Strict | ✓ Light | ✓ Standard | ✗ |
| **ERP Integration** | ✗ | ✗ | ✓ Service acct | ✗ | ✗ | ✗ |
| **Shift Tracking** | ✗ | ✗ | ✓ Logon audit | ✗ | ✗ | ✗ |
| **BitLocker** | ✗ | ✗ | ✗ | ✗ | ✓ Required | ✗ |
| **USB Restrictions** | ✗ | ✗ | ✗ | ✗ | ✓ Disabled | ✗ |
| **MFA Required** | ✗ | ✗ | ✗ | ✗ | ✓ Yes | ✓ Tiered |
| **DLP Policies** | ✗ | ✗ | ✗ | ✗ | ✓ Financial | ✗ |
| **Audit Logging** | Standard | Standard | Enhanced | Standard | **Full** | **Full** |
| **VPN Access** | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **Admin Tiering** | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ Tier 0/1/2 |
| **Privileged Access** | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ PAM |
| **LAPS** | Standard | Standard | Standard | Standard | Standard | ** Enhanced** |

---

## Security Baseline Comparison

### Password & Account Policies (All Departments)
```
Minimum Length:           14 characters
Complexity Required:      YES (Upper, Lower, Number, Special)
Maximum Age:              90 days
History Remembered:       24 passwords
Account Lockout:          5 failed attempts → 30 min lockout
Kerberos Max Ticket Age:  10 hours
Account Type:             Domain User (Standard)
```

### Department-Specific Hardening

**Production Department:**
- Software Restriction Policy: ALLOWLIST only
- USB Devices: Standard devices only
- Run Command (Win+R): DISABLED
- Device Manager: HIDDEN
- Control Panel: RESTRICTED
- Network File Sharing: DISABLED (except approved)

**Accounting & HR Department:**
- BitLocker: REQUIRED (C: + D: drives)
- Removable Media: COMPLETELY DISABLED
- USB Authentication: Device recognition required
- Screen Saver: Lock at 5 minutes idle
- USB Ports: TPM-based restriction policy
- Encryption: All drives encrypted

**Management/IT Department:**
- Admin Accounts: Separate from daily use
- Session Recording: All RDP sessions logged
- Elevation: Require credentials for UAC
- Audit: Every privileged action tracked
- LAPS: 24-character auto-rotation
- Restricted Admin Mode: ENABLED for Tier-0 access

---

## Network Flowchart

```
Internet
  │
  ├─→ Firewall (Policy-based)
      │
      ├─→ DMZ (Optional)
      │
      └─→ Corp Network (172.16.0.0/16)
          │
          ├─→ DC01 172.16.1.10 (Primary DC)
          │   ├─→ Services: AD, DNS, DHCP, Print, File
          │   ├─→ Monitoring: Prometheus agent (9182)
          │   └─→ Logs: Central event collection
          │
          ├─→ Prometheus 172.16.1.20
          │   └─→ Scrapes metrics every 15 seconds
          │
          ├─→ Grafana 172.16.1.25
          │   └─→ Displays dashboards & alerts
          │
          ├─→ Backup Storage (NAS/SAN)
          │   └─→ Veeam backup target & staging
          │
          ├─→ User Subnets (172.16.100-200.0/24)
          │   ├─→ Sales-Showroom (100)
          │   ├─→ Design-Technical (101)
          │   ├─→ Production (102)
          │   ├─→ Warehouse Staff (VLAN 100)
          │   ├─→ Warehouse Scanners (VLAN 101)
          │   ├─→ Warehouse RFID (VLAN 102)
          │   ├─→ Warehouse Printers (VLAN 103)
          │   ├─→ Accounting-HR (104)
          │   └─→ Management-IT (105)
          │
          └─→ Printers (172.16.2.50-63)
              ├─→ Sales-Printer 172.16.2.50
              ├─→ Design-Printer 172.16.2.51
              ├─→ Production-Printer 172.16.2.52
              ├─→ Warehouse-Label 172.16.2.53
              └─→ Company-Main 172.16.2.60

Replication/Backup Flows:
├─→ AD Replication: DC01 ↔ Secondary DC (RPC/LDAP 389)
├─→ File Share Replication: DC01 → NAS → Off-site
├─→ Veeam Backup: Backup Proxy → Storage (6160)
└─→ Log Forwarding: All machines → DC01 (WinRM 5985)
```

---

## Deployment Timeline

| Phase | Duration | Tasks |
|-------|----------|-------|
| **Phase 1: Foundation** | 30-45 min | Run 00-setup.ps1, validate AD, create OUs |
| **Phase 2: Departments** | 60 min | Run all 6 department scripts |
| **Phase 3: Infrastructure** | 90 min | GPO, shares, printers, security, monitoring |
| **Phase 4: Client Setup** | Ongoing | Join workstations, test access, reset passwords |
| **Phase 5: Validation** | 30 min | Verify all services, test file access, backup |
| **TOTAL** | ~3.5-4 hours | Full enterprise deployment |

*Times vary based on infrastructure size and network connectivity*

---

## Hybrid Cloud Considerations

For future expansion:

**Azure AD Hybrid:**
- Azure AD Connect for user sync
- Conditional access policies
- Cloud-only resources
- Hybrid identity management

**Office 365 Integration:**
- Exchange Online
- Teams for collaboration
- OneDrive for Business
- SharePoint Online

**Cloud DR Site:**
- Failover VMs to Azure/AWS
- RTO: 2 hours (cloud-based)
- RPO: 4 hours (replicated backups)

---

## Compliance & Standards

This configuration aligns with:
- **ISO 27001** - Information security management
- **SOC 2** - Security and availability controls
- **GDPR** - Data privacy requirements (encryption, audit logs)
- **HIPAA** - Healthcare compliance (if applicable)
- **PCI-DSS** - Payment card security (if handling cards)

---

## Cost Estimation (Annual)

| Component | Quantity | Annual Cost |
|-----------|----------|------------|
| Windows Server Licenses | 2 | $6,000 |
| Active Directory Users | 80 | Included |
| Backup Software (Veeam) | 1 | $3,000 |
| Network Storage (NAS) | 1 | $5,000 |
| Monitoring Software | 1 | $2,000 |
| Maintenance & Support | 1 | $15,000 |
| **TOTAL** | | **$31,000** |

*Note: Licensing varies by organization size and edition*

---

## Performance Benchmarks

### Expected Performance
- User logon time: < 30 seconds
- File share access: < 2 seconds (LAN)
- Print job completion: < 10 seconds (network printer)
- Backup speed: 500 GB/hour (typical)
- Restore time: 2 minutes for single file

### Scalability Limits
- Users per DC: 80-100 (achieved, can extend to 500+)
- File shares: 8-10 (can add more on additional storage)
- Group policies: 50+ (current: 20-30)
- Organizational Units: Unlimited (current: 25)

---

## Document Version
**Current Version:** 1.0  
**Created:** 2026-03-10  
**Last Updated:** 2026-03-10  
**Next Review:** 2026-09-10
