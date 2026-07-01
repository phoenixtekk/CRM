# 3. Implementation Guide — Software Discovery & Entitlement Reconciliation

Follow these steps **in order**. Steps run partly in your discovery consoles (Configuration Manager,
the Microsoft Intune admin center at `https://intune.microsoft.com`, or the Flexera console) and
partly with the supplied scripts. Do this — the reasoning lives in the Solution Overview.

> **Model:** Pilot on one source / one product family, validate the reconciliation, then expand to all
> sources. The artifacts you build are reused verbatim every cycle.

## Step 1 — Define the pilot scope
1. Choose one discovery source (or one product family within it) as the
   `Discovery Scope Group – Pilot Source – Pilot`.
2. Build the scope targeting with `SWDISC-Set-ScopeTargeting.ps1` (creates/confirms the pilot scope
   group for the chosen source/product family). Record the data owner.

## Step 2 — Confirm inventory is enabled on the pilot source
1. Configuration Manager: open `Administration > Client Settings`, confirm `Software Inventory` and
   `Hardware Inventory` (with Asset Intelligence reporting classes) are enabled for the scoped
   collection.
2. Intune: open `Apps > Monitor > Discovered apps` and confirm the detected-apps list is populated for
   the scoped devices.
3. Flexera: confirm inventory is flowing in the Flexera console. Flexera-specific configuration
   (beacons, connectors, Technopedia recognition) is deferred to Flexera's documentation.

## Step 3 — Export the installed-software data
1. Run `SWDISC-Discovery.ps1` against the pilot source to produce the
   `Installed-Software Inventory – All Sources – Discovery` (read-only).
   - For Intune, the script reads detected apps via Microsoft Graph.
   - For Configuration Manager, the script reads software inventory via the Get-CM cmdlets / the SMS
     Provider WMI namespace.
   - For Flexera, place the installed-software export produced from the Flexera console where the
     script expects it (the script consumes the export; it does not call a Flexera API).
2. Confirm the inventory file contains publisher, title, edition/version, and device columns.

## Step 4 — Build or update the normalization map
1. Open the `Normalization Map – SKU Vocabulary – Configure` (a controlled lookup table).
2. For each distinct raw publisher/title/edition/version in the inventory, add or confirm a rule that
   resolves it to one canonical SKU (collapse edition suffixes and version/patch levels into the SKU
   you license against).
3. Run `SWDISC-Validation.ps1` to confirm every raw row in the pilot inventory resolves to a SKU; rows
   that do not resolve are reported so you can add rules.

## Step 5 — Import the entitlement register
1. From the entitlement system of record (Global Requirement G3), build the
   `Entitlement Register – Systems of Record – Configure`: one row per SKU with the entitled quantity
   and the licensing metric.
2. Confirm the register's SKUs use the **same** canonical SKU vocabulary as the normalization map (so
   they join cleanly).

## Step 6 — Reconcile and produce the position
1. Run `SWDISC-Report.ps1` to aggregate normalized installs per SKU and match them against the
   `Entitlement Register – Systems of Record – Configure`, producing the
   `Reconciliation Ledger – SKU vs Entitlement – Validate` (read-only).
2. The ledger shows, per SKU: installed quantity, entitled quantity, and the position
   (over-deployed / under-deployed / balanced).

## Step 7 — Route exceptions
1. `SWDISC-Report.ps1` also writes the `Exception Register – Unmatched & Edge Cases – Validate`:
   installs that resolved to no SKU, and SKUs with installs but no entitlement.
2. For each exception, take the SAM analyst decision: add a normalization rule (Step 4), record a
   missing entitlement (Step 5), or flag a true compliance gap for procurement.
3. Re-run `SWDISC-Report.ps1` after resolving exceptions so the ledger reflects the decisions.

## Step 8 — Remediate mapping gaps safely
1. Run `SWDISC-Remediation.ps1` to apply queued normalization-map fixes (e.g. add pending alias rules
   for unmatched titles). It defaults to `-WhatIf` and only previews changes.
2. Review the preview, then re-run with `-WhatIf:$false` to commit the map updates. Re-run
   `SWDISC-Validation.ps1` to confirm the previously unmatched rows now resolve.

## Step 9 — Validate the pilot
1. `SWDISC-Validation.ps1` confirms all pilot rows normalize to SKUs.
2. `SWDISC-Report.ps1` confirms a clean ledger and a triaged exception register for the pilot SKUs.
3. Complete the Testing Guide and confirm the pilot pass gate before expanding.

## Step 10 — Expand to all sources
1. Add the remaining discovery sources to the
   `Installed-Software Inventory – All Sources – Discovery` (re-run `SWDISC-Discovery.ps1` per source
   and merge).
2. Extend the normalization map for products that only appear in the added sources (Step 4).
3. Re-run `SWDISC-Report.ps1` for the full scope; reconcile and triage exceptions each cycle.

---
### Order of operations
`Pilot scope → confirm inventory → export discovery → normalization map → import entitlements →
reconcile → route exceptions → remediate map gaps → validate pilot → expand to all sources`
