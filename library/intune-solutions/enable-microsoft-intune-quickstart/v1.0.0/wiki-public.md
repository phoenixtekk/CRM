# Enable Microsoft Intune — Quick-Start (New or Existing Tenant)

> **Free preview of the Workplace solution catalog.** This complete, click-by-click guide gets Microsoft Intune up and running — a brand-new tenant or an existing one — and enrolls a **Windows PC** and an **iPhone** end to end. It is genuinely useful *and* a taste of how every solution in the catalog is built: the same house style, the same tested PowerShell, the same pilot-first method.
>
> **Corporate zero-touch iPhone enrollment (Apple Business Manager / ADE)** is the one piece that lives outside Intune — this guide shows exactly where it fits and points you to the full **Apple Business Manager** solution in the catalog at **[workplace.phoenixtekk.com](https://workplace.phoenixtekk.com)**.

---



# Executive Summary — Enable Microsoft Intune (Quick-Start)

This Quick-Start takes you from **no device management** to a **working Microsoft Intune** in a single,
short session — whether you are standing up a **brand-new Microsoft 365 tenant** or **turning Intune on
for the first time in an existing tenant**. When you finish, Intune is the enrollment authority, the
basics and sensible defaults are in place, and you can **enroll and manage a Windows PC and an iPhone
(iOS/iPadOS)** end to end.

It is intentionally focused on the **fundamentals** — the smallest set of correct steps that gives you a
functioning Intune you can build on. It is not an exhaustive hardening guide; it is the confident first
mile.

## What you will accomplish
- Confirm licensing and set **Intune as the MDM authority** (a one-time tenant switch).
- Configure the **tenant-wide enrollment defaults** so the right platforms enroll and the wrong ones
  are blocked.
- Turn on **automatic Windows enrollment** so Entra-joined PCs manage themselves.
- Add the **Apple MDM push certificate** so iPhones and iPads can enroll.
- Apply a **minimal baseline** (one compliance policy, one configuration profile) so devices report
  health from day one.
- **Enroll a Windows device and an iPhone**, and confirm both check in and show as compliant.

## Where the boundary is (and where to go next)
Personal/BYOD iPhone enrollment works with only the Intune-side steps in this guide. **Corporate,
zero-touch iPhone enrollment (Automated Device Enrollment)** additionally requires **Apple Business
Manager (ABM)** — an Apple portal that lives *outside* Intune. This guide tells you exactly where ABM
fits and **points you to the dedicated catalog solution** that walks ABM setup end to end (see
`04-enrollment-scenarios.md`), so you are never left guessing.

## Why this exists
This Quick-Start is a **free preview** of the full solution catalog. It is written in the same
click-by-click house style, ships the same tested-script quality, and follows the same pilot-first
method as every paid solution — so you can see exactly what to expect before you buy. Once Intune is
live, the catalog picks up where this leaves off: Autopilot zero-touch, Conditional Access, compliance
at scale, application deployment, and more.

## Effort and outcome
A competent administrator completes the tenant-side configuration in well under an hour, plus a few
minutes per test device. The outcome is a **functioning Intune** with a repeatable enrollment path for
Windows and iOS — a foundation, not a dead end.


# Solution Overview — Enable Microsoft Intune (Quick-Start)

## What this is
Microsoft Intune is the cloud service that enrolls, configures, secures, and reports on your
organization's devices — Windows PCs, iPhones/iPads, Macs, and Android. This Quick-Start enables Intune
with the **basics and defaults** so it becomes your device-management authority and can immediately
manage a **Windows** device and an **iPhone (iOS/iPadOS)**.

It covers the two ways organizations arrive here:

- **New tenant** — you just created a Microsoft 365 / Entra tenant (or are setting one up) and nothing
  is configured yet.
- **Existing tenant** — Microsoft 365 is already in use (mail, Teams, Entra ID) but Intune has never
  been turned on.

The steps are the same at the core; where a new tenant needs an extra confirmation (e.g. verifying a
domain, assigning your first licenses), this guide calls it out.

## How Intune works (the short version)
1. **Identity first.** Every device and user is an object in **Microsoft Entra ID** (formerly Azure AD).
   Intune trusts Entra for who the user is and which device is theirs.
2. **Licensing enables the service.** A user must hold an Intune license (standalone, or bundled in
   Enterprise Mobility + Security or a Microsoft 365 plan) to enroll devices.
3. **Enrollment brings a device under management.** A device enrolls into Intune, receives an MDM
   certificate, and from then on checks in for policy on a schedule.
4. **Policy configures and secures.** Configuration profiles set the device up; compliance policies
   define "healthy"; both are evaluated at every check-in.
5. **Reporting proves state.** The admin center shows each device's enrollment, configuration, and
   compliance status.

This Quick-Start puts the minimum of each in place: identity/licensing confirmed, enrollment turned on
for Windows and iOS, one configuration profile, and one compliance policy — enough for a **functioning
Intune**, not a full production hardening.

## The deployment model (the same across every solution)
Every solution — free or paid — follows the same repeatable shape, so each deployment feels familiar:

> **Assess → Configure → Pilot → Validate → Expand**

- **Assess** — confirm the prerequisites (licensing, roles, identity).
- **Configure** — set the tenant-wide switches and baseline policies.
- **Pilot** — enroll one Windows device and one iPhone.
- **Validate** — confirm both check in and report compliant, using the included scripts.
- **Expand** — when you are ready, roll out to more devices and layer on the deeper catalog solutions.

## What "functioning Intune" means when you finish
- Intune is the **MDM authority** for the tenant.
- **Windows** devices that are Entra-joined enroll **automatically**.
- **iPhones/iPads** can enroll (personal/BYOD) via the Company Portal.
- Every enrolled device receives a **baseline configuration** and is evaluated against a **compliance
  policy**.
- You can **see** device state in the Intune admin center and via the included reporting script.

## Supported enrollment in this Quick-Start
| Platform | Method covered here | External dependency |
|---|---|---|
| **Windows 10/11** | Automatic enrollment (Entra join → auto-MDM) | None |
| **iPhone/iPad — personal (BYOD)** | User enrollment via Company Portal + Apple MDM push certificate | None beyond the push certificate |
| **iPhone/iPad — corporate (zero-touch ADE)** | **Pointer only** — requires Apple Business Manager | **Apple Business Manager** (see `04-enrollment-scenarios.md`) |

## What is intentionally out of scope
This is a first-mile enablement. Zero-touch Autopilot, Conditional Access, app deployment, advanced
compliance, Defender integration, and Apple Business Manager setup are **deliberately not** covered in
depth here — each is its own catalog solution. Where one of them is the natural next step, this guide
points you to it.

## Auth and connections used
- **Microsoft Intune admin center** (`https://intune.microsoft.com`) — the primary UI.
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) — licensing, groups, MDM auto-enrollment scope.
- **Microsoft Graph PowerShell** (optional) — the included scripts use it read-only to verify and report state.
- You act as a **Global Administrator** (new-tenant setup) or an **Intune Administrator** (existing tenant).


