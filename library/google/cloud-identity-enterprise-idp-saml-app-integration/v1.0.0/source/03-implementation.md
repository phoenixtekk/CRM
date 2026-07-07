# Implementation

This guide builds the SAML app-integration factory following the house model
**Assess → Design → Configure → Pilot → Validate → Expand**. Every artifact is named with the
convention `<Purpose> – <Scope> – <Stage>` and reused verbatim in later steps, testing, and the
tools. **All production changes are pilot-first with a documented rollback and an explicit pass/fail
gate.**

Google Admin console paths are current as of authoring; menu labels occasionally move — where a label
differs, **verify the equivalent in your tenant**. Third-party app (SP) console steps are deferred to
each vendor's documentation.

---

## Stage 0 — Assess (read-only)

**Goal:** know the estate and each app's SSO/provisioning readiness before changing anything.

1. **Inventory the SaaS estate.** Assemble the app list from CASB/CMDB/finance sources plus the OAuth
   token audit in **admin.google.com → Security → API controls → App access control** and (if licensed)
   the Workspace **investigation/login audit** logs. Record each app and a business owner.
2. **Run the readiness assessment (Tool 1).**
   `python sso_readiness_assessment.py --apps apps.csv --out readiness.json`
   It reports, per app, the declared auth method, whether SSO/SCIM is claimed, and the owner — a
   read-only baseline. It never changes configuration.
3. **Seed the catalog.** Create **`App Catalog – Federated SaaS – v1`** (a spreadsheet or IGA record)
   with columns: app, type (SAML/OIDC/unknown), NameID format, attribute map, assigned group,
   provisioning method (auto/JIT/manual), owner, IdP-cert expiry, onboarding date, status.
4. **Confirm the assignment groups exist and are governed** (Requirement 2): each app will map to an
   `Assignment Group – <App> – Users` populated from your source of truth, not hand-edited.

**Gate 0 (pass/fail):** a seeded `App Catalog – Federated SaaS – v1`, each app owned, and the pilot
cohort (`Pilot Cohort – SSO Factory – Pilot`) confirmed. **Fail →** do not proceed until the inventory
and pilot exist.

---

## Stage 1 — Design the onboarding pattern

**Goal:** one documented, repeatable pattern every app will follow.

