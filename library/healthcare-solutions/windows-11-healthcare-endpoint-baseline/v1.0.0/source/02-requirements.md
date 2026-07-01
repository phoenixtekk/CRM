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
