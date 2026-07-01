# Endpoint Imaging, Inventory & Hardware Lifecycle Management

> **Version 1.0.0** · Category: Infrastructure · Solution code: IMGLIFE

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Endpoint Imaging, Inventory & Hardware Lifecycle Management

Without a defined lifecycle, devices appear and vanish off the books: nobody knows what was bought,
what is deployed, what is idle in a drawer, or what was retired without being wiped. Imaging is done
ad hoc, inventory lives in a stale spreadsheet, and audits are painful. This package gives you a
repeatable endpoint imaging, inventory, and hardware lifecycle — a clear provisioning method
(cloud provisioning with Windows Autopilot, or Configuration Manager task-sequence imaging where it
is genuinely required), accurate hardware inventory as a source of truth, and a governed
procure → deploy → refresh → retire flow that ends every device's life with a secure wipe.

This is a complete, deploy-it-today package, written for an administrator with no prior
device-lifecycle experience. It tells you which provisioning method to pick and why, how to make
Intune the system of record for hardware inventory, and exactly how to retire and wipe a device so
it leaves the fleet clean.

## What you get
- A plain-language Solution Overview of the device lifecycle model, the provisioning decision
  (Autopilot vs. imaging), hardware inventory sources, and the procure/deploy/refresh/retire flow.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click steps in the required order.
- Five PowerShell scripts for hardware/inventory discovery, provisioning and inventory validation,
  a lifecycle and asset-reconciliation report, a safe retire/wipe remediation helper (preview by
  default), and a lifecycle-stage group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A defined lifecycle for every device: one chosen provisioning method, an accurate hardware
inventory you can trust for audits and refresh planning, lifecycle-stage groups that move a device
cleanly from procured to deployed to refresh-due to retired, and a secure wipe at end of life.

## The repeatable deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Every device accounted for across its whole life — provisioned by a defined method, inventoried
accurately, refreshed on criteria, and retired with a secure wipe — proven on a pilot before you
scale.


---


# 1. Solution Overview — Endpoint Imaging, Inventory & Hardware Lifecycle Management

## What this solution is
A repeatable way to manage the whole life of every Windows device: how it gets provisioned, how it
is inventoried, when it gets refreshed, and how it is securely retired. It replaces ad hoc imaging
and a stale spreadsheet with a defined provisioning method, an accurate hardware inventory that acts
as the source of truth, and a governed procure → deploy → refresh → retire flow that ends in a
secure wipe.

## The device lifecycle model
1. Procure — a device is purchased and its hardware identity (hardware hash or serial / manufacturer
   / model) is captured before or at receipt.
2. Deploy — the device is provisioned by your chosen method (Windows Autopilot cloud provisioning or
   Configuration Manager task-sequence imaging) and enrolled in Intune.
3. Operate / inventory — the device is in service and its hardware details are tracked in Intune,
   which is the inventory system of record.
4. Refresh — when the device meets refresh criteria (age, warranty expiry, or spec), it is flagged
   for replacement and its successor is procured.
5. Retire — at end of life the device is retired and securely wiped, then removed from inventory
   (and de-registered from Autopilot if applicable).

## The provisioning decision (Autopilot vs. imaging)
This is the most important choice in the solution, so make it deliberately.

- Windows Autopilot cloud provisioning is the default for modern, cloud-managed fleets. The device
  ships from the vendor (or is reset), the user signs in, and Intune provisions it over the internet
  with no custom image. You register the device's hardware identity once; everything else is policy.
  Choose this when devices are internet-connected, you want zero-touch deployment, and you do not
  need a custom on-disk image.
- Configuration Manager task-sequence imaging is the alternative for environments that genuinely
  require it: an on-premises image with a specific disk layout or drivers, offline or
  bandwidth-constrained sites, or a managed estate already standardized on Configuration Manager.
  It lays down an OS image and applications from a distribution point on the LAN.

Why the choice matters: it decides where your "golden state" lives (Microsoft cloud policy vs. an
on-prem image), how new hardware is onboarded, and how much network you need at deploy time. Most
fleets should standardize on Autopilot and keep imaging only for the sites or device types that
truly need it.

## Hardware inventory as a source of truth
Intune holds per-device hardware details (manufacturer, model, serial number, processor, memory,
storage, enrollment and last-check-in dates). Once devices are enrolled, this becomes the single
inventory you reconcile against — not a spreadsheet. Autopilot adds a registered-devices list keyed
by hardware hash, which is your procurement-to-deployment ledger. Reconciling purchased devices
against enrolled devices is how you find machines that were bought but never deployed, or deployed
but never inventoried.

