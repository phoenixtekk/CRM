# 4. Maintenance & Update Guide — the CIS benchmark-version lifecycle

This is the half of the solution that keeps your baseline from silently drifting behind CIS. CIS
revises the Windows 11 Benchmark periodically; each revision can add, remove, renumber, or change the
recommended value of controls. Run this lifecycle **every time CIS publishes a new version**, and run
the drift portion **on an ongoing cadence** even between versions.

> **Maintenance model (mirrors the deployment model):**
> **Obtain → Diff → Assess/Approve → Update (controlled change) → Re-validate → Record version.**
> Treat every benchmark update as a piloted, approved, rollback-ready production change — exactly like
> the net-new implementation in document 3.

## Two kinds of maintenance
1. **Ongoing drift maintenance (continuous):** devices fall out of compliance between benchmark
   versions (a conflicting policy, a local change, a failed apply). You detect and reapply.
2. **Benchmark-version update (event-driven):** CIS ships a new version; you bring your baseline up to
   it. This is the main subject of this guide.

---

## Part A — Ongoing drift maintenance (run on a cadence)
1. On a schedule (for example weekly), run `CIS11-Report.ps1` to produce the fleet CIS posture and a
   drift list (devices whose configuration state is no longer compliant).
2. For drifted devices, run `CIS11-Validation.ps1` to see which settings drifted on a specific device.
3. Reapply with `CIS11-Remediation.ps1`. **It runs with `-WhatIf` by default** — review the planned
   actions first, then re-run with `-WhatIf:$false` to force the policy sync that reapplies the
   baseline. (Remediation here means forcing the Intune policy to re-apply, not editing settings
   outside Intune.)
4. If a device keeps drifting, look for a **conflicting policy** in Intune (two policies setting the
   same control differently) and resolve the conflict at the policy level.

---

## Part B — Benchmark-version update (run when CIS releases a new version)

### Step 1 — Obtain
1. Download the **new** CIS Windows 11 Benchmark version (and its updated Build Kit) from CIS WorkBench.
2. Note the new version number (e.g. `vX.Y.Z+1`) and keep the version you are currently live on (your existing tag `CIS-Win11-vX.Y.Z`).

### Step 2 — Diff (what changed)
1. Export your **current live baseline** from Intune (the settings in `CIS Win11 – L1 – Production` and any L2/ADMX policies). The discovery/report scripts and the Intune export help here.
2. Export or extract the **new benchmark's** intended settings (from the new Build Kit / benchmark).
3. Run `CIS11-Compare-BenchmarkVersion.ps1` to diff the new benchmark export against your current live baseline. It reports:
   - **Added** controls (new in this version — you must add them),
   - **Removed** controls (dropped — you may retire them),
   - **Changed** controls (same control, new recommended value — you must update the value),
   - **Level changes** (a control moved between L1 and L2).
4. Save the diff output as the change record for this version update.

### Step 3 — Assess / Approve
1. For each changed/added control, assess **business impact** — could it break an app or workflow?
   Pay special attention to controls moving into L1 (now applies fleet-wide) and to scripting,
   network, removable-media, and authentication controls.
2. Decide for each: **adopt**, **adopt with an exception**, or **defer with documented reason**.
3. Obtain approval per your change-control process (Requirement 2.7). Record approver, date, and the
   list of accepted changes.

### Step 4 — Update (controlled change, piloted)
1. **Update the pilot policies first.** Edit `CIS Win11 – L1 – Pilot` (and L2/ADMX pilot policies) to
   add/change/remove the approved controls. Update each policy **Description** to the new version tag
   `CIS-Win11-vX.Y.Z+1`.
2. Implement approved exceptions exactly as in document 3, Step 6 (omit the setting or scope an
   exception group); keep the exception register current.
3. Assign remains `CIS Win11 – Pilot Devices`. Sync a pilot device.

### Step 5 — Re-validate (pilot gate again)
1. In Intune, confirm the updated pilot policies show **Succeeded** (per-setting status).
2. Run `CIS11-Validation.ps1` on a pilot device and `CIS11-Report.ps1` for pilot posture.
3. **Soak the pilot** for several business days against real apps — a new benchmark version can
   introduce a control that breaks something that L1 never touched before. Complete the relevant
   Testing Guide checks.
4. **Gate:** do not promote to production until the pilot passes and no unresolved breakage remains.
   If something breaks, roll back that control (remove the setting / unassign) and record it as an
   exception, exactly as in document 3, Step 9.

### Step 6 — Promote and Record version
1. Apply the same approved changes to the production policies (`CIS Win11 – L1 – Production`, and L2/ADMX
   as applicable). Update their **Description** to the new version tag. Roll out in waves for large fleets.
2. Re-run `CIS11-Report.ps1` after each wave to confirm posture and catch drift.
3. **Record the version** you are now live on: update the change record, the policy descriptions
   (`CIS-Win11-vX.Y.Z+1`), and your baseline document. This closes the loop — the next benchmark
   release diffs against this newly recorded baseline.

---
### Maintenance order of operations
`Obtain new version → Diff vs live baseline (CIS11-Compare-BenchmarkVersion.ps1) → Assess/Approve →
Update pilot policies (controlled change) → Re-validate (pilot gate + rollback) → Promote to
production → Record new version tag`

### Cadence summary
| Activity | When | Tool |
|---|---|---|
| Drift detection + reapply | Weekly (or your cadence) | `CIS11-Report.ps1`, `CIS11-Validation.ps1`, `CIS11-Remediation.ps1` |
| Benchmark-version update | Each new CIS Windows 11 Benchmark release | `CIS11-Compare-BenchmarkVersion.ps1` + this Part B |
| Version recorded in policy descriptions | After every update | Intune policy Description = `CIS-Win11-vX.Y.Z` |
