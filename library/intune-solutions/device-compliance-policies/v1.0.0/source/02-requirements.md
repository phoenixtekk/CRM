# 2. Requirements Guide — Device Compliance Policies

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1) for compliance; Microsoft Entra ID P1 for Conditional Access enforcement.
**Why:** Intune evaluates compliance; Entra P1 lets Conditional Access require a compliant device.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (both include Intune + Entra P1).

## 2.2 Device enrollment
**Description:** Targeted devices are enrolled in Intune.
**Why:** Compliance is only evaluated on enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Device health prerequisites
**Description:** TPM + UEFI Secure Boot for the health rules (BitLocker, Secure Boot).
**Why:** Health attestation rules require TPM/Secure Boot capable hardware.
**Verify:** `Get-Tpm`; `Confirm-SecureBootUEFI`; or run **`DCP-Discovery.ps1`**.
**Implement:** Enable TPM and Secure Boot in UEFI; this solution can be paired with the BitLocker solution to enforce encryption.

## 2.4 Microsoft Defender (for AV/firewall rules)
**Description:** Microsoft Defender Antivirus + Windows Firewall active (or a managed AV).
**Why:** Compliance can require real-time protection and firewall on.
**Verify:** `Get-MpComputerStatus`; `Get-NetFirewallProfile`.
**Implement:** Ensure Defender AV is enabled (default) and firewall profiles are on.

## 2.5 Defender for Endpoint (optional — threat level rules)
**Description:** Defender for Endpoint connector in Intune.
**Why:** Required only if you enforce a machine risk score.
**Verify:** Intune → **Endpoint security → Microsoft Defender for Endpoint** connection status = Active.
**Implement:** Connect Defender for Endpoint (see the Defender integration solution).

## 2.6 Conditional Access (for enforcement)
**Description:** A Conditional Access policy requiring a compliant device.
**Why:** Compliance reports status; Conditional Access turns it into access enforcement.
**Verify:** Entra → **Protection → Conditional Access**.
**Implement:** Pair with the Conditional Access Integration solution.

---
## Checklist
- [ ] Intune + Entra P1 licensing assigned
- [ ] Devices enrolled
- [ ] TPM + Secure Boot for health rules — `DCP-Discovery.ps1`
- [ ] Defender AV + firewall active
- [ ] (Optional) Defender for Endpoint connected for threat-level rules
- [ ] Pilot Entra group created
- [ ] Tenant "no compliance policy" default decided
