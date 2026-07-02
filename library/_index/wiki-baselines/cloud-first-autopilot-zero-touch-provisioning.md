# Cloud-First Autopilot Zero-Touch Provisioning (Entra Join, Optional Later Domain Join)

> **Version 1.0.0** · Category: Intune · Solution code: CFAP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Cloud-First Autopilot Zero-Touch Provisioning (Microsoft Intune)

White-label · Intune Solutions

Provisioning a new Windows PC the old way is slow and hands-on: a technician images the machine,
domain-joins it, installs apps, applies policy, and babysits every build. The modern path is
cloud-first — Microsoft Entra join plus Windows Autopilot — so a device provisions itself the moment
it is powered on and connected to the internet. Apps and policy arrive during enrollment, the
Enrollment Status Page holds the desktop until the device is ready, and the technician does almost
nothing. Domain join is added afterward only when a specific app or resource genuinely requires it —
never by default.

This is a complete, deploy-it-today package for standing up cloud-first, near zero-touch provisioning
with Microsoft Intune, written for an administrator with no prior Autopilot experience.

## What you get
- A plain-language Solution Overview of the cloud-first model: Entra join, Autopilot, the Enrollment
  Status Page, provisioning-time apps and policy, and why this beats hybrid-by-default.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click Intune steps in the required order — register
  devices, build the Autopilot profile, configure the ESP and provisioning-time apps, then pilot,
  validate, and expand.
- A clear decision path for adding domain join later, only when a named app or resource requires it.
- Five PowerShell scripts for readiness discovery, per-device provisioning validation, a
  provisioning-success and technician-touch report, safe remediation of failed provisioning, and an
  Autopilot target-group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A near zero-touch provisioning model: a dynamic Autopilot device group, a user-driven, Entra-joined
deployment profile, an Enrollment Status Page that blocks until apps and policy land, and the core
app/baseline set delivered at enrollment — so technicians only unbox and power on. The rare device
that truly needs on-premises resources gets domain join added afterward on a documented, evidence-led
decision path.

## The standard deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Windows devices that provision themselves on power-on — Entra-joined via Autopilot, apps and policy
applied at enrollment, domain join only where truly required — cutting technician effort to almost
nothing and proven on a pilot before you scale.


---


# 1. Solution Overview — Cloud-First Autopilot Zero-Touch Provisioning

## What cloud-first provisioning is
Cloud-first provisioning means a Windows device is set up entirely from the cloud, with no on-premises
imaging and no Active Directory domain join. The device is Microsoft Entra joined (not Active
Directory domain joined, not Hybrid) and provisioned by Windows Autopilot through Microsoft Intune.
The moment a new or reset device is powered on and connected to the internet, it identifies itself to
Autopilot, applies your deployment profile, enrolls in Intune, and pulls down apps and policy — while
the Enrollment Status Page (ESP) holds the desktop until the device is ready. The result is a near
zero-touch experience: the technician unboxes the device, powers it on, and walks away.

## Why cloud-first beats hybrid-by-default
Hybrid Azure AD join (domain join plus Entra registration) made sense when apps and resources lived
on a domain controller. Today most identity, app, and policy needs are met by Entra and Intune, and
hybrid adds real cost: line-of-sight to a domain controller during provisioning, an on-prem Intune
Connector, VPN-at-OOBE complexity, and slower, more failure-prone builds. The modern guidance is to
go Entra-join-first and add domain join only for the specific device that genuinely needs an on-prem
resource. This solution is built around that principle: cloud-first by default, domain join later only
if a named app or resource requires it.

## How it works
1. Each device is registered to your tenant as an Autopilot device by its hardware hash (uploaded by
   you, or registered by the OEM/reseller at purchase).
2. A dynamic Autopilot device group automatically gathers all registered devices by their Autopilot
   ZTDID, so you never hand-add members.
3. A Windows Autopilot deployment profile (user-driven, Microsoft Entra joined) defines the
   out-of-box experience: branding, account type, and the cloud-only join.
