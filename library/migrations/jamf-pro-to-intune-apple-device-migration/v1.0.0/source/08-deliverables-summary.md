# Deliverables Summary

## Documentation
- **Solution Overview** — the one-MDM-per-device rule, ABM as the pivot, the wipe vs no-wipe split, the
  three migration approaches, and the wave-based model across macOS, iPadOS, and iOS.
- **Requirements** — Intune/ABM/Jamf access, Apple push cert + ADE + VPP tokens, the inventory
  worksheet, wave groups, wipe windows, and change approval — each with verify + implement-if-missing.
- **Implementation** — Phase 1 assess → Phase 2 build the Intune target per platform → Phase 3 pilot
  wave → Phase 4 production waves → Phase 5 decommission Jamf, with every object named and rollback.
- **Testing & Validation** — per-phase and per-platform checks, including the tracker to zero pending.
- **Troubleshooting** — stuck Jamf profiles, ABM re-assign not taking, VPP licenses not releasing,
  FileVault escrow, Setup Assistant not showing Remote Management, duplicate records, cert re-issue.
- **Best Practices** — decide wipe scope first, migrate in waves, translate config, protect the push
  cert, handle VPP deliberately, validate before sign-off.

## PowerShell scripts
- **`JAMFMIG-Export-JamfInventory.ps1`** — Jamf Pro API export (computers, mobile devices, PreStage,
  profiles) → mapping worksheet.
- **`JAMFMIG-Get-IntuneReadiness.ps1`** — Apple push cert, ADE tokens, VPP tokens with expiry.
- **`JAMFMIG-Get-ABMAssignments.ps1`** — serials assigned to Intune's ADE token vs still on Jamf.
- **`JAMFMIG-Validate-Migration.ps1`** — Intune-enrolled Apple devices by platform, compliance, apps.
- **`JAMFMIG-Track-Waves.ps1`** — reconcile Jamf inventory vs Intune enrollment → migrated / pending.

## Outputs you will produce
- Jamf inventory CSVs + mapping worksheet, Intune readiness report, ABM assignment report, per-wave
  validation reports, and the wave tracker driving Jamf decommissioning.

## Outcome
The Apple fleet — macOS, iPadOS, and iOS/iPhone — is migrated off Jamf Pro and onto Microsoft Intune,
managed and compliant, with apps and configuration rebuilt, delivered in validated waves and with Jamf
cleanly decommissioned.
