# 6. Troubleshooting Guide — Managed Identities for Azure Logic Apps & Functions

Use `MIM365-Discovery.ps1` / `MIM365-Validate.ps1` for identity and permission state, `MIM365-Report.ps1` for the estate inventory, and `MIM365-Find-StoredCredentials.ps1` for the migration worklist. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names. Version/feature/endpoint specifics below are flagged **_verify against current Microsoft documentation_** — do not treat them as asserted fact.

## A. Managed identity not enabled / not found
| Symptom | Cause | Remediation |
|---|---|---|
| HTTP action or code has no identity to use | System-assigned not turned on, or user-assigned not attached | Implementation Step 1: set **Identity → System assigned = On**, or attach `Graph Automation Identity – Contoso – Prod`; confirm with `MIM365-Discovery.ps1` |
| User-assigned identity attached but token still fails | Code/action did not select the specific identity | For a user-assigned identity, pass its **Client ID** (`ManagedIdentityClientId`) in code, or select it explicitly in the Logic App action |

## B. Permission / admin consent missing
| Symptom | Cause | Remediation |
|---|---|---|
| Call returns 403 / "insufficient privileges" | The application app-role was never granted, or consent not given | Run `MIM365-Set-AppRole.ps1 -ManagedIdentityObjectId <id> -GraphAppRole '<perm>' -Execute`; grant admin consent. Requires Privileged Role Administrator / Global Admin |
| App-role assignment succeeded but access still denied | Consent/propagation delay, or wrong permission name | Allow propagation; re-check with `MIM365-Validate.ps1`. *Verify the exact permission name/scope against current Microsoft documentation — do not assume it.* |

## C. 403 / insufficient privileges on a mailbox call
- The application permission may be granted but **tenant-wide and not scoped**, or scoped to a **different** mailbox than the call targets. Application mail permissions are constrained by companion product **#4 "Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online."**
- Confirm the mailbox the workflow targets is **within** the #4 scope (Application Access Policy or Graph-for-Exchange RBAC scope). *Verify which scoping model applies to your tenant against current Microsoft documentation.* This guide grants least privilege; #4 owns the mailbox scoping.

## D. Token audience / scope errors
| Symptom | Cause | Remediation |
|---|---|---|
| "Invalid audience" / "wrong resource" | Token requested for the wrong resource/audience | Logic App action: set **Audience = `https://graph.microsoft.com`**. Function: request `https://graph.microsoft.com/.default`. *Verify the audience/resource URI and Graph host for your cloud against current Microsoft documentation* |
| Works in commercial, fails in a national cloud | Sovereign-cloud endpoints differ (Graph host, authority, audience) | Target the correct sovereign endpoints and set the credential's authority for that cloud. *Verify the exact `.us` (or other) endpoints against current Microsoft documentation* |

## E. User- vs system-assigned confusion
- **Symptom:** a Function using `DefaultAzureCredential` picks the wrong identity, or fails when two identities are present.
- **Cause:** with a user-assigned identity attached, `DefaultAzureCredential` needs the **Client ID** to disambiguate; without it, it may not resolve the intended identity.
- **Remediation:** pass `ManagedIdentityClientId = "<user-assigned Client ID>"` for a user-assigned identity, or omit it and rely on system-assigned. Do not enable both and leave the code ambiguous. Confirm which identity holds the grant with `MIM365-Validate.ps1`.

## F. Azure Functions credential not resolving
| Symptom | Cause | Remediation |
|---|---|---|
| `DefaultAzureCredential` throws "no credential available" | Running locally (no managed identity), or identity not enabled on the Function App | In Azure, ensure the identity is enabled/attached (Step 1). Locally, `DefaultAzureCredential` falls back to developer credentials — expected; test in Azure |
| Credential resolves but Graph SDK call fails to compile / run | SDK package/class/method names differ by version | *Verify the current Azure.Identity and Microsoft.Graph SDK package names, classes, and method signatures against current Microsoft documentation* — they change between versions |

## G. Connector action won't use a managed identity
- Not every **Office 365 Outlook** connector action supports managed-identity auth. *Verify which connector operations support managed identity against current Microsoft documentation.*
- **Remediation:** use the **direct Graph HTTP call** (Implementation Step 3) instead of the connector — the robust, secret-free pattern. The mailbox siblings #1 (replace-the-connector), #2 (change-notifications), and #3 (polling) show these Graph calls end-to-end.

## H. Stored credential still flagged after migration
- `MIM365-Find-StoredCredentials.ps1` still lists a migrated workflow → the old **API connection** or **secret app setting** was not removed. Complete Implementation Step 6: delete the saved connection / secret app setting once managed-identity parity is confirmed, then re-run the finder — it should drop off.

## I. Diagnostics quick reference
```powershell
# Which compute has an identity + what app-roles it holds:
.\MIM365-Discovery.ps1

# PASS/FAIL a specific resource against expected least privilege:
.\MIM365-Validate.ps1 -ResourceName 'Graph Automation LogicApp - Contoso - Pilot' -ResourceGroup '<rg>' -ExpectedAppRoles 'Mail.Read'

# Estate inventory + CSV:
.\MIM365-Report.ps1

# Migration worklist (who still uses a stored credential):
.\MIM365-Find-StoredCredentials.ps1

# Grant one least-privilege app-role (preview first, then -Execute):
.\MIM365-Set-AppRole.ps1 -ManagedIdentityObjectId '<identity object id>' -GraphAppRole 'Mail.Read'
```

## J. When to escalate
If the identity is enabled, the expected app-role is granted and consented, the audience/endpoints are correct for the cloud, and a Graph call still fails after the normal propagation window, collect `MIM365-Report.ps1` output and the identity/permission details and open a Microsoft support case. *Confirm current permission names, connector support, Consumption-vs-Standard behaviour, and sovereign-cloud endpoints against current Microsoft documentation before escalating.*
