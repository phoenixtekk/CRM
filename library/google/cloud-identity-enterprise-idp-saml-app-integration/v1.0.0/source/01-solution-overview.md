# Solution Overview — Cloud Identity as Enterprise IdP: SAML App Integration Factory

## What this is

In a Google-first enterprise, **Cloud Identity / Google Workspace becomes the identity provider (IdP)**
for the whole SaaS estate — hundreds of third-party applications that employees sign in to every day
(Salesforce, ServiceNow, Slack, Workday, Atlassian, Zoom, Box, and long-tail line-of-business apps).
Federating each of those apps to Google single sign-on (SSO) one app at a time — hand-crafting the SAML
metadata, wiring up provisioning, deciding who gets access — is slow, inconsistent, and hard to audit.

This solution builds a **repeatable SAML/OIDC app-integration factory**: one standard onboarding
pattern applied to every app, **group-based app assignment** driven from your directory, **automatic
user provisioning** where the app supports it (SCIM / Google auto-provisioning connectors), and an
**app catalog + runbook** that captures each integration's configuration and owner. The result is that
new apps federate to Google SSO **fast, consistently, and securely**, and the whole program is
governed from one place.

> **Scope boundary.** This is **Google-as-IdP for third-party SaaS** — Google Cloud Identity /
> Workspace issuing SAML assertions and OIDC tokens to downstream apps. It is **distinct** from
> inbound Entra↔Google federation (making Microsoft Entra ID trust Google, or vice-versa, for
> workforce identity). Where an app's own admin console is involved, its internal click-paths are
> deferred to that vendor's documentation; the Google Admin side is authored at exact detail.

## How it works

The Google Admin console (**admin.google.com → Apps → Web and mobile apps**) is the control plane.
For each app you either pick it from the **prebuilt SAML/OIDC app catalog** Google curates (thousands
of apps with tested, semi-templated configuration) or add a **custom SAML app** when the app isn't in
the catalog. Google issues signed SAML assertions (or OIDC ID tokens) to the app; the app trusts
Google as its IdP.

Four building blocks make this a *factory* rather than a pile of one-off integrations:

1. **A standard onboarding pattern.** Every app follows the same ordered checklist — collect the app's
   SP metadata, create the app in Google, exchange metadata/certificates, map attributes (NameID,
   email, groups), configure provisioning, assign by group, test, and record it in the catalog. The
   pattern is identical whether the app is SAML or OIDC; only the token format differs.
2. **Group-based app assignment.** Access to each app is turned **ON for specific Google Groups /
   organizational units (OUs)**, never per-user. Group membership (sourced from your directory / HR /
   IGA system per Global Requirement 4) becomes the single lever that grants or revokes app access —
   the same lever your joiner-mover-leaver process already moves.
3. **Automatic provisioning where supported.** For apps that support it, Google **auto-provisioning**
   (or the app's SCIM endpoint) creates, updates, and deactivates the user's account *in the app* when
   they're added to / removed from the assigned group — so access and account lifecycle stay in sync.
   Not every app supports auto-provisioning; the catalog records which do.
4. **An app catalog + runbook.** A living inventory of every federated app: its type (SAML/OIDC),
   NameID format, attribute mappings, assigned groups, provisioning method, business owner, and
   onboarding date. The catalog is the audit surface and the onboarding template for the next app.

## Reference design

Named artifacts (reused verbatim throughout the guide, testing, and scripts):

- **`SSO Onboarding Pattern – SaaS – v1`** — the standard, documented onboarding checklist every app
  follows (the "factory line").
- **`App Catalog – Federated SaaS – v1`** — the master inventory (a spreadsheet or IGA record) of every
  app, its config, owner, and provisioning method.
- **`Assignment Group – <App> – Users`** — the Google Group whose membership grants access to a given
  app (e.g. `Assignment Group – Salesforce – Users`). One per app (or per access role within an app).
- **`Pilot Cohort – SSO Factory – Pilot`** — a small OU/group of pilot users used to validate every new
  integration before the app is turned on for its full audience.
- **`Custom SAML App – <App> – v1`** — the Google Admin app object for an app added as a custom SAML app
  (not in the prebuilt catalog).
- **`Attribute Map – <App> – v1`** — the documented NameID + attribute/group mapping for an app.

Flow: **Directory / HR-IGA (source of truth)** → **Google Cloud Identity / Workspace (IdP)** →
signed SAML assertion / OIDC token → **third-party SaaS app (SP)**, with the assigned Google Group
driving both **who sees the app** and **who gets provisioned into it**.

## Benefits

- **Speed:** a standard pattern turns app onboarding from a bespoke project into a repeatable checklist
  a competent identity engineer can run in a scheduled change window.
- **Consistency:** every app is configured the same way (NameID format, attribute mapping, group
  assignment, provisioning), so the estate is predictable and auditable.
- **One access lever:** group-based assignment ties app access to directory group membership, so
  joiner-mover-leaver automatically grants and revokes SaaS access.
- **Lifecycle sync:** auto-provisioning keeps the app's user accounts in step with directory reality —
  reducing orphaned accounts and license waste.
- **Governance:** the catalog is a single evidence surface for access reviews, SOX/ISO audits, and
  offboarding verification.

## Limitations & boundaries

- **App SP configuration is vendor-specific.** Each app's own admin console (where you paste Google's
  IdP metadata and enable SCIM) differs; those steps are deferred to the app vendor's documentation.
  This solution standardizes the **Google side** and the **process**.
- **Not every app supports auto-provisioning.** SCIM / Google auto-provisioning availability varies by
  app and license tier; the catalog records the method (auto, JIT, or manual) per app.
- **Edition/feature dependence.** Some capabilities (e.g. context-aware access on app sign-in via
  **BeyondCorp Enterprise**, advanced session controls) depend on Workspace/Cloud Identity edition and
  may be preview or add-on features — **verify availability in your tenant** before designing them in.
- **Directory source of truth is a prerequisite, not built here.** Group membership must be governed
  upstream (Global Requirement 4). This solution consumes groups; it does not define your HR/IGA sync.
- **Regulatory determinations are deferred.** Which apps may hold regulated data, and any legal-hold or
  residency constraints, are decided by your security/compliance functions (Global Requirement 6).

## Deployment model

This solution follows the house model: **Assess → Design → Configure → Pilot → Validate → Expand**,
pilot-first, with explicit pass/fail gates and a documented rollback for any production change.

- **Assess** — inventory the SaaS estate, each app's SSO/provisioning readiness, and current access.
- **Design** — define `SSO Onboarding Pattern – SaaS – v1`, attribute-mapping standards, and naming.
- **Configure** — stand up the pattern and integrate a **pilot set** of representative apps.
- **Pilot** — validate SSO, provisioning, and group assignment against `Pilot Cohort – SSO Factory –
  Pilot` before turning any app on for its full audience.
- **Validate** — run the validation gates (SSO works, provisioning correct, assignment group-driven).
- **Expand** — run the factory across the estate, one app per change window, recording each in
  `App Catalog – Federated SaaS – v1`.
