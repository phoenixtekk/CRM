# Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

> **Version 1.0.0** · Category: Healthcare Solutions · Solution code: CLINLOGON

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

## The challenge

On shared clinical endpoints — Workstations-On-Wheels, exam-room PCs, and nursing-station kiosks — and on virtual desktops, clinicians lose time at every sign-in. The default Windows profile model builds a full local profile on first use of each device, or copies a roaming profile over the network on every login, so clinicians routinely wait 60–120+ seconds at the worst possible moment in care. The same model produces temporary-profile errors, profile corruption, and settings that differ device-to-device — friction that drives the unsafe workarounds (generic shared logins, never signing out) the organization is trying to eliminate. On a busy ward, seconds-per-login multiplied across thousands of daily sign-ins is a measurable drain on clinical time.

## The solution

This solution deploys and configures **FSLogix profile containers** — the Microsoft-standard mechanism for roaming profiles on shared and virtual Windows — and applies **fast-logon tuning** so clinicians sign in measurably faster with one profile that follows them everywhere. Each clinician's profile lives in a per-user **VHD(X) container** on an SMB or **Azure Files** profile share; the container is **attached** at sign-in (mounted, not copied), so logon time drops sharply and stays consistent across every shared endpoint and **Azure Virtual Desktop** host. **Redirections and exclusions** keep volatile caches out of the container to control bloat and corruption, and fast-logon settings (deleting stale cached profiles, trimming sign-in work) shave off additional seconds. The FSLogix agent and configuration are delivered through **Microsoft Intune** (or Group Policy) using named, reusable objects.

The work follows a disciplined phase model — **Assess (baseline logon) → Configure FSLogix → Tune fast logon → Pilot → Validate (measure) → Expand** — anchored by a **measured baseline** so the improvement is proven, not assumed, and gated by a defined acceptance test before fleet rollout.

## Business outcomes

- **Faster, consistent clinician sign-in.** Attaching a profile container instead of copying it cuts logon time against a measured baseline and keeps it consistent across every shared device and virtual desktop.
- **One roaming profile that follows the clinician.** A single container per clinician means the same desktop, settings, and Office/EHR state on every WOW, exam-room PC, and AVD host — no more device-to-device inconsistency.
- **Fewer profile failures.** Attaching a container avoids the temporary-profile, corruption, and merge-conflict failures of roaming/mandatory profiles, and exclusions keep containers small and stable.
- **Proven, monitored delivery.** Intune (or GPO) installs, targets, and reports on the agent and configuration; the deployment ships with a measured before/after and continuous coverage reporting, expanding in controlled waves.

## Scope and governance

The solution covers the **FSLogix deployment, endpoint/AVD configuration, fast-logon tuning, profile-share requirements, and measured validation**. Storage-platform values (share path, storage account, tier, quota, backup), FSLogix/Windows licensing entitlement, and Imprivata appliance policy are intentionally **not invented here** — they are governed by the organization's **storage/infrastructure team**, **licensing owner**, and **Imprivata administrator** (a separate solution), and the documentation directs the reader to those owners at every decision point. The deployment is gated by HIPAA/HITRUST change control, clinical maintenance windows, a measured baseline, a validated test plan, and documented change/compliance sign-off.

## What you receive

A complete, productized package: nine implementation documents, five runnable PowerShell scripts (inventory/discovery, per-device validation, fleet logon-time-and-size reporting, safe remediation, and baseline capture), and a listing hero image — everything needed to baseline, deploy, prove, and expand FSLogix logon and profile optimization across shared clinical endpoints and AVD with confidence.


---


# 1. Solution Overview — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

## What this solution delivers

This solution cuts sign-in times and stabilizes user sessions on **shared clinical Windows endpoints** — Workstations-On-Wheels (WOWs), exam-room PCs, nursing-station kiosks — and on **Azure Virtual Desktop (AVD) session hosts** where applicable, by deploying and configuring **FSLogix profile containers** and applying **fast-logon tuning**. A clinician's Windows profile is moved out of the slow, locally-cached, copy-on-every-login model and into a **per-user VHD(X) profile container** stored on an SMB / Azure Files share; the container is **attached** at sign-in (mounted, not copied), so the profile loads in a fraction of the time and roams cleanly across every shared endpoint the clinician touches. The **FSLogix agent**, the FSLogix configuration, the profile share definition, redirections/exclusions, and the fast-logon settings are delivered to the endpoints with **Microsoft Intune** (or **Group Policy** where that is the management plane) using named, reusable objects.

The result is the experience clinical staff actually want on a shared device: walk up, sign in, and be working in seconds — with the same desktop, settings, and Office state on every WOW and exam-room PC — instead of waiting through a long first-time profile build, a temporary-profile error, or a bloated roaming-profile copy. FSLogix is the Microsoft-standard mechanism for roaming user profiles on shared and virtualized Windows; this solution applies it correctly for the clinical shared-endpoint and AVD case and **quantifies the before/after** (logon seconds, profile load time, container size).

## What problem it solves

On shared clinical endpoints, the default Windows profile model is the bottleneck. The first time a clinician signs in to a given device, Windows builds a full local profile; on roaming-profile setups the whole profile is copied over the network on every login and copied back on logout. Either way clinicians wait — often 60–120+ seconds — at the worst possible time (mid-round, mid-triage). Worse, the model produces temporary-profile errors, profile corruption, and inconsistent settings device-to-device, which drives the same unsafe workarounds (generic shared logins, never-signing-out) that the organization is trying to eliminate. This solution closes the gap:

- **Fast, consistent sign-in on shared devices** — the profile container is **attached** at logon rather than copied, so logon time drops sharply and is consistent across every endpoint.
- **A single roaming profile that follows the clinician** — one VHD(X) per user on the profile share means the same desktop, settings, and (optionally) Office/Outlook cache and search index on every shared endpoint and AVD host.
- **Stability over the copy-profile failure modes** — attaching a container avoids the temporary-profile and merge-conflict failures of mandatory/roaming profiles, and **redirections.xml exclusions** keep volatile/cache data out of the container to control bloat and corruption.
- **Fast-logon tuning on top of FSLogix** — deleting stale locally-cached profiles, trimming what runs at sign-in, and the supporting GPO/Intune settings shave additional seconds off the clinician's wait.
- **Measured, repeatable delivery** — Intune (or GPO) delivers the agent and configuration to a named device group, and the deployment is gated by a **measured baseline** so the improvement is provable, not assumed.

## Scope and boundaries

**In scope (this document):**
- Deployment of the **FSLogix agent** and FSLogix configuration to the clinical endpoints / AVD hosts via Intune (settings catalog / Win32) or Group Policy.
- Configuration of the **FSLogix Profile Container** (and, where in scope, the **Office Container**) to the named profile share, with VHD(X) sizing, container-naming, and locked-VHD/concurrent-session behavior appropriate to shared devices.
- **Profile storage** on an SMB file server or **Azure Files** share, including the share/NTFS (or Azure Files Kerberos + share) **permissions** FSLogix requires.
- **redirections.xml exclusions** and recommended FSLogix exclusion settings to control container bloat and protect against corruption.
- **Fast-logon tuning**: delete-cached-profiles behavior, sign-in optimizations, roaming-vs-local decisions, and the supporting GPO/Intune settings.
- The documented **interplay with Imprivata tap-and-go fast user switching** so FSLogix container attach/detach behaves correctly under rapid badge-driven session changes.
- Baseline measurement, pilot, validation (measure before/after), and fleet expansion, with named objects and full navigation paths.

