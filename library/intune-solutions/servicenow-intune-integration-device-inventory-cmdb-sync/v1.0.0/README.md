# ServiceNow ↔ Microsoft Intune Integration — Device Inventory & CMDB Sync (SNOWINT) v1.0.0

**Category:** Intune Solutions · **Version:** v1.0.0 · **Status:** generated · **Branding:** OFF (white-label)

Connect ServiceNow to Microsoft Intune so ServiceNow **collects managed-device (and installed-app)
inventory into the CMDB on a schedule** — re-establishing the Intune equivalent of a retiring
Workspace ONE (AirWatch) MDM feed. Read-only Microsoft Graph, serial-number IRE reconciliation (no
duplicate CIs), least-privilege by design.

## Products / SKUs
| Tier | SKU | Price |
|---|---|---|
| Commercial | PTK-SNOWINT-COMM-001 | $2,795.00 |
| Non-Profit (−40%) | PTK-SNOWINT-NPO-001 | $1,677.00 |
| Government (−15%) | PTK-SNOWINT-GOV-001 | $2,375.75 |

## What's included
- **Docs (Word + PDF):** Solution Overview, Requirements (Microsoft + ServiceNow), Implementation,
  Testing, Troubleshooting, Best Practices, Executive Summary, Deliverables Summary.
- **5 PowerShell scripts (cloud-aware, read-only by default):** `SNOWINT-Preflight.ps1`,
  `SNOWINT-Export-ManagedDevices.ps1`, `SNOWINT-Validate-Sync.ps1`, `SNOWINT-Report-Coverage.ps1`,
  `SNOWINT-Remediation.ps1` (guarded).
- **Deliverable bundle:** `SNOWINT-Complete-Solution.zip` (PDF + Word + Scripts) — attached to all
  three products.
- **Hero:** `SNOWINT-hero.png`.

## Key verified facts
- Supported path: **Service Graph Connector for Microsoft Intune** (ServiceNow Store), requires **ITOM
  Visibility or Discovery**; writes to CMDB via **IRE**. A custom Integration Hub import is the
  ITOM-free fallback.
- Graph **Application** (read-only, admin-consented) scopes: `DeviceManagementManagedDevices.Read.All`,
  `DeviceManagementApps.Read.All`, `DeviceManagementServiceConfig.Read.All`, `Directory.Read.All`.
- Data: managed devices (`/deviceManagement/managedDevices`) + detected apps
  (`/deviceManagement/detectedApps`) → CMDB `cmdb_ci_computer` + handheld/mobile class.
- Reconciled against the existing Workspace ONE feed via a shared **serial-number** identifier.

## Scope boundary
Re-establishes the **CMDB data feed only**. Deferred (referenced, not reproduced): device migration
(**WS1PROG**), SAM license workflow (**SNOWSAM**), software entitlement reconciliation (**SWDISC**).

## Government
`gov_variant: false` — the ServiceNow app/CMDB model is identical for Gov; only the Microsoft
endpoints differ (documented inline; scripts run `-Cloud USGov|USGovDoD`). GCC High connector-endpoint
support flagged "verify against current documentation."

## Accuracy note
ServiceNow release-specific names (connector app/version, data-stream names, exact CMDB class/field
names, roles, ITOM packaging) are flagged inline to **verify against current ServiceNow documentation
for your instance release**. Microsoft Graph scopes verified against Microsoft Learn (see
`solution.meta.json` → `author_notes` for source URLs).
