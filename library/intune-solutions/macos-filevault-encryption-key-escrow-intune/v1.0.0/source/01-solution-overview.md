# 1. Solution Overview — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

## What FileVault is
FileVault is Apple's built-in full-disk (whole-volume) encryption for macOS. When enabled, the
data on the Mac's internal drive is encrypted with **XTS-AES 128** and is unreadable without a
credential that can unlock it. Managed through Microsoft Intune, FileVault is **enforced by
policy**, and every **personal recovery key is escrowed to Intune** so an authorized admin can
recover a locked-out Mac.

## How it works on modern Macs (Apple Silicon and Intel T2)
On **Apple Silicon** Macs and **Intel Macs with the Apple T2 Security Chip**, the internal storage
is *always* hardware-encrypted at the controller level. FileVault adds the crucial second layer:
it ties decryption of the volume to a **user credential**, so the data is not readable simply by
having the hardware. Turning FileVault on is therefore what makes the built-in encryption
meaningful for device-loss protection — without it, the drive can be unlocked without a password.

FileVault depends on a macOS feature called **SecureToken**:

1. A **SecureToken** is a wrapped cryptographic key granted to a user account. Only a user who
   holds a SecureToken can be enabled for FileVault (added to the list of users allowed to unlock
   the disk at boot).
2. On **Automated Device Enrollment (ADE/DEP)** Macs, Intune deploys a **bootstrap token** — a
   token escrowed to MDM that lets the management channel grant SecureToken to accounts (including
   mobile/Entra accounts) without an existing SecureToken admin present. **This is why the bootstrap
   token matters: without it, a freshly provisioned ADE Mac may have no SecureToken user, and
   FileVault cannot be enabled.**
3. With a SecureToken-enabled user present, the Intune **FileVault disk-encryption policy** turns
   FileVault on. On next login the user is prompted (or, where supported, enablement is deferred to
   the next sign-in) and encryption begins.

## Personal vs institutional recovery keys
FileVault supports two recovery-key models. Intune uses the **personal recovery key** model:

- **Personal recovery key (what Intune manages):** a unique 24-character key is generated **per
  device** during enablement and **escrowed to Intune**. It is visible to admins in the Intune
  admin center under the device's **Recovery keys**, and retrievable through Microsoft Graph. Intune
  can also **rotate** the personal recovery key after it has been used or on a schedule.
- **Institutional recovery key:** a single organization-wide key backed by a certificate/keychain
  that unlocks any Mac. Intune's FileVault profile is built around the **personal** key model;
  institutional keys are a legacy, higher-risk pattern (one key unlocks the whole fleet) and are not
  the recommended Intune approach. This solution uses **personal keys escrowed and rotated by
  Intune**.

## The recovery model
When a user forgets their password or a Mac is locked out:

1. The admin looks up the device in Intune → device → **Recovery keys** (or retrieves it through
   Microsoft Graph — see `MACFV-Report.ps1`).
2. At the FileVault login/recovery screen, the personal recovery key unlocks the volume.
3. The user resets their password; Intune **rotates** the personal recovery key so the used key is
   retired and a fresh one is escrowed.

## What you can require through Intune
- **Enable FileVault** on the target Macs (disk-encryption policy, platform macOS, profile
  **FileVault**).
- **Escrow the personal recovery key to Intune** and **hide the recovery key from the user**.
- **Rotate** the personal recovery key (after use / on a schedule).
- **Defer enablement** until the user next logs out/in, with an optional prompt limit.
- Deploy the **bootstrap token** (via ADE enrollment) so SecureToken can be granted.

## Benefits
- **Device-loss protection** — a lost or stolen Mac exposes no readable data.
- **Always recoverable** — personal keys escrowed to Intune; the help desk can always unlock a Mac.
- **Rotatable keys** — a used recovery key can be retired automatically.
- **Compliance cornerstone** — satisfies "require encryption" in device compliance / Conditional Access.

## Limitations (be honest with buyers)
- **FileVault needs a SecureToken-enabled user.** On non-ADE (manually enrolled) Macs there may be
  no bootstrap token, so SecureToken must be granted by an existing SecureToken user — plan for this.
- **Enablement often requires the user to sign in** (FileVault is enabled at login on the personal
  key model); it is not always fully silent.
- The **first full encryption takes time**; plan pilot timing.
- FileVault's encryption method is **XTS-AES 128** (Apple's implementation) — this is expected and
  is not the same knob as Windows BitLocker's selectable method.

## The standard deployment model
> **Confirm SecureToken/bootstrap-token → create the FileVault disk-encryption policy (escrow +
> rotate) → assign to a pilot → validate encryption + key escrow + recovery → expand.** The
> repeatable pattern is: **Assess → Configure → Pilot → Validate → Expand.**
