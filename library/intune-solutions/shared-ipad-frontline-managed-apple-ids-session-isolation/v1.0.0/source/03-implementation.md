# 3. Implementation — Shared iPad for Frontline Teams

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**.

**The design:** iPads enrolled through **Automated Device Enrollment (ADE)** from **Apple Business
Manager**, **supervised**, with **Shared iPad enabled in the enrollment profile**; each staff member
signs in with a **Managed Apple ID** federated to Microsoft Entra ID; the device is locked to the field
workload. Pilot first: **Assess → Configure → Pilot → Validate → Expand.**

**Consoles used:**
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`
- **Apple Business Manager (ABM)** — `https://business.apple.com`

> **Apple-portal steps carry a VERIFY WITH APPLE flag.** Apple changes ABM's navigation, flow names,
> and mechanics without notice. Where you see the flag, this guide gives you **what to do and why, and
> the decision you must make** — get the **exact current clicks** from Apple's live ABM documentation.
> Do not follow a screenshot from an older project.

> **Objects created by this solution** — reuse these names **verbatim** everywhere:
>
> | Object | Type | Where |
> |---|---|---|
> | `PILOT – Shared iPad Users` | Entra security group (Assigned, **users**) | Step 1 |
> | `SHARED IPAD – FMD – Pilot` | Entra security group (Assigned, **devices**) | Step 2 |
> | `SHARED IPAD – FMD – Production` | Entra security group (Assigned, **devices**) | Step 2 |
> | `SHARED IPAD – ADE Profile – Shared` | Intune ADE enrollment profile | Step 7 |
> | `SHARED IPAD – Restrictions – Field Lockdown` | Intune device configuration profile | Step 9 |
> | `SHARED IPAD – Compliance – iPadOS` | Intune compliance policy | Step 10 |
> | `SHARED IPAD – Apps – Field Allowlist` | Intune app assignments (the app set) | Step 11 |

---

## Phase 1 — Assess & prepare identity

### Step 1. Create the pilot user group

1. Go to `https://entra.microsoft.com` → **Identity → Groups → All groups → New group**.
2. **Group type:** `Security`. **Group name:** **`PILOT – Shared iPad Users`**.
3. **Membership type:** `Assigned`.
4. **Members → No members selected** → add the **two** real staff members who will run the
   session-isolation test (Testing §5). You need exactly two humans, not one — the test is A-then-B.
5. Click **Create**.

### Step 2. Create the device groups

1. Entra → **Identity → Groups → All groups → New group**.
2. **Group type:** `Security`. **Group name:** **`SHARED IPAD – FMD – Pilot`**.
3. **Membership type:** `Assigned`. Click **Create**.
4. Repeat and create a second group named **`SHARED IPAD – FMD – Production`**, also **`Assigned`**.

> **Both groups must be `Assigned`, never `Dynamic`.** These groups target devices **at enrollment**
> (no user affinity is involved at the device layer under Shared iPad), and enrollment-time device
> grouping only works against an **Assigned** group. Continue to Step 2b.

### Step 2b. Add the Intune Provisioning Client as an owner of each device group

*(Do this for **both** `SHARED IPAD – FMD – Pilot` and `SHARED IPAD – FMD – Production`.)*

1. Entra → **Identity → Groups → All groups →** open **`SHARED IPAD – FMD – Pilot`**.
2. Select **Owners → Add owners**.
3. In the search box, paste the **AppId** **`f1346770-5b25-470b-88bd-d5744ab7952c`**. Select the
   result and click **Select**.
   - **Search by the AppId, not by the display name.** The display name varies by tenant — many
     tenants show it as **`Intune Autopilot ConfidentialClient`**, others show something else.
   - **If the principal does not appear:** open the Intune portal (`https://intune.microsoft.com`)
     once as a **Global Administrator** to provision it into the tenant, then repeat this step.
