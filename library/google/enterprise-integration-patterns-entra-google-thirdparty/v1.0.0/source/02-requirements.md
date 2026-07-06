# 2. Requirements Guide — Enterprise Integration Patterns

Verify every requirement before defining or piloting the target patterns. Each entry:
**Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (Google tenant,
source M365/Entra environment, DNS control, source of truth, pilot scope, governance stakeholders)
are in `global-requirements-google.md` — this guide adds what the integration-pattern work needs on
top of those.

## 2.1 Both control planes accessible (Entra + Google)
- **Description:** Administrative access to **Microsoft Entra ID** (to author federation and
  provisioning on the Microsoft side) and to the **Google Admin console / Cloud Identity** (to accept
  the SAML profile and enable SCIM on the Google side).
- **Why required:** The Entra↔Google patterns (P1/P2) are configured on both ends — Entra publishes
  SSO/SCIM; Google accepts the SSO profile and enables the SCIM endpoint.
- **Verify:** Sign in to **entra.microsoft.com** with an app-management role and to **admin.google.com**
  as a super-admin.
- **Implement:** Obtain the roles from the respective tenant owners before piloting.

## 2.2 Administrative roles (least privilege)
- **Description:** On Entra: `Application Administrator` (or `Cloud Application Administrator`) for
  federation/provisioning app configuration; `Global Administrator` only for tenant-wide settings. On
  Google: a **super-admin** for the SSO profile and provisioning; on third-party apps, the app's SSO/admin role.
- **Why required:** Configuring federation, SSO, and provisioning are privileged actions on each plane.
- **Verify:** Entra → `Roles and administrators`; Google → `Account → Admin roles`; each app's admin console.
- **Implement:** Assign the least-privilege role on each plane; reserve `Global Administrator` for the
  one-time tenant settings.

## 2.3 Chosen identity provider and direction, per workload
- **Description:** A documented decision on **which system is the IdP** for each workload and app, and
  the **protocol** (SAML 2.0 or OIDC). During coexistence the answer can differ per workload.
- **Why required:** The catalog patterns are direction-specific (P1 = Entra-as-IdP → Google). Picking
  the IdP per workload up front prevents circular or conflicting trusts.
- **Verify:** A short IdP-direction table exists for the workloads/apps in scope.
- **Implement:** Decide the enterprise IdP (commonly Entra ID during a Google transformation) and any
  per-workload exceptions before configuring; record it in the Integration-Patterns reference doc.

## 2.4 Single source of truth for identity + provisioning model
- **Description:** One authoritative directory per object type and a chosen provisioning mechanism —
  **SCIM push** (Entra → Google, P2), **GCDS pull** (AD/LDAP → Google, P3), or **JIT** on first SSO —
  never two masters for the same object.
- **Why required:** Two sources of truth is the anti-pattern that causes directories to drift and
  conflict; consistent provisioning underpins SSO, licensing, and de-provisioning.
- **Verify:** Confirm which directory masters users/groups and which mechanism moves them into Google
  (and into each third-party app).
- **Implement:** Pick the source of truth and the P2/P3/JIT mechanism per object before enabling
  provisioning. (Enterprise-source-of-truth details are in global requirement 4.)

## 2.5 Third-party app SSO/provisioning capability matrix
- **Description:** For each in-scope third-party app (e.g. ServiceNow, SAP, Databricks), the **verified**
  facts: does it federate over SAML, OIDC, or both; does it support **SCIM** provisioning from the chosen
  IdP, or only a legacy/connector approach; how are roles carried (claims/groups).
- **Why required:** App capabilities differ and change — e.g. Databricks supports SAML/OIDC + SCIM (with
  JIT on newer accounts), while some apps support SAML SSO but **not** SCIM from a given IdP and need a
  supported connector instead. The pattern chosen (P5/P6) depends on what the app actually supports.
- **Verify:** Confirm each app's current capability from the **vendor's own documentation** and a test
  in your tenant — do not assume.
- **Implement:** Build the matrix (app → protocol → provisioning → role model) and record it in the
  Integration-Patterns reference doc; flag any "verify in tenant" items.

## 2.6 Coexistence cutover plan (M365 ↔ Google)
- **Description:** A per-workload plan for the coexistence window: which IdP owns each workload, how
  identities stay synchronized, and the **cutover order** (identity → SSO → provisioning → mail/data).
- **Why required:** Undocumented coexistence is an anti-pattern; a defined order keeps authentication
  and provisioning consistent while both ecosystems are live.
- **Verify:** A cutover plan exists with an owner and change windows.
- **Implement:** Draft the plan under change control before piloting coexistence patterns (mail/DNS
  changes are high-impact — see global requirement 3).

## 2.7 API / data-access identities defined
- **Description:** For service-to-service and data access (P7): the intended **OAuth client-credentials
  / workload identity federation** and **scoped service accounts**, with least-privilege scopes — no
  shared long-lived secrets by default.
- **Why required:** Credential sprawl and over-broad scopes are the API-layer anti-patterns; workload
  identity federation removes standing secrets.
- **Verify:** Each automation/data path has a named identity and a scoped set of permissions.
- **Implement:** Define the workload-identity or service-account model and scopes before granting access.

## 2.8 Microsoft Graph PowerShell SDK
- **Description:** The Microsoft Graph PowerShell SDK on the operator workstation, with consent to the
  read scopes the scripts use.
- **Why required:** Discovery, validation, and reporting read the Entra-side integration estate —
  federation/SSO apps, provisioning jobs, service principals, app-role assignments, OAuth grants, and
  credentials — through Microsoft Graph.
- **Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; a test
  `Connect-MgGraph` succeeds.
- **Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`; the scripts request least
  privilege (`Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, `Synchronization.Read.All`;
  and — only for remediation — `Application.ReadWrite.All` / `DelegatedPermissionGrant.ReadWrite.All`).

## 2.9 Pilot app set and change control
- **Description:** A small, representative **set of apps** to pilot the target patterns on (typically:
  the Entra↔Google trust plus one third-party app), and a change-control window.
- **Why required:** Every pattern is validated on a pilot before the estate; a scoped set proves the
  design without risking production integrations.
- **Verify:** A named pilot app set and change window exist.
- **Implement:** Choose the pilot apps and agree the change process; use `GWINTEG-Set-ScopeTargeting.ps1`
  to build the pilot scope group.

## 2.10 Break-glass accounts
- **Description:** Two cloud-only emergency-access accounts excluded from federation/conditional-access
  policies.
- **Why required:** A federation or SSO change could interfere with admin sign-in; break-glass accounts
  restore access.
- **Verify:** Entra → `Users`; two cloud-only `@onmicrosoft.com` admins exist, excluded from broad policies.
- **Implement:** Create them, exclude from federation/CA policies, store credentials securely, monitor sign-ins.

---
## Checklist
- [ ] Both control planes accessible — Entra (app-mgmt role) + Google (super-admin)
- [ ] Least-privilege admin roles assigned on each plane
- [ ] IdP + direction + protocol decided per workload/app
- [ ] Single source of truth + provisioning model (SCIM / GCDS / JIT) chosen per object
- [ ] Third-party app SSO/provisioning capability matrix built and verified from vendor docs
- [ ] Coexistence cutover plan drafted under change control
- [ ] API / data-access identities and scopes defined (workload identity / scoped service accounts)
- [ ] Microsoft Graph PowerShell SDK installed and consented
- [ ] Pilot app set and change window named — `GWINTEG-Set-ScopeTargeting.ps1`
- [ ] Two break-glass accounts created and excluded from federation/CA policies
