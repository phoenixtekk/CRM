# 3. Implementation Guide — Endpoint Health & Digital Experience Monitoring

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).
Navigation for the dashboard is `Reports → Endpoint analytics`.

> **Model:** Enable Endpoint analytics, onboard a small **pilot**, let it collect a **baseline**,
> interpret the scores, wire **proactive remediations** for common issues, validate, then expand to
> the fleet. The pilot's baseline period is the gate.

> **Naming:** every object is named `<Purpose> – <Scope> – <Stage>`. Reuse the names below verbatim.

## Step 1 — Enable Endpoint analytics
1. Go to `Reports → Endpoint analytics`.
2. On the **Overview** tab, select **Start** (first run only). This enables the capability.
3. Open the **Settings** tab and confirm the data source includes **Intune enrolled devices** (add
   **Configuration Manager** devices only if you use co-management).
4. Leave the default startup-performance data collection on. Endpoint analytics begins collecting
   from enrolled devices.

## Step 2 — Create the pilot group
1. Entra → **Groups → New group → Security**.
2. **Name:** `Endpoint Analytics – Pilot Devices – Monitoring`. Add a few representative devices
   (mix of models). **Create**.
3. (Optional, for later) create `Endpoint Analytics – All Windows – Monitoring` for the broad scope —
   or use the script `EHEM-Set-MonitoringScopeTargeting.ps1` to build it.

## Step 3 — Confirm device data collection
1. In `Reports → Endpoint analytics → Settings`, confirm devices are enrolling for analytics.
2. On a pilot device, run `EHEM-Validation.ps1` to confirm the device is reporting and diagnostic
   data is at the required level.
3. If devices are not appearing, ensure they are enrolled and have synced (`EHEM-Remediation.ps1`
   can force a sync).

## Step 4 — Let the pilot collect a baseline
1. Allow the **baseline period** (typically several days) for the pilot devices to report.
2. Watch device counts climb in **Startup performance**, **Application reliability**, and
   **Resource performance**.
3. Do not judge scores until enough data has accrued — this warm-up is the pilot gate.

## Step 5 — Interpret the scores
1. **Overview** — read the overall Endpoint analytics score (0–100) and the four sub-scores.
2. **Startup performance** — sort by **Core boot time** and **Core sign-in time**; note the slowest
   models and devices.
3. **Application reliability** — review the least reliable apps (crashes/hangs) across the pilot.
4. **Resource performance** — find devices with high CPU/RAM spike time (under-resourced hardware).
5. **Work from anywhere** — review cloud-management and Autopilot readiness gaps.
6. Run `EHEM-Report.ps1` to pull the same scores and the top issues into a summary you can share.

## Step 6 — Wire proactive remediations for common issues
1. Go to `Reports → Endpoint analytics → Proactive remediations → Create script package`.
2. **Name:** `Proactive Remediation – Restart Stale Devices – Pilot` (this example nudges devices
   that have not restarted in N days — a frequent cause of slow, flaky endpoints).
3. Upload a **detection** script and a **remediation** script (Microsoft publishes sample packages;
   start from those, or use your own tested scripts). Set **Run this script using the logged-on
   credentials** as appropriate and **Enforce script signature check** per your policy.
4. **Scope tags / Assignments → Add groups →** `Endpoint Analytics – Pilot Devices – Monitoring`. Set
   the schedule (e.g. daily). **Create**.
5. Repeat for other common issues you found in Step 5 (e.g. clear temp files, reset a stuck service),
   each named `Proactive Remediation – <Issue> – Pilot`.

## Step 7 — (Optional) Integrate a dedicated DEX platform
1. Only if Step 5 shows you need deeper telemetry than Endpoint analytics provides, and you have
   licensing (Requirement 2.8).
2. Follow the **vendor's own documentation** (Nexthink, Tanium, etc.) to deploy the collector to a
   pilot group and stand up its console. Vendor-specific steps are intentionally out of scope here —
   use the vendor's deployment guide.
3. Keep Endpoint analytics running alongside it; treat the dedicated platform as additive.

## Step 8 — Validate the pilot
1. Run `EHEM-Validation.ps1` on pilot devices → confirms they are reporting for analytics.
2. Run `EHEM-Report.ps1` → confirms scores and the top issues are populated.
3. Confirm each proactive remediation shows **run history** with detections and successful fixes in
   `Proactive remediations → (package) → Device status`. Complete the **Testing Guide**.

## Step 9 — Expand to production
1. Re-point (or re-create) the proactive remediation assignments to
   `Endpoint Analytics – All Windows – Monitoring` once the pilot passes.
2. Continue to monitor the overall score trend; chase the worst models/devices.
3. Re-validate each cycle with `EHEM-Report.ps1`; add new remediation packages as new common issues
   emerge.

---
### Order of operations
`Enable analytics → pilot group → confirm data collection → baseline period → interpret scores → proactive remediations → (optional DEX platform) → validate → expand`
