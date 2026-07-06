# 2. Requirements Guide — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Object names used throughout this solution (reuse them verbatim in Intune):
- Disk-encryption policy: `FileVault – Pilot` (and later `FileVault – Production`)
- Pilot device group: `FileVault – Pilot Devices`
- Production device group: `FileVault – Production Devices`
- (If used) macOS enrollment profile / bootstrap-token source: your Automated Device Enrollment profile

## 2.1 Intune licensing
**Description:** An Intune-bearing license (Plan 1 is sufficient for the macOS disk-encryption policy).
**Why required:** Intune delivers the FileVault disk-encryption policy, escrows the recovery key, and reports encryption status.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**.
**How to implement if missing:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 Apple MDM Push (APNs) certificate
**Description:** A valid Apple Push Notification service (APNs) certificate configured in Intune.
**Why required:** No Apple device — including a Mac — can be managed by Intune without an APNs certificate; no policy reaches the Mac until it exists.
**How to verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; confirm it is present and **not expired**. Run `MACFV-Discovery.ps1`.
**How to implement if missing:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate → download the CSR**, create the certificate at `https://identity.apple.com` with a long-lived Apple ID, upload it back, and record the renewal date.

## 2.3 macOS enrollment configured (and enrolled Macs)
**Description:** A working macOS enrollment method so target Macs are enrolled and manageable — Automated Device Enrollment (ADE/DEP), Account-driven enrollment, or Company Portal.
**Why required:** The FileVault policy and its escrow/reporting apply only to enrolled Macs.
**How to verify:** Intune → **Devices → macOS → macOS devices**; the Mac appears as managed. Run `MACFV-Discovery.ps1`.
**How to implement if missing:** Configure **Automated Device Enrollment** (Apple Business/School Manager token + an enrollment profile) for corporate Macs, or **Account-driven**/Company Portal enrollment for user-owned Macs; then enrol the devices.

## 2.4 Supported hardware — Apple Silicon or Intel T2
**Description:** Target Macs are **Apple Silicon** or **Intel Macs with the Apple T2 Security Chip** (older Intel Macs still support FileVault but lack the hardware layer and bootstrap-token behaviour).
**Why required:** SecureToken/bootstrap-token behaviour and the always-on hardware encryption described in the Overview depend on Apple Silicon / T2.
**How to verify:** On a Mac, **Apple menu → About This Mac** (Apple Silicon shows a "Chip"; Intel T2 Macs list the T2 under **System Report → Controller**). Or Intune → device → **Hardware**.
**How to implement if missing:** For unsupported older hardware, FileVault still encrypts but plan SecureToken enablement manually and expect no bootstrap-token flow.

## 2.5 SecureToken / bootstrap token available
**Description:** At least one account on each Mac can be granted **SecureToken**, and (on ADE Macs) a **bootstrap token** is escrowed to Intune.
**Why required:** FileVault **cannot be enabled** for a user without a SecureToken. On ADE Macs the bootstrap token lets Intune grant SecureToken to accounts; without it a fresh ADE Mac may have no SecureToken user.
**How to verify:** On a Mac, `sysadminctl -secureTokenStatus <username>` shows **ENABLED** for the target user; `profiles status -type bootstraptoken` shows the bootstrap token is escrowed to the server. Run `MACFV-Discovery.ps1` for the tenant/enrollment signals.
**How to implement if missing:** Enroll corporate Macs via **Automated Device Enrollment** so the bootstrap token is generated and escrowed at setup. For already-enrolled Macs, run `sudo profiles install -type bootstraptoken` from a SecureToken-enabled admin, or grant SecureToken with `sysadminctl -secureTokenOn` from an existing SecureToken admin.

## 2.6 Microsoft Entra ID groups (pilot and production)
**Description:** Two Entra ID security groups: `FileVault – Pilot Devices` (a small representative sample of Macs) and `FileVault – Production Devices` (the rest of the Mac fleet).
**Why required:** FileVault is piloted before fleet rollout because enablement affects user login and the first encryption takes time.
**How to verify:** Entra → **Groups**; both groups exist. Use `MACFV-Set-ScopeTargeting.ps1` to stage membership.
**How to implement if missing:** Entra → **Groups → New group → Security**; add representative pilot Macs to one and the remaining Macs to the other.

## 2.7 A pilot (change control)
**Description:** A documented approval step and a small pilot of representative Macs before fleet rollout, with a rollback plan.
**Why required:** Enabling FileVault is a production change that touches user login; validate escrow and recovery on a pilot before scaling.
**How to verify:** You have a change record (who approved, what changed, rollback step) and a populated `FileVault – Pilot Devices` group.
**How to implement if missing:** Adopt a simple change record and populate the pilot group with a representative sample.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Apple MDM Push (APNs) certificate present and not expired — `MACFV-Discovery.ps1`
- [ ] macOS enrollment configured (ADE / Account-driven / Company Portal); Macs enrolled
- [ ] Target Macs are Apple Silicon or Intel T2
- [ ] SecureToken available / bootstrap token escrowed (ADE) — `MACFV-Discovery.ps1`
- [ ] `FileVault – Pilot Devices` and `FileVault – Production Devices` groups created
- [ ] Pilot + change-control/approval process agreed
