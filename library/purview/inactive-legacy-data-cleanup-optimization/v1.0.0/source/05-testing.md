# 5. Testing & Validation — Inactive & Legacy Data Cleanup & Storage Optimization (Microsoft Purview)

Validate the cleanup implementation against explicit **pass/fail gates**. The four headline gates are:
**(A) the right stale/legacy data is identified and scoped**, **(B) no held item is deletable — the safety
gate**, **(C) cleanup acts only where intended and produces disposition evidence**, and **(D) savings are
measured and the control is reversible up to permanent deletion**. Run every test with **fabricated / clearly
non-production data or a designated safe pilot scope** — **never** by deleting real business content to "see if
it works." Record the evidence.

> All tests assume the artifacts from the Implementation Guide: labels published to the pilot, auto-apply in
> **simulation**, and the deletion policy scoped to `DLC Cleanup Pilot – Stage1` only. Deletion is destructive —
> **the hold cross-check (Gate B) must pass before any enforcement.**

---

## Test A — Identification & scoping (the right data is targeted)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | ROT candidates sized | Run `DLCCLEAN-Report.ps1 -StaleDays 365 -CsvPath ...` | A named, sized list of stale sites/OneDrives/mailboxes (last-activity + storage) is produced. |
| A2 | Inactive mailboxes enumerated | Run `DLCCLEAN-Discovery.ps1`; inspect the inactive-mailbox section. | Inactive mailboxes (`Get-Mailbox -InactiveMailboxOnly`) are listed with the hold that retains them. |
| A3 | Auto-apply simulation accuracy | Open `DLC – Auto-Apply Cleanup – Simulation` results. | The items that *would* be labeled are the intended stale/legacy content — no live business data. |
| A4 | Scope is limited, not "All" | Run `DLCCLEAN-Validate.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot'`. | Policy scope is the named pilot location(s) only — **not** an "All" / tenant-wide location. |
| A5 | Adaptive scope precision (if used) | Review the members an adaptive scope resolves to. | Members match the intended stale/decommissioned attribute query — no live/active objects mis-selected. |

**Gate A (pass):** stale/legacy candidates are identified and sized; the deletion policy is confirmed **limited-
scoped** to the intended targets.

---

## Test B — Hold safety (no held item is deletable) — the defensibility gate

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Hold inventory complete | `DLCCLEAN-Discovery.ps1` lists litigation, eDiscovery case, and retention holds. | Every hold class is enumerated; the count matches what legal/eDiscovery confirms (Req 2.4). |
| B2 | Scope vs hold cross-check | `DLCCLEAN-Validate.ps1` cross-checks the delete-policy scope against all holds. | **No in-scope location/mailbox/site is under any hold** — or every overlap is flagged and excluded. **PASS = zero deletable held items.** |
| B3 | Held content survives a delete action | On a fabricated item placed under a test hold within (a copy of) the scope, confirm a delete label/policy does **not** purge it. | Held content is **retained** despite the delete action (retention principles: hold blocks purge). |
| B4 | Uncertain hold halts enforcement | Simulate an unconfirmed hold state. | The process **stops** — enforcement does not proceed while any hold state is unconfirmed. |

**Gate B (pass):** the hold cross-check is **clean** (no deletable held item) and any overlap is excluded or
resolved with legal before enforcement. **This gate is mandatory before Phase 4/5.**

---

## Test C — Controlled cleanup & disposition evidence (acts only where intended)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | `-WhatIf` preview makes no change | Run the config/report tools without `-Commit`. | Only a preview of what *would* happen is produced; nothing is created, labeled, or deleted. |
| C2 | Pilot-only action | With auto-apply on for the pilot, confirm content **outside** `DLC Cleanup Pilot – Stage1` is untouched. | No labeling/deletion occurs outside the pilot scope. |
| C3 | Disposition review gate | For `DLC – Disposition Review – LegacyRecords` content at end-of-life, run the review. | Reviewers must **approve** before permanent deletion; approval/extension/relabel is recorded. |
| C4 | Disposition evidence captured | Inspect the disposition record for a reviewed item. | An auditable record exists: who approved deleting what, and when (defensible-cleanup evidence). |
| C5 | Retention wins where classes overlap | Apply a retain label and a delete label to overlapping content. | The **retain** action wins (retention precedence) — content is not prematurely deleted. |

**Gate C (pass):** cleanup acts **only** on the pilot scope, deletion of record-value content passes through
disposition review, and the disposition evidence is captured.

---

## Test D — Savings measurement & reversibility

| # | Test | Steps | Pass condition |
|---|---|---|---|
| D1 | Storage baseline vs projected savings | Compare the `DLCCLEAN-Report.ps1` ROT-candidate storage before, and the projected/actual reclaimed storage after. | A measured storage figure exists (candidate GB identified; reclaimed GB after disposition). |
| D2 | Reversible pre-purge | Set auto-apply back to **simulation** / remove the pilot policy before any permanent deletion. | The control is removed with **no content lost** (reversible up to permanent deletion). |
| D3 | Scripts safe-by-default | Run `DLCCLEAN-Config.ps1` and `DLCCLEAN-Set-Scope.ps1` **without** `-Commit`. | They make no change (`-WhatIf` output only); Discovery/Validate/Report are read-only. |
| D4 | No tool deletes content | Review all five scripts. | **None** permanently deletes content — deletion remains a hold-checked portal/policy action. |

**Gate D (pass):** savings are measured, the control is reversible before permanent deletion, and every tool is
confirmed non-destructive.

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV + **complete hold inventory** (Phase 0 / Test B1).
- Sized **ROT candidate list** and the measured storage figure (Test A1 / D1).
- The **hold cross-check result** proving no deletable held item (Test B2) — the defensibility centerpiece.
- Auto-apply **simulation results** and the `-WhatIf` disposition preview (Test A3 / C1).
- The **disposition-approval trail** (who approved deleting what, when) for reviewed content (Test C3/C4).
- Confirmation that action stayed inside the pilot scope (C2) and that the control reverts pre-purge (D2).

> **Determination boundary.** These tests prove the **control works and is defensible**. Whether a given class's
> retention period, its records status, what is under legal hold, and whether a deletion is *authorized* are
> **records / compliance / legal** sign-offs, captured alongside the evidence above.