## The procure → deploy → refresh → retire flow with secure wipe
Lifecycle-stage security groups move a device through the flow and let policy and reporting target
the right stage. The solution names them with a fixed convention so they are reusable verbatim:
- `Device Lifecycle – Procurement – Procured`
- `Device Lifecycle – Fleet – Deployed`
- `Device Lifecycle – Aging – Refresh-Due`
- `Device Lifecycle – End-of-Life – Retire`

At retirement, Intune performs a secure wipe. Retire removes company data and management; Wipe
returns the device to a clean factory state (a full reset). Choosing the correct action at end of
life is what guarantees no data leaves with a retired device.

## Benefits
- Accountability — every device is tracked from procurement to retirement; nothing falls off the
  books.
- A defined provisioning method — one repeatable way to stand up a device, chosen deliberately.
- Accurate inventory — Intune is the source of truth for audits and refresh planning, not a
  spreadsheet.
- Clean retirement — every retired device is securely wiped, so no data walks out the door.
- Proven before scale — piloted on a small group before the whole fleet.

## Limitations (be honest with buyers)
- Autopilot needs the hardware identity registered (hash or vendor registration) and internet
  connectivity at provisioning; it does not lay down a custom on-disk image.
- Task-sequence imaging requires a working Configuration Manager environment (site, distribution
  point, boot media); standing that up is out of scope here, though we note where it fits.
- Intune hardware inventory reflects enrolled devices; devices bought but never enrolled appear in
  the reconciliation as gaps, not in inventory.
- A secure wipe is irreversible — confirm the device and the action before applying.

## The repeatable deployment model
> Choose the provisioning method → register/import devices and establish inventory → build the
> lifecycle-stage groups → pilot the flow → validate → expand to the fleet. The repeatable way:
> Assess → Configure → Pilot → Validate → Expand.


---


