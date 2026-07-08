# 6. Troubleshooting Guide — Databricks Data Governance (Unity Catalog / lakehouse): Microsoft Purview

Use `DGDBX-Discovery.ps1` for readiness/role/runtime/Key-Vault and Databricks-source state, `DGDBX-Report.ps1`
for scan status and classification/ownership/lineage coverage (CSV), `DGDBX-Set-Scope.ps1` to (re)record a
scope and (with `-Commit`) set a schedule, `DGDBX-Register-DatabricksSource.ps1` (`-WhatIf` by default) to
register/scan, and `DGDBX-Test-Readiness.ps1` for the consolidated readiness/pilot gate. All scripts are
read-only unless you pass `-Commit` (only `DGDBX-Register-DatabricksSource.ps1` and
`DGDBX-Set-Scope.ps1 -Commit` write).

## A. Cannot reach the account / token fails
| Symptom | Cause | Remediation |
|---|---|---|
| `Discovery` reports endpoint GAP | Wrong account name or endpoint | Confirm the account name; the endpoint is `https://<account>.purview.azure.com`; re-run `DGDBX-Discovery.ps1` |
| Token acquisition fails | Not signed in / wrong resource | Run `Connect-AzAccount`; the scripts request a token for `https://purview.azure.net` — confirm your account can obtain it |
| 401/403 on every call | Missing least-privilege role | Assign Data reader (browse) or the specific role the action needs at the collection scope; re-run |
| Calls fail with "api-version" errors | The example API version has moved | The Data Governance experience is evolving — verify and set the current data-plane API version for your tenant |

## B. The Azure Databricks connector isn't offered / wrong connector
| Symptom | Cause | Remediation |
|---|---|---|
| No **Azure Databricks** in Register | Connector unavailable/preview for your tenant | Verify licensing/region and Microsoft's current Data Governance connector availability; scope the pilot to what is actually offered |
| Empty or partial scan | Wrong connector for the workspace (Unity Catalog vs. Hive metastore) | Confirm with the Databricks admins whether Unity Catalog is enabled and the metastore; register the **matching** connector |
| Unknown source "kind" | Connector name differs from the script default | Verify the exact `kind`/`credentialType` names for your tenant before `-Commit` (the `-Kind` param accepts Unity Catalog or Hive metastore) |