4. Confirm the principal is now listed under **Owners**.
5. **Repeat steps 1–4 for `SHARED IPAD – FMD – Production`.**

> **Verify this owner is present before every pilot and every expansion wave.** Enrollment-time device
> grouping works by this principal *owning* the Assigned group. Without the owner, the group stays
> **empty at enrollment** and **nothing deploys** — no restrictions, no compliance, no apps — and the
> failure looks exactly like a policy problem.

### Step 3. Resolve the personal Apple ID conflicts — **THIS IS A GATE**

**Do not proceed past this step for a given user until their conflict is resolved.** A conflicted
address cannot be issued a Managed Apple ID, and a user without a Managed Apple ID cannot sign in to a
Shared iPad. You can configure everything downstream, but you cannot pilot.

**3a. Build the candidate worklist (Microsoft side, read-only).**
1. On an admin workstation, run:
   ```
   .\SHAREDIPAD-AppleIDConflict.ps1 -GroupName 'PILOT – Shared iPad Users' -CsvPath .\appleid-candidates.csv
   ```
2. This exports every user whose work address would need a Managed Apple ID and therefore **may**
   collide with a personal Apple ID. **It cannot query Apple.** It is your planning and tracking list.
3. For the pilot, scope it to `PILOT – Shared iPad Users`. For the campaign, re-run it across the full
   frontline population.

**3b. Get the authoritative conflict list (Apple side).**
1. Sign in to `https://business.apple.com` as an ABM administrator.
2. Confirm your domain (e.g. `contoso.com`) is **verified** (Requirements R5). Domain verification is
   what gives you visibility of, and a path to resolve, personal Apple IDs on your domain.
3. Use ABM's conflict-resolution capability to obtain the list of addresses on your verified domain
   that are already in use by a **personal** Apple ID.
4. Reconcile against `appleid-candidates.csv` from 3a. **ABM is the truth. The CSV is the tracker.**

> **VERIFY WITH APPLE.** Apple's domain-verification and conflict-resolution capability, its exact
> name, where it appears in ABM, what it reports, what notification Apple sends the affected user, the
> **grace period** Apple allows, and **what happens to a user who does not act within it** are **all
> Apple's and all subject to change**. **Get every one of these specifics from current Apple Business
> Manager documentation before you plan dates or write a word of user communication.** This guide gives
> you the concept and the sequence, deliberately and on purpose — an invented timeline here would
> become a broken promise to staff.

**3c. Make the decision — escalate it, do not make it.**

The concept is: affected staff must **change their personal Apple ID to a personal email address**, so
the work address is released and ABM can issue a Managed Apple ID on it. That request reaches the
staff member's **personal iPhone, personal Mac, iCloud photo library, and App Store purchase history**.

**This is an identity, HR, legal, and communications decision. It is not yours.**

1. Present to the customer's **HR, legal, and identity owners**:
   - **Option 1 — Mandate.** All affected staff must move their personal Apple ID to a personal address
     within an agreed window. *Impact:* fastest path to Shared iPad; touches personal devices and
     personal data; needs HR/legal sign-off and probably a consultation process; will generate
     helpdesk volume and some genuine upset.
   - **Option 2 — Voluntary with a deadline.** Staff are asked to move, with support, ahead of an
     announced date after which Apple's process applies. *Impact:* better received; slower; leaves a
     tail of non-responders you must still handle.
   - **Option 3 — Scope down.** Issue Managed Apple IDs only to staff with no conflict, and defer or
     exclude the rest. *Impact:* no personal-device impact for the excluded; those staff cannot use a
     Shared iPad, so the fleet is only partly usable and you carry two operating models.
   - **Option 4 — Alternative addressing.** Issue Managed Apple IDs on a **different verified
     subdomain** the staff member has never used personally (e.g. `staff.contoso.com`). *Impact:* may
     sidestep many conflicts entirely; adds a second domain to verify and federate, and a second
     address for staff to understand. **VERIFY WITH APPLE** that this fits your ABM/federation
     configuration before proposing it as a solution — it is a genuine option worth raising, not a
     guaranteed escape.
