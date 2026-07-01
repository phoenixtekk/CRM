# 5. Testing Guide — Azure Virtual Desktop Remote Access

Run after the pilot is configured (Implementation Step 10) and after each expansion.

## Test 1 — Host pool and session hosts healthy
**Do:** `portal.azure.com` → **Azure Virtual Desktop → Host pools →** `AVD – Host Pool – Pilot` **→ Session hosts**; or run `AVD-Validation.ps1`.
**Expected:** The `avdsh-` session hosts show **Available** with status **OK**.

## Test 2 — Workspace and Desktop published
**Do:** **Azure Virtual Desktop → Workspaces →** `AVD – Workspace – Core` **→ Application groups**.
**Expected:** `AVD – App Group – Desktop` is registered, and the pilot group `AVD – Users – Pilot` is assigned to it.

## Test 3 — Windows client connects
**Do:** On a Windows pilot device, subscribe in the Windows App / Remote Desktop client and launch the Desktop as a pilot user.
**Expected:** `AVD – Workspace – Core` appears; the Desktop launches to a full Windows session.

## Test 4 — macOS client connects
**Do:** On a Mac pilot device, add the workspace in the Windows App / Microsoft Remote Desktop and launch the Desktop as a pilot user.
**Expected:** The same workspace and Desktop appear and launch from macOS, matching the Windows experience.

## Test 5 — Conditional Access enforces MFA
**Do:** Sign in from either client as a pilot user covered by `AVD – Conditional Access – MFA`.
**Expected:** The user is prompted for multifactor authentication before the session opens; the break-glass account is unaffected.

## Test 6 — FSLogix profile roams
**Do:** Sign in to the pooled Desktop, create a file on the desktop, sign out, sign in again (landing on any `avdsh-` host).
**Expected:** A profile container exists on `AVD – FSLogix Share – Core`, and the file and settings persist across sessions.

## Test 7 — Usage and assignment report
**Do:** Run `AVD-Report.ps1`.
**Expected:** A clear list of host pools, application groups, assigned groups, and active/recent user sessions.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass — both clients connect, MFA is enforced, and the profile roams |
| **Production pass** | Tests 1–3, 5, 7 pass for the production audience before broad rollout |