# 2. Requirements Guide — Endpoint Imaging, Inventory & Hardware Lifecycle Management

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-infrastructure.md`.

## 2.1 Intune (provisioning, inventory, and retire/wipe)
Description: Microsoft Intune (Plan 1), the control plane for Autopilot, enrollment, hardware
inventory, and the retire/wipe actions.
Why: Autopilot profiles, device inventory, and the secure-wipe lifecycle actions all live in Intune.
Verify: `intune.microsoft.com` loads; Devices is visible.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## 2.2 Provisioning method chosen (Autopilot or imaging)
Description: A deliberate decision: Windows Autopilot cloud provisioning (default) or Configuration
Manager task-sequence imaging (where required).
Why: This decides where the golden state lives and how devices are onboarded; the implementation
steps differ.
Verify: Confirm which method this fleet (or this site) will use; run `IMGLIFE-Discovery.ps1` to see
current state (Autopilot registration, enrollment, any ConfigMgr client).
Implement: Default to Autopilot. Use Configuration Manager imaging only for sites/device types that
require a custom on-disk image or offline deployment, and confirm a working ConfigMgr site exists.

## 2.3 Windows Autopilot prerequisites (if using Autopilot)
Description: Devices' hardware identities registered to Autopilot (vendor registration or imported
hardware hash) and an Autopilot deployment profile.
Why: Autopilot can only provision devices it recognizes by hardware identity.
Verify: Intune → Devices → Enrollment → Windows Autopilot → Devices shows the registered devices;
run `IMGLIFE-Validation.ps1`.
Implement: Have the OEM/reseller register devices, or import the hardware hash; create an Autopilot
deployment profile (Step 2 of the Implementation Guide).

## 2.4 Configuration Manager environment (if using imaging)
Description: A working ConfigMgr site with a distribution point, boot media, an OS image package, and
a task sequence.
Why: Task-sequence imaging deploys the OS and apps from on-premises distribution points.
Verify: ConfigMgr console → Software Library → Operating Systems → Task Sequences shows a usable
deployment task sequence.
Implement: Stand up (or reuse) a ConfigMgr site and build an OS-deployment task sequence; this is
out of scope here but noted as the imaging path.

## 2.5 Device enrollment in Intune
Description: Provisioned devices are enrolled and manageable in Intune.
Why: Inventory, lifecycle groups, and retire/wipe only reach enrolled devices.
Verify: Intune → Devices → All devices shows the device; run `IMGLIFE-Validation.ps1`.
Implement: Enable automatic enrollment and join devices to Entra ID (Autopilot enrolls
automatically; imaged devices enroll via the join/enrollment step).

## 2.6 Hardware inventory source of truth
Description: Intune device hardware inventory is treated as the authoritative inventory, with a
procurement record to reconcile against.
Why: An accurate, single source of truth is what makes audits, refresh planning, and reconciliation
possible.
Verify: Intune → Devices → All devices → (a device) → Hardware shows model, serial, storage; run
`IMGLIFE-Report.ps1` for the fleet inventory.
Implement: Ensure devices are enrolled (so they report hardware); keep a procurement list (serials)
to reconcile against the enrolled inventory.

## 2.7 Retirement and secure-wipe process
Description: A defined end-of-life action — Retire (remove company data/management) or Wipe (full
factory reset) — and who is authorized to run it.
Why: A device must leave the fleet clean; an undocumented retirement is how data walks out the door.
Verify: Confirm the operator holds Intune Administrator and that the action is documented; preview
with `IMGLIFE-Remediation.ps1` (runs in WhatIf mode by default).
Implement: Document the retire-vs-wipe decision and authorization; use `IMGLIFE-Remediation.ps1` as
the safe helper.

## 2.8 Lifecycle-stage groups
Description: Entra ID security groups for each lifecycle stage, named by the solution convention.
Why: Stages let policy and reporting target the right population as a device moves through its life.
Verify: Entra → Groups shows the four lifecycle groups; or run
`IMGLIFE-Set-LifecycleStageTargeting.ps1` (idempotent — reports/creates).
Implement: Run `IMGLIFE-Set-LifecycleStageTargeting.ps1` to create them, or create them by hand with
the exact names below.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Provisioning method chosen (Autopilot default, or ConfigMgr imaging) — `IMGLIFE-Discovery.ps1`
- [ ] Autopilot devices registered + deployment profile (if Autopilot) — `IMGLIFE-Validation.ps1`
- [ ] ConfigMgr site + task sequence (if imaging)
- [ ] Devices enrolled in Intune
- [ ] Hardware inventory established as source of truth — `IMGLIFE-Report.ps1`
- [ ] Retire/wipe action documented and authorized
- [ ] Lifecycle-stage groups created — `IMGLIFE-Set-LifecycleStageTargeting.ps1`


---


# Global Requirements — Infrastructure Solutions (category-level)

These requirements apply to **every** solution in the **Infrastructure** category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying *any* Infrastructure solution. Each entry: Description · Why · Verify · Implement-if-missing.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID (Azure AD) tenant.
Why: It is the identity backbone for Microsoft 365, Entra ID, and Intune-managed infrastructure — including device sign-in, group targeting, and shared cloud resources.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Microsoft 365 / Intune subscription
Description: A Microsoft 365 plan that includes Microsoft Intune and the cloud service the solution relies on.
Why: Intune delivers configuration, deployment, and policy targeting; the bundled Microsoft 365 services back the cloud capability being deployed.
Verify: `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
Description: Appropriate Entra / Intune admin roles for the operator.
Why: Creating cloud service settings, policies, and deployments requires elevated rights.
Verify: Entra → **Roles and administrators**; confirm **Intune Administrator** (plus any service-specific admin role the solution calls out).
Implement: Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
Description: Targeted Windows devices are enrolled and manageable.
Why: Deployments and policies only reach enrolled, Entra-joined devices.
Verify: Intune → **Devices → All devices**; the device appears and is **compliant**.
Implement: Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
Description: A Microsoft Entra security group for the pilot population (users or devices).
Why: Every solution is piloted before fleet rollout — the pilot is the gate.
Verify: Entra → **Groups**; the pilot group exists.
Implement: Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
Description: Windows 10 21H2+ or Windows 11 with current updates.
Why: Modern Intune and Microsoft 365 cloud features assume a patched, supported OS.
Verify: `winver`, or Intune → device → **Hardware**.
Implement: Deploy update rings or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
Why: Enrollment, policy sync, authentication, and the cloud service traffic depend on these endpoints.
Verify: From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
Implement: Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through the proxy/firewall.

---
The repeatable deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# 3. Implementation Guide — Endpoint Imaging, Inventory & Hardware Lifecycle Management

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).
The default path is Windows Autopilot cloud provisioning; Step 3 covers the Configuration Manager
task-sequence imaging alternative for sites that require it.

> Model: choose one provisioning method, register/import devices and establish inventory, build the
> lifecycle-stage groups, then pilot the procure → deploy → refresh → retire flow before expanding.