# Requirements — Enable Microsoft Intune (Quick-Start)

Confirm each requirement below **before** you start. For every item: what it is, why it is required, how
to verify it, and how to put it in place if it is missing. Do not assume anything already exists —
especially in a brand-new tenant.

---

## 1. A Microsoft Entra / Microsoft 365 tenant
- **Description:** The cloud tenant that holds your users, groups, and devices.
- **Why required:** Intune is a workload inside your tenant; there is nothing to enable without one.
- **How to verify:** Sign in at `https://entra.microsoft.com`. If you reach the admin center, you have a
  tenant. Note the tenant's default domain (e.g. `contoso.onmicrosoft.com`).
- **How to implement if missing:** Create one by signing up for a Microsoft 365 or Microsoft Entra plan.
  For a brand-new tenant, also **add and verify your custom domain** (e.g. `contoso.com`) under
  **Entra admin center → Settings → Domain names** so users sign in with real addresses. Domain
  verification is a DNS TXT record you add at your registrar.

## 2. Global Administrator (or Intune Administrator) access
- **Description:** A role with permission to enable Intune and configure enrollment.
- **Why required:** Setting the MDM authority, enrollment defaults, and the Apple push certificate are
  tenant-level actions.
- **How to verify:** In **Entra admin center → Roles & admins**, confirm your account holds **Global
  Administrator** (new tenant) or at least **Intune Administrator** (existing tenant).
- **How to implement if missing:** Have an existing Global Administrator assign you the role, or use the
  tenant's first Global Administrator account created at sign-up.

## 3. Intune licenses assigned to your test users
- **Description:** An Intune entitlement, standalone or bundled in **Enterprise Mobility + Security (EMS)**
  or a **Microsoft 365** plan (e.g. Business Premium, E3/E5).
- **Why required:** A user cannot enroll a device unless they are licensed for Intune. This is the single
  most common reason enrollment fails.
- **How to verify:** In **Entra admin center → Billing → Licenses** (or **Microsoft 365 admin center →
  Billing → Licenses**), confirm you own Intune-bearing licenses and have **free seats**. Then confirm
  your test user is assigned one under the user's **Licenses** blade.
