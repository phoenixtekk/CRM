# FEATURES — Phoenixtekk Workplace Marketplace factory

A repeatable two-stage pipeline that turns a topic into a published, priced marketplace
solution on **https://workplace.phoenixtekk.com/** (Bagisto ~2.3.x).

## Pipeline
**author → package → list → load**, implemented as two Claude Code skills sharing one contract.

| Capability | Where | Status |
|---|---|---|
| Stage 1 — author a solution from a topic | `/generate-solution` skill | ✅ built |
| Stage 2 — publish a generated solution to the live store | `/publish-solution` skill | ✅ built |
| Product-data contract (the interface between stages) | `schema/bagisto-products.schema.json` | ✅ built |
| Generic, idempotent product loader (php8.4, `--inspect`/`--dry-run`, downloadable files) | `loader/create-bagisto-products.php` | ✅ built; downloadable file-attach pending first live verify |
| Pricing rules engine (NPO = commercial × 0.60; subscription tiers) | `pricing.md` | ✅ built |
| Account-wide subscription tiers (Memberships) | `catalog/memberships/bagisto-products.json` (loaded via the main loader `--ensure-category`) | ✅ **live** — Individual $499/mo, Professional $999/mo, Enterprise $1,499/mo, category "Memberships" (id 18), hero images. Recurring billing deferred (see ADMIN_DOCS). |
| Live store config captured via `--inspect` | this doc / `ADMIN_DOCS.md` | ✅ channel 1/default, locale en, family 1, inv 1, categories mapped |
| Managed solution library (category → slug → version, self-contained) | `library/` | ✅ built; category-first, versioned, deliverables shelf |
| Auto-generated master index + registry | `library/_index/` (`rebuild-index.ps1`) | ✅ built; regenerated from `solution.meta.json` |
| Visual HTML dashboard (metrics, status donut, per-category chart, collapsible click-to-open file browser) | `library/_index/INDEX.html` | ✅ built; self-contained, no CDN; regenerated with the index |

## Per-solution products
Each solution publishes **two** products: Commercial (`PTK-<SOL>-COMM-001`) and
Non-Profit (`PTK-<SOL>-NPO-001`, exactly 40% less). Subscriptions are account-wide and
created once, not per solution.

## Solutions authored & published
**12 solutions live** (24 SKUs) at workplace.phoenixtekk.com, all category **Intune Solutions**,
each with branded Word/PDF + scripts ZIP + a seeded hero image, Commercial + Non-Profit (40% less).

