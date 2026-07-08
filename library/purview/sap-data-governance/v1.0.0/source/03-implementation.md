# 3. Implementation Guide — SAP Data Governance: Microsoft Purview

Follow these steps in order. This guide assesses SAP readiness, designs the collection and role model,
stands up the SHIR + SAP driver path, establishes the SAP credential safely, registers and
**pilot-scans** a bounded SAP source, reviews classifications, then expands across the SAP estate.
Artifact names are fixed — create them with the exact names shown and reuse them everywhere. **Every
scan is piloted on a bounded scope before the SAP estate is scanned.**

> Model: prove the SAP connector, driver/credential/network path, and classification on a pilot scope,
> then expand. The repeatable way: **Assess → Design → Configure → Pilot → Validate → Expand.** Verify
> current portal paths, connector availability, supported SAP versions, and driver/Java requirements
> for your tenant as you go — the connectors are evolving.

## Step 1 — Assess current state (read-only)
1. Run `DGSAP-Discovery.ps1` to capture readiness signals: the Purview account endpoint is reachable,
   which **collections** exist and their **role coverage**, which **integration runtimes** are
   registered (you need a **SHIR**), and how many SAP (and other) sources are already registered. No
   changes are made.
2. In the Purview portal (**Data Map → Sources → Register**) confirm the SAP source type you need
   (**SAP ECC / S/4HANA / BW / HANA**) is offered and note the **supported SAP versions** for your
   tenant.
3. Record gaps against the Requirements checklist. Do **not** proceed past a missing account, a missing
   connector, missing least-privilege roles, a missing SHIR, a missing driver, or a missing network
   path — remediate those first.

## Step 2 — Design the collection and role model
1. Decide the **collection** the SAP sources register into. For the pilot, create one collection named
   `DGSAP-Collection-Pilot` under the root; plan the broader hierarchy (for example an `SAP` branch by
   system or by sensitivity) on paper for the expansion phase.
2. Assign least-privilege roles at the narrowest scope: **Data source admin** on
   `DGSAP-Collection-Pilot` to whoever will register/scan SAP sources, **Data curator** to the catalog
   editors, **Data reader** to browsers, and **Collection admin** to a small named group. Reserve
   account-level admin for a minimal named group.

## Step 3 — Stand up the scanner: SHIR + SAP driver + Java (safe by design)
1. Install and register a **self-hosted integration runtime (SHIR)** on a hardened Windows host with
   **line of sight to the SAP system** (RFC gateway for ECC/S4HANA/BW, or the HANA SQL port). Confirm
   it shows **Running/Available** in the portal.
2. On the SHIR machine, place the **SAP-provided driver** downloaded from the SAP Support Portal under
   your S-user: for ECC/S4HANA/BW, the **SAP JCo** files (`sapjco3.jar` + `sapjco3.dll`, 64-bit) plus a
   supported **64-bit Java runtime** with `JAVA_HOME`/path set; for HANA, the **HANA JDBC driver**
   (`ngdbc.jar`). **Verify the exact driver and Java versions Microsoft's current connector docs
   require** and the folder they must sit in. **Put no secret anywhere** — the driver is not a
   credential.
3. Confirm the SAP host/port is reachable from the SHIR machine (open only the firewall rules the
   scanner needs — no broader).

## Step 4 — Establish the SAP credential path (Key Vault, safe by design)
1. With the SAP security team, create a **least-privilege SAP read user** and a scoped authorization
   role (for example SAP user `PURVIEW_SCAN` with role `Z_PURVIEW_SCAN`) carrying the `S_RFC`
   function-module set and metadata read the scanner requires (for HANA, a DB user with read on the
   in-scope schemas). **Verify the exact authorizations against Microsoft's current connector
   documentation.**
2. Link an **Azure Key Vault** to the Purview account (or confirm one is linked), store the SAP user's
   secret there, and create a Purview credential **by name** (for example `DGSAP-Cred-SAP-KV`) that
   references the Key Vault secret. This name is what the scripts reference; **the SAP secret is never
   inlined in a script or document.**

