# 3. Implementation — OneDrive for Business Deployment & Governance

Follow these steps in order. They implement the reference design from the Overview using the
**Assess → Design → Configure → Pilot → Validate → Expand** model. Every artifact is named with the
`<Purpose> – <Scope> – <Stage>` convention and reused verbatim in Testing, Troubleshooting, and the
scripts. Tenant-wide sync, sharing, retention, and KFM changes are **high-impact** — pilot first,
gate every stage, and keep the documented rollback ready.

> **Cloud note.** Portal paths use Commercial cloud URLs (`*-admin.sharepoint.com`). For **Government**
> clouds substitute the Government URLs (e.g. `*-admin.sharepoint.us`) — **verify in your tenant**. Do
> not assume a Commercial path exists unchanged in GCC/GCC High.

---

## Stage 0 — Assess (read-only baseline)

**Step 0.1 — Capture the current OneDrive posture.** Run the discovery script read-only and save the
baseline `OneDrive Baseline – Tenant – Discovery`:

```powershell
.\ODFBGOV-Discovery.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
    -CsvPath C:\ODFBGOV\OneDrive-Baseline.csv -IncludeGraphUsage
```

Record: default quota, orphaned-site retention, `OneDriveSharingCapability` vs org `SharingCapability`,
current sync-client restriction state, provisioned OneDrive count, and top storage consumers.

**Step 0.2 — Resolve the identifiers.** Capture the tenant ID and domain GUID(s) for the KFM and sync
policies:

```powershell
.\ODFBGOV-Set-Scope.ps1 -TenantOnlyLookup      # tenant ID (KFM + tenant sync restriction)
.\ODFBGOV-Set-Scope.ps1 -ResolveDomainGuids    # AD domain GUID(s) (domain-join sync restriction)
```

**Gate 0 (pass/fail):** Baseline captured, tenant ID and domain GUID(s) recorded, and the deployment
channel (Intune or GPO) confirmed present (Requirement 1). **Fail** → resolve before proceeding.

---

## Stage 1 — Design (name the baseline)

**Step 1.1 — Define the rings.** In Entra ID create/confirm two groups: `OneDrive Pilot Ring – Users –
Stage1` (a small, representative set including at least one KFM-eligible and one edge-case device) and
`OneDrive Broad Ring – Users – Stage2` (the remaining population).

