# Executive Summary — Managed Identities for Azure Logic Apps & Functions (Authenticating to Microsoft 365 Without Stored Credentials)

**White-label · Azure Solutions**

Automations that reach into Microsoft 365 too often run on a **stored service-account connection** or a **client secret** sitting in the workflow — credentials that must be rotated, can leak, and grant standing access far beyond the one task they exist for. A **managed identity** removes the credential entirely: Azure issues and rotates it, and you grant it exactly the application permissions it needs. This solution is the **pattern reference** for authenticating Azure **Logic Apps** and Azure **Functions** to Microsoft 365 (Microsoft Graph and related resources) with managed identities — and for migrating existing secret-based automations off stored credentials.

This is a complete, **deploy-it-today** package written for an administrator with no prior managed-identity experience.

## What you get
- A plain-language **Solution Overview** of managed identities — system-assigned vs user-assigned and when to choose each, and the Logic Apps and Functions authentication patterns.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, ordered steps — enable the identity, grant a **least-privilege** application permission with admin consent, call Graph from a **Logic App** (no connector, no secret), call Graph from a **Function** (with a working code example), validate, and migrate.
- Five **PowerShell scripts** (Microsoft.Graph) for identity/app-role discovery, least-privilege validation, an estate inventory + CSV, a stored-credential finder that produces the migration worklist, and a `-WhatIf`-gated app-role assignment helper.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
Azure Logic Apps and Functions authenticating to Microsoft Graph through **managed identities** and **least-privilege application permissions** — no stored service-account passwords, no client secrets — with a repeatable path to migrate existing secret-based flows and retire the credentials. Mailbox scoping is handled by companion product #4; the mailbox-specific workloads by products #1/#2/#3. This document is the general pattern that underpins them all, across both compute types.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — pilot one workflow, prove least privilege and parity, then expand across the estate, driving the stored-credential worklist to zero.

## Outcome
A credential-free authentication standard for your Azure automations — proven on a pilot workflow across both Logic Apps and Functions before you scale, deployable by a single administrator.
