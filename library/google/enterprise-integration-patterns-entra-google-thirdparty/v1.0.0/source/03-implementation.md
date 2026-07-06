# 3. Implementation Guide — The Reference Integration Patterns

This is the catalog. Each pattern names its **intent**, **authN**, **authZ**, **data access**, the
**standard** to hold to, and the **anti-pattern** to avoid. The pattern names (P1–P7) are used
throughout the other guides and in the Integration-Patterns reference doc.

> Model: inventory the estate → classify each integration against the catalog → pilot the target
> patterns on the scoped app set → validate conformance → expand, tracking exceptions. Every change is
> staged, validated on a pilot, and reversible.
>
> **Vendor boundary.** The **Entra** side is authored from Microsoft's public docs; the **Google
> Admin console / Cloud Identity** side from Google's public docs. **Third-party enterprise-app
> internals** (ServiceNow, SAP, Databricks, …) are integrated **at the pattern level** — the recommended
> authN/authZ/data-access approach — and their exact console steps and current capabilities are
> **deferred to the vendor's own documentation and verified in your tenant**.

---

## Step 0 — Inventory and classify (do this first)
1. Run `GWINTEG-Discovery.ps1` to inventory the **Entra-side** estate: SSO/federation apps,
   provisioning (SCIM synchronization) jobs, service principals, app-role assignments, delegated
   OAuth grants, and credentials.
2. On **Google**, record the SSO profile(s) under `Security → Authentication → SSO with third-party
   IdP` and any provisioning/GCDS in use.
3. For each **third-party app** in scope, record its SSO protocol and provisioning mechanism into the
   capability matrix (Requirement 2.5) — verified from the vendor's docs.
4. Run `GWINTEG-Report.ps1` to produce the coverage/exception view: which integrations match a
   catalog pattern and which are snowflakes.

---

## Section A — Entra ID ↔ Google Workspace

### P1 — Entra-as-IdP → Google (SAML SSO)
- **Intent:** Entra ID federates user sign-in to Google Workspace / Cloud Identity so users
  authenticate once against the enterprise IdP.
- **AuthN:** SAML 2.0. In Entra, add the **"Google Cloud / Google Workspace"** gallery application and
  configure SAML SSO. In the **Google Admin console** → `Security → Authentication → SSO with
  third-party IdP → Third-party SSO profiles → Add SAML profile`, paste Entra's IdP metadata; Google
  presents the ACS URL and Entity ID that Entra must return.
- **AuthZ:** Google authorization (OU/group membership, admin roles) is decided in Google; the SAML
  assertion authenticates, it does not authorize Google admin. Keep the **NameID** aligned to the
  Google primary domain — if the Entra domain differs, map the NameID claim to a value that matches the
  verified Google domain.
- **Data access:** none directly — this is sign-in federation.
- **Standard:** the Google domain is **verified in Entra**; NameID matches the Google identity; SSO is
  piloted on an OU before org-wide enforcement.
- **Anti-pattern:** enabling SSO org-wide without a break-glass Google super-admin path, or a NameID
  that does not match the Google domain (users cannot sign in).

### P2 — Entra → Google provisioning (SCIM push)
- **Intent:** Entra ID is the source of truth; it creates, updates, and de-provisions Google users and
  groups automatically.
- **AuthN/mechanism:** SCIM. In the same gallery app, configure **Provisioning** (SCIM). On Google,
  enable the SCIM/provisioning endpoint and authorize Entra (a Google admin identity for the
  connection). Assign users/groups to the app to bring them into scope; start provisioning.
- **AuthZ:** attribute mappings decide what Entra writes to Google (including OU placement where
  mapped); scope provisioning by assignment or scoping filter so only intended users flow.
- **Data access:** directory objects only, over SCIM.
- **Standard:** one source of truth (Entra) for the objects it masters; **SCIM push (P2)** and **GCDS
  pull (P3)** are not both used for the same object.
- **Anti-pattern:** SCIM push **and** GCDS pull mastering the same users — they fight and drift.

### P3 — AD-source provisioning (GCDS pull)
- **Intent:** where **on-prem Active Directory / LDAP remains the source of truth**, Google is
  populated by pulling from that directory.
- **Mechanism:** **Google Cloud Directory Sync (GCDS)** reads AD/LDAP and syncs users/groups into
  Google on a schedule.
- **AuthZ:** GCDS mapping rules decide which OUs/attributes flow.
- **Standard:** use P3 when AD/LDAP is authoritative; use P2 when **Entra** is authoritative. Pick one
  per object, never both.
- **Anti-pattern:** running GCDS against objects that Entra also pushes via SCIM (two masters).

*JIT note:* SAML **just-in-time** creation makes a Google user on first SSO. Treat JIT as a
convenience, not the source of truth — for lifecycle (especially **de-provisioning**), use P2 or P3 so
leavers are actually removed.

---

## Section B — M365 ↔ Google coexistence

### P4 — Coexistence identity (single source of truth)
- **Intent:** keep authentication and provisioning consistent while M365 and Google run side by side.
- **AuthN:** one enterprise IdP owns sign-in for each workload (commonly Entra ID during a Google
  transformation); relying parties on both sides federate to it (P1/P5).
- **Provisioning:** one authoritative directory, synchronized into the other ecosystem (P2/P3), so an
  object exists once and flows out — never mastered in both.