## C. Source registration or Test connection fails
| Symptom | Cause | Remediation |
|---|---|---|
| Register returns 403 | Not a Data source admin on the collection | Assign Data source admin on `DGDBX-Collection-Pilot`; re-run `DGDBX-Register-DatabricksSource.ps1 -Commit` |
| Test connection fails: auth | Wrong/expired Databricks service principal or PAT, or Key Vault secret | Confirm the scan identity and the Key Vault secret; reference the credential **by name** (`-Credential DGDBX-Cred-Databricks-KV`); re-test |
| Test connection fails: access denied on catalog/schema | Scan identity lacks Databricks metadata read | Grant least-privilege Unity Catalog metadata read (e.g. `USE CATALOG`/`USE SCHEMA`/`SELECT` or the connector's documented equivalents) to the scan identity; re-test |
| "Credential not found" / Key Vault error | Vault not linked or secret name wrong | Link the Key Vault to the account, store the secret, reference it **by name**; never inline a token or secret |
| Metastore not resolved (Unity Catalog) | Wrong/missing `-Metastore` | Confirm the workspace's Unity Catalog metastore with the Databricks admins; verify the required metastore value for the connector; re-register |

## D. Network / integration-runtime failures
| Symptom | Cause | Remediation |
|---|---|---|
| Test connection times out | Workspace is VNet-injected / Private Link, no path from managed IR | Install and register a self-hosted integration runtime (`DGDBX-SHIR`) with line of sight; open only the rules the scanner needs to reach the workspace + metastore; re-test |
| `Discovery` shows no integration runtime | No IR registered | Register the Azure (managed) IR for a public workspace, or a SHIR for a private one; re-run `DGDBX-Discovery.ps1` |
| Intermittent scan failures on a private workspace | SHIR host offline / network rule changed | Confirm the SHIR shows Running/Available and the network path is open; re-run the scan |

## E. Scan runs but classifies nothing
| Symptom | Cause | Remediation |
|---|---|---|
| Assets returned, 0 classified | Scan rule set has no classifications | Confirm `DGDBX-ScanRuleSet-Pilot` includes system classifications; re-scan and review with `DGDBX-Report.ps1` |
| An internal pattern isn't detected | No custom classification rule | Define `DGDBX-Classification-Custom-<name>`, validate against sample data, add to the rule set, re-scan |
| Scan scope too broad / slow / costly | Whole metastore scanned | Re-scope the scan to one catalog/schema (`-Catalog`/`-Schema`); keep it one-time until validated |
| Scan status Failed | Transient/auth/network | Open the run in the portal for the failure reason; fix credential/runtime/network; re-run |

## F. Lineage is missing or shallow
| Symptom | Cause | Remediation |
|---|---|---|
| No lineage on scanned tables | Connector/tenant doesn't surface Unity Catalog lineage yet, or Unity Catalog lineage prerequisites unmet | **Verify** the connector version and Unity Catalog lineage prerequisites for your tenant before assuming a defect; confirm lineage is tracked in Unity Catalog for those tables |
| `DGDBX-Report.ps1` shows 0% lineage | Lineage API version/shape differs, or lineage not yet computed | Verify the current lineage API version for your tenant; allow Unity Catalog lineage to populate; re-run the report |
| Partial lineage | Depth is connector-dependent | Lineage depth varies by connector and evolves — do not promise coverage the connector doesn't provide; verify current support |

## G. Databricks / Azure cost higher than expected
- Scanning drives Databricks compute and Purview Data Governance is consumption-billed. Keep scans
  **one-time and bounded** until validated, scope to one catalog/schema, and agree the expected cost with
  the workspace and Azure subscription owners as part of change control. Cancel a runaway scan in the
  portal (no source data is modified) and re-scope. Enable a schedule (`DGDBX-Set-Scope.ps1 -Commit`) only
  after a scope validates.

## H. Classifications look wrong
- False positives/negatives are expected on first scan. Review with the **data owner** using
  `DGDBX-Report.ps1`; tune or remove a custom classification rule and re-scan the pilot scope. The solution
  provides the technical result — the owner decides whether a classification is correct for the business.

## I. Ownership / gate not passing
| Symptom | Cause | Remediation |
|---|---|---|
| `DGDBX-Test-Readiness.ps1` shows "not owned" | Owners not assigned on scanned assets | Assign the owner/steward from the scope manifest to each catalog/schema/table in the catalog; re-run |
| Gate shows no Succeeded scan | Scan not run or Failed | Trigger the one-time scan; fix any Test-connection failure first; re-check |
| Gate shows classification 0 | Rule set / scope issue | See section E; re-scan and re-check |
| Gate shows Key Vault / IR GAP | Vault not linked / no runtime | Link the Key Vault and register the integration runtime; re-run `DGDBX-Test-Readiness.ps1` |

## J. Diagnostics quick reference
```powershell
.\DGDBX-Discovery.ps1 -PurviewAccount contoso-purview                 # readiness: endpoint, collections, roles, runtimes, Key Vault, Databricks sources
.\DGDBX-Set-Scope.ps1 -Collection DGDBX-Collection-Pilot -WorkspaceUrl https://adb-1234567890123456.7.azuredatabricks.net `
    -Catalog contoso_prod -Schema finance -Credential DGDBX-Cred-Databricks-KV   # record scope (preview; -Commit sets a schedule)
.\DGDBX-Register-DatabricksSource.ps1 -PurviewAccount contoso-purview -Collection DGDBX-Collection-Pilot `
    -SourceName dbx-lakehouse-01 -WorkspaceUrl https://adb-1234567890123456.7.azuredatabricks.net `
    -Metastore contoso-uc-metastore -Credential DGDBX-Cred-Databricks-KV   # -WhatIf by default
.\DGDBX-Report.ps1 -PurviewAccount contoso-purview -Collection DGDBX-Collection-Pilot -OutFile .\dgdbx-report.csv  # scan + classification + lineage coverage (CSV)
.\DGDBX-Test-Readiness.ps1 -PurviewAccount contoso-purview -Collection DGDBX-Collection-Pilot  # consolidated readiness/pilot gate
```

## K. When to escalate
If the account is reachable, roles are assigned, the runtime is Running, the Key Vault credential resolves,
Test connection passes, and a scoped scan still returns no classified assets after tuning the rule set,
capture the `DGDBX-Discovery.ps1` and `DGDBX-Report.ps1` output and the portal scan-run detail, and review
the source connectivity and rule set with the data owner and your Purview/Azure administrator (and your
Databricks workspace admin for Unity Catalog grants / metastore / network). For evolving or preview
connectors and lineage, verify current availability, connector name, and API versions against Microsoft's
documentation before assuming a defect.
