# 3. Implementation — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

This document is the build. It follows the phase model **Assess → Deploy Agent → Configure SSO/Badge → Enable EPCS → Pilot → Validate → Expand**, using **full navigation paths** and **named objects**. Every object you create is named with the `<Purpose> – <Scope> – <Stage>` convention and is reused verbatim in `05-testing.md`, `06-troubleshooting.md`, and the scripts. Appliance-side policy values and EPCS/DEA specifics are obtained from your **Imprivata administrator** and **compliance team** — this document does not invent them.

### Objects you will create (named, reused verbatim)

| Object type | Name |
|-------------|------|
| Win32 app (agent) | `Imprivata Agent – Clinical Endpoints – Deploy` |
| Win32 app (reader driver) | `Proximity Reader Driver – Clinical Endpoints – Deploy` |
| Entra device group | `IMPRIVATA – Clinical Endpoints` |
| Entra device group (pilot subset) | `IMPRIVATA – Clinical Endpoints – Pilot` |
| Device configuration profile | `Imprivata Endpoint – Clinical Endpoints – Baseline` |
| Win32 app (agent, uninstall use) | `Imprivata Agent – Clinical Endpoints – Deploy` (Uninstall assignment) |

> When this document references a packaged Win32 app, name it exactly as above and record the **publisher** (the Imprivata agent is published by **Imprivata, Inc.**; the reader driver is published by the **reader hardware vendor** — record the exact vendor string from the driver package).

---

## Phase 1 — Assess

1. Open the **Microsoft Intune admin center** at `https://intune.microsoft.com`.
2. Navigate to `Devices > All devices` and confirm the target clinical endpoints (and the test device from global requirement G6) appear as **managed** and **compliant**.
3. Confirm every requirement in `02-requirements.md` (R1–R10) and `global-requirements-healthcare-solutions.md` (G1–G7) is satisfied. Do not start packaging until R1 (appliance reachable), R3 (readers/drivers), R4 (Intune enrollment), R5 (identity), and R7 (shared-device model) are confirmed.
4. From your **Imprivata administrator**, obtain: the **agent installer** for your licensed OneSign version, the **silent install/uninstall command lines**, the **detection criteria** (installed file path/version or registry key), the appliance host/port, and the supported reader models/drivers. Record these — they are inputs to the steps below.

## Phase 2 — Deploy Agent

### Step 1 — Create the clinical device group

