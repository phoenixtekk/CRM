# Mobile Application Management (MAM) App Protection Policies for BYOD (Microsoft 365 Apps)

> **Version 1.0.0** · Category: Intune · Solution code: MAMAPP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Mobile Application Management (MAM) App Protection Policies for BYOD (Microsoft 365 Apps)

Employees want Outlook, Teams, SharePoint, and OneDrive on their own phones — and the business
needs that corporate data protected. Enrolling personal devices into full mobile device management
(MDM) is intrusive, slows adoption, and raises privacy concerns. Mobile Application Management (MAM)
with App Protection Policies solves this: it protects corporate data inside the Microsoft 365 apps —
encryption, cut/copy/paste and save-as limits, an app PIN, jailbreak/root blocking, and selective
wipe of corporate data only — on unenrolled, personal devices, without touching the rest of the phone.

This is a complete, deploy-it-today package for standing up App Protection Policies for BYOD in
Microsoft Intune and enforcing them with Conditional Access, written for an administrator with no
prior MAM experience.

## What you get
- A plain-language Solution Overview of MAM-without-enrollment, the data-protection controls, app
  configuration, and how Conditional Access enforces "require app protection policy".
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click Intune and Entra steps in the required order.
- Five PowerShell scripts for App Protection Policy discovery, per-user protection-status validation,
  a coverage and enforcement report, safe remediation of gaps, and a MAM scope-group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
App Protection Policies for iOS and Android that encrypt corporate data in the Microsoft 365 apps,
restrict data movement (copy/paste, save-as, "open in"), require an app PIN, block compromised
devices, and allow a selective wipe that removes corporate data while leaving personal data intact —
all enforced by a Conditional Access grant that requires an app protection policy, and all without
enrolling the device.

## The deployment model
Assess to Configure to Pilot to Validate to Expand.

## Outcome
Corporate data protected inside the Microsoft 365 apps on personal phones — encryption, data-movement
limits, PIN, and selective wipe, enforced by Conditional Access, with no full-device enrollment —
proven on a pilot before you scale.


---


# 1. Solution Overview — Mobile Application Management (MAM) App Protection Policies for BYOD

## What MAM App Protection Policies are
Mobile Application Management (MAM) is a way to protect corporate data inside individual mobile apps
without managing the whole device. App Protection Policies (APP) are the Intune feature that carries
those protections. Because they work on unenrolled devices — a model called MAM-without-enrollment —
you protect the data in Outlook, Teams, SharePoint, OneDrive, and Edge on an employee's personal
phone without ever enrolling that phone into mobile device management (MDM).

This is deliberately different from device enrollment (COD / BYOD MDM). Enrollment manages the whole
device (settings, apps, compliance). MAM manages only the corporate data inside supported apps. On a
personal (BYOD) phone, MAM is the lighter, privacy-respecting choice: IT never sees personal photos,
messages, or apps, and can only wipe the corporate data it placed there.

## How it works
1. An App Protection Policy is created for a platform (one for iOS/iPadOS, one for Android) and
   scoped to the Microsoft 365 apps the policy protects.
2. The policy is assigned to a user group. When a user signs in to a targeted app with their work
   account, the app enforces the policy on the corporate identity only.
3. Data-protection settings encrypt org data and restrict how it moves: cut/copy/paste to
   unmanaged apps, save-as to personal locations, and "open in / share" are limited to managed apps.
4. Access settings require an app PIN (or biometric), block jailbroken/rooted devices, set an
   offline grace period, and can require a minimum OS/app version.
5. An App Configuration Policy (for managed apps) pushes app settings — for example, requiring data
   to be saved only to OneDrive/SharePoint, or configuring the Edge managed browser.
6. A Conditional Access grant of "Require app protection policy" ensures the corporate resources are
   reachable only from an app that has a protection policy applied — so the protection cannot be
   bypassed by using an unmanaged app.
7. When someone leaves or a phone is lost, a selective wipe removes only the corporate data from the
   apps, leaving the user's personal data untouched.

## What you can control
- Encryption of org data at rest inside the app.
- Cut/copy/paste, save-as, and "open in / share" restrictions between managed and unmanaged apps.
- App-level PIN or biometric, PIN complexity, and PIN retry/reset behavior.
- Block on jailbroken (iOS) / rooted (Android) devices; minimum OS and app versions.
- Offline grace period before access is blocked or corporate data is wiped.
- Managed browser (Edge) and "save copies of org data" location controls (via app configuration).
- Selective wipe of corporate data only, on demand.

## Benefits
- Data protection without device management — the corporate data is protected; the personal phone is not managed.
- Privacy for the employee — IT cannot see or wipe personal data, which speeds BYOD adoption.
- Enforced, not optional — a Conditional Access grant blocks access from apps without the policy.
- Selective wipe — offboarding or a lost phone removes only corporate data.
- Repeatable — assign the policies once to a group; new users inherit protection automatically.

