# 8. Deliverables Summary — Microsoft Purview CJIS Compliance Program

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the CJIS-aligned Purview program is, the CJIS policy areas Purview contributes to, what you control, honest limitations, the environment boundary (GCC High / Azure Government), and the naming convention. |
| **2. Requirements Guide** | CJIS-specific prerequisites (authorized environment + CJIS agreement, control licensing incl. Audit Premium, least-privilege roles with separation of duties, CJI classification scheme, unified audit logging + retention target, control-map owner + CSA/auditor engagement, bounded pilot, secured evidence target) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: confirm the authorized environment, assess licensing/state, map CJIS areas to Purview controls, configure the CJI label/DLP/retention/audit in simulation/test, pilot on a bounded CJI scope, validate, produce evidence, and expand to enforcement — pilot-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Eleven gates from "environment authorized" to "evidence package reconciles," each with method / pass / fail action. |
| **6. Troubleshooting** | The failure modes that make a CJIS program wrong, over-blocking, or unevidenced — environment/licensing gaps, DLP over/under-match, audit not retained, role bleed, evidence drift — and their fixes. |
| **7. Best Practices** | Operating principles: configure the control but defer the determination, environment first, pilot in simulation, least-privilege & separation of duties, audit as backbone, repeatable evidence, licensing/preview reality, CJI identifiers stay with the agency. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; content-policy writes require `-Commit`, and no high-impact
control **enforces** without a separate `-Enforce -Commit`. No credentials or secrets are embedded.
Configuration uses **Security & Compliance PowerShell** (`Connect-IPPSSession`), **Exchange Online**
(audit config), and **Microsoft Graph** (licensing reads).

| Script | Role | Default |
|---|---|---|
| `CMPCJIS-Discovery.ps1` | Assess: licensing (labels/encryption, DLP, retention, **Audit Premium**, Insider Risk via Graph `subscribedSkus`), existing CJI-relevant objects, unified-audit-logging state, and Compliance Manager assessment-template visibility (flagged verify). | Read-only |
| `CMPCJIS-ScopeCheck.ps1` | Scope/health helper: connection/permission/licensing health across functions; list CJI-candidate labels, DLP/retention policies, workloads, and audit state; role-separation reminders. | Read-only |
| `CMPCJIS-Configure.ps1` | Configure: enable unified audit logging; scaffold `CJI – Protected – Label` (encryption), `CJI Protection – Exfiltration – Policy` (**Test mode**), and `CJI Records – Retention – Policy` (staged); enforce only with `-Enforce -Commit`. | `-WhatIf` (writes on `-Commit`) |
| `CMPCJIS-Validate.ps1` | Validate: audit logging on + retention targeted, each mapped control's object present and in the expected state, encryption on the label, DLP in test mode, retention staged, separation of duties — technical PASS/FAIL. | Read-only |
| `CMPCJIS-Report.ps1` | Report: produce `CJIS Evidence – Formal Audit – Package` (CSV + HTML) — the control map with per-control implementing object, state, and audit reference for the auditor/CSA. | Read-only (output files only) |

## Named artifacts created
- Control map: `CJIS Control Map – Purview – Baseline`.
- CJI label: `CJI – Protected – Label`. DLP: `CJI Protection – Exfiltration – Policy`. Retention:
  `CJI Records – Retention – Policy`.
- Assessment: `CJIS Assessment – Compliance Manager – Baseline`. Evidence: `CJIS Evidence – Formal Audit –
  Package`. Pilot: `CJIS Pilot – CJI Scope – Stage1`.

## Definition of done
- The **authorized environment** (GCC High / Azure Government) and CJIS agreement are **confirmed by the
  CSA/CSO**, and licensing gaps for in-scope controls are resolved or recorded as deferred.
- The **control map** is complete and reviewed with the CSA/auditor; the **CJI classification scheme** is
  agreed with the agency's records/security owners.
- The CJI **label (encryption)**, **DLP (test mode)**, **retention (staged)**, and **unified audit
  logging** are configured, **piloted on the bounded CJI scope**, and the DLP simulation is **reviewed and
  signed off** by the security officer.
- **Validation is technically green** (controls in the expected state; **separation of duties** holds),
  and the **`CJIS Evidence – Formal Audit – Package`** is produced, reconciled, and delivered via the
  secured channel; enforcement expanded under CSA/change approval.

> **Boundary:** this solution delivers **configured technical controls and repeatable evidence**. Whether
> those controls **satisfy** the CJIS Security Policy, whether the **environment** is authorized, and any
> **records-retention / regulatory / legal determination** are **deferred to your CSA, CJIS auditor,
> records, and legal functions.** Capability availability is **licensing-/cloud-dependent and evolving —
> verify against your entitlements, your cloud (GCC High / Azure Government), and your current CJIS
> Security Policy version.**
