# Best Practices — Microsoft Purview Insider Risk Management

Operating principles that keep an IRM program **effective, defensible, and privacy-respecting**. They
reflect the three non-negotiables: privacy by design, strict role separation, and determinations that
belong to HR/legal.

## Privacy first — always

- **Keep anonymization ON.** Reviewers see pseudonymized identities by default. De-anonymization is a
  **justified, role-gated, audited exception** — never a routine step, never the administrator's call.
- **Scope to the minimum.** Only put people in a policy's scope when there is a reason. Broad,
  everyone-in-scope policies are both noisy and hard to justify to privacy/legal.
- **Least data, least reveal.** Prefer analytics (aggregate, no names) to size the program; reveal
  identity only when a case genuinely requires it.
- **Document the privacy decisions** (anonymization posture, who may de-anonymize, on what basis) and
  keep them current with privacy/legal.

## Role separation — enforce it, then watch it

- **One function per person.** Admins configure; Analysts triage; Investigators go deep; Auditors watch
  the reviewers. Do **not** concentrate roles, and do **not** assign the combined **Insider Risk
  Management** role group to operators.
- **Independent audit.** Assign **Auditors** who are **not** Admins/Analysts/Investigators, and have
  them review the IRM audit log on a schedule — especially every **de-anonymization**.
- **Re-verify after every change.** Re-run `PURVIRM-Discovery.ps1` after any role change; treat a
  conflicting combination as an incident, not a convenience.

## Determinations stay with HR/legal

- **IRM produces evidence, not verdicts.** An alert or a case is a signal and an audited trail. Whether
  it reflects misconduct, and what happens next, is an **HR/legal/privacy determination**.
- **Route, don't rule.** Use case actions to route evidence (notification, eDiscovery, Communication
  Compliance, resolve). The employment decision is made by the people authorized to make it.
- **Engage before you enable.** Confirm the lawful basis / notice / consultation for your
  jurisdiction(s) **before** switching a policy on. Applicability is a legal determination.

## Pilot and tune before you rely

- **Analytics first.** Run Insider Risk analytics before scoping anyone — it is aggregate and needs no
  policy.
- **Pilot scope, then expand.** Start every policy at `SG-IRM-Pilot`, tune thresholds and exclusions
  against real activity, and expand **group-by-group** only after the gates pass.
- **Tune out noise deliberately.** Use file-type/domain exclusions and the intelligent-detection
  settings to cut false positives — but record why, so exclusions don't quietly blind the program.

## Detection hygiene

- **Enable only the indicators you need**, and make sure their prerequisites are met (device onboarding
  for device indicators; MDE connection for security-policy violations; HR connector for departing-user
  triggers).
- **Keep the HR connector fresh.** A stale leaver feed means departing-user detection silently stops.
  Monitor connector health (`PURVIRM-Test-Readiness.ps1`) and alert on failed uploads.
- **Prefer the HR trigger over account-deletion** where possible — it detects theft **before** the
  account is gone, not after.
- **Use priority user groups sparingly** and with HR/legal — membership in a "priority" group is itself
  sensitive.

## Operations and evidence integrity

- **Triage promptly and consistently.** A backlog of un-triaged alerts undermines both effectiveness
  and fairness. Agree SLAs for triage with the team.
- **Never delete cases/audit records to tidy up.** They are the defensible, HR/legal-facing trail.
  Retention/disposition of IRM records is a **records/legal determination**.
- **Report without over-exposing.** Leadership rollups should show counts/severity/trends
  (`PURVIRM-Report.ps1`) — not identities — unless the audience is authorized.

## Change control and safety

- **All policy/scope changes go through change control**, previewed with `-WhatIf` where a script
  supports it.
- **No secrets in automation.** Scripts authenticate interactively (`Connect-IPPSSession` /
  `Connect-MgGraph`); the HR-connector credential lives in the connector app, never in code.
- **Verify against your licensing/tenant.** IRM capabilities are plan-gated and the portal evolves —
  confirm availability rather than assuming, and re-check when Microsoft ships changes.

## Fit with the rest of Purview

- **IRM + DLP.** Data-leak policies can trigger on DLP matches; Adaptive Protection can let IRM risk
  levels drive dynamic DLP/Conditional Access (verify licensing/availability).
- **IRM + Communication Compliance / eDiscovery.** Case actions can escalate into these workflows —
  keep the role separation consistent across all of them.
- **IRM + audit.** The unified audit log records IRM admin/reviewer activity; keep audit logging on and
  use it as independent corroboration.