4. An Enrollment Status Page blocks the desktop during provisioning until your required apps and
   policy install, so users never reach a half-configured machine.
5. Provisioning-time apps and a security baseline are assigned to the Autopilot group so they install
   during enrollment, not days later.
6. The user signs in once with their work account; the device Entra-joins, Intune-enrolls, and lands
   fully configured. Technician touch is effectively limited to powering it on.

## The near zero-touch experience
- Technician effort: unbox, connect power/network, power on. No imaging, no manual join, no per-app
  installs.
- User effort: connect to a network and sign in once with their work account.
- Everything else — join, enrollment, apps, policy, baseline — happens automatically behind the ESP.

## When (and how) domain join is added later
Domain join is the exception, not the default. Add it only when a specific, named requirement cannot
be met cloud-first — for example a legacy line-of-business app that authenticates only via Kerberos to
on-prem Active Directory, or a file share / print resource that cannot be reached with Microsoft Entra
Kerberos or Cloud Kerberos Trust. The decision criteria and the supported path (Microsoft Entra hybrid
join, or Microsoft Entra Kerberos for resource access without changing the join type) are detailed in
the Implementation Guide. Default everything to Entra join; carve out the rare exception deliberately
and document why.

## What you can control
- The join type and out-of-box experience via the Autopilot deployment profile.
- Which apps and policy block provisioning via the Enrollment Status Page.
- The provisioning-time app and baseline set assigned to the Autopilot group.
- Device registration (manual hash upload or OEM/reseller registration).
- A documented exception path to domain join for the rare on-prem dependency.

## Benefits
- Near zero technician touch — power on and walk away; no imaging or manual join.
- Faster, more consistent builds — every device provisions the same assigned set.
- Cloud-first identity — Entra join with no domain-controller line-of-sight at OOBE.
- Lower complexity and risk — no on-prem Intune Connector or VPN-at-OOBE unless an exception requires it.
- Provable readiness — the ESP guarantees apps and policy are present before the user reaches the desktop.
- A measurable touch report — see provisioning success rate and where any manual touch crept in.

## Limitations (be honest with buyers)
- Autopilot needs each device registered (hardware hash); at scale, OEM/reseller registration is
  strongly preferred over manual upload.
- The device must reach the internet at the out-of-box experience to provision.
- Pure cloud (Entra-join) does not natively authenticate to on-prem AD resources; those rare cases use
  Microsoft Entra Kerberos / Cloud Kerberos Trust, or the deliberate domain-join exception.
- Provisioning-time apps that are very large extend the ESP wait; keep the blocking set lean.
- White-glove / pre-provisioning is an advanced add-on and is not the focus of this solution.

## The standard deployment model
> Register devices → build the Autopilot profile (Entra join) → configure the ESP and provisioning-time
> apps → validate the zero-touch flow on a pilot → expand. repeatable pattern:
> Assess → Configure → Pilot → Validate → Expand.


---


# 2. Requirements Guide — Cloud-First Autopilot Zero-Touch Provisioning

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

The named artifacts used throughout this solution (reuse these names verbatim):
- Autopilot group: `Autopilot Devices – All Cloud-First – Provisioning`
- Deployment profile: `Autopilot Profile – Entra Join – Provisioning`
- Enrollment Status Page: `ESP – Cloud-First – Provisioning`
- Provisioning app set: `App Assignments – Core Apps – Provisioning`
- Baseline: `Security Baseline – Cloud-First – Provisioning`

## 2.1 Licensing
Description: Intune (Plan 1) plus Microsoft Entra ID. Windows Autopilot itself is included.
Why: Intune delivers the Autopilot profile, the ESP, and provisioning-time apps/policy; Entra provides
the cloud join.
Verify: M365 admin center → Billing → Licenses.
Implement: Assign M365 E3/E5 or Business Premium (Intune + Entra ID P1 included).

## 2.2 Automatic enrollment configured
Description: MDM automatic enrollment is on so Entra-joined devices auto-enroll in Intune.
Why: Autopilot relies on auto-enrollment to bring the device into Intune during OOBE.
Verify: Intune → Devices → Enrollment → Automatic Enrollment; MDM user scope is All (or the pilot group).
Implement: Set MDM user scope to All (or the pilot group) and Save.

