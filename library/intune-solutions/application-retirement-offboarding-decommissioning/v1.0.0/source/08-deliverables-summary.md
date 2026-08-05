# Deliverables Summary

This solution delivers a complete, repeatable process plus tooling for retiring an application from
an Intune-managed Windows fleet and proving it is decommissioned.

## Documents

| Document | What it gives you |
|---|---|
| **Solution Overview** (`01-solution-overview.md`) | The retirement pipeline, the five triggers, exactly how Intune's Uninstall intent behaves (and why Required beats it), waves vs big-bang, and the honest limitations (irreversibility, check-in bound, per-device failures out of scope). |
| **Global Requirements** (`global-requirements-intune-solutions.md`) | Category-level prerequisites (tenant, Intune, enrollment, Windows baseline, network). |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites — roles, Graph read scopes, a working uninstall command, a reliable detection rule, usage evidence, a named owner/approver, the data-handling determination, wave groups, and artefact knowledge — each with Description / Why / Verify / Implement. |
| **Implementation Guide** (`03-implementation.md`) | The 15-step campaign: name the trigger and decision record, discovery, impact analysis, comms + grace period, wave groups, the DATA checkpoint, point the Uninstall intent (or use supersedence), validate, expand, reclaim licences, handle stragglers, clean up every artefact, produce the evidence pack, monitor. Every object is named and reused. |
| **Testing** (`05-testing.md`) | Seven pass/fail gates from data preservation through evidence + closure, plus a full-campaign regression. |
| **Troubleshooting** (`06-troubleshooting.md`) | Campaign-level problems: devices not checking in, partial fleet removal, "nothing happened", reappearance, reporting gaps — and when to escalate a per-device failure. |
| **Best Practices** (`07-best-practices.md`) | Decision discipline, protecting data, intent precedence, cleanup, straggler reach, and repeatability. |
| **Executive Summary** (`executive-summary.md`) | The business case in one page. |

## PowerShell scripts

All scripts use the Microsoft Graph PowerShell SDK and accept `-Environment USGov` / `USGovDoD` for
sovereign clouds. All five are **read-only by default**; the two planning helpers write only files
you name, and no script performs an uninstall or a deletion — removal actions are done deliberately
in the Intune portal per the Implementation Guide.

| Script | Purpose | Access |
|---|---|---|
| **APPRET-Discovery.ps1** | Install base + assignments/intents + dependency/supersedence + per-device install list (evidence exhibit A). | Read-only |
| **APPRET-ImpactAnalyzer.ps1** | What breaks if removed: apps that depend on it, supersedence chains, assign groups + member counts, shared detection scripts. | Read-only |
| **APPRET-WaveReporter.ps1** | Wave `Status` (gate check), `Plan` (split install base into balanced waves), `Stragglers` (classify non-removed devices). | Read-only |
| **APPRET-ArtifactFinder.ps1** | Leftover artefacts: app object, groups (SAFE vs SHARED), CA references, enterprise app, remediation scripts. | Read-only |
| **APPRET-EvidenceExport.ps1** | Compile the decommission evidence pack (final status, residuals, remaining artefacts) to a timestamped folder. | Read-only |

## How the pieces fit

1. Confirm **Requirements**; open the **Decision Record** and name the trigger.
2. Run **Discovery** for the install base; obtain a real usage signal.
3. Run **ImpactAnalyzer**; resolve anything that depends on the app.
4. Communicate; set the grace period; build **wave groups** and the exclusion group.
5. **Protect data** (the irreversible checkpoint), then point the **Uninstall** intent at Wave 0
   (or configure supersedence for a migration).
6. **Validate** with the testing gates; use **WaveReporter** to expand wave by wave and classify
   **stragglers**.
7. Reclaim **licences**; use **ArtifactFinder** to clean up every leftover.
8. Run **EvidenceExport** for the proof pack; **monitor** for reappearance, then close.
