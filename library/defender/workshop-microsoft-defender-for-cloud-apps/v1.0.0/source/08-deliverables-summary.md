# 8. Deliverables Summary — Workshop: Microsoft Defender for Cloud Apps

This workshop is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation set below plus five lab-helper assets, yours to keep and reuse to train new analysts.

## Documentation (source/)
- **executive-summary.md** — what the workshop is, the outcome, the boundary, and the effort.
- **01-solution-overview.md** — what a CASB / MDA is, how Cloud Discovery, connectors, app governance, and the policy engine work, the operator console/workflows, the five labs, and what is in/out of scope.
- **02-requirements.md** — workshop-specific prerequisites (MDA licensing, a discovery data source, a connected app, app governance, hunting access, read scopes, roles), each with verify / implement-if-missing. Category-level prerequisites are in `global-requirements-defender.md`.
- **03-implementation.md** — the facilitator + student runbook: Lab 0 readiness plus the five guided labs, with named objects and pass/fail gates.
- **05-testing.md** — environment validation, the per-attendee knowledge-check, and the capstone demonstration.
- **06-troubleshooting.md** — symptom → cause → fix for the common workshop and MDA issues.
- **07-best-practices.md** — how to run the workshop and operate MDA well, plus where to go next in the catalog.
- **08-deliverables-summary.md** — this file.
- **global-requirements-defender.md** — the category-level prerequisites (shared across all Defender solutions).

## Lab-helper assets (scripts/)
- **WSMCA-Discovery.ps1** — read-only discovery (Microsoft Graph): MDA alert count, connected-app signal, and an OAuth app count/inventory summary for Lab 0. Makes no changes.
- **WSMCA-Validate.ps1** — read-only readiness validation: Graph connectivity + read scopes, MDA alert data reachable, connected-app/OAuth signal, and advanced-hunting reminder. Green = ready to teach.
- **WSMCA-Report.ps1** — read-only workshop summary report: MDA alerts by severity plus shadow-IT / OAuth shortlist templates for Labs 1 and 3.
- **WSMCA-LabQueries.kql** — advanced-hunting KQL pack for Labs 1, 2, 3, and 5: shadow-IT / discovery, connected-app activity, OAuth apps, and anomaly-investigation queries over `CloudAppEvents`.
- **WSMCA-OAuthApp-Lab.ps1** — read-only Lab 3 helper: enumerates OAuth service principals and consent grants with risk hints (high-privilege scopes, unverified publisher, broad consent) and prints the approval-gated revoke steps (**preview only — revokes nothing**).

## Take-home runbook artifacts (produced during the labs)
- Saved hunting queries: `Discovery-ShadowIT – CloudApps Lab – Pilot`, `OAuthApps – CloudApps Lab – Pilot`, `Anomaly-Investigation – CloudApps Lab – Pilot`.
- The report-only session policy `Monitor-Downloads – CloudApps Lab – Pilot`.
- The `ShadowIT-Shortlist – CloudApps Lab – Pilot` and `OAuthRisk-Shortlist – CloudApps Lab – Pilot`.
- The `Investigation – CloudApps Lab – Pilot` findings document.

*Delivered as a Word document and PDF, plus all five lab-helper scripts in a single ZIP — yours to keep and reuse.*
