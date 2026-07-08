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
