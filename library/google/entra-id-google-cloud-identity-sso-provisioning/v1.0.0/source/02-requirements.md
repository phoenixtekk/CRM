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
