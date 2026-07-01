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