**Out of scope / owned elsewhere — do not invent these values:**
- **The clinical applications' own profile/cache requirements** (e.g., the EHR client's local cache location and size) beyond pointing them into or out of the container correctly — confirm app-specific behavior with the application owner.
- **Imprivata appliance / OneSign computer-policy values** (tap-out lock vs. log-off behavior, session timing). These are governed by your **Imprivata administrator** and are the subject of a separate Imprivata solution. This document documents the *FSLogix-side* settings that make tap-and-go and FSLogix coexist; it does not set Imprivata policy.
- **The storage platform's own provisioning specifics** (Azure Files tier/quota/region, file-server hardware/sizing SKUs, backup/snapshot schedules). These are governed by your **storage / infrastructure team**; this document states the *requirements FSLogix imposes* on that storage and directs you to that owner for the platform values.
- **Directory and licensing entitlement** for FSLogix and Windows (see `02-requirements.md` R1) — governed by your licensing owner.

Throughout, named objects (the FSLogix config profile, the profile share, the device group, the GPO/Intune settings policy) follow the `<Purpose> – <Scope> – <Stage>` convention and are reused verbatim in later documents so the build is traceable end to end.

## Phase model

The solution follows a six-phase model, used consistently across the requirements, implementation, and testing documents:

1. **Assess (baseline logon)** — confirm prerequisites and **measure the current logon time and profile load time** on representative endpoints so the improvement is quantifiable.
2. **Configure FSLogix** — deploy the FSLogix agent and configure the Profile (and Office) Container to the named profile share, with sizing, redirections, and recommended exclusions.
3. **Tune fast logon** — apply delete-cached-profiles, sign-in optimizations, and the supporting GPO/Intune settings; reconcile FSLogix with Imprivata tap-and-go behavior.
4. **Pilot** — run a small, representative ward / set of endpoints (or AVD host pool subset) end to end.
5. **Validate (measure)** — re-measure logon and profile load against the baseline, confirm the target reduction is met, and confirm stability and fast-user-switch behavior.
6. **Expand** — roll out to the remaining clinical endpoints / AVD hosts in controlled waves.

## Audience

This solution is written for the IT team that owns endpoint and/or AVD management (Intune administrators and/or AVD/VDI engineers), in partnership with the **storage / infrastructure team** (the profile share and its permissions), the **identity team** (the directory FSLogix uses), and — where the endpoints also run Imprivata — the **Imprivata administrator** (tap-and-go interplay). Steps are written so a competent Intune/GPO administrator can execute them without prior FSLogix experience, deferring storage-platform, regulatory, and Imprivata-policy values to the named owners.

## Outcome

On completion, clinicians on the targeted shared endpoints (and AVD hosts) sign in measurably faster with a single roaming FSLogix profile that follows them across devices, sessions are stable and free of temporary-profile and corruption failures, container bloat is controlled by exclusions, and the deployment is delivered and monitored through Intune (or GPO) with a **measured before/after** that proves the logon-time reduction and a documented path to expand across the fleet.


---


# 2. Requirements — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

These are the solution-specific requirements. The category-wide prerequisites shared by every Healthcare Solution (tenant and roles, Windows licensing, HIPAA/HITRUST data-handling and change control, clinical maintenance windows, network reachability, a test device, and rollback) are documented separately in `global-requirements-healthcare-solutions.md` and must also be satisfied. **Never assume a prerequisite is already in place** — for each requirement below, confirm it explicitly using the **Verify** action, and follow **Implement if missing** when it is not.

Each requirement is stated as: **Description / Why / Verify / Implement if missing.**

---

## R1 — FSLogix licensing / entitlement

- **Description:** The organization is **entitled to use FSLogix**. FSLogix is included with several licenses (e.g., Microsoft 365 / Windows Enterprise per-user, Windows Enterprise E3/E5, Windows Education A3/A5, RDS CALs, and AVD entitlement) — at least one qualifying entitlement covers the target users/endpoints.
- **Why:** FSLogix is licensed via an underlying Microsoft entitlement, not sold standalone. Deploying it without a qualifying license is a compliance gap, even though the agent installs and runs.
- **Verify:** Confirm with your licensing owner which qualifying entitlement covers the target users/devices (M365/Windows Enterprise, RDS CAL, or AVD). Record the entitlement used.
- **Implement if missing:** Acquire or assign a qualifying entitlement before deployment. Do not proceed to agent deployment until the entitlement is confirmed and recorded.

## R2 — An SMB / Azure Files profile share with correct permissions

- **Description:** A highly-available **SMB file share** (on a Windows file server / cluster) or an **Azure Files share** exists to hold the FSLogix profile containers, with the **permissions FSLogix requires**: the file-server/Azure Files **share-level** permission allowing the profile users (and computers, for AVD/computer-context) to access the share, **plus** the **NTFS / directory ACLs** on the share following the FSLogix-recommended model — *Users: Create folder/append data, List, Read (this folder only); Creator Owner: Modify (subfolders and files only)* — so each user can create and own only their own container folder. For Azure Files, this means **identity-based authentication (Kerberos)** for NTFS ACLs **and** the share-level RBAC role (e.g., *Storage File Data SMB Share Contributor*) assigned to the profile users/group.
- **Why:** FSLogix attaches a per-user VHD(X) over SMB; if share/NTFS permissions are wrong the container fails to create or attach (the classic cause of "you've been signed in with a temporary profile"). Both the **share-level** and the **NTFS/Kerberos** layers must be correct — getting only one right still fails.
- **Verify:** Confirm the share exists and is reachable over SMB (port 445) from a representative endpoint. With your storage team, confirm both the share-level permission and the NTFS/directory ACLs match the FSLogix model above (for Azure Files: confirm Kerberos identity-based auth is enabled and the share-level RBAC role is assigned). **Do not invent the share path, storage account, or quota — obtain them from the storage team.**
- **Implement if missing:** With the storage / infrastructure team, provision the share, enable identity-based Kerberos authentication (Azure Files) or domain access (file server), and apply both permission layers per the FSLogix model. Size/quota is a storage-team value — confirm it against R7. Re-test SMB reachability and a test container create before proceeding.

## R3 — Intune or Group Policy management plane

- **Description:** The target endpoints are managed by **Microsoft Intune** (settings catalog / Win32 app delivery) **or** by **Group Policy** (domain-joined, with the FSLogix ADMX templates installed in the Central Store), and you have confirmed which plane delivers the FSLogix agent and configuration.
- **Why:** The FSLogix agent and its registry-based configuration (Profile Container settings, redirections, fast-logon settings) are delivered by one of these planes; mixing them inconsistently produces conflicting settings.
- **Verify:** Determine the management plane for the target endpoints. For Intune: in the **Microsoft Intune admin center** (`Devices > All devices`) confirm a representative endpoint is managed and compliant. For GPO: confirm the FSLogix **ADMX/ADML** templates are in the domain Central Store (`\\<domain>\SYSVOL\<domain>\Policies\PolicyDefinitions`) and you can edit a GPO linked to the target OU.
- **Implement if missing:** Stand up the chosen plane: enroll endpoints in Intune, **or** install the FSLogix ADMX templates into the Central Store and create/link the GPO. Pick **one** authoritative plane per setting to avoid conflicts; record the choice.

## R4 — Supported Windows 10/11 or AVD session hosts

- **Description:** Target endpoints run a **supported Windows 10/11 edition and build**, or are **AVD session hosts** (including multi-session Windows Enterprise multi-session) on a supported build, compatible with the FSLogix agent version you will deploy.
- **Why:** FSLogix and the fast-logon settings require a supported OS; multi-session AVD hosts and single-session shared endpoints have different concurrency considerations the configuration must reflect.
- **Verify:** In `Devices > All devices` (Intune) or via inventory, review the OS edition/build of representative endpoints and AVD hosts. Confirm the build is supported by the FSLogix agent version (use the current FSLogix release).
- **Implement if missing:** Update endpoints/hosts to a supported build via your standard update process within a clinical maintenance window before deploying the agent.

