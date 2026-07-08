# 6. Troubleshooting Guide — Data Estate Insights & Data Quality (Microsoft Purview)

Use `DGINSIGHT-Discovery.ps1` for readiness/role/feature state, `DGINSIGHT-Report.ps1` for the insights
baseline and data-quality scores, `DGINSIGHT-Set-Scope.ps1` to (re)record a scope, `DGINSIGHT-Scope-Health.ps1`
for coverage gaps, and `DGINSIGHT-Configure-Quality.ps1` (`-WhatIf` by default) to author rules and run
scoring. All scripts are read-only except `DGINSIGHT-Configure-Quality.ps1`, which changes nothing
unless you pass `-Commit`.

## A. Cannot reach the account / token fails
| Symptom | Cause | Remediation |
|---|---|---|
| `Discovery` reports endpoint GAP | Wrong account name or endpoint | Confirm the account name; the endpoint is `https://<account>.purview.azure.com`; re-run `DGINSIGHT-Discovery.ps1` |
| Token acquisition fails | Not signed in / wrong resource | Run `Connect-AzAccount`; the scripts request a token for `https://purview.azure.net` — confirm your account can obtain it |
| 401/403 on every call | Missing least-privilege role | Assign a catalog / Data Governance reader (view) or the specific role the action needs at the domain scope; re-run |
| Calls fail with "api-version" errors | The example API version has moved | The insights / Unified Catalog / Data Quality experience is evolving — verify and set the current data-plane API version for your tenant |

## B. Data Quality surface does not respond (feature availability)
| Symptom | Cause | Remediation |
|---|---|---|
| `Discovery` reports Data Quality GAP | Feature not licensed/enabled or in preview | Confirm the required licensing/consumption model and enablement with your Purview/Azure owner; if unavailable in your tenant/region, record the DQ steps as **deferred** — do not assume availability |
| Data Quality reachable but 403 | Missing the data-quality steward role | Assign the **data-quality steward** role on the governance domain (verify current role name); re-run |
| DQ menu absent in the portal | Portal path/name has moved | Verify the current Unified Catalog Data Quality path for your tenant — the experience is evolving |

## C. Insights show no data
| Symptom | Cause | Remediation |
|---|---|---|
| `Report` returns 0 assets | Estate not scanned/catalogued yet | This solution measures a governed estate — stand up the Data Map / scanning / catalog first, then re-baseline |
| Classification distribution empty | Scans applied no classifications | Confirm scans ran with classifications in the Data Map solution; this solution reports what scanning produced, it does not classify |
| Ownership coverage 0% | No owners assigned on assets/data products | Assign owners in the Unified Catalog; unowned assets are a governance gap surfaced by `DGINSIGHT-Scope-Health.ps1` |
| Portal insights view differs from `Report` | Different scope or cache | Align the search scope; the report samples the catalog — for the authoritative view use the portal insights/analytics surface |

## D. The data-quality connection or Test connection fails
| Symptom | Cause | Remediation |
|---|---|---|
| Test connection fails (cloud source) | Managed identity lacks read on the source | Grant the Purview account's managed identity the **least read** role on the source; re-test |
| "Credential not found" | Key Vault credential name wrong / vault not linked | Link the Key Vault to the account and reference the credential **by name**; never inline a secret in a script |
| Test connection fails (on-prem/private) | No network path | Use the appropriate integration runtime with line of sight to the source; confirm it is Running; re-test |
| Scan cannot read the CDE columns | Identity has table but not column access, or wrong asset mapped | Confirm the data product's assets map to the real source columns and the identity can read them; re-map and re-test |

