# 5. Testing & Validation — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Run every check against the pilot (`AVD – Host Pool – Pilot`) before expanding to production. Each test has an explicit **pass/fail gate**. The scripts referenced here are in the `scripts/` folder and are read-only except `AVDDEP-Maintenance.ps1`, which defaults to a safe `-WhatIf` preview.

> Run order: `AVDDEP-Discovery.ps1` → `AVDDEP-Validate.ps1` → `AVDDEP-Report.ps1`. Use `AVDDEP-Maintenance.ps1` (preview mode) only to rehearse the drain/patch gate.

---

## Test 1 — Golden image is versioned in the gallery
- **How:** Run `AVDDEP-Discovery.ps1` (or `AVDDEP-Report.ps1`). Confirm `avd_compute_gallery_core` contains the definition `avd-win11-m365-multisession` with version `1.0.0` in state **Succeeded**, replicated to each target region.
- **Pass:** The version exists, is Succeeded, and is Gen2/Generalized.
- **Fail:** No version, a Failed replication, or a generation mismatch → revisit Section 3, Step 4.

## Test 2 — Session hosts were built from the intended image version
- **How:** Run `AVDDEP-Validate.ps1`. It reports each session host's source image reference and flags any host whose image does **not** match the gallery version the host pool was deployed from.
- **Pass:** All hosts in `AVD – Host Pool – Pilot` trace to gallery version `1.0.0`.
- **Fail:** A host built from a Marketplace image or an older version → it is a snowflake; redeploy it from Bicep (Step 6).

## Test 3 — Session hosts are healthy and registered
- **How:** In **Host pool → Session hosts**, confirm both pilot hosts show **Available** with a healthy AVD agent; `AVDDEP-Validate.ps1` reports agent/status per host.
- **Pass:** All pilot hosts **Available**, no **Unavailable**/**Upgrading**/**NeedsAssistance**.
- **Fail:** A host stuck not-registered usually means an expired registration token (requirement R6) → redeploy so a fresh token is minted; do not hand-edit.

## Test 4 — FSLogix profiles roam
- **How:** Sign a pilot user into two different hosts in turn. Confirm a `Profile_<user>.vhdx` is created on `AVD – Profile Share – Core` and that desktop/settings/Outlook cache follow the user. `AVDDEP-Validate.ps1` confirms the FSLogix registry on each host points at the correct UNC path with `Enabled=1`.
- **Pass:** One container per user on the share; profile identical across hosts; logon completes in a reasonable time.
- **Fail:** A fresh temp profile each logon, or no VHDX → check share permissions (users: Modify) and the `VHDLocations` value (Section 3, Step 8).

## Test 5 — RBAC is least-privilege and correct
- **How:** `AVDDEP-Validate.ps1` lists role assignments on the host pool and resource group. Confirm operators hold **Desktop Virtualization** roles, not broad **Owner/Contributor** at subscription scope.
- **Pass:** Operators have Desktop Virtualization Contributor / Host Pool Contributor scoped to the RG/host pool; Owner is limited to the platform team.
- **Fail:** Broad standing Owner on operators → tighten per Section 3, Step 7 (prefer PIM).

## Test 6 — Scaling plan controls capacity
- **How:** `AVDDEP-Report.ps1` prints the scaling plan, its schedules, and the host-pool assignment. Confirm `AVD – Scaling Plan – Pilot` is **enabled** and assigned to `AVD – Host Pool – Pilot`. Observe that off-peak drives idle hosts to deallocated.
- **Pass:** Plan enabled and assigned; ramp-up/ramp-down/off-peak schedule present; idle hosts deallocate off-peak.
- **Fail:** Plan not assigned, or hosts never power down → confirm the AVD service principal has Power On/Off rights (Section 3, Step 9).

## Test 7 — IaC deployment is reproducible (what-if is clean)
- **How:** Re-run the Section 3, Step 6 `az deployment group what-if` against the pilot parameters.
- **Pass:** What-if reports **no changes** (the deployed state matches the template) — proving the estate is fully described by code.
- **Fail:** What-if wants to change/recreate resources you did not change → a manual drift crept in; reconcile the template to reality before expanding.

## Test 8 — Drain/patch workflow is safe (rehearsal)
- **How:** Run `AVDDEP-Maintenance.ps1` in its **default `-WhatIf`** mode. Confirm it lists which hosts *would* be drained and their active session counts **without changing anything**.
- **Pass:** Preview lists targets and session counts; no drain mode is actually set.
- **Fail:** Any state change in preview mode, or the script errors → do not run `-Apply`; resolve first.

---

### Exit criteria (all must be green before expanding)
Image version Succeeded (T1) · hosts trace to that version (T2) · hosts Available (T3) · FSLogix roams (T4) · RBAC least-privilege (T5) · scaling plan enabled and cost-effective (T6) · what-if clean/reproducible (T7) · drain preview safe (T8). Only then deploy `AVD – Host Pool – Production` from the same image and template.
