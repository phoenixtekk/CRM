# Endpoint Analytics Deployment & Optimization in Microsoft Intune — Startup, Reliability & Work-From-Anywhere Scores

> **Version 1.0.0** · Category: Intune · Solution code: ENDPTAN

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Most endpoint teams have **no objective measure of the user experience**. They learn about slow boots,
crashing apps, and struggling remote laptops the same way every time — when the tickets pile up. There
is no baseline, no benchmark, and no way to prove whether last quarter's work actually made devices
faster or more reliable.

**Endpoint Analytics** is the fix: the **data plane Microsoft Intune uses to measure the real endpoint
experience** — Startup performance, Application + Device reliability, Work-From-Anywhere readiness, and
Resource performance, all **scored and benchmarked**. This solution deploys it end to end and turns the
data into action:

- **Turn it on, the right way** → enable Endpoint Analytics and assign a named **data-collection
  policy** to a scoped **pilot** group, so telemetry starts flowing before you touch the whole fleet.
- **Baseline and benchmark** → establish a pilot baseline, then a fleet baseline, and compare against
  the Microsoft-published "all organizations" median — so every later number means something.
- **Read every score, and the *why* under it** → interpret all four scores down to the sub-signals
  (the Group-Policy processing time, the crashing app, the outdated driver, the legacy Windows edition)
  that explain a low number.
- **Ship a prioritized backlog** → convert the worst offenders into a ranked remediation plan, then run
  a review cadence that re-measures against the baseline so improvement is provable.

Built the standard repeatable way — **Assess → Configure → Pilot → Validate → Expand** — with exact,
click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph, read-only plus one `-WhatIf`-gated
state-changer), and testing/troubleshooting guides with clear pass/fail gates.

This is the **flagship** of a three-product Endpoint Analytics set: it stands up, baselines, and
operationalizes Endpoint Analytics, then hands the two deep specialties to its companions — **Proactive
Remediations at Scale** to fix the backlog with detection/remediation script packs, and **Anomaly
Detection & Application Reliability** for the reliability and anomaly deep-dive.

**Outcome:** an Endpoint Analytics deployment that gives you an objective, benchmarked view of the
endpoint experience and a prioritized plan to improve it — managed by data instead of ticket volume, by
your own team, without a consulting engagement.


---


# 1. Solution Overview — Endpoint Analytics Deployment & Optimization in Microsoft Intune

## What this solution is
This solution turns on **Endpoint Analytics** — the **data plane Microsoft Intune uses to measure the
real endpoint experience** — and puts it to work end to end. Instead of learning about slow boots,
crashing apps, and struggling remote laptops only when the help desk gets buried, you get an
**objective, scored, benchmarked** view of how devices actually behave for the people using them, and
a **prioritized plan to improve it**.

Endpoint Analytics collects experience telemetry from your managed Windows devices, rolls it up into
a small set of **scores** (with the detailed **sub-signals** behind each), and compares those scores
against a **baseline** — your own historical baseline and the Microsoft-published "all organizations"
median. This package deploys that capability the standard, repeatable way — **Assess → Configure →
Pilot → Validate → Expand** — then teaches you to read each score, read the sub-signals under it, and
convert the worst offenders into a **remediation backlog** you can work down.

It delivers exactly what an endpoint team needs to run experience by data:

1. **Endpoint Analytics enabled** on the tenant, with a named **data-collection policy** assigned to a
   scoped device group so telemetry starts flowing.
2. **A baseline** — a pilot baseline first, then a fleet baseline — so every later number has
   something to be measured against.
3. **Every score interpreted** — Startup performance, Application + Device reliability, Work-From-
   Anywhere, and Resource performance — down to the sub-signals that explain *why* a score is low.
4. **A remediation backlog** — the low scores and their worst-contributing devices, apps, and drivers
   turned into a ranked, actionable list, plus a repeatable **review cadence** to keep improving.

## The four score areas (and what each measures)
Endpoint Analytics presents its data as a set of scores. Cover all four at a working level; the exact
score names, weightings, thresholds, and blades change over time, so treat the specifics as
**verify-against-current-Microsoft-documentation** and the concepts as durable.

- **Startup performance.** How long a device takes to become usable from power-on through to a
  responsive desktop — broken into phases (core boot, sign-in, and the time to a responsive desktop).
  The sub-signals point at what is slow: **Group Policy / configuration processing**, heavy **startup
  apps**, **disk type** (spinning vs. SSD), and outdated **drivers/firmware**. This is the flagship
  score most teams start with because slow logon is the most-felt pain.
