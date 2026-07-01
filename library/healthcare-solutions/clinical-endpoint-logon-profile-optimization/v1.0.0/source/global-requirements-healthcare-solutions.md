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

- **Description:** Target endpoints are covered by the appropriate **Windows** and **Microsoft Intune** licensing for management and Win32/settings-catalog delivery (and, where GPO is the plane, are domain-joined and managed).
- **Why:** Configuration delivery, profiles, and compliance reporting require the endpoints and users to be correctly licensed and enrolled/managed.
- **Verify:** Confirm licensing assignment in the admin center; confirm a representative endpoint is enrolled/managed and compliant in `Devices > All devices` (Intune) or domain-joined and in the target OU (GPO).
- **Implement if missing:** Assign the required licenses and complete enrollment/domain-join before deploying any payload.

## G3 — HIPAA/HITRUST data-handling and change control

- **Description:** The work follows the organization's **HIPAA/HITRUST data-handling and change-control** processes: a recorded change request, an approval, a defined back-out, and no PHI handled outside approved systems.
- **Why:** Clinical-endpoint, profile-storage, and identity changes affect access to PHI; governance is mandatory and auditable.
- **Verify:** Confirm an approved change record exists for this work and that data-handling rules (no PHI in screenshots, logs, or exports) are understood by the implementer.
- **Implement if missing:** Open and obtain approval for a change record before making changes. Ensure all artifacts (reports, logs) are scrubbed of PHI.

## G4 — Clinical maintenance windows

- **Description:** Changes that affect clinician sign-on or device behavior are scheduled within an **approved clinical maintenance window** that avoids disrupting patient care.
- **Why:** Sign-on, profile, and session changes on shared clinical endpoints can interrupt active care if applied during peak clinical hours.
- **Verify:** Confirm the maintenance window with clinical operations and that the targeted wards / host pools are aware.
- **Implement if missing:** Schedule the window with clinical operations; stage deployments (pilot first) so changes land in the agreed window.

## G5 — Network reachability to Microsoft and the profile storage

- **Description:** Endpoints can reach the required **Microsoft (Intune/Entra)** management endpoints **and** the **profile storage** (the SMB file server or Azure Files share over SMB/TCP 445, plus Kerberos/DC reachability for authentication), including any required proxy/firewall allowances.
- **Why:** Each component fails silently or partially if a required network path is blocked — Intune/GPO can't deliver, or the FSLogix agent can't reach the profile share to attach the container.
- **Verify:** From a representative endpoint, confirm reachability to the Microsoft management endpoints, to the profile share over SMB (TCP 445), and to a domain controller / Entra Kerberos for authentication. **Do not invent hosts/ports** — obtain the share path and storage host from the storage team.
- **Implement if missing:** Work with networking to allow the required paths through proxy/firewall (notably SMB/445 to the profile storage and Kerberos to the directory). Re-test reachability before deployment.

## G6 — Test device

- **Description:** A **representative test endpoint** (same make/model and OS build as production clinical endpoints, or a representative AVD session host) is available for piloting before fleet rollout.
- **Why:** Logon behavior, agent install, and container attach depend on hardware, build, and storage-path specifics; validating on a representative device prevents fleet-wide surprises.
- **Verify:** Confirm a test device exists that matches the production hardware/OS (or AVD host image) and is managed by the chosen plane.
- **Implement if missing:** Designate and enroll/join a representative test device before starting deployment.

## G7 — Rollback / back-out plan

- **Description:** A documented **rollback** exists: how to remove or disable the FSLogix agent and configuration and restore the prior profile/sign-on behavior on an endpoint or group.
- **Why:** If the deployment causes sign-on or profile failures on shared clinical endpoints, a fast, rehearsed back-out is required to protect patient care.
- **Verify:** Confirm the rollback steps are written (uninstall via the Intune app's **Uninstall** assignment or remove the config policy / GPO link, disable Profile Container, remove devices from the group) and that an owner is named.
- **Implement if missing:** Author the rollback steps as part of change control, including how to revert each named object created in `03-implementation.md`, and rehearse on the test device.

---

## Global requirements summary

| # | Requirement | Verify location | Gate |
|---|-------------|-----------------|------|
| G1 | Tenant + least-privilege roles | Entra / Intune admin centers | Assess |
| G2 | Windows + Intune licensing / management | Admin center / Devices | Configure FSLogix |
| G3 | HIPAA/HITRUST + change control | Change record | Assess |
| G4 | Clinical maintenance windows | Clinical operations | Pilot |
| G5 | Network to Microsoft + profile storage | On-endpoint reachability test | Configure FSLogix |
| G6 | Representative test device | Devices > All devices | Pilot |
| G7 | Rollback / back-out plan | Change record | All phases |