2. **Record their decision in writing.** Then execute it.
3. **Do not send a single staff notification until Requirement R18 is satisfied** — a named executive
   sponsor, agreed messaging, an agreed grace period, and an agreed support path.

**3d. Run the campaign and track it.**
1. Send the agreed communication to the affected staff, with the support path.
2. Track each user's state in `appleid-candidates.csv` (the script emits a `Status` column for this).
3. Re-check ABM as staff act; a released address becomes eligible for a Managed Apple ID.
4. **Gate:** your two `PILOT – Shared iPad Users` must be **clear of conflict** before Step 12. If they
   are not, the pilot cannot run — pick two clear users or resolve theirs first.

### Step 4. Federate ABM to Microsoft Entra ID

1. Sign in to `https://business.apple.com` as an ABM administrator.
2. Configure **federated authentication** against **Microsoft Entra ID** for your verified domain
   (e.g. `contoso.com`).
3. Complete the Microsoft-side consent when ABM redirects you — sign in with a **Global
   Administrator** and grant the requested permissions.
4. Confirm ABM shows federation as active for the domain.

> **VERIFY WITH APPLE AND MICROSOFT.** The ABM navigation for federation, the flow name, the exact
> Microsoft permissions requested, how ABM handles a domain that still contains unresolved personal
> Apple IDs, and the behaviour for accounts that already have a Managed Apple ID are **Apple's and
> Microsoft's, and they change**. **Follow Apple's current ABM federation documentation for the exact
> steps.**

> **Sequencing matters:** federate **after** Step 3 has cleared conflicts on the domain, or at minimum
> after you understand which addresses are conflicted. Federating a domain full of unresolved personal
> Apple IDs is how a project acquires a surprise.

> **Related catalog solution:** if you want Managed Apple IDs created automatically from Entra ID
> rather than by hand, see *Implement Entra ID Integration with ABM for Account Auto Provisioning for
> Microsoft Intune*. It covers the provisioning of accounts into ABM; it does not cover Shared iPad.

---

## Phase 2 — Configure the Apple connection

### Step 5. Create the Apple MDM Push (APNs) certificate

*(Skip if Intune already shows an **Active** certificate with a future expiry — do **not** create a
second one, it will break your existing fleet.)*

1. Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**.
2. Check **I agree**, then **Download your CSR**.
3. Click **Create your MDM push certificate** → `https://identity.apple.com`.
4. Sign in with a **company-owned Apple ID**. **Record this Apple ID** — you must reuse the exact same
   one to renew every year. Never use a staff member's personal Apple ID.
5. **Create a Certificate**, upload the CSR, then **Download** the `.pem`.
6. Back in Intune, enter the **Apple ID** you used, **Browse** to the `.pem`, and click **Upload**.
7. Confirm the status reads **Active** with an expiry ~1 year out. Put the renewal in the operational
   calendar.

### Step 6. Connect Apple Business Manager (upload the ADE token)

1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens → Add**.
2. Check **I agree**, then **Download your public key** (the `.pem`).
3. Go to `https://business.apple.com` and create a new **MDM server** entry; **name it
   `Intune – Shared iPad`**; upload the Intune public key; save it; then **download the token**
   (`.p7m`). **VERIFY WITH APPLE** — the ABM navigation to MDM server management changes; get the
   current path from Apple's ABM documentation.
4. Back in Intune, enter the **Apple ID** used for ABM, **Browse** to the `.p7m`, and click **Upload**.
5. Confirm the token appears under **Enrollment program tokens** with a **future** expiry.
   **This token expires annually — calendar the renewal now.**

### Step 7. Create the ADE enrollment profile with **Shared iPad enabled**

**This is the step that delivers session isolation. Everything else is supporting work.**

