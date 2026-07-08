# 8. Deliverables Summary — Microsoft Purview FERPA Compliance Program

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the program is, the three Purview control domains (classify & label education records, DLP against unauthorized disclosure, retention & audit evidence), what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | FERPA-program prerequisites (licensing per control, least-privilege roles, S&C PowerShell + Graph toolchain, in-scope education-record data/workloads/endpoints, the obligation-to-control map, DLP simulation/disclosure-exception preconditions, audit, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, design the control map, configure classification & labels, DLP (in simulation), retention & audit, track in Compliance Manager, validate & evidence, expand to enforcement — pilot-in-simulation/test-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Nine gates from "licensing present" to "validation scorecard green," each with method / pass / fail action — read-only or benign pilot content, DLP kept in simulation. |
| **6. Troubleshooting** | The failure modes — label/classification behavior, DLP false positives/enforcement, retention scope, audit off, licensing, endpoint/onboarding, evidence gaps — and their fixes. |
| **7. Best Practices** | Defensible-program principles: defer determinations, classify first, treat DLP as a one-way lever, make evidence first-class, operate it as a program. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Sensitivity labels, DLP, retention, and audit retention cmdlets use **Security & Compliance
PowerShell** (`Connect-IPPSSession`); licensing reads use **Microsoft Graph**.

| Script | Role | Default |
|---|---|---|
| `CMPFERPA-Discovery.ps1` | Assess: licensing, sensitivity labels/policies, DLP policies (enforce vs simulation), retention labels/policies, sensitive info types, unified-audit state + audit retention. | Read-only |
| `CMPFERPA-Scope.ps1` | Scope/health helper: in-scope education-record locations/mailboxes/sites, device-onboarding state, visible role groups, connection identity/health. | Read-only |
| `CMPFERPA-Configure.ps1` | Configure/Remediate: create the education-record label + publish policy, the DLP policy **in simulation**, retention, and audit-evidence retention — `-Control Label\|DLP\|Retention\|Audit`. | `-WhatIf` (writes on `-Commit`) |
| `CMPFERPA-Validate.ps1` | Validate: program scorecard across label/classification, DLP (simulation + exceptions), retention, audit, pilot coverage. | Read-only |
| `CMPFERPA-Report.ps1` | Report: control → object → configuration → proof export (`Evidence – FERPA Controls – Binder`), cross-referenced to the control map. | Read-only |

## Named artifacts created
- Classification/protection: `Protect – FERPA Education Records – Confidential` (sensitivity label), `Protect – FERPA Education Records – Publish` (publish policy).
- Disclosure prevention: `DLP – FERPA Education Records – Simulate` (built and validated in simulation mode).
- Records lifecycle: `Retention – FERPA Records – Publish`, `Disposition – FERPA Records – Review`.
- Access evidence: `Audit Retention – FERPA Evidence – LongTerm`.
- Program tracking: `Assessment – FERPA Controls – Program` (Compliance Manager, in-portal).
- Governance/evidence: `Control Map – FERPA – Purview`, `Evidence – FERPA Controls – Binder`, pilot `FERPA Pilot – Education Records – Stage1`.

## Definition of done
- Compliance **licensing confirmed** for classification, DLP, retention, and audit evidence on the in-scope population.
- Classification & labeling control in place — `Protect – FERPA Education Records – Confidential` published to the approved scope and applying to education records.
- Disclosure-prevention control in place — `DLP – FERPA Education Records – Simulate` validated **in simulation** with permitted-disclosure exceptions, then moved to enforcement on the approved scope **under compliance/registrar sign-off**.
- Retention scoped and **unified audit on** with `Audit Retention – FERPA Evidence – LongTerm` retaining access evidence.
- The `Control Map – FERPA – Purview` register complete and the `Evidence – FERPA Controls – Binder` generated; the **validation scorecard green** for the pilot — then expanded to enforcement with a monitoring cadence and disposition review scheduled.

> **Boundary:** this solution delivers the technical control configuration and the evidence.
> **Education-record scope, permitted-disclosure/DLP-exception adequacy, retention adequacy, and any FERPA
> determination are deferred to your compliance, registrar, records, privacy, and legal functions.**
> Feature availability is **licensing-/tenant-dependent and evolving — verify against your entitlements
> and current Microsoft documentation.**
