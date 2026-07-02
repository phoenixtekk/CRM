# OneDrive for Business

> **Version 1.0.0** · Category: Intune · Solution code: ODFB

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — OneDrive for Business (Microsoft Intune)

**White-label · Intune Solutions**

When files live only on a laptop, one lost, stolen, or wiped device means lost work — and a
ransomware hit can take a whole team offline. **OneDrive for Business** turns every user's
Desktop, Documents, and Pictures into cloud-backed, version-protected, roam-anywhere storage —
silently, with no user action required.

This solution is a complete, **deploy-it-today** package for configuring OneDrive for Business
on Windows devices using Microsoft Intune. It is written for an administrator with little or no
prior OneDrive policy experience: every requirement is verified before it is used, every
configuration step is exact and in order, and every result is testable.

## What you get
- A plain-language **Solution Overview** of what OneDrive for Business does and why it matters.
- A **Requirements Guide** with exactly what must be true first — and how to fix anything that isn't.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for readiness discovery, configuration validation, tenant usage reporting, safe remediation, and retrieving the Tenant ID needed for Known Folder Move.
- A **Testing Guide** that proves the rollout worked.
- A **Troubleshooting Guide** for the issues that actually occur in the field.

## The three capabilities this delivers
1. **Silent Sign-In** — OneDrive configures itself with the user's Windows credentials. No prompts.
2. **Known Folder Move (KFM)** — Desktop, Documents, and Pictures are redirected into OneDrive and backed up automatically.
3. **Files On-Demand** — files appear locally but download only when opened, saving disk space.

## The standard deployment model
Every Intune solution follows the same shape: **Assess → Configure → Pilot →
Validate → Expand.** Repeat buyers recognize the pattern, so each new deployment feels familiar.

## Outcome
Automatic, silent file backup and protection for your Windows fleet — ransomware resilience,
device-loss protection, and seamless roaming — deployable by a single administrator in a
controlled pilot within a day.


---


# 1. Solution Overview — OneDrive for Business

## What OneDrive for Business is
OneDrive for Business is Microsoft 365's per-user cloud file storage, paired with the **OneDrive
sync client** built into Windows 10 and Windows 11. Configured through Microsoft Intune, it
silently backs up each user's files to the cloud and keeps them synchronized across devices —
with no manual setup by the user.

## How it works
1. Intune delivers OneDrive **configuration policy** to the device (via the Settings Catalog).
2. **Silent Account Configuration** signs the OneDrive sync client in automatically using the
   user's existing Windows (Microsoft Entra) credentials — no sign-in prompt.
3. **Known Folder Move (KFM)** redirects the user's **Desktop, Documents, and Pictures** into
   their OneDrive folder. Existing content is moved up to the cloud and continues to sync.
4. **Files On-Demand** shows every file in File Explorer but downloads content only when a file
   is opened, so the cloud library never fills the local disk.
5. Changes sync continuously. Files are versioned in the cloud, so prior versions can be restored.

The user simply works as normal in Desktop/Documents/Pictures; everything is backed up behind the scenes.

## Capabilities delivered
- **Silent Sign-In** (`SilentAccountConfig`) — zero-touch account setup.
- **Known Folder Move** (`KFMSilentOptIn`) — automatic backup of Desktop/Documents/Pictures.
- **Files On-Demand** (`FilesOnDemandEnabled`) — disk-space-efficient sync.
- **Optional hardening** — block syncing of personal OneDrive accounts; restrict by file type; cap upload bandwidth.

## Benefits
- **Ransomware & device-loss resilience** — files live in the cloud, versioned and restorable.
- **Zero-touch for users** — no prompts, no manual folder setup.
- **Roaming** — the same Desktop/Documents/Pictures on any signed-in device.
- **Lower help-desk load** — fewer "I lost my files" and reimage-data-loss tickets.
- **Disk efficiency** — Files On-Demand keeps local storage lean.