| Solution | Slug | Commercial / NPO | Status |
|---|---|---|---|
| Windows Hello for Business | `windows-hello-for-business` | $1,495 / $897 | ✅ published |
| OneDrive for Business | `onedrive-for-business` | $1,495 / $897 | ✅ published |
| Windows Autopilot | `windows-autopilot` | $2,495 / $1,497 | ✅ published |
| Device Compliance Policies | `device-compliance-policies` | $2,495 / $1,497 | ✅ published |
| Conditional Access Integration | `conditional-access-integration` | $2,495 / $1,497 | ✅ published |
| Microsoft Defender for Endpoint Integration | `defender-for-endpoint-integration` | $2,495 / $1,497 | ✅ published |
| BitLocker Drive Encryption | `bitlocker-drive-encryption` | $2,495 / $1,497 | ✅ published |
| Endpoint Security Baselines | `endpoint-security-baselines` | $2,495 / $1,497 | ✅ published |
| Attack Surface Reduction (ASR) Rules | `attack-surface-reduction-rules` | $2,495 / $1,497 | ✅ published |
| Windows Firewall Management | `windows-firewall-management` | $2,495 / $1,497 | ✅ published |
| Application Control (WDAC) | `application-control-wdac` | $2,495 / $1,497 | ✅ published |
| Remote Help | `remote-help` | $2,495 / $1,497 | ✅ published |
| macOS Automated Device Enrollment with SSO | `macos-ade-with-sso` | $1,695 / $1,017 | ✅ published |
| macOS ADE with SSO (Jamf Pro + Intune) | `macos-ade-with-sso-jamf-pro` | $1,995 / $1,197 | ✅ published (separate solution; Jamf-as-MDM) |
| Corporate-Owned (COD) & BYOD Device Management | `cod-and-byod-device-management` | $2,495 / $1,497 | ✅ published |
| Dual-Device (Personal + Corporate) Management with SSO | `cod-byod-dual-device-sso` | $2,495 / $1,497 | ✅ published (forked from COD/BYOD; both live) |
| Dual-Device iPhone (Personal + Corporate iOS) Management with SSO | `cod-byod-iphone-dual-device-sso` | $2,495 / $1,497 | ✅ published (forked from dual-device-sso; iOS-specific, both live) |
| iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling | `ios-iphone-shared-device-mode` | $1,995 / $1,197 | ✅ published (DEM enrollment, kiosk lockdown, Cisco Webex) |
| Endpoint Privilege Management (EPM) | `endpoint-privilege-management` | $1,495 / $897 | ✅ published |
| **Azure Solutions** | | | |
| Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains) | `m365-exchange-tenant-to-tenant-migration` | $3,495 / $2,097 / Gov $2,970.75 | ✅ published (T4; white-label; 3-tier) |
| Commercial→GCC High M365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD) | `commercial-to-gcc-high-migration-program` | $5,995 / $3,597 / Gov $5,095.75 | ✅ published (T5, flagship; white-label; 3-tier) |
| Microsoft Teams Phone Direct Routing with AudioCodes SBC Integration | `teams-phone-direct-routing-sbc-audiocodes` | $3,495 / $2,097 / Gov $2,970.75 | ✅ published (T4; white-label) |
| **Healthcare Solutions** (clinical / Epic) | | | |
| Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle (Intune) | `epic-hyperdrive-client-deployment-lifecycle` | $3,495 / $2,097 / Gov $2,970.75 | ✅ published (T4; white-label) |
| Imprivata SSO, Badge-Tap & EPCS for Clinical Endpoints | `imprivata-sso-badge-tap-epcs-clinical-endpoints` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets (Intune) | `healthcare-shared-clinical-device-management` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Epic Clinical Workstation Standardization & Peripheral Configuration (Intune) | `epic-clinical-workstation-standardization` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Epic Go-Live & Command Center Endpoint Readiness Playbook | `epic-go-live-command-center-readiness` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Clinical Endpoint Logon & Profile Performance Optimization (FSLogix) | `clinical-endpoint-logon-profile-optimization` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender) | `hipaa-hitrust-endpoint-compliance-remediation` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| **Managed** (MSP managed services) | | | |
| MSP Tool Stack Design & Standup — PSA, RMM & Patch Management | `msp-tool-stack-psa-rmm-patch` | $4,995 / $2,997 / Gov $4,245.75 | ✅ published (T5; white-label) |
| M365 & Azure Incident Response & Escalation Runbook | `m365-azure-incident-response-runbook` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting | `rmm-monitoring-alert-tuning` | $1,995 / $1,197 / Gov $1,695.75 | ✅ published (T2; white-label) |
| **Backup & DR Solutions** | | | |
| Backup Validation & Recoverability Assurance Program (M365 + Azure) | `backup-validation-recoverability-assurance` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| **TalentFish wave — SCCM/Intune endpoint engineering (2026-06-28)** | | | |
| Configuration Manager Cloud Management Gateway (CMG) Setup & Operations | `sccm-cloud-management-gateway-setup` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Windows 365 Cloud PC Deployment & Management | `windows-365-cloud-pc-deployment` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Azure Solutions) |
| Intune Win32 Application Packaging & Deployment | `intune-win32-app-packaging-deployment` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Group Policy to Intune Settings Migration | `group-policy-to-intune-settings-migration` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Third-Party Application Patching with Intune | `third-party-app-patching-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Universal Print Deployment & Print-Server Retirement | `universal-print-deployment-migration` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |
| Endpoint Reporting & Dashboards for Intune and Configuration Manager | `endpoint-reporting-dashboards` | $1,995 / $1,197 / Gov $1,695.75 | ✅ published (T2; white-label; Infrastructure) |
| WSUS to Windows Update for Business Patch Modernization (+1 fork of WUfB) | `wsus-to-wufb-patch-modernization` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| **Epic Wave 3 — endpoint engineering foundation (2026-06-28)** | | | |
| Windows 11 Healthcare Endpoint Baseline (Intune) | `windows-11-healthcare-endpoint-baseline` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Healthcare) |
| Configuration Manager and Intune Co-Management Enablement | `sccm-intune-co-management-enablement` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Intune) |
| Endpoint PowerShell Deployment & Patch Automation Toolkit | `endpoint-powershell-deployment-automation` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |
| Endpoint Health & Digital Experience Monitoring | `endpoint-health-experience-monitoring` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |
| Endpoint Imaging, Inventory & Hardware Lifecycle Management | `endpoint-imaging-inventory-lifecycle` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |
| New-Site Endpoint Rollout Playbook | `new-site-endpoint-rollout-playbook` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |
| **Federal Cloud Service Desk wave (2026-06-28)** | | | |
| Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys | `passwordless-fido2-phishing-resistant-mfa` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Entra ID) |
| Azure Virtual Desktop Remote Access (Windows & macOS) | `azure-virtual-desktop-remote-access` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Azure) |
| Entra ID & Intune Audit Telemetry to Microsoft Sentinel | `entra-intune-audit-telemetry-sentinel` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Sentinel) |
| Device Enrollment, Identity Association & Asset Inventory (Intune) | `device-enrollment-identity-asset-inventory` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| Hybrid Identity with Active Directory & Microsoft Entra Connect | `hybrid-identity-ad-entra-connect` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Entra ID) |
| **Asset Mgt — Software Asset Management / licensing wave (2026-06-29)** | | | |
| Microsoft 365 License Optimization & Reharvesting | `microsoft-365-license-optimization-reharvesting` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Microsoft Licensing Cost Governance — EA, CSP & True-Up Readiness | `microsoft-licensing-cost-governance-ea-csp` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Software Asset Management (SAM) Program Standup & Governance | `software-asset-management-program-standup` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Software License Compliance & Audit-Defense (Effective License Position) | `software-license-compliance-audit-defense` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Software Discovery & Entitlement Reconciliation (SCCM / Intune / Flexera) | `software-discovery-entitlement-reconciliation` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Software License Usage Reporting & Cost Dashboards (Power BI) | `software-license-usage-cost-dashboards-powerbi` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Software Renewals, Contracts & OEM Bundle Tracking | `software-renewals-contracts-oem-tracking` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| SaaS Application Discovery & License Right-Sizing | `saas-application-discovery-license-rightsizing` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Adobe Creative Cloud for Enterprise License Management (Admin Console) | `adobe-creative-cloud-enterprise-license-management` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| ServiceNow SAM — Request Fulfillment & License Reclamation Workflow | `servicenow-sam-request-fulfillment-reclamation` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Tier-1 Publisher License & Audit-Risk Management (Oracle / IBM / SAP) | `tier1-publisher-license-audit-risk` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| **Network — Netskope / SASE-SSE wave (2026-06-29; Netskope internals deferred to vendor docs)** | | | |
| Netskope Secure Web Gateway (SWG) Deployment & Web Filtering | `netskope-secure-web-gateway-deployment` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Netskope Client Deployment & Traffic Steering at Scale (Intune) | `netskope-client-deployment-traffic-steering-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Zero Trust Network Access (ZTNA) with Netskope Private Access — VPN Replacement | `ztna-netskope-private-access-vpn-replacement` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| SSL/TLS Inspection & Decryption Rollout (Netskope) | `netskope-ssl-tls-inspection-decryption` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Forcepoint Neo to Netskope Migration (Legacy Web Filtering) | `forcepoint-neo-to-netskope-migration` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| SASE / SSE Architecture & Design Blueprint | `sase-sse-architecture-design-blueprint` | $4,995 / $2,997 / Gov $4,245.75 | ✅ published (T5 flagship; white-label) |
| Netskope + Entra ID SSO & Identity-Based Policy Enforcement | `netskope-entra-sso-identity-policy` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Netskope Client Troubleshooting & Diagnostics Toolkit | `netskope-client-troubleshooting-diagnostics-toolkit` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| CASB & Cloud App Control with Netskope | `casb-cloud-app-control-netskope` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |

