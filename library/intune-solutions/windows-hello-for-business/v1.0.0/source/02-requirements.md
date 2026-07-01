# 2. Requirements Guide — Windows Hello for Business

Verify **every** requirement below before you configure anything. Each entry follows the same
pattern: **Description · Why required · How to verify · How to implement if missing.** Do not
assume any prerequisite already exists.

> Category-wide prerequisites (a tenant, an Intune subscription, MDM enrollment, etc.) are
> documented once in **`global-requirements-intune-solutions.md`**. This guide lists only what
> is specific to or especially important for WHfB.

---

## 2.1 Microsoft licensing
**Description:** Licenses that cover Intune device management and Microsoft Entra ID.
**Why required:** Intune delivers the WHfB policy; Entra ID stores the registered credential.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**. Confirm an Intune-bearing
plan (Intune Plan 1, Microsoft 365 E3/E5, or Business Premium) and at least Entra ID P1 if you
will gate access with Conditional Access.
**How to implement if missing:** Purchase/assign Microsoft 365 E3/E5 or Business Premium (Intune
included), or standalone Intune Plan 1, to every targeted user.

> **Note:** WHfB itself is a free Windows feature. Licensing is required for the *management*
> (Intune) and *identity* (Entra ID) layers, not for WHfB.

## 2.2 Microsoft Entra ID
**Description:** Devices must be **Microsoft Entra joined** (cloud) or **Microsoft Entra hybrid joined** (hybrid).
**Why required:** WHfB registers the public key against the device's Entra identity.
**How to verify:** On a device run `dsregcmd /status` → under **Device State**, `AzureAdJoined : YES`.
**How to implement if missing:** Cloud — join during OOBE or **Settings → Accounts → Access work or
school → Connect → Join this device to Microsoft Entra**. Hybrid — configure Entra Connect device
sync and the hybrid-join process.

## 2.3 Microsoft Intune (MDM)
**Description:** Targeted devices are enrolled in Intune.
**Why required:** Intune is how the WHfB policy reaches the device.
**How to verify:** Intune admin center → **Devices → All devices**; the device is listed and compliant.
For Entra-joined devices, MDM auto-enrollment should be on.
**How to implement if missing:** Entra admin center → **Devices → Device settings**, and Intune →
**Devices → Enrollment → Automatic Enrollment**: set **MDM user scope** to **All** (or a pilot group).

## 2.4 Windows operating system
**Description:** Windows 10 version 1709 or later; **Windows 11 recommended**.
**Why required:** WHfB and Cloud Kerberos Trust depend on modern Windows components.
**How to verify:** `winver` on the device, or Intune → device → **Hardware**. For Cloud Kerberos
Trust, use Windows 10 21H2+/Windows 11 21H2+ with current cumulative updates.
**How to implement if missing:** Patch via Windows Update / Update rings, or upgrade to Windows 11.

## 2.5 Hardware
**Description:** A business-class PC; optional biometric sensors.
**Why required:** WHfB binds keys to hardware; biometrics need specific sensors.
**How to verify:** For facial recognition confirm a **Windows Hello IR camera**; for fingerprint a
compatible reader (Device Manager → **Biometric devices**).
**How to implement if missing:** Users without biometric hardware still use a **PIN** — no blocker.
Add external IR cameras/fingerprint readers only where biometrics are desired.

## 2.6 TPM (Trusted Platform Module)
**Description:** A TPM chip, **version 2.0 recommended** (1.2 supported).
**Why required:** The TPM creates and protects the non-exportable private key. Without a TPM,
keys fall back to software protection (weaker) unless policy forbids it.
**How to verify:** Run `tpm.msc` → **Status: The TPM is ready for use**, and **Specification
Version 2.0**. Or `Get-Tpm` in PowerShell (`TpmPresent : True`, `TpmReady : True`).
**How to implement if missing:** Enable TPM in UEFI/BIOS (often labeled *PTT* on Intel, *fTPM* on
AMD). Replace hardware that has no TPM. The **WHfB-Discovery.ps1** script reports TPM status fleet-wide.

## 2.7 Cloud-only vs hybrid considerations
**Description:** Decide whether targeted devices are cloud-only or hybrid.
**Why required:** Hybrid devices need **Microsoft Entra Kerberos** to reach on-premises resources with WHfB.
**How to verify:** `dsregcmd /status` — cloud-only shows `AzureAdJoined : YES` and `DomainJoined : NO`;
hybrid shows both `YES`.
**How to implement if missing:** Cloud-only — nothing extra. Hybrid — run **Enable-EntraKerberos.ps1**
(in this package) once per domain to enable Microsoft Entra Kerberos (Cloud Kerberos Trust).

## 2.8 Network
**Description:** Outbound HTTPS to Microsoft Entra ID and Intune service endpoints; hybrid devices
need line-of-sight to a domain controller for Kerberos.
**Why required:** Enrollment and credential registration call cloud endpoints; hybrid resource
access requires DC connectivity.
**How to verify:** From a device, browse to `https://login.microsoftonline.com`; for hybrid run
`nltest /dsgetdc:<yourdomain>`.
**How to implement if missing:** Allow Microsoft 365/Entra/Intune endpoints through proxy/firewall
(Microsoft's published URL/IP list). Ensure VPN/network gives hybrid devices DC reachability.

## 2.9 Certificates
**Description:** None required for this solution.
**Why required (not):** We use **Cloud Kerberos Trust**, which does **not** require per-user
certificates, PKI, or NDES. This is deliberate — it removes the hardest part of legacy WHfB.
**How to verify:** N/A.
**How to implement if missing:** N/A. (Certificate Trust is explicitly out of scope.)

---

## Requirements checklist (use before configuring)
- [ ] Intune + Entra ID licensing assigned to pilot users
- [ ] Devices Microsoft Entra joined (or hybrid joined) — `dsregcmd /status`
- [ ] Devices enrolled in Intune and compliant
- [ ] Windows 10 21H2+/Windows 11 with current updates
- [ ] TPM present and ready (2.0) — `Get-Tpm` / `WHfB-Discovery.ps1`
- [ ] (Hybrid only) Microsoft Entra Kerberos enabled — `Enable-EntraKerberos.ps1`
- [ ] Network/proxy allows Microsoft cloud endpoints; hybrid has DC line-of-sight
- [ ] Pilot Entra security group created