## Limitations (be honest with buyers)
- Requires Microsoft 365 licensing that includes OneDrive for Business.
- KFM requires your **Microsoft Entra Tenant ID** in the policy (a script in this package retrieves it).
- Very large existing folders take time for the first upload; plan pilot timing accordingly.
- Known Folder Move covers Desktop/Documents/Pictures — not arbitrary custom folders.
- Some line-of-business apps that hardcode local paths may need testing against redirected folders.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Windows devices, Intune-managed, OneDrive configured via the Settings Catalog**
> (Silent Sign-In + Known Folder Move + Files On-Demand), assigned to a pilot group first.

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — OneDrive for Business

Verify **every** requirement below before you configure anything. Each entry follows the same
pattern: **Description · Why required · How to verify · How to implement if missing.** Do not
assume any prerequisite already exists.

> Category-wide prerequisites (a tenant, an Intune subscription, MDM enrollment, admin roles, a
> pilot group) are documented once in **`global-requirements-intune-solutions.md`**. This guide
> lists only what is specific to OneDrive for Business.

---

## 2.1 Microsoft licensing
**Description:** Licenses that include OneDrive for Business plus Intune management.
**Why required:** OneDrive for Business provides the cloud storage; Intune delivers the policy.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**. Confirm a plan that
includes OneDrive (Microsoft 365 Business Basic/Standard/Premium, or E3/E5, or Office 365) and an
Intune-bearing plan, assigned to every targeted user.
**How to implement if missing:** Assign Microsoft 365 Business Premium or E3/E5 (both include
OneDrive + Intune), or add the appropriate OneDrive and Intune Plan 1 licenses.

## 2.2 Microsoft Entra ID
**Description:** Devices are **Microsoft Entra joined** (or hybrid joined).
**Why required:** Silent Account Configuration uses the device's Entra identity to sign OneDrive in.
**How to verify:** On a device run `dsregcmd /status` → `AzureAdJoined : YES`.
**How to implement if missing:** Join during OOBE, or **Settings → Accounts → Access work or
school → Connect → Join this device to Microsoft Entra**.

## 2.3 Microsoft Intune (MDM)
**Description:** Targeted devices are enrolled in Intune.
**Why required:** Intune is how the OneDrive configuration reaches the device.
**How to verify:** Intune admin center → **Devices → All devices**; the device is listed and compliant.
**How to implement if missing:** Enable **Automatic Enrollment** (Intune → Devices → Enrollment) and join devices to Entra ID.

## 2.4 Microsoft Entra Tenant ID
**Description:** Your tenant's directory (tenant) GUID.
**Why required:** **Known Folder Move** policy (`KFMSilentOptIn`) requires the Tenant ID as its value.
**How to verify:** Entra admin center → **Overview → Tenant ID**, or run **`Get-TenantId.ps1`** (in this package).
**How to implement if missing:** It always exists — retrieve it with **`Get-TenantId.ps1`** and record it for Step-by-step configuration.

## 2.5 Windows operating system
**Description:** Windows 10 or Windows 11 with the built-in OneDrive sync client.
**Why required:** The sync client applies the policy and performs Silent Sign-In, KFM, and Files On-Demand.
**How to verify:** `winver` for the OS; the OneDrive client is at `%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe`.
**How to implement if missing:** Windows 10/11 ship with OneDrive. If removed, deploy the current OneDrive sync client (machine-wide install) as an Intune app.

## 2.6 OneDrive sync client version
**Description:** A current OneDrive sync client build.
**Why required:** Silent Account Configuration and KFM require a recent client.
**How to verify:** Run **`ODFB-Discovery.ps1`**, or check **Settings → About** in the OneDrive client.
**How to implement if missing:** Configure OneDrive to auto-update (default), or deploy the latest client via Intune.

