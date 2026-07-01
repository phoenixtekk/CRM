# Device Enrollment, Identity Association & Asset Inventory (Intune)

> **Version 1.0.0** · Category: Intune Solutions · Solution code: ENROLLID

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Device Enrollment, Identity Association & Asset Inventory (Microsoft Intune)

A service desk cannot support what it cannot see. When devices are not reliably enrolled, are not
tied to the right person, and are not tracked in an accurate inventory, every ticket starts with
detective work and assets quietly go missing. This package establishes clean **device enrollment**,
correct **identity association** (primary user / device identity), and an accurate, reconciled
**asset inventory** in **Microsoft Intune** — so the inventory becomes a source of truth the service
desk can trust.

This is a complete, **deploy-it-today** package, written for an administrator with no prior
enrollment or device-identity experience: every object is named for you, every step is click-by-click,
and a pilot proves it before you expand.

## What you get
- A plain-language **Solution Overview** of the enrollment methods (Autopilot, Entra join + automatic
  enrollment, bulk/DEM, BYOD), the primary-user / device-identity model, and the Intune inventory.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for enrollment/identity discovery, per-device validation, an inventory
  reconciliation and gap report, safe remediation (fix primary-user / stale records), and a
  device-scope group builder.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A repeatable enrollment posture — the right enrollment methods enabled, **enrollment restrictions**
that allow only the platforms you support, **automatic enrollment** for Entra-joined Windows, and an
**enrollment status page** that gates first sign-in — every device associated with the correct
**primary user**, stale and duplicate records cleaned up, and a reconciled inventory the service desk
can search to start every ticket with the facts.

## The Phoenixtekk deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every device enrolled, tied to the right user, and accounted for in a reconciled Intune inventory —
so the service desk starts every ticket with the facts — proven on a pilot before you scale.


---


# 1. Solution Overview — Device Enrollment, Identity Association & Asset Inventory

## What this is
Device enrollment is how a device becomes managed by Microsoft Intune; identity association is the
link between that device and the person who uses it (its **primary user**); and asset inventory is
the record Intune keeps of every managed device. Together they answer the three questions a service
desk asks on every ticket: *Is this device managed? Who owns it? Is it the device we think it is?*
This solution establishes all three so Intune becomes the **reconciled source of truth** for the
fleet.

## Why it matters
- **You can only support what is enrolled.** Policies, compliance, and remote actions reach managed
  devices only. An unenrolled device is invisible to the service desk.
- **The primary user is how tickets find the device.** When a user calls, the desk searches by name;
  the right **primary user** association is what surfaces the correct device, its compliance, and its
  apps. A wrong or missing primary user means every call starts with guesswork.
- **An inventory you cannot trust is worse than none.** Stale records (devices long since retired),
  duplicates (re-enrolled hardware), and devices that never enrolled all corrupt the count. A
  reconciled inventory is what lets you spot the gaps — and the missing assets.

## The enrollment methods (what to use, when)
1. **Windows Autopilot** — the device ships, the user signs in, and it provisions itself
   (Entra-joined, Intune-enrolled, with the apps and policies pre-staged). Best for new corporate
   Windows hardware. The **enrollment status page** can block the desktop until setup completes.
2. **Entra join + automatic enrollment** — a user (or IT) joins the device to Entra ID and, because
   automatic enrollment is on, it enrolls in Intune in the same step. Best for existing corporate
   Windows devices joining directly.
3. **Bulk enrollment / Device Enrollment Manager (DEM)** — a single provisioning package or a
   special DEM account enrolls many shared/kiosk devices that are not tied to one user. Best for
   shared hardware where a per-user primary association is not wanted.
4. **BYOD (personal devices)** — users enroll their own devices through the Company Portal under a
   personal-device enrollment profile, typically with lighter management. Best when staff use
   personal hardware to reach work resources.

## Enrollment restrictions (the gate)
**Enrollment restrictions** decide which platforms and which kinds of devices (personal vs.
corporate) are even allowed to enroll, and how many devices a user may enroll. They are the gate that
keeps the inventory clean: if you only support corporate Windows, restrictions stop personal phones
and unsupported platforms from cluttering the fleet.

