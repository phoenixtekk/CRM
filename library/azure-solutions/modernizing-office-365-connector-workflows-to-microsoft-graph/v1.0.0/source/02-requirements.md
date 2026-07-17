# 2. Requirements Guide — Modernizing Office 365 Connector Workflows to Microsoft Graph

Verify **every** requirement before running the program. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md` (G1–G6). Objects created during the program are named `<Purpose> – <Scope> – <Stage>` and reused verbatim.

> **Verify-against-Microsoft flags appear throughout.** Whether a specific Office 365 connector trigger/action supports managed identity, the exact Microsoft Graph application permission names/scopes, and the Power Platform enumeration surface all drift between platform and connector versions — **confirm each against current Microsoft documentation at migration time**; this guide states the target and flags the specifics.

## 2.1 Read access to enumerate the Logic Apps estate

**Description:** An account with **Reader** (or higher) across the Azure subscriptions/resource groups that hold Logic Apps, so the program can list every Logic App and inspect its workflow definition and connections.
**Why:** The inventory step must find every Logic App that uses an Office 365 connector and record how it authenticates; that requires read access to the workflow definitions and their API connections across the estate.
**Verify:** `portal.azure.com` → **Subscriptions → Access control (IAM)** shows **Reader** at the needed scopes; run `O365GRAPH-Discovery.ps1` (read-only) — it lists Logic Apps and their Office 365 connections.
**Implement-if-missing:** Assign **Reader** at the narrowest scope that still covers every subscription/resource group holding Logic Apps; prefer PIM-eligible activation over standing access.

## 2.2 Read access to enumerate Power Automate flows (Power Platform)

**Description:** A **Power Platform administrator** (or equivalent read role) able to enumerate flows and their connection references across the environments in scope.
**Why:** Power Automate flows are **not** Azure resources — they live in the Power Platform and are enumerated through a Power Platform admin method, separate from the Azure Logic Apps inventory. Without this role the inventory misses half the estate.
**Verify:** `admin.powerplatform.microsoft.com` resolves and lists the in-scope environments; confirm the account can view flows and connections.
**Implement-if-missing:** Grant the Power Platform admin (or a scoped read) role for the in-scope environments. **The exact enumeration method (admin center export, Power Platform admin PowerShell/CLI, or Dataverse query) is a `verify against current Microsoft documentation` item** — the capability and command names change between platform versions.

## 2.3 Rights to create managed identities and grant application permissions

**Description:** Rights to create/assign **Azure managed identities** for Logic Apps (Contributor on the Logic App), and an identity role able to **grant Microsoft Graph application permissions and admin-consent** them (e.g. Privileged Role Administrator / Global Administrator for consent, or a delegated app-management role).
**Why:** The modern end state assigns each migrated Logic App a managed identity and grants it a **scoped Graph application permission**; creating the identity and consenting the permission both require these rights.
**Verify:** Confirm the operating account can add a managed identity to a Logic App and grant/admin-consent an application permission (Entra → **Enterprise applications** / **App registrations**); `O365GRAPH-Set-AppRole.ps1 -WhatIf` reports whether the intended app-role assignment is permitted.
**Implement-if-missing:** Assign the minimum roles at the narrowest scope; separate "create the identity" (Contributor on the Logic App) from "consent the permission" (a consent-capable role) where your org splits those duties. **The exact Graph application permission required for a given flow (e.g. a mail permission) is a `verify against current Microsoft documentation` item** — confirm the current least-privilege permission name and use it.

## 2.4 Rights to scope mailbox access (defer the mechanism to sibling #4)

**Description:** The ability to constrain a migrated flow's Graph **application** mailbox access to only the mailbox(es) it needs — via an **Application Access Policy** or the newer Graph **RBAC-for-Exchange** model.
**Why:** A Graph mail application permission is tenant-wide by default; least privilege requires scoping it down. This program **defers the "how" to sibling #4** ("Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online") and treats the scoping as a required gate on every mail-touching flow.
**Verify:** Confirm Exchange Online admin rights sufficient to create the scoping construct; sibling #4 details the verification.
**Implement-if-missing:** Follow sibling #4. **Which mechanism to use — the established Application Access Policy vs the newer Graph RBAC-for-Exchange model — is a `verify against current Microsoft documentation` item**; pick the current recommended one for your tenant and cloud.

## 2.5 Microsoft.Graph PowerShell and an enumeration method for Power Automate

**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operating workstation, plus **Az** PowerShell (for Logic Apps enumeration) and whatever Power Platform enumeration method your tenant supports.
**Why:** The program's scripts (`O365GRAPH-*.ps1`) use Microsoft.Graph for identity/permission checks and Az for Logic Apps discovery; Power Automate enumeration uses a separate Power Platform method.
**Verify:** `Get-Module Microsoft.Graph -ListAvailable` and `Get-Module Az -ListAvailable` return versions; run `O365GRAPH-Discovery.ps1` — it reports which modules/methods are available.
**Implement-if-missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` and `Install-Module Az -Scope CurrentUser`. **The Power Platform enumeration module/command is a `verify against current Microsoft documentation` item** — install the current supported one.