## 2.7 Disk space (Files On-Demand)
**Description:** Sufficient free disk for at least the "always available" content.
**Why required:** Files On-Demand minimizes usage, but pinned/always-available files consume local space.
**How to verify:** **`ODFB-Discovery.ps1`** reports free space.
**How to implement if missing:** Free space or enable Files On-Demand (this solution does) so files stay cloud-only until opened.

## 2.8 Network
**Description:** Outbound HTTPS to OneDrive/SharePoint and Microsoft 365 endpoints.
**Why required:** Sync, sign-in, and KFM upload all call cloud endpoints.
**How to verify:** From a device, browse to `https://<yourtenant>-my.sharepoint.com`.
**How to implement if missing:** Allow Microsoft 365 (OneDrive/SharePoint) URLs/IPs through proxy/firewall;
do **not** SSL-inspect OneDrive traffic (Microsoft does not support it and it breaks sync).

## 2.9 Certificates
**Description:** None required.
**Why required (not):** OneDrive configuration uses Entra identity and Intune policy — no PKI or certificates.
**How to verify:** N/A.
**How to implement if missing:** N/A.

---

## Requirements checklist (use before configuring)
- [ ] M365 (OneDrive) + Intune licensing assigned to pilot users
- [ ] Devices Microsoft Entra joined — `dsregcmd /status`
- [ ] Devices enrolled in Intune and compliant
- [ ] **Tenant ID recorded** — `Get-TenantId.ps1`
- [ ] Windows 10/11 with current OneDrive sync client — `ODFB-Discovery.ps1`
- [ ] Network/proxy allows OneDrive/SharePoint endpoints (no SSL inspection)
- [ ] Pilot Entra security group created


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level on the marketplace so individual
solution listings stay small. Confirm these are in place before deploying *any* Intune solution.

Each entry: **Description · Why required · How to verify · How to implement if missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads and **Tenant administration → Tenant status** shows an active subscription.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator** (or Global Administrator for setup).
**Implement:** Assign **Intune Administrator** to the operator; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** (Intune → Devices → Enrollment) and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted to a small group before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists with intended members.
**Implement:** Entra → **Groups → New group** → type **Security** → add pilot members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current cumulative updates.
**Why:** Modern Intune features and security settings assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** (Intune → Devices → Windows → Update rings) or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — OneDrive for Business

Follow these steps **in order**. Each step must be complete before the next. All navigation is
in the **Microsoft Intune admin center** (`https://intune.microsoft.com`) unless stated otherwise.

> **Model:** Windows devices, Intune-managed, OneDrive configured via the **Settings Catalog**
> (Silent Sign-In + Known Folder Move + Files On-Demand), assigned to a pilot group first.

---

## Step 1 — Get your Microsoft Entra Tenant ID
Known Folder Move requires this value.

1. Open `https://entra.microsoft.com` → **Overview**.
2. Copy the **Tenant ID** (a GUID).
3. (Or run **`Get-TenantId.ps1`** from this package.) Record it for Step 5.

## Step 2 — Create the pilot security group
1. Open `https://entra.microsoft.com` → **Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `ODFB-Pilot`.
3. Add 3–5 pilot users. Click **Create**.

## Step 3 — Create the OneDrive configuration profile
1. Go to **Devices → Windows → Configuration**.
2. Click **+ Create → New Policy**.
3. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog**.
4. Click **Create**.
5. **Name:** `OneDrive - Pilot - Silent + KFM`. Click **Next**.

## Step 4 — Add the OneDrive settings
1. On **Configuration settings**, click **+ Add settings**.
2. In the picker search box, type **OneDrive**. Select the **OneDrive** category.
3. Add these settings (select each checkbox):
   - **Silently sign in users to the OneDrive sync app with their Windows credentials**
   - **Silently move Windows known folders to OneDrive**
   - **Use OneDrive Files On-Demand**
   - (Optional) **Prevent users from syncing personal OneDrive accounts**
4. Close the picker.

