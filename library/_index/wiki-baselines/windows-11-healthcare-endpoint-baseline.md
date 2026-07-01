# Windows 11 Healthcare Endpoint Baseline (Intune)

> **Version 1.0.0** · Category: Healthcare Solutions · Solution code: W11HC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows 11 Healthcare Endpoint Baseline (Microsoft Intune)

Moving a hospital or clinic fleet to Windows 11 without a defined baseline means every device
drifts: inconsistent security settings, power options that put shared clinical PCs to sleep
mid-shift, undefined update behavior, and no documented standard to audit against. This solution
gives you one proven Windows 11 endpoint baseline — configuration profiles, the settings catalog, a
referenced security baseline, update behavior, and power/display tuning — delivered through Microsoft
Intune, assigned once and inherited by the whole fleet.

This is a complete, deploy-it-today package for standardizing Windows 11 clinical and corporate
endpoints with Microsoft Intune, written for an administrator with no prior baseline experience.

## What you get
- A plain-language Solution Overview of the baseline model: configuration profile plus settings
  catalog plus security baseline, with update and power/display tuning for shared clinical versus
  personal corporate devices.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click Intune steps in the required order.
- Five PowerShell scripts for baseline-readiness discovery, per-device validation, fleet
  baseline-drift reporting, safe remediation, and baseline-target group building.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A single, documented Windows 11 baseline — a device-restrictions and endpoint-protection
configuration, a settings catalog policy for the fine-grained controls, a referenced Microsoft
security baseline, an update ring per scope, and a power/display profile tuned so shared clinical
devices stay awake on shift while personal corporate laptops conserve battery — all named, assigned,
and inherited fleet-wide.

## The deployment model
Assess to Configure to Pilot to Validate to Expand, with a pilot gate before any device used for care
is touched.

## Outcome
Every Windows 11 endpoint on one auditable baseline — consistent security, update, and power
behavior for shared clinical and corporate devices alike — proven on a pilot before you scale.


---


# 1. Solution Overview — Windows 11 Healthcare Endpoint Baseline

## What a Windows 11 endpoint baseline is
An endpoint baseline is a single, documented set of device settings that every Windows 11 endpoint
inherits, so the fleet behaves the same way no matter who set up the device. Delivered through
Microsoft Intune, the baseline is a small stack of policies — a configuration profile, a settings
catalog policy, a referenced Microsoft security baseline, an update ring, and a power/display profile
— each named and assigned to device groups. Set it once and every enrolled device inherits it.

## How it works
1. A device-restrictions configuration profile sets the broad, visible behavior — lock-screen,
   Microsoft Defender, SmartScreen, and similar device controls.
2. A settings catalog policy adds the fine-grained controls that are not exposed in the
   restrictions templates (the settings catalog is Intune's full, searchable list of device
   settings).
3. A referenced Microsoft security baseline applies Microsoft's recommended hardened security
   settings as one assignable package, so you are not hand-picking hundreds of values.
4. An update ring controls how and when quality and feature updates install per scope — a short
   deferral for clinical devices on a maintenance window, a standard deferral for corporate.
5. A power/display profile keeps shared clinical devices awake on shift (no sleep, no display-off
   mid-task) while letting personal corporate laptops conserve battery.
6. Everything is assigned to Entra device groups (clinical versus corporate, pilot versus
   production), so the right baseline reaches the right devices.

## What you can control
- Device restrictions: Defender, SmartScreen, lock-screen, and other endpoint controls.
- Settings catalog: any documented Windows setting not covered by the restriction templates.
- Security baseline: Microsoft's hardened recommended settings as one referenced package.
- Update behavior: quality/feature deferrals, deadlines, and active hours per scope.
- Power and display: sleep, hibernate, display-off, and lid behavior — tuned for shared versus
  personal use.

## Benefits
- Consistency — every Windows 11 endpoint is built to one standard, not to whoever imaged it.
- Security — a referenced baseline plus device restrictions harden the fleet uniformly.
- Clinical uptime — shared devices stay awake on shift; no PC sleeping mid-patient-encounter.
- Auditability — one documented, named baseline you can show an auditor and reproduce.
- Repeatability — assign once, inherited fleet-wide; new devices are compliant on enrollment.

