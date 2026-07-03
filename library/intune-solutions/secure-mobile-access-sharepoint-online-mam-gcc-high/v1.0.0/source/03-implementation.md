# 3. Implementation Guide — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

This guide gives **exact, ordered, click-by-click steps** on the **GCC High** portals. It follows the
standard model — **Assess → Configure → Pilot → Validate → Expand** — with a **gate** between phases.
Do not skip the gates.

> **Before you start — you are in the sovereign cloud.** Sign in with your **GCC High** admin account
> at `login.microsoftonline.us`. The Intune portal is **`https://intune.microsoft.us`** and the Entra
> portal is **`https://entra.microsoft.us`**. If a URL ends in `.com`, stop — you are in Commercial.

**Named objects created in this guide (reuse these exact names):**
- App Protection Policy (iOS): **`APP-SPO-iOS-Enterprise`**
- App Protection Policy (Android): **`APP-SPO-Android-Enterprise`**
- Conditional Access policy: **`CA-SPO-Mobile-Require-App-Protection`**
- Pilot group (from R5): **`SG-SPMAMG-Pilot`**
- Break-glass exclusion group (from R4): **`SG-BreakGlass-Exclude`**

---

## Phase 1 — Assess (gate: R1–R8 pass)
1. Confirm requirements R1–R8 in **Requirements Guide** are all green.
2. Run **`SPMAMG-Discovery.ps1`** (connects to **`graph.microsoft.us`** via `-Environment USGov`).
   Save the output — it lists existing App Protection Policies and Conditional Access policies so you
   don't collide with an existing configuration.
3. On a test iOS and a test Android device, install the **SharePoint** app, sign in with a GCC High
   account, and confirm your `*.sharepoint.us` site loads. This proves the mobile app resolves the
   **government cloud** (R6) before you add policy.

**Gate:** all requirements pass and a baseline SharePoint mobile sign-in works. Proceed.

---

## Phase 2 — Configure

### Step 2.1 — Create the iOS App Protection Policy (`APP-SPO-iOS-Enterprise`)
1. Go to **`https://intune.microsoft.us`** → **Apps** → **App protection policies**.
2. Click **+ Create policy** → **iOS/iPadOS**.
3. **Basics** — Name: **`APP-SPO-iOS-Enterprise`**. Description: "Protects SharePoint/OneDrive/Office
   data on iOS (BYO) — GCC High." Click **Next**.
4. **Apps** — **Target policy to**: **Selected apps**. Add the supported public apps:
   **Microsoft SharePoint**, **Microsoft OneDrive**, **Microsoft 365 (Office)**, **Microsoft Edge**,
   **Microsoft Teams**, **Microsoft Outlook**. Click **Next**.
