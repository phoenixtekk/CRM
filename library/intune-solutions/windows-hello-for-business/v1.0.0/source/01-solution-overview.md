# 1. Solution Overview — Windows Hello for Business

## What Windows Hello for Business is
Windows Hello for Business (WHfB) is a passwordless, two-factor authentication method built
into Windows 10 and Windows 11. It replaces the user's password with a credential made of two
parts:

1. **Something the user has** — a private cryptographic key bound to the specific device and
   protected by the device's **TPM** (Trusted Platform Module).
2. **Something the user is or knows** — a **biometric** (face or fingerprint) or a **PIN** that
   unlocks the key locally.

The PIN and biometric never travel across the network and are not stored centrally. They only
unlock the private key, which stays on the device hardware. There is no password to phish,
spray, or replay.

## How it works
1. When a user enrolls, Windows generates an asymmetric key pair. The **private key** is created
   inside the **TPM** and cannot be exported.
2. The **public key** is registered with Microsoft Entra ID against the user's account.
3. To sign in, the user presents their gesture (face/fingerprint/PIN). This unlocks the TPM,
   which signs an authentication request with the private key.
4. Microsoft Entra ID validates the signature against the registered public key and issues the
   sign-in token. Access to on-premises resources (hybrid) is brokered via **Microsoft Entra
   Kerberos** (Cloud Kerberos Trust).

Because the private key is hardware-bound and unlocked only locally, WHfB is **phishing-resistant**:
an attacker who tricks a user on a fake website gains nothing — there is no shared secret to steal.

## Authentication methods supported
- **PIN** — a device-local code (digits, optionally letters/symbols). Always available as the baseline.
- **Facial recognition** — requires a Windows Hello–compatible **infrared (IR) camera**.
- **Fingerprint** — requires a compatible fingerprint reader.

All three unlock the same underlying hardware-bound key; biometrics are a convenience layer over the PIN.

## Benefits
- **Phishing-resistant, passwordless** sign-in — removes the most-attacked credential.
- **Hardware-bound** — the credential is useless on any other device.
- **Fewer password resets** — lower help-desk cost.
- **Better user experience** — a glance or a tap instead of a typed password.
- **Compliance** — supports modern Zero Trust and passwordless mandates; integrates with Conditional Access.

## Limitations (be honest with buyers)
- Requires a **TPM** (2.0 strongly recommended) and modern Windows.
- Biometrics need supported hardware (IR camera / fingerprint reader); without it, users still get PIN.
- The credential is **per-device** — a user signing in on a new device enrolls again there.
- Hybrid (on-premises AD) access to file shares/printers requires **Microsoft Entra Kerberos** to be enabled.
- Shared/kiosk multi-user scenarios need extra planning (not covered by the base solution).

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Microsoft Entra–joined devices, managed by Intune, using Cloud Kerberos Trust.**

- **Cloud-only organizations:** WHfB works against Microsoft Entra ID with no on-premises components.
- **Hybrid organizations:** the same model applies; you additionally enable **Microsoft Entra
  Kerberos** once (a single script in this package) so WHfB users can reach on-premises resources.

This avoids the complexity of the legacy **Certificate Trust** model (no PKI, NDES, or
per-user certificates required). Every step follows the repeatable pattern:
**Assess → Configure → Pilot → Validate → Expand.**
