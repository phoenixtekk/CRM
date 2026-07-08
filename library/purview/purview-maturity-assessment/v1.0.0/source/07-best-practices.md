# 7. Best Practices — Microsoft Purview Maturity Assessment

- **Score from evidence, not opinion.** Drive every domain score from what `PURVIEW-Discovery.ps1`
  actually reads in the tenant, and attach the signal to the score. A maturity number nobody can trace
  to configuration is a survey, not an assessment.
- **Set targets before you score.** Not every organization needs L5 in every domain. Agree each
  domain's target level and weight (`Purview Maturity Model - 10 Domains x 6 Levels`) with the
  compliance, security, and records owners first — a score without a target has no meaning.
- **Separate "unlicensed" from "unconfigured."** A domain absent because it is not licensed is a
  budget/roadmap dependency; one licensed but unconfigured is a config task. Flag licensing-capped
  domains and score them against their achievable ceiling, so the overall band is honest.
- **Flag, don't invent.** Purview is plan-gated and the portal evolves. Where a signal or a portal path
  is uncertain, mark the domain **"verify your licensing/tenant"** rather than asserting a level.
- **Keep the assessment read-only; gate the quick wins.** The scorecard and roadmap require no changes.
  Only run `PURVIEW-Remediation.ps1` after the readout is signed off, always `-WhatIf` first, and only
  ever into **test/simulation/disabled** mode — never straight to enforce.
- **Pilot every quick win.** Baseline objects (`Sensitivity Label - Confidential - Baseline`,
  `DLP Policy - Baseline PII - Test`) go to `Purview - Pilot Users` in non-enforcing mode; enforcement
  is a separate, change-controlled roadmap step.
- **Defer the determinations.** Retention schedules, records file plans, legal holds, and insider-risk
  / communication-compliance case actions are **records / compliance / privacy / legal** decisions.
  Score and roadmap the *technical capability*; route the *determination* to the owning function.
- **Treat D4/D5 as HR/privacy-sensitive.** Score Insider Risk and Communication Compliance on
  presence and privacy-by-design (pseudonymization, role separation) — read only presence, never case
  content, and route findings to HR/legal.
- **Weight for your risk profile.** Regulated organizations weight D3 (records), D6 (audit), and
  D7 (eDiscovery) higher; IP-sensitive ones weight D1/D2. Make the weighting explicit so the overall
  band reflects real priorities.
- **Re-run on a cadence.** The single most valuable output is the **trend**. Re-run the same model each
  quarter; a rising overall band is the proof the program is improving and the budget is working.
- **Document the model, the scores, and the rollback.** Record the domains, targets, weights, each
  score's evidence, the roadmap owners, and the baseline rollback — so the assessment is repeatable and
  defensible under change control and audit.
