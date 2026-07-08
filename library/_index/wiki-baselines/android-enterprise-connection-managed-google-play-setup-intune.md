# Android Enterprise Connection & Managed Google Play Setup in Intune

> **Version 1.0.0** · Category: Android · Solution code: ANDROIDENT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Android Enterprise Connection & Managed Google Play Setup in Intune

## The problem
Android management in Microsoft Intune succeeds or fails on **one thing done correctly first**: the
**managed Google Play** binding and the **enrollment model**. Get either wrong and the symptom is stark —
**nothing enrolls**. Devices fail to add a Google account, the wrong management model is applied, or
personal-device enrollment is silently allowed (or blocked) against policy. Every downstream capability —
app delivery, compliance, kiosk lockdown — depends on this foundation being right.

## The solution
This solution stands up that foundation, end to end:
- **Connects Intune to managed Google Play** using the **account enterprise** model (for organizations
  without Google Workspace), owned by an organization-controlled account.
- **Configures enrollment restrictions** so exactly the intended Android Enterprise models may enrol and
  the rest (including legacy device administrator) are blocked.
- **Creates enrollment profiles for all four models** — personally-owned **work profile (BYOD)**, **fully
  managed**, **corporate-owned work profile**, and **dedicated / COSU** — so each device type enrols the
  right way.
- **Validates on a pilot** with explicit pass/fail gates and a documented rollback before any fleet-wide
  rollout.

## Why it is different
- **Foundation-first and honest about the moving parts.** The Intune side is documented at click-by-click
  and Graph-automatable detail; the **AMAPI transition**, web/account-driven enrollment, and whether a
  change triggers **re-enrollment** are **flagged as evolving** and deferred to current Microsoft guidance
  — never asserted from memory. That candor prevents costly wrong assumptions on production fleets.
- **Pilot-first with rollback.** Assess → Design → Configure → Pilot → Validate → Expand, with gates that
  stop a bad change before it reaches the fleet.
- **Safe, auditable automation.** Five Microsoft Graph PowerShell tools assess, configure (safe-by-default
  `-WhatIf`), validate, and report — with no hardcoded credentials or secrets.

## Business value
- **Devices enrol correctly the first time**, avoiding the rework and support load of a mis-configured
  binding or enrollment model.
- **Policy is enforced at the door** — only the intended models enrol, protecting both corporate control
  and BYOD user privacy.
- **Lower risk on a high-impact change** — the binding and enrollment models are tenant-wide; piloting and
  clear rollback protect the production estate.
- **A clean base to build on** — app management, compliance, and dedicated/COSU lockdown extend this
  foundation instead of fighting it.

## Bottom line
A correct Android Enterprise foundation in Intune — **managed Google Play bound, enrollment models
configured, restrictions enforced, validated on a pilot** — so devices enrol the right way and everything
else works.


---


# 1. Solution Overview — Android Enterprise Connection & Managed Google Play Setup in Intune

## What this solution is
This solution stands up the **foundation** of Android management in Microsoft Intune: it connects
Intune to **managed Google Play**, configures **enrollment restrictions** and platform settings, and
creates the **enrollment profiles** for all four Android Enterprise enrollment models — **personally-owned
work profile (BYOD)**, **fully managed**, **corporate-owned work profile**, and **dedicated / COSU
(kiosk)**. When this layer is correct, devices enroll the right way and everything else — app delivery,
compliance, configuration — has something to build on. When it is wrong, **nothing enrolls**.

It is deliberately the *first* Android solution in the line. It does not cover app delivery, per-model
kiosk lockdown, or the Google Workspace integration in depth — those are separate solutions. It gets the
**binding and the enrollment models** right.

## The one decision that comes first — which managed Google Play binding
Intune talks to Android Enterprise through **managed Google Play**, and there are **two mutually
exclusive binding models**. You must pick the one that matches the organization:

1. **Managed Google Play account enterprise** — for organizations **without Google Workspace**. Intune
   creates an **enterprise-owned, Google-hosted managed Google Play account** bound to the tenant. This
   is the common model and the one this solution configures end to end.
