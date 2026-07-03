# Deliverables Summary — Standardize Power Platform Secrets in Azure Key Vault (Government / GCC High)

Everything included in this solution and where to find it.

## Documents (`source/`)

| File | What it covers |
| --- | --- |
| `executive-summary.md` | One-page business case + the three biggest Commercial-vs-GCC-High differences. |
| `01-solution-overview.md` | What the solution does, the deployment model, and the **Commercial vs GCC High — what's different** section. |
| `02-requirements.md` | Prerequisites R1–R8 with Verify / Implement-if-missing, layered on the global Azure requirements. |
| `03-implementation.md` | Ordered click-to-implement steps using the GCC High portals, with parity caveats inline and phase gates. |
| `05-testing.md` | Pass/fail tests mapped to each phase gate; evidence to capture. |
| `06-troubleshooting.md` | GCC-High-specific symptoms, causes, and fixes. |
| `07-best-practices.md` | Durable operating practices (vault design, least privilege without PIM, hygiene, network). |
| `gcc-high-parity-notes.md` | **Cited** Commercial-vs-GCC-High reference (endpoints, identity, feature mechanics, Azure Gov management gaps). |
| `08-deliverables-summary.md` | This index. |
| `global-requirements-azure-solutions.md` | Baseline Azure platform requirements (G1–G6) shared by all Azure solutions. |

## Scripts (`scripts/`)

All scripts connect to the sovereign cloud (`-Environment AzureUSGovernment`), are **read-only for secrets**, and **never read secret values** (metadata only). Remediation and scope-targeting default to **preview (WhatIf)** and require `-Apply` to change anything.

| Script | Type | What it does |
| --- | --- | --- |
| `PPKVG-Discovery.ps1` | Read-only | Inventories vaults, permission models, secret **names/metadata**, and Key Vault Secrets User assignments; checks the `Microsoft.PowerPlatform` provider. Outputs CSV. |
| `PPKVG-Validation.ps1` | Read-only | Pass/fail check of every prerequisite control for a target vault/secret (provider, RBAC model, Secrets User, Dataverse principal, network, secret present). |
| `PPKVG-Report.ps1` | Read-only | Governance HTML + CSV report with hygiene findings (no-expiry secrets, access-policy vaults, missing Secrets User). |
| `PPKVG-Remediation.ps1` | Change (WhatIf default) | Registers the provider, switches a vault to Azure RBAC, and grants Key Vault Secrets User to the Dataverse principal and makers group. Flags the Dataverse principal "verify for GCC High." |
| `PPKVG-Set-ScopeTargeting.ps1` | Change (WhatIf default) | Sets the Copilot Studio `AllowedBots` / `AllowedEnvironments` **tag** on a secret (metadata only — value untouched). |

### Running the scripts

```powershell
# Modules (once): Install-Module Az -Scope CurrentUser
# All scripts sign in to Azure Government on first run.

powershell -ExecutionPolicy Bypass -File .\PPKVG-Discovery.ps1
powershell -ExecutionPolicy Bypass -File .\PPKVG-Validation.ps1 -VaultName 'your-vault-name' -SecretName 'your-secret-name'
powershell -ExecutionPolicy Bypass -File .\PPKVG-Report.ps1
powershell -ExecutionPolicy Bypass -File .\PPKVG-Remediation.ps1            # preview
powershell -ExecutionPolicy Bypass -File .\PPKVG-Remediation.ps1 -Apply     # apply
powershell -ExecutionPolicy Bypass -File .\PPKVG-Set-ScopeTargeting.ps1 -AllowedEnvironments 'your-environment-id' -Apply
```

## Packaged outputs

| Artifact | Contents |
| --- | --- |
| `PPKVG-Solution.pdf` | The compiled document set (this `source/` folder). |
| `PPKVG-Scripts.zip` | The five PowerShell scripts. |

## Suggested engagement flow

1. Read `executive-summary.md` and the **Commercial vs GCC High** section of `01-solution-overview.md`.
2. Work `02-requirements.md`; run `PPKVG-Discovery.ps1` (Assess).
3. Follow `03-implementation.md` phase by phase; validate each gate with `05-testing.md` and the scripts.
4. Adopt `07-best-practices.md`; keep `06-troubleshooting.md` and `gcc-high-parity-notes.md` on hand.
