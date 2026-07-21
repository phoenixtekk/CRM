# 3. Implementation — Anomaly Detection & Application Reliability with Endpoint Analytics

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. This solution is about **reading the reliability signals
and acting on them** — it assumes Endpoint Analytics is already enabled and collecting data (the
**parent** solution, *"Endpoint Analytics Deployment & Optimization in Microsoft Intune,"* does that).
Pilot first: **Assess → Configure → Pilot → Validate → Expand.**

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com` (Endpoint analytics lives here)
- **Microsoft Entra admin center** — `https://entra.microsoft.com`

> **Navigation accuracy.** Endpoint Analytics report names, blade locations, tabs, and the exact place
> anomaly detection appears **change over time and can differ by cloud (Commercial vs. GCC / GCC High /
> DoD)**. Wherever this guide names a portal path or a report, treat the *path* as **"verify against
> current Microsoft documentation"** and confirm it in your own tenant — the **practice** (what to read
> and what to do) is what matters and does not change.

> **Object names — create them exactly as written and reuse them verbatim** in every later step, the
> Testing guide, the Troubleshooting guide, and the scripts:
> - Entra security group **`Reliability – Pilot`** — the small pilot scope for this practice.
> - Entra security group **`Reliability – Review Scope`** — the ongoing review population (created by
>   `ENDPTREL-Set-ReviewScope.ps1` in the Expand phase).
> - Exported report file convention **`Reliability Review – <YYYY-MM>.csv`** — the monthly reliability
>   export produced by `ENDPTREL-Report.ps1`.
> - Handoff label convention **`Reliability Handoff – <App|Driver|Update> – <Version>`** — the ticket/
>   work-item label used when routing a fix to an owner or to the automated-fix companion.

---

## Phase 1 — Confirm reliability data is flowing (Assess)

### Step 1. Confirm Endpoint Analytics reliability data is populating
1. In the Intune admin center, open **Endpoint analytics**. *(Exact left-nav location — verify against
   current Microsoft documentation.)*
2. Confirm the **Application reliability** report and the **device reliability / restart** report show
   data and a device count consistent with your fleet — not "still collecting," empty, or a handful of
   devices.
3. If the reports are empty or thin, **stop** and finish the **parent** solution first (enable Endpoint
   Analytics, deploy the data-collection policy, onboard devices) and allow the reporting window to
   fill. *(Data latency and minimum device population — verify against current Microsoft
   documentation.)*
4. For a scripted readiness read, run **`ENDPTREL-Discovery.ps1`** (read-only): it reports reliability-
   data availability, the scoped device count, and the top unreliable apps/devices it can see.

### Step 2. Create the pilot review scope
1. Entra → **Groups → New group → Security**; **name it `Reliability – Pilot`**.
2. Add a small, representative set of in-scope devices (a cross-section of hardware models and app
   versions so the pilot exercises real triage). *(This group is a **subset** of what Endpoint
   Analytics is collecting — see Requirements R5.)*
3. You will use `Reliability – Pilot` to rehearse the read-triage-route loop before running it against
   the whole fleet.

---

## Phase 2 — Read application reliability & separate bad-app from bad-rollout (Configure)

### Step 3. Read the application reliability report
1. In **Endpoint analytics**, open **Application reliability**. *(Exact name/location — verify against
   current Microsoft documentation.)*
2. Review the apps ranked by their reliability signal (crashes/hangs and the number of devices/users
   affected). Note the **worst few apps** and, where the report exposes it, the **version** dimension.
3. Record the candidates you'll triage — app name, version if shown, affected device/user count — using
   the export from **`ENDPTREL-Report.ps1`** (writes `Reliability Review – <YYYY-MM>.csv`).

### Step 4. Classify each candidate — bad app vs. bad rollout
For each app flagged in Step 3, decide which of these it is (Solution Overview has the full logic):
1. **Bad app** — elevated crashes/hangs spread across a **broad, mixed** population (many models, many
   OS builds); the common factor is the app itself. → Plan to **fix/update/roll back the app/version**;
   the owner is the **app owner**.
2. **Bad rollout** — the spike is **concentrated** in the population that recently received a new app
   **version** or configuration, and started **right after** that change. The common factor is the
   change event. → Plan to **pause/stage/roll back the deployment**; the owner is the **deployment
   owner**.
3. Confirm the split by checking the **version** breakdown: if one version is bad and the previous
   version is fine, it's a **bad version/rollout**; if all versions crash across the board, it's a
   **bad app**.
4. Run **`ENDPTREL-Test-Signal.ps1`** (read-only) against a known-bad app to confirm the signal is
   **visible and attributable** to the app/version before you act on it.

---

## Phase 3 — Read device reliability & restart analytics (Configure)

### Step 5. Read the device reliability / restart report
1. In **Endpoint analytics**, open the **device reliability / restart** report. *(Exact report name —
   many tenants show this as a restart-frequency / device-reliability view; verify against current
   Microsoft documentation.)*
2. Review restart **causes** (planned vs. **unexpected** / stop-error) and the **unexpected-restart
   trend** over time.
3. Look at the trend two ways:
   - **Fleet-wide** rise → suspect a broadly deployed change (an **OS update**).
   - **Model-scoped** rise (one hardware model spiking while others are flat) → suspect a
     **driver/firmware** regression on that model.

### Step 6. Attribute a restart spike to an update or a driver
1. Note **when** the unexpected-restart trend rose and **which cohort** it hit (whole fleet vs. a
   model).
2. Line that start time up against your change calendar — an **OS update ring**, a **driver/firmware**
   push, or a **configuration** change deployed around then.
