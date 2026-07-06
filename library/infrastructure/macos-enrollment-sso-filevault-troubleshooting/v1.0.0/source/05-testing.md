# 5. Testing Guide — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

Run these after you have read access set up and have piloted the playbook on a real failure
(Diagnostic Playbook §3). These tests prove the toolkit actually isolates and resolves the failing
layer — not that the doc reads well. Each test maps to a symptom branch.

## Test 1 — Device context is visible (Discovery)
**Do:** Run `MACDX-Discovery.ps1` (optionally `-DeviceName device-name-or-serial`).
**Expected:** The macOS device is listed with enrollment state, ownership, compliance, OS build, and
last check-in — read-only, with no attempt to change the tenant. PASS if it connects with the read
scopes and lists devices; FAIL if sign-in or scopes are missing.

## Test 2 — Enrollment / ADE state (Branch A)
**Do:** Run `MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check Enrollment`; cross-check
Intune → **Devices → Enrollment → Enrollment program tokens**.
**Expected:** The script reports the enrollment token's expiry and whether a default profile is set,
consistent with the portal; a stuck device is shown as not-enrolled with the reason class visible.

## Test 3 — SSO extension state (Branch B)
**Do:** Run `MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check Profiles`; on the Mac run
`app-sso platform -s`.
**Expected:** The SSO app-extension profile state (`Succeeded`/`Error`/`Conflict`) matches the portal,
and the on-Mac registration state agrees. A failing SSO device shows the profile not `Succeeded` or
the extension not registered.

## Test 4 — SecureToken / FileVault state (Branch C)
**Do:** Run `MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check FileVault`; on the Mac run
`sysadminctl -secureTokenStatus theusername` and `fdesetup status`.
**Expected:** The FileVault profile state and recovery-key escrow reported by the script match Intune
→ device → **Recovery keys**; the on-Mac SecureToken/FileVault status agrees. A failing device shows
no escrowed key or a SecureToken-DISABLED account.

## Test 5 — Compliance / Conditional Access (Branch D)
**Do:** Run `MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check Compliance`; open Entra →
**Sign-in logs → Conditional Access** for the blocked sign-in.
**Expected:** The script names any non-compliant setting; the sign-in log names the CA policy and the
grant control that denied. A "compliant but denied" case shows Compliant in Intune yet a failed CA
grant in Entra.

## Test 6 — Fleet report and escrow coverage
**Do:** Run `MACDX-Report.ps1`.
**Expected:** A clean summary — counts by enrollment/compliance state, stale (not-checked-in) macOS
devices, OS-version spread, and FileVault recovery-key escrow coverage — reconciling with the Intune
portal for your scope.

## Test 7 — Safe remediation preview (default -WhatIf)
**Do:** Run `MACDX-Remediation.ps1 -DeviceName device-name-or-serial -Action Sync` **without**
`-WhatIf:$false`.
**Expected:** It prints the intended safe action (device Sync) and makes **no** change (PREVIEW MODE).
Re-running with `-WhatIf:$false` on a pilot device issues the Sync and reports success.

## Test 8 — Scope targeting preview (default -WhatIf)
**Do:** Run `MACDX-Set-ScopeTargeting.ps1 -GroupName pilot-group-name -DeviceName device-name-or-serial`
**without** `-WhatIf:$false`.
**Expected:** It prints the intended group and membership change and makes **no** change. With
`-WhatIf:$false` on a pilot group it creates the group if needed and adds the device.

## Test 9 — Re-check after fix (any branch)
**Do:** After applying a branch fix, re-run the matching `MACDX-Validation.ps1 -Check ...` and the
on-Mac command for that layer.
**Expected:** The signal that was failing now reads healthy (enrolled / SSO registered / FileVault On
+ key escrowed / CA satisfied), and the symptom is gone.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Read pass** | Tests 1–6 pass read-only: device context, per-branch state, and the fleet report reconcile with the Intune portal and Entra sign-in logs |
| **Safety pass** | Tests 7–8 pass: Remediation and Set-ScopeTargeting default to `-WhatIf` and make no change until `-WhatIf:$false` |
| **Resolution pass** | Test 9 passes on **two** distinct real failures (Playbook §3, Step 10): each was isolated to the correct layer and the re-check reads healthy |