## 2.3 Supported Windows OS and edition
Description: Windows 10 (21H2+) or Windows 11, Pro/Enterprise/Education, in out-of-box state.
Why: Autopilot, Entra join, and the ESP require a supported build and a non-consumer edition.
Verify: `winver`; run `CFAP-Discovery.ps1`.
Implement: Reset to OOBE, or upgrade to a supported build/edition before registration.

## 2.4 Internet access at the out-of-box experience
Description: The device can reach Microsoft cloud endpoints at OOBE (Autopilot, Entra, Intune,
Windows Update, app content).
Why: Cloud-first provisioning happens entirely over the internet at first boot; no domain-controller
line-of-sight is needed.
Verify: From a test device at OOBE, confirm internet connectivity; from a managed device reach
`https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
Implement: Allow Microsoft's published Autopilot/Intune/Entra URL and IP ranges through proxy/firewall;
ensure DHCP/Wi-Fi is available at OOBE.

## 2.5 Device registration path (hardware hash)
Description: A way to register each device to the tenant as an Autopilot device — OEM/reseller
registration at purchase, or manual hardware-hash upload.
Why: Autopilot only provisions devices registered to your tenant.
Verify: Intune → Devices → Enrollment → Windows → Windows Autopilot → Devices; the device is listed.
Run `CFAP-Discovery.ps1` to flag unregistered pilot devices.
Implement: For pilots, collect the hash and upload it (see Implementation Step 2); at scale, require
OEM/reseller Autopilot registration on the purchase order.

## 2.6 Provisioning-time app and baseline set
Description: The core apps and a security baseline to be applied during enrollment, assigned to the
Autopilot group.
Why: A zero-touch device must arrive fully usable; apps/policy must install at provisioning, not later.
Verify: Intune → Apps → Windows; confirm the core apps exist and are assigned to
`Autopilot Devices – All Cloud-First – Provisioning`.
Implement: Add the core apps (Required) and assign the baseline as in Implementation Steps 6–7.

## 2.7 Pilot device(s)
Description: One or more representative devices to validate the zero-touch flow before fleet rollout.
Why: Every solution is piloted before expansion.
Verify: A reset/new device is available and registered to the Autopilot group.
Implement: Reset a spare device to OOBE and register its hash for the pilot.

## 2.8 (Conditional) On-prem dependency assessment for later domain join
Description: A documented list of any app/resource that genuinely requires on-prem Active Directory.
Why: Determines whether the rare domain-join exception is needed; cloud-first is the default.
Verify: Review line-of-business apps for Kerberos-to-AD-only auth or on-prem-only file/print needs.
Implement: If a true dependency exists, plan the exception path (Microsoft Entra Kerberos / Cloud
Kerberos Trust for resource access, or Microsoft Entra hybrid join) per Implementation Step 9.

---
## Checklist
- [ ] Intune + Entra ID licensing assigned
- [ ] Automatic enrollment (MDM user scope) configured
- [ ] Windows 10 21H2+/11 supported edition in OOBE — `CFAP-Discovery.ps1`
- [ ] Internet reachable at OOBE
- [ ] Device registration path in place (OEM/reseller or manual hash)
- [ ] Provisioning-time apps + baseline ready to assign
- [ ] Pilot device(s) registered to `Autopilot Devices – All Cloud-First – Provisioning`
- [ ] (Conditional) On-prem dependency assessed for any later domain-join exception


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
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
**Why:** Every solution is piloted before fleet rollout.
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
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Cloud-First Autopilot Zero-Touch Provisioning

Follow these steps in order. All navigation is in the Microsoft Intune admin center
(`https://intune.microsoft.com`) unless stated otherwise.

> Model: user-driven, Microsoft Entra joined Autopilot, assigned to a dynamic Autopilot device group,
> with an Enrollment Status Page and provisioning-time apps/policy. Default to cloud-first; add domain
> join later only for a named on-prem dependency (Step 9).

