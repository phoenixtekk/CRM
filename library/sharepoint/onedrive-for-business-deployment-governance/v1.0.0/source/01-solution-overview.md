# 1. Solution Overview — OneDrive for Business Deployment & Governance

## What this solution is
OneDrive for Business is where most users' working files actually live. Deployed carelessly it
becomes a liability: the sync client is signed in by hand (or not at all), the Desktop, Documents,
and Pictures folders stay on the local disk and vanish with a lost or reimaged laptop, personal
OneDrive accounts sync corporate data onto unmanaged machines, storage grows without limit, sharing
drifts wider than policy allows, and when an employee leaves nobody can retrieve their files. This
solution is a repeatable, pilot-first way to **deploy** the OneDrive sync client silently and
**govern** it end to end — client deployment and silent sign-in, Known Folder Move (KFM), sync
controls, storage and retention, sharing alignment, and offboarding/data-retention on departure —
using only the Microsoft 365 admin center, the SharePoint admin center, the OneDrive client policies
(Intune or Group Policy ADMX), the SharePoint Online Management Shell / PnP PowerShell, and Microsoft
Graph. No third-party tooling.

## Why this matters
- **Data loss is the default.** Until KFM redirects Desktop/Documents/Pictures into OneDrive, those
  folders live only on the device. A lost, stolen, failed, or wiped machine takes the files with it.
- **Silent deployment is the difference between adoption and shelfware.** If users must find, install,
  and sign in to the client themselves, coverage is partial and inconsistent; silent sign-in with
  Windows credentials makes OneDrive present and working on every managed device with zero user steps.
- **Uncontrolled sync is a data-exfiltration and support problem.** Without controls, users sync
  personal OneDrive accounts on corporate machines, sync corporate data onto unmanaged personal
  machines, and sync file types that should never leave (e.g. PST). Sync controls close those paths.
- **Sharing and storage drift.** OneDrive sharing can quietly be more permissive than the org intends,
  and unbounded quotas hide cost and stale data. Both need a governed baseline.
- **Offboarding without a plan destroys or orphans data.** When an account is deleted the OneDrive is
  retained only for a configured window, then permanently removed. Without a manager-access and
  retention step, a departure means either lost files or a scramble.

## How it works
1. **Deploy the client silently.** The OneDrive sync client ships with Windows and Microsoft 365 Apps;
   the solution ensures a current, machine-wide install and enables **silent account configuration**
   (`SilentAccountConfig`) so the client signs the user in with their Windows/Entra credentials — no
   prompts. Deployed via **Intune** (Settings Catalog / Administrative Templates — ADMX-backed) or
   **Group Policy** (the OneDrive `OneDrive.admx`/`.adml` in the Central Store).
2. **Redirect known folders (KFM).** The **Silently move Windows known folders to OneDrive**
   (`KFMSilentOptIn`, keyed to your **tenant ID**) policy moves Desktop, Documents, and Pictures into
   OneDrive with no user interaction; **Prevent users from moving their known folders back to the PC**
   (`KFMBlockOptOut`) keeps them protected. A notification variant informs users when redirection
   completes.
