# 8. Deliverables Summary — Microsoft Purview FINRA/SEC Compliance Program

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the program is, the three Purview control domains (records retention, communication supervision, audit evidence), what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | FINRA/SEC-program prerequisites (licensing per control, least-privilege roles with reviewer separation, S&C PowerShell + Graph toolchain, in-scope population/channels, the rule-to-control map, comms-compliance privacy preconditions, audit, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, design the control map, configure records/audit/supervision, track in Compliance Manager, validate & evidence, expand to enforcement — pilot-in-simulation/test-first with pass/fail gates and rollback (and the regulatory-records irreversibility gate). |
| **5. Testing & Validation** | Nine gates from "licensing present" to "validation scorecard green," each with method / pass / fail action — read-only or benign pilot content. |
| **6. Troubleshooting** | The failure modes — label/record behavior, retention scope, supervision privacy/scope, audit off, licensing, endpoint confusion, evidence gaps — and their fixes. |
| **7. Best Practices** | Defensible-program principles: defer determinations, treat regulatory records as one-way, build supervision privacy-first, make evidence first-class, operate it as a program. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Retention labels/policies, Communication Compliance (supervisory-review), and audit retention
cmdlets use **Security & Compliance PowerShell** (`Connect-IPPSSession`); licensing reads use
**Microsoft Graph**.

| Script | Role | Default |
|---|---|---|
| `CMPFINRA-Discovery.ps1` | Assess: licensing, retention labels/policies (records/regulatory), Communication Compliance policies, unified-audit state + audit retention. | Read-only |
| `CMPFINRA-Scope.ps1` | Scope/health helper: covered-persons group members, in-scope mailboxes/sites, visible role groups, connection identity/health. | Read-only |
| `CMPFINRA-Configure.ps1` | Configure/Remediate: create records labels + publish/comms-store retention, audit-evidence retention, and the supervision policy **in test** — `-Control Records\|Audit\|Supervision`. | `-WhatIf` (writes on `-Commit`) |
| `CMPFINRA-Validate.ps1` | Validate: program scorecard across records, comms-store retention, audit, supervision (test + reviewer separation), pilot coverage. | Read-only |
| `CMPFINRA-Report.ps1` | Report: control → object → configuration → proof export (`Evidence – FINRA/SEC Controls – Binder`), cross-referenced to the control map. | Read-only |

## Named artifacts created
- Records: `Records – FINRA/SEC Regulated – Regulatory` (label), `Retention – FINRA/SEC Records – Publish` (publish policy), `Retention – FINRA/SEC Comms Store – Immutable` (comms-store retention).
- Supervision: `Supervision – Registered Persons Comms – Test` (built and validated in test mode).
- Audit evidence: `Audit Retention – FINRA/SEC Evidence – LongTerm`.
- Program tracking: `Assessment – FINRA/SEC Controls – Program` (Compliance Manager, in-portal).
- Governance/evidence: `Disposition – FINRA/SEC Records – Review`, `Control Map – FINRA/SEC – Purview`, `Evidence – FINRA/SEC Controls – Binder`, pilot `FINRA/SEC Pilot – Registered Persons – Stage1`.

## Definition of done
- Compliance **licensing confirmed** for records, supervision, and audit evidence on the in-scope population.
- Records-preservation control in place — pilot **non-regulatory** label validated, then the **regulatory-records** label applied on the approved scope **under compliance sign-off**, plus comms-store retention.
- **Unified audit on** with `Audit Retention – FINRA/SEC Evidence – LongTerm` retaining evidence.
- Communication supervision policy present **in test** with correct **reviewer separation**, surfacing benign test items.
- The `Control Map – FINRA/SEC – Purview` register complete and the `Evidence – FINRA/SEC Controls – Binder` generated; the **validation scorecard green** for the pilot — then expanded to enforcement with a monitoring cadence and disposition review scheduled.

> **Boundary:** this solution delivers the technical control configuration and the evidence. **Rule
> applicability, retention adequacy, supervisory scope/lexicon sufficiency, 17a-4 compliance, and any
> regulatory determination are deferred to your compliance, records, privacy, and legal functions.**
> Feature availability is **licensing-/tenant-dependent and evolving — verify against your entitlements
> and current Microsoft documentation.**
