# 6. Troubleshooting Guide — Android Enterprise Connection & Managed Google Play Setup

Symptom → root cause → fix for the foundation. Start with **`ANDROIDENT-Discovery.ps1`** (binding, app
sync, restrictions, profiles) and **`ANDROIDENT-Report.ps1`** (per-model enrollment coverage) to localize
the problem before changing anything.

> **Golden rule:** never disconnect the managed Google Play connection to "test" — it **un-enrols** Android
> Enterprise devices. And where the **AMAPI transition** is involved, **verify re-enrollment behavior on
> your own tenant** rather than assuming.

---

## A. Connection / binding

### A1. Managed Google Play shows not bound / not connected
- **Likely cause:** the connection was never completed, or the Google-hosted sign-in was cancelled.
- **Fix:** Intune → **Devices → Android → Android enterprise** → complete **Launch Google to connect now**
  as **Global Administrator**, signing in with the **organization-owned Google account** (Req 2.2). Confirm
  `ANDROIDENT-Discovery.ps1` reports **bind status = bound**.

### A2. Bound, but the owner is a personal Gmail / individual account
- **Likely cause:** the binding was completed with the wrong Google account.
- **Fix:** plan a change-controlled re-binding with the correct organization-owned account. Because
  disconnect/reconnect **un-enrols** devices, coordinate this deliberately — do not do it casually.

### A3. App catalog sync failing / stale (`lastAppSyncStatus` not success)
- **Likely cause:** blocked Google/Microsoft endpoints, or a transient service issue.
- **Fix:** confirm the required **Google (managed Google Play, Android)** and **Microsoft (Intune, Entra)**
  endpoints are allowed (Req 2.6); trigger a sync and re-check `ANDROIDENT-Discovery.ps1`. Persistent
  failure with open endpoints → verify the owner account is healthy.

---

## B. Enrollment restrictions

### B1. BYOD (personally-owned work profile) devices cannot enrol
- **Likely cause:** the Android platform restriction **blocks personally-owned** Android Enterprise (BYOD
  has no device-side profile — the restriction is the only gate), or the restriction is not assigned to the
  user's group.
- **Fix:** run `ANDROIDENT-Set-EnrollmentRestrictions.ps1` (preview, then `-Apply` **without**
  `-BlockPersonallyOwned`) so personally-owned work profile is **allowed**; confirm the restriction is
  assigned to the BYOD **user** group (`Android WP - Users - Pilot`).

### B2. A device enrolled via a model you did not intend
- **Likely cause:** the restriction allows more models than planned, or a broader restriction (higher
  priority) applies.
- **Fix:** tighten the named restriction to block the unwanted model; check restriction **priority** so the
  intended one wins for the scope. Restrictions apply at **next enrollment** — retire/re-enrol the
  offending device if needed.

### B3. Legacy Android device administrator devices keep appearing
- **Likely cause:** the **Android device administrator** platform is still allowed.
- **Fix:** block legacy device administrator in the restriction (the script sets this by default). Android
  Enterprise is the modern, supported model.

---

## C. Per-model enrollment failures

### C1. "Can't add a Google account" during corporate-owned enrollment
- **Likely cause:** blocked endpoints on the device network, or the device was not truly factory-reset.
- **Fix:** confirm endpoint reachability (Req 2.6); **factory-reset** the device and retry the QR/token
  enrollment. Corporate-owned models enrol only at **first-run**.

### C2. Fully managed device also created a work profile (or vice-versa)
- **Likely cause:** the wrong **enrollment profile / mode** was used (FM vs COPE vs dedicated).
- **Fix:** re-check which profile's QR/token was scanned; use `Android FM - Enroll - Pilot` for fully
  managed, `Android COPE - Enroll - Pilot` for corporate-owned work profile, `Android COSU - Enroll -
  Pilot` for dedicated. Re-create the profile with `ANDROIDENT-New-EnrollmentProfile.ps1 -Model <model>`
  if missing.

### C3. Corporate-owned work profile (COPE) mode not available / profile create fails
- **Likely cause:** the corporate-owned **work profile** enrollment mode is one of the surfaces affected by
  the **AMAPI transition** and its availability/name can differ by tenant and date.
- **Fix:** **verify the current mode against Microsoft's documentation for your tenant**; if the Graph create
  fails, create the profile in the Intune portal. Do not assume the mode name — the script flags this.

### C4. Dedicated/COSU device enrolled *with* a user
- **Likely cause:** a user-affinity model was used instead of the dedicated profile.
- **Fix:** enrol with the `Android COSU - Enroll - Pilot` (dedicated) profile so the device has **no user
  affinity**. Deep kiosk lockdown is the separate dedicated/COSU solution.

---

## D. Automation / Graph

### D1. `Connect-MgGraph` fails or a script reports missing permissions
- **Likely cause:** the Graph SDK is not installed, or admin consent for the delegated scope is missing.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to the scopes named in each script
  header (read scopes for Discovery/Report; ReadWrite for the config scripts). Never hardcode credentials.

### D2. A config script's PATCH/POST is rejected (schema mismatch)
- **Likely cause:** the Android restriction / enrollment-profile schema is **evolving with AMAPI** and a
  property name/shape changed.
- **Fix:** run the script in default **`-WhatIf`** to see the planned body; **verify the current schema**
  against Microsoft's documentation for your tenant, or make the change in the Intune portal. The scripts
  emit this guidance on failure rather than guessing.

---

## E. AMAPI transition — the "verify, don't assume" cases
- **Whether a change triggers re-enrollment** (restriction, enrollment-model, or connector changes) is
  **actively evolving**. **Test on a pilot device on your own tenant** before any production change;
  re-validate Testing Gates B and C after any Microsoft-announced Android enrollment change.
- **Web / account-driven enrollment** surfaces and defaults are shifting — confirm the current flow in
  Microsoft's documentation rather than relying on remembered steps.