## Primary user / device-identity association
Every Intune-managed device has a **primary user** — the account Intune treats as the device's owner
for licensing, app targeting, and service-desk lookup. Autopilot and user-driven enrollment set it
automatically to the enrolling user; shared/DEM devices have **no** primary user by design. When the
primary user is wrong (device reassigned, enrolled by a technician, imported from another system),
the service desk searches by the user and finds nothing — so correcting and maintaining this
association is central to a trustworthy inventory.

## Intune inventory as the source of truth
Intune records each managed device with its name, owner (primary user), platform, compliance, serial
number, and last check-in. Reconciliation compares that record against reality — flagging stale
records (no check-in for weeks), duplicates (same serial, multiple records), missing primary users,
and devices that should be enrolled but are not. The reconciled result is what the service desk
trusts.

## What you can control
- **Which enrollment methods are enabled** and how each is configured (Autopilot profile, automatic
  enrollment, BYOD profile, DEM accounts).
- **Enrollment restrictions** — allowed platforms, personal vs. corporate, and the per-user device
  limit.
- **The enrollment status page** — what the user sees during Autopilot and whether the desktop is
  blocked until setup completes.
- **Primary-user association** — read, correct, or clear it per device.
- **Inventory reconciliation** — which records are stale, duplicate, or missing an owner.

## Limitations (be honest with buyers)
- Intune inventory covers **enrolled** devices; truly off-grid hardware that never enrolled won't
  appear until it does — reconciliation surfaces the gap but cannot conjure the device.
- Some hardware/asset fields (purchase date, cost, location) live in a procurement/CMDB system, not
  Intune; reconciliation can compare against an exported list but Intune is not a full ITAM tool.
- Shared/DEM devices intentionally have **no** primary user — don't "fix" them to one.
- Apple/Android enrollment methods exist but each needs its own connector/credentials; this solution
  centers on the cross-platform model with Windows as the worked example.

## The standard Phoenixtekk deployment model
> **Enable the enrollment methods you support → set enrollment restrictions and automatic enrollment
> → establish the primary-user rules → enroll/import a pilot → reconcile and validate the inventory →
> expand to the fleet.** Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Device Enrollment, Identity Association & Asset Inventory

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1 or via M365 E3/E5 / Business Premium) for every enrolled user/device.
**Why:** Enrollment, primary-user association, and inventory all require an Intune license.
**Verify:** M365 admin center → **Billing → Licenses**; users who will enroll have Intune assigned.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 MDM authority and automatic enrollment
**Description:** Intune set as the MDM authority, with automatic enrollment configured for Windows.
**Why:** Automatic enrollment is what enrolls an Entra-joined Windows device into Intune in one step.
**Verify:** Intune → **Devices → Enrollment → Automatic Enrollment**; **MDM user scope** is **All**
(or your pilot group).
**Implement:** Set **MDM user scope** to your enrollment group; leave MAM scope as your policy.

## 2.3 Enrollment restrictions reviewed
**Description:** Device-platform and device-limit enrollment restrictions that match what you support.
**Why:** Restrictions keep the inventory clean — only allowed platforms/ownership types enroll.
**Verify:** Intune → **Devices → Enrollment → Enrollment restrictions**; review the **Default**
device-platform restriction; run `ENROLLID-Discovery.ps1`.
**Implement:** Create a platform restriction allowing only the platforms/ownership you support
(see Implementation Step 3).

## 2.4 Identity model for primary user
**Description:** A clear rule for who the primary user should be (the day-to-day user of the device).
**Why:** Service-desk lookup, app targeting, and licensing all key off the primary user.
**Verify:** Intune → **Devices → All devices →** open a device → **Properties → Primary user**;
run `ENROLLID-Validation.ps1` against a pilot device.
**Implement:** Adopt the rule "primary user = the enrolling/daily user; shared & DEM devices have
none," then correct exceptions with `ENROLLID-Remediation.ps1`.