1. In the Intune admin center, navigate to `Groups > All groups > New group`.
2. Set **Group type** = `Security`.
3. Set **Group name** = `IMPRIVATA – Clinical Endpoints`.
4. Set **Membership type** = `Assigned` (or `Dynamic Device` with a rule that matches your clinical endpoints' naming/category, if you maintain one — record the rule).
5. For an assigned group, choose **Members > Add members** and add the shared clinical endpoints (and the test device).
6. Select **Create**.
7. Repeat steps 1–6 to create a pilot subset group named `IMPRIVATA – Clinical Endpoints – Pilot` containing only the pilot ward's endpoints and the test device.

### Step 2 — Package the Imprivata agent as a Win32 app

1. Obtain the Imprivata agent installer (from your Imprivata admin) and the **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`).
2. Wrap the installer into an `.intunewin` package per the standard Win32 packaging process (source folder, setup file, output folder).

### Step 3 — Create the agent Win32 app in Intune

1. Navigate to `Apps > All apps > Add`.
2. Set **App type** = `Windows app (Win32)` and select **Select**.
3. On **App information**: upload the `.intunewin` from Step 2. Set **Name** = `Imprivata Agent – Clinical Endpoints – Deploy`. Set **Publisher** = `Imprivata, Inc.`. Add a description and the version supplied by your Imprivata admin.
4. On **Program**:
   - **Install command** = the silent install command line supplied by your Imprivata admin (do not invent installer switches).
   - **Uninstall command** = the silent uninstall command line supplied by your Imprivata admin.
   - **Install behavior** = `System`.
5. On **Requirements**: set **Operating system architecture** and **Minimum operating system** to the supported values from R6.
6. On **Detection rules**: choose **Manually configure detection rules > Add** and enter the detection criteria supplied by your Imprivata admin (installed file path + version, or registry key/value). Do not guess.
7. On **Dependencies** and **Supersedence**: leave unless your admin specifies a dependency.
8. On **Assignments**: under **Required**, select **Add group** and add `IMPRIVATA – Clinical Endpoints – Pilot` for the pilot. (You will add the full `IMPRIVATA – Clinical Endpoints` group in the Expand phase.)
9. Select **Next > Create**.

### Step 4 — Package and create the reader-driver Win32 app

1. Obtain the proximity reader driver package from the reader hardware vendor (per R3). For HID-class driverless readers, skip this step and document that no driver app is required.
2. Wrap the driver installer into an `.intunewin` package as in Step 2.
3. Navigate to `Apps > All apps > Add > Windows app (Win32) > Select`.
4. On **App information**: set **Name** = `Proximity Reader Driver – Clinical Endpoints – Deploy`. Set **Publisher** = the exact reader hardware vendor string from the driver package.
5. On **Program**: enter the driver's silent **Install command** and **Uninstall command**; set **Install behavior** = `System`.
6. On **Requirements**: set OS architecture and minimum OS per R6.
7. On **Detection rules**: add the driver's detection criteria (driver file/version or registry key from the vendor package).
8. On **Assignments**: under **Required**, add `IMPRIVATA – Clinical Endpoints – Pilot`.
9. Select **Next > Create**.

> Order note: if your Imprivata admin requires the reader driver present before the agent, set the reader-driver app as a **dependency** of the agent app on the agent's **Dependencies** tab (Step 3.7), or sequence the pilot so the driver app installs first.

### Step 5 — Create the endpoint baseline configuration profile

1. Navigate to `Devices > Configuration > Create > New Policy`.
2. Set **Platform** = `Windows 10 and later` and **Profile type** = `Settings catalog`. Select **Create**.
3. On **Basics**: set **Name** = `Imprivata Endpoint – Clinical Endpoints – Baseline`. Add a description.
4. On **Configuration settings**: add the settings your Imprivata admin and shared-device model require — for example, enabling **fast user switching** at the OS level and any lock/timeout behavior consistent with the appliance computer policy. **Confirm each setting value with your Imprivata admin** so the OS profile and the appliance computer policy do not conflict.
5. On **Assignments**: add `IMPRIVATA – Clinical Endpoints – Pilot` (add the full group in the Expand phase).
6. Select **Next > Create**.

## Phase 3 — Configure SSO / Badge

> Tap-and-go, fast user switching, and SSO into Epic and clinical web apps are driven primarily by the **Imprivata appliance computer policy and application profiles**, configured by your **Imprivata administrator**. The endpoint side (this document) ensures the agent and reader are present and the OS is prepared; the steps below are the integration points to confirm with the admin.

1. With your Imprivata administrator, confirm the **computer policy** that the pilot endpoints inherit is set for the **tap-and-go / fast user switching** experience appropriate to shared clinical endpoints (tap-in to start a session; tap-out to lock or switch). Record the policy name your admin assigns.
2. Confirm the **OneSign agent on the endpoint** is bound to the directory identity from R5 so each badge maps to a clinician's Entra/AD account.
3. With your Imprivata admin, confirm the **application profiles** that broker SSO into **Epic** and the clinical web apps are assigned to the pilot endpoints/users. Coordinate the Epic launch/credential-vault configuration with your **Epic / EHR team** (this is owned by Epic + Imprivata, not by Intune).
4. On the test device, enroll a test clinician's badge per your Imprivata admin's enrollment process (typically: clinician taps badge, then authenticates once with their directory credentials to bind the badge). Record that enrollment succeeds.

## Phase 4 — Enable EPCS

> EPCS is governed by **Imprivata Confirm ID**, **DEA regulations**, and your **compliance / pharmacy leadership**. Do not invent Confirm ID policy values or DEA specifics. The steps below establish the workflow shape; the regulatory configuration is owned by compliance and the Imprivata admin.

1. Confirm with compliance that **identity proofing** is complete for the test prescriber (R8) and that the **supervised approval** workflow is defined.
2. With your Imprivata admin, confirm the prescriber is **enrolled in Confirm ID** with the **approved two factors** (e.g., badge or fingerprint **plus** PIN — the exact approved factors come from compliance).
3. Confirm the **supervised approval** that grants the prescriber logical access to EPCS signing has been completed in Confirm ID.
4. Confirm the Epic EPCS signing workflow is configured (Epic + Imprivata) so that signing a controlled-substance order triggers the Confirm ID two-factor prompt.
5. Confirm **auditing** (R9) is capturing EPCS signing events for review.

## Phase 5 — Pilot

1. With the pilot assignments in place (apps, profile, and policy targeted to `IMPRIVATA – Clinical Endpoints – Pilot`), allow the pilot endpoints to receive the deployment within the approved maintenance window (G4).
2. On each pilot endpoint, confirm the agent and reader-driver apps install (`Apps > Monitor` shows **Installed**) and the reader enumerates without error.
3. Have pilot clinicians use tap-and-go for real (non-EPCS) sign-on, fast user switching, and SSO into Epic and clinical web apps for an agreed pilot period.
4. In a controlled, non-production context, exercise the EPCS two-factor signing of a controlled-substance order with the enrolled test prescriber (per `05-testing.md`).
5. Collect issues and tune the appliance policy (with your Imprivata admin) and the OS baseline profile as needed.

## Phase 6 — Validate

1. Execute the full test plan in `05-testing.md` against the pilot endpoints.
2. Confirm every test passes and the **acceptance gate** is met.
3. Obtain the compliance sign-off (R10) for the badge SSO / fast-user-switch behavior and, where in scope, the EPCS workflow.

## Phase 7 — Expand

1. In `Apps > All apps`, open `Imprivata Agent – Clinical Endpoints – Deploy` and `Proximity Reader Driver – Clinical Endpoints – Deploy`; on **Properties > Assignments**, add the full `IMPRIVATA – Clinical Endpoints` group under **Required**.
2. Open `Devices > Configuration > Imprivata Endpoint – Clinical Endpoints – Baseline > Properties > Assignments` and add the full `IMPRIVATA – Clinical Endpoints` group.
3. Add the remaining shared clinical endpoints to `IMPRIVATA – Clinical Endpoints` in controlled waves, each within an approved maintenance window.
4. With your Imprivata admin, extend the computer policy / application profiles and (where in scope) Confirm ID enrollment to the expanded population.
5. After each wave, run `IMPRIVATA-Report.ps1` to confirm coverage and re-run the acceptance checks on a sample.

---

## Rollback (per global requirement G7)

To back out on an endpoint or group: change the relevant Win32 app assignment to **Uninstall** for the target group (this triggers the admin-supplied silent uninstall), remove the `Imprivata Endpoint – Clinical Endpoints – Baseline` profile assignment, and remove the devices from `IMPRIVATA – Clinical Endpoints`. Coordinate with your Imprivata admin to revert the computer policy / application-profile assignment so endpoints return to the prior sign-on behavior. Rehearse this on the test device before fleet expansion.
