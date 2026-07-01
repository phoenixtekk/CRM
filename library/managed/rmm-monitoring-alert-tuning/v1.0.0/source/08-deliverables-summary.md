# 8. Deliverables Summary — RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting

This solution ships as a documentation set, a script toolkit, and a hero image. Together they let a managed-services team run the full tuning loop **Assess → Classify → Tune thresholds → Automate/self-heal → Route → Validate → Operate** against any common RMM and prove the result.

---

## Documentation
- **01 — Solution Overview** — description, rationale, the four canonical severity tiers, and the named objects produced.
- **02 — Requirements** — solution-specific prerequisites (R1…R11), each with Description / Why / Verify / Implement-if-missing.
- **Global Requirements (Managed)** — category-wide prerequisites (GR1…GR7) shared by all Managed solutions.
- **03 — Implementation** — the ordered, imperative runbook for the full tuning loop.
- **05 — Testing & Validation** — the four pass/fail gates (noise reduced, % actionable up, no missed criticals, alert→ticket correct) plus secondary checks.
- **07 — Best Practices** — operating guidance to keep the tuned state healthy.
- **06 — Troubleshooting** — common failure modes and fixes.
- **Executive Summary** — the one-page business case and outcomes.

## Scripts (PowerShell)
All scripts default to **read-only** and carry the neutral note "Managed — read-only." Those that can change live state require an explicit `-Apply` and support `-WhatIf`.

- **RMMTUNE-Discovery.ps1** — pulls/parses an alert export and baselines alert volume by type, device, and hour. Builds the first part of the **Alert Inventory & Baseline – RMM Estate – Assess**.
- **RMMTUNE-Set-AlertBaseline.ps1** — computes and stores the alerts/endpoint/day baseline (and supporting metrics); `-WhatIf` previews. Finalizes the **Alert Inventory & Baseline – RMM Estate – Assess**.
- **RMMTUNE-Report.ps1** — produces the noise / actionability / MTTA / MTTR report to CSV. Drives the **Tuning Baseline Report – Noise & Actionability – Validate**.
- **RMMTUNE-Validation.ps1** — compares post-tune metrics against the baseline and emits PASS/FAIL against the testing gates.
- **RMMTUNE-Remediation.ps1** — flags noisy alert sources; read-only/`-WhatIf` by default, acts only with `-Apply`. Used in the Operate phase to catch drift.

## Hero image
- **RMMTUNE-hero.png** — the solution hero image for the marketplace listing.

---

## How the deliverables map to the loop
| Phase | Primary deliverables |
|-------|----------------------|
| Assess (baseline) | `RMMTUNE-Discovery.ps1`, `RMMTUNE-Set-AlertBaseline.ps1`, **Alert Inventory & Baseline – RMM Estate – Assess** |
| Classify | Section 03/07 guidance, **Severity & Taxonomy Matrix – Alert Classes – Classify** |
| Tune thresholds | Section 03, **Threshold & Hysteresis Policy Set – Monitor Conditions – Tune**, **Dedup & Correlation Ruleset – Alert Stream – Tune** |
| Automate/self-heal | Section 03, **Self-Heal Automation Library – Common Conditions – Automate** |
| Route | Section 03, **Routing & Escalation Matrix – Business Hours / On-Call – Route**, **Alert-to-Ticket Mapping – PSA Integration – Route** |
| Validate | `RMMTUNE-Report.ps1`, `RMMTUNE-Validation.ps1`, **Tuning Baseline Report – Noise & Actionability – Validate** |
| Operate | `RMMTUNE-Remediation.ps1`, recurring re-run of the above |

Total: **8 documents + 5 scripts + 1 hero image (`RMMTUNE-hero.png`).**
