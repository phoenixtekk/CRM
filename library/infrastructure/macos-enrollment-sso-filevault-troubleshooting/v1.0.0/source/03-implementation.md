# 3. Diagnostic Playbook — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

This is the runbook. It takes a stuck Mac, classifies the symptom, and drives it to the failing layer
and a fix. Console work is in the **Microsoft Intune admin center** (`https://intune.microsoft.com`);
on-device checks run in **Terminal** on the affected Mac (admin); the scripts run from a PowerShell
session with the **Microsoft.Graph.Authentication** module signed in with the read scopes (§2.2).

> **Method:** Classify the symptom → confirm the layer **above** it is healthy (top-down) → read the
> layer's signal → apply the branch fix → re-check → record. Name every artifact you create with
> `<Purpose> – <Scope> – <Stage>` and reuse the names (e.g. `macOS SSO Fix – Pilot – Triage`).

## Step 0 — Classify the symptom and gather context
1. Ask the one question that picks the branch: **where does it stop?**
   - No Remote Management / enrollment never finishes → **Branch A (ADE/enrollment)**.
   - Enrolled, but the SSO prompt never works → **Branch B (SSO)**.
   - FileVault won't enable or a user can't unlock the disk → **Branch C (SecureToken/FileVault)**.
   - Device shows Compliant but a resource is blocked → **Branch D (compliant but denied)**.
   - Enrolled, but the user can't log in / password is wrong → **Branch E (locked out)**.
2. Get the device context first — run `MACDX-Discovery.ps1` to list the macOS device, its enrollment
   state, ownership, compliance, last check-in, and OS build. This confirms which layer the device
   has reached and gives you the device id the other scripts use.

---

## Branch A — ADE not assigned / enrollment stuck
**Tell:** Setup Assistant shows no **Remote Management** screen, or enrollment hangs/errors.
**Diagnose top-down (Apple assignment → Intune token → profile):**
1. **Serial assigned in Apple.** In **Apple Business Manager / School Manager → Devices**, search the
   Mac's serial. Confirm it is assigned to **your** MDM server (the Intune server). If it isn't
   there, the device was never bought through / added to ABM/ASM — no ADE is possible.
2. **Token healthy in Intune.** Intune → **Devices → Enrollment → Enrollment program tokens**. Confirm
   the token's **expiry is in the future** and a **default enrollment profile** is set. Run
   `MACDX-Validation.ps1 -Check Enrollment` to read the token/profile summary via Graph.
3. **Profile assigned to the device.** In the token → **Profiles** and **Devices**, confirm the Mac's
   serial has an enrollment profile assigned (not just the default). Re-sync ABM/ASM
   (**Sync**) if the serial is new.
4. **On the Mac.** After erase, at Setup Assistant, or via `sudo profiles renew -type enrollment`
   (macOS reaches out again). `profiles status -type enrollment` should report it is enrolled / has a
   configuration waiting.

**Fix:**
- Serial not assigned → have the reseller/Apple assign it, or add it to ABM/ASM and **Sync** to Intune.
- Token expired → **renew** the token (download a new one from ABM/ASM, upload to Intune).
- No default profile → set a **default enrollment profile** on the token and assign it to the serial.
- Stuck mid-enrollment → erase and re-run Setup Assistant, or `sudo profiles renew -type enrollment`.

**Confirm:** The Mac reaches **Remote Management** and appears in Intune → **Devices → macOS** as
enrolled. Re-run `MACDX-Validation.ps1`.

---

## Branch B — SSO won't sign in (Platform SSO / Extensible SSO)
**Tell:** The Platform/Extensible SSO prompt never appears, loops, or rejects the Entra credential.
**Diagnose top-down (profile delivered → app installed → extension registered → method correct):**
1. **Extension profile delivered.** Intune → device → **Device configuration**; the **SSO app
   extension** (Platform SSO or the Microsoft Enterprise SSO / Extensible SSO) profile shows
   **Succeeded**, not Error/Conflict. Run `MACDX-Validation.ps1 -Check Profiles` to list per-device
   profile states via Graph.
