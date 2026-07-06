# Troubleshooting

The Runbook Library covers the common single-category cases. This guide handles the **cross-cutting
edge cases** — tasks that span two runbooks, symptoms that mimic one cause but have another, and the
failure modes of the tooling and the macOS platform itself. Use it when a ticket doesn't sit cleanly
inside one runbook.

## Symptoms that cross runbook boundaries

- **"Can't sign in to apps on my Mac" that is really SSO.** Microsoft 365 apps re-prompt for
  password/MFA. This is **Runbook 2 (SSO)**, not an app problem — check the SSO extension/Platform
  SSO payload and the sign-in log before touching the app (Runbook 3).
- **"Blocked from resources" — Conditional Access vs. compliance.** Being blocked can come from a
  non-compliant Mac (Runbook 6) *or* a Conditional Access policy (Runbook 1/2 identity paths). The
  sign-in log's Conditional Access tab names which policy applied; that decides the runbook.
- **"Non-compliant Mac" that is really FileVault or an OS version.** Compliance fails on "FileVault
  not enabled" or "minimum macOS version." Start in **Runbook 6** to name the failing setting, then
  switch to **Runbook 4** (FileVault) or deploy the macOS update, then re-evaluate compliance.
- **"FileVault won't turn on" that is really a missing bootstrap/SecureToken.** The FileVault policy
  is assigned but encryption never engages or the key never escrows. Check **SecureToken and the
  bootstrap token** (Runbook 4 C4 / Runbook 7 C3–C4) — MDM-driven FileVault needs them.
- **"App installed but broken" that is really licensing.** A VPP app shows installed but won't
  activate — check **VPP licenses and token** (Runbook 3 C1–C2) before assuming a runtime fault.

## Confusing single-symptom cases

- **Mac stuck at the FileVault unlock screen.** Do **not** improvise. Go straight to **Runbook 7 C1**
  — is the recovery key escrowed? If yes, recover with it and rotate afterward. If no, escalate; this
  is potentially unrecoverable and is never a guess-the-password exercise.
- **User can log in but can't unlock FileVault.** Classic **SecureToken missing** (Runbook 7 C3):
  the password is correct but the account has no SecureToken, so it can't unlock the encrypted disk.
- **"My Mac isn't managed."** Confirm with `profiles status -type enrollment` and **System Settings →
  Device Management** before concluding it's unenrolled — the MDM profile may be present but the Mac
  simply hasn't checked in (trigger **Sync**), or you may be searching the wrong identifier (serial
  vs. name vs. primary user — Requirement R4).
- **New Mac never offered enrollment in Setup Assistant.** ADE only triggers during Setup Assistant.
  If the Mac was already past setup, it must be **erased/reset** to re-run it (Runbook 1 gate —
  approval + backup + confirmed key) or enrolled user-driven via Company Portal (Runbook 5).
- **Repeated MFA prompts on a Mac.** Often clock skew (token validation fails when the Mac's clock is
  wrong — check date/time first), then a broken SSO registration (Runbook 2 C3), then a Conditional
  Access session policy.

## When scope changes the answer

- **One Mac vs. many.** If several Macs show the same symptom at once, stop working the single device:
  it's almost certainly **policy/targeting** (wrong or missing Entra group — use
  MACRUN-Set-ScopeTargeting to inspect) or an **expired token** (ADE or VPP — Runbook 1/3). Working
  each Mac individually will not fix a fleet-wide cause.
- **New enrollment vs. established.** A brand-new ADE enrollment failing differently from established
  Macs usually points to the ABM assignment, the ADE token, or the enrollment profile (Runbook 1),
  not the everyday support paths.
- **After a macOS major upgrade.** A symptom that appears right after a macOS release often means a
  deprecated MDM command or a changed Platform SSO/FileVault behavior — re-verify against the current
  Apple/Intune docs and re-run the Testing gates before assuming the Mac is broken.

## Tooling and script edge cases

- **`Connect-MgGraph` fails or lacks scopes.** Re-run with the explicit `-Scopes` the script header
  lists; if consent is required, an admin must grant it once (Requirement R2). `Get-MgContext`
  confirms the active scopes.
- **A script returns fewer Macs than expected.** The signed-in account's Intune **scope (groups)**
  may limit what it can read (Requirement R1). Confirm the technician's role scope includes the
  target Macs. Also confirm the filter — the scripts filter to `operatingSystem eq 'macOS'`.
- **Remediation/Set-ScopeTargeting "did nothing."** By design — both default to `-WhatIf` and only
  print the planned change. Re-run without `-WhatIf` (on a pilot first) once you've reviewed the plan.
- **Rotate FileVault key "did nothing."** With the default `-WhatIf` the Remediation script only
  previews. When run for real, allow the Mac to check in, then re-run MACRUN-Validation and confirm
  the **new** key is escrowed in Intune before considering the old one retired.
- **Portal and script disagree.** The portal can lag; trigger **Sync** on the Mac and re-run the
  read-only Validation script. Persistent disagreement is itself evidence — attach both and escalate.
- **Remote tool won't connect / can't control the Mac.** Confirm the approved remote tool is deployed
  and its macOS **Screen Recording / Accessibility (PPPC)** permissions are granted (Requirement R3),
  the user is present to consent, and the Mac has connectivity before assuming a tool fault.

## When nothing fits
If a ticket matches no runbook and no edge case above: capture the standard evidence (device
name/serial, exact symptom, scope, timestamps, any error codes, relevant `profiles`/`fdesetup`
output), run MACRUN-Discovery/Validation for state, and escalate to endpoint engineering with that
package. An unclassifiable-but-recurring ticket is a signal to add a new runbook — feed it back into
the library (see Best Practices).
