# Implementation — Enablement Kit: Microsoft Defender for Endpoint (Guided Labs)

This is the exact, ordered enablement kit — a sequence of **guided hands-on labs**. Every object you create
is **named** with a consistent convention — `<Purpose> – <Scope> – <Stage>` — and the same name is
reused in later labs, the knowledge-check, and the scripts. Run the labs against **real telemetry,
read-only or preview-first**; the only change to the tenant is one **alert-only** capstone detection
and **audit-mode** ASR lab rules.

> **Before you start:** confirm MDE is onboarded with devices reporting (**R1**), the plan supports
> the P2 labs (**R2**), a pilot lab device group exists (**R3**), roles are split (**R4**), and the
> **read-only / no-production-response** posture is agreed (**R5**). This enablement kit **uses** MDE; it
> does not onboard or reconfigure the deployment.

**Named objects created in this enablement kit (verbatim — reused everywhere):**

| Object | Name | What it is |
| --- | --- | --- |
| Learner cohort group | `Grp-MDEEnablement Kit-Cohort` | Entra security group of enablement kit learners |
| Pilot lab device group | `Grp-MDE-LabDevices-Pilot` | Non-critical devices for Live Response / ASR-audit labs |
| Shared saved-query set | `Hunt-MDELab-Pilot` | The endpoint lab queries saved to shared queries |
| ASR lab config (audit) | `ASR-Lab-AuditOnly-Pilot` | The ASR rules set to **audit** for the lab |
| Custom detection (capstone) | `Detect-MDELab-Pilot` | Alert-only detection built from a tuned lab hunt |
| Knowledge-check | `Check-MDELab-Pilot` | The scored end-of-enablement kit knowledge-check |

The runnable queries for the hunting labs live in the delivered **`WSMDE-Labs.kql`** pack, organized
by lab number. Paste them into Advanced hunting, or run one read-only via `WSMDE-RunLab.ps1`.

---

## Phase 0 — Assess (read-only, changes nothing)

### Step 0.1 — Confirm readiness

1. Sign in to `https://security.microsoft.com` → **Assets → Devices**; confirm active, healthy
   devices are listed.
2. From PowerShell:

   ```
   pwsh -File .\WSMDE-Discovery.ps1
   ```

   It reports device count, endpoint-table freshness (`DeviceProcessEvents`, `DeviceNetworkEvents`,
   `DeviceEvents`, …), and whether Live Response / advanced features are enabled. **Read-only.**

### Step 0.2 — Create the cohort and the lab device group

1. In **Entra** → **Groups → New group**: Security; **Name** `Grp-MDEEnablement Kit-Cohort`; add learners.
2. In the Defender portal (or Intune) create the device group **`Grp-MDE-LabDevices-Pilot`** with a
   couple of non-critical onboarded devices (**R3**).
3. Assign read/hunt roles to learners; reserve Live Response + detection-authoring to the instructor
   (**R4**).

---

## Phase 1 — Configure (load the lab pack; nothing production yet)

### Step 1.1 — Load the KQL lab pack and shared query set

1. Open `WSMDE-Labs.kql`; confirm you can paste a query into **Advanced hunting** and run it.
2. Save your first working query into **shared queries** under a folder **`Hunt-MDELab-Pilot`**; save
   each lab’s good query here as you go.

### Step 1.2 — Stage the ASR audit configuration (do not enforce)

1. Note the ASR rules you will demonstrate. In the lab you will set them to **audit** only, as
   **`ASR-Lab-AuditOnly-Pilot`**, scoped to `Grp-MDE-LabDevices-Pilot`. **Do not set any rule to
   block during the enablement kit.** *Verify current ASR rule GUIDs/behavior in your tenant.*

---

## Phase 2 — Pilot (the guided labs)

### Lab 1 — The MDE console and the EDR mental model

- **Concept.** Sensor → alerts → incidents. Where device inventory, incidents, timelines, hunting,
  and settings live.
- **Task.** Tour **Incidents & alerts**, **Assets → Devices**, and open one device’s page.
- **Check.** You can navigate to any incident, device, timeline, or the hunting blade unaided.

### Lab 2 — Investigate an incident (graph + alert story)

- **Concept.** An incident groups related alerts; the **incident graph** shows entities; the **alert
  story** reconstructs the process tree.
- **Task.** Open a real (or the built-in evaluation) incident; walk the graph, expand the alert story,
  and identify the **root cause process** and the **impacted assets**.
- **Check.** You can state, for the incident, what started it and how far it spread.

### Lab 3 — Read a device timeline

- **Concept.** The per-device chronological event record is the ground truth for "what happened here."
- **Task.** On a device from `Grp-MDE-LabDevices-Pilot`, open **Timeline**, filter to a time window
  and event types, and reconstruct a sequence (e.g. a process launch and its network activity).
- **Check.** You can read the timeline to answer a "what did this machine do at time X?" question.

