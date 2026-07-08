# Executive Summary — Inactive & Legacy Data Cleanup & Storage Optimization (Microsoft Purview)

## The problem
Every tenant quietly accumulates **ROT** — data that is **Redundant, Obsolete, or Trivial** — and **inactive /
legacy** content: the mailbox of an employee who left years ago, a SharePoint site nobody has opened since a
finished project, an unused OneDrive, a Teams team for an event long past, a decade of duplicate "final_v7"
files. It inflates **storage cost**, enlarges the **data-breach blast radius** (every stale file is one more
thing to exfiltrate), and drags on **eDiscovery and audits**. The temptation is to "just delete the old stuff"
— but deletion is **irreversible**, and deleting content that turns out to be **under legal hold** or subject to
a **retention obligation** is a serious, sometimes legal, failure.

## The solution
Use **Microsoft Purview Data Lifecycle Management and Records Management** — the native retention/deletion engine
— to **identify** ROT and stale/legacy data and **defensibly clean it up** across **Exchange, SharePoint,
OneDrive, Teams, and Microsoft 365 Groups**, using only the Microsoft Purview portal, Security & Compliance
PowerShell, Exchange Online PowerShell, and Microsoft Graph usage reports. The defining discipline is that
**nothing is ever auto-deleted and everything is proven safe first**: stale-data candidates are **identified and
sized from real signals**; auto-apply label policies run in **simulation**; deletion policies are **piloted on a
limited scope** and previewed with `-WhatIf`; **every existing hold is enumerated and cross-checked** so no held
item can be deleted; and record-value content passes through **disposition review** that produces an auditable
approval trail. The result: storage and exposure go **down**, defensibly, without destroying anything that should
have been kept.

## What it delivers
- A **sized ROT candidate inventory** — inactive mailboxes, dormant sites, unused OneDrives, orphaned
  Teams/Groups — built from mailbox/site last-activity and storage signals, not guesswork.
- **Retention labels and retention/deletion policies** (retain / retain-then-delete / delete-only /
  disposition-review) scoped by **static or adaptive** scope, designed with the records function.
- A **hold safety gate**: the complete hold inventory (litigation, eDiscovery case, retention) cross-checked
  against the cleanup scope, proving **no held item is deletable** before enforcement.
- **Disposition review** for record-value content, producing the **who-approved-deleting-what-and-when**
  evidence that makes cleanup defensible.
- **Five PowerShell tools** (posture/hold discovery, policy config helper, validation/hold cross-check,
  ROT/savings report, scope helper) — read-only or `-WhatIf` by default; **none deletes content**.

## Business outcomes
- **Lower storage cost and a smaller attack surface** — ROT and inactive data reduced across the workloads it
  actually lives in.
- **Defensible, not reckless** — the hold cross-check and disposition review mean cleanup can be evidenced to
  auditors and counsel, not just performed.
- **No accidental data loss** — limited-scope pilots, `-WhatIf` previews, simulation, and hold checks make the
  control reversible right up to the point of authorized permanent deletion.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
Feature availability is licensing-/plan-dependent — **adaptive scopes, auto-apply, Records Management, and
disposition review generally require Microsoft 365 E5 / E5 Compliance** (some preview); basic labels and static
retention are E3-capable (verify your tenant). This solution provides the **technical method and the evidence**;
*how long* to keep each class, *what* is under legal hold, whether content is a **record**, and whether a given
deletion is **authorized and defensible** are **records, compliance, privacy, and legal determinations**,
captured alongside the delivered evidence.
