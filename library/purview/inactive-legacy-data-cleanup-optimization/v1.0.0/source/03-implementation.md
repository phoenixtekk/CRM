# 3. Implementation Guide — Inactive & Legacy Data Cleanup & Storage Optimization (Microsoft Purview)

This is the exact, ordered procedure to **identify** ROT / inactive / legacy data and **defensibly clean it up**
with Microsoft Purview — auto-apply built in **SIMULATION** first, deletion **piloted on a limited scope** and
**previewed with `-WhatIf`**, and **every hold checked and respected** before anything is enforced. Portal paths
and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent features and evolving portal
paths are flagged "verify your licensing/tenant"** and are never asserted for your tenant. Do the phases in
order. Each phase names its artifacts (from the Overview naming table), states a **pass/fail gate**, and gives a
**rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), **Exchange Online PowerShell** (inactive mailboxes / statistics), and **Microsoft
> Graph** (usage reports). They are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`
> switch. **None of them permanently deletes content** — the destructive action stays a deliberate, hold-checked
> portal/policy step under change control. No credentials are stored in code.

> **Determinations deferred.** *How long* to keep each class, *what* is under legal hold, whether content is a
> **record**, and whether a deletion is **defensible** are **records / compliance / privacy / legal** decisions
> (Req 2.4, 2.5). Capture the retention schedule and the confirmed hold inventory **before** Phase 3, and the
> deletion authorization **before** Phase 5.

---

## Phase 0 — Connect and baseline the storage / ROT posture (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # Connect-IPPSSession + Connect-ExchangeOnline
   Connect-IPPSSession   -UserPrincipalName admin@contoso.com          # Security & Compliance PowerShell
   Connect-ExchangeOnline -UserPrincipalName admin@contoso.com         # inactive mailboxes / mailbox statistics
   Connect-MgGraph -Scopes 'Reports.Read.All','Organization.Read.All' -NoWelcome   # Graph usage reports
   ```
