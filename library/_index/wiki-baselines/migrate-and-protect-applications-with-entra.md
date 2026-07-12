# Migrate & Protect Applications with Entra

> **Version 1.0.0** · Category: Entra · Solution code: ENTAPPMIG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Migrate & Protect Applications with Entra

## The problem
Most organizations run a long tail of applications whose authentication is stuck in the past: relying
parties on an **AD FS** farm nobody wants to touch, internal web apps reachable only over the VPN, and a
handful of SaaS apps wired up with bespoke or forgotten SSO. Each one is an unmanaged risk. AD FS is a
single point of failure and a prized attacker target (Golden SAML); on-prem-only apps force the flat
network access that Zero Trust is meant to end; and apps outside Entra can't be protected by Conditional
Access, can't be reviewed, and don't show up when an auditor asks "which apps can this user reach, and
under what conditions." The result is a fragile estate that blocks the move to Zero Trust.

## The solution
This solution **migrates application authentication to Microsoft Entra** and protects every app it moves,
in four coordinated tracks:
1. **Discover & plan** — inventory AD FS relying parties, on-prem web apps, and SaaS SSO; use the **AD FS
   application activity** signal to prioritize; produce a per-app **migration plan** with a cutover and
   rollback for each.
2. **Migrate AD FS → Entra SSO** — recreate each relying party as an Entra **enterprise application**
   (SAML/OIDC), validate with a **pilot** audience, then **cut over** federation to Entra and retire the
   AD FS relying party — reversible at every step.
3. **Publish on-prem apps** — make internal web apps reachable without a VPN via **Application Proxy** (or
   **GSA Private Access**), with pre-authentication in Entra.
4. **Provision & protect** — automate account provisioning with **SCIM**, and wrap **every migrated app**
   in **Conditional Access** and periodic **access reviews**.

Delivery follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model: migrate and
prove **one** app of each type against a pilot group first, confirm explicit pass/fail gates, then move
the rest in waves — AD FS kept live as fallback until each relying party is validated on Entra.

## What's included
Full documentation (overview, requirements, ordered implementation, testing matrix, troubleshooting,
best practices) plus **five PowerShell (Microsoft Graph) tools** — with **KQL** for sign-in evidence —
that inventory AD FS relying parties and Entra apps, validate the named migrated objects, report SCIM
provisioning status, export cutover/sign-in evidence, and preview cutover changes. Every tool is
**read-only or `-WhatIf` by default**, uses least-privilege Graph scopes, and stores **no credentials**.

## Business value
- **AD FS retired** — the single point of failure and Golden SAML target is removed, app-by-app.
- **On-prem apps reachable without a VPN** — published through Entra with pre-authentication.
- **Every app under Conditional Access** — MFA, device compliance, and risk conditions on all app access.
- **Provisioning automated** — SCIM creates/updates/deprovisions accounts, closing the leaver gap.
- **Audit-ready & reversible** — access reviews per app, and a documented rollback for every cutover.

## Effort and boundary
A competent identity admin can migrate and protect the pilot (one AD FS relying party, one App Proxy app,
one SCIM integration, and Conditional Access) in a few focused sessions, then migrate the rest in waves.
This is a **technical implementation** guide: it provides the migration method, the publishing and
provisioning setup, and the automation. The application **inventory decisions** — which apps migrate in
which wave, cutover windows, and app-owner sign-off — remain the customer's change-management calls.

> **Scope note (avoids overlap):** this solution is the **AD FS migration + on-prem publishing** track. If
> you need **SSO onboarding at scale** — a repeatable factory for integrating many SAML/OIDC SaaS apps —
> that is the separate *Cloud Identity as Enterprise IdP — SAML App Integration Factory* solution; the two
> are complementary and cross-referenced in §7.
>
> **Licensing & preview note:** **Application Proxy** and Conditional Access require **Entra ID P1**;
> **GSA Private Access** (an alternative publishing path) requires the **Microsoft Entra Suite / Private
> Access** add-on; **access reviews** require **Entra ID Governance / P2**. Some capabilities may be in
> **preview**. *Verify current licensing and feature availability in your tenant before you begin.*


---


# 1. Solution Overview — Migrate & Protect Applications with Entra

## What this solution is
This solution moves **application authentication** onto **Microsoft Entra** and protects every app it
migrates. It covers the three ways an app is typically stranded and brings each into the Entra control
plane:

- **AD FS relying parties → Entra SSO.** Recreate each AD FS relying party as an Entra **enterprise
  application** using **SAML** or **OIDC**, migrate claim/attribute logic, validate on a pilot, then
  **cut over** and retire the AD FS relying party — removing the AD FS dependency app-by-app.
- **On-prem web apps → published through Entra.** Make internal web apps reachable **without a VPN** using
  **Microsoft Entra Application Proxy** (a connector-based reverse proxy) or **GSA Private Access**, with
  **pre-authentication** in Entra so Conditional Access applies before the app is ever reached.
- **SaaS / modern apps → integrated + provisioned.** Integrate SAML/OIDC apps and automate account
  lifecycle with **SCIM** provisioning, then protect them with Conditional Access and access reviews.

## How the technology works
Everything is configured under **Enterprise applications** and **Application proxy** in the Microsoft
Entra admin center (`https://entra.microsoft.com`) and is backed by the Microsoft Graph `applications`,
`servicePrincipals`, and `onPremisesPublishing` APIs. The building blocks:

- **Enterprise application (+ service principal)** → the migrated app in Entra. It holds the **SSO
  configuration** (SAML metadata / OIDC settings), the **user/group assignments**, the **provisioning**
  (SCIM) job, and is the resource a Conditional Access policy targets.
- **AD FS application activity** → a usage/insights report (Entra → **Usage & insights**) that lists AD FS
  relying parties and whether each is ready to migrate, so you prioritize by real usage.
- **Application Proxy connector group** → connectors installed on-prem that make outbound-only
  connections to Entra; a **published app** maps an **external URL** to an **internal URL** and sets the
  **pre-authentication** method (Entra ID) and SSO mode (KCD / header-based / password).
- **Provisioning (SCIM) job** → on the enterprise app; connects to the app's SCIM endpoint with a tenant
  URL + secret token, **maps attributes**, and is **scoped** to a group so it creates/updates/deprovisions
  only in-scope users.
