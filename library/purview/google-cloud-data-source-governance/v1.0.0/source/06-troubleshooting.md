# 6. Troubleshooting Guide — Google Cloud Data-Source Governance: Microsoft Purview

Use `DGGCP-Discovery.ps1` for readiness/role/runtime state, `DGGCP-Report.ps1` for scan and
classification coverage, `DGGCP-Set-Scope.ps1` to (re)record a scope, `DGGCP-Register-GcpSource.ps1`
(`-WhatIf` by default) to register/scan, and `DGGCP-Test-Readiness.ps1` for the consolidated gate. All
scripts are read-only unless you pass `-Commit` (only `DGGCP-Register-GcpSource.ps1` writes).

## A. Cannot reach the account / token fails
| Symptom | Cause | Remediation |
|---|---|---|
| `Discovery` reports endpoint GAP | Wrong account name or endpoint | Confirm the account name; the endpoint is `https://<account>.purview.azure.com`; re-run `DGGCP-Discovery.ps1` |
| Token acquisition fails | Not signed in / wrong resource | Run `Connect-AzAccount`; the scripts request a token for `https://purview.azure.net` — confirm your account can obtain it |
| 401/403 on every call | Missing least-privilege role | Assign Data reader (browse) or the specific role the action needs at the collection scope; re-run |
| Calls fail with "api-version" errors | The example API version has moved | The Data Governance experience is evolving — verify and set the current data-plane API version for your tenant |

## B. Google BigQuery source registration or Test connection fails
| Symptom | Cause | Remediation |
|---|---|---|
| Register returns 403 | Not a Data source admin on the collection | Assign Data source admin on `DGGCP-Collection-Pilot`; re-run `DGGCP-Register-GcpSource.ps1 -Commit` |
| Unknown source "kind" | Connector name/availability differs | Verify the exact BigQuery connector `kind` and its availability (the connector may be preview) in Microsoft's docs; **Data Map → Sources → Register** must offer Google BigQuery |
| "Credential not found" | Key Vault credential name wrong or vault not linked | Link the Key Vault to the account and reference the credential **by name** (`-KeyVaultCredential DGGCP-Cred-BQ-KV`); never inline a key |
| Test connection fails — auth | Service account lacks read / wrong key / key expired | Grant the service account read-only BigQuery roles (Data Viewer + Metadata Viewer + Job User — verify), regenerate/re-store the private key in Key Vault, confirm the BigQuery API is enabled; re-test |
| Test connection fails — no runtime | No self-hosted integration runtime (SHIR) | BigQuery scans require a **Running SHIR**; install/register one with line of sight to BigQuery and reference it with `-IntegrationRuntime`; re-test |
| Test connection fails — driver | Java/JDBC driver prerequisites missing on SHIR | Install the required Java/JDK and BigQuery driver prerequisites on the SHIR host (verify the current version); restart the SHIR; re-test |

## C. Scan runs but classifies nothing
| Symptom | Cause | Remediation |
|---|---|---|
| Assets returned, 0 classified | Scan rule set has no classifications | Confirm `DGGCP-ScanRuleSet-Pilot` includes system classifications; re-scan and review with `DGGCP-Report.ps1` |
| An internal pattern isn't detected | No custom classification rule | Define `DGGCP-Classification-Custom-<name>`, validate against sample data, add to the rule set, re-scan |
| Scan scope too broad / slow / costly | Whole project scanned instead of pilot datasets | Re-scope the scan to the bounded pilot datasets; keep it one-time until validated; watch BigQuery query/egress cost |
| Scan status Failed | Transient / auth / SHIR / network | Open the run in the portal for the failure reason; confirm the SHIR is Running and the service-account credential resolves; re-run |

## D. Classifications look wrong
- False positives/negatives are expected on first scan. Review with the **data owner** using
  `DGGCP-Report.ps1`; tune or remove a custom classification rule and re-scan the pilot scope. The
  solution provides the technical result — the owner decides whether a classification is correct for
  the business.

## E. Ownership / catalog issues
| Symptom | Cause | Remediation |
|---|---|---|
| Scanned dataset has no owner | Owner not assigned | Assign the owner/steward from the scope manifest in the catalog; every governed asset must have a named owner |
| Cannot edit catalog metadata | Not a Data curator | Assign Data curator at the collection scope; re-try |

## F. SHIR health
- BigQuery scans depend on the self-hosted integration runtime. If scans queue or fail intermittently,
  confirm the SHIR shows **Running/Available**, the host has network line of sight to BigQuery, and the
  Java/driver prerequisites are current. `DGGCP-Discovery.ps1` reports whether a self-hosted runtime is
  registered.

## G. Cost surprises
- Scanning issues read jobs against BigQuery and can incur **query/egress cost**. If cost climbs,
  cancel the run in the portal, re-scope to the bounded pilot datasets, keep scans one-time until a
  scope validates, and enable a schedule only for validated scopes. Agree expected cost with the source
  owner before widening.

## H. Diagnostics quick reference
```powershell
.\DGGCP-Discovery.ps1 -PurviewAccount contoso-purview                      # readiness: endpoint, roles, SHIR, sources
.\DGGCP-Set-Scope.ps1 -ProjectId my-gcp-project -Source @('my-gcp-project/analytics_ds')  # record a pilot scope
.\DGGCP-Register-GcpSource.ps1 -PurviewAccount contoso-purview -Collection DGGCP-Collection-Pilot `
    -SourceName bq-analytics -ProjectId my-gcp-project                     # -WhatIf by default; add -Commit to apply
.\DGGCP-Report.ps1 -PurviewAccount contoso-purview -Collection DGGCP-Collection-Pilot     # scan + classification coverage
.\DGGCP-Test-Readiness.ps1 -PurviewAccount contoso-purview -Collection DGGCP-Collection-Pilot  # consolidated gate
```

## I. When to escalate
If the account is reachable, roles are assigned, the SHIR is Running with the driver prerequisites,
Test connection passes, and a scoped scan still returns no classified assets after tuning the rule set,
capture the `DGGCP-Discovery.ps1` and `DGGCP-Report.ps1` output and the portal scan-run detail, and
review the BigQuery connectivity and rule set with the data owner and your Purview/Azure administrator.
For evolving or preview features, verify current availability, required GCP IAM roles, and API versions
against Microsoft's documentation before assuming a defect.
