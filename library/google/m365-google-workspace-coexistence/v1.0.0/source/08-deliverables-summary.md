# 8. Deliverables Summary — Microsoft 365 ↔ Google Workspace Coexistence

Everything in this solution, and what to do with it.

## Documents (`source/`)

| Doc | Purpose |
|---|---|
| `01-solution-overview.md` | The coexistence model — the three pillars (mail routing/split delivery, free/busy interop, directory sync), scope, and lifecycle. |
| `02-requirements.md` | Prerequisites (R1–R9) as Description → Why → Verify → Implement — both platforms + admin, DNS/mail-flow, interop role accounts, directory-sync mechanism, pilot. |
| `03-implementation.md` | The ordered runbook: **Assess → Configure → Pilot → Validate → Expand**, with named objects and per-phase exit gates and rollback. |
| `05-testing.md` | Pass/fail gates T1–T5 and ongoing regression checks — mail routes, free/busy both ways, directory in sync. |
| `06-troubleshooting.md` | Symptom → cause → fix for the common coexistence failures (NDRs, relay loops, blank free/busy, missing GAL entries). |
| `07-best-practices.md` | Keeping the transition stable, and the controlled decommission at consolidation. |
| `08-deliverables-summary.md` | This file. |
| `executive-summary.md` | One-page summary for decision-makers. |

## Scripts (`scripts/`)

All Microsoft-side automation uses the **Microsoft Graph PowerShell SDK** (and the Exchange Online
module for mail-flow objects). Discovery, Validation, and Report are **read-only**; Remediation and
Set-ScopeTargeting default to **`-WhatIf`** and require `-Apply` to make changes.

| Script | Role | Read/Write |
|---|---|---|
| `GWCOEX-Discovery.ps1` | Coexistence-readiness discovery — accepted-domain types, connectors, MX/SPF/DKIM/DMARC, cross-platform contacts, Interop state. | Read-only |
| `GWCOEX-Validation.ps1` | Per-user interop validation — mail routing, free/busy both directions, directory presence. | Read-only |
| `GWCOEX-Report.ps1` | Coexistence coverage report — per-user pillar status + overall coverage %. | Read-only |
| `GWCOEX-Remediation.ps1` | Safe remediation of common gaps (relay type, connector, mail contacts). Default `-WhatIf`. | Write (gated) |
| `GWCOEX-Set-ScopeTargeting.ps1` | Point the coexistence scope at the pilot group or all users. Default `-WhatIf`. | Write (gated) |

## How to use it end to end

1. Verify **`02-requirements.md`** (R1–R9). Capture the DNS + Google + M365 baseline.
2. Run **`GWCOEX-Discovery.ps1`** for the M365-side baseline.
3. Follow **`03-implementation.md`** Phase by Phase, honoring each **`05-testing.md`** gate.
4. In Pilot/Validate, run **`GWCOEX-Set-ScopeTargeting.ps1`**, **`GWCOEX-Validation.ps1`**, and
   **`GWCOEX-Report.ps1`**; remediate with **`GWCOEX-Remediation.ps1`** as needed.
5. Expand to the fleet, prove coverage, tighten DMARC.
6. Operate per **`07-best-practices.md`**; at consolidation, run the **decommission** checklist.

## Outcome

Microsoft and Google working as one through the transition — **mail routes, calendars resolve, the
directory stays in sync** — piloted, validated, and rollback-ready, until consolidation retires the
legacy side cleanly.
