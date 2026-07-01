# 2. Requirements Guide — Adobe Creative Cloud for Enterprise License Management

Verify every requirement before configuring. Each entry follows: Description, Why, Verify, and
Implement-if-missing. Category-wide prerequisites are in `global-requirements-asset-mgt.md`; the
requirements below are specific to Adobe Creative Cloud for Enterprise.

Adobe-specific configuration (Admin Console internals, identity and SSO setup, exact API
authentication) is deferred to Adobe's official documentation. The steps below give the correct
general procedure and tell you what to confirm, not fabricated Adobe menus.

## 2.1 Adobe Admin Console administrative access
Description: An administrator account for the Adobe Admin Console with rights to view and manage
users, product profiles, and assignments.
Why: Reading the seat inventory and reclaiming or reassigning seats requires administrative rights in
the console that holds the Adobe entitlements.
Verify: Sign in to the Adobe Admin Console and confirm the Products, Users, and (where present)
Insights or reporting areas load for your account.
Implement-if-missing: Have an existing System Administrator grant the least-privilege Adobe admin role
that covers user and product-profile management (for example a Product Profile Administrator or User
Group Administrator), reserving System Administrator for organization-wide changes. The exact role
names and grant procedure are deferred to Adobe's documentation.

## 2.2 Identity foundation confirmed
Description: A known, working identity type for the Adobe organization (for example federated identity
via an identity provider, enterprise-managed identities, or Adobe IDs) so that named users are
governed consistently.
Why: Named-user licensing ties each seat to an identity; you must know how users are created and
authenticated before you reconcile assignments, and a clean identity foundation makes reclamation
safe (you are removing the right person).
Verify: In the Admin Console, confirm the directory and identity type in use and that a sample user
resolves to the expected identity.
Implement-if-missing: Establish the identity type and directory per Adobe's official documentation
(identity setup and SSO are Adobe-owned and out of scope for this package). For SAM purposes you only
need it confirmed and stable, not changed.

## 2.3 Product profiles defined
Description: Product profiles configured for each purchased Adobe product so that assignment happens
through profiles rather than ad hoc.
Why: The product profile is the unit of assignment that consumes a seat; a clean profile structure is
what makes the seat inventory and right-sizing meaningful (all-apps versus single-app).
Verify: In the Admin Console under Products, confirm each purchased product has at least one product
profile and that the profile shows its quota of seats and entitled users or groups.
Implement-if-missing: Create one product profile per product (or per role, where a role needs a
distinct service set) and name it clearly; attach user groups rather than individuals where possible.
Profile creation specifics are deferred to Adobe's documentation.

## 2.4 Entitlement record (purchased seat counts)
Description: An authoritative record of how many seats of each Adobe product were purchased, with the
renewal date — see global requirement G3.
Why: Right-sizing and compliance are only possible against a known, authoritative purchased count;
without it you cannot tell over- from under-licensed.
Verify: You can state the purchased seat quantity and renewal date for at least one representative
Adobe product from your records.
Implement-if-missing: Capture current Adobe order or quote quantities and renewal dates into the
entitlement system of record (G3); reconcile against the Admin Console quota per profile.

## 2.5 Usage and activity data source
Description: A source of Adobe seat activity — preferably the Adobe User Management API (REST) for
assignment data, plus Admin Console usage or activity reporting, or an Admin Console CSV export.
Why: Reclaiming and right-sizing seats requires evidence that a seat is idle or over-provisioned;
assignment data alone is not enough without activity signal.
Verify: You can read assignment data through the Adobe User Management API, or you can export a users
and product-assignment CSV from the Admin Console; and you can identify a recent-activity or
last-active signal for a sample of users (from Adobe reporting where available).
Implement-if-missing: Enable and obtain credentials for the Adobe User Management API per Adobe's
official developer documentation, or schedule a recurring Admin Console CSV export. Where Adobe does
not expose a direct last-active field to you, substitute the best available activity report and note
the limitation in the right-sizing register. The exact API authentication flow is deferred to Adobe's
documentation.

## 2.6 API credentials and access (where the API is used)
Description: Credentials and authorization for the Adobe User Management API, stored securely.
Why: Programmatic, repeatable inventory and validation depend on authorized API access; manual exports
are a fallback.
Verify: A non-secret test call to the Adobe User Management API returns your organization's data; the
credentials are stored in a secret store or environment variables, not in the scripts.
Implement-if-missing: Register the integration and obtain credentials per Adobe's official developer
documentation, grant it the least privilege needed to read users and product assignments, and store
the secret outside source control. If API access is not available, operate the scripts in CSV mode
against an Admin Console export.

## 2.7 Pilot scope identified
Description: A representative subset to prove the process first — one product (for example the all-apps
profile), one department, or one office — see global requirement G7.
Why: Every solution is piloted before broad rollout to validate accuracy and avoid cutting off active
users.
Verify: A pilot scope and its data owner are named.
Implement-if-missing: Choose a high-value, well-understood scope (the all-apps profile is often the
best first pass because it carries the most cost per seat).

---
## Checklist
- [ ] Adobe Admin Console admin access (least privilege)
- [ ] Identity foundation confirmed and stable
- [ ] Product profiles defined per purchased product
- [ ] Entitlement record with purchased counts and renewal dates (G3)
- [ ] Usage and activity data source — User Management API or Admin Console CSV export
- [ ] Adobe User Management API credentials stored securely (where API is used)
- [ ] Pilot scope and data owner identified (G7)
