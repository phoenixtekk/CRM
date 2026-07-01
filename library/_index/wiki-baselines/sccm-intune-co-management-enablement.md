# Configuration Manager and Intune Co-Management Enablement

> **Version 1.0.0** · Category: Migrations · Solution code: COMGMT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Configuration Manager and Intune Co-Management Enablement (Microsoft Intune)

Most organizations cannot abandon Configuration Manager overnight, yet management is moving to the
cloud. Co-management is the bridge: a single Windows device managed by Configuration Manager and
Microsoft Intune at the same time, so you move responsibilities — called workloads — from
Configuration Manager to Intune one at a time, on your schedule, with a clean path to cloud-first.

This is a complete, deploy-it-today package for enabling co-management correctly and running a
controlled, workload-by-workload migration, written for an administrator with no prior co-management
experience.

## What you get
- A plain-language Solution Overview of the co-management authority model, the workload slider, and
  cloud attach / tenant attach.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click steps across the Configuration Manager console
  and `https://intune.microsoft.com`, in the required order.
- Five PowerShell scripts for readiness discovery, per-device co-management validation, a
  workload-authority and enrollment report, safe remediation of un-enrolled clients, and a pilot
  collection / device-group builder.
- Testing and Troubleshooting guides for confident rollout.

## What this delivers
Co-management enabled with a named co-management configuration, a `Co-Management – Pilot Collection –
Stage 1` onboarding scope, cloud attach (tenant attach) connecting your site to the cloud, and a
staged workload slider that moves each workload — compliance, device configuration, Endpoint
Protection, Resource access, Client apps, Office Click-to-Run apps, and Windows Update policies —
from Configuration Manager to Intune only after it is validated on the pilot.

## The deployment model
Assess to Configure to Pilot to Validate to Expand — with a pilot gate before every workload move.

## Outcome
A Configuration Manager fleet co-managed with Intune, workloads moving to the cloud one controlled
step at a time, proven on a pilot before you scale — deployable by a single administrator.


---


# 1. Solution Overview — Configuration Manager and Intune Co-Management Enablement

## What co-management is
Co-management lets a single Windows device be managed by Configuration Manager and Microsoft Intune
at the same time. Configuration Manager keeps doing what it does today; Intune is attached alongside
it. You then move management responsibilities — called workloads — from Configuration Manager to
Intune one at a time, on your schedule. The device stays fully managed throughout, so there is no
rip-and-replace and no all-or-nothing cutover.

## How it works
1. You enable a co-management configuration in the Configuration Manager console. This tells the
   Configuration Manager client to auto-enroll the device into Intune.
2. Each Windows client gets two management authorities: Configuration Manager and Intune. The
   workload slider decides, per workload, which authority is in charge.
3. You onboard a small pilot collection first, validate, then expand to the full fleet.
4. Cloud attach (tenant attach) connects your Configuration Manager site to your cloud tenant so the
   site and Intune work together and devices appear in `https://intune.microsoft.com`.
5. As each workload is moved to Intune (Pilot first, then All), Intune policies take over that
   responsibility and Configuration Manager stands down for it.
6. Status is visible in both the Configuration Manager console and the Intune admin center.

## The co-management workloads (the slider)
Each workload is moved independently — set to Pilot (only the pilot collection) or All (whole fleet):
- Compliance policies
- Device configuration
- Endpoint Protection
- Resource access policies
- Client apps
- Office Click-to-Run apps
- Windows Update policies

## Cloud attach: cloud attach and tenant attach
- Cloud attach is the umbrella for connecting Configuration Manager to the Microsoft cloud.
- Tenant attach uploads your Configuration Manager devices to the Intune admin center so you can see
  and take actions on them from the cloud console, even before any workload moves.
- Co-management is the part that enables the dual authority and the workload slider.

## Enrollment models
- Automatic enrollment via the Configuration Manager client (the default for co-management).
- Staged enrollment, where only the pilot collection auto-enrolls first, then enrollment expands —
  this is the controlled path this solution uses.

## Why co-management (and why staged)
Co-management exists because most organizations have years of Configuration Manager investment and
cannot move to the cloud in one step. It removes the risk of a big-bang migration: you keep
everything working while you shift responsibilities to Intune at a pace you control, validating each
workload on a pilot before the fleet feels it. Moving workloads one at a time means a problem with
any single workload is contained to the pilot and easy to roll back, and you end with a clear,
low-drama path to cloud-first management.