## R5 — The FSLogix agent

- **Description:** The **FSLogix agent** installer (current release from the Microsoft FSLogix download) is available to package/deploy, and you have the install/uninstall and detection details for the chosen management plane.
- **Why:** The agent provides the profile-container filter driver that attaches the VHD(X) at sign-in; nothing works without it on each endpoint/host.
- **Verify:** Confirm you have the current FSLogix agent installer (`FSLogixAppsSetup.exe`) and have recorded its version, silent install/uninstall command lines, and a detection method (installed file/version or the `FSLogix Apps` registry/uninstall key).
- **Implement if missing:** Download the current FSLogix agent, record the version and command lines, and prepare it for Intune (Win32 / packaged) or for software-install via GPO/your standard mechanism. Do not invent installer switches — use the documented silent switches.

## R6 — A baseline logon measurement

- **Description:** A **measured baseline** of current logon time and profile load time exists for representative endpoints **before** any FSLogix/fast-logon change, captured with a repeatable method and recorded in change control.
- **Why:** The entire solution is judged on a quantified before/after. Without a baseline there is no way to prove (or size) the improvement, and the acceptance gate in `05-testing.md` cannot be met.
- **Verify:** Confirm a baseline has been captured (sign-in start to usable-desktop seconds, and profile load time) for representative shared endpoints / AVD hosts, using the method that `CLINLOGON-Set-FSLogixBaseline.ps1` automates (e.g., Group Policy / Profile Service operational-log timings and the User Profile Service events).
- **Implement if missing:** Capture the baseline first — run `CLINLOGON-Set-FSLogixBaseline.ps1` (see `08-deliverables-summary.md`) on representative endpoints and record the results. Set the **target reduction** (e.g., a specific percentage or seconds) with the stakeholders before configuring FSLogix.

## R7 — Profile-storage sizing and growth control

- **Description:** The profile share is **sized** for the expected number of concurrent containers and per-container size, and a **container-size/growth-control** approach is agreed (per-container VHD(X) max size, dynamic vs. fixed disk, and the exclusion strategy that keeps volatile/cache data out of the container).
- **Why:** Containers grow over time; uncontrolled growth fills the share, slows attach, and risks corruption. Sizing and exclusions are a prerequisite decision, not an afterthought.
- **Verify:** With the storage team, confirm the share quota/capacity and the agreed **per-container maximum size** and **disk type** (dynamic recommended for shared clinical fleets). Confirm the **redirections.xml exclusion list** is agreed (caches, temp, indexable content not needed in the roaming profile). **Defer the storage quota/capacity numbers to the storage team — do not invent them.**
- **Implement if missing:** Agree the per-container size and disk type and the redirections/exclusion list with the storage team and application owners before configuring FSLogix (these become settings in `03-implementation.md`). Plan periodic container size review.

## R8 — Directory identity for profile users

- **Description:** Clinicians have valid identities in the directory the endpoints use (**Active Directory** for domain-joined / file-server shares; **Microsoft Entra ID** with Entra Kerberos for Azure Files; or hybrid), and the **profile-share permissions in R2 grant those identities** access.
- **Why:** FSLogix attaches each container under the signed-in user's identity over Kerberos; the user must exist in the directory the share trusts and be granted by the share/NTFS permissions, or the container won't attach.
- **Verify:** Confirm representative clinician accounts exist and are enabled in the directory the share authenticates against, and that they are members of the group granted in R2. For Azure Files, confirm Entra Kerberos (or AD DS Kerberos) authentication is configured for the storage account.
- **Implement if missing:** Reconcile the directory and the share-permission group so every profile user is present and granted. Configure the required Kerberos authentication for Azure Files with the identity/storage teams.

## R9 — Imprivata tap-and-go interplay (where applicable)

- **Description:** On endpoints that **also** run **Imprivata** tap-and-go / fast user switching, the interaction between rapid badge-driven session changes and FSLogix container **attach/detach** has been reviewed so a container detaches cleanly on tap-out and attaches cleanly on the next tap-in (no orphaned/locked VHD(X)).
- **Why:** Tap-and-go drives frequent, fast sign-in/sign-out. If FSLogix doesn't detach the prior user's container before the next attaches, you get locked-VHD or temporary-profile failures — a coexistence issue, not a fault of either product alone.
- **Verify:** Identify which target endpoints run Imprivata. With your **Imprivata administrator**, confirm the tap-out behavior (lock vs. log-off) and confirm whether sessions are fully signed out (which detaches the container) or only locked. **Defer Imprivata appliance/computer-policy values to the Imprivata admin — they are owned by a separate solution.**
- **Implement if missing:** Where Imprivata is present, agree with the Imprivata admin a session model where the container reliably detaches between users (typically a full sign-out on tap-out for shared single-session devices), and validate it in `05-testing.md` (T7). Document the agreed behavior.

## R10 — Change control and compliance sign-off

- **Description:** Documented **change control** and **compliance sign-off** authorizing the profile-storage and sign-on changes on the targeted clinical endpoints, before production use.
- **Why:** The solution changes where clinician profiles (which may contain configuration touching PHI workflows) are stored and how sessions sign in — a governed change in a HIPAA/HITRUST environment.
- **Verify:** Confirm an approved change record exists (per `global-requirements-healthcare-solutions.md`) and that compliance/security has signed off on storing profile containers on the named share and on the sign-on behavior changes.
- **Implement if missing:** Open and obtain approval for the change record and compliance sign-off before fleet expansion. Pilot only under the approved change window.

---

## Requirements summary

| # | Requirement | Owner to confirm with | Gate |
|---|-------------|----------------------|------|
| R1 | FSLogix licensing / entitlement | Licensing owner | Configure FSLogix |
| R2 | SMB/Azure Files profile share + permissions | Storage / infrastructure team | Configure FSLogix |
| R3 | Intune or GPO management plane | Intune / AD admin | Configure FSLogix |
| R4 | Supported Win10/11 or AVD hosts | Intune / AVD engineer | Configure FSLogix |
| R5 | FSLogix agent | Intune / endpoint admin | Configure FSLogix |
| R6 | Baseline logon measurement | Endpoint admin + stakeholders | Assess |
| R7 | Storage sizing + growth control | Storage team + app owners | Configure FSLogix |
| R8 | Directory identity for profile users | Identity team | Configure FSLogix |
| R9 | Imprivata tap-and-go interplay | Imprivata administrator | Tune fast logon |
| R10 | Change control + compliance sign-off | Compliance / security | Pilot → Expand |


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


---


# 3. Implementation — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

This document is the build. It follows the phase model **Assess (baseline logon) → Configure FSLogix → Tune fast logon → Pilot → Validate (measure) → Expand**, using **full navigation paths** and **named objects**. Every object you create is named with the `<Purpose> – <Scope> – <Stage>` convention and is reused verbatim in `05-testing.md`, `06-troubleshooting.md`, and the scripts. Storage-platform values (share path, storage account, quota), licensing, and Imprivata policy are obtained from their respective owners — this document does not invent them.

The steps are written for the **Microsoft Intune** management plane (settings catalog). Where your plane is **Group Policy**, the equivalent settings are configured in the FSLogix ADMX-backed GPO named identically (see the GPO note in each step); the setting names and values are the same.

### Objects you will create (named, reused verbatim)

