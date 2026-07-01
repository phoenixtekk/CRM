# 7. Best Practices — RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting

These practices keep the tuned state healthy and prevent the slow return of noise. They reinforce the phase model **Assess → Classify → Tune thresholds → Automate/self-heal → Route → Validate → Operate** and the named objects from Section 1.

---

## Measure before you touch anything
Never tune from intuition. Always establish the **Alert Inventory & Baseline – RMM Estate – Assess** first, and re-measure after. A change you cannot prove with the **Tuning Baseline Report – Noise & Actionability – Validate** is a change you should not have made. The whole discipline is the loop: measure → classify → threshold → automate → re-measure.

## Tune by impact, not alphabetically
The top handful of alert types almost always produce the majority of the noise. Sequence Phase C by the volume profile from `RMMTUNE-Discovery.ps1` so the first changes deliver the biggest drop. Resist the urge to perfect rare alerts before quieting the loud ones.

## Every alert must have an owner and an action
If an alert type has no defined action, it should not page or ticket — it is SEV-3 at most, or suppressed. The **Severity & Taxonomy Matrix – Alert Classes – Classify** is the contract: an alert exists only because someone will do something specific about it.

## Always use duration and hysteresis, never bare thresholds
A bare threshold flaps. Require a sustain duration before raising, and separate the raise and clear thresholds (hysteresis) so a value oscillating around the limit produces one alert, not dozens. Add auto-close so self-recovering conditions clean up after themselves. These three together — duration, hysteresis, auto-close — are the core of the **Threshold & Hysteresis Policy Set – Monitor Conditions – Tune**.

## Correlate root causes; suppress the dependent storm
When a site or upstream service fails, alert on the **parent** and suppress the children. One root event should produce one ticket. Maintain the **Dedup & Correlation Ruleset – Alert Stream – Tune** as dependencies change.

## Suppress planned work
Wire maintenance windows so patching, reboots, and planned changes do not alert. Unsuppressed maintenance is a leading, entirely avoidable noise source.

## Self-heal first, ticket only on failure
For known deterministic conditions, run the remediation automatically (verify → act → verify) and create a ticket **only if the fix fails**. Grow the **Self-Heal Automation Library – Common Conditions – Automate** deliberately, testing each automation on the pilot client (GR6) before fleet enablement, and keep every script read-only-by-default with an explicit `-Apply`.

## Route by severity AND time-of-day
A SEV-2 at 2 p.m. is a ticket; the same condition at 2 a.m. should batch, not page. Only true SEV-1 conditions page after hours. Keep the **Routing & Escalation Matrix – Business Hours / On-Call – Route** aligned with the current on-call roster and per-client business hours.

## Protect against missed criticals
The single unacceptable failure mode is suppressing a real critical. Review every suppression, correlation, and raised threshold against the question "could this hide a SEV-1?" Gate 3 in testing is non-waivable for exactly this reason.

## Make changes reversible and recorded
Snapshot every policy set before editing it, attach it to a change record (GR4), and keep the documentation home (GR7) authoritative. A tuned RMM with no change history is one technician away from un-tunable.

## Operate it as a recurring loop, not a project
Noise creeps back as the estate changes. Schedule a recurring re-run (monthly is typical): export → `RMMTUNE-Report.ps1` → review drift → re-tune. Use `RMMTUNE-Remediation.ps1` in its default read-only/`-WhatIf` mode to flag newly-noisy sources between full passes. A downward or flat alerts/endpoint/day trend over successive runs is the proof the practice is working.

## Stay vendor-agnostic in method, vendor-specific in execution
The method, severity tiers, and metrics are identical across NinjaOne, Datto RMM, ConnectWise Automate, and others. Defer only the click paths to the chosen RMM's current documentation — never hard-code a UI path into a runbook that outlives it.