3. Decide the owner: fleet-wide-after-update → **update owner**; single-model → **hardware/driver
   owner**.
4. Where the mitigation is **scriptable** (roll back a driver, apply a registry/config fix, pause an
   update ring), plan to hand it to the **automated-fix companion** (Step 9).

---

## Phase 4 — Use anomaly detection to catch a regression early (Pilot)

### Step 7. Read anomaly detection
1. In **Endpoint analytics**, open the **anomaly detection** view. *(Availability, exact name, and
   whether it's preview or GA — **verify against current Microsoft documentation** for your cloud; if
   it isn't available, skip to Step 8 and rely on the reliability trends.)*
2. For each anomaly, read the three things that make it actionable:
   - **Which metric** moved (crashes, hangs, unexpected restarts, a reliability measure).
   - **Which cohort** it affects (a device model, an app version, an OS build).
   - **When it started** — the start time is your correlation anchor to a change event.
3. **Confirm it's real, not a false signal:**
   - **True anomaly:** correlates with a real change (a rollout, an update, a driver push), affects a
     meaningful cohort, and **persists** across the next data refresh. → Triage it.
   - **False signal:** transient, tiny/high-variance cohort, or coincides with a reporting gap, and
     **fades** on the next refresh. → Note it and move on; do not spend remediation effort.
4. Cross-check the anomaly against the underlying report (Step 3 or Step 5) — an anomaly should be
   visible as a real movement in application reliability or restart analytics, not only as an alert.

---

## Phase 5 — Triage, route, and close the loop (Validate)

### Step 8. Route each confirmed signal to its owner
1. For each confirmed bad-app / bad-rollout / restart-cause / anomaly, open (or update) a work item and
   label it **`Reliability Handoff – <App|Driver|Update> – <Version>`** (e.g. `Reliability Handoff –
   Contoso LOB App – 4.2.1`, or `Reliability Handoff – Display Driver – 31.0.15`).
2. Route to the owner you identified: **app owner**, **deployment owner**, **update owner**, or
   **hardware/driver owner**.
3. Include the evidence: the report screenshot/export row (`Reliability Review – <YYYY-MM>.csv`), the
   affected cohort, and the start time.

### Step 9. Hand scriptable fixes to the automated-fix companion
1. Where the fix is **scriptable and fleet-wide** — clear a bad cache, reset a service, remove/roll back
   a bad driver, repair a configuration — hand it to the **"Proactive Remediations at Scale"** solution
   (the **automated-fix companion**) rather than fixing devices by hand.
2. Give the companion the specifics the handoff item captured: the exact condition to **detect** (which
   app/version, which driver, which config) and the **remediation** to apply. *(Building the
   detection/remediation script pack itself is the companion's job — this solution defines **what** to
   fix and **who** owns it; it does **not** reproduce the companion's remediation model.)*
3. Target the companion's remediation at the affected cohort (align it with `Reliability – Review
   Scope`, or a tighter model/version group where appropriate).

### Step 10. Verify the signal recovers
1. After the owner ships the fix (app update/rollback, driver rollback, update-ring change, or the
   companion's remediation), watch the **same** report and any related anomaly across the next data
   refreshes.
2. **Close the loop** only when the signal recovers: crashes/hangs fall back to baseline, the
   unexpected-restart trend flattens, or the anomaly clears. Record the outcome on the handoff item.
3. Re-run **`ENDPTREL-Test-Signal.ps1`** against the previously-bad app/version to confirm the signal
   is no longer attributable at problem levels.

---

## Phase 6 — Establish the review cadence and expand (Expand)

### Step 11. Create the ongoing review scope group
1. Run **`ENDPTREL-Set-ReviewScope.ps1`** — the one state-changing script — to create/assign the Entra
   security group **`Reliability – Review Scope`** for the ongoing cadence. **It defaults to `-WhatIf`
   (preview only) and prints that it is doing so; re-run with `-Commit` (or `-WhatIf:$false`) to
   actually create/assign the group.**
2. Align `Reliability – Review Scope` with the population Endpoint Analytics is collecting (Requirements
   R5) so the cadence reviews exactly what's reporting.

### Step 12. Stand up the reliability review cadence
1. Establish a recurring **reliability review** (weekly or biweekly to start; monthly once steady).
   Book it as a standing meeting/checklist named **`Reliability Review – Weekly`** (rename to match your
   chosen frequency).
2. Each review runs the loop against `Reliability – Review Scope`:
   - Read **Application reliability** (Step 3–4) — any new bad app/version?
   - Read **device reliability / restart** (Step 5–6) — any restart trend rising?
   - Read **anomaly detection** (Step 7) — any new confirmed anomaly?
   - **Route** new confirmed signals (Step 8), **hand scriptable fixes** to the companion (Step 9), and
     **verify** last cycle's fixes recovered (Step 10).
   - Export the run with **`ENDPTREL-Report.ps1`** → `Reliability Review – <YYYY-MM>.csv` and keep it as
     the trend record.
3. Track **corrections-per-review over time** — a downward trend means the practice is preventing
   regressions instead of chasing them.

### Step 13. Expand from pilot to fleet
1. Once the loop is smooth on `Reliability – Pilot`, widen the cadence to `Reliability – Review Scope`
   (the fleet population).
2. Validate each widening with **`ENDPTREL-Validate.ps1`** (reliability signals present for the scope,
   anomaly detection active) before relying on the review at the new scope.
3. Keep the parent solution (data collection) and the automated-fix companion (remediation) in the loop
   as the two neighbors this practice depends on.