## 2.5 Enrollment status page (Autopilot/Windows)
**Description:** An enrollment status page (ESP) profile controlling first sign-in setup.
**Why:** The ESP gates the desktop until apps/policies install, so the device is ready before use.
**Verify:** Intune → **Devices → Enrollment → Enrollment Status Page**; the **Default** profile (or
your named profile) is configured.
**Implement:** Configure the ESP profile (see Implementation Step 5).

## 2.6 (Autopilot) Hardware hash / device import path
**Description:** A way to register corporate devices (OEM/partner registration or imported hardware hashes).
**Why:** Autopilot provisioning needs the device's hardware identity registered to your tenant.
**Verify:** Intune → **Devices → Enrollment → Windows → Devices**; corporate devices are listed.
**Implement:** Have the OEM/CSP register devices, or import hardware hashes (CSV) for existing
hardware.

## 2.7 Inventory reconciliation source (optional but recommended)
**Description:** An external list of devices that *should* exist (procurement/CMDB/HR export, CSV).
**Why:** Reconciliation compares Intune against an authoritative "should exist" list to find gaps.
**Verify:** You have a CSV of expected devices (serial number and/or device name).
**Implement:** Export a device list from procurement/CMDB; `ENROLLID-Report.ps1` reconciles it
against Intune.

## 2.8 Microsoft Graph access for the scripts
**Description:** Permission to read managed devices and Entra devices via Microsoft Graph.
**Why:** Discovery, validation, and reporting scripts query Graph for device + primary-user data.
**Verify:** An admin can consent to `DeviceManagementManagedDevices.Read.All` and
`Device.Read.All`.
**Implement:** Sign in with an Intune Administrator when the script prompts for consent.

---
## Checklist
- [ ] Intune licensing assigned to enrolling users
- [ ] MDM authority = Intune; automatic enrollment scope set
- [ ] Enrollment restrictions reviewed — `ENROLLID-Discovery.ps1`
- [ ] Primary-user identity rule decided — `ENROLLID-Validation.ps1`
- [ ] Enrollment status page configured
- [ ] (Autopilot) corporate devices registered / hashes imported
- [ ] (Optional) external "should exist" list for reconciliation
- [ ] Graph read access for the scripts
- [ ] Pilot Entra group(s) created


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** Phoenixtekk solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every Phoenixtekk solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The Phoenixtekk deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Device Enrollment, Identity Association & Asset Inventory

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Enable only the enrollment methods you support, gate them with restrictions and an
> enrollment status page, set the primary-user rule, then enroll/import a **pilot**, reconcile the
> inventory, and only then expand. Object names below use the `<Purpose> – <Scope> – <Stage>`
> convention; **reuse each name verbatim** wherever it appears.

## Step 1 — Create the device groups
1. Entra → **Groups → New group** → **Security** → name `Enrollment – Pilot Devices – Pilot`
   (a few representative devices). **Create**.
2. Create `Enrollment – All Managed Devices – Production` (a dynamic device group, or the rest of the
   fleet). **Create**.
3. Create `Enrollment – Shared Devices – Production` for shared/kiosk hardware that will have **no**
   primary user. **Create**.

## Step 2 — Turn on automatic enrollment (Windows)
1. Intune → **Devices → Enrollment → Automatic Enrollment**.
2. Set **MDM user scope** to **Some** and add `Enrollment – Pilot Devices – Pilot`'s users for the
   pilot (expand to **All** at Step 9). Leave **MDM terms of use URL / discovery URL** at defaults.
3. **Save**.

## Step 3 — Set enrollment restrictions (the gate)
1. Intune → **Devices → Enrollment → Enrollment restrictions → Create restriction → Device platform
   restriction**.
2. **Name:** `Enrollment Restriction – Supported Platforms – Production`. **Next**.
3. **Platform settings:** **Allow** the platforms you support (e.g. Windows MDM), set **Personally
   owned** to **Block** if you only allow corporate, leave others **Block**. **Next**.
4. **Assignments → Add groups →** `Enrollment – All Managed Devices – Production`. **Next → Create**.
5. (Optional) **Device limit restriction →** `Enrollment Restriction – Device Limit – Production`,
   set the per-user device cap, assign, **Create**.

