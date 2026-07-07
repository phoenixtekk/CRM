# OneDrive for Business Deployment & Governance

> **Version 1.0.0** · Category: SharePoint · Solution code: ODFBGOV

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — OneDrive for Business Deployment & Governance

## The outcome
User files protected, synced, and governed. OneDrive for Business is deployed **silently** to every
managed device, Desktop/Documents/Pictures are **redirected into OneDrive** (Known Folder Move) so a
lost or reimaged laptop no longer means lost data, sync is **restricted to managed devices**, storage
and retention are set to governed values, sharing is **aligned to policy**, and when an employee
**leaves**, their files are preserved and handed to their manager — not orphaned or destroyed.

## The approach
The solution follows a disciplined, pilot-first model — **Assess → Design → Configure → Pilot →
Validate → Expand** — using only Microsoft-native tooling: the Microsoft 365 and SharePoint admin
centers, the OneDrive client policies (Intune or Group Policy ADMX), the SharePoint Online Management
Shell / PnP PowerShell, and Microsoft Graph. It configures the full OneDrive lifecycle in one coherent
pass:

- **Silent client deployment** — the sync client signs users in with their Windows credentials, no prompts.
- **Known Folder Move** — Desktop, Documents, and Pictures move into OneDrive automatically, opt-out blocked.
- **Sync controls** — sync limited to domain-joined devices, personal accounts blocked, risky file types excluded, and (optionally) unmanaged browser sessions restricted to web-only.
- **Storage, retention & sharing** — a governed default quota, a deliberate orphaned-OneDrive retention window, and OneDrive sharing aligned to (never exceeding) the organization's sharing policy.
- **Offboarding** — a manager-access-and-retention step so departing users' data is retrievable, with legal/records holds deferred to compliance.

Five PowerShell tools — discovery, a `-WhatIf` configuration helper, a `-WhatIf` offboarding helper, a
governance report, and a scope/identifier helper — make the work repeatable and auditable.

## Why it's low-risk
- **Pilot-first with explicit gates.** Every high-impact change (sync, sharing, retention, KFM) is
  validated on a named pilot ring against pass/fail tests before any tenant-wide rollout, and each
  change has a documented rollback.
- **Safe-by-default automation.** Every script is read-only or requires an explicit `-Commit`/`-WhatIf`
  preview; none stores credentials or secrets.
- **Native and reversible.** No third-party tooling; all settings are standard Microsoft controls that
  can be reverted to the recorded baseline.
- **Compliance stays with compliance.** Retention and legal-hold **determinations** are deferred to the
  organization's records and legal functions — the solution provides the technical method and evidence,
  not the determination.

The result is the difference between OneDrive as an uncontrolled liability and OneDrive as a governed,
protected, and cost-managed part of the estate — delivered self-guided, tested, at a fraction of
consulting cost.


---


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


---


# 2. Requirements — OneDrive for Business Deployment & Governance

These are the **solution-specific** prerequisites for deploying and governing OneDrive for Business.
They build **on top of** the shared SharePoint-category prerequisites in
`global-requirements-sharepoint.md` — read that first. It already covers the six shared items:
(1) a Microsoft 365 tenant with SharePoint Online / OneDrive and the right licensing, (2)
least-privilege SharePoint administrative access, (3) the SPO Management Shell / PnP + Graph
toolchain, (4) the identity/group source of truth, (5) a pilot scope and change control, and (6)
security/compliance/records stakeholders. Do **not** re-verify those here; verify the OneDrive-specific
items below.

Each requirement is stated as **Description / Why / Verify / Implement if missing**.

---

## 1. A managed device fleet with a client-policy channel (Intune or Group Policy)
- **Description:** A population of managed Windows devices reachable by **Microsoft Intune** (Settings
  Catalog / Administrative Templates — ADMX-backed) **or** on-prem **Group Policy** with the current
  OneDrive **`OneDrive.admx`/`.adml`** in the domain Central Store. macOS devices, if in scope, are
  governed by the equivalent OneDrive `.plist` configuration profile.
