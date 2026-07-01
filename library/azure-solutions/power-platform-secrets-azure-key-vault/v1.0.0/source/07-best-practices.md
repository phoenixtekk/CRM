# 7. Best Practices — Standardize Power Platform Secrets in Azure Key Vault

- **Default to Secret environment variables.** Pattern A keeps the value out of the app/flow
  definition, travels with the solution between environments, and rotates without a rebuild — it is
  the Microsoft-recommended approach and the right choice in most cases.
- **Use the Azure RBAC permission model, not access policies.** RBAC is role-based, auditable, and
  consistent with the rest of Azure; the Secret env-var pattern assumes it.
- **Least privilege, per secret where you can.** Grant `Key Vault Secrets User` (read) only to the
  identities that must read, and `Key Vault Secrets Officer` (manage) only to owners. Scope the read
  role to the individual secret rather than the whole vault when a consumer needs just one.
- **Reference secrets versionless.** Point env vars / connectors at the secret **without** a version
  so rotation is picked up automatically. Pin to a version only when you deliberately want to freeze it.
- **Always mark actions Secure.** Enable **Secure Inputs** and **Secure Outputs** on every Power
  Automate action that receives or passes a secret, so nothing lands in run history.
- **Never let apps read the vault directly.** Have Power Apps obtain a secret through a flow (or the
  Function/connector broker), not by embedding vault calls in formulas.
- **One vault per environment.** A vault per Power Platform environment keeps dev/test/prod secrets
  and access cleanly separated and makes solution promotion predictable.
- **Tag every secret with an owner and purpose.** Accountability and audit start with knowing who
  owns each secret and why it exists; enforce this with `PPKV-Set-RotationOwnership.ps1`.
- **Set expiry and a rotation cadence.** Every secret gets an expiration and a rotation schedule;
  chase expiring secrets from `PPKV-Report.ps1` before they lapse.
- **Prove no exposure, don't assume it.** After every change, verify the value is absent from run
  history, formulas, connector definitions, and exports (Testing Guide) — and scan exports with
  `PPKV-Discovery.ps1`.
- **Never hardcode again.** Make the vaulted pattern the standard for new flows/apps; keep the
  discovery scan in the review pipeline so a hardcoded secret is caught before it ships.
