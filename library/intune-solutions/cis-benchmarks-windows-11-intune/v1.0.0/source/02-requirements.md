# 2. Requirements Guide — CIS Benchmarks for Windows 11 (Microsoft Intune)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Object names used throughout this solution (reuse them verbatim in Intune):
- Settings-catalog policy: `CIS Win11 – L1 – Pilot` (and later `CIS Win11 – L1 – Production`)
- Optional Level 2 policy: `CIS Win11 – L2 – Pilot` / `CIS Win11 – L2 – Production`
- Imported ADMX policy: `CIS Win11 – ADMX – Pilot` / `CIS Win11 – ADMX – Production`
- Compliance policy: `CIS Win11 – Compliance`
- Device groups: `CIS Win11 – Pilot Devices` and `CIS Win11 – Production Devices`
- Version tag (put in every policy description): `CIS-Win11-vX.Y.Z` (the benchmark version you are on)

## 2.1 Intune licensing
**Description:** An Intune-bearing license (Plan 1 is sufficient for settings catalog and ADMX).
**Why required:** Intune delivers the settings-catalog, imported-ADMX, and compliance policies.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**.
**How to implement if missing:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 Device enrollment
**Description:** The targeted Windows 11 devices are enrolled in Intune.
**Why required:** Configuration profiles and compliance policies apply only to enrolled devices.
**How to verify:** Intune → **Devices → All devices**; run `CIS11-Discovery.ps1`.
**How to implement if missing:** Enable automatic enrollment (Entra ID join / Hybrid join) and enroll the devices.

## 2.3 Supported Windows 11 edition
**Description:** Windows 11 Pro, Enterprise, or Education on a currently supported build.
**Why required:** Many CIS controls (Credential Guard, certain Defender/audit policies) require Enterprise/Education-class features and a current build.
**How to verify:** `winver` on a device, or Intune → device → **Hardware**; run `CIS11-Discovery.ps1`.
**How to implement if missing:** Upgrade to a supported Windows 11 edition/build (subscription activation or a feature update).

## 2.4 Official CIS Benchmark source (membership content)
**Description:** The current CIS Microsoft Windows 11 Benchmark PDF and, ideally, the CIS Intune "Build Kit" / GPO content from CIS WorkBench.
**Why required:** This is the authoritative list of controls, levels, and values. The exact control numbers and Build Kit settings are deferred to this source — do not work from memory.
**How to verify:** You can open the current Windows 11 Benchmark document and identify its version (e.g. `vX.Y.Z`) and the L1/L2 designations.
**How to implement if missing:** Obtain CIS membership (or the free benchmark PDF) and download the current Windows 11 Benchmark and its Build Kit from CIS WorkBench.

## 2.5 ADMX templates for non-catalog controls
**Description:** The ADMX/ADML files for any CIS controls not present in the Intune settings catalog (for example, third-party or template-only settings).
**Why required:** A minority of CIS controls can only be delivered via imported administrative templates.
**How to verify:** While building, note any CIS control with no settings-catalog equivalent; those need imported ADMX.
**How to implement if missing:** Obtain the matching ADMX/ADML files and import them in Intune → **Devices → Configuration → Import ADMX**.

## 2.6 Pilot and production device groups
**Description:** Two Entra ID security groups: `CIS Win11 – Pilot Devices` (a small representative sample) and `CIS Win11 – Production Devices` (the rest of the fleet).
**Why required:** Hardening is piloted before fleet rollout because L1/L2 controls can break apps.
**How to verify:** Entra → **Groups**; both groups exist.
**How to implement if missing:** Entra → **Groups → New group → Security**; add representative pilot devices to one and the remaining devices to the other.

## 2.7 Change control / approval process
**Description:** A lightweight, documented approval step for applying and updating the baseline.
**Why required:** Hardening and benchmark-version updates are production changes; they need review and a rollback plan. This is central to the maintenance lifecycle in document 4.
**How to verify:** You have a place to record approved changes and the benchmark version in use (a change ticket, register, or the policy descriptions).
**How to implement if missing:** Adopt a simple change record (who approved, what changed, benchmark version, rollback step). Record the version tag `CIS-Win11-vX.Y.Z` in each policy description.

## 2.8 (Optional) Application inventory for break-glass exceptions
**Description:** A short list of business-critical apps that may conflict with hardening (legacy line-of-business, scripting, removable-media workflows).
**Why required:** Lets you plan documented exceptions before they cause an outage.
**How to verify:** You can name the apps and which CIS controls might affect them.
**How to implement if missing:** Collect the list from app owners during the Assess phase; record planned exceptions in your change record.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Windows 11 devices enrolled — `CIS11-Discovery.ps1`
- [ ] Supported Windows 11 edition/build
- [ ] Current CIS Windows 11 Benchmark (and Build Kit) obtained — note version `vX.Y.Z`
- [ ] ADMX/ADML files for any non-catalog controls
- [ ] `CIS Win11 – Pilot Devices` and `CIS Win11 – Production Devices` groups created
- [ ] Change-control / approval process and version tag convention agreed
- [ ] (Optional) App inventory for planned break-glass exceptions
