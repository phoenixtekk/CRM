# 2. Requirements Guide — Event-Driven Mail Processing with Microsoft Graph Change Notifications

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`. Objects are named per the convention below and reused verbatim throughout.

> **Naming (set once, reuse verbatim).** Azure ARM resources use lower-case hyphenated names; Exchange/Entra logical objects use `<Purpose> – <Scope> – <Stage>`.
> - Resource group: `rg-mailevents-pilot`
> - Logic App (hosting the workflows): `logic-mailevents-receiver-pilot`
> - Receiver workflow: `wf-NotificationReceiver`
> - Renewal / catch-up workflow: `wf-SubscriptionRenewal`
> - Key Vault (for the `clientState` secret): `kv-mailevents-pilot`
> - `clientState` secret name: `MailEvents-ClientState`
> - Target mailbox: `svc-mailevents@contoso.com`
> - Mail-enabled security group for scoping: `MailEvents – Scope – Pilot`
> - Application Access Policy: `MailEvents – AppAccess – Pilot`

---

## 2.1 An Azure Logic App with a reachable public HTTPS notificationUrl
**Description:** An Azure Logic App (`logic-mailevents-receiver-pilot`) whose HTTP-triggered workflow exposes an **HTTPS endpoint that Microsoft Graph can reach from the internet** to POST notifications and the validation request.
**Why:** Change notifications are *pushed*. Graph must resolve and connect to the `notificationUrl` over public TLS, both at subscription-creation (the validation handshake) and for every notification. No public path = no webhook.
**Verify:** From an external network, `curl -i https://<workflow-endpoint>` returns a TLS response (not a private/timeout). Run `GRAPHSUB-Discovery.ps1`.
**Implement-if-missing:** Create the Logic App and an HTTP-request-triggered workflow with a public endpoint. **Consumption vs Standard** hosting differs in networking and pricing for an always-on HTTP endpoint — **verify against current Microsoft documentation** which plan fits; if only a private endpoint is possible, use the **polling** pattern (product #3) instead.

## 2.2 A managed identity on the Logic App
**Description:** A **managed identity** (system-assigned on `logic-mailevents-receiver-pilot`, or a user-assigned identity attached to it) that the workflows use to call Graph.
**Why:** The whole point of this family is credential-free auth — the workflow authenticates to Graph as the managed identity, with no service account, secret, or O365 connection.
**Verify:** Azure portal → the Logic App → **Identity** shows **System assigned = On** (or a user-assigned identity attached) and an **Object (principal) ID**. `GRAPHSUB-Discovery.ps1` reports it.
**Implement-if-missing:** Turn on the system-assigned identity (or create and attach a user-assigned one). Record the identity's **Object ID** — you grant the Graph permission to it in Step 2 of the Implementation Guide.

## 2.3 A least-privilege application Graph permission, admin-consented
**Description:** An **application** Microsoft Graph permission — least privilege for reading mail (for example **`Mail.Read`**) — granted to the managed identity's service principal, with **admin consent**.
**Why:** Application permissions are tenant-wide by default and require an admin to consent; the workflow needs read access to the changed message. Application (not delegated) permission is what lets an unattended workflow run with no signed-in user.
**Verify:** Entra → **Enterprise applications** → the managed identity → **Permissions**; or run `GRAPHSUB-Validate.ps1`, which checks the app-role assignment exists.
**Implement-if-missing:** Assign the app role to the managed identity's service principal and grant admin consent (Implementation Step 2). **The exact permission name and whether a narrower mail-read scope exists are version-specific — verify against current Microsoft documentation**; grant the *least* permission that lets the workflow read the message, never `Mail.ReadWrite` "to be safe."

## 2.4 Mailbox access scoped to the one target mailbox
**Description:** The application permission from 2.3 **restricted to only `svc-mailevents@contoso.com`**, using an **Application Access Policy** (`MailEvents – AppAccess – Pilot`) over a mail-enabled security group (`MailEvents – Scope – Pilot`) — or the newer Graph-RBAC-for-Exchange model.
**Why:** A bare application `Mail.Read` grant can read **every** mailbox in the tenant. Scoping it to one mailbox is the security spine of this solution.
**Verify:** `Test-ApplicationAccessPolicy` (Exchange Online PowerShell) returns **Granted** for the target mailbox and **Denied** for a control mailbox. See product #4 for the full procedure.
**Implement-if-missing:** Create the scoping (Implementation Step 3, concise). **The choice between Application Access Policy and the newer Graph RBAC for Exchange Online, and which is current/recommended, is version-specific — verify against current Microsoft documentation.** For the deep treatment, **use product #4 "Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online" — this guide does not reproduce it.**

## 2.5 An Exchange Online target mailbox
**Description:** A live Exchange Online mailbox to monitor — `svc-mailevents@contoso.com` (a shared or user mailbox that receives the mail you want to process).
**Why:** The change-notification subscription is created against this mailbox's message resource; it must exist and be licensed/enabled as required.
**Verify:** Exchange admin center → **Recipients → Mailboxes** shows `svc-mailevents@contoso.com`; `Get-Mailbox svc-mailevents@contoso.com` succeeds.
**Implement-if-missing:** Create the mailbox (shared mailboxes need no user license in most cases — **verify licensing against current Microsoft documentation**).

## 2.6 The Microsoft.Graph PowerShell module
**Description:** The **Microsoft.Graph** PowerShell module on the operator workstation, for discovery, validation, reporting, and renewal.
**Why:** The five solution scripts use `Microsoft.Graph` cmdlets (`Connect-MgGraph`, `Get-MgSubscription`, `New-MgSubscription`, `Update-MgSubscription`, `Get-MgServicePrincipal`).
**Verify:** `Get-Module -ListAvailable Microsoft.Graph`; `GRAPHSUB-Discovery.ps1` self-checks and installs if missing.
**Implement-if-missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.7 A secret store for clientState (and any encryption key)
**Description:** A secret store — **`kv-mailevents-pilot` (Azure Key Vault)** — holding the random **`clientState`** secret (`MailEvents-ClientState`) the subscription and receiver share, plus any resource-data encryption key if you enable encrypted payloads.
**Why:** `clientState` is how the receiver proves a notification really came from your subscription; it must be a secret, not in code. The Logic App reads it via its managed identity.
**Verify:** Key Vault → **Secrets** shows `MailEvents-ClientState`; the Logic App's managed identity has **Key Vault Secrets User** (or an access policy) on the vault.
**Implement-if-missing:** Create the vault, add the secret (a long random string), and grant the managed identity read access. **Whether you also need an encryption key depends on using encrypted resource-data delivery — verify against current Microsoft documentation.**

## 2.8 TLS and endpoint trust
**Description:** A valid, publicly trusted **TLS** certificate on the `notificationUrl` host, meeting Graph's current TLS requirements.
**Why:** Graph will not deliver to an endpoint it cannot validate over TLS; the Logic App's default `*.azurewebsites.net`/`*.logic.azure.com` endpoint is already TLS-terminated, but a custom domain/gateway in front must present a trusted certificate.
**Verify:** The endpoint answers on `https://` with a valid chain (browser/`curl` shows no cert error). **Graph's minimum TLS version is version-specific — verify against current Microsoft documentation.**
**Implement-if-missing:** Use the platform-provided HTTPS endpoint, or install a publicly trusted certificate on the fronting gateway.

## 2.9 National-cloud endpoints (if applicable)
**Description:** If the tenant is a **government / national cloud** (GCC High, DoD, or another sovereign cloud), the correct **national-cloud Graph and login endpoints** for subscriptions and token acquisition.
**Why:** Commercial `graph.microsoft.com` / `login.microsoftonline.com` are **not** the endpoints in sovereign clouds; using the wrong host fails auth and subscription creation.
**Verify:** Confirm the tenant's cloud and the matching endpoints. `Connect-MgGraph -Environment <cloud>` targets the right sovereign endpoint.
**Implement-if-missing:** **The exact national-cloud Graph/login endpoints and feature parity for change notifications are cloud-specific — verify against current Microsoft documentation** and set the module `-Environment` / Logic App endpoints accordingly. Do not assume commercial hosts.

---
## Checklist
- [ ] Logic App with a reachable public HTTPS endpoint — `GRAPHSUB-Discovery.ps1`
- [ ] Managed identity on the Logic App (Object ID recorded)
- [ ] Least-privilege application Graph permission granted + admin-consented — `GRAPHSUB-Validate.ps1`
- [ ] Mailbox access scoped to `svc-mailevents@contoso.com` (see product #4)
- [ ] Exchange Online mailbox `svc-mailevents@contoso.com` exists
- [ ] Microsoft.Graph PowerShell module installed
- [ ] `kv-mailevents-pilot` holds `MailEvents-ClientState`; MI can read it
- [ ] Public, trusted TLS on the notificationUrl host
- [ ] National-cloud endpoints confirmed (if a sovereign tenant) — *verify with Microsoft*
