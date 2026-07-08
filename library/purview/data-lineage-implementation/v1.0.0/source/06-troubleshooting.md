# 6. Troubleshooting Guide — Data Lineage Implementation (Microsoft Purview)

Field issues and how to resolve them, in the order you are likely to hit them. Every check here is safe
(read-only or a `-WhatIf` preview).

## The Data Map / lineage capability isn't there, or the account won't provision
**Symptom:** No Data Map in the portal, or you can't create a Purview (Data Governance) account, or
lineage features are absent.
**Cause:** Data lineage is a **Data Governance (Data Map / Unified Catalog)** capability — separately
provisioned and **Azure-metered** (capacity units / consumption), **distinct** from Microsoft 365 E5 /
E5 Compliance. Without a provisioned Purview account there is nothing to draw lineage in; and the classic
Data Map vs. the newer unified experience differ.
**Fix:** Provision a Purview (Data Governance) account under an Azure subscription. **Verify the current
provisioning model, pricing, and which experience your tenant is on** against Microsoft's documentation —
this area is actively evolving. `DGLINE-ScopeHealth.ps1` confirms once the account exists and is reachable.

## `Get-AzAccessToken` / data-plane calls return 401 / 403
**Symptom:** `Connect-AzAccount` succeeds but a REST call to `…purview.azure.com` is unauthorized, or
collections don't enumerate.
**Cause:** No **data-plane role** at the collection scope (Collection admin / Data source admin / Data
curator), or the wrong data-plane **resource URL** was used for the token.
**Fix:** Assign the least-privilege data-plane role at the in-scope **collection** (Purview portal →
**Data Map → Collections → Role assignments**, verify path). Confirm the token resource is the current
Purview data-plane resource (`https://purview.azure.net` as of authoring — **verify in your tenant**).
Re-run `DGLINE-ScopeHealth.ps1`. Control-plane (Azure RBAC on the account) is **not** the same as
data-plane (collection) roles.

## A REST call returns 404 / "api-version not supported"
**Symptom:** A scanning/catalog/lineage endpoint returns 404 or an api-version error.
**Cause:** The `api-version` value or the endpoint path has changed — the Data Governance data-plane APIs
evolve, and the classic vs. unified experiences expose different surfaces.
**Fix:** Every `api-version` in the scripts is a **placeholder cited as of authoring** — override it with
the `-…ApiVer` parameter using the **current** value from Microsoft's REST documentation for your tenant.
Do not assume the path is wrong before checking the api-version.

## Lineage isn't appearing after connecting ADF/Synapse/Power BI
**Symptom:** The integration source is connected to Purview but the asset's Lineage tab is empty.
**Cause (most common):** Automatic lineage is captured only on **runs that happen after** the connection
exists — a pipeline that ran **before** you connected it is **not back-filled**. Or the source/sink
stores aren't **scanned**, so there's no asset to attach the edge to. Or there's simple processing delay.
**Fix:** **Run the pipeline again** after connecting, and ensure both the source and sink stores are
**registered and scanned** into the Data Map (Requirement 2.4). Re-run
`DGLINE-Validate.ps1 -Asset '<sink qualified name>'`. Connect **early** — this is why the Requirements and
Best Practices insist on it.

## Custom-lineage push flags an asset as "not resolvable"
**Symptom:** `DGLINE-Configure.ps1 -WhatIf` prints `[WARN] input/output asset not resolvable in catalog`.
**Cause:** The `InputQualifiedName` / `OutputQualifiedName` doesn't match a scanned asset — usually a
hand-typed path, a casing/format difference, or the asset was never scanned.
**Fix:** Use the **canonical qualified name from a scan** (copy it from the catalog / from
`DGLINE-Validate.ps1` output), not a hand-built path. Scan the endpoint first if it isn't in the Data Map.
Re-run `-WhatIf` until both ends resolve, then `-Commit`.

## `DGLINE-Configure.ps1 -Commit` created lineage in the wrong place
**Symptom:** A custom-lineage `Process` points at the wrong asset.
**Cause:** A wrong qualified name in the coverage-map CSV.
**Fix:** The script printed the created **GUID** and the exact reverse **`DELETE`** call — run it to
remove **only** that `Process` entity (it never deletes underlying data assets). Correct the CSV and
re-push. This is why every push is dry-run (`-WhatIf`) and reviewed against
`Data Lineage Coverage Map – DGLINE – Design` first.

## Lineage renders but points at the wrong source ("confident wrong answer")
**Symptom:** The graph is present but a data owner says the upstream source or downstream consumer is
wrong.
**Cause:** The automatic connector captured a path you didn't expect, or a custom `Process` referenced the
wrong endpoint — presence is not correctness.
**Fix:** Walk the graph with the data owner (Testing Guide Test 7). Remove/repair the offending edge
(delete the wrong custom `Process` by GUID, or correct the connection scope) and re-validate. Never sign
off lineage on **presence** alone.

## Coverage report shows many assets "without lineage"
**Symptom:** `DGLINE-Report.ps1` reports low coverage.
**Cause:** Expected — assets legitimately have no lineage until a source is connected or custom lineage is
pushed; or the endpoints aren't scanned; or the report's search scope is too broad (assets not actually in
your traceability target).
**Fix:** Treat each without-lineage asset as a **named follow-up** (scan the endpoint, connect the source,
or push a custom `Process`). Narrow the report with `-Keyword`/`-Limit` to the in-scope estate so coverage
is measured against the governance **target**, not the whole catalog. Coverage is closed **deliberately**,
not assumed.

## Scan shows failed / no runs for a source
**Symptom:** `DGLINE-Discovery.ps1` reports `no runs` / `failed` / `not readable` for a source.
**Cause:** The source was registered but never scanned, the scan credential/integration runtime is
misconfigured, or your role can't read the scan history.
**Fix:** Run (or fix) the scan in the portal (**Data Map → Data sources → New scan**, verify path);
confirm the scan credential and integration runtime; ensure you hold **Data source admin** on the
collection. Re-run `DGLINE-Discovery.ps1` and confirm a **completed** scan before expecting lineage.

---
### When to stop and escalate
- The **Data Governance account/pricing model** or which **experience** (classic Data Map vs. unified
  Unified Catalog) your tenant is on is unclear → verify against Microsoft's current documentation and
  your Azure subscription before provisioning or assuming an API surface; do not invent an endpoint.
- A determination is being asked of you — **which lineage coverage is *required*** for a regulatory/records
  obligation, or **which source is *authoritative*** for a data element → escalate to data governance,
  records, privacy, or legal. This solution provides the graph and the coverage evidence, never the
  determination.
- A portal path or REST `api-version` in this guide **doesn't match your tenant** → this area is actively
  evolving; verify the current path/version in your tenant before concluding the *step* is wrong.