## What you can control
- Which workloads move, and whether each goes to the pilot only or to all devices.
- The pilot collection membership (who experiences each workload move first).
- Whether the Configuration Manager client auto-enrolls devices into Intune.
- The order and pace of the migration, gated by validation at each step.

## Limitations (be honest with buyers)
- Co-management requires a supported Configuration Manager current branch and healthy clients.
- Identity must be in place first: devices must be hybrid Entra joined (or Entra joined) and able to
  enroll in Intune.
- A workload set to Intune is owned by Intune — you must have an equivalent Intune policy ready
  before you move that workload, or that capability lapses.
- Moving a workload affects every device in the chosen scope; validate on the pilot before choosing
  All.

## The deployment model
> Enable co-management to onboard a pilot collection to move one workload at a time to Intune to
> validate each to expand. Pattern: Assess to Configure to Pilot to Validate to Expand.


---


# 2. Requirements Guide — Configuration Manager and Intune Co-Management Enablement

Verify every requirement before configuring. Each entry: Description, Why, Verify,
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Supported Configuration Manager current branch
Description: A supported Configuration Manager current branch site, in good health.
Why: Co-management, cloud attach, and the workload slider are current-branch features; older builds
lack them.
Verify: Configuration Manager console to Administration to Site Configuration to Sites; check the
version. Run `COMGMT-Discovery.ps1`.
Implement: Update to a supported current branch via Administration to Updates and Servicing.

## 2.2 Configuration Manager client health
Description: Targeted devices run a healthy, current Configuration Manager client.
Why: The client is what auto-enrolls the device into Intune and reports co-management state.
Verify: Console to Assets and Compliance to Devices (Client = Yes, Client Activity = Active). Run
`COMGMT-Discovery.ps1`.
Implement: Deploy or repair the client; resolve client-health issues before onboarding.

## 2.3 Intune subscription and MDM authority
Description: An Intune-bearing license plan with Intune as the MDM authority.
Why: Co-management auto-enrolls devices into Intune; without it the dual authority cannot form.
Verify: `https://intune.microsoft.com` loads; Tenant administration to Tenant status is active.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## 2.4 Microsoft Entra ID and identity (hybrid or Entra join)
Description: Devices are hybrid Microsoft Entra joined (or Entra joined) with Entra Connect syncing
identities.
Why: Co-management enrollment relies on the device having an Entra identity to authenticate to
Intune.
Verify: On a client, `dsregcmd /status` shows `AzureAdJoined : YES` (and `DomainJoined : YES` for
hybrid). Run `COMGMT-Discovery.ps1`.
Implement: Configure hybrid Entra join (or Entra join) and Microsoft Entra Connect; confirm sync.

## 2.5 Automatic enrollment in Intune enabled
Description: Automatic MDM enrollment is enabled in Microsoft Entra for the enrolling users/devices.
Why: The Configuration Manager client uses automatic enrollment to register devices with Intune.
Verify: Entra admin center to Mobility (MDM and MAM) to Microsoft Intune; MDM user scope is Some or
All.
Implement: Set MDM user scope to Some (scoped to a pilot group) or All; confirm enrollment URLs are
default.

## 2.6 Cloud attach (tenant attach) configured
Description: The Configuration Manager site is connected to the cloud via cloud attach (tenant
attach).
Why: Tenant attach uploads devices to the Intune admin center and underpins co-management.
Verify: Console to Administration to Cloud Services to Cloud Attach (or Co-management) shows the
tenant connected. Run `COMGMT-Validation.ps1`.
Implement: Run the Cloud Attach / Co-management configuration wizard and sign in with a tenant
administrator.

## 2.7 Supported Windows OS
Description: Windows 10/11 (Pro/Enterprise/Education) on a supported build.
Why: Co-management and Intune workloads require a supported, manageable client OS.
Verify: `winver`; run `COMGMT-Discovery.ps1`.
Implement: Patch or upgrade to a supported build.

