# 3. Implementation Guide — Microsoft 365 Purview eDiscovery Administration

Follow the deployment model **Assess → Design → Configure → Pilot → Validate → Expand**. Every
artifact is **named** with the convention `<Purpose> – <Scope> – <Stage>` and the **same name is
reused** in testing, troubleshooting, and the scripts. Run the whole flow on the **pilot matter
`Matter-A`** first; only after the validation gates pass do you apply the pattern to a live matter.

Portal: `https://purview.microsoft.com` → **eDiscovery** (Government clouds use a different host,
e.g. `*.office365.us` — **verify in your tenant**). PowerShell: `Connect-IPPSSession` (Security &
Compliance) for Content Search/Standard; **Microsoft.Graph.Security** for Premium.

> **Legal owns the determination** of scope, custodians, holds, and production. The steps below are
> the technical method; do not place a live hold or export without the legal sign-off from
> Requirement 2.5.

---

## Stage A — Assess (read-only, no changes)
1. **Confirm tier, roles, and audit.** Run **`MSEDISC-Discovery.ps1`**. It reports eDiscovery role-
   group membership, existing cases/searches/holds, and whether audit is on. Confirm you have
   **eDiscovery Manager/Administrator** (Requirement 2.2) and know whether the tenant has **Premium**
   (Requirement 2.1). Resolve any gap before continuing.
2. **Record the in-scope workloads** per custodian from Requirement 2.4 (Exchange mailbox, OneDrive
   URL, SharePoint sites, Teams membership). Remember Teams **messages** are collected via the
   custodian's **mailbox** and Teams **files** via **SharePoint/OneDrive**.

**Gate A (pass/fail):** roles present, audit on, tier known, in-scope workloads mapped. Fail → stop
and fix (Requirements 2.1–2.4).

---

## Stage B — Design (on paper)
3. **Name the matter and artifacts.** For the pilot use:
   - Case: `eDiscovery Case – Matter-A – Pilot`
   - Search: `Content Search – Matter-A-Keywords – Pilot`
   - Hold policy / rule: `Hold Policy – Matter-A – Pilot` / `Hold Rule – Matter-A – Pilot`
   - (Premium) Custodian: `Custodian – <pilotUPN> – Matter-A`; Review set: `Review Set – Matter-A –
     Pilot`; Export: `Export – Matter-A – Pilot`.
4. **Design the query (KQL + conditions).** With legal's keywords, draft a **KQL** query for
   `ContentMatchQuery`, for example:
   `(subject:"Project Falcon" OR body:"Project Falcon") AND (received>=2024-01-01 AND received<=2024-12-31)`.
   Prefer explicit **conditions** (date range, participants, `kind:`/`filetype:`, sensitive-info
   type) over broad free-text. Keep the first pass **narrow** — you widen only if it under-collects.

**Gate B:** named artifacts and a written, scoped KQL query approved by legal. Fail → refine.

---

## Stage C — Configure scope & boundaries (once per tenant)
5. **(Optional) Compliance boundary.** If Requirement 2.8 requires scoping which population an
   eDiscovery team may search, create a **compliance security filter** with **`MSEDISC-Scope.ps1`**
   (dry-run by default; `-Apply` to commit). It wraps `New-ComplianceSecurityFilter` — the *policy*
   (who may search whom) is legal/HR's determination; the script only implements it. Skip if not
   required.

**Gate C:** boundary filters exist and validate (or are explicitly out of scope). Fail → fix filter
definition.

---

## Stage D — Configure & run the pilot matter

### Content Search / Standard (Security & Compliance PowerShell or portal)
6. **Create the case.** Portal: **eDiscovery → Cases → Create a case** named
   `eDiscovery Case – Matter-A – Pilot`. PowerShell (Standard):
   `New-ComplianceCase -Name "eDiscovery Case – Matter-A – Pilot" -CaseType eDiscovery`.
7. **Build the search.** Use **`MSEDISC-Search.ps1`** — **dry-run by default**; it echoes the
   `New-ComplianceSearch`/`Start-ComplianceSearch` it *would* run and only creates/starts when you
   pass `-Apply`. It creates `Content Search – Matter-A-Keywords – Pilot` scoped to the in-scope
   locations (`-ExchangeLocation`, `-SharePointLocation`, or `All` for an estimate) with your
   `-ContentMatchQuery` KQL, then starts it. Portal equivalent: inside the case, **Searches → New
   search**, add locations + query.