1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens**.
2. **Open the token** you uploaded in Step 6 (click its name — you must drill into the token; the
   Profiles tab does not exist anywhere else).
3. Select **Profiles → Create profile → iOS/iPadOS**.
4. **Name:** **`SHARED IPAD – ADE Profile – Shared`**. **Description:** `Shared iPad, supervised,
   field frontline fleet.`
5. **Platform:** confirm **iOS/iPadOS**. Click **Next**.
6. On the **Management settings** page:
   - **User Affinity:** select **`Enroll with user affinity`**, then select **`Shared iPad`** as the
     enrollment mode. *(Shared iPad is presented under the user-affinity choice — it is a multi-user
     model, so it is not "without user affinity". If you cannot see the Shared iPad option, the token
     or the platform selection is wrong; see Troubleshooting §6.)*
   - **Maximum number of cached users** (or the equivalent resident-user setting): set it to the
     number of shift users you need resident on the device. **VERIFY WITH APPLE** — the maximum Apple
     supports, and the storage each resident user consumes, are Apple's published figures and they
     change; confirm against Apple's current Shared iPad documentation and against Requirement R11
     **before** you set this. Setting it above what the hardware can carry produces sign-in failures,
     not a warning.
   - **Supervised:** **`Yes`**. *(Required — Requirement R9.)*
   - **Locked enrollment:** **`Yes`**. *(Users cannot remove management. Essential for a field fleet.)*
7. Click **Next** to the **Setup Assistant customization** page. Hide every pane the field team does
   not need — **Restore**, **Apple ID** *(the Managed Apple ID sign-in is the Shared iPad sign-in
   screen, not this pane)*, **Siri**, **Privacy**, **Screen Time**, **App Analytics**, **Terms and
   conditions**, **Display Zoom** — so the iPad comes up straight at the Shared iPad sign-in screen.
8. Click **Next → Review + Create → Create**.
9. Confirm the profile appears in the token's **Profiles** list.

### Step 8. Assign the iPads and the profile

1. In **ABM → Devices**, select the iPad **serial numbers** for the pilot.
2. Assign them to the MDM server **`Intune – Shared iPad`** (Step 6), and confirm. **VERIFY WITH
   APPLE** — the ABM device-assignment navigation changes; get the current path from Apple's docs.
3. In Intune, open the token → **Devices** → click **Sync**. **Apple rate-limits this sync** — allow
   several minutes and do not click it repeatedly.
4. When the serials appear, select them → **Assign profile** → choose **`SHARED IPAD – ADE Profile –
   Shared`** → confirm.
5. Verify each serial's **Profile status** shows the assignment.

> **Devices that do not appear here are not in ABM** and cannot be ADE-enrolled — see Requirements R6
> and Troubleshooting §6. This is where an existing retail-bought fleet reveals itself. Establish the
> real number now, before you commit to a rollout date.

---

## Phase 3 — Configure the device

### Step 9. Create the field lockdown restrictions profile

1. Intune → **Devices → Configuration → Create → New policy**.
2. **Platform:** `iOS/iPadOS`. **Profile type:** `Templates` → **`Device restrictions`** → **Create**.
3. **Name:** **`SHARED IPAD – Restrictions – Field Lockdown`**. **Description:** `Field frontline
   Shared iPad lockdown.` Click **Next**.