| **Intune — added 2026-06-29** | | | |
| Implement & Manage CIS Benchmarks for Windows 11 Devices (Intune) | `cis-benchmarks-windows-11-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; net-new + maintenance lifecycle) |
| Implement & Manage CIS Benchmarks for macOS Devices (Intune) | `cis-benchmarks-macos-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; net-new + maintenance lifecycle) |
| Deploy a Third-Party PFX Certificate to Mobile Devices for App Use (Intune) | `deploy-third-party-pfx-certificate-mobile-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; imported-PFX vs custom PKCS12, app-keychain) |
| iOS Lock Down Profile for Shared iPhones — Shared & Corporate provisioning/login (Intune) | `ios-lock-down-profile-shared-devices-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; shared no-affinity + corporate user-affinity) |
| Entra ID Integration with ABM for Account Auto-Provisioning (Intune) — COD/BYOD/Shared | `entra-id-abm-account-auto-provisioning-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Entra↔ABM federation + SCIM Managed Apple IDs; Entra ID category) |
| **Migrations** (platform-to-platform migration programs; 2026-06-29) | | | |
| Workspace ONE to Microsoft Intune Migration Program | `workspace-one-to-intune-migration-program` | $4,995 / $2,997 / Gov $4,245.75 | ✅ published (T5 flagship; white-label) |
| Workspace ONE to Intune Application Rebuild & Repackaging | `workspace-one-to-intune-application-rebuild` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Workspace ONE to Intune — Windows Device Migration | `workspace-one-to-intune-windows-device-migration` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Workspace ONE to Intune — iOS/iPadOS Device Migration | `workspace-one-to-intune-ios-device-migration` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Workspace ONE to Intune — Android Enterprise Device Migration | `workspace-one-to-intune-android-device-migration` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Workspace ONE to Intune — Policy & Compliance Translation | `workspace-one-to-intune-policy-compliance-translation` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| MDM Migration Readiness Assessment & Wave Planning | `mdm-migration-readiness-assessment-wave-planning` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| Workspace ONE to Intune — macOS Device Migration | `workspace-one-to-intune-macos-device-migration` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label) |
| Workspace ONE to Intune Coexistence & Cutover Runbook | `workspace-one-to-intune-coexistence-cutover-runbook` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label) |
| _Re-homed into Migrations_ (from Azure/Intune): `commercial-to-gcc-high-migration-program` ($5,995), `m365-exchange-tenant-to-tenant-migration` ($3,495), `sccm-intune-co-management-enablement` ($2,995), `group-policy-to-intune-settings-migration` ($2,995) | | | ✅ moved (store + wiki + gating) |

| **GPO-modernization wave (2026-06-30)** | | | |
| GPO Rationalization & Cleanup with Group Policy Analytics | `gpo-rationalization-cleanup-group-policy-analytics` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Migrations) |
| AppLocker to WDAC (App Control for Business) Migration | `applocker-to-wdac-app-control-migration` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Migrations) |
| Cloud-First Autopilot Zero-Touch Provisioning | `cloud-first-autopilot-zero-touch-provisioning` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Intune) |
| Intune Administrative Governance — RBAC & Multi-Admin Approval | `intune-rbac-multi-admin-governance` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| Cloud PKI Integration with Intune (Certificate Modernization) | `cloud-pki-integration-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Security) |
| Windows Firewall GPO to Intune Migration | `windows-firewall-gpo-to-intune-migration` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Migrations) |
| Phased GPO-to-Intune Transition Program & Sequencing Roadmap | `phased-gpo-to-intune-transition-program` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Migrations) |