- **Conditional Access policy** → targets the migrated app(s) and enforces MFA / compliant device / risk.
- **Access review** → recurring recertification of who is assigned to each migrated app.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand** — inventory AD FS relying parties, on-prem apps, and
> SaaS SSO and build the migration plan (Assess); recreate one AD FS app in Entra, publish one on-prem app
> via App Proxy, set up one SCIM integration, and author the Conditional Access policy (Configure); target
> them at a small **pilot** group and keep AD FS live (Pilot); prove the pass/fail gates — pilot SSO works
> on Entra, the published app loads without VPN, SCIM provisions, CA enforces (Validate); then cut over the
> AD FS relying party and migrate the remaining apps in waves (Expand). Every cutover is reversible.

## What is in scope
- **App discovery + a per-app migration plan** (AD FS relying parties, on-prem web apps, SaaS SSO).
- **One AD FS relying party migrated** to an Entra enterprise app with staged **cutover + rollback**
  (the repeatable pattern for the rest).
- **One on-prem web app published** via **Application Proxy** (or GSA Private Access) with Entra
  pre-authentication.
- **One SAML/OIDC integration** with **SCIM provisioning** (create/update/deprovision).
- **Conditional Access** protection and a recurring **access review** for the migrated apps.
- Read-only **reporting** for cutover/sign-in evidence via the included scripts (Graph + KQL).

## What is out of scope
- **SSO onboarding at scale** — a repeatable factory for integrating **many** SaaS SAML/OIDC apps — is the
  **separate, adjacent** *Cloud Identity as Enterprise IdP — SAML App Integration Factory* solution. This
  solution is the **AD FS migration + on-prem publishing** track; use the Factory when the job is "onboard
  50 SaaS apps to SSO," and this solution when the job is "get off AD FS and publish on-prem apps."
- **Conditional Access baseline design** (the full Zero Trust policy set) — a separate solution; here CA
  is *applied to* the migrated apps.
- **Network-layer ZTNA** for non-web/TCP apps at fleet scale — that is **GSA Private Access** in the
  *Entra Global Secure Access* solution (referenced as an alternative publishing path here).
- The **decision** of which apps migrate in which wave, cutover windows, and app-owner sign-off — those
  are the customer's change-management determinations.

## Authentication and connections used
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) → **Enterprise applications**,
  **Application proxy**, **Usage & insights (AD FS application activity)**, **Conditional Access**.
