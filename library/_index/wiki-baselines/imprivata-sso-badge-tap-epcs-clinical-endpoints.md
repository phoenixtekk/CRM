# Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

> **Version 1.0.0** · Category: Healthcare Solutions · Solution code: IMPRIVATA

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

## The challenge

On shared clinical endpoints — Workstations-On-Wheels, exam-room PCs, and nursing-station kiosks — password-based sign-on is slow, repetitive, and a known driver of clinician burnout and unsafe workarounds (shared passwords, sessions left open, sticky notes). At the same time, electronically prescribing controlled substances carries a strict regulatory burden: the DEA requires identity proofing, two-factor authentication, logical access controls, and a tamper-evident audit trail before any controlled-substance prescription can be signed. Most organizations face both problems on the same devices, with the same clinicians.

## The solution

This solution deploys and configures **Imprivata OneSign** for clinical endpoints so clinicians authenticate with a **tap of a proximity badge** instead of a password, switch users in seconds on shared workstations, single-sign-on into the **Epic EHR** and clinical web applications, and — where required — complete **EPCS** (Electronic Prescribing of Controlled Substances) two-factor signing through **Imprivata Confirm ID**. The Imprivata agent and the proximity reader drivers are delivered through **Microsoft Intune** using the standard deployment model: packaged Win32 apps, a named device group, configuration profiles, and identity integrated with Microsoft Entra ID / Active Directory.

The work follows a disciplined phase model — **Assess → Deploy Agent → Configure SSO/Badge → Enable EPCS → Pilot → Validate → Expand** — with named, reusable objects and a defined acceptance gate, so the rollout is repeatable and auditable from a pilot ward to the entire fleet.

## Business outcomes

- **Faster, safer clinician sign-on.** Badge tap-and-go and fast user switching remove the password friction that drives unsafe workarounds, while every session is correctly attributed to the clinician who tapped in.
- **One sign-on into clinical apps.** OneSign brokers credentials into Epic and clinical web apps, so clinicians authenticate once per tap rather than once per application.
- **Compliant controlled-substance signing.** Confirm ID provides the DEA-aligned two-factor workflow and supervised approval needed for EPCS, with an audit trail for review.
- **Scalable, monitored delivery.** Intune installs, targets, and reports on the agent and reader drivers, so the same deployment scales in controlled waves with continuous compliance visibility.

## Scope and governance

The solution covers the **Intune deployment, endpoint configuration, identity integration, and validation/testing**. Imprivata appliance/console policy values, license SKUs, and EPCS/DEA regulatory specifics are intentionally **not invented here** — they are governed by the organization's **Imprivata administrator and Imprivata documentation** and by **DEA EPCS regulations and the organization's compliance/pharmacy leadership**, and the documentation directs the reader to those owners at every regulated decision point. The deployment is gated by HIPAA/HITRUST change control, clinical maintenance windows, a validated test plan, and documented compliance sign-off.

## What you receive

A complete, productized package: nine implementation documents, five runnable PowerShell scripts (discovery, per-device validation, fleet reporting, safe remediation, and group provisioning), and a listing hero image — everything needed to deploy, validate, and expand Imprivata tap-and-go SSO and EPCS across shared clinical endpoints with confidence.


---


# 1. Solution Overview — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

## What this solution delivers

This solution deploys and configures **Imprivata OneSign** across shared clinical endpoints so that clinicians authenticate with a **tap of a proximity badge** instead of typing usernames and passwords, switch between users in seconds on a shared workstation, single-sign-on into the **Epic EHR** and clinical web applications, and complete **Electronic Prescribing of Controlled Substances (EPCS)** two-factor signing where required. The Imprivata agent and the proximity card-reader drivers are delivered to the endpoints with **Microsoft Intune** using the standard deployment model — packaged Win32 apps, an Entra device group, and configuration profiles — and identity is integrated with **Microsoft Entra ID / Active Directory**.

The result is the "tap-and-go" clinical workstation experience: a clinician walks up to a Workstation-On-Wheels (WOW), exam-room PC, or nursing-station kiosk, taps their badge, and is immediately at their session inside Epic; they tap out (or another clinician taps in) and the session is locked or switched in place. Where a controlled-substance prescription must be signed, Imprivata Confirm ID drives the EPCS two-factor prompt (badge or fingerprint **plus** a second factor such as a PIN) and records the audit trail.

## What problem it solves

On shared clinical endpoints, password-based login is slow, error-prone, and a documented source of clinician burnout and workarounds (shared passwords, never-locking sessions, sticky notes). EPCS adds a regulatory burden: the DEA requires identity proofing, two-factor authentication, logical access controls, and a tamper-evident audit trail before any controlled-substance prescription can be signed electronically. This solution closes both gaps at once:

- **Speed and safety on shared devices** — badge tap-and-go and fast user switching remove the password friction that drives unsafe workarounds, while every session is attributed to the clinician who tapped in.
- **One sign-on into clinical apps** — Imprivata OneSign brokers credentials into Epic and clinical web apps so clinicians sign on once per tap, not once per application.
- **Compliant controlled-substance signing** — Imprivata Confirm ID provides the DEA-required two-factor workflow and the supervised approval / identity-proofing process for EPCS.
- **Repeatable, fleet-wide delivery** — Intune installs the agent and reader drivers, targets the right devices by group, and reports compliance, so the same deployment scales from a pilot ward to the whole organization.

## Scope and boundaries

