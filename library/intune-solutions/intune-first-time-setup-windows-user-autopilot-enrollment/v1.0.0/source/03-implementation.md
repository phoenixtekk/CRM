# 3. Implementation Guide — Microsoft Intune First-Time Setup for Windows

Follow these steps **in order**. Navigation is in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) and **Microsoft Entra admin center** (`https://entra.microsoft.com`)
as noted. *(Government tenants: use `intune.microsoft.us` and `entra.microsoft.us`.)*

> **Model:** enable auto-enrollment → build pilot groups → user-driven enrollment → basic Entra-joined
> Autopilot (profile + ESP) → enroll one PC each way → validate → expand.
> Naming convention: `<Purpose> - <Scope/Platform> - <Stage>`.

---

## Phase A — Configure (tenant-wide switches + pilot scope)

### Step 1 — Enable automatic Windows enrollment
1. In the **Microsoft Intune admin center**, go to **Devices** → in the left menu under **Device
   onboarding** select **Enrollment**.
2. Open the **Windows** tab → **Automatic Enrollment**.
3. Set **MDM user scope** to **Some**, then **Select groups** and choose
   `INTBASE - Windows Users - Pilot` (you create this group in Step 3; return here if needed).
   *(Setting scope to **All** enrolls every Entra-joined Windows device tenant-wide — for a first pilot,
   keep it to the pilot group.)*
4. Leave **MAM user scope** as **None** for this solution. Click **Save**.

### Step 2 — Set a first-run branding (optional but recommended)
1. Open **`https://entra.microsoft.com`** → **Home** → search **Company branding** (or **Entra ID →
   Company branding**).
2. Click **Customize** (or **Add**) on the default sign-in experience; add your logo, background, and
   sign-in text; **Save**.
   *(Branding makes the Autopilot OOBE and Windows sign-in show your organization, so pilot users trust
   the flow.)*

### Step 3 — Create the pilot USER group
1. In **`https://entra.microsoft.com`** go to **Groups** → **All groups** → **New group**.
2. **Group type:** Security. **Group name:** `INTBASE - Windows Users - Pilot`.
3. **Membership type:** **Assigned**. Under **Members**, add your pilot user (e.g. `Windows Pilot User
   01`). Click **Create**.
4. Return to **Step 1** if you deferred it and select this group for the **MDM user scope**.

### Step 4 — Create the pilot Windows compliance policy
1. In the **Intune admin center**, go to **Devices** → **Compliance** (under **Manage devices**) →
   **Create policy**.
2. **Platform:** Windows 10 and later. Click **Create**.
3. **Name:** `INTBASE - Compliance - Windows Pilot`. Click **Next**.
4. Under **Compliance settings**, expand **Device Health** and set **Require BitLocker** = **Not
   configured** for the pilot (keep it minimal); expand **System Security** and set **Require a password
   to unlock mobile devices** = **Require**, **Minimum password length** = **6**. *(Keep the baseline
   small — deep compliance hardening is a separate catalog solution.)* Click **Next**.
5. **Actions for noncompliance:** leave the default **Mark device noncompliant** immediately. Click
   **Next**.
6. **Assignments → Add groups →** `INTBASE - Windows Users - Pilot`. Click **Next → Create**.

---

## Phase B — User-driven enrollment (an existing PC)

### Step 5 — End-user: Entra-join the PC (auto-enrolls into Intune)
Perform this on the **user-driven** pilot PC, signed in as a local user:
1. Open **Settings → Accounts → Access work or school**.
2. Click **Connect**. On the dialog, click **Join this device to Microsoft Entra ID** (the small link
   under the email box — **not** the email box itself, which only adds a work account).
3. Sign in with the pilot user's work account (e.g. `pilotuser01@contoso.com`) and complete the prompts.
   Accept the confirmation to join.
4. When it finishes, the PC is **Entra joined** and, because automatic enrollment is on (Step 1), it
   **auto-enrolls into Intune**.
5. Verify on the device: **Settings → Accounts → Access work or school** shows the account with an
   **Info** button; open **Info** and confirm the managed connection and click **Sync** to force a
   check-in. *(Optionally run `dsregcmd /status` and confirm `AzureAdJoined : YES` and an `MDMUrl`.)*

---

## Phase C — Basic Windows Autopilot (Entra-ID joined)

### Step 6 — Create the Autopilot DEVICE group and set the required owner
1. In **`https://entra.microsoft.com`** go to **Groups** → **All groups** → **New group**.
2. **Group type:** Security. **Group name:** `INTBASE - Autopilot Devices`. **Membership type:**
   **Assigned** (not Dynamic). Click **Create**.
3. Open the group → **Owners** → **Add owners**. In the search box type the **AppId**
   `f1346770-5b25-470b-88bd-d5744ab7952c` (the **Intune Provisioning Client**, sometimes shown as
   *Intune Autopilot ConfidentialClient*). Select it and click **Select**.
   > **Why:** enrollment-time device grouping requires this first-party service principal to **own** the
   > assigned group. Without the owner, devices never land in the group at enrollment and the profile/ESP
   > do not deploy. If the principal does not appear, open the Intune admin center once as a **Global
   > Administrator** to provision it, then retry. Search by **AppId**, not the display name.

