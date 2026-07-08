# 3. Implementation Guide — Android Enterprise Connection & Managed Google Play Setup

Follow these steps **in order**. The **Intune admin center** side is documented click-by-click and is
automatable with the five provided Graph scripts; the **managed Google Play sign-in** (Google-hosted) and
any OEM console steps name the action and defer the exact Google/OEM screens to their official
documentation.

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com` (scope groups)
- **Managed Google Play sign-in** — Google-hosted, reached **inside** the Intune connection flow (screens
  deferred to Google's documentation)

> **Model:** Connect managed Google Play (account enterprise), configure enrollment restrictions + platform
> settings, create the enrollment profiles for each model, then pilot-enroll one device per model,
> validate, and expand. **Assess → Design → Configure → Pilot → Validate → Expand.**

> **Artifact names (use verbatim).** Scope groups: `Android AE - Pilot - Stage`, `Android AE - Prod`;
> per-model groups `Android WP - Users - Pilot` (BYOD work profile, **users**), `Android FM - Devices -
> Pilot` (fully managed), `Android COPE - Devices - Pilot` (corporate-owned work profile), `Android COSU -
> Devices - Pilot` (dedicated). Enrollment restriction: `Android Enterprise - Platform Restrictions -
> Pilot`. Corporate-owned enrollment profiles: `Android FM - Enroll - Pilot`, `Android COPE - Enroll -
> Pilot`, `Android COSU - Enroll - Pilot`.

> **Risk + rollback (read first).** The **managed Google Play binding is tenant-wide** and the chosen
> **binding model is a one-way commitment** (account enterprise vs Google Workspace EMM). **Enrollment
> restriction** and **enrollment-model** changes are **high-impact** and can affect which devices enrol —
> and, where the **AMAPI transition** is in play, *may* affect re-enrollment behavior (**verify against
> current Microsoft guidance / your tenant** — do not assume). **Rollback:** enrollment restrictions and
> enrollment profiles can be reverted/deleted in Intune (block the model / delete the profile) *before*
> broad rollout; the **managed Google Play connection itself** should only be **disconnected** as a
> deliberate, change-controlled action because it **un-enrols Android Enterprise devices** — never
> disconnect to "test." Always **pilot on a scoped group first**.

---

## Phase 0 — Assess (before any change)

### Step 1 — Confirm the binding decision and current state
1. Confirm with the identity owner that the organization has **no Google Workspace** (→ account enterprise,
   this solution) or **has Google Workspace** (→ stop; use the Workspace ↔ Intune EMM solution). See
   Requirement 2.1.
2. Run **`ANDROIDENT-Discovery.ps1`** (read-only). It reports the **managed Google Play connection**
   (`androidManagedStoreAccountEnterpriseSettings`) bind status and last app-sync, the current **Android
   enrollment platform restrictions**, and any existing **corporate-owned enrollment profiles**
   (`androidDeviceOwnerEnrollmentProfiles`). Record the baseline.

### Step 2 — Create the scope groups
1. Entra → **Groups → New group → Security** → create `Android AE - Pilot - Stage` (a few pilot users /
   devices) and `Android AE - Prod` (the full population, used at expand).
2. Create the per-model groups: `Android WP - Users - Pilot` (**users** — BYOD is user-scoped),
   `Android FM - Devices - Pilot`, `Android COPE - Devices - Pilot`, `Android COSU - Devices - Pilot`.

> Prefer automation? Run **`ANDROIDENT-Set-ScopeTargeting.ps1`** to create all of these in one pass
> (default `-WhatIf`; add `-Apply`). It also reports the enrollment-restriction assignment so you can
> confirm the pilot scope before enforcing anything.

---

## Phase 1 — Connect Intune to managed Google Play (account enterprise)

### Step 3 — Establish the managed Google Play connection
1. Sign in to the **Intune admin center** as **Global Administrator** (Requirement 2.3).
2. Go to **Devices → Android → Android enterprise** (in some tenants **Devices → Enrollment → Android**).
   Under **Managed Google Play**, choose to **connect / set up** managed Google Play (account enterprise).
3. Accept the agreement, then **Launch Google to connect now**. This opens the **Google-hosted managed
   Google Play sign-in** (deferred to Google's documentation).
4. On the Google page, **sign in with the organization-owned Google account** from Requirement 2.2 (never
   a personal Gmail) and complete the enterprise sign-up. You are returned to Intune.
5. Back in Intune, confirm the connection shows **bound / connected** and that the **owner account** is the
   organization account you used.

> **Do not disconnect to test.** Disconnecting the connection **un-enrols** Android Enterprise devices.

### Step 4 — Confirm the app catalog sync
1. In Intune, confirm the connection reports a recent successful **app sync** (managed Google Play
   catalog). If it is stale, trigger a sync.
2. Re-run **`ANDROIDENT-Discovery.ps1`** and confirm **bind status = bound** and **last app sync =
   success**. This is **Gate A** (see Testing).

---

## Phase 2 — Enrollment restrictions and platform settings

### Step 5 — Configure the Android enrollment platform restriction (pilot-scoped)
1. Intune → **Devices → Enrollment → Enrollment restrictions → Device platform restrictions**. Create (or
   edit) a **platform restriction** named `Android Enterprise - Platform Restrictions - Pilot`.
2. Set, per the plan from Requirement 2.4:
   - **Android Enterprise (work profile / corporate-owned)** — **Allow** the models this pilot needs.
     Allowing **personally owned work profile** is what makes **BYOD** enrollment possible (it has no
     device-side profile). Allow **corporate-owned** device-owner enrollment for FM / COPE / COSU.
   - **Personally owned** devices — allow or block per policy (block here forces corporate-owned only).
   - **Android device administrator** (legacy) — **Block** unless a specific legacy need exists (Android
     Enterprise is the modern model).
3. **Assignments:** assign the restriction to **`Android AE - Pilot - Stage`** only. **Save.**

> Prefer automation? **`ANDROIDENT-Set-EnrollmentRestrictions.ps1`** previews (default `-WhatIf`) and, with
> `-Apply`, sets the Android platform restriction to the allowed models. Restriction changes take effect
> **at next enrollment**; existing devices are not retro-enrolled.

> **AMAPI note.** Exact restriction labels and defaults are shifting with the **AMAPI transition** —
> confirm the current labels in your tenant against Microsoft's current documentation; the **intent**
> (allow the models you want, block the rest) is stable.

---

## Phase 3 — Create the enrollment profiles per model

> BYOD **personally-owned work profile** has **no enrollment-profile object** — it was enabled by the
> restriction in Step 5 and the user enrols from **Company Portal**. Steps 6–8 create the **corporate-owned
> enrollment profiles** (`androidDeviceOwnerEnrollmentProfiles`) for the three company-owned models. These
> carry an **enrollment token / QR code** used at device first-run.

### Step 6 — Fully managed enrollment profile
1. Intune → **Devices → Android → Android enterprise → Corporate-owned devices** (the
   **enrollment profiles / tokens** surface). **Create** a profile named `Android FM - Enroll - Pilot`.
2. Set the enrollment mode to **fully managed** (whole-device management, no personal space). Set a
   sensible **token expiry** and (optionally) enable **corporate-owned Wi-Fi / device details** per policy.
3. **Create.** The profile yields an **enrollment token + QR code**; record where the QR/token is retrieved
   for the pilot device.

> Automation: **`ANDROIDENT-New-EnrollmentProfile.ps1 -Model FullyManaged`** (default `-WhatIf`; add
> `-Apply`) creates this profile via Graph.

### Step 7 — Corporate-owned work profile (COPE) enrollment profile
1. On the same **Corporate-owned devices** surface, **Create** a profile named `Android COPE - Enroll -
   Pilot`.
2. Set the enrollment mode to **corporate-owned work profile** (company device **with** a managed work
   profile and a personal space).
3. **Create.** Record the token/QR.

> Automation: **`ANDROIDENT-New-EnrollmentProfile.ps1 -Model CorporateOwnedWorkProfile`**.

> **Verify the mode value against your tenant.** The corporate-owned **work profile** enrollment mode is
> one of the areas affected by the **AMAPI transition**; confirm the current mode name/availability in your
> tenant and Microsoft's current documentation before relying on it in production.

### Step 8 — Dedicated / COSU enrollment profile
1. **Create** a profile named `Android COSU - Enroll - Pilot` on the **Corporate-owned devices** surface.
2. Set the enrollment mode to **dedicated device** (kiosk / no user affinity). **Create.** Record the
   token/QR.
3. Deep kiosk lockdown (single-app / multi-app layout, allowed apps) is the **dedicated/COSU solution**;
   here we create the enrollment profile so the device enrols **without user affinity**.

> Automation: **`ANDROIDENT-New-EnrollmentProfile.ps1 -Model Dedicated`**.

---

## Phase 4 — Pilot, validate, expand

### Step 9 — Pilot-enroll one device per model
1. **BYOD (work profile):** on a personal Android phone, install the **Intune Company Portal**, sign in as
   a member of `Android WP - Users - Pilot`, and enrol — a **work profile** is created; confirm personal
   space is untouched.
2. **Fully managed:** on a **factory-reset** company device, at first-run tap the setup screen the required
   number of times to trigger **QR enrollment** (or use the chosen enrollment method) and scan the
   `Android FM - Enroll - Pilot` QR — the whole device enrols managed.
3. **Corporate-owned work profile:** repeat on a reset company device with the `Android COPE - Enroll -
   Pilot` token — confirm a managed work profile plus personal space.
4. **Dedicated/COSU:** repeat with `Android COSU - Enroll - Pilot` — the device enrols **no user
   affinity** (kiosk-ready).

### Step 10 — Validate the pilot
1. Run **`ANDROIDENT-Discovery.ps1`** (binding bound + app sync + restriction + profiles present).
2. Run **`ANDROIDENT-Report.ps1`** — per-model enrollment coverage (device ownership + management state),
   restriction assignment, and profile inventory. Complete the **Testing Guide** gates before expanding.

### Step 11 — Expand to production
1. **Restrictions:** re-assign / create a production platform restriction and assign to **`Android AE -
   Prod`** (or make the pilot restriction the default) once the pilot passes.
2. **Corporate-owned profiles:** issue the `… - Enroll - Pilot` tokens/QRs (or production equivalents) to
   the broader device supply; add devices to the per-model groups as they enrol.
3. **BYOD:** extend `Android WP - Users - Pilot` (or a production BYOD group) to the broader BYOD user
   population.
4. Re-run **`ANDROIDENT-Report.ps1`** and roll out in waves, validating each wave before widening. For any
   **AMAPI-related** change, **verify re-enrollment behavior on your tenant first** — do not assume.

---
### Order of operations
`Assess (Discovery) → scope groups → connect managed Google Play (account enterprise) → confirm app sync →
Android platform restriction (pilot) → FM / COPE / COSU enrollment profiles → BYOD via Company Portal →
pilot-enroll one per model → validate (Discovery + Report) → expand`
