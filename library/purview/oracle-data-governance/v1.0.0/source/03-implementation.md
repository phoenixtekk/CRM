# 3. Implementation Guide — Oracle Data Governance: Microsoft Purview

Follow these steps in order. This guide assesses Oracle readiness, designs the collection and role
model, establishes the credential and SHIR/network path safely, registers and **pilot-scans** a bounded
Oracle source (one database, a few schemas), reviews classifications, then expands across the Oracle
estate. Artifact names are fixed — create them with the exact names shown and reuse them everywhere.
**Every scan is piloted on a bounded scope before the Oracle estate is scanned.**

> Model: prove the Oracle connector, credential path, network/driver, and classification on a pilot
> scope, then expand. The repeatable way: **Assess → Design → Configure → Pilot → Validate → Expand.**
> Verify current portal paths, connector availability, supported Oracle versions, the driver
> requirement, and the supported authentication methods for your tenant as you go — the connector is
> evolving.

## Step 1 — Assess current state (read-only)
1. Run `DGORACLE-Discovery.ps1` to capture readiness signals: the Purview account endpoint is
   reachable, which **collections** exist and their **role coverage**, which **integration runtimes**
   are registered (you need a SHIR), and how many Oracle (and other) sources are already registered. No
   changes are made.
2. In the Purview portal (**Data Map → Sources → Register**) confirm **Oracle** is offered and note the
   **supported versions and capabilities** (scan, classification, lineage) for your tenant.
3. Record gaps against the Requirements checklist. Do **not** proceed past a missing account, a missing
   connector, missing least-privilege roles, a missing credential, or a missing SHIR/network/driver —
   remediate those first.

## Step 2 — Design the collection and role model
1. Decide the **collection** the Oracle source registers into. For the pilot, create one collection
   named `DGORACLE-Collection-Pilot` under the root; plan the broader hierarchy (for example an
   `Oracle` branch by database or by sensitivity) on paper for the expansion phase.
2. Assign least-privilege roles at the narrowest scope: **Data source admin** on
   `DGORACLE-Collection-Pilot` to whoever will register/scan the Oracle source, **Data curator** to the
   catalog editors, **Data reader** to browsers, and **Collection admin** to a small named group.
   Reserve account-level admin for a minimal named group.

## Step 3 — Create the least-privilege Oracle login (read-only)
1. With the DBA, create a dedicated read-only scanning login (for example `PURVIEW_SCAN`).
2. Grant it **`CREATE SESSION`** and **`SELECT`** on the in-scope schemas/objects and the
   data-dictionary views the scanner reads (verify the exact grant list in Microsoft's current
   Oracle-connector documentation). **Do not** grant DBA/SYS. Confirm the login can query the in-scope
   objects and catalog views.

## Step 4 — Establish the credential path (Key Vault, safe by design)
1. Link an **Azure Key Vault** to the Purview account (or confirm one is linked).
2. Store the `PURVIEW_SCAN` password as a Key Vault **secret**, then create a Purview credential
   **by name** — `DGORACLE-Cred-Oracle-KV` (Basic authentication: the username inline, the password
   referenced from the Key Vault secret). **No password is ever placed in a script or document.**

## Step 5 — Establish the SHIR, network path, and driver
1. Install and register a **self-hosted integration runtime (SHIR)** — `DGORACLE-SHIR` — on a machine
   with **network line of sight** to the Oracle listener; confirm it shows **Running/Available** in the
   portal.
