# Implement Entra ID Integration with ABM for Account Auto Provisioning for Microsoft Intune

> **Version 1.0.0** · Category: Entra · Solution code: ABMPROV

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Entra ID + Apple Business Manager Federation & Account Auto-Provisioning (Microsoft Intune)

Managed Apple IDs are the backbone of modern iPhone management — but hand-making them and reconciling
them with your real users is a slog, and it blocks the cleanest enrollment experiences. The fix is to
**integrate Microsoft Entra ID with Apple Business Manager**: **federate authentication** so users sign
in to Apple services with their Entra credentials, and **auto-provision Managed Apple IDs** from Entra
(SCIM) so accounts simply exist when you need them. With that foundation in place, all three iPhone
models — **Corporate-Owned, BYOD, and Shared** — enroll into **Microsoft Intune** the right way.

This is a complete, **deploy-it-today** package, written for an administrator with no prior
Apple-identity experience.

## What you get
- A plain-language **Solution Overview** of Entra ↔ ABM federation, automatic Managed Apple ID
  provisioning (SCIM plus just-in-time on first sign-in), and the domain-capture / existing-Apple-ID
  conflict considerations.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Entra and Intune steps (ABM actions named,
  exact ABM menus deferred to Apple's documentation).
- A dedicated **Enrollment Scenarios** section showing how the federated Managed Apple ID flows into
  **COD, BYOD, and Shared**, with the end-user sign-in experience per model.
- Five **PowerShell scripts** for readiness discovery, per-user/per-device validation, fleet coverage
  reporting, safe remediation, and scope-group building.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
**Federated authentication** (Entra ID as the identity provider for Apple) and **self-provisioning
Managed Apple IDs**, scoped to a pilot group first, with existing-Apple-ID conflicts resolved — then
**Corporate-Owned (account-driven ADE)**, **BYOD (account-driven User Enrollment)**, and **Shared
(no-user-affinity)** iPhones enrolling into Intune on one clean identity.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — federate and provision a scoped pilot, prove it,
then expand.

## Outcome
Entra ID federated with Apple Business Manager and Managed Apple IDs provisioning themselves — so every
iPhone, whatever its purpose, enrolls into Intune the right way on one identity, validated before you
scale.


---


# 1. Solution Overview — Entra ID + Apple Business Manager Federation & Account Auto-Provisioning

## What this solution is
This solution integrates **Microsoft Entra ID** with **Apple Business Manager (ABM)** so that two
things happen automatically: users sign in to Apple services with their **Entra credentials**
(federated authentication), and their **Managed Apple IDs** are created and kept in sync from Entra
(automatic account provisioning). With that identity foundation in place, every company iPhone then
enrolls into **Microsoft Intune** the right way for its purpose — **Corporate-Owned (COD)**, **BYOD**,
or **Shared**.

It is the identity-and-provisioning layer beneath iPhone management. It does not replace your
enrollment products; it makes them work on one clean identity.

## The two pillars

### Pillar 1 — Federated authentication (Entra ID is the identity provider for Apple)
You link Apple Business Manager to your Entra tenant and a **verified domain**. After federation,
when a user signs in to an Apple service with their work email, Apple redirects the sign-in to Entra
ID; the user authenticates with their normal Entra credentials (and MFA), and Apple trusts the
result. There is no separate Apple password to manage.

### Pillar 2 — Automatic Managed Apple ID provisioning
A **Managed Apple ID** is the organization-owned Apple account a user signs in with on managed
Apple devices and services. This solution creates them automatically by **two complementary paths**:

1. **SCIM provisioning from Entra ID to Apple Business Manager.** Entra has a gallery
   **Apple Business Manager** provisioning application. You scope it to a group, turn provisioning on,
   and Entra creates/updates the matching Managed Apple IDs in ABM on a recurring cycle — and
   de-provisions them when a user leaves the scope. This is the controlled, auditable bulk path.
2. **Just-in-time (JIT) creation on first federated sign-in.** With federation in place, a scoped
   user who has no Managed Apple ID yet can have one created the first time they sign in to an Apple
   service with their federated credentials. This catches users who provisioning has not reached yet.

Use SCIM as the primary path for predictable, scoped, reversible provisioning; treat JIT as the
backfill so no scoped user is ever blocked waiting for a cycle.

## The domain-capture / existing-Apple-ID conflict (read this before you federate)
Federating a domain tells Apple that your organization owns every Apple identity that uses an email
in that domain. If employees previously created **personal** Apple IDs using their work email
(`name@yourdomain.com`), those personal accounts now **conflict** with the Managed Apple IDs your
organization wants to own — Apple calls this domain capture / a Managed Apple ID conflict. Apple
gives those users a window to change their personal account to a different email so the company can
claim the work-email identity. If this is ignored, provisioning fails for the conflicted users and
their enrollment experience breaks. **Detecting and resolving these conflicts is a first-class step**
in the Implementation Guide and a dedicated section in Troubleshooting — never skip the conflict scan
before you widen the scope.

## How the foundation feeds the three enrollment models
Once a user has a federated Managed Apple ID, Intune can enroll their iPhone the right way:

- **Corporate-Owned (COD)** — company-owned phones enrolled zero-touch via **Automated Device
  Enrollment (ADE)** from ABM, **supervised**, account-driven so the user signs in with their Entra
  identity / Managed Apple ID during setup.
- **BYOD** — personal phones enrolled with **account-driven User Enrollment**: a modern,
  privacy-preserving model that uses the **Managed Apple ID + Entra federated sign-in** to create a
  managed, cryptographically separated work partition while leaving the user's personal data and
  personal Apple ID untouched.
- **Shared** — appliance phones enrolled with **no user affinity** plus restrictions; staff identity
  lives in a **Managed Apple ID / shared app sign-in**, not bound to one person.

The detailed per-model flows and end-user experience are in **Section 4 — Enrollment Scenarios**.

## An honest note on "Shared iPad" vs shared iPhone
Apple's true multi-user **Shared iPad** feature (where the device caches several users' Managed
Apple IDs and each gets a partition) is an **iPad-only** capability. **iPhones do not have Shared
iPad.** A "shared iPhone" in this solution means an iPhone enrolled with **no user affinity**,
locked down with restrictions, where staff sign in to the relevant **app/service with a Managed
Apple ID or a shared account** rather than personalizing the device. This solution states that
accurately and builds the shared model on no-affinity enrollment, not on a feature iPhones lack.

