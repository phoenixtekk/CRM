# 7. Best Practices — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Field-proven guidance to keep the Jamf-managed, Entra-enforced deployment reliable, secure, and
low-maintenance.

## Architecture & ownership
- **Keep one MDM authority.** Jamf is the **MDM**; Intune/Entra are the **identity & compliance**
  authority. Never try to dual-enroll a Mac into both Jamf and Intune MDM.
- **Document the split.** Record which controls live in Jamf (enrollment, profiles, patch, Self
  Service) versus Entra/Intune (registration, compliance, Conditional Access) so the team knows where
  to look.

## Identity & authentication
- **Standardize on the Secure Enclave key method.** It is phishing-resistant and decouples the local
  password from Entra. Reserve password sync for edge cases that genuinely need it.
- **Pair Platform SSO with a phishing-resistant Conditional Access strength** once the pilot is clean,
  so the Secure Enclave credential is actually required, not just available.
- **Enforce with Conditional Access in waves** — start **report-only**, confirm compliance is
  flowing, then turn the macOS policy **On**.

## Enrollment hygiene
- **Always supervise** company Macs (Step 7) and make the **MDM profile mandatory** so management
  can't be removed.
- **Buy through channels linked to ABM** so devices appear automatically; use Apple Configurator only
  for legacy stock, and complete enrollment before the **30-day provisional period** lapses.
- **Keep one well-named MDM server** per environment in ABM (e.g. *Jamf – Production*) to avoid
  assigning devices to the wrong tenant.
- **Use Smart Groups** to drive scope (PreStage, SSO profile, Company Portal, compliance) so a device
  picks up everything automatically as it enrolls.

## Token & certificate lifecycle (the #1 cause of outages)
- **Track both annual expiries** — the Jamf **APNs certificate** and the **ADE token**. A lapse blocks
  all new enrollments and can unenroll devices.
- **Always renew APNs with the same company Apple ID.** Document which Apple ID owns it; never use a
  personal Apple ID or one tied to an individual who may leave.
- **Schedule `JAMFADE-JamfReadiness.ps1`** to run regularly and alert on anything within 30 days of
  expiry.

## Operating system & updates
- **Set a minimum-OS rule in both places** — a Jamf Smart Group/policy and a matching Intune
  **compliance** rule (macOS 14+ recommended) so Platform SSO works reliably and out-of-support Macs
  are flagged and blocked by Conditional Access.
- **Manage updates in Jamf** (Software Updates / DDM) so the fleet stays patched without user
  intervention.

## Rollout discipline
- **Pilot first, expand in waves.** Validate each wave with `JAMFADE-Validation.ps1` before widening.
- **Hide noisy Setup Assistant panes** for a clean, fast first-run, but keep privacy/location prompts
  that your policy requires.
- **Pre-stage apps and profiles** (Company Portal + SSO) in the PreStage so a freshly enrolled Mac is
  useful — and registerable — within minutes.

## Operations & documentation
- **Keep a runbook** of the Apple ID, ABM org, Jamf MDM server name, APNs/ADE expiry dates, the SSO
  profile identifiers, and the Device Compliance connector status — the values that, if lost, are
  painful to recover.
- **Report monthly** with `JAMFADE-DeviceReport.ps1`: macOS count, Platform SSO registration coverage,
  Entra registration, and Intune compliance (partner-managed) — so drift is visible early.
- **Re-validate the Jamf ↔ Intune integration after major updates** to either platform; Microsoft and
  Jamf occasionally change the connector and the SSO/Platform-SSO behavior between releases.

## Security posture
- **Combine with disk encryption** (FileVault, escrowed to Jamf) and a **macOS security baseline** for
  a complete managed posture.
- **Make compliance meaningful** — define Intune compliance to reflect real Jamf signals (encryption,
  OS version, etc.) so Conditional Access enforces a genuine security bar, not just registration.
- **Limit local admin** and use Jamf to manage privileged access; supervised + mandatory enrollment
  prevents users from quietly removing management.