| Object type | Name |
|-------------|------|
| Win32 app (FSLogix agent) | `FSLogix Agent – Clinical Endpoints – Deploy` |
| Entra device group | `Clinical – Logon Optimization` |
| Entra device group (pilot subset) | `Clinical – Logon Optimization – Pilot` |
| Settings catalog profile (FSLogix) | `FSLogix Profile – Clinical Endpoints – Container` |
| Settings catalog profile (fast logon) | `Fast Logon – Clinical Endpoints – Tuning` |
| Profile share (logical name; path from storage team) | `Clinical Profiles – FSLogix – Share` |
| GPO (only if GPO is the plane) | `Clinical – Logon Optimization – FSLogix GPO` |

> The profile share `Clinical Profiles – FSLogix – Share` is a **logical name** for the share that holds the containers; its **physical UNC path / Azure Files endpoint is supplied by your storage team** (R2). Use that path everywhere a share path is required below; never invent it.

---

## Phase 1 — Assess (baseline logon)

1. Open the **Microsoft Intune admin center** at `https://intune.microsoft.com`.
2. Navigate to `Devices > All devices` and confirm the target clinical endpoints (and the test device from global requirement G6) appear as **managed** and **compliant**. For AVD, confirm the session-host pool is managed by your chosen plane.
3. Confirm every requirement in `02-requirements.md` (R1–R10) and `global-requirements-healthcare-solutions.md` (G1–G7) is satisfied. Do not start configuring FSLogix until R1 (licensing), R2 (share + permissions), R5 (agent), R6 (baseline), R7 (sizing/exclusions), and R8 (identity) are confirmed.
4. **Capture the baseline.** On each representative endpoint (and the test device), run `CLINLOGON-Set-FSLogixBaseline.ps1` to record the current logon time and profile load time, **before** any change. Record the results and agree the **target reduction** (e.g., "reduce usable-desktop logon from baseline by ≥ 50%, to under N seconds") with stakeholders. This target is the acceptance criterion in `05-testing.md`.
5. From your storage team, obtain the **profile share UNC path / Azure Files endpoint** for `Clinical Profiles – FSLogix – Share`, and the **agreed per-container max size, disk type, and redirections/exclusion list** (R7). From your endpoint team, obtain the FSLogix agent installer, version, silent install/uninstall command lines, and detection method (R5). Record all of these — they are inputs below.

## Phase 2 — Configure FSLogix

### Step 1 — Create the clinical device group

