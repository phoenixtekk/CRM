# 6. Troubleshooting Guide — Scoping Application-Permission Mailbox Access

Use `MBXRBAC-Discovery.ps1` / `MBXRBAC-Validate.ps1` for scoping state, `MBXRBAC-Report.ps1` for the tenant-wide picture, `MBXRBAC-Test-Boundary.ps1` for the live boundary proof, and `MBXRBAC-Set-AccessPolicy.ps1` (defaults to `-WhatIf`) to (re)create the scope. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names.

> **Verify-with-Microsoft note:** every cmdlet, role name, permission name, propagation window, and the choice of scoping model named below is version- and cloud-dependent — **confirm against current Microsoft documentation** before acting.

## A. The policy seems to have no effect / propagation delay
| Symptom | Cause | Remediation |
|---|---|---|
| Boundary test still lets the app read every mailbox right after you create the policy | **Propagation not complete** — new Application Access Policies / RBAC assignments are not instant (commonly cited up to ~30 minutes or longer; *verify with Microsoft*) | Wait the propagation window, then re-run `MBXRBAC-Test-Boundary.ps1`. Don't record a result until propagation completes |
| `Test-ApplicationAccessPolicy` shows the right answer but a live read does not | Cached tokens for the app still carry the old (unscoped) grant | Wait for the app's token to expire / re-acquire, then re-test |

## B. The app still reads ALL mailboxes (out-of-scope NOT denied)
This is the critical failure — the boundary is not in effect. Work through, in order:
1. **Wrong model applied for the situation.** Confirm which model you intended (Application Access Policy vs Graph RBAC for Exchange Online) and that it is the one actually configured. An RBAC assignment does not show up as an Application Access Policy and vice-versa — `MBXRBAC-Discovery.ps1` checks the access-policy path; **verify the RBAC path separately against current Microsoft documentation**.
2. **Policy not bound to this AppId.** Run `MBXRBAC-Validate.ps1`; if it reports "no policy covers the AppId", the policy references a different app. Re-create with the correct `-AppId` (`MBXRBAC-Set-AccessPolicy.ps1`).
3. **`-AccessRight` is the wrong sense.** `RestrictAccess` limits the app **to** the group; `DenyAccess` blocks the app **from** the group. Using `DenyAccess` with an allow-list group produces the opposite of what you want. *Verify the `-AccessRight` values against current Microsoft documentation.*
4. **Propagation** — see section A.
5. **The out-of-scope mailbox is a member of the scope group** — see section D.

## C. The IN-scope read is DENIED (scope too tight)
| Symptom | Cause | Remediation |
|---|---|---|
| `MBXRBAC-Test-Boundary.ps1` fails the in-scope read (403) | The allowed mailbox is **not** a member of `App Mailbox Scope – Reporting – Prod` | Add it: `Add-DistributionGroupMember -Identity "App Mailbox Scope – Reporting – Prod" -Member "reports@contoso.com"`, allow propagation, re-test |
| In-scope read denied even though membership is correct | The app is missing the **permission** itself (e.g. `Mail.Read` not granted/consented) | Grant + admin-consent the specific mail application permission in Entra → the app → API permissions; *verify the exact permission name* |
| RBAC model: in-scope denied | The scoped **role** does not include the needed right, or the scope excludes the mailbox | Re-check the Exchange role and the resource scope filter; *verify role/scope cmdlets with Microsoft* |

## D. Group membership not honored / wrong group type
- **Application Access Policy requires a mail-enabled security group.** A plain security group or a Microsoft 365 group will not scope correctly. `MBXRBAC-Validate.ps1` flags the type; recreate as `New-DistributionGroup -Type Security` if wrong (*verify current cmdlet*).
- **Membership drift** — a mailbox added after the policy was created is only in scope once it is a **member** of `App Mailbox Scope – Reporting – Prod`. Keep membership current; re-run `MBXRBAC-Report.ps1` to see the allowed set.
- **Nested groups** may not be evaluated the way you expect — prefer direct membership; *verify nesting behaviour with Microsoft*.

## E. Graph RBAC for Exchange Online — assignment errors
| Symptom | Cause | Remediation |
|---|---|---|
| `New-ManagementRoleAssignment` / `New-ManagementScope` not recognized or errors | Cmdlet name/parameters differ by version, or the model is not available in this cloud | **Verify the exact cmdlets, role names, and scope-object types against current Microsoft documentation**; confirm availability for your cloud (GCC / GCC High / DoD) before relying on it |
| Assignment created but app still tenant-wide | The service principal object, the role, or the scope is mismatched | Confirm the app's Exchange service principal (`New-ServicePrincipal` if required — *verify*), the role name, and that the scope resolves to the intended mailboxes |
| Not sure which model to use | Availability/recommendation is roadmap-dependent | Pilot the Application Access Policy model first (broadly available, audit-recognized); adopt Graph RBAC as target state only after verifying support |

## F. Scripts — connection, scopes, exact-name matching, -WhatIf
```powershell
# Connect as needed:
Connect-ExchangeOnline -ShowBanner:$false
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All'   # add 'Mail.Read' where a delegated read is used; VERIFY scopes

# Exact-name matching: object names contain an en dash (–), not a hyphen (-). Quote them verbatim:
Get-DistributionGroup -Identity "App Mailbox Scope – Reporting – Prod"

# The state-changer defaults to preview. It changes nothing unless you pass -Apply:
.\MBXRBAC-Set-AccessPolicy.ps1 -AppId "11111111-1111-1111-1111-111111111111"          # WhatIf preview
.\MBXRBAC-Set-AccessPolicy.ps1 -AppId "11111111-1111-1111-1111-111111111111" -Apply    # executes

# Boundary proof authenticates AS THE APP (client credentials or managed identity), not as you.
.\MBXRBAC-Test-Boundary.ps1 -TenantId "<tenant>" -AppId "<appid>" -UseManagedIdentity
```
- **Exact-name matching:** the mail-enabled security group, policy, scope, and assignment names use an **en dash (`–`)**. Copy names verbatim from the Implementation Guide; a hyphen (`-`) will not match.
- **National clouds:** `MBXRBAC-Test-Boundary.ps1` targets `graph.microsoft.com`. For GCC High / DoD use the correct sovereign Graph endpoint — *verify the endpoint against current Microsoft documentation*.

## G. When to escalate
If the correct model is configured against the correct `AppId`, the scope group is a mail-enabled security group with the right membership (or the RBAC scope resolves correctly), the propagation window has elapsed, and the out-of-scope read **still** succeeds, capture `MBXRBAC-Report.ps1` output and the policy/assignment details and open a Microsoft support case — a boundary that will not enforce after correct configuration and propagation is a service-side issue.
