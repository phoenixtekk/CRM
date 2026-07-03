# 6. Troubleshooting Guide — MAM App Protection Policies for BYOD (Government / GCC High)

Use **`MAMAPPG-Validation.ps1`** for a user's protection status, **`MAMAPPG-Discovery.ps1`** to
inventory policies and confirm the cloud, **`MAMAPPG-Report.ps1`** for coverage, and
**`MAMAPPG-Remediation.ps1`** for safe fixes. All scripts connect to **US Gov Graph**
(`-Environment USGov`).

## A. Wrong cloud (the #1 GCC High issue)
| Symptom | Cause | Remediation |
|---|---|---|
| Scripts return nothing / errors, or show `graph.microsoft.com` | Connected to the Commercial cloud, not US Gov | Reconnect with **`Connect-MgGraph -Environment USGov`**; re-run `MAMAPPG-Discovery.ps1` and confirm environment = **USGov** |
| Portal changes have no effect | You edited `intune.microsoft.com` / `entra.microsoft.com` (Commercial) | Use the **`*.us`** portals: `intune.microsoft.us`, `entra.microsoft.us` |
| Sign-in behaves oddly | App pointed at `login.microsoftonline.com` | GCC High auth is **`login.microsoftonline.us`** — verify the account/tenant is `.onmicrosoft.us` |

## B. Policy not applying to the app
| Symptom | Cause | Remediation |
|---|---|---|
| App never prompts for a PIN | User not in the assigned group, or app not targeted | Confirm the user is in `MAM Users - BYOD - Pilot`; confirm the app is in the policy's app list; run `MAMAPPG-Remediation.ps1` |
| **Android** app not protected | **Company Portal** (the MAM broker) not installed | Install Intune Company Portal from Google Play (broker only, no enrollment — GCC High endpoint `portal.manage.microsoft.us`); reopen the app |
| **iOS** app not protected | **Microsoft Authenticator** broker not installed | Install Authenticator; reopen the app and sign in with the work account |
| Policy shows unlicensed | User missing Intune / Entra ID P1 (Gov) | Assign Government licensing (Requirement 2.2); run `MAMAPPG-Discovery.ps1` |

## C. Conditional Access blocks or does not enforce
| Symptom | Cause | Remediation |
|---|---|---|
| Access granted from an unmanaged app | `CA - Require APP - M365 (Gov)` still in Report-only | Set the policy **Enable → On** in `entra.microsoft.us`; re-test from an unmanaged app |
| Legitimate user blocked | User not covered by an App Protection Policy, or wrong platform condition | Confirm the APP is assigned and applied; check the CA **Device platforms** include iOS/Android; review the sign-in log Report-only tab |
| Admin locked out | Break-glass account not excluded | Exclude the two break-glass `.onmicrosoft.us` accounts from `CA - Require APP - M365 (Gov)` |

## D. Data-movement controls not working as expected
- Copy/paste still works to a personal app: confirm **Restrict cut, copy, and paste** is
  **Policy managed apps** (not **Any app**) and the target is not another managed app.
- Save-as to a personal location succeeds: confirm **Save copies of org data** is **Block** with only
  OneDrive/SharePoint allowed, and that the app has re-checked in after the policy change.

## E. PIN and access issues
- User forgot the app PIN: max attempts triggers a PIN reset (or wipe) per conditional launch; the
  user re-creates the PIN on next launch.
- Access blocked after travel: the offline grace period elapsed — reconnect to network and sign in
  (via `login.microsoftonline.us`) to re-evaluate the policy.

## F. Selective wipe did not complete
- Wipe pending: the wipe runs the next time the app connects with the work identity. Have the user
  open the app online; check `intune.microsoft.us` → **Apps → App selective wipe** for status.
- Personal data appears removed: on BYOD, only corporate data should be wiped — confirm you issued an
  **app selective wipe**, not a device wipe.

## G. GCC-High-specific gotchas
- **A feature works in Commercial but is missing here.** New MAM features generally reach GCC High
  weeks–months later; some (quiet time policies) are not supported in sovereign clouds at all, and
  some Outlook mobile extras (location services, Play My Emails, To Do) are not FedRAMP-approved for
  US Gov. **Verify for GCC High** before relying on it. See `gcc-high-parity-notes.md`.
- **An MTD connector is absent.** Only MTD vendors that also support GCC High appear; a Commercial
  connector may not exist in your Gov tenant.

## H. Diagnostics quick reference
Run **`MAMAPPG-Discovery.ps1`** (confirms USGov, inventories iOS/Android App Protection policies, App
Configuration policies, and the CA app-protection grant) and **`MAMAPPG-Report.ps1`** (per-policy
coverage plus CA grant state). On the device, the app's in-app "About / managed by your organization"
screen shows whether a protection policy is applied. In `entra.microsoft.us`, the sign-in log
Report-only / Applied tab shows which CA policies evaluated for a given sign-in.

## I. When to escalate
If the App Protection Policy is assigned and applied, the user is licensed, the broker is present
(Company Portal on Android / Authenticator on iOS), the scripts confirm the **USGov** cloud, the CA
grant is enabled with break-glass excluded, and access still behaves incorrectly after the app checks
in, capture the Intune app-protection status, the CA sign-in log entry, and the app/OS versions, and
open a Microsoft support case against the **GCC High** tenant.
