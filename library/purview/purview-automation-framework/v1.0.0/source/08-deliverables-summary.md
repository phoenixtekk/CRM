# 8. Deliverables Summary — Microsoft Purview Automation Framework

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the automation framework is, the config-as-code model, the Purview objects it manages (DLP, labels, retention), what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | Automation-specific prerequisites (licensing per policy type, least-privilege roles per type, S&C PowerShell + Graph toolchain, a reviewed desired-state config, scope/classification, content ownership, pilot & safe-first modes) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: health-check, discover current state, author + validate config, deploy safe-first, validate drift, report, enforce deliberately, expand, operationalize the cadence — pilot-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Ten gates from "toolchain ready" to "cadence catches injected drift," each with method / pass / fail action. |
| **6. Troubleshooting** | The failure modes of config-driven Purview automation — connect/role/licensing errors, mode/parameter drift, unexpected extra objects, enforce mistakes, throttling — and their fixes. |
| **7. Best Practices** | Operating principles: policy as code, deploy safe-first + enforce deliberately, pilot small, make drift visible, manage only what you own, least-privilege, keep decisions where they belong, no secrets. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`, and **enforcement/publishing
requires a separate explicit `-Enforce -Commit`**. No credentials or secrets are embedded — interactive
modern-auth / MFA sign-in. All policy objects are **Security & Compliance PowerShell** (`Connect-IPPSSession`);
licensing/reporting reads use **Microsoft Graph**.

| Script | Role | Default |
|---|---|---|
| `OPSAUTO-Health.ps1` | Assess/scope helper: module versions, connectivity, per-policy-type read permission probe, licensing (E5/E5-Compliance) check. | Read-only |
| `OPSAUTO-Discovery.ps1` | Assess: inventory existing DLP policies (+ mode), sensitivity labels + label policies, retention policies + rules → state snapshot. | Read-only |
| `OPSAUTO-Deploy.ps1` | Configure/Remediate: reconcile config → tenant. Validate-only, then `-WhatIf`; deploys **safe-first** (DLP test/simulation, labels/retention unpublished) on `-Commit`; enforces only on `-Enforce -Commit`; `-Remove` cleans up managed objects. | `-WhatIf` (writes on `-Commit`; enforce on `-Enforce -Commit`) |
| `OPSAUTO-Validate.ps1` | Validate: compare deployed objects to the desired-state config → drift report (missing/extra/altered/mode-mismatched), pass/fail. | Read-only |
| `OPSAUTO-Report.ps1` | Validate: policy inventory + coverage scorecard (present, correct mode, in scope, versus config). | Read-only |

## Named artifacts created / produced
- Desired-state config: `Automation Config – Purview Ops – Baseline` (JSON, customer-owned).
- Current-state snapshot: `Automation Snapshot – Tenant State – Current`.
- Safe-first deploy effort: `Automation Deploy – Purview Policies – Simulation`.
- Drift validation: `Automation Validate – Desired State – Drift`.
- Reports: `Automation Report – Policy Inventory – Tenant`, `Automation Report – Coverage Scorecard – Tenant`.
- Pilot scope: `Automation Pilot – Ops Scope – Stage1`.

## Definition of done
- Health check **green** for the policy types the config targets (modules, connectivity, roles, licensing).
- A reviewed **desired-state config** that validates structurally, with a named content-owner per policy.
- The config **deployed safe-first** to the pilot — DLP in **test/simulation mode**, labels **unpublished**, retention **pilot-scoped** — and confirmed by discovery.
- **Validation drift-free** and the **coverage scorecard green** for the pilot; DLP test/simulation results reviewed and accepted.
- Enforcement performed **deliberately** (`-Enforce -Commit`) only after the pilot passed, then **expanded** to full scope through the same safe-first → validate → enforce cycle.
- The **read-only cadence** (Discovery → Validate → Report) scheduled so drift is caught, and config changes flowing only through the gated deploy path.

> **Boundary:** this framework delivers repeatable deployment, validation, and evidence for Purview policy
> objects. **The policy *content* — which sensitive info types, which retention durations, which labels, and
> whether a policy is legally adequate — is deferred to your compliance, records, privacy, and legal
> functions.** Records-management, insider-risk, and communication-compliance objects are **out of automated
> scope.** Feature availability and cmdlet parameters (notably DLP simulation/mode values) are **licensing-/
> tenant-dependent and evolving — verify against your entitlements and current Microsoft documentation.**
