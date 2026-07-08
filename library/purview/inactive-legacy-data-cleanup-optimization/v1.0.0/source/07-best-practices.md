# 7. Best Practices — Inactive & Legacy Data Cleanup & Storage Optimization (Microsoft Purview)

Field-tested practices for identifying ROT and defensibly cleaning up inactive/legacy data so the control cuts
storage and exposure **without ever destroying data that should have been kept**. These complement the
Implementation and Testing guides. The golden rule: **deletion is irreversible — prove it safe before you
enforce it, and never auto-delete.**

## Check holds first, every time — the defensibility gate
- **Enumerate every hold** (litigation, eDiscovery case, retain-action retention) **before** designing any
  delete policy, and **re-run the cross-check after every scope change** (`DLCCLEAN-Validate.ps1`). Purview's
  retention principles mean a hold *blocks* purge — but "the platform protects it" is not evidence; **prove** no
  in-scope item is held.
- If **any** hold state is uncertain, **stop**. Resolve it with legal/eDiscovery before enforcing. A deletion
  later found to have targeted held content is a serious, sometimes legal, failure.
- Keep the **hold inventory and the cross-check result** as part of the deliverable evidence — it is what makes
  the cleanup defensible.

## Never auto-delete — pilot small, preview with `-WhatIf`, expand slowly
- **Nothing is auto-deleted by these tools.** The scripts are read-only or `-WhatIf`; the destructive action is
  always a deliberate, hold-checked policy step under change control.
- **Pilot on a small, known-safe scope first** (`DLC Cleanup Pilot – Stage1`) — non-production or clearly-obsolete
  content — before touching the wider estate. Expand **one workload/scope at a time**, re-validating each.
- **Preview impact before committing:** run `DLCCLEAN-Report.ps1 -Mode DispositionPreview` and the auto-apply
  **simulation** so you see exactly what *would* be labeled/removed, and its storage, before it happens.

## Use simulation and disposition review as human gates
- **Run auto-apply label policies in SIMULATION first** — they show what *would* be labeled with no label
  applied. Read the results and confirm they are stale/legacy content, not live business data, before turning on.
- For record-value or sensitive content, require **mandatory disposition review** (`DLC – Disposition Review –
  LegacyRecords`) so a human **approves** each permanent deletion and the approval is **evidenced**. Reserve
  delete-only labels for content the records schedule clearly permits to simply age out.
- **Separate who authors a delete policy from who approves a disposition** where possible (Req 2.2) — least
  privilege on a destructive capability.

## Understand retention precedence before you design
- Retention and deletion are **one engine** governed by the **principles of retention**: **retention wins over
  deletion**, the **longest** retention wins, **explicit** beats **implicit**, and a **hold blocks purge**.
  Design cleanup knowing that a retain label/policy anywhere in scope will keep content your delete policy
  targets — that is a feature (it protects), not a bug.
- Don't stack overlapping delete policies hoping one "wins" — they don't purge held/retained content, and the
  interaction gets hard to reason about. Prefer **fewer, well-scoped** labels and policies.

## Get the scope right — static for pilot, adaptive for scale
- **Start static** (named pilot sites/mailboxes) so the pilot blast radius is exactly what you chose.
- Move to **adaptive scopes** for ongoing targeting (stale sites, departed-user mailboxes) **only once the
  attribute data is reliable** (Req 2.6) — an adaptive query over bad attributes selects the wrong objects. Test
  what an adaptive scope resolves to **before** binding a delete policy to it.
- **Refresh adaptive-scope attribute data** on a cadence — membership drifts as the estate changes; stale
  attributes silently mis-target.

## Measure ROT and savings from evidence
- Size ROT from **real signals** — mailbox/site/OneDrive **last-activity and storage** (Graph usage reports),
  **inactive-mailbox** inventory — not from assumptions. Name and size the candidates so the records/storage
  owners can decide.
- **Report savings** (candidate GB identified vs GB reclaimed after disposition) on a recurring cadence — it is
  the business case and it shows the control is working.
- Re-baseline periodically (`DLCCLEAN-Discovery.ps1`) — new ROT accumulates continuously; cleanup is an ongoing
  operation, not a one-time project.

## Mind the platform's behavior
- **Retention actions have latency** — label application, the deletion timer, and disposition processing run on
  Microsoft's cadence, not instantly. Allow dwell time before concluding a policy "didn't work."
- **Inactive mailboxes are already retained by a hold** — cleaning them up means applying a records-approved
  retention/label so they are eventually dispositioned, not kept forever; removing the hold without a plan can
  make them permanently unrecoverable.
- **Verify licensing/tenant** before relying on adaptive scopes, auto-apply, records management, or disposition
  review — several are E5/E5-Compliance (some preview), and portal paths evolve.

## Stay inside the boundary
- This solution provides the **technical method and the evidence**. The **retention schedule (how long),
  records status, legal-hold state, and whether a deletion is authorized/defensible are records / compliance /
  privacy / legal determinations** — you find the candidates, configure the control, prove no held item is
  deletable, and produce the disposition evidence; they own the decision to delete.
