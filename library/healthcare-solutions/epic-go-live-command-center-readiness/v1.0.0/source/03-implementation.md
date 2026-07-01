# 3. Implementation — Epic Go-Live & Command Center Endpoint Readiness Playbook

This is the operational walkthrough. It follows the five-phase model — **Assess → Prepare/Remediate → Validate (go/no-go) → Command Center (hypercare) → Stabilize/Handover** — and produces the named artifacts defined in `01-solution-overview.md`. Every step that uses a console gives the full navigation path. Confirm the prerequisites in `02-requirements.md` and `global-requirements-healthcare-solutions.md` before starting; never assume a prerequisite is satisfied.

> **Safety posture.** All read-only steps (discovery, validation, reporting) can run any time. Every state-changing step happens only inside an approved maintenance window (GR4), against the readiness device group (R10), with a documented rollback (GR7), and after a successful test-device run (GR6). Remediation tooling defaults to `-WhatIf`; it changes nothing until you pass `-Apply`.

---

## Phase 1 — Assess

Goal: know exactly what is in scope and where every device stands against the readiness standard. Assume nothing is ready.

### Step 1.1 — Confirm scope and build the in-scope inventory (R1)

1. Get the activation's scope from the Epic program: which units, floors, departments, or facility, and the activation date/time.
2. In **Microsoft Intune admin center > Devices > All devices**, filter to the scope (by group, OU, naming, or tag) and export the list.
3. Reconcile that list against the asset/CMDB list and a physical floor walk of the activation area. Resolve every discrepancy (in Intune but not on the floor; on the floor but not in Intune).
4. Record the agreed denominator — the count the go/no-go gate will report against.

### Step 1.2 — Capture the readiness snapshot

1. Connect to Microsoft Graph and run **`EPICGOLIVE-Discovery.ps1`** scoped to the inventory. It produces a fleet readiness snapshot: per device, the enrollment state, compliance state, OS build, detected Epic client version, Imprivata agent presence, and last check-in — all read-only.
2. Save the snapshot as the **before** baseline (it also serves the GR7 rollback baseline).

### Step 1.3 — Define / confirm the readiness standard (R2)

1. Confirm the **Endpoint Readiness Checklist – Clinical Fleet – Pre-Go-Live** exists and carries the environment-specific values supplied by the Epic program / Epic TS:
   - exact target **Epic client version** string;
   - required **printers / print pathway** per device class;
   - required **peripherals** per device class;
   - **Imprivata tap-and-go** required (yes/no) per device class;
   - maximum acceptable **login time** (seconds) per device class;
   - required **compliance policy** / enrollment state.
2. Map each device class in the inventory to a checklist profile.

### Step 1.4 — Gap analysis

1. Compare the snapshot (1.2) to the standard (1.3). Produce the gap list: not-enrolled, non-compliant, wrong Epic version, missing Imprivata agent, etc.
2. This gap list drives Phase 2. Track it in the same place the go/no-go gate will read from.

### Step 1.5 — Create the readiness device group (R10)

1. In **Microsoft Entra admin center > Groups > New group** (or **Intune > Groups**), create **Readiness Device Group – Clinical Fleet – Validation** (name verbatim).
2. Populate it from the inventory — a dynamic membership rule on the in-scope tag/attribute, or assigned membership for a fixed list.
3. Preview and manage membership with **`EPICGOLIVE-Set-ReadinessGroup.ps1 -WhatIf`**; confirm the preview matches the inventory before applying.

---

## Phase 2 — Prepare / Remediate

Goal: close every gap from Phase 1 so the fleet can pass validation. All actions are scheduled into maintenance windows, tested first, and reversible.

### Step 2.1 — Remediate enrollment and compliance (R8)

1. Review compliance failures in **Microsoft Intune admin center > Devices > Compliance** for the readiness group, and the Conditional Access impact under **Devices > Conditional access**.
2. Run **`EPICGOLIVE-Remediation.ps1`** (default `-WhatIf`) to preview the safe, supported remediation actions per device (e.g., re-sync, re-evaluate compliance, trigger enrollment follow-up). Review the plan.
3. On the test device (GR6), run with `-Apply`; confirm the device becomes enrolled/compliant.
4. In an approved window, run with `-Apply` against the readiness group. Re-run `EPICGOLIVE-Discovery.ps1` to confirm.

