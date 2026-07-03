# 5. Testing Guide — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

Every test has an explicit **pass/fail gate**. Run these on the **GCC High** portals
(`intune.microsoft.us`, `entra.microsoft.us`) and on real iOS/Android test devices signed in with
`login.microsoftonline.us`. Where a script is named, it connects to **US Gov Graph**
(`-Environment USGov`).

## T0. Sovereign-cloud check (do this first)
**Steps:** Confirm you are administering the correct cloud.
**Pass:** Portals are `*.us`; the SharePoint test site is `https://<tenant>.sharepoint.us`;
`SPMAMG-Discovery.ps1` reports it connected to **`graph.microsoft.us`**.
**Fail:** Any `.com` portal or `graph.microsoft.com` — you are in Commercial; stop and switch.

## T1. App Protection Policies exist and target the right apps
**Steps:** `intune.microsoft.us` → **Apps → App protection policies**. Confirm
**`APP-SPO-iOS-Enterprise`** and **`APP-SPO-Android-Enterprise`** exist and target SharePoint,
OneDrive, Office/M365, Edge, Teams, Outlook.
**Pass:** Both policies present, correct apps, assigned to **`SG-SPMAMG-Pilot`**, excluding
**`SG-BreakGlass-Exclude`**. `SPMAMG-Validation.ps1` confirms.
**Fail:** Missing policy, wrong app list, or missing exclusion.

## T2. App PIN is enforced on the device
**Steps:** On a pilot iOS and Android device, open the **SharePoint** app signed in as a pilot user.
**Pass:** The app prompts to **set/enter an app PIN** and encrypts data.
**Fail:** No PIN prompt — policy not applied (check assignment, license, and that the app is the
government-cloud instance).

## T3. Data-leak prevention fires
**Steps:** Open a document in the SharePoint app. Attempt to (a) copy text into a personal note app,
(b) "Save a copy" to a consumer cloud, (c) open in an unmanaged app.
**Pass:** All three are **blocked or restricted** to policy-managed apps.
**Fail:** Data moves freely to unmanaged apps — re-check **Data protection** settings in the APP.

## T4. Conditional Access requires app protection (Report-only)
**Steps:** `entra.microsoft.us` → **Conditional Access** → **`CA-SPO-Mobile-Require-App-Protection`**.
Use **What If** for a pilot user on iOS against Office 365; review **Sign-in logs → Report-only**.
**Pass:** The policy **applies** and the **Require app protection policy** control is **satisfied**
for the protected app.
**Fail:** Policy not applied to mobile/Office 365, or control not evaluated — re-check Users, Target
resources, Device platforms, Client apps.

## T5. Negative test — unprotected access is blocked
**Steps:** After enforcing the CA policy (**On**), try SharePoint from a mobile **browser** outside
managed Edge, or from an app without the app protection policy.
**Pass:** Access is **blocked or limited** as designed.
**Fail:** Unprotected access still returns data — CA policy scope/grant is wrong.

## T6. Break-glass exclusion verified
**Steps:** Run `SPMAMG-Validation.ps1`; also confirm in the CA policy's **Exclude** list.
**Pass:** **`SG-BreakGlass-Exclude`** is excluded from **`CA-SPO-Mobile-Require-App-Protection`**.
**Fail:** Break-glass not excluded — fix immediately (a bad policy could otherwise lock everyone out).

## T7. Selective wipe works
**Steps:** In `intune.microsoft.us` → **Apps → App selective wipe**, issue a wipe for a pilot user's
device.
**Pass:** Corporate data is removed from the managed apps; the user's personal data is untouched.
**Fail:** Wipe not delivered — check the user has checked in recently and the device is reachable.

## T8. GCC High parity behavior confirmed
**Steps:** In the SharePoint mobile app, confirm the **known GCC High limitations** (Graph-dependent
features such as certain rollups/notifications) behave as documented, not as Commercial.
**Pass:** Behavior matches **GCC High Parity Notes**; no reliance on a feature that is disabled in GCC
High.
**Fail:** A workflow depends on a Graph-dependent SharePoint feature that is disabled in GCC High —
redesign per parity notes.

---
**Overall gate:** T0–T8 all **pass** before declaring the rollout validated. Capture
`SPMAMG-Report.ps1` output as evidence for your change record.
