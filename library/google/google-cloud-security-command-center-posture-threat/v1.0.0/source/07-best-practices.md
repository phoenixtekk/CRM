# Best Practices

Durable practices for keeping Security Command Center (SCC) valuable — high signal, owned
findings, and a closing loop — after the pilot.

## Coverage & edition
- **Re-verify the edition periodically.** SCC editions, included services, and detectors change.
  Re-run the coverage assessment (script #1) on a schedule and re-confirm what your edition
  includes against Google's current docs — don't assume last quarter's detector set still holds.
- **Keep the whole hierarchy in scope.** New folders/projects should inherit SCC coverage; audit
  for orphaned projects that fell outside scope.

## Noise control (so responders trust the queue)
- **Mute deliberately, document every exception.** Every mute in **Posture Baseline – Corp – v1**
  has a written justification, an owner, and a review date. Un-audited mutes hide real risk.
- **Tune the export filter, not the detectors.** Prefer filtering what streams to the SIEM over
  disabling detectors — you keep the finding in SCC for audit while sparing the SIEM the noise.
- **Review high-volume categories first.** A single noisy detector can drown the queue; fix the
  root cause (e.g. a standard that generates thousands of low-value findings) rather than muting
  blindly.

## Triage & ownership
- **Own by scope, not by person.** Route findings to **groups** (per the ownership matrix), so
  triage survives staffing changes.
- **SLA by severity, tracked automatically.** Run the triage/SLA report (script #3) on a cadence;
  surface at-risk and breached findings to owners before they age out.
- **Close the loop on remediation.** A finding isn't done until SCC shows it `INACTIVE` on rescan
  — track re-open rate; a finding that keeps returning signals a systemic gap, not a one-off.
- **Accept-risk is a decision, not a default.** If a Low finding won't be fixed, record an explicit
  risk acceptance (owner + expiry) rather than letting it linger unworked.

## Notifications & export
- **One governed export path.** Keep **Finding Export Topic – SecOps – v1** in the SecOps project
  with least-privilege IAM; don't scatter ad-hoc notification configs across projects.
- **Least privilege for consumers.** The SIEM/consumer service account gets only
  `roles/pubsub.subscriber` on the subscription — never Owner, never an exported key committed to
  disk. Prefer workload identity / ADC.
- **Verify the SCC notification service-account binding** after any org change; a missing
  `roles/pubsub.publisher` binding silently stops the stream.

## Security & safety
- **No secrets in automation.** The provided tools use ADC / the environment; never hardcode
  credentials or commit service-account keys. Restrict who can create notification configs and
  mute rules (privileged, org-level).
- **Change control for org-wide actions.** Enabling/disabling services, org-wide mutes, and
  notification changes go through change control with the documented rollback ready.
- **Least-privilege triage roles.** Triagers edit finding state; only admins configure services and
  mutes.

## Operating rhythm
- **Weekly triage review** of the SLA report; **monthly** posture-drift and mute review; **quarterly**
  edition/coverage re-verification. Trend finding volume, time-to-close, and re-open rate — a falling
  time-to-close and re-open rate is the proof the program is working.
- **Keep the runbook current.** As teams and services change, update **Triage Runbook – SecOps – v1**
  so ownership never goes stale.
