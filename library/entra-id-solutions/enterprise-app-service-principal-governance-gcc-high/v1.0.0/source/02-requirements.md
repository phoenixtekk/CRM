# 2. Requirements Guide — Enterprise App & Service Principal Governance (Government / GCC High)

Verify every requirement before configuring, using the **US sovereign** portals and endpoints. Each
entry: Description / Why / Verify / Implement-if-missing. Category-wide prerequisites are in
`global-requirements-entra-id-solutions.md`. Cited GCC High feature-availability detail is in
`gcc-high-parity-notes.md`.

> GCC High reminder: sign in at `https://entra.microsoft.us` (Entra), `https://portal.azure.us`
> (Azure), `https://portal.office365.us` (M365 admin) with a GCC High account. A GCC High credential
> is not recognized on the Commercial `.com` portals. The scripts connect with
> `Connect-MgGraph -Environment USGov` (`graph.microsoft.us`).

## 2.1 GCC High tenant
Description: An active Microsoft Entra ID tenant in the US Government L4 (GCC High) cloud.
Why: All portals, endpoints, and Graph calls target the sovereign `.us` instance; a Commercial tenant
uses different URLs and is not interchangeable.
Verify: Sign in to `https://entra.microsoft.us` as an administrator; confirm the tenant resolves and
that `Connect-MgGraph -Environment USGov` authenticates.
Implement: Provision or migrate to a GCC High tenant through your Microsoft/Government partner; this
solution does not create the tenant.

## 2.2 Entra ID licensing (Government SKUs)
Description: Microsoft Entra ID P1 (P2 if you also want risk-based and identity-protection signals),
delivered through the US Government plans — typically Microsoft 365 **G3/G5 (GCC High)** or EMS G3/G5,
or standalone Entra ID P1/P2 for Government.
Why: The admin-consent workflow and some app-governance and risk features need P1+; the core app and
service-principal inventory and consent settings work with any tenant, but the review workflow that
makes this repeatable needs P1.
Verify: `https://portal.office365.us` -> `Billing -> Licenses`; confirm Entra ID P1/P2 (bundled in
M365 G3/G5 or EMS G3/G5).
Implement: Assign M365 G3/G5, EMS G3/G5, or standalone Entra ID P1/P2 (Government).
Note: Entra ID Governance (Access reviews, Entitlement management, PIM, Lifecycle workflows) is GA in
GCC High — see parity notes.

## 2.2a Confirm US Gov feature parity for anything you layer on
Description: A quick check of `gcc-high-parity-notes.md` before you build a step on any
adjacent feature.
Why: GCC High parity is close but not total. For example, **Microsoft Entra threat intelligence**
(an ID Protection risk detection) is not available, and **Graph Explorer** is not supported in
GCC High — use the PowerShell scripts instead.
Verify: Read the parity notes; for any feature marked "verify for GCC High," confirm it in your
`entra.microsoft.us` portal before depending on it.
Implement: If a planned adjacent control (for example a specific risk signal) is not in GCC High,
substitute the over-permission report and consent policy, which do not depend on it.

## 2.3 Administrative roles
Description: An operator role that can read and manage apps and consent. `Application Administrator`
(or `Cloud Application Administrator`) for day-to-day app governance; `Privileged Role
Administrator` or `Global Administrator` only for the settings that change tenant-wide consent
policy. RBAC and these roles are available in US Government (see parity notes).
Why: Reviewing and remediating app permissions, consent grants, and credentials requires an
app-management role; changing the user-consent policy is a tenant-wide, high-privilege action.
Verify: `entra.microsoft.us` -> `Roles and administrators`; confirm `Application Administrator` (and a
`Global Administrator` available for the consent-policy change).
Implement: Assign `Application Administrator` (or `Cloud Application Administrator`); reserve
`Global Administrator` for the one-time consent-policy change.

## 2.4 Consent policy decision
Description: A documented decision on how much users may consent to on their own — block user
consent, or allow it only for verified publishers and low-risk delegated permissions — and whether
to enable the admin-consent workflow.
Why: It is the single most consequential control for stopping consent-phishing. The default in many
tenants is far too permissive.
Verify: `entra.microsoft.us` -> `Entra ID -> Enterprise apps -> Consent and permissions ->
User consent settings`; confirm the current setting is a deliberate choice, not the default.
Implement: Default to "Allow user consent for apps from verified publishers, for selected
permissions" (low-risk delegated scopes only); enable the admin-consent workflow so users can request
apps for review. Decide in Implementation Step 4.