- **Application reliability.** How reliably the apps people actually run stay up — surfacing apps with
  high **crash/hang rates**, the devices they crash on, and usage counts so you can tell a broadly
  painful app from a one-device fluke. *The deep reliability + anomaly analysis is the subject of the
  companion product — see "Where this fits" below.*
- **Work-From-Anywhere (WFA).** How ready your fleet is to be managed and secured from anywhere —
  a readiness roll-up over **cloud identity** (Entra-joined), **cloud management** (Intune/co-managed),
  **Windows edition/version currency**, **Autopilot** provisioning, and **TPM/hardware** readiness. It
  is less "how fast" and more "how modern and remote-ready."
- **Resource performance.** How hard devices are working — a spotlight on **CPU** and **RAM**
  pressure so you can spot under-spec'd or over-loaded machines that make the experience sluggish even
  when boot times look fine.

*Score names, exact sub-metrics, and thresholds evolve; confirm the current set in the Intune portal
and Microsoft documentation before quoting a specific number to stakeholders.*

## How baselining and benchmarking work
A raw score means little on its own — the value is in the comparison:

1. **Data collection starts the clock.** Once the data-collection policy is assigned and devices are
   reporting, Endpoint Analytics needs a **collection window** before scores populate (they do not
   appear instantly — see Troubleshooting). Confirm exact timing against current Microsoft docs.
2. **A baseline is captured.** Endpoint Analytics keeps a **baseline** you compare current scores
   against. You start with a **pilot baseline** (a small scoped group), then a **fleet baseline** once
   the whole managed estate is reporting. You can also compare against the **Microsoft-published
   "all organizations" median baseline** to see whether you are ahead of or behind the pack.
3. **Sub-signals explain the gap.** When a score sits below baseline, you drill into its sub-signals
   to find the *cause* — e.g. a low Startup score that is really a Group-Policy-processing problem, or
   a WFA score dragged down by devices still on a legacy Windows edition.
4. **Improvement is measured against the baseline.** After you act on the backlog, the score should
   move toward (and past) baseline — that delta is your proof the work paid off.

## The improvement loop
This is the operating rhythm the solution installs:

> **Baseline → interpret each score → drill to sub-signals → build a prioritized remediation backlog →
> remediate → re-measure against the baseline → repeat on a review cadence.**

Two of those steps have **dedicated companion products** so this flagship stays focused on deploying,
baselining, and interpreting rather than re-teaching the deep specialties:

## Where this fits — the Endpoint Analytics cluster (pointers, not repetition)
This is the **flagship** of a three-product Endpoint Analytics cluster. It covers all four scores at a
working level and hands off the two deep specialties to its siblings — **use those for depth; this
guide does not reproduce them**:

- **Proactive Remediations at Scale — Detection & Remediation Script Packs for Microsoft Intune (#2).**
  Endpoint Analytics surfaces *what* to fix; **Proactive Remediations** is the **engine that fixes it
  at scale** — authoring, packaging, scoping, and scheduling the detection/remediation script pairs
  that clear items off your backlog automatically. When this guide says "remediate the backlog item,"
  the *how* of building the script pack lives there.
- **Anomaly Detection & Application Reliability with Endpoint Analytics (#3).** This flagship reads the
  Application/Device reliability score at a working level; the **reliability and anomaly deep-dive**
  — interpreting crash/hang patterns, using anomaly detection to catch a bad app/update/driver rollout
  early, and running a reliability investigation to root cause — lives in that companion product.

Buy this one to **stand up, baseline, and operationalize** Endpoint Analytics; add #2 to **remediate
at scale** and #3 to **go deep on reliability and anomalies**.

## The standard deployment model
This solution uses **one** model so the process is repeatable across the catalog:

> **Enable Endpoint Analytics on the tenant, assign a named data-collection policy to a scoped pilot
> group, let devices report and establish a baseline, interpret each score and its sub-signals, turn
> the low scores into a prioritized remediation backlog, then expand from pilot to the whole fleet —
> improving on a review cadence.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**

## Benefits
- **Experience becomes measurable** — objective, scored, benchmarked numbers replace "it feels slow"
  and ticket volume as your signal.
- **You know *why*, not just *what*** — the sub-signals under each score point at the actual lever
  (policy, app, driver, disk, hardware, edition) so remediation is targeted.
- **A prioritized backlog, not a data dump** — the worst-scoring devices/apps/drivers become a ranked
  list your team can work down.
- **Proof of improvement** — every change is re-measured against the baseline, so you can show
  stakeholders the score moved.
- **Fleet-scale and repeatable** — assign the data-collection policy once to a group; add devices to
  the group and they start contributing. The same playbook runs on the next wave and the next project.
- **Composable with the cluster** — pairs with Proactive Remediations (#2) to fix at scale and with
  the reliability/anomaly deep-dive (#3) without re-buying overlapping content.

## Limitations (be honest with buyers)
- **Windows-focused.** Endpoint Analytics scores are centered on **managed Windows devices**; it is not
  a cross-platform experience score for iOS/Android/macOS. Confirm current platform support against
  Microsoft documentation.
- **Scores are not instant.** After you enable data collection there is a **collection window** before
  scores populate and a baseline forms — plan for it; don't declare failure on day one.
- **Licensing and feature availability can vary.** Endpoint Analytics availability and the specific
  features/scores you see depend on your licensing and tenant configuration — **verify against current
  Microsoft documentation** for your plan, and note that **national clouds (GCC, GCC High, DoD)** can
  differ in feature parity, rollout timing, and portal endpoints.
- **It measures and prioritizes; it does not fix by itself.** Turning a score up requires action —
  policy changes, driver updates, hardware refresh, or **Proactive Remediations (#2)** script packs.
  This product builds the backlog; remediation-at-scale is the sibling's job.
- **Data collection depends on connectivity and endpoints.** Devices must be able to reach the required
  Microsoft service endpoints to submit analytics data; blocked endpoints mean blank scores.


---


# 2. Requirements — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, supported OS, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to standing up
**Endpoint Analytics**, getting devices to report telemetry, baselining, and interpreting the scores.

> **Licensing, feature availability, and national-cloud specifics change.** Where this document names a
> license, a portal path, or a service endpoint, treat it as a starting point and **verify against
> current Microsoft documentation** for your plan and cloud (Commercial vs. GCC / GCC High / DoD)
> before you rely on it.

## R1. An Endpoint Analytics–capable license
**Description:** A Microsoft license/plan that includes **Endpoint Analytics** for your managed devices.
**Why:** Endpoint Analytics is a licensed Intune capability; without an entitling plan the node is
unavailable or limited.
**Verify:** In the Intune admin center, open **Reports → Endpoint analytics** and confirm the node
loads and is not blocked by a licensing message. **Verify the exact entitling SKUs against current
Microsoft documentation** — do not assume a specific bundle grants it.
**Implement:** Assign the entitling license (commonly delivered via Microsoft 365 / Intune plans —
**confirm the current requirement with Microsoft**) to the devices/users in scope, then re-open the node.

## R2. Devices enrolled / co-managed in Intune
**Description:** The Windows devices you want scored are **Intune-enrolled** or **co-managed**
(Configuration Manager + Intune).
**Why:** Endpoint Analytics collects its telemetry through the Intune management channel; only managed
devices report scores. (Co-managed devices can be onboarded via Configuration Manager — **verify the
current co-management onboarding path against Microsoft documentation**.)
**Verify:** Intune → **Devices → All devices**; the target Windows devices appear and are managed.
**Implement:** Enroll the devices in Intune (or onboard the Configuration Manager collection for
co-management) before expecting scores. See Global Requirement **G4**.

## R3. Supported, current Windows edition/version
**Description:** A supported Windows edition and version on the devices in scope.
**Why:** Startup performance, Work-From-Anywhere, and resource metrics assume a supported, patched
Windows build; unsupported builds report partial or no data and drag the WFA score down.
**Verify:** Intune → **Devices → (device) → Hardware** shows the edition/version; or check
**Settings → System → About** on the device. **Confirm the currently supported Windows versions for
Endpoint Analytics against Microsoft documentation.**
**Implement:** Bring devices to a supported Windows version with your update policy before baselining.

## R4. The Endpoint Analytics data-collection policy
**Description:** An Endpoint Analytics **data-collection policy** created in Intune and **assigned** to
the device group in scope.
**Why:** This policy is what tells enrolled devices to **collect and submit** the experience telemetry
that produces the scores. No assigned data-collection policy → no data → blank scores.
**Verify:** Intune → **Reports → Endpoint analytics → Settings** (data collection) shows collection
configured and assigned to your scope group. **Confirm the current Settings/blade name against Microsoft
documentation** (portal wording changes).
**Implement:** Create and assign it in Implementation §3 (**named `EPA – Data Collection – Pilot`**),
or run `ENDPTAN-Set-DataCollection.ps1` (defaults to `-WhatIf`).

## R5. A scoped device group (pilot, then fleet)
**Description:** A Microsoft Entra security group of the Windows devices to collect from — a small
**pilot** group first, then a **fleet** group.
**Why:** The data-collection policy is assigned to a group; piloting to a small group first proves data
flows and lets you read a baseline before you turn on the whole estate.
**Verify:** Entra → **Groups**; `EPA – Pilot Devices` exists with the pilot devices as members.
**Implement:** Create it in Implementation §2. (See Global Requirement **G5** for the pilot-group pattern.)

## R6. Telemetry / diagnostic data settings permit collection
**Description:** Windows **diagnostic data** settings on the devices allow Endpoint Analytics to collect
what it needs.
**Why:** Endpoint Analytics depends on Windows telemetry; if diagnostic data is turned off or set below
the level the feature requires, devices will not report complete scores.
**Verify:** Check the device's diagnostic-data configuration (via your configuration profiles or
**Settings → Privacy & security → Diagnostics & feedback**). **Confirm the exact diagnostic-data level
Endpoint Analytics requires against current Microsoft documentation** — do not hard-code a level.
**Implement:** Assign a configuration profile that sets diagnostic data to the level Microsoft currently
documents for Endpoint Analytics, to the same scope group.

## R7. Network access to the analytics/telemetry endpoints
**Description:** Outbound HTTPS from managed devices to the Microsoft **Intune** service endpoints
**and** the **Windows diagnostic-data / Endpoint Analytics telemetry endpoints**.
**Why:** Devices submit their experience telemetry to Microsoft's service; if the telemetry endpoints
are blocked at the proxy/firewall, scores stay blank even though the policy is assigned.
**Verify:** From a managed device, confirm reachability of the Microsoft telemetry/diagnostic endpoints
and the Intune endpoints. **Get the current endpoint list from Microsoft's published documentation** —
the diagnostic-data endpoints are a distinct set from the core Intune URLs.
**Implement:** Allow the Microsoft-published diagnostic-data + Intune endpoint ranges through
proxy/firewall. See Global Requirement **G7**.

## R8. Administrative rights to Endpoint Analytics
**Description:** An operator with rights to read Endpoint Analytics reports and to create/assign the
data-collection and configuration policies.
**Why:** Enabling data collection and creating policies requires Intune administrative permissions;
reading scores requires at least reporting access.
**Verify:** Sign in to Intune and confirm you can open **Reports → Endpoint analytics** and create
policies under **Devices → Configuration**.
**Implement:** Assign the operator **Intune Administrator** (or a suitable Endpoint Analytics/reporting
role — **verify the current role names and scopes against Microsoft documentation**). See Global
Requirement **G3**.

## R9. (If co-managed) Configuration Manager onboarding for Endpoint Analytics
**Description:** For **co-managed** devices, the Configuration Manager side is onboarded to Endpoint
Analytics.
**Why:** Co-managed devices can contribute Endpoint Analytics data via Configuration Manager; this
requires the ConfigMgr environment to be connected/onboarded.
**Verify:** In the Configuration Manager console, confirm Endpoint Analytics onboarding is configured.
**Confirm the current co-management onboarding steps and prerequisites against Microsoft documentation.**
**Implement:** Onboard Configuration Manager to Endpoint Analytics per Microsoft's current guidance
(cloud attach / co-management), then confirm the collection is reporting.

## R10. National-cloud confirmation (GCC / GCC High / DoD)
**Description:** If you operate in a **US-sovereign / national cloud**, confirm Endpoint Analytics
availability, feature parity, and the correct portal/service endpoints for that cloud.
**Why:** Feature availability, rollout timing, and endpoint URLs can differ between Commercial and
Government clouds; a Commercial procedure can be wrong for GCC High/DoD.
**Verify:** Confirm the Endpoint Analytics feature set and the correct admin portal
(e.g. `endpoint.microsoft.us` for some Government tenants) **against Microsoft's US-sovereign-cloud
documentation** — do not assume Commercial parity.
**Implement:** Use the national-cloud portal and endpoint set Microsoft documents for your cloud;
where a capability is delayed or absent, note it and plan around it. **Verify before each deployment.**


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level on the marketplace so individual
solution listings stay small. Confirm these are in place before deploying *any* Intune solution.

Each entry: **Description · Why required · How to verify · How to implement if missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, enrollment, and security policies.
**Verify:** `https://intune.microsoft.com` loads and **Tenant administration → Tenant status** shows an active subscription.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies, enrollment connectors, and configuration profiles requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator** (or Global Administrator for connector setup).
**Implement:** Assign **Intune Administrator** to the operator; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted devices are enrolled and manageable in Intune.
**Why:** Policies only reach enrolled (or app-managed) devices, regardless of platform.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Configure the appropriate enrollment method for the platform and ownership model, then enroll the device.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted to a small group before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists with intended members.
**Implement:** Entra → **Groups → New group** → type **Security** → add pilot members.

## G6. Supported, current operating system
**Description:** A supported OS baseline with current updates for the targeted platform.
**Why:** Modern Intune features and security settings assume a patched, vendor-supported OS.
**Verify:** Check the device's OS version or Intune → device → **Hardware**.
**Implement:** Deploy update policies or upgrade to a supported release.

## G7. Network access to required cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing & Validation — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Validate against the **pilot device group** before expanding to the fleet. Each test has an explicit
**pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the
Intune portal for the score/baseline checks.

> **Scores are not instant.** Several tests below depend on the Endpoint Analytics **collection window**
> — allow the time Microsoft documents after enabling data collection before treating a blank result as
> a failure. **Confirm the current expected timing against Microsoft documentation.**

## Test 1 — Tenant readiness
**Procedure:** Run `ENDPTAN-Discovery.ps1`.
**Pass:** Endpoint Analytics data collection is configured, the `EPA – Pilot Devices` group exists, and
managed Windows devices are present in the tenant.
**Fail:** Any missing → resolve before baselining (create the group, enable data collection, enroll
devices).

## Test 2 — Data-collection policy assigned to the pilot
**Procedure:** In Intune → **Reports → Endpoint analytics → Settings** (data collection), confirm
`EPA – Data Collection – Pilot` is enabled and assigned to `EPA – Pilot Devices`. **Verify the current
Settings wording against Microsoft documentation.**
**Pass:** The data-collection policy is **enabled and assigned** to the pilot group.
**Fail:** Not assigned → assign it (Implementation §3) or run `ENDPTAN-Set-DataCollection.ps1 -Apply`.

## Test 3 — Data is flowing from the pilot devices
**Procedure:** Run `ENDPTAN-Test-DataFlow.ps1` (and confirm the pilot devices appear in **Reports →
Endpoint analytics**).
**Pass:** The pilot devices are **managed, syncing recently, and reporting** analytics data (or the
documented collection window has not yet elapsed and they are otherwise healthy).
**Fail:** Devices not reporting after the documented window → see Troubleshooting (no data / blocked
endpoints / diagnostic-data level / licensing).

## Test 4 — Scores populated for the pilot
**Procedure:** In **Reports → Endpoint analytics**, confirm the pilot devices have populated scores for
the enabled areas (Startup performance, Application reliability, Work-From-Anywhere, Resource
performance).
**Pass:** Scores are **populated** (not blank/"collecting") for the pilot devices.
**Fail:** Blank after the documented window → Troubleshooting (scores blank or delayed).

## Test 5 — Baseline established
**Procedure:** In **Reports → Endpoint analytics → Settings** (baselines), confirm a **baseline** is
selected/established, and record the pilot baseline scores (use `ENDPTAN-Report.ps1`).
**Pass:** A **pilot baseline** exists and its scores are recorded for later comparison.
**Fail:** No baseline → establish one (Implementation §8); **verify the baseline UI against Microsoft
documentation**.

## Test 6 — A score sub-signal is correctly interpreted
**Procedure:** Pick one below-baseline score (e.g. Startup performance) and drill into its sub-signals;
identify the top contributing factor (e.g. Group Policy / configuration processing time, a startup app,
disk type, or an outdated driver) and record it as a backlog item.
**Pass:** The low score is traced to a **specific, named sub-signal** and captured as a prioritized
backlog item (not just "the score is low").
**Fail:** You can see the score but not the cause → re-check that the relevant score area was enabled in
data collection (Implementation §3) and that the sub-signals have populated.

## Test 7 — Backlog produced and reportable
**Procedure:** Run `ENDPTAN-Report.ps1` and confirm you have a CSV of scores/sub-signals plus a written
prioritized backlog (Implementation §12).
**Pass:** A prioritized remediation backlog exists, each item tied to a score area and sub-signal, with
a report/export saved alongside the baseline.
**Fail:** No actionable backlog → complete Implementation §9–§12.

## Acceptance gate
Proceed to **Expand** (fleet) only when Tests 1–7 pass: Endpoint Analytics is **enabled**, the
**data-collection policy is assigned** to the pilot, **data is flowing**, **scores are populated**, a
**baseline is established**, at least one **sub-signal is correctly interpreted**, and a **prioritized
remediation backlog** exists. Hand backlog items to **Proactive Remediations (#2)** for scaled fixes and
to the **Anomaly Detection & Application Reliability product (#3)** for reliability deep-dives.


---


# 6. Troubleshooting — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Work top-down: confirm **licensing/access**, then **data collection is enabled and assigned**, then
**diagnostic-data settings**, then **endpoint reachability**, then **scope**, then give it the
**collection window**. Most "no scores" cases are one of: data collection not assigned, diagnostic data
below the required level, blocked telemetry endpoints, or simply not enough time elapsed yet.

> **Before chasing a fault, remember scores are not instant.** After enabling data collection there is a
> **collection window** before scores populate and a baseline forms. **Confirm the current expected
> timing against Microsoft documentation** and wait it out before treating blank scores as broken.

## No data at all / devices not reporting
- **Data-collection policy not assigned.** In **Reports → Endpoint analytics → Settings**, confirm
  `EPA – Data Collection – Pilot` is **enabled and assigned** to `EPA – Pilot Devices` (Implementation
  §3). Run `ENDPTAN-Test-DataFlow.ps1` to see which pilot devices are reporting.
- **Diagnostic data below the required level.** Endpoint Analytics needs Windows diagnostic data at the
  level Microsoft documents; if it's off or too low the device won't report. Confirm/assign
  `EPA – Diagnostic Data – Pilot` (Implementation §4). **Verify the required level against Microsoft
  documentation** — do not assume a fixed level.
- **Telemetry endpoints blocked.** The diagnostic-data / analytics endpoints are a **distinct set** from
  the core Intune URLs; if the proxy/firewall blocks them, scores stay blank even with the policy
  assigned. Allow the **Microsoft-published** endpoint ranges (Requirement R7) and re-test.
- **Device not actually managed / not syncing.** Confirm the device is Intune-enrolled or co-managed and
  syncing (Intune → Devices → device → **Sync**). A device that isn't checking in can't report analytics.

## Scores blank or delayed (data is flowing but no scores)
- **Collection window not elapsed.** Give it the documented time; `ENDPTAN-Test-DataFlow.ps1` can show
  devices are syncing even before scores render.
- **Score area not enabled.** If a specific score is missing, confirm that area was enabled when you
  turned on data collection (Implementation §3) — e.g. Application reliability enabled for the app-health
  score. **Verify the current toggle set against Microsoft documentation.**
- **Too few devices for a meaningful score.** Some scores need a minimum population/usage before they
  render. Expand the pilot slightly or wait for the fleet. **Confirm any current minimums with Microsoft.**
- **Co-managed devices not onboarded.** For co-managed devices, confirm the Configuration Manager side is
  onboarded to Endpoint Analytics (Requirement R9). **Verify the current onboarding steps with Microsoft.**

## Licensing / prerequisite gaps
- **Node blocked or limited.** If **Reports → Endpoint analytics** shows a licensing block, resolve the
  entitlement (Requirement R1) — **verify the entitling SKUs against current Microsoft documentation**;
  don't assume a bundle includes it.
- **Insufficient rights.** If you can read but not create the data-collection/config policies, you likely
  lack Intune administrative rights (Requirement R8) — assign the appropriate role.
- **Unsupported Windows version.** Devices on an unsupported build report partial/no data and drag WFA
  down. Bring them current (Requirement R3).

## Scope wrong (right feature, wrong devices)
- **Policy assigned to the wrong group.** Confirm the data-collection policy targets `EPA – Pilot Devices`
  (pilot) or `EPA – Fleet Devices` (fleet) as intended, and that the diagnostic-data profile is assigned
  to the **same** group — a mismatch means devices collect but aren't told to, or vice versa.
- **Devices missing from the group.** Confirm the intended devices are members (Assigned group) or match
  the rule (dynamic group). Re-run `ENDPTAN-Validate.ps1` after fixing membership.
- **Fleet expansion missed the diagnostic-data profile.** When you add `EPA – Fleet Devices` to data
  collection (Implementation §14), also extend the `EPA – Diagnostic Data` profile to the fleet group.

## National-cloud differences (GCC / GCC High / DoD)
- **Wrong portal or endpoint set.** Government tenants may use a different admin portal
  (e.g. `endpoint.microsoft.us`) and different service/telemetry endpoints, and a feature may be delayed
  or absent. **Verify availability, the correct portal, and the endpoint list against Microsoft's
  US-sovereign-cloud documentation** before concluding something is broken.

## Scripts (PowerShell / Microsoft Graph)
- **Connect with the right scopes.** The read-only scripts use read scopes
  (`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`,
  `DeviceManagementServiceConfig.Read.All`, `Group.Read.All`); the state-changer
  (`ENDPTAN-Set-DataCollection.ps1`) needs `DeviceManagementConfiguration.ReadWrite.All` and
  `Group.ReadWrite.All`. Consent to exactly those scopes at `Connect-MgGraph` — a missing scope shows as
  a 403/authorization error.
- **The state-changer defaults to `-WhatIf`.** `ENDPTAN-Set-DataCollection.ps1` **previews only** unless
  you pass **`-Apply`**. If "nothing changed," that's expected — re-run with `-Apply` to commit.
- **Match names/scope exactly (verbatim).** The scripts look up objects by their exact display names
  (`EPA – Pilot Devices`, `EPA – Data Collection – Pilot`). If you renamed an object, pass the matching
  `-PilotGroupName` / `-PolicyName` so the lookup finds it — note the names use an en dash (`–`), not a
  hyphen; copy them exactly.
- **Graph resources evolve — verify.** The Endpoint Analytics `userExperienceAnalytics*` resources are on
  the **beta** endpoint and change over time. If `ENDPTAN-Report.ps1` / `ENDPTAN-Test-DataFlow.ps1`
  return nothing, read the scores in **Reports → Endpoint analytics** and **verify the current Graph
  resource names against Microsoft documentation** before assuming a fault. The scripts intentionally do
  **not invent** an endpoint — `ENDPTAN-Set-DataCollection.ps1` previews its intent and points you to the
  portal when the data-collection resource isn't set.
- **Module missing.** `Install-Module Microsoft.Graph -Scope CurrentUser` once before first run.

## Useful checkpoints
- **Intune:** **Reports → Endpoint analytics** (scores/baseline), **Reports → Endpoint analytics →
  Settings** (data collection + baseline), **Devices → Configuration** (the diagnostic-data profile),
  **Devices → All devices** (managed/sync state).
- **Entra:** **Groups → `EPA – Pilot Devices` / `EPA – Fleet Devices`** (membership).
- **Scripts:** re-run `ENDPTAN-Validate.ps1` after each change to confirm the gate.


---


# 7. Best Practices — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Field-proven guidance for standing up Endpoint Analytics and running it as an ongoing improvement loop.

## Deploy & scope
- **Pilot before fleet, always.** Assign the `EPA – Data Collection – Pilot` policy to a small,
  representative `EPA – Pilot Devices` group first — prove data flows and read a baseline before you
  turn on the whole estate.
- **Make the pilot representative.** Include a mix of models, roles, and locations so the pilot baseline
  reflects reality, not just the newest laptops.
- **Name everything by intent** — `EPA – Pilot Devices`, `EPA – Data Collection – Pilot`,
  `EPA – Diagnostic Data – Pilot`, `EPA – Fleet Devices` — so the configuration is self-documenting and
  easy to audit and clean up.
- **Confirm diagnostic-data + endpoints up front.** The two most common causes of blank scores are
  diagnostic data set below the required level and blocked telemetry endpoints — verify both before you
  wait on a collection window. **Confirm the required level and endpoint list against Microsoft docs.**

## Baseline & measure
- **Set a baseline before you change anything.** A score is only meaningful against a baseline — capture
  the pilot baseline (and the fleet baseline later) and record the numbers so improvement is provable.
- **Compare against the "all organizations" median too.** Your own baseline shows movement; the
  Microsoft-published median shows whether you are ahead of or behind the pack.
- **Expect a collection window.** Scores populate after a delay, not instantly — don't declare failure
  on day one. **Verify the current timing against Microsoft documentation.**

## Interpret the scores
- **Always drill from score to sub-signal.** "Startup is low" is not actionable; "sign-in is dominated
  by Group Policy processing on model X" is. Trace every low score to a named cause.
- **Separate broad pain from one-offs.** For Application reliability, weigh crash/hang counts against
  usage — a widely used app failing often beats a single flaky device. For the deep reliability +
  anomaly investigation, use the companion product **Anomaly Detection & Application Reliability with
  Endpoint Analytics (#3)**.
- **Treat Work-From-Anywhere as a modernization checklist.** Its sub-signals (cloud identity, cloud
  management, edition currency, Autopilot, TPM) each map to a concrete project — attack them one at a time.

## Remediate & operate
- **Turn scores into a ranked backlog, not a data dump.** Prioritize highest-impact, lowest-effort
  first, and tie every item to a score area and sub-signal.
- **Fix at scale with the remediation engine.** For anything you'd script (detection + fix), use the
  companion product **Proactive Remediations at Scale — Detection & Remediation Script Packs for
  Microsoft Intune (#2)** rather than one-off manual fixes.
- **Re-measure against the baseline after every change.** The delta from baseline is your proof the work
  paid off — keep it for stakeholder reporting.
- **Run a review cadence.** Re-read the scores on a schedule (e.g. monthly), refresh the backlog, and
  report the trend. `ENDPTAN-Report.ps1` gives you the export each cycle.
- **Keep a runbook** of the groups, the data-collection policy, the diagnostic-data profile, the
  baseline(s), and the backlog — the moving parts that define your Endpoint Analytics program.

## National clouds
- **Verify before you deploy in GCC High / DoD.** Feature availability, rollout timing, and portal
  endpoints can differ from Commercial — confirm against Microsoft's US-sovereign-cloud documentation
  and use the correct national-cloud portal.


---


# 8. Deliverables Summary — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — what Endpoint Analytics is, the four score areas and what each measures, how
  baselining/benchmarking works, the improvement loop, where it fits in the three-product cluster
  (pointers to the Proactive Remediations and reliability/anomaly siblings), benefits, and honest
  limitations.
- **Requirements Guide** — every prerequisite (Endpoint Analytics licensing, enrolled/co-managed
  devices, supported Windows, the data-collection policy, a scoped device group, diagnostic-data
  settings, telemetry endpoints, admin rights, co-management onboarding, national-cloud confirmation)
  with how to **verify** and how to **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across five phases: assess & scope,
  configure (enable data collection), pilot (let data flow, set a baseline), validate (read each score
  and its sub-signals), then build the backlog and expand to the fleet — every object named and reused.
- **Testing & Validation** — seven tests with explicit pass/fail gates and an acceptance gate, proving
  data flows, scores populate, a baseline is set, and a sub-signal is correctly interpreted into a backlog.
- **Troubleshooting** — top-down diagnosis for no data, blank/delayed scores, licensing/prereq gaps,
  wrong scope, and a scripts section (Graph scopes, exact-name matching, `-WhatIf` default).
- **Best Practices** — deploy/scope, baseline/measure, interpret, remediate/operate, and national clouds.

## PowerShell scripts (Microsoft Graph) — `ENDPTAN-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Graph scopes · Expected results**. Four are
**read-only**; one is a **state-changer that defaults to `-WhatIf`**.

1. **`ENDPTAN-Discovery.ps1`** — read-only tenant readiness: Endpoint Analytics data collection present,
   the pilot group exists, and managed Windows devices in scope.
2. **`ENDPTAN-Validate.ps1`** — PASS/FAIL gate: data collection configured, pilot group populated, and
   pilot devices managed and syncing recently.
3. **`ENDPTAN-Report.ps1`** — exports a CSV summary of the scores and sub-signals for records, baseline
   tracking, and stakeholder reporting.
4. **`ENDPTAN-Test-DataFlow.ps1`** — read-only confirmation that the pilot devices are submitting
   analytics data, calling out any device not yet reporting.
5. **`ENDPTAN-Set-DataCollection.ps1`** — the only state-changer: creates/assigns the
   `EPA – Data Collection – Pilot` policy to `EPA – Pilot Devices`. **Defaults to `-WhatIf`** (preview
   only); re-run with `-Apply` to commit.

> The Endpoint Analytics Graph resources evolve; the scripts flag where to **verify the current resource
> names against Microsoft documentation** and fall back to the portal where Graph is inconclusive.

## Hero image
- **`ENDPTAN-hero.png`** — the product image (1200×1200) used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.

## Companion products (buy for depth — not reproduced here)
- **Proactive Remediations at Scale — Detection & Remediation Script Packs for Microsoft Intune (#2)** —
  the engine that fixes backlog items at scale (authoring/packaging/scheduling detection + remediation
  scripts).
- **Anomaly Detection & Application Reliability with Endpoint Analytics (#3)** — the reliability and
  anomaly deep-dive (crash/hang root-cause, catching bad rollouts early).