- **How to implement if missing:** Purchase/trial an Intune-bearing plan, then assign a license to each
  test user (directly or via a group). A **30-day trial** is sufficient to complete this Quick-Start —
  *verify current trial availability in your tenant*.

## 4. Two test accounts (or one) with mailbox-capable identities
- **Description:** A cloud user you will use to enroll the Windows device and the iPhone.
- **Why required:** Enrollment binds a device to a signed-in, licensed user.
- **How to verify:** In **Entra admin center → Users**, confirm at least one non-admin cloud user exists,
  is licensed (item 3), and can sign in.
- **How to implement if missing:** Create a user under **Users → New user**, assign an Intune license, and
  set a password you can use on the test devices. Name it clearly, e.g. `Intune Pilot User 01`.

## 5. A Windows 10/11 test device
- **Description:** A physical or virtual Windows 10 (1809+) or Windows 11 machine you can factory-reset or
  join fresh.
- **Why required:** To prove automatic Windows enrollment works.
- **How to verify:** Confirm the device runs a supported Windows edition (Pro, Enterprise, or Education —
  **not** Home) and can reach the internet.
- **How to implement if missing:** Use a spare PC or a cloud VM. If it is currently on a personal Microsoft
  account or domain, plan to **Entra-join** it during testing (covered in `05-testing.md`).

## 6. An iPhone or iPad test device
- **Description:** A physical iOS/iPadOS device running a currently supported iOS version.
- **Why required:** To prove iOS enrollment works. (iOS enrollment cannot be fully tested on a simulator.)
- **How to verify:** Confirm the device is on a supported iOS/iPadOS version and can install apps from the
  App Store.
- **How to implement if missing:** Use any supported iPhone/iPad. For this Quick-Start, **personal (BYOD)**
  enrollment is used; a corporate zero-touch device is not required here.

## 7. An Apple ID for the MDM push certificate
- **Description:** An Apple ID used to create and renew the **Apple MDM Push (APNs) certificate** that lets
  Intune talk to Apple devices.
- **Why required:** No iOS/iPadOS or macOS device can enroll in Intune without this certificate on the
  tenant.
- **How to verify:** In **Intune admin center → Devices → Enrollment → Apple → Apple MDM Push
  certificate**, check whether a certificate is present and its expiry.
- **How to implement if missing:** Create one during setup (`03-implementation.md`, step 4). **Use a
  dedicated organizational Apple ID** (e.g. `appleid@contoso.com`) — never a personal Apple ID — because
  the certificate must be **renewed annually by the same Apple ID**. Record which Apple ID you used.

## 8. Network access from devices
- **Description:** Devices must reach Microsoft Intune, Entra, and Apple/Windows notification endpoints.
- **Why required:** Enrollment and check-in are cloud calls.
- **How to verify:** Devices on normal internet access generally work. On restricted networks, confirm the
  Microsoft Intune network endpoints and Apple APNs (TCP 443 / 5223) are reachable — *verify against
  current Microsoft and Apple endpoint documentation*.
- **How to implement if missing:** Allow the documented endpoints through your firewall/proxy.

---

### About the boundary — Apple Business Manager
**Corporate, zero-touch iPhone enrollment (Automated Device Enrollment / ADE)** additionally requires an
**Apple Business Manager (ABM)** account and an enrollment token exchange with Intune. ABM is an Apple
portal that lives **outside** Intune and is **not required** to complete this Quick-Start (which uses
personal/BYOD iOS enrollment). When you are ready for zero-touch corporate iPhones, see
`04-enrollment-scenarios.md` for exactly where ABM fits and the dedicated catalog solution that covers
its setup end to end.


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


# Implementation — Enable Microsoft Intune (Quick-Start)

Follow these steps in order. Each step names the exact object to create so you can find, audit, and reuse
it later. Where a step only applies to a **new tenant**, it is marked. The whole tenant-side sequence
takes well under an hour.

> **Before you start:** sign in to the **Intune admin center** at `https://intune.microsoft.com` and the
> **Entra admin center** at `https://entra.microsoft.com` as a Global Administrator (new tenant) or Intune
> Administrator (existing tenant).

---

## Step 1 — (New tenant only) Verify your domain and create your pilot user
*Skip to Step 2 if your tenant already has verified users.*

1. In the **Entra admin center**, go to **Settings → Domain names → Add custom domain**.
2. Enter your domain (e.g. `contoso.com`), then add the shown **TXT record** at your DNS registrar and
   click **Verify**.
3. Go to **Users → All users → New user → Create new user**. Set:
   - **User principal name:** `pilot01@contoso.com`
   - **Display name:** `Intune Pilot User 01`
   - Set a password you will use on the test devices.
