# 7. Best Practices — Windows Advanced Audit Policy & Security Logging Baseline

These practices keep the audit baseline consistent, useful, and reversible across Windows 10/11
endpoints. They assume the deployment model in the Solution Overview: a single Intune **Settings
Catalog** profile carrying CIS/Microsoft-aligned subcategories, the force-subcategory override,
command-line process auditing, and a right-sized Security log, deployed pilot-first.

## Set the override first, and prove it
- **Enable "Force audit policy subcategory settings" explicitly.** Never rely on the default. Put it in
  the same `Win Audit Policy - Baseline - Pilot` profile (Step 6a) so the baseline is deterministic, and
  confirm `SCENoApplyLegacyAuditPolicy = 1` on-device (Test 4) before trusting any subcategory result.
- **Kill legacy basic audit policy.** If any GPO still sets the nine basic **Audit Policy** categories,
  set them to *Not Defined*. Basic and advanced audit fighting each other is the top cause of
  "the setting shows applied but nothing is audited."

## Audit for detection, not for volume
- **Start from the workstation-tuned table (Step 6b).** It is CIS/Microsoft-aligned and captures the
  events SOC playbooks expect without drowning the log.
- **Keep Process Creation with command line.** Row 14 + Step 6c (Event ID 4688 with the command line) is
  the single most valuable pairing for detecting living-off-the-land attacks. Size the log for it rather
  than turning it off.
- **Treat the loud subcategories deliberately.** *Detailed File Share* (5145) and *Filtering Platform
  Connection* (5156/5157) are very high volume. Leave Filtering Platform Connection off on workstations
  (baseline default); enable it only on hosts under active investigation and only if the SIEM can absorb
  it.

## Split workstation and server baselines
- **Clone, don't overload.** Create `Win Audit Policy - Baseline - Servers` for server roles and adjust
  the high-volume subcategories (File Share, Detailed File Share, Filtering Platform Connection,
  Sensitive Privilege Use) to match the role. A file server and a laptop have very different noise
  profiles.
- **Assign by group, not by "All devices."** Keep workstations and servers in separate Entra groups so
  each gets the right variant.

## Size and forward the logs
- **Right-size the Security log (Step 6d).** 196608 KB (192 MB) is the Microsoft baseline; go larger if
  you forward on a schedule rather than continuously, so evidence survives between collections.
- **Overwrite oldest, never block.** Set the Security log to *overwrite events as needed* so a full log
  can't stop new auditing.
- **Auditing is the source; forwarding is separate.** This baseline makes devices *generate and keep*
  events. Pair it with the **Entra ID & Intune Audit Telemetry to Microsoft Sentinel** solution (Azure
  Monitor Agent + Data Collection Rule / Windows Security Events) to get them into your SIEM. Don't try
  to solve forwarding inside this profile.

## Deploy pilot-first and reversibly
- **Assign to `Win Audit Policy - Pilot Devices`, never "All devices" first.** Expand in waves after
  each gate passes.
- **Rollback is unassignment.** Because this only adds a configuration profile, removing the assignment
  cleanly reverts to the prior audit state — no re-enrollment or cleanup. Keep the profile so you can
  re-target quickly.

## Operate and monitor
- **Report before you widen.** Run `WINAUDIT-Report.ps1` each wave; only broaden when coverage matches
  the assigned group.
- **Remediate with `-WhatIf` first.** `WINAUDIT-Remediation.ps1` and `WINAUDIT-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Re-run `auditpol` after major Windows upgrades.** A feature update or a new co-managing policy can
  reintroduce a legacy audit setting; confirm the override is still `1` and subcategories still match.

## Change control
- **Version scope changes.** When you change a subcategory level or the log size, note the date and
  reason, and re-run Discovery + Report to confirm no regressions.
- **Map to your compliance requirement.** Record which benchmark (CIS L1/L2, a STIG, or your own
  standard) and which version the baseline targets, so an auditor can trace each subcategory value back
  to its source.