## Limitations (be honest with buyers)
- A baseline standardizes Microsoft/Windows settings; third-party app configuration and patching
  are separate.
- Settings catalog and security baseline values can overlap; this solution keeps the security
  baseline authoritative for security settings and uses the catalog for the rest to avoid conflicts.
- Power settings for shared clinical devices trade battery life for always-awake behavior; that is
  intentional but should be confirmed for any battery-only device.
- The referenced security baseline is updated by Microsoft over time; review changes before adopting
  a new baseline version.

## Why a baseline matters in a clinical setting
Shared clinical workstations are used around the clock by many clinicians; an inconsistent or
unmanaged endpoint is both a security gap and a patient-safety risk when it sleeps, drifts, or
behaves differently from the device next to it. A single inherited baseline removes that variability.

## The deployment model
> Create the device groups, build the configuration profile and settings catalog policy, reference
> the security baseline, set the update ring and power profile, assign to the pilot, validate, then
> expand. The repeatable way: Assess to Configure to Pilot to Validate to Expand.


---


# 2. Requirements Guide — Windows 11 Healthcare Endpoint Baseline

Verify every requirement before configuring. Each entry: Description, Why, Verify, and
Implement-if-missing. Category-wide prerequisites are in
`global-requirements-healthcare-solutions.md`.

## 2.1 Intune licensing and admin role
Description: A Microsoft Intune subscription and an operator holding Intune Administrator (or
Endpoint Security Manager).
Why: Intune delivers the configuration profiles, settings catalog policy, security baseline, update
ring, and power profile, and authoring them requires elevated rights.
Verify: M365 admin center, Billing, Licenses; Entra, Roles and administrators shows the operator's
role.
Implement: Assign M365 E3/E5 or Business Premium (Intune included); assign the operator Intune
Administrator.

## 2.2 Devices enrolled and Entra joined
Description: Targeted Windows 11 devices are Intune-enrolled and Microsoft Entra joined (or hybrid
Entra joined).
Why: Baseline policies reach only enrolled, identity-bound devices, and assignments are scoped to
Entra device groups.
Verify: Intune, Devices, All devices (device present); on the device `dsregcmd /status` shows
`AzureAdJoined : YES`. Run `W11HC-Discovery.ps1`.
Implement: Enroll via Autopilot or Settings, Accounts, Access work or school; for hybrid, configure
Entra Connect.

## 2.3 Supported Windows 11 edition and hardware
Description: Devices run a supported, licensed Windows 11 (Pro/Enterprise/Education) on hardware that
meets Windows 11 requirements (TPM 2.0, Secure Boot capable).
Why: The security baseline and several catalog settings assume Windows 11 with TPM and Secure Boot.
Verify: `winver` on a device, or Intune, device, Hardware; run `W11HC-Discovery.ps1` (reports build,
TPM, Secure Boot).
Implement: Apply correct Windows licensing; upgrade devices to a supported Windows 11 build; enable
TPM and Secure Boot in firmware where supported.

## 2.4 Device groups for baseline targeting
Description: Entra security groups that separate clinical from corporate and pilot from production.
Why: The baseline is assigned by scope and stage, so each group receives the right configuration,
update ring, and power profile.
Verify: Entra, Groups shows the four target groups; run `W11HC-Discovery.ps1` for membership counts.
Implement: Create the groups named in the Implementation Guide, or run
`W11HC-Set-BaselineTargeting.ps1` to create and populate them.

## 2.5 A referenced security baseline available
Description: The Microsoft Security Baseline for Windows is available to reference in Intune,
Endpoint security, Security baselines.
Why: The baseline applies Microsoft's hardened recommended settings as one assignable package
instead of hundreds of hand-set values.
Verify: Intune, Endpoint security, Security baselines lists the current Windows security baseline.
Implement: No install needed; the baseline is built into Intune. Confirm your tenant shows the
current version before referencing it.