## Step 1 — Create the lifecycle-stage groups
Create these four Entra ID security groups (Entra → Groups → New group → Security), using the exact
names so the rest of the solution can reuse them verbatim:
1. `Device Lifecycle – Procurement – Procured`
2. `Device Lifecycle – Fleet – Deployed`
3. `Device Lifecycle – Aging – Refresh-Due`
4. `Device Lifecycle – End-of-Life – Retire`

Also create the pilot provisioning group `Autopilot Provisioning – Standard Users – Pilot` (a few
representative users/devices) and `Autopilot Provisioning – Standard Users – Broad` (the rest).
Tip: `IMGLIFE-Set-LifecycleStageTargeting.ps1` creates these idempotently.

## Step 2 — Register devices and create the Autopilot deployment profile (default path)
1. Register hardware identities: Devices → Enrollment → Windows Autopilot → Devices. Devices
   registered by your OEM/reseller appear here; otherwise import the hardware hash (CSV) with Import.
2. Create the profile: Devices → Enrollment → Windows Autopilot → Deployment profiles →
   Create profile → Windows PC.
3. Name: `Autopilot Provisioning – Standard Users – Pilot`. Next.
4. Out-of-box experience (OOBE): set deployment mode (User-driven), join type (Microsoft Entra
   joined), and the OOBE options (hide EULA, hide privacy settings, etc.) to your policy. Next.
5. Assignments → Add groups → `Autopilot Provisioning – Standard Users – Pilot`. Next → Create.
6. Repeat for `Autopilot Provisioning – Standard Users – Broad` assigned to the broad group (do this
   after the pilot validates).

## Step 3 — Alternative: Configuration Manager task-sequence imaging (only if required)
Use this instead of Step 2 only for sites/device types that need a custom on-disk image or offline
deployment. In the Configuration Manager console:
1. Software Library → Operating Systems → confirm an OS image package and a deployment task sequence
   exist on a distribution point.
2. Deploy the task sequence to the imaging collection and boot the device from PXE or boot media.
3. After imaging, ensure the device enrolls into Intune (Entra join + automatic enrollment) so it
   reports hardware inventory like any other device.

## Step 4 — Establish hardware inventory as the source of truth
1. Confirm enrolled devices report hardware: Devices → All devices → (a device) → Hardware (model,
   serial number, storage, memory).
2. Pull the fleet inventory with `IMGLIFE-Report.ps1` (Microsoft Graph), which lists managed devices
   plus the Autopilot registered-devices list.
3. Reconcile your procurement list (serials purchased) against the report to find gaps: bought but
   not enrolled, or enrolled but not on the books.

## Step 5 — Move devices into the Deployed stage
1. As devices finish provisioning and report inventory, add them to
   `Device Lifecycle – Fleet – Deployed`.
2. Keep `Device Lifecycle – Procurement – Procured` for devices received but not yet provisioned, so
   the reconciliation report can flag procured-but-not-deployed machines.

## Step 6 — Define refresh criteria and flag refresh-due devices
1. Decide the refresh trigger (for example, age over N years, warranty expired, or below a spec
   threshold).
2. Run `IMGLIFE-Report.ps1` to identify devices meeting the criteria (enrollment/age and hardware
   fields).
3. Add those devices to `Device Lifecycle – Aging – Refresh-Due` and procure their replacements.

## Step 7 — Implement secure retirement and wipe
1. For a device at end of life, add it to `Device Lifecycle – End-of-Life – Retire`.
2. Preview the action first: run `IMGLIFE-Remediation.ps1` (WhatIf by default) to confirm the target
   device and the chosen action.
3. In Intune, Devices → All devices → (the device) → choose Retire (remove company
   data/management) or Wipe (full factory reset) per your documented policy. Wipe is the secure full
   reset; Retire keeps the OS but removes company data and management.
4. After confirming the wipe completed, remove the device record and de-register it from Autopilot
   (Devices → Enrollment → Windows Autopilot → Devices → Delete) so inventory stays clean.

## Step 8 — Pilot the full flow
1. Run the whole procure → deploy → refresh → retire flow on the
   `Autopilot Provisioning – Standard Users – Pilot` group.
2. Validate with `IMGLIFE-Validation.ps1` (provisioning/enrollment) and `IMGLIFE-Report.ps1`
   (inventory and reconciliation). Complete the Testing Guide.

