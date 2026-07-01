# 1. Solution Overview — Standardize Power Platform Secrets in Azure Key Vault

## The problem this solves
Power Platform makes it trivial to paste a secret where it does not belong: an API key in a Power
Automate flow action, a client secret in a custom connector, a connection string in a Power Apps
formula, a service-account password in an environment variable, or a token in a script. Once a
secret is embedded that way it leaks — into **flow run history** (inputs/outputs), **app and flow
definitions**, **connector exports**, **solution exports**, and **logs** — and it cannot be rotated
without editing and re-publishing every app and flow that hardcoded it. This solution moves every
Power Platform secret into **Azure Key Vault**, retrieves it through an approved pattern, removes the
hardcoded copies, proves no exposure remains, and governs rotation, ownership, and access — so a key
change never means an app rebuild.

## Secret types in scope
API keys, OAuth client secrets, connection strings, certificates (and certificate passwords),
service-account credentials, external-system tokens, and any integration credential that today lives
inside a Power App, a Power Automate flow, a custom connector, a Dataverse environment variable of a
plaintext type, or a script.

## The retrieval patterns (and how to choose)
There is more than one supported way to read a Key Vault secret from Power Platform. Lead with the
native pattern; use the alternatives only where they fit.

### Pattern A (PRIMARY) — Secret environment variables backed by Azure Key Vault
A Dataverse **environment variable of type `Secret`** stores only a **reference** (the Key Vault
secret's resource identifier), not the value. At run time Power Apps / Power Automate resolves the
reference and reads the current secret value through the Power Platform / Dataverse first-party
service principal, which you grant the Key Vault **`Key Vault Secrets User`** RBAC role. This is the
**Microsoft-recommended** approach: the value never lands in the app/flow definition, it moves
cleanly between environments as part of a solution, and rotating the vault secret is picked up
automatically because the reference resolves the **current** version.

- **Use when:** you want the standard, lowest-friction, no-code pattern — which is most cases.
- **Requires:** the vault on the **Azure RBAC** permission model, the Power Platform service
  principal granted `Key Vault Secrets User` on the vault (or secret), and the secret's resource ID.

### Pattern B — The Azure Key Vault connector (Power Automate)
The built-in **Azure Key Vault** connector has a `Get secret` action. It is a **premium** connector
(licensing applies) and authenticates as a **service principal / app registration** you configure on
the connection.

- **Use when:** a flow needs a secret ad hoc and you accept a premium connector; or you need actions
  the env-var pattern does not cover.
- **Caution:** the returned value is a flow variable — if the action or a downstream action is not
  marked **secure**, the value appears in run history. Always enable **Secure Outputs** on the
  `Get secret` action and **Secure Inputs** on any action that consumes it.

### Pattern C — Azure Function + managed identity, called via a custom connector
An **Azure Function** with a **system-assigned managed identity** reads the secret from Key Vault
(the managed identity is granted `Key Vault Secrets User`) and returns only the result of whatever
work needs the secret (or the value over a secured channel). A **custom connector** exposes the
Function to flows/apps.

- **Use when:** you need transformation, want the secret to never leave Azure, need tighter control
  or auditing, or must broker calls to an external API without handing the secret to Power Platform.
- **Trade-off:** more moving parts (Function + connector) to build and maintain.

### Pattern D — Direct service principal / managed identity retrieval
A script or component authenticates as a **service principal** or **managed identity** and reads the
secret directly (e.g. Azure PowerShell, Azure CLI, or an SDK).

- **Use when:** the consumer is a script or an Azure-hosted component outside the Power Platform
  no-code surface. Not a Power Apps/Automate retrieval pattern per se — included for completeness.

> **Decision guide (short form):** default to **Pattern A** (Secret environment variables). Reach
> for **Pattern B** only when a premium connector is acceptable and the env-var pattern will not do.
> Choose **Pattern C** when you need transformation, brokering, or the secret to stay inside Azure.
> Use **Pattern D** for scripts / Azure-hosted consumers.

## Access model
Access to the vault is granted with **Entra ID identities** — app registrations / service principals
and **managed identities** — assigned **Azure RBAC** roles on the Key Vault, least privilege:

- **`Key Vault Secrets User`** — read secret values (what a consumer needs).
- **`Key Vault Secrets Officer`** — create/update/rotate secrets (what a secret owner/administrator needs).

Prefer the **Azure RBAC** permission model over the legacy **access-policy** model — RBAC is
role-based, auditable, and consistent with the rest of Azure. Grant the read role at the **secret**
scope where you can, and at the vault scope only when a consumer legitimately needs the whole vault.

## Governance & rotation model
Secrets are only as safe as their lifecycle. This solution establishes:

- **Ownership** — every secret is tagged with an owner and a purpose so accountability is explicit.
- **Least-privilege access** — only the identities that must read a secret hold `Key Vault Secrets
  User`; only owners hold `Key Vault Secrets Officer`; everything else is denied by default.
- **Expiry & rotation** — every secret has an expiration and a rotation cadence; expired or
  soon-to-expire secrets are surfaced in the report so nothing silently ages out.
- **Rotation without a rebuild** — this is the payoff of vaulting. When you rotate a secret (create a
  new version in the vault), the **Secret environment variable** (Pattern A) and the **connector /
  Function** (Patterns B/C) resolve the **current** version at run time. Apps and flows keep working
  with the new value **without any edit or re-publish**. (A reference pinned to a specific version is
  the exception — reference the secret without a version to always get current.)

## What "no exposure" means (validated later)
A secret is *out* of Power Platform only when its value appears in **none** of: flow run history
inputs/outputs, app formulas, connector definitions/exports, solution exports, or logs. The Testing
Guide proves each of these; the Discovery script scans exported definitions for hardcoded-secret
patterns as a safety net.

## The deployment model
> **Assess → Configure → Pilot → Validate → Expand**, with a **pilot gate**: prove the pattern on a
> single flow or app, validate no exposure, then expand across the environment. A rollback note is
> included at each disruptive step.
