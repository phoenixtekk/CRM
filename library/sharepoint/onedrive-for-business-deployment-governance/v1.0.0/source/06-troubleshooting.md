# 6. Troubleshooting — OneDrive for Business Deployment & Governance

Common failure modes, their root cause, and the resolution. Symptoms reference the named artifacts and
tests from the Implementation and Testing guides.

---

## Silent sign-in doesn't happen (client shows "Sign in")
**Symptom:** After `OneDrive Client Config – Pilot – Stage1` applies, the OneDrive client still prompts
to sign in; Test 1 shows `SilentAccountConfig` present but the account isn't configured.
**Root causes & resolution:**
- **Device isn't Entra/hybrid joined.** `SilentAccountConfig` signs in with the device's primary work
  account; on workgroup/personal devices it cannot complete. Confirm `dsregcmd /status` shows
  `AzureAdJoined : YES` (Requirement 2). Resolution: bring the device into Entra/hybrid join.
- **Policy not applied.** Confirm the profile is assigned to `OneDrive Pilot Ring – Users – Stage1` and
  the device has synced policy (Intune → device → check-in; or `gpupdate /force` for GPO). Verify
  `HKLM\SOFTWARE\Policies\Microsoft\OneDrive\SilentAccountConfig = 1`.
- **Modern auth / MFA loop.** If the account requires interactive MFA at first sign-in, silent config
  completes only after the credential is established; ensure the device is compliant for conditional access.

## KFM didn't redirect (folders still on the local profile)
**Symptom:** Desktop/Documents/Pictures still resolve to `%UserProfile%\...` not `…\OneDrive - <Org>\`;
Test 2 fails.
**Root causes & resolution:**
- **Wrong or blank tenant ID.** `KFMSilentOptIn` must equal your **tenant ID** GUID (Step 0.2). A wrong
  or empty value silently no-ops. Fix the value (use `ODFBGOV-Set-Scope.ps1 -TenantOnlyLookup`) and reapply.
- **Folder ineligible.** Legacy **Folder Redirection** (GPO) pointing a known folder to a network/UNC
  path, a known folder on a non-C: drive, or a folder containing OneNote notebooks/locked or
  unsupported files can block the silent move. Remediation: remove the conflicting Folder Redirection
  GPO, then let KFM retry. Files already there stay; the move completes once the blocker is cleared.
- **Not signed in yet.** KFM runs after the client is signed in; if silent sign-in failed (above), fix
  that first — KFM has nothing to redirect into.

## Sync isn't blocked on an unmanaged device (restriction not working)
**Symptom:** A non-domain-joined device still syncs; Test 3 fails.
**Root causes & resolution:**
- **Restriction not enabled / wrong GUID.** `Get-SPOTenantSyncClientRestriction` must show
  `TenantRestrictionEnabled = True` with the correct **domain GUID** (not the tenant GUID — the
  domain-join list uses the AD **domain** GUID from `(Get-ADDomain).ObjectGUID`). Re-apply with the
  correct GUID via `ODFBGOV-Configure.ps1 -DomainGuids … -Commit`.
- **Propagation delay.** Sync-client restriction changes can take time to take effect on clients;
  allow the documented propagation window before concluding it failed, and re-test on a clean client.

## Sync is blocked on a device that should be allowed (over-blocked)
**Symptom:** A legitimately domain-joined device gets "your organization does not allow syncing on this
computer."
**Root causes & resolution:**
- **Device in a different domain/forest.** Only the domain GUID(s) in the allow-list may sync. Add the
  missing domain GUID (multi-domain forests need each domain's GUID) and reapply.
- **Hybrid-only device without the on-prem domain GUID.** Devices joined only to Entra (not the on-prem
  AD) won't match an on-prem domain GUID. Reconsider whether domain-join restriction fits your device
  model, or use device compliance/conditional access instead — **verify which control matches your estate.**

## Personal account still syncs (personal-sync block not working)
**Symptom:** Users can add a personal Microsoft account; Test 4 fails.
**Resolution:** Confirm `DisablePersonalSync = 1` is in the assigned profile and applied on the device
(`HKLM\SOFTWARE\Policies\Microsoft\OneDrive\DisablePersonalSync`). If present but ineffective, ensure
the OneDrive client build supports the policy and re-sync policy.

## Offboarding — can't access the departed user's OneDrive
**Symptom:** `ODFBGOV-Set-OffboardingAccess.ps1` reports "No provisioned OneDrive found," or the
delegate is denied.
**Root causes & resolution:**
- **OneDrive never provisioned.** A user who never signed in to OneDrive may have no personal site; it
  provisions on first use (or can be pre-provisioned with `Request-SPOPersonalSite`). If never
  provisioned, there is no data to hand off.
- **Owner UPN mismatch.** The script matches on `Owner`; if the UPN changed (rename/merge), pass the
  current UPN or locate the site with `Get-SPOSite -IncludePersonalSite $true -Filter "Url -like '…'"`.
- **Retention already expired.** If the account was deleted more than `OrphanedPersonalSitesRetentionPeriod`
  days ago, the OneDrive is permanently removed. This is why the offboarding grant must happen **before**
  deletion, and holds must be confirmed with compliance first.

## Governance report is empty or partial
**Symptom:** `ODFBGOV-Report.ps1` returns few/no rows or blank last-activity.
**Root causes & resolution:**
- **Graph consent missing.** The report needs `Reports.Read.All`; consent it on first run.
- **Usage reports de-identified.** A tenant privacy setting (M365 admin center → Settings → Org settings
  → Reports) anonymizes user names in usage reports, breaking per-user matching. Turn it off (with
  privacy approval) to get named data; otherwise storage/quota still report from SPO but activity won't match.
- **Latency.** Usage data lags actual activity by a few days and has a fixed maximum window — set
  `-UsagePeriod` inside the available range.

## `Connect-SPOService` fails (wrong admin URL / cloud)
**Symptom:** Connection error against the admin endpoint.
**Resolution:** Use the correct admin URL for your cloud — Commercial `https://<tenant>-admin.sharepoint.com`,
Government `https://<tenant>-admin.sharepoint.us` (**verify in your tenant**). Ensure the account holds
the least-privilege SharePoint Administrator role and modern auth/MFA succeeds.
