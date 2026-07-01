# 6. Troubleshooting Guide — MAM App Protection Policies for BYOD

Use `MAMAPP-Validation.ps1` for a user's protection status, `MAMAPP-Discovery.ps1` to inventory
policies and the CA grant, `MAMAPP-Report.ps1` for coverage, and `MAMAPP-Remediation.ps1` for safe
fixes.

## A. Policy not applying to the app
| Symptom | Cause | Remediation |
|---|---|---|
| App never prompts for a PIN | User not in the assigned group, or app not targeted | Confirm the user is in `MAM Users – BYOD – Pilot`; confirm the app is in the policy's app list; run `MAMAPP-Remediation.ps1` |
| Android app not protected | Company Portal (the MAM broker) not installed | Install Intune Company Portal from Google Play (broker only, no enrollment); reopen the app |
| Policy shows unlicensed | User missing Intune / Entra ID P1 | Assign licensing (Requirement 2.1); run `MAMAPP-Discovery.ps1` |

## B. Conditional Access blocks or does not enforce
| Symptom | Cause | Remediation |
|---|---|---|
| Access granted from an unmanaged app | `CA – Require APP – M365` still in Report-only | Set the policy Enable to `On`; re-test from an unmanaged app |
| Legitimate user blocked | User not covered by an App Protection Policy, or wrong platform condition | Confirm the APP is assigned and applied; check the CA Device platforms include iOS/Android; review the sign-in log Report-only tab |
| Admin locked out | Break-glass account not excluded | Exclude the two break-glass accounts from `CA – Require APP – M365` |

## C. Data-movement controls not working as expected
- Copy/paste still works to a personal app: confirm `Restrict cut, copy, and paste` is set to `Policy managed apps` (not `Any app`) and that the target is not another managed app.
- Save-as to a personal location succeeds: confirm `Save copies of org data` is `Block` with only OneDrive/SharePoint allowed, and that the app has re-checked in after the policy change.

## D. PIN and access issues
- User forgot the app PIN: max attempts triggers a PIN reset (or wipe) per conditional launch; the user re-creates the PIN on next launch.
- Access blocked after travel: the offline grace period elapsed — reconnect to network and sign in to re-evaluate the policy.

## E. Selective wipe did not complete
- Wipe pending: the wipe runs the next time the app connects with the work identity. Have the user open the app online; check Intune → Apps → App selective wipe for status.
- Personal data appears removed: on BYOD, only corporate data should be wiped — confirm you issued an app selective wipe, not a device wipe.

## F. Diagnostics quick reference
Run `MAMAPP-Discovery.ps1` (inventory of iOS/Android App Protection Policies, App Configuration
policies, and the CA app-protection grant) and `MAMAPP-Report.ps1` (per-user/app coverage plus CA
grant state). On the device, the app's in-app "About / managed by your organization" screen shows
whether a protection policy is applied. In Entra, the sign-in log Report-only / Applied tab shows
which CA policies evaluated for a given sign-in.

## G. When to escalate
If the App Protection Policy is assigned and applied, the user is licensed, Company Portal is present
(Android), the CA grant is enabled with break-glass excluded, and access still behaves incorrectly
after the app checks in, capture the Intune app-protection status, the CA sign-in log entry, and the
app/OS versions, and open a Microsoft support case.