Named artifacts (reuse verbatim — these match the Requirements Guide):
- Autopilot group: `Autopilot Devices – All Cloud-First – Provisioning`
- Deployment profile: `Autopilot Profile – Entra Join – Provisioning`
- Enrollment Status Page: `ESP – Cloud-First – Provisioning`
- Provisioning app set: `App Assignments – Core Apps – Provisioning`
- Baseline: `Security Baseline – Cloud-First – Provisioning`

## Step 1 — Enable automatic MDM enrollment
1. Go to Devices → Enrollment → Automatic Enrollment.
2. Set MDM user scope to All (or your pilot group). Click Save.

## Step 2 — Register the pilot device(s)
1. On each pilot device (in OOBE or already running), run `CFAP-Discovery.ps1` to confirm readiness and
   to export the hardware hash CSV, or use the built-in
   `Get-WindowsAutopilotInfo` from the `WindowsAutopilotIntune` / `Get-WindowsAutopilotInfo` script.
2. Go to Devices → Enrollment → Windows → Windows Autopilot → Devices → Import, then upload the CSV.
3. Click Sync and wait for the device to appear under Windows Autopilot → Devices.
   (At scale, have the OEM/reseller register devices at purchase so this step is unnecessary.)

## Step 3 — Create the dynamic Autopilot device group
1. Open `https://entra.microsoft.com` → Groups → New group.
2. Group type: Security. Name: `Autopilot Devices – All Cloud-First – Provisioning`.
3. Membership type: Dynamic Device.
4. Add the dynamic membership rule: `(device.devicePhysicalIDs -any (_ -contains "[ZTDId]"))`. Save.
5. Click Create. Registered Autopilot devices join this group automatically.

## Step 4 — Configure company branding (optional but recommended)
1. Open `https://entra.microsoft.com` → Company branding → Customize (or Add).
2. Add your logo, background, and sign-in text so the OOBE shows your brand. Save.

## Step 5 — Create the Autopilot deployment profile (Entra join)
1. Go to Devices → Enrollment → Windows → Windows Autopilot → Deployment profiles → Create profile →
   Windows PC.
2. Name: `Autopilot Profile – Entra Join – Provisioning`. Click Next.
3. On Out-of-box experience (OOBE):
   - Deployment mode: User-driven.
   - Join to Microsoft Entra ID as: Microsoft Entra joined. (This is the cloud-first choice — not
     Microsoft Entra hybrid joined.)
   - Microsoft Software License Terms: Hide.
   - Privacy settings: Hide.
   - Hide change account options: Yes.
   - User account type: Standard.
   - Allow pre-provisioned deployment: No (keep the pilot simple).
   - Apply device name template: optionally set a naming template (for example `CF-%SERIAL%`).
4. Click Next → Assignments → Add groups → `Autopilot Devices – All Cloud-First – Provisioning`.
5. Click Next → Create.

## Step 6 — Assign the provisioning-time apps
1. Go to Apps → Windows → Add and add each core app the device must arrive with (for example the
   Microsoft 365 Apps, the company VPN/agent, and any line-of-business app). Name this set, in your
   notes, `App Assignments – Core Apps – Provisioning`.
2. For each app: Assignments → Required → Add group →
   `Autopilot Devices – All Cloud-First – Provisioning`. Save.
3. Keep the blocking set lean — large apps extend the Enrollment Status Page wait.

## Step 7 — Assign a security baseline
1. Go to Endpoint security → Security baselines → choose the Windows baseline → Create profile.
2. Name: `Security Baseline – Cloud-First – Provisioning`. Accept or tune the defaults. Next.
3. Assignments → Add groups → `Autopilot Devices – All Cloud-First – Provisioning`. Create.