- **Microsoft Graph** for the automation scripts, via `Connect-MgGraph` with least-privilege scopes
  (`Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, `AuditLog.Read.All`; write scopes only
  for the gated cutover preview). No credentials or secrets are stored in the scripts.
- **AD FS management** (`Get-AdfsRelyingPartyTrust`, run on an AD FS server) for the on-prem relying-party
  inventory that Graph can't see directly.
- **Application Proxy connectors** on-prem; and, optionally, **Azure Monitor / Log Analytics** for the
  sign-in KQL.

## Limitations (be honest with buyers)
- **Licensing gate:** Application Proxy + Conditional Access need **Entra ID P1**; **GSA Private Access**
  needs the **Entra Suite / Private Access** add-on; **access reviews** need **Entra ID Governance / P2**.
  *Verify current SKU coverage against Microsoft's documentation and your tenant.*
- **Cutover is a real change.** Repointing federation from AD FS to Entra affects live sign-in — always
  pilot with a limited audience, keep AD FS as fallback, and cut over under change control.
- **Claims parity matters.** Complex AD FS **claim rules** (transforms, custom attributes) must be
  reproduced as Entra **claims mapping**; some edge cases need extra work — the plan flags these per app.
- Portal blade names and Graph beta endpoints evolve; match by intent and verify against current guidance.


---


# 2. Requirements Guide — Migrate & Protect Applications with Entra

Verify **every** requirement before you migrate any application. Each entry: **Description · Why required ·
How to verify · How to implement if missing.** The category-wide prerequisites (an active Entra ID tenant,
base licensing, administrative roles, and break-glass accounts) are defined once in
`global-requirements-entra-id-solutions.md` — confirm those first. The items below are **specific to
application migration and publishing**.

## 2.1 Licensing for the publishing + protection features
**Description:** **Application Proxy** and **Conditional Access** require **Entra ID P1**; **GSA Private
Access** (an alternative publishing path) requires the **Microsoft Entra Suite / Private Access** add-on;
**access reviews** for migrated apps require **Entra ID Governance / P2**.
**Why required:** Without the right SKU the publishing blade, CA targeting, or access-review creation is
blocked, and licensing applies to the **users who use** the apps.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**; confirm P1 (and Governance/P2 if
using access reviews). In Entra, **Application proxy** and **Conditional Access** load without a licensing
banner. Run **`ENTAPPMIG-Discovery.ps1`**.
**How to implement if missing:** Assign Entra ID P1 (often via M365 E3/E5 or EMS) to in-scope users; add
Governance/P2 for access reviews and the Private Access add-on if publishing via GSA. *Verify current SKU
rules against Microsoft's documentation.*

## 2.2 Application Administrator / Cloud Application Administrator role
**Description:** The operator holds **Application Administrator** (or **Cloud Application Administrator**)
to create and configure enterprise apps, plus **Conditional Access Administrator** to protect them.
**Why required:** Creating enterprise apps, configuring SSO/provisioning, and publishing via App Proxy
need the application admin role; wiring CA needs the CA admin role.
**How to verify:** Entra → **Roles and administrators**; confirm the roles on the operator.
**How to implement if missing:** Assign **Application Administrator** and **Conditional Access
Administrator**; reserve Global Administrator for the one-time federation/cutover steps only.

## 2.3 The AD FS relying parties are inventoried
**Description:** A list of the **AD FS relying party trusts** to migrate, with each one's **entity ID
(identifier)**, **reply/ACS URL(s)**, **claim rules**, and **usage**.
**Why required:** Each Entra enterprise app must reproduce the relying party's identifier, URLs, and claims
to be a drop-in replacement; you migrate by real usage, not guesswork.
**How to verify:** On an AD FS server, `Get-AdfsRelyingPartyTrust` lists trusts; Entra → **Usage &
insights → AD FS application activity** shows usage and migration readiness. Run **`ENTAPPMIG-Discovery.ps1`**
(which reads both where available).
**How to implement if missing:** Export the relying-party inventory from AD FS and the AD FS application
activity report; record identifier, URLs, and claim rules per app. Start the pilot with **one** app.

## 2.4 The on-prem apps to publish are identified (internal + external URL)
**Description:** For each internal web app to publish, its **internal URL** (as the connector resolves it),
the desired **external URL**, and its **SSO method** (KCD/IWA, header-based, or password) are known.
**Why required:** Application Proxy maps an external URL to an internal URL and performs pre-auth + SSO;
you must know both URLs and the app's native auth to publish it correctly.
**How to verify:** You have, per app: internal URL, external URL (a verified custom domain or the default
`msappproxy.net`), and SSO mode. Run **`ENTAPPMIG-Discovery.ps1`** to list already-published apps.
**How to implement if missing:** Document each app's URLs and SSO mode with the app owner; verify any custom
domain in Entra; start the pilot with a **single, low-risk internal web app**.

## 2.5 An Application Proxy connector host
**Description:** At least one **Windows Server (2019/2022+)**, patched, with **outbound HTTPS** to the
Entra Application Proxy service and network line-of-sight to the internal app(s). Two per location for HA.
**Why required:** The App Proxy connector is the outbound-only bridge from Entra to the internal app; no
inbound firewall ports are opened.
**How to verify:** A server that can resolve/reach the app's internal URL with outbound 443 to the App
Proxy endpoints; the connector shows **Active** after install. (If publishing via GSA Private Access
instead, use that solution's connector — see the *Entra Global Secure Access* solution.)
**How to implement if missing:** Provision the server (not a domain controller), open outbound 443, and
install the connector from **Application proxy → Download connector service**. Deploy **two** for HA.

## 2.6 SCIM endpoint + credentials for provisioning (where used)
**Description:** For apps that support **SCIM**, the app's **SCIM base URL** and a **secret token** (or
OAuth) with permission to create/update/deprovision users.
**Why required:** Automatic provisioning connects Entra to the app's SCIM endpoint; without valid
credentials the provisioning job can't write.
**How to verify:** The app vendor provides a SCIM URL + token; a **Test connection** in the provisioning
blade succeeds. Run **`ENTAPPMIG-Provisioning.ps1`** to report provisioning status once configured.
**How to implement if missing:** Obtain the SCIM endpoint + token from the app owner/vendor; store the
token only in the provisioning config (never in scripts). Not all apps support SCIM — those stay
assignment-only.

## 2.7 A pilot group and named app owners / approvers
**Description:** An Entra security group **`ENTAPPMIG-Pilot`** with test users for each app type, and named
**app owners** to validate function and act as **reviewers** for access reviews.
**Why required:** The pilot-first model targets `ENTAPPMIG-Pilot`; validation and reviews need real
identities and someone who knows the app to confirm it still works after migration.
**How to verify:** Entra → **Groups**; confirm `ENTAPPMIG-Pilot` and members; confirm app-owner identities.
**How to implement if missing:** Create `ENTAPPMIG-Pilot` (Assigned) with test users who actually use the
apps; nominate an owner/reviewer per app.

## 2.8 Ability to repoint federation / DNS at cutover
**Description:** Control over the **federation setting** or **DNS/relying-party** repoint needed to move an
app from AD FS to Entra at cutover — e.g. updating the app's SAML endpoint to Entra, or converting a domain
from federated to managed where relevant.
**Why required:** Cutover is where sign-in actually moves; you must be able to make (and reverse) the
repoint under change control.
**How to verify:** You know, per app, exactly what changes at cutover (the app's IdP endpoint/metadata) and
how to roll it back to AD FS. For domain-level federation, Global Administrator is available for the change.
**How to implement if missing:** Work with the app owner to identify the cutover change and its rollback
before migrating; schedule cutover in a change window with AD FS kept live as fallback.

## 2.9 Microsoft Graph PowerShell toolchain
**Description:** The **Microsoft Graph PowerShell SDK** on the operator's workstation (and, for the AD FS
inventory, PowerShell access to an **AD FS server**), with consent for the read scopes the scripts use.
**Why required:** The five tools authenticate via `Connect-MgGraph`; the discovery tool also reads AD FS
relying parties from an AD FS server where available.
**How to verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; running
**`ENTAPPMIG-Discovery.ps1`** connects successfully.
**How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to
`Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, `AuditLog.Read.All` on first run.

---
## Checklist
- [ ] Category global requirements confirmed (`global-requirements-entra-id-solutions.md`)
- [ ] Licensing: P1 (App Proxy + CA); Governance/P2 (access reviews); Private Access add-on if using GSA — *verify*
- [ ] Application Administrator (+ Conditional Access Administrator) role held
- [ ] AD FS relying parties inventoried (identifier, URLs, claims, usage) — `ENTAPPMIG-Discovery.ps1`
- [ ] On-prem apps identified (internal + external URL, SSO mode)
- [ ] Application Proxy connector host(s) provisioned with outbound 443
- [ ] SCIM endpoint + token available for apps that support it — `ENTAPPMIG-Provisioning.ps1`
- [ ] `ENTAPPMIG-Pilot` group created; app owners/reviewers nominated
- [ ] Cutover + rollback (federation/DNS repoint) understood per app
- [ ] Microsoft Graph PowerShell SDK installed (+ AD FS server access) — `ENTAPPMIG-Discovery.ps1`


---


# Global Requirements — Entra ID Solutions (category-level)

These requirements apply to every solution in the Entra ID Solutions category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying any identity solution. Each entry: Description / Why / Verify / Implement-if-missing.

> The identity plane is high risk. A mistake here breaks sign-in for everyone, so every change is
> staged and a break-glass account is kept ready before you touch anything.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID tenant.
Why: It is the cloud identity backbone every other identity service builds on.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 or Azure subscription, which provisions a tenant.

## G2. Entra ID licensing (P1, P2 where noted)
Description: Microsoft Entra ID P1 (or P2 for risk-based and PIM features).
Why: Hybrid features such as seamless sign-in, password writeback, and Conditional Access require P1+.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2 (often bundled in M365 E3/E5 or EMS).
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## G3. Administrative roles
Description: Hybrid Identity Administrator and Global Administrator for the operator.
Why: Configuring directory synchronization and authentication methods needs these elevated roles.
Verify: Entra -> `Roles and administrators`; confirm `Hybrid Identity Administrator` (and a Global Administrator for the one-time first-sync consent).
Implement: Assign `Hybrid Identity Administrator`; reserve `Global Administrator` for tenant-wide and first-sync changes.

## G4. Break-glass (emergency access) accounts
Description: At least two cloud-only emergency access accounts, excluded from Conditional Access and MFA-broad policies.
Why: If sync, federation, or an auth-method change locks out admins, break-glass accounts get you back in.
Verify: Entra -> `Users`; confirm two cloud-only accounts (`@onmicrosoft.com`) with strong stored credentials and documented use.
Implement: Create two cloud-only Global Administrator accounts; exclude them from policies; store credentials securely and monitor sign-ins.

## G5. Healthy on-premises Active Directory
Description: A functional AD forest/domain with healthy replication and DNS.
Why: Synchronization reads from AD; replication or DNS faults corrupt or stall the sync.
Verify: Run `dcdiag` and `repadmin /replsummary` on a domain controller with no errors; run `HYBID-Discovery.ps1`.
Implement: Resolve AD replication, DNS, and time-sync issues before synchronizing.

## G6. An Entra Connect host server
Description: A domain-joined Windows Server (2016+), patched, for Microsoft Entra Connect Sync (or a lightweight host with the Cloud Sync agent).
Why: Connect Sync runs as a service on this host and must reach both AD and Entra ID.
Verify: A supported, domain-joined server with TLS 1.2, .NET, and PowerShell available; run `HYBID-Discovery.ps1`.
Implement: Provision a dedicated server (not a domain controller for production), patch it, and enable TLS 1.2.

## G7. UPN / domain hygiene
Description: User principal names use a public, verified, routable domain (not `.local`).
Why: A non-routable UPN suffix produces sign-in problems and `onmicrosoft.com` fallbacks in the cloud.
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; AD UPN suffixes match it; run `HYBID-Discovery.ps1`.
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD and update user UPNs.

## G8. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS (443) from the Connect host to Entra ID, plus required Microsoft 365 service URLs.
Why: Synchronization, authentication-agent traffic, and tokens depend on these endpoints.
Verify: From the Connect host, reach `https://login.microsoftonline.com` and the Microsoft 365 published URL/IP ranges.
Implement: Allow the Microsoft 365 / Entra service URLs and IP ranges through the proxy/firewall.

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation Guide — Migrate & Protect Applications with Entra

Follow these steps **in order**, in the **Microsoft Entra admin center** (`https://entra.microsoft.com`).
Names in `code` are the exact objects to create — keep them consistent so the scripts, testing, and
troubleshooting all refer to the same objects. Portal blade names evolve; if a label differs, match by
intent and verify against current Microsoft guidance.

**Object naming convention:** `ENTAPPMIG – <Purpose> – <Scope> – <Stage>`. The objects you will build:

| Object | Name |
|--------|------|
| Pilot user group | `ENTAPPMIG-Pilot` |
| Migrated AD FS app (enterprise app) | `ENTAPPMIG – App – LOBSaml – Pilot` |
| Application Proxy connector group | `ENTAPPMIG – ConnectorGroup – OnPrem` |
| Published on-prem web app | `ENTAPPMIG – AppProxy – Intranet – Pilot` |
| SCIM-provisioned app (enterprise app) | `ENTAPPMIG – App – ScimSaaS – Pilot` |
| Conditional Access (migrated apps) | `ENTAPPMIG – CA – MigratedApps – Pilot` |
| Access review (migrated apps) | `ENTAPPMIG – Review – MigratedApps – Quarterly` |

> **Model:** Assess → Configure → Pilot → Validate → Expand. Build each object, scope it to
> **`ENTAPPMIG-Pilot`** first, prove the gates in §5, then cut over and expand in waves. Keep **AD FS live**
> as fallback until each relying party is validated on Entra. Every cutover has a rollback (see end of file).

## Step 1 — Assess and build the migration plan
1. Run **`ENTAPPMIG-Discovery.ps1`** — inventories AD FS relying parties (from an AD FS server where
   reachable), the **AD FS application activity** report, existing Entra enterprise apps, and App Proxy
   connector groups. This is your starting map.
2. In Entra → **Identity → Applications → Usage & insights → AD FS application activity**, review each
   relying party's usage and **migration readiness**. Prioritize the plan by real usage.
3. Pick the **pilot apps**: one AD FS relying party (`ENTAPPMIG – App – LOBSaml – Pilot`), one on-prem web
   app (`ENTAPPMIG – AppProxy – Intranet – Pilot`), and one SCIM-capable SaaS app
   (`ENTAPPMIG – App – ScimSaaS – Pilot`). Confirm `ENTAPPMIG-Pilot` exists with test users.

## Step 2 — Recreate the AD FS relying party as an Entra enterprise app
1. **Identity → Applications → Enterprise applications → + New application.** From the gallery pick the
   app if listed, otherwise **+ Create your own application → Non-gallery**. Name it
   `ENTAPPMIG – App – LOBSaml – Pilot`.
2. **Single sign-on → SAML** (or OIDC if the app uses it). Set:
   - **Identifier (Entity ID)** = the exact value from the AD FS relying party (Requirement 2.3).
   - **Reply URL (ACS)** = the app's assertion consumer service URL(s).
   - **Sign-on URL / relay state** as needed.
3. **Attributes & Claims** — reproduce the AD FS **claim rules** as Entra **claims mapping** (NameID
   format, and each attribute the app expects). Flag any complex transform for extra work.
4. **SAML signing certificate** — download the Entra federation metadata / certificate to hand to the app
   owner for the cutover.
5. **Users and groups → + Add:** assign **`ENTAPPMIG-Pilot`** only (pilot-first).

## Step 3 — Deploy Application Proxy connectors
1. **Identity → Applications → Application proxy → Download connector service.** Install it on the
   connector host (Requirement 2.5) and sign in with an application admin.
2. Confirm the connector shows **Active**; install a **second** connector for HA.
3. **Application proxy → Connector groups → + New connector group**, name
   `ENTAPPMIG – ConnectorGroup – OnPrem`, and assign both connectors.

## Step 4 — Publish the on-prem web app via Application Proxy
1. **Enterprise applications → + New application → On-premises application** (Application Proxy).
2. **Basics:** Name `ENTAPPMIG – AppProxy – Intranet – Pilot`; **Internal URL** = the app's internal
   address; **External URL** = your published address; **Pre-authentication = Microsoft Entra ID**;
   **Connector group** = `ENTAPPMIG – ConnectorGroup – OnPrem`.
3. **Single sign-on** — set the mode the app needs (e.g. **Integrated Windows Authentication (KCD)**,
   **Header-based**, or **Password-based**).
4. **Users and groups → + Add:** assign **`ENTAPPMIG-Pilot`**.
5. Browse the **External URL** as a pilot user — you should be pre-authenticated by Entra and land on the
   app **without a VPN**.
   > **Alternative publishing path:** for non-web/TCP apps or full ZTNA, publish via **GSA Private Access**
   > instead (see the *Entra Global Secure Access* solution). App Proxy is for **web** apps with browser SSO.

## Step 5 — Integrate a SaaS app and configure SCIM provisioning
1. **Enterprise applications → + New application →** add the SaaS app (gallery or non-gallery). Name it
   `ENTAPPMIG – App – ScimSaaS – Pilot`. Configure **SSO (SAML/OIDC)** as in Step 2.
2. **Provisioning → Get started → Provisioning Mode = Automatic.**
3. **Admin Credentials:** enter the app's **SCIM base URL** + **secret token** (Requirement 2.6);
   **Test connection** must succeed.
4. **Mappings** — confirm/adjust the attribute mappings (which Entra attributes flow to the app).
5. **Settings → Scope = Sync only assigned users and groups**; assign **`ENTAPPMIG-Pilot`**.
6. **Provision on demand** for one pilot user to prove create/update works before turning the job on.

## Step 6 — Protect the migrated apps with Conditional Access
1. **Entra → Protection → Conditional Access → + New policy.** Name `ENTAPPMIG – CA – MigratedApps – Pilot`.
2. **Users:** include **`ENTAPPMIG-Pilot`**; **exclude** your **break-glass** accounts (global requirement G4).
3. **Target resources:** select the migrated apps — `ENTAPPMIG – App – LOBSaml – Pilot`,
   `ENTAPPMIG – AppProxy – Intranet – Pilot`, `ENTAPPMIG – App – ScimSaaS – Pilot`.
4. **Grant:** require **Multi-factor authentication** and (for managed devices) **Require device to be
   marked as compliant**.
5. **Enable policy: Report-only** first. Create. Review **Insights**, then switch to **On** once validated.

## Step 7 — Add an access review for the migrated apps
1. **Identity governance → Access reviews → + New access review.** *(Requires Governance/P2 — verify.)*
2. **Review type:** **Applications → Select applications →** the migrated apps.
3. **Name:** `ENTAPPMIG – Review – MigratedApps – Quarterly`; **Recurrence:** Quarterly; **Reviewers:** the
   app owner / manager. **Auto apply = Enabled**; for the **first** cycle set don't-respond → **No change**.
4. **Create.** This recertifies who can reach each migrated app over time.

## Step 8 — Validate the pilot (the gates)
Run **`ENTAPPMIG-Validate.ps1`** and confirm on `ENTAPPMIG-Pilot` (see §5 for the full matrix):
- **G1 AD FS app on Entra** — a pilot user signs into `ENTAPPMIG – App – LOBSaml – Pilot` via **Entra**
  (test endpoint) and gets the right claims — **while AD FS is still live**.
- **G2 Published app, no VPN** — with the **VPN disconnected**, a pilot user reaches
  `ENTAPPMIG – AppProxy – Intranet – Pilot` at its external URL, pre-authenticated by Entra.
- **G3 SCIM provisions** — provision-on-demand creates/updates a pilot user in the SaaS app.
- **G4 Conditional Access** — access to the migrated apps enforces MFA/compliant device.

**Pass** = all four gates green. **Fail** = fix before cutover/expand (see §6).

## Step 9 — Cut over the AD FS relying party
1. Preview with **`ENTAPPMIG-Cutover.ps1`** (report-only / `-WhatIf`) — it summarizes the app's Entra
   config, assignments, and CA coverage so you cut over with eyes open.
2. In a **change window**, repoint the app's federation from AD FS to **Entra** (update the app's IdP
   endpoint/metadata to the Entra values from Step 2, per Requirement 2.8).
