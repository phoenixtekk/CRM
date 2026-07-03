# Deliverables Summary — Universal Print Deployment & Print-Server Retirement (GCC High)

This solution is a complete, self-guided package for deploying Universal Print on a **GCC High**
tenant and retiring legacy print servers. Everything below is included.

## Documents

| Deliverable | What it gives you |
| --- | --- |
| **01 — Solution Overview** | What the solution does, the Assess→Configure→Pilot→Validate→Expand model, and the full **Commercial vs GCC High — what's different** table (portals, endpoints, licensing, client support) with the availability caveat up front. |
| **02 — Requirements Guide** | Ten GCC-High-specific prerequisites (R1–R10), each with **verify** and **implement** steps against `.us` portals, plus a pass/fail checklist. |
| **03 — Implementation Guide** | Ordered, click-by-click steps across all five phases using the GCC High portals, with **[GCC High]** caveats inline (registry keys, connector, parity gaps) and a reusable naming convention. |
| **05 — Testing & Validation** | Pass/fail test sets A–E, one per phase gate, tied to the bundled scripts. |
| **06 — Troubleshooting** | GCC-High-specific symptoms and fixes (wrong-cloud errors, `-Environment USGov`, registry keys, connector, endpoints, licensing propagation). |
| **07 — Best Practices** | Ten practice areas: sovereign-cloud discipline, licensing, pilot gating, safe server retirement, parity-gap design, connector hygiene, client strategy, naming, change safety, monitoring. |
| **gcc-high-parity-notes.md** | Cited Commercial-vs-GCC-High reference: availability, portals, endpoints, client support, licensing, and confirmed parity gaps — with sources and "verify for GCC High/DoD" flags. |
| **Executive Summary** | One-page business-level summary for approvers. |
| **global-requirements-infrastructure.md** | Category-level prerequisites shared across all Infrastructure solutions. |

## PowerShell scripts (all connect to US Gov Graph, `-Environment USGov`)

| Script | Type | What it does |
| --- | --- | --- |
| **UPRTG-Discovery.ps1** | Read-only | Confirms UP reachability on GCC High, lists printers/shares/connectors, checks the `*.print.azure.us` endpoints. Run at the Assess gate. |
| **UPRTG-Validation.ps1** | Read-only | Validates the pilot/wave scope against pass/fail criteria (printer shared, targeting granted, connector healthy). Run at Pilot/Expand gates. |
| **UPRTG-Report.ps1** | Read-only | Generates a dated HTML/CSV evidence report of printers, shares, connector state, and targeting. Run at the Validate gate and monthly. |
| **UPRTG-Remediation.ps1** | Change (default `-WhatIf`) | Safely fixes common configuration drift (e.g., re-grant targeting, re-share). Shows a `-WhatIf` plan first; apply only after review. |
| **UPRTG-Set-ScopeTargeting.ps1** | Change (default `-WhatIf`) | Builds/populates pilot and wave targeting groups and grants them on shares, repeatably. Shows a `-WhatIf` plan first. |

## How the pieces fit the phases

- **Assess:** Requirements Guide + `UPRTG-Discovery.ps1` → Assess gate (Test set A).
- **Configure:** Implementation Steps 3–7 + `UPRTG-Set-ScopeTargeting.ps1` → Configure gate (Test set B).
- **Pilot:** Implementation Steps 8–10 + `UPRTG-Validation.ps1` → Pilot gate (Test set C).
- **Validate:** Implementation Step 11 + `UPRTG-Report.ps1` + `UPRTG-Remediation.ps1` → Validate gate (Test set D).
- **Expand & Retire:** Implementation Steps 12–13 + all scripts per wave → Expand gate (Test set E).

## Outcome

Universal Print published on GCC High with the correct sovereign-cloud portals and endpoints,
parity gaps handled, pilot-proven, and legacy print servers retired only after their printers are
validated in the cloud.
