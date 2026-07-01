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
