# 8. Deliverables Summary — Microsoft Purview NIST 800-53 Compliance Program

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What a NIST 800-53 program in Purview is, the control-family-to-Purview map, what you control, honest coverage limits, the authorization boundary, and the naming convention. |
| **2. Requirements Guide** | NIST-specific prerequisites (premium-template licensing, Compliance Manager + capability roles, S&C/Exchange/Graph toolchain, system boundary, tailored baseline, audit/retention & evidence requirements, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess posture, create the assessment, build the control-to-Purview map, configure AU audit + retention, configure the SC/MP DLP control **in simulation**, confirm AC/SC label evidence, validate per family, produce the evidence report, expand to enforce — pilot-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Ten gates from "licensing/roles in place" to "enforcement live and drift-monitored," each with method / pass / fail action. |
| **6. Troubleshooting** | The failure modes — template not addable, roles, DLP mode confusion, audit not retroactive, evidence gaps, endpoint mix-ups — and their fixes. |
| **7. Best Practices** | Program-maintenance principles: keep the authorization boundary bright, evidence as artifact, audit before you need it, pilot in simulation, least-privilege/SoD, tailored baseline, evolving template. |

## PowerShell tools (5)
All run **read-only or `-WhatIf`/simulation by default**; writes require `-Commit`. No credentials or secrets
are embedded. DLP/label/retention cmdlets use **Security & Compliance PowerShell** (`Connect-IPPSSession`);
audit enablement uses **Exchange Online PowerShell** (`Connect-ExchangeOnline`); licensing/roles use
**Microsoft Graph**. The scripts inventory and validate the **underlying Purview controls** that evidence the
NIST families — they do not invent a Compliance Manager cmdlet (assessment creation and improvement-action
evidence are portal operations; verify current automation for your tenant).

| Script | Role | Default |
|---|---|---|
| `CMPNIST-Scope.ps1` | Assess/health: connectivity to S&C/Exchange/Graph, E5/E5-Compliance licensing check, role-gated read checks, in-scope family confirmation. | Read-only |
| `CMPNIST-Discovery.ps1` | Assess: inventory the Purview control posture per family — audit state + retention, DLP policies + mode, published labels, retention policies. | Read-only |
| `CMPNIST-Set-ControlPolicy.ps1` | Configure/Remediate: enable unified audit; create/remove the AU audit-retention policy; create the SC/MP DLP control **in simulation** and later switch to enforce. | `-WhatIf` (writes on `-Commit`) |
| `CMPNIST-Validate.ps1` | Validate: per-family pass/fail against the control-to-Purview map (audit, retention, DLP present + mode, labels, assessment reference). | Read-only |
| `CMPNIST-Report.ps1` | Evidence: produce `NIST 800-53 – Control Evidence – Report` (family → Purview artifact → status) as CSV/HTML for the assessment package. | Read-only |

## Named artifacts created
- Compliance Manager assessment: `NIST 800-53 – Rev5 – Assessment` (portal, from the NIST SP 800-53 Rev. 5 template).
- Control-to-Purview mapping workbook: `NIST 800-53 – Control-to-Purview – Map`.
- Audit-evidence retention policy (AU): `Control Evidence – NIST AU – Audit Retention`.
- Control-support DLP policy (SC/MP, simulation-first): `Control Evidence – NIST SC-MP – DLP (Simulation)`.
- Evidence report / package export: `NIST 800-53 – Control Evidence – Report`.
- Pilot scope: `NIST Pilot – Control Set – Stage1`.

## Definition of done
- Licensing, roles, and toolchain confirmed; the **NIST SP 800-53 Rev. 5 assessment** created in Compliance
  Manager.
- The **control-to-Purview map** documented and approved, each in-scope control marked *Purview-covered* or
  *deferred*.
- **AU family:** unified audit logging **on** and `Control Evidence – NIST AU – Audit Retention` in place.
- **SC/MP:** `Control Evidence – NIST SC-MP – DLP (Simulation)` created in **test mode**, detecting without
  blocking, validated on the pilot — then moved to **enforce** on expand.
- **AC/SC:** the label/encryption evidence the map cites is present (or the gap recorded and assigned).
- Per-family **validation green** for the pilot; `NIST 800-53 – Control Evidence – Report` generated and its
  artifacts attached to the Compliance Manager improvement actions; the monitoring cadence scheduled.

> **Boundary:** this solution delivers the technical control configuration and the evidence. **Control
> applicability/tailoring, evidence sufficiency, residual-risk acceptance, the authorization boundary, and
> the authorization determination (ATO) are deferred to your Authorizing Official, security, compliance,
> records, privacy, and legal functions.** Purview implements a **subset** of NIST 800-53; non-technical
> families are handled by your program. Feature availability is **licensing-/tenant-dependent and evolving —
> verify against your entitlements and current Microsoft documentation.**