## Step 5 — Configure the setting values (in this order)
1. **Silently sign in users to the OneDrive sync app with their Windows credentials:** **Enabled**.
2. **Use OneDrive Files On-Demand:** **Enabled**.
3. **Silently move Windows known folders to OneDrive:** **Enabled**.
   - **Tenant ID:** paste the GUID from Step 1.
   - **Show notification to users after folders have been redirected:** **Disabled** (silent) or **Enabled** (inform users) — your choice.
4. (Optional) **Prevent users from syncing personal OneDrive accounts:** **Enabled**.
5. Click **Next**.

## Step 6 — Scope tags (optional)
1. On **Scope tags**, add tags if your org uses them, else click **Next**.

## Step 7 — Assign to the pilot group
1. On **Assignments**, under **Included groups**, click **Add groups**.
2. Select **`ODFB-Pilot`**. Click **Select**, then **Next**.

## Step 8 — Review and create
1. On **Review + create**, confirm every setting (especially the Tenant ID).
2. Click **Create**.

## Step 9 — (If OneDrive client is missing) deploy the sync client
Skip if OneDrive is already present (default on Windows 10/11).

1. Go to **Apps → Windows → Add → Microsoft Store app (new)** (or Win32) and add **OneDrive**.
2. Assign to **`ODFB-Pilot`** as **Required**.

## Step 10 — Sync and apply on a pilot device
1. On a pilot device, open **Settings → Accounts → Access work or school**, select the account, click **Info → Sync**.
2. Sign out and back in (or wait for the next policy cycle). OneDrive signs in silently and begins Known Folder Move.
3. Open **File Explorer** and confirm **Desktop, Documents, and Pictures** now appear under the OneDrive folder.

## Step 11 — Validate the pilot
1. Run **`ODFB-Validation.ps1`** on the pilot device → confirms Silent Sign-In, KFM, and Files On-Demand are applied.
2. Run **`ODFB-TenantReport.ps1`** → confirms pilot users have OneDrive provisioned and syncing.
3. Complete the **Testing Guide** (Section 5) before expanding.

## Step 12 — Expand to production
1. Once the pilot passes, add **`ODFB-Production`** (or broaden `ODFB-Pilot`) to the profile **Assignments**.
2. Roll out in waves (e.g. by department). Re-validate each wave with **`ODFB-Validation.ps1`** / **`ODFB-TenantReport.ps1`**.
3. Allow time for first-sync uploads on devices with large Desktop/Documents/Pictures folders.

---
### Order of operations (summary)
`Tenant ID → Pilot group → Create Settings Catalog profile → Add OneDrive settings → Set values (Silent → Files On-Demand → KFM+Tenant ID) → Assign → Apply on device → Validate → Expand`


---


# 5. Testing Guide — OneDrive for Business

Run these validations after the pilot device has applied policy (Implementation Step 11) and
again after each production wave. Each test states **what to do** and the **expected result**. Do
not expand the rollout until every test passes for the pilot group.

## Test 1 — Policy applied
**Do:** Intune admin center → **Devices → Configuration →** `OneDrive - Pilot - Silent + KFM` **→ Device/User check-in status**.
**Expected:** Pilot devices/users show **Succeeded**. No **Error** or **Conflict**.

## Test 2 — Silent Sign-In worked
**Do:** On a pilot device, look at the OneDrive cloud icon in the system tray (signed in, no prompt). Or run `ODFB-Validation.ps1`.
**Expected:** OneDrive is signed in with the work account automatically — the user was never prompted. Registry `SilentAccountConfig = 1`.

## Test 3 — Known Folder Move applied
**Do:** Open **File Explorer**. Check the location of **Desktop**, **Documents**, and **Pictures** (right-click → Properties → Location), or run `ODFB-Validation.ps1`.
**Expected:** All three point into the OneDrive folder (path contains **OneDrive - <Org>**). Existing files were moved up and continue to sync.