## What is in scope vs deferred
- **Exact navigation is given** for the **Entra side** (federation + the Apple Business Manager
  provisioning app) and the **Intune side** (APNs, ADE token, enrollment profiles, enrollment types).
- **Apple Business Manager console internals** (the exact ABM menu paths to add the federation /
  identity provider, manage Managed Apple IDs, and assign devices) change over time and are
  **deferred to Apple's official documentation** — this solution names the action and the control to
  use, and tells you what value to carry between consoles, without fabricating ABM menu paths.

## Benefits
- **One identity** — users sign in to Apple with Entra credentials; no separate Apple password.
- **Hands-off accounts** — Managed Apple IDs provision and de-provision themselves with the user's
  lifecycle (SCIM), with JIT as a safety net.
- **Right enrollment per phone** — COD, BYOD, and Shared each get the correct, modern model on the
  same federated identity.
- **Privacy for BYOD** — account-driven User Enrollment keeps personal data separate from work.
- **Auditable + reversible** — scoped to groups, piloted first, with scripts to validate and report.

## Limitations (be honest with buyers)
- Federation is **tenant-and-domain-wide for Apple sign-in** — pilot on a scoped group and resolve
  existing-Apple-ID conflicts before you widen it; this is the highest-risk change in the solution.
- **ABM console specifics are deferred to Apple** (they move); this solution covers the Entra and
  Intune sides exactly and names the ABM actions.
- Provisioning from Entra covers **Managed Apple IDs in ABM**; it is not a general Apple data sync.
- Account-driven User Enrollment and account-driven device enrollment require **supported iOS
  versions** and a correctly federated Managed Apple ID — unsupported/old devices fall back to older
  enrollment flows.

## The standard deployment model
> **Federate ABM with Entra (scoped) → turn on Managed Apple ID provisioning for a pilot group →
> resolve existing-Apple-ID conflicts → stand up COD / BYOD / Shared enrollment → validate on the
> pilot → expand.** Pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Entra ID + ABM Federation & Account Auto-Provisioning

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide identity prerequisites are in
`global-requirements-entra-id-solutions.md` (tenant, licensing, admin roles, break-glass accounts,
UPN/domain hygiene, network) — confirm those first.

> **Object names used throughout (use verbatim):**
> Entra provisioning app `Apple Business Manager – Federation – Prod`;
> provisioning job `ABM SCIM Provisioning – Corp – Prod`;
> provisioning pilot group `Managed Apple ID Provisioning – Pilot – Stage`;
> provisioning production group `Managed Apple ID Provisioning – Corp – Prod`;
> per-scenario groups `iOS COD – Devices – Pilot`, `iOS BYOD – Users – Pilot`,
> `iOS Shared – Devices – Pilot` (and `… – Prod` variants);
> ADE profiles `iOS COD – ADE – Pilot`, `iOS Shared – ADE – Pilot`;
> compliance `iOS COD – Compliance – Pilot`, `iOS BYOD – Compliance – Pilot`,
> `iOS Shared – Compliance – Pilot`.

## 2.1 Microsoft Intune (and Entra ID P1+)
**Description:** Intune (Plan 1) for iPhone enrollment and policy; Entra ID P1+ for the federation
and provisioning features (see global G2).
**Why required:** Intune delivers the ADE / User Enrollment / no-affinity enrollment and compliance;
Entra delivers federation and SCIM provisioning.
**How to verify:** M365 admin center → **Billing → Licenses**; confirm Intune and Entra ID P1/P2.
**How to implement if missing:** Assign M365 E3/E5 / Business Premium (Intune + Entra P1 included).

## 2.2 Apple Business Manager (ABM) account
**Description:** An organization **Apple Business Manager** account (not Apple School Manager) with
an administrator who can configure identity/federation and manage devices and Managed Apple IDs.
**Why required:** ABM is where federation is linked, Managed Apple IDs live, and devices are assigned
to your MDM (Intune).
**How to verify:** Sign in to `https://business.apple.com` as an ABM Administrator.
**How to implement if missing:** Enroll the organization in Apple Business Manager (Apple docs);
verify the organization and assign an ABM Administrator.

## 2.3 Verified domain(s) for federation
**Description:** The email domain(s) your Managed Apple IDs will use, **verified in Entra** and ready
to be added in ABM for federation.
**Why required:** Federation is keyed on a domain; Apple must confirm the org owns the domain, and the
Managed Apple ID local part comes from the user's verified-domain email.
**How to verify:** Entra → **Identity → Settings → Domain names** shows the domain **Verified**.
**How to implement if missing:** Add and verify the public domain in Entra (DNS TXT record), then add
it on the ABM side per Apple docs.

