# Executive Summary — Microsoft Purview Executive Dashboard

## The problem
Boards, audit committees, regulators, and cyber-insurers now ask the same standing question: *how
compliant are we, how exposed is our data, and are we getting better or worse?* Microsoft Purview holds
the answer — but scattered across Compliance Manager, DLP, sensitivity labels, Content and Activity
Explorer, Insider Risk, DSPM, and Data Lifecycle/Records, each its own blade on its own refresh. There
is no single C-suite one-pager, and nothing shows **trend** unless someone captures snapshots over time.
So every time the question is asked, the answer is a slow, manual scramble — different each time, and
impossible to trend.

## The solution
A complete, self-guided **executive dashboard** for Microsoft Purview: **one page** covering
**compliance posture, data risk, and trend**. It defines the metric set and thresholds with your
stakeholders, collects the signals with safe read-only PowerShell (Security & Compliance PowerShell /
Microsoft Graph), merges the few portal-only values, renders the one-pager (HTML/CSV, Power BI-ready),
pilots it as a **draft** with every number checked against its Purview source, validates that it
reconciles, and schedules it to refresh — capturing a **monthly snapshot** so the page shows direction,
not just a point. Five safe-by-default PowerShell tools (read-only, or `-WhatIf` for the only two writes
— the definition file and the schedule) do the assessment, configuration, collection/render, validation,
and scope/health checks.

## What you get
- **Compliance posture, at a glance** — Compliance Manager score and delta, outstanding improvement actions, active regulatory assessments.
- **Data risk, quantified** — sensitivity-label coverage, high-severity DLP volume, sensitive items detected, retention coverage, and (where licensed) Insider Risk aggregate alerts and DSPM open recommendations.
- **Trend, not just a point** — a monthly snapshot so posture, DLP volume, label coverage, and incident counts are shown moving — the thing executives actually act on.
- **Every number attributed** — each KPI shows its data source and as-of timestamp, reconciled to its Purview blade, with unlicensed sources honestly flagged rather than fabricated.
- **Trustworthy by design** — pilot-first, validated before distribution, Insider Risk aggregate/de-identified with strict role separation.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot → Validate →
Expand** — building and reconciling the one-pager as a **draft** before any executive sees it, with
pass/fail gates and documented rollback. The dashboard is a **reporting layer**: it changes no Purview
policy; its only artifacts are a definition file, the snapshots, and a scheduled collection task.

## Boundaries
The signals are **licensing-/plan-dependent** (DSPM, Insider Risk, Content Explorer, and advanced DLP
require E5 / E5 Compliance; some preview) and the portal is **actively evolving** — capabilities and
paths are cited or flagged **"verify your licensing/tenant,"** never assumed. Some values are
**portal-only** in many tenants and are read by a named owner, not scraped. Whether the posture the
dashboard reports is **adequate**, and any **regulatory/records/legal determination**, are **deferred to
your compliance, records, privacy, and legal functions** — the solution provides the accurate
measurement, not the judgement.

## The bottom line
A one-page view for the C-suite — compliance posture, data risk, and trend — **configured, reconciled,
validated, and defensible** in Microsoft Purview, so the next time the board asks, the answer is already
on the page.
