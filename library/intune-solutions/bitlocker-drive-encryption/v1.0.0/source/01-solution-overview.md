# 1. Solution Overview — BitLocker Drive Encryption

## What BitLocker is
BitLocker is the full-volume encryption built into Windows. It encrypts the operating-system
drive (and optionally fixed data drives) so the data is unreadable without the correct key.
Managed through Microsoft Intune, encryption is enforced by policy, enabled **silently** on
devices with a TPM, and every **recovery key is escrowed to Microsoft Entra ID**.

## How it works
1. An Intune **disk encryption policy** defines the encryption requirements (method, drives, protectors).
2. On a targeted device, BitLocker enables — **silently** when a TPM is present and the user has no action to take.
3. The OS drive is protected by the **TPM** (optionally plus a startup PIN); the encryption uses **XTS-AES 256**.
4. The **recovery key is automatically backed up to Entra ID**, visible to admins in Intune (device → Recovery keys) and Entra (device → BitLocker keys).
5. Intune reports each device's encryption status for compliance and audits.

## What you can require
- **OS drive** encryption with TPM protector (and optional startup PIN), XTS-AES 256.
- **Fixed data drive** encryption with auto-unlock.
- **Recovery options** — store recovery key in Entra ID, hide recovery options from the user, client-driven recovery password rotation.
- **Silent enablement** for standard users on TPM devices.

## Benefits
- **Device-loss protection** — a lost/stolen device exposes no readable data.
- **Silent and zero-touch** — no user action on TPM hardware.
- **Always recoverable** — keys escrowed to Entra ID; the help desk can recover access.
- **Compliance cornerstone** — satisfies "require encryption" in device compliance.

## Limitations (be honest with buyers)
- **Silent** enablement requires a **TPM** and a supported, properly configured device.
- Devices without a TPM can encrypt but require a startup PIN/USB key (not silent).
- The first full encryption takes time (used-space-only is faster); plan pilot timing.
- Self-encrypting drives / certain firmware quirks may need hardware-specific handling.

## The standard Phoenixtekk deployment model
> **Create the disk encryption policy → require XTS-AES 256 + Entra key escrow + silent enablement
> → assign to a pilot → validate encryption + key escrow → expand.** Phoenixtekk pattern:
> **Assess → Configure → Pilot → Validate → Expand.**
