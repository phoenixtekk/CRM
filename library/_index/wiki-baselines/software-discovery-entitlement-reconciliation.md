# Software Discovery & Entitlement Reconciliation (SCCM / Intune / Flexera)

> **Version 1.0.0** · Category: Asset Mgt · Solution code: SWDISC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Software Discovery & Entitlement Reconciliation (SCCM / Intune / Flexera)

Discovery tools tell you what is installed. They do not tell you whether you own it. Raw inventory
arrives as thousands of unnormalized titles, editions, and versions that map to no SKU and link to
nothing you actually bought — so the question that matters, "are we compliant and where can we
reharvest?", goes unanswered.

This package turns software discovery into a reconciled license position. It is a complete,
do-it-today method for pulling installed-software data from Configuration Manager, Microsoft Intune,
or a discovery tool such as Flexera, normalizing the noise into clean SKUs, mapping those SKUs to
your entitlements, and producing the reconciliation that drives compliance decisions and reharvesting.
It is written for a Software Asset Management (SAM) analyst with no prior reconciliation pipeline.

## What you get
- A plain-language Solution Overview of discovery sources, software normalization, the entitlement
  reconciliation model, and how the output feeds compliance and optimization.
- A Requirements Guide with verify / implement-if-missing for every prerequisite. Vendor-specific
  Flexera setup is deferred to the vendor's documentation.
- An Implementation Guide of precise, ordered steps: confirm inventory, export installed-software
  data, normalize titles/editions/versions to SKUs, map to entitlements, reconcile and flag
  exceptions, then pilot, validate, and expand to more sources.
- Five PowerShell scripts for installed-software discovery, normalization/mapping validation, a
  reconciliation and exception report, safe remediation of mapping gaps, and a discovery-scope group
  builder.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
A repeatable reconciliation pipeline: discovery from one or more sources, normalized into a single
SKU vocabulary, matched against an authoritative entitlement count, with every unmatched install
routed to an exception register for decision. Proven on a one-source pilot before it scales.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Raw software discovery turned into a clean, reconciled license position — normalized, mapped to
entitlements, exceptions flagged — the foundation for compliance and reharvesting, proven on a pilot
before you scale.


---


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


---


# 2. Requirements Guide — Software Discovery & Entitlement Reconciliation

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-asset-mgt.md`.

## 2.1 At least one installed-software discovery source
**Description:** A source that reports installed software per device — Configuration Manager (SCCM),
Microsoft Intune detected apps, or a discovery tool such as Flexera.
**Why:** The reconciliation pipeline cannot start without an installed-software extract to normalize.
**Verify:** Run `SWDISC-Discovery.ps1` against one source and confirm it returns installed-software
rows; or in Configuration Manager open `Assets and Compliance > Asset Intelligence`, or in Intune
open `Apps > Monitor > Discovered apps`.
**Implement:** Enable Configuration Manager software inventory / Asset Intelligence, or confirm Intune
detected apps are populated, or onboard a discovery tool. Flexera-specific setup is deferred to
Flexera's documentation.

## 2.2 Read access to each discovery source
**Description:** Rights to query or export installed-software data from each in-scope source.
**Why:** Discovery is read-only, but it still requires query/export permission.
**Verify:** For Intune, you can run a Microsoft Graph query with `DeviceManagementManagedDevices.Read.All`;
for Configuration Manager, the SMS Provider / WMI namespace is reachable with a read role; for Flexera,
you can produce an installed-software export from its console.
**Implement:** Assign a least-privilege read role per source (e.g. an Intune read role, a Configuration
Manager Read-only Analyst, or the appropriate Flexera role). Reserve elevated roles for changes.

## 2.3 An entitlement system of record
**Description:** An authoritative record of purchased entitlements per product, used to build the
`Entitlement Register – Systems of Record – Configure`.
**Why:** A position can only be computed against a known, owned entitlement count.
**Verify:** You can locate the current entitlement quantity (and licensing metric) for a representative
product. Covered category-wide by Global Requirement G3.
**Implement:** Stand up the entitlement repository and import current purchase orders / true-up
statements; record the licensing metric per SKU.

## 2.4 A software normalization approach
**Description:** A maintained `Normalization Map – SKU Vocabulary – Configure` that translates raw
publisher/title/edition/version strings into canonical SKUs.
**Why:** Raw inventory lists the same product many ways; without normalization, installs cannot be
counted or matched.
**Verify:** Run `SWDISC-Validation.ps1` and confirm a normalization map is present and that a sample of
raw titles resolves to SKUs.
**Implement:** Create the normalization map (a controlled lookup table) seeded from your top products;
add a rule for each new product family as it appears in discovery.

## 2.5 A defined reconciliation scope and pilot source
**Description:** A bounded `Discovery Scope Group – Pilot Source – Pilot` — one source or one product
family — to prove the pipeline before fleet-wide reconciliation.
**Why:** Piloting on one source validates accuracy and surfaces normalization gaps cheaply. Aligned
with Global Requirement G7.
**Verify:** A pilot source/product family and its data owner are identified; build it with
`SWDISC-Set-ScopeTargeting.ps1`.
**Implement:** Choose a high-value, well-understood source or product family as the first pass.

## 2.6 Reporting toolchain
**Description:** Excel (Power Query) and/or Power BI to view the
`Reconciliation Ledger – SKU vs Entitlement – Validate` and the
`Exception Register – Unmatched & Edge Cases – Validate`.
**Why:** The position and exceptions are delivered as reports for IT, procurement, and finance.
**Verify:** Excel Power Query opens a CSV export; Power BI Desktop can connect. Covered category-wide
by Global Requirement G5.
**Implement:** Install a current Excel and/or Power BI Desktop.

## 2.7 (Optional) Microsoft Graph PowerShell for Intune discovery
**Description:** The Microsoft Graph PowerShell SDK, used by the scripts to read Intune detected apps.
**Why:** Required only when Intune is an in-scope discovery source for the scripted path.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns the module.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser` (the scripts install it if missing).