## Step 8 — Create the Enrollment Status Page (ESP)
1. Go to Devices → Enrollment → Windows → Enrollment Status Page → Create.
2. Name: `ESP – Cloud-First – Provisioning`. Next.
3. Settings:
   - Show app and profile configuration progress: Yes.
   - Block device use until all apps and profiles are installed: Yes.
   - Allow users to reset device if installation error occurs: Yes.
   - Show error when installation takes longer than (minutes): set a sensible limit (for example 60).
   - Block device use until these required apps are installed: select only the must-have apps from
     `App Assignments – Core Apps – Provisioning`.
4. Assignments → Add groups → `Autopilot Devices – All Cloud-First – Provisioning`. Create.

## Step 9 — Provision a pilot device (the zero-touch flow)
1. Power on a reset/new registered pilot device and connect it to the internet at OOBE.
2. Your company branding appears; the user signs in once with their work account.
3. The device Microsoft Entra joins, auto-enrolls in Intune, and the ESP runs — installing the
   provisioning apps and baseline — until the device is ready.
4. The user reaches a fully configured desktop. Technician touch: power-on only.

## Step 10 — Validate the pilot
1. Run `CFAP-Validation.ps1` → confirms the device is Autopilot-registered, Microsoft Entra joined,
   Intune-enrolled, and that the assigned apps/baseline are present.
2. Run `CFAP-Report.ps1` → confirms provisioning success and the technician-touch summary across pilot
   devices.
3. Complete the Testing Guide (Section 5) before expanding.

## Step 11 — Decision path: add domain join LATER, only if required
Default to cloud-first. Add domain join only for a device that has a named, verified on-prem dependency.
Use these criteria in order:
1. Does any required app authenticate only via Kerberos/NTLM to on-prem Active Directory (no modern
   auth, no Entra app)? Does the device need an on-prem-only file share or print server?
   - If No → stay Entra joined. Done.
   - If Yes → continue.
2. Can the on-prem resource be reached without changing the join type? Prefer Microsoft Entra Kerberos
   / Cloud Kerberos Trust (for SMB/Kerberos resource access from an Entra-joined device). If that meets
   the need → stay Entra joined and enable Cloud Kerberos Trust. Done.
3. Only if neither cloud option works, adopt the exception: Microsoft Entra hybrid join for that device
   class. This requires line-of-sight to a domain controller and the on-prem Intune Connector for
   Active Directory. Create a separate hybrid Autopilot deployment profile (Join type: Microsoft Entra
   hybrid joined) and a separate device group; do not change the default cloud-first profile. Document
   the named dependency that justified the exception.

## Step 12 — Expand to production
1. Register production devices (OEM/reseller registration at purchase is ideal at scale).
2. They join `Autopilot Devices – All Cloud-First – Provisioning` automatically (dynamic group) and
   inherit the profile, ESP, apps, and baseline.
3. Re-validate each wave with `CFAP-Validation.ps1` and `CFAP-Report.ps1`; track the technician-touch
   rate trending toward zero.

---
### Order of operations
`Auto-enrollment → Register devices → Dynamic group → Branding → Deployment profile (Entra join) → Provisioning apps → Baseline → ESP → Provision → Validate → (Domain-join exception only if required) → Expand`


---


# 5. Testing Guide — Cloud-First Autopilot Zero-Touch Provisioning

Run after the pilot device provisions (Implementation Step 10) and after each expansion wave.

## Test 1 — Device is Autopilot-registered
Do: Intune → Devices → Enrollment → Windows → Windows Autopilot → Devices; confirm the pilot device is
listed with the profile assigned. Or run `CFAP-Validation.ps1`.
Expected: The device appears and the deployment profile status is Assigned.

## Test 2 — Profile applied and join type correct
Do: Run `CFAP-Validation.ps1`, or on the device run `dsregcmd /status`.
Expected: `AzureAdJoined: YES` and `DomainJoined: NO` (cloud-first); the assigned profile is
`Autopilot Profile – Entra Join – Provisioning`.

## Test 3 — ESP blocked and completed
Do: Watch the provisioning run, or check Intune → Devices → Monitor → Enrollment Status Page.
Expected: The Enrollment Status Page blocked the desktop, installed the required apps/baseline, and
finished with success.

