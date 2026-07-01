# New-Site Endpoint Rollout Playbook

> **Version 1.0.0** · Category: Infrastructure · Solution code: NEWSITE

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — New-Site Endpoint Rollout Playbook (Microsoft Intune)

Opening a new office, clinic, branch, or acquired site usually means reinventing the endpoint
rollout from scratch — scrambling on go-live day and discovering missing apps, no printers, or
no network access while staff are already trying to work. This package replaces that scramble with
a repeatable program: a sequenced playbook that provisions the site's devices, applies your
existing baseline, deploys the site's apps and printers, validates connectivity and identity, and
runs a concrete go-live checklist — so every new location opens the same proven way.

This is a complete, deploy-it-today playbook for rolling out endpoints at a new site with Microsoft
Intune, written for an administrator with no prior site-rollout experience. It reuses the Intune
standards you already have rather than building anything new.

## What you get
- A plain-language Solution Overview of the new-site rollout model and its dependency order.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click Intune steps in the required order.
- Five PowerShell scripts for site-readiness discovery, per-device go-live validation, a site
  rollout status report, safe remediation of failed deployments, and a site device-group builder.
- A concrete go-live checklist, plus Testing and Troubleshooting guides for confident rollout.

## What this delivers
A sequenced rollout — network/identity readiness, then provisioning, then your baseline, then the
site's apps and printers, then validation, then go-live — driven by a per-site device group and a
consistent object-naming convention. The first site runs as the pilot; once it passes the go-live
gate, you repeat the same program at every subsequent location.

## The deployment model
Assess → Configure → Pilot → Validate → Expand. The first site is the pilot.

## Outcome
Every new site opening with endpoints that work on day one — provisioned, baselined, app- and
printer-ready, and validated against a go-live checklist — proven on a pilot site before you repeat
it everywhere.


---


# 1. Solution Overview — New-Site Endpoint Rollout Playbook

## What this playbook is
The New-Site Endpoint Rollout Playbook is a repeatable program for standing up Windows endpoints at
a new location — a new office, clinic, branch, or acquired site — using Microsoft Intune. Instead of
reinventing the rollout each time, you follow one sequenced process: confirm the site's network and
identity readiness, provision its devices, apply your existing device baseline, deploy the site's
apps and printers, validate that everything works, and run a go-live checklist before staff arrive.

It deliberately reuses the Intune standards you already have — your compliance policy, your security
baseline, your Autopilot/enrollment configuration, your printer deployment method — and adds only
the per-site coordination layer: a site device group, site-scoped assignments, validation, and the
go-live gate. The repeatable way to open a site is to make the rollout a program, not a one-off.

## The dependency order (why the sequence matters)
Each stage depends on the one before it; doing them out of order is the usual cause of a chaotic
go-live. The order is:

1. Network / identity readiness — the site can reach Microsoft cloud endpoints and devices can sign
   in and enroll. Nothing downstream works without this, so it is verified first.
2. Provisioning — devices are enrolled into Intune and placed in the site's device group.
3. Baseline — your standard compliance policy, security baseline, and configuration apply to the
   site's devices so they match the rest of the fleet.
4. Apps and printers — the site's required applications and its local printers deploy to the site
   group.
5. Validation — connectivity, identity sign-in, baseline state, app installs, and printing are
   confirmed per device.
6. Go-live checklist — a final gate; only when every item passes does the site open.

After the first site passes the gate, you expand: repeat the identical program for the next site by
cloning the site group and assignments and changing only the site name.

## How it works
- A per-site Microsoft Entra device group scopes every assignment to that site only, so one site's
  rollout never disturbs another.
- Existing baseline and configuration profiles are assigned to the new site group — you reuse them,
  you do not author new ones.
- The site's app set and printer set are deployed to the site group as required (auto-installed)
  assignments.
- Validation scripts confirm each device meets the go-live criteria; the go-live checklist is the
  final human gate.
- A status report shows, per site, how many devices are provisioned, baselined, app-ready, and
  validated — so you know at a glance whether the site is ready to open.

