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
