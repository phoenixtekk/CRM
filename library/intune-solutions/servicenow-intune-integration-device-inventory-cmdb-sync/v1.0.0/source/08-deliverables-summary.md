# 8. Deliverables Summary — ServiceNow ↔ Microsoft Intune Integration (Device Inventory & CMDB Sync)

## What you receive
A complete, self-guided implementation package to re-establish the CMDB device-inventory feed from
Microsoft Intune into ServiceNow — the Intune equivalent of the Workspace ONE MDM feed.

### Documentation (Word + PDF)
1. **Solution Overview** — the data flow (Graph → connector → IRE → CMDB), the supported product path
   (Service Graph Connector for Microsoft Intune), and how it replaces the Workspace ONE feed.
2. **Requirements Guide** — two-platform prerequisites (Microsoft: Intune, Entra app registration,
   least-privilege Graph scopes, admin consent; ServiceNow: ITOM entitlement, connector + dependencies,
   roles, IRE identifier) — each with Description · Why · Verify · Implement-if-missing.
3. **Implementation Guide** — ordered steps: Entra app registration & consent → ServiceNow connection →
   field/CMDB mapping & serial-number IRE → scheduled import → pilot → validate → expand → retire WS1.
4. **Testing & Validation** — 10 tests with explicit PASS/FAIL gates and pilot exit criteria.
5. **Troubleshooting** — auth failures, throttling, duplicate CIs, stale records, and more.
6. **Best Practices** — credentials, reconciliation/CMDB hygiene, scope/scheduling, WS1 transition, ops.

### PowerShell scripts (5) — the Microsoft side, read-only by default, cloud-aware
- **`SNOWINT-Preflight.ps1`** — verify the app registration, consented scopes, and managed-device read.
- **`SNOWINT-Export-ManagedDevices.ps1`** — export the exact Intune device dataset ServiceNow imports
  (for reconciliation/validation).
- **`SNOWINT-Validate-Sync.ps1`** — compare Intune vs a CMDB export CSV (matched / missing / stale /
  duplicate serials).
- **`SNOWINT-Report-Coverage.ps1`** — managed-device coverage by platform / ownership / compliance /
  staleness.
- **`SNOWINT-Remediation.ps1`** — guarded (`-WhatIf`/diagnose-by-default) fix for a missing/expired
  app-registration secret or a missing scope.

All scripts use `Connect-MgGraph -Environment Global|USGov|USGovDoD` so they run in Commercial and US
Government clouds.

## Key verified facts (with the sources relied on)
- ServiceNow ingests Intune device inventory via the **Service Graph Connector for Microsoft Intune**
  (ServiceNow Store), which requires an **ITOM Visibility or Discovery** subscription and writes to the
  CMDB through IRE.
- The connector authenticates to **Microsoft Graph** with **Application** permissions:
  `DeviceManagementManagedDevices.Read.All`, `DeviceManagementApps.Read.All`,
  `DeviceManagementServiceConfig.Read.All`, `Directory.Read.All` — all read-only, admin-consented.
- Managed devices come from `…/deviceManagement/managedDevices` and detected apps from
  `…/deviceManagement/detectedApps`; devices land in the CMDB **computer** class (`cmdb_ci_computer`)
  and the **handheld/mobile** class.

> Release-specific ServiceNow names (connector app/version, data-stream names, exact CMDB class/field
> names, role names, ITOM packaging) **must be verified against current ServiceNow documentation for
> your instance release** — the guide flags each inline.

## Out of scope (deferred, referenced not reproduced)
- **SNOWSAM** — ServiceNow SAM license workflow.
- **SWDISC** — software entitlement reconciliation / effective license position.
- **WS1PROG** — the Workspace ONE → Intune device migration itself.

## Outcome
A scheduled, reconciled, least-privilege Intune → ServiceNow CMDB device-inventory feed that survives
the Workspace ONE → Intune transition, keyed on serial number so every device is one trustworthy CI.