1. **Author `SSO Onboarding Pattern – SaaS – v1`** — the standard checklist (this becomes the runbook):
   1. Collect the app's **SP metadata** (ACS/Reply URL, Entity ID/audience, NameID format; for OIDC:
      redirect URIs, required scopes).
   2. Create the app in Google (prebuilt catalog entry **or** `Custom SAML App – <App> – v1`).
   3. Exchange metadata/certificate both directions.
   4. Define **`Attribute Map – <App> – v1`** (NameID → primary email by default; add `email`, given/
      family name, and a **groups** claim only where the app consumes it).
   5. Configure **provisioning** (Google auto-provisioning or the app's SCIM endpoint) where supported.
   6. **Assign by group** — turn the app ON for `Assignment Group – <App> – Users` only.
   7. Test against `Pilot Cohort – SSO Factory – Pilot`; record the result.
   8. Record the integration in `App Catalog – Federated SaaS – v1`.
2. **Set standards** in the pattern: default **NameID = primary email (persistent)**; a fixed attribute-
   naming convention; a rule that access is **group-only**; and a **certificate-rotation** entry for
   every app (track Google's IdP signing-cert expiry per app).
3. **Decide SAML vs OIDC per app** by what the SP supports (prefer the app's recommended method; both
   are first-class in Google's app catalog). The pattern steps are identical; only token format differs.

**Gate 1:** `SSO Onboarding Pattern – SaaS – v1` is written, reviewed by security (Global Requirement 6),
and names the attribute, NameID, group-only, and cert-rotation standards. **Fail →** finish the pattern
before configuring apps.

---

## Stage 2 — Configure a pilot set of apps

**Goal:** integrate a small **representative** pilot set (aim for 3–5 apps spanning: a prebuilt-catalog
SAML app, a custom SAML app, an OIDC app, and one app with SCIM auto-provisioning) by running the
pattern for each. Do all of this against the pilot only.

### 2a. Prebuilt-catalog SAML app (the common case)

1. In **admin.google.com → Apps → Web and mobile apps → Add app → Search for apps**, select the app.
   Google pre-populates much of the SAML configuration.
2. On the **Google Identity Provider details** step, note the **SSO URL, Entity ID, and Certificate**
   (download IdP metadata). Provide these to the app's SSO settings **in the app's own console** (vendor
   docs). Paste the app's **ACS URL and Entity ID** back into Google.
3. Configure **`Attribute Map – <App> – v1`**: set **Name ID = Basic Information > Primary email**,
   format **EMAIL** (unless the app requires a different NameID — verify in the app's docs). Map any
   additional attributes the app requires.
4. **Do not turn the app ON for everyone.** On **User access**, turn it **ON only for**
   `Assignment Group – <App> – Users` (or the pilot OU). Save.

### 2b. Custom SAML app (`Custom SAML App – <App> – v1`)

1. **Add app → Add custom SAML app.** Name it exactly `Custom SAML App – <App> – v1`.
2. Copy Google's **SSO URL, Entity ID, Certificate** (or download metadata) into the app's SSO config.
3. Enter the app's **ACS URL** and **Entity ID**; set **Name ID format** and **Name ID** per
   `Attribute Map – <App> – v1`; add attribute mappings.
4. Set **User access** ON only for `Assignment Group – <App> – Users`. Save.

### 2c. OIDC app

1. Add the app from the catalog (or per the app's OIDC integration guide). Provide the app's **redirect
   URIs** and the scopes it requires; consent to the OAuth client as directed.
2. Assign by group exactly as above (`Assignment Group – <App> – Users`).

### 2d. Provisioning (where supported)

1. If the app appears with **Auto-provisioning** in Google (Apps → the app → **Auto-provisioning**),
   enable it, authorize the connection, and map attributes; **scope provisioning to
   `Assignment Group – <App> – Users`** so only assigned users are provisioned/deprovisioned.
2. If the app uses its **own SCIM endpoint**, generate a SCIM token in the app and configure the
   provisioning connection per the app's docs; scope to the same assignment group.
3. Record the method (auto / SCIM / JIT / manual) in the catalog. **Availability of Google
   auto-provisioning is per-app — verify it exists for your app before designing around it.**

**Gate 2:** each pilot app is created, attribute-mapped, assigned to its group only, and (where
supported) provisioning-enabled — with **nothing turned on for the full audience yet**.

---

## Stage 3 — Pilot & validate

**Goal:** prove each pilot integration against real pilot users before expanding.

1. Ensure pilot users are members of the relevant `Assignment Group – <App> – Users` (via your source
   of truth). Add a test user to the pilot cohort where needed.
2. **SP-initiated and IdP-initiated SSO:** from the app's login page (SP-init) and from the user's
   Google **apps** launcher (IdP-init, where the app supports it), sign in and confirm access.
3. **Provisioning check:** add a test user to the assignment group; confirm the account is created in
   the app (auto/SCIM). Remove them; confirm deactivation. (See Testing for exact procedures.)
4. **Run the validation report (Tool 3).**
   `python sso_validation_report.py --catalog catalog.csv --out validation.html`
   It reconciles the catalog against directory group membership and flags apps missing an assignment
   group, missing an owner, missing a provisioning method, or with an IdP cert nearing expiry.
5. **Run the guardrail check (Tool 4).**
   `python assignment_guardrail_check.py --catalog catalog.csv`
   It flags policy violations: an app assigned to **All users / an OU instead of a group**, an app with
   **no group**, over-broad group assignment, or a NameID not matching the standard.

**Gate 3 (the pilot gate):** for every pilot app — SSO succeeds (SP- and IdP-initiated), provisioning
create+deactivate works where enabled, assignment is **group-driven** (guardrail clean), and the
validation report is green. **Fail →** fix and re-test; do **not** expand a failing app.

### Rollback (documented, per app)

If an app fails validation or causes a production issue after turn-on:

1. In **Apps → Web and mobile apps → <app> → User access**, set the app **OFF** (or scope back to the
   pilot group) — this immediately stops Google issuing assertions/tokens to that app.
2. If provisioning misbehaved, **disable auto-provisioning / SCIM** for the app so no further account
   changes are pushed; reconcile any accounts already changed with the app owner.
3. Users fall back to the app's prior sign-in method (local login or previous IdP) **only if** it is
   still enabled in the app — confirm the fallback exists **before** turn-on, and keep it until the app
   passes Gate 3. Record the rollback outcome in the catalog.

---

## Stage 4 — Expand the factory across the estate

**Goal:** run the proven pattern across the remaining apps, one app per change window.

1. For each remaining app, execute `SSO Onboarding Pattern – SaaS – v1` end to end (Stages 2–3),
   integrating and validating against the pilot cohort **before** turning the app on for its full
   `Assignment Group – <App> – Users`.
2. **Turn on for the full audience only after Gate 3 passes** for that app, inside an approved change
   window (Global Requirement 5). Update `App Catalog – Federated SaaS – v1` (status → live, onboarding
   date, cert expiry).
3. **Batch by owner/risk:** low-risk, high-value apps first; regulated-data apps only after security/
   compliance sign-off (Global Requirement 6).
4. **Operationalize the catalog with the config helper (Tool 5).**
   `python catalog_config_helper.py --catalog catalog.csv --new-app "<App>" --type saml`
   It appends a correctly-shaped catalog row and emits the onboarding checklist for the new app so every
   integration is recorded consistently.
5. **Schedule certificate rotation** from the catalog's cert-expiry column; rotate Google's IdP signing
   certificate and update each affected app's SP config before expiry (never after).

**Gate 4 (steady state):** every live app is in the catalog with an owner, an assignment group, a
provisioning method, and a tracked cert expiry; the guardrail check runs clean across the estate; and
new apps are onboarded only through `SSO Onboarding Pattern – SaaS – v1`.