4. Leave this user selected — you will license it in Step 2.

## Step 2 — Confirm licensing and assign an Intune license
1. In the **Entra admin center**, go to **Billing → Licenses → All products** and confirm you hold an
   **Intune-bearing** license (Intune standalone, EMS E3/E5, or Microsoft 365 Business Premium / E3 / E5)
   with **free seats available**. If you have none, start a trial or purchase seats before continuing.
2. Go to **Users → All users**, select your pilot user (`Intune Pilot User 01`), open **Licenses →
   Assignments**.
3. Tick the Intune-bearing license, click **Save**. Repeat for any second test user.
4. **Verify:** the user's **Licenses** blade now lists the plan and shows **Microsoft Intune** as an
   enabled service plan.

## Step 3 — Set Intune as the MDM authority *(the enable switch)*
> On modern tenants the **MDM authority is already set to Intune** automatically. Confirm it; only set it
> if it shows "None."

1. In the **Intune admin center**, go to **Devices → Enroll devices → (or) Tenant administration →
   Overview**. The **MDM authority** is shown on the tenant overview.
2. If it reads **Microsoft Intune**, you are done with this step.
3. If it reads **None**, click **MDM authority** and set it to **Intune**, then **Save**. This is a
   one-time tenant switch.

## Step 4 — Add the Apple MDM Push (APNs) certificate *(enables all Apple enrollment)*
1. In the **Intune admin center**, go to **Devices → Enrollment → Apple → Apple MDM Push certificate**
   (older path: **Devices → Enroll devices → Apple enrollment → Apple MDM Push certificate**).
2. **Tick the "I grant Microsoft permission…" consent box.**
3. Click **Download your CSR** and save the `.csr` file.
4. Click **Create your MDM push certificate** — this opens the **Apple Push Certificates Portal**. Sign in
   with your **dedicated organizational Apple ID** (e.g. `appleid@contoso.com`), upload the `.csr`, and
   download the resulting `.pem` certificate.
5. Back in Intune, enter the **Apple ID you just used** (record it — renewal requires the same one), upload
   the `.pem`, and click **Upload**.
6. **Verify:** the blade now shows a **valid** certificate with an expiry ~1 year out and the Apple ID.

## Step 5 — Configure enrollment defaults (enrollment restrictions)
1. In the **Intune admin center**, go to **Devices → Enrollment → Enrollment device platform
   restrictions** (or **Devices → Enroll devices → Enrollment restrictions**).
2. Open the **All Users** default **device type restriction**.
3. For this Quick-Start, confirm **Windows (MDM)** and **iOS/iPadOS** are set to **Allow**. Leave
   personally owned as **Allow** for iOS (BYOD) for now.
4. If you want to keep the pilot tight, instead create a **new** device type restriction named
   `Enrollment – QuickStart – Pilot`, allow only **Windows (MDM)** and **iOS/iPadOS**, and assign it to a
   group containing only your pilot users (see Step 6). **Save.**

## Step 6 — Create a pilot group
1. In the **Entra admin center**, go to **Groups → New group**.
2. Set:
   - **Group type:** Security
   - **Group name:** `INTUNE – QuickStart – Pilot`
   - **Membership type:** Assigned
3. Add your pilot user(s) as members. Click **Create**. You will target the baseline policies (Steps 7–8)
   and, if used, the pilot enrollment restriction at this group.

## Step 7 — Turn on automatic Windows enrollment
1. In the **Entra admin center**, go to **Devices → Mobility (MDM and MAM) → Microsoft Intune**.
2. Set **MDM user scope** to **Some**, then select the group `INTUNE – QuickStart – Pilot` (or **All** if
   you want every Entra-joined Windows device to auto-enroll). Leave the **MDM discovery/terms/compliance
   URLs** at their defaults.
3. Click **Save.** From now on, when a device in scope is **Entra-joined**, Windows automatically enrolls
   it into Intune.

## Step 8 — Apply a minimal baseline (one compliance policy + one configuration profile)

### 8a. Compliance policy — Windows
1. In the **Intune admin center**, go to **Devices → Compliance → Create policy**. Platform:
   **Windows 10 and later**. Click **Create**.
2. **Name:** `Compliance – Windows – Baseline`.
3. Set a couple of sensible basics — e.g. **Require BitLocker: Require**, **Minimum OS version** to a
   supported build, **Firewall: Require**. Keep it light.
4. On **Actions for noncompliance**, leave the default *Mark device noncompliant immediately*.
5. **Assignments:** assign to `INTUNE – QuickStart – Pilot`. **Create.**