2. **Google Workspace / Cloud Identity ↔ Intune third-party EMM** — for organizations that **already use
   Google Workspace**. The binding is established from the **Google Admin console** (Intune registered as
   the EMM). This is a **separate product**; this solution names the decision and points to it, and does
   not duplicate the Workspace-side steps.

> **One and only one model applies per tenant.** Choosing is a first-class step in the Requirements and
> Implementation guides. This solution builds the **account enterprise** model; if the organization has
> Google Workspace, use the Workspace ↔ Intune EMM solution instead.

## The four Android Enterprise enrollment models (and when to use each)
Android Enterprise is not one enrollment method — it is four, and the **device ownership** and **user
privacy** posture decide which one a given device gets:

- **Personally-owned work profile (BYOD)** — a personal Android phone the user owns. Enrollment creates a
  **separate, encrypted work profile** alongside the user's personal space; the organization manages only
  the work profile and can never see or wipe personal data. **User-driven** via the Intune Company Portal.
  There is **no device-side "enrollment profile" object** for this model — it is enabled by **allowing it
  in the enrollment platform restriction**; the user then enrolls from Company Portal.
- **Fully managed** — a **company-owned** device where the entire device is managed (no personal space).
  Enrolled at **factory-reset / first-run** via a token, QR code, Google account, or zero-touch. Backed by
  an **Android Enterprise corporate-owned enrollment profile** in Intune.
- **Corporate-owned work profile (COPE)** — a **company-owned** device that still gives the user a managed
  **work profile** with a personal space, so the organization manages work without owning the user's
  personal apps. Also enrolled at first-run via a corporate-owned enrollment profile.
- **Dedicated / COSU (kiosk)** — a **company-owned**, typically single-purpose or shared device (kiosk,
  scanner, signage) enrolled **without user affinity**. Backed by a corporate-owned enrollment profile in
  **dedicated** mode. (Per-model kiosk lockdown lives in the dedicated/COSU solution; here we create the
  enrollment profile so the device enrols the right way.)

The corporate-owned models (**fully managed**, **corporate-owned work profile**, **dedicated/COSU**) all
enrol through **Android Enterprise corporate-owned enrollment profiles** that carry an **enrollment token
/ QR code**. BYOD does not — it is restriction-driven and user-initiated.

## An honest note on the AMAPI transition (read this)
Microsoft is moving Android Enterprise management from the legacy **Google Play EMM API** onto the
**Android Management API (AMAPI)**. This is an **actively evolving** change: the exact enrollment surfaces,
some defaults, and — importantly — **whether a given change triggers device re-enrollment** can differ by
tenant and by the date you read this. This solution **flags** those areas rather than asserting them, and
directs you to **verify against current Microsoft guidance and test on your own tenant** before making a
production change. The binding itself (managed Google Play account enterprise) and the four enrollment
models are stable concepts; the plumbing beneath them is what is in motion.

## What is in scope vs deferred
- **Exact navigation and Graph automation are given** for the **Intune admin center**
  (`intune.microsoft.com`) side: the managed Google Play connection, enrollment restrictions / platform
  settings, and the corporate-owned enrollment profiles.
- The **managed Google Play sign-in page** (the Google-hosted account-binding step you complete inside the
  Intune connection flow) and any **Google Admin console** actions (Workspace path) are **deferred to
  Google's official documentation** — this solution names the action and what to carry between consoles,
  without fabricating Google menu paths.
- **OEM specifics** (Samsung Knox, Zebra, and other rugged/kiosk vendors) and **third-party apps** are
  addressed at the **pattern level**; their consoles are deferred to the vendor's docs.
- **AMAPI transition / web / account-driven enrollment and re-enrollment behavior** are **flagged as
  version-dependent** — verify against current Microsoft guidance / your tenant.

## Benefits
- **Devices enroll the right way** — the correct binding plus a profile per model, so BYOD, fully managed,
  corporate-owned work profile, and dedicated/COSU each behave as intended.
- **Nothing enrolls by accident** — enrollment restrictions block the models you do not want and gate
  personal-device enrollment where required.
