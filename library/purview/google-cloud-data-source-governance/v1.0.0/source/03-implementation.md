# 3. Implementation Guide — Google Cloud Data-Source Governance: Microsoft Purview

Follow these steps in order. This guide assesses Google Cloud readiness, designs the collection and
role model, establishes the BigQuery service-account credential and SHIR/network path safely,
registers and **pilot-scans** a bounded Google Cloud source set, reviews classifications, then expands
across the Google Cloud estate. Artifact names are fixed — create them with the exact names shown and
reuse them everywhere. **Every scan is piloted on a bounded scope before the Google Cloud estate is
scanned.**

> Model: prove the Google Cloud connector, credential path, and classification on a pilot scope, then
> expand. The repeatable way: **Assess → Design → Configure → Pilot → Validate → Expand.** Verify
> current portal paths, connector availability, required GCP IAM roles, and the SHIR/driver
> prerequisites for your tenant as you go — the multicloud connectors are evolving.

## Step 1 — Assess current state (read-only)
1. Run `DGGCP-Discovery.ps1` to capture readiness signals: the Purview account endpoint is reachable,
   which **collections** exist and their **role coverage**, which **integration runtimes** are
   registered (you will need a SHIR for BigQuery), and how many sources are already registered. No
   changes are made.
2. In the Purview portal (**Data Map → Sources → Register**) confirm **Google BigQuery** is offered
   for your tenant.
3. Record gaps against the Requirements checklist. Do **not** proceed past a missing account, a
   missing connector, missing least-privilege roles, or a missing SHIR/network path — remediate those
   first.

## Step 2 — Design the collection and role model
1. Decide the **collection** the Google Cloud sources register into. For the pilot, create one
   collection named `DGGCP-Collection-Pilot` under the root; plan the broader hierarchy (for example a
   `GCP` branch by project or by sensitivity) on paper for the expansion phase.
2. Assign least-privilege roles at the narrowest scope: **Data source admin** on
   `DGGCP-Collection-Pilot` to whoever will register/scan Google Cloud sources, **Data curator** to
   the catalog editors, **Data reader** to browsers, and **Collection admin** to a small named group.
   Reserve account-level admin for a minimal named group.

## Step 3 — Establish the BigQuery service-account credential (safe by design)
1. In **Google Cloud**, create a **service account** in the in-scope project and grant it **read-only**
   BigQuery access — historically **BigQuery Data Viewer** + **BigQuery Metadata Viewer** plus read-job
   ability (**BigQuery Job User**); **verify the current required roles** for the Purview connector.
   Enable the **BigQuery API** in the project.
2. Generate a **service-account key** for it. **Do not place the key in a script or document.**
3. In Azure, link an **Azure Key Vault** to the Purview account (or confirm one is linked) and store
   the service account's **private key** as a Key Vault secret.
4. In Purview, register a credential **by name** (for example `DGGCP-Cred-BQ-KV`) of the BigQuery
   service-account type that references the Key Vault secret. This name is what the scripts reference;
   no key material is ever inlined in a script.

## Step 4 — Establish the SHIR and network path
1. Install and register a **self-hosted integration runtime (SHIR)** to the Purview account on a
   machine with **network line of sight to Google Cloud / BigQuery**.
2. Install the **BigQuery driver prerequisites** on the SHIR host (historically a **Java Runtime
   Environment / JDK** for the JDBC driver — **verify the current version** for your tenant).
3. Confirm the SHIR shows **Running/Available** and that any Google Cloud / network firewall rules
   permit the SHIR to reach BigQuery.

## Step 5 — Record the pilot scope
1. Run `DGGCP-Set-Scope.ps1` to record the pilot Google Cloud source set (one BigQuery project / one
   or two datasets) with owners, plus the pilot collection and scan-rule-set intent (read-only;
   produces the scope manifest you register against).

## Step 6 — Register the pilot Google Cloud source into the Data Map
1. Register the pilot source into `DGGCP-Collection-Pilot`. You may use the portal
   (**Register → Google BigQuery**), or run `DGGCP-Register-GcpSource.ps1` which **defaults to
   `-WhatIf`** and prints exactly what it would register (kind `GoogleBigQuery`, the project ID, the
   collection, and the credential name); re-run with `-Commit` to register.
2. Run **Test connection** for the registered source and confirm it passes (service-account auth over
   the SHIR succeeds) before scanning. Do not scan until Test connection passes.

## Step 7 — Configure and pilot the scan (bounded scope, pilot-first)
1. Define the scan configuration: a **scan rule set** named `DGGCP-ScanRuleSet-Pilot` (start from the
   system default rule set), the **classifications** to apply (system classifications plus any custom
   rule named `DGGCP-Classification-Custom-<name>`), and a **scoped** scan that targets only the pilot
   datasets — not every dataset in the project.
2. Trigger the scan **once** on the bounded scope (not scheduled yet) via
   `DGGCP-Register-GcpSource.ps1 -ConfigureScan` (`-WhatIf` by default; `-Commit` to apply) or the
   portal. Pass/fail: the scan completes with **status Succeeded** and returns assets with
   classifications.
3. **Rollback:** if a scan misbehaves, over-reaches, or runs up BigQuery query/egress cost, cancel the
   run in the portal and set the scan to disabled; a scan does not modify source data, but cancel to
   stop resource/cost consumption. Re-scope and re-run on a smaller set.

## Step 8 — Review scanned assets and classifications
1. Run `DGGCP-Report.ps1` to list the pilot Google Cloud assets discovered (BigQuery
   datasets/tables/columns), the classifications applied, and any assets returned **unclassified**.
2. With the data owner, confirm the classifications are correct. Where a real internal pattern was
   missed, define a **custom classification rule** (`DGGCP-Classification-Custom-<name>`), validate it
   against sample data, add it to `DGGCP-ScanRuleSet-Pilot`, and re-scan the pilot scope.

## Step 9 — Assign ownership on the Google Cloud assets
1. In the catalog, assign the **data owner** and **steward** recorded in the scope manifest to the
   scanned datasets/tables so every governed Google Cloud asset has a named owner — ownership is what
   makes classification and later access decisions accountable.

## Step 10 — Validate against the pilot gate
1. Complete the Testing Guide. Run `DGGCP-Test-Readiness.ps1` for a consolidated PASS/GAP gate check.
   The pilot passes only when: the Google Cloud source is registered and **Test connection** passes;
   the scan **Succeeded** and returned classified assets; and every scanned pilot asset has an owner
   assigned.
2. Remediate any gaps and re-run the relevant validation before proceeding. Do **not** widen scope
   until the gate passes.

## Step 11 — Expand across the Google Cloud estate (enforce)
1. After the pilot passes, register further BigQuery projects/datasets one grouping at a time (for
   example per project), re-running `DGGCP-Set-Scope.ps1`, `DGGCP-Register-GcpSource.ps1`, and
   `DGGCP-Report.ps1` for each new scope. Reuse the same service-account pattern (extending its
   read-only grant to the new datasets/projects) and Key Vault credential pattern.
2. Move scans from one-time to **scheduled** only once a scope is validated, so classifications stay
   current as Google Cloud data changes — and watch BigQuery query/egress cost as scope grows.
3. Keep ownership assigned on every newly scanned asset and track coverage with `DGGCP-Report.ps1`.

---
### Order of operations
`Assess -> Design (collection/roles) -> BigQuery service-account credential (Key Vault) -> SHIR & network -> Record scope -> Register GCP source -> Pilot scan (bounded) -> Review classifications -> Assign ownership -> Validate gate -> Expand (scheduled scans)`
