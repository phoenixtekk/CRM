# 2. Requirements Guide — Enterprise App & Service Principal Governance

Verify every requirement before configuring. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

## 2.1 Entra ID licensing
Description: Microsoft Entra ID P1 (P2 if you also want risk-based and identity-protection signals).
Why: The admin-consent workflow and some app-governance and risk features need P1+; the core app and
service-principal inventory and consent settings work with any tenant, but the review workflow that
makes this repeatable needs P1.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2.
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## 2.2 Administrative roles
Description: An operator role that can read and manage apps and consent. `Application Administrator`
(or `Cloud Application Administrator`) for day-to-day app governance; `Privileged Role
Administrator` or `Global Administrator` only for the settings that change tenant-wide consent
policy.
Why: Reviewing and remediating app permissions, consent grants, and credentials requires an
app-management role; changing the user-consent policy is a tenant-wide, high-privilege action.
Verify: Entra -> `Roles and administrators`; confirm `Application Administrator` (and a
`Global Administrator` available for the consent-policy change).
Implement: Assign `Application Administrator` (or `Cloud Application Administrator`); reserve
`Global Administrator` for the one-time consent-policy change.

## 2.3 Consent policy decision
Description: A documented decision on how much users may consent to on their own — block user
consent, or allow it only for verified publishers and low-risk delegated permissions — and whether
to enable the admin-consent workflow.
Why: It is the single most consequential control for stopping consent-phishing. The default in many
tenants is far too permissive.
Verify: Entra -> `Identity -> Applications -> Enterprise applications -> Consent and permissions ->
User consent settings`; confirm the current setting is a deliberate choice, not the default.
Implement: Default to "Allow user consent for apps from verified publishers, for selected
permissions" (low-risk delegated scopes only); enable the admin-consent workflow so users can request
apps for review. Decide in Implementation Step 4.

## 2.4 App inventory approach
Description: A repeatable way to enumerate every enterprise app and service principal with its
app-role assignments, delegated grants, owners, and credentials.
Why: You cannot govern what you have not inventoried; the tenant almost always holds more apps than
anyone expects.
Verify: Run `APPGOV-Discovery.ps1`; confirm it returns service principals with their app-role
assignments, OAuth2 grants, and credential expiry.
Implement: Install the Microsoft Graph PowerShell SDK (see 2.6) and run `APPGOV-Discovery.ps1`.

## 2.5 Governance scope group (pilot)
Description: A pilot scope for the consent-policy and workflow rollout — a security group of
representative users named `App Governance Consent Scope - Pilot - Pilot`, plus a reviewer group
`App Governance Consent Reviewers - Tenant - Steady` for the admin-consent workflow.
Why: Every change is validated on a pilot before the tenant. The user-consent policy is tenant-wide,
so the pilot gate is the admin-consent workflow rollout and the remediation of a first batch of
apps — not a per-user policy split.
Verify: The groups exist with representative members; run `APPGOV-Set-ScopeTargeting.ps1` to preview.
Implement: Create the groups with `APPGOV-Set-ScopeTargeting.ps1` (see Implementation Step 1).

## 2.6 Microsoft Graph PowerShell SDK
Description: The Microsoft Graph PowerShell SDK on the operator workstation, with consent to the
read scopes the scripts use.
Why: Discovery, validation, and reporting read service principals, applications, app-role
assignments, OAuth2 grants, credentials, and the authorization policy through Microsoft Graph.
Verify: `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; a test
`Connect-MgGraph` succeeds.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; the scripts request the least
privilege they need (`Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, and — only for
remediation — `Application.ReadWrite.All` / `DelegatedPermissionGrant.ReadWrite.All`).

## 2.7 Break-glass accounts
Description: Two cloud-only emergency access accounts excluded from broad policies.
Why: A consent-policy or app-permission change could interfere with admin tooling; break-glass
accounts restore access.
Verify: Entra -> `Users`; two cloud-only `@onmicrosoft.com` admins exist (see global requirement G4).
Implement: Create them, exclude from broad policies, store credentials securely, and monitor sign-ins.

---
## Checklist
- [ ] Entra ID P1/P2 licensing assigned
- [ ] `Application Administrator` role assigned; `Global Administrator` available for consent-policy change
- [ ] User-consent policy decision documented (verified-publisher, low-risk scopes) + admin-consent workflow decision
- [ ] App inventory produced — `APPGOV-Discovery.ps1`
- [ ] Governance scope + reviewer groups created — `APPGOV-Set-ScopeTargeting.ps1`
- [ ] Microsoft Graph PowerShell SDK installed and consented
- [ ] Two break-glass accounts created and excluded from broad policies
