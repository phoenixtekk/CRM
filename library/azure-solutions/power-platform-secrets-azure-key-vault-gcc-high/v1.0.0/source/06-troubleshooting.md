# Troubleshooting — Standardize Power Platform Secrets in Azure Key Vault (Government / GCC High)

Symptoms, causes, and fixes — with the GCC-High-specific gotchas called out. Work top to bottom; most failures are one of the first four.

> Portals: Azure Government `https://portal.azure.us` · Power Apps (GCC High) `https://make.high.powerapps.us` · Power Platform admin (GCC High) `https://high.admin.powerplatform.microsoft.us`.

---

## 1. "This variable didn't save properly. User isn't authorized to read secrets from 'Azure Key Vault path'."

- **Cause:** the signed-in maker lacks **Key Vault Secrets User** on that vault (access is validated in the background when you save).
- **Fix:** add the maker (or their group `Key Vault Secrets – Makers – <EnvName>`) to **Key Vault Secrets User** on the vault (IAM → Add role assignment), then re-save. Verify with `PPKVG-Validation.ps1`.

## 2. Environment variable saves, but the flow fails to retrieve the secret

- **Cause A — Dataverse principal missing the role.** Dataverse reads the secret on the maker's behalf; it also needs **Key Vault Secrets User**.
  - **Fix:** grant it (implementation §1.4). **GCC High gotcha (verify for GCC High):** the Commercial Dataverse app id `00000007-0000-0000-c000-000000000000` may not be the principal in your GCC High tenant — confirm the real one in **Entra ID → Enterprise applications** before granting. Do not assume the Commercial id resolves.
- **Cause B — provider not registered.** `Microsoft.PowerPlatform` must be **Registered** on the vault's subscription.
  - **Fix:** register it (Subscriptions → Resource providers) or `PPKVG-Remediation.ps1 -Apply`.
- **Cause C — network block** (see §4).

## 3. Everything "looks right" but nothing resolves — you're in the wrong cloud

- **GCC High gotcha.** A Commercial bookmark (`portal.azure.com`, `make.powerapps.com`) or a PowerShell session without `-Environment AzureUSGovernment` operates in a **different cloud** and cannot see your Gov resources.
- **Tells:** vault URI ends in `.vault.azure.net` (should be `.vault.usgovcloudapi.net`); script ARM endpoint is `management.azure.com` (should be `management.usgovcloudapi.net`); sign-in went through `login.microsoftonline.com` not `login.microsoftonline.us`.
- **Fix:** use the `.us` portals (§ header) and connect scripts with `Connect-AzAccount -Environment AzureUSGovernment` (and `Connect-MgGraph -Environment USGov` for Graph). `PPKVG-Validation.ps1` will REVIEW-flag a non-sovereign endpoint.

## 4. Key Vault firewall blocks Power Platform

- **Cause:** the vault firewall is enabled and Power Platform's IPs are not allowed. **Power Platform is NOT covered by "Allow trusted Microsoft services."**
- **GCC High gotcha:** you must allow the **US Gov** Power Platform IP ranges (focus on `AzureCloud.usgovvirginia` / `AzureCloud.usgovtexas`), not the Commercial set.
- **Fix:** vault → **Networking** → add the current Power Platform US Gov IP ranges (from *Power Platform URLs and IP address ranges*, US Gov), or move to **VNet + Private Link** delegated to Power Platform. Re-test the flow.

## 5. Copilot Studio agent won't use the secret (`AllowedBots` error)

- **Cause:** Copilot Studio needs (a) **Key Vault Secrets User** for the **Microsoft Copilot Studio Service** principal, and (b) a scope **tag** on the secret.
- **Fix:** grant the role (verify for GCC High that the principal resolves), then set the tag. The error text gives the exact `{envId}/{schemaName}` — apply it with `PPKVG-Set-ScopeTargeting.ps1 -AllowedBots '<envId>/<schemaName>' -Apply`, or scope the whole environment with `-AllowedEnvironments '<environmentId>'`. Refresh the test pane.

## 6. Secret value appears in flow run history

- **Cause:** **Secure Inputs/Outputs** not enabled on the retrieve step and/or the consuming step.
- **Fix:** on the Dataverse `RetrieveEnvironmentVariableSecretValue` step and any step using the value → **… → Settings** → enable **Secure Inputs** and **Secure Outputs**. **Then treat the exposure as an incident: rotate the secret** (new version in Key Vault).

## 7. Vault is on the vault-access-policy model / access behaves inconsistently

- **Cause:** the service evaluates access via the **Azure RBAC** APIs even when the vault still uses vault access policies, so a policy-only grant can look present but not satisfy the check.
- **Fix:** vault → **Settings → Access configuration** → switch **Permission model** to **Azure role-based access control**, then (re)assign **Key Vault Secrets User**. `PPKVG-Remediation.ps1 -Apply` does the switch.

## 8. `Register-AzResourceProvider` / `New-AzRoleAssignment` fails or hits the wrong subscription

- **Cause:** not connected to Azure Government, wrong subscription context, or insufficient rights (need **Owner**/**User Access Administrator** to assign RBAC).
- **Fix:** `Connect-AzAccount -Environment AzureUSGovernment`; `Set-AzContext -Subscription 'your-subscription-id'`; confirm your role in IAM. Re-run in preview before `-Apply`.

## 9. Cross-tenant / cross-cloud reference errors

- **Cause:** the Key Vault and the Power Platform environment are not in the **same tenant**, or the vault is a Commercial vault while Power Platform is GCC High.
- **Fix:** the vault must be an **Azure Government** vault in the **same Entra Government tenant** as the environment. Recreate the vault in the correct subscription/tenant if needed.

## 10. Script can't find modules or the Dataverse/Copilot principal

- **Modules:** `Install-Module Az -Scope CurrentUser` (needs Az.Accounts, Az.KeyVault, Az.Resources); `Install-Module Microsoft.Graph` if using Graph steps.
- **Principal not resolvable:** this is expected in GCC High and is **why the scripts REVIEW-flag it** — confirm the Dataverse and Copilot Studio Service principals manually in **Entra ID → Enterprise applications** and grant Key Vault Secrets User to the confirmed object. Flagged **verify for GCC High** throughout.

---

## Escalation checklist (capture before opening a support case)

1. `PPKVG-Validation.ps1` output (overall result + the failing control).
2. `PPKVG-Report.ps1` HTML (vaults, models, Secrets User assignments — no secret values).
3. The confirmed **Dataverse principal object id** you granted (the GCC High verification artifact).
4. Which cloud/endpoints you used (must be the `.us` / `usgovcloudapi.net` set).
5. A flow run history screenshot showing the secret **masked** (never include an exposed value in a ticket).
