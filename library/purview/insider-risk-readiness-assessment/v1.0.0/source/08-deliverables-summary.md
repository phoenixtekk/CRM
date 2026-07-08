# 8. Deliverables Summary — Insider Risk Readiness Assessment (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The IRM readiness model — privacy-by-design (anonymization on, minimum indicators), the four-way role-separation model (Admins / Analysts / Investigators / Auditors, separate from HR/Legal), connectors (HR/Entra/DLP/Defender), Analytics-first, and the least-exposing → scoped journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (IRM licensing; separated role groups; privacy/anonymization + minimum indicators; HR/Entra/DLP/Defender connectors; unified audit logging; a minimal readiness scope; HR/privacy/legal sign-off) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → privacy-by-design → separate roles → prepare connectors → pilot **Analytics-first then a disabled/minimal policy** → validate & hand off; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the four headline outcomes — licensed & private (A), roles separated (B), signal substrate healthy (C), scope minimal & pilot least-exposing (D) — plus pseudonymization/data-handling checks, all with fabricated test data and touching no individual. |
| **Troubleshooting Guide** | The common failure modes (IRM not visible, role-separation conflicts, analytics/policy shows nothing, connector not importing, audit off, "why can't PowerShell do X") and how to resolve them. |
| **Best Practices** | Privacy-first discipline, ruthless role separation, Analytics-before-policy, connector-to-template matching, honesty about what is scriptable, and keeping the scaffold non-operational until the deploy decision. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Microsoft Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`, and **no tool ever
enables an IRM policy or enforcement**. No credentials are stored in code. They connect via
`Connect-IPPSSession` (role groups, audit) and/or `Connect-MgGraph` (licensing signal, the backing scope
group). Because **IRM is largely portal-configured**, each tool clearly directs the operator to the Purview
portal for the portal-only steps it cannot script — it never invents a cmdlet.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **IRMASSESS-Discovery.ps1** | IRM readiness posture: IRM role groups + membership with **separation-conflict** flags, unified-audit-log state, a licensing **signal** (subscribed-SKU service plans), and a portal checklist for analytics/connectors/pseudonymization/policies. | Read-only |
| 2 | **IRMASSESS-Config.ps1** | Readiness-scaffold helper: creates the **backing Entra security group** for the priority-user scope (`IRM Priority Users – Readiness – Scope`) **empty / least-exposing**. Never binds a policy, never enables IRM — those are portal steps. | `-WhatIf` (writes need `-Commit`) |
| 3 | **IRMASSESS-Validate.ps1** | Readiness validator: per-gate **PASS / FAIL / VERIFY-IN-PORTAL** for licensing signal, audit-log state, role separation, and the backing scope group; prints the portal-verified gates (privacy/anonymization, connectors, analytics, policy). | Read-only |
| 4 | **IRMASSESS-Report.ps1** | **Pseudonymized** readiness scorecard for stakeholder review: **counts and gate status only** (role-group member *counts*, not names) — no personal data, safe to hand to HR/privacy/legal. | Read-only |
| 5 | **IRMASSESS-Set-Scope.ps1** | Scope/health helper: reports the backing scope group's membership and (with `-Commit`) **adjusts** it (add/remove a member of the readiness scope). Does not enable any policy. | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- IRM is **licensed** and openable in the portal (Req 2.1 — verify your licensing/tenant).
- **Privacy-by-design** set: anonymization **ON**, minimum indicators enabled, privacy decision signed off
  (Gate A).
- **Role separation** proven: Admins / Analysts / Investigators / Auditors held by **different** owners, the
  super-group minimal, HR/Legal not default Investigators, no separation conflict flagged (Gate B).
- **Signal substrate** ready: unified audit logging on; the connectors the intended template needs (HR/Entra/
  DLP/Defender) configured and healthy in the portal (Gate C).
- **Least-exposing pilot** done: **Analytics** run and reviewed (aggregated/anonymized, no policy); the
  backing scope group minimal/test-only; the readiness policy created **disabled/minimal**, scoped to the
  priority-user group only; nothing enforcing against real users (Gate D).
- **Pseudonymized readiness scorecard** produced and handed to HR/privacy/legal; scaffold verified
  non-operational; scripts safe-by-default; change log and privacy sign-off captured.

> **Boundary:** the solution delivers the technical **readiness** method and the evidence. The decision to
> **deploy** IRM, the **lawfulness of monitoring** in your jurisdiction, whether to **open a case**, what a
> risk signal **means** for a person, and any **HR/disciplinary/legal action** are HR/privacy/legal
> determinations, captured alongside the evidence. The assessment operates against **no** individual.
