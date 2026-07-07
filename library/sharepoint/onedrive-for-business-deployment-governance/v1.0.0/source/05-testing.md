# 5. Testing & Validation — OneDrive for Business Deployment & Governance

Run these after each stage and as the go/no-go gate before tenant-wide expansion. Each test has an
explicit **expected pass** and a **fail** signal. Use the named artifacts from the Implementation guide.
Client-side tests run **on a pilot device** signed in as a pilot-ring user; tenant tests run from the
SPO Management Shell.

---

## Test 1 — Silent sign-in (`OneDrive Silent Config – AllUsers – Prod`)
**Procedure (pilot device):** After the profile `OneDrive Client Config – Pilot – Stage1` applies, sign
in as a pilot user on a freshly-synced device. Confirm the policy landed:
```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name SilentAccountConfig
```
**Expected pass:** `SilentAccountConfig = 1`, and the OneDrive client is signed in with the user's work
account **without any prompt** (cloud icon in the system tray, "Up to date").
**Fail:** value absent/0, or the client shows "Sign in" — see Troubleshooting (silent sign-in).

## Test 2 — Known Folder Move (`KFM Silent Redirect – Pilot – Stage1`)
**Procedure (pilot device):**
```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name KFMSilentOptIn, KFMBlockOptOut
```
Then open **File Explorer → Desktop / Documents / Pictures** and check the path.
**Expected pass:** `KFMSilentOptIn` equals the **tenant ID**, `KFMBlockOptOut = 1`; the three folders
resolve under `%UserProfile%\OneDrive - <Org>\` and their contents appear in OneDrive online; the
"Stop protecting" / move-back option is greyed out.
**Fail:** folders still on the local profile path, or opt-out available — see Troubleshooting (KFM blocked).

## Test 3 — Domain-join sync restriction (`Sync Restriction – DomainJoined – Prod`)
**Procedure:** Confirm the tenant setting, then test client behavior on two devices:
```powershell
Get-SPOTenantSyncClientRestriction | Select TenantRestrictionEnabled, AllowedDomainList, ExcludedFileExtensions
```
- On a **domain-joined / allowed-GUID** pilot device: sync a file.
- On a **non-domain-joined** test device: attempt to sync.
**Expected pass:** `TenantRestrictionEnabled = True` with the correct domain GUID(s); allowed device
syncs; non-allowed device is blocked with the "your organization does not allow syncing on this
computer" message; a blocked extension (e.g. `.pst`) is refused.
**Fail:** restriction not enabled, or a non-allowed device syncs — see Troubleshooting (sync not blocked).

## Test 4 — Personal-account block (`DisablePersonalSync`)
**Procedure (pilot device):** In the OneDrive client, attempt to add a **personal** Microsoft account.
```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name DisablePersonalSync
```
**Expected pass:** `DisablePersonalSync = 1`; the client refuses to add a personal OneDrive account.
**Fail:** personal account adds successfully — re-check the policy assignment.

## Test 5 — Storage quota & retention (`OneDrive Storage Quota – Default – Prod`, `OneDrive Retention – Orphaned – Prod`)
**Procedure:**
```powershell
Get-SPOTenant | Select OneDriveStorageQuota, OrphanedPersonalSitesRetentionPeriod
```
**Expected pass:** both equal the approved design values (e.g. quota 1048576 MB, retention 365 days);
a per-user override (if set) shows on that site via `Get-SPOSite -Identity <url> | Select StorageQuota`.
**Fail:** values differ from design — re-run `ODFBGOV-Configure.ps1 -Commit`.

## Test 6 — Sharing alignment (`OneDrive Sharing – Aligned – Prod`)
**Procedure:**
```powershell
Get-SPOTenant | Select SharingCapability, OneDriveSharingCapability
```
**Expected pass:** `OneDriveSharingCapability` equals the target and is **no more permissive** than the
org `SharingCapability` (e.g. org `ExternalUserSharingOnly`, OneDrive `ExistingExternalUserSharingOnly`).
**Fail:** OneDrive more permissive than org (not possible to set — indicates a misread target) or not the
approved value — re-align.

## Test 7 — Offboarding access (`Offboarding Access – Manager – Prod`)
**Procedure:** For a **test** departing user, run `ODFBGOV-Set-OffboardingAccess.ps1 … -Commit`, then
have the delegate open the leaver's OneDrive URL.
```powershell
Get-SPOUser -Site <OneDriveUrl> | Where-Object { $_.LoginName -eq 'manager@contoso.com' } | Select LoginName, IsSiteAdmin
```
**Expected pass:** delegate shows `IsSiteAdmin = True`, can browse and download the leaver's files; the
reported retention window matches `OneDrive Retention – Orphaned – Prod`.
**Fail:** access denied or OneDrive not resolved — see Troubleshooting (offboarding access).

## Test 8 — Governance report (`OneDrive Governance – Tenant – Report`)
**Procedure:**
```powershell
.\ODFBGOV-Report.ps1 -AdminUrl https://contoso-admin.sharepoint.com -HtmlPath C:\ODFBGOV\OneDrive-Report.html -StaleDays 90
```
**Expected pass:** the report renders one row per OneDrive with quota, used, headroom %, last activity,
sharing, and NearQuota/Stale flags; totals match the provisioned OneDrive count.
**Fail:** empty/partial report — confirm Graph `Reports.Read.All` consent and that usage reporting is
not de-identified (a tenant privacy setting can anonymize names).

---

## Go / No-Go gate (before Stage 8 expansion)
**Go** only when Tests 1–8 all pass on the pilot ring: silent sign-in works, KFM redirects and blocks
opt-out, sync is restricted to allowed devices and blocks personal accounts, quota/retention/sharing
match design, offboarding grants work, and the governance report is clean. **No-Go on any failure** —
remediate via Troubleshooting and re-test before expanding tenant-wide.
