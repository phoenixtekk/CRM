# 2. Requirements Guide — BitLocker Drive Encryption

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1); BitLocker is a Windows feature (no separate license).
**Why:** Intune delivers and reports the disk encryption policy.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Windows edition
**Description:** Windows 10/11 **Pro, Enterprise, or Education**.
**Why:** BitLocker is not available on Windows Home.
**Verify:** `winver` / **Settings → System → About → Edition**.
**Implement:** Upgrade Home editions to Pro/Enterprise.

## 2.3 TPM (for silent enablement)
**Description:** TPM 1.2+ (2.0 recommended), enabled in UEFI.
**Why:** Silent BitLocker enablement and the strongest protection require a TPM.
**Verify:** `Get-Tpm` (`TpmPresent : True`, `TpmReady : True`); or run **`BITLK-Discovery.ps1`**.
**Implement:** Enable TPM/PTT/fTPM in UEFI. Devices without TPM can still encrypt with a startup PIN/USB key (not silent).

## 2.4 UEFI / Secure Boot (recommended)
**Description:** UEFI firmware with Secure Boot.
**Why:** Modern boot integrity improves BitLocker protection and pairs with health attestation.
**Verify:** `Confirm-SecureBootUEFI`.
**Implement:** Switch firmware to UEFI and enable Secure Boot (may require reinstall if legacy BIOS/MBR).

## 2.5 Microsoft Entra ID (key escrow)
**Description:** Devices Microsoft Entra joined (or hybrid joined).
**Why:** Recovery keys are escrowed to the device's Entra object.
**Verify:** `dsregcmd /status` → `AzureAdJoined : YES`.
**Implement:** Join devices to Microsoft Entra.

## 2.6 Device enrollment
**Description:** Devices enrolled in Intune.
**Why:** The policy and reporting require enrollment.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Windows Pro/Enterprise/Education
- [ ] TPM present + ready (for silent) — `BITLK-Discovery.ps1`
- [ ] UEFI + Secure Boot (recommended)
- [ ] Devices Microsoft Entra joined (key escrow)
- [ ] Devices enrolled in Intune
- [ ] Pilot Entra group created
