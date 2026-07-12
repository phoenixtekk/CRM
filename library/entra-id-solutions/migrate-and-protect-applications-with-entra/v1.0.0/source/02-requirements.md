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
