# 6. Troubleshooting — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Work top-down: confirm **licensing/access**, then **data collection is enabled and assigned**, then
**diagnostic-data settings**, then **endpoint reachability**, then **scope**, then give it the
**collection window**. Most "no scores" cases are one of: data collection not assigned, diagnostic data
below the required level, blocked telemetry endpoints, or simply not enough time elapsed yet.

> **Before chasing a fault, remember scores are not instant.** After enabling data collection there is a
> **collection window** before scores populate and a baseline forms. **Confirm the current expected
> timing against Microsoft documentation** and wait it out before treating blank scores as broken.

## No data at all / devices not reporting
- **Data-collection policy not assigned.** In **Reports → Endpoint analytics → Settings**, confirm
  `EPA – Data Collection – Pilot` is **enabled and assigned** to `EPA – Pilot Devices` (Implementation
  §3). Run `ENDPTAN-Test-DataFlow.ps1` to see which pilot devices are reporting.
- **Diagnostic data below the required level.** Endpoint Analytics needs Windows diagnostic data at the
  level Microsoft documents; if it's off or too low the device won't report. Confirm/assign
  `EPA – Diagnostic Data – Pilot` (Implementation §4). **Verify the required level against Microsoft
  documentation** — do not assume a fixed level.
- **Telemetry endpoints blocked.** The diagnostic-data / analytics endpoints are a **distinct set** from
  the core Intune URLs; if the proxy/firewall blocks them, scores stay blank even with the policy
  assigned. Allow the **Microsoft-published** endpoint ranges (Requirement R7) and re-test.
- **Device not actually managed / not syncing.** Confirm the device is Intune-enrolled or co-managed and
  syncing (Intune → Devices → device → **Sync**). A device that isn't checking in can't report analytics.

## Scores blank or delayed (data is flowing but no scores)
- **Collection window not elapsed.** Give it the documented time; `ENDPTAN-Test-DataFlow.ps1` can show
  devices are syncing even before scores render.
- **Score area not enabled.** If a specific score is missing, confirm that area was enabled when you
  turned on data collection (Implementation §3) — e.g. Application reliability enabled for the app-health
  score. **Verify the current toggle set against Microsoft documentation.**
- **Too few devices for a meaningful score.** Some scores need a minimum population/usage before they
  render. Expand the pilot slightly or wait for the fleet. **Confirm any current minimums with Microsoft.**
- **Co-managed devices not onboarded.** For co-managed devices, confirm the Configuration Manager side is
  onboarded to Endpoint Analytics (Requirement R9). **Verify the current onboarding steps with Microsoft.**

## Licensing / prerequisite gaps
- **Node blocked or limited.** If **Reports → Endpoint analytics** shows a licensing block, resolve the
  entitlement (Requirement R1) — **verify the entitling SKUs against current Microsoft documentation**;
  don't assume a bundle includes it.
- **Insufficient rights.** If you can read but not create the data-collection/config policies, you likely
  lack Intune administrative rights (Requirement R8) — assign the appropriate role.
- **Unsupported Windows version.** Devices on an unsupported build report partial/no data and drag WFA
  down. Bring them current (Requirement R3).

## Scope wrong (right feature, wrong devices)
- **Policy assigned to the wrong group.** Confirm the data-collection policy targets `EPA – Pilot Devices`
  (pilot) or `EPA – Fleet Devices` (fleet) as intended, and that the diagnostic-data profile is assigned
  to the **same** group — a mismatch means devices collect but aren't told to, or vice versa.
- **Devices missing from the group.** Confirm the intended devices are members (Assigned group) or match
  the rule (dynamic group). Re-run `ENDPTAN-Validate.ps1` after fixing membership.
- **Fleet expansion missed the diagnostic-data profile.** When you add `EPA – Fleet Devices` to data
  collection (Implementation §14), also extend the `EPA – Diagnostic Data` profile to the fleet group.

## National-cloud differences (GCC / GCC High / DoD)
- **Wrong portal or endpoint set.** Government tenants may use a different admin portal
  (e.g. `endpoint.microsoft.us`) and different service/telemetry endpoints, and a feature may be delayed
  or absent. **Verify availability, the correct portal, and the endpoint list against Microsoft's
  US-sovereign-cloud documentation** before concluding something is broken.

## Scripts (PowerShell / Microsoft Graph)
- **Connect with the right scopes.** The read-only scripts use read scopes
  (`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`,
  `DeviceManagementServiceConfig.Read.All`, `Group.Read.All`); the state-changer
  (`ENDPTAN-Set-DataCollection.ps1`) needs `DeviceManagementConfiguration.ReadWrite.All` and
  `Group.ReadWrite.All`. Consent to exactly those scopes at `Connect-MgGraph` — a missing scope shows as
  a 403/authorization error.
- **The state-changer defaults to `-WhatIf`.** `ENDPTAN-Set-DataCollection.ps1` **previews only** unless
  you pass **`-Apply`**. If "nothing changed," that's expected — re-run with `-Apply` to commit.
- **Match names/scope exactly (verbatim).** The scripts look up objects by their exact display names
  (`EPA – Pilot Devices`, `EPA – Data Collection – Pilot`). If you renamed an object, pass the matching
  `-PilotGroupName` / `-PolicyName` so the lookup finds it — note the names use an en dash (`–`), not a
  hyphen; copy them exactly.
- **Graph resources evolve — verify.** The Endpoint Analytics `userExperienceAnalytics*` resources are on
  the **beta** endpoint and change over time. If `ENDPTAN-Report.ps1` / `ENDPTAN-Test-DataFlow.ps1`
  return nothing, read the scores in **Reports → Endpoint analytics** and **verify the current Graph
  resource names against Microsoft documentation** before assuming a fault. The scripts intentionally do
  **not invent** an endpoint — `ENDPTAN-Set-DataCollection.ps1` previews its intent and points you to the
  portal when the data-collection resource isn't set.
- **Module missing.** `Install-Module Microsoft.Graph -Scope CurrentUser` once before first run.

## Useful checkpoints
- **Intune:** **Reports → Endpoint analytics** (scores/baseline), **Reports → Endpoint analytics →
  Settings** (data collection + baseline), **Devices → Configuration** (the diagnostic-data profile),
  **Devices → All devices** (managed/sync state).
- **Entra:** **Groups → `EPA – Pilot Devices` / `EPA – Fleet Devices`** (membership).
- **Scripts:** re-run `ENDPTAN-Validate.ps1` after each change to confirm the gate.
