# 4. Maintenance & Update Guide — the DISA STIG-release lifecycle

This is the half of the solution that keeps your baseline from silently drifting behind DISA. DISA
revises the Windows 10/11 STIGs periodically (typically quarterly); each release can add, remove,
renumber, or change the required value of rules. Run this lifecycle every time DISA publishes a new
STIG release, and run the drift portion on an ongoing cadence even between releases.

> Maintenance model (mirrors the deployment model):
> Obtain → Diff → Assess/Approve → Update (controlled change) → Re-validate → Record version.
> Treat every STIG-release update as a piloted, approved, rollback-ready production change — exactly
> like the net-new implementation in document 3.

## Two kinds of maintenance
1. Ongoing drift maintenance (continuous): devices fall out of compliance between STIG releases (a
   conflicting policy, a local change, a failed apply). You detect and reapply.
2. STIG-release update (event-driven): DISA ships a new STIG release; you bring your baseline up to
   it. This is the main subject of this guide.

---

## Part A — Ongoing drift maintenance (run on a cadence)
1. On a schedule (for example weekly), run `STIG-Report.ps1` to produce the fleet STIG posture and a
   drift list (devices whose configuration state is no longer compliant).
2. For drifted devices, run `STIG-Validation.ps1` to see which settings drifted on a specific device.
3. Reapply with `STIG-Remediation.ps1`. It runs with `-WhatIf` by default — review the planned
   actions first, then re-run with `-WhatIf:$false` to force the policy sync that reapplies the
   baseline. (Remediation here means forcing the Intune policy to re-apply, not editing settings
   outside Intune.)
4. If a device keeps drifting, look for a conflicting policy in Intune (two policies setting the same
   rule differently) and resolve the conflict at the policy level.

---

## Part B — STIG-release update (run when DISA releases a new STIG)

### Step 1 — Obtain
1. Download the new DISA Windows 10/11 STIG release (and its updated SCAP benchmark) from the DISA cyber exchange, and open it in the STIG Viewer.
2. Note the new release (for example `vYYYY.MM`) and keep the release you are currently live on (your existing tag `STIG-Win-vYYYY.MM`).

### Step 2 — Diff (what changed)
1. Export your current live baseline from Intune (the settings in the `STIG Win10/11 – CAT I/II/III – Production` and ADMX policies). The discovery/report scripts and the Intune export help here.
2. Export or extract the new STIG's intended rules (from the new STIG Viewer / SCAP content).
3. Run `STIG-Compare-StigVersion.ps1` to diff the new STIG export against your current live baseline. It reports:
   - Added rules (new in this release — you must add them),
   - Removed rules (dropped — you may retire them),
   - Changed rules (same rule, new required value — you must update the value),
   - Severity changes (a rule moved between CAT I/II/III).
4. Save the diff output as the change record for this release update.

### Step 3 — Assess / Approve
1. For each changed/added rule, assess business impact — could it break a mission app or workflow?
   Pay special attention to new or upgraded CAT I rules and to scripting, network, removable-media,
   and authentication rules.
2. Decide for each: adopt, adopt with a POA&M exception, or defer with documented reason.
3. Obtain approval per your change-control process (Requirement 2.7). Record approver, date, and the
   list of accepted changes. Update the POA&M register for anything you cannot adopt.

### Step 4 — Update (controlled change, piloted)
1. Update the pilot policies first. Edit the `STIG Win10/11 – CAT I/II/III – Pilot` (and ADMX pilot)
   policies to add/change/remove the approved rules. Update each policy Description to the new version
   tag `STIG-Win-vYYYY.MM`.
2. Implement approved exceptions exactly as in document 3, Step 7 (omit the setting or scope an
   exception group); keep the POA&M register current.
3. Assign remains `STIG Win10/11 – Pilot Devices`. Sync a pilot device.

### Step 5 — Re-validate (pilot gate again)
1. In Intune, confirm the updated pilot policies show Succeeded (per-setting status).
2. Run `STIG-Validation.ps1` on a pilot device and `STIG-Report.ps1` for pilot posture; reconcile
   against a fresh STIG Viewer / SCAP scan of the pilot device.
3. Soak the pilot for several business days against real mission apps — a new STIG release can
   introduce a rule that breaks something a prior release never touched.
4. Gate: do not promote to production until the pilot passes and no unresolved breakage remains. If
   something breaks, roll back that rule (remove the setting / unassign) and record it as a POA&M
   exception, exactly as in document 3, Step 10.

### Step 6 — Promote and Record version
1. Apply the same approved changes to the production policies (`STIG Win10/11 – CAT I/II/III –
   Production`, and ADMX as applicable). Update their Description to the new version tag. Roll out in
   waves for large fleets.
2. Re-run `STIG-Report.ps1` after each wave to confirm posture and catch drift.
3. Record the release you are now live on: update the change record, the policy descriptions
   (`STIG-Win-vYYYY.MM`), the POA&M register, and your baseline document. This closes the loop — the
   next STIG release diffs against this newly recorded baseline.

---
### Maintenance order of operations
`Obtain new STIG → Diff vs live baseline (STIG-Compare-StigVersion.ps1) → Assess/Approve →
Update pilot policies (controlled change) → Re-validate (pilot gate + rollback) → Promote to
production → Record new version tag`

### Cadence summary
| Activity | When | Tool |
|---|---|---|
| Drift detection + reapply | Weekly (or your cadence) | `STIG-Report.ps1`, `STIG-Validation.ps1`, `STIG-Remediation.ps1` |
| STIG-release update | Each new DISA Windows 10/11 STIG release (typically quarterly) | `STIG-Compare-StigVersion.ps1` + this Part B |
| Version recorded in policy descriptions | After every update | Intune policy Description = `STIG-Win-vYYYY.MM` |
| POA&M review | On each release and per your GRC cadence | POA&M / exception register |