## 2.5 App inventory approach
Description: A repeatable way to enumerate every enterprise app and service principal with its
app-role assignments, delegated grants, owners, and credentials — via US Gov Graph.
Why: You cannot govern what you have not inventoried; the tenant almost always holds more apps than
anyone expects.
Verify: Run `APPGOVG-Discovery.ps1`; confirm it connects with `-Environment USGov` and returns
service principals with their app-role assignments, OAuth2 grants, and credential expiry.
Implement: Install the Microsoft Graph PowerShell SDK (see 2.7) and run `APPGOVG-Discovery.ps1`.

## 2.6 Governance scope group (pilot)
Description: A pilot scope for the consent-policy and workflow rollout — a security group of
representative users named `App Governance Consent Scope - Pilot - Pilot`, plus a reviewer group
`App Governance Consent Reviewers - Tenant - Steady` for the admin-consent workflow.
Why: Every change is validated on a pilot before the tenant. The user-consent policy is tenant-wide,
so the pilot gate is the admin-consent workflow rollout and the remediation of a first batch of
apps — not a per-user policy split.
Verify: The groups exist with representative members; run `APPGOVG-Set-ScopeTargeting.ps1` to preview.
Implement: Create the groups with `APPGOVG-Set-ScopeTargeting.ps1` (see Implementation Step 1).

## 2.7 Microsoft Graph PowerShell SDK (US Gov)
Description: The Microsoft Graph PowerShell SDK on the operator workstation, with consent to the
read scopes the scripts use, connecting to the **USGov** environment.
Why: Discovery, validation, and reporting read service principals, applications, app-role
assignments, OAuth2 grants, credentials, and the authorization policy through Microsoft Graph — and
in GCC High that must be the `graph.microsoft.us` endpoint, because Graph Explorer is not supported.
Verify: `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; a test
`Connect-MgGraph -Environment USGov` succeeds and `(Get-MgContext).Environment` reads `USGov`.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; the scripts request the least
privilege they need (`Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, and — only for
remediation — `Application.ReadWrite.All` / `DelegatedPermissionGrant.ReadWrite.All`) against USGov.

## 2.8 Break-glass accounts
Description: Two cloud-only emergency access accounts excluded from broad policies.
Why: A consent-policy or app-permission change could interfere with admin tooling; break-glass
accounts restore access.
Verify: `entra.microsoft.us` -> `Users`; two cloud-only `@<tenant>.onmicrosoft.us` admins exist
(see global requirement G4; note the `.us` onmicrosoft suffix in GCC High).
Implement: Create them, exclude from broad policies, store credentials securely, and monitor sign-ins.

## 2.9 Network egress to US Gov endpoints
Description: Outbound HTTPS (443) from the operator workstation to the GCC High service endpoints.
Why: The scripts and portals reach `login.microsoftonline.us`, `graph.microsoft.us`,
`entra.microsoft.us`, and `portal.azure.us`; a proxy/firewall that only allows the Commercial `.com`
endpoints will block them.
Verify: From the workstation, reach `https://login.microsoftonline.us` and `https://graph.microsoft.us`.
Implement: Allow the Microsoft 365 U.S. Government GCC High URL/IP ranges through the proxy/firewall
(see M365 US Gov GCC High endpoints, cited in parity notes).

---
## Checklist
- [ ] GCC High (US Gov L4) tenant confirmed — signs in at `entra.microsoft.us`
- [ ] Entra ID P1/P2 licensing assigned via Government SKUs (M365/EMS G3/G5)
- [ ] GCC High parity checked for any adjacent feature (`gcc-high-parity-notes.md`)
- [ ] `Application Administrator` role assigned; `Global Administrator` available for consent-policy change
- [ ] User-consent policy decision documented (verified-publisher, low-risk scopes) + admin-consent workflow decision
- [ ] App inventory produced — `APPGOVG-Discovery.ps1` (connects `-Environment USGov`)
- [ ] Governance scope + reviewer groups created — `APPGOVG-Set-ScopeTargeting.ps1`
- [ ] Microsoft Graph PowerShell SDK installed and consented; `Connect-MgGraph -Environment USGov` works
- [ ] Two break-glass accounts created and excluded from broad policies
- [ ] Network egress to `login.microsoftonline.us` / `graph.microsoft.us` allowed
