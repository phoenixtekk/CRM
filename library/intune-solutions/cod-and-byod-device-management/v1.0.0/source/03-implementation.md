# 3. Implementation — Corporate-Owned (COD) & BYOD Device Management

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. The whole design assumes **one Entra identity per user**
that works on both device types — so you assign policies to the **user (group)** and let
**ownership-based filters** route the right policy to each device. Pilot first:
**Assess → Configure → Pilot → Validate → Expand.**

All steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and Microsoft Entra
at `https://entra.microsoft.com` unless noted.

---

## Phase 1 — Identity & enrollment baseline

### Step 1. Confirm one identity and licensing per pilot user
1. Entra → **Users** → confirm each pilot user is a **single** account with an Intune + Entra ID P1
   license (Requirements R1–R3).
2. Entra → **Groups → New group** → **Security** → name it **`PILOT – COD-BYOD Users`** → add the pilot users.
   *(You assign every policy in this solution to this **user** group.)*

### Step 2. Set enrollment restrictions for both ownership types
1. **Devices → Enrollment → Enrollment device platform restrictions.**
2. Open the default (or create a pilot-scoped restriction **named `Enrollment Restriction – COD-BYOD – Pilot`**).
3. For **BYOD** platforms (e.g. iOS/Android personal), set **Personal devices = Allow**.
4. For platforms you only allow as corporate, set **Personal devices = Block** (those must enroll via
   a corporate method).

### Step 3. Establish how COD devices are marked Corporate
1. **Devices → Enrollment → Corporate device identifiers → Add** serial numbers/IMEIs of company
   devices **(or)** rely on a corporate enrollment program (Autopilot/ADE/Android Enterprise).
2. Confirm a known company device shows **Ownership = Corporate** on its device record.

---

## Phase 2 — Ownership-based targeting (the core of "one account, both devices")

### Step 4. Create device-ownership filters
1. **Tenant administration → Filters → Create.**
2. Filter 1: **Corporate Devices** — platform as needed; rule `(device.deviceOwnership -eq "Corporate")`.
3. Filter 2: **Personal Devices** — rule `(device.deviceOwnership -eq "Personal")`.
3. **Save** both.

> Prefer automation? Run **`Set-OwnershipBasedTargeting.ps1`** to create these filters (and optionally
> assign the policies below) via Microsoft Graph.

---

## Phase 3 — Corporate-owned (COD): full MDM

### Step 5. Create a compliance policy for corporate devices
1. **Devices → Compliance → Create policy** → pick the platform; **name it `COD – Compliance – Pilot`**.
2. Set baseline rules (OS minimum, disk encryption, firewall, etc.).
3. **Assignments:** assign to **PILOT – COD-BYOD Users**, and under **Filter**, **Include** the
   **Corporate Devices** filter → **Create**.

### Step 6. Create configuration profile(s) for corporate devices
1. **Devices → Configuration → Create → New policy** → platform → your settings; **name it `COD – Configuration – Pilot`**.
2. **Assignments:** assign to **PILOT – COD-BYOD Users**, **Include** the **Corporate Devices** filter.

*(Zero-touch corporate enrollment — Windows Autopilot, Apple ADE, Android Enterprise corporate — is
each covered by its own solution; plug those in for fully automated COD provisioning.)*

---

## Phase 4 — BYOD: App Protection (MAM)

### Step 7. Create App Protection Policies
1. **Apps → App protection policies → Create policy** → **iOS/iPadOS**, **name it `BYOD – App Protection – iOS – Pilot`** (repeat for **Android** as **`BYOD – App Protection – Android – Pilot`**).
2. **Apps:** select the approved managed apps (Outlook, Edge, Teams, Office, OneDrive).
3. **Data protection:** block **backup**, restrict **cut/copy/paste** to managed apps, block **Save
   As** to personal locations, require corporate data to stay in managed apps.
4. **Access requirements:** require **PIN** / org credentials to access; set offline timeouts.
5. **Assignments:** assign to **PILOT – COD-BYOD Users**. *(App Protection is identity-based — it
   applies to the user wherever they sign into the managed app, so it naturally targets the personal
   device without device enrollment.)*

### Step 8. Make the approved apps available to BYOD users
1. **Apps → (platform) → Add** Outlook, Edge, Teams, Office, Company Portal as needed.
2. Assign them **Available** to **PILOT – COD-BYOD Users** so users install them from Company
   Portal / store.

---

## Phase 5 — Unify access with Conditional Access

### Step 9. One Conditional Access policy for both device types
1. Entra → **Protection → Conditional Access → Create new policy** → name it **`CA – COD-BYOD Access`**.
2. **Users:** **PILOT – COD-BYOD Users**.
3. **Target resources:** Office 365 (and other corporate apps).
4. **Grant:** require **one of the following** — **Require device to be marked as compliant** *(this
   is satisfied by the corporate device)* **and/or** **Require app protection policy** *(satisfied by
   the personal device's managed app)*; set the control to **Require one of the selected controls**.
5. **Enable policy:** **Report-only** for the pilot → **Create**.

This single policy is what lets the **same account** reach corporate data from a **compliant COD** or
an **app-protected BYOD** device.

---

## Phase 6 — Pilot, validate, expand

### Step 10. Pilot with one user on two devices
1. As a pilot user, enroll a **corporate** device (it tags Corporate → gets compliance/config).
2. On a **personal** device, sign into **Outlook/Edge** with the **same account** → the App
   Protection policy applies (PIN prompt, managed-app data containment).
3. Confirm the **same UPN** now owns both a Corporate and a Personal device in Intune.

### Step 11. Validate
1. Run **`CODBYOD-Discovery.ps1`** (tenant readiness) and **`CODBYOD-Validation.ps1 -User <upn>`**:
   confirm the user has **one Corporate** device (compliant) and **one Personal** device (app
   protection applied), under a single identity.
2. Confirm the **Corporate** filter applied device policy and the **Personal** filter did not (and
   vice-versa for app protection).
3. Review Conditional Access **report-only** results for the pilot user.

### Step 12. Expand
1. When the pilot passes, widen the assignments from the pilot group to broader user groups.
2. Move **CA – COD-BYOD Access** from **report-only** to **On**.
3. Roll out in waves, validating each wave with the scripts before widening.
