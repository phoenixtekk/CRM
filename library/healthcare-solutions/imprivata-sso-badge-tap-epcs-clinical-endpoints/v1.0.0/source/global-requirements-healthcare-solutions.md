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
