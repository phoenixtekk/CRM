# 6. Troubleshooting — Migrate & Protect Applications with Entra

Symptom → likely root cause → fix. Start with **`ENTAPPMIG-Discovery.ps1`** (are the named objects present
and is the AD FS side inventoried?) and **`ENTAPPMIG-Validate.ps1`** (which gate is failing?) — most
migration issues are a SAML mismatch, a missing claim, a connector/DNS problem, or a CA scope error.

## The migrated app rejects the sign-in ("invalid SAML response" / audience mismatch)
- **Root cause:** the Entra app's **Identifier (Entity ID)** or **Reply URL (ACS)** doesn't exactly match
  what the AD FS relying party used (and what the app expects).
- **Fix:** copy the **exact** identifier and ACS URL(s) from the AD FS relying party (Requirement 2.3) into
  `ENTAPPMIG – App – LOBSaml – Pilot` → **Single sign-on**. A trailing slash or http/https difference is
  enough to break it. `ENTAPPMIG-Validate.ps1` shows the app's configured identifier/reply URLs.

## Sign-in works but the app says "access denied" / wrong user
- **Root cause:** a **claim** the app relies on (NameID format, an attribute like `employeeid` or a role) is
  missing or in the wrong format — the AD FS **claim rule** wasn't reproduced.
- **Fix:** in the app's **Attributes & Claims**, reproduce each AD FS claim, including the **NameID format**.
  Inspect the actual token (testing gate G2) and compare to the AD FS claims. Flag complex transforms for
  extra work.

## The App Proxy published app shows a 500 / "app proxy" error page
- **Root cause:** the connector can't reach the **internal URL**, the internal URL is wrong, or no connector
  in `ENTAPPMIG – ConnectorGroup – OnPrem` is **Active**.
- **Fix:** confirm the connector is **Active** and can resolve/reach the internal URL from the connector
  host (`Test-NetConnection`); correct the **Internal URL** on `ENTAPPMIG – AppProxy – Intranet – Pilot`;
  ensure two connectors for HA.

## The published app loads but single sign-on fails (repeated prompts)
- **Root cause:** the App Proxy **SSO mode** is wrong or misconfigured — e.g. **KCD/IWA** without the SPN
  or delegation set up, or header-based SSO without the right headers.
- **Fix:** set the correct **Single sign-on** mode for the app; for **IWA (KCD)** configure the SPN and
  Kerberos-constrained delegation on the connector service account; for **header-based** map the required
  headers. Verify with a pilot user.

## SCIM provisioning "Test connection" fails or users aren't created
- **Root cause:** wrong **SCIM base URL** or **secret token**, insufficient token permissions, an attribute
  **mapping** mismatch, or the user is **out of scope** (job set to assigned-only and the user isn't assigned).
- **Fix:** re-enter the SCIM URL + token (Requirement 2.6) and re-run **Test connection**; check the
  **Mappings** for a required attribute the app rejects; confirm the user is in `ENTAPPMIG-Pilot` and the
  scope is **assigned users/groups**. Use **provision on demand** and read the step-by-step result;
  `ENTAPPMIG-Provisioning.ps1` reports the job status and recent sync outcomes.

## Removing a user didn't deprovision them in the SaaS app
- **Root cause:** the provisioning job doesn't have **deprovisioning** enabled, or the app only supports
  disable (not delete), or the user was removed from Entra faster than the sync cycle.
- **Fix:** confirm the job's target attribute mappings include the **active/disable** flag; allow a sync
  cycle or **provision on demand**; some apps **disable** rather than delete — verify the expected behavior
  with the vendor.

## After cutover, real users can't sign in (but the pilot worked)
- **Root cause:** the app's federation was repointed to Entra but a **production** setting differs (a
  different ACS URL for prod, a claim only prod users need), or the AD FS relying party is still intercepting.
- **Fix:** **re-enable the AD FS relying party** and repoint the app back to AD FS (instant rollback), then
  reconcile the prod-vs-pilot difference (extra ACS URL / claim) in the Entra app before retrying cutover.
  This is why AD FS is **disabled, not deleted**, at cutover.

## A Conditional Access policy locked users (or an admin) out of the migrated apps
- **Root cause:** the CA grant is too strict, the app target is wrong, or **break-glass** wasn't excluded.
- **Fix:** set `ENTAPPMIG – CA – MigratedApps – Pilot` back to **Report-only**, confirm **break-glass**
  accounts (global requirement G4) are **excluded**, and sign in as break-glass to recover. Re-enable after
  correcting the grant/target. `ENTAPPMIG-Validate.ps1` flags a CA policy missing the break-glass exclusion.

## The AD FS application activity report is empty / an app isn't listed
- **Root cause:** AD FS **auditing** isn't enabled or the connector/usage data hasn't populated, so Entra
  can't show relying-party activity.
- **Fix:** enable AD FS auditing and allow the report to populate; in the meantime inventory relying parties
  directly on the AD FS server with `Get-AdfsRelyingPartyTrust` (which `ENTAPPMIG-Discovery.ps1` runs when
  pointed at an AD FS server).

---
### First moves for any migration issue
1. `ENTAPPMIG-Discovery.ps1` — are the AD FS relying parties inventoried and the Entra objects present?
2. `ENTAPPMIG-Validate.ps1` — which gate is failing (SSO config, pre-auth, provisioning, CA scope)?
3. `ENTAPPMIG-Provisioning.ps1` — for any SCIM issue, what does the job status / last sync say?
4. Inspect the **actual token** for claim issues; check the **connector** for publishing issues.
5. Only then change configuration — preview any cutover with `ENTAPPMIG-Cutover.ps1` (`-WhatIf`), and keep
   **AD FS disabled-not-deleted** as your rollback.
