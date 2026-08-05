# 5. Testing & Validation — iOS iPhone Entra ID Shared Device Mode

Validate against a **pilot iPhone** with **two** pilot users before expanding. Each test has an
explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side
checks and the on-device steps for the shared-session experience.

> **What "pass" means here:** a worker signs in as themselves on a shared iPhone, signs out once, and
> the **next** worker signs in with **no trace** of the previous user in the SDM apps. This is a
> per-user identity session, not kiosk lockdown.

## Test 1 — Tenant readiness
**Procedure:** Run `IOSSDMFL-Discovery.ps1`.
**Pass:** A no-user-affinity ADE profile exists; Microsoft Authenticator and Teams are added/assigned;
the **iPhone SDM – Devices** assigned group exists with the Intune Provisioning Client as owner; the
Cloud Device Administrator role has a member.
**Fail:** Any missing → resolve before piloting (see Remediation).

## Test 2 — Assigned group ownership (enrollment-time grouping)
**Procedure:** Run `IOSSDMFL-Validation.ps1` (or Entra → Groups → **iPhone SDM – Devices** → Owners).
**Pass:** The group is **Assigned** and the **Intune Provisioning Client** (`f1346770-5b25-470b-88bd-
d5744ab7952c`) is an **owner**.
**Fail:** Group is Dynamic, or the SP is not an owner → devices won't populate at enrollment; fix with
`IOSSDMFL-Remediation.ps1`.

## Test 3 — No-affinity enrollment
**Procedure:** On the pilot iPhone (after ADE enrollment), Intune → **Devices → iOS/iPadOS → (device)**.
**Pass:** The device is **supervised**, shows **no primary user**, and is a member of
**iPhone SDM – Devices**.
**Fail:** Device has a primary user / user affinity → correct the **iPhone SDM – ADE Profile**
(Requirement R2) and re-enroll.

## Test 4 — Shared-mode registration
**Procedure:** Confirm the device was registered into shared mode via Microsoft Authenticator with the
Cloud Device Administrator account (Implementation Step 7).
**Pass:** Teams (and other SDM apps) present the **shared-device** sign-in experience, not the normal
single-user one.
**Fail:** Apps show a normal sign-in → re-run the Authenticator shared-device registration with an
account holding **Cloud Device Administrator** (R5).

## Test 5 — Global sign-in (user A)
**Procedure:** Sign in as **user A** in Teams; open another SDM app if present.
**Pass:** A is signed in; other SDM apps recognize A **without** a second sign-in.
**Fail:** Each app prompts separately with no shared identity → confirm shared-mode registration (Test
4) and that the apps are SDM-aware (R6).

## Test 6 — Single (global) sign-out
**Procedure:** As user A, sign out once in Teams.
**Pass:** A is signed out of **all** SDM apps and A's cached data is cleared from the device.
**Fail:** A still signed in elsewhere, or data remains → the app is not SDM-aware, or the device is not
truly in shared mode — re-verify Tests 4/6 and app support.

## Test 7 — Clean second sign-in (user B) — the core test
**Procedure:** Sign in as **user B** in Teams after A's sign-out.
**Pass:** B sees **only** their own data; there is **no trace** of user A (chats, files, tokens).
**Fail:** Any of A's data/session visible to B → do **not** proceed; the shared-session boundary is
not intact. Confirm SDM registration and that only SDM-aware apps hold user data on the device.

## Test 8 — Coverage / inventory report
**Procedure:** Run `IOSSDMFL-Report.ps1`.
**Pass:** The pilot iPhone appears as a no-affinity, shared-pool device with Authenticator + Teams
present; counts match **iPhone SDM – Devices**.
**Fail:** Device missing or apps absent → run `IOSSDMFL-Remediation.ps1` (`-WhatIf` first).

## Test 9 — Non-SDM app boundary (negative test)
**Procedure:** Confirm no non-SDM app that caches personal data is deployed to the shared pool (review
the **iPhone SDM – Restrictions** profile and app assignments).
**Pass:** Only SDM-aware apps (and safe utilities) are present; global sign-out therefore clears all
user data that exists on the device.
**Fail:** A non-SDM data-caching app is on the pool → remove it or restrict it; SDM will **not** clear
its data on sign-out.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass and **Test 7 (clean second sign-in) passes on a real
device with two real users**, and Test 9 confirms no non-SDM app leaks data across users.
