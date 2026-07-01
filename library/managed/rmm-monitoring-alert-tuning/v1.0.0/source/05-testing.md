# 5. Testing & Validation — RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting

Validation proves the tuning loop worked: noise fell, actionability rose, nothing critical was missed, and alerts became correctly-routed tickets. Every gate compares the post-tune state against the **Alert Inventory & Baseline – RMM Estate – Assess** and is captured in the **Tuning Baseline Report – Noise & Actionability – Validate**. Run `RMMTUNE-Report.ps1` to produce the metrics and `RMMTUNE-Validation.ps1` to emit PASS/FAIL.

Each gate lists what to test, how to verify, and the pass criterion. Do not declare success on any single gate — **all four** must pass before fleet-wide rollout (per Implementation Step 14).

---

## Gate 1 — Noise reduced versus baseline
**Test.** Compare alerts/endpoint/day after tuning against the baseline figure.
**Verify.** Run `RMMTUNE-Report.ps1` over the post-tune window; compare to the baseline stored by `RMMTUNE-Set-AlertBaseline.ps1`.
**Pass criterion.** Alerts/endpoint/day reduced by **at least the agreed target** (typical target ≥ 50%, common result 60–90%). `RMMTUNE-Validation.ps1` returns PASS for the noise metric.

## Gate 2 — Percent actionable increased
**Test.** Compare the share of alerts that resulted in (or warranted) action, before versus after.
**Verify.** Using the severity matrix dispositions and ticket outcomes, compute % actionable post-tune; compare to baseline.
**Pass criterion.** % actionable **rose** to at least the target set in Implementation Step 6 (e.g. ≥ 60%). PASS from `RMMTUNE-Validation.ps1`.

## Gate 3 — No missed criticals
**Test.** Confirm that every SEV-1/SEV-2 condition that occurred in the validation window was alerted, routed, and acknowledged — i.e. tuning did not suppress a real critical.
**Verify.** Cross-check known incidents / client-reported issues in the window against the alert and ticket records; confirm each critical produced a timely alert and ticket. Review the **Threshold & Hysteresis Policy Set – Monitor Conditions – Tune** and **Dedup & Correlation Ruleset – Alert Stream – Tune** for any suppression that could hide a critical.
**Pass criterion.** **Zero** missed criticals. This gate is mandatory and cannot be waived — any miss fails the whole validation and requires re-tuning the offending policy.

## Gate 4 — Alert-to-ticket mapping correct
**Test.** Confirm surviving alerts open tickets on the correct PSA board/queue, at the correct priority/category, with dedup/correlation collapsing storms into single tickets and auto-close closing them.
**Verify.** Inject or observe representative alerts of each severity; trace each through the **Alert-to-Ticket Mapping – PSA Integration – Route** into the PSA. Confirm one root event yields one ticket, not a storm.
**Pass criterion.** Every tested severity routes to the correct board/priority; no duplicate-storm tickets; auto-closed alerts close their tickets. PASS.

---

## Secondary checks
- **MTTA / MTTR trend.** Confirm mean time to acknowledge and resolve improved or held steady (`RMMTUNE-Report.ps1`).
- **Self-heal success rate.** Confirm SEV-4 automations in the **Self-Heal Automation Library – Common Conditions – Automate** resolve their conditions and only ticket on failure.
- **Routing correctness by time-of-day.** Confirm an after-hours SEV-2 batches and an after-hours SEV-1 pages, per the **Routing & Escalation Matrix – Business Hours / On-Call – Route**.

## Sign-off
Attach the **Tuning Baseline Report – Noise & Actionability – Validate** (before/after for all four metrics plus missed-critical count) to the change record and obtain stakeholder sign-off before rolling tuned policies beyond the pilot client.