| Standardize Power Platform Secrets in Azure Key Vault | `power-platform-secrets-azure-key-vault` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Azure) |

| **UEM/DoD wave (2026-07-01)** | | | |
| DISA STIG Compliance for Windows 10 & 11 (Intune) | `disa-stig-compliance-windows-10-11-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Intune; net-new + STIG-release lifecycle) |
| SCCM Task Sequence Troubleshooting & Status Message Analysis | `sccm-task-sequence-troubleshooting-status-messages` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |
| SCCM Application Migration to Intune Win32 (Repackaging) | `sccm-application-migration-to-intune-win32` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Migrations) |
| Intune Custom Compliance & Configuration Items (Scripted) | `intune-custom-compliance-configuration-items` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| Dynamic Device Targeting in Intune — Dynamic Groups & Filters | `intune-dynamic-device-targeting-groups-filters` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |

| **MAM / mobile-access wave (2026-07-01)** | | | |
| Secure Mobile Access to SharePoint Online under MAM (App Protection + Conditional Access) | `secure-mobile-access-sharepoint-online-mam` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Intune) |
| Mobile Application Management (MAM) App Protection Policies for BYOD (M365 apps) | `mam-app-protection-policies-byod-m365` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| Microsoft Tunnel for MAM — Mobile Access to Intranet Resources | `microsoft-tunnel-for-mam-intranet-access` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Intune) |

| **M365 Cloud & Security wave (2026-07-01)** | | | |
| Microsoft 365 Copilot Secure Adoption & Governance | `microsoft-365-copilot-secure-adoption-governance` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Security) |
| Microsoft Purview — DLP, Sensitivity Labels & Retention | `microsoft-purview-dlp-sensitivity-labels-retention` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Security) |
| Microsoft 365 Security Baseline & Audit Readiness (Secure Score / Compliance Manager) | `microsoft-365-security-baseline-audit-readiness` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Security) |
| Entra ID Governance — PIM, Access Reviews & Entitlement Management | `entra-id-governance-pim-access-reviews` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Entra) |
| Enterprise App & Service Principal Governance (App Registrations, API Permissions) | `enterprise-app-service-principal-governance` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Entra) |
| Azure Security Baseline & Governance (Least-Privilege, Secure Config, Guardrails) | `azure-security-baseline-governance` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Azure) |

| **Cisco ISE VPN + Intune wave (2026-07-01)** | | | |
| Cisco Secure Client (AnyConnect) VPN Deployment via Microsoft Intune | `cisco-secure-client-vpn-deployment-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Network) |
| Certificate-Based VPN Authentication for Cisco ISE with Intune (SCEP/PKCS) | `cisco-ise-certificate-vpn-authentication-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Security) |
| Cisco ISE Device Compliance & Posture Integration with Intune (MDM Compliance Connector) | `cisco-ise-intune-compliance-posture-integration` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Network) |
| Cisco Secure Client Per-App VPN for Managed Mobile Devices (iOS/Android) via Intune | `cisco-per-app-vpn-mobile-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Network) |
| Cisco ISE 802.1X Certificate Authentication for Wi-Fi & Wired via Intune | `cisco-ise-8021x-certificate-wifi-wired-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Network) |
| Cisco ISE VPN + Intune Troubleshooting & Diagnostics Toolkit | `cisco-ise-vpn-intune-diagnostics-toolkit` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Network) |
| Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune | `cisco-vpn-client-sccm-gpo-to-intune-migration` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Migrations) |

| **Endpoint Troubleshooting & Ops wave (2026-07-01)** | | | |
| Intune Device Configuration & Policy Troubleshooting Toolkit | `intune-configuration-policy-troubleshooting` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| Intune Compliance-Failure Diagnostics & Remediation | `intune-compliance-failure-diagnostics` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| Intune App Deployment Troubleshooting & Failure Remediation (Win32/LOB/Store) | `intune-app-deployment-troubleshooting` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| Enterprise Desktop Support Runbook Library for Intune-Managed Windows | `enterprise-desktop-support-runbook-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Infrastructure) |
| Endpoint Network Connectivity Troubleshooting Toolkit (DNS, Proxy, VPN, IP/Port/URL Filtering) | `endpoint-network-connectivity-troubleshooting` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Network) |
| IP/Port/URL Allow-List & Egress Filtering Management for Microsoft 365 & Intune Endpoints | `m365-endpoint-allowlist-egress-management` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Network) |
| Windows Endpoint Performance & Reliability Troubleshooting (Boot, Profile, Crash, Disk) | `windows-endpoint-performance-reliability-troubleshooting` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |
| Peripheral, Driver & Device-Control Management for Enterprise Desktops (Intune) | `peripheral-driver-device-control-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| Enterprise VOIP / Softphone Endpoint Support & Troubleshooting | `voip-softphone-endpoint-support` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |
| Continuous Compliance Monitoring & Audit-Evidence Automation (CIS/STIG on Intune + Entra) | `continuous-compliance-audit-evidence-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Security) |

