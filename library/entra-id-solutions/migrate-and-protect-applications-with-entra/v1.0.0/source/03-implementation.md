# 3. Implementation Guide — Migrate & Protect Applications with Entra

Follow these steps **in order**, in the **Microsoft Entra admin center** (`https://entra.microsoft.com`).
Names in `code` are the exact objects to create — keep them consistent so the scripts, testing, and
troubleshooting all refer to the same objects. Portal blade names evolve; if a label differs, match by
intent and verify against current Microsoft guidance.

**Object naming convention:** `ENTAPPMIG – <Purpose> – <Scope> – <Stage>`. The objects you will build:

| Object | Name |
|--------|------|
| Pilot user group | `ENTAPPMIG-Pilot` |
| Migrated AD FS app (enterprise app) | `ENTAPPMIG – App – LOBSaml – Pilot` |
| Application Proxy connector group | `ENTAPPMIG – ConnectorGroup – OnPrem` |
| Published on-prem web app | `ENTAPPMIG – AppProxy – Intranet – Pilot` |
| SCIM-provisioned app (enterprise app) | `ENTAPPMIG – App – ScimSaaS – Pilot` |
| Conditional Access (migrated apps) | `ENTAPPMIG – CA – MigratedApps – Pilot` |
| Access review (migrated apps) | `ENTAPPMIG – Review – MigratedApps – Quarterly` |

> **Model:** Assess → Configure → Pilot → Validate → Expand. Build each object, scope it to
> **`ENTAPPMIG-Pilot`** first, prove the gates in §5, then cut over and expand in waves. Keep **AD FS live**
> as fallback until each relying party is validated on Entra. Every cutover has a rollback (see end of file).

## Step 1 — Assess and build the migration plan
1. Run **`ENTAPPMIG-Discovery.ps1`** — inventories AD FS relying parties (from an AD FS server where
   reachable), the **AD FS application activity** report, existing Entra enterprise apps, and App Proxy
   connector groups. This is your starting map.
2. In Entra → **Identity → Applications → Usage & insights → AD FS application activity**, review each
   relying party's usage and **migration readiness**. Prioritize the plan by real usage.
3. Pick the **pilot apps**: one AD FS relying party (`ENTAPPMIG – App – LOBSaml – Pilot`), one on-prem web
   app (`ENTAPPMIG – AppProxy – Intranet – Pilot`), and one SCIM-capable SaaS app
   (`ENTAPPMIG – App – ScimSaaS – Pilot`). Confirm `ENTAPPMIG-Pilot` exists with test users.

## Step 2 — Recreate the AD FS relying party as an Entra enterprise app
1. **Identity → Applications → Enterprise applications → + New application.** From the gallery pick the
   app if listed, otherwise **+ Create your own application → Non-gallery**. Name it
   `ENTAPPMIG – App – LOBSaml – Pilot`.
2. **Single sign-on → SAML** (or OIDC if the app uses it). Set:
   - **Identifier (Entity ID)** = the exact value from the AD FS relying party (Requirement 2.3).
   - **Reply URL (ACS)** = the app's assertion consumer service URL(s).
   - **Sign-on URL / relay state** as needed.
3. **Attributes & Claims** — reproduce the AD FS **claim rules** as Entra **claims mapping** (NameID
   format, and each attribute the app expects). Flag any complex transform for extra work.
4. **SAML signing certificate** — download the Entra federation metadata / certificate to hand to the app
   owner for the cutover.
5. **Users and groups → + Add:** assign **`ENTAPPMIG-Pilot`** only (pilot-first).

## Step 3 — Deploy Application Proxy connectors
1. **Identity → Applications → Application proxy → Download connector service.** Install it on the
   connector host (Requirement 2.5) and sign in with an application admin.
2. Confirm the connector shows **Active**; install a **second** connector for HA.
3. **Application proxy → Connector groups → + New connector group**, name
   `ENTAPPMIG – ConnectorGroup – OnPrem`, and assign both connectors.

## Step 4 — Publish the on-prem web app via Application Proxy
1. **Enterprise applications → + New application → On-premises application** (Application Proxy).
2. **Basics:** Name `ENTAPPMIG – AppProxy – Intranet – Pilot`; **Internal URL** = the app's internal
   address; **External URL** = your published address; **Pre-authentication = Microsoft Entra ID**;
   **Connector group** = `ENTAPPMIG – ConnectorGroup – OnPrem`.
3. **Single sign-on** — set the mode the app needs (e.g. **Integrated Windows Authentication (KCD)**,
   **Header-based**, or **Password-based**).
4. **Users and groups → + Add:** assign **`ENTAPPMIG-Pilot`**.
5. Browse the **External URL** as a pilot user — you should be pre-authenticated by Entra and land on the
   app **without a VPN**.
   > **Alternative publishing path:** for non-web/TCP apps or full ZTNA, publish via **GSA Private Access**
   > instead (see the *Entra Global Secure Access* solution). App Proxy is for **web** apps with browser SSO.