2. **Required app installed.** The extension needs its companion app present and run once:
   **Company Portal** (Platform SSO / Company Portal-based registration) or Microsoft
   **Authenticator** (Extensible SSO plug-in). Confirm the app is assigned (Intune → **Apps → macOS**)
   and installed on the Mac.
3. **Extension registered on the Mac.** In Terminal: `app-sso platform -s` (Platform SSO) shows the
   registration/state; `app-sso -l` lists SSO extensions. For Extensible SSO, **System Settings →
   Profiles** shows the SSO extension profile installed.
4. **Method correct.** Confirm the configured Platform SSO **authentication method** (Password,
   Secure Enclave key, or Smart Card) matches what the user has and what the profile specifies; a
   Secure-Enclave-key config with no registered key loops.

**Fix:**
- Profile in Error/Conflict → resolve the conflicting profile / re-assign; confirm the Mac is in the
  target group (`MACDX-Set-ScopeTargeting.ps1`, `-WhatIf` by default).
- App missing → assign/install Company Portal or Authenticator; open it once to register.
- Not registered → have the user complete registration in Company Portal; `sudo profiles renew` to
  re-pull the extension; re-run after check-in.
- Wrong method → align the profile's Platform SSO method with the user's capability; re-deploy.

**Confirm:** The user signs in through SSO and `app-sso platform -s` shows a registered/logged-in
state. Re-run `MACDX-Validation.ps1 -Check Profiles`.

---

## Branch C — SecureToken / FileVault error
**Tell:** FileVault won't enable, a user can't unlock the disk at boot, or the recovery key isn't escrowed.
**Diagnose top-down (SecureToken holder → Bootstrap Token escrow → FileVault profile → key escrow):**
1. **SecureToken holder.** On the Mac: `sysadminctl -secureTokenStatus theusername` for the affected user
   and the first admin. A user with **ENABLED** SecureToken can be a FileVault user; a user with
   **DISABLED** cannot enable/unlock FileVault.
2. **Bootstrap Token escrowed.** `profiles status -type bootstraptoken` shows whether the Bootstrap
   Token is escrowed to the MDM. Modern Apple-silicon FileVault relies on the Bootstrap Token; if it
   was never escrowed, MDM-driven enablement and additional-user grants fail.
3. **FileVault profile state.** Intune → device → **Device configuration**; the FileVault
   (Endpoint security → Disk encryption) policy shows **Succeeded**. Run
   `MACDX-Validation.ps1 -Check FileVault`.
4. **Recovery key escrowed.** Intune → device → **Recovery keys** shows a stored **personal recovery
   key**. `MACDX-Report.ps1` includes an escrow-coverage count across the fleet. `fdesetup status`
   on the Mac shows whether FileVault is On.

**Fix:**
- User lacks SecureToken → grant it from a SecureToken-holder admin:
  `sysadminctl -secureTokenOn theusername -password userpassword -adminUser adminname -adminPassword adminpassword`
  (run on the Mac; substitute the real account names and passwords).
- Bootstrap Token not escrowed → `sudo profiles install -type bootstraptoken` (or re-enroll) to
  escrow it; confirm with `profiles status -type bootstraptoken`.
- FileVault profile in Error → fix the assignment/settings and re-deploy; ensure the target account
  holds SecureToken first.
- Key not escrowed → rotate/re-escrow the personal recovery key via the FileVault policy; confirm it
  appears under **Recovery keys**.

**Confirm:** `fdesetup status` shows FileVault On for the intended user, the recovery key is visible
under **Recovery keys** in Intune, and the user unlocks the disk at boot. Re-run
`MACDX-Validation.ps1 -Check FileVault`.

---

