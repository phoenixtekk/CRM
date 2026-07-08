# Deliverables Summary — Adaptive Protection in Microsoft Purview

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Solution Overview** (`01-solution-overview.md`) | What Adaptive Protection delivers, the IRM-driven model (risk levels → DLP/CA controls), the privacy sensitivity, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **Requirements** (`02-requirements.md`) | Adaptive-Protection-specific prerequisites — licensing across IRM/DLP/Entra ID P2, roles on all three surfaces, the IRM source signal, Quick vs Custom setup, sensitivity labels, DLP/endpoint coverage, Conditional Access readiness, HR/legal engagement + lawful basis, pilot/change control. |
| **Implementation** (`03-implementation.md`) | Ordered steps: confirm the IRM signal + privacy first, enable Adaptive Protection, build the DLP policy in **simulation** and the CA policy in **report-only**, validate, then enforce and expand — with pass/fail gates and rollback. |
| **Testing & Validation** (`05-testing.md`) | Ten pass/fail gates from licensing/roles and the IRM signal through DLP-simulation and CA-report-only proof of per-level behavior to the HR/legal confirmation before enforcement. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common Adaptive Protection failure modes (no risk levels assigned, DLP condition not visible, wrong per-level action, CA not evaluating, propagation delays, role/permission issues) and how to resolve them. |
| **Best Practices** (`07-best-practices.md`) | Risk-level-as-automation-not-verdict, protect the source signal's privacy, pilot-first, proportionate per-level actions, classification-keyed enforcement, deliberate tuning, access continuity, and evidence integrity. |
| **Executive Summary** (`executive-summary.md`) | One-page business framing for decision-makers. |

## PowerShell tools (5)

All tools are **read-only or `-WhatIf`/simulation by default**, authenticate **interactively** (no
credentials in code), and use **Security & Compliance PowerShell** (`Connect-IPPSSession`), **Exchange
Online** (`Connect-ExchangeOnline`), and/or **Microsoft Graph** (`Connect-MgGraph`). Adaptive
Protection **setup** and the DLP **risk-level condition** are portal actions; these tools handle
readiness, DLP scaffolding, validation, reporting, and scoping.

| Script | Type | What it does |
| --- | --- | --- |
| **`PURVAP-Discovery.ps1`** | Read-only | Adaptive Protection **readiness/discovery**: reports the IRM source-policy signal (present/scoring where readable), prompts to confirm the IRM privacy posture in-portal, inventories existing DLP policies and whether any rule already references the adaptive-protection risk-level condition, and (via Graph) reports Conditional Access policy presence. Changes nothing. |
| **`PURVAP-Set-DlpPolicy.ps1`** | `-WhatIf` default | **DLP-policy configuration helper**: validates prerequisites and prints the exact intended `DLP-Adaptive-Protection` policy/rule plan (three per-level rules, simulation-first, label-keyed); its `-Commit` path can scaffold the policy shell **in simulation mode** with documented conditions, and flags that the **risk-level condition is added in the portal** where PowerShell does not expose it — "verify availability in your tenant". |
| **`PURVAP-Test-Readiness.ps1`** | Read-only | **Validation checker**: reports whether Adaptive Protection prerequisites are met — DLP policy present and in **simulation/enforce**, its scope, workload/device signals, and licensing/integration hints — as pass/fail lines aligned to `05-testing.md`. |
| **`PURVAP-Report.ps1`** | Read-only | **Enforcement reporting rollup**: summarizes adaptive DLP activity readable from the unified audit log (by action/workload/time) to CSV for a leadership rollup; notes Activity explorer / DLP alerts and CA report-only insights as authoritative. |
| **`PURVAP-Set-Scope.ps1`** | `-WhatIf` default | **Scope helper**: previews and (with `-WhatIf:$false`) applies membership changes to the pilot/scope group (`SG-AP-Pilot`) so expansion stays deliberate and reversible; the DLP/CA policies follow the group. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Pilot scope group:** `SG-AP-Pilot`
- **Risk levels:** **Elevated**, **Moderate**, **Minor**
- **DLP policy:** `DLP-Adaptive-Protection` (simulation/test first), with rules:
  - `AP-Elevated-Block` — risk level **Elevated** → block (policy tip)
  - `AP-Moderate-WarnOverride` — risk level **Moderate** → block with override / warn
  - `AP-Minor-Audit` — risk level **Minor** → audit only
- **Conditional Access policy:** `CA-InsiderRisk-Elevated` — Insider risk = **Elevated** → agreed
  control (block / step-up / limited session), report-only first, break-glass excluded

## What this solution deliberately does NOT do

- It does **not** treat a risk level as a **finding of misconduct** or a disciplinary trigger — those
  determinations are HR/legal's.
- It does **not** enforce DLP/CA before piloting in **simulation/report-only** and passing the gates.
- It does **not** weaken the IRM privacy guardrails (anonymization, role separation) that produce the
  source signal.
- It does **not** invent portal paths or cmdlets — where Adaptive Protection setup or the risk-level
  condition is portal-only, the tools stop at readiness/validation/scaffolding and say so.
- It does **not** decide your **lawful basis** for the underlying monitoring — that is a legal
  determination for your jurisdiction(s).
