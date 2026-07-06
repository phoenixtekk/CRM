# Entra ID ↔ Google Cloud Identity — SSO Federation & Provisioning (GCDS / SCIM)

> **Version 1.0.0** · Category: Google · Solution code: GWSSO

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Entra ID ↔ Google Cloud Identity: SSO Federation & Provisioning

White-label · Google Category

In a Google transformation, **identity is the backbone.** Before mail, files, or apps can move or
coexist, users have to sign in **once** and exist **consistently** across both clouds — the same
person, the same account, the same groups — with **Microsoft Entra ID** as the enterprise identity
provider and **Google Workspace / Cloud Identity** as the relying party. Left unmanaged, identity
splits: two logins, accounts present in one directory but not the other, groups that drift, and
licensing that no longer matches who is active. Everything downstream inherits that confusion.

This package stands up the identity foundation deliberately and in the right order: **federate Entra
ID to Google for single sign-on** (SAML 2.0, via the "Google Cloud / G Suite Connector by Microsoft"
gallery app), then **provision users and groups into Google** from a single source of truth — **SCIM
push** when Entra masters identity, or **Google Cloud Directory Sync (GCDS)** when on-prem Active
Directory does. Accounts, group membership, and licensing stay consistent across Microsoft and Google,
and the lifecycle **closes** — leavers are de-provisioned, not orphaned. It is deployed **pilot-first**
and **rollback-ready**.

## What you get
- A plain-language Solution Overview of the identity model — Entra as IdP federating to Google, the
  three provisioning options (SCIM push, GCDS pull, JIT-convenience), and the cardinal rule of **one
  source of truth per object**.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — both control planes,
  the source-of-truth decision, the custom domain verified in **both** clouds, the SCIM admin account
  or GCDS host, a named pilot, and break-glass on both sides.
- An Implementation Guide with the exact click-by-click steps to configure **Entra→Google SAML SSO**
  (both consoles, NameID = user.mail, domain-specific issuer), **provisioning** of users and groups
  (SCIM Path A or GCDS Path B, including de-provisioning), and to **pilot** sign-in and provisioning on
  a named OU/group before expanding.
- Five PowerShell scripts for identity-readiness discovery, per-user SSO + provisioning validation, an
  identity coverage/exception report, safe remediation, and a pilot-scope builder.
- A Testing Guide of conformance gates (sign-in works, users/groups provisioned, one source of truth,
  de-provisioning removes access, break-glass intact) and a Troubleshooting Guide for a confident,
  staged rollout.

## What this delivers
A stable identity foundation: users authenticate once against Entra ID and reach Google without a
second password; users, groups, and licensing stay consistent because one directory is authoritative
and provisions the other; and access is removed when a person leaves. SSO is correctly scoped to
authentication only, provisioning to a single source of truth, and the whole thing is proven on a
pilot before it touches production — with the Google-side console steps authored from Google's own docs
and GCDS internals deferred to Google where appropriate.

## The standard deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
One identity across Microsoft and Google — single sign-on and consistent provisioning — underpinning
coexistence, migration, and secure access through the transformation and beyond, proven on a named
pilot and reversible at every step.


---


# 1. Solution Overview — Entra ID ↔ Google Cloud Identity: SSO Federation & Provisioning

## Why identity is the foundation of a Google transformation
When an organization adopts Google Workspace / Cloud Identity while Microsoft Entra ID remains the
enterprise identity provider, the first thing that has to work is **identity**. Users must sign in
**once** and exist **consistently** across both clouds — the same person, the same account, the same
groups — or every downstream workload (mail, Drive, Meet, third-party apps) inherits the confusion.
The failure mode is a **split identity**: two logins, accounts that exist in one directory but not the
other, groups that drift, and licensing that no longer matches who is actually active.

This solution stands up the identity foundation deliberately and in the right order:
**federate Entra ID to Google for single sign-on**, then **provision users and groups into Google**
from a single source of truth — so accounts, group membership, and licensing stay consistent across
Microsoft and Google. It is the base layer that coexistence and migration are built on, deployed
**pilot-first** and **rollback-ready**.

