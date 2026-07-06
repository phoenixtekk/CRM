# 1. Solution Overview — Enterprise Integration Patterns (Entra ID ↔ Google + M365 Coexistence + Third-Party Apps)

## Why a pattern catalog, not a pile of connectors
During a Google Workspace transformation, identity does not sit still. Users, groups, apps, and data
have to keep working across **Microsoft Entra ID**, **Google Workspace / Cloud Identity**, the
**Microsoft 365** systems still live during coexistence, and a long tail of **third-party enterprise
apps** (ServiceNow, SAP, Databricks, and more). The failure mode is predictable: every team that
needs an integration builds its own — a one-off SAML app here, a hand-rolled sync there, a service
account with a permanent password somewhere else. The result is a **snowflake estate**: inconsistent
authentication, ad-hoc authorization, credential sprawl, and coexistence gaps that nobody owns.

This solution answers that with a **pattern catalog**: a small, named set of reference integration
designs that every new integration is expected to conform to. Instead of deciding authentication and
authorization app-by-app, an architect picks the matching pattern and applies it. Consistency becomes
the default, exceptions become visible and few, and the estate scales through the transformation and
beyond.

> This is an **architecture / governance** product. It defines the reference patterns, the standards,
> and the anti-patterns, and ships scripts that inventory the estate and check conformance. It is not
> a click-by-click configuration guide for any single app — third-party enterprise-app internals are
> integrated **at the pattern level** and their console steps are deferred to the vendor's own docs.

## The five integration dimensions
Every integration in the estate is described by where it sits on five dimensions. The catalog names a
recommended pattern for each.

1. **Identity federation** — who is the identity provider (IdP) and who is the relying party (SP/RP),
   and over what protocol (SAML 2.0 or OIDC). During a Google transformation, Entra ID is commonly the
   enterprise IdP and Google Workspace a relying party, but the direction can invert per workload.
2. **Provisioning** — how accounts and groups are created, updated, and de-provisioned across
   directories: **SCIM** push (Entra → Google via the gallery app), **GCDS** pull (AD/LDAP → Google),
   and **just-in-time (JIT)** creation on first SSO. Choose one authoritative source per object.
3. **App SSO (SAML / OIDC)** — how enterprise apps authenticate users. The pattern names the IdP,
   the protocol, and how roles/entitlements flow (claims/groups).
4. **API & data access** — how services and automations authenticate to each other and to data:
   OAuth 2.0 client-credentials / workload identity federation, service accounts, and least-privilege
   scoping — never long-lived shared secrets by default.
5. **Coexistence** — how identity and access stay consistent while M365 and Google run side by side:
   one source of truth, synchronized identities, and a defined cutover order per workload.

## Reference patterns in this catalog
Each is named once and reused throughout the guides:

- **P1 — Entra-as-IdP → Google (SAML SSO)**: Entra ID federates sign-in to Google Workspace / Cloud
  Identity via the "Google Cloud / Google Workspace" gallery application.
- **P2 — Entra → Google provisioning (SCIM push)**: Entra ID provisions and de-provisions users and
  groups into Google via SCIM using the same gallery app.
- **P3 — AD-source provisioning (GCDS pull)**: where on-prem Active Directory / LDAP remains the
  source of truth, Google Cloud Directory Sync pulls objects into Google.
- **P4 — Coexistence identity (single source of truth)**: one authoritative directory, synchronized
  to the other ecosystem, with a per-workload cutover so authentication stays consistent during
  overlap.
- **P5 — Third-party app SSO (federated SAML/OIDC)**: enterprise apps federate to the chosen IdP over
  SAML or OIDC, with roles carried in claims/groups — no local passwords.
- **P6 — Third-party app provisioning (SCIM / connector)**: lifecycle into the app via SCIM where the
  app and IdP support it, or the app's supported connector where they do not.
- **P7 — API / data access (OAuth workload identity)**: service-to-service and data access via OAuth
  client-credentials / workload identity federation and scoped service accounts, not shared secrets.

## Anti-patterns the catalog exists to kill
- **Per-app snowflakes** — every app authenticated a different way, with no reuse.
- **Credential sprawl** — shared service accounts, long-lived secrets, and passwords in scripts.
- **Two sources of truth** — an object mastered in both directories, so they drift and conflict.
- **Over-broad authorization** — app roles and API scopes granted far beyond what the integration
  uses, expanding blast radius.
- **Undocumented coexistence** — no defined cutover order, so mail, SSO, or provisioning breaks mid-transition.

## What you can control
- **Inventory** — every federation trust, SSO app, provisioning connection, and service credential
  across Entra, Google, and the third-party apps in scope.
- **Conformance** — whether each integration matches a catalog pattern, and where the exceptions are.
- **Standards** — the consistent authN (federated SSO), authZ (claims/group-driven, least privilege),
  and data-access (scoped OAuth / workload identity) approach applied everywhere.
- **Coexistence** — one source of truth, synchronized, with a documented cutover per workload.

## Benefits
- **Consistency** — one way to connect Google, Microsoft, and everything else; new integrations reuse
  a pattern instead of inventing one.
- **Security** — federated SSO removes local passwords, least-privilege scoping bounds blast radius,
  and credential sprawl is designed out.
- **Visibility** — a real inventory and a conformance/exception view, so snowflakes are caught early.
- **Scale** — the estate grows through the transformation without the connector count becoming chaos.

## Limitations (be honest with buyers)
- This is a **pattern and governance** product. It standardizes and inventories; it does not replace
  each vendor's own configuration documentation for the app internals.
- **Third-party app capabilities vary and change.** Whether a given app supports SCIM from a given IdP,
  or only SAML, or only a legacy connector, must be **verified in the vendor's current docs and your
  tenant** — the catalog names the pattern; the app decides what it supports.
- Some Entra provisioning and conditional-access capabilities require **Entra ID P1/P2** licensing
  (see Requirements).
- The scripts inventory and check conformance on the **Microsoft/Entra side** via Microsoft Graph
  (read-only); Google-side and third-party-side state is confirmed in those consoles.

## The standard deployment model
> Inventory the integration estate → classify each integration against the catalog patterns →
> define the target patterns and standards → pilot the target patterns on a scoped set of apps →
> validate conformance → expand across the estate, tracking exceptions. Repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand.**
