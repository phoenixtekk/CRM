# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
| Document | What it gives you |
|---|---|
| **1. Solution Overview** | What the permission/access model is, how it works, the standard permission-level model, the reference artifacts, benefits, limitations, and the boundaries vs external sharing / IA / records. |
| **2. Requirements** | Solution-specific prerequisites (SharePoint Admin + SCA, PnP app registration, group source of truth, information owners, P2/SAM licensing, Graph read scopes, pilot + rollback) with verify/implement steps — on top of the shared SharePoint global requirements. |
| **3. Implementation** | Exact ordered steps: assess (audit) → design the group + level model → configure group-based access → remediate direct grants + broken inheritance (pilot, `-WhatIf` first) → validate → stand up reviews → expand. Every artifact named; pass/fail gates and rollback throughout. |
| **5. Testing & Validation** | Nine tests (group-based root, correct levels, inheritance reduced to exceptions, Limited Access reduced, no over-share, converted-user effective access, review running, report reproduces, rollback understood), each with pass/fail. |
| **6. Troubleshooting** | Common failure modes (audit shows nothing, can't reset inheritance, Limited Access persists, direct grants reappear, review/report gaps, Gov-cloud paths) with root cause and fix. |
| **7. Best Practices** | Durable practices for group-based access, inheritance discipline, change control, ongoing attestation, and cloud/licensing awareness. |
| **Executive Summary** | Crisp outcome/approach/why-low-risk summary for decision-makers. |

## PowerShell scripts (5) — SharePoint Online Management Shell / PnP PowerShell / Microsoft Graph
All are **safe by default** (read-only, or `-WhatIf` / dry-run unless an explicit `-Commit`), use
modern-auth `Connect-PnPOnline` / `Connect-MgGraph` (no stored credentials), and reuse the artifact names
from the reference model.

| Script | What it does | Safe default |
|---|---|---|
| **SPOPERM-Scope.ps1** | Pre-flight scope/health check: modules installed, sign-in works, group-read (Site Collection Admin proxy), standard groups/levels resolve, and the broken-inheritance footprint sized. Run first. | Read-only |
| **SPOPERM-Discovery.ps1** | Read-only audit → `Permission Audit – SPO – Discovery`: broken inheritance, unique permissions, **direct user grants**, **Limited Access**, and **over-share** signals per site. The rollback baseline + owner exception list. | Read-only |
| **SPOPERM-Remediate-GroupAccess.ps1** | Moves the site to **group-based access**: ensures the standard Owners/Members/Visitors groups + levels exist, and converts **direct user grants** into group membership. Records `Group Access Remediation – <Site> – Remediation`. | Dry-run unless `-Commit`; `-WhatIf` |
| **SPOPERM-Reset-Inheritance.ps1** | Resets **broken-inheritance** scopes back to inherit (clearing unique permissions and the Limited Access they created), **excluding** documented exceptions. Records `Inheritance Reset – <Site> – Remediation`. | Dry-run unless `-Commit`; `-WhatIf` |
| **SPOPERM-AccessReview.ps1** | Read-only who-has-access report → `Access Report – SPO – Report`: SharePoint groups expanded to members, including nested Entra/M365 groups via Graph. The recurring attestation evidence (`Access Review – <Site> – Prod`) when P2/SAM features aren't licensed. | Read-only |

> **Licensing note:** **Entra ID Access Reviews** (P2) and SharePoint **Data Access Governance reports /
> site access review** (SharePoint Advanced Management) are **plan-dependent add-ons** — verify in your
> tenant/plan. Where they aren't licensed, the included PowerShell reporting provides the same evidence.
> **Who belongs in each group is an information-owner decision**, not an implementer one.