## E. The data-quality scan fails or returns no scores
| Symptom | Cause | Remediation |
|---|---|---|
| Scan status Failed | Transient / auth / compute unavailable | Open the run in the portal for the failure reason; confirm the connection and that Data Quality compute is available; re-run |
| Scan Succeeded, 0 rule scores | Rules not authored / not attached to the data product | Confirm `DGI-DQ-Ruleset-Pilot` exists on `DGI-DataProduct-Pilot` (`DGINSIGHT-Report.ps1`); author with `DGINSIGHT-Configure-Quality.ps1 -Commit`; re-scan |
| Scan runs long / costs too much | Scope too broad (whole source, all columns) | Re-scope to the bounded pilot CDEs; keep it one-time until validated; schedule only after the gate passes |
| `-Commit` seems to do nothing | Ran in default `-WhatIf` | The tool is safe by default — add `-Commit` (and `-RunScan -Commit` to start the scan) |

## F. Scores look wrong
- A false-low or false-high score usually means the **rule or threshold** is wrong, not the data.
  Review with the **data owner** using `DGINSIGHT-Report.ps1`, tune the rule/threshold in
  `DGI-DQ-Ruleset-Pilot`, and re-scan the pilot scope. The solution produces the score; **the owner
  decides what it means and whether the data needs remediation** — a red score is evidence, not a
  compliance ruling, and remediating the underlying data is the owner's action.

## G. Rolling back a rule or scan
- A data-quality scan **reads and scores; it does not modify source data**. To stop a run, cancel it in
  the portal and set the rule set to not scheduled. To back out a mis-authored rule, preview with
  `DGINSIGHT-Configure-Quality.ps1 -Remove -WhatIf`, then apply with `-Remove -Commit`. Re-scope and
  re-run rather than widening scope.

## H. Health / coverage gaps
| Symptom | Cause | Remediation |
|---|---|---|
| `Scope-Health` shows owner GAP | Data product has no named owner | Assign an owner in the Unified Catalog; re-run `DGINSIGHT-Scope-Health.ps1` |
| CDEs-with-rule below total | Some CDEs have no data-quality rule | Author the missing `DGI-DQ-Rule-<Dimension>-<CDE>`; re-run the health check |
| "Never scored" / stale score | Scoring not run or beyond the window | Run/schedule scoring on the data product after the pilot validates; re-check with `-StaleDays` |
| Health-controls surface unavailable | Feature preview/not enabled | `DGINSIGHT-Scope-Health.ps1` reports the same coverage without it — record health-controls as deferred |

## I. Diagnostics quick reference
```powershell
.\DGINSIGHT-Discovery.ps1 -PurviewAccount contoso-purview                                   # readiness: endpoint, domains, data products, DQ availability, roles
.\DGINSIGHT-Set-Scope.ps1 -Domain DGI-Domain-Pilot -DataProduct DGI-DataProduct-Pilot `
    -Cde @('DGI-CDE-CustomerID','DGI-CDE-Email')                                            # record the pilot scope manifest (local only)
.\DGINSIGHT-Configure-Quality.ps1 -PurviewAccount contoso-purview -ScopeFile .\DGI-scope.json          # -WhatIf by default
.\DGINSIGHT-Configure-Quality.ps1 -PurviewAccount contoso-purview -ScopeFile .\DGI-scope.json -RunScan -Commit  # author + start scoring
.\DGINSIGHT-Report.ps1 -PurviewAccount contoso-purview -DataProduct DGI-DataProduct-Pilot   # insights baseline + DQ scores
.\DGINSIGHT-Scope-Health.ps1 -PurviewAccount contoso-purview -Domain DGI-Domain-Pilot -StaleDays 30    # coverage gaps
```

## J. When to escalate
If the estate is reachable and catalogued, roles are assigned, Data Quality is confirmed available, the
connection Test connection passes, and a scoped scan still returns no scores after confirming rules are
authored and attached, capture the `DGINSIGHT-Discovery.ps1` and `DGINSIGHT-Report.ps1` output and the
portal scan-run detail, and review the connection, the CDE-to-column mapping, and the rule set with the
data owner and your Purview/Azure administrator. For evolving or preview features, verify current
availability and API versions against Microsoft's documentation before assuming a defect.