## Branch D — Compliant but denied
**Tell:** Intune shows the Mac **Compliant**, yet the user is blocked from a resource (M365, etc.).
**Diagnose top-down (compliance signal → Entra sign-in log → Conditional Access policy):**
1. **Compliance is real and current.** Intune → device → **Compliance**; the policy shows
   **Compliant** with a recent evaluation. Run `MACDX-Validation.ps1 -Check Compliance` — it names any
   non-compliant setting. A device that flipped compliant seconds ago may not have propagated yet.
2. **Read the actual block.** Entra → **Sign-in logs** → filter to the user and the time of the block
   → open the failed sign-in → **Conditional Access** tab. It names the **policy** that applied and
   the **grant control** that failed (e.g. *Require device to be marked as compliant*, *Require
   approved app*, *Require hybrid Entra join*).
3. **Device identity match.** Confirm the device Entra ID in the sign-in log matches the compliant
   Intune device — a second/duplicate device record, or a browser not using the SSO extension, can
   present as a *different* (non-compliant/unknown) device to CA.

**Fix:**
- Signal lag → wait for propagation, or force a device **Sync** (`MACDX-Remediation.ps1 -Action Sync`,
  `-WhatIf` by default) and re-test after check-in.
- CA grant the Mac can't meet → adjust the policy scope/exclusion or give the Mac the required state
  (e.g. ensure the SSO extension is delivering device compliance to the browser — Branch B).
- Duplicate/stale device object → reconcile the duplicate Entra device record so CA evaluates the
  compliant one.

**Confirm:** The same sign-in now shows **Success** with the CA policy **Satisfied** in Entra
Sign-in logs.

---

## Branch E — User locked out after enrollment
**Tell:** Enrollment succeeded, but the user can't log in, is prompted for an unknown password, or the
local account is out of sync with Entra.
**Diagnose top-down (account model → Platform SSO binding → FileVault account → password sync):**
1. **Which account model.** Determine whether the Mac uses **Platform SSO** account binding (local
   account linked to Entra), a **mobile account**, or a plain local admin. `app-sso platform -s` and
   `dscl . -read /Users/theusername` show the account state.
2. **Platform SSO binding health.** If Platform SSO is in use, confirm the extension is registered and
   the user completed sign-in (Branch B) — a half-bound account can reject the Entra password locally.
3. **FileVault account match.** If FileVault is On, the login/unlock account must be a
   SecureToken-holding, FileVault-enabled user (Branch C). A user who isn't FileVault-enabled can't
   unlock at boot even with the right password.
4. **Password sync.** With Platform SSO password mode, a recent Entra password change must sync; the
   user may need to sign in with the **previous** local password once, then the extension syncs.

**Fix:**
- Half-bound Platform SSO → re-register via Company Portal; `sudo profiles renew` and re-run sign-in.
- FileVault account mismatch → grant SecureToken and add the user to FileVault (Branch C).
- Password out of sync → follow the Platform SSO password-sync path (sign in local, let it sync); as a
  last resort an admin resets the local password from a SecureToken holder.
- No admin available on the box → use the escrowed **personal recovery key** (Intune → **Recovery
  keys**) to unlock, then repair the account.

**Confirm:** The user logs in and unlocks the disk with their Entra credential (or synced password),
and `app-sso platform -s` shows a healthy registered state.

---

## Step 9 — Record the resolution
Capture the symptom class, the failing layer, the signal you read, the root cause, and the fix in
your runbook log (name it `macOS Failure Log – <Site> – Runbook`). This is what makes the next
ticket minutes instead of hours.

## Step 10 — Validate and expand
1. Run the full loop on **at least two** distinct real failures (ideally different branches); confirm
   each was isolated to the correct layer and resolved. Complete the **Testing Guide** (§5).
2. Save the scripts, the recorded resolutions, and the on-Mac command cheat-sheet where the team
   works. Make this the standard triage path for macOS tickets; re-validate as macOS versions and the
   SSO method change.

---
### Order of operations
`Classify symptom → confirm layer above (top-down) → read the layer's signal → apply branch fix →
re-check the signal → record → validate on real failures → expand`
