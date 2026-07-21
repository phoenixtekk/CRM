# 8. Deliverables Summary — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — what Endpoint Analytics is, the four score areas and what each measures, how
  baselining/benchmarking works, the improvement loop, where it fits in the three-product cluster
  (pointers to the Proactive Remediations and reliability/anomaly siblings), benefits, and honest
  limitations.
- **Requirements Guide** — every prerequisite (Endpoint Analytics licensing, enrolled/co-managed
  devices, supported Windows, the data-collection policy, a scoped device group, diagnostic-data
  settings, telemetry endpoints, admin rights, co-management onboarding, national-cloud confirmation)
  with how to **verify** and how to **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across five phases: assess & scope,
  configure (enable data collection), pilot (let data flow, set a baseline), validate (read each score
  and its sub-signals), then build the backlog and expand to the fleet — every object named and reused.
- **Testing & Validation** — seven tests with explicit pass/fail gates and an acceptance gate, proving
  data flows, scores populate, a baseline is set, and a sub-signal is correctly interpreted into a backlog.
- **Troubleshooting** — top-down diagnosis for no data, blank/delayed scores, licensing/prereq gaps,
  wrong scope, and a scripts section (Graph scopes, exact-name matching, `-WhatIf` default).
- **Best Practices** — deploy/scope, baseline/measure, interpret, remediate/operate, and national clouds.

## PowerShell scripts (Microsoft Graph) — `ENDPTAN-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Graph scopes · Expected results**. Four are
**read-only**; one is a **state-changer that defaults to `-WhatIf`**.

1. **`ENDPTAN-Discovery.ps1`** — read-only tenant readiness: Endpoint Analytics data collection present,
   the pilot group exists, and managed Windows devices in scope.
2. **`ENDPTAN-Validate.ps1`** — PASS/FAIL gate: data collection configured, pilot group populated, and
   pilot devices managed and syncing recently.
3. **`ENDPTAN-Report.ps1`** — exports a CSV summary of the scores and sub-signals for records, baseline
   tracking, and stakeholder reporting.
4. **`ENDPTAN-Test-DataFlow.ps1`** — read-only confirmation that the pilot devices are submitting
   analytics data, calling out any device not yet reporting.
5. **`ENDPTAN-Set-DataCollection.ps1`** — the only state-changer: creates/assigns the
   `EPA – Data Collection – Pilot` policy to `EPA – Pilot Devices`. **Defaults to `-WhatIf`** (preview
   only); re-run with `-Apply` to commit.

> The Endpoint Analytics Graph resources evolve; the scripts flag where to **verify the current resource
> names against Microsoft documentation** and fall back to the portal where Graph is inconclusive.

## Hero image
- **`ENDPTAN-hero.png`** — the product image (1200×1200) used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.

## Companion products (buy for depth — not reproduced here)
- **Proactive Remediations at Scale — Detection & Remediation Script Packs for Microsoft Intune (#2)** —
  the engine that fixes backlog items at scale (authoring/packaging/scheduling detection + remediation
  scripts).
- **Anomaly Detection & Application Reliability with Endpoint Analytics (#3)** — the reliability and
  anomaly deep-dive (crash/hang root-cause, catching bad rollouts early).