- **Pilot-first and reversible** — every change is validated on a small scope before fleet-wide rollout,
  with explicit pass/fail gates and rollback.
- **Auditable automation** — PowerShell (Microsoft Graph) scripts assess, configure (safe-by-default),
  validate, and report — no hardcoded credentials or secrets.
- **A clean foundation** — app delivery, compliance, and per-model lockdown build on this without rework.

## Limitations (be honest with buyers)
- **The binding model is a one-way commitment per tenant** — account enterprise vs Google Workspace EMM
  are mutually exclusive; choose deliberately (this solution builds account enterprise).
- **AMAPI / enrollment specifics move** — where behavior is version-dependent (including re-enrollment
  triggers), this solution flags it and defers to current Microsoft guidance rather than asserting.
- **Google-side and OEM consoles are deferred** to their vendors; this solution covers the Intune side
  exactly and names the Google/OEM actions.
- **Deep kiosk lockdown and app delivery are separate solutions** — this one establishes the connection
  and the enrollment models.

## The standard deployment model
> **Assess the binding decision → connect managed Google Play (account enterprise) → configure enrollment
> restrictions + platform settings → create the enrollment profiles for each model → pilot-enroll one
> device per model → validate the gates → expand.** Pattern: **Assess → Design → Configure → Pilot →
> Validate → Expand**, with explicit pass/fail gates and a documented rollback for every production change.


---


# 2. Requirements Guide — Android Enterprise Connection & Managed Google Play Setup

These are the **solution-specific** prerequisites for connecting Intune to managed Google Play and
standing up the four enrollment models. They **build on** the shared category requirements in
**`global-requirements-android.md`** (tenant + Intune, the binding model, least-privilege roles, enrollment
method decision + Graph toolchain, network reachability, and a pilot scope with change control) — read
those first; this guide does not repeat them, it adds what is specific to the **foundation** solution.

For each requirement: **Description** · **Why it's required** · **How to verify** · **How to implement if
missing**.

---

## 2.1 A deliberate binding-model decision: account enterprise (this solution) vs Google Workspace
- **Description:** A recorded decision that this tenant uses the **managed Google Play account enterprise**
  model (for organizations **without Google Workspace**), not the **Google Workspace / Cloud Identity ↔
  Intune third-party EMM** model. See category requirement 2.
- **Why it's required:** The two binding models are **mutually exclusive** and configured differently.
  This solution builds **account enterprise**; if the organization uses Google Workspace, the Workspace ↔
  Intune EMM solution is the correct product instead.
- **How to verify:** Confirm whether the organization uses **Google Workspace / Cloud Identity**. In the
  Intune admin center → **Devices > Android > Android enterprise** (or **Enrollment**), confirm no
  conflicting connection already exists.
- **How to implement if missing:** Decide with the identity owner. If **no Google Workspace** → proceed
  here. If **Google Workspace** → stop and use the Workspace integration solution.

## 2.2 A managed Google Play account owner (an organizational identity, not a personal Gmail)
- **Description:** When you connect Intune to managed Google Play (account enterprise), Google asks you to
  **sign in with a Google account** that becomes the **owner** of the managed Google Play enterprise. Use
  an **organization-controlled account** (e.g. a shared/service identity the organization owns), **never a
  personal Gmail** and never a personal admin's account.
- **Why it's required:** The owning account is durable and tied to the enterprise binding; a personal or
  individual account creates a bus-factor and lifecycle risk for the whole Android estate.
- **How to verify:** Confirm a suitable organization-owned Google account exists and its credentials are
  held by the organization (record the account identity — reuse it; do not store its password in code or
  docs).