**In scope (this document):**
- Intune packaging and deployment of the **Imprivata OneSign agent** and the **proximity reader drivers** as named Win32 apps.
- Creation of the **Entra device group `IMPRIVATA – Clinical Endpoints`** and the configuration profiles that prepare endpoints for tap-and-go and fast user switching.
- Endpoint-side configuration and identity integration with Entra ID / Active Directory.
- The endpoint-side enablement of SSO into Epic and clinical web apps, tap-and-go, fast user switching, and the EPCS two-factor experience.
- Pilot, validation, and fleet expansion, with named objects and full navigation paths.

**Out of scope / owned elsewhere — do not invent these values:**
- **Imprivata appliance and console policy values** (OneSign / Confirm ID server configuration, application profile definitions, computer policies, license SKUs, agent installer parameters specific to your version). These are governed by **your Imprivata administrator and Imprivata's customer documentation**. This document tells you *where* the endpoint integrates; your Imprivata admin supplies the policy values.
- **EPCS / DEA regulatory specifics** (identity-proofing provider, two-factor credential requirements, incident-reporting obligations, audit-retention periods). These are governed by **DEA EPCS regulations and your organization's compliance / pharmacy leadership**. This document documents the *workflow shape* accurately; your compliance team owns the regulatory configuration and sign-off.
- **Epic application-side SSO configuration** (Epic credential vaulting, Hyperdrive/Hyperspace launch settings) — coordinated with your Epic / EHR team and your Imprivata admin.

Throughout, named objects (the Win32 apps, the device group, the configuration profiles) follow the `<Purpose> – <Scope> – <Stage>` convention and are reused verbatim in later documents so the build is traceable end to end.

## Phase model

The solution follows a seven-phase model, used consistently across the requirements, implementation, and testing documents:

1. **Assess** — confirm prerequisites: Imprivata licensing and appliance reachability, Confirm ID for EPCS, reader hardware and drivers, Intune/Entra readiness, target OS, and the shared-device model.
2. **Deploy Agent** — package and deploy the Imprivata agent and reader drivers via Intune Win32 apps to the clinical device group.
3. **Configure SSO / Badge** — bind the agent to identity, enable tap-and-go badge SSO and fast user switching, and broker SSO into Epic and clinical web apps.
4. **Enable EPCS** — enable the Confirm ID two-factor enrollment and the supervised approval / identity-proofing workflow for controlled-substance signing.
5. **Pilot** — run a small, representative ward / set of endpoints end to end.
6. **Validate** — execute the test plan and meet the acceptance gate.
7. **Expand** — roll out to the remaining clinical endpoints in controlled waves.

## Audience

This solution is written for the IT team that owns endpoint management (Intune administrators), in partnership with the **Imprivata administrator** (appliance-side policy), the **Epic / EHR team** (application SSO), and the organization's **compliance / pharmacy leadership** (EPCS / DEA). Steps are written so a competent Intune administrator can execute them without prior Imprivata experience, deferring appliance-side and regulatory values to the named owners.

## Outcome

On completion, clinicians on the targeted endpoints tap a badge to sign in, switch users instantly on shared devices, single-sign-on into Epic and clinical web apps, and complete EPCS two-factor signing where required — all delivered and monitored through Intune, with a validated audit trail and a documented path to expand across the fleet.


---


# 2. Requirements — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

These are the solution-specific requirements. The category-wide prerequisites shared by every Healthcare Solution (tenant and roles, Windows licensing, HIPAA/HITRUST data-handling and change control, clinical maintenance windows, network reachability, a test device, and rollback) are documented separately in `global-requirements-healthcare-solutions.md` and must also be satisfied. **Never assume a prerequisite is already in place** — for each requirement below, confirm it explicitly using the **Verify** action, and follow **Implement if missing** when it is not.

Each requirement is stated as: **Description / Why / Verify / Implement if missing.**

---

## R1 — Imprivata OneSign licensing and a reachable Imprivata appliance

- **Description:** The organization has active **Imprivata OneSign** licensing and at least one Imprivata appliance (physical or virtual) that the clinical endpoints can reach over the network.
- **Why:** The OneSign agent on each endpoint authenticates badge taps, brokers SSO, and enforces computer policy by communicating with the appliance. Without licensing and reachability, the agent installs but cannot function.
- **Verify:** Confirm with your **Imprivata administrator** that OneSign is licensed and the appliance is in service. From a representative clinical endpoint, confirm the endpoint can resolve and reach the appliance host/port your Imprivata admin specifies (do not invent the port — obtain it from the admin).
- **Implement if missing:** Engage your Imprivata administrator / Imprivata account team to provision licensing and stand up or expose the appliance. Open the required network path per `global-requirements-healthcare-solutions.md`. Do not proceed to agent deployment until the appliance is reachable.

## R2 — Imprivata Confirm ID for EPCS

- **Description:** **Imprivata Confirm ID** (the typical Imprivata product for EPCS) is licensed and configured on the appliance for Electronic Prescribing of Controlled Substances.
- **Why:** EPCS requires DEA-compliant two-factor authentication, identity proofing, logical access controls, and audit. Confirm ID provides the supervised approval and two-factor signing workflow that OneSign alone does not.
- **Verify:** Confirm with your Imprivata administrator that Confirm ID is licensed and enabled, and confirm with your **compliance / pharmacy leadership** that the EPCS program (identity-proofing provider, approved second factors, supervised approval process) is established. **Do not invent DEA specifics or Confirm ID policy values.**
- **Implement if missing:** If only OneSign (SSO/badge) is required for the initial scope, EPCS can be a later phase — but flag it explicitly with compliance. To enable EPCS, your Imprivata admin licenses/configures Confirm ID and your compliance team establishes the DEA-required identity-proofing and approval workflow before any controlled-substance signing is attempted.