## 2.4 The Entra "Apple Business Manager" provisioning application
**Description:** The gallery **Apple Business Manager** enterprise application used to provision
Managed Apple IDs by SCIM, added to your tenant as `Apple Business Manager – Federation – Prod`.
**Why required:** It is the supported automatic provisioning path from Entra to ABM (scoped to
groups, recurring sync, de-provision on removal).
**How to verify:** Entra → **Identity → Applications → Enterprise applications**; confirm the app
exists; run **`ABMPROV-Discovery.ps1`**.
**How to implement if missing:** Add it from the gallery (Implementation Step 2) and name it
`Apple Business Manager – Federation – Prod`.

## 2.5 Apple MDM Push (APNs) certificate
**Description:** A valid **Apple MDM Push certificate** connecting Intune to Apple for iOS management.
**Why required:** No iPhone can be managed by Intune without an active APNs certificate; it underpins
all three enrollment models.
**How to verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; status
**Active**; run **`ABMPROV-Discovery.ps1`** (reports expiry).
**How to implement if missing:** Create/renew it (Implementation Step 6) with a **company** Apple ID
you record and reuse yearly.

## 2.6 ADE enrollment program token (for Corporate-Owned)
**Description:** An **Automated Device Enrollment** token linking an ABM **MDM server** entry to
Intune, so company-owned devices enroll zero-touch.
**Why required:** COD enrollment is driven by the ADE token; devices assigned to the Intune MDM server
in ABM flow to Intune and receive an ADE profile.
**How to verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens**; a valid,
non-expired token exists; run **`ABMPROV-Discovery.ps1`**.
**How to implement if missing:** Create it (Implementation Step 7): download Intune's public key,
create the MDM server in ABM, upload the token back to Intune.

## 2.7 Supported iOS versions for modern enrollment
**Description:** iPhones on an iOS version that supports **account-driven User Enrollment** (BYOD) and
**account-driven device enrollment** (COD).
**Why required:** The modern, Managed-Apple-ID-based flows require recent iOS; older devices fall back
to legacy enrollment.
**How to verify:** Check device iOS versions in Intune → **Devices → All devices**; confirm against
Apple's stated minimums for account-driven enrollment.
**How to implement if missing:** Update target iPhones to a supported iOS version before enrolling.

## 2.8 User/group scoping and a pilot group
**Description:** Entra security groups that scope provisioning and each enrollment model, plus a small
**pilot** group, all created with the naming convention above.
**Why required:** Federation and provisioning must be **piloted on a scoped group first** — you do not
federate/provision the whole tenant at once. Per-scenario groups keep COD, BYOD, and Shared cleanly
separated.
**How to verify:** Entra → **Groups**; confirm the provisioning + per-scenario groups exist; run
**`ABMPROV-Report.ps1`**.
**How to implement if missing:** Create them with **`ABMPROV-Set-ScopeTargeting.ps1`** (Implementation
Step 1).

## 2.9 Existing-Apple-ID conflict review readiness
**Description:** A plan and access to detect personal Apple IDs that use your verified-domain email
(domain capture conflicts) and resolve them before widening federation.
**Why required:** Conflicted users fail Managed Apple ID provisioning and cannot complete account-
driven enrollment until resolved.
**How to verify:** ABM provides the conflict / domain-capture report on the federation/identity screen
(deferred to Apple docs); plan user communications for the change window.
**How to implement if missing:** Run the conflict review in ABM (Implementation Step 4), notify
affected users to change their personal Apple ID email, then re-check before expanding.

## 2.10 Enrollment-time grouping owner for the Shared device group (Intune Provisioning Client as Owner)
**Description:** For the **Shared** (no-affinity) scenario, when `iOS Shared – Devices – Pilot` is an
**Assigned** security group (the deterministic targeting model), the **Intune Provisioning Client**
first-party service principal — **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, often shown as
**`Intune Autopilot ConfidentialClient`** — must be an **Owner** of that group.
**Why required:** Enrollment-time device grouping adds each newly enrolled shared iPhone to the
Assigned group by way of this principal *owning* the group. Without the owner the group stays **empty
at enrollment** and **none of the shared-device compliance/config profiles or apps deploy**. This is
the same first-party principal and mechanism Windows Autopilot device preparation uses. Applies only
when a **security group targets** the shared devices; a Dynamic group instead relies on its membership
rule and does not use this owner.
**How to verify:** Entra → **Groups → `iOS Shared – Devices – Pilot` → Owners** lists the service
principal — confirm by **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, not the display name (which
varies by tenant). Verify in your tenant before each pilot.
**How to implement if missing:** Entra → **Groups → `iOS Shared – Devices – Pilot` → Owners → Add
owners**, search by the AppId, and add it. (If the principal isn't present, open the Intune portal once
as Global Administrator to provision it, then add it as owner.)

---
## Checklist
- [ ] Intune + Entra ID P1+ licensing assigned (2.1)
- [ ] Apple Business Manager account with an Administrator (2.2)
- [ ] Verified domain(s) for federation (2.3)
- [ ] Entra `Apple Business Manager – Federation – Prod` provisioning app added (2.4)
- [ ] Apple MDM Push (APNs) certificate Active (2.5)
- [ ] ADE enrollment program token valid (2.6) — for Corporate-Owned
- [ ] Target iPhones on a supported iOS version (2.7)
- [ ] Provisioning + per-scenario scope groups created, incl. pilot (2.8)
- [ ] Existing-Apple-ID conflict review planned (2.9)
- [ ] Intune Provisioning Client (AppId `f1346770-5b25-470b-88bd-d5744ab7952c`) is an Owner of the Assigned `iOS Shared – Devices – Pilot` group (2.10)


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


