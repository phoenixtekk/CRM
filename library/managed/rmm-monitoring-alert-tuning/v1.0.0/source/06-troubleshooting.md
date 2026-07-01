# 6. Troubleshooting — RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting

Common failure modes encountered while running the tuning loop, with likely cause and resolution. Symptoms are organized by phase (**Assess → Classify → Tune thresholds → Automate/self-heal → Route → Validate → Operate**). Each entry assumes nothing — verify the requirement (`02-requirements.md`, `global-requirements-managed.md`) before deeper diagnosis.

---

## Assess

### The alert export is missing timestamps, severity, or acknowledge/resolve times
**Cause.** The RMM report template excludes columns, or the API field set is narrow.
**Resolution.** Rebuild the export from a richer report template or expand the API field selection (R3). At minimum capture timestamp, device, type, and severity; resolve times are needed for MTTR but the baseline can proceed without them with that metric flagged as unavailable.

### `RMMTUNE-Discovery.ps1` cannot parse the export
**Cause.** Unexpected delimiter, header naming, or encoding from the vendor export.
**Resolution.** Confirm the file is CSV/UTF-8; map the vendor's column names to the expected fields (the script accepts a column-mapping parameter). Re-run after correcting.

### Alerts/endpoint/day looks implausibly high or low
**Cause.** Wrong in-scope endpoint count (stale agents inflate the denominator's error) or a partial export window.
**Resolution.** Reconcile the device count against the CMDB (R7/GR3), remove decommissioned agents, and confirm the export covers the full window before re-running `RMMTUNE-Set-AlertBaseline.ps1`.

## Classify

### Many alert types have no agreed action
**Cause.** Severity definitions were never ratified with the desk (R8).
**Resolution.** Run the severity workshop to ratify the four canonical tiers; any alert with no defined action is SEV-3 or suppressed. Update the **Severity & Taxonomy Matrix – Alert Classes – Classify**.

## Tune thresholds

### Alerts still flap after raising the threshold
**Cause.** No sustain duration or no hysteresis — the value oscillates across a single bare threshold.
**Resolution.** Add a sustain duration and separate the raise/clear thresholds (hysteresis) per Implementation Step 8. Confirm auto-close is enabled so self-recovering conditions clear themselves.

### A storm of identical alerts from one device persists
**Cause.** Deduplication not configured.
**Resolution.** Enable dedup so repeated identical alerts collapse into one with a count (**Dedup & Correlation Ruleset – Alert Stream – Tune**).

### A site outage still produces hundreds of endpoint alerts
**Cause.** No correlation/parent suppression.
**Resolution.** Configure correlation to alert on the parent (site/upstream) and suppress dependent children. Verify dependency mappings are current.

### Planned patching/reboots generate alerts
**Cause.** Maintenance windows not wired to suppression.
**Resolution.** Configure maintenance-window suppression so planned work does not alert.

## Automate / self-heal

### A self-heal automation runs but the condition returns immediately
**Cause.** The remediation treats a symptom, not the root cause, or lacks a verify step.
**Resolution.** Make the automation verify → act → verify; if it cannot confirm a fix, fail to a ticket rather than looping. Re-test on the pilot client (R9/GR6).

### Self-heal never fires
**Cause.** The RMM automation module is disabled or the alert→script trigger is not wired (R5).
**Resolution.** Enable the automation engine, confirm the agent runner is deployed, and bind the SEV-4 condition to its remediation.

## Route

### After-hours pages fire for non-critical conditions
**Cause.** Time-of-day routing not applied; SEV-2/SEV-3 paging after hours.
**Resolution.** Apply severity × time-of-day routing so only SEV-1 pages after hours; SEV-2 batches (**Routing & Escalation Matrix – Business Hours / On-Call – Route**).

### One root event creates many PSA tickets
**Cause.** Dedup/correlation not reflected in the alert-to-ticket mapping.
**Resolution.** Ensure correlated/deduplicated alerts produce one ticket; verify auto-closed alerts close their tickets (**Alert-to-Ticket Mapping – PSA Integration – Route**).

### Tickets land on the wrong board/queue or priority
**Cause.** Mapping rules not derived from the severity matrix.
**Resolution.** Align the PSA mapping to the severity tiers and per-client board/queue (R2); re-test each severity.

## Validate

### `RMMTUNE-Validation.ps1` returns FAIL on noise reduction
**Cause.** Top noise sources not yet tuned, or the validation window predates the changes.
**Resolution.** Confirm the validation window is fully post-change; re-tune the remaining top sources from the discovery profile and re-measure.

### Gate 3 flags a missed critical
**Cause.** An over-aggressive threshold, suppression, or correlation hid a real SEV-1.
**Resolution.** This is non-waivable. Identify the offending rule in the **Threshold & Hysteresis Policy Set – Monitor Conditions – Tune** or **Dedup & Correlation Ruleset – Alert Stream – Tune**, loosen it, re-validate, and document the correction in the change record.

## Operate

### Noise creeps back over weeks
**Cause.** Estate changed; new devices/apps introduced untuned conditions.
**Resolution.** Run the recurring loop (export → `RMMTUNE-Report.ps1` → review drift → re-tune). Use `RMMTUNE-Remediation.ps1` (read-only/`-WhatIf`) to flag newly-noisy sources between full passes.

### A tuned policy was changed and no one knows what it was
**Cause.** Change not snapshotted/recorded.
**Resolution.** Restore from the pre-change snapshot attached to the change record (GR4); reinforce that every policy edit is snapshotted to the documentation home (GR7) before the change.