## Limitations (be honest with buyers)
- MAM protects data inside supported apps (the Microsoft 365 apps and other MAM-enabled apps). It
  does not protect data in apps that do not support App Protection Policies.
- A user can still take a photo of the screen; MAM reduces data leakage, it does not make it impossible.
- Enforcing "Require app protection policy" through Conditional Access requires Entra ID P1.
- Some deep controls (for example, requiring device-level compliance) need enrollment; MAM alone
  does not manage the device.
- Personal and work accounts in the same app are handled per-identity; only the work identity is protected.

## The standard deployment model
> Create iOS + Android App Protection Policies, add an App Configuration Policy, enforce with a
> Conditional Access "Require app protection policy" grant, validate on an unenrolled BYOD device,
> then pilot and expand. Pattern: Assess to Configure to Pilot to Validate to Expand.


---


# 2. Requirements Guide — MAM App Protection Policies for BYOD

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

The objects this solution creates (name them exactly, reuse verbatim throughout):
- Group `MAM Users – BYOD – Pilot` — the pilot user group.
- Group `MAM Users – BYOD – Production` — the broad user group.
- Policy `BYOD – App Protection – iOS` — the iOS/iPadOS App Protection Policy.
- Policy `BYOD – App Protection – Android` — the Android App Protection Policy.
- Policy `BYOD – App Config – M365` — the App Configuration Policy for managed apps.
- Policy `CA – Require APP – M365` — the Conditional Access grant enforcing app protection.

## 2.1 Licensing (Intune + Entra ID P1)
Description: An Intune plan for App Protection Policies, plus Entra ID P1 for Conditional Access.
Why: Intune delivers the App Protection and App Configuration policies; Conditional Access (P1)
enforces "Require app protection policy".
Verify: M365 admin center → Billing → Licenses; confirm Intune and Entra ID P1 (both in M365 E3/E5 and Business Premium).
Implement: Assign M365 E3/E5 or Business Premium (Intune + Entra ID P1 included) to targeted users.

## 2.2 Target users licensed and in scope
Description: The BYOD users who will get the policies are licensed and known.
Why: App Protection Policies are assigned to user groups, not devices.
Verify: Run `MAMAPP-Discovery.ps1`; confirm users hold Intune + Entra ID P1.
Implement: Assign licensing; add users to the scope groups (see 2.6).

## 2.3 Microsoft 365 mobile apps available
Description: The Microsoft 365 apps (Outlook, Teams, SharePoint, OneDrive, Edge) are installable on iOS and Android.
Why: App Protection Policies protect data inside these managed apps; the user must install them from the store.
Verify: The apps are available in the Apple App Store / managed Google Play for your users.
Implement: Publish the apps as available assignments in Intune (Apps → iOS/Android), or let users install them from the store.

## 2.4 Apple / Android platform prerequisites
Description: iOS/iPadOS uses the app directly; Android uses the Company Portal app as a broker (no enrollment).
Why: On Android, MAM-without-enrollment requires the Intune Company Portal app to be installed as the policy broker — but the device is not enrolled.
Verify: On a test Android device, the Company Portal app is installed (users are not prompted to enroll).
Implement: Instruct Android users to install Intune Company Portal from Google Play; it brokers MAM only.

## 2.5 Conditional Access ready (Entra ID)
Description: Conditional Access is available and a break-glass account is excluded from CA policies.
Why: The "Require app protection policy" grant is a Conditional Access policy; break-glass accounts prevent lockout.
Verify: entra.microsoft.com → Protection → Conditional Access loads; two break-glass Global Administrator accounts exist.
Implement: Confirm Entra ID P1; create two cloud-only break-glass Global Administrators to exclude from every CA policy.

## 2.6 Scope groups (Pilot + Production)
Description: Entra security groups `MAM Users – BYOD – Pilot` and `MAM Users – BYOD – Production`.
Why: Every rollout is piloted before production; policies assign to these groups.
Verify: Entra → Groups; both groups exist. Run `MAMAPP-Set-ScopeTargeting.ps1 -WhatIf` to preview.
Implement: Create the two groups (or run `MAMAPP-Set-ScopeTargeting.ps1` to create/populate them).

## 2.7 Admin roles
Description: Intune Administrator (for APP/app config) and Conditional Access Administrator (for the CA grant).
Why: Creating these policies requires the appropriate elevated roles.
Verify: Entra → Roles and administrators; confirm the operator holds the roles.
Implement: Assign Intune Administrator and Conditional Access Administrator; reserve Global Administrator for tenant-wide changes.

