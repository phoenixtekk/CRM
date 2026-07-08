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