### Step 7 — Register the Autopilot device (hardware hash)
1. On the pilot Autopilot PC (elevated PowerShell), run **`INTBASE-Get-AutopilotHash.ps1`** to export
   the hardware hash CSV. *(Or have your OEM/reseller register the device to your tenant at purchase — no
   import needed.)*
2. In the **Intune admin center**, go to **Devices** → **Enrollment** → open the **Windows** tab →
   **Devices** (under **Windows Autopilot**) → **Import**.
3. Upload the CSV and wait for the device serial to appear. Click **Sync** and refresh if it is not
   listed yet (registration can take a few minutes).
4. Add the device to the group: **Entra → Groups → `INTBASE - Autopilot Devices` → Members → Add
   members**, and add the imported Autopilot device (by serial). *(At scale a dynamic ZTDId group is used
   instead — deferred to the deeper Autopilot solution; for a first pilot, add the one device explicitly.)*

### Step 8 — Create the Autopilot deployment profile
1. Go to **Devices** → **Enrollment** → **Windows** tab → **Deployment Profiles** (under **Windows
   Autopilot**) → **Create profile** → **Windows PC**.
2. **Name:** `INTBASE - Autopilot - Pilot`. **Description:** first-time user-driven Entra-joined pilot.
   Set **Convert all targeted devices to Autopilot** = **No** (explicit registration only). Click
   **Next**.
3. **Out-of-box experience (OOBE):**
   - **Deployment mode:** **User-driven**.
   - **Join to Microsoft Entra ID as:** **Microsoft Entra joined**.
   - **Microsoft Software License Terms:** Hide. **Privacy settings:** Hide. **Hide change account
     options:** Hide.
   - **User account type:** **Standard**.
   - **Allow pre-provisioned deployment:** **No** (out of scope). **Language / keyboard:** as you prefer.
     Click **Next**.
4. **Assignments → Add groups →** `INTBASE - Autopilot Devices`. Click **Next → Create**.

### Step 9 — Create the Enrollment Status Page (ESP)
1. Go to **Devices** → **Enrollment** → **Windows** tab → **Enrollment Status Page** (under **Windows
   Autopilot**) → **Create**.
2. **Name:** `INTBASE - ESP - Pilot`. Click **Next**.
3. **Settings:**
   - **Show app and profile configuration progress:** **Yes**.
   - **Block device use until all apps and profiles are installed:** **Yes**.
   - **Allow users to reset device if installation error occurs:** **Yes**.
   - **Allow users to use device if installation error occurs:** **Yes** (keeps the pilot from getting
     stuck).
   - **Block device use until required apps are installed:** leave as **All** but do **not** require heavy
     apps on the pilot (keep the ESP light — deep ESP tuning is a separate solution). Click **Next**.
4. **Assignments → Add groups →** `INTBASE - Autopilot Devices`. Click **Next → Create**.

### Step 10 — Set a Windows enrollment restriction (sensible default)
1. Go to **Devices** → **Enrollment** → **Windows** tab → **Enrollment device platform restrictions** →
   open the **Windows restrictions** default (or **Create restriction**).
2. If creating: **Name:** `INTBASE - Windows Enrollment - Pilot`; **Platform:** Windows; **Personally
   owned devices:** **Block** (corporate-only for the pilot). Assign to
   `INTBASE - Windows Users - Pilot`. **Save/Create**.
   *(This keeps the pilot to corporate devices; you can relax it later.)*

---

## Phase D — Pilot

### Step 11 — Provision the Autopilot pilot device
1. **Factory-reset** the registered Autopilot PC (or use a new one already registered) so it starts at
   **OOBE**.
2. Connect it to the internet at the region/keyboard screens.
3. The Autopilot branding appears; the pilot user signs in with their **work account**.
4. The device **Entra-joins**, **MDM-enrolls**, and the **`INTBASE - ESP - Pilot`** page runs until the
   device is ready.

---

## Phase E — Validate & Expand

### Step 12 — Validate both devices
1. Run **`INTBASE-Validate-Enrollment.ps1`** on each pilot PC (or by device name via Graph) → confirms
   the device is Entra-joined, Intune-enrolled, and compliant.
2. Run **`INTBASE-Report-Enrollment.ps1`** → lists enrolled Windows devices with their **enrollment
   method** (user-driven vs Autopilot).
3. Complete the **Testing Guide** (Section 5) and confirm every PASS/FAIL gate before expanding.

### Step 13 — Expand (when ready)
1. Add more pilot users to `INTBASE - Windows Users - Pilot` (or widen the auto-enrollment scope) for
   user-driven PCs.
2. Register more Autopilot devices and add them to `INTBASE - Autopilot Devices` (OEM registration at
   purchase is ideal at scale).
3. Re-validate each wave. For production-scale Autopilot (dynamic-group strategy, multi-profile,
   pre-provisioning, deep ESP tuning, app packaging, Conditional Access), move to the deeper Autopilot
   catalog solutions.

---
### Order of operations
`Auto-enrollment → pilot user group → compliance → user-driven join → Autopilot device group (+ SP
owner) → register device → deployment profile → ESP → enrollment restriction → provision → validate →
expand`
