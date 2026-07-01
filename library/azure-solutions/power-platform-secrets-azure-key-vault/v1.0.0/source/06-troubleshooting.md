# 6. Troubleshooting Guide — Standardize Power Platform Secrets in Azure Key Vault

Use `PPKV-Validation.ps1` for access/permission-model state, `PPKV-Discovery.ps1` for the vault/secret
inventory and a hardcoded-secret scan of exports, `PPKV-Report.ps1` for expiry/rotation and access,
and `PPKV-Remediation.ps1` for safe fixes.

## A. Secret value showing in flow run history
| Symptom | Cause | Remediation |
|---|---|---|
| The literal secret appears in an action's inputs/outputs in run history | Action not marked secure | Open the action → **Settings** → enable **Secure Inputs** and **Secure Outputs**; enable Secure Inputs on every downstream action that receives the value; re-run and re-check |
| Value still visible after enabling secure on one action | A different action (or a compose/parse) re-exposes it | Trace the value through every action; mark each secure. A value passed into an unsecured action re-appears |
| Value in a variable/compose output | The secret was copied into an unsecured Compose/Set variable | Remove the intermediate, or mark that action secure; prefer passing the env-var reference, not the value |

## B. Env-var / secret not resolving (RBAC or permission-model mismatch)
| Symptom | Cause | Remediation |
|---|---|---|
| Flow/app fails resolving the Secret environment variable | Power Platform service principal lacks `Key Vault Secrets User` | Assign the role (Implementation Step 3) or run `PPKV-Remediation.ps1`; confirm with `PPKV-Validation.ps1` |
| Role assigned but still denied | Vault is on the **legacy access-policy** model, so RBAC roles are ignored | Switch **Access configuration → Permission model** to **Azure RBAC** (requirement 2.2); re-test |
| Resolves in one environment, not another | Wrong vault/secret reference or a different service principal per environment | Confirm the env var points at the correct vault/secret for that environment; verify the SP has the role on **that** vault |
| Intermittent failures | RBAC assignment still propagating | Allow a few minutes for the role assignment to propagate, then retry |

## C. Env var configured but returns empty / old value
| Symptom | Cause | Remediation |
|---|---|---|
| Returns an old value after rotation | The reference is pinned to a specific secret **version** | Re-point the env var / connector at the **versionless** secret reference so it resolves current |
| Returns empty | Secret expired or disabled in the vault | Check the secret's status/expiry (`PPKV-Report.ps1`); enable / add a new version; set a future expiry with `PPKV-Set-RotationOwnership.ps1` |
| Reference invalid | Secret renamed or moved | Update the env-var reference to the current secret name/identifier |

## D. Connector / Function authentication failures (Patterns B and C)
| Symptom | Cause | Remediation |
|---|---|---|
| Azure Key Vault connector `Get secret` returns 403 | The connection's service principal lacks `Key Vault Secrets User` | Assign the role to the app registration `Secrets Reader – <Component> – <Environment>`; recreate the connection if the credential expired |
| Connector connection fails to create | Wrong tenant/client ID or an expired client secret | Verify the app registration's IDs; generate a fresh client secret/certificate and update the connection |
| Function returns 403 from Key Vault | Managed identity not enabled or not granted read | Enable the Function's system-assigned identity; assign it `Key Vault Secrets User` on the vault |
| Function/connector call blocked | Vault firewall denies the caller | Allow the caller's network / trusted Microsoft services, or use a private endpoint (requirement 2.8) |

## E. Vault firewall / networking
- If RBAC is correct but resolution still fails, check the vault **Networking** blade — a restrictive
  firewall blocks the caller regardless of role. Allow the required networks / trusted Microsoft
  services, or reach the vault over a private endpoint.

## F. Hardcoded secret still found in an export
- `PPKV-Discovery.ps1` flags a pattern in exported JSON → open that flow/app/connector, replace the
  literal with the environment-variable reference (Implementation Step 5), re-export, and re-scan
  until clean. Treat any finding as unremediated.

## G. Diagnostics quick reference
```powershell
# Vault permission model + read-role check for the Power Platform SP
.\PPKV-Validation.ps1 -VaultName 'pp-secrets-prod-kv'
# Inventory vaults/secrets/RBAC + scan an export folder for hardcoded-secret patterns
.\PPKV-Discovery.ps1 -ExportPath 'C:\exports\pilot'
# Expiry / rotation / access report (no values printed)
.\PPKV-Report.ps1 -VaultName 'pp-secrets-prod-kv'
```

## H. When to escalate
If the vault is on the RBAC model, the Power Platform service principal holds `Key Vault Secrets
User`, the network path is open, the secret is enabled and referenced versionless, and the env var
still will not resolve, capture the `PPKV-Validation.ps1` output and the exact error and open a
Microsoft support case (Power Platform + Key Vault).
