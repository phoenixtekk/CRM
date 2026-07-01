# 2. Requirements Guide — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

Verify every requirement before configuring. Each entry: Description · Why required · How to verify ·
How to implement if missing. Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Object names used throughout this solution (reuse them verbatim in Intune):
- Settings-catalog policies (by severity):
  `STIG Win10/11 – CAT I – Pilot` and `STIG Win10/11 – CAT I – Production`
  `STIG Win10/11 – CAT II – Pilot` and `STIG Win10/11 – CAT II – Production`
  `STIG Win10/11 – CAT III – Pilot` and `STIG Win10/11 – CAT III – Production`
- Imported ADMX policy: `STIG Win10/11 – ADMX – Pilot` / `STIG Win10/11 – ADMX – Production`
- Compliance policy: `STIG Win10/11 – Compliance`
- Device groups: `STIG Win10/11 – Pilot Devices` and `STIG Win10/11 – Production Devices`
- Version tag (put in every policy description): `STIG-Win-vYYYY.MM` (the STIG release you are on)

## 2.1 Intune licensing
Description: An Intune-bearing license (Plan 1 is sufficient for settings catalog and ADMX).
Why required: Intune delivers the settings-catalog, imported-ADMX, and compliance policies.
How to verify: Microsoft 365 admin center → Billing → Licenses.
How to implement if missing: Assign M365 E3/E5, Business Premium (Intune included), or standalone Intune Plan 1. For DoD, use the appropriate government cloud offering (GCC High / DoD) where required.

## 2.2 Device enrollment
Description: The targeted Windows 10/11 devices are enrolled in Intune.
Why required: Configuration profiles and compliance policies apply only to enrolled devices.
How to verify: Intune → Devices → All devices; run `STIG-Discovery.ps1`.
How to implement if missing: Enable automatic enrollment (Entra ID join / Hybrid join) and enroll the devices.

## 2.3 Supported Windows 10/11 edition and build
Description: Windows 10 or Windows 11 Enterprise or Education on a currently supported build (Pro is acceptable for most rules; some STIG rules assume Enterprise/Education-class features).
Why required: Many STIG rules (Credential Guard, certain Defender/audit policies) require Enterprise/Education features and a current, supported build.
How to verify: `winver` on a device, or Intune → device → Hardware; run `STIG-Discovery.ps1`.
How to implement if missing: Upgrade to a supported Windows 10/11 edition/build (subscription activation or a feature update).

## 2.4 Official DISA STIG source (STIG Viewer / SCAP)
Description: The current DISA Windows 10 STIG and/or Windows 11 STIG (the STIG Viewer `.stig`/XCCDF content) and, ideally, the matching SCAP benchmark for automated scanning.
Why required: This is the authoritative list of rules, CAT severities, required values, and check/fix text. Exact Rule/Group/Vuln IDs and values are deferred to this source — do not work from memory.
How to verify: You can open the current Windows 10/11 STIG in the DISA STIG Viewer and identify its release (for example `vYYYY.MM` / the DISA quarterly release) and each rule's CAT severity.
How to implement if missing: Download the current Windows 10/11 STIG and its SCAP benchmark from the DISA public cyber exchange, and install the DISA STIG Viewer.

## 2.5 ADMX templates for non-catalog rules
Description: The ADMX/ADML files for any STIG rules not present in the Intune settings catalog (for example, template-only or third-party settings).
Why required: A minority of STIG rules can only be delivered via imported administrative templates.
How to verify: While building, note any STIG rule with no settings-catalog equivalent; those need imported ADMX.
How to implement if missing: Obtain the matching ADMX/ADML files and import them in Intune → Devices → Configuration → Import ADMX.

## 2.6 Pilot and production device groups
Description: Two Entra ID security groups: `STIG Win10/11 – Pilot Devices` (a small representative sample) and `STIG Win10/11 – Production Devices` (the rest of the fleet).
Why required: Hardening is piloted before fleet rollout because STIG rules can break mission apps.
How to verify: Entra → Groups; both groups exist.
How to implement if missing: Entra → Groups → New group → Security; add representative pilot devices to one and the remaining devices to the other.

## 2.7 Change control / approval process
Description: A documented approval step for applying and updating the baseline (aligned with your RMF/change process).
Why required: Hardening and STIG-release updates are production changes; they need review and a rollback plan. This is central to the maintenance lifecycle in document 4.
How to verify: You have a place to record approved changes and the STIG release in use (a change ticket, register, or the policy descriptions).
How to implement if missing: Adopt a change record (who approved, what changed, STIG release, rollback step). Record the version tag `STIG-Win-vYYYY.MM` in each policy description.

## 2.8 POA&M / exception register
Description: A register that tracks any STIG rule you cannot meet as a Plan of Action & Milestones (POA&M) item.
Why required: Open findings must be carried as documented, risk-accepted POA&Ms with a remediation milestone — not silent gaps. Assessors expect this.
How to verify: You have a POA&M/exception register with fields for finding (Rule/Vuln ID), CAT, risk, compensating control, owner, and milestone date.
How to implement if missing: Create the register (spreadsheet or GRC tool). Record each planned exception before it is needed; link it to the STIG rule ID from the STIG Viewer.

---
## Checklist
- [ ] Intune licensing assigned (government cloud where required)
- [ ] Windows 10/11 devices enrolled — `STIG-Discovery.ps1`
- [ ] Supported Windows 10/11 edition/build
- [ ] Current DISA Windows 10/11 STIG (and SCAP) obtained via STIG Viewer — note release `vYYYY.MM`
- [ ] ADMX/ADML files for any non-catalog rules
- [ ] `STIG Win10/11 – Pilot Devices` and `STIG Win10/11 – Production Devices` groups created
- [ ] Change-control / approval process and version tag convention agreed
- [ ] POA&M / exception register in place
