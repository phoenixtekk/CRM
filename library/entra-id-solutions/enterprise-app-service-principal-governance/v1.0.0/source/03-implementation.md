# 3. Implementation Guide — Enterprise App & Service Principal Governance

Follow these steps in order. Most steps are in the Microsoft Entra admin center
(`https://entra.microsoft.com`); the inventory and remediation steps use the included scripts.

> Model: inventory first, review permissions and consent for over-privilege, set the user-consent
> policy and admin-consent workflow, then remediate a first batch of risky apps and manage credential
> expiry on a pilot scope before expanding tenant-wide. Every change is staged and reversible.

## Step 1 — Create the governance scope and reviewer groups
1. Entra -> `Identity -> Groups -> All groups -> New group` -> Security ->
   `App Governance Consent Scope - Pilot - Pilot` (a few representative users). Create.
2. Create `App Governance Consent Reviewers - Tenant - Steady` — the admins who will review
   admin-consent requests. Add the reviewers.
3. Or run `APPGOV-Set-ScopeTargeting.ps1` to create and populate the groups and preview membership.

## Step 2 — Inventory every enterprise app and service principal
1. Entra -> `Identity -> Applications -> Enterprise applications -> All applications` to see the
   service principals in the tenant.
2. Run `APPGOV-Discovery.ps1`. It exports, per service principal: the app-role assignments
   (application permissions), the OAuth2 delegated grants, the owners, and the client-secret and
   certificate expiry. Save the output — it is your baseline.

## Step 3 — Review API permissions and consents for over-privilege
1. For a suspect app: Entra -> `Enterprise applications ->` open the app `-> Permissions`. Review the
   admin-consented permissions; note any tenant-wide application permissions (for example
   `Mail.Read`, `Directory.ReadWrite.All`, `Application.ReadWrite.All`).
2. Run `APPGOV-Report.ps1` to rank apps by risk — those holding high-privilege application
   permissions, broad delegated grants, many credentials, or an unknown/absent owner rise to the top.
3. Build a shortlist of over-permissioned and unowned apps to remediate in Step 6.

## Step 4 — Configure the user-consent policy
1. Entra -> `Identity -> Applications -> Enterprise applications -> Consent and permissions ->
   User consent settings`.
2. Set `User consent for applications` to `Allow user consent for apps from verified publishers, for
   selected permissions` (low-risk delegated scopes only). Do not leave it on `Allow user consent for
   all apps`.
3. Under `Consent and permissions -> Permission classifications`, confirm only low-risk delegated
   permissions (for example `openid`, `profile`, `User.Read`, `offline_access`) are classified as low.
4. Save. This is the tenant-wide control that stops consent-phishing.

## Step 5 — Enable the admin-consent workflow
1. Entra -> `Identity -> Applications -> Enterprise applications -> Admin consent settings`.
2. Set `Users can request admin consent to apps they are unable to consent to` to `Yes`.
3. Add `App Governance Consent Reviewers - Tenant - Steady` as the reviewers who receive and act on
   requests; set the notification and request-expiry options. Save.

## Step 6 — Remediate risky grants (staged)
1. Preview first: run `APPGOV-Remediation.ps1` with its default `-WhatIf`. It reports the risky
   OAuth2 delegated grants and app-role assignments it would revoke — nothing is changed.
2. Review the preview against the Step 3 shortlist with the app owners; confirm each app can lose the
   grant without breaking a needed function.
3. Re-run with `-WhatIf:$false` scoped to the confirmed apps to revoke the risky grants. To revoke a
   single app in the portal instead: `Enterprise applications ->` open the app `-> Permissions ->`
   remove the permission, or `Properties -> Delete` to remove an unused app entirely.

## Step 7 — Manage secret and certificate expiry
1. Run `APPGOV-Report.ps1` (expiring-secret section) to list credentials expiring soon and
   credentials with no expiry or an excessive lifetime.
2. For an app you own: `Entra -> App registrations ->` open the app `-> Certificates & secrets`;
   rotate the secret or certificate before expiry and remove stale or surplus credentials.
3. Prefer a certificate over a long-lived client secret for app-only authentication.

## Step 8 — Validate on the pilot
1. Run `APPGOV-Validation.ps1` -> confirms the user-consent policy is set to verified-publisher /
   low-risk, the admin-consent workflow is enabled with reviewers, and no pilot-scope app still holds
   a revoked risky grant.
2. Have a pilot user attempt to consent to a high-risk app -> the attempt should be blocked and route
   to an admin-consent request. Complete the Testing Guide.

## Step 9 — Expand tenant-wide
1. With the policy validated, work the full Step 3 shortlist in batches — remediate the remaining
   over-permissioned and unowned apps with `APPGOV-Remediation.ps1` (preview, confirm, apply).
2. Put credential expiry on a schedule: re-run `APPGOV-Report.ps1` monthly and rotate ahead of
   expiry.
3. Re-run `APPGOV-Discovery.ps1` and `APPGOV-Report.ps1` on a recurring cadence so new apps and
   grants are caught as they appear.

---
### Order of operations
`Scope + reviewer groups -> inventory -> permission/consent review -> user-consent policy ->
admin-consent workflow -> remediate risky grants -> credential expiry -> validate -> expand`

### Rollback
- User-consent policy: revert `User consent settings` to the previous option in `Consent and
  permissions` (change is immediate and reversible).
- Admin-consent workflow: set `Users can request admin consent...` back to `No`.
- Revoked grant: re-add the permission on the app's `Permissions` blade (or re-grant admin consent);
  because remediation is confirmed per app from a `-WhatIf` preview, only reviewed apps are ever
  changed.
