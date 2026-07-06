# 3. Implementation Guide — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Follow these steps **in order**, working in **Google Vault** (`vault.google.com`) and the **Google
Admin console** (`admin.google.com`) on the Workspace side, and the **Microsoft Purview portal**
(`purview.microsoft.com`) on the Microsoft side.

> **Model:** Establish what's governed where **first**, then configure Vault retention and holds
> inside named matters, mirror each to a parallel Purview eDiscovery case/hold, define the discovery
> workflow across both, validate on a small pilot custodian scope, and only then expand. Vault and
> Purview **do not sync** — holds are issued in parallel.

> **Not legal advice.** Retention *periods*, hold *triggers*, and what "defensible" requires for a
> given matter are **legal/records-counsel determinations**. Configure to the counsel-approved
> schedule and hold list; do not invent periods or scope.

> **Verify in your tenant.** Vault's **Gemini-app** hold/retention support and the evolving Purview
> **eDiscovery** experience change over time; the paths below reflect current public documentation —
> confirm exact toggles for your editions and defer volatile specifics to the vendors' documentation.

Name every object exactly as shown, in the form `<Purpose> – <Scope> – <Stage>`, and use the **same
matter/case name on both platforms** — verbatim across scripts, holds, and reports.

## Step 1 — Inventory what's governed where (read-only)
1. Run `GWVAULT-Discovery.ps1` to enumerate the Google-side governance state: existing Vault
   **matters**, **holds**, and **retention rules** (default + custom), and the apps each covers
   (Gmail, Drive, Chat, Meet, Groups, Calendar, Voice, Sites, and the Gemini app where available).
2. Run `GWVAULT-Report.ps1` to produce the coverage/gap summary — which custodians and record classes
   are held/retained in Vault, and which require a matching Purview hold.
3. In the **Purview portal → eDiscovery → Cases**, note existing cases and **Hold policies**; in
   **Solutions → Data Lifecycle Management / Records management**, note retention policies/labels.
4. Record the custodians who have data on **both** sides (the migration overlap) as the parallel-hold
   worklist. **Do not release or narrow any existing hold.**

## Step 2 — Create the matter and case (matched names)
1. In **Vault → Matters → Create**, create the matter using the agreed name, e.g.
   `Litigation – Acme v. Example – Hold`. Reuse an existing matter if the legal matter already has one.
2. In the **Purview portal → eDiscovery → Cases → Create case**, create a case with the **same name**.
3. Record both identifiers against the one legal matter so the Vault matter and the Purview case are
   unmistakably the same matter (this is what makes the parallel hold auditable).

## Step 3 — Configure Google Vault retention (to the approved schedule)
1. In **Vault → Retention**, set/confirm **Default retention rules** and, where a record class needs a
   different period, **Custom retention rules** — scoped to the relevant service (Gmail, Drive, Chat,
   Meet, Groups, Voice, Sites, and the Gemini app where available) and OU, to the **counsel-approved**
   schedule.
2. Where the same record class also lives in M365, set the Vault period to the **longer** of the Vault
   and Purview schedules so neither side purges a record the other must keep.
3. Heed Vault's warning: modifying/deleting retention rules can allow services to **purge** data users
   expect to keep — change retention only under change control with counsel sign-off.
4. Remember the precedence: in Vault, a **hold** retains data **indefinitely** and **takes precedence**
   over default and custom retention rules. (Source: Google Vault Help.)

## Step 4 — Place the Google Vault legal hold (inside the matter)
1. In **Vault → Matters →** *(your matter)* **→ Holds → Create hold**. Name the hold with the matter
   convention (e.g. `Litigation – Acme v. Example – Hold`).
2. Choose the **service** to hold (e.g. Gmail, Drive, Chat, Groups, Voice, Sites, Meet, and the Gemini
   app where available) and the **accounts or an OU** to preserve — the pilot custodians in this pass.
3. Save the hold. Vault holds preserve data indefinitely regardless of retention rules or user
   deletion — confirm each in-scope service and custodian is covered.