4. On the **Configuration settings** page, set the following. *(Each of these applies **only** to a
   supervised device — Requirement R9. On an unsupervised iPad most of them are silently ignored, which
   is a common source of "restrictions not applying" — see Troubleshooting §6.)*

   **App Store, Doc Viewing, Gaming**
   - **App Store:** **`Block`** — staff cannot browse or install personal apps.
   - **Installing apps:** **`Block`**.
   - **Removing apps:** **`Block`** — staff cannot uninstall the CMMS app.
   - **In-app purchases:** **`Block`**.
   - **Explicit content in media:** **`Block`**.

   **Built-in apps**
   - **Safari:** **`Block`** *(unless the CMMS or schematics workflow needs the browser — confirm with
     the field team before blocking; a blocked Safari that the CMMS app relies on for SSO breaks the
     workload).*
   - **Camera:** **`Allow`** — the field team photographs assets. This is part of the workload.
   - **FaceTime:** **`Block`**.
   - **Apple Music / Podcasts / News / Game Center:** **`Block`**.

   **Cloud and storage**
   - **Backup to iCloud:** **`Block`**.
   - **iCloud Photo Library / iCloud Drive:** **`Block`** *(prevents field photos leaving to a personal
     library).*
   - **Managed apps syncing to cloud:** **`Block`**.

   **Connected devices and sharing**
   - **AirDrop:** **`Block`** — a shared field device should not be a data-exfiltration path.
   - **Bluetooth modification:** **`Block`** *(unless the field workload pairs a Bluetooth accessory —
     confirm first).*
   - **Pairing with a host computer / Apple Configurator:** restrict per your management model.

   **Accounts and identity — this is the group that matters most**
   - **Account modification:** **`Block`** — **staff cannot add personal accounts to the device.** This
     is the setting that stops a shift worker signing their personal Apple ID or personal mail into the
     field iPad.
   - **Modifying the passcode:** **`Block`**.
   - **Modifying the device name:** **`Block`**.
   - **Erase all content and settings:** **`Block`**.
   - **Modifying restrictions:** **`Block`**.

   **Keyboard and dictation**
   - **Predictive keyboard / auto-fill:** **`Block`** — reduces cross-shift leakage of typed identity
     and text into shared keyboard state.

5. Click **Next** through **Scope tags**.
6. On **Assignments**, click **Add groups** and select **`SHARED IPAD – FMD – Pilot`**. Click **Next**.
   *(Add `SHARED IPAD – FMD – Production` at Expand, Step 14 — not now.)*
7. **Review + create → Create**.

> **App allowlisting vs app blocking — which to use.** A **blocklist** ("hidden apps") names the apps
> to remove and lets everything else through — it fails the moment a new app exists. An **allowlist**
> ("allowed apps") names the apps permitted and hides everything else — it is the correct model for a
> locked-down field device and it is what this solution uses (Step 11). **The restrictions profile
> above blocks the *capabilities*; the allowlist controls the *app inventory*.** You need both:
> restrictions stop the App Store and account modification; the allowlist decides what is on the home
> screen. Do not try to do the job with only one of them.

### Step 10. Create the compliance policy