3. Validate real users sign in through Entra. **Then** disable the **AD FS relying party** (do not delete
   it yet — keep it disabled as an instant rollback).
4. After a soak period with no issues, **remove** the AD FS relying party.

## Step 10 — Expand in waves
1. Repeat Steps 2–6 for the next apps, using the same convention
   (`ENTAPPMIG – App – <App> – Prod`, `ENTAPPMIG – AppProxy – <App> – Prod`), migrating by usage priority.
2. **Broaden assignments** from `ENTAPPMIG-Pilot` to the real user population per app.
3. **Broaden CA scope** and switch `ENTAPPMIG – CA – MigratedApps – Pilot` from Report-only to **On**.
4. **Broaden the access review** scope to all migrated apps; switch don't-respond to **Remove access** once
   reviewers are trained.
5. Re-run **`ENTAPPMIG-Validate.ps1`** and **`ENTAPPMIG-Report.ps1`** after each wave to capture evidence.

> **Rollback (any step):** disable rather than delete. Before cutover, everything is additive (AD FS still
> serves the app). At cutover, **re-enable the AD FS relying party** and repoint the app back to AD FS to
> instantly revert. For CA, set the policy to **Report-only**. For provisioning, **pause** the job. For
> publishing, set the published app's users back to `ENTAPPMIG-Pilot` or disable it. Break-glass accounts
> are excluded from the CA policy so an app/CA fault never locks out admins.

