# 8. Deliverables Summary — Microsoft Purview FedRAMP Compliance Program

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the program is, the three Purview control domains (information protection, DLP, retention & audit evidence) mapped to NIST 800-53 families, what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | FedRAMP-program prerequisites (licensing per control, least-privilege roles, S&C PowerShell + Graph toolchain, in-scope controlled data/workloads, the NIST-800-53-to-control map, DLP simulation preconditions, audit, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, design the control map, configure information protection / DLP (in test/simulation) / audit & retention, track in Compliance Manager, validate & evidence, expand to enforcement — pilot-in-simulation/test-first with pass/fail gates and rollback (and the DLP-enforcement sign-off gate). |
| **5. Testing & Validation** | Nine gates from "licensing present" to "validation scorecard green," each with method / pass / fail action — read-only or benign pilot content, no DLP enforcement exercised. |
| **6. Troubleshooting** | The failure modes — label/encryption behavior, DLP mode/scope, audit off, retention scope, licensing, endpoint confusion, evidence gaps — and their fixes. |
| **7. Best Practices** | Defensible-program principles: defer determinations, simulate DLP first, pilot encryption deliberately, make evidence first-class, operate it as a program. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Sensitivity labels, DLP, retention, and audit retention cmdlets use **Security & Compliance
PowerShell** (`Connect-IPPSSession`); licensing reads use **Microsoft Graph**.

| Script | Role | Default |
|---|---|---|
| `CMPFEDRAMP-Discovery.ps1` | Assess: licensing, sensitivity labels/policies (flag encryption), DLP policies (flag Mode), retention labels/policies, unified-audit state + audit retention. | Read-only |
| `CMPFEDRAMP-Scope.ps1` | Scope/health helper: controlled-data-owners group members, in-scope mailboxes/sites, visible role groups, connection identity/health. | Read-only |
| `CMPFEDRAMP-Configure.ps1` | Configure/Remediate: create the sensitivity label + publish policy, the DLP policy **in test/simulation**, audit-evidence and controlled-records retention — `-Control Label\|DLP\|Audit\|Retention`; `-Enforce` switches DLP to Enable. | `-WhatIf` (writes on `-Commit`) |
| `CMPFEDRAMP-Validate.ps1` | Validate: program scorecard across label, DLP (present + in test/simulation), audit, retention, pilot coverage. | Read-only |
| `CMPFEDRAMP-Report.ps1` | Report: control → object → configuration → proof export (`Evidence – FedRAMP Controls – Binder`), cross-referenced to the control map. | Read-only |

## Named artifacts created
- Information protection: `Protect – FedRAMP Controlled – Confidential` (label), `Protect – FedRAMP Controlled – Publish` (label policy).
- DLP: `DLP – FedRAMP Controlled – Simulate` (built and validated in test/simulation mode; enforced only after sign-off).
- Audit evidence & retention: `Audit Retention – FedRAMP Evidence – LongTerm`, `Retention – FedRAMP Records – Publish`.
- Program tracking: `Assessment – FedRAMP Controls – Program` (Compliance Manager, in-portal).
- Governance/evidence: `Control Map – FedRAMP – Purview`, `Evidence – FedRAMP Controls – Binder`, pilot `FedRAMP Pilot – Controlled Data – Stage1`.

## Definition of done
- Compliance **licensing confirmed** for information protection, DLP, and audit evidence on the in-scope population.
- Information-protection control in place — `Protect – FedRAMP Controlled – Confidential` label piloted on benign content and published to the approved scope (encryption applied per design under sign-off).
- DLP policy `DLP – FedRAMP Controlled – Simulate` present **in test/simulation** mode, pilot-scoped, reporting matches with no blocking — then moved to **Enable (enforce)** on the approved scope **under sign-off**.
- **Unified audit on** with `Audit Retention – FedRAMP Evidence – LongTerm` retaining AU evidence, and `Retention – FedRAMP Records – Publish` scoped where required.
- The `Control Map – FedRAMP – Purview` register complete and the `Evidence – FedRAMP Controls – Binder` generated; the **validation scorecard green** for the pilot — then expanded with a monitoring cadence and the Compliance Manager assessment tracking the program.

> **Boundary:** this solution delivers the technical control configuration and the evidence. **The
> applicable baseline, NIST 800-53 control applicability, whether a Purview object satisfies a control,
> and any ATO/authorization decision are deferred to your security, compliance, and legal functions —
> this solution asserts no certification or ATO.** Feature availability is **licensing-/tenant-dependent
> and evolving — verify against your entitlements and current Microsoft documentation.**
