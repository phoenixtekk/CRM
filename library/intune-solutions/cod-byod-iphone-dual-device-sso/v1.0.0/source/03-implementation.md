# 3. Implementation — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. The whole design assumes **one Entra identity per user**
who carries **two iPhones** — a **corporate iPhone (COD)** and a **personal iPhone (BYOD)** — so you
assign policies to the **user (group)** and let **ownership-based filters** route the right policy to
each iPhone. Pilot first: **Assess → Configure → Pilot → Validate → Expand.**

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`
- **Apple Business Manager (ABM)** — `https://business.apple.com`

> **Scope note (iOS iPhones):** the **corporate iPhone** is enrolled supervised via **Apple Business
> Manager + Automated Device Enrollment (ADE)** for full MDM. The **personal iPhone** is protected by
> **App Protection Policies (MAM)** — with **Account-Driven Apple User Enrollment** called out as an
> optional lightweight MDM path. **Single sign-on** across both iPhones is delivered by the **Microsoft
> Authenticator** broker plus the **iOS Enterprise SSO extension**, all under one Entra identity.

---

## Phase 1 — Identity, Apple connection & enrollment baseline

### Step 1. Confirm one identity and licensing per pilot user
1. Entra → **Users** → confirm each pilot user is a **single** account with an Intune + Entra ID P1
   license (Requirements R1–R3).
2. Entra → **Groups → New group** → **Security** → name it **`PILOT – iPhone COD-BYOD Users`** → add
   the pilot users. *(You assign every policy in this solution to this **user** group.)*

### Step 2. Create the Apple MDM Push (APNs) certificate
1. In Intune, go to **Devices → Enrollment → Apple → Apple MDM Push certificate**.
2. Check **I agree**, then **Download** the CSR file.
3. Click **Create your MDM push certificate** → `https://identity.apple.com`; sign in with a
   **company Apple ID** (record which Apple ID — you must reuse it every year).
4. **Create a Certificate**, upload the CSR, **Download** the `.pem`, then back in Intune enter that
   **Apple ID**, **Browse** to the `.pem`, and **Upload**.
5. Confirm the status shows **Active** with an expiration ~1 year out. *(Required for both
   corporate-iPhone MDM and personal-iPhone User Enrollment.)*

### Step 3. Connect Apple Business Manager for corporate iPhones (ADE token)
1. In Intune, go to **Devices → Enrollment → Apple → Enrollment program tokens → Add** → check
   **I agree** → **Download** the Intune **public key** (`.pem`).
2. In **ABM → Preferences → MDM Servers → Add**; name it **`Intune – iPhone COD`**; **Upload** the
   Intune public key; **Save**; **Download Token** (`.p7m`).
3. Back in Intune, enter the **Apple ID** used for ABM, **Browse** to the `.p7m`, **Upload**. The
   token appears under **Enrollment program tokens** with a future expiration.

### Step 4. Set enrollment restrictions for iPhone ownership types
1. **Devices → Enrollment → Enrollment device platform restrictions.**
2. Open the default (or create a pilot-scoped restriction **named `Enrollment Restriction – iPhone
   COD-BYOD – Pilot`**).
3. For **iOS/iPadOS**, set **Personal devices = Allow** *(so the user's personal iPhone may enroll for
   User Enrollment / register for App Protection)*.
4. Corporate iPhones are forced through ADE in the next phase, so they always tag **Corporate**.

---

## Phase 2 — Ownership-based targeting (the core of "one account, both iPhones")

### Step 5. Create device-ownership filters
1. **Tenant administration → Filters → Create.**
2. Filter 1: **name it `iPhone – Corporate`** — platform **iOS/iPadOS**; rule
   `(device.deviceOwnership -eq "Corporate")`.
3. Filter 2: **name it `iPhone – Personal`** — platform **iOS/iPadOS**; rule
   `(device.deviceOwnership -eq "Personal")`.
4. **Save** both.

> Prefer automation? Run **`IOSDD-Set-OwnershipBasedTargeting.ps1`** to create these filters (and
> optionally assign the policies below) via Microsoft Graph.

---

## Phase 3 — Corporate iPhone (COD): supervised ADE + full MDM