---
## Checklist
- [ ] Intune + Entra ID P1 licensing assigned
- [ ] Target users licensed and in scope — `MAMAPP-Discovery.ps1`
- [ ] Microsoft 365 mobile apps available to users
- [ ] Android users have Company Portal installed (broker, no enrollment)
- [ ] Conditional Access available; break-glass accounts excluded
- [ ] `MAM Users – BYOD – Pilot` and `MAM Users – BYOD – Production` groups created
- [ ] Intune Administrator + Conditional Access Administrator roles assigned


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** Phoenixtekk solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every Phoenixtekk solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The Phoenixtekk deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — MAM App Protection Policies for BYOD

Follow these steps in order. App Protection and App Configuration policies are in the Microsoft
Intune admin center (`https://intune.microsoft.com` → Apps). The Conditional Access grant is in
Microsoft Entra (`https://entra.microsoft.com` → Conditional Access).

> Model: Create iOS + Android App Protection Policies, add an App Configuration Policy, enforce with a
> Conditional Access "Require app protection policy" grant, validate on an unenrolled BYOD device,
> then pilot and expand.

Reuse these object names exactly: `MAM Users – BYOD – Pilot`, `MAM Users – BYOD – Production`,
`BYOD – App Protection – iOS`, `BYOD – App Protection – Android`, `BYOD – App Config – M365`,
`CA – Require APP – M365`.

## Step 1 — Create the scope groups
1. Entra → Groups → New group → Security → `MAM Users – BYOD – Pilot` (a few representative BYOD users). Create.
2. Create `MAM Users – BYOD – Production` (the rest of the BYOD population). Create.

## Step 2 — Create the iOS App Protection Policy
1. Intune → Apps → App protection policies → Create policy → iOS/iPadOS.
2. Name: `BYOD – App Protection – iOS`. Next.
3. Apps: Target policy to `Selected apps` (or `All Microsoft apps`). Add Outlook, Teams, SharePoint, OneDrive, and Edge. Next.
4. Data protection:
   - Backup org data to iTunes and iCloud backups: `Block`.
   - Send org data to other apps: `Policy managed apps` (limits "open in / share").
   - Receive data from other apps: `Policy managed apps`.
   - Restrict cut, copy, and paste between other apps: `Policy managed apps with paste in`.
   - Save copies of org data: `Block`, then allow only `OneDrive for Business` and `SharePoint` under `Allow user to save copies to selected services`.
   - Encrypt org data: `Require`.
5. Access requirements:
   - PIN for access: `Require`; PIN type and length per your policy; allow biometric as an alternative.
   - Recheck the access requirements after (minutes of inactivity): `30`.
   - Offline grace period: `720` minutes to block access; `90` days to wipe org data.
   - Next.
6. Conditional launch:
   - Jailbroken/rooted devices: `Block access`.
   - Min OS version and min app version: set per your standard (action `Warn` or `Block`).
   - Max PIN attempts: `5` → action `Reset PIN` (or `Wipe data`).
   - Next.
7. Assignments → Included groups → `MAM Users – BYOD – Pilot`. Next → Create.

## Step 3 — Create the Android App Protection Policy
1. Intune → Apps → App protection policies → Create policy → Android.
2. Name: `BYOD – App Protection – Android`. Next.
3. Apps: add the same set — Outlook, Teams, SharePoint, OneDrive, and Edge. Next.
4. Data protection: match Step 2's settings (block backup, policy-managed transfer, block save-as except OneDrive/SharePoint, require encryption). Also set `Screen capture and Google Assistant` to `Block` if required. Next.
5. Access requirements: require an app PIN (allow biometric), recheck after `30` minutes, offline grace `720` minutes to block / `90` days to wipe. Next.
6. Conditional launch: rooted devices → `Block access`; set min OS / min app version and min patch level; max PIN attempts `5` → `Reset PIN`. Set `Device attestation` (SafetyNet / Play Integrity) to `Require` if your standard needs it. Next.
7. Assignments → Included groups → `MAM Users – BYOD – Pilot`. Next → Create.

## Step 4 — Create the App Configuration Policy (managed apps)
1. Intune → Apps → App configuration policies → Add → Managed apps.
2. Name: `BYOD – App Config – M365`. Next.
3. Public apps: select the same Microsoft 365 apps (iOS and Android). Next.
4. Settings: add managed-app configuration keys per your standard — for example, set the default save location to OneDrive/SharePoint, and configure the Edge managed browser (require org sign-in, restrict which sites open outside the managed browser). Next.
5. Assignments → Included groups → `MAM Users – BYOD – Pilot`. Next → Create.

