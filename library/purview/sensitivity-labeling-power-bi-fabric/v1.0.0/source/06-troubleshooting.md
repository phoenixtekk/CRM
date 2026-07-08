# 6. Troubleshooting — Sensitivity Labeling for Power BI & Microsoft Fabric (Microsoft Purview)

Symptoms, likely causes, and fixes for analytics labeling. Stay in **pilot** while diagnosing —
reproduce on `Analytics Labels – Pilot Ring – Stage1` / the pilot workspace before touching the wider
estate, and prefer disabling a tenant setting over deleting a label.

## The sensitivity-label picker doesn't appear in the Power BI service
- **Tenant setting off.** "Allow users to apply sensitivity labels for content" must be **On** and scoped
  to a group the user is in (`BI Labeling – Enabled Users`). Confirm in the Power BI/Fabric admin portal.
- **Label not published to the user.** Confirm `Analytics Labels – Policy` targets the user
  (`Get-LabelPolicy`); add them with `IPPBI-Set-InfoProtection.ps1 -Action PublishPolicy -Commit`.
- **Licensing.** The user needs the AIP/label entitlement **and** Power BI Pro/PPU (or a capacity).
  `IPPBI-Check-Prereqs.ps1` reports the signals; missing licensing → labeling **deferred** for that user.
- **Propagation lag.** Tenant-setting and label-policy changes take time to reach the service. Have the
  user sign out/in and retry before assuming failure.

## The label doesn't inherit from a labeled data source
- **Source-inheritance setting off.** "Apply sensitivity labels from data sources to their data in Power
  BI" must be **On**. Confirm in the admin portal.
- **The source isn't actually labeled.** Inheritance only flows a label that exists on the source. Verify
  the upstream source carries a label/classification; if it doesn't, rely on artifact labeling and record
  inheritance as **partial**.
- **Refresh needed.** Inheritance is evaluated on refresh/build. Refresh the semantic model and re-check.
- **Behavior differs by source type.** Which sources propagate labels is Microsoft-defined and evolving —
  verify the source type is supported for inheritance in current Microsoft guidance.

## An export to Excel/PowerPoint/PDF isn't protected
- **Export-protection setting not configured.** The export inherits the label and its encryption only when
  the export/restriction settings are configured. Re-check the export-protection tenant settings.
- **Label has no encryption.** A label with no protection/encryption produces an export with no
  protection — that's expected. Confirm the label used on the content actually applies encryption/usage
  rights (its Purview label configuration).
- **Unsupported export path.** Some export/print paths behave differently; verify the specific export type
  against current Microsoft documentation before concluding it's a defect.

## Mandatory labeling is blocking creators unexpectedly
- **Enabled too early.** Mandatory labeling should be **Off during the pilot** and enabled only after
  validation, with creators told first. If it was enabled prematurely, turn it **Off** in the admin
  portal — it's the highest-friction setting and the first to roll back.
- **Labels not published to all creators.** If mandatory labeling is on but a creator can't see any label
  (see the first section), they're blocked with no way forward. Fix publication/licensing first, then
  enable mandatory labeling.

## `IPPBI-Set-InfoProtection.ps1 -Commit` fails to publish the policy
- **Not connected / wrong session.** Ensure `Connect-IPPSSession` succeeded (`Get-Command Get-Label`
  resolves). The label cmdlets are in Security & Compliance PowerShell.
- **Insufficient role.** Publishing labels needs Information Protection / Compliance Administrator. Confirm
  in Purview → Roles & scopes / Permissions.
- **Parameter shape by module version.** Label/membership parameter names vary across
  ExchangeOnlineManagement versions; verify against your version and update the module if it's far behind.

## `IPPBI-Discover.ps1` can't read workspaces
- **Power BI module/role.** Workspace inventory needs the MicrosoftPowerBIMgmt module,
  `Connect-PowerBIServiceAccount`, and Power BI admin rights for `-Scope Organization`. Without them the
  script still reports labels/policies and prints the tenant-setting checklist — the workspace list is
  optional.

## `IPPBI-Validate.ps1` says a label is "not detected on the policy" but the portal shows it
- **Module-version property shape.** Label-to-policy attachment is exposed under different property names
  across module versions. Confirm in the portal (Information Protection → Label policies → the policy →
  **Labels**); if listed there, treat the validator line as informational and note the module version.

---
### When to stop and escalate
- A required capability is unavailable on your licensing/tenant (AIP entitlement, Pro/PPU/capacity, a
  tenant setting) — record it **deferred** and route the licensing decision to the owner; do not design
  around an unavailable feature.
- **Which content is sensitive** is a stakeholder determination (compliance/privacy/data-governance), not
  a technical fix — capture the mapping in `Analytics Scope – Map` and defer the determination.
- If inheritance or export protection can't be reconciled with the settings, keep the tenant settings
  scoped to the pilot group, gather `IPPBI-Validate.ps1` + `IPPBI-Report.ps1` output as evidence, and
  raise with Microsoft support rather than expanding a configuration that doesn't behave as designed.