## 2.6 No conflicting configuration authority
Description: Intune is the authority for these settings, not a leftover group policy (GPO) or a
second overlapping Intune profile.
Why: Two authorities setting the same value fight and cause inconsistent results and conflict
reports.
Verify: Run `W11HC-Discovery.ps1` (flags an on-prem GPO `WUServer` and common policy keys); review
Intune, Devices, Configuration for overlapping profiles.
Implement: Remove or scope away the conflicting GPO/profile so the baseline is authoritative.

---
## Checklist
- [ ] Intune licensing and Intune Administrator assigned
- [ ] Devices enrolled and Entra joined — `W11HC-Discovery.ps1`
- [ ] Supported Windows 11 edition, TPM 2.0, Secure Boot — `W11HC-Discovery.ps1`
- [ ] Clinical/corporate and pilot/production device groups created
- [ ] Current Windows security baseline available in Intune
- [ ] No conflicting GPO/profile authority


---


# Global Requirements — Healthcare Solutions (category-level)

These requirements apply to **every** solution in the **Healthcare Solutions** category. They are
published once at the category level so individual solution listings stay focused. Confirm all of
them are in place before deploying *any* Healthcare Solutions product into a clinical environment.

Each entry: **Description · Why required · How to verify · How to implement if missing.**

> Clinical environments carry obligations (HIPAA, often HITRUST) and uptime expectations that a
> standard office fleet does not. Treat every change as a controlled clinical change, not an ad-hoc
> IT task.

## G1. Microsoft 365 / Intune tenant with admin roles
**Description:** An active Microsoft Entra ID tenant with a Microsoft Intune subscription, and an
operator holding **Intune Administrator** (or **Application Manager** / **Endpoint Security Manager**
as appropriate).
**Why:** Intune is the delivery channel for every configuration and application in this category;
authoring profiles, apps, and assignments requires elevated rights.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows an
active subscription; Entra → **Roles and administrators** shows the operator's role.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1; assign the
operator **Intune Administrator**. Reserve Global Administrator for tenant-wide setup only.

## G2. Windows licensing for managed clinical endpoints
**Description:** Targeted devices run a supported, licensed **Windows 10 / Windows 11**
(Enterprise or Pro) with current cumulative updates.
**Why:** Modern Intune configuration, app-management, and printing features assume a patched,
supported OS.
**Verify:** `winver` on a device, or Intune → device → **Hardware**.
**Implement:** Apply correct Windows licensing; deploy **Update rings**
(Intune → **Devices → Windows → Update rings**) or upgrade devices to a supported build.

## G3. Devices enrolled and identity-joined
**Description:** Clinical endpoints are **Intune-enrolled** and **Microsoft Entra joined** (or
**hybrid Entra joined** where co-managed with Configuration Manager).
**Why:** Policies, profiles, and apps only reach enrolled, identity-bound devices, and assignments
are scoped to Entra device groups.
**Verify:** Intune → **Devices → All devices** (device present, compliant); on the device
`dsregcmd /status` shows `AzureAdJoined : YES` (or `DomainJoined : YES` + `AzureAdJoined : YES` for
hybrid).
**Implement:** Enroll via Autopilot or **Settings → Accounts → Access work or school**; for hybrid,
configure Entra Connect + group policy / co-management.

## G4. HIPAA / HITRUST data-handling and clinical change control
**Description:** A documented change-control process for clinical endpoints, and data-handling that
keeps **electronic protected health information (ePHI)** in-bounds — no ePHI in logs, exports, or
script output; least-privilege access; auditable changes.
**Why:** Clinical endpoints handle ePHI; uncontrolled changes risk both patient safety and
HIPAA / HITRUST compliance. Every standardization, printer, and peripheral change must be
change-managed and auditable.
**Verify:** Confirm a change ticket / change-advisory-board (CAB) approval exists for the deployment;
confirm the scripts and reports in use do **not** capture patient data (the tools in this category
are read-only over device/printer/app state, not over clinical content).
**Implement:** Route the change through your CAB; record the approved change window, rollback plan,
and back-out criteria; restrict who can run deployment actions; retain change records per your
compliance program.