---
### Order of operations
`Assess (Discovery + AD FS activity) → recreate AD FS app in Entra → App Proxy connectors + group →
publish on-prem app → SaaS app + SCIM → Conditional Access → access review → validate the 4 gates →
cut over AD FS (keep it as rollback) → expand in waves`


---


# 5. Testing & Validation — Migrate & Protect Applications with Entra

Validate on the **pilot** (`ENTAPPMIG-Pilot`) first, **while AD FS stays live**. Each test has a
**pass/fail** signal. Do not cut over or expand until all gates pass. Reference scripts are named in each
row.

## Test matrix

| # | Gate | What you do | Pass signal | Fail signal |
|---|------|-------------|-------------|-------------|
| 1 | **G1 AD FS app on Entra** | A pilot user signs into `ENTAPPMIG – App – LOBSaml – Pilot` via Entra (test SSO / My Apps) | Sign-in succeeds through **Entra** with the app functioning | Sign-in fails / app errors |
| 2 | **G1 Claims parity** | Inspect the SAML/OIDC token the app receives | Required claims (NameID + attributes) match the AD FS values | Missing/wrong claims; app rejects the user |
| 3 | **G2 Published app, no VPN** | With the **VPN disconnected**, browse the external URL of `ENTAPPMIG – AppProxy – Intranet – Pilot` | Entra pre-auth, then the app loads over App Proxy | App unreachable / still needs VPN |
| 4 | **G2 Pre-auth enforced** | Try the external URL unauthenticated | Redirected to Entra sign-in before the app is reached | App served without authentication |
| 5 | **G3 SCIM provision** | **Provision on demand** a pilot user for `ENTAPPMIG – App – ScimSaaS – Pilot` | User is **created/updated** in the SaaS app | Provision fails / no change in the app |
| 6 | **G3 SCIM deprovision** | Remove a pilot user from scope and re-provision | User is **disabled/deprovisioned** in the app | User remains active in the app |
| 7 | **G4 Conditional Access** | Access a migrated app under `ENTAPPMIG – CA – MigratedApps – Pilot` | **MFA / compliant device** enforced as configured | Access granted without the required control |
| 8 | **G4 Least privilege** | Sign in as a user **not** in `ENTAPPMIG-Pilot` | Access denied (not assigned) | Non-assigned user reaches the app |

