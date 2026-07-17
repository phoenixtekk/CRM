# 2. Requirements Guide — Exchange Online Mailbox Automation with Logic Apps Managed Identity (Graph)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`. Objects are named consistently and reused verbatim (see the naming table in `03-implementation.md`).

> The security spine of this solution is a **least-privilege application Graph permission scoped to ONE mailbox**. Every requirement below serves that goal.

## 2.1 An Azure subscription and a Logic App
**Description:** An Azure subscription and an Azure **Logic App** to host the workflow — named `la-mailbox-automation-pilot`. This guide uses **Logic Apps Consumption** by default.
**Why:** The Logic App is the workload that will hold the managed identity and call Microsoft Graph; the managed identity only exists once the Logic App exists.
**Verify:** `portal.azure.com` → **Logic apps** → confirm (or plan) `la-mailbox-automation-pilot`; run `LAMIMAIL-Discovery.ps1`.
**Implement-if-missing:** Create the Logic App in the pilot resource group `rg-mailbox-automation-pilot`.
**Verify with Microsoft:** **Consumption vs Standard Logic Apps differ** in how the managed identity is enabled and referenced and in some workflow features — if you must use **Standard**, **verify the managed-identity and Graph-call specifics against current Microsoft documentation**; this guide's steps assume Consumption.

## 2.2 A managed identity on the Logic App (system- or user-assigned)
**Description:** A **managed identity** for `la-mailbox-automation-pilot` — **system-assigned** by default (this guide), or a **user-assigned** identity `id-mailbox-automation-pilot` if you need to share it across resources.
**Why:** The managed identity is what authenticates to Graph with no stored credential — it replaces the Office 365 Outlook connector's service-account OAuth connection.
**Verify:** `portal.azure.com` → the Logic App → **Identity** → **System assigned** = **On** (or a user-assigned identity is attached); run `LAMIMAIL-Discovery.ps1`.
**Implement-if-missing:** Turn **System assigned** identity **On** (Implementation Step 1), or create and attach `id-mailbox-automation-pilot`.

## 2.3 Exchange Online and the target mailbox
**Description:** Exchange Online is active, and the **single target mailbox** the workflow will read — `automation-inbox@contoso.com` — exists.
**Why:** This mailbox is the one (and only) mailbox the identity will be scoped to read; the whole design targets exactly this object.
**Verify:** `admin.microsoft.com` → Exchange admin center → **Recipients → Mailboxes** → confirm `automation-inbox@contoso.com`; run `LAMIMAIL-Discovery.ps1`.
**Implement-if-missing:** Create or designate the mailbox; record its address and object ID (used by the scope and the scripts).

## 2.4 Ability to grant an application Graph permission (admin consent)
**Description:** An account able to grant **application** Microsoft Graph permissions (app roles) to a service principal and **provide admin consent** — typically **Global Administrator** or **Privileged Role Administrator**.
**Why:** Assigning the app role (e.g. `Mail.Read`) to the managed identity's service principal and consenting to it requires a privileged role; without it the identity cannot read any mail.
**Verify:** Entra admin center → **Roles & admins** → confirm the operating account holds the role.
**Implement-if-missing:** Have a Global Administrator perform (or delegate) the app-role assignment and consent in Implementation Step 2.
**Verify with Microsoft:** the **exact application permission name/scope** to grant for reading mail (e.g. `Mail.Read`) is a Graph product detail — **verify the current permission name and its exact effect against Microsoft Graph documentation** before consenting.

## 2.5 A mailbox-scoping control (one-mailbox restriction)
**Description:** A decision on the **mailbox-scoping control** that restricts the application permission to only `automation-inbox@contoso.com` — an **Application Access Policy** (with a mail-enabled security group `sg-MailboxAutomation-Scope-Pilot`) or **Graph RBAC for Exchange Online**.
**Why:** An application `Mail.Read` grant is **tenant-wide by default**; scoping to one mailbox is the security requirement of this solution, not an optional hardening step.
**Verify:** Confirm the scope binding exists and lists only the target mailbox; run `LAMIMAIL-Test-MailboxAccess.ps1` (in-scope read succeeds, out-of-scope read denied).
**Implement-if-missing:** Apply the concise scope in Implementation Step 3; for the full walkthrough use the sibling product *"Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online."*
**Verify with Microsoft:** **whether to use Application Access Policy or the newer Graph RBAC-for-Exchange model, and their exact cmdlets/syntax, is version- and tenant-dependent — verify against current Microsoft documentation.**

## 2.6 Microsoft.Graph PowerShell for the scripts
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation (for the LAMIMAIL discovery/validation/reporting/test scripts).
**Why:** The included scripts authenticate with `Connect-MgGraph` and read identity, app-role, and mailbox-scope state through Graph.
**Verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version; the scripts print a clear message if it is missing.
**Implement-if-missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.7 Network / endpoint reachability
**Description:** The Logic App runtime and the operator workstation can reach the required **Microsoft Graph** and **login** endpoints.
**Why:** The workflow authenticates the managed identity and calls Graph over the network; blocked egress breaks both auth and the mail read.
**Verify:** Confirm reachability to the commercial endpoints (`graph.microsoft.com`, `login.microsoftonline.com`); run `LAMIMAIL-Validate.ps1`.
**Implement-if-missing:** Open firewall/proxy allowances for the correct endpoint set.
**Verify with Microsoft:** **national clouds use different endpoints** (e.g. `graph.microsoft.us`, `login.microsoftonline.us` and DoD variants) and may differ in feature availability — **verify the sovereign-cloud Graph/login endpoints and parity against current Microsoft documentation** before deploying to GCC High / DoD.

## 2.8 Change control, pilot scope, and rollback
**Description:** An approved change window, the named pilot scope (one Logic App, one mailbox), and a documented rollback before granting the app role or applying the scope.
**Why:** Granting an application permission and binding a mailbox scope are tenant-affecting changes; the pilot scope and rollback are the safety net.
**Verify:** An approved change record, the pilot scope, and a written back-out exist (per `global-requirements-azure-solutions.md` G5/G6).
**Implement-if-missing:** Capture current state (`LAMIMAIL-Report.ps1`), define the pilot scope, and write the rollback (remove the app-role assignment; remove the scope binding).

---
## Checklist
- [ ] Azure subscription + Logic App `la-mailbox-automation-pilot` (Consumption; Standard = verify) — `LAMIMAIL-Discovery.ps1`
- [ ] Managed identity on the Logic App (system-assigned default, or user-assigned `id-mailbox-automation-pilot`)
- [ ] Exchange Online + target mailbox `automation-inbox@contoso.com`
- [ ] Ability to grant an application Graph permission + admin consent (Global Admin)
- [ ] Mailbox-scoping control chosen (App Access Policy or Graph RBAC — verify which)
- [ ] Microsoft.Graph PowerShell installed
- [ ] Graph / login endpoint reachability (national-cloud endpoints = verify)
- [ ] Change window, pilot scope, and rollback documented