## 2.6 A named pilot cohort

**Description:** A small, representative set of connector-based flows chosen as the first migration wave — the **PILOT – Connector Migration – Pilot** cohort — covering the flow types that matter (a send flow, an event/trigger flow, a polling flow) and, ideally, both a Logic App and a Power Automate flow.
**Why:** The program is pilot-first: the method is proven on a small cohort and gated before any wave. A representative pilot exercises every per-flow pattern once.
**Verify:** A written pilot list exists; each pilot flow is tagged in the **Migration Register – Estate – Program**.
**Implement-if-missing:** Pick 3–8 flows spanning the sibling patterns (#1 send/read, #2 change-notification trigger, #3 polling) and both platforms; record them as the pilot cohort.

## 2.7 Change control, parity baseline, and per-flow rollback

**Description:** An approved change window per wave, a captured **parity baseline** for each flow (what the legacy connector flow does — its trigger, its outputs, its schedule), and a documented **per-flow rollback** (re-enable the legacy flow, disable the migrated one) before any cutover.
**Why:** A migrated flow must match the legacy flow's behaviour; parity can only be judged against a captured baseline, and a cutover that breaks parity must be reversible per flow.
**Verify:** An approved change record, a per-flow parity baseline, and a written rollback exist (per `global-requirements-azure-solutions.md` G5/G6).
**Implement-if-missing:** Capture each pilot/wave flow's behaviour with `O365GRAPH-Discovery.ps1` output as the baseline; write the per-flow rollback (the legacy flow is **disabled, not deleted**, until its migrated replacement passes validation and a grace period elapses).

## 2.8 National-cloud endpoint confirmation (if applicable)

**Description:** For government/sovereign tenants (GCC / GCC High / DoD), confirmation of the correct Graph, Azure, and Power Platform endpoints and any feature-parity gaps.
**Why:** Government clouds use distinct endpoints and can lag commercial on connector/Graph features; a step correct for commercial can be wrong for a sovereign cloud.
**Verify:** Confirm the tenant's cloud and the matching endpoint set (per `global-requirements-azure-solutions.md` G4).
**Implement-if-missing:** Target the correct sovereign endpoints. **National-cloud endpoints and feature parity are a `verify against current Microsoft documentation` item** — do not assume commercial specifics apply.

---
## Checklist
- [ ] Reader across the Logic Apps estate — `O365GRAPH-Discovery.ps1`
- [ ] Power Platform admin / read to enumerate Power Automate flows (method: verify)
- [ ] Rights to create managed identities + grant/consent Graph application permissions
- [ ] Rights to scope mailbox access (mechanism deferred to sibling #4; verify AAP vs Graph RBAC)
- [ ] Microsoft.Graph + Az PowerShell installed; Power Platform enumeration method (verify)
- [ ] Named pilot cohort `PILOT – Connector Migration – Pilot`
- [ ] Change window, per-flow parity baseline, and per-flow rollback documented
- [ ] National-cloud endpoints confirmed if government (verify)