### 8b. Compliance policy — iOS/iPadOS
1. **Devices → Compliance → Create policy**. Platform: **iOS/iPadOS**. **Create**.
2. **Name:** `Compliance – iOS – Baseline`.
3. Set **Require a password to unlock mobile devices: Require**, **Minimum OS version** to a supported
   version. Keep it light.
4. **Assignments:** assign to `INTUNE – QuickStart – Pilot`. **Create.**

### 8c. Configuration profile — a harmless proof-of-config
1. **Devices → Configuration → Create → New policy**. Platform **Windows 10 and later**, Profile type
   **Settings catalog**. **Create**.
2. **Name:** `Config – Windows – Baseline`.
3. Add one benign setting (e.g. set a **device name template** or a **desktop/lock-screen** value) so you
   can confirm configuration reaches the device.
4. **Assignments:** assign to `INTUNE – QuickStart – Pilot`. **Create.**

> That is the whole tenant-side enablement. Intune is now the authority, Apple enrollment is unlocked,
> Windows auto-enrolls in scope, and every pilot device gets a baseline. Proceed to
> `04-enrollment-scenarios.md` to understand the enrollment paths, then `05-testing.md` to enroll your two
> devices and confirm.


# Enrollment Scenarios — Windows & iOS (and where Apple Business Manager fits)

This section explains the enrollment paths this Quick-Start enables, so you know **which method to use for
which device** — and exactly where the one external dependency (Apple Business Manager) comes in.

---

## Windows enrollment

### Automatic enrollment (covered here)
Because you turned on **MDM auto-enrollment** (implementation Step 7), any Windows 10/11 device that is
**Entra-joined** by an in-scope, licensed user is **automatically enrolled** into Intune — no extra action
on the device. This is the path used in testing.

- **When to use:** company-standard PCs signed in with a work account.
- **What the user does:** joins the device to Entra during out-of-box setup or via **Settings → Accounts →
  Access work or school → Connect → Join this device to Microsoft Entra ID**.

### What's next for Windows (paid catalog)
Zero-touch, pre-provisioned Windows (ship the PC straight to the user, self-deploying) is **Windows
Autopilot** — beyond this Quick-Start. See the catalog solution **"Cloud-First Autopilot Zero-Touch
Provisioning"** when you are ready.

---

## iPhone / iPad (iOS/iPadOS) enrollment

There are **two** ways to enroll Apple devices. This Quick-Start fully enables the first; the second needs
Apple Business Manager.

### 1. Personal / BYOD enrollment (covered here)
With the **Apple MDM push certificate** in place (implementation Step 4), a user can enroll their own
iPhone through the **Company Portal** app:

- **When to use:** employee-owned iPhones/iPads; quick pilots; getting Intune working today.
- **What the user does:** installs **Intune Company Portal** from the App Store, signs in with their
  licensed work account, and follows the prompts to enroll. Management profile is user-approved.
- **Requirement:** only the tenant-level Apple MDM push certificate — **no Apple Business Manager needed.**
  This is the path used in `05-testing.md`.

### 2. Corporate zero-touch enrollment — Automated Device Enrollment (ADE) — **requires Apple Business Manager**
For **company-owned** iPhones/iPads that should enroll **automatically at first power-on**, supervised and
locked to your organization, you use **Automated Device Enrollment (ADE)**, formerly DEP. ADE depends on
**Apple Business Manager (ABM)** — an Apple portal, **separate from Intune**, where your organization's
purchased devices are registered and assigned to your MDM (Intune).

**Why it's a separate step:** ABM is operated by Apple, tied to your organization's **D-U-N-S number** and
verified business identity, and it is where Apple device tokens are generated and exchanged with Intune.
None of that happens inside the Intune admin center, so it cannot be covered by an Intune-only Quick-Start.

