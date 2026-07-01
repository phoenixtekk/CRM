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
Why: Every Phoenixtekk solution is piloted before expansion.
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
