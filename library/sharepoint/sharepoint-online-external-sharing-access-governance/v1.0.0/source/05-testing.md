# 5. Testing & Validation — SharePoint Online External Sharing & Access Governance

Each test states **how to run it** and the **expected pass/fail**. Run them at the pilot gate and after
every expansion tranche. Automate the repeatable ones with `SPOEXT-Validation.ps1` and
`SPOEXT-ExposureReport.ps1`. Substitute your real tenant, site URLs, and domains for the `contoso.com` /
`fabrikam.com` placeholders.

---

## T1 — Tenant sharing baseline is in effect
- **Run:**
  ```powershell
  Get-SPOTenant | Select-Object SharingCapability, OneDriveSharingCapability,
      DefaultSharingLinkType, DefaultLinkPermission, ExternalUserExpirationRequired,
      ExternalUserExpireInDays, RequireAnonymousLinksExpireInDays, SharingDomainRestrictionMode
  ```
- **Pass:** every value matches `Tenant Sharing Baseline – SPO – Prod` (e.g. `SharingCapability =
  ExternalUserSharingOnly`, `DefaultSharingLinkType = Direct`, `DefaultLinkPermission = View`,
  `ExternalUserExpirationRequired = True`).
- **Fail:** any value differs → re-apply that setting (Implementation 2b) or investigate propagation
  delay (re-check after the propagation window).

## T2 — OneDrive sharing is no looser than the tenant
- **Run:** compare `OneDriveSharingCapability` to `SharingCapability` (from T1).
- **Pass:** `OneDriveSharingCapability` is **equal to or tighter** than the tenant `SharingCapability`.
- **Fail:** OneDrive is looser → `Set-SPOTenant -OneDriveSharingCapability <= tenant`.

## T3 — Default sharing link is Specific people / View
- **Run:** as a normal user in a pilot site, click **Share** on a document and read the default link
  scope and permission (do not send). Confirm in PowerShell via `DefaultSharingLinkType` /
  `DefaultLinkPermission`.
- **Pass:** the share dialog defaults to **Specific people** and **Can view** (not "Anyone", not "Can
  edit").
- **Fail:** default is "Anyone" or "Edit" → re-apply `Set-SPOTenant`/`Set-SPOSite` link defaults.

## T4 — Anyone-link expiration is enforced (only if Anyone is permitted)
- **Run:** where `SharingCapability` allows Anyone, create an **Anyone** link on a test file and read
  the expiration; check `RequireAnonymousLinksExpireInDays`.
- **Pass:** the Anyone link carries an expiration ≤ the policy value (e.g. 30 days) and cannot be set
  beyond it. If the tenant does **not** permit Anyone links, this test is **N/A** (T5 should show Anyone
  is disallowed).
- **Fail:** an Anyone link is created with no/over-limit expiration → re-apply the expiration setting.

## T5 — External sharing level blocks disallowed link types
- **Run:** on a site set to `ExternalUserSharingOnly`, attempt to create an **Anyone** link; on a site
  set to `ExistingExternalUserSharingOnly`, attempt to invite a **brand-new** external user.
- **Pass:** the disallowed action is unavailable/blocked (no Anyone option on the first; the second
  cannot invite a not-yet-directory guest).
- **Fail:** the disallowed action succeeds → the site/tenant `SharingCapability` is not what you expect;
  re-check T1 and the site value.

## T6 — Guest-access expiration applies to new guests
- **Run:** invite a test external user to a pilot site; in the SharePoint admin center → **More
  features → External users**, or via Graph, confirm an expiration is set.
- **Pass:** the new guest shows an expiration date consistent with `Guest Expiration – 60d – Prod`.
- **Fail:** no expiration → confirm `ExternalUserExpirationRequired = True` and `ExternalUserExpireInDays`.

## T7 — Domain allow/block restriction is enforced
- **Run:** attempt to share to an **allowed** partner domain (e.g. `fabrikam.com`) and to a
  **non-allowed** domain (e.g. `random-external.com`).
- **Pass:** the allowed domain succeeds; the non-allowed domain is **blocked** with a clear message.
  (`SharingDomainRestrictionMode = AllowList` + `SharingAllowedDomainList` contains the allowed domain.)
- **Fail:** a non-allowed domain succeeds, or an allowed domain is blocked → correct the mode / list
  (tenant or per-site). Remember per-site lists apply on top of the tenant.

## T8 — Sensitivity-label container control is applied (if in scope)
- **Run:** `Get-SPOSite -Identity <confidential-site> | Select-Object SensitivityLabel`; open the
  site and confirm the label badge and that its external-sharing container setting is in effect.
- **Pass:** the site shows `Container Label – <Level> – Prod` and its external-sharing behavior matches
  the label's published container setting.
- **Fail:** no label / wrong behavior → confirm the label is **published** (Requirement 2.6) and
  re-apply `Set-SPOSite -SensitivityLabel <id>`.

## T9 — External-exposure report is complete and accurate
- **Run:** `.\SPOEXT-ExposureReport.ps1 -SiteScope (Get-Content .\pilot-sites.txt) -CsvPath
  .\External-Exposure-Report.csv` and open the CSV; cross-check a few rows against a site's actual
  sharing.
- **Pass:** the report (`External Exposure – SPO – Report`) lists each pilot site's sharing links
  (type, expiration, principal), external users, and flags Anyone-links / no-expiration / out-of-policy
  domains; spot-checked rows match reality.
- **Fail:** missing sites or principals → check PnP/Graph permissions (Requirements 2.3–2.4) and
  throttling on large sites (re-run scoped).

## T10 — Guest access review runs and removes stale access
- **Run:** confirm `Access Review – Guests – Quarterly` exists and its first cycle has reviewers and a
  due date; simulate a "deny" on a test guest and confirm auto-apply removes access (or, for the
  fallback, confirm the CSV was routed and actioned).
- **Pass:** the review recurs, reviewers are assigned, and a denied guest loses access on apply.
- **Fail:** no recurrence / no removal → check the review configuration and Entra ID Governance
  licensing (Requirement 2.7); use the scripted fallback if unlicensed.

## T11 — Rollback works
- **Run (in a change window):** loosen one pilot site back to its Stage-0 `SharingCapability`, confirm,
  then re-tighten.
- **Pass:** both directions apply cleanly and `Get-SPOSite` reflects each state. (Note: existing links
  disabled by a tightening do **not** auto-restore on loosening — that is expected, not a test failure.)
- **Fail:** rollback does not apply → resolve before Expand; do not widen scope without a proven
  rollback.

---

### Validation gate summary (all must pass before Expand)
1. Tenant + OneDrive sharing scoped to policy (T1, T2).
2. Links default to Specific people / View and Anyone-links expire (T3, T4).
3. Disallowed link/guest actions blocked (T5); guests time-boxed (T6).
4. Domain allow/block enforced (T7); label container control applied where in scope (T8).
5. External exposure visible and accurate (T9); guest reviews recur and remove stale access (T10).
6. Rollback proven (T11).