# 3. Implementation Guide — Entra ID + ABM Federation & Account Auto-Provisioning

Follow these steps **in order**. The Entra side and the Intune side are documented click-by-click;
the Apple Business Manager side names the action and defers the exact ABM menu paths to Apple's
official documentation (they change over time).

Consoles used:
- **Microsoft Entra admin center** — `https://entra.microsoft.com`
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Apple Business Manager (ABM)** — `https://business.apple.com` (menu paths deferred to Apple docs)

> **Model:** Federate ABM with Entra, turn on Managed Apple ID provisioning **scoped to a pilot
> group**, resolve existing-Apple-ID conflicts, then stand up COD / BYOD / Shared enrollment, validate
> on the pilot, and expand. **Assess → Configure → Pilot → Validate → Expand.**

> **Artifact names (use verbatim):** provisioning app `Apple Business Manager – Federation – Prod`;
> provisioning job `ABM SCIM Provisioning – Corp – Prod`; provisioning pilot group
> `Managed Apple ID Provisioning – Pilot – Stage`; provisioning prod group
> `Managed Apple ID Provisioning – Corp – Prod`; per-scenario groups `iOS COD – Devices – Pilot`,
> `iOS BYOD – Users – Pilot`, `iOS Shared – Devices – Pilot`; ADE profiles `iOS COD – ADE – Pilot`,
> `iOS Shared – ADE – Pilot`.

> **Risk + rollback (read first):** Federating a domain changes Apple sign-in for **everyone** whose
> email is in that domain. Always **scope provisioning to the pilot group first** and resolve
> conflicts before widening. **Rollback:** set the provisioning job to **Off** and remove the pilot
> group's assignment to stop creating Managed Apple IDs; the federation link itself is removed on the
> ABM side (deferred to Apple docs) only if you must fully revert — coordinate this, as it affects
> sign-in.

---

## Phase 1 — Scope groups and the provisioning application

### Step 1 — Create the scope groups
1. Entra → **Groups → New group → Security** → `Managed Apple ID Provisioning – Pilot – Stage` (a few
   representative users). **Create**.
2. Repeat for `Managed Apple ID Provisioning – Corp – Prod` (the full population, used later at expand).
3. Create the per-scenario groups: `iOS COD – Devices – Pilot`, `iOS BYOD – Users – Pilot`, and
   `iOS Shared – Devices – Pilot`. **Create** each.

> Prefer automation? Run **`ABMPROV-Set-ScopeTargeting.ps1`** to create all of these groups in one pass
> (default `-WhatIf`; add `-Apply`).

### Step 2 — Add the Apple Business Manager provisioning application (Entra)
1. Entra → **Identity → Applications → Enterprise applications → New application**.
2. Search the gallery for **Apple Business Manager**, select it, and add it. **Name it**
   `Apple Business Manager – Federation – Prod`. **Create**.
3. Open `Apple Business Manager – Federation – Prod` → **Users and groups → Add user/group** → add
   `Managed Apple ID Provisioning – Pilot – Stage` only (pilot scope). **Assign**.

---

## Phase 2 — Federate ABM with Entra ID

### Step 3 — Link Apple Business Manager to Entra ID (federated authentication)
1. In **ABM**, open the identity / federation settings and **add Microsoft Entra ID as the identity
   provider**, then **federate your verified domain** (the exact ABM screen/menu is deferred to Apple's
   official documentation).
2. Complete the trust between ABM and Entra: when ABM prompts, **sign in / consent with an Entra
   administrator** so Apple can redirect sign-ins for that domain to Entra ID.
3. The value that links the two sides is your **verified domain** (Requirement 2.3) — confirm it is the
   domain you intend to federate before saving. After this, users in that domain authenticate to Apple
   services via Entra.

> Federation now covers the **whole domain** for Apple sign-in. Provisioning, however, is still scoped
> to the pilot group from Step 2 — keep it that way until conflicts are resolved (Step 4) and the pilot
> passes.

### Step 4 — Detect and resolve existing-Apple-ID conflicts (do this before widening)
1. In **ABM**, open the **domain capture / Managed Apple ID conflict** report for the federated domain
   (the exact ABM location is deferred to Apple docs). It lists personal Apple IDs that use an email in
   your domain.
2. For each conflicted user, Apple provides a process to have the user **change their personal Apple ID
   to a different (personal) email**, freeing the work-email identity for a Managed Apple ID. Notify
   those users with a deadline (the change window).
3. Re-open the conflict report and confirm it is **clear for the pilot users** before turning on
   provisioning. Do not expand beyond the pilot while conflicts remain for in-scope users.

---

## Phase 3 — Automatic Managed Apple ID provisioning

### Step 5 — Configure SCIM provisioning of Managed Apple IDs (Entra side, pilot-scoped)
1. Entra → **Identity → Applications → Enterprise applications → open**
   `Apple Business Manager – Federation – Prod` **→ Provisioning → Get started**.
2. Set **Provisioning Mode** to **Automatic**.
3. Under **Admin Credentials**, authorize Entra to ABM as the connector requires (for the Apple
   Business Manager gallery app this is an OAuth authorization to ABM; complete the ABM-side
   authorization prompt — deferred to Apple docs for the exact ABM screen). **Test Connection**; when
   it succeeds, treat this provisioning configuration as `ABM SCIM Provisioning – Corp – Prod`.
