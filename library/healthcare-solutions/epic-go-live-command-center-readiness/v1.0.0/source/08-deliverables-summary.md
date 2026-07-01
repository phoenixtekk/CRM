# 8. Deliverables Summary — Epic Go-Live & Command Center Endpoint Readiness Playbook

This solution ships a complete, ready-to-run package: the documentation set, five PowerShell automation scripts, and a hero image. Everything is white-label and reusable across waves, sites, and upgrades.

---

## Documentation

| # | Document | Purpose |
|---|----------|---------|
| 1 | `01-solution-overview.md` | What the playbook is, the problem it solves, scope, phase model, and the named artifacts it produces. |
| 2 | `02-requirements.md` | Solution-specific requirements R1–R12, each with Description / Why / Verify / Implement-if-missing. |
| 3 | `global-requirements-healthcare-solutions.md` | Category-wide prerequisites (tenant/roles, licensing, HIPAA/HITRUST + change control, maintenance windows, network, test device, rollback). |
| 4 | `03-implementation.md` | The five-phase operational walkthrough (Assess → Prepare/Remediate → Validate → Command Center → Stabilize) with full console paths and the triage runbook. |
| 5 | `05-testing.md` | Validation sweep, readiness scorecard, functional spot-tests, remediation rehearsal, command-center dry run, and gate/exit-criteria validation. |
| 6 | `06-troubleshooting.md` | Deep diagnostics for the common day-1 endpoint problems and tooling issues. |
| 7 | `07-best-practices.md` | Accumulated discipline across readiness, change safety, command center, comms, compliance, and handover. |
| 8 | `08-deliverables-summary.md` | This document. |
| — | `executive-summary.md` | One-page executive framing for program and clinical leadership. |

---

## PowerShell scripts

All scripts use Microsoft Graph where appropriate, carry a standard header block, and are **read-only by default**. The `.NOTES` block on each is neutral: *"Healthcare Solutions — read-only."* State-changing actions require an explicit switch and run only inside an approved maintenance window against the readiness device group.

| # | Script | What it does | Default mode |
|---|--------|--------------|--------------|
| 1 | `EPICGOLIVE-Discovery.ps1` | Fleet readiness snapshot — per device: enrollment, compliance, OS build, detected Epic client version, Imprivata agent presence, last check-in. Serves as the Assess baseline and the rollback before-state. | Read-only |
| 2 | `EPICGOLIVE-Validation.ps1` | Per-device go/no-go validation against the readiness checklist; returns **PASS/FAIL** with reasons per check. | Read-only |
| 3 | `EPICGOLIVE-Report.ps1` | Rolls validation results into the **Readiness Scorecard – Clinical Fleet – Validation** and exports to CSV (per-device + roll-ups; no ePHI). | Read-only |
| 4 | `EPICGOLIVE-Remediation.ps1` | Safe, supported remediation of enrollment/compliance gaps. Previews actions by default; changes state only with `-Apply`. | `-WhatIf` (read-only) |
| 5 | `EPICGOLIVE-Set-ReadinessGroup.ps1` | Manages membership of the **Readiness Device Group – Clinical Fleet – Validation** from the in-scope inventory. Previews intended membership by default. | `-WhatIf` |

---

## Visual asset

| File | Purpose |
|------|---------|
| `EPICGOLIVE-hero.png` | Hero image for the solution listing. |

---

## Named artifacts the playbook produces (operating outputs)

These are produced *by running the playbook* in a customer environment (not shipped pre-filled), each named `<Purpose> – <Scope> – <Stage>`:

- **Endpoint Readiness Checklist – Clinical Fleet – Pre-Go-Live**
- **Go/No-Go Gate – Endpoint Domain – Activation**
- **Readiness Scorecard – Clinical Fleet – Validation** (output of `EPICGOLIVE-Report.ps1`)
- **Command Center Roster – Endpoint Support – Hypercare**
- **Rapid-Fix Triage Runbook – Day-1 Endpoint – Hypercare**
- **Comms & Escalation Plan – Endpoint Domain – Activation**
- **Hypercare Exit Criteria – Endpoint Domain – Handover**
- **Readiness Device Group – Clinical Fleet – Validation** (managed by `EPICGOLIVE-Set-ReadinessGroup.ps1`)

---

## How the pieces fit

1. **Assess** with `EPICGOLIVE-Discovery.ps1` and create the **Readiness Device Group** via `EPICGOLIVE-Set-ReadinessGroup.ps1 -WhatIf`.
2. **Remediate** gaps with `EPICGOLIVE-Remediation.ps1 -Apply` (tested first, in a window).
3. **Validate** with `EPICGOLIVE-Validation.ps1` and produce the **Readiness Scorecard** with `EPICGOLIVE-Report.ps1`.
4. **Decide** at the **Go/No-Go Gate**.
5. **Run hypercare** with the **Roster**, **Triage Runbook**, and **Comms & Escalation Plan**.
6. **Hand over** on the **Hypercare Exit Criteria**.

---

## Related solutions (deep configuration)

- **Epic client deployment & standardization solution** — Hyperdrive/Hyperspace packaging, versioning, deployment rings.
- **Imprivata tap-and-go / SSO solution** — OneSign agent, enrollment, policy.
- **Clinical workstation standardization solution** — master image, baseline, hardware standards.
