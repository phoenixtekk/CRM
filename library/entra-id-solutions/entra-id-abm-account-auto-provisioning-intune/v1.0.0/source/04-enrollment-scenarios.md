# 4. Enrollment Scenarios — How the Federated Identity + Managed Apple ID Flows into Each Model

This section details how the same foundation — **Entra federation + an auto-provisioned Managed Apple
ID** — feeds each of the three iPhone models, and what the **end-user sign-in experience** looks like
per model. All three are first-class; keep them cleanly separated by the per-scenario groups from the
Implementation Guide.

> **Shared identity, three behaviors.** In every model the user authenticates to Apple via **Entra ID**
> and uses a **Managed Apple ID** provisioned from Entra. What differs is *user affinity* (who the
> device belongs to), *supervision*, and *where the identity is bound* (to the device, to the user's
> work partition, or to an app/service).

---

## 4.1 Corporate-Owned (COD) — supervised, account-driven device enrollment

**What it is:** A company-owned iPhone, enrolled zero-touch via **Automated Device Enrollment (ADE)**
from Apple Business Manager, **supervised**, with **user affinity** so the device is tied to its
assigned employee.

**How the identity flows:**
- The device serial is assigned to the **`Intune – iOS COD`** MDM server in ABM and receives the
  **`iOS COD – ADE – Pilot`** profile.
- During **Setup Assistant**, the phone shows **Remote Management** for your organization. Because the
  profile is **account-driven**, the user signs in with their **Entra credentials**; their
  **auto-provisioned Managed Apple ID** is used for managed Apple services.
- Device sits in **`iOS COD – Devices – Pilot`** and gets **`iOS COD – Compliance – Pilot`**.

**End-user sign-in experience:** Power on a new/erased phone → connect to network → see
"Remote Management" naming the company → **sign in with work email + Entra password (and MFA)** → the
phone finishes setup already managed and supervised, signed in with the Managed Apple ID. No personal
Apple ID, no separate Apple password.

**Use when:** the organization owns the phone and wants full control and zero-touch provisioning.

---

## 4.2 BYOD — account-driven User Enrollment (privacy-preserving)

**What it is:** A personal iPhone enrolled with **account-driven User Enrollment**, the modern model
that uses the **Managed Apple ID + Entra federated sign-in** to create a **cryptographically separated
managed (work) partition**, leaving the user's personal data and **personal Apple ID** untouched.

**How the identity flows:**
- The user is a member of **`iOS BYOD – Users – Pilot`** (user-scoped, not device-scoped).
- The user starts enrollment from **device settings**; iOS prompts for the **work account**, redirects
  the sign-in to **Entra** (federated), and uses the **federated Managed Apple ID** to stand up the
  managed work partition.
- The device receives **`iOS BYOD – Compliance – Pilot`**; only work apps/data live in the managed
  partition — Intune cannot see or wipe personal data.

**End-user sign-in experience:** Settings → add the work account / start enrollment → **sign in with
work email + Entra password (and MFA)** → a separate, managed work area appears for company apps; the
personal side (personal Apple ID, photos, messages) is unchanged. The user keeps their own Apple ID
for personal use **and** has a Managed Apple ID for work.

**Use when:** employees use personal phones and privacy/separation matters; no ADE token is required.

---

## 4.3 Shared — no user affinity + Managed Apple ID / shared app sign-in

**What it is:** An appliance iPhone enrolled via ADE with **no user affinity**, supervised, locked
down. Staff are **not** bound to the device as primary users; identity lives in the **Managed Apple ID
/ a shared sign-in to the relevant app/service**.

**Accurate scope:** iPhones do **not** have Apple's multi-user **Shared iPad** feature (that is
iPad-only). "Shared iPhone" here means **no-affinity enrollment + restrictions**, with staff signing in
to the app/service that matters using a Managed Apple ID or a shared account — not personalizing the
device.

**How the identity flows:**
- The device serial is assigned to its MDM server in ABM and receives **`iOS Shared – ADE – Pilot`**
  (**Enroll without user affinity**, **Supervised**, **Locked enrollment**).
- The device joins **`iOS Shared – Devices – Pilot`** and gets **`iOS Shared – Compliance – Pilot`**.
- Staff identity is **not** the device login; it is the **Managed Apple ID / shared app sign-in** used
  inside the relevant managed app or service.

> **Targeting note (Assigned group + owner):** When `iOS Shared – Devices – Pilot` is an **Assigned**
> security group, enrollment-time device grouping only populates it if the **Intune Provisioning
> Client** service principal (**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, often shown as **`Intune
> Autopilot ConfidentialClient`**) is an **Owner** of the group — otherwise the group stays empty at
> enrollment and no shared-device profiles/apps deploy. Match by **AppId**, not the display name, and
> verify in your tenant. See Implementation Step 11 and Requirement 2.10. The group must be **Assigned**,
> never Dynamic, for this mechanism (the same principal Windows Autopilot device preparation uses).

**End-user sign-in experience:** The phone is already set up and locked down — no per-user device
sign-in. A staff member picks it up and **signs in to the relevant app/service** (with a Managed Apple
ID or a shared account) to do their task, then hands it on. The device itself stays generic.

**Use when:** phones are shared across staff/shifts (front desk, floor, kiosk-style) and you want a
generic, controlled device rather than a personal one.

---

## 4.4 Keeping the three cleanly separated
- **COD** → device group **`iOS COD – Devices – Pilot`**, profile **`iOS COD – ADE – Pilot`**.
- **BYOD** → user group **`iOS BYOD – Users – Pilot`**, profile **`iOS BYOD – User Enrollment – Pilot`**.
- **Shared** → device group **`iOS Shared – Devices – Pilot`**, profile **`iOS Shared – ADE – Pilot`**.

Never assign more than one model's enrollment profile / compliance policy to the same device or user.
Use **`ABMPROV-Set-ScopeTargeting.ps1`** to build the groups consistently and **`ABMPROV-Report.ps1`**
to confirm each device lands in exactly one model.

| Model | Owner | User affinity | Supervised | Identity is bound to | Needs ADE token |
|---|---|---|---|---|---|
| **COD** | Company | Yes | Yes | The device (assigned user) | Yes |
| **BYOD** | Employee | User-scoped | No | The managed work partition | No |
| **Shared** | Company | No (no affinity) | Yes | The app/service (Managed Apple ID) | Yes |