## What you control
- The per-site device group and the consistent naming of every object created for the site.
- Which existing baseline / configuration profiles are assigned to the site.
- The site's app set and printer set.
- The go-live criteria and the order in which sites are opened (pilot first, then expand).

## Object naming convention (use verbatim)
Every object you create for a site is named `<Purpose> – <Site> – <Stage>` so the tenant stays
readable as you add sites. Reuse these names exactly:

- Site device group (pilot site): `New Site – Site A – Pilot`
- Site device group (a later site): `New Site – Site B – Production`
- App deployment assignment: `App Deployment – Site A – Pilot`
- Printer deployment assignment: `Printer Deployment – Site A – Pilot`
- Baseline assignment: `Baseline Assignment – Site A – Pilot`

For the first site, the Stage is `Pilot`; for every site after the pilot validates, the Stage is
`Production`.

## Benefits
- Predictable go-live — endpoints work on day one because nothing is improvised.
- Repeatable — every site opens the same proven way; the second site is faster than the first.
- Low risk — the first site runs as a pilot and must pass a go-live gate before you scale.
- Reuses your standards — no new baseline to maintain; the site inherits the fleet's configuration.
- Visible — a per-site status report shows exactly how far each rollout has progressed.

## Limitations (be honest with buyers)
- This is a coordination playbook, not a replacement for your baseline — it assumes you already have
  a compliance policy, security baseline, and enrollment method in place (the Requirements Guide
  shows how to confirm or create them).
- It manages Windows endpoints through Intune; non-Windows platforms and on-premises-only servers
  are out of scope.
- Physical site readiness (cabling, internet circuit, Wi-Fi) must be delivered by the site/network
  team; the playbook verifies cloud reachability but does not install network hardware.
- Printer deployment uses your existing method (Universal Print or a print-server connector); the
  playbook assigns printers to the site group but does not change your print architecture.

## The deployment model
> Confirm network/identity → build the site device group → provision devices → apply baseline →
> deploy site apps and printers → validate → run the go-live checklist → expand to the next site.
> Model: Assess → Configure → Pilot → Validate → Expand — the first site is the pilot.


---


# 2. Requirements Guide — New-Site Endpoint Rollout Playbook

Verify **every** requirement before you start a site rollout. Each entry: Description · Why ·
Verify · Implement-if-missing. Category-wide prerequisites are in
`global-requirements-infrastructure.md`. This playbook reuses your existing Intune standards — most
requirements below are about confirming those standards exist, not building new ones.

## 2.1 Intune licensing
Description: Microsoft Intune (Plan 1 or via Microsoft 365 E3/E5 or Business Premium).
Why: Intune delivers the device group targeting, baseline, app, and printer assignments the rollout
depends on.
Verify: Microsoft 365 admin center → **Billing → Licenses**; confirm an Intune-bearing plan.
Implement: Assign Microsoft 365 E3/E5 or Business Premium (Intune included), or standalone Intune
Plan 1.

## 2.2 Enrollment method for the new site
Description: A way to enroll the site's devices into Intune — Windows Autopilot, automatic
enrollment, or bulk enrollment.
Why: Provisioning (the second stage) cannot happen until devices can enroll.
Verify: Intune → **Devices → Enrollment → Windows**; confirm an enrollment method is configured
(Autopilot profile or automatic enrollment).
Implement: Configure **Automatic Enrollment** (Intune → Devices → Enrollment → Automatic
Enrollment, set MDM user scope), and/or import the site's devices as Autopilot devices.