## Step 5 — Record the pilot scope
1. Run `DGSAP-Set-Scope.ps1` to record the pilot SAP source (one system/client with a scoped
   table/object intent) with owner/steward, the pilot collection, the credential name, and the
   scan-rule-set intent (read-only; produces the scope manifest you register against).

## Step 6 — Register the pilot SAP source into the Data Map
1. Register the pilot source into `DGSAP-Collection-Pilot`. You may use the portal
   (**Register → SAP ECC / S/4HANA / BW / HANA**), or run `DGSAP-Register-SapSource.ps1` which
   **defaults to `-WhatIf`** and prints exactly what it would register (the SAP `kind`, the
   host/instance/client or HANA host/port, the collection, the SHIR, and the credential name); re-run
   with `-Commit` to register.
2. Run **Test connection** for the registered source and confirm it passes (the SHIR loads the SAP
   driver, reaches SAP, and authenticates with the named credential) before scanning. **Do not scan
   until Test connection passes.**

## Step 7 — Configure and pilot the scan (bounded scope, pilot-first)
1. Define the scan configuration: a **scan rule set** named `DGSAP-ScanRuleSet-Pilot` (start from the
   system default rule set), the **classifications** to apply (system classifications plus any custom
   rule named `DGSAP-Classification-Custom-<name>`), and a **scoped** scan that targets only the pilot
   system's intended tables/objects — not the entire SAP dictionary.
2. Trigger the scan **once** on the bounded scope (not scheduled yet) via
   `DGSAP-Register-SapSource.ps1 -ConfigureScan` (`-WhatIf` by default; `-Commit` to apply) or the
   portal. Pass/fail: the scan completes with **status Succeeded** and returns assets with
   classifications.
3. **Rollback:** if a scan misbehaves, over-reaches, or loads the SAP system, cancel the run in the
   portal and set the scan to disabled; a metadata scan does not modify SAP data, but cancel to stop
   resource consumption. Re-scope and re-run on a smaller set, and coordinate the window with SAP Basis.

## Step 8 — Review scanned assets and classifications
1. Run `DGSAP-Report.ps1` to list the pilot SAP assets discovered (tables/objects and, where scanned,
   columns/fields), the classifications applied, and any assets returned **unclassified**.
2. With the data owner, confirm the classifications are correct. Where a real internal pattern was
   missed, define a **custom classification rule** (`DGSAP-Classification-Custom-<name>`), validate it
   against sample data, add it to `DGSAP-ScanRuleSet-Pilot`, and re-scan the pilot scope.

## Step 9 — Assign ownership on the SAP assets
1. In the catalog, assign the **data owner** and **steward** recorded in the scope manifest to the
   scanned SAP source/assets so every governed SAP asset has a named owner — ownership is what makes
   classification and later access decisions accountable.

## Step 10 — Validate against the pilot gate
1. Complete the Testing Guide. Run `DGSAP-Test-Readiness.ps1` for a consolidated PASS/GAP gate check.
   The pilot passes only when: the SAP source is registered and **Test connection** passes; the scan
   **Succeeded** and returned classified assets; and every scanned pilot asset has an owner assigned.
2. Remediate any gaps and re-run the relevant validation before proceeding. Do **not** widen scope
   until the gate passes.

## Step 11 — Expand across the SAP estate (enforce)
1. After the pilot passes, register further SAP systems one at a time, re-running
   `DGSAP-Set-Scope.ps1`, `DGSAP-Register-SapSource.ps1`, and `DGSAP-Report.ps1` for each new source.
   Reuse the same SHIR/driver pattern and Key Vault credential pattern (a per-system read user where
   your SAP security model requires it).
2. Move scans from one-time to **scheduled** only once a source is validated, so classifications stay
   current as SAP data changes — and coordinate scan windows with SAP Basis to avoid production load.
3. Keep ownership assigned on every newly scanned asset and track coverage with `DGSAP-Report.ps1`.

---
### Order of operations
`Assess -> Design (collection/roles) -> SHIR + SAP driver + Java -> SAP credential (Key Vault) & network -> Record scope -> Register SAP source -> Pilot scan (bounded) -> Review classifications -> Assign ownership -> Validate gate -> Expand (scheduled scans)`