## Step 5 — Mirror the hold in Microsoft Purview (parallel hold)
1. In the **Purview portal → eDiscovery → Cases →** *(the matched case)* **→ Hold policies →
   Create policy**. Give it the matched name and a description.
2. On **Manage data sources**, add the **same custodians** and the workloads they touch on the M365
   side: **Exchange mailboxes** (also preserves Teams 1:1/group chat, card, and meeting/call data
   stored in the mailbox) and **SharePoint sites / OneDrive accounts** (also preserves Teams channel
   files). For a **Team / Microsoft 365 group**, add the group's mailbox **and** SharePoint site — and
   add members' own mailboxes/OneDrive if their individual data is in scope (group membership is a
   point-in-time snapshot at hold creation).
3. Choose the hold scope: an **infinite** hold on all content, or a **query-based** hold (condition
   builder or KeyQL) with an optional date range, per counsel's instruction.
4. Select **Apply hold**. Allow up to **24 hours** for the hold to take effect. Confirm on the hold's
   **Details** tab that each location shows **on hold**.
5. Record the Purview hold policy against the same matter as the Vault hold — the custodian is now held
   on **both** ecosystems.

## Step 6 — Configure Microsoft Purview retention (align to the longer schedule)
1. In the **Purview portal → Data Lifecycle Management / Records management → Retention policies (and
   labels)**, set/confirm retention for the M365 workloads (Exchange, SharePoint, OneDrive, Teams) to
   the **counsel-approved** schedule.
2. Where a record class also lives in Workspace, set the Purview period to the **longer** of the two so
   it matches the Vault side. Remember most-restrictive-wins: eDiscovery holds, retention policies/
   labels, Litigation Hold, delay holds, and Single Item Recovery each independently preserve content.
3. Do **not** rely on retention to preserve for an active matter — the **hold** is the preservation
   instrument; retention governs the ongoing schedule.

## Step 7 — Define the cross-system discovery workflow
1. **Search each side by the matched matter/case:** in **Vault → Matters →** *(matter)* **→ Search**,
   scope by custodian/service/date; in **Purview → eDiscovery → Cases →** *(case)*, build the matching
   search (condition builder / KeyQL) across the M365 data sources.
2. **Export from each side:** run the Vault export and the Purview export for the same scope.
3. **Reconcile into one production:** assemble the two export sets into a single, de-duplicated
   production under counsel's direction, so content in the coexistence overlap is neither missed nor
   double-counted. Document the reconciliation so the collection is defensible.

## Step 8 — Validate the pilot
1. Run `GWVAULT-Validation.ps1` for the pilot scope: confirms, per custodian, that a Vault hold exists
   in the matter across the in-scope services, that Vault retention matches the approved schedule, and
   flags the Purview-side hold/retention to confirm in the portal.
2. Run `GWVAULT-Report.ps1` to confirm coverage: every pilot custodian is held on **both** sides and no
   in-scope record class is unretained.
3. Perform the **discovery probe** in the Testing Guide: run the matched search on both platforms for a
   known pilot item and confirm it is returned and exportable from the correct side(s). Confirm the
   Purview hold shows **on hold** (allow 24h) and Vault preservation is effective. Complete the pilot
   gate with legal/eDiscovery sign-off.

## Step 9 — Expand to all custodians
1. Only after the pilot passes: extend the matched matter/case holds to the remaining custodians in
   controlled waves, keeping Vault and Purview in parallel for each.
2. Re-run `GWVAULT-Report.ps1` after each wave to confirm both-sides coverage and no gaps.
3. Stand up recurring **coverage reviews** — re-run `GWVAULT-Discovery.ps1` on a schedule and reconcile
   Vault matters against Purview cases so a migrating custodian never falls out of hold on one side.

---
### Order of operations
`Inventory what's governed where → Matter + matched case → Vault retention → Vault hold → Purview
parallel hold → Purview retention (longer-of-two) → Cross-system discovery workflow → Validate
(pilot) → Expand`
