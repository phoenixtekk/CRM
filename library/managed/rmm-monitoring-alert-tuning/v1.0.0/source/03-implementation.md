# 3. Implementation — RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting

This is the ordered runbook for the tuning loop. The phase model is **Assess (baseline) → Classify → Tune thresholds → Automate/self-heal → Route → Validate → Operate.** Steps are imperative and reference the named objects from Section 1 verbatim. Do not assume any prerequisite — confirm Section 2 (`02-requirements.md`) and the global requirements (`global-requirements-managed.md`) are met first. The **Assess** and **Classify** phases are read-only; no live policy changes occur until **Tune thresholds**.

---

## Phase A — Assess (baseline)

### Step 1 — Confirm scope and read-only posture
1. Confirm the in-scope clients/devices (R7) and the agreed measurement window (minimum 14 days, target 30).
2. Confirm with stakeholders that Assess and Classify make **no live changes**.
3. Raise a change record (GR4) covering the whole engagement, noting that policy edits begin only at Phase C.

### Step 2 — Export the current alert stream
1. As an RMM administrator (R1), export the alert/event log for the window (R3) — via scheduled report, CSV, or API.
2. Ensure the export includes, at minimum: timestamp, device, alert type/source, severity, and acknowledge/resolve times if available.
3. Store the raw export in the documentation home (GR7) as the immutable source for the baseline.

### Step 3 — Parse and profile the alerts
1. Run `RMMTUNE-Discovery.ps1` against the export to parse it and tabulate alert volume by type, by device, and by hour-of-day.
2. Identify the **top noise sources** — the alert types and devices generating the most volume.
3. Record the parsed profile as the first part of the **Alert Inventory & Baseline – RMM Estate – Assess**.

### Step 4 — Compute the baseline metrics
1. Run `RMMTUNE-Set-AlertBaseline.ps1` (with `-WhatIf` first to preview, then commit) to compute and store: **alerts/endpoint/day**, **% actionable**, **MTTA**, and **MTTR**.
2. Establish the in-scope endpoint count from R7/GR3 so the per-endpoint figure is accurate.
3. Finalize the **Alert Inventory & Baseline – RMM Estate – Assess** and have stakeholders sign it off. This is the number every later phase is measured against.

---

## Phase B — Classify

### Step 5 — Build the severity & taxonomy matrix
1. Using the canonical four tiers (SEV-1 Critical, SEV-2 High, SEV-3 Warning, SEV-4 Auto/Self-Heal) from Section 1, classify **every** alert type found in Step 3.
2. For each alert type record: severity tier, whether it is actionable, the expected disposition (page / ticket / batch / self-heal / suppress), and the responsible queue.
3. Flag alert types that are non-actionable or pure noise for suppression in Phase C.
4. Save this as the **Severity & Taxonomy Matrix – Alert Classes – Classify** in the documentation home.

### Step 6 — Set actionability targets
1. From the baseline % actionable, set the target uplift (e.g. raise from 15% to ≥60%).
2. Identify which classifications drive the largest noise reduction so Phase C is sequenced by impact.

---

## Phase C — Tune thresholds

### Step 7 — Snapshot existing policies (rollback point)
1. Before editing anything, export/snapshot each monitor policy set you will change and attach it to the change record (GR4). This is the rollback point.

### Step 8 — Apply thresholds, duration, and hysteresis
1. For each noisy SEV-2/SEV-3 condition, raise the trigger threshold and add a **sustain duration** (the condition must persist N minutes/samples before alerting) so transient spikes are ignored.
2. Add **hysteresis** — separate the alert (raise) threshold from the clear (reset) threshold so a value oscillating around one number does not flap. Example: alert when disk free < 10% sustained 15 min; clear only when disk free ≥ 15%.
3. Add **auto-close** rules so a condition that self-recovers closes its own alert without human action.
4. Record all changes as the **Threshold & Hysteresis Policy Set – Monitor Conditions – Tune**, referencing the vendor's docs for the exact click path (thresholds and hysteresis exist in NinjaOne condition policies, Datto RMM monitors, and ConnectWise Automate internal monitors — the concept is identical; the UI differs).

### Step 9 — Deduplicate and correlate
1. Configure deduplication so repeated identical alerts from the same device collapse into one (with a count), rather than one per occurrence.
2. Configure correlation so a single root event (e.g. a site going offline) suppresses the dependent storm (every endpoint at that site) — alert on the parent, suppress the children.
3. Add maintenance-window suppression so planned reboots/patching do not alert.
4. Record these as the **Dedup & Correlation Ruleset – Alert Stream – Tune**.

---

## Phase D — Automate / self-heal

### Step 10 — Build the self-heal automation library
1. For each SEV-4 condition with a known deterministic fix (e.g. restart a hung service, clear a temp directory at high disk, restart the print spooler, re-register an offline agent), author or map a remediation script.
2. Configure each so the RMM runs the remediation automatically on the condition, and only creates a ticket **if the self-heal fails** (verify-then-act).
3. Test each remediation on the pilot client (R9/GR6) before fleet enablement.
4. Catalog these as the **Self-Heal Automation Library – Common Conditions – Automate**, naming each automation by the condition it resolves.

### Step 11 — Wire self-heal outcomes back to severity
1. Update the **Severity & Taxonomy Matrix – Alert Classes – Classify** so conditions now covered by self-heal are marked SEV-4, and confirm they no longer page on success.

---

## Phase E — Route

### Step 12 — Build the routing & escalation matrix
1. Using business hours and the on-call roster (R4), define routing by **severity × time-of-day**: SEV-1 pages on-call 24×7; SEV-2 tickets during business hours and batches after hours; SEV-3 tickets only on persistence/recurrence; SEV-4 self-heals silently.
2. Define escalation paths and timers (e.g. SEV-1 unacknowledged in 15 min escalates to the next on-call).
3. Save as the **Routing & Escalation Matrix – Business Hours / On-Call – Route**.

### Step 13 — Map alerts to PSA tickets
1. Configure the RMM→PSA integration (R2) so each surviving alert opens a ticket on the **correct board/queue**, with the right priority and category derived from the severity matrix.
2. Ensure deduplicated/correlated alerts produce **one** ticket, not many, and that auto-closed alerts close their tickets.
3. Save as the **Alert-to-Ticket Mapping – PSA Integration – Route**.

---

## Phase F — Validate

### Step 14 — Pilot and re-measure
1. Apply the tuned policy set to the pilot client first; let it run for a representative window.
2. Run `RMMTUNE-Report.ps1` and `RMMTUNE-Validation.ps1` to compare post-tune metrics against the **Alert Inventory & Baseline – RMM Estate – Assess** and produce PASS/FAIL against the gates in `05-testing.md`.
3. Produce the **Tuning Baseline Report – Noise & Actionability – Validate** showing before/after for noise, % actionable, MTTA, MTTR, and missed-critical count.
4. Only on PASS, roll the tuned policies to the remaining in-scope clients.

---

## Phase G — Operate

### Step 15 — Establish the recurring tuning cadence
1. Schedule a recurring (e.g. monthly) re-run of the loop: export → `RMMTUNE-Report.ps1` → review drift → re-tune.
2. Use `RMMTUNE-Remediation.ps1` (read-only/`-WhatIf` by default) to flag newly-noisy sources between full passes.
3. Update the named objects and the change record whenever policies change, keeping the documentation home (GR7) authoritative.
