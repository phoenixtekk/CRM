# 6. Troubleshooting Guide — SAP Data Governance: Microsoft Purview

Field issues and remediation, in the order you hit them. Read-only checks (`DGSAP-Discovery.ps1`,
`DGSAP-Report.ps1`, `DGSAP-Test-Readiness.ps1`) are safe to repeat while you diagnose.

## The SAP connector isn't offered in Register
Symptom: **Data Map → Sources → Register** doesn't list the SAP source type you need (ECC / S/4HANA /
BW / HANA).
Likely cause: Connector availability is licensing-/region-/preview-dependent and evolving.
Fix: Verify your Purview account's region and licensing, and Microsoft's current connector availability
for your tenant. Scope the pilot to the SAP source type actually offered and defer the others; do not
assume a connector that isn't shown.

## `DGSAP-Discovery.ps1` reports the endpoint as GAP (not reachable)
Symptom: The script can't read collections.
Likely causes: wrong account name, not signed in, missing Data reader role, or an account API version
that has moved.
Fix: Confirm the short account name, run `Connect-AzAccount`, ensure at least **Data reader** on the
collection, and verify the current account API version for your tenant. The script never stores a
secret — it acquires a data-plane token for `https://purview.azure.net`.

## No self-hosted integration runtime (SHIR) shows up
Symptom: `DGSAP-Discovery.ps1` / `DGSAP-Test-Readiness.ps1` report no self-hosted IR.
Likely cause: SAP is behind the corporate network and the Azure (managed) runtime cannot reach it; a
SHIR hasn't been installed/registered.
Fix: Install and register a **SHIR** on a hardened Windows host with line of sight to the SAP
host/port, confirm it shows **Running/Available**, and re-run discovery. **Verify** the current runtime
requirement for your connector.

## Test connection fails: SAP driver / Java not found
Symptom: **Test connection** fails referencing the SAP connector, a missing library, or Java.
Likely cause: the **SAP JCo** files (`sapjco3.jar` + `sapjco3.dll`, ECC/S4HANA/BW) or the **HANA JDBC
driver** (`ngdbc.jar`, HANA), or a supported **64-bit Java runtime**, aren't present on the SHIR
machine — or the versions don't match Microsoft's requirement.
Fix: Download the driver from the **SAP Support Portal under your S-user**, install the required Java
runtime, place the files in the location Microsoft's current connector docs specify, set
`JAVA_HOME`/path, restart the SHIR service if required, and re-test. Match the **exact** driver and
Java versions Microsoft's docs call for — a version mismatch is the most common failure. The solution
cannot ship SAP's drivers; obtain them under your SAP license.

## Test connection fails: authentication or authorization (SAP side)
Symptom: The SHIR reaches SAP but authentication or metadata read fails.
Likely causes: the SAP read user's password is wrong or expired, the Key Vault credential references
the wrong secret, or the user's authorization role is missing the `S_RFC` function-module set or the
metadata-table read the scanner needs (for HANA, missing read on the in-scope schemas).
Fix: Confirm the Key Vault secret is current and the Purview credential references it **by name**; with
the SAP security team, confirm the authorization role grants exactly the least-privilege authorizations
Microsoft's current connector docs require — no more. Never place the SAP password in a script or the
scan definition.

## Test connection fails: network path to SAP
Symptom: The SHIR cannot reach the SAP host/port.
Likely cause: firewall rules block the RFC gateway (ECC/S4HANA/BW) or the HANA SQL port from the SHIR
machine.
Fix: Open only the specific firewall rule the scanner needs from the SHIR to the SAP host/port — no
broader. Confirm the SHIR machine can resolve and reach the host, then re-test.

## Scan runs but returns no assets (or far fewer than expected)
Symptom: The scan status is Succeeded but `DGSAP-Report.ps1` shows few/no SAP assets.
Likely causes: the scan scope was too narrow (or pointed at the wrong tables/objects), or the SAP read
user lacks read on some metadata.
Fix: Review the scan's scope and rule set, widen it deliberately to the intended tables/objects (still
bounded), confirm the read user can see them, and re-scan the pilot scope.

## Scan Succeeded but assets are unclassified
Symptom: Assets appear in the catalog but with no classifications.
Likely causes: the data genuinely doesn't match the system classifications, or a real internal pattern
(an SAP customer/vendor ID scheme) isn't covered.
Fix: Confirm with the data owner whether the assets should carry a classification. Where a real pattern
is missed, define a **custom classification rule** (`DGSAP-Classification-Custom-<name>`), validate it
against sample data, add it to `DGSAP-ScanRuleSet-Pilot`, and re-scan. Don't over-fit custom rules —
trust system classifications first.

## The scan loads the SAP system or collides with a batch window
Symptom: SAP Basis reports load during a scan, or the scan overlaps a period-close/batch job.
Fix: Keep the scan **one-time and scoped** until validated; schedule scans only after a source passes,
and coordinate every window with SAP Basis so a governance scan never competes with production
processing. If a run misbehaves, cancel it in the portal and set the scan to disabled (a metadata scan
does not modify SAP data) — then re-scope.

## `-WhatIf` printed a plan but nothing was registered
Symptom: `DGSAP-Register-SapSource.ps1` printed a plan and made no change.
Cause: **This is by design** — the script defaults to `-WhatIf` and only prints the payload it would
send. Re-run with `-Commit` once you've confirmed the SAP source `kind`, the property schema, the API
version, the SHIR name, and the Key Vault credential name for your tenant.

## Roles look wrong or a curator can't classify
Symptom: A user can't register a source, run a scan, or edit classifications.
Fix: Confirm least-privilege roles at the collection scope — **Data source admin** to register/scan,
**Data curator** to edit metadata/classifications, **Data reader** to browse. Assign the narrowest role
that lets the person do their job; reserve Collection/account admin for a small named group.

---
### When to escalate vs. defer
- **Escalate (technical):** connector not offered, SHIR/driver/network failures, scan errors, API-version
  drift — these are configuration issues this guide's steps and scripts address.
- **Defer (determination):** whether a given SAP source is in scope, how its data must be classified,
  retained, or accessed, and any regulatory obligation — these belong to the data owners, stewards, and
  the compliance/records/privacy/legal functions, not to the scanning configuration.