4. Under **Mappings**, confirm the user attribute mappings ABM expects — at minimum a stable user
   identifier and the attributes that form the **Managed Apple ID** (the verified-domain email / UPN).
5. Under **Settings**, set **Scope** to **Sync only assigned users and groups**, then **Save**. (Only
   `Managed Apple ID Provisioning – Pilot – Stage` is assigned, so only the pilot provisions.)

### Step 6 — Start provisioning to the pilot scope
1. On the **Provisioning** page, set **Provisioning Status** to **On**.
2. Provisioning runs on a recurring cycle; the first cycle creates Managed Apple IDs in ABM for the
   members of `Managed Apple ID Provisioning – Pilot – Stage`. Monitor **Provisioning logs** for
   success and address any per-user errors (often a remaining conflict from Step 4).
3. Run **`ABMPROV-Discovery.ps1`** (provisioning job status) and **`ABMPROV-Validation.ps1`**
   (per-user Managed Apple ID provisioned/federated) for the pilot users.

> **Just-in-time backfill:** with federation in place, a scoped user without a Managed Apple ID can
> have one created on **first federated sign-in** to an Apple service. Use SCIM as the primary path and
> JIT as the safety net so no pilot user is blocked waiting for a cycle.

---

## Phase 4 — Intune Apple connection (shared by all enrollment models)

### Step 7 — Create the Apple MDM Push (APNs) certificate
1. Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**.
2. Check **I agree**, **Download** the CSR.
3. **Create your MDM push certificate** → `https://identity.apple.com`; sign in with a **company Apple
   ID** (record it — reuse it every year).
4. **Create a Certificate**, upload the CSR, **Download** the `.pem`; back in Intune enter the **Apple
   ID**, **Browse** to the `.pem`, **Upload**. Confirm status **Active** (~1 year out).

### Step 8 — Connect Apple Business Manager to Intune (ADE token — for Corporate-Owned)
1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens → Add** → check **I agree** →
   **Download** the Intune **public key** (`.pem`).
2. In **ABM**, add an **MDM server** and **upload the Intune public key**, then **download the server
   token** (`.p7m`) (exact ABM menu deferred to Apple docs). Name the MDM server `Intune – iOS COD`.
3. Back in Intune, enter the **Apple ID** used for ABM, **Browse** to the `.p7m`, **Upload**. The token
   appears under **Enrollment program tokens**.

---

## Phase 5 — Stand up the three enrollment models

### Step 9 — Corporate-Owned (COD): ADE enrollment profile (supervised, account-driven)
1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens →** open the token from Step 8
   **→ Profiles → Create profile → iOS/iPadOS**. **Name it** `iOS COD – ADE – Pilot`; add a description.
2. **User affinity** = **Enroll with user affinity**, and select **account-driven** enrollment so the
   user signs in with their **Entra identity / Managed Apple ID** during Setup Assistant.
3. **Management options:** enable **Supervised**; set **Locked enrollment = Yes**.
4. **Setup Assistant:** hide non-essential panes for a clean first-run.
5. **Review + Create.**
6. Assign devices: in **ABM**, assign the company-owned iPhone serials to the **`Intune – iOS COD`**
   MDM server (deferred to Apple docs); in Intune, on the token → **Devices**, **Sync** (Apple
   rate-limits — allow a few minutes), select the serials → **Assign profile** → `iOS COD – ADE – Pilot`.

### Step 10 — BYOD: account-driven User Enrollment
1. Intune → **Devices → Enrollment → Enrollment types** (Apple) → **Create** a profile for
   **User Enrollment**; **name it** `iOS BYOD – User Enrollment – Pilot`.
2. Set the enrollment type to **account-driven User Enrollment** (the modern, privacy-preserving model
   that uses the **Managed Apple ID + Entra federated sign-in**).
3. **Assignments:** assign to **`iOS BYOD – Users – Pilot`** (users, not devices — BYOD is user-scoped).
   **Create.**

> No ADE token is needed for BYOD; the user starts enrollment from the device's settings and
> authenticates with their federated Managed Apple ID, which creates the managed work partition.

### Step 11 — Shared: no-user-affinity enrollment
1. On the ADE token, **Profiles → Create profile → iOS/iPadOS**; **name it** `iOS Shared – ADE – Pilot`.
2. **User affinity** = **Enroll without user affinity** (this is what makes the device shared — no
   primary user). Enable **Supervised**; **Locked enrollment = Yes**.
3. **Setup Assistant:** hide non-essential panes. **Review + Create.**
4. In **ABM**, assign the shared iPhone serials to the `Intune – iOS COD` MDM server (or a dedicated
   server entry) (deferred to Apple docs); in Intune, on the token → **Devices → Sync**, select the
   serials → **Assign profile** → `iOS Shared – ADE – Pilot`.
5. Staff identity on shared phones lives in the **Managed Apple ID / shared app sign-in**, not bound to
   a primary user. (iPhones have no Apple "Shared iPad" — see Overview.)

