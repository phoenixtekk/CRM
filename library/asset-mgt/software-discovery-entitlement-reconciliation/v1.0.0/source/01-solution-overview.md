# 1. Solution Overview — Software Discovery & Entitlement Reconciliation

## What this solution is
Software discovery and entitlement reconciliation is the core of Software Asset Management (SAM): it
takes the raw list of what is installed across your estate, cleans that list into a controlled SKU
vocabulary, and matches it against what you have actually purchased. The output is your effective
license position — where you are over-deployed (compliance risk), where you are under-deployed
(reharvesting and savings opportunity), and which installs cannot be explained (exceptions).

This is a repeatable method that is source-agnostic: it works whether your installed-software data
comes from Microsoft Configuration Manager (SCCM), Microsoft Intune detected apps, or a dedicated
discovery tool such as Flexera. The pipeline normalizes all sources into the same SKU vocabulary, so
the reconciliation logic stays identical regardless of where the inventory originated.

## The named artifacts
This solution produces and reuses a fixed set of named artifacts. Every step references them by name,
and the scripts read and write them. Each name follows the pattern `<Purpose> – <Scope> – <Stage>`:

- `Installed-Software Inventory – All Sources – Discovery` — the merged raw extract of installed
  software from every in-scope discovery source (Configuration Manager, Intune, Flexera export).
- `Normalization Map – SKU Vocabulary – Configure` — the lookup that translates raw publisher,
  title, edition, and version strings into a single canonical SKU.
- `Entitlement Register – Systems of Record – Configure` — the authoritative count of purchased
  entitlements per SKU, sourced from the entitlement system of record (Global Requirement G3).
- `Reconciliation Ledger – SKU vs Entitlement – Validate` — the matched output: installed quantity
  per SKU versus entitled quantity per SKU, with the resulting position.
- `Exception Register – Unmatched & Edge Cases – Validate` — every install that did not map to a SKU,
  or mapped to a SKU with no entitlement, routed for a decision.
- `Discovery Scope Group – Pilot Source – Pilot` — the targeting group (one source / one product
  family) that bounds the pilot before expansion.

## How the pipeline works
1. Discovery sources are queried for installed software and merged into the
   `Installed-Software Inventory – All Sources – Discovery`. Configuration Manager supplies its
   software inventory and Asset Intelligence data; Intune supplies its detected apps list; Flexera
   supplies a normalized installed-software export from its own console.
2. The raw rows are run through the `Normalization Map – SKU Vocabulary – Configure`, which collapses
   the many ways one product appears (different publisher spellings, edition suffixes, version and
   patch levels) into one canonical SKU.
3. Normalized installs are aggregated per SKU and matched against the
   `Entitlement Register – Systems of Record – Configure` to build the
   `Reconciliation Ledger – SKU vs Entitlement – Validate`.
4. Anything that cannot be matched — an install whose title resolves to no SKU, or a SKU with installs
   but no entitlement — is written to the `Exception Register – Unmatched & Edge Cases – Validate`
   for a SAM analyst decision (add a normalization rule, record a missing entitlement, or flag a true
   compliance gap).
5. The ledger and exception register drive action: true-up where over-deployed, reharvest where
   under-deployed, and resolve exceptions so the next run is cleaner.

## Why discovery sources differ (and why normalization matters)
Each source describes the same installed product differently. Configuration Manager reports from
installed-product inventory and Asset Intelligence; Intune reports a detected-apps list keyed on
display name, publisher, and version; Flexera applies its own Technopedia-based recognition before
export. Left raw, the same product appears as many distinct rows and cannot be counted. Normalization
to a single SKU vocabulary is what makes counting — and therefore reconciliation — possible.

## What you can control
- Which discovery sources are in scope and how they are merged.
- The normalization rules that map titles, editions, and versions to SKUs.
- The entitlement counts the position is measured against.
- How exceptions are triaged and who owns each decision.
- The pilot scope (one source or one product family) before fleet-wide reconciliation.

## Benefits
- Compliance — a defensible, reproducible license position for audits and true-ups.
- Savings — under-deployment surfaced for reharvesting and renewal right-sizing.
- Trust — a single SKU vocabulary so every source counts consistently.
- Auditability — every unmatched install is captured and decided, not silently dropped.
- Repeatability — the same pipeline runs each cycle and on any source.

## Limitations (be honest with buyers)
- This solution reconciles installed-software discovery to entitlements; it does not measure SaaS
  user-based consumption (that is a separate discipline).
- Normalization quality depends on the rules you maintain; a new product family needs a new rule.
- Flexera-specific configuration (connectors, inventory beacons, Technopedia, the export itself) is a
  vendor product and is deferred to Flexera's own documentation — this solution consumes its export.
- Metric-based licensing (per-core, per-processor, per-user with downgrade rights) requires the
  entitlement register to record the metric; the pipeline reconciles counts against the metric you
  record, it does not infer entitlement rules.

## The standard deployment model
> Confirm a discovery source and an entitlement register → build the normalization map and import
> entitlements → pilot on one source / one product family → validate the reconciliation and
> exceptions → expand to all sources. Pattern: **Assess → Configure → Pilot → Validate → Expand.**
