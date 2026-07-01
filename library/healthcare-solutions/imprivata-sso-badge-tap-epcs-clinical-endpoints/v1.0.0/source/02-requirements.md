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
