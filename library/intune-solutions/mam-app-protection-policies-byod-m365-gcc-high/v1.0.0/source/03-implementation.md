# 3. Implementation Guide — MAM App Protection Policies for BYOD (Government / GCC High)

Follow these steps **in order**. In GCC High, App Protection and App Configuration policies are in
the Intune admin center (**`https://intune.microsoft.us`** → **Apps**). The Conditional Access grant
is in Microsoft Entra (**`https://entra.microsoft.us`** → **Protection → Conditional Access**).

> **Government caveat (read first):** every portal below is a **`*.us`** sovereign-cloud URL. If a
> link opens `intune.microsoft.com`, `entra.microsoft.com`, or `login.microsoftonline.com`, stop —
> you are on the Commercial cloud, and changes there do **not** affect your GCC High tenant.

> **Model:** iOS + Android App Protection Policies → App Configuration Policy → CA "require app
> protection policy" grant (Report-only) → validate on an unenrolled BYOD device → pilot → expand.

Reuse these object names exactly: **`MAM Users - BYOD - Pilot`**, **`MAM Users - BYOD - Production`**,
**`BYOD - App Protection - iOS (Gov)`**, **`BYOD - App Protection - Android (Gov)`**,
**`BYOD - App Config - M365 (Gov)`**, **`CA - Require APP - M365 (Gov)`**.

## Step 1 — Create the scope groups
1. `https://entra.microsoft.us` → **Groups → New group → Security** → **`MAM Users - BYOD - Pilot`**
   (a few representative BYOD users). **Create**.
2. Create **`MAM Users - BYOD - Production`** (the rest of the BYOD population). **Create**.
   *(Or run `MAMAPPG-Set-ScopeTargeting.ps1` — defaults to preview — to create both.)*

## Step 2 — Create the iOS App Protection Policy
1. `https://intune.microsoft.us` → **Apps → App protection policies → Create policy → iOS/iPadOS**.
2. **Name:** `BYOD - App Protection - iOS (Gov)`. **Next**.
3. **Apps:** target **Selected apps** (or **All Microsoft apps**) and add Outlook, Teams, Word,
   Excel, PowerPoint, OneDrive, SharePoint, and Edge. **Next**.
4. **Data protection:**
   - Backup org data to iTunes and iCloud backups: **Block**.
   - Send org data to other apps: **Policy managed apps** (limits "open in / share").
   - Receive data from other apps: **Policy managed apps**.
   - Restrict cut, copy, and paste between other apps: **Policy managed apps with paste in**.
   - Save copies of org data: **Block**, then allow only **OneDrive for Business** and **SharePoint**.
   - Encrypt org data: **Require**.
5. **Access requirements:** PIN for access: **Require** (allow biometric); Recheck after (inactivity):
   **30** min; Offline grace period: **720** minutes to block / **90** days to wipe. **Next**.
6. **Conditional launch:** Jailbroken/rooted devices → **Block access**; min OS / min app version
   per your standard (action **Warn** or **Block**); Max PIN attempts **5** → **Reset PIN** (or
   **Wipe data**). **Next**.
7. **Assignments → Included groups → `MAM Users - BYOD - Pilot`**. **Next → Create**.

## Step 3 — Create the Android App Protection Policy
1. `https://intune.microsoft.us` → **Apps → App protection policies → Create policy → Android**.
2. **Name:** `BYOD - App Protection - Android (Gov)`. **Next**.
3. **Apps:** add the same set — Outlook, Teams, Word, Excel, PowerPoint, OneDrive, SharePoint, Edge. **Next**.
4. **Data protection:** match Step 2 (block backup, policy-managed transfer, block save-as except
   OneDrive/SharePoint, require encryption). Set **Screen capture and Google Assistant** to **Block**
   if required. **Next**.
5. **Access requirements:** require an app PIN (allow biometric), recheck after **30** min, offline
   grace **720** minutes to block / **90** days to wipe. **Next**.
6. **Conditional launch:** rooted devices → **Block access**; set min OS / min app version / min
   patch level; max PIN attempts **5** → **Reset PIN**. Set **Device attestation** (Play Integrity)
   to **Require** if your standard needs it. **Next**.
7. **Assignments → Included groups → `MAM Users - BYOD - Pilot`**. **Next → Create**.