## 2.8 Network access to cloud endpoints
Description: Outbound HTTPS to Microsoft Entra, Intune enrollment, and Configuration Manager cloud
endpoints.
Why: Enrollment, policy sync, and tenant attach all depend on these endpoints.
Verify: From a device, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`.
Implement: Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through proxy and
firewall.

## 2.9 Equivalent Intune policy ready per workload
Description: For each workload you plan to move, an equivalent Intune policy exists and is assigned.
Why: When a workload moves to Intune, Intune owns it — without a policy in place that capability
lapses.
Verify: Intune to the relevant policy area shows a configured, assigned policy. Run
`COMGMT-Report.ps1`.
Implement: Author the Intune policy (compliance, configuration, etc.) before moving its workload.

---
## Checklist
- [ ] Supported Configuration Manager current branch — `COMGMT-Discovery.ps1`
- [ ] Healthy Configuration Manager clients on targeted devices
- [ ] Intune subscription with Intune as MDM authority
- [ ] Hybrid Entra join (or Entra join) + Entra Connect — `dsregcmd /status`
- [ ] Automatic enrollment in Intune enabled (MDM scope)
- [ ] Cloud attach (tenant attach) configured — `COMGMT-Validation.ps1`
- [ ] Windows 10/11 supported build
- [ ] Network allows Microsoft cloud endpoints
- [ ] Equivalent Intune policy ready for each workload to move
- [ ] `Co-Management – Pilot Collection – Stage 1` collection created


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


# 3. Implementation Guide — Configuration Manager and Intune Co-Management Enablement

Follow these steps in order. Some steps are in the Configuration Manager console (Administration to
Cloud Services to Co-management) and some are in the Microsoft Intune admin center
(`https://intune.microsoft.com`).

> Model: Onboard a small pilot collection first, move one workload at a time to the pilot, validate
> each, then expand each workload to All. Never move a workload to All before its pilot passes.

Reuse these exact object names verbatim throughout (convention: `<Purpose> – <Scope> – <Stage>`):
- Co-management configuration: `Co-Management – Configuration – Production`
- Pilot device collection (Configuration Manager): `Co-Management – Pilot Collection – Stage 1`
- Pilot device group (Intune/Entra): `Co-Management – Pilot Devices – Stage 1`

## Step 1 — Create the pilot collection (Configuration Manager)
1. Console to Assets and Compliance to Device Collections to Create Device Collection.
2. Name: `Co-Management – Pilot Collection – Stage 1`. Limiting collection: All Systems.
3. Add a membership rule selecting a few representative, healthy devices (direct or query rule).
   Run `COMGMT-Set-CoMgmtPilotTargeting.ps1` to build the membership safely. Next to Create.

## Step 2 — Confirm cloud attach (tenant attach) is connected
1. Console to Administration to Cloud Services to Cloud Attach (or Co-management).
2. Confirm the tenant shows Connected. If not, run the Cloud Attach configuration and sign in with a
   tenant administrator.
3. Validate with `COMGMT-Validation.ps1` before continuing.

## Step 3 — Enable co-management with staged enrollment
1. Console to Administration to Cloud Services to Co-management to Configure co-management (or
   Properties if already created).
2. Name the configuration `Co-Management – Configuration – Production`.
3. On the Enablement page, set Automatic enrollment in Intune to Pilot.
4. For the pilot collection, choose `Co-Management – Pilot Collection – Stage 1`. This is the staged
   enrollment scope — only these devices auto-enroll first. Next.

## Step 4 — Leave all workloads on Configuration Manager (start state)
1. On the Workloads page, leave every slider on Configuration Manager for now:
   Compliance policies, Device configuration, Endpoint Protection, Resource access policies, Client
   apps, Office Click-to-Run apps, and Windows Update policies.
2. Finish the wizard. Co-management is now enabled; the pilot collection will auto-enroll into Intune
   while Configuration Manager still owns every workload.

## Step 5 — Onboard and verify the pilot enrolls
1. On a pilot device, trigger client policy: Configuration Manager control panel applet to Actions
   to Machine Policy Retrieval and Evaluation Cycle.
2. Confirm the device enrolls: it appears in `https://intune.microsoft.com` to Devices to All
   devices, and `dsregcmd /status` shows the MDM URL.
3. Run `COMGMT-Validation.ps1` on the pilot device to confirm co-management state and dual authority.

## Step 6 — Create the pilot device group (Intune/Entra)
1. Intune to Groups to New group to Security. Name: `Co-Management – Pilot Devices – Stage 1`.
2. Add the same pilot devices (this group targets the Intune policies for moved workloads).
   Create.

## Step 7 — Move the first workload to the pilot
1. Before moving any workload, ensure its equivalent Intune policy exists and is assigned to
   `Co-Management – Pilot Devices – Stage 1` (Requirement 2.9). Run `COMGMT-Report.ps1` to confirm.
2. Console to Administration to Cloud Services to Co-management to Properties to Workloads.
3. Move one slider — start with Compliance policies — to Pilot Intune. Apply.
4. The slider options are Configuration Manager, Pilot Intune (pilot collection only), and Intune
   (all). Use Pilot Intune for every first move.

