# 4. Maintenance & Update Guide — the CIS benchmark-version lifecycle (macOS)

This is the half of the solution that keeps your baseline from silently drifting behind CIS. CIS
revises the macOS Benchmark periodically, and — importantly for macOS — publishes a **new benchmark
document for each new macOS major release**. Each revision can add, remove, renumber, or change the
recommended value of controls, and a new macOS release can change which Apple payloads exist. Run
this lifecycle **every time CIS publishes a new version (or you move Macs to a new macOS major)**, and
run the drift portion **on an ongoing cadence** even between versions.

> **Maintenance model (mirrors the deployment model):**
> **Obtain → Diff → Assess/Approve → Update (controlled change) → Re-validate → Record version.**
> Treat every benchmark update as a piloted, approved, rollback-ready production change — exactly like
> the net-new implementation in document 3.

## Two kinds of maintenance
1. **Ongoing drift maintenance (continuous):** devices fall out of compliance between benchmark
   versions (a conflicting profile, a removed profile, a failed apply, or a user change that a shell
   control has not yet re-corrected). You detect and reapply.
2. **Benchmark-version update (event-driven):** CIS ships a new version, or you adopt a new macOS
   major; you bring your baseline up to it. This is the main subject of this guide.

---

## Part A — Ongoing drift maintenance (run on a cadence)
1. On a schedule (for example weekly), run `CISMAC-Report.ps1` to produce the fleet CIS posture and a
   drift list (Macs whose configuration/script state is no longer compliant).
2. For drifted devices, run `CISMAC-Validation.ps1` to see which settings drifted on a specific Mac.
3. Reapply with `CISMAC-Remediation.ps1`. **It runs with `-WhatIf` by default** — review the planned
   actions first, then re-run with `-WhatIf:$false` to repair/reassign the drifted policy/profile/
   script so the baseline re-applies. (Remediation here means making the Intune-managed objects
   re-apply — re-syncing the device and confirming assignments — not editing settings on the Mac
   outside Intune.)
4. If a Mac keeps drifting, look for a **conflicting profile** in Intune (two profiles setting the
   same payload differently) and resolve the conflict at the policy level. For a control delivered by
   a shell script that users keep changing, confirm the script's **run frequency** re-enforces it
   often enough.

---

## Part B — Benchmark-version update (run when CIS releases a new version)

### Step 1 — Obtain
1. Download the **new** CIS macOS Benchmark version (and any updated supporting `.mobileconfig` / audit content) from CIS WorkBench. If this is a new macOS major, obtain that release's benchmark document.
2. Note the new version number (for example `vX.Y.Z+1`) and keep the version you are currently live on (your existing tag `CIS-macOS-vX.Y.Z`).

### Step 2 — Diff (what changed)
1. Export your **current live baseline** from Intune (the settings in `CIS macOS – L1 – Production`, any L2 catalog policy, the custom `.mobileconfig` payloads, and the shell-script controls). The discovery/report scripts and the Intune export help here.
2. Export or extract the **new benchmark's** intended settings (from the new benchmark / supporting content).
3. Run `CISMAC-Compare-BenchmarkVersion.ps1` to diff the new benchmark export against your current live baseline. It reports:
   - **Added** controls (new in this version — you must add them),
   - **Removed** controls (dropped — you may retire them),
   - **Changed** controls (same control, new recommended value — you must update the value),
   - **Level changes** (a control moved between L1 and L2),
   - **Surface changes** (where indicated — a control now needs a different macOS surface, for example moved from a custom profile into the settings catalog).
4. Save the diff output as the change record for this version update.

### Step 3 — Assess / Approve
1. For each changed/added control, assess **business impact** — could it break an app, a workflow, or
   login? Pay special attention to controls moving into L1 (now applies fleet-wide) and to Gatekeeper,
   firewall, removable-media, automation, and authentication controls.
2. Decide for each: **adopt**, **adopt with an exception**, or **defer with documented reason**.
3. Obtain approval per your change-control process (Requirement 2.8). Record approver, date, and the
   list of accepted changes.

### Step 4 — Update (controlled change, piloted)
1. **Update the pilot objects first.** Edit `CIS macOS – L1 – Pilot` (and the L2 catalog policy,
   `CIS macOS – Custom – Pilot`, and `CIS macOS – Shell – Pilot`) to add/change/remove the approved
   controls. For a control that changed surface, move it to the correct surface. Update each object
   **Description** to the new version tag `CIS-macOS-vX.Y.Z+1`.
2. Implement approved exceptions exactly as in document 3, Step 8 (omit the setting, scope an
   exception group, or disable the script); keep the exception register current.
3. Assignment remains `CIS macOS – Pilot Devices`. Sync a pilot Mac.

### Step 5 — Re-validate (pilot gate again)
1. In Intune, confirm the updated pilot objects show **Succeeded** (per-setting and shell-script status).
2. Run `CISMAC-Validation.ps1` on a pilot Mac and `CISMAC-Report.ps1` for pilot posture.
3. **Soak the pilot** for several business days against real apps — a new benchmark version (or a new
   macOS major) can introduce a control that breaks something the previous baseline never touched.
   Complete the relevant Testing Guide checks.
4. **Gate:** do not promote to production until the pilot passes and no unresolved breakage remains.
   If something breaks, roll back that control (remove the setting / unassign / disable the script)
   and record it as an exception, exactly as in document 3, Step 10.

### Step 6 — Promote and Record version
1. Apply the same approved changes to the production objects (`CIS macOS – L1 – Production`, and the
   L2/custom/shell production objects as applicable). Update their **Description** to the new version
   tag. Roll out in waves for large fleets.
2. Re-run `CISMAC-Report.ps1` after each wave to confirm posture and catch drift.
3. **Record the version** you are now live on: update the change record, the policy/profile/script
   descriptions (`CIS-macOS-vX.Y.Z+1`), and your baseline document. This closes the loop — the next
   benchmark release diffs against this newly recorded baseline.

---
### Maintenance order of operations
`Obtain new version → Diff vs live baseline (CISMAC-Compare-BenchmarkVersion.ps1) → Assess/Approve →
Update pilot objects (controlled change) → Re-validate (pilot gate + rollback) → Promote to
production → Record new version tag`

### Cadence summary
| Activity | When | Tool |
|---|---|---|
| Drift detection + reapply | Weekly (or your cadence) | `CISMAC-Report.ps1`, `CISMAC-Validation.ps1`, `CISMAC-Remediation.ps1` |
| Benchmark-version update | Each new CIS macOS Benchmark release (and each new macOS major) | `CISMAC-Compare-BenchmarkVersion.ps1` + this Part B |
| APNs certificate renewal | Annually, before expiry | Intune → Devices → Enrollment → Apple → Apple MDM Push certificate |
| Version recorded in descriptions | After every update | Intune object Description = `CIS-macOS-vX.Y.Z` |
