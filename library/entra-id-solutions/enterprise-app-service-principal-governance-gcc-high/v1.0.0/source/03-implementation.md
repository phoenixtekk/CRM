# 3. Implementation Guide — Enterprise App & Service Principal Governance (Government / GCC High)

Follow these steps in order. Most steps are in the **Microsoft Entra admin center for US Government**
(`https://entra.microsoft.us`); the inventory and remediation steps use the included scripts, which
connect to US Gov Microsoft Graph with `-Environment USGov`.

> GCC High caveat (read first): sign in to `entra.microsoft.us` with a GCC High account — the
> Commercial `entra.microsoft.com` will not recognize it. Graph Explorer is **not supported** in
> GCC High, so every API action here is done via the PowerShell scripts, not the browser API tool.
> See `gcc-high-parity-notes.md` for citations.

> Model: inventory first, review permissions and consent for over-privilege, set the user-consent
> policy and admin-consent workflow, then remediate a first batch of risky apps and manage credential
> expiry on a pilot scope before expanding tenant-wide. Every change is staged and reversible.

## Step 0 — Confirm you are in the sovereign cloud
1. Browse to `https://entra.microsoft.us` and sign in with your GCC High admin account.
2. On the operator workstation, run `Connect-MgGraph -Environment USGov -NoWelcome` once and confirm
   `(Get-MgContext).Environment` returns `USGov`. If it returns `Global`, you are pointed at the
   Commercial cloud — reconnect with `-Environment USGov`.
3. Confirm licensing and roles per the Requirements Guide (2.2, 2.3).

## Step 1 — Create the governance scope and reviewer groups
1. `entra.microsoft.us` -> `Entra ID -> Groups -> All groups -> New group` -> Security ->
   `App Governance Consent Scope - Pilot - Pilot` (a few representative users). Create.
2. Create `App Governance Consent Reviewers - Tenant - Steady` — the admins who will review
   admin-consent requests. Add the reviewers.
3. Or run `APPGOVG-Set-ScopeTargeting.ps1` (connects `-Environment USGov`) to create and populate the
   groups and preview membership.

## Step 2 — Inventory every enterprise app and service principal
1. `entra.microsoft.us` -> `Entra ID -> Enterprise apps -> All applications` to see the
   service principals in the tenant.
2. Run `APPGOVG-Discovery.ps1`. It exports, per service principal: the app-role assignments
   (application permissions), the OAuth2 delegated grants, the owners, and the client-secret and
   certificate expiry — all read from `graph.microsoft.us`. Save the output — it is your baseline.

## Step 3 — Review API permissions and consents for over-privilege
1. For a suspect app: `entra.microsoft.us` -> `Enterprise apps ->` open the app `-> Permissions`.
   Review the admin-consented permissions; note any tenant-wide application permissions (for example
   `Mail.Read`, `Directory.ReadWrite.All`, `Application.ReadWrite.All`).
2. Run `APPGOVG-Report.ps1` to rank apps by risk — those holding high-privilege application
   permissions, broad delegated grants, many credentials, or an unknown/absent owner rise to the top.
3. Build a shortlist of over-permissioned and unowned apps to remediate in Step 6.
   GCC High caveat: do not rely on the **Microsoft Entra threat intelligence** risk signal to flag
   apps — it is not available in GCC High (parity notes). The over-permission report is your primary
   signal here.

## Step 4 — Configure the user-consent policy
1. `entra.microsoft.us` -> `Entra ID -> Enterprise apps -> Consent and permissions ->
   User consent settings`.
2. Set `User consent for applications` to `Allow user consent for apps from verified publishers, for
   selected permissions` (low-risk delegated scopes only). Do not leave it on `Allow user consent for
   all apps`.
3. Under `Consent and permissions -> Permission classifications`, confirm only low-risk delegated
   permissions (for example `openid`, `profile`, `User.Read`, `offline_access`) are classified as low.
4. Save. This is the tenant-wide control that stops consent-phishing.
   GCC High caveat: the *capability* is GA in GCC High, but if a sub-option looks different from a
   Commercial screenshot, trust the live `entra.microsoft.us` portal — do not assume a
   Commercial-only option exists here (parity notes, "verify for GCC High").

## Step 5 — Enable the admin-consent workflow
1. `entra.microsoft.us` -> `Entra ID -> Enterprise apps -> Consent and permissions ->
   Admin consent settings`.
2. Set `Users can request admin consent to apps they are unable to consent to` to `Yes`.
3. Add `App Governance Consent Reviewers - Tenant - Steady` as the reviewers who receive and act on
   requests; set the notification and request-expiry options. Save.
   Note: only reviewers holding a role able to grant tenant-wide consent (for example Global
   Administrator) can approve requests for Microsoft Graph application permissions.

## Step 6 — Remediate risky grants (staged)
1. Preview first: run `APPGOVG-Remediation.ps1 -AppId your-app-id` with its default `-WhatIf`. It
   reports the risky OAuth2 delegated grants and app-role assignments it would revoke — nothing is
   changed. (Connects `-Environment USGov`.)
2. Review the preview against the Step 3 shortlist with the app owners; confirm each app can lose the
   grant without breaking a needed function.
3. Re-run with `-WhatIf:$false` scoped to the confirmed apps to revoke the risky grants. To revoke a
   single app in the portal instead: `Enterprise apps ->` open the app `-> Permissions ->` remove the
   permission, or `Properties -> Delete` to remove an unused app entirely.

## Step 7 — Manage secret and certificate expiry
1. Run `APPGOVG-Report.ps1` (expiring-secret section) to list credentials expiring soon and
   credentials with no expiry or an excessive lifetime.
2. For an app you own: `entra.microsoft.us` -> `App registrations ->` open the app
   `-> Certificates & secrets`; rotate the secret or certificate before expiry and remove stale or
   surplus credentials.
3. Prefer a certificate over a long-lived client secret for app-only authentication — especially on a
   CUI/ITAR tenant, where a leaked long-lived secret is a controlled-data exposure.

## Step 8 — Validate on the pilot
1. Run `APPGOVG-Validation.ps1` -> confirms the user-consent policy is set to verified-publisher /
   low-risk, the admin-consent workflow is enabled with reviewers, and (with `-CheckAppId`) that a
   pilot-scope app no longer holds a revoked risky grant. It reads back from `graph.microsoft.us`.
2. Have a pilot user attempt to consent to a high-risk app -> the attempt should be blocked and route
   to an admin-consent request. Complete the Testing Guide.

## Step 9 — Expand tenant-wide
1. With the policy validated, work the full Step 3 shortlist in batches — remediate the remaining
   over-permissioned and unowned apps with `APPGOVG-Remediation.ps1` (preview, confirm, apply).
2. Put credential expiry on a schedule: re-run `APPGOVG-Report.ps1` monthly and rotate ahead of
   expiry.
3. Re-run `APPGOVG-Discovery.ps1` and `APPGOVG-Report.ps1` on a recurring cadence so new apps and
   grants are caught as they appear.

---
### Order of operations
`Confirm USGov -> scope + reviewer groups -> inventory -> permission/consent review -> user-consent
policy -> admin-consent workflow -> remediate risky grants -> credential expiry -> validate -> expand`

### Rollback
- User-consent policy: revert `User consent settings` to the previous option in `Consent and
  permissions` (change is immediate and reversible).
- Admin-consent workflow: set `Users can request admin consent...` back to `No`.
- Revoked grant: re-add the permission on the app's `Permissions` blade (or re-grant admin consent);
  because remediation is confirmed per app from a `-WhatIf` preview, only reviewed apps are ever
  changed.