## Step 4 — Create the BYOD enrollment profile (only if you support personal devices)
1. Intune → **Devices → Enrollment → Enrollment restrictions**; ensure **Personally owned** is
   **Allow** in a restriction scoped to your BYOD users only.
2. Communicate the **Company Portal** enrollment path to those users (Company Portal → **Add device**).

## Step 5 — Configure the enrollment status page (Windows/Autopilot)
1. Intune → **Devices → Enrollment → Enrollment Status Page → Create profile**.
2. **Name:** `Enrollment Status Page – Corporate Windows – Production`. **Next**.
3. **Settings:** **Show app and profile configuration progress = Yes**; **Block device use until all
   apps and profiles are installed = Yes** (recommended for corporate); set a reasonable timeout.
   **Next**.
4. **Assignments → Add groups →** `Enrollment – Pilot Devices – Pilot`. **Next → Create**.

## Step 6 — Create the Windows Autopilot deployment profile (new corporate hardware)
1. Intune → **Devices → Enrollment → Windows → Deployment Profiles → Create profile → Windows PC**.
2. **Name:** `Autopilot Profile – Corporate Windows – Production`. **Next**.
3. **Out-of-box experience (OOBE):** **Deployment mode = User-driven**; **Join to Entra ID as = Entra
   joined**; set privacy/EULA/account-type per policy. **Next**.
4. **Assignments → Add groups →** `Enrollment – Pilot Devices – Pilot`. **Next → Create**.
5. Register corporate devices (OEM/CSP registration, or **Windows → Devices → Import** a hardware-hash
   CSV) so they pick up this profile.

## Step 7 — Set the device-scope targeting group (primary-user / shared)
1. Run `ENROLLID-Set-DeviceScopeTargeting.ps1` to populate `Enrollment – Shared Devices – Production`
   with devices that should have **no** primary user (kiosks/shared), and to confirm pilot devices
   are in `Enrollment – Pilot Devices – Pilot`.
2. This keeps shared devices out of per-user app/primary-user logic.

## Step 8 — Enroll the pilot and set primary users
1. Enroll the pilot devices via the method you chose (Autopilot self-deploy, or Entra join → auto
   enroll).
2. Intune → **Devices → All devices →** open a pilot device → **Properties → Primary user**; confirm
   it is the daily user. For shared devices, set primary user to **None**
   (**Properties → Primary user → Remove**).
3. Run `ENROLLID-Validation.ps1` on/against a pilot device to confirm it is enrolled and the primary
   user is correct.

## Step 9 — Reconcile inventory and validate the pilot
1. Run `ENROLLID-Discovery.ps1` for the current enrollment posture.
2. Run `ENROLLID-Report.ps1 -ExpectedCsv <list>` to reconcile Intune against your "should exist" list
   and surface stale records, duplicates, missing primary users, and not-yet-enrolled devices.
3. Fix exceptions with `ENROLLID-Remediation.ps1` (runs with `-WhatIf` by default — review first).
   Complete the **Testing Guide**.

## Step 10 — Expand to production
1. Set **Automatic Enrollment → MDM user scope = All** (Step 2).
2. Assign `Enrollment Status Page – Corporate Windows – Production` and
   `Autopilot Profile – Corporate Windows – Production` to
   `Enrollment – All Managed Devices – Production`.
3. Enroll/import the rest of the fleet, then re-reconcile with `ENROLLID-Report.ps1` each cycle.

---
### Order of operations
`Groups → Automatic enrollment → Enrollment restrictions → BYOD profile → Enrollment status page →
Autopilot profile → Device-scope targeting → Pilot enroll + primary users → Reconcile + validate →
Expand`


---


# 5. Testing Guide — Device Enrollment, Identity Association & Asset Inventory

Run after the pilot enrolls (Implementation Step 9) and after each reconciliation cycle.

## Test 1 — Automatic enrollment works
**Do:** Join a pilot Windows device to Entra ID with a scoped user; wait for the policy cycle.
**Expected:** The device appears in Intune → **Devices → All devices** within minutes; status shows
managed.