## G5. Clinical maintenance windows
**Description:** Approved, low-acuity maintenance windows during which clinical endpoints may be
reconfigured, have printers re-mapped, or be rebooted, agreed with clinical operations.
**Why:** Pushing a profile, printer change, or reboot during patient care is unacceptable; shared
clinical devices are often in use around the clock.
**Verify:** A documented maintenance-window schedule exists and is referenced in the change ticket.
**Implement:** Agree windows with clinical operations / nursing leadership; align Intune assignment
**availability** and any restart behavior to those windows.

## G6. Network access to Microsoft and clinical service endpoints
**Description:** Outbound HTTPS from clinical endpoints to **Microsoft 365 / Entra / Intune** service
URLs and **Universal Print** endpoints, plus reachability to any **on-premises print servers /
direct-IP printer queues** and the **Epic Print Service (EPS)** host the workflows use.
**Why:** Enrollment, policy sync, profile and app delivery, Universal Print, and scripted printer
installation all depend on these network paths.
**Verify:** From a device, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`; for Universal Print reach `*.print.microsoft.com`; for
scripted install, confirm the print server / printer IP is reachable; confirm profile and app
deployments report **Succeeded** in Intune.
**Implement:** Allow Microsoft's published Office 365 / Intune / Universal Print URL & IP ranges, and
the print-server / printer / EPS endpoints your build team specifies, through proxy / firewall.

## G7. A non-production / test clinical device
**Description:** At least one **dedicated test device** representative of the clinical fleet (ideally
one of each form factor — a fixed workstation and a WOW), in a representative **unit**, that is
**not in live patient care**.
**Why:** Every baseline, printer-deployment, and peripheral change is proven on a test device before
any pilot or broad assignment touches a device used for care.
**Verify:** The test device is enrolled, in the pilot group, located in (or representing) the target
unit, and flagged as non-production.
**Implement:** Set aside a representative device; add it to the pilot group used by the solution.

## G8. Rollback posture
**Description:** A defined back-out plan for every change: how to revert a configuration profile, how
to restore the previous printer-deployment / default-printer mapping, and the criteria that trigger a
rollback.
**Why:** In a clinical setting a failed change must be reversible quickly to protect care delivery.
**Verify:** The change ticket includes a rollback plan and names the previously-validated profile /
printer mapping to revert to.
**Implement:** Keep the prior validated profile assignments and printer-deployment policy (export the
settings catalog profile and record the prior per-unit default printer); document the revert steps
(re-assign prior profile / remove the new assignment) before deploying the new one.

---
**The standard deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.**
For workstation-standardization solutions in this category this is realized as
**Assess → Standardize → Deploy Peripherals/Printing → Pilot → Validate → Expand**.


---


# 3. Implementation Guide — Windows 11 Healthcare Endpoint Baseline

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).
Create every object with the exact name shown and reuse it verbatim in later steps.

> Model: Build the baseline once, assign it to a small clinical pilot, validate, then expand to the
> whole fleet. The pilot gate protects devices used for care. The repeatable way: Assess to Configure
> to Pilot to Validate to Expand.

## Objects this guide creates (names are fixed — reuse exactly)
| Object | Name |
|---|---|
| Device group (clinical pilot) | `W11 Baseline – Clinical – Pilot` |
| Device group (clinical production) | `W11 Baseline – Clinical – Production` |
| Device group (corporate pilot) | `W11 Baseline – Corporate – Pilot` |
| Device group (corporate production) | `W11 Baseline – Corporate – Production` |
| Configuration profile (device restrictions) | `W11 Device Restrictions – All – Baseline` |
| Settings catalog policy | `W11 Settings Catalog – All – Baseline` |
| Security baseline reference | `W11 Security Baseline – All – Baseline` |
| Update ring (clinical) | `W11 Update Ring – Clinical – Baseline` |
| Update ring (corporate) | `W11 Update Ring – Corporate – Baseline` |
| Power profile (clinical, always-on) | `W11 Power – Clinical – AlwaysOn` |
| Power profile (corporate, battery-saving) | `W11 Power – Corporate – BatterySaver` |

## Step 1 — Create the device groups
1. Entra, Groups, New group, Security; name `W11 Baseline – Clinical – Pilot` (a few representative
   non-production clinical devices). Create.
2. Repeat for `W11 Baseline – Clinical – Production`, `W11 Baseline – Corporate – Pilot`, and
   `W11 Baseline – Corporate – Production`.

(You can create and populate all four with `W11HC-Set-BaselineTargeting.ps1` instead.)

## Step 2 — Create the device-restrictions configuration profile
1. Intune, Devices, Configuration, Create, New policy. Platform Windows 10 and later; Profile type
   Templates; Device restrictions. Create.
2. Name `W11 Device Restrictions – All – Baseline`. Next.
3. Under Microsoft Defender Antivirus, enable real-time monitoring and cloud-delivered protection.
   Under Microsoft Defender SmartScreen, turn SmartScreen on. Under Locked screen experience and
   General, set your lock-screen and basic device controls. Next.
4. Assignments, Add groups, add `W11 Baseline – Clinical – Pilot` and `W11 Baseline – Corporate – Pilot`. Next, Create.

## Step 3 — Create the settings catalog policy
1. Intune, Devices, Configuration, Create, New policy. Platform Windows 10 and later; Profile type
   Settings catalog. Create.
2. Name `W11 Settings Catalog – All – Baseline`. Next.
3. Add settings, search the catalog, and add the fine-grained controls the restrictions template does
   not expose (for example specific Microsoft Defender, AutoPlay, and lock-screen timeout settings).
   Set each to your standard. Next.
4. Assignments, Add groups, add `W11 Baseline – Clinical – Pilot` and `W11 Baseline – Corporate – Pilot`. Next, Create.

## Step 4 — Reference the security baseline
1. Intune, Endpoint security, Security baselines, open the current Security Baseline for Windows,
   Create profile.
2. Name `W11 Security Baseline – All – Baseline`. Next.
3. Review the recommended settings; accept the defaults unless a setting conflicts with a clinical
   workflow. The security baseline is authoritative for security settings, so do not duplicate those
   in the settings catalog policy. Next.
4. Assignments, Add groups, add `W11 Baseline – Clinical – Pilot` and `W11 Baseline – Corporate – Pilot`. Next, Create.

## Step 5 — Create the update rings
1. Intune, Devices, Windows, Update rings for Windows 10 and later, Create profile.
2. Name `W11 Update Ring – Clinical – Baseline`. Set Quality update deferral 3 days, Feature update
   deferral 14 days, Automatic update behavior Auto install and restart at maintenance time, Active
   hours aligned to the clinical maintenance window. Assignments, add
   `W11 Baseline – Clinical – Pilot`. Create.
3. Create profile again. Name `W11 Update Ring – Corporate – Baseline`. Set Quality deferral 7 days,
   Feature deferral 14 days, standard active hours. Assignments, add
   `W11 Baseline – Corporate – Pilot`. Create.

## Step 6 — Create the power/display profiles
1. Intune, Devices, Configuration, Create, New policy. Platform Windows 10 and later; Profile type
   Settings catalog. Name `W11 Power – Clinical – AlwaysOn`. Add the Power settings: set
   plugged-in sleep and display-off timeouts to Never (0) so shared clinical devices stay awake on
   shift; set lid-close action to Do nothing where appropriate. Assignments, add
   `W11 Baseline – Clinical – Pilot`. Create.
2. Create another settings catalog policy. Name `W11 Power – Corporate – BatterySaver`. Set sensible
   on-battery sleep and display-off timeouts so corporate laptops conserve battery. Assignments, add
   `W11 Baseline – Corporate – Pilot`. Create.

## Step 7 — Apply on a pilot device
1. On a pilot device, sync policy (Settings, Accounts, Access work or school, Info, Sync).
2. Confirm the profiles applied (Intune device, Device configuration shows Succeeded), or run
   `W11HC-Validation.ps1`.

## Step 8 — Validate the pilot
1. Run `W11HC-Validation.ps1` on a pilot device to confirm the baseline settings are present.
2. Run `W11HC-Report.ps1` to confirm pilot devices show the baseline policies as Succeeded across the
   fleet view. Complete the Testing Guide. Do not proceed past the pilot gate until all pass.

## Step 9 — Expand to production
1. Open each object (Steps 2 through 6) and in Assignments add the matching Production group:
   clinical objects get `W11 Baseline – Clinical – Production`, corporate objects get
   `W11 Baseline – Corporate – Production`.
2. Re-validate after the next policy cycle with `W11HC-Report.ps1`; remediate any drift with
   `W11HC-Remediation.ps1`.

---
### Order of operations
`Device groups -> Device restrictions -> Settings catalog -> Security baseline -> Update rings -> Power profiles -> Apply -> Validate (pilot gate) -> Expand`


---


# 5. Testing Guide — Windows 11 Healthcare Endpoint Baseline

Run after the pilot assignment applies (Implementation Step 8) and again after expanding to
production. All Test 1 through Test 6 must pass on the pilot before the expand step (the pilot gate).

## Test 1 — Profiles applied
Do: Intune, Devices, Configuration, open `W11 Device Restrictions – All – Baseline`, Device status.
Expected: Pilot devices show Succeeded. Repeat for `W11 Settings Catalog – All – Baseline`.

## Test 2 — Security baseline applied
Do: Intune, Endpoint security, Security baselines, open `W11 Security Baseline – All – Baseline`,
check status.
Expected: Pilot devices show Succeeded with no Conflict.

## Test 3 — Settings present on device
Do: On a pilot device run `W11HC-Validation.ps1`.
Expected: Defender/SmartScreen on, baseline registry values present, no conflicting authority.

## Test 4 — Update ring applied
Do: Intune, Devices, Windows, Update rings, open `W11 Update Ring – Clinical – Baseline`, Device
status; or run `W11HC-Validation.ps1`.
Expected: Pilot devices show Succeeded; deferral/active-hours values match the ring.

## Test 5 — Power behavior correct
Do: On a clinical pilot device run `powercfg /q` (or `W11HC-Validation.ps1`) and confirm sleep and
display-off are Never on plugged-in power.
Expected: Shared clinical device does not sleep or blank mid-shift; corporate device conserves on
battery.

## Test 6 — Fleet report
Do: Run `W11HC-Report.ps1`.
Expected: A clear per-device baseline status (which baseline policies are Succeeded, which devices
lag) and OS-build inventory.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 through 6 pass on the pilot groups; no Conflict on the security baseline |
| Production pass | Tests 1 through 4 and Test 6 pass for the production groups after expand |


---


# 6. Troubleshooting Guide — Windows 11 Healthcare Endpoint Baseline

Use `W11HC-Validation.ps1` and `W11HC-Discovery.ps1` for device state, `W11HC-Report.ps1` for fleet
status, and `W11HC-Remediation.ps1` for a safe sync.

## A. Profile shows Error or Not applicable
| Symptom | Cause | Remediation |
|---|---|---|
| Profile shows Error | Device not enrolled or not checked in | Confirm enrollment and group membership; run `W11HC-Remediation.ps1` to sync |
| Profile shows Not applicable | Device not in the assigned group, or wrong platform | Confirm the device is in the correct `W11 Baseline – <Scope> – <Stage>` group |
| Settings not present on device | Policy not yet synced | Run `W11HC-Remediation.ps1`; re-check after a policy cycle with `W11HC-Validation.ps1` |

## B. Security baseline shows Conflict
- A Conflict means two policies set the same security value. Keep `W11 Security Baseline – All – Baseline`
  authoritative for security settings and remove that value from `W11 Settings Catalog – All – Baseline`
  (or from any legacy GPO). Re-sync and re-check.

## C. Shared clinical device still sleeps mid-shift
| Symptom | Cause | Remediation |
|---|---|---|
| Device sleeps or display blanks | `W11 Power – Clinical – AlwaysOn` not applied, or device on battery | Confirm the profile is assigned and Succeeded; on battery-only devices set on-battery timeouts too; verify with `powercfg /q` |
| Power profile shows Conflict | A second power profile or GPO also setting power | Remove the duplicate; keep one power profile per scope |

## D. Updates not installing or restarting at the wrong time
- Confirm the device is in the correct update-ring group and the ring shows Succeeded; check the
  deferral and active-hours values match the maintenance window. Run `W11HC-Remediation.ps1` to sync,
  then let a policy cycle pass.

## E. Conflicting configuration authority
- An on-prem GPO (for example a `WUServer` value) or a second overlapping Intune profile will fight
  the baseline. Run `W11HC-Discovery.ps1` to flag it, then remove or scope away the conflicting
  source so the baseline is authoritative.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion
(Get-Tpm).TpmPresent, (Confirm-SecureBootUEFI)
Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled, AntivirusEnabled
powercfg /q                       # current power scheme timeouts
dsregcmd /status                  # Entra join + MDM enrollment state
```