- **Why required:** Silent sign-in, KFM, Files On-Demand, and sync restrictions are **client policies**
  delivered to the device — without a policy channel they cannot be enforced at scale.
- **Verify:** Confirm devices are Intune-enrolled (or domain-joined with GPO applying) and that the
  OneDrive ADMX is present in the Central Store (`\\<domain>\SYSVOL\<domain>\Policies\PolicyDefinitions\OneDrive.admx`),
  or that the OneDrive Administrative Templates appear in Intune's Settings Catalog.
- **Implement if missing:** Enroll devices in Intune, or download the current OneDrive ADMX/ADML from
  the sync client install folder (`%localappdata%\Microsoft\OneDrive\<version>\adm\`) into the Central Store.

## 2. Devices Entra joined / hybrid joined for silent sign-in
- **Description:** In-scope devices are **Microsoft Entra joined** or **hybrid Entra joined** with the
  user signed in under their corporate account.
- **Why required:** `SilentAccountConfig` signs the user in with their Windows/Entra credentials; it
  can only complete when the device carries a usable primary work account. On workgroup or personal
  devices the user must sign in interactively.
- **Verify:** `dsregcmd /status` shows `AzureAdJoined : YES` (or `DomainJoined : YES` + `AzureAdJoined
  : YES` for hybrid) on a sample device.
- **Implement if missing:** Bring devices into Entra join / hybrid join before relying on silent sign-in.

## 3. Tenant ID and Active Directory domain GUID(s) captured
- **Description:** The **Microsoft 365 tenant ID** (a GUID) and, where domain-join sync restriction is
  used, the **on-prem AD domain GUID(s)**.
- **Why required:** The KFM **Silently move known folders** policy is keyed to the **tenant ID**, and
  **Allow syncing only on computers joined to specific domains** is keyed to **domain GUIDs** — the
  wrong GUID silently no-ops the policy.
- **Verify:** Tenant ID from the Entra admin center (Overview) or `ODFBGOV-Set-Scope.ps1
  -TenantOnlyLookup`; domain GUID from `(Get-ADDomain).ObjectGUID` or `ODFBGOV-Set-Scope.ps1
  -ResolveDomainGuids`.
- **Implement if missing:** Retrieve and record both before authoring the client policies.

## 4. Storage-quota and retention policy decided
- **Description:** A decided **default OneDrive storage quota** (and any per-role overrides) and the
  **orphaned-OneDrive retention period** (30–3650 days) for departed users.
- **Why required:** Both are governed baselines; the retention period is also the **hard deletion
  timer** for a leaver's OneDrive, so it must be set deliberately with compliance input, not left at default.
- **Verify:** Current values via `Get-SPOTenant` (`OneDriveStorageQuota`,
  `OrphanedPersonalSitesRetentionPeriod`); confirm the target values are agreed with storage/records owners.
- **Implement if missing:** Agree the target quota and retention window with the storage and
  compliance/records stakeholders (GR item 6) before configuring.

## 5. Org-level SharePoint sharing baseline known (sharing alignment ceiling)
- **Description:** The tenant's **org-level SharePoint external sharing** setting, which is the ceiling
  OneDrive sharing cannot exceed.
- **Why required:** `OneDriveSharingCapability` can be set equal to or **more restrictive** than the
  org SharePoint setting, never more permissive — so the org baseline must be known to align OneDrive.
- **Verify:** `Get-SPOTenant | Select SharingCapability, OneDriveSharingCapability`.
- **Implement if missing:** Confirm the org sharing baseline (often set by the External Sharing solution)
  before aligning OneDrive.

## 6. Offboarding process and delegate model agreed
- **Description:** An agreed **offboarding** process naming who receives access to a departing user's
  OneDrive (typically the **manager**) and for how long, and where legal/records **holds** are decided.
- **Why required:** The offboarding step grants operational access and relies on retention to preserve
  data; the **hold determination** is a compliance/records decision that must be owned before an account
  is deleted.
- **Verify:** Confirm the HR/IT joiner-mover-leaver process references a OneDrive handoff step and a
  compliance checkpoint.
- **Implement if missing:** Define the delegate model and the compliance hold checkpoint with HR,
  records, and legal before running offboarding at scale.

---

*Compliance and legal determinations — retention schedules, legal-hold decisions, and records
classification of OneDrive content — are **deferred** to the organization's compliance, records, and
legal functions. This solution provides the technical method (retention period, manager access,
evidence) and defers the determination.*


---


# Global Requirements — SharePoint Online & OneDrive Solutions

These requirements apply to **every** solution in the **SharePoint** category (SharePoint Online
architecture & provisioning, external sharing, OneDrive for Business, migration to SPO, permissions,
search, and records/retention). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every SharePoint solution).** The **SharePoint admin center**, the
> **Microsoft 365 admin center**, the **SharePoint Online Management Shell** and **PnP PowerShell**,
> and **Microsoft Graph** are authored at exact, current click-by-click / cmdlet detail from Microsoft's
> public documentation. Where a capability, setting, or portal path is **plan- or version-dependent**
> (storage limits, sharing controls, Syntex/records features, Commercial vs Government cloud), it is
> **cited or flagged "verify in your tenant"** — never invented. **Third-party migration and governance
> tools** (e.g. ShareGate, Migration Manager, AvePoint) are integrated at the pattern level; their
> consoles are deferred to the vendor's docs. Automation is **PowerShell** (SPO Management Shell / PnP /
> Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with SharePoint Online / OneDrive and licensing
- **Description:** A Microsoft 365 tenant with **SharePoint Online** and **OneDrive for Business** and
  the licensing the capability requires (e.g. an E-plan for advanced records/retention, Syntex where used).
- **Why required:** All site, sharing, OneDrive, and records configuration depends on the right plan.
- **How to verify:** In the M365 admin center confirm the SharePoint/OneDrive subscription and add-ons.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Administrative access (least-privilege SharePoint roles)
- **Description:** Access with the least-privilege role the solution names — typically **SharePoint
  Administrator** (and Global Administrator only where genuinely required, e.g. tenant-wide sharing).
- **Why required:** Tenant/site settings, sharing, provisioning, and records changes require the role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. SharePoint Online Management Shell / PnP + Graph toolchain
- **Description:** A workstation with the **SharePoint Online Management Shell** and/or **PnP
  PowerShell** (and Graph PowerShell where used), modern-auth / MFA-capable admin sign-in (PnP app
  registration where required).
- **Why required:** Configuration, automation, and the provided scripts run through SPO/PnP/Graph.
- **How to verify:** `Connect-SPOService` / `Connect-PnPOnline` succeeds; modules installed.
- **How to implement if missing:** Install the modules; register the PnP app where needed; confirm sign-in.

## 4. Information architecture & identity/group source of truth
- **Description:** A defined **information-architecture** intent (hub/site structure, taxonomy) and the
  identity/group source (Entra ID groups, M365 Groups backing team sites) that drives access.
- **Why required:** Provisioning, permissions, search, and governance key off the IA and groups.
- **How to verify:** Confirm the intended hub/site structure and which groups model is authoritative.
- **How to implement if missing:** Define the IA and group model (often the Architecture solution) first.

## 5. A pilot scope and change control
- **Description:** A **pilot site collection / hub / user set** to validate on before tenant-wide
  rollout, and a **change-control** process for production changes (sharing, permissions, retention,
  migration cutover are high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; tenant-wide sharing/permission/retention changes are high-impact.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

## 6. Security, compliance & records stakeholders
- **Description:** Engagement with the **security, compliance/records, and data-governance** stakeholders
  whose policies the configuration must satisfy (external sharing, permissions, retention/records,
  sensitivity).
- **Why required:** Sharing, permission, and records settings must align to enterprise policy.
- **How to verify:** Confirm the applicable policies and named approvers.
- **How to implement if missing:** Identify the owners and capture requirements before configuring governance.

*The deployment model across every SharePoint solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (SPO Management Shell / PnP / Graph) — never with
hardcoded credentials or secrets in code.*


---


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


---


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


---


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


---


# 7. Best Practices — OneDrive for Business Deployment & Governance

Durable practices that keep OneDrive deployed, governed, and low-risk after the initial rollout.

## Deployment & client
- **Silent sign-in + KFM together, always.** Silent sign-in without KFM leaves Desktop/Documents/
  Pictures on the device — the very data-loss gap you deployed to close. Pair `SilentAccountConfig`
  with `KFMSilentOptIn` in the same profile so protection is complete the moment the client signs in.
- **Block the opt-out.** Set `KFMBlockOptOut = 1` so users can't move known folders back to the PC and
  silently re-open the data-loss gap. Use the notification variant so users understand the change.
- **Keep the client current, don't repackage it.** OneDrive updates itself on its release ring; prefer
  the built-in current ring over pinning an old standalone build. Only use per-machine standalone
  install where your device model genuinely requires it (e.g. non-persistent VDI).
- **Enable Files On-Demand.** `FilesOnDemandEnabled = 1` avoids filling local disks on first sync of a
  large OneDrive — essential for KFM at scale.

## Sync governance
- **Restrict sync to managed devices.** Always enable the domain-join allow-list
  (`Sync Restriction – DomainJoined – Prod`) so corporate data only syncs to devices you manage, and
  block personal accounts (`DisablePersonalSync`) so corporate and personal data never mix on a device.
- **Block risky file types at the tenant.** Exclude extensions that should never sync (e.g. `pst`) via
  `Set-SPOTenantSyncClientRestriction -ExcludedFileExtensions`.
- **Use web-only access for unmanaged sessions** (`ConditionalAccessPolicy = AllowLimitedAccess`) so
  browser access from unmanaged devices can't download, print, or sync — verify the licensing first.
- **Prefer ADMX/Intune over hand-edited registry.** Deploy client policies through the OneDrive ADMX in
  Intune/GPO, not by pushing raw registry values — the ADMX carries the correct, build-matched value names.

## Storage, retention & sharing
- **Set a deliberate default quota, override by exception.** A governed default
  (`OneDrive Storage Quota – Default – Prod`) with per-role overrides beats an unbounded max that hides
  cost and hoards stale data. Review near-quota accounts from the governance report.
- **Set the orphaned-retention window with records, not by default.** It is the **hard deletion timer**
  for a departed user's OneDrive — agree it with compliance/records and document it.
- **Keep OneDrive sharing aligned to (≤) org sharing.** Re-check `OneDriveSharingCapability` against org
  `SharingCapability` after any sharing change so OneDrive never drifts more permissive than policy.

## Offboarding & lifecycle
- **Grant, retrieve, then revoke.** Grant the manager site-collection admin only for the handoff window
  and remove it (`IsSiteCollectionAdmin $false`) once files are retrieved — don't leave standing access.
- **Confirm holds before deletion.** Never delete a departed user's account until compliance confirms no
  legal/records hold applies — the retention window is a timer, not a hold, and not a backup.
- **Automate the manager-access grant** on deletion (SharePoint admin center Retention/Notifications) so
  offboarding is consistent, not ad-hoc.

## Operate & assure
- **Report on a cadence.** Run `ODFBGOV-Report.ps1` regularly and act on NearQuota (≥90%) and Stale
  accounts; a downward stale trend means governance is working.
- **Pilot every high-impact change.** Sync, sharing, retention, and KFM changes are tenant-wide — always
  validate on `OneDrive Pilot Ring – Users – Stage1` with the go/no-go gate before broad rollout, and
  keep the documented rollback ready.
- **Preview before you commit.** Run `ODFBGOV-Configure.ps1` and `ODFBGOV-Set-OffboardingAccess.ps1`
  without `-Commit` (or with `-WhatIf`) first; commit only after the change table is reviewed.
- **Verify plan- and cloud-dependent behavior in your tenant.** Storage maxima, some sharing controls,
  and admin URLs differ by plan and between Commercial and Government clouds — confirm, don't assume.


---


# 8. Deliverables Summary — OneDrive for Business Deployment & Governance

Everything included in this solution, on one page.

## Documentation
| Document | What it gives you |
|---|---|
| **01 – Solution Overview** | The OneDrive model: silent client deployment, KFM, sync controls, storage/retention, sharing alignment, and offboarding — plus the reference design and the artifact naming convention. |
| **02 – Requirements** | The six OneDrive-specific prerequisites (managed-device policy channel, Entra join for silent sign-in, tenant ID + domain GUIDs, storage/retention decision, org sharing ceiling, offboarding model) — each with Verify / Implement — building on the SharePoint category global requirements. |
| **03 – Implementation** | Exact, ordered, pilot-first steps: Assess → Design → Configure (client, KFM, sync, storage/retention/sharing, offboarding) → Pilot → Validate → Expand, with pass/fail gates and a documented rollback. Every artifact named. |
| **05 – Testing & Validation** | Eight validation tests (silent sign-in, KFM, sync restriction, personal-sync block, quota/retention, sharing alignment, offboarding access, governance report), each with expected pass/fail, and the go/no-go gate. |
| **06 – Troubleshooting** | The common failure modes (silent sign-in not working, KFM blocked, sync not blocked/over-blocked, offboarding access, report empty) with root cause and resolution. |
| **07 – Best Practices** | Durable practices for client, sync, storage/retention/sharing, offboarding, and ongoing assurance. |
| **Executive Summary** | The outcome, approach, and why the rollout is low-risk — for approvers. |

## PowerShell scripts (5) — safe by default (read-only or `-WhatIf`)
| Script | What it does |
|---|---|
| **ODFBGOV-Discovery.ps1** | **Read-only.** Assesses the OneDrive posture: tenant default quota, orphaned-site retention, OneDrive sharing capability, conditional/limited access, sync-client restriction, provisioned OneDrive sites, and (optional) Graph usage — writes the `OneDrive Baseline – Tenant – Discovery` export. |
| **ODFBGOV-Configure.ps1** | **Dry-run by default (`-WhatIf` / no `-Commit`).** Tenant sync-control + storage/retention/sharing helper: sets default quota, orphaned retention, `OneDriveSharingCapability`, web-only access, and the domain-join sync allow-list — previews every change (current → proposed) before applying with `-Commit`. |
| **ODFBGOV-Set-OffboardingAccess.ps1** | **Dry-run by default.** Offboarding/data-retention helper: resolves a departing user's OneDrive, grants the manager site-collection admin for handoff, and reports the retention window — never deletes anything; legal/records hold deferred to compliance. |
| **ODFBGOV-Report.ps1** | **Read-only.** Governance report: per-OneDrive storage used vs quota (headroom %), last activity, sharing, and NearQuota/Stale flags, to CSV/HTML — the `OneDrive Governance – Tenant – Report`. |
| **ODFBGOV-Set-Scope.ps1** | **Read-only helper.** Resolves the tenant ID (KFM + tenant sync restriction) and AD domain GUID(s) (domain-join sync restriction), and emits a reviewed `.reg` reference template of the documented client policy value names. |

All scripts use modern-auth `Connect-*` (no stored credentials or secrets), default to read-only or
`-WhatIf`, and require `-Commit` to write. Cmdlet/parameter and portal detail follow Microsoft public
documentation; plan- and cloud-dependent behavior (storage maxima, Government cloud URLs) is flagged
**"verify in your tenant."**