## Step 5 — Integrate a SaaS app and configure SCIM provisioning
1. **Enterprise applications → + New application →** add the SaaS app (gallery or non-gallery). Name it
   `ENTAPPMIG – App – ScimSaaS – Pilot`. Configure **SSO (SAML/OIDC)** as in Step 2.
2. **Provisioning → Get started → Provisioning Mode = Automatic.**
3. **Admin Credentials:** enter the app's **SCIM base URL** + **secret token** (Requirement 2.6);
   **Test connection** must succeed.
4. **Mappings** — confirm/adjust the attribute mappings (which Entra attributes flow to the app).
5. **Settings → Scope = Sync only assigned users and groups**; assign **`ENTAPPMIG-Pilot`**.
6. **Provision on demand** for one pilot user to prove create/update works before turning the job on.

## Step 6 — Protect the migrated apps with Conditional Access
1. **Entra → Protection → Conditional Access → + New policy.** Name `ENTAPPMIG – CA – MigratedApps – Pilot`.
2. **Users:** include **`ENTAPPMIG-Pilot`**; **exclude** your **break-glass** accounts (global requirement G4).
3. **Target resources:** select the migrated apps — `ENTAPPMIG – App – LOBSaml – Pilot`,
   `ENTAPPMIG – AppProxy – Intranet – Pilot`, `ENTAPPMIG – App – ScimSaaS – Pilot`.
4. **Grant:** require **Multi-factor authentication** and (for managed devices) **Require device to be
   marked as compliant**.
5. **Enable policy: Report-only** first. Create. Review **Insights**, then switch to **On** once validated.

## Step 7 — Add an access review for the migrated apps
1. **Identity governance → Access reviews → + New access review.** *(Requires Governance/P2 — verify.)*
2. **Review type:** **Applications → Select applications →** the migrated apps.
3. **Name:** `ENTAPPMIG – Review – MigratedApps – Quarterly`; **Recurrence:** Quarterly; **Reviewers:** the
   app owner / manager. **Auto apply = Enabled**; for the **first** cycle set don't-respond → **No change**.
4. **Create.** This recertifies who can reach each migrated app over time.

## Step 8 — Validate the pilot (the gates)
Run **`ENTAPPMIG-Validate.ps1`** and confirm on `ENTAPPMIG-Pilot` (see §5 for the full matrix):
- **G1 AD FS app on Entra** — a pilot user signs into `ENTAPPMIG – App – LOBSaml – Pilot` via **Entra**
  (test endpoint) and gets the right claims — **while AD FS is still live**.
- **G2 Published app, no VPN** — with the **VPN disconnected**, a pilot user reaches
  `ENTAPPMIG – AppProxy – Intranet – Pilot` at its external URL, pre-authenticated by Entra.
- **G3 SCIM provisions** — provision-on-demand creates/updates a pilot user in the SaaS app.
- **G4 Conditional Access** — access to the migrated apps enforces MFA/compliant device.

**Pass** = all four gates green. **Fail** = fix before cutover/expand (see §6).

## Step 9 — Cut over the AD FS relying party
1. Preview with **`ENTAPPMIG-Cutover.ps1`** (report-only / `-WhatIf`) — it summarizes the app's Entra
   config, assignments, and CA coverage so you cut over with eyes open.
2. In a **change window**, repoint the app's federation from AD FS to **Entra** (update the app's IdP
   endpoint/metadata to the Entra values from Step 2, per Requirement 2.8).
3. Validate real users sign in through Entra. **Then** disable the **AD FS relying party** (do not delete
   it yet — keep it disabled as an instant rollback).
4. After a soak period with no issues, **remove** the AD FS relying party.

## Step 10 — Expand in waves
1. Repeat Steps 2–6 for the next apps, using the same convention
   (`ENTAPPMIG – App – <App> – Prod`, `ENTAPPMIG – AppProxy – <App> – Prod`), migrating by usage priority.
2. **Broaden assignments** from `ENTAPPMIG-Pilot` to the real user population per app.
3. **Broaden CA scope** and switch `ENTAPPMIG – CA – MigratedApps – Pilot` from Report-only to **On**.
4. **Broaden the access review** scope to all migrated apps; switch don't-respond to **Remove access** once
   reviewers are trained.
5. Re-run **`ENTAPPMIG-Validate.ps1`** and **`ENTAPPMIG-Report.ps1`** after each wave to capture evidence.

> **Rollback (any step):** disable rather than delete. Before cutover, everything is additive (AD FS still
> serves the app). At cutover, **re-enable the AD FS relying party** and repoint the app back to AD FS to
> instantly revert. For CA, set the policy to **Report-only**. For provisioning, **pause** the job. For
> publishing, set the published app's users back to `ENTAPPMIG-Pilot` or disable it. Break-glass accounts
> are excluded from the CA policy so an app/CA fault never locks out admins.

---
### Order of operations
`Assess (Discovery + AD FS activity) → recreate AD FS app in Entra → App Proxy connectors + group →
publish on-prem app → SaaS app + SCIM → Conditional Access → access review → validate the 4 gates →
cut over AD FS (keep it as rollback) → expand in waves`
