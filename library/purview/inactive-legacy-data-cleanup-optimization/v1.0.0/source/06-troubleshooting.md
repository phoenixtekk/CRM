# 6. Troubleshooting — Inactive & Legacy Data Cleanup & Storage Optimization (Microsoft Purview)

Symptom-first fixes for the failures you actually hit identifying ROT and cleaning up inactive/legacy data with
Purview Data Lifecycle Management. Most problems are one of: nothing happens (latency), the wrong content is
targeted, held content is unexpectedly in scope, an adaptive scope mis-selects, a label/policy won't apply, or a
report comes back empty. **Remember the golden rule:** if a hold check is failing or uncertain, **stop and do
not enforce deletion** — troubleshoot before, not after, content is removed.

---

## Nothing seems to happen

**I applied a delete policy/label and nothing was deleted.**
- **This is usually latency, not failure.** Retention label application, the deletion timer, and disposition
  processing run on **Microsoft's cadence**, not instantly — policies can take time to reach all locations and
  the timer runs periodically. Allow dwell time before concluding it is broken.
- Confirm the policy is **Enabled** — the config helper deliberately creates the pilot policy **disabled**
  (`Enabled=$false`) so you validate holds first. It does nothing until you enable it under change control.
- Confirm the content is actually **past the retention period** — a "delete after 2555 days" rule does nothing
  to content that is younger.
- **A hold is (correctly) blocking the purge.** If the content is under any hold, the delete action will **not**
  remove it — that is the platform protecting held data (see below). Check with `DLCCLEAN-Validate.ps1`.

**Auto-apply simulation shows matches but no labels were applied.**
- That is **correct** — simulation shows what *would* be labeled with nothing applied. To apply, switch the
  auto-apply policy from **simulation** to **on** for the pilot scope (Implementation Phase 4).

## Wrong content targeted / too much in scope

**The policy is scoped to "All" / tenant-wide when I wanted a pilot.**
- `DLCCLEAN-Validate.ps1` **Gate 1** flags this. Narrow the scope with `DLCCLEAN-Set-Scope.ps1`
  (`-RemoveLocation`, add a named site/mailbox, or bind an adaptive scope). The config and set-scope helpers
  **refuse to add "All"** by design.
- Never pilot a delete action on "All" — the whole discipline is a **limited scope first**.

**An adaptive scope is selecting live/active objects, not just stale ones.**
- The adaptive query is matching on **attributes that are wrong or unpopulated** (Req 2.6). Inspect what the
  scope resolves to **before** binding a delete policy to it, and **refresh the attribute data**. A query over
  bad attributes mis-targets — fix the attributes, not the policy.
- Prefer a **static** named scope for the pilot; move to adaptive only once membership is proven accurate.

**Content I expected to be cleaned up is being kept instead.**
- **Retention precedence:** *retain wins over delete*, and the *longest* retention wins. Another retain
  label/policy (or a hold) in scope is keeping it. `DLCCLEAN-Validate.ps1` Gate 3 lists the overlapping
  retain policies/holds. This is by design — resolve it with the records function, don't force-delete.

## Held content is unexpectedly in scope (the safety gate)

**`DLCCLEAN-Validate.ps1` Gate 3 (hold cross-check) reports FAIL / overlaps.**
- **Do not enforce.** An in-scope location overlaps a litigation hold, an eDiscovery case hold, or a retain
  policy. Either **exclude** those locations from the cleanup scope (`DLCCLEAN-Set-Scope.ps1 -RemoveLocation`)
  or **resolve the hold** with legal/eDiscovery — then re-run Validate until Gate 3 is **PASS**.
- The platform will still block the purge of held items, but the point is to **prove** it before acting — a
  clean cross-check is your defensibility evidence.

**The hold inventory looks incomplete.**
- Litigation-hold enumeration needs **Exchange Online** connected (`Connect-ExchangeOnline`) — if it is not,
  `DLCCLEAN-Discovery.ps1` / `-Validate.ps1` say so and skip that class. Connect it for a complete check.
