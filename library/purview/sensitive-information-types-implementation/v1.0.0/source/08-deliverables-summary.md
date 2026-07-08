# 8. Deliverables Summary — Sensitive Information Types Implementation (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The built-in SIT model — the library, confidence levels and instance count as the two tuning dials, where SITs are consumed across Purview, and the select→test→tune journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (licensing to view/test/measure SITs, SIT roles **including Content Explorer viewer**, classification intent, a fake positive+negative test corpus, DLP for simulation, an FP threshold + pilot ring) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: inventory the built-in library → select per category → test against the corpus → measure in **simulation** → tune the dials (and, only if needed, an editable SIT copy) → validate and hand off; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — true positives detected (A), negatives rejected + low false-positive rate (B), selection consistent and handed off (C) — plus safety/rollback checks, all with fake test data. |
| **Troubleshooting Guide** | The common failure modes (SIT not matching, look-alike false positives, can't see matched items, Content Explorer empty) and how to resolve them. |
| **Best Practices** | Reuse-built-in-first, tune-the-dials-before-the-pattern, test-negatives-too, measure-in-simulation, and keep-the-registers-consistent. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; the one tool that writes creates a policy **in
simulation mode only — never enforce** — and requires an explicit `-Commit`. No credentials are stored in
code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **CLSSIT-Discovery.ps1** | Built-in SIT inventory: lists the SITs available in the tenant, the confidence levels each publishes, and which existing DLP/auto-labeling policies already reference SITs. | Read-only |
| 2 | **CLSSIT-Test.ps1** | SIT accuracy tester: runs corpus files (positive + negative) through a selected SIT and reports match/no-match and confidence per file, for corpus scoring. | Read-only |
| 3 | **CLSSIT-BuildSimPolicy.ps1** | Measurement policy builder: creates a DLP policy referencing the selected SIT(s) at a chosen confidence/instance count **in simulation mode**, for real-traffic false-positive measurement. | `-WhatIf` (writes need `-Commit`; simulation-only, never enforce) |
| 4 | **CLSSIT-Report.ps1** | Match / false-positive report: exports simulation match activity for TP-vs-FP classification and false-positive-rate calculation. | Read-only |
| 5 | **CLSSIT-Set-Scope.ps1** | Scope helper: reports and (with `-Commit`) adjusts the measurement policy's included/excluded users/groups (e.g. the pilot ring). | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- The built-in SIT library inventoried and mapped: every in-scope data category → a named built-in SIT in
  the `SIT Selection Register`, or explicitly flagged as a gap for the custom/EDM/trainable solutions.
- Each selected SIT **tested** against a fake positive+negative corpus — positives detected at the target
  confidence, negatives rejected.
- Each selected SIT **measured** against real traffic in a **simulation** DLP policy, with matches inspected
  in Content Explorer and classified TP/FP.
- False-positive rate **tuned** to at/under the agreed threshold via confidence level, instance count, and
  (only where necessary) an editable SIT copy — with the original built-in SIT unmodified.
- The `SIT Selection Register` and `SIT Threshold Register` finalized and handed to the downstream controls;
  measurement policies decommissioned; evidence captured.

> **Boundary:** the solution delivers the accurate, validated **detector** and the evidence. The **data
> categories in scope, the SITs that legally satisfy a regulation, and the acceptable false-positive
> threshold per category** are compliance/privacy/legal determinations, captured alongside the evidence.
> Building custom SITs, Exact Data Match, and trainable classifiers for gaps is delivered by the adjacent
> solutions.
