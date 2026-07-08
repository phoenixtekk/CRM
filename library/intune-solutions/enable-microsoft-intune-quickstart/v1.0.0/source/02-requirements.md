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
