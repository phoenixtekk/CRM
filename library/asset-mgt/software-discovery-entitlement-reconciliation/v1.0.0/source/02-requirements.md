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