**Step 1.2 — Decide the target values** and record them in the design (each becomes a named artifact):
- `OneDrive Storage Quota – Default – Prod` — default quota in MB (e.g. 1048576 = 1 TB; **verify your
  plan's max** — plan-dependent).
- `OneDrive Retention – Orphaned – Prod` — orphaned-OneDrive retention days (30–3650), agreed with records.
- `OneDrive Sharing – Aligned – Prod` — target `OneDriveSharingCapability` (≤ org `SharingCapability`).
- `Sync Restriction – DomainJoined – Prod` — the domain GUID allow-list + blocked file extensions.
- `Sync Tenant Restriction – OrgOnly – Prod` — the tenant-ID allow list (own tenant only).
- KFM mode: silent (`KFM Silent Redirect – …`), block opt-out yes/no, notification yes/no.

**Gate 1:** Rings created, every target value decided and approved through change control. **Fail** →
do not configure until approved.

---

## Stage 2 — Configure the client-deployment policy (pilot ring)

Configure to the **pilot ring only** first. Steps below give the **Intune** path with the equivalent
**Group Policy** setting named; use whichever channel is your standard (Requirement 1).

**Step 2.1 — Create the client-config profile `OneDrive Client Config – Pilot – Stage1`.**
Intune admin center → **Devices → Configuration → Create → Windows 10 and later → Settings catalog**.
Name it `OneDrive Client Config – Pilot – Stage1`. Add the OneDrive settings:

| Setting (Intune / GP name) | Value | Policy value |
|---|---|---|
| **Silently sign in users to the OneDrive sync app with their Windows credentials** | Enabled | `SilentAccountConfig = 1` (`OneDrive Silent Config – AllUsers – Prod`) |
| **Use OneDrive Files On-Demand** | Enabled | `FilesOnDemandEnabled = 1` |
| **Prevent users from syncing personal OneDrive accounts** | Enabled | `DisablePersonalSync = 1` |

**Step 2.2 — Ensure the sync client is current and machine-wide.** OneDrive ships in Windows and
Microsoft 365 Apps. Confirm the pilot devices run a current build; for machine-wide (per-machine)
install where standalone deployment is needed, install with the documented per-machine switch
(`OneDriveSetup.exe` with the all-users install parameter) — **defer exact packaging to your
Intune/Configuration Manager app model.**

**Step 2.3 — Assign** `OneDrive Client Config – Pilot – Stage1` to `OneDrive Pilot Ring – Users –
Stage1` only.

**Gate 2:** Profile assigned; on a pilot device `SilentAccountConfig` is present (registry
`HKLM\SOFTWARE\Policies\Microsoft\OneDrive`) and the client signs in with no prompt. **Fail** →
Troubleshooting (silent sign-in).

---

## Stage 3 — Configure Known Folder Move (pilot ring)

**Step 3.1 — Add KFM to the pilot profile** `OneDrive Client Config – Pilot – Stage1` (artifact `KFM
Silent Redirect – Pilot – Stage1`):

| Setting (Intune / GP name) | Value | Policy value |
|---|---|---|
| **Silently move Windows known folders to OneDrive** | Enabled, **Tenant ID = your tenant GUID** | `KFMSilentOptIn = <tenant ID>` |
| **Prevent users from moving their Windows known folders to their PC** | Enabled | `KFMBlockOptOut = 1` |
| *(optional)* **Silently move … with notification** | Enabled to notify users when redirect completes | `KFMSilentOptInWithNotification = 1` |

> The tenant ID **must** be the GUID from Step 0.2. A wrong or blank tenant ID makes the policy no-op silently.

**Step 3.2 — Deploy** to the pilot ring and allow the client to redirect Desktop, Documents, and
Pictures into OneDrive.

**Gate 3:** On a pilot device the three known folders show the OneDrive redirect (path under
`%UserProfile%\OneDrive - <Org>\`), files are present in OneDrive online, and opt-out is greyed out.
**Fail** → Troubleshooting (KFM blocked).

---

## Stage 4 — Configure sync controls (tenant — validate on pilot devices)

Sync controls are **tenant-level**; scope validation to pilot devices before broad reliance.

**Step 4.1 — Domain-join sync restriction `Sync Restriction – DomainJoined – Prod`.**
SharePoint admin center → **Settings → OneDrive → Sync** → **Allow syncing only on computers joined to
specific domains** → paste the **domain GUID(s)** from Step 0.2. In this pane also set **Block syncing
of specific file types** (e.g. `pst`) and, if required, **Block Mac sync**. PowerShell equivalent
(preview first with `ODFBGOV-Configure.ps1`):

```powershell
# Preview:
.\ODFBGOV-Configure.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
    -DomainGuids '12345678-90ab-cdef-1234-567890abcdef' -WhatIf
# Apply:
.\ODFBGOV-Configure.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
    -DomainGuids '12345678-90ab-cdef-1234-567890abcdef' -Commit
# Direct cmdlet equivalent:
Set-SPOTenantSyncClientRestriction -Enable -DomainGuids "12345678-90ab-cdef-1234-567890abcdef" -ExcludedFileExtensions "pst"
```

**Step 4.2 — Organization sync restriction `Sync Tenant Restriction – OrgOnly – Prod`.** To stop the
client signing in to other organizations' tenants, allow only your own tenant ID
(`AllowTenantList`) via the **Allow syncing OneDrive accounts for only specific organizations** policy
(or block specific tenants with **Block syncing OneDrive accounts for specific organizations**,
`BlockTenantList`). These are **client ADMX policies keyed by tenant GUID** — deploy through the same
Intune/GPO channel; **verify the exact value names against your OneDrive ADMX build**.

**Step 4.3 — Browser web-only access (optional).** To block download/print/sync from unmanaged browser
sessions, set limited access (requires the conditional-access prerequisites — **verify licensing**):

```powershell
.\ODFBGOV-Configure.ps1 -AdminUrl https://contoso-admin.sharepoint.com -ConditionalAccess AllowLimitedAccess -Commit
# equivalent: Set-SPOTenant -ConditionalAccessPolicy AllowLimitedAccess
```

**Gate 4:** On a **non-domain-joined** test device the OneDrive client refuses to sync (restriction
works); on a pilot **domain-joined** device sync succeeds; blocked extensions are refused. **Fail** →
Troubleshooting (sync blocked / not blocked).

---

## Stage 5 — Configure storage, retention, and sharing (tenant)

**Step 5.1 — Storage quota + retention + sharing.** Preview then apply the named artifacts:

```powershell
# Preview all three:
.\ODFBGOV-Configure.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
    -StorageQuotaMB 1048576 -RetentionDays 365 -OneDriveSharing ExistingExternalUserSharingOnly -WhatIf
# Apply:
.\ODFBGOV-Configure.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
    -StorageQuotaMB 1048576 -RetentionDays 365 -OneDriveSharing ExistingExternalUserSharingOnly -Commit
```

This sets `OneDrive Storage Quota – Default – Prod` (`-OneDriveStorageQuota`), `OneDrive Retention –
Orphaned – Prod` (`-OrphanedPersonalSitesRetentionPeriod`), and `OneDrive Sharing – Aligned – Prod`
(`-OneDriveSharingCapability`, kept ≤ org `SharingCapability`). Admin-center equivalents: **SharePoint
admin center → Settings → OneDrive storage limit** and **→ Sharing**.

**Step 5.2 — Per-user quota overrides (as needed).** `Set-SPOSite -Identity <OneDriveUrl>
-StorageQuota <MB>` for roles that justify more/less than the default.

**Gate 5:** `Get-SPOTenant` shows the target quota, retention, and OneDrive sharing values, and
OneDrive sharing is **not** more permissive than org sharing. **Fail** → re-apply / align.

---

## Stage 6 — Configure offboarding & data-retention (validate on a test departure)

**Step 6.1 — Manager access `Offboarding Access – Manager – Prod`.** For a departing user, grant the
delegate (manager) access to the leaver's OneDrive so files can be retrieved before deletion:

```powershell
# Preview:
.\ODFBGOV-Set-OffboardingAccess.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
    -DepartingUser jdoe@contoso.com -Delegate manager@contoso.com -WhatIf
# Apply:
.\ODFBGOV-Set-OffboardingAccess.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
    -DepartingUser jdoe@contoso.com -Delegate manager@contoso.com -Commit
```

The tenant retention window (`OneDrive Retention – Orphaned – Prod`) preserves the OneDrive for the
configured days after the account is deleted. The SharePoint admin center can also **automatically
grant the manager access** for a set number of days on deletion — configure that under **Settings →
OneDrive → Retention/Notifications** to match `Offboarding Access – Manager – Prod`.

**Step 6.2 — Hold before deletion (compliance-owned).** If the leaver is subject to any legal/records
**hold**, compliance applies a Purview retention/eDiscovery hold **before** the account is deleted.
This is a **compliance/legal determination — deferred**; IT provides the technical retention window and
manager-access evidence, compliance decides and applies the hold.

**Gate 6:** On a test departure the manager can open the OneDrive and retrieve files, and the retention
period is confirmed. **Fail** → Troubleshooting (offboarding access).

---

## Stage 7 — Validate the pilot

Run the full validation before expanding (see **05-testing.md**), then re-run discovery to confirm the
posture and generate the governance report:

```powershell
.\ODFBGOV-Discovery.ps1 -AdminUrl https://contoso-admin.sharepoint.com -IncludeGraphUsage   # confirm tenant settings
.\ODFBGOV-Report.ps1 -AdminUrl https://contoso-admin.sharepoint.com -HtmlPath C:\ODFBGOV\OneDrive-Report.html
```

Client-side gates (silent sign-in, KFM redirect, sync enforcement) are verified **on the pilot device**
per the procedures in **05-testing.md** (registry checks + observed client behavior).

**Gate 7 (go/no-go):** All pilot gates green — silent sign-in, KFM redirect, sync controls enforced,
storage/retention/sharing correct, offboarding works. **Fail any** → hold expansion, remediate, re-test.

---

## Stage 8 — Expand tenant-wide

**Step 8.1 — Broad client config.** Clone the pilot profile to `OneDrive Client Config – Broad –
Stage2` (silent sign-in + Files On-Demand + KFM `KFM Silent Redirect – Broad – Stage2` + personal-sync
block) and assign to `OneDrive Broad Ring – Users – Stage2`.

**Step 8.2 — Confirm tenant settings** (sync restriction, quota, retention, sharing) are already
tenant-wide from Stages 4–5; no per-ring change needed.

**Step 8.3 — Monitor** with `ODFBGOV-Report.ps1` on a recurring cadence (near-quota and stale accounts).

**Gate 8:** Broad ring reports silent sign-in + KFM at target coverage; governance report clean.

---

## Rollback (documented, per high-impact change)
- **Silent sign-in / KFM:** unassign the client-config profile (or set `KFMBlockOptOut = 0` and remove
  `KFMSilentOptIn`); redirection already completed stays in OneDrive — reverse per Microsoft KFM guidance.
- **Sync restriction:** `Set-SPOTenantSyncClientRestriction -Disable` (re-run `ODFBGOV-Configure.ps1`
  without `-DomainGuids` does not disable — use the direct cmdlet) to lift the domain-join allow list.
- **Sharing / quota / retention:** re-run `ODFBGOV-Configure.ps1 -Commit` with the prior baseline values
  recorded in Step 0.1.
- **Offboarding grant:** `Set-SPOUser -Site <url> -LoginName <delegate> -IsSiteCollectionAdmin $false`.
