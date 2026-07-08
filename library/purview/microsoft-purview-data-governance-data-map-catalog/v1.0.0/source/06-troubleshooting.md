# 6. Troubleshooting Guide — Microsoft Purview Data Governance: Data Map, Scanning & Unified Catalog

Use `PURVGOV-Discovery.ps1` for readiness/role/runtime state, `PURVGOV-Report.ps1` for scan and
classification coverage and catalog health, `PURVGOV-Set-Scope.ps1` to (re)record a scope,
`PURVGOV-Register-Source.ps1` (`-WhatIf` by default) to register/scan, and `PURVGOV-Curate-Catalog.ps1`
(`-WhatIf` by default) to curate. All scripts are read-only unless you pass `-Commit`.

## A. Cannot reach the account / token fails
| Symptom | Cause | Remediation |
|---|---|---|
| `Discovery` reports endpoint GAP | Wrong account name or endpoint | Confirm the account name; the endpoint is `https://<account>.purview.azure.com`; re-run `PURVGOV-Discovery.ps1` |
| Token acquisition fails | Not signed in / wrong resource | Run `Connect-AzAccount`; the scripts request a token for `https://purview.azure.net` — confirm your account can obtain it |
| 401/403 on every call | Missing least-privilege role | Assign Data reader (browse) or the specific role the action needs at the collection scope; re-run |
| Calls fail with "api-version" errors | The example API version has moved | The Data Governance experience is evolving — verify and set the current data-plane API version for your tenant |

## B. Source registration or Test connection fails
| Symptom | Cause | Remediation |
|---|---|---|
| Register returns 403 | Not a Data source admin on the collection | Assign Data source admin on `DG-Collection-Pilot`; re-run `PURVGOV-Register-Source.ps1 -Commit` |
| Test connection fails (cloud source) | Managed identity lacks read on the source | Grant the account's managed identity the least read role on the source; re-test |
| Test connection fails (on-prem/private) | No network path | Install and register a self-hosted integration runtime (SHIR) with line of sight to the source; confirm Running; re-test |
| "Credential not found" | Key Vault credential name wrong or vault not linked | Link the Key Vault to the account and reference the credential **by name** (`-KeyVaultCredential`); never inline a secret |
| Unknown source "kind" | Connector name/availability differs | Verify the exact connector `kind` and its availability (some multicloud connectors are preview) in Microsoft's docs |

## C. Scan runs but classifies nothing
| Symptom | Cause | Remediation |
|---|---|---|
| Assets returned, 0 classified | Scan rule set has no classifications | Confirm `DG-ScanRuleSet-Pilot` includes system classifications; re-scan and review with `PURVGOV-Report.ps1` |
| An internal pattern isn't detected | No custom classification rule | Define `DG-Classification-Custom-<name>`, validate against sample data, add to the rule set, re-scan |
| Scan scope too broad / slow / costly | Whole source scanned instead of pilot scope | Re-scope the scan to the bounded pilot assets; keep it one-time until validated |
| Scan status Failed | Transient/auth/network | Open the run in the portal for the failure reason; fix credential/runtime; re-run |

## D. Classifications look wrong
- False positives/negatives are expected on first scan. Review with the **data owner** using
  `PURVGOV-Report.ps1`; tune or remove a custom classification rule and re-scan the pilot scope. The
  solution provides the technical result — the owner decides whether a classification is correct for
  the business.

## E. Unified Catalog curation issues
| Symptom | Cause | Remediation |
|---|---|---|
| Glossary/data-product create returns 403 | Not a Data curator / governance domain owner | Assign the Unified Catalog role for the domain; re-run `PURVGOV-Curate-Catalog.ps1 -Commit` |
| Data product has no owner | Owner not set | Set `-Owner`; every published data product and asset must have a named owner/steward |
| Curation API path 404 / version error | Unified Catalog API evolving | Verify the current Unified Catalog / Atlas glossary and data-product API versions for your tenant |

## F. Lineage is missing
- Lineage populates automatically from **supported** systems (Azure Data Factory, Synapse, Power BI,
  and more) and from scans. If a pilot asset shows no lineage, confirm the producing system is a
  supported lineage source and is connected to Purview; record unsupported systems as known gaps
  rather than expecting lineage from them.

## G. Data quality unavailable
- Data quality may be in **preview** or not enabled for your tenant. If `DG-DQ-Ruleset-Pilot` cannot
  be created, verify the feature's availability and licensing for your tenant; record the step as
  deferred to the expansion phase — it is not a pilot failure.

## H. Diagnostics quick reference
```powershell
.\PURVGOV-Discovery.ps1 -PurviewAccount contoso-purview            # readiness: endpoint, collections, roles, runtimes
.\PURVGOV-Set-Scope.ps1 -Source @('sql-fin-01.contoso.com/FinanceDB')  # record a pilot scope manifest
.\PURVGOV-Register-Source.ps1 -PurviewAccount contoso-purview -Collection DG-Collection-Pilot `
    -SourceName sql-fin-01 -Kind AzureSqlDatabase                 # -WhatIf by default; add -Commit to apply
.\PURVGOV-Report.ps1 -PurviewAccount contoso-purview -Collection DG-Collection-Pilot  # scan + classification coverage
.\PURVGOV-Curate-Catalog.ps1 -PurviewAccount contoso-purview -Glossary -TermName "Customer ID"  # -WhatIf by default
```

## I. When to escalate
If the account is reachable, roles are assigned, the runtime is Running, Test connection passes, and a
scoped scan still returns no classified assets after tuning the rule set, capture the
`PURVGOV-Discovery.ps1` and `PURVGOV-Report.ps1` output and the portal scan-run detail, and review the
source connectivity and rule set with the data owner and your Purview/Azure administrator. For evolving
or preview features, verify current availability and API versions against Microsoft's documentation
before assuming a defect.