## 2.3 Site network / identity readiness
Description: The site can reach Microsoft cloud endpoints and devices can sign in and enroll from
the site's network.
Why: This is the first dependency — provisioning, baseline, apps, and printing all fail if the site
cannot reach Microsoft Entra and Intune.
Verify: From a device on the site network, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`; run `NEWSITE-Discovery.ps1` for an automated check.
Implement: Have the network team allow Microsoft's published Microsoft 365 / Intune URL and IP
ranges through the site proxy/firewall, and confirm the internet circuit and Wi-Fi are live.

## 2.4 Existing device baseline
Description: Your standard compliance policy, security baseline, and configuration profiles that the
rest of the fleet uses.
Why: The site inherits the fleet's baseline rather than getting a new one; this is what makes the
rollout repeatable.
Verify: Intune → **Devices → Compliance** and **Endpoint security → Security baselines**; confirm
your standard policies exist.
Implement: If no baseline exists, create your standard compliance policy and security baseline once
(this becomes the reusable baseline for all sites). The exact baseline is your organization's
standard and is out of scope for this playbook.

## 2.5 Site app set
Description: The list of applications the site's staff need, available as Intune apps.
Why: Apps are deployed to the site group during the apps/printers stage; they must already be
packaged in Intune.
Verify: Intune → **Apps → Windows**; confirm the site's required apps are present (Microsoft Store,
Win32, or line-of-business apps).
Implement: Add any missing apps (Intune → Apps → Windows → Add); reuse apps already in your catalog
where possible.

## 2.6 Site printer set and a printer deployment method
Description: The site's local printers and your existing way of deploying them — Universal Print or a
print-server / connector method.
Why: Printers are assigned to the site group during the apps/printers stage.
Verify: For Universal Print, Intune → **Devices → Configuration**; confirm a Universal Print printer
profile or your printer-deployment configuration exists. For a print server, confirm the connector
is in place.
Implement: Register the site's printers in your chosen print method and prepare a printer assignment
targetable to a device group. The playbook assigns to the site group; it does not change your print
architecture.

## 2.7 Site device group (created by this playbook)
Description: A Microsoft Entra device group scoped to the new site, named per the convention.
Why: It scopes every assignment to the site so one rollout never disturbs another.
Verify: Entra → **Groups**; confirm the site group exists (e.g. `New Site – Site A – Pilot`).
Implement: Create it manually (Entra → Groups → New group → Security) or run
`NEWSITE-Set-SiteGroupTargeting.ps1` to build it.

## 2.8 Go-live window and pilot designation
Description: A scheduled go-live date for the site, and a decision on which site is the pilot.
Why: The first site runs as the pilot and must pass the go-live gate before you scale; the window
sets the validation deadline.
Verify: Confirm with the business the site's open date and that the first site is treated as the
pilot.
Implement: Designate the first site as the pilot; schedule its go-live with enough lead time to run
validation and remediation before staff arrive.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Enrollment method configured for the site (Autopilot / automatic enrollment)
- [ ] Site network/identity reachable — `NEWSITE-Discovery.ps1`
- [ ] Existing baseline (compliance + security baseline) present
- [ ] Site app set available in Intune
- [ ] Site printer set + printer deployment method ready
- [ ] Site device group created (per naming convention)
- [ ] Go-live window scheduled; first site designated as pilot


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


# 3. Implementation Guide — New-Site Endpoint Rollout Playbook

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) and the **Microsoft Entra admin center**
(`https://entra.microsoft.com`). The order matches the dependency chain: network/identity →
provisioning → baseline → apps/printers → validation → go-live → expand.

> Model: the first site is the pilot. Run the full sequence for the pilot site, pass the go-live
> gate, then repeat for each subsequent site by cloning the site group and assignments and changing
> only the site name. Name every object created `<Purpose> – <Site> – <Stage>` (e.g.
> `New Site – Site A – Pilot`).

## Step 1 — Confirm network and identity readiness
1. From a device on the new site's network, browse to `https://login.microsoftonline.com` and
   `https://enrollment.manage.microsoft.com` — both must load.
2. Run `NEWSITE-Discovery.ps1` on a device at the site to check cloud reachability, DNS, and time
   sync.
3. Do not continue until the site is reachable; provisioning and everything after it depend on this.

## Step 2 — Build the site device group
1. Entra → **Groups → New group**.
2. **Group type:** Security. **Group name:** `New Site – Site A – Pilot` (use `Production` as the
   Stage for sites after the pilot). **Membership type:** Assigned (or a dynamic rule on the site's
   device-name prefix or enrollment tag). **Create**.