### Step 2.2 — Deploy the correct Epic client version (R3)

1. Using the **Epic client deployment solution** (referenced — deep packaging/ring config lives there), deploy the designated client version to the readiness group.
2. Track deployment under **Microsoft Intune admin center > Apps > Monitor > App install status**.
3. Re-run `EPICGOLIVE-Discovery.ps1`; confirm every device reports the exact designated version.

### Step 2.3 — Fix printing (R4)

1. Confirm each device has the required printers/pathway from the checklist. Coordinate the print-routing configuration with the print-server / Epic print team.
2. Perform a test print per device class through the intended pathway (label/wristband, document, specialty).
3. Record the print pathway in the readiness checklist so the triage runbook (Step 4.3) can reference it.

### Step 2.4 — Fix peripherals (R5)

1. For each device class, confirm the expected peripheral set enumerates and functions (scan a barcode, tap a badge, sign a pad).
2. Attach/replace missing or faulty peripherals; install/confirm drivers or the driver package.
3. Re-test until each device's expected peripheral set is complete.

### Step 2.5 — Confirm Imprivata tap-and-go (R6)

1. Confirm the Imprivata agent is installed and healthy on each device that requires tap-and-go (deep OneSign config lives in the referenced Imprivata solution).
2. Perform a badge-tap test; confirm fast user switching / proximity behavior matches policy.
3. Confirm the documented manual-login fallback works (the triage runbook depends on it).

### Step 2.6 — Address login-time outliers (R7)

1. Measure login time on representative devices per class. For any device/class over target, investigate the dominant contributor (profile size, startup apps, login scripts, GPO processing, antivirus scope, device RAM/disk).
2. Remediate and re-measure until within target. Flag persistent outliers for the go/no-go gate.

---

## Phase 3 — Validate (go/no-go)

Goal: prove readiness with evidence and convert it to a documented go/no-go recommendation.

### Step 3.1 — Run the validation sweep

1. Run **`EPICGOLIVE-Validation.ps1`** against the readiness group. For each device it returns a **PASS/FAIL** against the readiness checklist criteria: Epic version correct, enrolled+compliant, Imprivata present, peripherals enumerated, plus the data points feeding printing and login-time checks.
2. Re-run as needed after late fixes; the sweep is read-only and idempotent.

### Step 3.2 — Produce the readiness scorecard

1. Run **`EPICGOLIVE-Report.ps1`** to roll the validation results into the **Readiness Scorecard – Clinical Fleet – Validation** and export to CSV: per-device PASS/FAIL with reasons, and rolled-up percentages by device class, unit, and overall.
2. Confirm the export contains only device/posture metadata (no ePHI — GR3).

### Step 3.3 — Walk the go/no-go gate (R11)

1. Convene the go/no-go review at the scheduled time with the named decision authority.
2. Walk the **Go/No-Go Gate – Endpoint Domain – Activation** against the scorecard:
   - Is the percent of in-scope devices at PASS at or above the defined threshold?
   - Are there **zero unresolved safety-critical failures** (e.g., wristband printing on the affected unit, tap-and-go for med admin)?
   - Are remaining FAILs documented with owner, fix plan, and risk?
3. Record the recommendation: **Go**, **Conditional-Go** (with tracked conditions carried into hypercare), or **No-Go** (with the gap that must close). Capture who decided and when.

---

## Phase 4 — Command Center (hypercare)

Goal: run the activation floor — triage at clinical speed, escalate cleanly, communicate clearly.

### Step 4.1 — Stand up the command center (R9)

1. Activate the **Command Center Roster – Endpoint Support – Hypercare**:
   - **Command-center lead** — owns the endpoint domain on the floor; the single point for the Epic program.
   - **Dispatcher(s)** — receive issues (ticket queue, phone, radio/chat), classify, and assign to the right tier/walker; track time-to-resolve.
   - **Tier-1 at-the-elbow (ATE) / floor walkers** — physically on the units; run the triage runbook for common issues.
   - **Tier-2 endpoint engineers** — handle issues the runbook escalates (imaging, complex peripheral/print, deeper SSO).
   - **Tier-3 / vendor & application liaisons** — bridge to Epic application, Imprivata, network, and print teams.
