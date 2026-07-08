# Best Practices — Departing-Employee Data-Theft Monitoring Quickstart

Operating principles that keep a departing-user monitoring capability **effective, defensible, and
privacy-respecting**. They reflect the three non-negotiables: privacy by design, strict role separation,
and determinations that belong to HR/legal.

## Privacy first — always

- **Keep anonymization ON.** Reviewers see pseudonymized identities by default. De-anonymization is a
  **justified, role-gated, audited exception** — never a routine step, never the administrator's call.
- **Scope to the minimum.** Put only actual/imminent **leavers** in scope, not the whole workforce. A
  narrow, purpose-built scope is both quieter and far easier to justify to privacy/legal — and it is the
  whole reason this template uses a trigger.
- **Least data, least reveal.** Reveal identity only when a case genuinely requires it, and record why.
- **Document the privacy decisions** (anonymization posture, who may de-anonymize, on what basis) and
  keep them current with privacy/legal.

## Role separation — enforce it, then watch it

- **One function per person.** Admins configure; Analysts triage; Investigators go deep; Auditors watch
  the reviewers. Do **not** concentrate roles, and do **not** assign the combined **Insider Risk
  Management** role group to operators.
- **Independent audit.** Assign **Auditors** who are **not** Admins/Analysts/Investigators, and have them
  review the IRM audit log on a schedule — especially every **de-anonymization**.
- **Re-verify after every change.** Re-run `IRMDEPART-Discovery.ps1` after any role change; treat a
  conflicting combination as an incident, not a convenience.

## Determinations stay with HR/legal

- **The policy produces evidence, not verdicts.** An alert or a case is a signal and an audited trail.
  Whether it reflects misconduct, and what happens next, is an **HR/legal/privacy determination**.
- **Route, don't rule.** Use case actions to route evidence (notification, eDiscovery, Communication
  Compliance, resolve). The employment decision is made by the people authorized to make it.
- **Engage before you enable.** Confirm the lawful basis / notice / consultation for your
  jurisdiction(s) **before** switching the policy on. Applicability is a legal determination.

## Make the leaver trigger reliable — this is where the value lives

- **Prefer the HR trigger over account-deletion.** The HR-connector leaver date lets you detect theft
  **before** the account is gone; account-deletion fires *after* the last day, when the damage is
  usually done. Use account-deletion only as a fallback when there is no HR feed.
- **Keep the HR connector fresh.** A stale leaver feed means departing-user detection silently stops.
  Monitor connector health (`IRMDEPART-Test-HRConnector.ps1`) and alert on failed uploads.
- **Tie the scope group to the leaver process.** In production, have your joiner-mover-leaver automation
  add imminent leavers to `SG-Departing-Pilot` (renamed for prod) so the monitored population tracks
  reality without manual effort.
- **Mind the look-back window.** Set **past-activity** long enough to catch exfiltration that began
  *before* the resignation was recorded — a resigning employee often starts copying files weeks ahead.

## Detection hygiene

- **Enable only the indicators you need**, and make sure their prerequisites are met — **device
  onboarding** for the high-signal USB/print/personal-cloud indicators; Office indicators for
  email/share exfiltration.
- **Use cumulative/sequence detection** for the classic slow leak — many small copies over days that no
  single event would flag.
- **Onboard the devices that matter.** Un-onboarded endpoints are invisible to device indicators; a
  leaver on an un-onboarded laptop is a blind spot.

## Pilot and tune before you rely

- **Pilot scope, then expand.** Start at `SG-Departing-Pilot`, tune thresholds and exclusions against
  real activity, and expand **group-by-group** only after the gates pass.
- **Tune out noise deliberately.** Use file-type/domain exclusions and the intelligent-detection settings
  to cut false positives — but record why, so exclusions don't quietly blind the program.

## Operations and evidence integrity

- **Triage promptly and consistently.** A backlog of un-triaged leaver alerts undermines both
  effectiveness and fairness — and leaver windows are short. Agree triage SLAs with the team.
- **Never delete cases/audit records to tidy up.** They are the defensible, HR/legal-facing trail.
  Retention/disposition of IRM records is a **records/legal determination**.
- **Report without over-exposing.** Leadership rollups should show counts/severity/trends
  (`IRMDEPART-Report.ps1`) — not identities — unless the audience is authorized.

## Change control and safety

- **All policy/scope changes go through change control**, previewed with `-WhatIf` where a script
  supports it.
- **No secrets in automation.** Scripts authenticate interactively (`Connect-IPPSSession` /
  `Connect-MgGraph`); the HR-connector credential lives in the connector app, never in code.
- **Verify against your licensing/tenant.** IRM capabilities are plan-gated and the portal evolves —
  confirm availability rather than assuming, and re-check when Microsoft ships changes.

## Fit with the rest of Purview

- **Departing-user + DLP.** DLP policies on your sensitive content complement the leaver policy —
  DLP blocks/warns in the moment; the leaver policy scores the pattern of exfiltration.
- **Departing-user + eDiscovery / Communication Compliance.** Case actions can escalate into these
  workflows — keep role separation consistent across all of them.
- **Departing-user + audit.** The unified audit log records IRM admin/reviewer activity; keep audit
  logging on and use it as independent corroboration. This quickstart can later grow into a full insider-
  risk program (data leaks, security-policy violations) on the same guardrails.
