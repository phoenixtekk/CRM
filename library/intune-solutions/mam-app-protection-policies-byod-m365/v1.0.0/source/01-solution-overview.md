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