## Step 8 — Validate the moved workload on the pilot
1. Sync the pilot device and run `COMGMT-Validation.ps1` to confirm Intune now owns that workload.
2. Confirm the Intune policy is applying (for Compliance, the device shows a compliance state in
   Intune). Complete the Testing Guide for this workload.
3. Pilot gate: do not proceed until this workload passes on the pilot.

## Step 9 — Repeat one workload at a time
1. Move the next workload to Pilot Intune, in this suggested order, validating each before the next:
   Device configuration, Endpoint Protection, Resource access policies, Client apps, Office
   Click-to-Run apps, Windows Update policies.
2. Validate each with `COMGMT-Validation.ps1` and the Testing Guide before moving on.

## Step 10 — Expand each validated workload to All
1. Once a workload has passed on the pilot, return to Workloads and move that slider from Pilot
   Intune to Intune (all). Apply.
2. Ensure the equivalent Intune policy is assigned to the broad device scope, not just the pilot
   group, before expanding.
3. Re-validate with `COMGMT-Report.ps1` across the fleet, then proceed to the next workload.

---
### Order of operations
`Pilot collection to Cloud attach to Enable co-management (Pilot) to Verify enrollment to Pilot
device group to Move workload (Pilot Intune) to Validate to Repeat per workload to Expand to Intune
(all)`


---


# 5. Testing Guide — Configuration Manager and Intune Co-Management Enablement

Run after the pilot collection enrolls (Implementation Step 5) and after each workload move.

## Test 1 — Co-management enabled and pilot scoped
Do: Console to Administration to Cloud Services to Co-management to Properties; confirm
`Co-Management – Configuration – Production` exists with automatic enrollment set to Pilot and the
pilot collection `Co-Management – Pilot Collection – Stage 1`.
Expected: Co-management is enabled and scoped to the pilot collection only.

## Test 2 — Pilot devices enrolled in Intune
Do: Intune to Devices to All devices; confirm pilot devices appear. On a device run
`COMGMT-Validation.ps1`.
Expected: Pilot devices are present in Intune and report co-managed (dual authority).

## Test 3 — Cloud attach (tenant attach) healthy
Do: Run `COMGMT-Validation.ps1`; in Intune to Devices, confirm tenant-attached devices show.
Expected: The site is connected and devices are visible from the cloud console.

## Test 4 — Workload authority is correct per slider
Do: Run `COMGMT-Report.ps1` and on a pilot device run `COMGMT-Validation.ps1`.
Expected: Each moved workload reports Intune (or Pilot Intune) as the authority; unmoved workloads
report Configuration Manager.

## Test 5 — Moved workload policy applies
Do: For the workload just moved (e.g. Compliance), confirm the Intune policy applies — for Compliance
the device shows a compliance state in Intune.
Expected: The Intune policy for the moved workload is applying on the pilot device.

## Test 6 — Equivalent Intune policy assigned before move
Do: Run `COMGMT-Report.ps1` to list which workloads have an assigned Intune policy.
Expected: Every workload set to Pilot Intune or Intune has an assigned equivalent Intune policy (no
capability gap).

## Test 7 — Un-enrolled clients remediated
Do: Run `COMGMT-Report.ps1` to find pilot devices not yet enrolled; run `COMGMT-Remediation.ps1`
(default `-WhatIf` first).
Expected: The report identifies gaps; remediation triggers a policy/enrollment retry on those
clients.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass (per workload) | Tests 1 to 6 pass for that workload on the pilot collection |
| Expand pass | Tests 4 and 6 pass fleet-wide before moving the slider to Intune (all) |


---


# 6. Troubleshooting Guide — Configuration Manager and Intune Co-Management Enablement

Use `COMGMT-Validation.ps1` / `COMGMT-Discovery.ps1` for device state and `COMGMT-Report.ps1` for
fleet status, `COMGMT-Remediation.ps1` for safe fixes.

## A. Device not enrolling into Intune
| Symptom | Cause | Remediation |
|---|---|---|
| Pilot device never appears in Intune | Client not in the pilot collection, or policy not retrieved | Confirm membership of `Co-Management – Pilot Collection – Stage 1`; trigger Machine Policy Retrieval; run `COMGMT-Remediation.ps1` |
| Enrollment fails | Device not hybrid Entra joined / no Entra identity | Run `dsregcmd /status`; fix hybrid Entra join and Entra Connect sync |
| Enrollment fails | Automatic enrollment (MDM scope) not enabled | Entra to Mobility (MDM and MAM) to Microsoft Intune; set MDM user scope to Some/All |

