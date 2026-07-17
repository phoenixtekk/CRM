# 2. Requirements Guide — Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim throughout (see the naming block in `03-implementation.md`).

> **Anything version-, feature-, or licensing-specific is flagged "verify against current Microsoft documentation" and is never asserted as fact** — exact Graph permission names/scopes, throttling limits, delta-query behavior, Consumption-vs-Standard capability differences, and national-cloud endpoints all change over time.

## 2.1 An Azure Logic App (Consumption or Standard)
**Description:** An Azure Logic App to host the recurrence-driven workflow — named `Mail Polling – Support Mailbox – Pilot`.
**Why:** The Logic App is the compute that runs the schedule, calls Graph, and holds the managed identity.
**Verify:** `portal.azure.com` → **Logic apps**; run `GRAPHPOLL-Discovery.ps1`.
**Implement-if-missing:** Create a Logic App. **Consumption (multi-tenant)** is the simplest for a single-mailbox poller; **Standard (single-tenant, App Service)** adds private networking and different trigger/state options. **The exact managed-identity, trigger, and networking differences between Consumption and Standard must be verified against current Microsoft documentation** — pick based on your networking and isolation needs, then keep the choice consistent through the guide.

## 2.2 A managed identity on the Logic App
**Description:** A **managed identity** for the Logic App — **system-assigned** (bound to this Logic App) or a **user-assigned** identity named `Mail Polling MI – Support Mailbox – Prod` reused across workflows.
**Why:** The managed identity is what authenticates the HTTP-to-Graph calls; it replaces the service account and stores no secret.
**Verify:** Logic App → **Identity** shows a system-assigned identity **On** (or the user-assigned identity attached); `GRAPHPOLL-Discovery.ps1` reports the identity and its object id.
**Implement-if-missing:** Logic App → **Identity** → **System assigned** → **On** (or **User assigned** → **Add** the identity). Record the identity's **Object (principal) ID** — every later grant targets it.

## 2.3 A least-privilege Graph application permission + admin consent
**Description:** An **application** Graph permission granting mailbox read — e.g. **`Mail.Read`** — granted to the managed identity as an **app-role assignment**, with **admin consent**.
**Why:** Polling from an unattended workflow uses **application** permissions (no signed-in user); the permission must be admin-consented and assigned to the identity, or every Graph call returns **403**.
**Verify:** Entra → **Enterprise applications** → the managed identity → **Permissions**; or run `GRAPHPOLL-Validate.ps1` (confirms the app-role assignment exists). `GRAPHPOLL-Set-AppRole.ps1 -WhatIf` previews the assignment.
**Implement-if-missing:** Assign the app role with `GRAPHPOLL-Set-AppRole.ps1` (defaults to `-WhatIf`; re-run with `-Execute`). **The exact least-privilege permission name and whether a narrower read scope than `Mail.Read` suffices must be verified against current Microsoft documentation** — do not assume; grant the narrowest that works.

## 2.4 The application permission scoped to ONE mailbox
**Description:** The managed identity's mailbox access **constrained to the single target mailbox** `supportmailbox@contoso.com`, via an **Application Access Policy** (mail-enabled security group `Mail Polling Scoped – Support Mailbox – Prod`) and/or the newer **Graph RBAC-for-Exchange** model.
**Why:** An application `Mail.Read` grant reads **every** mailbox in the tenant until scoped. Constraining to one mailbox is the **security spine** of this solution.
**Verify:** Test that the identity can read the target mailbox but is denied another; `GRAPHPOLL-Validate.ps1` checks the target is reachable. **Full scoping design/verification is covered by product #4** — not reproduced here.
**Implement-if-missing:** Apply the scope per **product #4** *"Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online"*. **Which model to use (Application Access Policy vs. Graph RBAC-for-Exchange) and their exact behavior must be verified against current Microsoft documentation.**

