# 8. Deliverables Summary — Business Glossary & Stewardship Program (Microsoft Purview)

## What you receive
A complete, self-guided package to stand up a **business glossary** and a **data-stewardship program**
in Microsoft Purview's **Unified Catalog** — configured, piloted in Draft, validated against explicit
gates, and operable with a repeatable upkeep cadence.

## Documentation set
| Document | What it gives you |
|---|---|
| **1. Solution Overview** | What the glossary + stewardship program is, the four building blocks (governance domain, glossary, stewardship program, upkeep cadence), roles, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **2. Requirements Guide** | The solution-specific prerequisites (Unified Catalog availability, least-privilege governance roles, the stewardship RACI + workflow, a pilot domain and CDE list, data-plane access, change control) — each with verify/implement — on top of the six category Global Requirements. |
| **3. Implementation Guide** | Exact ordered steps: design the domain/roles/workflow, seed the glossary **in Draft** (`-WhatIf` then `-Commit`), owner-gated publish, validate, run the upkeep cadence, expand — with named artifacts, pass/fail gates, and rollback. |
| **5. Testing & Validation Guide** | Six pass/fail gates from readiness through owned/defined Published terms to an evidenced upkeep cadence, plus the rollback summary. |
| **6. Troubleshooting Guide** | The common failure modes (endpoint/token, roles, workflow, unowned or stale terms, evolving API/portal) and how to resolve each. |
| **7. Best Practices** | Field-tested guidance: start with CDEs, one owner + one steward per term, Draft-first publishing, definition vs determination, least privilege, re-certification cadence, verify the evolving portal. |
| **Executive Summary** | A one-page business framing for sponsors and stakeholders. |

## PowerShell tools (5)
All tools are **read-only or `-WhatIf` by default**; any write is gated behind an explicit `-Commit`.
They acquire a **Purview data-plane token** from your interactive `Connect-AzAccount` sign-in — **no
secret is stored in code**. Verify the current Purview data-plane API versions for your tenant.

| Script | Role | Safety |
|---|---|---|
| **DGGLOSS-Discovery.ps1** | Assess readiness: endpoint reachable, governance domains, glossary term count + status mix, governance-role coverage. | Read-only |
| **DGGLOSS-Set-Scope.ps1** | Record the pilot scope: domain, candidate terms/CDEs, owner/steward mapping, re-certification interval → scope manifest. | Read-only |
| **DGGLOSS-Configure-Glossary.ps1** | Configure/remediate: create the governance domain and seed terms **in Draft** (owner/steward/definition); set a term's status (e.g. Published) with `-Commit`. | `-WhatIf` default; `-Commit` to write |
| **DGGLOSS-Validate.ps1** | Validate against the pilot gate: Published terms have definition, owner, steward, and intended links; workflow gate honored. | Read-only |
| **DGGLOSS-Report.ps1** | Stewardship report: terms by status, unowned Published terms, stale terms past re-certification, coverage per domain. | Read-only |

## Outcomes
- A **governance domain** with least-privilege roles and a named stewardship RACI.
- A **business glossary** of agreed terms / critical data elements — each **owned**, **stewarded**,
  **defined**, and **approved** before it is Published.
- A **term-approval workflow** that blocks unreviewed publishing.
- A **repeatable upkeep cadence** with reporting evidence that the program is maintained.
- A validated pilot and a documented path to expand across further domains.

## Boundary
The package delivers the **technical configuration and operating model**. The **authoritative meaning**
of each term, whether an element is a regulated critical data element, and any records/legal
consequence of a definition remain determinations of the business data owners, compliance, records,
privacy, and legal functions. Purview features are licensing-/plan-dependent and the portal is
evolving — verify availability, paths, and API versions for your tenant.
