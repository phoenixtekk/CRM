# 6. Troubleshooting Guide — Microsoft Purview Adoption Program

Common failures when *driving adoption* of Purview, with the cause and the fix. Grouped by area. All fixes
stay within the safe-by-default model — read-only checks first, changes only under `-WhatIf`-then-`-Commit`.

## Connection & permissions
**"The term 'Get-Label' / 'Get-DlpCompliancePolicy' is not recognized."**
- *Cause:* not in a Security & Compliance PowerShell session; those cmdlets only exist after
  `Connect-IPPSSession`.
- *Fix:* `Import-Module ExchangeOnlineManagement; Connect-IPPSSession` with a modern-auth/MFA admin, then
  re-run the script.

**`OPSADOPT-Report.ps1` / `OPSADOPT-KpiReport.ps1` errors that audit search is unavailable.**
- *Cause:* `Search-UnifiedAuditLog` isn't available in your session, your role lacks **View-Only Audit Logs /
  Audit Reader**, or audit logging isn't enabled/retained for your plan.
- *Fix:* connect with an audit-capable admin; confirm audit logging is on (M365 admin / Purview **Audit**);
  verify audit retention for your licensing. The scripts warn and return `n/a` rather than inventing data.

**`Get-MgGroup` / `New-MgGroupMember` fails with an authorization error.**
- *Cause:* the Graph scope isn't consented — read scopes (`Group.Read.All`, `User.Read.All`) for
  validation/reporting, or `Group.ReadWrite.All` for the ring-expansion helper.
- *Fix:* `Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'` (add `Group.ReadWrite.All` only for
  `OPSADOPT-Remediation.ps1`); an admin consents the scope once if required. Confirm with `Get-MgContext`.

**A whole control family reads empty (e.g. auto-labeling, advanced DLP).**
- *Cause:* the capability isn't licensed/enabled (Purview is plan-gated — E5 / E5 Compliance) or your role
  lacks access.
- *Fix:* verify licensing and the role group (Requirement 2.2) in the portal; `OPSADOPT-Discovery.ps1` logs a
  warning and continues with what it *can* read — expected on lower plans.

## Adoption signal (OPSADOPT-Report.ps1)
**The report is empty but you know people are labeling.**
- *Cause:* the window (`-Days`) is too short, the **operation names** don't match your tenant/workload (they
  vary and evolve), or audit hasn't ingested the events yet.
- *Fix:* widen `-Days`; reconcile against Purview **Activity explorer** for the same window; pass your
  tenant's actual operation names via `-LabelApplyOps` / `-DlpOps`. An empty pre-launch window is a valid
  baseline, not a bug.
**Everything lands in one bucket / coverage looks wrong.**
- *Cause:* the apply-vs-remove coverage figure is a **directional proxy** from audit events, not a
  document-by-document census; and operation-name matching is best-effort.
- *Fix:* treat coverage as a trend signal (is it rising?), not an absolute count; for an absolute labeled-item
  census use Purview **Content explorer** (licensing permitting). Adjust the operation lists to your tenant.
**Ring scoping (`-RingGroup`) returns tenant-wide numbers.**
- *Cause:* Microsoft.Graph isn't connected, or the ring group name/`UserIds` field don't match; the audit
  `UserIds` value may differ from the group member UPN format.
- *Fix:* `Connect-MgGraph`; confirm the exact ring `displayName`; if UPNs don't match the audit `UserIds`
  format, reconcile the identifier before scoping.

## Coverage diff (OPSADOPT-Validation.ps1)
**An area is flagged as uncovered but you know it has a champion.**
- *Cause:* the champion is named in the roster but **not a member of the champions group**, or the UPN in the
  roster doesn't match the group member UPN.
- *Fix:* add the champion to `Champions – Purview – Adoption`, or correct the roster UPN; re-run. Coverage is
  proven by group membership, not by the roster alone.
**The ring diff flags expected members as absent right after populating the ring.**
- *Cause:* Graph group membership can take a short time to replicate, or the wave CSV UPNs differ from the
  directory UPNs.
- *Fix:* re-run after replication; confirm the CSV UPNs exactly match directory UPNs.
**"Roster CSV must have 'Area' and 'ChampionUpn' columns."**
- *Cause:* the roster export uses different column names.
- *Fix:* rename the columns to `Area`, `ChampionUpn` (and optionally `RingMember`, `Wave`); the script prints
  the columns it found.

## Ring expansion (OPSADOPT-Remediation.ps1)
**`-WhatIf` seems to do nothing / you expected the ring to change.**
- *Cause:* that is correct behavior — the tool is **safe by default**; without `-Commit` it previews only.
- *Fix:* review the previewed add/remove list, then re-run with `-Commit` **inside a change window, after a
  CLEAR wave gate**.
**`-Commit` skips users as "already in ring" / "not in ring."**
- *Cause:* idempotency — the tool won't re-add an existing member or remove a non-member.
- *Fix:* expected; only genuine deltas are applied and recorded. Confirm the intended membership with
  `OPSADOPT-Validation.ps1`.
**Expansion succeeded but the piloted behavior didn't apply to the new users.**
- *Cause:* the label/DLP policy is scoped to a **different** object than the ring group, so ring membership
  alone doesn't change what applies to the user.
- *Fix:* confirm the piloted label/DLP policy is scoped to `Adoption Ring – Purview – WaveN`; policy scope
  changes are made on the policy under **its own** change control (this tool manages ring membership only).
**You want to turn on mandatory labeling / DLP block via this script.**
- *Cause:* it intentionally does **not** do that — enforcement is a change to the label/DLP policy itself,
  not to ring membership.
- *Fix:* introduce enforcement on the policy under change control **only after** the ring's wave gate is
  CLEAR; never cold.

## KPIs & wave gate (OPSADOPT-KpiReport.ps1)
**The comms CSV won't parse / reach shows "n/a".**
- *Cause:* the export columns differ from `Wave, Sent, Reached`.
- *Fix:* the script prints the columns it found — re-export with `Sent` and `Reached` totals, or rename
  columns. This is a data-format issue, not a Purview fault.
**The wave gate says INCONCLUSIVE.**
- *Cause:* one or more KPIs are `n/a` (not connected for live signal, no roster/comms CSV supplied).
- *Fix:* connect `Connect-IPPSSession` (labeling/DLP) and `Connect-MgGraph` (champion coverage) and supply
  `-CommsCsv` / `-RosterCsv`; **do not gate on incomplete data** — resolve availability first.
**Coverage is high but the gate still HOLDs.**
- *Cause:* another KPI (often DLP **override rate** too high, or comms reach too low) fails its threshold — a
  high label rate with high overrides means people are labeling *and* routing around DLP.
- *Fix:* tune the friction driving overrides and reinforce comms; don't expand on one green KPI while another
  is red.

## General
**Adoption metrics are being treated as individual performance/surveillance data.**
- *Cause:* per-user audit signal was surfaced instead of the aggregate coverage the program is for.
- *Fix:* report **aggregate** KPIs (privacy-by-design); keep per-user signal role-separated and minimal; any
  individual case action is an **HR/legal** determination, never an output of this program.
**Not sure whether a capability / audit signal is available for your tenant.**
- *Cause:* Purview is plan-gated, audit operation names/retention vary by workload and evolve.
- *Fix:* verify in the M365 admin center and the Purview portal for **your** tenant before relying on a
  feature; flag "verify your licensing/tenant" in your runbook where availability is uncertain — never assume.
