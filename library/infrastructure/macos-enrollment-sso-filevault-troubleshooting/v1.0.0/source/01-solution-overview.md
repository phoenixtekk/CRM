# 1. Solution Overview — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

## What this solution is
A structured, symptom-driven method — a diagnostic playbook plus tooling — for troubleshooting the
**macOS + Microsoft Intune** stack when a Mac won't finish enrolling, won't sign in through
**Platform/Extensible SSO**, throws a **SecureToken/FileVault** error, is compliant but still denied
by **Conditional Access**, or locks a user out after enrollment. Instead of wiping the Mac on a
hunch, you read the signals the stack already produces — the **Automated Device Enrollment (ADE)**
assignment, the delivered **configuration profiles**, the SSO extension state, SecureToken/FileVault
status, and the compliance/Conditional-Access result — and follow a root-cause tree that isolates
the **one failing layer** in minutes. The result is a repeatable diagnose-then-resolve loop any
competent Intune administrator or Mac technician can run.

## The macOS + Intune signal path (the layered model)
A working, trusted Mac is the product of a chain of layers, each of which must succeed before the
next can. When something fails, it is almost always **one** layer — and the layers fail in a
predictable order, so you diagnose top-down:

1. **ADE / enrollment.** The Mac's serial is assigned to your MDM in **Apple Business Manager**
   (ABM) or **Apple School Manager** (ASM), which is synced to Intune's **enrollment program token**.
   During **Setup Assistant** the Mac contacts Apple, is handed to Intune, and enrolls with an
   **enrollment profile**. If the serial isn't assigned, or the token is expired, or the profile
   isn't set as default — enrollment never starts.
2. **Configuration profiles.** Once enrolled, Intune delivers the **device configuration profiles**
   the later layers depend on: the **SSO app extension** (Platform SSO or the Microsoft Enterprise
   SSO plug-in / Extensible SSO), the **compliance-supporting** settings, and any **FileVault**
   policy. Profiles are targeted by group; if the Mac isn't in the right group, or a profile shows
   **Error/Conflict**, the dependent layer above it can't work.
3. **SSO (Platform SSO / Extensible SSO).** With the extension profile delivered and the
   **Company Portal** (or Microsoft **Authenticator**/**Intune** app for the plug-in) installed and
   registered, the user signs in with their Entra ID identity. **Platform SSO** additionally binds
   the local account to Entra. If the extension isn't registered, the app isn't installed, or the
   method (password / secure-enclave key / smart card) is misconfigured, sign-in fails here.
4. **SecureToken / FileVault.** On Apple Silicon and modern macOS, a user needs a **SecureToken** (or
   the volume-owner **Bootstrap Token**, escrowed to Intune) to be enabled for FileVault and to
   unlock the disk at boot. Intune can escrow the **FileVault personal recovery key**. If the first
   account never gained SecureToken, or the Bootstrap Token wasn't escrowed, FileVault enablement or
   a user's disk-unlock fails.
5. **Compliance / Conditional Access.** Intune evaluates the Mac against the **compliance policy**;
   the result flows to Entra ID, where **Conditional Access** decides whether the identity on that
   device may reach a resource. A Mac can be perfectly enrolled and still be **denied** — because it
   is non-compliant, or because a CA policy (device state, app, grant control) blocks it.

> **Read the model top-down.** A failure at a lower layer (SSO, FileVault, CA) is very often caused
> by a missing or errored artifact **above** it (an unassigned serial, an undelivered profile). The
> playbook always confirms the higher layer before blaming the lower one.

## The five failure classes (symptoms)
Almost every "stuck Mac" ticket is one of these. Each has a diagnostic tell and a branch in the
Diagnostic Playbook (§3):

- **ADE not assigned / enrollment stuck.** Setup Assistant shows no **Remote Management** screen, or
  enrollment hangs / errors. Tell: the serial isn't assigned to the MDM in ABM/ASM, the enrollment
  program token is expired, or no default enrollment profile is set.
- **SSO won't sign in.** The Platform/Extensible SSO prompt never appears, loops, or rejects the
  Entra credential. Tell: the SSO extension profile isn't delivered/registered, the required app
  (Company Portal / Authenticator) isn't installed, or the extension configuration is wrong.
- **SecureToken / FileVault error.** FileVault won't enable, a user can't unlock the disk at boot, or
  the recovery key isn't escrowed. Tell: the account lacks SecureToken, the Bootstrap Token wasn't
  escrowed to Intune, or the FileVault profile is in Error.
- **Compliant but denied.** The device shows **Compliant** in Intune yet the user is still blocked
  from a resource. Tell: a Conditional-Access policy (device state, sign-in risk, app control) is
  denying — or the compliance signal hasn't reached Entra yet.
- **User locked out after enrollment.** Enrollment succeeded but the user can't log in / is prompted
  for an unknown password, or the local account is out of sync with Entra. Tell: Platform SSO
  account binding, a FileVault-enabled account mismatch, or a mobile-account/password issue.

## The signals you read (and where)
| Layer | Primary signal | Where you read it |
|---|---|---|
| ADE / enrollment | Serial assignment, token expiry, default profile | ABM/ASM; Intune → **Devices → Enrollment → Enrollment program tokens** |
| Profiles | Profile assignment + per-device state (`Succeeded`/`Error`/`Conflict`) | Intune → **Devices → Configuration**; device → **Device configuration** |
| SSO | Extension delivered/registered; app installed | Device profile state; on-Mac `Profiles` pane / `app-sso` diagnostics |
| SecureToken / FileVault | SecureToken holder, Bootstrap Token escrow, recovery key escrow | On-Mac `sysadminctl`/`fdesetup`; Intune device → **Recovery keys** |
| Compliance / CA | Compliance state; CA policy result; sign-in log | Intune device → **Compliance**; Entra → **Sign-in logs** / **Conditional Access** |

## The diagnose → resolve method
> **1. Classify the symptom** into one of the five classes. **2. Confirm the layer above** the
> symptom is healthy (top-down) — assignment, then profile, then app/extension. **3. Read the layer's
> signal** (the table above) to find the failing artifact. **4. Apply the branch fix** from the
> Playbook (§3). **5. Re-check the signal** and confirm the symptom is gone. **6. Record** the
> symptom, the failing layer, the cause, and the fix so the next ticket is faster.

## The standard deployment model
> **Assess** the failing Mac and its symptom class → **Configure** the read access and vantage points
> (Graph read, device logs, ABM/ASM) → **Pilot** the playbook on real failures → **Validate** the
> diagnoses and fixes → **Expand** it to the whole support team. Repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand.**