## 2.5 An Exchange Online target mailbox
**Description:** The Exchange Online mailbox to poll — `supportmailbox@contoso.com` — with a **`Processed`** mail folder for idempotent moves.
**Why:** This is the source of the messages the workflow reads and the destination folder that makes processing idempotent.
**Verify:** `admin.microsoft.com` / Exchange admin center shows the mailbox; `GRAPHPOLL-Discovery.ps1` reports current message/backlog counts.
**Implement-if-missing:** Confirm the licensed mailbox exists; create a child mail folder named **`Processed`** under the mailbox (the workflow moves handled items there).

## 2.6 A durable store for the watermark
**Description:** A place to persist the **high-water mark** (the `receivedDateTime` watermark or the delta `deltaLink`) between runs — options: a small **Azure Storage table/blob** (e.g. table `mailpollingwatermark`), a **Logic App Standard** stateful variable/workflow-state, or another durable key/value store.
**Why:** The watermark **must survive between runs**; a lost or reset watermark causes skipped mail or reprocessing of the whole mailbox.
**Verify:** The store is reachable and holds a readable watermark value; `GRAPHPOLL-Validate.ps1` checks the watermark store is reachable and `GRAPHPOLL-Report.ps1` reports the last-processed watermark.
**Implement-if-missing:** Provision an **Azure Storage account** and a table named `mailpollingwatermark` (recommended for Consumption Logic Apps), granting the **same managed identity** the least-privilege data role to read/write it. **Which store is available/natural differs between Consumption and Standard and must be verified against current Microsoft documentation.** Never store the watermark only in memory or a run-scoped variable.

## 2.7 Microsoft.Graph PowerShell (for the scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK on the operator workstation for the discovery/validation/reporting/watermark/app-role scripts.
**Why:** All five `GRAPHPOLL-*.ps1` scripts use Microsoft.Graph cmdlets to read grants, mailbox reachability, backlog, and to assign the app role.
**Verify:** `Get-Module Microsoft.Graph -ListAvailable`; run `GRAPHPOLL-Discovery.ps1` (it imports the modules).
**Implement-if-missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Sign in with an account holding the rights to read directory/app-role and (for `GRAPHPOLL-Set-AppRole.ps1`) to assign the app role and admin-consent.

## 2.8 National-cloud endpoint decision
**Description:** A decision on which **cloud** the tenant is in — commercial (`graph.microsoft.com`, `login.microsoftonline.com`) vs. a **national cloud** (e.g. GCC High / DoD: `graph.microsoft.us`, `login.microsoftonline.us`).
**Why:** The Graph host, login authority, and Logic App HTTP audience differ by cloud; a workflow or script pointed at the wrong endpoint fails to authenticate or returns nothing.
**Verify:** Confirm the tenant's cloud and its Graph/login endpoints. **The exact national-cloud endpoint hosts and feature parity must be verified against current Microsoft documentation.**
**Implement-if-missing:** Set the HTTP action's Graph base URL, the managed-identity **audience**, and the Microsoft.Graph PowerShell **environment** (`Connect-MgGraph -Environment <…>`) to the correct cloud before building or running anything.

---
## Checklist
- [ ] Azure Logic App `Mail Polling – Support Mailbox – Pilot` (Consumption vs Standard decided — verify) — `GRAPHPOLL-Discovery.ps1`
- [ ] Managed identity on the Logic App (system- or user-assigned) — object id recorded
- [ ] Least-privilege application Graph permission (e.g. `Mail.Read`) + admin consent — `GRAPHPOLL-Validate.ps1`
- [ ] Application permission **scoped to one mailbox** `supportmailbox@contoso.com` (per product #4)
- [ ] Exchange Online mailbox + a `Processed` folder
- [ ] Durable watermark store reachable (e.g. table `mailpollingwatermark`) — `GRAPHPOLL-Validate.ps1`
- [ ] Microsoft.Graph PowerShell installed
- [ ] National-cloud endpoints confirmed (verify)