## 2.8 (Optional) Configuration Manager access for the scripted path
**Description:** The Configuration Manager console / cmdlets or WMI access to the site's
`root\sms\site_<code>` namespace, used by the scripts to read software inventory.
**Why:** Required only when Configuration Manager is an in-scope discovery source for the scripted path.
**Verify:** `Get-CMSite` succeeds in the console, or the SMS Provider WMI namespace is reachable.
**Implement:** Install the Configuration Manager console (which provides the cmdlets) or grant read
access to the SMS Provider WMI namespace.

---
## Checklist
- [ ] At least one discovery source returns installed software — `SWDISC-Discovery.ps1`
- [ ] Read access confirmed per in-scope source
- [ ] Entitlement system of record located (G3)
- [ ] Normalization map present and resolving samples — `SWDISC-Validation.ps1`
- [ ] Pilot source / product family defined — `SWDISC-Set-ScopeTargeting.ps1`
- [ ] Reporting toolchain available (G5)
- [ ] (Optional) Microsoft Graph PowerShell for Intune discovery
- [ ] (Optional) Configuration Manager console/WMI access for the scripted path


---


# Global Requirements — Asset Mgt (category-level)

These requirements apply to **every** solution in the **Asset Mgt** category (Software Asset
Management, license compliance, and entitlement governance). They are published once at the category
level so individual listings stay small. Confirm these before deploying *any* Asset Mgt solution.
Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for user-based license assignment, access, and reporting.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Administrative access to the license sources
**Description:** Admin rights to the consoles that hold entitlements — at minimum the Microsoft 365
admin center (`https://admin.microsoft.com`), plus any others in scope (Adobe Admin Console,
publisher portals).
**Why:** Reading and adjusting entitlements, assignments, and true-ups requires elevated rights.
**Verify:** Each console loads and shows the licensing/billing area for an admin account.
**Implement:** Assign the least-privilege admin role per console (e.g. License Administrator or
Billing Administrator in Microsoft 365); reserve Global Administrator for tenant-wide changes.

## G3. A system of record for entitlements
**Description:** A maintained record of purchased entitlements, contracts, and renewal dates — a
SAM/ITAM tool, a ServiceNow/CMDB instance, or (at minimum) a controlled spreadsheet/repository.
**Why:** Compliance and optimization are only possible against a known, authoritative entitlement count.
**Verify:** You can locate the current entitlement quantity and renewal date for a representative product.
**Implement:** Stand up the records repository and import current purchase orders / true-up statements.

## G4. Deployment / usage discovery data
**Description:** A source of what is actually installed or used — Microsoft Intune, Configuration
Manager (SCCM), a discovery tool (e.g. Flexera), or sign-in/usage telemetry.
**Why:** Reconciling entitlements against real deployment/usage is the core of compliance and reharvesting.
**Verify:** You can export an installed-software or license-usage report for a sample of devices/users.
**Implement:** Enable Intune/Configuration Manager inventory or onboard a discovery tool; for SaaS,
enable usage/sign-in reporting.

## G5. Reporting toolchain
**Description:** Excel (PivotTables, Power Query) and/or Power BI for analysis and dashboards.
**Why:** License usage, compliance, and cost-optimization findings are delivered as reports/dashboards.
**Verify:** Power BI Desktop opens and can connect to a data source; Excel Power Query is available.
**Implement:** Install Power BI Desktop and a current Excel; provision a Power BI workspace if sharing.

