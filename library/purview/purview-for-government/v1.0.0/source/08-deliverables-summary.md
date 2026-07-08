# 8. Deliverables Summary — Microsoft Purview for Government

What you receive, what to run, and what "done" looks like. This is a **Government industry bundle** — it
curates and sequences Purview capabilities (sensitivity labels, DLP/endpoint DLP, retention, audit,
Compliance Manager) for a CJIS/CMMC/ITAR tenant, referencing the granular products for deep how-to rather
than re-teaching them.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the bundle is, the curated Purview control stack (labels, DLP/endpoint DLP, retention, audit, Compliance Manager), the sovereign-cloud caveat, what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | Government-program prerequisites (tenant/cloud/licensing, least-privilege roles, S&C PowerShell + Graph with the correct cloud endpoints, in-scope controlled data/devices, the obligation-to-control map, ITAR/encryption/access preconditions, audit, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, design the control map, configure labels (pilot access first), DLP/endpoint DLP **in simulation**, retention + audit, track in Compliance Manager, validate & evidence, expand to enforcement — with pass/fail gates and rollback. |
| **5. Testing & Validation** | Nine gates from "licensing present in your cloud" to "validation scorecard green," each with method / pass / fail action — read-only or benign pilot content, no enforcement during test. |
| **6. Troubleshooting** | The failure modes — cloud-endpoint/connection, label encryption/access, DLP not matching or blocking, endpoint-DLP onboarding, retention scope, audit off, licensing, evidence gaps — and their fixes. |
| **7. Best Practices** | Defensible-program principles: defer determinations, verify against your cloud, simulate DLP before enforce, pilot label access, make evidence first-class, operate it as a program. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Sensitivity labels, DLP/endpoint DLP, retention, and audit cmdlets use **Security & Compliance
PowerShell** (`Connect-IPPSSession` — pass your cloud's `-ConnectionUri` in GCC High/DoD); licensing and DLP
alert reads use **Microsoft Graph** (`Connect-MgGraph -Environment …`).

| Script | Role | Default |
|---|---|---|
| `INDGOV-Discovery.ps1` | Assess: licensing, sensitivity labels/policies (flag encrypting), DLP policies (flag mode + endpoint), retention, unified-audit state + audit retention. | Read-only |
| `INDGOV-Scope.ps1` | Scope/health helper: in-scope population/mailboxes/sites, visible role groups, endpoint-onboarding readiness, cloud-endpoint reachability, connection identity. | Read-only |
| `INDGOV-Configure.ps1` | Configure/Remediate: create the CJI/CUI/ITAR labels, DLP + endpoint DLP **in simulation**, records retention, and audit-evidence retention — `-Control Labels\|DLP\|EndpointDLP\|Retention\|Audit`. | `-WhatIf` (writes on `-Commit`) |
| `INDGOV-Validate.ps1` | Validate: program scorecard across labels (encrypt+publish), DLP + endpoint DLP (in simulation), retention, audit, pilot coverage. | Read-only |
| `INDGOV-Report.ps1` | Report: control → object → configuration → proof export (`Evidence – Gov Controls – Binder`) plus the **DLP simulation-match** summary, cross-referenced to the control map. | Read-only |

## Named artifacts created
- Labels: `Protect – Gov CJI – Restricted`, `Protect – Gov CUI – Controlled`, `Protect – Gov ITAR – Controlled`
  (encrypting; published pilot-first).
- DLP: `DLP – Gov Controlled Data – Simulate` (services) and `DLP – Gov Endpoint Egress – Simulate` (devices)
  — built and validated **in simulation**, enforced only after sign-off.
- Records/audit: `Retention – Gov Records – Publish`, `Audit Retention – Gov Evidence – LongTerm`.
- Program tracking: `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` (Compliance Manager,
  in-portal).
- Governance/evidence: `Control Map – Gov – Purview`, `Evidence – Gov Controls – Binder`, pilot
  `Gov Pilot – Controlled Data – Stage1`.

## Definition of done
- Cloud confirmed (GCC/GCC High/DoD) and compliance **licensing confirmed** for labels, DLP/endpoint DLP, and
  audit evidence on the in-scope population.
- The three government **labels** created (encrypting), **piloted for access outcomes**, and published — pilot
  first, then the approved scope under sign-off.
- **DLP + endpoint DLP** present **in simulation**, matching the right controlled content without blocking;
  moved to **enforce** only after validation and compliance/security sign-off.
- Records retention scoped, **unified audit on** with `Audit Retention – Gov Evidence – LongTerm` retaining
  evidence.
- The `Control Map – Gov – Purview` register complete, the `Evidence – Gov Controls – Binder` and DLP
  simulation-match summary generated, and the **validation scorecard green** for the pilot — then expanded to
  enforcement with a monitoring cadence.

> **Boundary:** this solution delivers the technical control configuration and the evidence. **Data
> classification (CJI/CUI/ITAR), CMMC-level applicability, retention adequacy, ITAR access sufficiency, and
> any regulatory determination are deferred to your compliance, security, records, and legal functions**, and
> it makes **no certification or authorization-to-operate claim.** Feature availability is **licensing-/
> tenant-/cloud-dependent and evolving — verify against your entitlements, your cloud (GCC/GCC High/DoD), and
> current Microsoft documentation.**
