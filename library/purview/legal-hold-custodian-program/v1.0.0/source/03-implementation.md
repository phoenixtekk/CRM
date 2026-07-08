# 3. Implementation Guide — Legal-Hold & Custodian Management Program (Microsoft Purview)

This is the exact, ordered procedure to stand up a legal-hold and custodian-management program in
**Microsoft Purview eDiscovery** — case, case hold, custodians, hold notifications, and tracking — proven on
a **pilot matter** with **fabricated test custodians** first, then adopted as the live practice for real
matters. Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent
features and evolving portal paths are flagged "verify your licensing/tenant"** and are never asserted for
your tenant. Do the phases in order. Each phase names its artifacts (from the Overview naming table), states
a **pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph** (eDiscovery, some endpoints **beta**). They are
> **read-only or `-WhatIf` by default**; writes require an explicit `-Commit` switch. **No script in this
> pack releases a hold** — release is a deliberate portal + sign-off action. No credentials are stored in code.

> **Determinations deferred.** *Whether* a duty to preserve has attached, *who* is a custodian, the *scope*
> of the hold, the legal sufficiency of a notice, and *when* a hold may be released are **legal / eDiscovery-
> counsel** decisions. This guide configures and proves the control; capture those decisions before Phase 3.

> **Scriptability caveat.** **Case holds** (`*-CaseHoldPolicy` / `*-CaseHoldRule`) and cases
> (`*-ComplianceCase`) are well covered by **Security & Compliance PowerShell**. **Custodians** and holds are
> readable/creatable via the **Microsoft Graph eDiscovery** APIs (some in **beta**). The
> **communications / hold-notice / acknowledgment** workflow is primarily a **portal** surface — the scripts
> **inventory and report** it where the API exposes status, but issuing/acknowledging notices is done in the
> Purview portal. Where a step is portal-only it is flagged; no cmdlet is invented.

---

## Phase 0 — Connect and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   # Graph (eDiscovery custodian/case read) — beta scopes, verify availability in your tenant:
   Connect-MgGraph -Scopes 'eDiscovery.Read.All','Organization.Read.All' -NoWelcome
   ```
2. **Run the posture assessment** (delivered script #1, read-only):
   ```powershell
   .\EDHOLD-Discovery.ps1 -CsvPath .\EDHOLD-Posture.csv
   ```
   It reports existing eDiscovery cases, case hold policies and their **distribution status**, any existing
   custodian/communications signal (via Graph, where licensed), a **Premium-licensing signal**, and
   eDiscovery role-group membership.
3. **Confirm licensing and roles** (Req 2.1, 2.2): confirm Standard vs Premium and that at least one
   **eDiscovery Administrator** owns the program, with **eDiscovery Managers** per matter.

**Pass/fail gate:** you have a written baseline (existing cases, holds and their distribution status, role
membership) and a confirmed licensing tier (Standard = case holds only; Premium = custodians + communications).
**Rollback:** none (read-only).

---

## Phase 1 — Design the matter case and preservation scope (Design)

Take the matter, custodian list, and preservation scope **from legal** (Req 2.3/2.4) and design the objects.
Do **not** invent a preservation scope — default to preserve-everything unless legal has authorized a query.

4. **Create the pilot case.** In **Purview portal → eDiscovery** (verify Standard vs the new unified
   experience in your tenant), create the case `Legal Hold Case – Contoso-Matter-001 – Pilot`, or:
   ```powershell
   New-ComplianceCase -Name 'Legal Hold Case – Contoso-Matter-001 – Pilot' `
       -CaseType eDiscovery -Description 'Pilot matter — fabricated custodians only'
   ```
5. **Design the hold.** Decide, with legal, whether the hold is **preserve-everything** or **query-based** (a
   `ContentMatchQuery` KQL condition and/or date range). For a query-based hold, validate the query with a
   **statistics/estimate** run in the portal *before* it becomes a hold, so you know it captures responsive
   content. *The query and date range are legal's determination — configured here, not authored here.*
6. **Design the custodian and non-custodial map** *(Premium for custodians)*. List each custodian and their
   data sources (primary mailbox/OneDrive + associated Teams/Groups + additional mailboxes/sites), and the
   **non-custodial** locations (shared mailboxes, departmental sites) to hold separately. Group conceptually as
   `Custodians – Contoso-Matter-001 – Pilot`.
7. **Design the notice cadence** *(Premium communications)*. With legal, fix the four notices —
   `Hold Notice – Contoso-Matter-001 – Issuance` / `– Reminder` / `– Escalation` / `– Release` — and the
   acknowledgment cadence (reminder interval, escalation trigger).

**Pass/fail gate:** a written case/hold/custodian/notice design exists, the preservation scope is chosen
(everything vs a validated query), and every custodian's data sources and every non-custodial location are
named.
**Rollback:** design only — nothing configured yet; discard the design.

---