2. Confirm support **tiers** and the **dispatch model**: how an issue flows from report → dispatcher → ATE → Tier-2 → Tier-3, with target response times per tier.
3. Set the at-the-elbow coverage map: which walker covers which unit/shift, including nights and weekends.

### Step 4.2 — Activate comms and escalation (R9)

1. Stand up the **Comms & Escalation Plan – Endpoint Domain – Activation**:
   - The dispatch channel (ticket queue + real-time chat/radio bridge).
   - A scheduled **status cadence** (e.g., huddles at shift change) reporting endpoint ticket volume, top issues, and trends to the Epic program.
   - The **escalation ladder**: ATE → command-center lead → Epic program; and the cross-team path to application/Imprivata/network/print Tier-3.
   - Clear criteria for what is **safety-critical** and gets immediate top-of-ladder escalation.

### Step 4.3 — Run the rapid-fix triage runbook

Use the **Rapid-Fix Triage Runbook – Day-1 Endpoint – Hypercare** for the high-volume problems. Each entry below is a quick-fix path; deep diagnostics are in `06-troubleshooting.md`.

**A. Login / SSO failure (tap doesn't log in)**
1. Confirm the badge reader is connected and lit; re-tap.
2. Confirm the Imprivata agent is running (tray/health); restart it if hung.
3. Fall back to **manual credential login** so the clinician can work *now*; log the device for Tier-2.
4. If many devices on one unit fail at once, escalate as a possible Imprivata/network event (don't fix device-by-device).

**B. Printing failure (wristband/label/document won't print)**
1. Confirm the printer is powered, online, and has media; clear any error.
2. Confirm the device has the correct printer mapped (per the checklist print pathway); re-add if missing.
3. Print a test page through the intended pathway; if it fails server-side, escalate to print/Epic print Tier-3.
4. For wristband/safety printing, treat as **safety-critical** — escalate immediately if not resolved in minutes.

**C. Device not enrolled / non-compliant (can't reach Epic)**
1. Confirm the device is the expected managed device and is checked-in (have Tier-2 verify in Intune).
2. Trigger a sync / re-evaluate compliance; for a quick fix, run `EPICGOLIVE-Remediation.ps1 -Apply` against that device.
3. If it cannot be brought compliant quickly, **swap in a known-good ready device** so care continues; remediate the failed device off the floor.

**D. Slow performance / slow login**
1. Check for an obvious local cause (low disk, runaway process, pending reboot); reboot if appropriate.
2. Compare against peers on the same unit — if widespread, escalate as a back-end/resource event, not a per-device fix.
3. For a single slow device, swap in a ready spare and send the slow device to Tier-2.

### Step 4.4 — Keep the picture current

1. The dispatcher maintains live counts by problem type; re-run `EPICGOLIVE-Report.ps1` periodically to track the fleet's readiness/posture during hypercare.
2. Feed recurring/new issues back into the triage runbook so the next shift inherits the fix.

---

## Phase 5 — Stabilize / Handover

Goal: retire the command center on defined criteria and hand a documented environment to steady-state ownership.

### Step 5.1 — Measure against exit criteria (R12)

1. Track the **Hypercare Exit Criteria – Endpoint Domain – Handover** — e.g., endpoint ticket volume below the threshold for N consecutive days, no open safety-critical endpoint issues, all conditional-go conditions closed, knowledge transferred.
2. Review the criteria with service-desk leadership who will inherit ownership.

### Step 5.2 — Execute the handover

1. Assemble the handover package: open items with owners, known issues and workarounds, the updated triage runbook, the final readiness scorecard, and the as-built notes (final Epic client version, print pathway, Imprivata state).
2. Walk the service desk through the package and the top recurring issues; confirm they can run the relevant triage steps.
3. Transfer ownership of the readiness device group and the standing tooling/reports.

### Step 5.3 — Retire and capture lessons

1. Formally stand down the command center on the decision authority's sign-off.
2. Run a brief retrospective; capture what to change for the next wave/site/upgrade. The artifacts (checklist, gate, roster, runbook, scorecard) are reusable — update them with what you learned so the next activation starts ahead.
