# Testing & Validation — Standardize Power Platform Secrets in Azure Key Vault (Government / GCC High)

Each test is **pass/fail** and maps to a phase gate in `03-implementation.md`. Run them in order. All PowerShell tests connect to the sovereign cloud (`-Environment AzureUSGovernment`) and read **metadata only — never secret values**.

> Portals: Azure Government `https://portal.azure.us` · Power Apps (GCC High) `https://make.high.powerapps.us` · Power Platform admin (GCC High) `https://high.admin.powerplatform.microsoft.us`.

---

## T0. Cloud/context sanity (Gate 0)

| Step | Expected (PASS) | FAIL means |
| --- | --- | --- |
| Sign in to `portal.azure.us`; check directory | Directory = your GCC High / Entra Government tenant | You are in Commercial (`portal.azure.com`) — wrong cloud |
| `PPKVG-Discovery.ps1` runs and prints ARM endpoint | ARM = `management.usgovcloudapi.net` | Endpoint is `management.azure.com` → not connected to Gov |
| Vault URIs in the report | End in `.vault.usgovcloudapi.net` | `.vault.azure.net` → vault is in Commercial |

---

## T1. Configuration controls (Gate 1)

Run: `powershell -ExecutionPolicy Bypass -File .\PPKVG-Validation.ps1 -VaultName 'your-vault-name' -SecretName 'your-secret-name'`

| Control | PASS | FAIL |
| --- | --- | --- |
| Sovereign endpoint | ARM on `usgovcloudapi.net` | Commercial endpoint |
| `Microsoft.PowerPlatform` provider | Registered | NotRegistered → run remediation |
| Key Vault exists | Found in subscription | Not found / wrong subscription |
| Permission model | Azure RBAC | Vault access policy (REVIEW → switch to RBAC) |
| Key Vault Secrets User | ≥1 assignment at vault scope | None → Dataverse + makers cannot read |
| Dataverse principal | Present (confirm object id) | REVIEW — **verify for GCC High** in Enterprise applications |
| Network access | Reachable (public allowed, or IPs/Private Link configured) | Firewall blocks Power Platform |
| Target secret | Secret name exists (value not read) | Secret missing |

**Gate 1 PASS = overall PASS with the Dataverse principal manually confirmed for GCC High.**

---

## T2. Pilot functional test (Gate 2)

| Step | Expected (PASS) | FAIL means |
| --- | --- | --- |
| Save the environment-variable secret in `make.high.powerapps.us` | Saves with no authorization error | Maker lacks Key Vault Secrets User (R5) |
| Run the test cloud flow with **RetrieveEnvironmentVariableSecretValue** | Flow succeeds; secret resolves | Provider/role/network/secret-name issue (see T1) |
| Inspect flow **run history** | Secret value is **masked/absent** (Secure Outputs on) | Value visible → Secure In/Out not enabled — remediate immediately |

---

## T3. Validation gates (Gate 3)

| Test | How | PASS |
| --- | --- | --- |
| Access enforced | Sign in as a user **not** in the makers group and try to save an env-var secret | Denied with the "isn't authorized" error |
| Network posture | Enable the vault firewall with US Gov IP allowances (or Private Link), re-run the flow | Flow still resolves the secret |
| Rotation | Add a **new version** of the secret in the portal; re-run the flow | New value used with no env-var edit |
| Governance hygiene | `PPKVG-Report.ps1` | Findings section empty (RBAC everywhere, provider registered, secrets have expiry) |

### T3a. Copilot Studio (only if in scope)

| Test | PASS |
| --- | --- |
| Copilot Studio Service principal has Key Vault Secrets User (**verify for GCC High**) | Role present |
| Scope tag set via `PPKVG-Set-ScopeTargeting.ps1 -Apply` | `AllowedBots` or `AllowedEnvironments` tag on the secret |
| Agent topic resolves the secret in the test pane | Value returned; no `AllowedBots` error |

---

## T4. Expand acceptance (Gate 4 / exit)

| Test | PASS |
| --- | --- |
| Each environment has its own vault on RBAC | `PPKVG-Report.ps1` shows one vault per env, all RBAC |
| Migration backlog cleared | No plaintext secrets remain in flows/connectors/config tables |
| Operators trained | Runbooks in `ADMIN_DOCS` acknowledged; troubleshooting guide reviewed |

---

## Evidence to capture

- `PPKVG-Discovery` CSV, `PPKVG-Validation` console output (overall PASS), and `PPKVG-Report` HTML per environment.
- A screenshot of a flow run history showing the secret **masked** (proves Secure Outputs).
- The confirmed **Dataverse principal object id** used for the Key Vault Secrets User grant (the GCC High verification artifact).

> None of the evidence should ever contain a secret **value**. If a value appears anywhere, treat it as an incident: rotate the secret and fix Secure Inputs/Outputs.