### Step 6. Create the iOS enrollment program profile (supervised)
1. In Intune, go to **Devices → Enrollment → Apple → Enrollment program tokens**, **open** your ADE
   token, then **Profiles → Create profile → iOS/iPadOS**; enter a name and description — **name it
   `iPhone ADE – COD – Pilot`**.
2. **User affinity** = **Enroll with user affinity** (required so the corporate iPhone ties to the
   user and can do SSO). Choose **Setup Assistant with modern authentication**.
3. **Management options:** enable **Supervised**; set **Locked enrollment = Yes** (prevents users
   removing management).
4. **Setup Assistant:** hide unnecessary panes (Restore, Apple ID, Siri, Privacy as policy dictates)
   for a clean first-run. **Review + Create.**

### Step 7. Assign devices and the profile (in ABM + Intune)
1. In **ABM → Devices**, select the corporate iPhone serial numbers → **Edit MDM Server** → choose
   **`Intune – iPhone COD`** → **Confirm**.
2. In Intune, on the token → **Devices**, click **Sync** (Apple rate-limits; allow a few minutes),
   then select the serials → **Assign profile** → **`iPhone ADE – COD – Pilot`**.

### Step 8. Create a compliance policy for corporate iPhones
1. **Devices → Compliance → Create policy → iOS/iPadOS**; **name it `iPhone – Compliance – COD –
   Pilot`**.
2. Set baseline rules (min iOS version, **require passcode**, jailbreak detection, etc.).
3. **Assignments:** assign to **`PILOT – iPhone COD-BYOD Users`**; under **Filter**, **Include** the
   **`iPhone – Corporate`** filter → **Create**.

### Step 9. Create a configuration profile for corporate iPhones
1. **Devices → Configuration → Create → New policy → iOS/iPadOS**; **name it `iPhone – Configuration
   – COD – Pilot`** (settings such as passcode, restrictions, Wi-Fi/VPN as needed).
2. **Assignments:** assign to **`PILOT – iPhone COD-BYOD Users`**, **Include** the **`iPhone –
   Corporate`** filter.

---

## Phase 4 — Personal iPhone (BYOD): App Protection (MAM)

### Step 10. Create the iOS App Protection Policy
1. **Apps → App protection policies → Create policy → iOS/iPadOS**; **name it `iPhone – App
   Protection – BYOD – Pilot`**.
2. **Apps:** select the approved managed apps (Outlook, Edge, Teams, Office, OneDrive, **Microsoft
   Authenticator**).
3. **Data protection:** block **backup**, restrict **cut/copy/paste** to managed apps, block **Save
   As** to personal locations, keep corporate data in managed apps.
4. **Access requirements:** require **PIN** / org credentials; set offline timeouts.
5. **Assignments:** assign to **`PILOT – iPhone COD-BYOD Users`**. *(App Protection is identity-based
   — it applies wherever the user signs into the managed app, so it targets the personal iPhone with
   no device enrollment.)*

### Step 11. Make the approved apps available to BYOD users
1. **Apps → iOS/iPadOS → Add** Outlook, Edge, Teams, Office, OneDrive, **Company Portal**, and
   **Microsoft Authenticator**.
2. Assign them **Available** to **`PILOT – iPhone COD-BYOD Users`** so users install them from the
   App Store / Company Portal.

> **Optional lightweight MDM for the personal iPhone:** if a personal iPhone must receive a few device
> settings, use **Account-Driven Apple User Enrollment** (Devices → Enrollment → Apple → enable
> **Account driven user enrollment**, **name the profile `iPhone – User Enrollment – BYOD – Pilot`**).
> It still tags **Personal** and is scoped by the **`iPhone – Personal`** filter, keeping personal data
> separate.

---

## Phase 5 — Single sign-on across the user's two iPhones

The goal: the user authenticates **once per iPhone**, then gets **silent SSO** to Microsoft 365 and
Entra apps on **both** iPhones with the same account. On iOS the **Microsoft Authenticator** app is
the identity broker, and the **iOS Enterprise SSO extension** extends that SSO to Safari and other
apps.

### Step 12. Deploy the iOS Enterprise SSO extension to the corporate iPhone
1. **Devices → Configuration → Create → New policy → iOS/iPadOS → Templates → Device features**;
   **name it `iPhone – Enterprise SSO – COD – Pilot`**.
