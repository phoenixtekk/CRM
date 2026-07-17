# 2. Requirements Guide — Managed Identities for Azure Logic Apps & Functions

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim.

## 2.1 An Azure subscription with Logic Apps and/or Functions
**Description:** At least one Azure subscription under the Microsoft Entra tenant, with the Azure Logic Apps and/or Azure Functions resource(s) that will call Microsoft 365 (either existing or to be created).
**Why:** A managed identity is enabled **on** a Logic App or Function; there must be a compute resource to host it.
**Verify:** `portal.azure.com` → **Logic apps** and/or **Function App**; run `MIM365-Discovery.ps1`.
**Implement-if-missing:** Create the Logic App (Consumption or Standard) or Function App in the subscription in scope, and name it per your convention (e.g. `Graph Automation – Contoso – Pilot`).

## 2.2 Ability to enable a managed identity on the compute
**Description:** Rights to turn on a **system-assigned** identity on the Logic App/Function, and/or to **create and attach** a **user-assigned** managed identity.
**Why:** The whole pattern rests on the compute having an identity; enabling it is a write operation on the resource.
**Verify:** On the resource → **Identity** blade you can toggle **System assigned = On** or add a **User assigned** identity; `MIM365-Discovery.ps1` reports whether each compute already has an identity.
**Implement-if-missing:** Grant **Contributor** (or a role with `Microsoft.Web/sites/write` / the Logic App equivalent) on the resource; for a user-assigned identity, **Managed Identity Contributor** to create it and **Managed Identity Operator** to attach it.

## 2.3 Entra rights to grant application permissions and admin consent
**Description:** An account able to assign **application** Microsoft Graph permissions (app-role assignments) to the managed identity's service principal **and** grant **admin consent**.
**Why:** Application permissions do not take effect until an app-role is assigned to the identity and admin consent is granted; consent is a privileged, tenant-governed action.
**Verify:** Entra → **Roles & admins** confirms the operating account holds **Privileged Role Administrator** or **Global Administrator** (for consent) and **Application Administrator**/**Cloud Application Administrator** (to manage app-role assignments); `MIM365-Discovery.ps1` reports current app-role assignments per identity.
**Implement-if-missing:** Assign the minimum roles at the tenant scope; prefer **PIM eligible** activation over standing access.

## 2.4 Microsoft.Graph PowerShell modules
**Description:** The **Microsoft.Graph** PowerShell SDK on the operator workstation, used by every script in this solution.
**Why:** Discovery, validation, reporting, the stored-credential inventory, and the app-role helper all call Microsoft Graph via the SDK.
**Verify:** `Get-Module Microsoft.Graph -ListAvailable`; `MIM365-Discovery.ps1` fails fast if the module is missing.
**Implement-if-missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Connect with the least scopes each script names in its header (e.g. `Application.Read.All`, `AppRoleAssignment.ReadWrite.All`, `Directory.Read.All`).

## 2.5 The target Microsoft 365 workload(s) and the exact application permission
**Description:** A decision on **which** Microsoft 365 workload the automation calls (Exchange Online / Outlook mail, users, groups, files, etc.) and the **specific least-privilege application Graph permission** it requires.
**Why:** The app-role you assign must match the task; granting more than the one permission the workflow uses defeats the purpose.
**Verify:** The workflow's Graph call is known (endpoint + method), and the single application permission that authorizes it is identified.
**Implement-if-missing:** Map the Graph call to its required application permission and record it as the only grant. *Verify the exact permission name/scope for your call against current Microsoft documentation — do not assume a permission name.* For **mailbox** permissions, plan to **scope** the grant to specific mailboxes per product #4 rather than leaving it tenant-wide.

## 2.6 Logic Apps hosting model — Consumption vs Standard *(verify)*
**Description:** Awareness of whether the Logic App is **Consumption** or **Standard**, because managed-identity support, the workflow authoring surface, and networking differ.
**Why:** A step that works in one model may differ in the other; the design must match the hosting model in scope.
**Verify:** `portal.azure.com` → the Logic App **Overview** shows the plan/type. *Confirm the managed-identity behaviour for that model against current Microsoft documentation.*
**Implement-if-missing:** Choose the hosting model deliberately; if a required identity feature is unsupported on the current model, plan the workflow on the model that supports it. **Flag as verify — do not assert Consumption/Standard specifics.**

## 2.7 National / sovereign cloud endpoints *(verify)*
**Description:** If the tenant is in a national/sovereign cloud (e.g. US Government), the Graph, login/authority, and resource endpoints differ from commercial.
**Why:** The managed-identity token must be requested for the correct **resource/audience** and the code/action must target the correct **Graph endpoint**, or calls fail with audience/authority errors.
**Verify:** Confirm the cloud in scope and its endpoint set. *Verify the exact Graph/authority/resource URLs for that cloud against current Microsoft documentation.*
**Implement-if-missing:** Configure the Logic App action / Function code and `DefaultAzureCredential` authority for the correct cloud. **Flag as verify — do not assert sovereign-cloud endpoints.**

## 2.8 Change control, pilot workflow, and rollback
**Description:** An approved change window, a named **pilot** Logic App/Function, and a documented rollback before migrating any production flow off stored credentials.
**Why:** Switching a live automation's authentication can break it; piloting one workflow and keeping a rollback is the safety net.
**Verify:** An approved change record, the pilot resource name, and a written back-out exist (per `global-requirements-azure-solutions.md` G5/G6).
**Implement-if-missing:** Capture the current state (`MIM365-Report.ps1`), pilot on one workflow, and write the rollback (re-enable the previous connection) before cutting over production.

---
## Checklist
- [ ] Azure subscription + Logic App and/or Function App — `MIM365-Discovery.ps1`
- [ ] Rights to enable system-assigned / create + attach user-assigned identity
- [ ] Entra rights to assign application Graph permissions **and** grant admin consent
- [ ] Microsoft.Graph PowerShell installed and connectable
- [ ] Target M365 workload + exact least-privilege application permission identified *(verify the permission name)*
- [ ] Logic Apps Consumption vs Standard understood *(verify)*
- [ ] National/sovereign cloud endpoints confirmed if applicable *(verify)*
- [ ] Change window, pilot workflow, and rollback documented