## Step 9 — Expand to production
1. After the pilot passes, assign the broad Autopilot profile and onboard the rest of the fleet.
2. Run the lifecycle on the broad population; re-reconcile inventory each cycle with
   `IMGLIFE-Report.ps1`.

---
### Order of operations
`Lifecycle groups → register devices + Autopilot profile (or ConfigMgr imaging) → establish
inventory → Deployed stage → refresh criteria → secure retire/wipe → pilot → expand`


---


# 5. Testing Guide — Endpoint Imaging, Inventory & Hardware Lifecycle Management

Run after the pilot flow applies (Implementation Step 8) and each lifecycle cycle.

## Test 1 — Provisioning method works
Do: Provision a pilot device by the chosen method — for Autopilot, reset/boot a registered device
and complete OOBE; for imaging, run the task sequence. Then run `IMGLIFE-Validation.ps1`.
Expected: The device provisions to the standard state and enrolls in Intune.

## Test 2 — Autopilot registration present (if Autopilot)
Do: Intune → Devices → Enrollment → Windows Autopilot → Devices; or run `IMGLIFE-Validation.ps1`.
Expected: The pilot device's hardware identity is registered and assigned the deployment profile.

## Test 3 — Device enrolled and reporting hardware
Do: Intune → Devices → All devices → (the device) → Hardware; or run `IMGLIFE-Validation.ps1`.
Expected: The device is present and reports model, serial number, storage, and memory.

## Test 4 — Inventory is the source of truth
Do: Run `IMGLIFE-Report.ps1`.
Expected: The fleet inventory lists the device with its hardware details and lifecycle stage.

## Test 5 — Reconciliation finds gaps
Do: Compare the procurement list (serials) against `IMGLIFE-Report.ps1` output.
Expected: Procured-but-not-deployed and deployed-but-not-inventoried devices are flagged.

## Test 6 — Refresh-due detection
Do: Apply the refresh criteria and run `IMGLIFE-Report.ps1`.
Expected: Devices meeting the criteria appear and are eligible for
`Device Lifecycle – Aging – Refresh-Due`.

## Test 7 — Secure retire/wipe (controlled)
Do: On a disposable pilot device, preview with `IMGLIFE-Remediation.ps1` (WhatIf), then perform
Retire or Wipe in Intune and confirm completion.
Expected: The device returns to a clean state (Wipe) or loses company data/management (Retire), then
is removed from inventory and de-registered from Autopilot.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–5 pass on the pilot group; a test retire/wipe (Test 7) completes cleanly |
| Broad pass | Tests 3–6 pass across the broad population before the next refresh cycle |


---


# 6. Troubleshooting Guide — Endpoint Imaging, Inventory & Hardware Lifecycle Management

Use `IMGLIFE-Validation.ps1` / `IMGLIFE-Discovery.ps1` for device state, `IMGLIFE-Report.ps1` for
fleet inventory and reconciliation, and `IMGLIFE-Remediation.ps1` for a safe retire/wipe (preview by
default).

## A. Autopilot provisioning problems
| Symptom | Cause | Remediation |
|---|---|---|
| Device skips Autopilot at OOBE | Hardware identity not registered, or no profile assigned | Confirm the device is in Devices → Enrollment → Windows Autopilot → Devices; assign the deployment profile to a group the device is in; run `IMGLIFE-Validation.ps1` |
| Profile assigned but not applied | Profile not yet synced to the device record | Wait for assignment to show Assigned; reset the device and retry OOBE |
| Wrong join type / OOBE options | Profile settings differ from intent | Edit the Autopilot deployment profile (join type, OOBE) and reassign |

## B. Imaging (Configuration Manager) problems
| Symptom | Cause | Remediation |
|---|---|---|
| Task sequence fails / device won't PXE | Boot media, distribution point, or content missing | Confirm the OS image and task sequence are distributed to the distribution point and the device can reach PXE/boot media |
| Imaged device not in Intune | Enrollment step skipped after imaging | Ensure the task sequence (or post-image step) Entra-joins and auto-enrolls the device |

## C. Device enrolled but not reporting hardware
- Confirm the device is in Devices → All devices and recently checked in; force a sync from the
  device (Settings → Accounts → Access work or school → Info → Sync), then re-run
  `IMGLIFE-Validation.ps1`.

