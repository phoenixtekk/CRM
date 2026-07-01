# 2. Requirements Guide — CIS Benchmarks for macOS (Microsoft Intune)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Object names used throughout this solution (reuse them verbatim in Intune):
- Settings-catalog policy: `CIS macOS – L1 – Pilot` (and later `CIS macOS – L1 – Production`)
- Optional Level 2 policy: `CIS macOS – L2 – Pilot` / `CIS macOS – L2 – Production`
- Custom `.mobileconfig` profile: `CIS macOS – Custom – Pilot` / `CIS macOS – Custom – Production`
- macOS shell script: `CIS macOS – Shell – Pilot` / `CIS macOS – Shell – Production`
- Compliance policy: `CIS macOS – Compliance`
- Device groups: `CIS macOS – Pilot Devices` and `CIS macOS – Production Devices`
- Version tag (put in every policy/profile/script description): `CIS-macOS-vX.Y.Z` (the benchmark version you are on)

## 2.1 Intune licensing
**Description:** An Intune-bearing license (Plan 1 is sufficient for settings catalog, custom profiles, and shell scripts).
**Why required:** Intune delivers the settings-catalog policy, custom configuration profiles, macOS shell scripts, and compliance policy.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**.
**How to implement if missing:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 Apple MDM Push (APNs) certificate
**Description:** A valid Apple Push Notification service (APNs) certificate configured in Intune.
**Why required:** Apple devices (including Macs) cannot be managed by Intune without an APNs certificate — no profiles, scripts, or compliance policies reach the Mac until it exists.
**How to verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; confirm it is present and **not expired**.
**How to implement if missing:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate → download the CSR**, create the certificate at `https://identity.apple.com` with a long-lived Apple ID, upload it back, and record the renewal date.

## 2.3 macOS enrollment configured
**Description:** A working macOS enrollment method so target Macs are enrolled and manageable — Automated Device Enrollment (ADE/DEP), Account-driven (user-enrollment / device enrollment), or Company Portal.
**Why required:** Profiles, scripts, and compliance policies apply only to enrolled Macs.
**How to verify:** Intune → **Devices → macOS → macOS devices**; the Mac appears as managed. Run `CISMAC-Discovery.ps1` for tenant/device readiness signals.
**How to implement if missing:** Configure **Automated Device Enrollment** (Apple Business/School Manager token + an enrollment profile) for corporate Macs, or **Account-driven**/Company Portal enrollment for user-owned Macs; then enrol the devices.

## 2.4 Supported macOS version
**Description:** A currently supported macOS major version that matches a published CIS macOS Benchmark (for example the Sonoma or Sequoia benchmark).
**Why required:** Many CIS controls and Apple payloads depend on the macOS major version, and CIS publishes a benchmark per macOS release. Configuring against the wrong version mismatches the controls.
**How to verify:** On a Mac, **Apple menu → About This Mac**; or Intune → device → **Hardware**. Run `CISMAC-Discovery.ps1`.
**How to implement if missing:** Update the Macs to a supported macOS version (and align to the matching CIS benchmark document).

## 2.5 Official CIS Benchmark source (membership content)
**Description:** The current CIS Apple macOS Benchmark PDF for your macOS version, and any CIS-provided `.mobileconfig` / audit content from CIS WorkBench.
**Why required:** This is the authoritative list of controls, levels, and values. The exact control numbers, payload keys, and recommended values are deferred to this source — do not work from memory.
**How to verify:** You can open the current macOS Benchmark document, identify its version (for example `vX.Y.Z`) and the macOS release it targets, and read the L1/L2 designations.
**How to implement if missing:** Obtain CIS membership (or the free benchmark PDF) and download the current macOS Benchmark and any supporting content from CIS WorkBench.

## 2.6 Custom `.mobileconfig` payloads for non-catalog controls
**Description:** The `.mobileconfig` files for any CIS controls whose Apple payload is not present in the Intune settings catalog.
**Why required:** A minority of CIS controls can only be delivered via a custom configuration profile carrying the raw Apple payload.
**How to verify:** While building, note any CIS control with no settings-catalog equivalent; those need a custom `.mobileconfig`.
**How to implement if missing:** Author the payload (or obtain CIS-provided content) and upload it via Intune → **Devices → macOS → Configuration → Create → Templates → Custom**.

## 2.7 Pilot and production device groups
**Description:** Two Entra ID security groups: `CIS macOS – Pilot Devices` (a small representative sample of Macs) and `CIS macOS – Production Devices` (the rest of the Mac fleet).
**Why required:** Hardening is piloted before fleet rollout because L1/L2 controls can break apps and even login.
**How to verify:** Entra → **Groups**; both groups exist.
**How to implement if missing:** Entra → **Groups → New group → Security**; add representative pilot Macs to one and the remaining Macs to the other.

## 2.8 Change control / approval process
**Description:** A lightweight, documented approval step for applying and updating the baseline.
**Why required:** Hardening and benchmark-version updates are production changes; they need review and a rollback plan. This is central to the maintenance lifecycle in document 4.
**How to verify:** You have a place to record approved changes and the benchmark version in use (a change ticket, register, or the policy descriptions).
**How to implement if missing:** Adopt a simple change record (who approved, what changed, benchmark version, rollback step). Record the version tag `CIS-macOS-vX.Y.Z` in each policy/profile/script description.

## 2.9 (Optional) Application inventory for break-glass exceptions
**Description:** A short list of business-critical apps and workflows that may conflict with hardening (legacy apps, kernel/system extensions, removable-media workflows, AppleScript automation).
**Why required:** Lets you plan documented exceptions before they cause an outage or a login failure.
**How to verify:** You can name the apps/workflows and which CIS controls might affect them.
**How to implement if missing:** Collect the list from app owners during the Assess phase; record planned exceptions in your change record.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Apple MDM Push (APNs) certificate present and not expired
- [ ] macOS enrollment configured (ADE / Account-driven / Company Portal); Macs enrolled — `CISMAC-Discovery.ps1`
- [ ] Supported macOS version matching a published CIS benchmark
- [ ] Current CIS macOS Benchmark (and supporting content) obtained — note version `vX.Y.Z`
- [ ] Custom `.mobileconfig` payloads for any non-catalog controls
- [ ] `CIS macOS – Pilot Devices` and `CIS macOS – Production Devices` groups created
- [ ] Change-control / approval process and version tag convention agreed
- [ ] (Optional) App inventory for planned break-glass exceptions
