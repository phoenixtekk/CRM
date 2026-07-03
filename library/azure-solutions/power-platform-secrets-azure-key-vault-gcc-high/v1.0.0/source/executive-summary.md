# Executive Summary — Standardize Power Platform Secrets in Azure Key Vault (Government / GCC High)

## The problem

Power Platform makers need secrets — API keys, client secrets, connection strings — to run cloud flows, custom connectors, and Copilot Studio agents. Without a standard, those secrets end up pasted in plaintext inside flow steps and configuration tables: unrotatable, unauditable, and one screenshot away from exposure. For a **government (GCC High)** organization handling ITAR/CJIS-regulated data, that is an unacceptable control gap.

The compounding risk on GCC High: the sovereign cloud is **not** the Commercial portal with a different sign-in. The admin URLs differ (`*.us`), identity runs through Microsoft Entra Government, PowerShell must target Azure Government, and some management conveniences (like PIM/JIT) are absent. Teams that follow Commercial instructions configure the wrong endpoints and hit silent failures.

## The solution

Standardize on the Microsoft-supported pattern: **store every secret in Azure Key Vault and reference it from Power Platform via an environment variable of type Secret.** The value stays in Key Vault; Power Platform holds only a reference. Rotation happens once, in one place; access is governed by Azure RBAC; every read is auditable.

This **Government (GCC High) edition** delivers that pattern authored for the US sovereign cloud — correct `*.us` portals, `vault.usgovcloudapi.net` endpoints, US Gov Graph/Az connections, and an explicit **Commercial-vs-GCC-High parity map** so the tenant is configured right the first time.

## What's delivered

- A phased, click-to-implement runbook (**Assess → Configure → Pilot → Validate → Expand**) using the GCC High portals, with parity caveats inline.
- **Five PowerShell scripts** — discovery, validation, governance reporting, WhatIf-by-default remediation, and a Copilot Studio scope-tag builder — all on US Gov endpoints, all **metadata-only (they never read secret values)**.
- Requirements, testing gates, troubleshooting, best practices, and a **cited GCC High parity reference**.

## The three biggest Commercial-vs-GCC-High differences

1. **Different portals and endpoints.** Maker `make.high.powerapps.us`, admin `high.admin.powerplatform.microsoft.us`, Azure `portal.azure.us`, Key Vault `vault.usgovcloudapi.net`, ARM `management.usgovcloudapi.net`, sign-in `login.microsoftonline.us`. PowerShell must use `-Environment AzureUSGovernment`.
2. **The Dataverse first-party principal must be verified, not assumed.** The Commercial Dataverse app id (`00000007-…`) may not be the principal to grant in GCC High; the solution flags this "verify for GCC High" and confirms the real object before granting Key Vault Secrets User.
3. **No PIM/JIT in Azure Government.** Least privilege is achieved with scoped standing RBAC groups + Conditional Access instead of just-in-time elevation — the role design reflects this.

## Outcome

Power Platform secrets are centralized, rotatable, RBAC-governed, and auditable — deployed correctly on GCC High, proven on a pilot before scale, at a fraction of the cost of a bespoke consulting engagement.