## G. When to escalate
If the profiles show Succeeded, no conflict exists, the device is synced and in the right group, and
a setting still will not apply after a policy cycle, collect `dsregcmd /status` and the Intune device
configuration status, then open a Microsoft support case.


---


# 7. Best Practices — Windows 11 Healthcare Endpoint Baseline

- Pilot before you scale, always. Assign the baseline to a small clinical pilot, validate, and only
  then expand — the single most important practice for devices used in patient care.
- One authoritative source per setting. Let the referenced security baseline own security settings
  and the settings catalog own the rest; do not set the same value in two places or they will
  conflict.
- Name everything to a convention. Use the `<Purpose> – <Scope> – <Stage>` naming from the
  Implementation Guide so any operator can read the fleet at a glance and reproduce it.
- Separate clinical from corporate. Shared clinical devices need always-awake power and a
  maintenance-window update ring; corporate laptops need battery saving and standard updates — keep
  them in distinct groups and profiles.
- Keep shared clinical devices awake. Set plugged-in sleep and display-off to Never so no PC sleeps
  mid-encounter; confirm this is acceptable for any battery-only clinical device.
- Align updates to maintenance windows. Set update-ring active hours and restart behavior to the
  approved clinical maintenance windows so patches never interrupt care.
- Review security baseline updates. Microsoft revises the baseline over time; review the diff before
  adopting a new version rather than auto-upgrading.