3. Alternatively, run `NEWSITE-Set-SiteGroupTargeting.ps1 -SiteName "Site A" -Stage "Pilot"` to
   create the group and add the site's devices by name pattern or device ID list.

## Step 3 — Provision the site's devices
1. Enroll the site's devices using your configured method:
   - Autopilot: Intune → **Devices → Enrollment → Windows → Windows Autopilot deployment profiles**;
     confirm the site's imported devices are assigned a profile, then run the out-of-box experience
     on each device.
   - Automatic enrollment: join each device to Entra ID (**Settings → Accounts → Access work or
     school → Connect → Join this device to Microsoft Entra ID**), which auto-enrolls it.
2. Confirm each device appears under Intune → **Devices → All devices** and is a member of the site
   device group (sync the group membership if you used a static list).

## Step 4 — Apply the existing baseline to the site
1. Intune → **Devices → Compliance**; open your standard compliance policy → **Properties →
   Assignments → Edit → Add groups →** `New Site – Site A – Pilot`. **Review + save**.
2. Intune → **Endpoint security → Security baselines**; open your standard baseline → **Properties →
   Assignments →** add `New Site – Site A – Pilot`. **Save**.
3. Assign any standard configuration profiles the fleet uses to the same site group. You are reusing
   existing policies — do not author new ones.

## Step 5 — Deploy the site's apps
1. Intune → **Apps → Windows**; for each app in the site's app set, open the app → **Properties →
   Assignments → Edit**.
2. Under **Required**, **Add group →** `New Site – Site A – Pilot`. **Review + save**.
3. Keep the assignment name consistent in your records as `App Deployment – Site A – Pilot`.

## Step 6 — Deploy the site's printers
1. Use your existing printer method:
   - Universal Print: Intune → **Devices → Configuration**; open your Universal Print printer profile
     (or create a configuration that provisions the site's printers) → **Assignments → Add groups →**
     `New Site – Site A – Pilot`. **Save**.
   - Print server / connector: assign your printer-deployment configuration to the site group the
     same way.
2. Record the assignment as `Printer Deployment – Site A – Pilot`.

## Step 7 — Validate each device
1. On each provisioned device, sync policy (**Settings → Accounts → Access work or school → Info →
   Sync**).
2. Run `NEWSITE-Validation.ps1` on each device → confirms it is enrolled, baseline-compliant, the
   site apps are installed, and the site printers are present.
3. Run `NEWSITE-Report.ps1` → shows the site's overall rollout status (provisioned / baselined /
   app-ready / validated counts) from Intune.

## Step 8 — Run the go-live checklist
Open the site only when every item passes. Use `NEWSITE-Report.ps1` and `NEWSITE-Validation.ps1` as
the evidence.

- [ ] Network/identity confirmed at the site (Step 1)
- [ ] All site devices enrolled and in the site group (Step 3)
- [ ] Baseline compliant on all devices — compliance policy + security baseline applied (Step 4)
- [ ] Site apps installed on all devices (Step 5)
- [ ] Site printers present and a test page prints (Step 6)
- [ ] Each device passes `NEWSITE-Validation.ps1`
- [ ] A representative user can sign in, open the site apps, and print
- [ ] Any failures remediated with `NEWSITE-Remediation.ps1` and re-validated

## Step 9 — Expand to the next site
1. Repeat Steps 2–8 for the next site, naming its group `New Site – Site B – Production` and its
   assignments accordingly.
2. Reuse the identical baseline, and the app/printer assignment pattern — change only the site name
   and Stage.
3. Re-run `NEWSITE-Report.ps1` per site to confirm each new site passes the same go-live gate.

---
### Order of operations
`Confirm network/identity → site device group → provision devices → apply baseline → deploy site
apps → deploy site printers → validate → go-live checklist → expand`


---


# 5. Testing Guide — New-Site Endpoint Rollout Playbook