### Lab 4 — Endpoint advanced hunting

- **Concept.** KQL over the device tables. Meet `DeviceProcessEvents`, `DeviceNetworkEvents`,
  `DeviceFileEvents`, `DeviceRegistryEvents`, `DeviceLogonEvents`, `DeviceEvents`.
- **Task.** Run the pack’s **Lab 4** queries — encoded-PowerShell, process→network correlation, and a
  per-device rollup — read-only:

  ```
  pwsh -File .\WSMDE-RunLab.ps1 -Lab 4
  ```

- **Check.** You can find a behavior across devices and explain the result.

### Lab 5 — ASR: audit first, read the events

- **Concept.** ASR rules block techniques; roll out **audit → read → enforce**, never block-first.
- **Task.** Set the demo ASR rules to **audit** as **`ASR-Lab-AuditOnly-Pilot`** on
  `Grp-MDE-LabDevices-Pilot`; then hunt the audit events in `DeviceEvents` (the pack’s **Lab 5**
  query) to see what **would** have been blocked.
- **Check.** You can read ASR audit results and reason about the impact of enforcing a rule.

### Lab 6 — Live Response (read-only commands only)

- **Concept.** A remote investigative shell to a device. Read-only verbs: `processes`, `dir`,
  `fileinfo`, `getfile`. Change verbs (`remediate`, `run`, `putfile`) are **out of scope for the lab**.
- **Task.** With the instructor (holding Live Response), connect to a device in
  `Grp-MDE-LabDevices-Pilot` and run **only** `processes`, `dir`, and `getfile` on a benign file.
- **Check.** You understand how to pull evidence live — and why change commands stay behind approvals.

### Lab 7 — Response actions: understand and gate (no production execution)

- **Concept.** Isolate device, restrict app execution, collect investigation package, stop &
  quarantine file, run AV scan — the containment verbs and when each applies.
- **Task.** Walk each action in the portal UI **without executing it** against production; discuss the
  approval each requires and how to reverse it (e.g. release from isolation).
- **Check.** You can describe the right response action for a scenario and the approval it needs. *No
  production response is performed in class (R5).*

### Lab 8 — From hunt to detection (alert-only)

- **Concept.** A tuned hunt becomes a scheduled custom detection that **alerts only**.
- **Task.** Open your tuned Lab 4 query and choose **Create detection rule**. Name it
  **`Detect-MDELab-Pilot`**, map the device/account entities, and set the response to **generate an
  alert only** — no automatic isolation or remediation.
- **Check.** `Detect-MDELab-Pilot` exists and is alert-only.

---

## Phase 3 — Validate (capstone + knowledge-check)

1. **Capstone investigation.** Each learner takes an incident (or an evaluation incident), establishes
   root cause and scope from the graph + timeline, writes a two-line summary, and names the response
   action they **would** recommend (not execute).
2. **Knowledge-check.** Score `Check-MDELab-Pilot`:

   ```
   pwsh -File .\WSMDE-Validate.ps1
   ```

   It walks the `05-testing.md` gates — readiness, lab queries resolve, ASR lab rules are **audit-only**,
   Live Response used read-only, `Detect-MDELab-Pilot` is **alert-only** — and prints a score.
3. **Cohort report.**

   ```
   pwsh -File .\WSMDE-Report.ps1 -OutputCsv .\wsmde-cohort.csv
   ```

---

## Phase 4 — Expand (operationalize the skills)

1. **Adopt the query set.** Move the tuned queries from `Hunt-MDELab-Pilot` into the team’s standing
   shared-query library.
2. **Advance ASR deliberately.** Review the audit results from `ASR-Lab-AuditOnly-Pilot` and, as an
   **operations decision**, enforce (block) the rules that are clean — staged by device ring, with
   rollback. Not a default this enablement kit flips.
3. **Promote detections deliberately.** If `Detect-MDELab-Pilot` proves quiet and accurate, security
   operations may **document a decision** to promote it (renamed for production).
4. **Wire response into the incident process.** Response actions and Live Response change-commands are
   used **through the SOC’s approvals**, never as a enablement kit habit. Feed tuned hunts to the **Threat
   Hunting hunt-library** program.

---

## Rollback / safe-off

- **Hunting / timeline / investigation:** read-only — nothing to roll back.
- **ASR lab rules:** they are **audit-only** — set them back to **off** (or leave audit) after the
  lab; they never blocked anything.
- **Live Response:** only read-only commands were run — nothing to undo. (If a device were ever
  isolated, **release from isolation** reverses it — but no isolation is performed in class.)
- **Custom detection:** disable or delete `Detect-MDELab-Pilot`; it is alert-only and never remediates.
- **Groups / saved queries:** delete `Grp-MDEEnablement Kit-Cohort`, `Grp-MDE-LabDevices-Pilot`, and the
  `Hunt-MDELab-Pilot` folder if the enablement kit was one-off; keep them if operationalizing.