8. **Review the statistics and refine.** Run **`MSEDISC-Report.ps1`** (or portal **search →
   Statistics**) to read item count, size, and locations with hits for `Content Search –
   Matter-A-Keywords – Pilot`. **Preview** a sample (`New-ComplianceSearchAction -Preview`). If the
   query over- or under-collects, refine the KQL (Step 4) and re-run **`MSEDISC-Search.ps1 -Apply`**.
   Iterate until scope is right — the search **name stays the same**.
9. **Place the hold (Standard).** Once legal confirms preservation, create a **case hold** with
   **`MSEDISC-CaseHold.ps1`** (dry-run by default; `-Apply` to commit). It creates
   `Hold Policy – Matter-A – Pilot` (`New-CaseHoldPolicy` over the custodian mailboxes/sites) and
   `Hold Rule – Matter-A – Pilot` (`New-CaseHoldRule`, optionally query-based). Portal equivalent:
   case → **Holds → Create**.

### eDiscovery (Premium) — custodians, review set, analytics, export (E5)
> Premium steps use the **new eDiscovery** UI and the **Microsoft.Graph.Security** cmdlets; exact
> parameters are version-dependent — **verify in your tenant**. `MSEDISC-Report.ps1` reports Premium
> case/hold/export status where the Graph module is available.
10. **Add custodians.** In the Premium case, **Data sources → Custodians → Add** each custodian
    (`Custodian – <pilotUPN> – Matter-A`), selecting their mailbox, OneDrive, SharePoint, and Teams.
    Placing a **custodian hold** here preserves their content. (Graph:
    `New-MgSecurityCaseEdiscoveryCaseCustodian` — verify parameters.)
11. **Collect into a review set.** Create a **collection/search**, estimate, then **commit/add to a
    review set** named `Review Set – Matter-A – Pilot`. This copies matching content into a static,
    reviewable set.
12. **Run analytics / de-duplication.** On the review set, run **Analytics** — email **threading**,
    **near-duplicate** detection, **themes** — and enable **de-duplication** so only unique items
    reach review. This is where review volume (and cost) drops.
13. **Review, tag, redact.** Reviewers apply tags (responsive/privileged) and redactions in the
    review set. **Legal makes responsiveness/privilege calls; you operate the tooling.**
14. **Export defensibly.** From the review set, **Export** `Export – Matter-A – Pilot` with the
    chosen options (native/redacted, metadata **load file**, item report). Download and record the
    export report as evidence. (Standard/Content Search export equivalent:
    `New-ComplianceSearchAction -SearchName "Content Search – Matter-A-Keywords – Pilot" -Export`.)

**Gate D (the core pilot gate):** case created; search scoped and previewed; hold **effective**
(preserving); (Premium) review set collected, analytics run, export **complete with a load file and
report**. Fail any → do not proceed to a live matter.

---

## Stage E — Validate
15. Run the **testing procedures in `05-testing.md`** against the pilot matter, and
    **`MSEDISC-Report.ps1`** for the evidence pack (search stats, hold status, export report). All
    gates must pass.

**Gate E:** every test in Section 5 passes; the audit log shows the case, search, hold, and export
activity. Fail → remediate before expanding.

---

## Stage F — Expand
16. **Apply the pattern to live matters.** For each real matter, repeat Stages B–E with the matter's
    real name (e.g. `eDiscovery Case – Matter-B – Prod`), legal-approved scope, and legal sign-off
    for holds/exports. Never skip the pilot gate for a new *type* of matter (new workload, cross-
    region custodians, very large collection).

---

## Rollback (documented before you place a live hold or export)
- **Remove a hold:** delete `Hold Rule – Matter-A – Pilot` then `Hold Policy – Matter-A – Pilot`
  (portal: case → Holds → remove; PowerShell `Remove-CaseHoldRule` / `Remove-CaseHoldPolicy`).
  Preservation stops going forward; content already preserved is released per its retention.
  **Do not remove a hold on a live matter without legal approval** — it may destroy preservation.
- **Undo a search/collection:** searches are non-destructive; delete the search
  (`Remove-ComplianceSearch`) or the review set/collection to discard.
- **Undo an export:** delete the export job and the downloaded package; the source content is
  unchanged.
- **Compliance filter:** `Remove-ComplianceSecurityFilter` to revert a boundary change.
