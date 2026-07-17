# 2. Requirements Guide — Scoping Application-Permission Mailbox Access

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim.

> **Verify-with-Microsoft note:** exact **role names**, **cmdlet names/parameters**, **Graph permission names**, and **which scoping model is current/recommended** are version- and cloud-dependent. Where a requirement names one, treat it as a starting point and **confirm against current Microsoft documentation** — do not assume.

## 2.1 An Exchange Online organization
**Description:** A Microsoft 365 tenant with **Exchange Online** and the mailboxes the app will (and will not) be allowed to access.
**Why:** Both scoping models — Application Access Policy and Graph RBAC for Exchange Online — are Exchange Online features; there is nothing to scope without Exchange Online mailboxes.
**Verify:** `https://admin.exchange.microsoft.com` resolves and lists mailboxes; run `MBXRBAC-Discovery.ps1`.
**Implement-if-missing:** License and provision Exchange Online mailboxes for the in-scope and out-of-scope test identities (`reports@contoso.com`, `ceo@contoso.com`).

## 2.2 An admin role that can create access policies / assign Exchange RBAC
**Description:** An operating account holding an Exchange admin role sufficient to run `New-ApplicationAccessPolicy` **and/or** to create Exchange RBAC scopes and role assignments — commonly **Global Administrator** or an Exchange role such as one carrying the **"Role Management"** / **"Organization Configuration"** rights (*verify the exact minimum role names against current Microsoft documentation*).
**Why:** Creating an Application Access Policy, and creating a management scope / role assignment for Graph RBAC, are privileged Exchange operations.
**Verify:** In Exchange admin center → **Roles → Admin roles**, confirm the account's role; `MBXRBAC-Discovery.ps1` reports the connected identity.
**Implement-if-missing:** Assign the minimum role that grants the needed rights at the narrowest scope; prefer PIM eligible activation over standing access.

## 2.3 An app registration or managed identity holding the application permission
**Description:** The **application identity** to be scoped — an Entra **app registration** (with a client ID / `AppId`) or the **managed identity** of a Logic App / Function — that holds a mail-capable **application** Graph permission (e.g. `Mail.Read`). In this guide the example identity is **`Mailbox Reporting App`** (`AppId` `11111111-1111-1111-1111-111111111111`, an example value — substitute your own).
**Why:** The scope binds to a specific application by its `AppId` / service-principal object ID; without an existing application identity there is nothing to scope.
**Why it is the exposure:** the mail-capable **application** permission it holds is tenant-wide until scoped — this is exactly what you are fencing.
**Verify:** Entra → **App registrations** (or **Enterprise applications** for the service principal / managed identity) → **API permissions** shows the granted application permission with admin consent; `MBXRBAC-Discovery.ps1` lists apps/identities holding mail-capable application permissions and whether each is scoped or tenant-wide.
**Implement-if-missing:** Register the app (or enable the managed identity), grant **only** the specific mail application permission the workload needs (least privilege at the permission level too), and grant admin consent. *Verify the exact Graph permission name required for the operation against current Microsoft documentation.*

## 2.4 A mail-enabled security group (for the Application Access Policy model)
**Description:** A **mail-enabled security group** whose members are exactly the mailboxes the app is allowed to touch. Named **`App Mailbox Scope – Reporting – Prod`** (primary SMTP `app-mailbox-scope-reporting@contoso.com`).
**Why:** `New-ApplicationAccessPolicy` scopes an app to a **mail-enabled security group** — not a plain security group and not a Microsoft 365 group. The group's membership *is* the allow-list.
**Verify:** Exchange admin center → **Recipients → Groups** shows `App Mailbox Scope – Reporting – Prod` as a **mail-enabled security group**; `MBXRBAC-Validate.ps1` confirms the group type and membership.
**Implement-if-missing:** Create the mail-enabled security group and add only the allowed mailbox(es) (`reports@contoso.com`). *Verify the exact group type requirement against current Microsoft documentation — only mail-enabled security groups are supported by Application Access Policy.* (Not required if you use the Graph RBAC model exclusively.)

## 2.5 A scope object (for the Graph RBAC for Exchange Online model)
**Description:** The **resource scope** the RBAC assignment will be limited to — a management scope, administrative unit, or group of mailboxes that defines which mailboxes the assigned Exchange application role may reach. Named **`App Mailbox Scope – Reporting – RBAC Scope`**.
**Why:** Graph RBAC for Exchange Online grants a specific Exchange application role **scoped** to a resource; the scope object is what makes the grant narrow instead of tenant-wide.
**Verify:** Confirm the scope object exists and resolves to the intended mailboxes (*verify the exact scope object type and cmdlet — e.g. management scope vs administrative unit — against current Microsoft documentation*).
**Implement-if-missing:** Create the scope object bounding it to the allowed mailbox(es); use `MBXRBAC-Set-AccessPolicy.ps1` (which defaults to `-WhatIf`) to preview the assignment. (Not required if you use the Application Access Policy model exclusively.)

## 2.6 Exchange Online PowerShell + Microsoft Graph PowerShell
**Description:** The **ExchangeOnlineManagement** module (for `Connect-ExchangeOnline`, access policies, and Exchange RBAC) and the **Microsoft.Graph** module (for discovering and reporting application permissions and running the boundary read). *Verify current module names and minimum versions against current Microsoft documentation.*
**Why:** Every step and script in this solution runs in one or both modules; the access-policy and RBAC cmdlets live in ExchangeOnlineManagement, the app-permission discovery and Graph mail read live in Microsoft.Graph.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph`; `MBXRBAC-Discovery.ps1` checks and imports both.
**Implement-if-missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.7 Change control, a pilot app, and rollback
**Description:** An approved change window, a named **pilot application** (`Mailbox Reporting App`) and pilot mailboxes, and a documented rollback before you scope any production app.
**Why:** A mis-scoped policy can break a working automation (in-scope reads start failing) or leave the app tenant-wide; the pilot and rollback are the safety net.
**Verify:** An approved change record, the pilot app/mailboxes, and a written back-out exist (per `global-requirements-azure-solutions.md` G5/G6).
**Implement-if-missing:** Capture current state with `MBXRBAC-Report.ps1`, define the pilot app + in-scope/out-of-scope mailboxes, and write the rollback (remove the Application Access Policy / RBAC assignment).

---
## Checklist
- [ ] Exchange Online organization + in-scope/out-of-scope mailboxes — `MBXRBAC-Discovery.ps1`
- [ ] Admin role that can create access policies / assign Exchange RBAC (verify exact role)
- [ ] App registration or managed identity holding the mail application permission (`Mailbox Reporting App`)
- [ ] Mail-enabled security group `App Mailbox Scope – Reporting – Prod` (Application Access Policy model)
- [ ] Scope object `App Mailbox Scope – Reporting – RBAC Scope` (Graph RBAC model)
- [ ] ExchangeOnlineManagement + Microsoft.Graph modules installed
- [ ] Change window, pilot app/mailboxes, and rollback documented
