# 7. Best Practices — macOS Automated Device Enrollment with SSO

Field-proven guidance to keep the deployment reliable, secure, and low-maintenance.

## Identity & authentication
- **Standardize on the Secure Enclave key method.** It is phishing-resistant and decouples the local
  password from Entra. Reserve password sync for edge cases that genuinely need it.
- **Require user affinity** on the enrollment profile so each Mac is tied to a user and Platform SSO
  can register. Device-affinity (shared) Macs need a different design.
- **Layer Conditional Access** to require compliant, registered Macs for Microsoft 365 — start in
  **report-only**, then enforce once the pilot is clean.

## Enrollment hygiene
- **Always supervise** company Macs (Step 7) and **lock enrollment** so management can't be removed.
- **Buy through channels linked to ABM** so devices appear automatically; use Apple Configurator only
  for legacy stock, and complete enrollment before the **30-day provisional period** lapses.
- **Keep one well-named MDM server** per environment in ABM (e.g. *Intune – Production*) to avoid
  assigning devices to the wrong tenant.

## Token & certificate lifecycle (the #1 cause of outages)
- **Track both annual expiries** — the **APNs certificate** and the **ADE token**. A lapse blocks all
  new enrollments and can unenroll devices.
- **Always renew APNs with the same company Apple ID.** Document which Apple ID owns it; never use a
  personal Apple ID or one tied to an individual who may leave.
- **Schedule `ADEMAC-Discovery.ps1`** to run regularly and alert on anything within 30 days of expiry.

## Operating system & updates
- **Set a minimum-OS compliance policy** (macOS 14+ recommended) so Platform SSO works reliably and
  out-of-support Macs are flagged.
- **Manage updates with Intune** (declarative software updates) so the fleet stays patched without
  user intervention.

## Rollout discipline
- **Pilot first, expand in waves.** Validate each wave with `ADEMAC-Validation.ps1` before widening.
- **Hide noisy Setup Assistant screens** for a clean, fast first-run, but keep privacy/location
  prompts that your policy requires.
- **Pre-stage apps as Required** (starting with Company Portal) so a freshly enrolled Mac is useful
  within minutes.

## Operations & documentation
- **Keep a runbook** of the Apple ID, ABM org, MDM server name, token/cert expiry dates, and the SSO
  profile identifiers — the values that, if lost, are painful to recover.
- **Report monthly** with `ADEMAC-DeviceReport.ps1`: enrolled macOS count, ADE vs. other, OS spread,
  Platform SSO registration coverage, and compliance.
- **Test OS upgrades** against the SSO extension before broad deployment; Apple occasionally changes
  Platform SSO behavior between major releases.

## Security posture
- **Combine with disk encryption** (FileVault) and a **macOS security baseline/compliance policy** for
  a complete managed posture (separate solutions cover these).
- **Limit local admin** and use Intune to manage privileged access; supervised + locked enrollment
  prevents users from quietly removing management.