## Automated checks
- **`ENTAPPMIG-Discovery.ps1`** — inventories AD FS relying parties (from an AD FS server where reachable),
  the AD FS application activity report, Entra enterprise apps, and App Proxy connector groups, so you can
  confirm the named objects exist and track migration progress.
- **`ENTAPPMIG-Validate.ps1`** — checks each **named** object from §3 is present and correctly wired (the
  migrated app has SSO config + `ENTAPPMIG-Pilot` assigned; the App Proxy app has pre-auth = Entra and a
  connector group; the SCIM app has provisioning enabled + scoped; the CA policy targets the apps and
  excludes break-glass) and **flags gaps** — the automated form of the gate table.
- **`ENTAPPMIG-Provisioning.ps1`** — reports SCIM **provisioning status** and recent sync results, and can
  **preview** an on-demand provision (gated `-WhatIf` / `-Commit`).
- **`ENTAPPMIG-Report.ps1`** — exports **sign-in evidence** for the migrated apps (Graph sign-in logs, and
  optional **KQL** against Log Analytics): who signed in, via which app, and the CA result — the cutover
  and audit artifact.
- **`ENTAPPMIG-Cutover.ps1`** — pre-cutover readiness summary (app config, assignments, CA coverage) with a
  **preview-only** default so you never flip a live app by accident.

## Reference KQL (sign-in logs for migrated apps)
Run in **Log Analytics** (or via `ENTAPPMIG-Report.ps1`). Field names may differ by tenant — verify schema.

```kql
// Sign-ins to the migrated apps, last 24h, with CA result
SigninLogs
| where TimeGenerated > ago(24h)
| where AppDisplayName startswith "ENTAPPMIG"
| summarize Signins = count() by AppDisplayName, UserPrincipalName, ResultType, ConditionalAccessStatus
| order by Signins desc
```

## Evidence to capture (for cutover / audit)
- Screenshot: pilot user signed into the migrated AD FS app **via Entra** (My Apps), with the token claims.
- Screenshot: the published app loading **with VPN off** after Entra pre-auth.
- Provisioning **on-demand** result showing a user created/updated (and later deprovisioned).
- CA **Insights / report-only** results before enforcement, and enforcement confirmed after.
- `ENTAPPMIG-Report.ps1` export of sign-ins per app with CA status.

## Exit criteria (before Cutover / Expand)
- [ ] G1 — the migrated app authenticates **via Entra** with correct claims (AD FS still live)
- [ ] G2 — the published app loads **without VPN** and enforces Entra pre-auth
- [ ] G3 — SCIM **provisions and deprovisions** a pilot user
- [ ] G4 — Conditional Access enforces MFA/compliant device on the migrated apps
- [ ] `ENTAPPMIG-Validate.ps1` shows no gaps for the pilot objects
- [ ] `ENTAPPMIG-Report.ps1` produces clean sign-in evidence per app


---


# 6. Troubleshooting — Migrate & Protect Applications with Entra

Symptom → likely root cause → fix. Start with **`ENTAPPMIG-Discovery.ps1`** (are the named objects present
and is the AD FS side inventoried?) and **`ENTAPPMIG-Validate.ps1`** (which gate is failing?) — most
migration issues are a SAML mismatch, a missing claim, a connector/DNS problem, or a CA scope error.

## The migrated app rejects the sign-in ("invalid SAML response" / audience mismatch)
- **Root cause:** the Entra app's **Identifier (Entity ID)** or **Reply URL (ACS)** doesn't exactly match
  what the AD FS relying party used (and what the app expects).
- **Fix:** copy the **exact** identifier and ACS URL(s) from the AD FS relying party (Requirement 2.3) into
  `ENTAPPMIG – App – LOBSaml – Pilot` → **Single sign-on**. A trailing slash or http/https difference is
  enough to break it. `ENTAPPMIG-Validate.ps1` shows the app's configured identifier/reply URLs.

## Sign-in works but the app says "access denied" / wrong user
- **Root cause:** a **claim** the app relies on (NameID format, an attribute like `employeeid` or a role) is
  missing or in the wrong format — the AD FS **claim rule** wasn't reproduced.
- **Fix:** in the app's **Attributes & Claims**, reproduce each AD FS claim, including the **NameID format**.
  Inspect the actual token (testing gate G2) and compare to the AD FS claims. Flag complex transforms for
  extra work.

## The App Proxy published app shows a 500 / "app proxy" error page
- **Root cause:** the connector can't reach the **internal URL**, the internal URL is wrong, or no connector
  in `ENTAPPMIG – ConnectorGroup – OnPrem` is **Active**.
- **Fix:** confirm the connector is **Active** and can resolve/reach the internal URL from the connector
  host (`Test-NetConnection`); correct the **Internal URL** on `ENTAPPMIG – AppProxy – Intranet – Pilot`;
  ensure two connectors for HA.

