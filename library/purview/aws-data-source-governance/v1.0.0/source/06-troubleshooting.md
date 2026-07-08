# 6. Troubleshooting Guide — AWS Data-Source Governance (S3/RDS): Microsoft Purview

Use `DGAWS-Discovery.ps1` for readiness/role/runtime and AWS-source state, `DGAWS-Report.ps1` for scan
status and classification/ownership coverage, `DGAWS-Set-Scope.ps1` to (re)record a scope,
`DGAWS-Register-AwsSource.ps1` (`-WhatIf` by default) to register/scan, and `DGAWS-Test-Readiness.ps1`
for the consolidated pilot gate. All scripts are read-only unless you pass `-Commit`
(only `DGAWS-Register-AwsSource.ps1` writes).

## A. Cannot reach the account / token fails
| Symptom | Cause | Remediation |
|---|---|---|
| `Discovery` reports endpoint GAP | Wrong account name or endpoint | Confirm the account name; the endpoint is `https://<account>.purview.azure.com`; re-run `DGAWS-Discovery.ps1` |
| Token acquisition fails | Not signed in / wrong resource | Run `Connect-AzAccount`; the scripts request a token for `https://purview.azure.net` — confirm your account can obtain it |
| 401/403 on every call | Missing least-privilege role | Assign Data reader (browse) or the specific role the action needs at the collection scope; re-run |
| Calls fail with "api-version" errors | The example API version has moved | The Data Governance experience is evolving — verify and set the current data-plane API version for your tenant |

## B. Amazon S3 / Amazon RDS connector isn't offered
| Symptom | Cause | Remediation |
|---|---|---|
| No **Amazon S3** or **Amazon RDS** in Register | Connector unavailable/preview for your tenant | Verify licensing/region and Microsoft's current multicloud-connector availability; scope the pilot to the connector(s) actually offered |
| RDS engine not registerable | Engine not in the supported list | Check Microsoft's current supported RDS engine list; if unsupported, defer that database or use an alternative in-scope engine |
| Unknown source "kind" | Connector name differs from `AmazonS3`/`AmazonRDS` | Verify the exact `kind`/`credentialType` names for your tenant before `-Commit` |

## C. S3 source registration or Test connection fails
| Symptom | Cause | Remediation |
|---|---|---|
| Register returns 403 | Not a Data source admin on the collection | Assign Data source admin on `DGAWS-Collection-Pilot`; re-run `DGAWS-Register-AwsSource.ps1 -Commit` |
| Test connection fails: "assume role" denied | Trust policy wrong (Microsoft principal or external ID) | Re-copy the **Microsoft AWS principal and external ID** from the Purview S3 registration UI; fix the IAM role trust policy; re-test |
| Test connection fails: access denied on bucket | Role lacks S3 read | Grant `AmazonS3ReadOnlyAccess` or a bucket-scoped read policy to the role; re-test |
| Encrypted bucket returns nothing / KMS error | Role lacks `kms:Decrypt` | Grant `kms:Decrypt` on the bucket's KMS key to the role; re-test |
| "Credential not found" | Credential name wrong / role ARN not registered | Register the role ARN as a Purview credential **by name** and pass that name (`-Credential`); never inline an ARN or key |

## D. RDS source registration or Test connection fails
| Symptom | Cause | Remediation |
|---|---|---|
| Test connection fails: auth | Wrong/expired DB login or Key Vault secret | Confirm the RDS read login and the Key Vault secret; reference the credential **by name** (`-Credential`); re-test |
| Test connection fails: network/timeout | RDS in a private VPC, no path | Install and register a self-hosted integration runtime (SHIR) with line of sight; open the RDS security group to the scanner; re-test |
| "Credential not found" / Key Vault error | Vault not linked or secret name wrong | Link the Key Vault to the account, store the secret, reference it by name; never inline a secret |
| Publicly-inaccessible instance | RDS `publicly accessible` off + managed IR used | Use a SHIR/managed VNet runtime with VPC access, or adjust network per your security policy |

## E. Scan runs but classifies nothing
| Symptom | Cause | Remediation |
|---|---|---|
| Assets returned, 0 classified | Scan rule set has no classifications | Confirm `DGAWS-ScanRuleSet-Pilot` includes system classifications; re-scan and review with `DGAWS-Report.ps1` |
| An internal pattern isn't detected | No custom classification rule | Define `DGAWS-Classification-Custom-<name>`, validate against sample data, add to the rule set, re-scan |
| Scan scope too broad / slow / costly | Whole bucket set or instance scanned | Re-scope the scan to the bounded pilot buckets/database; keep it one-time until validated |
| Scan status Failed | Transient/auth/network | Open the run in the portal for the failure reason; fix credential/runtime/AWS network; re-run |

## F. AWS request/egress cost higher than expected
- S3 scanning issues list/get requests and can incur AWS request and egress charges; RDS scanning
  consumes instance resources. Keep scans **one-time and bounded** until validated, scope tightly, and
  agree the expected cost with the AWS account owner as part of change control. Cancel a runaway scan in
  the portal (no source data is modified) and re-scope.

## G. Classifications look wrong
- False positives/negatives are expected on first scan. Review with the **data owner** using
  `DGAWS-Report.ps1`; tune or remove a custom classification rule and re-scan the pilot scope. The
  solution provides the technical result — the owner decides whether a classification is correct for
  the business.

## H. Ownership / gate not passing
| Symptom | Cause | Remediation |
|---|---|---|
| `DGAWS-Test-Readiness.ps1` shows "not owned" | Owners not assigned on scanned assets | Assign the owner/steward from the scope manifest to each bucket/database in the catalog; re-run |
| Gate shows no Succeeded scan | Scan not run or Failed | Trigger the one-time scan; fix any Test-connection failure first; re-check |
| Gate shows classification 0 | Rule set / scope issue | See section E; re-scan and re-check |

## I. Diagnostics quick reference
```powershell
.\DGAWS-Discovery.ps1 -PurviewAccount contoso-purview                 # readiness: endpoint, collections, roles, runtimes, AWS sources
.\DGAWS-Set-Scope.ps1 -S3Bucket @('contoso-fin-extracts') -RdsDatabase @('fin-rds-01.contoso.example/FinanceDB')  # record a pilot scope
.\DGAWS-Register-AwsSource.ps1 -PurviewAccount contoso-purview -Collection DGAWS-Collection-Pilot `
    -SourceName s3-fin-extracts -Kind AmazonS3 -BucketOrEndpoint contoso-fin-extracts -Credential DGAWS-Cred-S3-Role  # -WhatIf by default
.\DGAWS-Report.ps1 -PurviewAccount contoso-purview -Collection DGAWS-Collection-Pilot   # scan + classification coverage
.\DGAWS-Test-Readiness.ps1 -PurviewAccount contoso-purview -Collection DGAWS-Collection-Pilot  # consolidated pilot gate
```

## J. When to escalate
If the account is reachable, roles are assigned, the runtime is Running, the S3 role-assume/RDS
credential Test connection passes, and a scoped scan still returns no classified assets after tuning the
rule set, capture the `DGAWS-Discovery.ps1` and `DGAWS-Report.ps1` output and the portal scan-run
detail, and review the source connectivity and rule set with the data owner and your Purview/Azure
administrator (and your AWS account owner for IAM/KMS/network). For evolving or preview connectors,
verify current availability, supported engines, and API versions against Microsoft's documentation
before assuming a defect.