- Watch for drift. Run `W11HC-Report.ps1` on a cadence and chase any device that lags the baseline;
  remediate with `W11HC-Remediation.ps1`.
- Document the baseline. Record the object names, assignments, and key settings for audits and for
  the next operator — the baseline is only repeatable if it is written down.
- Keep a rollback ready. Note the prior validated assignments before each change so a failed baseline
  change can be reverted quickly.


---


# 8. Deliverables Summary — Windows 11 Healthcare Endpoint Baseline

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | What a baseline is; configuration profile, settings catalog, security baseline, update, power; benefits and limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Healthcare Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps with named objects |
| 5. Testing Guide | Validation procedures with a pilot-gate pass/fail |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `W11HC-Discovery.ps1` | Reports OS build, edition, TPM, Secure Boot, enrollment, and conflicting authority (read-only) |
| `W11HC-Validation.ps1` | Confirms the baseline settings applied on a device (Defender, SmartScreen, update, power) (read-only) |
| `W11HC-Report.ps1` | Fleet-wide baseline status and OS-build inventory via Microsoft Graph (read-only) |
| `W11HC-Remediation.ps1` | Safe remediation; forces an MDM sync so the baseline re-applies (default `-WhatIf`) |
| `W11HC-Set-BaselineTargeting.ps1` | Creates and populates the clinical/corporate and pilot/production device groups via Microsoft Graph |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Every Windows 11 endpoint on one documented, auditable baseline — consistent security, update, and
power behavior for shared clinical and corporate devices — proven on a pilot before fleet rollout.