> **GCC High caveat:** on **Android**, the policy will not apply until **Company Portal** (the MAM
> broker, service endpoint `portal.manage.microsoft.us`) is installed — no enrollment, broker only.
> On **iOS**, the **Microsoft Authenticator** broker is required. [MAM for unenrolled
> devices](https://learn.microsoft.com/en-us/intune/app-management/protection/mam-without-enrollment)

## Step 4 — Create the App Configuration Policy (managed apps)
1. `https://intune.microsoft.us` → **Apps → App configuration policies → Add → Managed apps**.
2. **Name:** `BYOD - App Config - M365 (Gov)`. **Next**.
3. **Public apps:** select the same Microsoft 365 apps (iOS and Android). **Next**.
4. **Settings:** add managed-app configuration keys per your standard — for example, default save
   location OneDrive/SharePoint, and Edge managed-browser settings (require org sign-in). **Next**.
   > **GCC High caveat:** do not configure Outlook features that are **not FedRAMP-approved for US
   > Gov** (location services, Play My Emails, To Do). **Verify for GCC High** that a given
   > configuration key is honored before relying on it. [Outlook in the Government
   > cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud)
5. **Assignments → Included groups → `MAM Users - BYOD - Pilot`**. **Next → Create**.

## Step 5 — Enforce with Conditional Access (require app protection policy)
1. `https://entra.microsoft.us` → **Protection → Conditional Access → Create new policy**.
2. **Name:** `CA - Require APP - M365 (Gov)`.
3. **Users:** Include `MAM Users - BYOD - Pilot`; **Exclude** the two break-glass accounts.
4. **Target resources:** Cloud apps → **Office 365**.
5. **Conditions → Device platforms →** Include **iOS** and **Android**.
6. **Grant:** Grant access → **Require app protection policy** and **Require approved client app**;
   choose **Require one of the selected controls**.
7. **Enable policy: Report-only**. **Create**.
   > **GCC High caveat:** the CA "require app protection policy" grant **is available** in GCC High.
   > Always pilot in **Report-only** first; see the **Conditional Access Integration (GCC High)**
   > solution for the full lockout-safe rollout.

## Step 6 — Validate on an unenrolled BYOD device
1. On a personal (unenrolled) iPhone or Android, install the Microsoft 365 apps and the MAM broker
   (**Authenticator** on iOS / **Company Portal** on Android — brokering only; do not enroll).
2. Sign in to Outlook with the pilot work account (sign-in goes to `login.microsoftonline.us`). The
   app should apply the policy: prompt for an app PIN and show "managed by your organization" behavior.
3. Copy org text into a personal app — paste should be blocked; save an attachment to a personal
   location — save-as should be blocked (OneDrive/SharePoint allowed).
4. Run **`MAMAPPG-Validation.ps1 -UserPrincipalName pilot-user@your-tenant.onmicrosoft.us`** (US Gov Graph) to confirm the
   user's apps report a protection policy applied.

## Step 7 — Validate the pilot and enable enforcement
1. Run **`MAMAPPG-Report.ps1`** to confirm coverage (which pilot users/apps have the policy) and the
   CA grant status.
2. `https://entra.microsoft.us` → **Monitoring & health → Sign-in logs** → open a pilot sign-in →
   **Report-only** tab; confirm `CA - Require APP - M365 (Gov)` would apply and grant only from a
   protected app.
3. Complete the Testing Guide. When clean, edit `CA - Require APP - M365 (Gov)` → **Enable policy → On**.

## Step 8 — Expand to production
1. Add **`MAM Users - BYOD - Production`** to the **Included groups** of the iOS and Android App
   Protection Policies, the App Configuration Policy, and the CA grant. Use
   **`MAMAPPG-Set-ScopeTargeting.ps1`** (defaults to preview) to build/populate the production group.
2. Roll out in waves; monitor sign-in logs and run **`MAMAPPG-Report.ps1`** each wave.
3. Re-validate with **`MAMAPPG-Validation.ps1`**; remediate gaps with **`MAMAPPG-Remediation.ps1`**
   (defaults to `-WhatIf`).

---
### Order of operations
`Scope groups → iOS APP → Android APP → App config → CA grant (Report-only) → Validate on BYOD → Enable → Expand`