1. In the Intune admin center, navigate to `Groups > All groups > New group`.
2. Set **Group type** = `Security`.
3. Set **Group name** = `Clinical – Logon Optimization`.
4. Set **Membership type** = `Assigned` (or `Dynamic Device` with a rule matching your clinical endpoints' naming/category, if you maintain one — record the rule).
5. For an assigned group, choose **Members > Add members** and add the shared clinical endpoints / AVD hosts (and the test device).
6. Select **Create**.
7. Repeat steps 1–6 to create a pilot subset group named `Clinical – Logon Optimization – Pilot` containing only the pilot ward's endpoints (or an AVD host-pool subset) and the test device.

> **GPO plane:** instead of groups, create/link the GPO `Clinical – Logon Optimization – FSLogix GPO` to the OU containing the clinical endpoints, and use a pilot OU/security-group filter for the pilot subset.

### Step 2 — Package the FSLogix agent as a Win32 app

1. Obtain the FSLogix agent installer (`FSLogixAppsSetup.exe`, current release) per R5 and the **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`).
2. Wrap the installer into an `.intunewin` package per the standard Win32 packaging process (source folder, setup file, output folder).

> **GPO plane:** deploy the agent via your standard software-install mechanism (the FSLogix agent supports silent install); the configuration in Step 4–5 is then delivered by the GPO rather than a settings-catalog profile.

### Step 3 — Create the FSLogix agent Win32 app in Intune

1. Navigate to `Apps > All apps > Add`.
2. Set **App type** = `Windows app (Win32)` and select **Select**.
3. On **App information**: upload the `.intunewin` from Step 2. Set **Name** = `FSLogix Agent – Clinical Endpoints – Deploy`. Set **Publisher** = `Microsoft Corporation`. Add a description and the FSLogix version you recorded.
4. On **Program**:
   - **Install command** = the FSLogix silent install command line (e.g., `FSLogixAppsSetup.exe /install /quiet /norestart`).
   - **Uninstall command** = the FSLogix silent uninstall command line (e.g., `FSLogixAppsSetup.exe /uninstall /quiet /norestart`).
   - **Install behavior** = `System`.
5. On **Requirements**: set **Operating system architecture** = `64-bit` and **Minimum operating system** to the supported value from R4.
6. On **Detection rules**: choose **Manually configure detection rules > Add** and enter the detection criteria — the installed agent file/version (e.g., `frxsvc.exe` under the FSLogix Apps install path) or the `FSLogix Apps` uninstall registry key. Do not guess the path; confirm from the installed agent.
7. On **Dependencies** and **Supersedence**: leave unless you maintain a prior FSLogix app to supersede.
8. On **Assignments**: under **Required**, select **Add group** and add `Clinical – Logon Optimization – Pilot` for the pilot. (You will add the full `Clinical – Logon Optimization` group in the Expand phase.)
9. Select **Next > Create**.

### Step 4 — Create the FSLogix Profile Container settings profile

1. Navigate to `Devices > Configuration > Create > New Policy`.
2. Set **Platform** = `Windows 10 and later` and **Profile type** = `Settings catalog`. Select **Create**.
3. On **Basics**: set **Name** = `FSLogix Profile – Clinical Endpoints – Container`. Add a description.
4. On **Configuration settings**, select **Add settings**, search the settings picker for **FSLogix > Profile Containers**, and configure (these map to the `HKLM\SOFTWARE\FSLogix\Profiles` registry values FSLogix reads):
   - **Enabled** = `1` (enable Profile Container).
   - **VHD Locations** = the profile share path for `Clinical Profiles – FSLogix – Share` supplied by your storage team (the UNC path / Azure Files endpoint). Do not invent it.
   - **Volume Type** = `VHDX`.
   - **Size In MBs** = the agreed per-container maximum from R7 (a storage-team value; do not invent).
   - **Is Dynamic** = `1` (dynamic disk) for shared clinical fleets unless the storage team specifies fixed.
   - **Flip Flop Profile Directory Name** = `1` so the per-user folder is named `%username%_%sid%` (easier to find a user's container).
   - **Delete Local Profile When VHD Should Apply** = `1` so a stale local profile is removed when the container applies (prevents temp-profile fallback on shared devices). Confirm this is acceptable on shared devices (it is the recommended shared-device behavior).
   - **Locked Retry Count / Locked Retry Interval** = leave default unless tuning concurrency on tap-and-go endpoints (see Phase 3).
5. **Office Container (optional, where in scope):** if Outlook/OneDrive cache roaming is wanted (typically on AVD rather than fast-switching WOWs), add **FSLogix > Office Container (ODFC)** settings — **Enabled** = `1`, **VHD Locations** = the same or a dedicated ODFC share path, and the Office services to include (Outlook, Outlook Personalization, OneDrive, etc.) per the application owners. For high-churn tap-and-go WOWs, prefer leaving Office Container off and excluding caches via redirections (Step 6) to keep attach fast and containers small.
6. **Redirections / exclusions:** create a `redirections.xml` listing the per-user paths to **exclude** from the roaming profile (volatile caches, temp, browser caches, indexable content not needed across devices, and any app cache the app owner says should stay local), per the agreed list in R7. Place it on a share readable by the endpoints, then set the **Redirection XML Source Folder** value in this profile to that location. This is the primary lever for **container bloat control** and corruption avoidance — keep large/volatile data out of the VHD(X).
7. On **Assignments**: add `Clinical – Logon Optimization – Pilot` (add the full group in the Expand phase).
8. Select **Next > Create**.

> **GPO plane:** the same values live under `Computer Configuration > Policies > Administrative Templates > FSLogix > Profile Containers` (and `Office Container`) in `Clinical – Logon Optimization – FSLogix GPO`. The setting names and recommended values are identical.

### Step 5 — Confirm share permissions are in place for attach

1. Confirm with your storage team that `Clinical Profiles – FSLogix – Share` has both permission layers from R2: the **share-level** permission granting the profile users, and the **NTFS/directory ACLs** following the FSLogix model (*Users: Create folder / List / Read this-folder-only; Creator Owner: Modify subfolders/files*). For **Azure Files**, confirm Kerberos identity-based auth is enabled and the **Storage File Data SMB Share Contributor** role is assigned to the profile users/group.
2. On the test device, sign in as a test clinician and confirm a per-user container folder is **created** under the share and the VHD(X) **attaches** (no temporary-profile message). This proves R2/R8 before pilot.

## Phase 3 — Tune fast logon

### Step 1 — Create the fast-logon tuning settings profile

1. Navigate to `Devices > Configuration > Create > New Policy > Windows 10 and later > Settings catalog > Create`.
2. On **Basics**: set **Name** = `Fast Logon – Clinical Endpoints – Tuning`. Add a description.
3. On **Configuration settings**, add and configure:
   - **Delete cached copies of roaming profiles** (`Administrative Templates > System > User Profiles`) = `Enabled` so stale local cached profiles are removed at sign-out on shared devices, keeping each sign-in clean and the local disk lean. (This complements the FSLogix *Delete Local Profile When VHD Should Apply* in Phase 2.)
   - **Set maximum wait time for the network if a user has a roaming user profile or remote home directory** = a small bounded value so sign-in does not stall waiting on the network when the profile share is briefly slow.
   - **Do not forcefully unload the users registry at user logoff** = `Disabled` (allow the hive to unload cleanly so the container detaches) — important on tap-and-go endpoints.
   - Trim **sign-in cost**: disable First Logon Animation (`Administrative Templates > System > Logon > Show first sign-in animation` = `Disabled`), and review startup/run items so fewer things execute at sign-in. Disable Windows **Welcome/OOBE consumer experiences** that add sign-in cost on shared clinical devices.
   - **Roaming vs. local:** ensure no legacy **roaming user profile** path is set for these users (FSLogix replaces it). If a roaming-profile GPO/path is still configured, remove it for the clinical OU so the two models do not fight.
4. On **Assignments**: add `Clinical – Logon Optimization – Pilot`.
5. Select **Next > Create**.

### Step 2 — Reconcile FSLogix with Imprivata tap-and-go (where applicable, R9)

1. For endpoints that also run Imprivata, confirm with your **Imprivata administrator** whether tap-out performs a **full sign-out** (which detaches the FSLogix container) or only a **lock** (which does not). On shared single-session WOWs, a full sign-out on tap-out is the clean model so the next clinician's container attaches without a locked-VHD conflict.
2. Where rapid tap-in/tap-out causes occasional locked-VHD retries, tune the FSLogix **Locked Retry Count** / **Locked Retry Interval** (in `FSLogix Profile – Clinical Endpoints – Container`) up modestly with your Imprivata admin so a just-detaching container is given time to release before the next attach.
3. Record the agreed session model. Validate it in `05-testing.md` (T7). Do not change Imprivata appliance policy from here — escalate the tap-out behavior to the Imprivata admin (separate solution).

## Phase 4 — Pilot

1. With the pilot assignments in place (agent app, `FSLogix Profile – Clinical Endpoints – Container`, and `Fast Logon – Clinical Endpoints – Tuning` targeted to `Clinical – Logon Optimization – Pilot`), allow the pilot endpoints to receive the deployment within the approved maintenance window (G4).
2. On each pilot endpoint, confirm the agent app installs (`Apps > Monitor` shows **Installed**) and both configuration profiles show **Succeeded** in `Devices > Configuration`.
3. Have pilot clinicians sign in (and, where applicable, tap in) for real for an agreed pilot period; confirm a single roaming profile follows them across pilot endpoints and that Office/EHR state is consistent.
4. Re-measure logon and profile load on the pilot endpoints (Phase 5) and compare against the Phase 1 baseline.
5. Collect issues and tune the FSLogix settings, redirections/exclusions, and fast-logon settings as needed; watch container sizes against the R7 target.

## Phase 5 — Validate (measure)

1. Execute the full test plan in `05-testing.md` against the pilot endpoints, including the **before/after logon measurement** (T1) and profile-load, stability, and fast-user-switch checks.
2. Re-run `CLINLOGON-Set-FSLogixBaseline.ps1` (or `CLINLOGON-Report.ps1`) on the pilot endpoints to capture post-change logon/profile-load numbers and confirm the **target reduction agreed in Phase 1 is met**.
3. Confirm every test passes and the **acceptance gate** is met; obtain the compliance/change sign-off (R10).

## Phase 6 — Expand

1. In `Apps > All apps`, open `FSLogix Agent – Clinical Endpoints – Deploy`; on **Properties > Assignments**, add the full `Clinical – Logon Optimization` group under **Required**.
2. Open `Devices > Configuration > FSLogix Profile – Clinical Endpoints – Container > Properties > Assignments` and `Devices > Configuration > Fast Logon – Clinical Endpoints – Tuning > Properties > Assignments`, and add the full `Clinical – Logon Optimization` group to each.
3. Add the remaining shared clinical endpoints / AVD hosts to `Clinical – Logon Optimization` in controlled waves, each within an approved maintenance window. For AVD, expand across the host pool in waves so drain/restart is staged.
4. After each wave, run `CLINLOGON-Report.ps1` to confirm coverage, agent install state, and logon/profile-size figures, and re-run a sample of the acceptance checks.
5. Periodically review container sizes against the R7 target and prune the redirections/exclusion list as new caches are identified.

---

## Rollback (per global requirement G7)

To back out on an endpoint or group: set **Enabled = 0** in `FSLogix Profile – Clinical Endpoints – Container` (or remove its assignment) so Profile Container is disabled and Windows reverts to local profiles; remove the `Fast Logon – Clinical Endpoints – Tuning` assignment; change the `FSLogix Agent – Clinical Endpoints – Deploy` app assignment to **Uninstall** for the target group if the agent itself must be removed; and remove the devices from `Clinical – Logon Optimization`. On the GPO plane, unlink `Clinical – Logon Optimization – FSLogix GPO`. Containers on `Clinical Profiles – FSLogix – Share` are left intact (do not delete user data) unless the storage team confirms disposal. Rehearse this on the test device before fleet expansion.


---


# 5. Testing — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

This document is the validation plan. Run it against the pilot endpoints (group `Clinical – Logon Optimization – Pilot`) in the **Validate (measure)** phase, and on a sample of each wave during **Expand**. Each test has a **procedure**, an **expected result**, and a **PASS/FAIL** record. The **acceptance gate** at the end must be fully met before fleet expansion. Run all tests with **test accounts and test data only** — never use real PHI.

> Names referenced below are the exact objects from `03-implementation.md`: the Win32 app `FSLogix Agent – Clinical Endpoints – Deploy`, the device group `Clinical – Logon Optimization` (pilot subset `Clinical – Logon Optimization – Pilot`), the settings profiles `FSLogix Profile – Clinical Endpoints – Container` and `Fast Logon – Clinical Endpoints – Tuning`, and the profile share `Clinical Profiles – FSLogix – Share`.

---

## T1 — Logon time reduced vs. baseline by the target

- **Procedure:** On a pilot endpoint, sign in as a test clinician and measure usable-desktop logon time and profile load time using the same method as the Phase 1 baseline (run `CLINLOGON-Set-FSLogixBaseline.ps1` or `CLINLOGON-Report.ps1`). Compare against the recorded baseline.
- **Expected result:** Logon time is reduced versus the baseline by **at least the target reduction agreed in Phase 1** (e.g., ≥ 50% / under N seconds). The improvement is consistent across repeated sign-ins (not just a warm-cache one-off).
- **Result:** ☐ PASS ☐ FAIL — notes: baseline ___s → measured ___s (___% reduction) ______________________

## T2 — Agent installed and configuration applied

- **Procedure:** In `Apps > All apps > FSLogix Agent – Clinical Endpoints – Deploy > Monitor`, confirm the pilot device shows **Installed**. In `Devices > Configuration`, confirm `FSLogix Profile – Clinical Endpoints – Container` and `Fast Logon – Clinical Endpoints – Tuning` both show **Succeeded** for the device. On the device, confirm the FSLogix registry settings (`HKLM\SOFTWARE\FSLogix\Profiles`) reflect the configured values.
- **Expected result:** Agent reports **Installed**, both profiles report **Succeeded**, and the on-device settings match `03-implementation.md`.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T3 — Profile container created and attaches

- **Procedure:** Sign in as a test clinician. On the profile share `Clinical Profiles – FSLogix – Share`, confirm a per-user container folder (e.g., `%username%_%sid%`) was created and contains a `.VHDX`. On the endpoint, confirm the container is **attached** (a mounted profile disk) and that no "signed in with a temporary profile" message appeared.
- **Expected result:** The per-user VHD(X) exists on the share, attaches at sign-in, and the clinician gets their real (not temporary) profile.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T4 — Profile roams across shared endpoints

- **Procedure:** As the same test clinician, make a visible profile change (e.g., a desktop/setting change), sign out, then sign in on a **different** pilot endpoint (or AVD host).
- **Expected result:** The same FSLogix container attaches on the second endpoint and the change is present — one roaming profile follows the clinician across shared devices.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T5 — No profile corruption; container size controlled

- **Procedure:** Over the pilot period, repeatedly sign in/out as test clinicians across endpoints. Inspect the container for corruption symptoms (failed attach, ESENT/Profile Service errors, runaway size). Check the VHD(X) size against the agreed R7 per-container target and confirm the redirections/exclusions are keeping volatile/cache data out.
- **Expected result:** No profile corruption or temporary-profile fallback across the pilot; container size stays within the agreed target because excluded caches are not stored in the VHD(X).
- **Result:** ☐ PASS ☐ FAIL — notes: container size ___ MB (target ___ MB) ______________________

## T6 — Session stable

- **Procedure:** During a normal clinical workflow on a pilot endpoint, run the EHR/clinical web apps and Office through a representative session; sign out cleanly and confirm the container **detaches**.
- **Expected result:** The session is stable for the workflow duration with no profile-related crashes or hangs, and the container detaches cleanly on sign-out (no orphaned/locked VHD(X) left on the share).
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T7 — Fast user switch / tap-and-go works (where Imprivata is present)

- **Procedure:** On an endpoint that also runs Imprivata tap-and-go, sign in test clinician A (tap in), then have test clinician B tap in per the agreed session model (R9). Repeat the A→B→A cycle a few times in quick succession.
- **Expected result:** On tap-out/switch, clinician A's container detaches cleanly and clinician B's container attaches without a locked-VHD or temporary-profile error; rapid switching does not orphan a container. (On endpoints without Imprivata, validate the equivalent fast Windows switch/sign-out behavior.)
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T8 — Negative / failure handling

- **Procedure:** (a) On a test endpoint, temporarily simulate the profile share being unreachable (with storage-team coordination) and attempt sign-in. (b) Sign in a user **not** granted by the share permissions (R2/R8) and observe.
- **Expected result:** (a) The endpoint degrades predictably — either a clear failure/retry rather than a silent corrupt profile — and recovers when the share returns. (b) The ungranted user does not silently corrupt or attach another user's container; the failure is clear and attributable.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

---

## Acceptance gate

The deployment is accepted for fleet expansion **only when all of the following are true**:

- **T1** Logon time reduced vs. baseline by the agreed target — PASS
- **T2** Agent installed and both configuration profiles applied — PASS
- **T3** Profile container created and attaches (no temporary profile) — PASS
- **T4** Profile roams across shared endpoints — PASS
- **T5** No profile corruption; container size within target — PASS
- **T6** Session stable; container detaches cleanly — PASS
- **T7** Fast user switch / tap-and-go works (where Imprivata is present) — PASS
- **T8** Negative / failure handling behaves safely — PASS
- **Change control / compliance sign-off (R10)** recorded for the profile-storage and sign-on changes.

Record the gate decision, date, tester, approver, and the measured baseline→after logon figures. Any FAIL blocks expansion until remediated (see `06-troubleshooting.md`) and re-tested.


---


# 6. Troubleshooting — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

Symptom-driven fixes for the most common issues across the deployment. Work top-down within each symptom. Object names match `03-implementation.md`: Win32 app `FSLogix Agent – Clinical Endpoints – Deploy`, device group `Clinical – Logon Optimization` (pilot subset `Clinical – Logon Optimization – Pilot`), settings profiles `FSLogix Profile – Clinical Endpoints – Container` and `Fast Logon – Clinical Endpoints – Tuning`, and profile share `Clinical Profiles – FSLogix – Share`. Storage-platform values are owned by your **storage / infrastructure team** and Imprivata policy by your **Imprivata administrator** — escalate to them where indicated rather than guessing.

The FSLogix log is the first stop for most issues: on the endpoint, review `C:\ProgramData\FSLogix\Logs\Profile` (and `ODFC` if the Office Container is used). The User Profile Service and Application event logs corroborate.

---

## Slow logon (little or no improvement vs. baseline)

- **Confirm FSLogix is actually attaching, not falling back.** In `C:\ProgramData\FSLogix\Logs\Profile`, confirm the container **attaches** at sign-in. If Windows is silently building a local profile instead, the speed gain is lost — see "Container won't attach" below.
- **Confirm fast-logon tuning applied.** In `Devices > Configuration > Fast Logon – Clinical Endpoints – Tuning`, confirm **Succeeded** on the device and that *Delete cached copies of roaming profiles*, the first-sign-in animation disable, and OOBE-experience trims are in effect.
- **Check share latency.** Attach speed depends on the profile share. With the storage team, check round-trip/latency to `Clinical Profiles – FSLogix – Share` (SMB/445) from the endpoint; a slow or distant share erases the benefit. Ensure the share is regionally close (Azure Files) or on responsive storage.
- **Check container size / bloat.** A bloated VHD(X) attaches slowly — see "Profile bloat" below; add exclusions and re-measure.
- **Remove legacy roaming profile.** If an old roaming-profile path still applies to the user/OU, the two models fight and sign-in stays slow. Remove the legacy roaming-profile config for the clinical OU.
- **Re-measure properly.** Compare against the recorded baseline with the same method (`CLINLOGON-Set-FSLogixBaseline.ps1`), over repeated sign-ins — not a single warm-cache run.

## Container won't attach (temporary profile / "signed in with a temporary profile")

- **Check share permissions first.** The leading cause. Confirm both layers on `Clinical Profiles – FSLogix – Share` (R2): the **share-level** permission and the **NTFS / Azure Files Kerberos** ACLs (Users create/list/read this-folder-only; Creator Owner modify subfolders/files). For Azure Files, confirm Kerberos identity-based auth is enabled and the **Storage File Data SMB Share Contributor** role is assigned. Escalate to the storage team.
- **Check the VHD Locations path.** In `FSLogix Profile – Clinical Endpoints – Container`, confirm **VHD Locations** is exactly the storage-team-supplied share path and is reachable over SMB/445 from the endpoint (G5). A wrong/blocked path fails the attach.
- **Check the directory identity.** Confirm the user exists/enabled in the directory the share trusts and is in the permission group (R8). For Azure Files, confirm Entra/AD Kerberos is configured for the storage account.
- **Check for a locked VHD(X).** If the user's container is still attached/locked from a prior session (common on fast switching), the new attach fails. See "Conflicts with Imprivata" and tune *Locked Retry Count/Interval*; confirm prior sessions sign out cleanly.
- **Read the FSLogix profile log.** `C:\ProgramData\FSLogix\Logs\Profile` states the precise reason (permissions, path, lock, disk full) — fix the stated cause rather than guessing.

## Share permission errors

- **Distinguish the two layers.** A share that "looks" permissioned at the NTFS level can still fail at the share level (and vice-versa). Have the storage team confirm **both** explicitly against the FSLogix model.
- **Azure Files specifics.** Confirm identity-based authentication (Kerberos) is enabled on the storage account, the share-level RBAC role is assigned to the profile users/group, and the on-share directory ACLs follow the model. Missing any one yields access-denied on container create/attach.
- **Creator Owner inheritance.** If users can't create their own folder, confirm *Users* has Create-folder/append on **this folder only** and *Creator Owner* has Modify on **subfolders and files** so each user owns only their container.
- **Escalate to storage.** Do not loosen permissions to "make it work" (e.g., granting broad write) — that exposes other clinicians' containers. Fix to the model with the storage team.

## Profile bloat (container too large / share filling up)

- **Tighten redirections/exclusions.** Identify what is growing in the container (caches, temp, browser profile, indexable content, app caches) and add it to `redirections.xml` / the FSLogix exclusion settings so it stays local instead of roaming (R7). This is the primary fix.
- **Confirm dynamic disk + sane max.** Confirm **Is Dynamic = 1** so share usage tracks real data, and that **Size In MBs** is a sane per-container max — raising the max should be a last resort after exclusions.
- **Find app misbehavior.** If an EHR/clinical app is caching large data into the profile, work with the app owner to relocate or exclude that cache.
- **Review on a schedule.** Run `CLINLOGON-Report.ps1` to track container sizes and catch creep early; prune exclusions as new caches appear.

## Profile corruption

- **Read the log and event records.** The FSLogix profile log plus User Profile Service / ESENT events identify corruption and its trigger (dirty detach, share interruption, antivirus locking the VHD(X)).
- **Exclude AV from the VHD(X).** Ensure endpoint antivirus excludes the FSLogix VHD(X) files and the agent processes per Microsoft's FSLogix AV-exclusion guidance — AV locking the container is a classic corruption cause. Confirm with your security team.
- **Ensure clean detach.** Corruption often follows an unclean sign-out (power-off, forced unload). Confirm *Do not forcefully unload the users registry at logoff* = `Disabled` and that sessions sign out cleanly (especially on tap-and-go — see below).
- **Recover a single user.** For a corrupted individual container, work with the storage team to restore from snapshot/backup; never delete a user's container without a restore plan.

## Conflicts with Imprivata (tap-and-go fast switching)

- **Confirm tap-out detaches the container.** On shared single-session WOWs, the container only detaches on a full **sign-out**. If Imprivata tap-out only **locks**, the prior user's container stays attached and the next clinician's attach can fail. With the **Imprivata administrator**, confirm the agreed session model (R9) — typically full sign-out on tap-out so the container detaches.
- **Tune locked-VHD retries.** Where rapid A→B→A switching causes occasional locked-VHD retries, raise FSLogix **Locked Retry Count / Locked Retry Interval** in `FSLogix Profile – Clinical Endpoints – Container` modestly so a just-detaching container is given time to release. Do not change Imprivata appliance policy from here — escalate it.
- **Watch attribution.** If a clinician lands in the wrong profile after a switch, treat as a defect: confirm the prior container detached and the directory identity mapping is correct; re-run test T7.
- **Keep the two solutions' ownership separate.** Imprivata appliance/computer-policy values are owned by the Imprivata admin (separate solution); this solution owns only the FSLogix-side settings that let the two coexist.

## Agent or configuration won't apply (Intune)

- **Check detection rules.** A "failed" agent install with FSLogix actually present usually means wrong detection criteria. Confirm the rule matches the installed agent file/version or the `FSLogix Apps` uninstall registry key.
- **Check command lines.** Confirm the silent install/uninstall command lines are the documented FSLogix switches (`/install /quiet /norestart`, `/uninstall /quiet /norestart`) — do not invent switches.
- **Check requirements.** Confirm the device meets the app's OS architecture (`64-bit`) / minimum OS (R4); a mismatch leaves the app **Not applicable**.
- **Check assignment, conflicts, and sync.** Confirm the app and both profiles are assigned **Required**/targeted to the device's group (`Clinical – Logon Optimization – Pilot` during pilot). In `Devices > Configuration`, check for a **conflict** state where another policy or a legacy GPO sets the same FSLogix value — pick one authoritative plane (R3). Force an Intune sync and review the device's policy state.
- **Remediate.** After the root cause is addressed, use `CLINLOGON-Remediation.ps1 -Apply` to safely clear stale local cached profiles and/or re-point the FSLogix config to the named share for the device.

---

## Escalation map

| Issue domain | Escalate to |
|--------------|-------------|
| Profile share path, permissions, Azure Files Kerberos, quota/capacity, backup/snapshot | Storage / infrastructure team |
| Imprivata tap-out behavior, session timing, appliance/computer policy | Imprivata administrator (separate solution) |
| FSLogix/Windows licensing entitlement | Licensing owner |
| Intune app/profile/group delivery, GPO/ADMX, device management, reporting | Intune / AD administrator |
| Antivirus exclusions for the VHD(X), compliance sign-off | Security / compliance team |
| Network reachability to Microsoft / profile storage (SMB 445, Kerberos) | Networking team |


---


# 7. Best Practices — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

These practices keep the deployment fast, stable, and compliant across the lifecycle. They complement — they do not replace — your storage team's platform guidance, your Imprivata administrator's appliance guidance, and your compliance team's HIPAA/HITRUST requirements.

## Measure first, measure after

- **Always capture a baseline before changing anything.** Run `CLINLOGON-Set-FSLogixBaseline.ps1` on representative endpoints and record logon and profile-load time, with the target reduction agreed in writing (R6). A solution sold on speed must prove the speed.
- **Re-measure with the same method.** Use the identical measurement method (same script, same warm/cold conditions) before and after so the before/after comparison is honest, and capture repeated sign-ins, not a single warm-cache run.
- **Report continuously.** Run `CLINLOGON-Report.ps1` after each wave to track logon time, agent install state, and container sizes; investigate any endpoint that drifts.

## Storage and permissions

- **Get both permission layers right.** FSLogix attach fails if either the **share-level** permission or the **NTFS / Azure Files Kerberos** ACLs are wrong. Use the FSLogix-recommended model (Users create/list/read this-folder-only; Creator Owner modify subfolders/files) and, for Azure Files, enable identity-based Kerberos **and** assign the share-level RBAC role.
- **Defer storage-platform values to the storage team.** Share path, storage account, tier, quota, and backup/snapshot schedule are storage-team decisions — confirm them, don't invent them, and ensure the share is highly available (a single slow/failed share stalls every sign-in).
- **Back up containers and plan capacity.** Treat the profile share as production user data: snapshot/back it up, monitor free space, and size for peak concurrent containers plus growth (R7).

## Container bloat and corruption control

- **Use redirections/exclusions aggressively.** Keep volatile caches, temp, browser caches, and indexable content the clinician doesn't need across devices **out** of the VHD(X) via `redirections.xml`. This is the primary lever against bloat and the leading cause of small, fast, stable containers.
- **Prefer dynamic VHDX with a sane max size.** Dynamic disks keep share usage proportional to real data; set a per-container max that fits the clinical profile without inviting runaway growth.
- **Review container sizes on a schedule.** Containers that creep up signal a missing exclusion or an app caching into the profile — find it and add the exclusion rather than just raising the size.

## Fast-logon tuning

- **Delete stale cached profiles on shared devices.** Enable both *Delete cached copies of roaming profiles* and FSLogix *Delete Local Profile When VHD Should Apply* so every sign-in is clean and the local disk stays lean.
- **Trim what runs at sign-in.** Disable the first-sign-in animation and OOBE consumer experiences, and review startup/run items — each one is sign-in latency on a shared clinical device.
- **Remove legacy roaming-profile config.** FSLogix replaces roaming user profiles; leaving an old roaming-profile path in place makes the two models fight. Remove it for the clinical OU.

## Coexisting with Imprivata tap-and-go

- **Make the container detach between users.** On shared single-session WOWs, agree (with the Imprivata admin) a tap-out that performs a full sign-out so the FSLogix container detaches before the next clinician's attaches — the clean model for rapid switching.
- **Tune locked-VHD retries, not appliance policy.** Where fast switching causes occasional locked-VHD retries, raise FSLogix *Locked Retry Count/Interval* modestly. Do not set Imprivata policy from this solution — escalate to the Imprivata admin (separate solution).

## Deployment hygiene

- **Pilot before fleet, always.** Validate on the representative test device and `Clinical – Logon Optimization – Pilot` before adding the full `Clinical – Logon Optimization` group; expand in controlled waves within approved maintenance windows. For AVD, stage across the host pool with drain.
- **Pin and record versions.** Record the exact FSLogix agent version, install/uninstall command lines, and detection criteria in change control, and keep the Win32 app publisher set to `Microsoft Corporation`.
- **Use device-targeted assignments** for shared endpoints — assign the agent app and both configuration profiles to the device group, not to users, so the experience follows the shared device.
- **Keep a rehearsed rollback.** Maintain and periodically rehearse the back-out (disable Profile Container, remove tuning, uninstall agent, remove from group) so a logon/profile regression on a shared clinical endpoint can be reversed quickly — without deleting user containers.

## Data handling

- **No PHI in artifacts.** Keep reports, logs, and screenshots free of PHI. Use test accounts and test data for all validation, and never store PHI outside approved systems.


---


# 8. Deliverables Summary — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

This solution delivers a complete, productized package: implementation documentation, runnable PowerShell tooling, and a hero image. Everything follows the standard deployment model — an Intune-delivered (or GPO-delivered) FSLogix agent and configuration, a named Entra device group, settings profiles, and a profile share — with storage-platform values, licensing, and Imprivata policy deferred to their respective owners.

## Documentation

| Document | Purpose |
|----------|---------|
| `01-solution-overview.md` | What the solution delivers, the problem it solves, scope/boundaries, and the phase model. |
| `02-requirements.md` | Solution-specific requirements R1–R10 (FSLogix licensing, SMB/Azure Files share + permissions, Intune/GPO plane, Win10/11 or AVD hosts, the FSLogix agent, a baseline logon measurement, storage sizing/exclusions, directory identity, Imprivata interplay, change control), each with Verify / Implement-if-missing. |
| `global-requirements-healthcare-solutions.md` | Category-wide prerequisites G1–G7 (tenant/roles, Windows/Intune licensing, HIPAA/HITRUST + change control, maintenance windows, network to Microsoft + profile storage, test device, rollback). |
| `03-implementation.md` | The build, Assess (baseline) → Expand, with full navigation paths and named objects. |
| `05-testing.md` | Test plan T1–T8 with PASS/FAIL and the acceptance gate, including the before/after logon measurement. |
| `06-troubleshooting.md` | Symptom-driven fixes for slow logon, container won't attach, share permission errors, profile bloat, corruption, and Imprivata conflicts. |
| `07-best-practices.md` | Measurement, storage/permissions, bloat/corruption control, fast-logon tuning, Imprivata coexistence, deployment, and data-handling guidance. |
| `executive-summary.md` | Business-level summary for decision-makers. |
| `08-deliverables-summary.md` | This document. |

## PowerShell scripts (5)

All scripts are read-only by default (remediation/baseline support `-WhatIf`) and intended to be run by an administrator with appropriate Microsoft Graph permissions (Intune scripts) or locally on the endpoint (baseline). Each has a `.SYNOPSIS` plus PURPOSE / HOW TO RUN / EXPECTED RESULTS header and a neutral `.NOTES` line.

| Script | Purpose |
|--------|---------|
| `CLINLOGON-Discovery.ps1` | Inventory: confirms the FSLogix agent app and configuration profiles exist and are assigned, the `Clinical – Logon Optimization` group exists, and reports the FSLogix agent presence + Profile Container configuration and profile-share health where reachable. Read-only. |
| `CLINLOGON-Validation.ps1` | Per-device validation: FSLogix configured to the named share, container attaches, and a logon-time sample vs. target — outputs PASS/FAIL. |
| `CLINLOGON-Report.ps1` | Fleet report: logon-time and profile-container-size figures plus agent install state and group coverage, exported to CSV. |
| `CLINLOGON-Remediation.ps1` | Safe fixes: clear stale local cached profiles and/or re-point FSLogix config to the named share; runs in `-WhatIf`/read-only by default, acts only with `-Apply`. |
| `CLINLOGON-Set-FSLogixBaseline.ps1` | Captures the pre-change logon/profile-load baseline on an endpoint (and re-runs post-change for the before/after); supports `-WhatIf`. |

## Hero image

| Asset | Purpose |
|-------|---------|
| `CLINLOGON-hero.png` | Listing hero image for the solution. |

## Named objects produced by the solution

These objects are created during implementation and reused verbatim across the docs and scripts:

- Win32 app: `FSLogix Agent – Clinical Endpoints – Deploy` (publisher `Microsoft Corporation`)
- Entra device group: `Clinical – Logon Optimization` (pilot subset `Clinical – Logon Optimization – Pilot`)
- Settings catalog profile: `FSLogix Profile – Clinical Endpoints – Container`
- Settings catalog profile: `Fast Logon – Clinical Endpoints – Tuning`
- Profile share (logical name; path from storage team): `Clinical Profiles – FSLogix – Share`
- GPO (only if GPO is the plane): `Clinical – Logon Optimization – FSLogix GPO`

## Outcome

A repeatable, **measured** deployment of FSLogix profile containers and fast-logon tuning across shared clinical endpoints (and AVD hosts) — cutting logon time against a proven baseline, giving clinicians one roaming profile that follows them, controlling container bloat with exclusions, coexisting cleanly with Imprivata tap-and-go — delivered and monitored through Microsoft Intune (or GPO), with a clear acceptance gate, rollback, and ongoing reporting.
