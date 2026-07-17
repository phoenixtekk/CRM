# 1. Solution Overview — Managed Identities for Azure Logic Apps & Functions (Authenticating to Microsoft 365 Without Stored Credentials)

## What a managed identity is
A **managed identity** is an identity that Azure creates and manages for a compute resource — an Azure Logic App or an Azure Function — so the resource can authenticate to other Azure and Microsoft 365 services **without any credential stored in the workflow or the code**. Azure issues the identity, rotates its underlying secret automatically, and removes it when the resource is deleted. Your automation asks Azure for a token at runtime; nothing is ever written into a connection string, an app setting, or a workflow definition. This solution is the **pattern reference** for using managed identities to authenticate **both** Azure Logic Apps **and** Azure Functions to **Microsoft 365** (Microsoft Graph and related resources), and for **migrating existing automations off stored service-account connections and client secrets**.

## Why this matters
Automations that reach into Microsoft 365 too often run on a **stored service-account connection** (a licensed user whose password sits in a saved connector connection) or a **client secret** pasted into the workflow or app settings. Those credentials must be rotated on a schedule, can leak into logs, source control, or exports, and grant **standing access** that survives long after the automation stops being used — a service account with a saved password can be reused by anyone who obtains it, and it typically carries far more access than the one task needs. A managed identity removes the credential from the picture entirely: there is nothing to rotate, nothing to leak, and access is bounded by the **application permissions** you explicitly grant. Combined with **least-privilege application permissions**, the automation can do exactly one job and no more.

## System-assigned vs user-assigned managed identity
There are two kinds, and choosing correctly is the first design decision:

- **System-assigned managed identity** — created **on** a single Logic App or Function, tied to that resource's lifecycle (deleted with it), and usable only by that resource. Choose it when a workflow's identity should live and die with the workflow and is not shared. Simple, but every resource gets its **own** identity, so app-permission grants and clean-up multiply across the estate.
- **User-assigned managed identity** — a **standalone** Azure resource you create once and then **attach to many** Logic Apps and Functions. Choose it when several workflows should share one identity and one set of granted permissions. Grant the application permissions **once** to the shared identity, and every workflow attached to it inherits them — one object to audit, one to review, one to remove. For a **multi-workflow estate**, a shared user-assigned identity is usually the simpler operational model; a single system-assigned identity is fine for a one-off, self-contained workflow.

> **Verify against current Microsoft documentation:** exact support for user-assigned identities in **Logic Apps Consumption vs Standard**, and in the various Azure Functions hosting plans, differs — confirm the compute type in scope supports the identity kind you choose before you commit to the design.

## How it works (the pattern)
1. **Enable a managed identity** on the Logic App or Function — a **system-assigned** identity toggled on for one resource, or a **user-assigned** identity created once and attached to many.
2. **Grant the identity least-privilege application permissions** — assign the specific **application** Microsoft Graph permission(s) the task needs (an **app-role assignment** to the managed identity's service principal) and grant **admin consent**. Least privilege by default: grant only the narrow permission the workflow uses, never a broad tenant-wide grant "to be safe."
3. **The compute calls Microsoft Graph with the identity** — a Logic App uses the built-in **managed-identity authentication** on its HTTP action (no connector, no secret); a Function uses **`DefaultAzureCredential` / `ManagedIdentityCredential`** in code to acquire a token. Azure returns a token scoped to the granted permissions; the call runs as the application.
4. **Validate and migrate** — confirm the identity authenticates and is least-privilege, then walk existing secret/service-account flows onto the same pattern and retire the stored credentials.

## Where mailbox scoping fits (point to product #4 — do not reproduce it)
Application Graph permissions like **`Mail.Read`** are, by default, **tenant-wide** — the app can read *every* mailbox. That is almost never what you want. **Restricting an application permission to a single mailbox (or a defined set)** is a distinct discipline covered in full by the companion product **"Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online" (product #4)**. This solution grants permissions **least-privilege** and hands mailbox scoping off to #4 rather than reproducing it — whenever a step here grants a mailbox permission, apply #4's scoping before considering the access production-ready.

## Concrete mailbox applications (point to #1 / #2 / #3 — do not reproduce them)
This is the broad pattern reference; the mailbox-specific siblings show it applied end-to-end and are the place to go for those workloads:
- **Product #1 — "Exchange Online Mailbox Automation with Logic Apps Managed Identity — Replacing the O365 Connector with Microsoft Graph"**: replacing a stored Office 365 Outlook connector with managed-identity Graph calls.
- **Product #2 — "Event-Driven Mail Processing with Microsoft Graph Change Notifications (Logic Apps + Managed Identity)"**: reacting to new mail via Graph change-notification subscriptions.
- **Product #3 — "Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)"**: scheduled polling of a mailbox without a service account.

Use those for the mailbox specifics; use this document for the **general managed-identity-to-M365 authentication pattern** that underpins all of them, across **both** Logic Apps and Functions.

## Benefits
- **No credential to store, rotate, or leak** — Azure issues and rotates the identity; nothing lives in the workflow, app settings, or code.
- **Least-privilege by design** — the automation holds only the application permissions you explicitly grant, not a service account's full access.
- **One pattern, two compute types** — the same managed-identity approach authenticates Logic Apps and Functions, so the estate is consistent.
- **A clean migration target** — every stored-secret and service-account flow has a defined path onto the identity model.
- **Simpler audit** — a user-assigned identity gives one object to review and one set of grants to justify across many workflows.

## Limitations (be honest with buyers)
- A managed identity works only **inside Azure** — it authenticates Azure compute (Logic Apps, Functions) to services that accept Entra tokens. It does not replace credentials for software running outside Azure.
- **Application permissions are tenant-wide until scoped** — `Mail.Read` granted to the identity can read every mailbox until you constrain it (see product #4). Granting the permission is not the same as scoping it.
- **Not every legacy connector action supports a managed identity** — some Office 365 / Outlook connector triggers and actions may not accept managed-identity auth, which is one reason the pattern favours **direct Graph calls**. *Verify against current Microsoft documentation which specific connector operations support managed identity.*
- **Consumption vs Standard Logic Apps and the various Functions hosting plans differ** in managed-identity and networking behaviour. *Verify the exact capabilities for the compute type and plan in scope against current Microsoft documentation.*
- **National / sovereign clouds use different endpoints** (Graph, login/authority, and resource URLs). *Verify the correct endpoints for the cloud in scope against current Microsoft documentation.*
- Granting **admin consent** for application permissions requires a **Privileged Role Administrator / Global Administrator**; this is a governed action, not a self-service one.

## The standard deployment model
> **Enable a managed identity (system- or user-assigned) → grant least-privilege application permissions with admin consent → wire a Logic App to call Graph with the identity → wire a Function to call Graph with the identity → validate least-privilege and token flow → migrate secret-based flows onto the identity and retire the credentials.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, piloting on one workflow before rolling the pattern across the estate, with the stored-credential inventory as the migration worklist.
