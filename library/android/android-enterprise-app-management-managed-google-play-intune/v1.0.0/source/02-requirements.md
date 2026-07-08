# 2. Requirements Guide — Android Enterprise App Management via Managed Google Play (Intune)

Verify **every** requirement before you approve and assign apps. Each entry: **Description · Why ·
Verify · Implement-if-missing.** The six category-wide prerequisites (tenant + Intune, the managed
Google Play binding, least-privilege roles, enrollment-method decision + Graph toolchain, network
reachability, pilot scope + change control) are defined once in
`global-requirements-android.md` — confirm those first; the items below are **specific to app
management** on managed Google Play.

## 2.1 A working managed Google Play connection (apps can sync)
**Description:** The managed Google Play binding is not just present but **healthy** — Intune can sync
the approved-app catalog from Google.
**Why:** App approval, assignment, and managed configuration all depend on the connection; a stale or
errored binding is the most common reason an approved app never appears on devices.
**Verify:** Intune admin center → **Devices > Android > Android enterprise** — confirm the connection is
connected and app sync is current. Run **`ANDROIDAPP-Scope.ps1`** (reads the managed store account
enterprise settings, including last app-sync status/time).
**Implement:** Repair/re-establish the binding (that is the *connection setup* solution) before app work.

## 2.2 Enrollment model(s) decided and at least one enrolled device per model
**Description:** The target enrollment model(s) — **work profile (BYOD)**, **fully managed**,
**corporate-owned work profile**, or **dedicated/COSU** — chosen, with a test device enrolled in each
model you will assign to.
**Why:** Assignment intent and behavior differ by model (silent **Required** push vs user-pulled
**Available**; kiosk surfaces apps differently). You cannot validate delivery without an enrolled device.
**Verify:** Intune → **Devices > All devices** (filter Android); confirm ownership/enrollment profile.
**Implement:** Enroll a device per model into the **pilot group** before assigning.

## 2.3 The app inventory and app-type decision
**Description:** A list of the apps to deliver, and for each the **type** (store / private LOB / web /
OEMConfig) and its **exact managed Google Play identity** — the **package name** (e.g.
`com.microsoft.office.outlook`) and **publisher**.
**Why:** Managed Google Play search returns near-identical results; the package name + publisher is what
guarantees you approve and lock to the *right* app, and the package name is the key the scripts and app
config policies match on.
**Verify:** Confirm each app's package name (managed Google Play iframe → app detail, or the vendor's
docs). Run **`ANDROIDAPP-Discovery.ps1`** to list what is already approved.
**Implement:** Record app + type + package name + intended intent per group before approving.

## 2.4 Private LOB / web apps published on the Google side (if used)
**Description:** For **private (LOB) apps**, the `.apk` published privately to your organization via the
managed Google Play **Publishing** flow (Google Play Console developer account or the in-iframe publisher);
for **web apps**, the web link created in managed Google Play.
**Why:** Intune can only approve/assign what managed Google Play already hosts for your organization;
private publishing and web-app creation happen on the Google side first.
**Verify:** The app/web link appears in the managed Google Play iframe under your organization's apps.
**Implement:** Publish the private app / create the web app in managed Google Play (flagged: the
Publishing surface evolves — follow current Google guidance), then sync into Intune.

## 2.5 Managed configuration schema for any app you will pre-configure
**Description:** For each app you will push settings to, the app's **managed configuration keys** (from
managed Google Play's app-config UI) or, for OEMConfig, the **OEM's configuration schema**.
**Why:** App config policies write **managed configurations** the app publishes; you can only set keys
the app (or OEM) actually exposes.
**Verify:** In the Intune app-config policy editor, the **configuration designer** lists the app's keys;
for OEMConfig, the OEM app's schema is shown. Confirm the keys you need exist.
**Implement:** Obtain the key list/schema from the vendor/OEM documentation before authoring the config.

## 2.6 App protection (MAM) prerequisites, if you will apply APP
**Description:** If applying **Android app protection policies**, the licensing for Intune app protection
and, for **MAM-only (unenrolled)** scenarios, the **Microsoft Entra Company Portal** presence the APP
framework requires on the device.
**Why:** App protection policy enforcement relies on the Intune APP SDK/Company Portal broker; without it
the policy does not attach to the app's corporate data.
**Verify:** Intune → **Apps > App protection policies** is available; run **`ANDROIDAPP-AppProtection.ps1`**
(read mode) to list existing Android APP policies.
**Implement:** Ensure Intune app-protection licensing and Company Portal availability before assigning APP.

## 2.7 Target groups for assignment (Assigned security groups)
**Description:** **Entra security groups** for each assignment scope — a **pilot** group and the
per-model / per-audience production groups.
**Why:** Apps, configs, tracks, and protection are targeted to **groups**; clean group design is what
lets you pilot a Beta track to one group while Production stays stable.
**Verify:** Entra → **Groups**; confirm membership. Run **`ANDROIDAPP-Discovery.ps1`** to see current
app→group assignments.
**Implement:** Create `ANDROIDAPP-Pilot` and the production groups before assigning.

---
## Checklist
- [ ] Category global requirements confirmed (`global-requirements-android.md`)
- [ ] Managed Google Play connection healthy / app sync current — `ANDROIDAPP-Scope.ps1`
- [ ] Enrollment model(s) decided; a test device enrolled per model in the pilot group
- [ ] App inventory with type + package name + intended intent — `ANDROIDAPP-Discovery.ps1`
- [ ] Private LOB / web apps published on the Google side (if used)
- [ ] Managed configuration keys / OEM schema obtained (if pre-configuring)
- [ ] App protection prerequisites met (if applying APP) — `ANDROIDAPP-AppProtection.ps1`
- [ ] Pilot + production Entra groups created
- [ ] Change window / rollback agreed