**The one-paragraph shape of ADE (so you know what's involved):** enroll your organization in Apple
Business Manager → download a public key from Intune's ADE token page → upload it in ABM to create an
**MDM server token** → upload that token back into Intune → assign your ABM devices to the Intune MDM
server → create an **ADE enrollment profile** in Intune → devices enroll automatically on activation.

> ### ⭐ Get the full Apple Business Manager walkthrough
> Setting up Apple Business Manager and wiring it to Intune for zero-touch iPhone enrollment is covered
> **end to end** in a dedicated solution in the Workplace catalog:
>
> **→ "Implement Entra ID Integration with ABM for Account Auto Provisioning for Microsoft Intune"**
> — available at **workplace.phoenixtekk.com** (search the catalog for *Apple Business Manager* or *ABM*).
>
> That solution walks the ABM enrollment, the token exchange, device assignment, and the Intune ADE
> enrollment profile with the same click-by-click detail you see in this free Quick-Start. When you need
> corporate zero-touch iPhones, start there.

---

## Which method should I use?

| Your situation | Use this | Covered in this Quick-Start? |
|---|---|---|
| Company Windows PCs signed in with work accounts | **Automatic Windows enrollment** | ✅ Yes |
| Employee-owned iPhones (BYOD) | **Company Portal user enrollment** | ✅ Yes |
| Company-owned iPhones, zero-touch at first boot | **ADE via Apple Business Manager** | ➡️ Pointer to the ABM catalog solution |
| Ship-to-user zero-touch Windows | **Windows Autopilot** | ➡️ Pointer to the Autopilot catalog solution |

For this Quick-Start you will enroll **one Windows PC (automatic)** and **one iPhone (BYOD via Company
Portal)** — both require nothing beyond what you configured in `03-implementation.md`.


# Testing & Validation — Enable Microsoft Intune (Quick-Start)

Prove the enablement worked by enrolling one Windows PC and one iPhone, then confirming both check in and
report compliant. Use the included scripts to verify tenant state without clicking through every blade.

---

## Pre-check — confirm the tenant is ready
Run the Discovery script first (see the Scripts appendix / `scripts\` folder):

```
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All","DeviceManagementConfiguration.Read.All","Directory.Read.All"
.\ITSTART-Discovery.ps1
```

**Expect:** it reports the MDM authority = Intune, an Apple MDM push certificate present (with expiry),
Windows auto-enrollment scope configured, and your pilot group and baseline policies found. Fix any ❌
before enrolling devices.

---

## Test 1 — Enroll the Windows device (automatic)
1. On the test PC, ensure it is **not** already managed. Go to **Settings → Accounts → Access work or
   school**.
2. Click **Connect**, then **"Join this device to Microsoft Entra ID."**
3. Sign in as your pilot user (`pilot01@contoso.com`) and complete the join. Reboot if prompted.
4. Sign in to the PC with the pilot user. Automatic enrollment runs in the background.

**Validate:**
- On the PC: **Settings → Accounts → Access work or school → (your account) → Info**. Under **Device sync
  status**, click **Sync** and confirm areas report successfully.
- In the **Intune admin center → Devices → All devices**, the PC appears, **Managed by = Intune**, and
  after a check-in shows **Compliant** against `Compliance – Windows – Baseline`. Confirm the setting from
  `Config – Windows – Baseline` applied.

## Test 2 — Enroll the iPhone (personal / BYOD via Company Portal)
1. On the iPhone, install **Intune Company Portal** from the App Store.
2. Open it and **sign in** as your pilot user.
3. Follow the prompts: tap **Begin → Continue**, allow the **management profile** download, then go to
   **Settings → Profile Downloaded → Install** and confirm with the device passcode.
4. Return to Company Portal and finish; it confirms the device is now managed.

**Validate:**
- In **Company Portal**, the device shows **"Can access company resources"** / compliant.
- In **Intune admin center → Devices → All devices**, the iPhone appears, **Managed by = Intune**, and
  reports **Compliant** against `Compliance – iOS – Baseline` after check-in.

## Test 3 — Confirm reporting end to end
Run the reporting script for a clean summary of what enrolled and its compliance:

```
.\ITSTART-Report.ps1 -OutCsv .\quickstart-enrollment.csv
```

**Expect:** a table (and CSV) listing your two devices with platform, ownership, management state, and
compliance — proof that Intune is functioning for both Windows and iOS.

## Test 4 — Validate the enablement checklist
Run the validation script to score the enablement against the Quick-Start's success criteria:

```
.\ITSTART-Validate.ps1
```

**Expect:** all checks **PASS** — MDM authority set, Apple push certificate valid, Windows auto-enrollment
on, baseline compliance policies assigned, and at least one Windows + one iOS device enrolled and
compliant. Any **FAIL** points you to the exact step to revisit.

---

## Success criteria (you are done when all are true)
- ✅ MDM authority = **Microsoft Intune**.
- ✅ Apple MDM push certificate is **valid**.
- ✅ Windows automatic enrollment is **enabled** for the pilot scope.
- ✅ One **Windows** device is enrolled and **compliant**.
- ✅ One **iPhone** is enrolled and **compliant**.
- ✅ Baseline configuration and compliance policies are **assigned and evaluating**.

When these hold, you have a **functioning Intune** — ready to expand to more devices and layer on the
deeper catalog solutions.


# Troubleshooting — Enable Microsoft Intune (Quick-Start)

Work the symptom to the most specific cause. All checks here are read-only; you never need to delete the
tenant configuration to diagnose. Run `ITSTART-Discovery.ps1` first — it surfaces most of these states at
a glance.

## Enrollment fails immediately with a licensing error
- **Symptom:** the user sees "Your account is not configured for enrollment" / "You need an Intune
  license."
- **Most likely:** the enrolling user has **no Intune-bearing license**, or the license lacks free seats.
- **Fix:** in **Entra admin center → Users → (user) → Licenses**, confirm an Intune-bearing plan is
  assigned and **Microsoft Intune** shows as an enabled service plan. Assign one if missing. This is the
  #1 cause of failed enrollment.

## Windows device joins Entra but never enrolls in Intune
- **Cause:** the device (or its user) is **out of scope** for MDM auto-enrollment, or is not actually
  Entra-*joined* (only "registered"/Workplace-joined).
- **Fix:** in **Entra admin center → Devices → Mobility (MDM and MAM) → Microsoft Intune**, confirm **MDM
  user scope** includes the user (Some → your pilot group, or All). On the PC, **Settings → Accounts →
  Access work or school** should show it **joined to Microsoft Entra ID**, not just "Connected." Trigger a
  sync and re-check `Devices → All devices` in Intune.

## iPhone enrollment stops — "Cannot connect to the server" or profile won't install
- **Cause:** the **Apple MDM push certificate** is missing or expired, or the management profile wasn't
  installed in iOS Settings.
- **Fix:** in **Intune admin center → Devices → Enrollment → Apple → Apple MDM Push certificate**, confirm
  a **valid** certificate (not expired). If expired, renew it **with the same Apple ID** that created it.
  On the device, complete **Settings → Profile Downloaded → Install**. `ITSTART-Discovery.ps1` reports the
  certificate's presence and expiry.

## Apple push certificate can't be renewed
- **Cause:** renewal was attempted with a **different Apple ID** than the one that created it.
- **Fix:** the APNs certificate must be renewed by the **original Apple ID** (recorded in the certificate
  blade). Using a new Apple ID creates a *new* certificate and **un-enrolls every existing Apple device** —
  avoid this. Always use a dedicated organizational Apple ID and store its credentials safely.

## MDM authority shows "None" and can't be changed
- **Cause:** on legacy or co-managed tenants the authority may be set elsewhere (e.g. Configuration
  Manager) or a role limitation.
- **Fix:** confirm you are a **Global Administrator**. On current tenants the authority is Intune by
  default; if it truly reads None, set it on the **Tenant administration → Overview / MDM authority**
  control. If co-management with Configuration Manager is in play, that is a deeper scenario beyond this
  Quick-Start — see the catalog co-management solutions.

## Device enrolls but never shows Compliant (stuck "In grace period" / "Not evaluated")
- **Cause:** the compliance policy isn't **assigned** to a group the device's user is in, or the device
  hasn't checked in yet.
- **Fix:** confirm `Compliance – Windows – Baseline` / `Compliance – iOS – Baseline` are **assigned** to
  `INTUNE – QuickStart – Pilot`, and the enrolled user is a **member**. Force a sync from the device; first
  evaluation can take a few minutes. `ITSTART-Validate.ps1` flags an unassigned baseline.

## "Personally owned iOS enrollment is blocked"
- **Cause:** an **enrollment restriction** blocks personally owned iOS, or blocks the iOS platform.
- **Fix:** in **Intune admin center → Devices → Enrollment → Enrollment device platform restrictions**,
  confirm **iOS/iPadOS** is **Allow** and **personally owned** is permitted for the pilot scope (or use the
  `Enrollment – QuickStart – Pilot` restriction described in implementation Step 5).

## Company Portal keeps asking to sign in / redirect loop
- **Cause:** the user isn't licensed, MFA is interrupting first enrollment, or the device time/date is
  wrong.
- **Fix:** confirm licensing (above), complete any MFA prompt, and verify the device clock is correct.
  Sign out fully in Company Portal and retry.

## New tenant — users can't sign in on devices
- **Cause:** the custom domain isn't verified, or the pilot user has no usable password/UPN.
- **Fix:** confirm the domain is **Verified** under **Entra → Settings → Domain names**, and that the pilot
  user's UPN uses a verified domain and has a known password.

---

*If licensing is assigned, the MDM authority is Intune, the Apple push certificate is valid, auto-enrollment
is scoped, and baselines are assigned — but a specific device still won't enroll — capture the on-device
error (Windows: `Access work or school → Info → Sync`; iOS: Company Portal diagnostics) and match it to the
symptom above before escalating. Deeper, at-scale enrollment and compliance troubleshooting is its own
catalog solution.*


# Best Practices — Enable Microsoft Intune (Quick-Start)

Keep the enablement clean and set yourself up to expand without rework.

## Pilot before you widen
- Start with the `INTUNE – QuickStart – Pilot` group and a handful of users. Confirm Windows and iOS both
  enroll and report compliant **before** you switch MDM user scope to **All** or broaden enrollment
  restrictions.
- Keep the pilot enrollment restriction (`Enrollment – QuickStart – Pilot`) until you are confident, then
  relax it deliberately.

## Name everything, consistently
- This guide uses `<Purpose> – <Platform> – <Stage>` (e.g. `Compliance – Windows – Baseline`,
  `INTUNE – QuickStart – Pilot`). Keep that convention as you add policies so you can find, audit, and
  clean up later. Reuse the exact names in scripts and documentation.

## Protect the Apple push certificate
- Use a **dedicated organizational Apple ID** (never a personal one) and store its credentials in your
  password vault.
- **Set a renewal reminder ~30 days before expiry.** Renew with the **same Apple ID** — a different Apple
  ID silently un-enrolls every Apple device. The certificate expiry is visible in the Apple MDM Push
  certificate blade and is reported by `ITSTART-Discovery.ps1`.

## License by group, not by hand (as you grow)
- One-off license assignment is fine for a pilot. For rollout, assign Intune licenses via a **group** so
  new users inherit entitlement automatically and enrollment "just works."

## Keep the baseline light — then layer
- The baseline here is deliberately minimal (one compliance policy per platform, one config profile). Do
  **not** pile on settings before devices reliably enroll. Add hardening incrementally, testing each
  layer against the pilot.

## Decide ownership early
- **BYOD (personal)** and **corporate** devices deserve different policy. This Quick-Start uses BYOD iOS to
  get you live fast; when you introduce company-owned iPhones via Apple Business Manager, keep their
  policies and enrollment profiles separate from BYOD.

## Verify with scripts, not assumptions
- Re-run `ITSTART-Validate.ps1` after any change to enrollment or baseline settings. It scores the
  enablement against the success criteria so drift is caught early.

## Know your next steps
Once Intune is functioning, the natural build-out (each a dedicated catalog solution):
- **Windows Autopilot** — zero-touch, ship-to-user Windows provisioning.
- **Apple Business Manager + ADE** — zero-touch corporate iPhones (see `04-enrollment-scenarios.md`).
- **Conditional Access** — require compliant devices before granting access to company data.
- **Compliance & configuration at scale**, **app deployment**, and **Defender for Endpoint** integration.

This free Quick-Start is the on-ramp; the catalog is the road.


# Deliverables Summary — Enable Microsoft Intune (Quick-Start)

This free Quick-Start ships the same package shape as every paid catalog solution, so you can see exactly
what you receive when you buy.

## Documentation (this guide)
- **Executive Summary** — what you accomplish and where the boundary is.
- **Solution Overview** — how Intune works and the deployment model.
- **Requirements** — every prerequisite with verify / implement-if-missing.
- **Implementation** — the exact ordered steps to enable Intune (new or existing tenant).
- **Enrollment Scenarios** — Windows and iOS paths, and where Apple Business Manager fits (with a pointer
  to the full ABM catalog solution).
- **Testing & Validation** — enroll a Windows PC and an iPhone and prove it works.
- **Troubleshooting** — the common enablement failures and their fixes.
- **Best Practices** — keep it clean and expand without rework.

## PowerShell scripts (included ZIP)
- **`ITSTART-Discovery.ps1`** — reports tenant readiness: MDM authority, Apple push certificate + expiry,
  Windows auto-enrollment scope, pilot group and baseline policies.
- **`ITSTART-Validate.ps1`** — scores the enablement against the Quick-Start success criteria (PASS/FAIL).
- **`ITSTART-Report.ps1`** — lists enrolled devices with platform, ownership, management state, and
  compliance; exports CSV.
- **`ITSTART-Enrollment-Readiness.ps1`** — checks a specific user's readiness to enroll (license, group
  membership, enrollment-restriction scope).
- **`ITSTART-Compliance-Check.ps1`** — summarizes baseline compliance-policy assignments and per-device
  compliance state.

All scripts connect to Microsoft Graph **read-only** for verification and reporting; none change tenant
configuration.

## What you get in the download
A single **Complete Solution Package** ZIP containing this guide as a **PDF** and **Word document**, plus
all five PowerShell scripts — yours to keep and reuse.

## This is a free preview
This Quick-Start is provided free as a preview of the Workplace solution catalog. When Intune is live and
you are ready to go further — Autopilot, Apple Business Manager zero-touch, Conditional Access, compliance
at scale, app deployment — the catalog at **workplace.phoenixtekk.com** continues in the same
click-by-click style, with the same tested scripts and pilot-first method.