## D. Inventory and reconciliation gaps
| Symptom | Cause | Remediation |
|---|---|---|
| Purchased device not in inventory | Bought but never enrolled | Provision/enroll the device, or mark it `Device Lifecycle – Procurement – Procured`; re-run `IMGLIFE-Report.ps1` |
| Device in Intune but not on the books | Procurement list incomplete | Add the serial to the procurement record; reconcile again |
| Stale/duplicate records | Retired device not removed | Remove the device record and de-register from Autopilot after wipe |

## E. Retire / wipe issues
- Wipe pending forever: the device must be online to receive the command; confirm it checks in. If
  it will never return, after the documented hold period remove the record so inventory stays clean.
- Wrong device almost wiped: always run `IMGLIFE-Remediation.ps1` in its default WhatIf mode first
  and confirm the serial/name before applying.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object CsManufacturer, CsModel, BiosSeralNumber
dsregcmd /status        # Entra join + MDM enrollment state
Get-Service -Name dmwappushservice, IntuneManagementExtension -ErrorAction SilentlyContinue
```
For the cloud-side device, Autopilot, and inventory state, use `IMGLIFE-Discovery.ps1` and
`IMGLIFE-Report.ps1` (Microsoft Graph).

## G. When to escalate
If a device is registered to Autopilot, assigned a profile, online, and synced, yet still fails to
provision or never reports hardware after a full reset and sync, collect the device's enrollment
diagnostics (Settings → Accounts → Access work or school → Export) and open a Microsoft support
case.


---


# 7. Best Practices — Endpoint Imaging, Inventory & Hardware Lifecycle Management

- Choose one provisioning method deliberately. Default to Windows Autopilot cloud provisioning; keep
  Configuration Manager task-sequence imaging only for sites/device types that genuinely need a
  custom on-disk image or offline deployment. Don't run both for the same population by accident.
- Register hardware identity at procurement. Capture the hardware hash (or have the OEM/reseller
  register devices to Autopilot) before the device reaches the user, so deployment is zero-touch.
- Make Intune the single source of truth. Reconcile against the enrolled-device inventory, never a
  side spreadsheet; a spreadsheet drifts the moment it is saved.
- Reconcile every cycle. Compare purchased serials against `IMGLIFE-Report.ps1` to catch
  procured-but-not-deployed and deployed-but-not-inventoried devices early.
- Use lifecycle-stage groups, named consistently. Move devices through
  `Device Lifecycle – Procurement – Procured`, `– Fleet – Deployed`, `– Aging – Refresh-Due`, and
  `– End-of-Life – Retire`, and reuse those exact names everywhere.
- Define refresh criteria up front. Decide the trigger (age, warranty, spec) so refresh is a rule,
  not a guess, and procure replacements before devices fail.
- Always preview a wipe. Run `IMGLIFE-Remediation.ps1` in its default WhatIf mode and confirm the
  target device before any retire/wipe — the action is irreversible.
- Retire clean, every time. Choose Retire vs. Wipe deliberately, confirm completion, then remove the
  record and de-register from Autopilot so inventory stays accurate.
- Pilot before the fleet. Validate the full procure → deploy → refresh → retire flow on the pilot
  group before expanding.
- Document the lifecycle. Record the chosen provisioning method, refresh criteria, and the retire/
  wipe authorization for audits and repeatability.


---


# 8. Deliverables Summary — Endpoint Imaging, Inventory & Hardware Lifecycle Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The lifecycle model, the Autopilot-vs-imaging decision, inventory as source of truth, the procure/deploy/refresh/retire flow with secure wipe |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps for provisioning, inventory, lifecycle stages, and secure retirement |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IMGLIFE-Discovery.ps1` | Reports current provisioning state: Autopilot registration, Intune enrollment, hardware inventory, and any ConfigMgr client (read-only) |
| `IMGLIFE-Validation.ps1` | Confirms a device is provisioned, registered (Autopilot), enrolled, and reporting hardware (read-only) |
| `IMGLIFE-Report.ps1` | Lifecycle and asset-reconciliation report across managed devices and the Autopilot registered-devices list (Microsoft Graph, read-only) |
| `IMGLIFE-Remediation.ps1` | Safe retire/wipe helper; previews by default (WhatIf), triggers the chosen end-of-life action only when explicitly applied |
| `IMGLIFE-Set-LifecycleStageTargeting.ps1` | Creates the lifecycle-stage Entra ID groups (idempotent) and optionally stages members |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess → Configure → Pilot → Validate → Expand.

## Outcome
Every device accounted for across its whole life — provisioned by a defined method, inventoried
accurately, refreshed on criteria, and retired with a secure wipe.