## Test 4 — Provisioning-time apps present
Do: Run `CFAP-Validation.ps1` (checks managed-app install state), or open Company Portal on the device.
Expected: Every app in `App Assignments – Core Apps – Provisioning` shows Installed.

## Test 5 — Security baseline applied
Do: Intune → Endpoint security → Security baselines → `Security Baseline – Cloud-First – Provisioning`
→ check the device status.
Expected: The pilot device shows Succeeded for the baseline.

## Test 6 — Near zero-touch confirmed
Do: Record the technician actions performed during the build (target: power-on only).
Expected: No imaging, no manual domain join, no per-app installs — technician touch is power-on only.

## Test 7 — Provisioning + touch report
Do: Run `CFAP-Report.ps1`.
Expected: A clear per-device provisioning-success result and a technician-touch summary across the
pilot group.

## Test 8 — (Conditional) Domain-join exception, if used
Do: Only if Step 11 created a hybrid exception: on that device run `dsregcmd /status`.
Expected: For the exception device only, `DomainJoined: YES` and `AzureAdJoined: YES`; all default
devices remain cloud-first.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–7 pass; the pilot device provisions cloud-first with apps/baseline present and technician touch is power-on only |
| Expand pass | Tests 1–5 and 7 pass for each wave before broadening rollout |


---


# 6. Troubleshooting Guide — Cloud-First Autopilot Zero-Touch Provisioning

