# 8. Deliverables Summary — Microsoft Purview for Legal

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the Legal-tailored program is, the four Purview control domains (sensitivity labels, DLP, matter retention, audit evidence), what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | Legal-program prerequisites (licensing per control, least-privilege roles, S&C PowerShell + Graph toolchain, in-scope legal population/matters/channels, the obligation-to-control map, DLP-simulation/encryption preconditions, audit, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, design the control map, configure labels, DLP (in simulation), matter retention & disposition, audit evidence, track in Compliance Manager, validate & evidence, expand to enforcement — pilot-in-simulation/test-first with pass/fail gates and rollback (and the regulatory-records irreversibility gate; legal holds referenced, never performed). |
| **5. Testing & Validation** | Eleven gates from "licensing present" to "validation scorecard green," each with method / pass / fail action — read-only or benign pilot content; DLP validated in simulation; legal-hold coverage read-only. |
| **6. Troubleshooting** | The failure modes — label/encryption behavior, DLP over-matching, retention scope, disposition, audit off, licensing, endpoint confusion, evidence gaps, hold/retention interaction — and their fixes. |
| **7. Best Practices** | Defensible-program principles: defer determinations, keep legal holds with legal, always pilot DLP in simulation, treat encryption/regulatory records as one-way, make evidence first-class, operate it as a program. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Sensitivity labels, DLP, retention labels/policies, and audit retention cmdlets use **Security &
Compliance PowerShell** (`Connect-IPPSSession`); licensing reads use **Microsoft Graph**. `Get-CaseHoldPolicy`
is used **read-only reference only** — the tools never create, change, or release a legal hold.

| Script | Role | Default |
|---|---|---|
| `INDLEGAL-Discovery.ps1` | Assess: licensing, sensitivity labels/policies (encryption), DLP policies (mode), retention labels/policies (records/regulatory), unified-audit state + audit retention, and read-only reference to eDiscovery holds. | Read-only |
| `INDLEGAL-Scope.ps1` | Scope/health helper: legal-population group members, in-scope mailboxes/matter sites, visible role groups, connection identity/health. | Read-only |
| `INDLEGAL-Configure.ps1` | Configure/Remediate: create labels (+encryption), DLP **in simulation**, matter-records retention, and audit-evidence retention — `-Control Labels\|DLP\|Retention\|Audit`. | `-WhatIf` (writes on `-Commit`) |
| `INDLEGAL-Validate.ps1` | Validate: program scorecard across labels (encryption), DLP (in simulation/test), matter retention, audit, pilot coverage. | Read-only |
| `INDLEGAL-Report.ps1` | Report: control → object → configuration → proof export (`Evidence – Legal Controls – Binder`), cross-referenced to the control map. | Read-only |

## Named artifacts created
- Sensitivity labels: `Protect – Legal Privileged – Restricted` (encrypted), `Protect – Legal Matter Confidential – Confidential`.
- DLP: `DLP – Legal Privileged – Simulate` (built and validated in simulation/test mode).
- Matter records: `Retention – Legal Matter Records – Publish` (retention label + publish policy), `Disposition – Legal Records – Review` (disposition stage).
- Audit evidence: `Audit Retention – Legal Evidence – LongTerm`.
- Program tracking: `Assessment – Legal Controls – Program` (Compliance Manager, in-portal).
- Governance/evidence: `Control Map – Legal – Purview`, `Evidence – Legal Controls – Binder`, pilot `Legal Pilot – Privileged Data – Stage1`.

## Definition of done
- Compliance **licensing confirmed** for labels/encryption, DLP (incl. Teams/Endpoint), records retention, and audit evidence on the legal population.
- **Sensitivity labels** published — privileged label encrypting to legal's approved scope, matter-confidential label available.
- **DLP** present and validated **in simulation**, its match report reviewed and tuned — then moved to **Enable** on the approved scope under legal sign-off.
- **Matter-records retention** in place — pilot **non-regulatory** label validated, disposition review configured where the schedule requires, and any **regulatory-records** label applied only under sign-off.
- **Unified audit on** with `Audit Retention – Legal Evidence – LongTerm` retaining evidence; eDiscovery hold coverage **visible** (read-only) for legal.
- The `Control Map – Legal – Purview` register complete and the `Evidence – Legal Controls – Binder` generated; the **validation scorecard green** for the pilot — then expanded to enforcement with a monitoring cadence and disposition review scheduled.

> **Boundary:** this solution delivers the technical control configuration and the evidence. **Privilege
> determination, matter mapping, retention adequacy, disposition triggers, and legal-hold scope are
> deferred to your legal, records, and compliance functions; legal holds and eDiscovery actions remain
> legal's.** Feature availability is **licensing-/tenant-dependent and evolving — verify against your
> entitlements and current Microsoft documentation.**