## Test 2 — Enrollment restrictions enforce
**Do:** Attempt to enroll a platform/ownership type you set to **Block**
(`Enrollment Restriction – Supported Platforms – Production`).
**Expected:** Enrollment is refused for the blocked type; allowed types enroll normally.

## Test 3 — Enrollment status page gates first sign-in
**Do:** Run an Autopilot pilot device through OOBE.
**Expected:** `Enrollment Status Page – Corporate Windows – Production` shows progress and blocks the
desktop until setup completes.

## Test 4 — Primary user is correct
**Do:** Intune → **Devices → All devices →** pilot device → **Properties → Primary user**; or run
`ENROLLID-Validation.ps1`.
**Expected:** Primary user = the daily user for assigned devices; **None** for shared devices in
`Enrollment – Shared Devices – Production`.

## Test 5 — Inventory reconciles
**Do:** Run `ENROLLID-Report.ps1 -ExpectedCsv <list>`.
**Expected:** A reconciliation showing matched devices and gaps — stale, duplicate, missing primary
user, and not-yet-enrolled.

## Test 6 — Discovery posture is clean
**Do:** Run `ENROLLID-Discovery.ps1`.
**Expected:** Enrollment method, restriction summary, and primary-user coverage reported with no
unexpected blockers.

## Test 7 — Remediation is safe and effective
**Do:** Run `ENROLLID-Remediation.ps1` (it runs `-WhatIf` by default); review the planned changes,
then re-run with `-WhatIf:$false` on an approved item.
**Expected:** With `-WhatIf` it only previews; when committed it fixes the targeted primary-user /
stale record without touching anything else.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; reconciliation (Test 5) shows pilot devices matched with correct owners |
| **Production pass** | Tests 1–6 pass for the broad scope; remediation (Test 7) verified safe before fleet use |


---


# 6. Troubleshooting Guide — Device Enrollment, Identity Association & Asset Inventory

Use `ENROLLID-Validation.ps1` / `ENROLLID-Discovery.ps1` for device/tenant posture,
`ENROLLID-Report.ps1` for inventory reconciliation, and `ENROLLID-Remediation.ps1` for safe fixes.

## A. Device won't enroll
| Symptom | Cause | Remediation |
|---|---|---|
| Enrollment fails for a user | Automatic enrollment scope excludes them | Intune → **Devices → Enrollment → Automatic Enrollment**; add the user to MDM scope |
| "This platform is blocked" | Enrollment restriction blocks the platform/ownership | Review `Enrollment Restriction – Supported Platforms – Production`; allow the needed type |
| "You've reached the device limit" | Device-limit restriction hit | Raise `Enrollment Restriction – Device Limit – Production` or retire the user's stale devices |
| No Intune license | Enrolling user unlicensed | Assign Intune license (Requirement 2.1), retry |

## B. Wrong or missing primary user
| Symptom | Cause | Remediation |
|---|---|---|
| Service desk can't find a user's device | Primary user wrong or blank | Device → **Properties → Primary user**; set the daily user, or run `ENROLLID-Remediation.ps1` |
| Device enrolled by a technician | Primary user = the tech, not the owner | Correct primary user to the assigned user |
| Shared device tied to one person | Primary user set on a shared device | Remove primary user (set **None**); ensure it's in `Enrollment – Shared Devices – Production` |

## C. Autopilot / enrollment status page issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device doesn't get the Autopilot profile | Hardware not registered to the tenant | **Devices → Enrollment → Windows → Devices**; register/import the hardware hash |
| Desktop usable before setup finishes | ESP not blocking, or unassigned | Confirm `Enrollment Status Page – Corporate Windows – Production` blocks use and is assigned |
| ESP times out | App/profile install too slow or stuck | Raise the ESP timeout; check the blocking app's install status |

## D. Inventory reconciliation gaps
| Symptom | Cause | Remediation |
|---|---|---|
| Stale devices in the count | Retired hardware never removed | Retire the records in Intune; re-run `ENROLLID-Report.ps1` |
| Duplicate records (same serial) | Device re-enrolled without cleanup | Remove the obsolete duplicate; keep the current record |
| Expected device missing | Never enrolled | Enroll it (Autopilot / Entra join); confirm it appears, then reconcile |