Use `CFAP-Discovery.ps1` / `CFAP-Validation.ps1` for device state, `CFAP-Report.ps1` for fleet status,
and `CFAP-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Device does not start Autopilot at OOBE
| Symptom | Cause | Remediation |
|---|---|---|
| OOBE shows a normal consumer setup, no branding | Device not registered, or profile not yet assigned | Confirm under Devices → Enrollment → Windows → Windows Autopilot → Devices; Sync; wait for profile status Assigned; re-OOBE |
| Device never reaches the cloud | No internet at OOBE | Provide Wi-Fi/DHCP and allow the Autopilot/Intune/Entra endpoints; retry |
| Registered but no profile applies | Not in the dynamic group, or rule wrong | Run `CFAP-Set-AutopilotTargeting.ps1`; verify the `[ZTDId]` membership rule and group assignment |

## B. Enrollment Status Page errors or hangs
| Symptom | Cause | Remediation |
|---|---|---|
| ESP stuck on app install | A required app is large or failing | Trim the ESP blocking set; check the app's install status; run `CFAP-Remediation.ps1` to re-trigger install |
| ESP times out | Timeout too short or app dependency missing | Raise the ESP timeout; confirm app dependencies/supersedence; re-provision |
| ESP shows error, device unusable | Required app/profile failed | Allow reset on error in the ESP; fix the failing app; reset and re-provision |

## C. Wrong join type
| Symptom | Cause | Remediation |
|---|---|---|
| Device is hybrid/domain joined unexpectedly | A hybrid profile or GPO matched the device | Confirm the device is in the cloud-first group only; ensure no hybrid profile/Connector targets it; reset and re-provision with `Autopilot Profile – Entra Join – Provisioning` |
| `dsregcmd /status` shows `DomainJoined: YES` for a default device | Exception profile mis-scoped | Re-scope the hybrid exception to its own group; keep the default profile Entra-join only |

## D. Apps or baseline missing after provisioning
- Confirm the apps and `Security Baseline – Cloud-First – Provisioning` are assigned to
  `Autopilot Devices – All Cloud-First – Provisioning` (device-targeted, Required).
- Sync the device (Settings → Accounts → Access work or school → Info → Sync) or run
  `CFAP-Remediation.ps1` to force a sync and re-evaluation.

## E. On-prem resource unreachable from an Entra-joined device
- This is expected for pure cloud join. Prefer Microsoft Entra Kerberos / Cloud Kerberos Trust for
  SMB/Kerberos resource access before considering domain join.
- Only if a named dependency cannot be met that way, follow the documented exception path
  (Implementation Step 11) using a separate hybrid profile and group.

## F. Diagnostics quick reference
```powershell
dsregcmd /status                 # join state: AzureAdJoined / DomainJoined / MDM enrollment
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsEditionId
# Autopilot diagnostics during/after OOBE:
mdmdiagnosticstool.exe -area Autopilot -cab C:\Temp\AutopilotDiag.cab
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\Autopilot' -EA SilentlyContinue
```
During OOBE you can press Shift+F10 for a command prompt to run `dsregcmd /status`.

## G. When to escalate
If the device is registered, in the dynamic group, the profile shows Assigned, internet is available at
OOBE, and provisioning still fails after a re-sync and re-provision, collect the Autopilot diagnostics
cab (`mdmdiagnosticstool.exe -area Autopilot`) and open a Microsoft support case.


---


# 7. Best Practices — Cloud-First Autopilot Zero-Touch Provisioning

- Default to Entra join. Make Microsoft Entra joined the standard for every device; treat domain join
  as a deliberate, documented exception, never the default.
- Register at the source. Push Autopilot registration onto the OEM/reseller at purchase so devices
  arrive pre-registered — manual hash upload does not scale.
- Use a dynamic Autopilot group. Let `Autopilot Devices – All Cloud-First – Provisioning` gather
  devices by ZTDID automatically so nothing is hand-added.
- Keep the ESP blocking set lean. Block only the must-have apps; large or non-essential apps belong as
  Available, not Required, so they don't stall provisioning.
- Assign apps and baseline to the Autopilot group, not to users. Device-targeted assignment guarantees
  the build is identical regardless of who signs in first.
- Name everything consistently. Reuse the artifact names (profile, ESP, group, app set, baseline) with
  the `<Purpose> – <Scope> – <Stage>` pattern so audits and handoffs are unambiguous.
- Pilot before you scale. Validate the full zero-touch flow on representative hardware and confirm the
  pass/fail gate before expanding.
- Measure technician touch. Track the touch rate with `CFAP-Report.ps1`; a number trending to zero is
  the whole point — chase any device that needed manual intervention.
- Prefer cloud paths for on-prem needs. Before adding domain join, try Microsoft Entra Kerberos / Cloud
  Kerberos Trust for SMB/Kerberos resource access from Entra-joined devices.
- Isolate any hybrid exception. If you must add domain join, use a separate profile and group; never
  modify the default cloud-first profile, and record the named dependency that justified it.
- Ensure OOBE internet. Confirm Wi-Fi/DHCP and the required Microsoft endpoints are reachable at first
  boot — cloud-first provisioning depends on it.
- Document the build. Record the artifact names, the app/baseline set, and any exception decisions for
  repeatability and audits.


---


# 8. Deliverables Summary — Cloud-First Autopilot Zero-Touch Provisioning

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The cloud-first model (Entra join + Autopilot), the ESP, provisioning-time apps, the zero-touch experience, and the later-domain-join decision criteria |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps: register, profile, ESP, apps/baseline, validate, expand, plus the domain-join exception path |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CFAP-Discovery.ps1` | Reports Autopilot/enrollment readiness — OS build/edition, OOBE/registration state, hardware-hash export, and tenant registration status (read-only) |
| `CFAP-Validation.ps1` | Per-device provisioning/enrollment validation — Autopilot registration, Entra join, Intune enrollment, assigned apps/baseline present (read-only) |
| `CFAP-Report.ps1` | Provisioning-success and technician-touch report across the Autopilot group (Microsoft Graph, read-only) |
| `CFAP-Remediation.ps1` | Safe remediation of failed provisioning; default `-WhatIf` (re-sync, re-trigger enrollment/app install) |
| `CFAP-Set-AutopilotTargeting.ps1` | Builds/maintains the dynamic Autopilot target group and confirms profile/ESP assignment (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the repeatable model: Assess → Configure → Pilot → Validate → Expand.

## Outcome
Windows devices that provision themselves on power-on — Entra-joined via Autopilot with apps and policy
applied at enrollment, domain join only where truly required — cutting technician effort to almost
nothing, proven on a pilot before you scale.