Run these after the site's devices are provisioned (Implementation Step 7) and again before the
go-live gate (Step 8). The first site is the pilot; it must pass every gate before you expand.

## Test 1 — Network / identity reachable at the site
Do: From a device on the site network, run `NEWSITE-Discovery.ps1`.
Expected: Microsoft login and enrollment endpoints reachable; DNS resolves; time is in sync.

## Test 2 — Devices enrolled and in the site group
Do: Intune → **Devices → All devices**; filter to the site, and check Entra → **Groups →**
`New Site – Site A – Pilot` → **Members**.
Expected: Every site device appears, is managed by Intune, and is a member of the site group.

## Test 3 — Baseline applied and compliant
Do: Intune → **Devices → Compliance → Device compliance**, scoped to the site; and **Endpoint
security → Security baselines →** your baseline **→ Device status**.
Expected: All site devices show **Compliant** and the security baseline shows **Succeeded**.

## Test 4 — Site apps installed
Do: On a site device run `NEWSITE-Validation.ps1`; or Intune → **Apps → Monitor → App install
status** scoped to the site app.
Expected: Each app in the site app set is **Installed** on every site device.

## Test 5 — Site printers present and printing
Do: On a site device, confirm the site printers appear under **Settings → Bluetooth & devices →
Printers & scanners**, then print a test page.
Expected: The site's printers are present and a test page prints successfully.

## Test 6 — Per-device go-live validation
Do: Run `NEWSITE-Validation.ps1` on each site device.
Expected: Each device reports PASS for enrollment, compliance, apps, and printers.

## Test 7 — Site rollout status report
Do: Run `NEWSITE-Report.ps1`.
Expected: The site shows expected counts for devices provisioned, baselined, app-ready, and
validated — with no devices stuck in an earlier stage.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–6 pass on every pilot-site device; a user can sign in, open apps, and print |
| Go-live | Test 7 shows full coverage and the Step 8 go-live checklist is fully ticked |
| Expand | Each subsequent site passes Tests 1–7 before it opens |


---


# 6. Troubleshooting Guide — New-Site Endpoint Rollout Playbook

Use `NEWSITE-Discovery.ps1` for site readiness, `NEWSITE-Validation.ps1` for per-device state,
`NEWSITE-Report.ps1` for site-wide status, and `NEWSITE-Remediation.ps1` (default `-WhatIf`) for
safe fixes. Work the stages in dependency order — a failure in an early stage cascades into later
ones, so fix the earliest failing stage first.

## A. Site network / identity not ready
| Symptom | Cause | Remediation |
|---|---|---|
| Devices cannot enroll at the site | Site firewall/proxy blocks Microsoft endpoints | Have the network team allow Microsoft 365 / Intune URL and IP ranges; re-run `NEWSITE-Discovery.ps1` |
| Sign-in fails or times out | DNS or time skew at the site | Confirm DNS resolves `login.microsoftonline.com` and the device clock is in sync; correct then retry |

## B. Provisioning / enrollment issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device not in Intune | Enrollment method not applied | Confirm the Autopilot profile or automatic enrollment is configured (Requirement 2.2); re-run OOBE or re-join to Entra ID |
| Device enrolled but not in the site group | Group membership not synced | Add the device (or fix the dynamic rule), then run `NEWSITE-Set-SiteGroupTargeting.ps1` to reconcile membership |

## C. Baseline not applying
| Symptom | Cause | Remediation |
|---|---|---|
| Device shows Not compliant | Compliance policy not assigned to the site group, or not yet synced | Confirm the policy is assigned to the site group (Implementation Step 4); sync, then re-check |
| Security baseline shows Error | Conflicting configuration profile | Identify the conflicting setting in Intune → Endpoint security → device status; resolve the conflict and re-sync |

## D. Apps not installing
| Symptom | Cause | Remediation |
|---|---|---|
| Site app missing on device | App not assigned as Required to the site group | Add a Required assignment to the site group (Step 5); run `NEWSITE-Remediation.ps1` to trigger a sync |
| App install fails | Dependency or detection rule issue | Check Intune → Apps → Monitor → App install status for the error code; correct the app's requirements/detection rule |