| **Government (GCC High) editions (2026-07-03)** | | | |
| 32 sovereign-cloud editions of the Microsoft-cloud solutions — separate `<slug>-gcc-high` products, GCC High / Azure Government / US Gov Graph, doc-cited Commercial-vs-GCC-High parity gaps | `*-gcc-high` | same 3-tier as parent | ✅ published (store + wiki + Dolibarr) |

| **macOS + Intune wave (2026-07-06)** | | | |
| macOS Endpoint Management Baseline in Microsoft Intune | `macos-endpoint-management-baseline-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Intune) |
| FileVault Full-Disk Encryption & Key Escrow/Recovery for macOS (Intune) | `macos-filevault-encryption-key-escrow-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| macOS Enterprise SSO App Extension (Extensible SSO) via Intune | `macos-enterprise-sso-app-extension-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| macOS App Deployment & Apple VPP with Intune | `macos-app-deployment-vpp-intune` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| macOS BYOD — User Enrollment, App Protection & Conditional Access | `macos-byod-user-enrollment-conditional-access` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Intune) |
| Microsoft Defender for Endpoint for macOS — Onboarding via Intune | `defender-for-endpoint-macos-onboarding-intune` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; white-label; Intune) |
| macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit | `macos-enrollment-sso-filevault-troubleshooting` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |
| macOS Compliance & Conditional Access for Zero-Trust Access | `macos-compliance-conditional-access-zero-trust` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Intune) |
| macOS Identity-Threat & Account-Lockout Hardening | `macos-identity-threat-account-lockout-hardening` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Security) |
| macOS Management Runbooks & IT-Support Enablement | `macos-management-runbooks-support-enablement` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; white-label; Infrastructure) |

| **Google Workspace + Gemini wave (2026-07-06) — NEW `Google` category (17)** | | | |
| Google Workspace + Gemini Enterprise Target Architecture Blueprint | `google-workspace-gemini-target-architecture-blueprint` | $4,995 / $2,997 / Gov $4,245.75 | ✅ published (T5; Google) |
| M365 → Google Workspace Migration Program & Wave Plan | `m365-to-google-workspace-migration-program` | $4,995 / $2,997 / Gov $4,245.75 | ✅ published (T5; Google) |
| ARB Governance · Vendor/Anti-Lock-In · Integration Patterns · Consolidation Strategy | `workspace-transformation-arb-governance-framework` · `workspace-vendor-technical-governance-anti-lock-in` · `enterprise-integration-patterns-entra-google-thirdparty` · `collaboration-ai-platform-consolidation-strategy` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; Google) |
| Exchange→Gmail · SPO/OneDrive→Drive · Teams→Chat/Meet · M365↔Google Coexistence | `exchange-online-to-gmail-migration` · `sharepoint-onedrive-to-google-drive-migration` · `teams-to-google-chat-meet-migration` · `m365-google-workspace-coexistence` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; Google) |
| Entra↔Cloud Identity SSO/Provisioning · Security Baseline/DLP/CAA · Vault↔Purview eDiscovery · Assured Controls (ITAR/DFARS) | `entra-id-google-cloud-identity-sso-provisioning` · `google-workspace-security-baseline-dlp-caa` · `google-vault-purview-coexistence-ediscovery` · `google-workspace-assured-controls-itar-dfars` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; Google) |
| Gemini Secure Adoption/Governance · Gemini Connector & Agent Framework | `gemini-enterprise-secure-adoption-governance` · `gemini-connector-strategy-agent-development-framework` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; Google) |
| Apps Script & AppSheet Work-Transformation Governance | `apps-script-appsheet-work-transformation-governance` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; Google) |
| **GCP + IAM + Gemini-deploy wave (2026-07-06) — extends `Google` category (11)** | | | |
| Google Cloud Platform Landing Zone & Organization Foundation | `google-cloud-landing-zone-organization-foundation` | $4,995 / $2,997 / Gov $4,245.75 | ✅ published (T5; Google) |
| GCP IAM & Least-Privilege Governance · GCP Network Architecture & VPC Service Controls · GCP Security Command Center (Posture & Threat) · Cloud Identity as Enterprise IdP (SAML Factory) · OAuth & Third-Party App Access Governance · BeyondCorp Enterprise Zero-Trust Access · Gemini Enterprise Deployment & Rollout | `google-cloud-iam-least-privilege-governance` · `google-cloud-network-architecture-vpc-service-controls` · `google-cloud-security-command-center-posture-threat` · `cloud-identity-enterprise-idp-saml-app-integration` · `oauth-third-party-app-access-governance-workspace` · `beyondcorp-enterprise-zero-trust-access` · `gemini-enterprise-deployment-rollout-enablement` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; Google) |
| GCP FinOps (Billing/Budgets/Cost Governance) · Microsoft 365 Tenant Decommission & Retirement · Google Workspace Adoption, Change Management & Training | `google-cloud-finops-billing-cost-governance` · `microsoft-365-tenant-decommission-retirement` · `google-workspace-adoption-change-management-training` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; Google) |
| **GW migration-tooling + steady-state wave (2026-07-06) — extends `Google` category (9)** | | | |
| Gmail Mail Flow/Routing & SPF/DKIM/DMARC & Compliance · Google Drive & Shared Drives Architecture/Governance · Google Workspace Migrate (Deployment & Execution) · BitTitan MigrationWiz (M365→Google) · CloudM Migrate (M365→Google) · Migration Wave Orchestration/Throttling/Validation | `gmail-mail-flow-routing-email-authentication-compliance` · `google-drive-shared-drives-architecture-permissions-governance` · `google-workspace-migrate-deployment-large-scale-execution` · `bittitan-migrationwiz-m365-to-google-migration-execution` · `cloudm-migrate-m365-to-google-migration-execution` · `migration-wave-orchestration-throttling-post-migration-validation` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; Google) |
| Google Meet & Chat Enterprise Collaboration Design · GWMME (Exchange→Gmail Implementation) · Workspace Admin SDK & API Automation/Reporting Toolkit | `google-meet-chat-enterprise-collaboration-design` · `gwmme-google-workspace-migration-microsoft-exchange-implementation` · `google-workspace-admin-sdk-api-automation-reporting-toolkit` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; Google) |
| **GW admin/Groups/CMMC wave (2026-07-06) — extends `Google` category (3)** | | | |
| Google Workspace Day-2 Administration & Operations Runbook (OU Design + Policy Governance folded in) · CMMC Level 2 Readiness & Assessment Prep (NIST SP 800-171) | `google-workspace-day2-administration-ou-operations-runbook` · `cmmc-level-2-readiness-assessment-google-workspace` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; Google) |
| Google Groups Management & Governance (Types, Lifecycle, Membership & Security) | `google-groups-management-governance` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; Google) |

| **Oracle Utilities C2M wave (2026-07-06) — NEW `Oracle` category (14)** | | | |
| Oracle Customer to Meter (C2M) Installation & Multi-Environment Build | `oracle-c2m-installation-environment-build` | $4,995 / $2,997 / Gov $4,245.75 | ✅ published (T5; Oracle) |
| WebLogic 14c for C2M · Coherence/JMS/IWS · SSO/SSL/Keystore · Batch · Patching/Upgrade · Env Migration/Code Promotion · Performance Tuning · DevOps CI/CD · Hypercare Runbook · Troubleshooting/RCA · SOA Integration | `oracle-weblogic-14c-c2m-install-configure` · `oracle-c2m-coherence-jms-iws-configuration` · `oracle-c2m-sso-ssl-keystore-configuration` · `oracle-c2m-batch-scheduling-management` · `oracle-c2m-weblogic-patching-upgrade-runbook` · `oracle-c2m-environment-migration-code-promotion` · `oracle-c2m-performance-tuning-optimization` · `oracle-c2m-devops-release-management-cicd` · `oracle-c2m-hypercare-production-support-runbook` · `oracle-c2m-troubleshooting-rca-toolkit` · `oracle-soa-integration-for-c2m` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; Oracle) |
| Dynatrace Monitoring & Alerting · Log Analysis & Health (SLO) | `oracle-c2m-dynatrace-monitoring-alerting` · `oracle-c2m-log-analysis-health-monitoring` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; Oracle) |
| **Synthetic clinical data + AI test-enablement wave (2026-07-06) — NEW `Synthetic` category (10)** | | | |
| Synthetic Data Sub-Function Standup for Quality Engineering · Hospital Twin — Simulated Environment for AI Testing | `synthetic-data-subfunction-standup-quality-engineering` · `hospital-twin-simulated-environment-ai-testing` | $4,995 / $2,997 / Gov $4,245.75 | ✅ published (T5; Synthetic) |
| Clinical Synthetic Data Generation Harness · AI Model Testing & Scenario Evaluation Harness · Privacy-Conscious Synthetic Test Environments (De-ID/Re-ID) · Synthetic Data Governance for Regulated Healthcare · Synthetic Data Fidelity & Validation Asset Library · Multi-Modal Clinical Synthetic Data · Digital-Twin & Synthetic-Data Vendor Integration Framework | `clinical-synthetic-data-generation-harness` · `ai-model-testing-scenario-evaluation-harness` · `privacy-conscious-synthetic-test-environments-deidentification` · `synthetic-data-governance-regulated-healthcare` · `synthetic-data-fidelity-validation-asset-library` · `multimodal-clinical-synthetic-data` · `digital-twin-synthetic-data-vendor-integration-framework` | $2,995 / $1,797 / Gov $2,545.75 | ✅ published (T4; Synthetic) |
| AI Delivery Pods/Squads & Engineering-Quality KPI Framework | `ai-delivery-pods-squads-quality-kpi-framework` | $2,495 / $1,497 / Gov $2,120.75 | ✅ published (T3; Synthetic) |

Total commercial catalog value: **$662,535** (233 solutions, all published — incl. 32 Government (GCC High) editions, the now-40-solution Google Workspace + Gemini + Google Cloud Platform + migration-tooling + admin/compliance line, the 14-solution Oracle Utilities C2M line, and the 10-solution Synthetic clinical-data + AI test-enablement line). The Google line's migration-tooling sub-wave adds **tool-specific execution playbooks** (Google Workspace Migrate, GWMME, BitTitan MigrationWiz, CloudM Migrate — vendor console internals deferred to each vendor's docs), the **tool-agnostic cutover-ops** layer (wave orchestration/throttling/validation), and **steady-state Workspace architecture** (Gmail mail flow/SPF-DKIM-DMARC, Drive/Shared-Drives governance, Meet/Chat collaboration design, Admin SDK automation) — distinct from the migration versions of Drive/Chat. Automation is delivered per-platform: **PowerShell** for Microsoft/Intune, **WLST (Jython)/shell/SQL** for the Oracle C2M line, and **Python** (`gcloud`/Cloud Client Libraries) for the Google/GCP and Synthetic lines (the factory compiler packages `.ps1/.sh/.sql/.wlst/.py`). The `Google` line now spans Workspace + Gemini **and** Google Cloud Platform foundation (landing zone, Cloud IAM, VPC Service Controls, Security Command Center, FinOps, BeyondCorp zero-trust) plus deeper IAM (Cloud Identity as IdP / SAML factory, OAuth app-access governance) and migration-lifecycle ops (M365 tenant decommission, adoption/change-management). The Synthetic line generates/validates **synthetic** clinical data in **isolated non-production** environments — never real PHI into a shared harness/twin/AI-test env; vendor tools (Synthea/commercial) and AI frameworks at the pattern level; HIPAA/HITRUST de-identification & disclosure-risk determinations deferred to the buyer's privacy/compliance/legal functions.

**Government (GCC High) editions (2026-07-03):** for every solution whose setup materially differs on a US
sovereign tenant, a **separate `<slug>-gcc-high` product** ("<Title> — Government (GCC High)") was authored
against Microsoft US-Gov docs — correct `*.us` portals (`portal.azure.us`, `intune.microsoft.us`,
`entra.microsoft.us`, `compliance.microsoft.us`, `security.microsoft.us`), US Gov Graph (`-Environment
USGov`/`USGovDoD`), and doc-cited Commercial-vs-GCC-High **parity gaps** (each edition ships a
`gcc-high-parity-notes.md`). Notable findings baked in: classic Windows Autopilot → Autopilot device
preparation; Cloud PKI N/A → SCEP/PKCS; cross-cloud Exchange migration → third-party tools; Entra↔ABM
federation unsupported; Universal Print GA in GCC High but not DoD; Tunnel needs `intune_env=FXP`, no FIPS;
Copilot GA Dec 2025 (web-grounding off). Parent products carry a non-destructive pointer to their Government
edition. Model + pricing: separate product, same 3 tiers as parent (content = GCC High, discount = buyer org).
Governed by generate-solution SKILL §0d (research-and-fork rule). **Categories are one word** (store renamed `Intune Solutions→Intune`, `Security Solutions→Security`, `Azure Solutions→Azure`, `Entra ID Solutions→Entra`). **Migrations** is now the single home for all platform-to-platform migration products (13 solutions). **Pricing is 3-tier**
(Commercial anchor · Non-Profit −40% · Government −15%), with the commercial anchor set from the
**Effort & Complexity Scale (T1–T5)** in `pricing.md`. Discounted tiers are eligibility-gated (see
`ADMIN_DOCS.md` → eligibility validation). Listings include a "run it yourself vs. consulting" value
section. Hero images: title auto-fits (≥15px border margin); imagery seeded per solution; same-category
solutions share a palette. Refresh an image via `tools/refresh-image.ps1`.

## Compiler & imagery
- `tools/build-deliverables.py` compiles each solution's `source\` + `scripts\` into a branded
  Word + PDF + scripts ZIP (python-docx + reportlab; no Office/pandoc needed). Reusable.
- `tools/build-hero.py` generates a templated product **hero image** from `listing\hero.json` +
  metadata (solution title rendered on the image), → `<SOL>-hero.svg` + `<SOL>-hero.png`
  (1200×1200, rendered via headless Edge/Chrome — no native libs). Attached as the product base
  image by the loader (`image` field; `--sync-images` to (re)attach to existing products). Shown as
  a thumbnail in `library/_index/INDEX.html`. Photoreal AI route (OpenAI `gpt-image-1`) deferred.

## Subscriptions & billing (`Phoenixtekk/Subscriptions` package — live 2026-06-14)
- Native Bagisto package for **recurring memberships**, **provider-agnostic**: active processor + keys
  are set in the **admin UI** (Configuration → Sales → Subscriptions & Billing), stored in `core_config`
  with `.env` fallback — no file edits, no redeploy to switch. **Active processor: Stripe** (Billing +
  Connect; permits marketplaces). MoR providers (Polar/Paddle) were ruled out — their AUPs prohibit
  marketplaces; **Polar removed 2026-06-14**. Freeze risk mitigated operationally (see `BILLING.md`).
- One-click **"Sync plans"** button on Admin → Subscriptions creates all 6 products/prices via API for
  the active provider (so the whole setup is UI-only).
- **PayPal backup rail** (`PayPalBillingProvider`) registered as a second processor for redundancy —
  selectable in admin config; webhooks verified via PayPal's verify-webhook-signature. (Stripe primary.)
- Hosted Checkout + hosted Customer/Billing Portal (minimal PCI scope; card data never touches server).
- Processor-abstracted: app depends on `Contracts/BillingProvider`; each driver
  (`Billing/PolarBillingProvider`, `Billing/StripeBillingProvider`) is the only place that talks to its
  processor **and** normalizes its webhooks into one canonical event — so `WebhookController` is
  provider-agnostic. **Switching providers = config change only** (no code/schema change).
- 3 tiers (Individual/Professional/Enterprise), monthly + annual, in `Config/subscriptions.php`.
- Storefront: `/memberships` pricing, hosted checkout, `/memberships/my-membership`, hosted portal.
- **Gated member library** (`/memberships/library`) — active members download every solution's
  deliverables; protected by `membership.active` middleware.
- Admin: read-only list at `/admin/subscriptions` (shows provider per subscription).
- `php artisan subscriptions:sync-plans` (provider-aware) creates the active provider's products/prices
  in `pt_sub_plans`. Webhook endpoint: `/billing/webhook`.
- Provider-neutral schema: `provider` column on all three `pt_sub_*` tables; scoped per provider so a
  fallback can coexist. Tables: `pt_sub_plans`, `pt_sub_subscriptions`, `pt_sub_webhook_events`.
- **Deployed live** (PSR-4 + provider registered, migrations run, routes live, site 200).
  **Activation pending** Polar (sandbox) token + webhook secret in `.env` (see `BILLING.md`).

## Not yet done
- Run `/generate-solution "Windows Hello for Business"` to (re)produce the WHfB artifacts in this repo.
- ✅ Done — 3 subscription tiers (Memberships) published live (2026-06-14).
- First real `/publish-solution` run (verifies downloadable file delivery end-to-end).
- ✅ Recurring billing built in-house as `Phoenixtekk/Subscriptions` (provider-agnostic; **Stripe**
  active — MoR ruled out for marketplaces, Polar removed) — deployed 2026-06-14; **activation pending
  Stripe keys** entered in admin UI (see `BILLING.md`).
- Category-page descriptions, product images/alt text.
- ✅ Agency Agents installed (`.claude/agents/`) — **232 agents**, native Claude Code format,
  from https://github.com/msitarzewski/agency-agents (2026-06-13, `install.sh --tool claude-code
  --no-interactive`). Re-run the installer to update.