## Step 5 — Enforce with Conditional Access (require app protection policy)
1. Entra → Conditional Access → Create new policy.
2. Name: `CA – Require APP – M365`.
3. Users: Include `MAM Users – BYOD – Pilot`; Exclude the two break-glass accounts.
4. Target resources: Cloud apps → Office 365.
5. Conditions → Device platforms → Include `iOS` and `Android`.
6. Grant: Grant access → select `Require app protection policy` and `Require approved client app`; choose `Require one of the selected controls` (so either satisfies on platforms that support one).
7. Enable policy: `Report-only`. Create.

## Step 6 — Validate on an unenrolled BYOD device
1. On a personal (unenrolled) iPhone or Android, install the Microsoft 365 apps (and Company Portal on Android — for MAM brokering only; do not enroll).
2. Sign in to Outlook with the pilot work account. The app should apply the policy: prompt to set an app PIN and show the "managed by your organization" data-protection behavior.
3. Try to copy org text into a personal app — the paste should be blocked; try to save an attachment to a personal location — save-as should be blocked (OneDrive/SharePoint allowed).
4. Run `MAMAPP-Validation.ps1` to confirm the user's apps report a protection policy applied.

## Step 7 — Validate the pilot and enable enforcement
1. Run `MAMAPP-Report.ps1` to confirm coverage (which pilot users/apps have the policy) and the CA grant status.
2. In Entra → Sign-in logs, open a pilot sign-in → Report-only tab and confirm `CA – Require APP – M365` would apply and grant only from a protected app.
3. Complete the Testing Guide. When clean, edit `CA – Require APP – M365` → Enable policy → `On`.

## Step 8 — Expand to production
1. Add `MAM Users – BYOD – Production` to the Included groups of `BYOD – App Protection – iOS`, `BYOD – App Protection – Android`, `BYOD – App Config – M365`, and `CA – Require APP – M365`.
2. Roll out in waves; monitor sign-in logs and run `MAMAPP-Report.ps1` each wave.
3. Re-validate with `MAMAPP-Validation.ps1`; remediate gaps with `MAMAPP-Remediation.ps1`.

---
### Order of operations
`Scope groups → iOS APP → Android APP → App config → CA grant (Report-only) → Validate on BYOD → Enable → Expand`


---


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


---


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


---


# 7. Best Practices — MAM App Protection Policies for BYOD

- Pilot first, always. Assign to `MAM Users – BYOD – Pilot` and validate on a real unenrolled device before touching production — the single most important practice.
- Enforce with Conditional Access. App Protection Policies protect data, but only `CA – Require APP – M365` guarantees corporate resources are reachable only from a protected app. Deploy both.
- Start Conditional Access in Report-only. Review sign-in impact before flipping `CA – Require APP – M365` to On, and always exclude break-glass accounts.
- Keep iOS and Android policies in sync. Mirror the same data-protection and access settings across `BYOD – App Protection – iOS` and `BYOD – App Protection – Android` so behavior is consistent.
- Limit save-as to org locations. Block save-as except OneDrive/SharePoint so corporate data does not land in personal cloud or the camera roll.
- Require an app PIN and encryption. These are the baseline that makes a lost phone a non-event for corporate data.
- Set a sensible offline grace period. Balance security and usability — too short frustrates travelers; too long weakens the wipe guarantee.
- Prefer selective wipe over device wipe on BYOD. Remove corporate data only; never wipe an employee's personal phone. Communicate this clearly to build trust and adoption.
- Respect privacy to speed adoption. Tell users MAM cannot see or wipe personal data — this is the message that gets BYOD accepted.
- Assign to groups, not users. Add new BYOD users to the scope groups; they inherit protection automatically.
- Watch coverage. Track which users/apps report a policy with `MAMAPP-Report.ps1` and chase the gaps.
- Document the settings. Record the data-protection and access values, the app list, and the CA grant for audits and repeatability.


---


# 8. Deliverables Summary — MAM App Protection Policies for BYOD

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What MAM/APP is, MAM-without-enrollment, data-protection controls, app config, CA enforcement, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune + Entra steps (iOS/Android APP, app config, CA grant) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MAMAPP-Discovery.ps1` | Inventories existing App Protection / App Configuration policies and CA app-protection grants (Microsoft Graph) |
| `MAMAPP-Validation.ps1` | Confirms a user's targeted apps report an App Protection Policy applied (Microsoft Graph) |
| `MAMAPP-Report.ps1` | Coverage and enforcement report — per-user/app protection status plus the CA grant state (read-only) |
| `MAMAPP-Remediation.ps1` | Safe remediation of gaps — assigns missing policies to the scope group (default -WhatIf) |
| `MAMAPP-Set-ScopeTargeting.ps1` | Creates/populates the `MAM Users – BYOD – Pilot` and `MAM Users – BYOD – Production` groups and previews assignment |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Corporate data protected inside the Microsoft 365 apps on personal phones — encryption, data-movement
limits, PIN, and selective wipe, enforced by Conditional Access, with no full-device enrollment.