2. Under **Single sign-on app extension**, set **SSO app extension type = Microsoft Entra ID**
   (Microsoft's Enterprise SSO plug-in, brokered by Authenticator).
3. Leave the Microsoft-managed defaults; under **App bundle IDs**, add Safari and any line-of-business
   apps that should get silent SSO.
4. **Assignments:** assign to **`PILOT – iPhone COD-BYOD Users`**, **Include** the **`iPhone –
   Corporate`** filter → **Create**.

### Step 13. Establish the Authenticator broker on the personal iPhone
1. On the personal iPhone, the user installs **Microsoft Authenticator** (it is the **identity
   broker** that App Protection onboarding registers).
2. The first sign-in to a managed app (Outlook/Edge/Teams) registers the account through the broker;
   afterward, **other approved apps get silent SSO** with the same account.
3. Do **not** require enrollment for SSO — the broker provides SSO while the personal iPhone stays
   BYOD (App Protection only).

### Step 14. Confirm the same identity owns both iPhones
1. Entra → **Devices** → filter by the pilot user: confirm the **same UPN** has the **corporate
   iPhone** (Entra-registered, supervised) **and** a **registered personal iPhone** under one identity.
2. The user should move between their two iPhones and into M365 apps **without re-entering
   credentials** beyond one sign-in per iPhone.

---

## Phase 6 — Unify access with Conditional Access

### Step 15. One Conditional Access policy for both iPhones
1. Entra → **Protection → Conditional Access → Create new policy**; **name it `CA – iPhone COD-BYOD
   Access`**.
2. **Users:** **`PILOT – iPhone COD-BYOD Users`**.
3. **Target resources:** Office 365 (and other corporate apps).
4. **Conditions → Device platforms:** **iOS**.
5. **Grant:** require **one of the following** — **Require device to be marked as compliant**
   *(satisfied by the corporate iPhone)* **and/or** **Require app protection policy** *(satisfied by
   the personal iPhone's managed app)*; set to **Require one of the selected controls**.
6. **Enable policy:** **Report-only** for the pilot → **Create**.

This single policy lets the **same account** reach corporate data from a **compliant corporate
iPhone** or an **app-protected personal iPhone**.

---

## Phase 7 — Pilot, validate, expand

### Step 16. Pilot with one user on two iPhones
1. **Erase** the pilot **corporate** iPhone (**Settings → General → Transfer or Reset → Erase All
   Content and Settings**) so it returns to Setup Assistant; enroll via ADE — it tags **Corporate**
   and receives compliance/config + the Enterprise SSO extension.
2. On the **personal** iPhone, install **Microsoft Authenticator**, then sign into **Outlook/Edge**
   with the **same account** → the App Protection policy applies (PIN prompt, managed-app containment).
3. Confirm the **same UPN** now owns both a Corporate and a Personal iPhone in Intune.

### Step 17. Validate
1. Run **`IOSDD-Discovery.ps1`** (tenant readiness: APNs, ADE token, filters, App Protection, CA) and
   **`IOSDD-Validation.ps1 -User <upn>`**: confirm the user has **one Corporate iPhone** (compliant,
   supervised) and **one Personal iPhone** (app protection applied), under a single identity.
2. Confirm the **`iPhone – Corporate`** filter applied device policy and the **`iPhone – Personal`**
   filter did not (and vice-versa for app protection).
3. **Verify single sign-on:** on the corporate iPhone open a Microsoft 365 web app in **Safari** and
   confirm **silent SSO** (no password prompt — the Enterprise SSO extension at work); on the personal
   iPhone, after the first managed-app sign-in, a second approved app (e.g. Teams) opens **without** a
   fresh password — silent SSO on both iPhones for the one account.
4. Review Conditional Access **report-only** results for the pilot user.

### Step 18. Expand
1. When the pilot passes, widen the assignments from the pilot group to broader user groups (or make
   **`iPhone ADE – COD – Pilot`** the default profile for the ADE token).
2. Move **`CA – iPhone COD-BYOD Access`** from **report-only** to **On**.
3. Roll out in waves, validating each wave with the scripts before widening.