## Test 4 — Files On-Demand active
**Do:** In File Explorer, view the **Status** column in the OneDrive folder.
**Expected:** Files show cloud / "Available when online" badges (not all forced local). Registry `FilesOnDemandEnabled = 1`.

## Test 5 — Sync works (round-trip)
**Do:** Create a test file on the Desktop. Sign in to `https://<tenant>-my.sharepoint.com` in a browser.
**Expected:** The test file appears in OneDrive online within a minute. Delete it online; it disappears locally.

## Test 6 — Version history / ransomware recovery
**Do:** Edit and save a synced document twice. In OneDrive online, right-click the file → **Version history**.
**Expected:** Multiple versions are listed and can be restored — the basis for ransomware recovery.

## Test 7 — Compliance remains intact
**Do:** Intune → **Devices → Compliance**; review the pilot devices after OneDrive configuration.
**Expected:** Devices remain **Compliant**; no new compliance failures were introduced.

## Test 8 — Tenant usage report
**Do:** Run **`ODFB-TenantReport.ps1`** (Microsoft Graph).
**Expected:** Pilot users appear with OneDrive provisioned and non-zero storage used / files synced.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 (and 7–8) all pass for **100%** of the pilot group |
| **Wave pass** | Tests 1–5, 7 pass for the wave before starting the next |

Record results in your change log. If any test fails, use the **Troubleshooting Guide** (Section 6)
and the **`ODFB-Remediation.ps1`** script before proceeding.


---


# 6. Troubleshooting Guide — OneDrive for Business

Work top to bottom. Most field issues are an unsynced policy, a missing/old OneDrive client, or a
KFM policy with the wrong (or missing) Tenant ID. Use **`ODFB-Validation.ps1`** to confirm state
and **`ODFB-Remediation.ps1`** for the safe fixes.

## A. Common deployment issues
| Symptom | Likely cause | Remediation |
|---|---|---|
| Profile shows **Error/Conflict** in Intune | Another OneDrive policy (GPO or second profile) conflicts | Keep one authoritative Settings Catalog profile; remove duplicate GPO/profile |
| Policy never reaches device | Device not synced / not enrolled | Run **`ODFB-Remediation.ps1`** (forces MDM sync); confirm device in **Devices → All devices** |
| Settings apply to nobody | Wrong assignment | Confirm `ODFB-Pilot` is under the profile's **Included groups** and users are members |

## B. Silent Sign-In failures
| Symptom | Cause | Remediation |
|---|---|---|
| OneDrive prompts the user to sign in | `SilentAccountConfig` not applied, or device not Entra joined | Confirm `dsregcmd /status` shows `AzureAdJoined : YES`; sync policy; check `SilentAccountConfig = 1` |
| Signs in to the wrong/personal account | Personal sync allowed | Enable **Prevent users from syncing personal OneDrive accounts** |
| Nothing happens at all | OneDrive client missing or outdated | Deploy/update the client (Implementation Step 9); run **`ODFB-Discovery.ps1`** |

## C. Known Folder Move (KFM) not applied
- **KFM policy value missing/blank** → the policy needs the **Tenant ID** GUID. Retrieve it with **`Get-TenantId.ps1`** and set it in the policy.
- **Folders still local** → confirm `KFMSilentOptIn` shows your Tenant ID (`ODFB-Validation.ps1`); a folder containing a OneDrive-incompatible item (e.g. a PST, OneNote, or a path too long) can block the move — resolve the blocking item, then re-sync.
- **"Make sure files are saved" / blocked** → an open file or unsupported file type in a known folder. Close apps; OneDrive retries automatically.

## D. Sync problems
- Run **`ODFB-Remediation.ps1`** (restart). If still broken, **`ODFB-Remediation.ps1 -ResetSync`** (re-initializes sync; cloud files are not deleted).
- Check the OneDrive activity center (cloud tray icon) for specific file errors (path too long >400 chars, invalid characters, file > size limit).
- Ensure the network/proxy is **not SSL-inspecting** OneDrive traffic — Microsoft does not support it and it breaks sync.

