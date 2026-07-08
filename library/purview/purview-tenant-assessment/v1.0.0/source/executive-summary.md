# Executive Summary — Microsoft Purview Tenant Assessment

## The problem
Microsoft Purview capabilities get turned on one at a time — a DLP policy, a few sensitivity labels,
retention when legal asks, Insider Risk after an incident — and no one ever steps back to ask the
whole-estate question: *across every capability we've enabled, what is actually configured, where are
the gaps, and what should we fix first?* The result is a compliance blind spot: DLP that covers email
but not Teams, a label taxonomy published to no one, a retention policy sitting **disabled** for a year,
an Insider Risk policy running with no reviewers — none of it visible, and therefore none of it fixed.

## The solution
A complete, self-guided **tenant-wide Purview assessment**. It inventories **every enabled Purview
capability** — Information Protection, DLP, Data Lifecycle & Records, Insider Risk, Communication
Compliance, Audit, eDiscovery, DSPM (and DSPM for AI), Compliance Manager, the Unified Catalog, and the
classifiers & sensitive information types underneath — reads each read-only, scores it on coverage and
maturity, and produces a **prioritized findings register (P1/P2/P3)** with a recommendation per finding.
Where a quick, safe win exists, it remediates **in simulation/test/pilot mode first**, validates, and
hands over a defensible baseline. Five safe-by-default PowerShell tools (read-only, or `-WhatIf` until
you commit) do the preflight, inventory, remediation, validation, and reporting.

## What you get
- **The full picture** — an evidenced inventory of every enabled capability's current configuration, with **not licensed / not enabled / portal-only** stated honestly rather than guessed.
- **A prioritized plan** — findings ranked P1 (critical exposure / enforced-but-risky), P2 (coverage gap / drift), P3 (optimization), so remediation follows risk.
- **A capability scorecard** — coverage and maturity at a glance, capability by capability.
- **Safe stabilization** — the quick wins (a blunt DLP policy moved to simulation, a disabled retention policy enabled, unified audit turned on) applied pilot-first with rollback.
- **An executive readout** and a governed backlog the compliance owners can act on and track quarter over quarter.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot → Validate →
Expand** — reading the whole estate first, prioritizing by risk, and applying any fix **simulation/test/
pilot-first** on a limited scope, with pass/fail gates and documented rollback at every step.

## Boundaries
Microsoft Purview capabilities are **licensing-/plan-dependent** (many require E5 or the E5 Compliance
add-on; some are preview) and several are **portal-driven** with limited PowerShell — availability and
paths are cited or flagged **"verify your licensing/tenant"** and **"portal-only — review manually,"**
never invented. **Whether a policy is correct — retention durations, a rule's regulatory sufficiency,
whether a capability is required, any records or legal-hold obligation — is deferred to your compliance,
records, privacy, and legal functions.** The assessment provides the technical findings and evidence,
not the determination; Insider Risk and Communication Compliance are reviewed for configuration hygiene
and role separation only.

## The bottom line
The whole Purview estate baselined in one pass — every enabled capability inventoried, the gaps found
and prioritized, the quick wins safely fixed — so you finally have **one picture, a ranked plan, and a
defensible baseline** instead of a blind spot.
