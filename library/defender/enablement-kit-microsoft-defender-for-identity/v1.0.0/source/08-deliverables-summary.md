# 8. Deliverables Summary — Enablement Kit: Microsoft Defender for Identity

This enablement kit is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation set below plus five lab-helper assets, yours to keep and reuse to train new analysts.

## Documentation (source/)
- **executive-summary.md** — what the enablement kit is, the outcome, the boundary, and the effort.
- **01-solution-overview.md** — what MDI is, how sensors and identity detections work, the operator console/workflows, the five labs, and what is in/out of scope.
- **02-requirements.md** — enablement-kit-specific prerequisites (healthy sensor, pilot scope, ISPM data, honeytoken candidate, hunting access, read scopes, roles), each with verify / implement-if-missing. Category-level prerequisites are in `global-requirements-defender.md`.
- **03-implementation.md** — the facilitator + student runbook: Lab 0 readiness plus the five guided labs, with named objects and pass/fail gates.
- **05-testing.md** — environment validation, the per-attendee knowledge-check, and the capstone demonstration.
- **06-troubleshooting.md** — symptom → cause → fix for the common enablement kit and MDI issues.
- **07-best-practices.md** — how to run the enablement kit and operate MDI well, plus where to go next in the catalog.
- **08-deliverables-summary.md** — this file.
- **global-requirements-defender.md** — the category-level prerequisites (shared across all Defender solutions).

## Lab-helper assets (scripts/)
- **WSMDI-Discovery.ps1** — read-only discovery (Microsoft Graph Security): MDI sensor health, recent identity alerts, and candidate honeytoken accounts for Lab 0/Lab 3. Makes no changes.
- **WSMDI-Validate.ps1** — read-only readiness validation: sensor health, ISPM/posture data present, advanced-hunting access, and read-scope consent. Green = ready to teach.
- **WSMDI-Report.ps1** — read-only enablement kit/posture summary report: identity alert counts by severity and the ISPM recommendation list for the Lab 4 shortlist.
- **WSMDI-LabQueries.kql** — advanced-hunting KQL pack for Labs 2, 3, and 5: recon, lateral-movement, honeytoken-activity, and investigation queries over the `Identity*` tables.
- **WSMDI-Honeytoken-Lab.ps1** — read-only helper that lists dormant/no-sign-in candidate accounts and prints the exact portal steps to tag one as a honeytoken (**preview only — tags nothing**).

## Take-home runbook artifacts (produced during the labs)
- Saved hunting queries: `Recon – Identity Lab – Pilot`, `LateralMovement – Identity Lab – Pilot`, `Honeytoken – Identity Lab – Pilot`.
- The honeytoken tag `Honeytoken – Identity Lab – Pilot` (`svc-legacy-backup`).
- The `ISPM-Shortlist – Identity Lab – Pilot` remediation shortlist.
- The `Investigation – Identity Lab – Pilot` findings document.

*Delivered as a Word document and PDF, plus all five lab-helper scripts in a single ZIP — yours to keep and reuse.*
