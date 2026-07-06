# 6. Troubleshooting Guide — Enterprise Integration Patterns

Use `GWINTEG-Discovery.ps1` for the Entra-side estate, `GWINTEG-Report.ps1` for coverage/exceptions and
credential/scope risk, `GWINTEG-Validation.ps1` for pattern conformance, and `GWINTEG-Remediation.ps1`
(preview first) for safe fixes. Google-side and third-party-app state is confirmed in those consoles.

## A. Discovery or report returns nothing / errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes missing | SDK not installed, or read scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept `Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, `Synchronization.Read.All` |
| Empty results | Signed in to the wrong tenant, or an app-read role missing | Confirm the tenant; ensure the operator holds `Application Administrator` / `Cloud Application Administrator` |
| Provisioning jobs not listed | `Synchronization.Read.All` not granted | Re-run and consent the synchronization read scope |

## B. Entra↔Google SSO fails (P1)
| Symptom | Cause | Remediation |
|---|---|---|
| Users cannot sign in to Google after enabling SSO | NameID does not match the Google primary domain | In the Entra "Google Cloud / Google Workspace" app, map the NameID claim to a value matching the verified Google domain |
| SSO loop or "invalid assertion" | ACS URL / Entity ID mismatch between Entra and the Google SAML profile | Re-copy Google's ACS URL and Entity ID into Entra, and Entra's IdP metadata into the Google SSO profile |
| Admin locked out of Google | SSO enforced with no break-glass path | Sign in as the cloud-only Google **super-admin** excluded from SSO; keep this path always available |

## C. Provisioning drift or duplicates (P2/P3)
| Symptom | Cause | Remediation |
|---|---|---|
| Objects conflict or flip-flop | Same object mastered by **both** SCIM push (P2) and GCDS pull (P3) — two sources of truth | Pick one master per object; disable the other for those objects |
| Users not provisioned into Google | Users not assigned/in scope of the Entra provisioning app, or SCIM not started on Google | Assign users/groups to the app; confirm the Google SCIM endpoint is enabled and provisioning is started |
| Leavers keep access | De-provisioning not configured — JIT used as the source of truth | Use P2/P3 for lifecycle so removal flows through; treat JIT as convenience only |
| Wrong OU placement | Attribute/OU mapping incomplete | Correct the provisioning attribute mappings (or GCDS mapping rules) |

## D. Third-party app SSO/provisioning (P5/P6)
| Symptom | Cause | Remediation |
|---|---|---|
| App SSO works but provisioning does not | The app does not support SCIM from the chosen IdP, or the endpoint/token is wrong | **Verify the app's current capability in the vendor's docs**; use the app's supported connector/import where SCIM is unavailable (e.g. some ServiceNow configurations) |
| Users authenticate but have no/incorrect roles | Roles not carried in the assertion/token, or group→role mapping missing | Map groups/claims to app roles (P5 authZ); do not use per-user local admin |
| Local app accounts still in use | Snowflake — app not federated | Move the app to federated SSO (P5) and disable local passwords |
| SAP federation behaves unexpectedly | Brokering topology (SAP identity/BTP service → enterprise IdP) not as assumed | **Verify the exact SAP brokering topology in the vendor's docs and your tenant** before troubleshooting further |

## E. API / data access (P7)
| Symptom | Cause | Remediation |
|---|---|---|
| Integration over-permissioned in the report | Scopes granted beyond what the integration uses | Cut to least privilege; prefer read-only scopes where it only reads |
| Long-lived shared secret flagged | Credential sprawl anti-pattern | Move to OAuth client-credentials / workload identity federation (short-lived, no stored secret); assign a named owner |

## F. Coverage/exception report shows unclassified integrations
- An integration that matches no catalog pattern is a **snowflake** by definition. Decide: bring it to
  the matching pattern (P1–P7) via `GWINTEG-Remediation.ps1` (preview, confirm, apply), or record it as
  a **deliberate exception** with an owner and review date in the exception register. The report should
  never contain silent, unexplained snowflakes.

## G. A legitimate integration broke after remediation
| Symptom | Cause | Remediation |
|---|---|---|
| App or job fails after a grant/scope was changed | The removed permission was actually in use | Re-grant it (change is reversible); always run `GWINTEG-Remediation.ps1` in `-WhatIf` first and confirm with the app owner before applying |

## H. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Synchronization.Read.All' -NoWelcome
# SSO/federation + provisioning apps (service principals with SSO mode or a sync job)
Get-MgServicePrincipal -All | Select-Object DisplayName, AppId, PreferredSingleSignOnMode
# provisioning (synchronization) jobs on an app
Get-MgServicePrincipalSynchronizationJob -ServicePrincipalId your-service-principal-id
# an app's granted application permissions and delegated grants (scope/least-privilege review)
Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId your-service-principal-id
Get-MgOauth2PermissionGrant -Filter "clientId eq 'your-service-principal-id'"
```

## I. When to escalate
If an integration cannot be attributed to any owner, holds broad application permissions or a
long-lived shared secret, and shows unexpected activity, treat it as a potential compromise: revoke its
grants and credentials, disable the service principal (`AccountEnabled` false), and engage your
incident-response process.