3. **Control sync.** In the **SharePoint admin center → Settings → OneDrive → Sync** (and the matching
   `Set-SPOTenantSyncClientRestriction` cmdlet) the tenant restricts sync to **domain-joined
   computers** (an allow-list of **AD domain GUIDs**), blocks specific file extensions, and optionally
   blocks Mac sync. **Prevent users from syncing personal OneDrive accounts** (`DisablePersonalSync`)
   blocks personal accounts on managed devices. Tenant-level **allow/block organization** lists
   (`AllowTenantList` / `BlockTenantList`, keyed by **tenant GUID**) stop the client from signing in to
   other organizations' tenants. Browser **web-only / limited access** (`ConditionalAccessPolicy =
   AllowLimitedAccess`) blocks download, print, and sync from unmanaged sessions.
4. **Set storage and retention.** A **default OneDrive storage quota**
   (`Set-SPOTenant -OneDriveStorageQuota`, per-site override `Set-SPOSite -StorageQuota`) and the
   **orphaned-OneDrive retention period** (`OrphanedPersonalSitesRetentionPeriod`, 30–3650 days —
   how long a deleted user's OneDrive survives) are set to governed values.
5. **Align sharing.** `OneDriveSharingCapability` is set no more permissive than the org-level
   SharePoint sharing setting (OneDrive can never exceed it), so OneDrive sharing matches policy.
6. **Govern offboarding.** On departure, a delegate (typically the **manager**) is granted
   site-collection admin on the leaver's OneDrive to retrieve needed files, retention preserves the
   data for the configured window, and any legal/records **hold** is applied by compliance (Purview)
   before deletion — the technical steps here, the determination there.
7. **Pilot first, then expand.** Every change is validated on a named pilot ring before tenant-wide
   rollout, with explicit pass/fail gates and a documented rollback.

## The reference design
| Layer | What it does | Where it's set |
|---|---|---|
| Client deployment | Machine-wide, current-ring sync client, silent sign-in | Intune / GPO ADMX (`SilentAccountConfig`, `FilesOnDemandEnabled`) |
| Known Folder Move | Redirect Desktop/Documents/Pictures into OneDrive, block opt-out | Intune / GPO ADMX (`KFMSilentOptIn` = tenant ID, `KFMBlockOptOut`) |
| Sync controls | Domain-joined only, block extensions, block personal accounts, org allow/block | SPO admin center Sync + `Set-SPOTenantSyncClientRestriction`, `DisablePersonalSync`, `AllowTenantList`/`BlockTenantList` |
| Browser access | Web-only (blocks download/print/sync) for unmanaged sessions | `Set-SPOTenant -ConditionalAccessPolicy AllowLimitedAccess` |
| Storage & retention | Default quota + per-user override; orphaned-site retention | `Set-SPOTenant -OneDriveStorageQuota` / `-OrphanedPersonalSitesRetentionPeriod` |
| Sharing | OneDrive sharing aligned to (≤) org sharing level | `Set-SPOTenant -OneDriveSharingCapability` |
| Offboarding | Manager access grant + retention; hold deferred to compliance | `Set-SPOUser -IsSiteCollectionAdmin`; Purview hold |

## What you can control
- The **deployment channel** (Intune vs Group Policy) and the pilot vs broad **client-config rings**.
- Whether KFM is **silent**, silent-with-notification, or wizard-prompted, and whether opt-out is blocked.
- The **sync restrictions**: which domain GUIDs may sync, which file extensions are blocked, whether
  personal accounts and Mac sync are allowed, and which organizations the client may sign in to.
- The **default quota** and any **per-user overrides**, and the **orphaned-OneDrive retention** window.
- The **OneDrive sharing** capability (kept at or below the org sharing level).
- The **offboarding** delegate and handoff process.

## Limitations (be honest with buyers)
- **KFM requires the folders be eligible.** Known Folder Move silently moves Desktop/Documents/Pictures
  only; folders that are redirected elsewhere by legacy Folder Redirection, are on a network path, or
  contain unsupported/locked content can block the move and must be remediated first (see Troubleshooting).
- **Silent sign-in requires the device be joined** (Entra joined / hybrid joined) with the user's
  primary account; on workgroup or personal devices `SilentAccountConfig` cannot complete and the user
  must sign in interactively.
- **Sync controls are client policies**, enforced by the OneDrive client on managed devices — they
  govern the sync client, not browser access; browser download/print is governed separately by
  conditional-access limited access.
- **Retention is a deletion timer, not a backup.** The orphaned-OneDrive retention period governs how
  long a deleted user's OneDrive is kept; it is not versioned backup and does not substitute for a
  legal hold, which is a **compliance/records determination** (deferred to Purview and legal).
- **Plan- and cloud-dependent behavior.** Default storage limits, some sharing controls, and admin
  URLs differ between plans and between **Commercial and Government** clouds (e.g.
  `*-admin.sharepoint.us`). These are flagged **"verify in your tenant"** throughout — never invented.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, admin centers, and Intune/GPO. The standard set:

| Artifact | Name |
|---|---|
| Pilot user ring | `OneDrive Pilot Ring – Users – Stage1` |
| Broad user ring | `OneDrive Broad Ring – Users – Stage2` |
| Silent client-config profile (pilot) | `OneDrive Client Config – Pilot – Stage1` |
| Silent client-config profile (broad) | `OneDrive Client Config – Broad – Stage2` |
| Silent sign-in setting | `OneDrive Silent Config – AllUsers – Prod` |
| KFM redirect (pilot) | `KFM Silent Redirect – Pilot – Stage1` |
| KFM redirect (broad) | `KFM Silent Redirect – Broad – Stage2` |
| Sync domain-join restriction | `Sync Restriction – DomainJoined – Prod` |
| Org sync allow list | `Sync Tenant Restriction – OrgOnly – Prod` |
| Default storage quota | `OneDrive Storage Quota – Default – Prod` |
| Orphaned-site retention | `OneDrive Retention – Orphaned – Prod` |
| OneDrive sharing alignment | `OneDrive Sharing – Aligned – Prod` |
| Offboarding manager access | `Offboarding Access – Manager – Prod` |
| Discovery baseline export | `OneDrive Baseline – Tenant – Discovery` |
| Governance report | `OneDrive Governance – Tenant – Report` |

## The standard deployment model
> Assess the current OneDrive posture → design the client-config, KFM, sync, storage, sharing, and
> offboarding baseline → configure it → roll to a **pilot** ring first → validate against explicit
> gates → expand tenant-wide, keeping a documented rollback for every high-impact change.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