- **Data access:** governed by each ecosystem's own controls; the coexistence layer keeps **identity**
  consistent, not data merged.
- **Standard:** a documented **cutover order** per workload — identity → SSO → provisioning →
  mail/data — under change control.
- **Anti-pattern:** undocumented coexistence — no defined IdP owner or cutover order — so SSO,
  provisioning, or mail flow breaks mid-transition.

---

## Section C — Third-party enterprise apps

> **The pattern is the deliverable here.** For each app, the recommended authN/authZ/data-access
> approach below is the guidance; the **exact console steps and current capabilities are the vendor's
> and must be verified** (Requirement 2.5). Capabilities change — treat any specific claim as
> "verify in the vendor's current docs and your tenant."

### P5 — Third-party app SSO (federated SAML/OIDC)
- **Intent:** enterprise apps authenticate users against the chosen IdP — no local app passwords.
- **AuthN:** SAML 2.0 or OIDC to the IdP. Prefer the app's **gallery/marketplace integration** on the
  IdP where one exists.
- **AuthZ:** carry roles/entitlements in the assertion or token — **group or claim-driven** — so app
  authorization follows directory groups, not per-user local admin.
- **Standard:** federated SSO for every app that supports it; roles from groups/claims; least-privilege
  app roles.
- **Anti-pattern:** local app accounts with their own passwords (a snowflake and a credential-sprawl risk).

### P6 — Third-party app provisioning (SCIM / connector)
- **Intent:** create, update, and de-provision app accounts automatically from the source of truth.
- **Mechanism:** **SCIM** from the chosen IdP where **both the IdP and the app support it**; otherwise
  the app's **supported connector** or import (e.g. a SOAP/API-based provisioning integration).
- **AuthZ:** map groups → app roles so entitlements follow directory membership; de-provision on leave.
- **Standard:** automated lifecycle with de-provisioning; group-to-role mapping; scoped provisioning.
- **Anti-pattern:** manual account creation and, worse, **no de-provisioning** — leavers keep access.

### Per-app pattern application (verify each in vendor docs + your tenant)
- **ServiceNow** — **P5:** SAML 2.0 SSO to the IdP (multi-provider SSO supported). **P6:** provisioning
  approach must be **verified** — SCIM support from a given IdP has changed over time and some
  configurations require the app's supported (e.g. SOAP/API) provisioning instead; do not assume SCIM.
  Roles map from groups → ServiceNow roles.
- **SAP** — **P5:** SAML 2.0 / OIDC federation, commonly fronted by the customer's SAP identity/BTP
  identity service brokering to the enterprise IdP; **verify the exact brokering topology** for the SAP
  products in scope. **P6:** provisioning via the app's supported mechanism. **P7:** API/data access via
  OAuth to SAP APIs with scoped clients.
- **Databricks** — **P5:** SAML 2.0 **or** OIDC SSO to the IdP (both supported). **P6:** **SCIM**
  provisioning from the IdP; **JIT** on first SSO is on by default for newer accounts — **verify** the
  behavior for your workspace/account age. Roles/groups map to Databricks entitlements.

---

## Section D — API & data access (cross-cutting)

### P7 — API / data access (OAuth workload identity)
- **Intent:** services, automations, and data pipelines authenticate to each other and to data without
  standing shared secrets.
- **AuthN:** **OAuth 2.0 client-credentials** or **workload identity federation** (an external workload
  presents a trusted token and exchanges it for short-lived access — no stored secret); **scoped service
  accounts** where a service identity is required.
- **AuthZ:** least-privilege scopes / roles for exactly the APIs and data the integration uses.
- **Data access:** through the granted scopes only; prefer read-only where the integration only reads.
- **Standard:** short-lived, federated credentials; least-privilege scopes; a named owner per identity.
- **Anti-pattern:** **credential sprawl** — shared service accounts, long-lived secrets, passwords in
  scripts, or `*.ReadWrite.All`-style scopes granted "to be safe."

---

## Step N — Pilot, validate, expand
1. **Pilot** the target patterns on the scoped app set (Requirement 2.9): the Entra↔Google trust
   (P1/P2 or P3) plus one third-party app (P5/P6) and one data path (P7).
2. **Validate** conformance with `GWINTEG-Validation.ps1` and the Testing Guide gates.
3. **Remediate** snowflakes with `GWINTEG-Remediation.ps1` (preview `-WhatIf` first, confirm with the
   app owner, then apply to the reviewed integration only).
4. **Expand** across the estate in batches, re-running `GWINTEG-Discovery.ps1` and `GWINTEG-Report.ps1`
   on a cadence so new integrations are classified as they appear; record every deliberate exception.

---
### Order of operations
`Inventory + classify → target patterns + standards → pilot (Entra↔Google + one app + one data path)
→ validate conformance → remediate snowflakes → expand, tracking exceptions`

### Rollback
- **P1 SSO:** disable the Google third-party SSO profile / disable the Entra SSO app — sign-in reverts
  to Google-native or the prior IdP. Keep a break-glass Google super-admin outside SSO.
- **P2 SCIM:** stop provisioning in the Entra app — existing objects remain; no new writes.
- **P5/P6 app:** disable the app's federation/provisioning to revert to its prior auth; every pattern
  change is piloted and reversible before estate-wide expansion.
