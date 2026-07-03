# 8. Deliverables Summary — M365 & Azure Incident Response & Escalation Runbook (Government / GCC High edition)

This package is a complete, enterprise-grade incident & problem management kit for leading high-priority and escalated incidents across **Microsoft 365 GCC High and Azure Government**. It contains the documentation runbook (with an explicit, cited Commercial-vs-GCC-High parity map), five PowerShell tools that connect to US Gov endpoints, and a hero image.

## Documentation

| File | What it covers |
|---|---|
| `01-solution-overview.md` | What the runbook is, the **Detect → Triage → Communicate → Diagnose → Resolve → RCA → Permanent Fix** phase model, the named artifacts, the per-workload diagnostic playbooks, benefits, and honest limitations — plus a **"Commercial vs GCC High — what's different"** section (portals, endpoints, feature parity). |
| `02-requirements.md` | R1–R12 prerequisites (Description / Why / Verify / Implement-if-missing) with every *Verify* step in the **`*.us`** consoles / US Gov PowerShell: responder roles + reader access, Service Health access, Entra/Exchange/Azure log access, a **GCC High** support plan, a PSA, comms channels, SLAs, and change control. |
| `global-requirements-managed.md` | Baseline requirements common to every Managed-category engagement (tenant/subscriptions, roles, licensing, monitoring + system of record, change control, backup/rollback). |
| `03-implementation.md` | Part A stands up the matrix, templates, playbooks, escalation sheet, RCA, and responder access; Part B is the per-incident runbook with full **GCC High (`*.us`)** console navigation paths and inline sovereign-cloud caveats. |
| `gcc-high-parity-notes.md` | The cited **Commercial-vs-GCC-High reference**: admin portal URLs, PowerShell/API endpoints, feature parity gaps (Threat Experts, AIR, Defender for IoT, Secure Score / MDVM items, advanced hunting, Sentinel, Identity Protection), and compliance framing — each with a Microsoft source. |
| `05-testing.md` | Numbered tests (T1–T9) with PASS/FAIL gates, validated through a tabletop/simulated incident on the GCC High tenant: readiness in `*.us` consoles, triage correct, comms on cadence, diagnosis reaching root cause manually, RCA produced, permanent fix logged. |
| `06-troubleshooting.md` | Common failure modes across sovereign-cloud connectivity, access/visibility, Service Health discrimination, per-workload diagnosis, escalation, remediation, comms, and the RCA loop — with fixes. |
| `07-best-practices.md` | The operating disciplines: sovereign-cloud discipline (`*.us` + `-Environment USGov` + parity awareness), Service-Health-first triage, role coordination, client comms, evidence-led diagnosis and escalation, remediation safety, and the RCA→permanent-fix loop. |
| `executive-summary.md` | One-page business case and outcomes for sponsors/leadership. |

## PowerShell scripts

All scripts carry a `.SYNOPSIS` header with PURPOSE / HOW TO RUN / EXPECTED RESULTS and a NEUTRAL white-label `.NOTES`, and connect to **Microsoft Graph US Gov** (`-Environment USGov`) / **Azure Government** (`-Environment AzureUSGovernment`) endpoints. Read-only and discovery scripts make no changes; the remediation and scope-targeting scripts default to `-WhatIf` and require `-Apply` to act, on **named objects only**.

| Script | What it does |
|---|---|
| `scripts\INCIDENTG-Discovery.ps1` | **Live incident snapshot (read-only, US Gov).** Pulls current Microsoft 365 + Azure **Service Health**, recent **high-severity sign-ins / risk detections** from Entra, and an **Azure Government Resource Health** snapshot into one CSV to seed diagnosis — via `graph.microsoft.us` and Azure Government. |
| `scripts\INCIDENTG-Validation.ps1` | **Responder readiness (PASS/FAIL, US Gov).** Verifies responders hold the required roles, can read the key logs (Service Health, sign-in, message trace, Azure Monitor), and that a **GCC High** Microsoft support plan is in place; emits PASS/FAIL per check for the §05 readiness gates. |
| `scripts\INCIDENTG-Report.ps1` | **Incident metrics report.** Reads incident timeline data and computes **MTTA/MTTR** and per-severity counts/trends to CSV — the program dashboard that proves the runbook is working. (Offline; no tenant access required.) |
| `scripts\INCIDENTG-Remediation.ps1` | **Safe common fixes (US Gov).** Performs scoped, well-understood remediations for a **named object** (e.g. revoke a user's sessions, re-enable a disabled mail-flow connector) against the US Gov endpoints. Runs read-only / `-WhatIf` by default; requires `-Apply` to change anything. |
| `scripts\INCIDENTG-Set-ScopeTargeting.ps1` | **Responder access + scope setup (US Gov).** Creates the `Responder Access Group – Identity – Response` Entra group and assigns the reader/scoped-admin roles responders need; supports `-WhatIf` preview before `-Apply`. Connects with `-Environment USGov`. |

## Hero image

| File | Purpose |
|---|---|
| `INCIDENTG-hero.png` | Listing/marketing hero image for the solution. |

> **Naming convention reminder:** the scripts and runbook share the object-naming standard `<Purpose> – <Scope> – <Stage>` (e.g. `Responder Access Group – Identity – Response`, `Microsoft Escalation Sheet – Incident – Escalate`, `GCC High Parity Notes – Incident – Sovereign`) so outputs cross-reference cleanly across discovery, validation, remediation, and reporting.

> **Sovereign-cloud reminder:** every console path in the documentation uses the **`*.us`** URL and every script connects with a **US Gov** environment flag. The `gcc-high-parity-notes.md` file is the single cited source of truth for those URLs, endpoints, and feature gaps — re-verify it against Microsoft's current docs each quarter, as parity gaps close over time.