## E. Files On-Demand issues
- Status column not showing cloud badges → confirm `FilesOnDemandEnabled = 1` and a current client; Files On-Demand requires the modern client and NTFS.
- Users complain files won't open offline → teach **right-click → Always keep on this device** for must-have-offline files.

## F. Policy conflicts
- Only **one** OneDrive configuration source should be authoritative. Do not mix a legacy on-prem **GPO** (`HKLM\SOFTWARE\Policies\Microsoft\OneDrive`) and the Intune Settings Catalog profile — disable the GPO or scope it away from Intune-managed devices.

## G. Diagnostics quick reference
```powershell
dsregcmd /status                                   # Entra join (needed for Silent config + Tenant ID)
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'   # applied OneDrive policy values
%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe /reset           # re-initialize sync (no cloud deletion)
```
Logs: `%LOCALAPPDATA%\Microsoft\OneDrive\logs`. Event logs: **Applications and Services Logs → Microsoft → Windows → Shell-Core / User Device Registration**.

## H. When to escalate
If a device passes **`ODFB-Discovery.ps1`** (supported OS, client present, Entra joined), the
profile shows **Succeeded**, the Tenant ID is correct, and KFM still won't apply after a sync
reset, collect the OneDrive logs and open a Microsoft 365 support case.


---


# 7. Best Practices — OneDrive for Business

- **Always pilot first.** Deploy to `ODFB-Pilot` (3–5 users), validate fully, then expand in waves. Large Desktop/Documents/Pictures folders make the first sync slow — pilot reveals timing.
- **One authoritative source.** Govern OneDrive only through the Intune Settings Catalog profile. Retire legacy GPOs that set the same registry keys.
- **Get the Tenant ID right.** KFM silently fails without a valid Tenant ID — verify it with `Get-TenantId.ps1` and double-check it in **Review + create**.
- **Enable Files On-Demand.** It keeps local disks lean and makes KFM safe on small-SSD devices.
- **Block personal accounts** where data governance matters (**Prevent users from syncing personal OneDrive accounts**).
- **Communicate to users.** A short heads-up ("your Desktop, Documents, and Pictures are now backed up to OneDrive automatically") prevents confusion and tickets.
- **Stage large migrations.** Roll out KFM by department/wave so first-sync uploads don't saturate the network at once.
- **Never SSL-inspect OneDrive traffic.** It is unsupported and breaks sync — exclude OneDrive/SharePoint URLs from inspection.
- **Teach "Always keep on this device"** for the few files users truly need offline (travel, field work).
- **Measure adoption.** Run `ODFB-TenantReport.ps1` on a schedule to track provisioning and storage growth, and catch users who never synced.
- **Protect against ransomware.** OneDrive version history + Files Restore is your recovery path — confirm version history works (Testing Test 6) and document the restore procedure for the help desk.


---


# 8. Deliverables Summary — OneDrive for Business

Everything included in this solution package.

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What OneDrive for Business does, how it works, benefits, limitations, the deployment model |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered, click-by-click Intune steps |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `Get-TenantId.ps1` | Retrieves the Microsoft Entra Tenant ID needed for Known Folder Move |
| `ODFB-Discovery.ps1` | Device readiness: OS, OneDrive client/version, Entra join, disk space |
| `ODFB-Validation.ps1` | Confirms Silent Sign-In, Known Folder Move, and Files On-Demand are applied |
| `ODFB-TenantReport.ps1` | Tenant-wide OneDrive usage/adoption report (Microsoft Graph) |
| `ODFB-Remediation.ps1` | Safe remediation; `-ResetSync` re-initializes sync (no cloud deletion) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Automatic, silent file backup and protection — Desktop, Documents, and Pictures redirected to
OneDrive, synced and versioned, with ransomware and device-loss resilience — deployable by a
single administrator and validated before every expansion.