## E. Diagnostics quick reference
```powershell
dsregcmd /status        # Entra join + MDM enrollment state on the device
ENROLLID-Discovery.ps1  # tenant enrollment posture + primary-user coverage (read-only)
ENROLLID-Validation.ps1 # this device: enrolled? primary user correct? (read-only)
ENROLLID-Report.ps1     # reconcile Intune inventory against a "should exist" CSV
```
On the device, enrollment state also shows under **Settings → Accounts → Access work or school**.

## F. When to escalate
If a device is Entra-joined and synced, the user is licensed and in the automatic-enrollment scope,
no enrollment restriction blocks the platform, and it still won't enroll, collect `dsregcmd /status`
and the enrollment event log (`Applications and Services Logs → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostics-Provider`)
and open a Microsoft support case.


---


# 7. Best Practices — Device Enrollment, Identity Association & Asset Inventory

- **Pilot first, always.** Enroll a small `Enrollment – Pilot Devices – Pilot` group and validate the
  full chain — enrollment, primary user, reconciliation — before turning automatic enrollment to
  **All**. The pilot gate is the single most important practice.
- **Gate enrollment with restrictions.** Only allow the platforms and ownership types you actually
  support; a tight `Enrollment Restriction – Supported Platforms – Production` is what keeps the
  inventory clean from day one.
- **One rule for primary user.** Primary user = the daily user; shared/DEM devices have **none**.
  Apply it consistently so service-desk lookup always works — and don't "fix" shared devices to a
  person.
- **Use the enrollment status page for corporate Windows.** Blocking the desktop until apps/policies
  install means the device is ready before the user touches it, which prevents a wave of day-one
  tickets.
- **Reconcile on a cadence.** Run `ENROLLID-Report.ps1` against a "should exist" list regularly;
  chase stale records, duplicates, and missing owners while they are fresh, not at audit time.
- **Remediate safely.** Keep `ENROLLID-Remediation.ps1` in `-WhatIf` by default; review the planned
  changes, then commit per item. Never bulk-overwrite primary users blindly.
- **Name everything to a convention.** `<Purpose> – <Scope> – <Stage>` for every group, restriction,
  profile, and status page makes the tenant self-documenting and audits trivial.
- **Treat Intune as the source of truth — and keep it honest.** Inventory is only trustworthy if you
  retire stale records and resolve duplicates; a clean count is what the service desk relies on.
- **Document the enrollment methods you use.** Record which of Autopilot / Entra join / bulk-DEM /
  BYOD are enabled and for whom, so the next operator inherits a clear map.
- **Separate shared from assigned.** Keep shared/kiosk hardware in
  `Enrollment – Shared Devices – Production` so per-user logic and primary-user expectations never
  apply to it.


---


# 8. Deliverables Summary — Device Enrollment, Identity Association & Asset Inventory

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Enrollment methods, restrictions, primary-user/device-identity, Intune inventory as source of truth |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps (enrollment, restrictions, ESP, Autopilot, primary user, reconciliation) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ENROLLID-Discovery.ps1` | Reports enrollment posture — managed-device counts by enrollment method/ownership and primary-user coverage (Microsoft Graph, read-only) |
| `ENROLLID-Validation.ps1` | Confirms a device is enrolled and checks its primary-user association (Microsoft Graph, read-only) |
| `ENROLLID-Report.ps1` | Inventory reconciliation against a "should exist" list — flags stale, duplicate, missing-owner, and not-enrolled gaps (read-only) |
| `ENROLLID-Remediation.ps1` | Safe fixes for wrong primary user / stale records; runs with `-WhatIf` by default |
| `ENROLLID-Set-DeviceScopeTargeting.ps1` | Builds/maintains the device-scope targeting groups (pilot / shared-no-primary-user) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the Phoenixtekk model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every device enrolled, tied to the right user, and accounted for in a reconciled Intune inventory —
the service desk's trusted source of truth — proven on a pilot before fleet rollout.