> **Shared device group targeting — make `iOS Shared – Devices – Pilot` an Assigned group owned by the
> Intune Provisioning Client (enrollment-time grouping).** For deterministic shared-device enrollment,
> keep `iOS Shared – Devices – Pilot` (created in Step 1) an **Assigned** security group and add the
> **Intune Provisioning Client** first-party service principal — **AppId
> `f1346770-5b25-470b-88bd-d5744ab7952c`**, in many tenants displayed as **`Intune Autopilot
> ConfidentialClient`** — as an **Owner** of the group. In Entra: **Groups → `iOS Shared – Devices –
> Pilot` → Owners → Add owners**, and search by that **AppId** (match by AppId, **not** the display
> name, which varies by tenant). Enrollment-time device grouping works by this principal *owning* the
> Assigned group — without the owner the group stays **empty at enrollment** and **none of the
> shared-device profiles (e.g. `iOS Shared – Compliance – Pilot`) or apps deploy**. The group must be
> **Assigned**, never Dynamic, for this mechanism. This is the same first-party principal and mechanism
> Windows Autopilot device preparation uses. **Verify the owner is present before each pilot.** *(If the
> principal isn't present in the tenant, open the Intune portal once as Global Administrator to
> provision it, then add it as owner.)*

### Step 12 — Compliance policies per model
1. Intune → **Devices → Compliance → Create policy → iOS/iPadOS**; create one each:
   `iOS COD – Compliance – Pilot`, `iOS BYOD – Compliance – Pilot`, `iOS Shared – Compliance – Pilot`.
2. Set rules appropriate to each model (e.g. min iOS version; jailbreak detection; a passcode rule for
   COD/BYOD; relaxed/no passcode for hand-off-speed shared phones).
3. **Assignments:** `iOS COD – Compliance – Pilot` → `iOS COD – Devices – Pilot`;
   `iOS BYOD – Compliance – Pilot` → `iOS BYOD – Users – Pilot`;
   `iOS Shared – Compliance – Pilot` → `iOS Shared – Devices – Pilot`. **Create** each.

---

## Phase 6 — Pilot, validate, expand

### Step 13 — Pilot-enroll one device per model
1. **COD:** erase a pilot company iPhone (**Settings → General → Transfer or Reset → Erase All Content
   and Settings**), power on, and complete **Remote Management** — it enrolls supervised, account-driven,
   and the user signs in with their federated Managed Apple ID.
2. **BYOD:** on a personal iPhone, start **account-driven User Enrollment** from device settings and
   sign in with the federated Managed Apple ID — a managed work partition is created.
3. **Shared:** erase a pilot shared iPhone and enroll via ADE with `iOS Shared – ADE – Pilot` — it
   enrolls **no user affinity**; staff sign in to the relevant app/service with the Managed Apple ID.

### Step 14 — Validate the pilot
1. Run **`ABMPROV-Discovery.ps1`** (federation + provisioning job + ADE token + APNs readiness).
2. Run **`ABMPROV-Validation.ps1`** (per-user Managed Apple ID provisioned/federated; per-device correct
   enrollment model).
3. Run **`ABMPROV-Report.ps1`** (provisioning coverage + COD/BYOD/Shared breakdown). Complete the
   **Testing Guide** pilot gate before expanding.

### Step 15 — Expand to production
1. **Provisioning:** Entra → `Apple Business Manager – Federation – Prod` → **Users and groups** → add
   `Managed Apple ID Provisioning – Corp – Prod`; the next cycle provisions the full population. Confirm
   conflicts are clear org-wide first.
2. **COD / Shared:** add remaining serials to the ADE token and assign the `… – ADE – Pilot` profiles
   (or make them the **default** profile for the token); add devices to the per-scenario groups.
3. **BYOD:** extend `iOS BYOD – User Enrollment – Pilot` to the broader BYOD user population.
4. Re-run **`ABMPROV-Report.ps1`** and roll out in waves, validating each wave before widening.

---
### Order of operations
`Scope groups → ABM provisioning app (Entra) → federate ABM↔Entra → resolve conflicts → SCIM
provisioning (pilot) → APNs → ADE token → COD ADE / BYOD User Enrollment / Shared no-affinity →
compliance → pilot-enroll → validate → expand`


---


# 5. Testing Guide — Entra ID + ABM Federation & Account Auto-Provisioning

Run after provisioning is on for the pilot and one device per model is enrolled (Implementation
Steps 13–14), and again after each expansion wave. Use **`ABMPROV-Discovery.ps1`** /
**`ABMPROV-Validation.ps1`** / **`ABMPROV-Report.ps1`** to back each test with data.

## Test 1 — Federation is active for the domain
**Do:** Have a pilot user sign in to an Apple service with their work email; confirm the sign-in
redirects to **Entra** and accepts their Entra credentials (and MFA).
**Expected:** Authentication completes via Entra ID — no separate Apple password prompt.

## Test 2 — Existing-Apple-ID conflicts are clear for pilot users
**Do:** Re-check the ABM domain-capture / conflict report for the pilot users (deferred to Apple docs).
**Expected:** No conflicted personal Apple IDs remain for in-scope pilot users.

## Test 3 — Managed Apple IDs auto-provision (SCIM)
**Do:** Entra → `Apple Business Manager – Federation – Prod` → **Provisioning → Provisioning logs**;
run **`ABMPROV-Validation.ps1`** for the pilot users.
**Expected:** Pilot users have a **Managed Apple ID provisioned** (provisioning job healthy; logs show
success for the pilot group).

## Test 4 — Just-in-time backfill works
**Do:** With a scoped user who has no Managed Apple ID yet, have them sign in to an Apple service with
their federated credentials.
**Expected:** A Managed Apple ID is created on first federated sign-in (JIT) without a manual step.

## Test 5 — COD enrolls correctly
**Do:** Run **`ABMPROV-Validation.ps1`** for a pilot COD device; check Intune → **Devices**.
**Expected:** The phone is **supervised**, **has user affinity**, enrolled via **ADE**
(`iOS COD – ADE – Pilot`), in **`iOS COD – Devices – Pilot`**, compliant.

