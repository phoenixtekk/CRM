# 6. Troubleshooting — SharePoint Online External Sharing & Access Governance

Common failure modes and their resolutions. Symptoms are grouped by where they show up. Substitute your
real tenant/site/domain for the `contoso.com` / `fabrikam.com` placeholders.

---

## Connection & tooling

### `Connect-SPOService` fails or `Get-SPOTenant` errors "not connected"
- **Cause:** connected to a **site** URL instead of the **admin** endpoint, or wrong cloud host.
- **Fix:** connect to the admin URL: `Connect-SPOService -Url https://contoso-admin.sharepoint.com`
  (Commercial) or your **Government** admin host (e.g. `https://contoso-admin.sharepoint.us` — **verify
  your cloud**). Confirm the operator holds **SharePoint Administrator** (Requirement 2.1).

### PnP `Connect-PnPOnline` fails with an app / consent error
- **Cause:** no PnP Entra app registration or missing consent for the required permissions.
- **Fix:** register the app (`Register-PnPEntraIDAppForInteractiveLogin`) or use your own app
  registration and grant admin consent to the Sites/Graph permissions, then
  `Connect-PnPOnline -Url <site> -Interactive` (Requirement 2.3). PnP 2.x requires PowerShell 7.

### `Get-MgUser` / access-review cmdlets fail with "insufficient privileges"
- **Cause:** `Connect-MgGraph` was called without the needed scopes, or the operator lacks the role.
- **Fix:** reconnect with the scopes (`Sites.Read.All`, `User.Read.All`, and
  `AccessReview.ReadWrite.All` for reviews). Access-review creation is the **identity-governance
  owner's** task, not the SharePoint admin's (Requirements 2.4, 2.7).

---

## Settings not taking effect

### A `Set-SPOTenant` change doesn't appear immediately
- **Cause:** tenant sharing changes **propagate** across the service; they are not always instant.
- **Fix:** wait the propagation window and re-check with `Get-SPOTenant` / `SPOEXT-Validation.ps1`. Do
  not re-apply repeatedly in a tight loop — that masks the real state.

### `Set-SPOSite -SharingCapability` fails: cannot set the site looser than the tenant
- **Cause:** a **site can only be equal to or tighter than the tenant** `SharingCapability`; you tried
  to make a site more open than the tenant allows.
- **Fix:** either loosen the **tenant** (a policy decision — do not do this to accommodate one site) or
  keep the site at/below the tenant level. `SPOEXT-Set-Sharing.ps1` reports the tenant level in its
  failure message. This is by design, not a bug.

### Default link is still "Anyone" / "Edit" after configuring
- **Cause:** the **site-level** default overrides the tenant, or the change hasn't propagated, or you
  read the site UI cached.
- **Fix:** set the default at the level you intend (`Set-SPOTenant -DefaultSharingLinkType Direct
  -DefaultLinkPermission View`, and/or `Set-SPOSite ...` per site), wait for propagation, and re-test
  with a fresh Share dialog (Testing T3).

---

## Sharing behavior surprises

### Existing links stopped working after tightening the tenant
- **Cause:** reducing `SharingCapability` (e.g. removing Anyone) **disables existing links** of the
  now-disallowed type — this is expected behavior, not a fault.
- **Fix:** this is why the rollout is **pilot-first with a change window and announcement**. If it was
  unplanned, roll back the tenant `SharingCapability` to the Stage-0 value; note that **re-allowing a
  type does not automatically re-enable** links that were disabled — affected users must re-share.

### Sharing to a non-allowed domain still succeeds (allow-list not enforced)
- **Cause:** `SharingDomainRestrictionMode` is `None`, the domain list is empty/misformatted, or a
  **per-site** list is overriding the tenant.
- **Fix:** confirm `Get-SPOTenant | Select SharingDomainRestrictionMode, SharingAllowedDomainList`; the
  list is **space-separated** (`"fabrikam.com contoso-partner.com"`). Check the site too
  (`Get-SPOSite -Identity <url> | Select SharingDomainRestrictionMode`). Re-apply and re-test (T7).

### An allowed partner cannot be invited (allow-list too tight)
- **Cause:** the partner's domain isn't in `SharingAllowedDomainList`, or they accept with a different
  domain than invited while `RequireAcceptingAccountMatchInvitedAccount` is on.
- **Fix:** add the domain to the allow-list under change control, and confirm the guest accepts with the
  invited address. This is a **policy** change — route it to the policy owner, don't quietly widen it.

### New guests have no expiration
- **Cause:** `ExternalUserExpirationRequired` is `$false` or `ExternalUserExpireInDays` unset; note the
  expiration applies to **newly invited** guests, not retroactively to existing ones.
- **Fix:** `Set-SPOTenant -ExternalUserExpirationRequired $true -ExternalUserExpireInDays 60`; existing
  guests are handled by the **access review**, not by this setting (Testing T6, T10).

---

## Sensitivity labels

### `Set-SPOSite -SensitivityLabel` fails or the label doesn't appear
- **Cause:** the label is **not published** to the operator/site scope, container labeling isn't enabled
  for the tenant, or the licensing doesn't include container-label features.
- **Fix:** confirm with the **compliance owner** that the label is **published** with container settings
  and that container labeling is enabled (Requirement 2.6). Container-label capability is
  **license-dependent — verify in your tenant/plan.** This solution applies a label; it does not author
  or publish one.

### The site's external-sharing behavior doesn't match the label
- **Cause:** the label's **container** external-sharing setting differs from what you assumed, or a
  per-site `SharingCapability` and the label disagree.
- **Fix:** the **label's** container setting is authored by the compliance owner — confirm its intended
  behavior with them; align the per-site setting rather than overriding the label ad hoc.

---

## Reporting & reviews

### `SPOEXT-ExposureReport.ps1` misses sites or throttles on large sites
- **Cause:** Graph/PnP **throttling** on very large libraries, or the `-MaxItemsPerLibrary` cap trimmed
  results, or PnP permissions are insufficient.
- **Fix:** run the report **scoped** to fewer sites, raise/lower `-MaxItemsPerLibrary` deliberately, and
  confirm PnP permissions (Requirement 2.3). Treat the report as a **cadence**, not a live feed; the
  admin-center **Data Access Governance** reports complement it for tenant-scale signals.

### Access Reviews aren't available to create
- **Cause:** the tenant lacks **Entra ID P2 / Microsoft Entra ID Governance** licensing (Requirement
  2.7).
- **Fix:** acquire the licensing, or use the **scripted fallback**: `SPOEXT-ExposureReport.ps1
  -IncludeGuests` produces a guest CSV for manual attestation. Flag the licensing gap to the policy
  owner — the fallback is a report, not an enforced governance workflow.

---

## Government cloud

### Cmdlets connect but hit the wrong tenant/endpoint on GCC High / DoD
- **Cause:** Commercial hosts/endpoints were used on a **Government** cloud.
- **Fix:** use the **`.us`** admin host for `Connect-SPOService`, the correct `-Region`/environment for
  the SPO shell, and `Connect-MgGraph -Environment USGov`/`USGovDoD` for Graph. Some features differ or
  lag on Government clouds — **verify capability on your cloud** rather than assuming Commercial behavior.
