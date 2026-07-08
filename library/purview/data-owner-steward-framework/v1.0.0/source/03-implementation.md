# 3. Implementation Guide — Data-Owner & Steward Framework (Microsoft Purview)

Follow these steps **in order**. Inventory and assessment come from the **Microsoft Purview portal**
(purview.microsoft.com), **Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft
Graph**. Role assignments are previewed with `-WhatIf` before `-Commit`. Artifact names follow the
`<Purpose> – Purview – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Assess ownership coverage → design the role model + RACI → configure assignments + cadence →
> validate on a **pilot domain** → confirm every gate → expand across the estate. Pattern: **Assess →
> Design → Configure → Pilot → Validate → Expand.**
>
> **Portal paths are cited as of authoring and the Purview portal — especially the Unified Catalog / Data
> Governance experience — is evolving; verify each path in your own tenant.** Capability availability is
> licensing-dependent (Requirement 2.2). This framework assigns *accountability*; it does not author
> labels, DLP, or retention policies — those are piloted in simulation/test in their own solutions.

## Step 1 — Assess current ownership coverage (Assess)
1. Open the **Microsoft Purview portal** (`https://purview.microsoft.com`) and orient: confirm which
   in-scope surfaces render (Information Protection → Labels, Data Loss Prevention → Policies, Data
   Lifecycle Management → Retention policies, Unified Catalog → Governance domains). Visibility tracks
   your licensing.
2. Run `DGSTEWARD-Assess-Ownership.ps1 -CsvPath .\OwnershipInventory.csv`. Read-only, it inventories the
   in-scope Purview controls — sensitivity labels (`Get-Label`), DLP policies (`Get-DlpCompliancePolicy`),
   retention policies (`Get-RetentionCompliancePolicy`) — plus (via Graph, where the Data Governance API
   is available in your tenant) governance domains, and reports for each whether an **owner** and
   **steward** are recorded (in the object's comment/metadata or the domain roles). It writes
   `Data Ownership Inventory – Steward – Assess`.
3. Record the **coverage gap**: which controls/assets have no owner, no steward, or neither.
   **Pass/fail:** you can state, per in-scope surface, a coverage number — "N of M labels have a recorded
   owner", "K DLP policies are unowned" — and a named list of gaps to close.

## Step 2 — Design the role model and RACI (Design)
1. Using the coverage output and the role model in the Overview, define the **roles** and who fills them:
   **Data Owner**, **Data Steward**, **Governance Domain Owner**, **Data Custodian / Control Owner**, and
   the strictly-separated sensitive roles (**Insider Risk**, **Communication Compliance**, **eDiscovery**).
2. Author the RACI `Data-Owner/Steward RACI – Design` as a CSV: one row per **governance activity**
   (classify/label an asset, author/tune a DLP policy, author/tune a retention policy, re-certify
   ownership, review a disposition, respond to an access request, close an audit finding), with columns
   naming exactly one **Accountable** party and the **Responsible / Consulted / Informed** parties. Rule:
   **exactly one A per row**; every row has at least one R.
3. Map each in-scope control/asset from Step 1 to its **Data Owner** and **Data Steward** in a companion
   assignment CSV (`Purview-Stewardship-Matrix.csv`) — the input the configuration script consumes.
4. Apply separation of duties: sensitive-role rows are **named, minimal, and separate** from general
   stewardship, and confirmed with HR/privacy/legal. **Pass/fail:** every in-scope control/asset has a
   named Owner and Steward; every RACI activity has exactly one A; no sensitive role is over-assigned.

## Step 3 — Preview and apply stewardship assignments (Configure, pilot-first)
1. Dry-run first: `DGSTEWARD-Set-Stewardship.ps1 -MatrixPath .\Purview-Stewardship-Matrix.csv -WhatIf`.
   With `-WhatIf` (the default) it makes **no changes** — it prints exactly which member would be added to
   which role group, and which owner/steward tag would be written to which control's metadata, and flags
   any role group or object it cannot find.
2. Read every line against `Data-Owner/Steward RACI – Design`. Confirm no unintended broad grant and that
   the sensitive-role rows match the HR/legal-approved list.
3. Apply to the **pilot domain first**: run with `-Commit` scoped to `Stewardship Pilot Domain – Stage1`.
   Compliance-side assignments use `Add-RoleGroupMember`; control-ownership tags are written to the
   object's comment/metadata via the object's `Set-*` cmdlet (e.g. `Set-Label`); governance-domain owner/
   steward assignments are made in the Unified Catalog (portal, or Graph where the data-plane API is
   available — the script flags this and does not invent an API). Writes `Stewardship Assignments –
   Configure`.
4. **Pass/fail + rollback:** `DGSTEWARD-Test-Framework.ps1` reports every pilot control/asset now has a
   recorded owner and steward. Rollback is `Remove-RoleGroupMember` / clearing the metadata tag — the
   script prints the exact reverse command for each change it makes.

## Step 4 — Establish the review cadence (Configure)
1. Agree the cadence interval with the stakeholders (e.g. quarterly re-certification of owned assets,
   monthly gap chase — the interval is a business decision, Requirement 2.8).
2. Record, per control/asset, a **last-reviewed** date and a **review-by** date (written into the object's
   metadata tag alongside owner/steward, or tracked in the assignment CSV where the object has no writable
   metadata). This is what makes "overdue" computable.
3. Assign the cadence an **owner** (the Data Steward runs it; the Data Owner is Accountable). **Pass/fail:**
   `DGSTEWARD-Check-Cadence.ps1` returns a due/overdue list and a named owner for running it.

## Step 5 — Validate on the pilot domain (Pilot → Validate)
1. Run the full validation suite against `Stewardship Pilot Domain – Stage1` (see the Testing Guide): every
   in-scope control/asset has an Owner and Steward, the RACI resolves to real identities, sensitive roles
   are separated, and the cadence produces a correct due/overdue list.
2. Produce `Accountability Coverage – Report` (`DGSTEWARD-Report-Accountability.ps1`) — the coverage
   percentage and gap list for the pilot. **Pass/fail:** pilot coverage is 100% of in-scope controls, or
   every remaining gap is a named, owned action item.

## Step 6 — Expand across the estate (Expand)
1. Broaden the assignment CSV from the pilot domain to the full in-scope set; re-run Step 3 (dry-run then
   `-Commit`) domain by domain, not all at once.
2. Re-run the accountability report and confirm coverage across the estate; hand the running of the
   cadence to the named stewards.
3. **Pass/fail:** estate coverage meets the agreed target; the cadence is scheduled and owned; every
   sensitive role remains named, minimal, and separated.

> **What is deferred (by design).** *What* an asset's classification, retention, or records schedule is,
> *whether* a regulation applies, and *who may* hold a sensitive role are **determinations** made by
> compliance, records, privacy, and legal — not by this framework. The framework records and operates
> those decisions with named accountability and a cadence; it does not make them, and it does not author
> the underlying label/DLP/retention policies.