## G6. Stakeholder and process alignment
**Description:** Named owners across IT, procurement, and finance, plus a request/intake channel
(e.g. ServiceNow) for license actions.
**Why:** Renewals, true-ups, and reharvesting require coordinated decisions and an auditable workflow.
**Verify:** A request can be raised and routed to the correct owner; procurement contacts are known.
**Implement:** Define roles (SAM analyst, approver, procurement liaison) and a documented intake process.

## G7. A pilot scope
**Description:** A representative subset (one product family, one department, or one publisher) to prove
the process before fleet-wide rollout.
**Why:** Every solution is piloted before broad adoption to validate accuracy and avoid disruption.
**Verify:** A pilot scope and its data owners are identified.
**Implement:** Choose a high-value, well-understood product/department as the first pass.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing Guide — Software Discovery & Entitlement Reconciliation

Run after the pilot pipeline completes (Implementation Step 9) and after each reconciliation cycle or
when a new source is added.

## Test 1 — Discovery returns installed software
**Do:** Run `SWDISC-Discovery.ps1` against the pilot source.
**Expected:** The `Installed-Software Inventory – All Sources – Discovery` is produced with publisher,
title, edition/version, and device columns populated for the scoped devices.

## Test 2 — Every raw row normalizes to a SKU
**Do:** Run `SWDISC-Validation.ps1` over the pilot inventory.
**Expected:** All raw rows resolve through the `Normalization Map – SKU Vocabulary – Configure` to a
canonical SKU; zero unresolved rows (or the unresolved rows are listed for rule creation).

## Test 3 — Entitlement register joins on the SKU vocabulary
**Do:** Run `SWDISC-Validation.ps1` and confirm SKUs in the
`Entitlement Register – Systems of Record – Configure` match the normalization map's vocabulary.
**Expected:** Register SKUs and normalized SKUs share one vocabulary; no orphaned-vocabulary warnings.

## Test 4 — Reconciliation ledger is produced
**Do:** Run `SWDISC-Report.ps1`.
**Expected:** The `Reconciliation Ledger – SKU vs Entitlement – Validate` lists, per SKU, installed
quantity, entitled quantity, and the position (over / under / balanced).

## Test 5 — Exceptions are captured, not dropped
**Do:** Inspect the `Exception Register – Unmatched & Edge Cases – Validate` from `SWDISC-Report.ps1`.
**Expected:** Every install with no SKU, and every SKU with installs but no entitlement, appears in
the register with a reason — nothing silently discarded.

## Test 6 — Remediation preview is safe
**Do:** Run `SWDISC-Remediation.ps1` (default `-WhatIf`).
**Expected:** Pending normalization-map fixes are previewed only; no changes are committed until the
script is re-run with `-WhatIf:$false`.

## Test 7 — Position holds across sources
**Do:** After expansion (Step 10), re-run `SWDISC-Report.ps1` for the full scope.
**Expected:** The ledger reconciles consistently across sources for shared SKUs; the same product from
two sources counts once per device, not twice.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 pass for the pilot source; the exception register is triaged |
| Expand pass | Tests 1-5 and 7 pass for the full multi-source scope |


---


# 6. Troubleshooting Guide — Software Discovery & Entitlement Reconciliation

Use `SWDISC-Discovery.ps1` and `SWDISC-Validation.ps1` to confirm inputs, `SWDISC-Report.ps1` for the
position, and `SWDISC-Remediation.ps1` (default `-WhatIf`) for safe normalization-map fixes.

## A. Discovery returns no installed software
| Symptom | Cause | Remediation |
|---|---|---|
| Inventory file is empty | Software inventory not enabled on the source | Configuration Manager: enable Software/Hardware inventory + Asset Intelligence on the scoped collection. Intune: confirm `Apps > Monitor > Discovered apps` is populated |
| Intune path returns nothing | Missing Graph scope | Connect with `DeviceManagementManagedDevices.Read.All`; re-run `SWDISC-Discovery.ps1` |
| Configuration Manager path errors | SMS Provider/WMI not reachable | Confirm the console/cmdlets are installed and the `root\sms\site_<code>` namespace is reachable with a read role |
| Flexera rows missing | Export not placed where the script expects | Produce the installed-software export from the Flexera console and place it at the expected path; the script consumes the export, it does not call Flexera |

## B. Rows do not normalize to a SKU
| Symptom | Cause | Remediation |
|---|---|---|
| Many unresolved rows in validation | Normalization map missing rules | Add rules to the `Normalization Map – SKU Vocabulary – Configure`; queue fixes and apply with `SWDISC-Remediation.ps1` |
| Same product appears as several SKUs | Edition/version suffixes not collapsed | Add rules that map edition/patch variants to one canonical SKU |
| Title resolves to the wrong SKU | Over-broad alias rule | Tighten the matching rule (publisher + title + edition), re-run `SWDISC-Validation.ps1` |