## E. Printers not appearing
| Symptom | Cause | Remediation |
|---|---|---|
| Site printer absent | Printer configuration not assigned to the site group | Assign your Universal Print / connector configuration to the site group (Step 6); sync |
| Printer present but cannot print | Network path or driver issue at the site | Confirm the print path (Universal Print connector or print server) is reachable from the site; print a test page |

## F. Diagnostics quick reference
```powershell
Test-NetConnection login.microsoftonline.com -Port 443          # cloud reachability
Get-MgDeviceManagementManagedDevice -Filter "..."               # device state via Graph
Get-Printer | Select Name, DriverName, PortName                 # printers present on the device
dsregcmd /status                                                # Entra join + MDM enrollment state
```

## G. When to escalate
If the site is reachable, devices are enrolled and in the site group, the baseline and apps are
assigned and synced, and devices still fail `NEWSITE-Validation.ps1` after running
`NEWSITE-Remediation.ps1` and a policy cycle, collect `dsregcmd /status` and the relevant Intune
install/compliance error codes and open a Microsoft support case.


---


# 7. Best Practices — New-Site Endpoint Rollout Playbook

- Pilot the first site, always. Run the very first location as the pilot and pass the full go-live
  gate before you scale — the single most important practice for a repeatable rollout.
- Respect the dependency order. Confirm network/identity before provisioning, baseline before apps,
  apps/printers before validation. Doing stages out of order is the usual cause of a chaotic go-live.
- One site, one device group. Scope every assignment to a per-site device group so one site's
  rollout can never disturb another site or the wider fleet.
- Name everything consistently. Use `<Purpose> – <Site> – <Stage>` (e.g.
  `New Site – Site A – Pilot`) for groups and assignments so the tenant stays readable as sites add
  up.
- Reuse the baseline, never re-author it. The site inherits your existing compliance policy and
  security baseline; building a new baseline per site defeats the repeatability.
- Validate per device, not just per policy. A policy showing "Succeeded" is not the same as a user
  being able to sign in, open the apps, and print — run `NEWSITE-Validation.ps1` on each device.
- Make go-live a gate, not a hope. Only open the site when the go-live checklist is fully ticked and
  `NEWSITE-Report.ps1` shows full coverage.
- Remediate before go-live, safely. Use `NEWSITE-Remediation.ps1` (default `-WhatIf`) to preview
  fixes for stuck devices, then re-validate — never improvise on go-live morning.
- Clone, do not rebuild. For the next site, clone the group and assignment pattern and change only
  the site name and Stage; the second site should be faster than the first.
- Document each site's set. Record the site's app set, printer set, and go-live date so the program
  is auditable and the next operator can repeat it.


---


# 8. Deliverables Summary — New-Site Endpoint Rollout Playbook

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The rollout model, the dependency order, naming convention, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps plus the go-live checklist |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for the assign-once, repeat-everywhere model |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NEWSITE-Discovery.ps1` | Checks a site's readiness — cloud endpoint reachability, DNS, and time sync (read-only) |
| `NEWSITE-Validation.ps1` | Per-device go-live validation — enrollment, compliance, site apps, site printers (read-only) |
| `NEWSITE-Report.ps1` | Site rollout status report — provisioned / baselined / app-ready counts via Microsoft Graph (read-only) |
| `NEWSITE-Remediation.ps1` | Safe remediation of failed deployments — sync, app/baseline re-evaluation (default `-WhatIf`) |
| `NEWSITE-Set-SiteGroupTargeting.ps1` | Builds the per-site device group and adds the site's devices via Microsoft Graph |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A concrete go-live checklist and a repeatable program following the model: Assess → Configure →
  Pilot → Validate → Expand, with the first site as the pilot.

## Outcome
Every new site opening with endpoints that work on day one — provisioned, baselined, app- and
printer-ready, and validated against a go-live checklist — proven on a pilot site before you repeat
it everywhere.