## R3 — Proximity card readers and drivers

- **Description:** Each target endpoint has a **proximity card reader** compatible with your badge technology, and the corresponding **reader driver** is available to package for Intune.
- **Why:** Tap-and-go badge SSO and fast user switching depend on the OS recognizing the reader and reading the badge. Readers are frequently the failure point if drivers are missing or mismatched.
- **Verify:** Inventory the reader make/model on a representative endpoint. On a test endpoint, confirm whether the reader enumerates in **Device Manager** without error. Confirm with your Imprivata admin which reader models and badge formats your OneSign deployment supports.
- **Implement if missing:** Procure supported readers. Obtain the vendor driver package and prepare it as the named reader-driver Win32 app (see `03-implementation.md`). Where a reader is HID-class and driverless, document that and skip the driver app for those models.

## R4 — Microsoft Intune licensing and enrollment

- **Description:** The organization has **Microsoft Intune** licensing, and the target clinical endpoints are **enrolled and managed** in Intune.
- **Why:** Intune is the delivery and reporting mechanism for the agent, reader drivers, configuration profiles, and group targeting in the standard deployment model.
- **Verify:** In the **Microsoft Intune admin center** (`Devices > All devices`), confirm a representative clinical endpoint appears as managed and compliant. Confirm Intune licensing covers the user/device count.
- **Implement if missing:** License Intune and enroll the endpoints (Entra hybrid join / Entra join + Intune enrollment, per your standard). See `global-requirements-healthcare-solutions.md` for tenant and role prerequisites.

## R5 — Entra ID / Active Directory identity integration

- **Description:** Clinicians have identities in **Microsoft Entra ID** and/or **Active Directory**, and that identity source is the one Imprivata OneSign is configured to authenticate against.
- **Why:** OneSign maps each badge to a directory identity and brokers that identity into Epic and clinical web apps. The directory Imprivata trusts must be the directory the endpoints and Intune use.
- **Verify:** Confirm with your Imprivata admin which directory OneSign authenticates against (AD domain, Entra, or hybrid). Confirm representative clinician accounts exist and are enabled in that directory.
- **Implement if missing:** Establish directory integration (Entra Connect / hybrid join) so the same identities are present in the directory Imprivata trusts and in Entra/Intune. Reconcile any clinicians missing from the trusted directory before enrollment.

## R6 — Target operating system

- **Description:** Target endpoints run a **supported Windows edition and build** for both the Imprivata agent and Intune Win32 app delivery.
- **Why:** The agent, reader drivers, and the tap-and-go / fast-user-switching experience require a supported OS; unsupported builds cause install failures or unstable behavior.
- **Verify:** In `Devices > All devices`, review the OS edition/build of representative endpoints. Confirm the build is supported by the Imprivata agent version your admin provides.
- **Implement if missing:** Update endpoints to a supported build via your standard update process within a clinical maintenance window before deploying the agent.

## R7 — Shared-device model confirmed

- **Description:** The deployment is confirmed as a **shared clinical endpoint** model (WOWs, exam-room PCs, nursing-station kiosks used by many clinicians) rather than 1:1 assigned devices.
- **Why:** Shared devices drive the configuration choices — fast user switching, tap-out/lock behavior, and **device-targeted** (not user-targeted) Intune assignments. Mis-modeling this produces the wrong assignment and policy design.
- **Verify:** Confirm with clinical operations which endpoints are shared and the expected lock/switch behavior on tap-out. Confirm the device group will be the targeting unit.
- **Implement if missing:** Classify endpoints as shared vs. assigned and document the list. Build the `IMPRIVATA – Clinical Endpoints` device group for the shared set; treat any assigned devices as a separate scope.

## R8 — EPCS identity proofing and two-factor enrollment readiness

- **Description:** For any clinician who will sign controlled-substance prescriptions, the **DEA-required identity proofing** is completed and the clinician is enrolled with the **approved two-factor credentials** (e.g., badge + PIN, or fingerprint + a second factor) in Confirm ID.
- **Why:** EPCS prohibits controlled-substance e-signing until the prescriber is identity-proofed and enrolled with two factors, and a supervised approval grants the logical access. This is a regulatory gate, not a technical convenience.
- **Verify:** Confirm with compliance / pharmacy leadership the list of EPCS prescribers, that identity proofing is complete, and that the supervised approval workflow is defined. **Defer the specific proofing method, approved factors, and DEA requirements to compliance — do not invent them.**
- **Implement if missing:** Compliance / pharmacy leadership runs identity proofing and the supervised approval; the Imprivata admin enrolls credentials in Confirm ID. No EPCS signing test (see `05-testing.md`) is run until enrollment and approval are complete for the test prescriber.

## R9 — Audit and logging

- **Description:** Imprivata audit/logging (sign-on events, badge taps, EPCS signing events) is enabled and retained per your compliance requirements, and the events are reviewable.
- **Why:** EPCS requires a tamper-evident audit trail, and tap-and-go attribution depends on reliable event logging. Validation (see `05-testing.md`) checks that audit entries are present.
- **Verify:** Confirm with your Imprivata admin and compliance team that auditing is enabled on the appliance and that the retention period meets policy. Confirm an authorized reviewer can access the audit records.
- **Implement if missing:** Your Imprivata admin enables auditing and configures retention; compliance confirms retention meets DEA/organizational policy. Establish the review access before EPCS go-live.

## R10 — Compliance sign-off