## The published app loads but single sign-on fails (repeated prompts)
- **Root cause:** the App Proxy **SSO mode** is wrong or misconfigured — e.g. **KCD/IWA** without the SPN
  or delegation set up, or header-based SSO without the right headers.
- **Fix:** set the correct **Single sign-on** mode for the app; for **IWA (KCD)** configure the SPN and
  Kerberos-constrained delegation on the connector service account; for **header-based** map the required
  headers. Verify with a pilot user.

## SCIM provisioning "Test connection" fails or users aren't created
- **Root cause:** wrong **SCIM base URL** or **secret token**, insufficient token permissions, an attribute
  **mapping** mismatch, or the user is **out of scope** (job set to assigned-only and the user isn't assigned).
- **Fix:** re-enter the SCIM URL + token (Requirement 2.6) and re-run **Test connection**; check the
  **Mappings** for a required attribute the app rejects; confirm the user is in `ENTAPPMIG-Pilot` and the
  scope is **assigned users/groups**. Use **provision on demand** and read the step-by-step result;
  `ENTAPPMIG-Provisioning.ps1` reports the job status and recent sync outcomes.

## Removing a user didn't deprovision them in the SaaS app
- **Root cause:** the provisioning job doesn't have **deprovisioning** enabled, or the app only supports
  disable (not delete), or the user was removed from Entra faster than the sync cycle.
- **Fix:** confirm the job's target attribute mappings include the **active/disable** flag; allow a sync
  cycle or **provision on demand**; some apps **disable** rather than delete — verify the expected behavior
  with the vendor.

## After cutover, real users can't sign in (but the pilot worked)
- **Root cause:** the app's federation was repointed to Entra but a **production** setting differs (a
  different ACS URL for prod, a claim only prod users need), or the AD FS relying party is still intercepting.
- **Fix:** **re-enable the AD FS relying party** and repoint the app back to AD FS (instant rollback), then
  reconcile the prod-vs-pilot difference (extra ACS URL / claim) in the Entra app before retrying cutover.
  This is why AD FS is **disabled, not deleted**, at cutover.

## A Conditional Access policy locked users (or an admin) out of the migrated apps
- **Root cause:** the CA grant is too strict, the app target is wrong, or **break-glass** wasn't excluded.
- **Fix:** set `ENTAPPMIG – CA – MigratedApps – Pilot` back to **Report-only**, confirm **break-glass**
  accounts (global requirement G4) are **excluded**, and sign in as break-glass to recover. Re-enable after
  correcting the grant/target. `ENTAPPMIG-Validate.ps1` flags a CA policy missing the break-glass exclusion.

## The AD FS application activity report is empty / an app isn't listed
- **Root cause:** AD FS **auditing** isn't enabled or the connector/usage data hasn't populated, so Entra
  can't show relying-party activity.
- **Fix:** enable AD FS auditing and allow the report to populate; in the meantime inventory relying parties
  directly on the AD FS server with `Get-AdfsRelyingPartyTrust` (which `ENTAPPMIG-Discovery.ps1` runs when
  pointed at an AD FS server).

---
### First moves for any migration issue
1. `ENTAPPMIG-Discovery.ps1` — are the AD FS relying parties inventoried and the Entra objects present?
2. `ENTAPPMIG-Validate.ps1` — which gate is failing (SSO config, pre-auth, provisioning, CA scope)?
3. `ENTAPPMIG-Provisioning.ps1` — for any SCIM issue, what does the job status / last sync say?
4. Inspect the **actual token** for claim issues; check the **connector** for publishing issues.
5. Only then change configuration — preview any cutover with `ENTAPPMIG-Cutover.ps1` (`-WhatIf`), and keep
   **AD FS disabled-not-deleted** as your rollback.


---


# 7. Best Practices — Migrate & Protect Applications with Entra

## Migration planning
- **Prioritize by real usage.** Drive the plan from the **AD FS application activity** report, not a stale
  spreadsheet — migrate the apps people actually use first, and retire dormant relying parties outright.
- **One app of each type first.** Prove the pattern on one AD FS app, one App Proxy app, and one SCIM app
  against `ENTAPPMIG-Pilot` before you scale. Waves after that are repeats of a proven recipe.
- **Reproduce claims deliberately.** Map each AD FS **claim rule** to Entra **claims mapping** and compare
  the actual token — silent claim drift is the top cause of "it authenticated but the app rejected me."

## AD FS cutover safety
- **Keep AD FS live until validated.** Never delete a relying party at cutover — **disable** it so it is an
  instant rollback, and only remove it after a clean soak period.
- **Cut over in a change window** with the app owner on hand, and preview first with
  `ENTAPPMIG-Cutover.ps1` (report-only). Repointing federation is a real change to live sign-in.
- **Have the rollback written down** per app: the exact endpoint/metadata to revert to AD FS. A rollback you
  have to improvise at 2 a.m. is not a rollback.

## Publishing on-prem apps
- **Pre-authenticate in Entra.** Always set App Proxy **pre-authentication = Microsoft Entra ID** so
  Conditional Access applies **before** the app is reached — passthrough publishing throws that away.
- **Two connectors per group.** Run App Proxy connectors in pairs in a **connector group** for HA, with
  clean internal DNS/route to the app.
- **Pick the right publishing path.** **Application Proxy** is for **web** apps with browser SSO; for
  **non-web/TCP** apps or full network ZTNA, publish via **GSA Private Access** (the *Entra Global Secure
  Access* solution) instead. Don't force a TCP app through a web proxy.

## Provisioning (SCIM)
- **Prove it on demand first.** Use **provision on demand** for one pilot user to confirm create/update
  before enabling the full job — then scope the job to **assigned users/groups only**.
- **Deprovisioning is the point.** Confirm that removing a user from scope **disables/deprovisions** them in
  the app — an SCIM job that only creates accounts leaves the classic leaver gap open.
- **Keep the token in the app, not in code.** The SCIM secret lives only in the provisioning config — never
  in scripts, source, or docs.

## Protection & governance
- **Conditional Access on every migrated app.** As you migrate an app, add it to
  `ENTAPPMIG – CA – MigratedApps – *` — an app off AD FS but with no CA is only half-protected.
