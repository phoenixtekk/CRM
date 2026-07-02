# 1. Solution Overview — Enterprise App & Service Principal Governance

## The Entra application model
When an app integrates with Microsoft Entra, two related objects appear. An `application` (the
app registration) is the global definition of the app — its identity, its declared permissions,
and its credentials — and it lives in the tenant that authored it. A `servicePrincipal` (the
enterprise application) is the local instance of that app in your tenant: it is what you actually
assign users to, consent permissions to, and see under Enterprise applications. A multi-tenant SaaS
vendor authors one app registration and every customer that signs in gets a service principal.
Governance is mostly about service principals — the running instances in your tenant — plus the app
registrations you own.

## Delegated vs. application permissions
Permissions come in two flavors, and the difference is the heart of the risk.

- Delegated permissions act on behalf of a signed-in user and are capped by that user's own rights.
  Example: `Mail.Read` delegated lets the app read only the signed-in user's mail.
- Application permissions (app roles) act as the app itself, with no user present, across the whole
  tenant. Example: `Mail.Read` as an application permission lets the app read every mailbox in the
  tenant. These are the dangerous ones — a compromised app with tenant-wide application permissions
  is a tenant-wide breach.

In the directory, granted delegated permissions appear as `oauth2PermissionGrants`, and granted
application permissions appear as `appRoleAssignments` on the service principal.

## Consent — who approves the permissions
- User consent: a user clicks Accept on an app's consent prompt and grants delegated permissions
  for themselves. Convenient, but it is exactly how consent-phishing works — an attacker sends a
  link to a malicious app that requests broad delegated scopes (read all your mail, files, send
  mail as you), and one careless click hands over a durable OAuth token that survives password
  changes and MFA.
- Admin consent: an administrator grants permissions for the whole organization — required for
  application permissions and for high-privilege delegated scopes. The healthy pattern is to
  restrict user consent to low-risk permissions and route everything else through an admin-consent
  workflow, so users can request an app and an admin reviews it before it is trusted.

## The over-permission problem
Apps accumulate more permission than they use. A vendor's app requests broad scopes to cover every
possible feature; an internal script is granted `Directory.ReadWrite.All` because it was quicker than
scoping it down. Every unused permission is blast radius: if that app or its secret is stolen, the
attacker inherits everything it was granted. Governance means finding these over-permissioned apps —
especially those with tenant-wide application permissions — and cutting them back to what they need.

## Secret and certificate hygiene
An app authenticates with a client secret (`passwordCredentials`) or a certificate
(`keyCredentials`). Two failure modes matter: a credential that expires unexpectedly breaks the
integration (an outage), and a credential that never expires — or has a very long life, or is one of
many piled on the same app — is a standing risk that outlives the people who created it. Governance
tracks expiry so nothing breaks by surprise, and prunes stale or excessive credentials so a leaked
secret has a short, bounded life.

## What you can control
- Inventory: every enterprise app and service principal, its owners, its app-role assignments,
  its OAuth2 delegated grants, and its credentials.
- User-consent policy: block user consent, or allow it only for verified publishers and low-risk
  permissions; enable an admin-consent workflow so users can request review.
- Over-permission review: identify apps holding high-privilege application permissions or broad
  delegated grants, and remediate the risky ones.
- Credential lifecycle: track secret and certificate expiry, and remove stale or surplus
  credentials.

## Benefits
- Security — the number-one payoff: risky consents revoked, over-privilege cut, and
  consent-phishing blocked at the policy level before a user can be tricked.
- Visibility — a real inventory of what apps exist, who owns them, and what they can do.
- Continuity — no more integrations breaking because a secret expired unnoticed.
- Repeatability — a governance pattern you run on a schedule, not a one-time cleanup.

## Limitations (be honest with buyers)
- Revoking a permission or removing a credential can break a legitimate app — every change is
  staged, validated on a pilot scope, and reversible, and the remediation script defaults to a
  preview (`-WhatIf`).
- The admin-consent workflow and some risk features need Entra ID P1 or P2 (see requirements).
- This governs Entra app permissions and consent; it does not replace a full third-party SaaS
  security review of what each vendor does with the access.

## The standard deployment model
> Inventory apps and service principals -> review permissions and consent for over-privilege ->
> configure the user-consent policy and admin-consent workflow on a pilot scope -> validate ->
> remediate risky grants and manage credential expiry -> expand tenant-wide. repeatable pattern:
> Assess -> Configure -> Pilot -> Validate -> Expand.