## B. Co-management not enabling
| Symptom | Cause | Remediation |
|---|---|---|
| Co-management wizard blocked | Cloud attach (tenant attach) not connected | Console to Administration to Cloud Services to Cloud Attach; run the wizard and sign in as tenant admin |
| Configuration Manager too old | Unsupported branch | Update via Administration to Updates and Servicing; run `COMGMT-Discovery.ps1` |

## C. Workload moved but capability lapsed
- A workload set to Intune is owned by Intune. If no equivalent Intune policy is assigned, that
  capability is gone. Author and assign the Intune policy, then re-validate with `COMGMT-Report.ps1`.
- Roll back by moving the slider back to Configuration Manager (or Pilot Intune) while you build the
  policy.

## D. Workload authority looks wrong
- Run `COMGMT-Validation.ps1` on the device and `COMGMT-Report.ps1` for the fleet to see the
  authority per workload. Confirm the slider position in Co-management Properties to Workloads
  matches what you intended (Configuration Manager / Pilot Intune / Intune).

## E. Client health blocking onboarding
- Co-management depends on a healthy Configuration Manager client. In the console, check Client = Yes
  and Client Activity = Active; repair the client; run `COMGMT-Discovery.ps1`.

## F. Diagnostics quick reference
```powershell
dsregcmd /status                                  # Entra join + MDM URL
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\CCM\CoManagementFlags' -EA SilentlyContinue   # co-management flags
Get-ComputerInfo | Select WindowsProductName, OsBuildNumber, WindowsVersion
```
Client logs: `CoManagementHandler.log` and `ComanagementWorkloadStatus` on the client
(`C:\Windows\CCM\Logs`).

## G. When to escalate
If co-management is enabled, the device is in the pilot collection, identity is healthy
(`dsregcmd /status` good), automatic enrollment is on, and the device still will not enroll after a
policy retrieval and `COMGMT-Remediation.ps1`, collect the client `CoManagementHandler.log` and open
a Microsoft support case.


---


# 7. Best Practices — Configuration Manager and Intune Co-Management Enablement

- Pilot first, always. Onboard `Co-Management – Pilot Collection – Stage 1` and use the Pilot Intune
  slider setting so a problem with any workload is contained to a few devices, never the fleet.
- Move one workload at a time. Shift a single slider, validate it, then move the next — never move
  several workloads in one change. It keeps every failure easy to diagnose and roll back.
- Have the Intune policy ready before you move the workload. A workload set to Intune is owned by
  Intune; if no equivalent policy is assigned, that capability lapses. Build and assign first.
- Fix client health before onboarding. Co-management auto-enrollment depends on a healthy
  Configuration Manager client and a working Entra identity — clean these up first.
- Confirm identity is in place. Devices must be hybrid Entra joined (or Entra joined) with Entra
  Connect syncing before enrollment will succeed.
- Use tenant attach early. Tenant attach gives you cloud visibility of devices before any workload
  moves, so you can watch enrollment and act from the Intune console.
- Validate, then expand. Only move a slider from Pilot Intune to Intune (all) after the workload
  passes on the pilot and the Intune policy is assigned to the broad scope.
- Keep names consistent. Reuse `<Purpose> – <Scope> – <Stage>` names verbatim so the configuration,
  collection, and device group stay traceable across both consoles.
- Watch both consoles. Check co-management status in the Configuration Manager console and device
  state in Intune; run `COMGMT-Report.ps1` to confirm authority per workload.
- Document the workload order and gate. Record which workloads moved, in what order, and the pilot
  result for each — for audits and repeatability.


---


# 8. Deliverables Summary — Configuration Manager and Intune Co-Management Enablement

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What co-management is, the authority model, the workload slider, cloud/tenant attach, staged enrollment, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps across the Configuration Manager console and Intune (enable co-management, staged pilot, move workloads, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `COMGMT-Discovery.ps1` | Reports co-management readiness: Configuration Manager client health, OS build, and Entra join state |
| `COMGMT-Validation.ps1` | Confirms a device is co-managed and reports the authority per workload |
| `COMGMT-Report.ps1` | Fleet-wide enrollment and workload-authority report (Microsoft Graph + ConfigMgr) |
| `COMGMT-Remediation.ps1` | Safe remediation (default `-WhatIf`); retries policy/enrollment on un-enrolled clients |
| `COMGMT-Set-CoMgmtPilotTargeting.ps1` | Builds the `Co-Management – Pilot Collection – Stage 1` membership safely |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess to Configure to Pilot to Validate to Expand.

## Outcome
A Configuration Manager fleet co-managed with Intune — workloads moving to the cloud one controlled,
validated step at a time, with a clear path to cloud-first.
