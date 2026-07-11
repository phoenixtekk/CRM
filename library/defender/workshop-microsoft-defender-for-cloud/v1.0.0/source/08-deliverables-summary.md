# 8. Deliverables Summary — Workshop: Microsoft Defender for Cloud

This workshop is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation set below plus five lab-helper assets, yours to keep and reuse to train new cloud/SOC engineers.

## Documentation (source/)
- **executive-summary.md** — what the workshop is, the outcome, the boundary, and the effort.
- **01-solution-overview.md** — what MDC is (CSPM vs CWPP), how Secure Score, recommendations, workload plans, compliance, and connectors work, the operator console/workflows, the five labs, and what is in/out of scope.
- **02-requirements.md** — workshop-specific prerequisites (pilot subscription, Secure Score data, a Defender plan on, reader access, Az modules, ARG access, optional connector), each with verify / implement-if-missing. Category-level prerequisites are in `global-requirements-defender.md`.
- **03-implementation.md** — the facilitator + student runbook: Lab 0 readiness plus the five guided labs, with named objects and pass/fail gates.
- **05-testing.md** — environment validation, the per-attendee knowledge-check, and the capstone demonstration.
- **06-troubleshooting.md** — symptom → cause → fix for the common workshop and MDC issues.
- **07-best-practices.md** — how to run the workshop and operate MDC well, plus where to go next in the catalog.
- **08-deliverables-summary.md** — this file.
- **global-requirements-defender.md** — the category-level prerequisites (shared across all Defender solutions).

## Lab-helper assets (scripts/)
- **WSMDC-Discovery.ps1** — read-only discovery (Az.Security): Defender plan tiers, current Secure Score, `Microsoft.Security` provider state, Log Analytics workspaces, and AWS/GCP connectors for Lab 0. Makes no changes.
- **WSMDC-Validate.ps1** — read-only readiness validation: Az connectivity, provider registration, Secure Score data present, a Defender plan on, and ARG access. Green = ready to teach.
- **WSMDC-Report.ps1** — read-only Secure-Score + recommendations report (HTML) with a shortlist template for Labs 1/5, for trending and the take-home runbook.
- **WSMDC-LabQueries.kql** — Azure Resource Graph / KQL pack for Labs 1, 2, and 5: recommendations, Secure Score by control, security-alert triage, and unhealthy-resource queries over the `securityresources` tables (plus Defender alert tables).
- **WSMDC-SecureScore-Lab.ps1** — preview-first (`-WhatIf`) Lab 5 helper: shows what enabling a Defender plan / applying a posture step *would* do on the pilot subscription. Defaults to **preview — changes nothing** unless explicitly confirmed and approval-gated.

## Take-home runbook artifacts (produced during the labs)
- Saved queries: `Recommendations – Cloud Lab – Pilot`, `Alerts-Triage – Cloud Lab – Pilot`, `SecureScore-Trend – Cloud Lab – Pilot`.
- The `SecureScore-Shortlist – Cloud Lab – Pilot` remediation shortlist.
- The `Compliance-Evidence – Cloud Lab – Pilot` export.
- The `Investigation – Cloud Lab – Pilot` ops-notes / cadence document.

*Delivered as a Word document and PDF, plus all five lab-helper scripts in a single ZIP — yours to keep and reuse.*