5. **Data protection** — set an **Enterprise (Level 2)** baseline
   ([Data protection framework](https://learn.microsoft.com/en-us/intune/app-management/protection/data-protection-framework)):
   - **Backup org data to iTunes and iCloud backups:** **Block**
   - **Send org data to other apps:** **Policy managed apps** (blocks copy/"Save As" to unmanaged
     apps)
   - **Save copies of org data:** **Block** — under **Allow user to save copies to selected
     services**, leave only **OneDrive for Business** / **SharePoint** if your policy permits.
   - **Receive data from other apps:** **Policy managed apps**
   - **Restrict cut, copy, and paste between other apps:** **Policy managed apps with paste in**
   - **Screen capture and Google Assistant** (Android equivalent) / **Third-party keyboards:** set
     per your risk posture.
   - **Encrypt org data:** **Require**
   - Click **Next**.
6. **Access requirements** — **PIN for access: Require**; **Work or school account credentials for
   access: Require**; **Recheck the access requirements after (minutes of inactivity): 30**. Click
   **Next**.
7. **Conditional launch** — keep the defaults (e.g. **Max PIN attempts → Reset PIN**, **Jailbroken/
   rooted devices → Block access**, **Offline grace period → Wipe data**). Click **Next**.
8. **Assignments** — **Included groups**: **`SG-SPMAMG-Pilot`**. **Excluded groups**:
   **`SG-BreakGlass-Exclude`**. Click **Next** → **Create**.

### Step 2.2 — Create the Android App Protection Policy (`APP-SPO-Android-Enterprise`)
Repeat Step 2.1 choosing **Android** at **+ Create policy**. Name it **`APP-SPO-Android-Enterprise`**,
target the same apps, apply the same Level 2 data-protection settings, and assign to
**`SG-SPMAMG-Pilot`** (exclude **`SG-BreakGlass-Exclude`**).

> **GCC High caveat:** target the **government-cloud** versions of the apps that resolve
> `*.sharepoint.us`. Personal accounts cannot be added to these apps in GCC High, and
> **Graph-dependent SharePoint mobile features are disabled** — see **GCC High Parity Notes**.

### Step 2.3 — Create the Conditional Access policy (`CA-SPO-Mobile-Require-App-Protection`)
1. Go to **`https://entra.microsoft.us`** → **Protection** → **Conditional Access** → **Policies**.
2. Click **+ New policy**. **Name:** **`CA-SPO-Mobile-Require-App-Protection`**.
3. **Users** — **Include**: **`SG-SPMAMG-Pilot`**. **Exclude**: **`SG-BreakGlass-Exclude`** (always).
4. **Target resources** — **Cloud apps → Include → Select apps → Office 365** (this covers SharePoint
   Online). *(If you prefer, select **SharePoint Online** specifically.)*
5. **Conditions → Device platforms** — **Include** → **Select device platforms** → **iOS** and
   **Android** only.
6. **Conditions → Client apps** — **Configure: Yes** → select **Mobile apps and desktop clients**
   (and, if you want to steer browsers, **Browser** — combined with the Edge routing note below).
7. **Grant** — **Grant access** → check **Require app protection policy**. If you also selected
   Browser, add **Require approved client app OR app protection policy** only as a temporary bridge —
   **note:** *"Require approved client app" is retiring in early March 2026; use "Require app
   protection policy" going forward.*
   ([Entra — migrate approved client app](https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app))
   For **multiple controls**, choose **Require one of the selected controls** only if you intentionally
   allow either; otherwise **Require all**.
8. **Enable policy** — set to **Report-only** (not On). Click **Create**.

**Gate:** iOS + Android App Protection Policies created and assigned to the pilot; the CA policy
exists in **Report-only**. Proceed to Pilot.

---

## Phase 3 — Pilot
1. On the pilot devices (already carrying Authenticator on iOS / Company Portal on Android per R7),
   open the **SharePoint** app and sign in with a **`SG-SPMAMG-Pilot`** account.
2. The app should prompt to **set an app PIN** (App Protection Policy applied). Open a `*.sharepoint.us`
   site and a document.
3. Test data-leak prevention: try to **copy** text from a SharePoint doc into a personal note app
   (should be blocked), and try **"Save a copy"** to a consumer cloud (should be blocked/limited).
4. Watch enforcement without risk: in **`entra.microsoft.us`** → **Conditional Access** →
   **`CA-SPO-Mobile-Require-App-Protection`** → **Report-only**, review that the pilot sign-ins would
   be **satisfied** by the app-protection control (use the **What If** tool and **Sign-in logs →
   Report-only** tab).

**Gate:** pilot users can work in the protected apps, data-leak controls fire, and Report-only shows
the CA control being **satisfied** (not blocking legitimate sign-ins). Proceed to Validate.

---

## Phase 4 — Validate
1. Run **`SPMAMG-Validation.ps1`** (US Gov Graph). It confirms: the two App Protection Policies exist
   and target the supported apps, the CA policy scopes iOS/Android + Office 365 with **Require app
   protection policy**, and **break-glass accounts are excluded** from the CA policy.
2. Run **`SPMAMG-Report.ps1`** to produce a summary of policies + recent mobile sign-in results
   (Report-only outcomes) for your change record.
3. Confirm the **negative test**: on a device **without** the app protection policy (or in a mobile
   browser outside managed Edge), SharePoint access is blocked/limited as designed once the policy is
   enforced.

**Gate:** validation script is clean and negative test behaves as designed. Proceed to Expand.

---

## Phase 5 — Expand
1. Flip **`CA-SPO-Mobile-Require-App-Protection`** from **Report-only** to **On** (start with the
   pilot group still, then widen).
2. Widen scope with **`SPMAMG-Set-ScopeTargeting.ps1`** (defaults to **`-WhatIf`** — review the plan,
   then re-run with `-Confirm` to apply). Add production groups to the **Include** of both App
   Protection Policies **and** the CA policy; keep **`SG-BreakGlass-Exclude`** excluded.
3. Communicate to users that SharePoint on mobile now requires the approved Microsoft apps + an app
   PIN.
4. Re-run **`SPMAMG-Report.ps1`** after each wave to confirm healthy enforcement and no unexpected
   blocks.

> **If anything locks out or misbehaves:** set the CA policy back to **Report-only** (or **Off**),
> use a **break-glass** account to sign in, and see **Troubleshooting**. `SPMAMG-Remediation.ps1`
> (defaults to **`-WhatIf`**) can re-assert break-glass exclusion and revert the CA policy to
> Report-only.

---
### Cited references
- App Protection Policies overview — https://learn.microsoft.com/en-us/intune/app-management/protection/overview
- Data protection framework — https://learn.microsoft.com/en-us/intune/app-management/protection/data-protection-framework
- App-based Conditional Access with Intune — https://learn.microsoft.com/en-us/intune/device-security/conditional-access-integration/app-based-policies
- Require app protection policy (CA) — https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-approved-app-or-app-protection
- Migrate approved client app → app protection policy — https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app
- SharePoint for US government environments — https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint
- GCC High endpoints — https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints
