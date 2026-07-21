# 3. Implementation — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. The design is: **enable Endpoint Analytics, assign a named
data-collection policy to a scoped pilot group, let devices report and set a baseline, interpret each
score and its sub-signals, build a prioritized remediation backlog, then expand to the fleet.** Pilot
first: **Assess → Configure → Pilot → Validate → Expand.**

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`

> **Portal wording changes.** Intune blade and node names (e.g. **Reports → Endpoint analytics**, the
> **Settings**/data-collection sub-page, score tab names) are given as they commonly appear, but
> **verify the current navigation against Microsoft documentation** before relying on an exact label.
> The **concepts and order** below are stable; the **exact labels** are the part to confirm.

> **National clouds:** if you are in GCC High / DoD, use your cloud's portal
> (e.g. `endpoint.microsoft.us`) and **verify feature availability against Microsoft's US-sovereign-cloud
> documentation** (Requirement R10) — the steps are the same in shape but endpoints/parity can differ.

---

## Phase 1 — Assess & scope

### Step 1. Confirm Endpoint Analytics is licensed and the node loads
1. In the Intune admin center, go to **Reports → Endpoint analytics**.
2. Confirm the node opens without a licensing/entitlement block. If it is blocked, resolve licensing
   (Requirement **R1**) before continuing. **Verify the entitling SKUs against current Microsoft
   documentation.**

### Step 2. Create the pilot device group
1. Entra → **Groups → New group → Security**; **name it `EPA – Pilot Devices`** (mail nickname
   `epa-pilot-devices`).
2. **Membership type = Assigned.** Add a small, representative set of managed Windows devices (mix of
   models/roles) as members. *(This is the group the data-collection policy targets first.)*
3. *(Later, in Phase 5, you create `EPA – Fleet Devices` for the whole managed estate.)*

---

## Phase 2 — Configure (enable data collection)

### Step 3. Enable Endpoint Analytics and create the data-collection policy
1. In Intune, go to **Reports → Endpoint analytics**.
2. Open the **Settings** (data collection) area for Endpoint Analytics. **Confirm the current
   Settings/data-collection blade name against Microsoft documentation** — wording varies.
3. **Enable** Endpoint Analytics data collection. When prompted to choose what to collect, enable the
   score areas you intend to use (Startup performance, Application reliability, Work-From-Anywhere,
   Resource performance). **Confirm the current toggle set against Microsoft documentation.**
4. Create/assign the data-collection policy and **name it `EPA – Data Collection – Pilot`**.
5. **Assignments:** assign `EPA – Data Collection – Pilot` to **`EPA – Pilot Devices`** (Step 2) →
   **Save**.

> Prefer automation? Run **`ENDPTAN-Set-DataCollection.ps1`** to create/assign the
> `EPA – Data Collection – Pilot` policy to `EPA – Pilot Devices`. It **defaults to `-WhatIf`** (preview
> only) — re-run without `-WhatIf` to apply. **Verify the exact Graph resource/settings against current
> Microsoft documentation**, as the data-collection object can change.

### Step 4. Ensure diagnostic-data settings permit collection
1. Confirm the pilot devices' Windows **diagnostic data** is at the level Endpoint Analytics requires
   (Requirement **R6**). **Confirm the exact required level against Microsoft documentation.**
2. If needed, create a configuration profile to set it and **name it `EPA – Diagnostic Data – Pilot`**:
   **Devices → Configuration → Create → New policy → Windows 10 and later → Settings catalog**;
   add the diagnostic-data setting Microsoft documents for Endpoint Analytics; **name it as above**;
   **Assign** to **`EPA – Pilot Devices`** → **Create**.

### Step 5. Confirm the telemetry endpoints are reachable
1. From a pilot device (or via your proxy/firewall team), confirm outbound access to the Microsoft
   diagnostic-data + Intune endpoints (Requirement **R7**). **Get the current endpoint list from
   Microsoft's published documentation.**
2. If blocked, allow the published ranges before expecting scores — blocked endpoints are the most
   common cause of permanently blank scores.

---

## Phase 3 — Pilot (let data flow, set a baseline)

### Step 6. Let the pilot devices report
1. Leave the pilot devices powered on and connected through at least one full **collection window**.
   Scores are **not instant** — allow the time Microsoft documents before expecting populated data.
   **Confirm the current expected timing against Microsoft documentation.**
2. Force a device sync if you want to hurry policy delivery: **Intune → Devices → (device) → Sync**
   (this speeds *policy* delivery, not the analytics collection window).

### Step 7. Confirm data is flowing
1. Run **`ENDPTAN-Test-DataFlow.ps1`** to confirm the pilot devices are reporting (read-only), and/or
2. In **Reports → Endpoint analytics**, confirm the pilot devices appear and scores begin to populate.
   If nothing appears after the documented window, go to Troubleshooting (§6).

### Step 8. Establish the pilot baseline
1. In **Reports → Endpoint analytics → Settings** (baselines), select or confirm the **baseline** to
   measure against. Start with a **pilot baseline**; you can also compare against the Microsoft-published
   **"all organizations" median** baseline. **Confirm the current baseline UI/wording against Microsoft
   documentation.**
2. Record the pilot baseline scores (use `ENDPTAN-Report.ps1`, Step 13) so later improvement is provable.

---

## Phase 4 — Validate (read each score and its sub-signals)

Read each score at a working level. For the **Application/Device reliability** deep-dive (anomaly
detection, crash/hang root-cause), use the companion product **Anomaly Detection & Application
Reliability with Endpoint Analytics (#3)** — this guide reads the score but does not reproduce that
analysis.

### Step 9. Read the Startup performance score
1. Open the **Startup performance** score. Note the overall score vs. the baseline.
2. Drill into the **sub-signals** — core boot time, sign-in time, time to a responsive desktop, and the
   contributing factors (**Group Policy / configuration processing time, startup apps, disk type,
   drivers/firmware**). **Confirm the current sub-metric names against Microsoft documentation.**
3. Write down the top contributors (e.g. "sign-in dominated by config processing," "spinning disks on
   model X") — these become backlog items in Step 12.

### Step 10. Read the Application reliability score
1. Open the **Application reliability** score. Identify apps with the highest **crash/hang** impact,
   the devices they affect, and usage counts (to separate broad pain from a one-off).
2. Note the worst offenders for the backlog. *(For a full reliability/anomaly investigation, use
   companion product #3 — do not attempt the deep root-cause here.)*

### Step 11. Read the Work-From-Anywhere and Resource performance scores
1. **Work-From-Anywhere:** open the WFA score and note the readiness sub-signals — **cloud identity
   (Entra-joined), cloud management (Intune/co-managed), Windows edition/version currency, Autopilot,
   and TPM/hardware readiness**. Note which factor is dragging the score down.
2. **Resource performance:** open the Resource performance score and note **CPU** and **RAM** pressure
   — flag under-spec'd or over-loaded devices.
3. **Confirm the current sub-signal names/thresholds against Microsoft documentation.**

---

## Phase 5 — Build the backlog, then expand

### Step 12. Build the prioritized remediation backlog
1. From the sub-signals in Steps 9–11, assemble a single **prioritized backlog** — highest-impact,
   lowest-effort first. Group items by lever:
   - **Policy/config** (e.g. reduce Group Policy processing time, trim startup apps).
   - **Apps** (address the worst crash/hang apps — hand to reliability deep-dive #3 if needed).
   - **Drivers/firmware** (update outdated drivers dragging startup).
   - **Hardware/edition** (disk upgrades, RAM, Windows edition currency for WFA).
2. For items you will fix **at scale with detection/remediation scripts**, hand them to the companion
   product **Proactive Remediations at Scale — Detection & Remediation Script Packs for Microsoft
   Intune (#2)**, which is the engine for authoring and deploying those script pairs. *(This guide
   builds the backlog; #2 builds and runs the remediation script packs.)*
3. Record the backlog with each item's score area, contributing sub-signal, target, and owner.

### Step 13. Report and record the baseline + backlog
1. Run **`ENDPTAN-Report.ps1`** to export a CSV summary of the scores/sub-signals for your records and
   for stakeholder reporting. Keep it alongside the pilot baseline from Step 8.

### Step 14. Create the fleet group and expand data collection
1. Entra → **Groups → New group → Security**; **name it `EPA – Fleet Devices`** (mail nickname
   `epa-fleet-devices`). Add the full managed Windows estate (or use a dynamic device group keyed on
   your management/OS criteria).
2. In **Reports → Endpoint analytics** data-collection settings, **add `EPA – Fleet Devices`** to the
   assignment of the data-collection policy (rename the policy to `EPA – Data Collection` if you prefer
   a fleet-wide name, and update the diagnostic-data profile assignment to match).
3. Let the fleet report through a collection window, then establish the **fleet baseline** (Step 8,
   applied fleet-wide).

### Step 15. Operationalize the improvement loop
1. Set a **review cadence** (e.g. monthly): re-read each score against the baseline, refresh the backlog,
   and confirm remediated items moved the score.
2. Feed backlog items to **Proactive Remediations (#2)** for scaled fixes and to the **reliability/
   anomaly deep-dive (#3)** for app reliability investigations.
3. Re-run `ENDPTAN-Report.ps1` each cycle to show the trend — the delta from baseline is your proof of
   improvement.