2. **Run the posture assessment** (delivered script #1, read-only):
   ```powershell
   .\DLCCLEAN-Discovery.ps1 -CsvPath .\DLCCLEAN-Posture.csv
   ```
   It reports existing **retention policies/labels/label policies** and their scope, **all holds in force**
   (litigation, eDiscovery case, retention), the **inactive-mailbox inventory**, and mailbox/site/OneDrive
   **last-activity + storage** signals — the ROT candidate baseline.
3. **Build the sized ROT candidate list** (delivered script #4, read-only):
   ```powershell
   .\DLCCLEAN-Report.ps1 -StaleDays 365 -CsvPath .\DLCCLEAN-ROT-Candidates.csv
   ```
   It lists stale sites/OneDrives/mailboxes (no activity beyond `-StaleDays`) with storage consumed, so the
   records/storage owners see named, sized candidates — not a guess.
4. **Confirm licensing** (Req 2.1): confirm E5/E5-Compliance where adaptive scopes, auto-apply, or disposition
   review are needed; if E3-only, plan a manual-label + static-scope first wave.

**Pass/fail gate:** you have a written baseline (existing retention + **complete hold inventory**), a **sized ROT
candidate list**, and confirmed licensing for the capabilities you will use.
**Rollback:** none (read-only).

---

## Phase 1 — Design the labels, policies, and scope (Design — with the records function)

Decide, **per in-scope data class**, the retention action and the scope. Do **not** invent retention periods —
they come from the records schedule (Req 2.5). *Whether adaptive scopes / auto-apply / disposition review are
available is licensing-dependent — verify your tenant.*

5. **Create the retention labels** you need in **Purview portal → Solutions → Records management → File plan**
   (or **Data lifecycle management → Labels**):
   - `DLC – Retain-Delete – GeneralContent` — **retain then delete** after the records-defined period.
   - `DLC – Delete-Stale – LegacyContent` — **delete-only** (no retain) for content the schedule says may simply
     be removed once stale.
   - `DLC – Disposition Review – LegacyRecords` — **retain then delete with mandatory disposition review** for
     record-value content (requires Records Management / E5 — verify). *The period and which content each label
     applies to are the records function's determination.*
6. **Design the scope for each cleanup policy** — **static** (named sites/mailboxes) for the pilot, **adaptive**
   for ongoing targeting where licensed:
   - `DLC – Stale Sites – Adaptive Scope` — a **SharePoint site** adaptive scope querying the attribute(s) that
     mark a site stale/decommissioned (Req 2.6).
   - `DLC – Inactive Mailboxes – Adaptive Scope` — a **User** adaptive scope for departed/disabled users'
     mailboxes.
   Portal: **Data lifecycle management → Adaptive scopes → Create scope**. *Adaptive scopes require E5-class
   licensing — verify.*
7. **Decide the auto-apply conditions** (if using auto-apply): which content should receive
   `DLC – Retain-Delete – GeneralContent` automatically (by SIT, keyword/query, or trainable classifier) — this
   will run in **simulation** first (Phase 2).

**Pass/fail gate:** every in-scope data class maps to a named label with a **records-approved** action/period,
and each cleanup target maps to a named static or adaptive scope; disposition-review labels are identified.
**Rollback:** delete unused labels/scopes (they have no effect until published/applied by a policy).

---

## Phase 2 — Configure and publish/auto-apply in SIMULATION (Configure — no deletion)

8. **Publish the labels to the pilot scope** — `DLC – Publish Cleanup Labels – Pilot`.
   Portal: **Data lifecycle management → Label policies → Publish labels** → select the DLC labels → **scope:
   the limited pilot locations only** (`DLC Cleanup Pilot – Stage1`). Publishing only *makes labels available /
   manually appliable*; it deletes nothing.
9. **Create the auto-apply policy in simulation** — `DLC – Auto-Apply Cleanup – Simulation` (E5 — verify).
   Portal: **Data lifecycle management → Label policies → Auto-apply a label** → choose
   `DLC – Retain-Delete – GeneralContent` → set the condition (SIT/keyword/query/classifier) → **scope: pilot** →
   **choose "Run policy in simulation mode."** Simulation shows *what would be labeled* with **no** label
   actually applied.
10. **Create the deletion/retention policy in PILOT, limited scope** — `DLC – Delete Inactive Content – Pilot`.
    Verify (read-only preview) with the config helper first, then commit to the **pilot scope only**:
    ```powershell
    # Preview only — no change:
    .\DLCCLEAN-Config.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' `
        -Workload SharePoint -RetentionAction Delete -RetentionDays 2555 `
        -StaticScopeLocation 'https://contoso.sharepoint.com/sites/DLC-Pilot' -WhatIf
    # Create it, still scoped to the limited pilot location:
    .\DLCCLEAN-Config.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' `
        -Workload SharePoint -RetentionAction Delete -RetentionDays 2555 `
        -StaticScopeLocation 'https://contoso.sharepoint.com/sites/DLC-Pilot' -Commit
    ```
    The helper creates the policy on the **named pilot location only** and never applies it tenant-wide; the
    retention period comes from the records schedule (Req 2.5), not the tool.

**Pass/fail gate:** labels published to pilot; auto-apply policy confirmed **in simulation** (no labels applied);
the deletion policy exists but is **scoped to the limited pilot location only**.
**Rollback:** unpublish the label policy / delete the simulation and pilot policies — no content was deleted, so
removal is clean.

---

## Phase 3 — Validate scope and prove no held item is deletable (Validate — the safety gate)

This phase is the **defensibility gate** and must pass before any expansion.

11. **Validate the pilot policy** (delivered script #3, read-only):
    ```powershell
    .\DLCCLEAN-Validate.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' -CsvPath .\DLCCLEAN-Validate.csv
    ```
    It confirms: the policy is scoped to the **intended pilot location(s) only** (not "All"); the **retention
    action/period** matches the design; and — critically — it **cross-checks every hold** (litigation,
    eDiscovery case, retain-action retention) against the policy scope and **flags any overlap** where an item
    could be under hold. **PASS = scope correct AND no in-scope item under hold would be purged.**
12. **Review the auto-apply simulation results.** Portal: open `DLC – Auto-Apply Cleanup – Simulation` → the
    **simulation results** show exactly which items *would* be labeled. Confirm they are the intended stale/legacy
    content and not live business data.
13. **Confirm the hold inventory with legal/eDiscovery** (Req 2.4). If any hold state is uncertain, **stop** —
    do not proceed to enforcement until legal confirms.

**Pass/fail gate:** scope verified limited-and-correct; **hold cross-check clean** (no deletable held item);
auto-apply simulation shows only intended content.
**Rollback:** none needed (read-only validation); if the check fails, **narrow the scope / exclude the held
locations / resolve the hold** before continuing — do not enforce.

---

## Phase 4 — Pilot the cleanup with `-WhatIf` and disposition review (Pilot)

14. **Preview the deletion impact on the pilot scope** (script #4, read-only):
    ```powershell
    .\DLCCLEAN-Report.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' -Mode DispositionPreview `
        -CsvPath .\DLCCLEAN-Disposition-Preview.csv
    ```
    This lists the items the pilot policy would act on and the storage they represent — the disposition-review
    input. **No deletion occurs.**
15. **Turn on auto-apply for the pilot** only after simulation is satisfactory: in the portal, switch
    `DLC – Auto-Apply Cleanup – Simulation` from **simulation** to **on** — *for the pilot scope only*. Labels now
    apply to pilot content (retain/retain-then-delete), still no immediate deletion (deletion happens at
    end-of-retention, gated by disposition review where configured).
16. **Run disposition review** for `DLC – Disposition Review – LegacyRecords` content reaching end-of-life.
    Portal: **Records management → Disposition** → the `DLC Disposition Review – Board` reviewers **approve,
    extend, or relabel** each item. Approval is what authorizes permanent deletion — and produces the
    **disposition evidence** (who approved what, when). *(E5 / Records Management — verify.)*
17. **Confirm scope stayed limited.** Re-run `DLCCLEAN-Validate.ps1` and confirm nothing outside
    `DLC Cleanup Pilot – Stage1` was affected and the hold cross-check is still clean.

**Pass/fail gate:** pilot content is labeled/dispositioned as designed; disposition reviewers produced approval
evidence; **no content outside the pilot scope was touched**; hold cross-check remains clean.
**Rollback:** remove the pilot policy / unpublish labels / set auto-apply back to simulation — reversible up to
the point a disposition approval permanently deletes an item. Content already permanently deleted past retention
is **not** recoverable — which is why the hold check and disposition review gate it.

---

## Phase 5 — Expand under change control and operate (Expand → Operate)

18. **Expand the scope** from the limited pilot to the intended population **one workload/scope at a time**,
    swapping the static pilot location for the `DLC – Stale Sites – Adaptive Scope` /
    `DLC – Inactive Mailboxes – Adaptive Scope` where licensed — **re-running `DLCCLEAN-Validate.ps1` and the
    hold cross-check after each expansion** (Req 2.6). Each expansion is a change-controlled step with the
    **deletion authorization** captured (Req 2.5).
19. **Extend to inactive mailboxes and orphaned Groups/Teams** deliberately: inactive mailboxes are already
    retained by a hold — apply the records-approved retention/label so they are eventually dispositioned rather
    than kept forever; clean up finished-project Teams/Groups and their connected sites/mailboxes per the same
    gated process.
20. **Operationalize:** schedule `DLCCLEAN-Report.ps1` for a **recurring storage-savings and ROT report**, run
    **disposition review on cadence**, and **refresh adaptive-scope attribute data** so membership stays
    accurate as the estate changes. Re-baseline periodically with `DLCCLEAN-Discovery.ps1`.
21. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence, including the storage-savings measurement and the disposition-approval trail.

**Pass/fail gate:** cleanup live across the intended scope with the records-approved action per class; **hold
cross-check clean at every expansion**; disposition evidence captured; measured storage savings recorded.
**Rollback:** any policy can be scoped back or removed; auto-apply can return to simulation; **but permanent
deletion past retention is irreversible** — expansion only proceeds where the hold check is clean and the
deletion is authorized.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline retention+holds, size ROT | Posture + ROT-candidate CSV | Baseline + hold inventory + sized candidates | n/a (read-only) |
| 1 Design | Labels, policies, static/adaptive scope with records fn | DLC labels + adaptive scopes | Every class → records-approved label + named scope | Delete unused label/scope |
| 2 Configure | Publish labels; auto-apply **simulation**; delete policy **pilot scope only** | Sim + pilot policies | Sim confirmed, delete policy limited-scoped | Unpublish / delete (nothing deleted) |
| 3 Validate | Verify scope; **prove no held item deletable** | Validation CSV | Scope correct + **hold cross-check clean** | Narrow scope / resolve hold (don't enforce) |
| 4 Pilot | `-WhatIf` preview; auto-apply on for pilot; disposition review | Disposition preview + evidence | Pilot only; disposition approved; holds clean | Back to simulation / remove (pre-purge) |
| 5 Expand | Broaden scope 1-at-a-time; adaptive; operate | Enforced policies | Full scope, holds clean, savings measured | Scope back (purge is irreversible) |
