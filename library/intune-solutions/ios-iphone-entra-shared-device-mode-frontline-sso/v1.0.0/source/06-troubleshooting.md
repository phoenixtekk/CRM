# 6. Troubleshooting — iOS iPhone Entra ID Shared Device Mode

Work in enrollment order: confirm the device **enrolled without affinity and landed in the group**,
then that it was **registered into shared mode**, then that the **SDM apps behave**. Most failures are
a Dynamic (not Assigned) group, a missing group **owner**, a wrong enrollment affinity, or an app that
is not SDM-aware. Each symptom gives the **likely cause** and the **fix**.

> **Before you start:** if the concern is "one worker can see another's data," first confirm the app
> in question is **SDM-aware**. SDM clears data only for apps that implement it — a non-SDM app on a
> shared phone is the classic false alarm (and a real leak). This is an app-scope decision, not an SDM
> bug.

## Symptom: Shared iPhones enroll but the group stays empty / nothing deploys
**Likely cause:** The device group is **Dynamic**, or the **Intune Provisioning Client** is not an
**owner** of the Assigned group.
**Fix:**
1. Confirm **iPhone SDM – Devices** is **Membership type = Assigned** (not Dynamic).
2. Add the **Intune Provisioning Client** (AppId `f1346770-5b25-470b-88bd-d5744ab7952c`) as an
   **owner** — search by **AppId**, since the display name varies (`IOSSDMFL-Remediation.ps1` can do
   this).
3. If the SP doesn't exist to search, open the Intune portal once as **Global Administrator** to
   provision it, then add it.

## Symptom: The device enrolled with a primary user (user affinity)
**Likely cause:** The ADE profile is not set to **Enroll without User Affinity**.
**Fix:**
1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens → (token) → Profiles →
   iPhone SDM – ADE Profile** and set **User Affinity = Enroll without User Affinity**, **Supervised**.
2. Re-assign the profile to the serials and **re-enroll** the affected devices (affinity is set at
   enrollment).

## Symptom: Teams shows a normal single-user sign-in, not shared mode
**Likely cause:** The device was never registered into Shared Device Mode, or the registering account
lacked the role.
**Fix:**
1. On the device, open **Microsoft Authenticator** and complete the **shared device registration**
   using an account that holds **Cloud Device Administrator** (R5).
2. Confirm the registration succeeded, then reopen Teams — it should present the shared-device
   experience.

## Symptom: Shared-device registration fails / is greyed out
**Likely cause:** The registering account lacks **Cloud Device Administrator**, or Authenticator isn't
installed.
**Fix:**
1. Entra → **Roles and administrators → Cloud Device Administrator** — add the provisioning account.
2. Confirm **Microsoft Authenticator** is installed on the device (R4) and the device has network
   access to the Entra endpoints (R8).

## Symptom: Sign-out doesn't clear the previous user (user B sees user A's data)
**Likely cause:** The offending app is **not SDM-aware**, or the device is not truly in shared mode.
**Fix:**
1. Identify which app retained data. If it is not Teams/an SDM-aware MSAL app, **remove or restrict**
   it — SDM cannot clear non-SDM apps.
2. Re-confirm shared-mode registration (Test 4) and that Teams itself performs global sign-out.
3. Tighten the **iPhone SDM – Restrictions** profile so only SDM-aware apps are present (R9).

## Symptom: Repeated MFA / sign-in loops on the shared device
**Likely cause:** Conditional Access re-challenging, blocked endpoint, or TLS inspection.
**Fix:**
1. Review Conditional Access sign-in-frequency policies applied to the frontline users; shared devices
   naturally re-authenticate per user per shift — tune frequency to the shift model.
2. Confirm the device reaches `https://login.microsoftonline.com` (or sovereign equivalent) (R8).
3. **Exempt Microsoft login endpoints from TLS inspection.**

## Symptom: Some LOB apps don't participate in global sign-in/out
**Likely cause:** The app is not built on MSAL or does not implement Shared Device Mode.
**Fix:**
1. Confirm SDM support with the app vendor / current Microsoft documentation.
2. If unsupported, do **not** rely on it for shared use — restrict it off the pool or accept it is
   outside the global-sign-out boundary and holds no user data.

## Symptom: Report shows fewer shared iPhones than expected
**Likely cause:** Devices not yet ADE-enrolled, not registered into shared mode, or missing from the
group.
**Fix:**
1. Run `IOSSDMFL-Report.ps1` to list which devices lack no-affinity enrollment or the SDM apps.
2. Run `IOSSDMFL-Remediation.ps1` (`-WhatIf` first) to fix group ownership/app assignment.
3. Complete the per-device shared-mode registration for stragglers (Implementation Step 7).

## Escalation checklist
Before opening a Microsoft support case, collect: the `IOSSDMFL-Discovery.ps1` output, the ADE
profile's affinity setting, the **iPhone SDM – Devices** group type + owners, the exact app bundle IDs
and their SDM support status, the registering account's role, iOS version, and a description of the
two-user sign-in/sign-out test result (isolates SDM from app-specific behavior).
