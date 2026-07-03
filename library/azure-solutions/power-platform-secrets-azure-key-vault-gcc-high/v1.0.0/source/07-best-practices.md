# Best Practices — Standardize Power Platform Secrets in Azure Key Vault (Government / GCC High)

Durable practices for running this pattern well on a **GCC High** tenant. GCC-High-specific guidance is called out; where a point is not confirmed in public US Gov docs it is flagged **"verify for GCC High."**

## Vault design

- **One vault per Power Platform environment.** Isolate blast radius; a breach or misconfiguration of one environment's vault does not expose another's secrets. Name each `PowerPlatform Secrets – <EnvName> – Prod` and reuse the name verbatim.
- **Use the Azure RBAC permission model, not vault access policies.** Power Platform evaluates access through the Azure RBAC APIs regardless, so RBAC is the unambiguous, current-guidance choice. Switch legacy vaults over.
- **Keep the vault in the same tenant and the same sovereign cloud** as the Power Platform environment. Cross-tenant references are unsupported, and a Commercial (`vault.azure.net`) vault is unreachable from GCC High Power Platform — always use `vault.usgovcloudapi.net`.
- **Never put export-controlled or sensitive data in resource names.** Azure Government resource names are not the place for ITAR/CUI markings.

## Access control (least privilege on GCC High)

- **Grant Key Vault Secrets User to a named group**, not to individuals — `Key Vault Secrets – Makers – <EnvName>`. Manage membership, not dozens of role assignments.
- **Grant only Key Vault Secrets User** to Dataverse and makers — not Contributor or Key Vault Administrator. Secrets User is read-of-secret-value only; management stays separate.
- **PIM/JIT is not available in Azure Government.** You cannot make these roles "eligible" with just-in-time activation. Achieve least privilege with **tightly scoped standing RBAC groups** + **Conditional Access** (named locations, device/compliance) rather than JIT elevation. Review membership on a schedule.
- **Confirm the Dataverse first-party principal for GCC High (verify for GCC High).** Do not blindly grant the Commercial app id `00000007-0000-0000-c000-000000000000`; verify the actual principal in Entra ID → Enterprise applications and document its object id as an engagement artifact.

## Secret hygiene

- **Set an expiration on every secret** and rotate on a schedule. `PPKVG-Report.ps1` flags secrets with no expiry.
- **Rotate in Key Vault, not in Power Platform.** The environment variable references the secret by location, so a new version flows through without touching Power Platform. This is the core payoff of the pattern.
- **Standardize secret names** (`Secret – <SystemName> – <EnvName>`) so references, audits, and rotation are predictable.
- **Consumers only:** environment-variable secrets work with **Power Automate flows, custom connectors, and Copilot Studio agents** — not general canvas-app formulas or the Web API. Design around that supported surface; don't try to read the value elsewhere.

## Flow / consumer safety

- **Always enable Secure Inputs and Secure Outputs** on the Dataverse `RetrieveEnvironmentVariableSecretValue` step and on any step that uses the value, so secrets never appear in run history.
- **Never log or output the secret value.** Not in flow compose steps, not in traces, not in the scripts. The provided scripts read metadata only by design — keep any custom automation to the same rule.

## Network posture

- **Prefer VNet + Private Link** for production so the vault has no public exposure; the private endpoint sits on the Power-Platform-delegated subnet.
- **If you use the Key Vault firewall, allow the Power Platform US Gov IP ranges explicitly** — Power Platform is **not** included in "Allow trusted Microsoft services." Use the **US Gov** IP set (`AzureCloud.usgovvirginia` / `AzureCloud.usgovtexas`), refreshed periodically.

## Operational discipline

- **Run the read-only scripts before any change** and the validation script after — the WhatIf-by-default remediation script should always be previewed first.
- **Keep a per-environment governance report** (`PPKVG-Report.ps1`) as recurring evidence for auditors: vaults, permission models, secret names/expiry/tags, and Secrets User assignments — all without a single secret value.
- **Change control:** treat provider registration, RBAC changes, and network lockdown as change-managed actions (global requirement G5) with a rollback (G6): capture the prior IAM/network state before applying.
- **Watch for parity drift.** GCC High capabilities can lag Commercial; re-check the Business Applications US Government availability summary before relying on any newer feature, and flag anything unconfirmed as **"verify for GCC High."**
