# 6. Troubleshooting Guide — Exchange Online Mailbox Automation with Logic Apps Managed Identity (Graph)

Use `LAMIMAIL-Discovery.ps1` / `LAMIMAIL-Validate.ps1` for identity + permission state, `LAMIMAIL-Test-MailboxAccess.ps1` for the mailbox boundary, and `LAMIMAIL-Report.ps1` for the audit record. `LAMIMAIL-Set-AppRole.ps1` (defaults to -WhatIf) grants/removes the app role. Objects are referenced by their names from `03-implementation.md`.

## A. The trigger won't accept the managed identity (the root cause)
| Symptom | Cause | Fix |
|---|---|---|
| The **Office 365 Outlook** *"When a new email arrives"* trigger has no option to use the managed identity; it only offers a sign-in / OAuth connection | **This is expected — it is the root cause.** The Office 365 Outlook connector authenticates as a **user/service account** via a stored OAuth connection; it is not a managed-identity-aware connector and cannot bind to an MI | **Stop using that connector.** Read the mailbox via a Microsoft Graph **HTTP** action with **Managed identity** authentication (Implementation Step 4). Choose the trigger pattern from a sibling product (change notifications for webhook, polling for polling) |
| A colleague "made it work" with the connector | They pointed the connection at a **licensed service-account mailbox** — reintroducing the stored credential this solution removes | Replace the connection with the Graph + managed-identity design; delete the service-account connection (Testing Test 6) |

> **Verify with Microsoft:** whether any specific Office 365 Outlook connector operation supports managed identity can change — confirm against current Microsoft documentation, but the trigger's user/service-account auth model is the reason the MI approach fails.

## B. Admin consent / permission not granted
| Symptom | Cause | Fix |
|---|---|---|
| Graph call returns **403** and the identity shows no application permission | The `Mail.Read` **app role** was never assigned to the identity's service principal, or admin consent was not given | Grant it: `LAMIMAIL-Set-AppRole.ps1 -IdentityDisplayName la-mailbox-automation-pilot -Execute` (a Global Admin / Privileged Role Admin must run it), or grant via Enterprise Applications → the identity's SP → Permissions. Re-check with `LAMIMAIL-Validate.ps1` |
| The permission name isn't found | Wrong or changed permission name | **Verify the exact application permission name against current Microsoft Graph documentation**; pass it via `-Permission` |
| Consent seems granted but reads still fail immediately | Directory propagation delay | Allow time after granting, then re-run `LAMIMAIL-Test-MailboxAccess.ps1` |

## C. 403 reading the mailbox (scope / permission)
| Symptom | Cause | Fix |
|---|---|---|
| In-scope read of `automation-inbox@contoso.com` returns **403 ErrorAccessDenied** even though `Mail.Read` is granted | The **Application Access Policy** (or Graph RBAC scope) does not include the target mailbox, or the app's AppId is scoped out | Confirm the mailbox is a member of `sg-MailboxAutomation-Scope-Pilot` and the policy binds the identity's **AppId** to it with **RestrictAccess**; allow the scope time to propagate. See the scoping sibling product |
| **Out-of-scope** read **succeeds** (e.g. `ceo@contoso.com` is readable) | **No mailbox scope is in place** — the application `Mail.Read` grant is tenant-wide | This is a security failure. Apply the one-mailbox scope (Implementation Step 3 / scoping sibling) and re-run `LAMIMAIL-Test-MailboxAccess.ps1` until the out-of-scope read is denied |

> **Verify with Microsoft:** whether to use Application Access Policy or Graph RBAC-for-Exchange, and the exact cmdlets/propagation time, are version-dependent — confirm against current Microsoft documentation.

## D. Token / audience errors
| Symptom | Cause | Fix |
|---|---|---|
| Graph HTTP action returns **401** or "invalid audience" / "wrong resource" | The managed-identity authentication's **audience/resource** is not Microsoft Graph | Set the audience to `https://graph.microsoft.com` (or the correct **national-cloud** audience — **verify against current Microsoft documentation**) in the HTTP action's authentication |
| Works in one cloud, fails in GCC High / DoD | National clouds use **different Graph/login endpoints and audiences** | Use the sovereign endpoints/audiences; verify parity and availability against current Microsoft documentation |

## E. Managed identity not enabled / not found
| Symptom | Cause | Fix |
|---|---|---|
| No service principal for `la-mailbox-automation-pilot`; the HTTP action can't select an identity | The identity was never enabled | Logic App → **Identity** → **System assigned** = **On** → Save (Implementation Step 1); or attach `id-mailbox-automation-pilot`. Re-run `LAMIMAIL-Discovery.ps1` |
| User-assigned identity not selectable in the action | It isn't attached to this Logic App, or the SKU references it differently | Attach it on the **Identity → User assigned** tab; **verify Consumption vs Standard referencing against current Microsoft documentation** |

## F. Scripts (Microsoft.Graph) issues
- **`Connect-MgGraph` scopes.** The scripts request delegated scopes such as `Application.Read.All`, `AppRoleAssignment.ReadWrite.All` (write path only, in `LAMIMAIL-Set-AppRole.ps1`), `User.Read.All`, `Directory.Read.All`. Consent to them when prompted. **Verify the exact scope names against current Microsoft Graph documentation.**
- **Exact display-name matching.** Discovery/Validation/Report/Set-AppRole resolve the identity by **exact `displayName`** (`la-mailbox-automation-pilot`). If your Logic App or user-assigned identity uses a different name, pass the exact name via `-IdentityDisplayName` — a mismatch reports "no service principal found."
- **-WhatIf default.** `LAMIMAIL-Set-AppRole.ps1` changes nothing until `-Execute`. If "nothing happened," you were in the default preview mode — re-run with `-Execute`. Use `-Verify` to report the current grant and `-Remove` to roll back.
- **Module missing.** `Install-Module Microsoft.Graph -Scope CurrentUser` (and `Install-Module ExchangeOnlineManagement` for the scope-binding portion of the report). `LAMIMAIL-Validate.ps1`'s workflow-present check additionally uses `Az.LogicApp` when you pass `-LogicAppName`/`-ResourceGroup`.
- **App-only boundary test.** `LAMIMAIL-Test-MailboxAccess.ps1` connects **app-only** with the app's AppId + a certificate (recommended) or secret, so it exercises the same application-permission + scope the Logic App identity uses. **Verify your app-only connection method against current Microsoft Graph documentation.**

## G. When to escalate
If the identity is enabled, `Mail.Read` is granted and consented, the mailbox scope is confirmed and has had time to propagate, the token audience is Graph, and the in-scope read still returns 403 (or the out-of-scope read still succeeds), collect `LAMIMAIL-Report.ps1` output plus the Logic App run history (HTTP action request/response) and open a Microsoft support case.