- **How to implement if missing:** Create/designate an organization-owned Google account for this purpose
  before starting the connection step. *(The exact managed Google Play sign-in screen is Google-hosted and
  deferred to Google's documentation.)*

## 2.3 Global Administrator for the initial binding; Intune Administrator thereafter
- **Description:** The **initial** managed Google Play connection typically requires **Global
  Administrator** (it establishes a tenant-wide binding and consents on Google's side). Ongoing enrollment
  restriction and enrollment-profile work is done as **Intune Administrator** (least privilege). See
  category requirement 3.
- **Why it's required:** The binding is a tenant-level trust; day-to-day profile/restriction changes are
  not and should run under the least-privilege role.
- **How to verify:** Confirm role assignments in the Microsoft 365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin perform the one-time binding under change control,
  then use Intune Administrator for the rest.

## 2.4 Enrollment restrictions planned per model (what may enrol, and how)
- **Description:** A plan for the **enrollment platform restrictions** that decide, for Android, which
  Android Enterprise models are **allowed** (personally-owned work profile / corporate-owned device
  owner) and whether **personally owned** devices may enrol at all. This is the control that makes BYOD
  work profile possible (or blocks it) and that keeps unwanted models out.
- **Why it's required:** Enrollment restrictions are enforced **at enrollment time**; getting them wrong
  either blocks the model you want or lets in a model you do not. In particular, **personally-owned work
  profile (BYOD) has no device-side profile** — it is enabled purely by the restriction.
- **How to verify:** Intune → **Devices > Enrollment > Enrollment restrictions** (Device platform
  restrictions) → review the **Android Enterprise (work profile)** and **Android (device administrator)**
  settings; assess with **`ANDROIDENT-Discovery.ps1`**.
- **How to implement if missing:** Decide the allowed models per audience and configure with
  **`ANDROIDENT-Set-EnrollmentRestrictions.ps1`** (default `-WhatIf`).

## 2.5 A device supply appropriate to each corporate-owned model
- **Description:** For **fully managed**, **corporate-owned work profile**, and **dedicated/COSU**, the
  devices must be **company-owned** and **factory-reset** (or new) so they can enrol at first-run with an
  enrollment token / QR code (or zero-touch / Google account, per your chosen enrollment method). BYOD
  devices are user-owned and enrol from Company Portal.
- **Why it's required:** Corporate-owned enrollment happens during **out-of-box / setup**; a device that
  is already set up personally cannot become fully managed without a reset.
- **How to verify:** Confirm the pilot devices for each corporate-owned model are company-owned and can be
  reset; confirm one BYOD test phone is available.
- **How to implement if missing:** Source/reset company devices for the corporate-owned pilots; identify a
  BYOD test phone.

## 2.6 Managed Google Play app sync and endpoint reachability
- **Description:** After binding, Intune **syncs the app catalog** from managed Google Play, and devices
  must reach the **Google (managed Google Play, Android)** and **Microsoft (Intune, Entra)** endpoints to
  add the managed Google account and enrol. See category requirement 5.
- **Why it's required:** A blocked endpoint is the most common cause of "can't add a Google account" and
  stalled app sync during enrollment.
- **How to verify:** Confirm the connection reports a recent successful **app sync**
  (`ANDROIDENT-Discovery.ps1` surfaces last-sync status); confirm the required endpoints are allowed on
  the device network.
- **How to implement if missing:** Allow the documented Google/Microsoft endpoints; trigger a sync and
  confirm it succeeds before enrolling.

## 2.7 Microsoft Graph PowerShell for the provided automation
- **Description:** A workstation with the **Microsoft Graph PowerShell SDK** (PowerShell 5.1+ or 7+) to run
  this solution's five scripts. See category requirement 4.
- **Why it's required:** Assessment, configuration (safe-by-default), validation, and reporting are
  delivered as Graph PowerShell.
- **How to verify:** `Connect-MgGraph` succeeds with the read scopes; `Get-Module -ListAvailable
  Microsoft.Graph.Authentication` returns a version.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Never store
  credentials or secrets in scripts — the scripts use interactive delegated sign-in.

---

> **Requirement-to-script map.** `ANDROIDENT-Discovery.ps1` (2.1, 2.4, 2.6 — read-only assessment) ·
> `ANDROIDENT-Set-ScopeTargeting.ps1` (2.4, pilot scope groups) ·
> `ANDROIDENT-Set-EnrollmentRestrictions.ps1` (2.4 — `-WhatIf`) ·
> `ANDROIDENT-New-EnrollmentProfile.ps1` (2.5 — `-WhatIf`) · `ANDROIDENT-Report.ps1` (readiness +
> per-model enrollment coverage). The **managed Google Play sign-in** (2.2) is Google-hosted and completed
> in the Intune connection flow — deferred to Google's documentation.


---


# Global Requirements — Microsoft Intune Android (Android Enterprise) Solutions

These requirements apply to **every** solution in the **Android** category (Android Enterprise
connection & managed Google Play, Google Workspace ↔ Intune EMM integration, the Android Management API
(AMAPI) migration, dedicated/COSU & work-profile enrollment, app management, and enrollment
troubleshooting). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Android solution).** The **Microsoft Intune admin center**
> (intune.microsoft.com), **Microsoft Graph**, the **managed Google Play** enrollment surface, and the
> **Google Admin console** (for Google Workspace / Cloud Identity integration) are authored at exact,
> current click-by-click / cmdlet detail from Microsoft's and Google's public documentation. The
> **Android Management API (AMAPI)** transition (Intune's move off the legacy Play EMM API) and
> **web-based / account-driven enrollment** are **actively evolving** — steps, defaults, and whether a
> change triggers **re-enrollment** are **cited or flagged "verify against current Microsoft guidance /
> your tenant"**, never asserted from memory or invented. **OEM specifics** (Samsung Knox, Zebra, and
> other rugged/kiosk vendors) and **third-party apps** are integrated at the pattern level; their
> consoles are deferred to the vendor's docs. Automation is **PowerShell** (Microsoft Graph) — never
> with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with Intune and Android Enterprise
- **Description:** A Microsoft 365 tenant with **Microsoft Intune** and Android Enterprise available,
  and the licensing the capability requires.
- **Why required:** All Android policy, enrollment, and app configuration is performed in Intune.
- **How to verify:** Sign in to the Intune admin center; confirm Android platform availability.
- **How to implement if missing:** Provision/assign Intune licensing before starting.

## 2. The managed Google Play binding (account enterprise OR Google Workspace)
- **Description:** Intune connected to **managed Google Play** — either the **managed Google Play
  account enterprise** (for tenants WITHOUT Google Workspace) or the **Google Workspace / Cloud Identity
  ↔ Intune third-party EMM** integration (for tenants that use Google Workspace). One and only one model
  applies per tenant.
- **Why required:** Android Enterprise enrollment and app delivery depend on the managed Google Play
  connection; the two binding models are mutually exclusive and must be chosen deliberately.
- **How to verify:** Intune admin center → **Devices > Android > Android enterprise (or Enrollment)** —
  confirm the connection status and which model is in place.
- **How to implement if missing:** Establish the correct binding (this is often the first solution in the
  line) before enrolling devices.

## 3. Administrative access (least-privilege Intune roles)
- **Description:** Access with the least-privilege role the solution names — typically **Intune
  Administrator**, with **Global Administrator** only where genuinely required (e.g. the initial managed
  Google Play / Google Workspace binding).
- **Why required:** Enrollment, connector, and app changes require the corresponding role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 4. Enrollment method decision and Graph/PowerShell toolchain
- **Description:** A decided **enrollment method** — personally-owned **work profile** (BYOD), **fully
  managed**, **corporate-owned work profile**, or **dedicated / COSU (kiosk)** — plus a workstation with
  **Microsoft Graph PowerShell** for automation.
- **Why required:** Profiles, restrictions, and app assignment differ by enrollment method; the provided
  scripts run through Graph.
- **How to verify:** Confirm the target enrollment method(s) with the device owners; `Connect-MgGraph`
  succeeds.
- **How to implement if missing:** Choose the enrollment method and install Graph PowerShell before starting.

## 5. Network reachability to Google & Microsoft endpoints
- **Description:** Devices and the enrollment path can reach the required **Google (managed Google Play,
  Android)** and **Microsoft (Intune, Entra)** service endpoints (no proxy/filter blocks the enrollment
  or account sign-in).
- **Why required:** Enrollment, managed Google Play account provisioning, and adding a Google account all
  require reachability; blocked endpoints are a common cause of "can't add a Google account" failures.
- **How to verify:** Confirm the required endpoints are allowed on the device network.
- **How to implement if missing:** Allow the documented Google/Microsoft endpoints before enrolling.

## 6. A pilot scope and change control
- **Description:** A **pilot group / small device set** to validate on before fleet-wide rollout, and a
  **change-control** process for production changes (enrollment-model, connector, and AMAPI-migration
  changes are high-impact and may affect existing devices).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; the pilot proves the design and protects the production fleet.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

*The deployment model across every Android solution is the same: **Assess → Design → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.
Automation is delivered as **PowerShell** (Microsoft Graph) — never with hardcoded credentials or
secrets. Where the AMAPI transition or enrollment behavior is version-dependent, verify against current
Microsoft guidance rather than assuming.*


---


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


---


# 5. Testing & Validation Guide — Android Enterprise Connection & Managed Google Play Setup

Validate the foundation with explicit **pass/fail gates**. Do **not** expand past the pilot until every
gate passes. Run the read-only scripts (`ANDROIDENT-Discovery.ps1`, `ANDROIDENT-Report.ps1`) to gather
evidence; confirm the device-side behavior by hand on the pilot devices.

> **Pilot-first rule.** Every gate is measured on the **pilot scope** (`Android AE - Pilot - Stage` and the
> per-model pilot groups) before any production expansion.

---

## Gate A — Managed Google Play binding is healthy
**What good looks like:** the connection is **bound / connected**, owned by the **organization Google
account** (not a personal Gmail), and the **app catalog sync** succeeded recently.

| Check | How | Pass |
| --- | --- | --- |
| Connection bound | `ANDROIDENT-Discovery.ps1` → bind status | Status is **bound** |
| Owner is org account | Intune → Android enterprise → owner account | Organization-owned account (Req 2.2) |
| App sync succeeded | `ANDROIDENT-Discovery.ps1` → last app sync | **Success**, recent timestamp |

**Fail →** see Troubleshooting (binding not bound / app sync failing — usually endpoint reachability or the
owner account).

---

## Gate B — Enrollment restrictions enforce the intended models
**What good looks like:** the `Android Enterprise - Platform Restrictions - Pilot` restriction **allows**
the models this pilot needs (incl. personally-owned work profile for BYOD), **blocks** unwanted models
(and legacy device administrator unless required), and is **assigned to the pilot scope only**.

| Check | How | Pass |
| --- | --- | --- |
| Allowed models correct | `ANDROIDENT-Discovery.ps1` → Android restriction | Matches the Req 2.4 plan |
| BYOD enabled (if in scope) | Restriction allows personally-owned work profile | Allowed |
| Legacy DA blocked | Restriction → Android device administrator | **Blocked** (unless justified) |
| Scoped to pilot | Restriction assignment | `Android AE - Pilot - Stage` only |

**Fail →** re-run `ANDROIDENT-Set-EnrollmentRestrictions.ps1` (preview first) and re-assign.

---

## Gate C — Each enrollment model enrolls correctly
**What good looks like:** one device of **each** model in scope enrolls the right way.

| Model | How | Pass |
| --- | --- | --- |
| **BYOD work profile** | Company Portal enrollment on a personal phone | A **work profile** is created; personal space untouched |
| **Fully managed** | QR/token enroll a reset company device (`Android FM - Enroll - Pilot`) | Whole device managed, **no** personal space |
| **Corporate-owned work profile** | Enroll with `Android COPE - Enroll - Pilot` | Managed **work profile + personal space** on a company device |
| **Dedicated / COSU** | Enroll with `Android COSU - Enroll - Pilot` | Device enrols **no user affinity** (kiosk-ready) |

Confirm in Intune → **Devices** that each pilot device shows the expected **ownership** (corporate /
personal) and **management** state. `ANDROIDENT-Report.ps1` summarizes this per model.

**Fail →** see Troubleshooting (per-model enrollment failures; "can't add a Google account").

---

## Gate D — Reporting reconciles and the profiles exist
**What good looks like:** the corporate-owned enrollment profiles exist and the report reconciles enrolled
devices to the expected models.

| Check | How | Pass |
| --- | --- | --- |
| Profiles present | `ANDROIDENT-Discovery.ps1` → enrollment profiles | `Android FM/COPE/COSU - Enroll - Pilot` present |
| Per-model coverage | `ANDROIDENT-Report.ps1` | Each in-scope model shows ≥1 enrolled pilot device |
| No unexpected models | `ANDROIDENT-Report.ps1` | No devices enrolled via a blocked model |

---

## Regression / periodic checks
- **Token / connection expiry** — corporate-owned enrollment tokens and the managed Google Play connection
  have lifecycles; `ANDROIDENT-Discovery.ps1` surfaces token expiry. Schedule a periodic
  `ANDROIDENT-Report.ps1`.
- **AMAPI transition watch** — because AMAPI, web/account-driven enrollment, and re-enrollment behavior are
  **evolving**, re-validate Gates B and C after any Microsoft-announced Android enrollment change, and
  **verify re-enrollment behavior on your own tenant** before assuming.

> **Expansion gate:** expand past the pilot only when **A, B, C, and D all pass** on the pilot scope.


---


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


---


# 7. Best Practices — Android Enterprise Connection & Managed Google Play Setup

Operating principles for a clean, durable Android Enterprise foundation in Intune.

## Binding & ownership
- **Own the managed Google Play owner account.** Bind managed Google Play with an
  **organization-controlled** Google account, never a personal Gmail or an individual admin's account.
  Record the account identity (not its password) so it survives staff changes.
- **Commit to one binding model deliberately.** Account enterprise (no Google Workspace) and the Google
  Workspace ↔ Intune EMM are **mutually exclusive**. Decide with the identity owner and document the
  decision; switching later is disruptive.
- **Never disconnect the connection to "test."** Disconnecting managed Google Play **un-enrols** Android
  Enterprise devices. Treat disconnect as a change-controlled, last-resort action only.

## Enrollment restrictions
- **Restrict to the models you actually use.** Allow personally-owned work profile only where BYOD is
  intended; allow corporate-owned device-owner enrollment only where you issue company devices. Block
  everything else — restrictions are the gate that keeps the wrong model out.
- **Block legacy Android device administrator** unless a specific legacy requirement exists. Android
  Enterprise is the modern, supported model.
- **Scope before you enforce.** Assign a new/changed restriction to the **pilot group first**; restrictions
  apply at **enrollment time**, so validate on new enrollments before widening.

## Enrollment models
- **Match the model to ownership and privacy.** BYOD → personally-owned work profile (personal data stays
  private). Company single-user → fully managed or corporate-owned work profile. Company shared/kiosk →
  dedicated/COSU (no user affinity).
- **Corporate-owned models require a reset device.** Fully managed / COPE / COSU enrol at **first-run**;
  plan device staging (or zero-touch) accordingly.
- **Keep enrollment tokens/QRs controlled.** They enrol devices — treat them as sensitive, set sane
  expiries, and rotate rather than sharing broadly.

## Pilot, change control, and the AMAPI transition
- **Assess → Design → Configure → Pilot → Validate → Expand** — always. Prove every change on the pilot,
  with pass/fail gates and a documented rollback.
- **Treat connector / enrollment-model changes as high-impact.** They can affect which devices enrol and,
  where AMAPI is in play, potentially re-enrollment.
- **Do not assume re-enrollment behavior.** The **AMAPI transition**, web/account-driven enrollment, and
  whether a change triggers **re-enrollment** are **actively evolving** — **verify against current Microsoft
  guidance and test on your own tenant** before any production change. Re-validate after Microsoft-announced
  Android enrollment changes.

## OEM & third-party (pattern level)
- **Layer OEM controls on top, don't replace the foundation.** Samsung Knox, Zebra, and other rugged/kiosk
  vendors extend Android Enterprise; configure their specifics in the vendor console (deferred to their
  docs) **after** the base enrollment model is correct.

## Automation & security
- **Safe-by-default automation.** Run the read-only scripts (`ANDROIDENT-Discovery.ps1`,
  `ANDROIDENT-Report.ps1`) freely; the config scripts default to `-WhatIf` — preview, then `-Apply`.
- **Least privilege.** Global Administrator for the one-time binding only; Intune Administrator for
  ongoing restriction/profile work.
- **No secrets in code.** The scripts use interactive delegated Graph sign-in — never hardcode credentials,
  tokens, or the Google owner account password.
- **Document the estate.** Record the binding model, owner account identity, restriction plan, and the
  enrollment-profile names so the next operator can reason about the foundation.


---


# 8. Deliverables Summary — Android Enterprise Connection & Managed Google Play Setup

Everything included in this solution, and how the pieces fit together.

## Documentation
- **Solution Overview** — what the foundation is, the two mutually-exclusive managed Google Play binding
  models (account enterprise vs Google Workspace EMM), the four Android Enterprise enrollment models and
  when to use each, and an honest note on the evolving AMAPI transition.
- **Requirements Guide** — the solution-specific prerequisites (binding decision, org-owned Google owner
  account, role model, enrollment-restriction plan, device supply, endpoint reachability, Graph toolchain),
  building on the shared Android **Global Requirements**.
- **Implementation Guide** — ordered steps: assess, scope groups, connect managed Google Play, confirm app
  sync, configure the Android enrollment platform restriction, create the FM / COPE / COSU enrollment
  profiles, pilot-enroll one device per model, validate, expand — each artifact named, pilot-first, with
  pass/fail gates and rollback.
- **Testing & Validation Guide** — Gates A–D (binding healthy, restrictions enforce intended models, each
  model enrolls correctly, reporting reconciles) with pass criteria and an AMAPI re-validation watch.
- **Troubleshooting Guide** — symptom → root-cause → fix for binding, app sync, "can't add a Google
  account," per-model enrollment failures, restriction mis-scope, and AMAPI-related uncertainty.
- **Best Practices** — binding/ownership, restriction discipline, model-to-ownership matching, pilot &
  change control, the AMAPI "verify, don't assume" rule, OEM layering, and automation/security hygiene.
- **Executive Summary** — the business case for getting the foundation right the first time.

## PowerShell (Microsoft Graph) tools — 5 scripts
All are safe-by-default (read-only, or `-WhatIf` unless `-Apply`), use interactive delegated `Connect-MgGraph`
with least scopes, and contain **no** hardcoded credentials or secrets.

| Script | Purpose | Safety |
| --- | --- | --- |
| **ANDROIDENT-Discovery.ps1** | Assess the managed Google Play connection (bind status, app sync, owner), the Android enrollment platform restrictions, and existing corporate-owned enrollment profiles. | Read-only |
| **ANDROIDENT-Set-ScopeTargeting.ps1** | Create the pilot/prod scope groups and the per-model groups; report the enrollment-restriction assignment. | Default `-WhatIf`; `-Apply` to change |
| **ANDROIDENT-Set-EnrollmentRestrictions.ps1** | Configure the Android enrollment platform restriction (allow the intended models, block the rest). | Default `-WhatIf`; `-Apply` to change |
| **ANDROIDENT-New-EnrollmentProfile.ps1** | Create a corporate-owned enrollment profile per model (fully managed / corporate-owned work profile / dedicated). | Default `-WhatIf`; `-Apply` to change |
| **ANDROIDENT-Report.ps1** | Android Enterprise readiness + per-model enrollment coverage (ownership/management), restriction and profile inventory. | Read-only |

## What is deferred (by design)
- The **managed Google Play sign-in** (Google-hosted account binding) and **Google Admin console** actions
  → Google's official documentation.
- **OEM specifics** (Samsung Knox, Zebra, etc.) and **third-party apps** → the vendor's docs (pattern
  level here).
- **AMAPI / web / account-driven enrollment and re-enrollment behavior** → verify against current
  Microsoft guidance / your tenant (flagged throughout, never asserted from memory).

## Outcome
A correct Android Enterprise foundation in Intune — **managed Google Play bound**, **enrollment models
configured**, **restrictions enforced**, validated on a pilot — so devices enrol the right way and app
delivery, compliance, and per-model lockdown build on it without rework.