## Phase 2 — Configure the case hold in the pilot (Configure — preview first)

Build the preservation **floor** — the case hold policy + rule — reviewing the intended change with `-WhatIf`
before committing. This is the mechanism that works at **every** tier (Standard and Premium).

8. **Create the case hold policy** naming the locations, scoped to the **pilot/test** locations only. Preview,
   then commit:
   ```powershell
   .\EDHOLD-Config.ps1 -Action NewCaseHold `
       -CaseName 'Legal Hold Case – Contoso-Matter-001 – Pilot' `
       -HoldPolicyName 'Hold Policy – Contoso-Matter-001 – Pilot' `
       -ExchangeLocation 'testcustodian1@contoso.com' -SharePointLocation 'https://contoso.sharepoint.com/sites/HoldPilot' `
       -WhatIf
   # add -Commit to apply (creates New-CaseHoldPolicy)
   ```
   The helper wraps `New-CaseHoldPolicy -Case <case> -ExchangeLocation ... -SharePointLocation ...`.
9. **Create the case hold rule.** A **preserve-everything** rule holds all content in the policy's locations;
   a **query-based** rule adds legal's `ContentMatchQuery` / date range:
   ```powershell
   .\EDHOLD-Config.ps1 -Action NewCaseHoldRule `
       -HoldPolicyName 'Hold Policy – Contoso-Matter-001 – Pilot' `
       -HoldRuleName 'Hold Rule – Contoso-Matter-001 – Pilot' `
       -ContentMatchQuery '' -WhatIf      # empty query = preserve everything
   # add -Commit to apply (creates New-CaseHoldRule)
   ```
   The helper wraps `New-CaseHoldRule -Name <rule> -Policy <policy> [-ContentMatchQuery <kql>]`.
10. **(Optional) Litigation Hold reinforcement.** For a small matter or a departing custodian, enable a
    mailbox-level hold as belt-and-suspenders — a deliberate, separately-tracked action:
    ```powershell
    .\EDHOLD-Config.ps1 -Action EnableLitigationHold -ExchangeLocation 'testcustodian1@contoso.com' `
        -LitigationHoldDurationDays 3650 -WhatIf      # add -Commit to apply Set-Mailbox -LitigationHoldEnabled $true
    ```

**Pass/fail gate:** the case hold policy + rule exist on the pilot case, scoped to the **test** locations,
with the intended preservation scope (everything vs the validated query); `-WhatIf` output was reviewed before
`-Commit`.
**Rollback:** remove the pilot hold — `Remove-CaseHoldPolicy`/`Remove-CaseHoldRule` in the portal or via the
helper's `-Action RemoveCaseHold -WhatIf` (preview first). Removing a **pilot** hold on test custodians is
safe; **never** remove a hold on a real matter without the release authority's sign-off (Req 2.5).

---

## Phase 3 — Add custodians and issue the hold notice (Configure — Premium)

*(Premium only. On E3/Standard, skip to Phase 4 and operate the notice workflow manually; the case hold from
Phase 2 is your preservation.)* Capture legal's custodian, scope, and notice decisions (Req 2.4) **before**
this phase.

11. **Add custodians and map data sources.** In **Purview portal → eDiscovery (Premium) → the case →
    Data sources / Custodians** (tab name differs between the classic and new unified experience — **verify in
    your tenant**), add each **test** custodian; Purview resolves their primary mailbox/OneDrive and lets you
    attach associated Teams/Groups and additional mailboxes/sites. Placing a custodian **on hold** creates the
    underlying case holds automatically. *Custodian creation is a Graph-eDiscovery / portal action; the
    `EDHOLD-Config.ps1 -Action AddCustodian` path uses the Graph eDiscovery API where licensed and **beta** —
    if unavailable in your tenant, add custodians in the portal.*
12. **Add non-custodial data sources.** Attach the shared mailboxes/departmental sites that belong to no
    custodian as **non-custodial data sources** on the case (portal), so they are held explicitly.
13. **Issue the hold notice** *(portal Communications)*. In the case **Communications**, create
    `Hold Notice – Contoso-Matter-001 – Issuance` from legal's text with an **acknowledgment** requirement,
    and configure the **reminder** (`– Reminder`) and **escalation** (`– Escalation`) on legal's cadence.
    **Issue** it to the test custodians. *Issuing/acknowledging notices is a portal workflow — no cmdlet sends
    a notice; the scripts report status only.*

**Pass/fail gate:** every test custodian is added with mapped data sources and shows **on hold**; non-custodial
locations are held; the issuance notice is issued to the test custodians with reminder/escalation configured.
**Rollback:** remove a **test** custodian / release the pilot notice **in the portal**. On a real matter,
custodian removal or notice release follows the release authority's sign-off (Req 2.5) — it is never scripted.

---

## Phase 4 — Validate the hold and the notice (Validate)

