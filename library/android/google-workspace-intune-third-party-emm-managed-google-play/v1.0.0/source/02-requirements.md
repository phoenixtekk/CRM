# 2. Requirements Guide — Google Workspace ↔ Intune Third-Party EMM Integration

These are the **solution-specific** prerequisites for the Google Workspace ↔ Intune third-party EMM
integration. They build on — and do not repeat — the six **category Global Requirements**
(`global-requirements-android.md`): a Microsoft 365 tenant with Intune and Android Enterprise (GR 1);
the managed Google Play binding decision (GR 2); least-privilege Intune roles (GR 3); the enrollment-
method decision and Graph PowerShell toolchain (GR 4); network reachability to Google & Microsoft
endpoints (GR 5); and a pilot scope with change control (GR 6). Verify the Global Requirements first,
then the solution-specific items below.

Each requirement below is stated as **Description · Why required · How to verify · How to implement if
missing**.

---

## 2.1 Your tenant genuinely uses Google Workspace / Cloud Identity (the correct model)
- **Description:** Your organization has a **Google Workspace or Cloud Identity managed domain** (i.e.
  your users have real Google identities), which is what makes the **third-party EMM** integration the
  right model rather than the managed Google Play **account enterprise** (`ANDROIDENT`).
- **Why required:** The two managed Google Play binding models are **mutually exclusive** (GR 2). Using
  the account-enterprise model on a domain that already exists in Google Workspace causes domain
  conflicts and "can't add account" failures. This solution is only correct if you have a managed Google
  domain.
- **How to verify:** Confirm a Google Workspace / Cloud Identity subscription and that your primary
  domain is verified in the **Google Admin console** (`admin.google.com`). Confirm Intune does **not**
  already have a managed Google Play *account enterprise* bound for a different (non-domain) account.
- **How to implement if missing:** If you have **no** Google managed domain, stop — use the
  account-enterprise solution (`ANDROIDENT`) instead. Do not create a managed Google domain solely to
  use this model.

## 2.2 Google Workspace / Cloud Identity super-admin access
- **Description:** Access to a **Google super-admin** account able to change device-management and
  third-party integration settings in the **Google Admin console**.
- **Why required:** Delegating managed Google Play to a third-party Android EMM (Intune) is a
  **super-admin** action performed in the Google Admin console — it cannot be done from Intune alone.
- **How to verify:** Sign in to `admin.google.com` with the account and confirm access to the mobile
  device-management / third-party integration settings (menu location is **verified against current
  Google guidance** — Google moves these; see Implementation).
- **How to implement if missing:** Have an existing Google super-admin grant the role (or perform the
  step) under change control. Record who will act, as the console step is theirs to run.

## 2.3 Least-privilege Intune role for the connection (Global Admin only where required)
- **Description:** The Intune-side connection is performed with **Intune Administrator**, with **Global
  Administrator** used **only** for the initial managed Google Play / Android Enterprise binding where
  it is genuinely required (per GR 3).
- **Why required:** Establishing or changing the Android Enterprise connection is a tenant-level change;
  day-to-day configuration should not use Global Admin.
- **How to verify:** Confirm the role in the Microsoft 365 admin center / Entra roles; confirm
  `Connect-MgGraph` succeeds with the read scopes the discovery scripts request.
- **How to implement if missing:** Have a Global Admin assign Intune Administrator, and reserve Global
  Admin for the single binding step under change control.

## 2.4 A documented current-state baseline (binding + existing devices)
- **Description:** A captured **before** picture: the current managed Google Play connection state (bind
  status, owning account, last app sync) and an inventory of existing Android devices (enrollment type,
  ownership, management state, last check-in).
- **Why required:** The **re-enrollment / end-user impact** question can only be answered against a known
  starting point. Without the baseline you cannot tell whether a device's state changed after the cutover.
- **How to verify:** Run `ANDROIDGW-Discovery.ps1` (binding posture) and `ANDROIDGW-DeviceImpact.ps1`
  (existing devices) — both read-only — and save `Binding Posture – Workspace+Intune – Discovery` and
  `Device Impact – Android – Assess`.
- **How to implement if missing:** Capture the baseline before making any console change; it is the
  reference the pilot is measured against.

## 2.5 The identity/account model is confirmed (Google identity ↔ Entra identity)
- **Description:** A confirmed mapping of how your **Google Workspace / Cloud Identity** user identities
  relate to the **Entra ID** identities Intune uses — in particular the account that will be added to
  managed devices and how managed Google Play resolves the user in a managed domain.
- **Why required:** In the Workspace model users have real Google identities; a mismatch (e.g. UPN vs
  Google primary email, unmatched domains) is a common root cause of enrollment / account-add failures.
- **How to verify:** Confirm the domains used for Entra UPNs and Google primary emails, and that the
  pilot users exist and are correctly licensed in both. `ANDROIDGW-Readiness.ps1` prints an
  identity/account checklist.
- **How to implement if missing:** Reconcile the identity model (matching domains / provisioning) before
  piloting; document the account users will sign in with on devices.

## 2.6 A named pilot scope for the impact assessment
- **Description:** A small, representative **pilot device set and user group** (`MGP Pilot – Android –
  Stage1`) — ideally spanning each enrollment model you actually use (work profile BYOD, fully managed,
  corporate-owned work profile, dedicated/COSU) — used to observe the real re-enrollment / end-user
  impact before fleet rollout.
- **Why required:** Re-enrollment behavior is **state- and version-dependent** and must be **observed**,
  not assumed (GR 6). A representative pilot is how impact is proven safely.
- **How to verify:** Confirm the pilot group exists and its members/devices are identified;
  `ANDROIDGW-Set-Scope.ps1` can create/populate `MGP Pilot – Android – Stage1`.
- **How to implement if missing:** Build the pilot group and enrol/identify its devices before the
  cutover; agree the observation window and pass/fail gate.

## 2.7 Network reachability for managed Google Play and account sign-in
- **Description:** The pilot devices and enrollment path can reach the required **Google** (managed
  Google Play, Android, Google sign-in) and **Microsoft** (Intune, Entra) endpoints, with no proxy or
  content filter blocking managed Google Play account provisioning or Google account sign-in (extends
  GR 5).
- **Why required:** Adding the managed Google account and syncing managed Google Play both require
  reachability; blocked endpoints are the most common cause of "can't add a Google account" during the
  Workspace integration.
- **How to verify:** Confirm the documented Google/Microsoft endpoints are allowed on the pilot device
  network.
- **How to implement if missing:** Allow the current documented endpoints (verify the current list
  against Microsoft/Google guidance) before piloting.

## 2.8 Change control and a documented rollback
- **Description:** An approved **change window** and a written **rollback** for the binding change —
  because a managed Google Play / third-party EMM binding change is **high-impact** and may affect
  existing devices (GR 6).
- **Why required:** If the pilot shows unacceptable impact (e.g. unexpected re-enrollment), you need a
  defined way to stop and revert before broad rollout.
- **How to verify:** Confirm the change record, the approver, and the rollback steps (including who
  reverts the Google Admin console setting) are documented.
- **How to implement if missing:** Draft the change/rollback plan before touching either console; do not
  proceed to the fleet without it.

---
### Requirements at a glance
`Confirm Workspace is the right model → super-admin + least-priv Intune role → baseline binding +
devices → confirm identity/account model → pilot scope → endpoint reachability → change control +
rollback.`

> **Cross-console reality.** This integration is the one Android solution where a **Google super-admin**
> must act in the **Google Admin console** and a Microsoft admin must act in **Intune**. Line up both
> owners, and both consoles' current guidance, before you start.
