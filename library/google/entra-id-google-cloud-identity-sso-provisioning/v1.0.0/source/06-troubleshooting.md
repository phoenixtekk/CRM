# 6. Troubleshooting Guide — Entra↔Google SSO & Provisioning

Use `GWSSO-Discovery.ps1` for the Entra-side identity state, `GWSSO-Report.ps1` for coverage and
exceptions, `GWSSO-Validation.ps1` for per-user SSO/provisioning conformance, and
`GWSSO-Remediation.ps1` (preview first) for safe fixes. **Google-side** state — the SSO profile,
provisioned users/groups, GCDS runs — is confirmed in the Google Admin console and GCDS.

## A. Discovery / validation / report returns nothing or errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes missing | SDK not installed, or read scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept `Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, `Synchronization.Read.All`, `User.Read.All` |
| The Google gallery app is not found | The "Google Cloud / G Suite Connector by Microsoft" app is not added, or you are in the wrong tenant | Add it from the gallery (Implementation Step 1); confirm the tenant |
| Provisioning job not listed | `Synchronization.Read.All` not granted, or provisioning never configured | Re-run and consent the synchronization read scope; if truly none, configure provisioning (Path A) |

## B. SSO fails — users cannot sign in to Google
| Symptom | Cause | Remediation |
|---|---|---|
| "cannot sign in" / wrong user after enabling SSO | **NameID does not match** the Google account email / verified domain | In the Entra app, map the **Unique User Identifier (NameID)** to **user.mail** (not user.userprincipalname); ensure it equals the Google `primaryEmail` on a verified domain |
| Users on `*.onmicrosoft.com` fail | Google rejects `*.onmicrosoft.com` identities | Move affected UPNs to the verified custom domain; re-test |
| SSO loop or "invalid assertion" | Identifier/Entity ID vs domain-specific-issuer mismatch, or ACS/certificate wrong | Make the Entra **Identifier** and the Google **"Use a domain-specific issuer"** choice agree; re-copy the ACS/Reply URL and re-upload the Base64 certificate |
| Wrong sign-out behavior | Default logout URL is incorrect | Use `https://login.microsoftonline.com/common/wsfederation?wa=wsignout1.0` as the sign-out URL |
| Admin locked out of Google | SSO enforced with no break-glass path | Sign in as the cloud-only Google **super-admin** whose SSO profile is **none**; keep this path always available |

## C. Provisioning — users/groups not appearing in Google (SCIM, Path A)
| Symptom | Cause | Remediation |
|---|---|---|
| Test Connection / Authorize fails | Google admin account lacks **Admin API privileges**, or API Controls trust not set | Google **Account → Admin roles** → enable all **Admin API privileges**; **Security → Access and data control → API Controls → "Trust internal, domain-owned apps" → SAVE**; re-**Authorize** |
| Users not provisioned | Users not **assigned**/in scope, or provisioning not started | Assign the users/groups to the app (or set a scoping filter); **Start provisioning**; use **on-demand provisioning** to test a user |
| Groups exist but memberships/attributes wrong | Group or user attribute mapping incomplete | Review **Attribute Mapping → users** (matching = `primaryEmail`) and **→ groups** (email, name, members) |
| Provisioning went to quarantine | Repeated failures (often auth/permission) | Check the **provisioning logs** and quarantine email; fix the Google admin permission/credential and resume |
| A user has an existing consumer Google account on that email | Conflicting personal account | Use Google's **Transfer Tool** for unmanaged accounts before syncing that user |

## D. Provisioning — GCDS (Path B)
| Symptom | Cause | Remediation |
|---|---|---|
| Simulation shows unexpected deletes/changes | OU/attribute mapping rules too broad or misconfigured | Correct the GCDS mapping rules; re-**simulate** and review before any real sync (per Google's GCDS docs) |
| GCDS cannot read AD | No LDAP line-of-sight / wrong bind account | Run GCDS on a host with LDAP access to AD (not the DC); fix the LDAP connection settings |
| Sync not recurring | No scheduled task | Schedule GCDS for continuous provisioning after the pilot sync validates |

## E. Two sources of truth — drift and conflicts
| Symptom | Cause | Remediation |
|---|---|---|
| Objects flip-flop / conflict | Same users mastered by **both** SCIM push (Entra) and GCDS pull (AD) | Pick **one** master per object; disable the other mechanism for those objects (Requirement 2.3) |
| Leavers keep access | JIT used as the "source of truth"; no de-provisioning | Use SCIM push or GCDS for lifecycle so removals flow through; treat JIT as convenience only |

## F. De-provisioning did not remove access
| Symptom | Cause | Remediation |
|---|---|---|
| Removed user still active in Google | Expected behavior — SCIM **suspends**, does not hard-delete; or the user was removed from *scope* without disabling | Confirm the user is **suspended** in Google (access removed). Removing from sync scope disables, it does not delete the object; delete in Google only per your retention policy |
| GCDS did not suspend the leaver | AD object not removed/disabled, or next run not executed | Disable/remove the AD object; run/await the next GCDS sync |

## G. Coverage report shows gaps
- A user who is **federated but not provisioned** (or vice versa) is a gap. Decide: bring them into
  scope with `GWSSO-Remediation.ps1` (preview, confirm, apply), or record a **deliberate exception**
  (e.g. a service account intentionally not federated) with an owner and review date. The report should
  never contain silent, unexplained gaps.

## H. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Synchronization.Read.All','User.Read.All' -NoWelcome
# find the Google gallery app service principal + its SSO mode
Get-MgServicePrincipal -Filter "startswith(displayName,'Google')" | Select-Object DisplayName, AppId, PreferredSingleSignOnMode
# is there a SCIM provisioning (synchronization) job on it?
Get-MgServicePrincipalSynchronizationJob -ServicePrincipalId your-service-principal-id
# verified custom domains (must match Google; no onmicrosoft.com for in-scope users)
Get-MgDomain | Where-Object IsVerified | Select-Object Id, IsDefault
```

## I. When to escalate
If admins are locked out of Google and the break-glass super-admin path also fails, or provisioning is
mass-suspending users unexpectedly, **stop the change**: set the SSO profile to **none** for the
affected scope and **Stop provisioning** in the Entra app (existing objects remain), then engage the
Google Workspace admin owner and your change-control/incident process before re-enabling.