- **Description:** Documented **compliance sign-off** authorizing the badge SSO / fast-user-switch behavior and the EPCS workflow on the targeted endpoints, before production use.
- **Why:** The solution changes how clinicians authenticate to PHI systems and how controlled substances are signed — both are governed activities requiring HIPAA/HITRUST and DEA-aligned approval.
- **Verify:** Obtain written sign-off from compliance / security leadership covering the shared-device sign-on model, session-lock behavior, and (where in scope) the EPCS workflow. Reference the change-control record from `global-requirements-healthcare-solutions.md`.
- **Implement if missing:** Do not enable production EPCS signing or fleet expansion until sign-off is recorded. Pilot in a controlled, non-production-signing context only.

---

## Requirements summary

| # | Requirement | Owner to confirm with | Gate |
|---|-------------|----------------------|------|
| R1 | OneSign licensing + reachable appliance | Imprivata admin | Deploy Agent |
| R2 | Confirm ID for EPCS | Imprivata admin + compliance | Enable EPCS |
| R3 | Proximity readers + drivers | IT / Imprivata admin | Configure SSO/Badge |
| R4 | Intune licensing + enrollment | Intune admin | Deploy Agent |
| R5 | Entra/AD identity integration | Imprivata admin + identity team | Configure SSO/Badge |
| R6 | Supported target OS | Intune admin | Deploy Agent |
| R7 | Shared-device model confirmed | Clinical ops | Assess |
| R8 | EPCS identity proofing + two-factor enrollment | Compliance / pharmacy | Enable EPCS |
| R9 | Audit + logging | Imprivata admin + compliance | Validate |
| R10 | Compliance sign-off | Compliance / security | Pilot → Expand |


---


# Global Requirements — Healthcare Solutions

These category-wide prerequisites apply to **every** solution in the Healthcare Solutions category and must be satisfied in addition to the solution-specific requirements in `02-requirements.md`. They are generic to clinical-endpoint and clinical-identity work in a HIPAA/HITRUST-governed environment. **Never assume any of these are already in place** — confirm each one explicitly.

Each requirement is stated as: **Description / Why / Verify / Implement if missing.**

---

## G1 — Microsoft tenant and administrative roles

- **Description:** A Microsoft Entra / Microsoft 365 tenant is in place, and the implementer holds the **least-privilege administrative roles** required for the work (typically **Intune Administrator** for app/profile/group work, and **Global Reader** for read-only verification). Privileged roles are time-bound where PIM is used.
- **Why:** Deploying apps, configuration profiles, and groups requires specific Intune/Entra permissions; using least privilege limits blast radius in a clinical tenant.
- **Verify:** In the **Microsoft Entra admin center** (`Identity > Roles & admins`), confirm the implementer's role assignments. In the **Microsoft Intune admin center**, confirm the implementer can open `Apps`, `Devices`, and `Groups`.
- **Implement if missing:** Assign the minimum roles needed (Intune Administrator scoped where possible), preferably as eligible PIM assignments activated for the change window.

## G2 — Windows licensing and management entitlement

- **Description:** Target endpoints are covered by the appropriate **Windows** and **Microsoft Intune** licensing for management and Win32 app delivery.
- **Why:** Win32 app deployment, configuration profiles, and compliance reporting require the endpoints and users to be correctly licensed and enrolled.
- **Verify:** Confirm licensing assignment in the admin center; confirm a representative endpoint is enrolled and compliant in `Devices > All devices`.
- **Implement if missing:** Assign the required licenses and complete enrollment before deploying any payload.

## G3 — HIPAA/HITRUST data-handling and change control

- **Description:** The work follows the organization's **HIPAA/HITRUST data-handling and change-control** processes: a recorded change request, an approval, a defined back-out, and no PHI handled outside approved systems.
- **Why:** Clinical-endpoint and identity changes affect access to PHI; governance is mandatory and auditable.
- **Verify:** Confirm an approved change record exists for this work and that data-handling rules (no PHI in screenshots, logs, or exports) are understood by the implementer.
- **Implement if missing:** Open and obtain approval for a change record before making changes. Ensure all artifacts (reports, logs) are scrubbed of PHI.

## G4 — Clinical maintenance windows

- **Description:** Changes that affect clinician sign-on or device behavior are scheduled within an **approved clinical maintenance window** that avoids disrupting patient care.
- **Why:** Sign-on and session changes on shared clinical endpoints can interrupt active care if applied during peak clinical hours.
- **Verify:** Confirm the maintenance window with clinical operations and that the targeted wards are aware.
- **Implement if missing:** Schedule the window with clinical operations; stage deployments (pilot first) so changes land in the agreed window.

## G5 — Network reachability to Microsoft, Imprivata, and Epic endpoints

- **Description:** Endpoints can reach the required **Microsoft (Intune/Entra)**, **Imprivata appliance**, and **Epic / clinical web app** endpoints over the network, including any required proxy/firewall allowances.
- **Why:** Each component fails silently or partially if a required network path is blocked — Intune can't deliver, the agent can't reach the appliance, or SSO can't reach Epic.
- **Verify:** From a representative endpoint, confirm reachability to the Microsoft management endpoints, to the Imprivata appliance host/port supplied by your Imprivata admin, and to the Epic/clinical web app URLs supplied by your EHR team. **Do not invent hosts/ports** — obtain them from the respective owners.
- **Implement if missing:** Work with networking to allow the required paths through proxy/firewall. Re-test reachability before deployment.

## G6 — Test device