Confirm the preservation is actually effective **before** the program is trusted — distribution succeeded,
every custodian/location is covered, and notices issued and are being acknowledged.

14. **Confirm hold distribution.** Placing a hold runs on service timers; **distribution status** can take
    minutes to hours (longer for many locations) to reach **Success** — do not judge a hold in its first
    minutes. Validate with the delivered script (read-only):
    ```powershell
    .\EDHOLD-Validate.ps1 -CaseName 'Legal Hold Case – Contoso-Matter-001 – Pilot' `
        -ExpectedExchangeLocation 'testcustodian1@contoso.com' -Verbose
    ```
    It reports per-gate pass/fail: hold **distribution = Success** across locations, expected custodians/
    locations in scope, Litigation Hold state (where used), and (via Graph, where exposed) notice/acknowledgment
    signal.
15. **Prove preservation.** With fabricated content, confirm a **hard-deleted** item on a held test mailbox is
    recoverable (moves to the preservation/Recoverable Items location) — the hold prevents **permanent purge**;
    it does not lock the item read-only. Record the evidence.
16. **Confirm acknowledgment tracking** *(Premium)*. In **Communications**, confirm each test custodian's
    acknowledgment status is tracked (acknowledged / not yet / reminded / escalated) and that a non-responder
    is reminded/escalated per cadence.

**Pass/fail gate:** distribution = **Success** on all pilot locations, every expected custodian/location is
covered, deleted held content is recoverable, and (Premium) notices issued with acknowledgment tracked — all
against explicit pass/fail gates (Section 5).
**Rollback:** none (read-only validation); if a gate fails, fix the scope/config in Phase 2/3 and re-validate —
do **not** proceed to real matters on a failed gate.

---

## Phase 5 — Track, then expand to live matters (Operate → Expand)

17. **Produce the hold register.** Export the defensible tracking record (read-only):
    ```powershell
    .\EDHOLD-Report.ps1 -CaseName 'Legal Hold Case – Contoso-Matter-001 – Pilot' `
        -CsvPath '.\Custodian Hold Register – Contoso-Matter-001 – Report.csv'
    ```
    It produces `Custodian Hold Register – Contoso-Matter-001 – Report` — custodians, data sources, hold/
    distribution status, and (where exposed) notice/acknowledgment status and dates — the record legal relies
    on.
18. **Maintain scope on change.** As a custodian's role or data sources change, adjust **hold locations /
    custodian data sources** with the scope helper (preview first) — it **adds/adjusts**, it never releases:
    ```powershell
    .\EDHOLD-Set-Scope.ps1 -HoldPolicyName 'Hold Policy – Contoso-Matter-001 – Pilot' `
        -AddExchangeLocation 'testcustodian2@contoso.com' -WhatIf   # add -Commit to apply
    ```
19. **Expand to the live practice.** Once the pilot gates pass, mint the **production** equivalents for real
    matters by swapping the `– Pilot` stage for the real matter name (e.g.
    `Legal Hold Case – <RealMatter> – Live`, `Hold Policy – <RealMatter> – Live`) — **never** edit a validated
    pilot artifact in place, and **never** reuse the pilot case for a real matter. Each real-matter hold goes
    through change control (Req 2.5) with the register updated.
20. **Release deliberately (portal + sign-off only).** When the **release authority** authorizes it in
    writing, release the custodian / remove the hold **in the portal**, issue the
    `Hold Notice – <Matter> – Release`, and record the release in the register. **No script in this pack
    releases a hold** — release is a two-party, signed, non-automated action. Confirm no *other* matter still
    requires the same location before releasing (overlapping holds).

**Pass/fail gate:** the hold register is exported and current; scope changes are additive and tracked; real
matters use production naming under change control; releases are signed, evidenced, and never scripted.
**Rollback:** a mis-scoped **addition** can be reverted (remove the added location, preview first); a
**release** cannot be undone for content purged afterward — which is exactly why it is gated behind sign-off,
not automation.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline cases/holds/roles, confirm licensing tier | Posture CSV | Baseline + tier confirmed | n/a (read-only) |
| 1 Design | Create pilot case; design hold scope, custodian/notice map (from legal) | Pilot case + written design | Case + design complete | Discard design |
| 2 Configure | Build case hold policy + rule (preview → commit); optional Lit Hold | Hold policy + rule | Hold scoped to test locations | Remove pilot hold (preview) |
| 3 Configure (Premium) | Add test custodians + non-custodial sources; issue notice (portal) | Custodians, notices | Custodians on hold, notice issued | Remove test custodian / release pilot notice (portal) |
| 4 Validate | Confirm distribution=Success, coverage, preservation, acknowledgment | Validation report | All gates pass | Fix + re-validate (never proceed on fail) |
| 5 Operate → Expand | Export register, maintain scope, go live on real matters, release by sign-off | Hold register | Register current; releases signed, never scripted | Revert additions; release is not reversible → gated by sign-off |