1. Intune → **Devices → Compliance → Create policy**.
2. **Platform:** `iOS/iPadOS` → **Create**.
3. **Name:** **`SHARED IPAD – Compliance – iPadOS`**. Click **Next**.
4. **Compliance settings:**
   - **Device Health → Jailbroken devices:** **`Block`**.
   - **Device Properties → Minimum OS version:** set your supported floor. **VERIFY WITH APPLE** — set
     this to the current Shared iPad minimum from Apple's documentation (Requirement R10), not a
     remembered number.
   - **System Security → Require a password to unlock mobile devices:** set per the customer's policy
     for a shared field device. *(Under Shared iPad each user authenticates at sign-in; discuss the
     device-passcode requirement with the customer's security owner rather than assuming.)*
5. Click **Next**. On **Actions for noncompliance**, keep the default **Mark device noncompliant →
   Immediately**.
6. **Assignments → Add groups →** **`SHARED IPAD – FMD – Pilot`** → **Next**.
7. **Review + create → Create**.

### Step 11. Deploy the field app allowlist

**`SHARED IPAD – Apps – Field Allowlist`** is the app set below. Deploy each app as **Required** to
**`SHARED IPAD – FMD – Pilot`**, then hide everything else.

**11a. Add each app.**

For each app in the field workload:
1. Intune → **Apps → All apps → Add**.
2. **App type:** **`iOS/iPadOS store app`** *(or **`iOS/iPadOS volume purchased program app`** if you
   license it through ABM — VPP is preferred for a fleet, since it does not depend on a user's App
   Store identity, which a Shared iPad does not have).*
3. **Search the App Store** and select the app.

   > **Identify every app by its exact publisher string and bundle ID — never by name alone.** App
   > Store search returns multiple near-identical results, and deploying the wrong one to 40 locked
   > devices is a re-staging exercise. Record the exact publisher and bundle ID for each app in your
   > build sheet before you search:
   >
   > | App | Publisher (exact string) | Bundle ID | Notes |
   > |---|---|---|---|
   > | Your CMMS app | *(from the vendor — confirm in writing)* | *(from the vendor)* | Confirm the vendor supports **Shared iPad**. Ask explicitly; do not assume. |
   > | Schematics / document viewer | *(from the vendor)* | *(from the vendor)* | Must render your drawing formats offline. |
   > | Microsoft Outlook | `Microsoft Corporation` | `com.microsoft.Office.Outlook` | Not "Outlook Lite", not a third-party mail client. |
   > | Microsoft Teams | `Microsoft Corporation` | `com.microsoft.skype.teams` | Not "Teams for Life" / personal Teams. |
   > | Microsoft Authenticator | `Microsoft Corporation` | `com.microsoft.azureauthenticator` | Required if you later layer Option B (SDM broker) — see the note below. |
   >
   > **Get the CMMS and viewer publisher/bundle ID from the vendor in writing.** Do not guess them
   > from search results.

4. Click **Select** → **Next** through the app information.
5. **Assignments → Required → Add group →** **`SHARED IPAD – FMD – Pilot`** → **Next**.
6. **Review + create → Create**.
7. Repeat for every app in the table.

**11b. Restrict the home screen to the allowlist.**
1. Intune → **Devices → Configuration → Create → New policy** → **`iOS/iPadOS`** → `Templates` →
   **`Device restrictions`** → **Create**.
2. **Name:** **`SHARED IPAD – Apps – Field Allowlist`**. Click **Next**.
3. Find the **Show or hide apps** settings group.
4. Select the **allowlist** control (**`Allowed apps`** / "Apps visible") — **not** the hidden-apps
   blocklist.
5. Add **each** app by its **bundle ID** from the table in 11a, **plus** the system apps the workload
   genuinely needs (Camera; Settings only if the field team must join Wi-Fi themselves — otherwise
   leave it out). Everything not listed is hidden.
6. **Assignments → Add groups →** **`SHARED IPAD – FMD – Pilot`** → **Next**.
7. **Review + create → Create**.

> **Do not lock the iPad to a single app.** Single-app (kiosk) mode is the right answer for a
> single-purpose appliance and the **wrong** answer here — this fleet runs a CMMS app **and** a viewer
> **and** the camera **and** Microsoft 365, and each shift user needs to reach the Shared iPad sign-out
> control. Use the **allowlist**, which is a lockdown that still permits the workload.

> **If you are layering Option B (Microsoft 365 Shared Device Mode) on top of Shared iPad:** SDM
> requires the **Microsoft Authenticator** broker and per-app configuration, and it only affects apps
> that **participate** in SDM. **The set of Microsoft apps supporting shared device mode on
> iOS/iPadOS changes over time — verify the current supported-app list against Microsoft's
> documentation before designing around it.** This solution does not assert that list. Deploy and
> validate **Option A (Shared iPad) first**; it is what delivers the OS-level isolation the test in
> §5 measures. Layer SDM afterwards, and re-run the §5 test after you do.

---

## Phase 4 — Pilot

### Step 12. Wipe and enroll the pilot iPad

> **Gate check before you touch a device:** the two members of `PILOT – Shared iPad Users` hold
> **Managed Apple IDs** and are **clear of Apple ID conflict** (Step 3). If not, stop — the pilot will
> fail at sign-in and you will spend a day debugging a policy that is fine.

1. On the pilot iPad, back up anything the field team needs off it. **This step erases the device.**
2. **Settings → General → Transfer or Reset iPad → Erase All Content and Settings.** Confirm.
3. The iPad restarts into **Setup Assistant**. Choose language and region, and connect to the field
   Wi-Fi (Requirement R17 — use a location with known-good signal).
4. Setup Assistant displays **Remote Management** naming your organization. Continue.
5. The iPad enrolls, supervises, and lands on the **Shared iPad sign-in screen** asking for a **Managed
   Apple ID**.
   - **If it lands on a normal personal-iPad home screen instead, it is not in Shared iPad mode.** Stop
     and go to Troubleshooting §6 — this is the #1 failure and the entire solution depends on getting
     it right. Do not proceed and do not "fix it later".
6. In Intune → **Devices → All devices**, confirm the iPad appears; open it → **Properties** and
   confirm **Supervised = `Yes`** and the enrollment profile is **`SHARED IPAD – ADE Profile –
   Shared`**.
7. Confirm the device is now a member of **`SHARED IPAD – FMD – Pilot`**. *(If the group is empty, the
   Step 2b owner is missing — go to Troubleshooting §6.)*
8. Allow the device to sync. Confirm the restrictions, compliance, and the allowlist apps arrive.

### Step 13. Run the validation gate

1. Run **`SHAREDIPAD-Validate.ps1`** and confirm an overall **PASS**.
2. **Run the session-isolation A/B test in Testing §5 with two real humans.** That test — not the
   script — is the acceptance gate for this project. It is what the customer is buying.
3. **Do not proceed to Step 14 until the session-isolation test PASSES.** Expanding a broken isolation
   model across 40 devices means wiping 40 devices twice.

---

## Phase 5 — Expand

### Step 14. Stage the fleet

1. **Confirm the eligible device count first.** In ABM → **Devices**, confirm **every** iPad serial in
   the fleet is present. Serials that are absent are **not in ABM**, cannot be ADE-enrolled, and
   **cannot run Shared iPad** (Requirement R6). Establish this number before you schedule anything —
   it is the difference between a configuration project and a hardware purchase.
2. **Confirm storage eligibility.** Run `SHAREDIPAD-Report.ps1` and check the model and storage
   columns against Apple's current guidance for your resident-user count (Requirement R11). Under-specced
   iPads must be re-sized or excluded — not hoped over.
3. **Assign the remaining eligible serials** to the `Intune – Shared iPad` MDM server in ABM, then in
   Intune assign them the **`SHARED IPAD – ADE Profile – Shared`** profile (Step 8). *(Alternatively,
   set it as the token's **default** profile so newly added serials inherit it automatically.)*
4. **Extend the policy assignments to production.** For each of **`SHARED IPAD – Restrictions – Field
   Lockdown`**, **`SHARED IPAD – Compliance – iPadOS`**, **`SHARED IPAD – Apps – Field Allowlist`**,
   and each app in the allowlist: open it → **Properties → Assignments → Edit → Add groups →**
   **`SHARED IPAD – FMD – Production`** → **Review + save**.
5. **Verify the Step 2b owner is on `SHARED IPAD – FMD – Production`** before the first wave enrolls.
   Check it; do not assume it carried over.
6. **Stage in waves, not in one weekend.** Wipe and re-enroll in batches of 8–10 (Step 12) so a shift
   is never without devices. After each wave, run `SHAREDIPAD-Validate.ps1` and spot-check the
   session-isolation test on one device from the wave **before** starting the next.
7. **Brief the field team** on the shift-handover runbook (Testing §5) before their devices are staged.
   A user who does not know to sign out is the one operational gap Shared iPad still leaves you.
8. Run `SHAREDIPAD-Report.ps1` after the final wave and keep the CSV as the as-built record.