- **Description:** A **representative test endpoint** (same make/model, reader, and OS build as production clinical endpoints) is available for piloting before fleet rollout.
- **Why:** Reader behavior, agent install, and SSO depend on hardware and build specifics; validating on a representative device prevents fleet-wide surprises.
- **Verify:** Confirm a test device exists that matches the production hardware/reader/OS and is enrolled in Intune.
- **Implement if missing:** Designate and enroll a representative test device before starting deployment.

## G7 — Rollback / back-out plan

- **Description:** A documented **rollback** exists: how to remove or disable the agent, reader drivers, and profiles, and restore the prior sign-on behavior on an endpoint or group.
- **Why:** If the deployment causes sign-on failures on shared clinical endpoints, a fast, rehearsed back-out is required to protect patient care.
- **Verify:** Confirm the rollback steps are written (uninstall via the Intune app's **Uninstall** assignment, remove the profile assignment, remove devices from the group) and that an owner is named.
- **Implement if missing:** Author the rollback steps as part of change control, including how to revert each named object created in `03-implementation.md`, and rehearse on the test device.

---

## Global requirements summary

| # | Requirement | Verify location | Gate |
|---|-------------|-----------------|------|
| G1 | Tenant + least-privilege roles | Entra / Intune admin centers | Assess |
| G2 | Windows + Intune licensing | Admin center / Devices | Deploy Agent |
| G3 | HIPAA/HITRUST + change control | Change record | Assess |
| G4 | Clinical maintenance windows | Clinical operations | Pilot |
| G5 | Network to Microsoft + Imprivata + Epic | On-endpoint reachability test | Deploy Agent |
| G6 | Representative test device | Devices > All devices | Pilot |
| G7 | Rollback / back-out plan | Change record | All phases |


---


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


---


# 5. Testing — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

This document is the validation plan. Run it against the pilot endpoints (group `IMPRIVATA – Clinical Endpoints – Pilot`) in the **Validate** phase, and on a sample of each wave during **Expand**. Each test has a **procedure**, an **expected result**, and a **PASS/FAIL** record. The **acceptance gate** at the end must be fully met before production EPCS signing and before fleet expansion. Run all tests with **test accounts and test data only** — never use real PHI or sign a real controlled-substance order in testing.

> Names referenced below are the exact objects from `03-implementation.md`: the Win32 apps `Imprivata Agent – Clinical Endpoints – Deploy` and `Proximity Reader Driver – Clinical Endpoints – Deploy`, the device group `IMPRIVATA – Clinical Endpoints` (pilot subset `IMPRIVATA – Clinical Endpoints – Pilot`), and the configuration profile `Imprivata Endpoint – Clinical Endpoints – Baseline`.

---

## T1 — Agent installed

- **Procedure:** In `Apps > All apps > Imprivata Agent – Clinical Endpoints – Deploy > Monitor`, confirm the pilot device shows **Installed**. On the device, confirm the agent is present using the detection criteria supplied by your Imprivata admin (installed file/version or registry key).
- **Expected result:** The agent reports **Installed** in Intune and is present on the device at the expected version.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T2 — Reader driver installed and reader detected

- **Procedure:** In `Apps > All apps > Proximity Reader Driver – Clinical Endpoints – Deploy > Monitor`, confirm **Installed** (skip for documented HID-class driverless readers). On the device, open **Device Manager** and confirm the proximity reader enumerates with **no warning/error icon**.
- **Expected result:** Driver reports **Installed**; the reader appears in Device Manager without error and is ready.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T3 — Device in the clinical group

- **Procedure:** In `Groups > IMPRIVATA – Clinical Endpoints – Pilot > Members`, confirm the pilot device is a member. Confirm the agent app, driver app, and `Imprivata Endpoint – Clinical Endpoints – Baseline` profile are assigned to that group.
- **Expected result:** The device is a member and all three objects are assigned and applied (profile shows **Succeeded** in `Devices > Configuration`).
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T4 — Badge tap logs in (tap-and-go)

- **Procedure:** With an enrolled test clinician badge, tap the badge on the reader at a locked/idle pilot endpoint.
- **Expected result:** The badge tap authenticates and starts the clinician's session (tap-and-go) without typing a password, mapping to the correct directory identity.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T5 — Fast user switching works

- **Procedure:** With test clinician A signed in via tap, have test clinician B tap their enrolled badge on the same shared endpoint.
- **Expected result:** Clinician A's session is locked/secured and clinician B is switched in (or A is tapped out and B taps in), per the configured shared-device behavior — quickly and without exposing A's session to B.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T6 — SSO into Epic

- **Procedure:** As a tapped-in test clinician, launch **Epic** (and a clinical web app) from the pilot endpoint.
- **Expected result:** Imprivata OneSign brokers the credentials and the clinician reaches their Epic session (and the clinical web app) without a separate manual sign-on.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T7 — EPCS two-factor prompts and completes (test context)

- **Procedure:** With the enrolled, identity-proofed, supervisor-approved **test prescriber**, sign a **controlled-substance order in a non-production / test context** in Epic so the Imprivata Confirm ID EPCS workflow is invoked.
- **Expected result:** The two-factor prompt appears (e.g., badge or fingerprint **plus** the approved second factor such as PIN), and on supplying both valid factors the signing completes. Supplying only one factor, or an invalid factor, is rejected.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

> Do not run T7 until R8 (identity proofing + two-factor enrollment) and the supervised approval are confirmed complete for the test prescriber, and only in a test context approved by compliance.

## T8 — Audit entries present

- **Procedure:** With your Imprivata admin / an authorized reviewer, review the Imprivata audit log for the events generated by T4–T7 (badge sign-on, fast user switch, SSO, EPCS signing).
- **Expected result:** Each action produced a corresponding audit entry attributing it to the correct clinician/prescriber, and EPCS signing events are recorded for the required retention period (R9).
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T9 — Negative / failure handling

- **Procedure:** (a) Tap an **unenrolled** badge. (b) Present an EPCS signing with only **one** factor. (c) Temporarily simulate loss of appliance reachability (with admin coordination) and tap a badge.
- **Expected result:** (a) Unenrolled badge does not grant a session. (b) Single-factor EPCS signing is rejected. (c) The endpoint degrades safely (no session granted / clear message) rather than granting unauthenticated access.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

---

## Acceptance gate

The deployment is accepted for production EPCS signing and fleet expansion **only when all of the following are true**:

- **T1** Agent installed — PASS
- **T2** Reader driver installed and reader detected — PASS
- **T3** Device in the clinical group with all objects assigned — PASS
- **T4** Badge tap logs in (tap-and-go) — PASS
- **T5** Fast user switching works — PASS
- **T6** SSO into Epic (and clinical web apps) — PASS
- **T7** EPCS two-factor prompts and completes in a test context — PASS
- **T8** Audit entries present for all of the above — PASS
- **T9** Negative / failure handling behaves safely — PASS
- **Compliance sign-off (R10)** recorded for the badge SSO / fast-user-switch behavior and the EPCS workflow.

Record the gate decision, date, tester, and approver. Any FAIL blocks expansion until remediated (see `06-troubleshooting.md`) and re-tested.


---


# 6. Troubleshooting — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

Symptom-driven fixes for the most common issues across the deployment. Work top-down within each symptom. Object names match `03-implementation.md`: Win32 apps `Imprivata Agent – Clinical Endpoints – Deploy` and `Proximity Reader Driver – Clinical Endpoints – Deploy`, device group `IMPRIVATA – Clinical Endpoints` (pilot subset `IMPRIVATA – Clinical Endpoints – Pilot`), profile `Imprivata Endpoint – Clinical Endpoints – Baseline`. Appliance-side policy values and EPCS/DEA specifics are owned by your **Imprivata administrator** and **compliance team** — escalate to them where indicated rather than guessing.

---

## Reader not detected

- **Confirm the driver deployed.** In `Apps > All apps > Proximity Reader Driver – Clinical Endpoints – Deploy > Monitor`, confirm **Installed** for the device. If **Failed/Pending**, see "Agent or driver app won't install" below.
- **Check Device Manager.** On the endpoint, open **Device Manager** and look for the reader. If it shows a warning/error icon, the driver is missing or mismatched — confirm the reader make/model matches the deployed driver (R3) and that the model is one your Imprivata admin supports.
- **Check install order.** If the agent installed before the driver, the reader may not bind on first tap. Set the reader-driver app as a **dependency** of the agent (Intune `Apps > Imprivata Agent – Clinical Endpoints – Deploy > Dependencies`) and re-sync, or reinstall the driver then the agent.
- **HID-class readers.** For driverless HID readers, no driver app is expected; confirm the reader enumerates as an HID device and is enabled.
- **Physical.** Reseat/replace the USB reader; test on the representative test device to isolate hardware vs. software.

## Badge not enrolling

- **Confirm directory mapping.** Badge enrollment binds a badge to a directory identity (R5). Confirm the clinician's account exists and is enabled in the directory OneSign authenticates against, and that it is the same directory used by Intune/Entra.
- **Confirm appliance reachability.** Enrollment requires the agent to reach the appliance. From the endpoint, confirm reachability to the appliance host/port your Imprivata admin specified (R1, G5). A blocked path causes enrollment to hang or fail.
- **Confirm enrollment policy.** With your Imprivata admin, confirm the endpoint inherits a computer policy that permits self-enrollment / first-tap binding. Escalate the policy value to the admin — do not change appliance policy yourself.
- **Badge format.** Confirm the badge technology/format is one the reader and OneSign deployment support.

## Slow tap (latency on tap-in)

- **Check appliance reachability/latency.** Slow tap-in is often network latency to the appliance or to the directory during the auth/broker step. Test reachability and round-trip from the endpoint; involve networking if latency is high.
- **Check directory responsiveness.** If OneSign authenticates against a remote DC/Entra, slow directory responses slow tap-in. Confirm the endpoint uses a responsive directory path.
- **Check SSO scope at tap.** If many application profiles fire at tap-in, sign-on can feel slow. With your Imprivata admin, review which application profiles launch on tap vs. on demand.
- **Endpoint health.** Confirm the endpoint meets the supported OS/build (R6) and isn't resource-starved; reboot to clear transient agent state.

## SSO fails to Epic (or clinical web apps)

- **Confirm the application profile.** SSO into Epic is driven by an Imprivata **application profile** owned by your Imprivata admin and coordinated with the Epic/EHR team. Confirm the profile is assigned to the endpoint/user and is current with the Epic client version.
- **Confirm Epic-side configuration.** Epic credential vaulting / launch settings are owned by the Epic team. If only Epic SSO fails (badge tap and other apps work), escalate to Epic + Imprivata admin.
- **Confirm reachability to Epic.** From the endpoint, confirm the Epic/clinical web app URLs supplied by the EHR team are reachable (G5).
- **Confirm credentials are vaulted.** First-time SSO often requires the clinician to authenticate once so OneSign can vault the credential; confirm that one-time step completed for the clinician.

## Fast-user-switch issues

- **Confirm OS profile applied.** In `Devices > Configuration > Imprivata Endpoint – Clinical Endpoints – Baseline`, confirm the profile shows **Succeeded** on the device and that fast user switching is enabled at the OS level.
- **Confirm appliance computer policy.** The switch/tap-out behavior (lock vs. log off vs. switch) is set by the appliance computer policy. If the OS profile and appliance policy conflict, behavior is inconsistent — reconcile values with your Imprivata admin so they agree.
- **Confirm shared-device model.** Ensure the device is treated as shared (R7) and assignments are device-targeted, not user-targeted, so the experience follows the device.
- **Session security.** If clinician A's session is briefly exposed during a switch, treat as a safety defect — escalate the policy timing to the Imprivata admin and re-run test T5.

## EPCS two-factor failures

- **Confirm enrollment + approval.** EPCS signing requires the prescriber to be identity-proofed, enrolled in **Confirm ID** with the approved two factors, and granted access via the supervised approval (R8, R2). Confirm all three with compliance/pharmacy and the Imprivata admin before debugging anything technical.
- **Confirm both factors are valid.** A rejected signing usually means one factor failed (wrong PIN, unenrolled/failed biometric, wrong badge). Confirm the prescriber is using the **approved** factor combination — defer the approved factors to compliance.
- **Confirm Confirm ID reachability.** The two-factor prompt depends on the agent reaching the appliance/Confirm ID; confirm reachability (R1, G5).
- **Confirm the Epic EPCS workflow.** If signing never triggers a prompt, the Epic EPCS signing workflow may not be wired to Confirm ID — escalate to the Epic team + Imprivata admin.
- **Do not work around EPCS.** Never disable or bypass two-factor to "unblock" signing — that breaks DEA compliance. Escalate to compliance.

## Audit gaps (missing or wrong-attribution entries)

- **Confirm auditing enabled.** With your Imprivata admin, confirm auditing is enabled on the appliance and capturing sign-on, switch, SSO, and EPCS events (R9).
- **Confirm attribution.** If events attribute to the wrong clinician, suspect a badge mapped to the wrong identity or a session not secured on switch — re-verify enrollment (R5) and fast user switching (T5).
- **Confirm retention.** Confirm the retention period meets DEA/organizational policy with compliance; gaps in retention are a compliance issue, not just a technical one.
- **Confirm reviewer access.** Ensure an authorized reviewer can access the audit records; lack of access is often mistaken for "missing" audit.

## Agent or driver app won't install (Intune)

- **Check detection rules.** A "failed" install with the app actually present usually means wrong detection criteria. Confirm the detection rule matches the admin-supplied installed file/version or registry key.
- **Check command lines.** Confirm the silent install/uninstall command lines are exactly those supplied by your Imprivata admin / the driver vendor (do not invent switches).
- **Check requirements.** Confirm the device meets the app's OS architecture/minimum OS (R6); a requirement mismatch leaves the app **Not applicable**.
- **Check assignment and sync.** Confirm the app is assigned **Required** to the device's group (`IMPRIVATA – Clinical Endpoints – Pilot` during pilot) and force an Intune sync; review the Intune install logs on the endpoint.
- **Remediate.** Use `IMPRIVATA-Remediation.ps1 -Apply` to safely re-deploy the named app to the device after the root cause is addressed.

---

## Escalation map

| Issue domain | Escalate to |
|--------------|-------------|
| Appliance policy, application profiles, agent installer specifics, enrollment policy | Imprivata administrator |
| Epic credential vaulting / launch / EPCS signing workflow | Epic / EHR team (with Imprivata admin) |
| EPCS identity proofing, approved factors, supervised approval, DEA requirements, audit retention | Compliance / pharmacy leadership |
| Intune app/profile/group delivery, device enrollment, reporting | Intune administrator |
| Network reachability to Microsoft / Imprivata / Epic | Networking team |


---


# 7. Best Practices — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

These practices keep the deployment safe, fast, and compliant across the lifecycle. They complement — they do not replace — your Imprivata administrator's appliance guidance and your compliance team's EPCS/DEA requirements.

## Identity and ownership

- **Keep one source of truth for identity.** Ensure OneSign authenticates against the same directory (Entra/AD) that Intune and the endpoints use. Reconcile leavers/joiners in that directory promptly so badges always map to valid, current clinician accounts.
- **Respect the ownership boundaries.** Appliance computer policy, application profiles, and Confirm ID/EPCS configuration are owned by the Imprivata admin and compliance. Use Intune for delivery (agent, drivers, OS baseline, group, reporting) and confirm policy values with the owners rather than guessing.
- **Use least privilege.** Scope Intune roles to what the work needs and activate privileged roles only for the change window.

## Deployment hygiene

- **Pilot before fleet, always.** Validate on the representative test device and `IMPRIVATA – Clinical Endpoints – Pilot` before adding the full `IMPRIVATA – Clinical Endpoints` group. Expand in controlled waves within approved maintenance windows.
- **Sequence the driver before the agent** where your Imprivata admin requires it — use a Win32 **dependency** so the reader driver is present before the agent installs, preventing "reader not detected" on first tap.
- **Pin and record versions.** Record the exact agent version, installer/uninstaller command lines, and detection criteria from your Imprivata admin in change control, and keep the Win32 app's publisher set to `Imprivata, Inc.` (and the reader driver to the exact vendor string).
- **Use device-targeted assignments** for shared endpoints — assign apps and the baseline profile to the device group, not to users, so the experience follows the shared device.

## Shared-device behavior

- **Tune tap-out / lock for the ward.** Confirm with clinical operations and the Imprivata admin whether tap-out should lock, log off, or switch — and that idle-lock timing matches clinical workflow without leaving sessions exposed.
- **Never leave a session attributable to the wrong clinician.** Validate fast user switching so clinician A's session is always secured before clinician B is active; this is both a safety and an attribution requirement.

## EPCS and compliance

- **Treat EPCS as a regulated gate, not a feature toggle.** No prescriber signs controlled substances until identity proofing, two-factor enrollment, and supervised approval are complete. Keep these owned by compliance/pharmacy and the Imprivata admin.
- **Verify two factors are genuinely independent.** Confirm the approved factor combination meets DEA requirements (something you have + something you are/know) per compliance — do not assume badge alone satisfies EPCS.
- **Protect the audit trail.** Confirm auditing is enabled, attributed correctly, and retained per policy. Establish authorized, read-only review access before EPCS go-live.

## Operations and monitoring

- **Report coverage continuously.** Run `IMPRIVATA-Report.ps1` after each wave and on a schedule to track agent install state and group coverage; investigate any endpoint that drifts out of compliance.
- **Validate, don't assume, after changes.** Re-run the relevant `05-testing.md` checks (especially T2 reader, T4 tap, T6 SSO, T7 EPCS) after agent upgrades, OS updates, or policy changes.
- **Keep a rehearsed rollback.** Maintain and periodically rehearse the back-out (uninstall assignment, profile removal, group removal, policy revert) so a sign-on regression on a shared clinical endpoint can be reversed quickly.

## Data handling

- **No PHI in artifacts.** Keep reports, logs, and screenshots free of PHI. Use test accounts and test data for all validation, and never sign a real controlled-substance order during testing.


---


# 8. Deliverables Summary — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

This solution delivers a complete, productized package: implementation documentation, runnable PowerShell tooling, and a hero image. Everything follows the standard deployment model — Intune-delivered agent and reader drivers, a named Entra device group, configuration profiles, and identity integration — with appliance-side policy and EPCS/DEA specifics deferred to your Imprivata administrator and compliance team.

## Documentation

| Document | Purpose |
|----------|---------|
| `01-solution-overview.md` | What the solution delivers, the problem it solves, scope/boundaries, and the phase model. |
| `02-requirements.md` | Solution-specific requirements R1–R10 (OneSign licensing/appliance, Confirm ID for EPCS, readers/drivers, Intune, identity, OS, shared-device model, EPCS proofing/two-factor, audit, compliance sign-off), each with Verify / Implement-if-missing. |
| `global-requirements-healthcare-solutions.md` | Category-wide prerequisites G1–G7 (tenant/roles, Windows/Intune licensing, HIPAA/HITRUST + change control, maintenance windows, network reachability, test device, rollback). |
| `03-implementation.md` | The build, Assess → Expand, with full navigation paths and named objects. |
| `05-testing.md` | Test plan T1–T9 with PASS/FAIL and the acceptance gate. |
| `06-troubleshooting.md` | Symptom-driven fixes for reader, badge, tap speed, Epic SSO, fast user switching, EPCS two-factor, and audit issues. |
| `07-best-practices.md` | Identity, deployment, shared-device, EPCS/compliance, operations, and data-handling guidance. |
| `executive-summary.md` | Business-level summary for decision-makers. |
| `08-deliverables-summary.md` | This document. |

## PowerShell scripts (5)

All scripts are read-only by default and intended to be run by an Intune administrator with appropriate Microsoft Graph permissions. Each has a `.SYNOPSIS` plus PURPOSE / HOW TO RUN / EXPECTED RESULTS header and a neutral `.NOTES` line.

| Script | Purpose |
|--------|---------|
| `IMPRIVATA-Discovery.ps1` | Tenant readiness: confirms the named agent app and reader-driver app exist and are assigned, the `IMPRIVATA – Clinical Endpoints` group exists, and target devices are present. Read-only. |
| `IMPRIVATA-Validation.ps1` | Per-device validation: agent installed, reader driver installed, device in group — outputs PASS/FAIL. |
| `IMPRIVATA-Report.ps1` | Fleet report: agent install state and device-group coverage, exported to CSV. |
| `IMPRIVATA-Remediation.ps1` | Safe re-deploy of the named agent/driver app to a device; runs in `-WhatIf`/read-only by default, acts only with `-Apply`. |
| `IMPRIVATA-Set-ClinicalGroup.ps1` | Creates the `IMPRIVATA – Clinical Endpoints` group and optionally assigns the named apps/profiles; supports `-WhatIf`. |

## Hero image

| Asset | Purpose |
|-------|---------|
| `IMPRIVATA-hero.png` | Listing hero image for the solution. |

## Named objects produced by the solution

These objects are created during implementation and reused verbatim across the docs and scripts:

- Win32 app: `Imprivata Agent – Clinical Endpoints – Deploy` (publisher `Imprivata, Inc.`)
- Win32 app: `Proximity Reader Driver – Clinical Endpoints – Deploy` (publisher = reader hardware vendor)
- Entra device group: `IMPRIVATA – Clinical Endpoints` (pilot subset `IMPRIVATA – Clinical Endpoints – Pilot`)
- Device configuration profile: `Imprivata Endpoint – Clinical Endpoints – Baseline`

## Outcome

A repeatable, validated deployment of Imprivata OneSign tap-and-go badge SSO, fast user switching, Epic/clinical-web SSO, and Confirm ID EPCS two-factor signing across shared clinical endpoints — delivered and monitored through Microsoft Intune, with a clear acceptance gate, rollback, and ongoing reporting.