## Test 6 — BYOD enrolls correctly (privacy-preserving)
**Do:** Run **`ABMPROV-Validation.ps1`** for a pilot BYOD device; check Intune → **Devices**.
**Expected:** The phone shows **account-driven User Enrollment**, a **managed work partition**, user in
**`iOS BYOD – Users – Pilot`**; personal data is not managed.

## Test 7 — Shared enrolls correctly (no affinity)
**Do:** Run **`ABMPROV-Validation.ps1`** for a pilot shared device; check Intune → **Devices**.
**Expected:** The phone is **supervised**, **no primary user**, enrolled via `iOS Shared – ADE – Pilot`,
in **`iOS Shared – Devices – Pilot`**; staff sign in to the app/service with a Managed Apple ID.

## Test 8 — Apple connection readiness
**Do:** Run **`ABMPROV-Discovery.ps1`**.
**Expected:** APNs certificate **Active** (not near expiry), a valid **ADE token**, the provisioning job
**On/healthy**, and federation reachable.

## Test 9 — Fleet coverage + scenario breakdown
**Do:** Run **`ABMPROV-Report.ps1`**.
**Expected:** A clear provisioning-coverage figure and a COD / BYOD / Shared device breakdown; each
device appears in exactly one model.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Federation/provisioning pass** | Tests 1–4 pass for the pilot group |
| **Per-model pass** | Tests 5–7 pass (one device validated per model) |
| **Readiness pass** | Tests 8–9 pass before any expansion wave |


---


# 6. Troubleshooting Guide — Entra ID + ABM Federation & Account Auto-Provisioning

Use **`ABMPROV-Discovery.ps1`** for federation/provisioning/ADE/APNs readiness,
**`ABMPROV-Validation.ps1`** for per-user/per-device state, **`ABMPROV-Report.ps1`** for fleet
coverage, and **`ABMPROV-Remediation.ps1`** (default `-WhatIf`) for safe fixes. ABM-side console
specifics are deferred to Apple's official documentation.

## A. Federation conflicts / existing personal Apple IDs
| Symptom | Cause | Remediation |
|---|---|---|
| User can't get a Managed Apple ID; "in use" | A personal Apple ID already uses the work-email (domain capture conflict) | Re-run the ABM domain-capture report; have the user change their personal Apple ID to a different email; re-check before re-provisioning |
| Federated sign-in fails for some users | Those users still have a conflicting personal Apple ID, or were not in the change window | Resolve the conflict (above); confirm the user is in the federated, provisioned scope |
| Whole-domain sign-in concerns after federation | Federation is domain-wide for Apple sign-in | Expected — keep provisioning scoped to the pilot group until conflicts clear; communicate the change |

## B. SCIM provisioning failures (Entra → ABM)
| Symptom | Cause | Remediation |
|---|---|---|
| Provisioning job won't start / Test Connection fails | ABM authorization not completed or expired | Re-authorize ABM under Provisioning → Admin Credentials; Test Connection (ABM screen deferred to Apple docs) |
| Some users never provision | They aren't in the assigned scope group, or "Sync only assigned" excludes them | Add them to `Managed Apple ID Provisioning – Pilot – Stage`/`– Corp – Prod`; run `ABMPROV-Remediation.ps1` to fix membership |
| Per-user errors in Provisioning logs | Attribute mapping / unresolved conflict | Check Mappings (stable identifier + verified-domain email); resolve any Apple-ID conflict; let the next cycle retry |
| Quota / not-found errors | App not assigned, or scope set to "all" by mistake | Confirm the app is assigned to the scope group and Scope = "Sync only assigned users and groups" |

## C. COD (Corporate-Owned) enrollment issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device doesn't show "Remote Management" | Serial not assigned to the Intune MDM server in ABM, or token not synced | Assign the serial to `Intune – iOS COD` in ABM (deferred to Apple docs); Intune → token → Devices → Sync (allow for Apple rate limits) |
| Enrolls but not supervised / not account-driven | Wrong ADE profile or profile not assigned | Confirm `iOS COD – ADE – Pilot` has Supervised + account-driven and is assigned to the serial |
| User can't sign in during setup | Federation/Managed Apple ID not ready for that user | Confirm the user is federated and provisioned (`ABMPROV-Validation.ps1`) before enrolling their device |

## D. BYOD (account-driven User Enrollment) issues
| Symptom | Cause | Remediation |
|---|---|---|
| Enrollment offers the wrong (older) flow | iOS too old for account-driven User Enrollment, or wrong enrollment type | Update iOS (Requirement 2.7); confirm the profile is account-driven User Enrollment assigned to `iOS BYOD – Users – Pilot` |
| Work account won't add | Federated Managed Apple ID missing for the user | Provision/JIT the Managed Apple ID first; verify with `ABMPROV-Validation.ps1` |
| Personal data appears managed | Device was enrolled with device enrollment, not User Enrollment | Re-enroll via account-driven User Enrollment (the privacy-preserving model) |

## E. Shared (no-affinity) enrollment issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device asks for a primary user | Profile has user affinity | Use `iOS Shared – ADE – Pilot` with **Enroll without user affinity** |
| Expecting Apple "Shared iPad" on iPhone | iPhones have no Shared iPad feature | Use no-affinity + restrictions + Managed Apple ID / shared app sign-in (see Overview / Section 4) |
| Staff can't access the app | Shared sign-in not set up | Sign in to the relevant app/service with the Managed Apple ID or shared account |
| `iOS Shared – Devices – Pilot` is **empty after enrollment**; no shared-device profiles or apps deploy | The group is **Assigned** but the **Intune Provisioning Client** SP (**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, often shown as **`Intune Autopilot ConfidentialClient`**) is **not an Owner**, so enrollment-time device grouping can't populate it | Entra → **Groups → `iOS Shared – Devices – Pilot` → Owners → Add owners**, search by that **AppId** (not the display name), then re-enroll a pilot device. Group must be **Assigned**, not Dynamic (same principal Windows Autopilot device preparation uses). If the SP is missing, open the Intune portal once as Global Administrator to provision it, then add it as owner |

