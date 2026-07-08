# 6. Troubleshooting Guide — Managing Microsoft Purview: Operations & Governance

Common failures when *operating* Purview, with the cause and the fix. Grouped by runbook. All fixes stay
within the safe-by-default model — read-only checks first, changes only under `-WhatIf`-then-`-Commit`.

## Connection & permissions
**"The term 'Get-DlpCompliancePolicy' / 'Get-RoleGroup' is not recognized."**
- *Cause:* not in a Security & Compliance PowerShell session. Those cmdlets only exist after
  `Connect-IPPSSession`.
- *Fix:* `Import-Module ExchangeOnlineManagement; Connect-IPPSSession` with a modern-auth/MFA admin, then
  re-run the script.

**`PURVOPS-Report.ps1` returns a permissions/authorization error from Graph.**
- *Cause:* the Graph **security** read scope is not consented.
- *Fix:* `Connect-MgGraph -Scopes 'SecurityAlert.Read.All'` (or `SecurityEvents.Read.All`); if admin consent
  is required, an admin approves the scope once in Entra. Confirm with `Get-MgContext`.

**A `Get-*` cmdlet errors with "not available" for a whole family (e.g. auto-labeling, insider risk).**
- *Cause:* the capability is **not licensed/enabled** in your tenant, or your role lacks access. Purview is
  heavily plan-gated (E5 / E5 Compliance) and evolving.
- *Fix:* verify licensing and the role group (Requirement 2.2) in the portal; the discovery script logs a
  warning and continues with the families you *can* read — this is expected on lower plans.

## RB-01 — Policy lifecycle & drift
**`-CompareBaseline` reports drift when nothing changed.**
- *Cause:* the baseline was saved against a different tenant/role scope, or a policy family became newly
  visible/invisible due to a licensing/role change; the compare key is Family|Name.
- *Fix:* confirm you are connected as the same role that saved the baseline; if the estate is genuinely
  known-good, re-baseline with `-SaveBaseline`. Only re-baseline after an **approved** state.

**Real drift appears but no one changed anything on purpose.**
- *Cause:* an out-of-band edit — someone changed a policy mode outside change control, or an automated
  process did.
- *Fix:* treat as a change-control incident. Cross-check the change record (`Change Record – Purview –
  ChangeControl`) and the unified audit log (`Search-UnifiedAuditLog`) for who/when before re-baselining.

**`PURVOPS-Remediation.ps1 -WhatIf` seems to do nothing / you expected a change.**
- *Cause:* that is correct behavior — the tool is **safe by default**; without `-Commit` it previews only.
- *Fix:* review the previewed From→To mode, then re-run with `-Commit` **inside a change window** to apply.

**`-Commit` fails with a mode error on promote.**
- *Cause:* the policy is not in a promotable state, the target mode value is invalid for that policy type, or
  the simulation hasn't completed.
- *Fix:* confirm the policy's current mode with `PURVOPS-Discovery.ps1`; ensure auto-labeling simulation has
  finished before promoting; valid rollback modes are `TestWithNotifications`, `TestWithoutNotifications`,
  `Disable`. Never force-promote a policy whose test results aren't clean.

## RB-03 — Alert triage & rollup
**The rollup is empty but you know alerts exist.**
- *Cause:* the window (`-Days`) is too short, the alerts live on a surface not exposed via
  `/security/alerts_v2` for your tenant, or they haven't synchronized.
- *Fix:* widen `-Days`; reconcile against the Purview/Defender portal for the same window; some Purview
  alerts surface through the portal rather than the unified alerts API — note the gap and triage those in the
  portal.

**Categories look wrong (everything lands in "Other").**
- *Cause:* the best-effort categorizer keys off alert source/title text, which varies by tenant and evolves.
- *Fix:* adjust the category patterns in `PURVOPS-Report.ps1` to match your tenant's alert titles/sources;
  the counts are still valid, only the bucketing needs tuning.

**Mean time-to-resolve is blank.**
- *Cause:* alerts have no `resolvedDateTime` (still open) or timestamps aren't populated.
- *Fix:* expected for open alerts; the KPI computes over resolved alerts only. Ensure your triage process
  actually resolves/closes alerts so the metric has data.

## RB-04 — Role & access review
**The diff flags additions that are actually legitimate.**
- *Cause:* the approved baseline is stale — legitimate changes happened but the baseline wasn't re-saved
  after the last attestation.
- *Fix:* attest the additions with the accountable owner, then re-run `-SaveApprovedList` to refresh the
  baseline. Only re-save **after** attestation.

**`Get-RoleGroupMember` returns nothing for a group that has members.**
- *Cause:* nested/queried membership or a role group managed outside the S&C surface, or a transient service
  issue.
- *Fix:* confirm membership in the portal (**Roles & scopes → Permissions**); some role groups are managed in
  the Purview portal directly — verify there and adjust the approved list accordingly.

## RB-02 / RB-05 — Compliance Manager & KPIs
**The Compliance Manager CSV won't parse / KPIs show "n/a".**
- *Cause:* the export column layout differs from what the script expects (Compliance Manager has **no public
  API**; the portal export format changes over time).
- *Fix:* the script prints the columns it found — re-export from **Compliance Manager → Improvement actions →
  Export**, confirm a status and a due/target column exist, and (if renamed) point the detection at the right
  columns. This is a data-format issue, not a Purview fault.

**Live policy-mode / role KPIs show "n/a (not connected)".**
- *Cause:* `PURVOPS-KpiReport.ps1` was run without an S&C PowerShell session (those KPIs need it; CM/alert
  KPIs are CSV-driven and independent).
- *Fix:* `Connect-IPPSSession` before running for the live KPIs; the CSV-driven KPIs still populate either way.

**Compliance score dropped after a bulk "implemented" update.**
- *Cause:* actions were marked complete without evidence, or a reassessment lowered credit.
- *Fix:* evidence each completion; do not game the score. Track the **trend**, and let compliance/legal own
  which obligations apply — the cadence evidences technical actions, not the regulatory determination.

## General
**A scheduled read-only run stopped producing artifacts.**
- *Cause:* an expired sign-in/token for the unattended context, or a module update changed a cmdlet.
- *Fix:* refresh the auth for the scheduled context; pin/verify module versions; keep **writes human-gated** —
  only Discovery/Report/Validation/KPI runs should ever be scheduled, never `-Commit` changes.

**Not sure whether a capability/path is available for your tenant.**
- *Cause:* Purview is plan-gated and the portal evolves.
- *Fix:* verify in the M365 admin center and the Purview portal for **your** tenant before relying on a
  feature; flag "verify your licensing/tenant" in your runbook where availability is uncertain — never assume.
