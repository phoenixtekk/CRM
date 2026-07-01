# 5. Testing Guide — MAM App Protection Policies for BYOD

Run after the pilot policies apply (Implementation Step 6) and after each expansion wave. Use a
real, unenrolled personal device where possible.

## Test 1 — Policy assigned and applied
Do: Intune → Apps → App protection policies → `BYOD – App Protection – iOS` (and Android) → Monitor / check-in status; or run `MAMAPP-Report.ps1`.
Expected: Pilot users show the policy applied (checked-in) for the targeted apps.

## Test 2 — App PIN enforced
Do: On an unenrolled device, open Outlook with the work account.
Expected: The app prompts to set an app PIN (or biometric) before showing org data.

## Test 3 — Copy/paste restricted
Do: Copy text from Outlook/Teams and try to paste into a personal app (for example, personal Notes).
Expected: The paste is blocked (or empty), per the "policy managed apps" cut/copy/paste setting.

## Test 4 — Save-as restricted
Do: Open an attachment and try Save / Share to a personal location (camera roll, personal cloud).
Expected: Save-as to personal locations is blocked; only OneDrive/SharePoint are allowed.

## Test 5 — Jailbreak/root block
Do: (If available) sign in from a jailbroken iOS or rooted Android device, or review the conditional-launch setting.
Expected: Access is blocked on a compromised device per the conditional-launch rule.

## Test 6 — Conditional Access enforces protected app
Do: Try to reach Office 365 from an unmanaged app (one without the policy) on the pilot account after Step 7 enable.
Expected: `CA – Require APP – M365` blocks the sign-in; access is granted only from a protected app.

## Test 7 — Selective wipe (corporate data only)
Do: Intune → Apps → App selective wipe → Create wipe request for a pilot user/device; then reopen the app.
Expected: Corporate data is removed from the apps; the user's personal data is untouched.

## Test 8 — Coverage and enforcement report
Do: Run `MAMAPP-Report.ps1`.
Expected: A clear per-user/app protection-status list plus confirmation the CA grant is enabled and scoped.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-5 and 7 pass on an unenrolled device; Test 6 passes once CA is enabled |
| Production pass | Tests 1-4, 6, 8 pass for the production group before declaring rollout complete |
