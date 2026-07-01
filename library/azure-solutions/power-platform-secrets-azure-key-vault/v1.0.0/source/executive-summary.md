# Executive Summary — Standardize Power Platform Secrets in Azure Key Vault

Power Platform makes it far too easy to paste an API key into a flow, a client secret into a custom
connector, or a connection string into an app formula — and once a secret is embedded that way it
leaks into **flow run history**, app and flow definitions, connector exports, and logs, and it cannot
be rotated without rebuilding every app and flow that hardcoded it. This solution moves every Power
Platform secret into **Azure Key Vault**, retrieves it securely through an approved pattern, removes
the hardcoded copies, proves no exposure remains, and governs rotation, ownership, and access — so a
key change never means an app rebuild.

This is a complete, **deploy-it-today** package for standardizing Power Platform secrets in Azure Key
Vault, written for an administrator with no prior secrets-management experience. It turns scattered,
hardcoded credentials into a single vaulted store consumed through the Microsoft-recommended pattern
and secured by Entra ID RBAC.

## What you get
- A plain-language **Solution Overview** — the secret types in scope, the four retrieval patterns
  (Key Vault-backed **Secret environment variables**, the **Azure Key Vault connector**, an **Azure
  Function + managed identity** via a custom connector, and direct service-principal/managed-identity
  retrieval) with a clear **decision guide**, plus the access and governance/rotation model.
- A **Requirements Guide** with why / verify / implement-if-missing for every prerequisite
  (subscription and vault, the RBAC permission model, the Power Platform service principal, Dataverse,
  maker access, licensing, Entra identities, networking, and the hardcoded-secret inventory).
- An **Implementation Guide** of precise, ordered steps across the Azure portal, the Power Platform
  admin center, and the Power Apps maker portal — create and lock down the vault, store the secrets,
  grant the Power Platform service principal `Key Vault Secrets User`, wire the Secret environment
  variable, refactor apps/flows/connectors off hardcoded values, govern rotation, and validate no
  exposure — then pilot, validate, and expand.
- Five **PowerShell scripts** for Key Vault + secret + RBAC discovery (with a hardcoded-secret scan
  of exports), access/retrieval validation, a secrets inventory + expiry/rotation report, safe
  remediation, and a rotation/ownership-tagging helper.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A **vaulted, governed secrets model** for Power Platform: secrets live in Azure Key Vault, apps and
flows read them through a Key Vault-backed Secret environment variable (or the connector / Function
pattern where it fits), access is least-privilege via Entra ID RBAC, no secret value survives in run
history, formulas, connectors, or exports, and rotating a secret in the vault flows through to every
consumer **without an app rebuild** — proven on a pilot before you scale.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate before production.

## Outcome
Every Power Platform secret centralized in Azure Key Vault, retrieved securely through approved
patterns, with no hardcoded credentials left anywhere — and rotation that never requires an app
rebuild — deployable by a single administrator and validated before rollout.