- **Report-only, then enforce.** Ship CA policies as report-only, read the Insights, then turn them on.
  Always **exclude break-glass**.
- **Recertify with access reviews.** Fold every migrated app into
  `ENTAPPMIG – Review – MigratedApps – Quarterly` so assignments are re-justified over time.

## Change safety & hygiene
- **Pilot-first, always** — prove the four gates on `ENTAPPMIG-Pilot` before cutover or expansion.
- **Least privilege for operators** — run day-to-day work as **Application Administrator**; reserve Global
  Administrator for the one-time federation/cutover changes.
- **No secrets in automation.** Scripts authenticate interactively via `Connect-MgGraph` with least read
  scopes; write actions are gated behind an explicit `-Commit` with a `-WhatIf` preview — never embed tokens.

## Where to go next (adjacent catalog areas)
- **Cloud Identity as Enterprise IdP — SAML App Integration Factory** — the complementary solution for
  **SSO onboarding at scale** (integrating many SaaS SAML/OIDC apps). Use it once AD FS is retired and you
  are onboarding new apps as a factory; use **this** solution to get **off AD FS** and **publish on-prem**.
- **Entra Global Secure Access** — publish **non-web/TCP** apps and deliver network ZTNA via **Private
  Access**, the alternative to Application Proxy for those cases.
- **Zero Trust — Conditional Access Baseline** — the full CA policy set the migrated apps plug into.
- **Entra ID Governance — Access Reviews & Entitlement Management** — govern app entitlement at scale.


---


# 8. Deliverables Summary — Migrate & Protect Applications with Entra

## What you receive
A complete, self-guided package to **migrate application authentication to Microsoft Entra** and protect
every app it moves — retiring **AD FS** relying parties onto **Entra SSO**, publishing on-prem web apps
without a VPN via **Application Proxy** (or GSA Private Access), automating account lifecycle with **SCIM**,
and wrapping every migrated app in **Conditional Access** and **access reviews** — with a discovery-driven
migration plan and a reversible cutover per app.

### Documentation
- **Executive Summary** — the problem (stranded AD FS / on-prem / bespoke-SSO apps), the four migration
  tracks, the outcome, the boundary (distinct from the SAML App Integration Factory), and the licensing gate.
- **Solution Overview** — how AD FS→Entra SSO, App Proxy publishing, and SCIM provisioning fit together, the
  building blocks (enterprise app → SSO/assignments/provisioning; connector group → published app; CA;
  access review), scope, and what's out of scope (SSO-at-scale and CA baseline are separate solutions).
- **Requirements Guide** — migration-specific prerequisites (licensing incl. App Proxy/Governance/Private
  Access, the app-admin role, AD FS relying-party inventory, on-prem app URLs, a connector host, SCIM
  endpoint/token, pilot group + app owners, cutover/rollback control, the Graph toolchain), each with
  Verify / Implement, on top of the category global requirements.
- **Implementation Guide** — ordered steps: assess + plan → recreate AD FS app in Entra → App Proxy
  connectors → publish on-prem app → SaaS + SCIM → Conditional Access → access review → validate → cut over
  AD FS (kept as rollback) → expand, with **every object named** using the
  `ENTAPPMIG – <Purpose> – <Scope> – <Stage>` convention.
- **Testing & Validation** — the gates (AD FS app on Entra with claims parity, published app without VPN,
  SCIM provision/deprovision, Conditional Access) as a pass/fail matrix, automated checks, and reference
  **KQL** for sign-in evidence.
- **Troubleshooting** — symptom → root-cause → fix for the common failures (SAML mismatch, missing claims,
  App Proxy 500s, KCD/SSO failures, SCIM errors, cutover sign-in breakage, CA lockout).
- **Best Practices** — usage-driven planning, safe AD FS cutover, pre-auth publishing, SCIM deprovisioning,
  CA + reviews, change safety, and where to go next.

### PowerShell tools (Microsoft Graph) — safe by default
| Script | Purpose | Default mode |
|--------|---------|--------------|
| **`ENTAPPMIG-Discovery.ps1`** | Inventory AD FS relying parties (AD FS server), AD FS application activity, Entra enterprise apps, and App Proxy connector groups (baseline + migration progress) | Read-only |
| **`ENTAPPMIG-Validate.ps1`** | Check each named §3 object exists and is wired (SSO config + pilot assigned; App Proxy pre-auth = Entra; SCIM enabled/scoped; CA targets apps, excludes break-glass); flag gaps | Read-only |
| **`ENTAPPMIG-Provisioning.ps1`** | Report SCIM provisioning status + recent sync results; preview an on-demand provision | Read / `-WhatIf` |
| **`ENTAPPMIG-Report.ps1`** | Export sign-in evidence for the migrated apps (Graph sign-in logs + optional KQL): who, which app, CA result | Read-only |
| **`ENTAPPMIG-Cutover.ps1`** | Pre-cutover readiness summary (config, assignments, CA coverage); preview-only by default | Read / `-WhatIf` |

All scripts use `Connect-MgGraph` with **least scopes**, contain **no credentials or secrets**, and any
change/remediation defaults to a **`-WhatIf` preview** gated behind an explicit `-Commit`.

## Outcomes
- **AD FS retired** — relying parties migrated to Entra SSO, app-by-app, with a reversible cutover.
- **On-prem apps reachable without a VPN** — published through Entra with pre-authentication.
- **Provisioning automated** — SCIM creates, updates, and **deprovisions** accounts.
- **Every migrated app protected** — Conditional Access enforced and access recertified on a schedule.
- A **pilot-first**, gated, reversible rollout with a documented rollback for every cutover.

## Assumptions & boundaries
- **Licensing** covers in-scope users — **P1** (App Proxy + CA), **Governance/P2** (access reviews),
  **Private Access** add-on if publishing via GSA — *verify current SKU coverage and preview status*.
- The **app inventory** (AD FS relying parties, on-prem URLs, SCIM endpoints) is provided by the customer.
- **SSO onboarding at scale** (the SAML App Integration Factory) and **CA baseline design** are **separate
  adjacent solutions**; this is the AD FS-migration + on-prem-publishing track.
- **Which apps migrate in which wave**, cutover windows, and app-owner sign-off are the customer's
  change-management decisions.

> Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the full documentation set plus
> all five PowerShell tools in a single ZIP, yours to keep and reuse on every migration wave.
