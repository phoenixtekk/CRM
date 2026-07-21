# 8. Deliverables Summary — Anomaly Detection & Application Reliability with Endpoint Analytics

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — the three reliability signals (application reliability, device reliability /
  restart analytics, anomaly detection), how to read each, the bad-app-vs-bad-rollout distinction, the
  triage-and-close-the-loop practice, and how this product relates to the **parent** Endpoint Analytics
  solution and the **automated-fix companion** (Proactive Remediations at Scale).
- **Requirements Guide** — every prerequisite (Endpoint Analytics enabled and reliability data flowing
  via the parent, licensing/entitlement, anomaly-detection availability, sufficient device population,
  device/data scope, reader access, group-creation rights) with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements. Feature/licensing/navigation
  specifics are flagged **verify against current Microsoft documentation**.
- **Implementation Guide** — exact, ordered steps across six phases: confirm reliability data is
  flowing, read application reliability and separate bad-app from bad-rollout, read device reliability /
  restart analytics, use anomaly detection to catch a regression, triage and route (handing scriptable
  fixes to the automated-fix companion), then establish the review cadence and expand. Every object is
  named and reused verbatim.
- **Testing & Validation** — nine tests with explicit pass/fail gates and an acceptance gate, proving
  the signals are populated, a known bad app and a restart trend are correctly identified, an anomaly is
  correctly interpreted vs. a false signal, and a confirmed signal is routed and verified to recover.
- **Troubleshooting** — top-down diagnosis for missing/delayed reliability data, false anomalies,
  crashes that can't be attributed to a version, unclear restart causes, and licensing/scope, plus a
  scripts section.
- **Best Practices** — how to read the signals, separate bad app from bad rollout, route and close the
  loop, hand scriptable fixes to the companion, and run the cadence as a measured habit.

## PowerShell scripts (Microsoft Graph) — `ENDPTREL-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each header states **Purpose · How to run · Graph scopes · Expected results**. Four are **read-only**;
one is a state-changer that **defaults to `-WhatIf`**.

1. **`ENDPTREL-Discovery.ps1`** *(read-only)* — reliability-data availability, the scoped device count,
   and the top unreliable apps/devices.
2. **`ENDPTREL-Validate.ps1`** *(read-only)* — PASS/FAIL readiness gate: reliability signals present for
   the pilot, anomaly detection active.
3. **`ENDPTREL-Report.ps1`** *(read-only)* — exports the application + device reliability + anomaly
   summary to `Reliability Review – <YYYY-MM>.csv` for the review cadence.
4. **`ENDPTREL-Test-Signal.ps1`** *(read-only)* — confirms a known reliability signal is visible and
   attributable to an app/version (and, after a fix, that it has receded).
5. **`ENDPTREL-Set-ReviewScope.ps1`** *(state-changer — defaults to `-WhatIf`)* — creates/assigns the
   `Reliability – Review Scope` group for the cadence. Previews only until re-run with `-Commit`.

> Reliability + anomaly data is read from the `userExperienceAnalytics*` Microsoft Graph resources,
> which evolve over time and can vary by cloud — the scripts fail soft and flag **verify against current
> Microsoft documentation** rather than erroring if a resource path has moved.

## Hero image
- **`ENDPTREL-hero.png`** — the product image (1200×1200) used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
