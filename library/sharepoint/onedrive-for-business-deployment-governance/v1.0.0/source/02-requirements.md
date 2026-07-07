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
