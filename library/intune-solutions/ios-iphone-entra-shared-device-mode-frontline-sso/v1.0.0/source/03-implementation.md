# 3. Implementation — iOS iPhone Entra ID Shared Device Mode (Frontline SSO)

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against
a small **pilot pool** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and the
Entra admin center at `https://entra.microsoft.com` unless noted.

> **This configures shared-identity (Shared Device Mode) on no-affinity iPhones.** It is not
> single-user SSO and not single-app kiosk lockdown. Every device here is enrolled **without user
> affinity**.

---

## Phase 1 — Build the shared-device foundation

### Step 1. Create the assigned device group (and set the Provisioning Client as owner)
1. Go to **Entra → Groups → New group**.
2. **Group type = Security**; **Membership type = Assigned** (not Dynamic); **Name:**
   **iPhone SDM – Devices**. **Create**.
3. Open **iPhone SDM – Devices → Owners → Add owners**. Search by **Application ID**
   `f1346770-5b25-470b-88bd-d5744ab7952c` (the **Intune Provisioning Client**; the display name
   varies — search by the AppId, not the name) and **add it as an owner**.
   - *Why:* no-affinity/shared devices are placed into an **assigned** group at enrollment by this
     service principal; if it is not an owner, the group stays empty and nothing deploys.
   - *Shortcut:* `IOSSDMFL-Remediation.ps1` can create the group and set this owner for you.

### Step 2. Create the ADE enrollment profile (no user affinity)
1. Go to **Devices → Enrollment → Apple → Enrollment program tokens**, and **open your ADE token**.
2. Select the **Profiles** tab → **Create profile → iOS/iPadOS**.
3. **Name:** **iPhone SDM – ADE Profile**. Set **User Affinity = Enroll without User Affinity** and
   **Supervised = Yes**. Complete the wizard and **Create**.
4. Back on the token, assign **iPhone SDM – ADE Profile** to your shared iPhone serial numbers
   (**Devices** tab → select devices → **Assign profile**).

### Step 3. Deploy Microsoft Authenticator and Teams to the pool
1. Go to **Apps → iOS/iPadOS → Add → iOS store app**.
2. Add **Microsoft Authenticator** — publisher **Microsoft Corporation**, bundle ID
   `com.microsoft.azureauthenticator`. Assign **Required** to **iPhone SDM – Devices**.
3. Add **Microsoft Teams** — publisher **Microsoft Corporation**, bundle ID
   `com.microsoft.skype.teams` (*not* "Teams" by another publisher). Assign **Required** to
   **iPhone SDM – Devices**.
4. *(Optional)* Add any **SDM-aware LOB apps** (confirmed with the vendor) the same way.

### Step 4. Add a restriction profile for the shared pool
1. Go to **Devices → Configuration → Create → New policy**; **Platform = iOS/iPadOS**;
   **Profile type = Templates → Device restrictions → Create**.
2. **Name:** **iPhone SDM – Restrictions**. Limit apps/functions to what the frontline role needs
   (SDM isolates SDM-app data, not the whole OS — keep non-SDM, personal-data apps off the pool).
3. **Assignments:** **iPhone SDM – Devices**. **Review + create → Create**.

### Step 5. Grant the provisioning account the Cloud Device Administrator role
1. Go to **Entra → Roles and administrators → Cloud Device Administrator → Add assignments**.
2. Add the dedicated **provisioning account** you will use to register devices into shared mode.

---

## Phase 2 — Enroll and register a pilot iPhone into Shared Device Mode

### Step 6. Enroll the pilot iPhone (no affinity)
1. Wipe/prepare the pilot iPhone and start setup; because its serial is assigned the
   **iPhone SDM – ADE Profile**, it enrolls **supervised, without user affinity**.
2. Confirm the device appears in **Devices → iOS/iPadOS** as **corporate / no primary user**, and that
   it landed in **iPhone SDM – Devices** (Entra → Groups → members).

### Step 7. Register the device into Shared Device Mode (the Authenticator step)
1. On the pilot iPhone, open **Microsoft Authenticator** (deployed in Step 3).
2. Sign in with the **provisioning account** (the Cloud Device Administrator from Step 5) and complete
   the **shared device registration** prompt to mark this device as a **shared device**.
3. The device now advertises **shared mode** to SDM-aware apps. This is a one-time provisioning action
   per device.

---

## Phase 3 — Pilot the global sign-in / single sign-out experience

### Step 8. First user signs in
1. On the pilot iPhone, open **Microsoft Teams**. Confirm Teams shows the **shared-device** sign-in
   experience.
2. Sign in as **pilot user A** (Entra credentials + MFA). Confirm A is signed in to Teams and any
   other SDM apps recognize A without a second sign-in.

### Step 9. Single (global) sign-out
1. As pilot user A, perform **sign out** in Teams.
2. Confirm this triggers a **global sign-out** — A is signed out of all SDM apps and A's cached data
   is cleared from the device.

### Step 10. Second user signs in clean
1. Open Teams again and sign in as **pilot user B**.
2. Confirm **no trace of user A** — B sees only their own chats/data; A's session and data are gone.
   This is the core acceptance behavior.

---

## Phase 4 — Validate and expand

### Step 11. Validate with the scripts
1. Run **`IOSSDMFL-Discovery.ps1`** (tenant readiness: no-affinity ADE profile, Authenticator + Teams
   assigned, assigned group with the Provisioning Client owner, Cloud Device Administrator present).
2. Run **`IOSSDMFL-Validation.ps1`** to confirm the assigned group ownership, ADE profile affinity,
   and app assignments are correct.
3. Run **`IOSSDMFL-Report.ps1`** to list the shared-mode iPhones (no user affinity) and their app/group
   state.

### Step 12. Remediate gaps (safe by default)
1. If the group is missing the Provisioning Client owner, the ADE profile has the wrong affinity, or
   apps are unassigned, run **`IOSSDMFL-Remediation.ps1`** — it **defaults to `-WhatIf`** and prints
   exactly what it would change. Review, then re-run to apply.

### Step 13. Expand in waves
1. Once the pilot passes (Testing gate), assign the **iPhone SDM – ADE Profile** to the next batch of
   serials and register each device into shared mode (Step 7).
2. Roll out by location/shift in waves, validating each wave with `IOSSDMFL-Report.ps1` before
   widening. Register-into-shared-mode is per device, so script/track it as part of your provisioning
   runbook.
