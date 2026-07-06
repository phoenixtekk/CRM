# 2. Requirements Guide — macOS Endpoint Management Baseline (Microsoft Intune)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Object names used throughout this solution (reuse them **verbatim** in Intune):
- Baseline settings-catalog policy: `macOS Baseline – Config – Pilot` (later `macOS Baseline – Config – Production`)
- Restrictions settings-catalog policy: `macOS Baseline – Restrictions – Pilot` / `macOS Baseline – Restrictions – Production`
- Software-update settings-catalog policy: `macOS Baseline – Software Update – Pilot` / `macOS Baseline – Software Update – Production`
- Custom `.mobileconfig` profile (only if needed): `macOS Baseline – Custom – Pilot` / `macOS Baseline – Custom – Production`
- Compliance policy: `macOS Baseline – Compliance`
- Device groups: `macOS Baseline – Pilot Devices` and `macOS Baseline – Production Devices`
- Version/scope tag (put in every policy/profile description): `macOS-Baseline-v1.0`

## 2.1 Intune licensing
**Description:** An Intune-bearing license (Plan 1 is sufficient for configuration profiles, custom profiles, compliance, and software-update policy).
**Why required:** Intune delivers every configuration profile, the compliance policy, and the software-update policy in this baseline.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**; confirm an Intune-bearing plan is present and assigned.
**How to implement if missing:** Assign Microsoft 365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 Microsoft Entra ID with users/devices in scope
**Description:** An Entra ID tenant whose Mac users and devices are the target of this baseline.
**Why required:** Intune assigns policy to Entra groups, and enrolled Macs are represented as Entra devices.
**How to verify:** Sign in to `https://entra.microsoft.com`; confirm the Mac users/devices exist.
**How to implement if missing:** Ensure the Mac users are licensed Entra users and the Macs enroll into the same tenant (see 2.4).

## 2.3 Apple MDM Push (APNs) certificate
**Description:** A valid Apple Push Notification service (APNs) certificate configured in Intune.
**Why required:** No Apple device — including a Mac — can be managed by Intune without an APNs certificate. Until it exists and is unexpired, **no** profile, compliance policy, or update policy reaches any Mac.
**How to verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; confirm it is present and **not expired**. Run `MACBASE-Discovery.ps1` for a readiness signal.
**How to implement if missing:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate → download the CSR**, create the certificate at `https://identity.apple.com` with a long-lived, business-owned Apple ID, upload it back, and **record the renewal date** (the certificate expires annually; letting it lapse stops all Mac management).

## 2.4 macOS enrollment configured
**Description:** A working macOS enrollment method so target Macs are enrolled and manageable — Automated Device Enrollment (ADE/DEP), account-driven device enrollment, or Company Portal.
**Why required:** The baseline profiles, compliance policy, and update policy apply only to enrolled Macs. This solution assumes enrollment is already in place (enrollment/ADE is a separate solution).
**How to verify:** Intune → **Devices → macOS → macOS devices**; the target Macs appear as **managed**. Run `MACBASE-Discovery.ps1` for a fleet count and version spread.
**How to implement if missing:** Configure **Automated Device Enrollment** (Apple Business/School Manager token + an enrollment profile) for corporate Macs, or account-driven / Company Portal enrollment for user-owned Macs, then enroll the devices. (Enrollment setup is out of scope for this baseline and covered by a separate solution.)

## 2.5 Supported macOS version
**Description:** A currently supported macOS major version on the target Macs.
**Why required:** Some baseline payloads — especially software-update enforcement and Declarative Device Management update behaviour — depend on the macOS major version. Configuring against an unsupported version mismatches the available settings.
**How to verify:** On a Mac, **Apple menu → About This Mac**; or Intune → device → **Hardware**. Run `MACBASE-Discovery.ps1` for the fleet version spread.
**How to implement if missing:** Update the Macs to a currently supported macOS version; then build the software-update policy (Implementation Step 7) to keep them current.

## 2.6 Entra pilot and production device groups
**Description:** Two Entra ID security groups: `macOS Baseline – Pilot Devices` (a small, representative sample of Macs) and `macOS Baseline – Production Devices` (the remaining Mac fleet).
**Why required:** The baseline is piloted before fleet rollout so a surprising setting is caught on a few Macs, not all of them.
**How to verify:** Entra → **Groups**; both groups exist.
**How to implement if missing:** Entra → **Groups → New group → Security**; add a few representative Macs to the pilot group and the rest to the production group. (Dynamic device groups filtered on `deviceOSType -eq "MacMDM"` are a convenient way to keep the production group current — verify the filter matches your tenant's device attributes.)

## 2.7 Baseline decisions agreed (Assess inputs)
**Description:** The specific baseline values you intend to enforce: which restrictions to apply (for example AirDrop, content caching, screen-saver password), the update behaviour (auto-download/install, minimum OS version, deadline), and the compliance thresholds (minimum OS version, FileVault required, firewall required).
**Why required:** The baseline is a set of *decisions*, not defaults. Agreeing them up front (with the app/security owners) prevents a policy that blocks a legitimate workflow.
**How to verify:** You can state, for each area, the value you will set and why.
**How to implement if missing:** Hold a short Assess review with the security and app owners; record the agreed values (they become the settings you enter in Implementation Steps 5–8).

## 2.8 (Optional) Custom `.mobileconfig` payloads for non-catalog settings
**Description:** The `.mobileconfig` file for any baseline setting whose Apple payload is not present in the Intune settings catalog.
**Why required:** A minority of Apple payloads can only be delivered via a custom configuration profile carrying the raw payload.
**How to verify:** While building the settings-catalog policies, note any agreed setting with no catalog equivalent; those need a custom `.mobileconfig`.
**How to implement if missing:** Author the payload from Apple's public MDM documentation (or obtain a vetted `.mobileconfig`) and upload it via Intune → **Devices → macOS → Configuration → Create → Templates → Custom** (Implementation Step 9).

## 2.9 Change control / approval process
**Description:** A lightweight, documented approval step for applying and later changing the baseline.
**Why required:** Baseline changes are production changes; they need review and a rollback plan.
**How to verify:** You have a place to record approved changes and the baseline version in use (a change ticket, register, or the policy descriptions).
**How to implement if missing:** Adopt a simple change record (who approved, what changed, rollback step). Record the tag `macOS-Baseline-v1.0` in each policy/profile description.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Entra tenant with the Mac users/devices in scope
- [ ] Apple MDM Push (APNs) certificate present and **not expired** — `MACBASE-Discovery.ps1`
- [ ] macOS enrollment configured (ADE / account-driven / Company Portal); Macs enrolled — `MACBASE-Discovery.ps1`
- [ ] Supported macOS version on the target Macs
- [ ] `macOS Baseline – Pilot Devices` and `macOS Baseline – Production Devices` groups created
- [ ] Baseline decisions agreed (restrictions, update behaviour, compliance thresholds)
- [ ] (Optional) Custom `.mobileconfig` payloads identified for any non-catalog settings
- [ ] Change-control / approval process and version tag convention agreed
