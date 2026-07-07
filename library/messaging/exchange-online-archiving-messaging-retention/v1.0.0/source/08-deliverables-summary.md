# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
| Document | What it gives you |
|---|---|
| **1. Solution Overview** | What Exchange Online Archiving is here, how it works, the reference model/artifacts, benefits, limitations, and the explicit boundary vs Purview DLP/labels/retention. |
| **2. Requirements** | Solution-specific prerequisites (archiving-capable licensing, least-privilege roles incl. Mailbox Import Export, PST source, legal/records determination, MFA timing, Commercial-vs-Gov) with verify/implement steps — on top of the shared Messaging requirements. |
| **3. Implementation** | Exact ordered steps: assess → design → enable archives + auto-expand → build MRM tags/policy → import PSTs → apply holds → pilot-validate → expand, with pass/fail gates and a rollback. Every artifact named. |
| **5. Testing & Validation** | Nine tests (archive provisioned, auto-expand, policy assigned, tags linked, move-to-archive working, PST landed in archive, litigation hold, In-Place hold, nothing-held-lost), each with pass/fail. |
| **6. Troubleshooting** | Common failure modes (archive won't enable, auto-expand not applying, mail not moving, PST in wrong place, hold not enforcing) with root cause and fix. |
| **7. Best Practices** | Durable practices for licensing, irreversible auto-expand, MRM hygiene, PST import, holds/preservation, and change discipline. |
| **Executive Summary** | Crisp outcome/approach/why-low-risk summary for decision-makers. |

## PowerShell scripts (5) — Exchange Online PowerShell (EXO V3) / Microsoft Graph
All are **safe by default** (read-only or `-WhatIf`/report unless an explicit `-Commit`), use modern-auth
`Connect-ExchangeOnline` (no stored credentials), and reuse the artifact names from the reference model.

| Script | What it does | Safe default |
|---|---|---|
| **EXOARCH-Discovery.ps1** | Read-only assessment: per-mailbox archive status, auto-expand flag, retention policy, primary/archive sizes, litigation + In-Place holds. Emits `Archive Posture – EXO – Discovery`. | Read-only |
| **EXOARCH-EnableArchive.ps1** | Enables the archive mailbox (and optionally the **irreversible** auto-expanding archive) for a scope; skips already-enabled; warns on unlicensed. | Dry-run unless `-Commit`; `-WhatIf` |
| **EXOARCH-Set-MrmPolicy.ps1** | Idempotently creates/updates the MRM move-to-archive DPT `Move to Archive – Default – Prod`, personal tag `Archive Now – Personal – Prod`, and policy `Archive Retention Policy – EXO – Prod`. | Preview unless `-Commit`; `-WhatIf` |
| **EXOARCH-Set-Holds.ps1** | Reports current holds; with `-Commit -Matter` applies **litigation hold** per the legal/records determination. (In-Place/eDiscovery holds are created in the Purview case.) | Report unless `-Commit`; `-WhatIf` |
| **EXOARCH-Validation.ps1** | Read-only pass/fail validation of archive, auto-expand, policy assignment, move-to-archive/PST ingest, and holds; optionally triggers the Managed Folder Assistant; emits `Archive Validation – EXO – Report`. | Read-only |

> **Licensing note:** archive and auto-expanding archive availability are **plan-dependent** — verify in
> your tenant/plan before enabling. **Holds** are technical only; **what to preserve and for how long is
> a legal/records determination**, not an implementer decision.