2. Open the firewall so **only** the SHIR host can reach the Oracle **listener port** (default `1521`;
   verify your instance's port).
3. Install the **Oracle JDBC driver** on the SHIR machine where Microsoft's current docs specify
   (**verify whether your SHIR version bundles it or requires a manual install**). A managed VNet
   runtime may be used instead for a cloud-reachable instance — verify.

## Step 6 — Record the pilot scope
1. Run `DGORACLE-Set-Scope.ps1` to record the pilot Oracle source (host/service, port, the in-scope
   schemas, owner/steward, the credential name `DGORACLE-Cred-Oracle-KV`, and the scan-rule-set intent)
   as a scope manifest to configure against (read-only; produces the manifest you register against).

## Step 7 — Register the pilot Oracle source into the Data Map
1. Register the pilot source into `DGORACLE-Collection-Pilot`. You may use the portal
   (**Register → Oracle**), or run `DGORACLE-Register-OracleSource.ps1` which **defaults to `-WhatIf`**
   and prints exactly what it would register (kind `Oracle`, the host/service, port, the collection, and
   the credential name); re-run with `-Commit` to register.
2. Run **Test connection** for the registered source and confirm it passes (the SHIR reaches the
   listener, the JDBC driver is present, and the Key Vault credential authenticates) before scanning.
   Do not scan until Test connection passes.

## Step 8 — Configure and pilot the scan (bounded scope, pilot-first)
1. Define the scan configuration: a **scan rule set** named `DGORACLE-ScanRuleSet-Pilot` (start from the
   system default rule set), the **classifications** to apply (system classifications plus any custom
   rule named `DGORACLE-Classification-Custom-<name>`), and a **scoped** scan that targets only the
   pilot **schemas** — not every schema on the instance.
2. Trigger the scan **once** on the bounded scope (not scheduled yet) via
   `DGORACLE-Register-OracleSource.ps1 -ConfigureScan` (`-WhatIf` by default; `-Commit` to apply) or the
   portal. Pass/fail: the scan completes with **status Succeeded** and returns assets with
   classifications.
3. **Rollback:** if a scan misbehaves, over-reaches, or loads the database, cancel the run in the portal
   and set the scan to disabled; a scan does not modify source data, but cancel to stop
   resource consumption. Re-scope to fewer schemas and re-run.

## Step 9 — Review scanned assets and classifications
1. Run `DGORACLE-Report.ps1` to list the pilot Oracle assets discovered (schemas/tables/columns), the
   classifications applied, and any assets returned **unclassified**.
2. With the data owner, confirm the classifications are correct. Where a real internal pattern was
   missed, define a **custom classification rule** (`DGORACLE-Classification-Custom-<name>`), validate
   it against sample data, add it to `DGORACLE-ScanRuleSet-Pilot`, and re-scan the pilot scope.

## Step 10 — Assign ownership on the Oracle assets
1. In the catalog, assign the **data owner** and **steward** recorded in the scope manifest to the
   scanned database/schemas so every governed Oracle asset has a named owner — ownership is what makes
   classification and later access decisions accountable.

## Step 11 — Validate against the pilot gate
1. Complete the Testing Guide. Run `DGORACLE-Test-Readiness.ps1` for a consolidated PASS/GAP gate check.
   The pilot passes only when: the Oracle source is registered and **Test connection** passes; the scan
   **Succeeded** and returned classified assets; and every scanned pilot asset has an owner assigned.
2. Remediate any gaps and re-run the relevant validation before proceeding. Do **not** widen scope
   until the gate passes.

## Step 12 — Expand across the Oracle estate (enforce)
1. After the pilot passes, register further Oracle databases/schemas one grouping at a time,
   re-running `DGORACLE-Set-Scope.ps1`, `DGORACLE-Register-OracleSource.ps1`, and `DGORACLE-Report.ps1`
   for each new scope. Reuse the same Key Vault credential pattern (a per-database read login where the
   estate spans instances) and the same SHIR where it has line of sight.
2. Move scans from one-time to **scheduled** only once a scope is validated, so classifications stay
   current as Oracle data changes — and watch SHIR/database load as scope grows.
3. Keep ownership assigned on every newly scanned asset and track coverage with `DGORACLE-Report.ps1`.

---
### Order of operations
`Assess -> Design (collection/roles) -> Oracle read login -> Credential (Key Vault) -> SHIR + network + JDBC driver -> Record scope -> Register Oracle source -> Test connection -> Pilot scan (bounded schemas) -> Review classifications -> Assign ownership -> Validate gate -> Expand (scheduled scans)`