## C. Reconciliation ledger looks wrong
| Symptom | Cause | Remediation |
|---|---|---|
| SKUs show installs but zero entitled | Entitlement register uses a different SKU vocabulary | Align register SKUs to the normalization map vocabulary so they join |
| Counts doubled for one product | Same install reported by two sources | Confirm the merge deduplicates on device plus SKU |
| Over-deployment false positive | Licensing metric not recorded (e.g. per-core) | Record the metric in the entitlement register; reconcile against the metric, not a raw count |

## D. Exceptions never shrink
- Each cycle, triage the `Exception Register – Unmatched & Edge Cases – Validate`: add a normalization
  rule, record a missing entitlement, or flag a true gap — then re-run `SWDISC-Report.ps1` so resolved
  items leave the register.

## E. Remediation made no change
- `SWDISC-Remediation.ps1` defaults to `-WhatIf` (preview only). Re-run with `-WhatIf:$false` to
  commit, then confirm with `SWDISC-Validation.ps1`.

## F. When to escalate
If discovery returns data, all rows normalize, the entitlement register shares the SKU vocabulary, and
the ledger still disagrees with a known true-up, capture the inventory file, the normalization map,
and the entitlement register, and review with procurement against the contract terms (downgrade
rights, metric, edition coverage) before declaring a compliance gap.


---


# 7. Best Practices — Software Discovery & Entitlement Reconciliation

- **Pilot on one source first.** Prove the pipeline on a single discovery source or product family
  before merging all sources — it surfaces normalization gaps cheaply and is the single most
  important practice.
- **One SKU vocabulary, everywhere.** The `Normalization Map – SKU Vocabulary – Configure` and the
  `Entitlement Register – Systems of Record – Configure` must use the same canonical SKUs, or the
  reconciliation join silently drops rows.
- **Never drop an unmatched install.** Every install that resolves to no SKU goes into the
  `Exception Register – Unmatched & Edge Cases – Validate` for a decision — exceptions are signal, not
  noise.
- **Treat the normalization map as a living asset.** Add a rule for each new product family as it
  appears; a stale map is the top cause of a noisy, untrustworthy ledger.
- **Deduplicate across sources.** When two sources report the same product on the same device, count
  it once — confirm the merge keys on device plus SKU.
- **Record the licensing metric.** Per-core, per-processor, and per-user-with-downgrade SKUs only
  reconcile correctly when the entitlement register stores the metric, not just a count.
- **Keep discovery read-only.** Discovery, validation, and reporting never change source systems;
  only `SWDISC-Remediation.ps1` writes, and it defaults to `-WhatIf`.
- **Reconcile on a cadence.** Run the pipeline each cycle and after every renewal or true-up so the
  position never drifts from reality.
- **Defer Flexera internals to the vendor.** Consume the Flexera installed-software export; do not
  reverse-engineer its recognition or API — its setup is the vendor's documentation, not this method.
- **Document the artifacts.** Record where each named artifact lives and who owns each exception
  decision, so the pipeline is repeatable and audit-ready.


---


# 8. Deliverables Summary — Software Discovery & Entitlement Reconciliation

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What discovery/reconciliation is, the named artifacts, the pipeline, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: discover, normalize, import entitlements, reconcile, route exceptions, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `SWDISC-Discovery.ps1` | Reads installed software from Intune detected apps (Graph) and Configuration Manager (Get-CM / WMI), or ingests a Flexera export, into the discovery inventory. Read-only |
| `SWDISC-Validation.ps1` | Confirms every raw row resolves through the normalization map to a SKU and that the entitlement register shares the SKU vocabulary. Read-only |
| `SWDISC-Report.ps1` | Builds the reconciliation ledger (installed vs entitled per SKU) and the exception register. Read-only |
| `SWDISC-Remediation.ps1` | Applies queued normalization-map fixes for unmatched titles; defaults to -WhatIf |
| `SWDISC-Set-ScopeTargeting.ps1` | Creates/confirms the pilot discovery-scope group (one source / one product family) |

## The named artifacts
| Artifact | Stage |
|---|---|
| `Installed-Software Inventory – All Sources – Discovery` | Discovery |
| `Normalization Map – SKU Vocabulary – Configure` | Configure |
| `Entitlement Register – Systems of Record – Configure` | Configure |
| `Reconciliation Ledger – SKU vs Entitlement – Validate` | Validate |
| `Exception Register – Unmatched & Edge Cases – Validate` | Validate |
| `Discovery Scope Group – Pilot Source – Pilot` | Pilot |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Raw software discovery turned into a clean, reconciled license position — normalized, mapped to
entitlements, exceptions flagged — proven on a pilot before you scale.