> **Vendor boundary.** The **Microsoft / Entra** side (the "Google Cloud / G Suite Connector by
> Microsoft" gallery application) and the **Google Admin console / Cloud Identity** side are authored
> at exact click-by-click detail from the vendors' current public documentation. **Google Cloud
> Directory Sync (GCDS)** is Google's supported tool for AD/LDAP-sourced provisioning; its internal
> configuration is deferred to Google's own docs where noted. Any capability that is preview or
> rolling out is flagged "verify in your tenant" — never invented.

## The identity model
Two decisions define the whole design. Make them explicitly, up front.

**1. Who authenticates the user (SSO / federation).**
Entra ID acts as the **identity provider (IdP)**; Google Workspace / Cloud Identity is the
**relying party (SP)**. Sign-in is federated over **SAML 2.0** using the Entra gallery app
**"Google Cloud / G Suite Connector by Microsoft."** The user authenticates against Entra ID once;
Google trusts the SAML assertion. This is **authentication only** — it does not create the Google
account and it does not decide Google authorization (OU/group/admin role); those are Google-side.

**2. Where the account comes from (provisioning) — one source of truth.**
An account has to **exist** in Google before (or as) SSO federates a user into it. Choose exactly one
authoritative source per object and one mechanism to move it into Google:

- **SCIM push (Entra → Google)** — Entra ID is the source of truth. The same gallery app's
  **Provisioning** capability creates, updates, and de-provisions Google users and groups over SCIM.
  Choose this when **Entra ID / Microsoft 365** masters identity.
- **GCDS pull (AD/LDAP → Google)** — **Google Cloud Directory Sync** runs on a host with LDAP access
  to on-prem Active Directory and syncs users/groups into Google on a schedule. Choose this when
  **on-prem Active Directory** remains authoritative.
- **JIT (just-in-time)** — SAML JIT can create a Google user on first SSO. Treat JIT as a
  **convenience, not the source of truth** — for lifecycle, and especially **de-provisioning of
  leavers**, use SCIM push or GCDS so removals actually flow through.

The cardinal rule: **one source of truth per object.** Never let SCIM push (Entra) and GCDS pull
(AD) master the same users — they fight and the directories drift.

## How the pieces fit together
```
                 authentication (SAML 2.0)
   Entra ID  ───────────────────────────────────►  Google Workspace /
  (IdP, SSO)        gallery app: "Google Cloud /       Cloud Identity
      │             G Suite Connector by Microsoft"       (relying party)
      │
      │  provisioning — choose ONE source of truth per object
      │
      ├─ SCIM push  (Entra is source of truth) ──────►  users + groups in Google
      │
   AD/LDAP ── GCDS pull (AD is source of truth) ─────►  users + groups in Google
```
SSO federates the **sign-in**; provisioning keeps the **accounts and groups** consistent. Both are
required — SSO with no provisioning strands users at a login page with no account; provisioning with
no SSO leaves two separate passwords.

## What you can control
- **Federation** — Entra ID as IdP, Google as relying party, over SAML 2.0, with a NameID that matches
  the verified Google domain.
- **Provisioning** — one source of truth (Entra via SCIM, or AD via GCDS), moving users and groups
  into Google, with de-provisioning that removes leavers.
- **Consistency** — the same people, groups, and licensing state across Microsoft and Google.
- **Coverage** — per-user visibility into who is federated, who is provisioned, and where the
  exceptions are.

## Benefits
- **Sign in once** — users authenticate against Entra ID and reach Google without a second password.
- **Consistent accounts and groups** — one source of truth provisions Google; membership and licensing
  stay aligned instead of drifting.
- **Lifecycle that closes** — de-provisioning through SCIM/GCDS removes access when a person leaves,
  instead of orphaning accounts.
- **A foundation to build on** — coexistence and migration inherit stable identity instead of fixing
  it under pressure later.
- **Pilot-first and reversible** — federation and provisioning are proven on a named pilot OU/group
  before org-wide enforcement, with a documented rollback.

## Limitations (be honest with buyers)
- SSO is **authentication only.** It does not create Google accounts (provisioning does) and does not
  grant Google admin — Google decides authorization by OU/group/admin role.
- **One source of truth is mandatory.** SCIM push and GCDS pull must not master the same objects.
  JIT is not a lifecycle mechanism — leavers must be de-provisioned by SCIM or GCDS.
- The NameID / unique identifier in the SAML assertion **must match the verified Google domain and the
  Google account's email**, or users cannot sign in.
- The scripts inventory and validate the **Microsoft / Entra side** through Microsoft Graph
  (read-only). **Google-side** state — the SSO profile, provisioned users/groups, GCDS runs — is
  confirmed in the Google Admin console and GCDS.
- Some Entra provisioning, conditional-access, and PIM-for-groups capabilities require **Entra ID
  P1/P2** licensing (see Requirements).

## The standard deployment model
> Assess the identity estate and pick the source of truth → configure Entra→Google SSO federation and
> provisioning → pilot both on a named OU/group → validate sign-in and provisioning end-to-end →
> expand across the organization, tracking exceptions. Repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates and a documented
> rollback for every production change.


---


# 2. Requirements Guide — Entra ID ↔ Google Cloud Identity SSO & Provisioning

Verify every requirement before configuring federation or provisioning. Each entry is
**Description / Why required / How to verify / How to implement if missing.** Category-wide
prerequisites (Google tenant, source M365/Entra environment, DNS control, source of truth, pilot
scope, governance stakeholders) are in `global-requirements-google.md` — this guide adds what the
Entra↔Google SSO + provisioning work needs on top of those.

## 2.1 Both control planes accessible (Entra + Google)
- **Description:** Administrative access to **Microsoft Entra ID** at **entra.microsoft.com** (to add
  and configure the "Google Cloud / G Suite Connector by Microsoft" gallery app) and to the **Google
  Admin console** at **admin.google.com** as a **super-admin** (to accept the SAML SSO profile and to
  authorize SCIM provisioning).
- **Why required:** Federation and provisioning are configured on **both** ends — Entra publishes the
  SAML IdP details and runs the provisioning service; Google accepts the SSO profile and authorizes the
  provisioning connection.
- **How to verify:** Sign in to **entra.microsoft.com** with an app-management role, and to
  **admin.google.com** as a super-admin.
- **How to implement if missing:** Obtain the roles from the respective tenant owners before starting.

## 2.2 Administrative roles (least privilege)
- **Description:** On **Entra**, one of `Application Administrator`, `Cloud Application Administrator`,
  or the app's `Application Owner` to configure SSO and provisioning; reserve `Global Administrator`
  for one-time tenant settings only. On **Google**, a **super-admin** to configure the SSO profile,
  plus a dedicated Google admin account (see 2.5) for the SCIM connection.
- **Why required:** Configuring federation and provisioning are privileged actions on each plane;
  least-privilege roles limit blast radius.
- **How to verify:** Entra → **Roles and administrators**; Google → **Account → Admin roles**.
- **How to implement if missing:** Assign the least-privilege role on each plane before configuring.

## 2.3 Source of truth + provisioning mechanism decided
- **Description:** A documented decision on **which directory masters users and groups** and **which
  mechanism** moves them into Google: **SCIM push** (Entra ID is source of truth), **GCDS pull**
  (on-prem Active Directory is source of truth), or **JIT** on first SSO (convenience only, not
  lifecycle). One authoritative source per object — never two.
- **Why required:** Two sources of truth is the anti-pattern that makes directories drift and conflict;
  the mechanism you pick determines the entire provisioning configuration and the de-provisioning path.
- **How to verify:** A one-line statement exists: "Google users/groups are mastered by ___ and
  provisioned via ___." (Enterprise-source-of-truth detail is in global requirement 4.)
- **How to implement if missing:** Decide the source of truth and the SCIM / GCDS / JIT mechanism per
  object type before enabling any provisioning.

## 2.4 Custom domain verified in BOTH Entra and Google
- **Description:** Every user to be provisioned/federated must have a **UPN on a verified custom
  domain** (e.g. `user@contoso.com`, **not** `user@contoso.onmicrosoft.com`), and that domain must be
  **verified in Google** as well (Google Admin console → **Account → Domains → Manage domains**).
- **Why required:** Google **rejects** `*.onmicrosoft.com` usernames for provisioning, and SSO fails if
  the SAML NameID does not match a verified Google domain. The user's identifier must match on both
  sides.
- **How to verify:** In Entra, users' UPNs are on the custom domain; in Google, the domain shows as
  verified under **Manage domains**.
- **How to implement if missing:** Add and verify the custom domain in Entra, change affected UPNs to
  it, then add and verify the same domain in Google (**Add a domain → ADD DOMAIN & START
  VERIFICATION**).

## 2.5 Google admin account with Admin API privileges (for SCIM)
- **Description:** If provisioning via **SCIM push**, a Google admin account whose admin role has **all
  Admin API privileges** enabled — this is the account Entra authorizes for the provisioning
  connection. Also enable **Security → Access and data control → API Controls → "Trust internal,
  domain-owned apps."**
- **Why required:** Entra's provisioning service authorizes against this account to create/update/remove
  Google users and groups over the Directory API; without the Admin API privileges the connection test
  fails.
- **How to verify:** Google Admin console → **Account → Admin roles** → the role's **Privileges** show
  Admin API privileges enabled; API Controls has the trust setting saved.
- **How to implement if missing:** Edit the role's privileges to enable Admin API privileges; save the
  API Controls trust setting. (Not required for GCDS-only or JIT-only designs.)

## 2.6 GCDS host (if provisioning from Active Directory)
- **Description:** If provisioning via **GCDS pull**, a **Windows or Linux host with LDAP access to
  Active Directory** to run **Google Cloud Directory Sync** — best on a **separate machine**, not the
  domain controller — plus a Google admin identity GCDS authenticates with.
- **Why required:** GCDS reads AD/LDAP and writes users/groups into Google on a schedule; it needs
  network line-of-sight to AD and a place to run its scheduled sync.
- **How to verify:** The host can reach AD over LDAP(S) and outbound to Google; GCDS is installed (or a
  target host is nominated).
- **How to implement if missing:** Nominate/provision the host, grant it LDAP access to AD, install
  GCDS, and prepare a Google admin for it. (Not required for SCIM-only or JIT-only designs.)

## 2.7 DNS control for the federated domains
- **Description:** Ability to create/modify **DNS records** (TXT/CNAME for domain verification) for the
  domains being federated and provisioned. (Category-wide DNS control is global requirement 3.)
- **Why required:** Verifying the custom domain in Google (2.4) requires a DNS change; identity changes
  are staged under change control.
- **How to verify:** Confirm access to the authoritative DNS zone for each domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage under change control.

## 2.8 Microsoft Graph PowerShell SDK
- **Description:** The Microsoft Graph PowerShell SDK on the operator workstation, with consent to the
  read scopes the scripts use.
- **Why required:** Discovery, validation, and reporting read the Entra-side identity/SSO/provisioning
  state — the gallery app's service principal, its SSO mode, its SCIM synchronization job, assignments,
  and users — through Microsoft Graph.
- **How to verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; a
  test `Connect-MgGraph` succeeds.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`. The read-only
  scripts request least privilege (`Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`,
  `Synchronization.Read.All`, `User.Read.All`); the scope helper adds `Group.ReadWrite.All` only with
  `-Create`; remediation adds `Synchronization.ReadWrite.All` / `AppRoleAssignment.ReadWrite.All`.

## 2.9 A named pilot OU / group and change control
- **Description:** A **named pilot organizational unit or group** (a handful of representative users)
  to validate SSO and provisioning on before org-wide enforcement, and a **change-control** window for
  the production identity changes.
- **Why required:** Federation and provisioning are proven on a pilot first (Assess → Configure →
  Pilot → Validate → Expand); enforcing SSO org-wide before validating can lock users out.
- **How to verify:** A named pilot OU/group exists and a change window/approval path is available.
- **How to implement if missing:** Create the pilot OU/group; use `GWSSO-Set-ScopeTargeting.ps1` to
  build the Entra pilot-scope group, and scope the Google SSO profile to the matching Google OU/group.

## 2.10 Break-glass accounts (both clouds)
- **Description:** On **Google**, a **cloud-only super-admin excluded from the SSO profile** so an SSO
  change can never lock admins out. On **Entra**, two cloud-only `@onmicrosoft.com` emergency-access
  admins excluded from broad conditional-access policies.
- **Why required:** A federation change could interfere with sign-in on either side; break-glass paths
  restore access.
- **How to verify:** Google → a super-admin with the SSO profile set to **none**; Entra → two cloud-only
  admins excluded from broad policies.
- **How to implement if missing:** Create them, exclude them from SSO/CA policies, store credentials
  securely, and monitor their sign-ins.

---
## Checklist
- [ ] Both control planes accessible — Entra (app-mgmt role) + Google (super-admin)
- [ ] Least-privilege admin roles assigned on each plane
- [ ] Source of truth + provisioning mechanism decided (SCIM push / GCDS pull / JIT) per object
- [ ] Custom domain verified in **both** Entra and Google; no `*.onmicrosoft.com` UPNs in scope
- [ ] Google admin account with Admin API privileges + API Controls trust set (if SCIM)
- [ ] GCDS host with LDAP access to AD prepared (if GCDS)
- [ ] DNS control confirmed for the federated domains
- [ ] Microsoft Graph PowerShell SDK installed and consented
- [ ] Named pilot OU/group + change window — `GWSSO-Set-ScopeTargeting.ps1`
- [ ] Break-glass: Google super-admin excluded from SSO + two Entra cloud-only admins


---


# Global Requirements — Google Workspace & Gemini Solutions

These requirements apply to **every** solution in the **Google** category. They are the common
foundation each Google Workspace / Gemini solution assumes is already in place (or stands up as part
of its own Requirements section). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Google solution).** The **Google Admin console**
> (admin.google.com), **Google Cloud / Cloud Identity**, and the **Microsoft / Entra** sides are
> authored at exact, current click-by-click detail from the vendors' public documentation. **Gemini
> Enterprise** capabilities that are in preview or rolling out are **cited or flagged "verify in your
> tenant"** — never invented. **Third-party migration tools** (e.g. for mail/Drive/Chat data movement)
> and **third-party enterprise apps** (ServiceNow, SAP, Databricks, etc.) are integrated at the
> pattern/architectural level; their internal console steps are deferred to the vendor's own docs.

## 1. Google Workspace / Cloud Identity tenant
- **Description:** A provisioned Google Workspace (or Cloud Identity) tenant with a **super-admin**
  account for configuration, and the appropriate Workspace edition/licensing for the capability in
  scope (e.g. Enterprise Plus for Vault/CAA/DLP, Gemini/AI add-on where required).
- **Why required:** All configuration, policy, and API work is performed against this tenant.
- **How to verify:** Sign in to **admin.google.com** as a super-admin; confirm edition and license
  counts under **Billing / Subscriptions**.
- **How to implement if missing:** Provision the tenant and licenses through Google or an authorized
  reseller before starting.

## 2. Source Microsoft 365 / Entra environment (for migration & coexistence)
- **Description:** For migration/coexistence/identity solutions, administrative access to the source
  **Microsoft 365** tenant and **Microsoft Entra ID** (Global Administrator or the least-privilege
  roles the solution names).
- **Why required:** Migration, directory sync, SSO federation, and coexistence read from and change
  the Microsoft side.
- **How to verify:** Confirm access to the M365 admin center and the Entra admin center with the
  required role.
- **How to implement if missing:** Obtain the role from the M365/Entra tenant owner.

## 3. DNS control for the routed domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF, DKIM, DMARC, TXT, CNAME) for the
  domains being migrated, coexisting, or verified.
- **Why required:** Domain verification, mail routing/coexistence, and authentication all depend on
  DNS changes.
- **How to verify:** Confirm access to the authoritative DNS zone for each domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow changes are high-impact).

## 4. Identity & provisioning source of truth
- **Description:** A defined **identity source of truth** (on-prem AD, Entra ID, or an HR/IGA system)
  and the sync mechanism (e.g. **Google Cloud Directory Sync (GCDS)** or SCIM-based provisioning).
- **Why required:** Consistent users/groups across ecosystems underpin SSO, licensing, and access.
- **How to verify:** Confirm which directory is authoritative and how objects flow into Google.
- **How to implement if missing:** Define the source of truth and provisioning model before configuring
  SSO or migrating.

## 5. A pilot scope (OU / group) and change control
- **Description:** A **pilot organizational unit or group** to validate on before fleet-wide rollout,
  and a **change-control** process for production changes (especially mail flow, DNS, identity, and DLP).
- **Why required:** Every solution follows an **Assess → Configure → Pilot → Validate → Expand** model;
  the pilot proves the design and change control protects production.
- **How to verify:** Confirm a named pilot OU/group exists and a change window/approval path is available.
- **How to implement if missing:** Create a pilot OU/group and agree the change-control process with the
  owners before making production changes.

## 6. Security, compliance & governance stakeholders
- **Description:** Engagement with the **security (CISO), legal/eDiscovery, and data-governance**
  stakeholders whose policies the configuration must satisfy (DLP, retention, Vault/Purview, and any
  regulatory regime such as ITAR/DFARS/Assured Controls where applicable).
- **Why required:** Data governance, eDiscovery, DLP, and regulated-workload settings must align to
  enterprise policy and legal requirements, not just technical defaults.
- **How to verify:** Confirm the applicable policies and named stakeholders/approvers.
- **How to implement if missing:** Identify the owners and obtain the policy/compliance requirements
  before configuring governance controls.

*The deployment model across every Google solution is the same: **Assess → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.*


---


# 3. Implementation Guide — Configure Entra→Google SSO Federation & Provisioning

This guide configures the identity foundation in the right order: **assess and pick the source of
truth → configure SSO federation (Entra IdP → Google) → configure provisioning (SCIM push or GCDS
pull) → pilot both on a named OU/group → validate sign-in and provisioning → expand.** Every change is
staged, validated on the pilot, and reversible.

> **Vendor boundary.** The **Entra** side is authored from Microsoft's current public docs (the
> "Google Cloud / G Suite Connector by Microsoft" gallery app); the **Google Admin console / Cloud
> Identity** side from Google's public docs. **GCDS** internals are Google's tool; its detailed
> field-by-field configuration is deferred to Google's own documentation where noted. Menu names and
> URLs change — treat any exact label as "verify in your current console."

> **Order matters.** Provision (or verify accounts already exist) **before** enforcing SSO org-wide —
> SSO federates a sign-in into an account that must already exist. Always keep a break-glass Google
> super-admin **outside** the SSO profile (Requirement 2.10).

---

## Step 0 — Assess and decide (do this first)
1. Run `GWSSO-Discovery.ps1` to inventory the **Entra side**: whether the "Google Cloud / G Suite
   Connector by Microsoft" app exists, its SSO mode (SAML / none), whether a SCIM provisioning
   (synchronization) job is present, how many users/groups are assigned, and the tenant's verified
   custom domains.
2. Confirm the **source of truth** (Requirement 2.3): **Entra → SCIM push**, **AD → GCDS pull**, or
   **JIT** (convenience only). Write it down; the rest of the guide branches on it.
3. Confirm the **custom domain is verified in both Entra and Google** and that no in-scope user has a
   `*.onmicrosoft.com` UPN (Requirement 2.4).
4. Build the pilot scope with `GWSSO-Set-ScopeTargeting.ps1` and identify the matching Google pilot
   **OU/group**.

---

## Step 1 — Add the gallery app (Entra)
1. Sign in to **entra.microsoft.com** as at least a **Cloud Application Administrator**.
2. Browse to **Entra ID → Enterprise apps → New application**.
3. In **Add from the gallery**, search **"Google Cloud / G Suite Connector by Microsoft"**, select it,
   and add it. (If you already use this app for SSO, you can reuse it for provisioning; when first
   testing, a separate app instance is fine.)

---

## Step 2 — Configure SSO federation (Entra IdP → Google, SAML 2.0)

### 2a. Entra side — SAML SSO
1. In the app, open **Single sign-on** and select **SAML**.
2. Edit **Basic SAML Configuration**. Use one of the documented patterns (verify against your console):
   - **Identifier (Entity ID):** `google.com` (no domain-specific issuer) **or**
     `google.com/a/your-domain-com` (domain-specific issuer). This must **match** the domain-specific
     issuer choice you make on the Google side in 2b.
   - **Reply URL (ACS):** for Workspace/Gmail `https://www.google.com`; for Google Cloud Platform
     `https://www.google.com/acs` (or the `/a/your-domain-com` variants).
   - **Sign on URL:**
     `https://www.google.com/a/your-domain-com/ServiceLogin?continue=https://mail.google.com`.
3. **Attribute / NameID:** the **Unique User Identifier (NameID)** must be the user's **email address**
   that matches their Google account — map it to **user.mail** (not the default
   `user.userprincipalname`). This is the single most common cause of "cannot sign in."
4. In **SAML Signing Certificate**, download **Certificate (Base64)**.
5. In **Set up ...**, copy the **Login URL** and **Logout URL** for the Google side. (Note: Microsoft
   documents the correct sign-out URL as
   `https://login.microsoftonline.com/common/wsfederation?wa=wsignout1.0`.)

### 2b. Google side — accept the SAML SSO profile
1. Sign in to **admin.google.com** as a **super-admin**.
2. Go to **Menu → Security → Authentication → SSO with third-party IdP**.
3. On the **Third-party SSO profile for your organization** tab:
   - **Sign-in page URL** ← Entra **Login URL**.
   - **Sign-out page URL** ← Entra **Logout URL**.
   - **Verification certificate** ← upload the Base64 certificate from 2a.
   - **Use a domain-specific issuer** ← check/uncheck to match your Entra Identifier choice in 2a.
   - **Change password URL** ← `https://mysignins.microsoft.com/security-info/password/change`.
   - **Save.**
4. **Scope the SSO profile to the pilot first.** Google supports assigning the SSO profile per **user,
   OU, or group**. Assign the profile to the **pilot OU/group** and set it to **none** for everyone
   else (and for the break-glass super-admin) so only the pilot federates until you validate.

> **What SSO does and does not do.** The SAML assertion **authenticates**; it does not create the
> Google account and does not grant Google admin. The account must already exist (Step 3), and Google
> decides authorization by OU/group/admin role.

---

## Step 3 — Configure provisioning (one source of truth)

Do **one** of the following, per the decision in Step 0.

### Path A — SCIM push (Entra ID is the source of truth)
1. **Google prerequisites** (Requirement 2.5): **Security → Access and data control → API Controls →
   "Trust internal, domain-owned apps" → SAVE**; and a Google admin account whose **Admin role**
   (**Account → Admin roles**) has **all Admin API privileges** enabled.
2. In Entra, open the app → **Provisioning** tab → **Get started** → **+ New configuration**.
3. Under **Admin Credentials**, select **Authorize** → in the Google dialog, **Accept** to grant Entra
   permission to manage the Google tenant → **Test Connection** → **Create**.
4. On **Overview → Properties**, enable **notification emails**, set a **quarantine** address, and
   enable **accidental-deletion prevention**; **Apply**.
5. **Attribute Mapping → users:** review mappings; **primaryEmail** is the matching attribute (and must
   equal the SSO NameID). **Attribute Mapping → groups:** review group mappings (email, name,
   description, members) so **groups and memberships** provision too.
6. **Scope who provisions:** either **assign** users/groups to the app (Enterprise app → Users and
   groups) or set an **attribute-based scoping filter**. **Start with the pilot OU/group only.**
7. Use **on-demand provisioning** to validate a couple of pilot users, then **Start provisioning** from
   **Overview**.
   - **De-provisioning:** removing a user from scope (or disabling in Entra) **suspends** them in
     Google — it does **not** hard-delete the Google object. That is the intended leaver path.

### Path B — GCDS pull (on-prem Active Directory is the source of truth)
1. Install **Google Cloud Directory Sync** on the prepared host with LDAP access to AD (Requirement
   2.6) — best on a **separate machine**, not the domain controller.
2. In **GCDS Configuration Manager**, connect to **Active Directory** (LDAP) and to **Google (Cloud
   Identity / Workspace)** with a Google admin.
3. Under **General Settings**, select **User Accounts** (and **Groups** if syncing groups). Configure
   **User Accounts → Additional User Attributes** and the OU/attribute mapping rules that decide which
   objects flow. (Field-by-field mapping is per Google's GCDS docs.)
4. **Simulate** a sync — GCDS reports the changes it *would* make without applying them; review the
   simulation against expectations.
5. Run a real sync for the **pilot OU** only, then **schedule** GCDS for continuous provisioning.
   - **De-provisioning:** removing/disabling the AD object flows through GCDS to suspend the Google
     account on the next run.

### JIT note
SAML **just-in-time** creation makes a Google user on first SSO. It is a **convenience, not the source
of truth** — for lifecycle, and especially **de-provisioning leavers**, use Path A or Path B so
removals actually propagate. Do not rely on JIT alone.

> **Never run both Path A and Path B against the same objects.** SCIM push (Entra) and GCDS pull (AD)
> mastering the same users is two sources of truth — they conflict and drift. Pick one per object.

---

## Step 4 — Pilot: validate sign-in AND provisioning on the named OU/group
1. Confirm the **pilot users exist in Google** (provisioned via Path A/B, or created for the test).
2. A pilot user **signs in** via Entra SSO (use **Test this application** in Entra, or the Google
   sign-on URL). Expected: redirect to Entra, authenticate, land in Google — no second password.
3. **Provisioning check:** add a pilot user to a source group; confirm the user **and group membership**
   appear in Google. Remove the user; confirm they are **de-provisioned (suspended)** in Google.
4. Run `GWSSO-Validation.ps1` to confirm the Entra side: SSO mode is SAML, a provisioning job exists
   and is running, and the pilot users are assigned/in scope.
5. Confirm the **break-glass Google super-admin** (SSO profile = none) can still sign in outside SSO.

**Gate:** do not proceed to expand until sign-in works, provisioning creates and de-provisions
correctly, and break-glass is confirmed (see the Testing Guide gates).

---

## Step 5 — Expand
1. Widen the **Google SSO profile** assignment from the pilot OU/group to the next batches of OUs/groups
   (leaving break-glass at **none**).
2. Widen **provisioning scope** (SCIM assignment/filter, or GCDS OU rules) in the same batches.
3. Re-run `GWSSO-Discovery.ps1`, `GWSSO-Validation.ps1`, and `GWSSO-Report.ps1` on a cadence so
   coverage and exceptions stay visible as the rollout grows.
4. Record every deliberate exception (e.g. service accounts intentionally not federated) with an owner.

---

### Order of operations
`Assess + pick source of truth → add gallery app → configure SAML SSO (Entra + Google) → configure
provisioning (SCIM push OR GCDS pull) → pilot (sign-in + provisioning on named OU/group) → validate →
expand in batches, tracking exceptions`

### Rollback
- **SSO:** set the Google SSO profile to **none** for the affected OU/group (or turn the Entra SSO app
  off) — sign-in reverts to Google-native or the prior IdP. The break-glass super-admin is always
  outside SSO.
- **Provisioning (SCIM):** **Stop provisioning** in the Entra app — existing Google objects remain; no
  new writes. Re-scoping to fewer users is non-destructive.
- **Provisioning (GCDS):** disable the scheduled task / narrow the OU rules — existing objects remain.
- Every change is piloted on a named OU/group and reversible before org-wide enforcement.


---


# 5. Testing Guide — SSO & Provisioning Conformance Gates

Run after the pilot (Implementation Step 4) and on the recurring cadence during and after expansion.
Each test checks whether the **identity foundation** works the standard way — not just that one user
can sign in, but that federation, provisioning, and de-provisioning are all correct and that
break-glass is intact.

## Test 1 — Entra-side identity state is inventoried
**Do:** Run `GWSSO-Discovery.ps1`.
**Expected:** The "Google Cloud / G Suite Connector by Microsoft" app is listed with its SSO mode
(SAML), whether a SCIM provisioning job exists, the count of assigned users/groups, and the tenant's
verified custom domains — a usable baseline. No changes made.

## Test 2 — Custom domain matches on both sides
**Do:** Confirm the in-scope custom domain is verified in **Entra** and in **Google** (Admin console →
**Account → Domains → Manage domains**); confirm no in-scope user has a `*.onmicrosoft.com` UPN.
**Expected:** The domain is verified in both clouds; every in-scope user's UPN is on the custom domain.
A `*.onmicrosoft.com` UPN is a fail — Google rejects it for provisioning and SSO.

## Test 3 — SSO federation works (pilot sign-in)
**Do:** A **pilot-OU** user signs in via Entra SSO (Entra **Test this application**, or the Google
sign-on URL). Run `GWSSO-Validation.ps1` for the Entra-side signal.
**Expected:** The user is redirected to Entra, authenticates, and lands in Google with **no second
password**. Entra SSO mode is **SAML**; the **NameID = user.mail** and matches the Google domain.

## Test 4 — Provisioning creates users AND groups
**Do:** Add a test user to a source group in scope; run `GWSSO-Validation.ps1` (provisioning section);
confirm in the Google Admin console.
**Expected:** The user **and the group + membership** appear in Google via the chosen mechanism (SCIM
push or GCDS pull). `primaryEmail` matches the SSO NameID. Attributes populate per the mapping.

## Test 5 — One source of truth (no dual mastering)
**Do:** Run `GWSSO-Validation.ps1` and confirm the design.
**Expected:** Each object type has exactly **one** master — SCIM push (Entra) **or** GCDS pull (AD),
never both for the same users. No object is written by two mechanisms. JIT is not being used as the
lifecycle source.

## Test 6 — De-provisioning removes access (leaver path)
**Do:** Remove the test user from the source group (or disable them in Entra/AD); wait for the next
cycle/run.
**Expected:** The user is **de-provisioned (suspended)** in Google — access is removed, not orphaned.
(SCIM removal from scope suspends rather than hard-deletes; GCDS suspends on the next run.) This is the
test that proves lifecycle actually closes.

## Test 7 — Break-glass path is intact
**Do:** Sign in as the cloud-only **Google super-admin** whose SSO profile is set to **none**; confirm
the two **Entra** cloud-only emergency admins are excluded from broad CA policies.
**Expected:** The Google super-admin signs in **outside** SSO; an SSO or provisioning change cannot
lock admins out.

## Test 8 — Scope is limited during pilot
**Do:** Confirm the **Google SSO profile** is assigned only to the pilot OU/group (everyone else and
break-glass = **none**) and provisioning scope (SCIM assignment/filter or GCDS OU rules) covers only
the pilot.
**Expected:** Only the pilot federates and provisions until the gate passes — the rest of the org is
untouched.

## Test 9 — Coverage across the estate (expansion)
**Do:** Run `GWSSO-Report.ps1`.
**Expected:** A per-user/coverage view — federated vs not, provisioned vs not — with the exception list
containing only **deliberate, documented** exceptions (e.g. service accounts intentionally not
federated). No silent gaps.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–8 pass on the pilot OU/group — sign-in works (Test 3), provisioning creates users+groups (Test 4), one source of truth (Test 5), de-provisioning removes access (Test 6), break-glass intact (Test 7), scope limited to pilot (Test 8) |
| Expand pass | Tests 1–7 and 9 pass across each batch; the exception list is reviewed and every item is deliberate; discovery / validation / report run on a schedule |


---


# 6. Troubleshooting Guide — Entra↔Google SSO & Provisioning

Use `GWSSO-Discovery.ps1` for the Entra-side identity state, `GWSSO-Report.ps1` for coverage and
exceptions, `GWSSO-Validation.ps1` for per-user SSO/provisioning conformance, and
`GWSSO-Remediation.ps1` (preview first) for safe fixes. **Google-side** state — the SSO profile,
provisioned users/groups, GCDS runs — is confirmed in the Google Admin console and GCDS.

## A. Discovery / validation / report returns nothing or errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes missing | SDK not installed, or read scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept `Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, `Synchronization.Read.All`, `User.Read.All` |
| The Google gallery app is not found | The "Google Cloud / G Suite Connector by Microsoft" app is not added, or you are in the wrong tenant | Add it from the gallery (Implementation Step 1); confirm the tenant |
| Provisioning job not listed | `Synchronization.Read.All` not granted, or provisioning never configured | Re-run and consent the synchronization read scope; if truly none, configure provisioning (Path A) |

## B. SSO fails — users cannot sign in to Google
| Symptom | Cause | Remediation |
|---|---|---|
| "cannot sign in" / wrong user after enabling SSO | **NameID does not match** the Google account email / verified domain | In the Entra app, map the **Unique User Identifier (NameID)** to **user.mail** (not user.userprincipalname); ensure it equals the Google `primaryEmail` on a verified domain |
| Users on `*.onmicrosoft.com` fail | Google rejects `*.onmicrosoft.com` identities | Move affected UPNs to the verified custom domain; re-test |
| SSO loop or "invalid assertion" | Identifier/Entity ID vs domain-specific-issuer mismatch, or ACS/certificate wrong | Make the Entra **Identifier** and the Google **"Use a domain-specific issuer"** choice agree; re-copy the ACS/Reply URL and re-upload the Base64 certificate |
| Wrong sign-out behavior | Default logout URL is incorrect | Use `https://login.microsoftonline.com/common/wsfederation?wa=wsignout1.0` as the sign-out URL |
| Admin locked out of Google | SSO enforced with no break-glass path | Sign in as the cloud-only Google **super-admin** whose SSO profile is **none**; keep this path always available |

## C. Provisioning — users/groups not appearing in Google (SCIM, Path A)
| Symptom | Cause | Remediation |
|---|---|---|
| Test Connection / Authorize fails | Google admin account lacks **Admin API privileges**, or API Controls trust not set | Google **Account → Admin roles** → enable all **Admin API privileges**; **Security → Access and data control → API Controls → "Trust internal, domain-owned apps" → SAVE**; re-**Authorize** |
| Users not provisioned | Users not **assigned**/in scope, or provisioning not started | Assign the users/groups to the app (or set a scoping filter); **Start provisioning**; use **on-demand provisioning** to test a user |
| Groups exist but memberships/attributes wrong | Group or user attribute mapping incomplete | Review **Attribute Mapping → users** (matching = `primaryEmail`) and **→ groups** (email, name, members) |
| Provisioning went to quarantine | Repeated failures (often auth/permission) | Check the **provisioning logs** and quarantine email; fix the Google admin permission/credential and resume |
| A user has an existing consumer Google account on that email | Conflicting personal account | Use Google's **Transfer Tool** for unmanaged accounts before syncing that user |

## D. Provisioning — GCDS (Path B)
| Symptom | Cause | Remediation |
|---|---|---|
| Simulation shows unexpected deletes/changes | OU/attribute mapping rules too broad or misconfigured | Correct the GCDS mapping rules; re-**simulate** and review before any real sync (per Google's GCDS docs) |
| GCDS cannot read AD | No LDAP line-of-sight / wrong bind account | Run GCDS on a host with LDAP access to AD (not the DC); fix the LDAP connection settings |
| Sync not recurring | No scheduled task | Schedule GCDS for continuous provisioning after the pilot sync validates |

## E. Two sources of truth — drift and conflicts
| Symptom | Cause | Remediation |
|---|---|---|
| Objects flip-flop / conflict | Same users mastered by **both** SCIM push (Entra) and GCDS pull (AD) | Pick **one** master per object; disable the other mechanism for those objects (Requirement 2.3) |
| Leavers keep access | JIT used as the "source of truth"; no de-provisioning | Use SCIM push or GCDS for lifecycle so removals flow through; treat JIT as convenience only |

## F. De-provisioning did not remove access
| Symptom | Cause | Remediation |
|---|---|---|
| Removed user still active in Google | Expected behavior — SCIM **suspends**, does not hard-delete; or the user was removed from *scope* without disabling | Confirm the user is **suspended** in Google (access removed). Removing from sync scope disables, it does not delete the object; delete in Google only per your retention policy |
| GCDS did not suspend the leaver | AD object not removed/disabled, or next run not executed | Disable/remove the AD object; run/await the next GCDS sync |

## G. Coverage report shows gaps
- A user who is **federated but not provisioned** (or vice versa) is a gap. Decide: bring them into
  scope with `GWSSO-Remediation.ps1` (preview, confirm, apply), or record a **deliberate exception**
  (e.g. a service account intentionally not federated) with an owner and review date. The report should
  never contain silent, unexplained gaps.

## H. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Synchronization.Read.All','User.Read.All' -NoWelcome
# find the Google gallery app service principal + its SSO mode
Get-MgServicePrincipal -Filter "startswith(displayName,'Google')" | Select-Object DisplayName, AppId, PreferredSingleSignOnMode
# is there a SCIM provisioning (synchronization) job on it?
Get-MgServicePrincipalSynchronizationJob -ServicePrincipalId your-service-principal-id
# verified custom domains (must match Google; no onmicrosoft.com for in-scope users)
Get-MgDomain | Where-Object IsVerified | Select-Object Id, IsDefault
```

## I. When to escalate
If admins are locked out of Google and the break-glass super-admin path also fails, or provisioning is
mass-suspending users unexpectedly, **stop the change**: set the SSO profile to **none** for the
affected scope and **Stop provisioning** in the Entra app (existing objects remain), then engage the
Google Workspace admin owner and your change-control/incident process before re-enabling.


---


# 7. Best Practices — Entra↔Google SSO & Provisioning

- **Decide the source of truth first — one master per object.** Before touching a console, state which
  directory masters users and groups (Entra via SCIM, or AD via GCDS) and provision outward from it.
  **Never** let SCIM push and GCDS pull master the same objects — two sources of truth is the
  drift-and-conflict anti-pattern.
- **Provision before you enforce SSO.** SSO federates a sign-in into an account that must already
  exist. Provision (or verify accounts) first, then enforce federation — otherwise users authenticate
  successfully and land nowhere.
- **Match the identifier on both sides.** The SAML **NameID must be the user's email (user.mail)** and
  must equal the Google account's `primaryEmail` on a **verified custom domain**. A mismatched NameID —
  or a `*.onmicrosoft.com` UPN — is the number-one cause of "cannot sign in." Verify the domain in both
  Entra and Google.
- **Keep a break-glass Google super-admin outside SSO — always.** Set that account's SSO profile to
  **none** so a federation change can never lock admins out. Keep two cloud-only Entra emergency admins
  excluded from broad conditional-access policies too.
- **Pilot on a named OU/group, then expand in batches.** Assign the Google SSO profile and the
  provisioning scope to the pilot only; set everyone else to **none** until the gate passes. Expand OU
  by OU, not all at once.
- **Test the leaver path, not just the joiner path.** Provisioning that creates accounts but never
  removes them is worse than none. Prove that removing a user from scope (or disabling them) actually
  **de-provisions/suspends** them in Google — every cycle.
- **Treat JIT as convenience, never as lifecycle.** Just-in-time SSO creation is handy, but it does not
  de-provision leavers. Use SCIM push or GCDS for the real lifecycle.
- **Drive Google authorization from groups, not per-user admin.** Provision groups and memberships, and
  let Google OU/group membership decide access and admin roles — so entitlements follow directory
  membership and reviews, not hand-set per-user grants. (For privileged Google groups, consider Entra
  **PIM for groups** for just-in-time membership.)
- **Scope provisioning tightly and watch the quarantine channel.** Use assignment or an attribute
  scoping filter so only intended users flow; enable Entra provisioning **notification emails**,
  **accidental-deletion prevention**, and a **quarantine** address, and act on quarantine promptly.
- **Run GCDS off the domain controller and simulate before you sync.** Put GCDS on a separate host with
  LDAP access to AD; always run a **simulation** and review the proposed changes before a real sync.
- **Stage every identity change under change control.** Federation and provisioning changes are
  high-impact and can lock out or orphan users. Change-window them, keep the rollback ready (SSO profile
  → none; **Stop provisioning**), and confirm break-glass before each change.
- **Make coverage recurring, not one-time.** Re-run discovery, validation, and the coverage/exception
  report on a cadence so new users, new OUs, and any drift are caught and classified as they appear.
- **Maintain the identity reference doc.** Keep the source-of-truth statement, the domain/NameID
  mapping, the SSO-profile assignment plan, the provisioning scope, and the exception register current —
  it is the identity foundation's source of truth for coexistence and migration to build on.


---


# 8. Deliverables Summary — Entra↔Google SSO & Provisioning

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The identity model: Entra ID as IdP federating to Google (SAML SSO), provisioning via SCIM push or GCDS pull, one source of truth, and how the pieces fit |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (both control planes, source of truth, domain verified in both clouds, SCIM admin / GCDS host, pilot, break-glass) |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Configure Entra→Google SAML SSO (both consoles), provisioning of users+groups via SCIM push (Path A) or GCDS pull (Path B), pilot sign-in + provisioning on a named OU/group, then expand |
| 5. Testing Guide | SSO + provisioning conformance gates with pass/fail (sign-in, create, one source of truth, de-provisioning, break-glass) |
| 6. Troubleshooting Guide | Field issues — SSO failures, provisioning drift, de-provisioning, domain/NameID — and remediation |
| 7. Best Practices | Source-of-truth, lifecycle, and pilot-first recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWSSO-Discovery.ps1` | Identity-readiness discovery — inventories the Entra-side gallery app, its SSO mode, SCIM provisioning job, assigned users/groups, and the tenant's verified custom domains, via Microsoft Graph (read-only) |
| `GWSSO-Validation.ps1` | Per-user SSO + provisioning validation — for scoped users, checks federated SSO is configured (SAML, NameID = mail), the user is on a verified domain, and is assigned/provisioned; reports pass/exception (read-only) |
| `GWSSO-Report.ps1` | Identity coverage / exception report — federated vs not, provisioned vs not, on-domain vs `*.onmicrosoft.com`, and the exception list (read-only) |
| `GWSSO-Remediation.ps1` | Safely fixes scoped Entra-side gaps (assigns a reviewed user/group to the app so provisioning brings them into scope); `-WhatIf` by default |
| `GWSSO-Set-ScopeTargeting.ps1` | Builds and previews the pilot-scope and owner groups for a staged SSO/provisioning rollout; `-WhatIf` / preview by default |

## Identity reference doc — outline
The primary architectural deliverable. Recommended structure:
1. **Purpose & scope** — the domains, OUs, and users covered.
2. **Source-of-truth statement** — which directory masters users/groups and the mechanism (SCIM push /
   GCDS pull / JIT-convenience).
3. **SSO federation design** — Entra IdP → Google relying party, SAML details, NameID = user.mail,
   domain-specific issuer choice.
4. **Domain & identifier map** — verified custom domain(s), UPN ↔ primaryEmail ↔ NameID alignment.
5. **Provisioning design** — attribute mappings, group provisioning, scope (assignment/filter or GCDS
   OU rules), and the de-provisioning behavior.
6. **SSO-profile assignment plan** — pilot OU/group first, break-glass = none, expansion batches.
7. **Break-glass** — the Google super-admin outside SSO and the Entra emergency admins.
8. **Exception register** — deliberate deviations (e.g. service accounts not federated), with owner and
   review date.
9. **Conformance cadence** — how discovery / validation / report run and how new users/OUs are covered.

## What the buyer receives
- This implementation guide and the identity model as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess → Configure → Pilot → Validate → Expand.

## Outcome
One identity across Microsoft and Google — users sign in once against Entra ID and reach Google, with
users, groups, and licensing kept consistent by a single source of truth and a lifecycle that
de-provisions leavers. The identity foundation for coexistence and migration, proven on a named pilot
before it touches the whole organization, and reversible at every step.