- eDiscovery **case holds** need `Get-CaseHoldPolicy` (Records/eDiscovery role). Confirm your role and re-run.
- If any hold state is **uncertain**, treat it as held and **stop** until legal confirms (Req 2.4).

## Labels / policies won't create or apply

**Adaptive scope / auto-apply / disposition review isn't available in the portal.**
- These are **E5 / E5 Compliance** (or Records Management) capabilities and some are **preview** — **verify
  your licensing/tenant** (Req 2.1). On **E3** you have manual labels + static-scope retention only; plan the
  first wave accordingly.

**`New-RetentionCompliancePolicy` / `New-ComplianceTag` fails or the cmdlet isn't recognized.**
- Ensure the **ExchangeOnlineManagement** module is installed/updated and you connected with
  **`Connect-IPPSSession`** (Security & Compliance PowerShell), not plain Exchange Online.
- Confirm the account holds the required **Records Management / Compliance Administrator** role — a missing role
  surfaces as "cmdlet not recognized" or access denied (Req 2.2).

**A retention label won't apply to content even though it's published.**
- **Publishing latency** — a newly published label can take time to appear where users/policies can apply it.
- Confirm the **label policy scope** includes the location you are testing, and that the label's action/period
  is what you intend.

## Reports / discovery come back empty

**`DLCCLEAN-Report.ps1` returns no stale candidates.**
- **Graph usage reports** need `Reports.Read.All` — connect with
  `Connect-MgGraph -Scopes 'Reports.Read.All'` and re-run.
- **Reports may be de-identified.** If tenant privacy settings **conceal user/site names** in usage reports,
  the identity columns come back anonymized — toggle the setting in the M365 admin center (reports privacy) if
  you need named candidates, under your privacy policy.
- Widen `-StaleDays` — if the window is too short nothing qualifies as stale.

**`Get-Mailbox -InactiveMailboxOnly` returns nothing.**
- There may genuinely be **no inactive mailboxes** (an inactive mailbox exists only when a mailbox was placed
  on hold and *then* the user was deleted). Confirm with the messaging team.
- Confirm **Exchange Online** is connected and your account can read recipients (Req 2.2).

## Something changed unexpectedly

**A script made a change I didn't expect.**
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`, and **none
  permanently deletes content**. The config helper creates pilot policies **disabled**; the set-scope helper
  changes **scope only** (never the action or enabled state). If a change landed, it was an explicit `-Commit`.
- The safe recovery is always to **disable / narrow the policy** (`DLCCLEAN-Set-Scope.ps1`) and **re-validate**
  — nothing is deleted until an enabled policy's timer runs on unheld, past-retention content.

---

### Fast triage table

| Symptom | First check |
|---|---|
| Nothing deleted | Latency (Microsoft timer); policy still **disabled**; content not past retention; a hold is blocking (correct) |
| Simulation matched but no labels applied | Auto-apply still in **simulation** — that's expected; turn on for pilot |
| Scope is "All" | Validate Gate 1 — narrow with Set-Scope; tools refuse to add "All" |
| Adaptive scope mis-selects | Wrong/unpopulated attributes — inspect resolved members, refresh attributes, prefer static for pilot |
| Expected-cleanup content kept | Retention precedence — a retain label/policy or hold wins (Validate Gate 3) |
| Hold cross-check FAIL | **Do not enforce** — exclude the held locations or resolve the hold, re-validate to PASS |
| Hold inventory incomplete | Connect Exchange Online (litigation) + Records/eDiscovery role (case holds) |
| Adaptive/auto-apply/disposition missing | E5 / E5 Compliance licensing — verify tenant |
| Cmdlet not recognized / denied | ExchangeOnlineManagement updated, `Connect-IPPSSession`, Records/Compliance role |
| Label won't apply | Publishing latency; label-policy scope; label action/period |
| Report empty | Graph `Reports.Read.All`; reports de-identified in tenant privacy; widen `-StaleDays` |
| No inactive mailboxes | May be none (hold-then-delete only); Exchange connected + recipient-read role |
| Unexpected change | Scripts are `-WhatIf`/read-only by default; none deletes; recover by disabling/narrowing + re-validate |