## F. Apple connection (APNs / ADE token)
| Symptom | Cause | Remediation |
|---|---|---|
| No iPhones can be managed | APNs certificate expired or wrong Apple ID | Renew APNs with the **same** company Apple ID (Implementation Step 7); never switch the Apple ID |
| COD devices stop flowing from ABM | ADE token expired | Renew the enrollment program token (re-upload the new `.p7m`) — `ABMPROV-Discovery.ps1` reports expiry |

## G. Diagnostics quick reference
- `ABMPROV-Discovery.ps1` — federation app, provisioning job status, ADE token, APNs readiness.
- `ABMPROV-Validation.ps1` — per-user Managed Apple ID + per-device enrollment model.
- `ABMPROV-Report.ps1` — provisioning coverage + COD/BYOD/Shared breakdown.
- Entra → `Apple Business Manager – Federation – Prod` → **Provisioning → Provisioning logs** for
  per-user provisioning results.

## H. When to escalate
If federation is configured, conflicts are clear, the provisioning job is On and healthy, the user is in
the assigned scope, and a Managed Apple ID still won't provision after a cycle, capture the Provisioning
log entry and the ABM domain-capture report state and open a Microsoft (Entra provisioning) and/or Apple
(ABM) support case as the failure side indicates.


---


# 7. Best Practices — Entra ID + ABM Federation & Account Auto-Provisioning

- **Pilot the scope, not the federation alone.** Federation is domain-wide for Apple sign-in, so the
  control you have is provisioning scope — keep SCIM scoped to `Managed Apple ID Provisioning – Pilot –
  Stage` until conflicts are resolved and the pilot passes. This is the single most important practice.
- **Resolve existing-Apple-ID conflicts before widening.** Run the ABM domain-capture report, give
  users a clear change-window deadline, and re-check before expanding. Conflicts are the number-one
  cause of provisioning and enrollment failures.
- **Use SCIM as primary, JIT as backfill.** SCIM gives scoped, auditable, reversible provisioning and
  de-provisioning with the user lifecycle; just-in-time creation on first federated sign-in catches
  anyone a cycle hasn't reached. Rely on both.
- **Keep the three models cleanly separated.** One enrollment profile and one compliance policy per
  device/user; COD by device group, BYOD by user group, Shared by device group. Never double-assign.
- **Be accurate about shared iPhones.** iPhones have no Apple "Shared iPad" — build shared on
  **no-affinity enrollment + restrictions + a Managed Apple ID / shared app sign-in**, and say so.
- **Name everything consistently.** Use the `<Purpose> – <Scope> – <Stage>` convention verbatim across
  groups, ADE profiles, and compliance policies so docs, scripts, and the console all match.
- **Protect the Apple credentials.** Record the **company Apple ID** used for the APNs certificate and
  the **ADE token** Apple ID; both renew yearly — a lapse breaks all iPhone management.
- **Keep break-glass ready.** Per the global requirements, keep cloud-only emergency-access accounts
  excluded from broad policies before changing identity/sign-in.
- **Validate every wave.** Run `ABMPROV-Discovery.ps1`, `ABMPROV-Validation.ps1`, and
  `ABMPROV-Report.ps1` before and after each expansion; don't widen on assumption.
- **Have a rollback.** To stop provisioning, set the job **Off** and remove the pilot group's
  assignment; full federation removal is an ABM-side action (deferred to Apple docs) — coordinate it
  because it affects sign-in.
- **De-provision with the lifecycle.** Let SCIM remove Managed Apple IDs when a user leaves scope; do
  not orphan accounts.


---


# 8. Deliverables Summary — Entra ID + ABM Federation & Account Auto-Provisioning

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Federation + Managed Apple ID provisioning (SCIM + JIT), the conflict nuance, and how it feeds COD/BYOD/Shared |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Entra ID Solutions) | Category-wide identity prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Entra + Intune steps; ABM actions named, menus deferred to Apple |
| 4. Enrollment Scenarios | How the federated Managed Apple ID flows into COD, BYOD, and Shared, with the per-model sign-in experience |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Federation/conflict, SCIM, and per-scenario enrollment issues |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ABMPROV-Discovery.ps1` | Readiness: federation app, Entra→ABM provisioning job status, ADE token, APNs (read-only) |
| `ABMPROV-Validation.ps1` | Per-user Managed Apple ID provisioned/federated; per-device correct enrollment model (read-only) |
| `ABMPROV-Report.ps1` | Fleet provisioning coverage + COD/BYOD/Shared scenario breakdown (read-only) |
| `ABMPROV-Remediation.ps1` | Safe fixes (default `-WhatIf`): re-provision a user / fix scope-group membership |
| `ABMPROV-Set-ScopeTargeting.ps1` | Build the provisioning + per-scenario enrollment scope groups (default `-WhatIf`) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Entra ID federated with Apple Business Manager and Managed Apple IDs provisioning themselves — so
Corporate-Owned, BYOD, and Shared iPhones all enroll into Intune cleanly on one identity, proven on a
pilot before you scale.
