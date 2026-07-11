# Workshop — Microsoft Defender for Endpoint

> **Version 1.0.0** · Category: Defender · Solution code: WSMDE

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Workshop: Microsoft Defender for Endpoint

## The problem

**Microsoft Defender for Endpoint (MDE)** is one of the most capable EDR platforms in the market —
and one of the most under-driven. Organizations onboard their devices, watch the alerts arrive, and
then use a fraction of what they paid for, because the **skill to investigate and respond** was never
built. The predictable gaps:

- **Alerts triaged, never investigated.** Analysts close alerts on the summary card without reading
  the **incident graph**, the **alert story**, or the **device timeline** — so root cause and blast
  radius are guessed, not established.
- **Attack surface left at defaults.** **Attack Surface Reduction (ASR)** rules ship the box unused
  or in the wrong mode, because no one was trained to roll them out in **audit** first and read the
  results.
- **Live response untouched.** The single fastest way to pull a file, list processes, or collect
  evidence from a remote device — **Live Response** — sits unused because it looks risky and no one
  practiced it safely.
- **Hunts that never happen.** The endpoint advanced-hunting tables (`DeviceProcessEvents`,
  `DeviceNetworkEvents`, …) hold the answers, but the team cannot write the query.

## The solution

This is a **structured enablement workshop** — concepts, **guided hands-on labs**, a **take-home
runbook**, and a **knowledge-check** — that takes an admin or SOC analyst from the MDE console to
confident **EDR investigation and response**: reading incidents and device timelines, rolling out
**ASR** the safe way, using **Live Response** with read-only commands, and hunting the endpoint
tables with KQL. It is a **skills** product:

- **Teaches investigation, not just triage** — how to walk an incident graph, an alert story, and a
  device timeline to establish root cause and scope.
- **Rolls out ASR safely** — audit-first, read the events, then enforce; no "block everything and
  see what breaks."
- **Practices Live Response and response actions safely** — read-only Live Response commands against
  a pilot lab device, and response actions (isolate, restrict, collect package) explained and
  **approval-gated**, never fired blind in class.
- **Ships a real endpoint KQL lab pack** and ends in an **alert-only** custom detection plus a
  **knowledge-check**.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure →
Pilot → Validate → Expand** — reframed for enablement. We confirm MDE is onboarded and the endpoint
tables have data, stand up a small **pilot lab device group** and a learner **cohort**, run the
**guided labs** read-only against real telemetry, **validate** with a capstone and a knowledge-check,
and then **expand** — folding the skills, saved queries, tuned ASR posture, and detection into the
live endpoint-security practice.

The package ships as **self-guided, click-by-click documentation plus a runnable endpoint KQL lab
pack and four PowerShell helpers** that check readiness, run a chosen lab query read-only, score the
knowledge-check, and report cohort progress — all **read-only or preview-first**, with **no
credentials in code**.

## Why it matters

- **Faster, deeper investigations** — analysts establish root cause and blast radius from the graph
  and timeline in minutes instead of guessing from an alert card.
- **Attack surface actually reduced** — ASR rolled out audit-first and enforced with evidence, not
  fear.
- **Response is fast but controlled** — Live Response and response actions understood and practiced
  safely, then used through the SOC’s approval process.
- **A fraction of consulting cost** — the same disciplined method a Defender specialist would teach,
  delivered as a repeatable runbook you keep and re-run for new hires.

## Important boundaries

This is a **skills / enablement** product — it teaches people to investigate and respond with MDE. It
**cross-references rather than repeats** the catalog’s MDE **onboarding accelerator** and
**optimization** solutions (which onboard devices and tune the deployment) and the **KQL for SecOps**
workshop (the language deep-dive this applies to endpoint tables). All labs are **read-only or
preview-first**: no destructive Live Response command and no response action (isolate, delete,
disable) is executed against production during the workshop — those route to the SOC’s normal
incident process. It provides the **technical skill and the labs**, not the **decisions**: which ASR
rules to enforce, which detections to promote, and every production response are the customer’s
**security-operations calls**. MDE features, table schemas, and Live Response commands **evolve and
can differ by plan (P1 vs P2) and cloud (Commercial vs GCC / GCC High)** — *verify current
availability and licensing in your tenant*.


---


# Solution Overview — Workshop: Microsoft Defender for Endpoint

## What this is

A complete, self-guided **enablement workshop** that takes an admin or SOC analyst from the
**Microsoft Defender for Endpoint (MDE)** console to confident **EDR investigation and response** —
incidents and device timelines, **Attack Surface Reduction (ASR)**, **Live Response**, response
actions, and **endpoint advanced hunting** with KQL. It is delivered as concepts, **guided hands-on
labs**, a **runnable endpoint KQL lab pack**, a **take-home runbook**, and a **knowledge-check**.

It is a **skills** product — the outcome is people who can drive MDE. It **cross-references** the
catalog’s MDE **onboarding accelerator** and **optimization** solutions (which deploy and tune MDE)
and the **Advanced KQL for SecOps** workshop (the language deep-dive) — this workshop applies those
skills specifically to endpoint investigation and response.

## How the technology works (the mental model)

- **EDR = record everything, alert on the bad, let you investigate the rest.** MDE’s sensor on each
  device streams process, file, network, registry, and logon events to the cloud, raises **alerts**
  when behavior matches detections, and correlates related alerts into **incidents**.
- **Incident graph & alert story.** An **incident** groups related alerts and evidence across devices
  and identities. The **incident graph** shows the entities and how they connect; the **alert story**
  reconstructs the sequence of actions (process tree) that led to the alert — this is where root cause
  and blast radius are established.
- **Device timeline.** A per-device chronological record of observed events — the ground truth for
  "what happened on this machine, and when." Reading it well is the core investigation skill.
- **Attack Surface Reduction (ASR).** A set of rules that block common attack techniques (e.g. Office
  spawning child processes, credential theft from LSASS). Each rule runs in **audit**, **block**, or
  **off**; the discipline is **audit first**, read the `DeviceEvents` ASR audit entries, then enforce.
  *ASR rule GUIDs and behavior evolve — verify current rules in your tenant.*
- **Live Response.** A remote shell to an onboarded device for investigation — list processes, pull a
  file, run a script, collect artifacts. It has **read-only/investigative** commands (`processes`,
  `dir`, `getfile`, `fileinfo`) and **change** commands (`remediate`, `putfile`, `run`). This
  workshop uses **only the read-only commands** in the labs. *Command set differs by OS and evolves —
  verify.*
- **Response actions.** The containment verbs on a device or file — **isolate device**, **restrict
  app execution**, **collect investigation package**, **stop & quarantine file**, **run AV scan**.
  These are **explained and approval-gated** here; none is executed against production in class.
- **Endpoint advanced hunting.** KQL over the device tables — `DeviceProcessEvents`,
  `DeviceNetworkEvents`, `DeviceFileEvents`, `DeviceRegistryEvents`, `DeviceLogonEvents`,
  `DeviceEvents`, `DeviceInfo` — for proactive hunting and building custom detections.

## The standard deployment model

Every solution in this program follows the same five stages; here they structure the workshop:

1. **Assess.** Confirm MDE is onboarded, devices are reporting, and the endpoint tables have data
   (run `WSMDE-Discovery.ps1`).
2. **Configure.** Create the learner cohort `Grp-MDEWorkshop-Cohort` and the pilot lab device group
   `Grp-MDE-LabDevices-Pilot`; load the KQL lab pack `WSMDE-Labs.kql`; agree the **read-only / no
   production response** posture.
3. **Pilot.** Run the **guided labs** (Labs 1–8) with the cohort — console & EDR model, investigate an
   incident, read a device timeline, endpoint hunting, ASR audit-mode, read-only Live Response,
   response-action walkthrough, hunt→detection.
4. **Validate.** Run the **capstone** investigation and score the **knowledge-check**
   `Check-MDELab-Pilot` (`WSMDE-Validate.ps1`); confirm the built detection `Detect-MDELab-Pilot` is
   **alert-only** and ASR lab rules are **audit-only**.
5. **Expand.** Fold the skills, the saved query set `Hunt-MDELab-Pilot`, the tuned ASR posture, and
   the detection into the **live endpoint-security practice** — deciding, as operations decisions,
   which ASR rules to enforce and which detections to promote.

## Scope — what this workshop covers

- **EDR investigation** — incidents, the incident graph, the alert story/process tree, and the
  **device timeline**.
- **Attack Surface Reduction** — rolling out ASR **audit-first** and reading ASR events via hunting.
- **Live Response** — connecting to a pilot device and using **read-only** investigative commands.
- **Response actions** — isolate / restrict / collect package / stop-and-quarantine, **explained and
  approval-gated** (not executed against production in class).
- **Endpoint advanced hunting** — a KQL lab pack over the device tables, ending in an **alert-only**
  custom detection.
- **A take-home runbook + knowledge-check.**

## Out of scope (handled elsewhere)

- **Onboarding and tuning MDE.** Getting devices onboarded, configuring the deployment, and
  optimizing it are the **MDE onboarding accelerator** and **MDE optimization** catalog solutions.
  This workshop **uses** an onboarded MDE; it does not deploy it.
- **Executing production response.** Isolating a real device, deleting a real file, or running
  destructive Live Response is the SOC’s **incident-response** activity under its own approvals — not
  a workshop lab.
- **Cross-pillar correlation and SOAR.** Bringing identity, email, and cloud-app signal into the same
  incident is the **Defender XDR** onboarding solution; automated response is the **Sentinel SOAR**
  area.
- **The security-operations decisions.** Which ASR rules to enforce, acceptable false-positive rates,
  which detections to promote, and every production response are **the customer’s SOC / security
  determinations**; this workshop provides the skill, the labs, and the data.

## Authentication and connections used

- **Microsoft Defender portal** (`security.microsoft.com`) for incidents, device inventory, the
  device timeline, ASR settings, Live Response, response actions, Advanced hunting, and custom
  detection rules.
- **PowerShell** with **Microsoft.Graph** (security — advanced hunting via `security/runHuntingQuery`,
  and read of device/alert entities) used only to **check readiness, run lab queries read-only**,
  score the knowledge-check, and report progress.
- All helpers authenticate **interactively** with an MFA-capable account holding at least read/hunt
  scopes; **no credentials are stored in code**. Government-cloud tenants pass the matching endpoints
  — *verify endpoints for your cloud*.


---


# Requirements — Workshop: Microsoft Defender for Endpoint

These are the **solution-specific** prerequisites for running the MDE enablement workshop. The
**category baseline** — an active Microsoft 365 / Entra tenant, Defender licensing in general,
least-privilege admin roles, onboarding reach, network access to Defender endpoints, a pilot ring, a
workspace where required, and response governance — is covered once in
**`global-requirements-defender.md`** (**G1–G8**). Read that first; the items below layer on top of
it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. Defender for Endpoint onboarded, with devices reporting

- **Description:** MDE is provisioned and a meaningful set of devices is **onboarded and reporting**
  (health = active), so incidents, timelines, and endpoint tables have real content.
- **Why required:** Every lab investigates or hunts **real device telemetry**. With no onboarded
  devices there are no timelines, no ASR events, no hunting data.
- **How to verify:** `security.microsoft.com → Assets → Devices` lists active devices; run
  `WSMDE-Discovery.ps1`, which reports device count and endpoint-table freshness.
- **How to implement if missing:** Onboard devices first — the **MDE onboarding accelerator** catalog
  solution. This workshop uses an onboarded MDE and does not perform onboarding.

## R2. MDE plan appropriate to the labs (P1 vs P2)

- **Description:** The Defender for Endpoint plan that covers the features in scope. **EDR, advanced
  hunting, Live Response, and custom detections are Plan 2 capabilities**; Plan 1 is
  prevention-focused. *Verify current plan-to-feature mapping in your tenant.*
- **Why required:** The investigation, hunting, Live Response, and detection labs depend on **P2**
  features. On P1 those labs cannot run in full.
- **How to verify:** Confirm the licensed plan (admin center billing / the Defender portal); confirm
  **Advanced hunting**, **Live Response**, and **Custom detection rules** are present.
- **How to implement if missing:** Assign Defender for Endpoint **Plan 2** (often bundled in M365 E5
  / E5 Security) to run the full workshop. On P1, run the prevention/ASR labs and defer the P2-only
  labs. *Verify licensing.*

## R3. A pilot lab device group

- **Description:** A small **device group** — `Grp-MDE-LabDevices-Pilot` — of non-critical devices to
  use for the Live Response and ASR-audit labs, so hands-on practice never touches a critical
  production endpoint.
- **Why required:** Live Response connects to a real device and ASR audit generates events. Practising
  on a dedicated, non-critical lab device is the safe way (category **G6**).
- **How to verify:** The device group exists in the Defender portal (or Intune) with the intended lab
  devices; those devices are onboarded and healthy.
- **How to implement if missing:** Create `Grp-MDE-LabDevices-Pilot` and add a couple of non-critical,
  onboarded test devices. Do **not** use executives’ or production-critical machines for the labs.

## R4. Roles: read/hunt for learners, response rights for the instructor

- **Description:** Learners hold a **read/hunt** role (**Security Reader** with hunting, or **Security
  Operator**). The instructor holds the rights needed for the gated demos — **Live Response**
  permission and the ability to create custom detection rules (**Security Administrator** or the
  granular equivalent, with Live Response enabled in **Advanced features**).
- **Why required:** Labs run at **least privilege** — read and hunt. Only the Live Response demo and
  the detection-authoring capstone need elevation, and only for the instructor.
- **How to verify:** Defender **Permissions & roles** (and Entra **Roles and administrators**) show
  the split; **Settings → Endpoints → Advanced features → Live Response** is enabled.
- **How to implement if missing:** Assign read/hunt roles to the cohort (prefer **PIM-eligible** for
  elevated roles where Entra ID P2 is available — *verify licensing*); enable Live Response and grant
  the instructor the response role.

## R5. A read-only / no-production-response lab posture

- **Description:** An agreed rule that all labs are **read-only or preview-first**: Live Response uses
  **only investigative commands**, ASR lab rules run in **audit**, the capstone detection is
  **alert-only**, and **no response action** (isolate, delete, disable) is executed against
  production during the workshop.
- **Why required:** Learners operate against live devices. The posture must be explicit so no one
  isolates a machine or runs a destructive command "to see what happens."
- **How to verify:** The workshop plan states the posture; ASR lab rules are audit; the detection is
  alert-only; Live Response transcripts show only read-only commands.
- **How to implement if missing:** State it at kickoff; route any real finding to the SOC’s normal
  incident process (category **G8**). Response actions are **taught and gated**, not performed in class.

## R6. The PowerShell helper toolchain

- **Description:** A workstation with **Microsoft.Graph** (security modules), signed in with an
  MFA-capable account holding at least read/hunt scopes; plus portal access to Advanced hunting, the
  device timeline, ASR settings, and Live Response for the interactive labs.
- **Why required:** The four delivered helpers check readiness, run a chosen lab query read-only,
  score the knowledge-check, and report cohort progress.
- **How to verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Connect-MgGraph`
  succeeds; Advanced hunting loads in the portal.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; sign in. For
  Government cloud, connect with the matching environment/endpoints — *verify the correct endpoints
  for your cloud*.


---


# Global Requirements — Defender (category-level)

These requirements apply to every solution in the Defender category (Microsoft Defender XDR and Defender
for Cloud). Published once at the category level so listings stay small. Confirm before deploying any
Defender solution. Each entry: Description / Why / Verify / Implement-if-missing.

> Defender changes touch detection and response for the whole tenant. Onboard in a ring (pilot devices/
> users first), keep automated response in an approval/simulate posture until trusted, and never disable
> an existing control to "test."

## G1. Microsoft 365 / Entra tenant
Description: An active Microsoft 365 tenant with Entra ID.
Why: Defender XDR services and the unified portal (security.microsoft.com) are tenant workloads.
Verify: Sign in to `https://security.microsoft.com` as an administrator.
Implement: Provision a Microsoft 365 tenant and confirm Entra ID identities exist.

## G2. Defender licensing
Description: The Defender plans for the pillars in scope — e.g. Defender for Endpoint P1/P2, Defender for Identity, Defender for Office 365 P1/P2, Defender for Cloud Apps, and Defender for Cloud plans.
Why: Each pillar/feature is license-gated; onboarding without the plan fails or silently limits features.
Verify: Admin center -> `Billing -> Licenses` (or the Defender portal). *Confirm the exact plan each feature needs — verify current availability in your tenant.*
Implement: Assign the required plans (often bundled in M365 E5 / E5 Security) before onboarding.

## G3. Administrative roles (least privilege)
Description: Security Administrator (and Global Administrator for first-time service activation).
Why: Onboarding, RBAC, and policy changes in the Defender portal require these roles.
Verify: Entra -> `Roles and administrators`; confirm Security Administrator.
Implement: Assign Security Administrator; reserve Global Administrator for one-time activations.

## G4. Onboarding reach to endpoints / identity / workloads
Description: A management channel to onboard the pillars — Intune/Configuration Manager/GPO/script for endpoints, domain controllers/AD FS for Identity sensors, and cloud connectors for Defender for Cloud.
Why: Each pillar collects signal from a source that must be reachable and instrumented.
Verify: Endpoints are managed (Intune/CM); DCs are reachable; cloud subscriptions are connected. Run the solution's discovery script.
Implement: Establish the onboarding channel per pillar (see the relevant catalog endpoint/identity solutions).

## G5. Network access to Defender service endpoints
Description: Outbound HTTPS to the Microsoft Defender / Microsoft 365 service URLs from onboarded assets.
Why: Sensors and agents report to the cloud service; blocked endpoints break onboarding and detections.
Verify: Confirm the documented Defender endpoint URLs/IP ranges are allowed. *Verify current endpoint list.*
Implement: Allow the Defender/M365 endpoints through proxy/firewall.

## G6. A pilot ring
Description: A defined set of pilot devices/users/subscriptions to onboard first.
Why: XDR onboarding and automated response are validated on a ring before tenant-wide rollout.
Verify: A pilot group exists in Entra/Intune.
Implement: Create the pilot ring before enabling anything that acts automatically.

## G7. Log Analytics workspace (where required)
Description: A Log Analytics workspace for Defender for Cloud / advanced hunting export where used.
Why: Some Defender data and continuous export land in a workspace.
Verify: A workspace exists and is access-controlled. Run the discovery script.
Implement: Provision a workspace (or reuse the SIEM/observability one) with least-privilege access.

## G8. Response governance
Description: An agreed position on automated response (auto-remediation levels, approval requirements).
Why: XDR/AIR can take disruptive actions (isolate, delete, disable); the organization must decide the guardrails.
Verify: A documented response policy exists; automation is in an approval/simulate posture until trusted.
Implement: Define response guardrails; keep AIR/automation approval-gated at first. *Incident-response decisions are the SOC/security team's; this guide covers the technical configuration.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# Implementation — Workshop: Microsoft Defender for Endpoint (Guided Labs)

This is the exact, ordered workshop — a sequence of **guided hands-on labs**. Every object you create
is **named** with a consistent convention — `<Purpose> – <Scope> – <Stage>` — and the same name is
reused in later labs, the knowledge-check, and the scripts. Run the labs against **real telemetry,
read-only or preview-first**; the only change to the tenant is one **alert-only** capstone detection
and **audit-mode** ASR lab rules.

> **Before you start:** confirm MDE is onboarded with devices reporting (**R1**), the plan supports
> the P2 labs (**R2**), a pilot lab device group exists (**R3**), roles are split (**R4**), and the
> **read-only / no-production-response** posture is agreed (**R5**). This workshop **uses** MDE; it
> does not onboard or reconfigure the deployment.

**Named objects created in this workshop (verbatim — reused everywhere):**

| Object | Name | What it is |
| --- | --- | --- |
| Learner cohort group | `Grp-MDEWorkshop-Cohort` | Entra security group of workshop learners |
| Pilot lab device group | `Grp-MDE-LabDevices-Pilot` | Non-critical devices for Live Response / ASR-audit labs |
| Shared saved-query set | `Hunt-MDELab-Pilot` | The endpoint lab queries saved to shared queries |
| ASR lab config (audit) | `ASR-Lab-AuditOnly-Pilot` | The ASR rules set to **audit** for the lab |
| Custom detection (capstone) | `Detect-MDELab-Pilot` | Alert-only detection built from a tuned lab hunt |
| Knowledge-check | `Check-MDELab-Pilot` | The scored end-of-workshop knowledge-check |

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

1. In **Entra** → **Groups → New group**: Security; **Name** `Grp-MDEWorkshop-Cohort`; add learners.
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
   block during the workshop.** *Verify current ASR rule GUIDs/behavior in your tenant.*

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
   rollback. Not a default this workshop flips.
3. **Promote detections deliberately.** If `Detect-MDELab-Pilot` proves quiet and accurate, security
   operations may **document a decision** to promote it (renamed for production).
4. **Wire response into the incident process.** Response actions and Live Response change-commands are
   used **through the SOC’s approvals**, never as a workshop habit. Feed tuned hunts to the **Threat
   Hunting hunt-library** program.

---

## Rollback / safe-off

- **Hunting / timeline / investigation:** read-only — nothing to roll back.
- **ASR lab rules:** they are **audit-only** — set them back to **off** (or leave audit) after the
  lab; they never blocked anything.
- **Live Response:** only read-only commands were run — nothing to undo. (If a device were ever
  isolated, **release from isolation** reverses it — but no isolation is performed in class.)
- **Custom detection:** disable or delete `Detect-MDELab-Pilot`; it is alert-only and never remediates.
- **Groups / saved queries:** delete `Grp-MDEWorkshop-Cohort`, `Grp-MDE-LabDevices-Pilot`, and the
  `Hunt-MDELab-Pilot` folder if the workshop was one-off; keep them if operationalizing.


---


# Testing & Validation — Workshop: Microsoft Defender for Endpoint

Validate the workshop against explicit **pass/fail gates** — that the **environment** supports the
labs and that the **skills** landed. Run the scripts and walk the manual checks. The automated gates
are produced by **`WSMDE-Validate.ps1`**; readiness comes from **`WSMDE-Discovery.ps1`**, running a
lab query from **`WSMDE-RunLab.ps1`**, and cohort evidence from **`WSMDE-Report.ps1`**.

Each gate lists **What good looks like / How to test / If it fails**.

---

## Gate 1 — MDE is onboarded and endpoint tables have data

- **What good looks like:** Active devices are listed; `DeviceProcessEvents`, `DeviceNetworkEvents`,
  and `DeviceEvents` return recent rows.
- **How to test:** Run `WSMDE-Discovery.ps1`; confirm device count > 0 and the freshness section shows
  rows in the last 24h.
- **If it fails:** Onboard devices (the MDE onboarding accelerator) and allow ingestion time (**R1**);
  run available labs meanwhile.

## Gate 2 — The plan supports the P2 labs

- **What good looks like:** Advanced hunting, Live Response, and Custom detection rules are present.
- **How to test:** Confirm the three surfaces load in the portal; `WSMDE-Discovery.ps1` reports Live
  Response / advanced features enabled.
- **If it fails:** Assign Defender for Endpoint **Plan 2** (R2); on P1, run the prevention/ASR labs and
  defer the P2-only labs. *Verify licensing.*

## Gate 3 — Each hunting lab query resolves

- **What good looks like:** Labs 4–5 from `WSMDE-Labs.kql` run without schema errors and return
  explainable results.
- **How to test:** `pwsh -File .\WSMDE-RunLab.ps1 -Lab 4` returns rows; repeat for Lab 5.
- **If it fails:** Correct any table/column name to your tenant’s schema (Advanced hunting → schema)
  and re-run.

## Gate 4 — Learners can investigate an incident

- **What good looks like:** In the capstone, a learner establishes **root cause** and **scope** from
  the incident graph + device timeline and names the recommended response action.
- **How to test:** Observe the capstone; confirm the two-line summary correctly identifies the origin
  process and impacted assets.
- **If it fails:** Re-run Labs 2 and 3 (incident graph, device timeline) before repeating the capstone.

## Gate 5 — ASR lab rules are audit-only

- **What good looks like:** `ASR-Lab-AuditOnly-Pilot` is set to **audit** (never block) on
  `Grp-MDE-LabDevices-Pilot`, and audit events appear in `DeviceEvents`.
- **How to test:** Confirm the ASR rule mode in the portal is **audit**; run the Lab 5 hunt and see
  audit entries. `WSMDE-Validate.ps1` flags any block-mode lab rule as a concern.
- **If it fails:** Set the lab rules back to **audit**; never block during the workshop (**R5**).

## Gate 6 — Live Response used read-only

- **What good looks like:** The Live Response transcript for the lab device shows **only** `processes`,
  `dir`, `fileinfo`, `getfile` — no change commands.
- **How to test:** Review the Live Response session history for `Grp-MDE-LabDevices-Pilot` devices;
  confirm no `run` / `remediate` / `putfile`.
- **If it fails:** Reaffirm the read-only posture; change commands are out of scope for the workshop
  (**R5**).

## Gate 7 — The lab detection exists and is alert-only

- **What good looks like:** `Detect-MDELab-Pilot` exists as a custom detection rule that **generates an
  alert only** — no isolation or remediation.
- **How to test:** **Advanced hunting → Custom detection rules** lists it; its response action is
  alert-only. `WSMDE-Validate.ps1` confirms presence.
- **If it fails:** Recreate it from the tuned Lab 4 query (Lab 8) and set the response to alert-only.

## Gate 8 — The knowledge-check passes

- **What good looks like:** Each learner passes `Check-MDELab-Pilot` (incident vs alert, reading a
  timeline, ASR modes, Live Response read vs change commands, the response actions and their
  approvals).
- **How to test:** Run `WSMDE-Validate.ps1`; it prints the knowledge-check answer key and score.
- **If it fails:** Revisit the mapped lab for any missed question.

## Gate 9 — Read-only posture held; roles least-privilege

- **What good looks like:** No production response action was taken; learners held read/hunt roles and
  only the instructor held Live Response + authoring rights.
- **How to test:** Review **Permissions & roles** (R4); confirm the audit shows read/hunt/audit
  activity only.
- **If it fails:** Tighten role assignments; reaffirm the posture (**R5**).

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | MDE onboarded + data | Devices active; endpoint tables return rows |
| 2 | Plan supports P2 labs | Advanced hunting / Live Response / detections present |
| 3 | Hunting labs resolve | Labs 4–5 run without schema errors |
| 4 | Investigate an incident | Capstone identifies root cause + scope |
| 5 | ASR audit-only | `ASR-Lab-AuditOnly-Pilot` in audit; events in `DeviceEvents` |
| 6 | Live Response read-only | Only read-only commands in the transcript |
| 7 | Lab detection alert-only | `Detect-MDELab-Pilot` exists, alert-only |
| 8 | Knowledge-check passes | `Check-MDELab-Pilot` scored to threshold |
| 9 | Read-only + least-privilege | No production response; roles scoped |

All gates pass ⇒ the cohort is enabled; proceed to **Expand**. Any fail ⇒ reinforce the mapped lab and
re-check.


---


# Troubleshooting — Workshop: Microsoft Defender for Endpoint

The common failure modes, each as **symptom → cause → fix**. Most workshop issues are onboarding /
plan gaps, table freshness, or a feature that needs enabling — not a broken platform.

---

## 1. No devices listed / endpoint tables empty

- **Symptom:** **Assets → Devices** is empty, or hunting tables return 0 rows.
- **Cause:** No devices onboarded, sensors unhealthy, or ingestion hasn’t caught up.
- **Fix:** Onboard devices (the **MDE onboarding accelerator** solution) and confirm health; allow
  ingestion time; check with `WSMDE-Discovery.ps1`. Run available labs on whatever data exists (**R1**).

## 2. Advanced hunting / Live Response / custom detections are missing

- **Symptom:** One of these blades is absent or greyed out.
- **Cause:** The tenant/user is on **Defender for Endpoint Plan 1** (these are P2 features), the
  feature isn’t enabled, or the role is insufficient.
- **Fix:** Confirm **Plan 2** (R2); enable **Live Response** under **Settings → Endpoints → Advanced
  features**; confirm the role (R4). *Verify current plan-to-feature mapping in your tenant.*

## 3. "Unknown table/column" in a hunting query

- **Symptom:** A Lab 4/5 query fails to resolve a table or column (e.g. `DeviceProcessEvents`,
  `RemoteIPType`).
- **Cause:** **Schema drift** — the pack uses representative names that evolve and can differ by cloud.
- **Fix:** Open **Advanced hunting → schema** and correct the name to your tenant’s current schema.
  *Verify current schema.*

## 4. ASR audit events don’t appear

- **Symptom:** The Lab 5 hunt over `DeviceEvents` returns no ASR audit entries.
- **Cause:** The rule isn’t in **audit**, it’s scoped to the wrong devices, nothing has triggered it
  yet, or the rule GUID differs.
- **Fix:** Confirm `ASR-Lab-AuditOnly-Pilot` is **audit** on `Grp-MDE-LabDevices-Pilot`; generate a
  benign triggering action on a lab device; verify the current ASR rule GUIDs. *Verify ASR rules for
  your tenant.*

## 5. An ASR rule is blocking legitimate software

- **Symptom:** A lab device can’t run an expected app after an ASR change.
- **Cause:** A rule was set to **block** instead of **audit** during the lab.
- **Fix:** Set the rule back to **audit** (the workshop never blocks — R5); if a real enforcement is
  needed later, add a **specific** exclusion and roll out by ring as an operations decision.

## 6. Live Response won’t connect to the lab device

- **Symptom:** The Live Response session fails to start.
- **Cause:** Live Response not enabled in Advanced features, the device is offline/unhealthy, or the
  account lacks the Live Response permission.
- **Fix:** Enable **Live Response** (Settings → Endpoints → Advanced features); confirm the device is
  online and healthy; grant the instructor the Live Response role (R4). Use only read-only commands
  (R5).

## 7. A learner ran a change command in Live Response

- **Symptom:** A `run` / `remediate` / `putfile` appears in the transcript.
- **Cause:** The read-only posture wasn’t enforced.
- **Fix:** Reaffirm the posture (R5); restrict Live Response to the instructor; change commands are
  out of scope for the workshop and belong to real incident response under approvals.

## 8. "Create detection rule" is greyed out

- **Symptom:** In Lab 8 you cannot create the custom detection.
- **Cause:** The account lacks the authoring role, or the query doesn’t project the required entity
  columns.
- **Fix:** Have the **instructor** author `Detect-MDELab-Pilot`; ensure the query projects
  `DeviceId`/`DeviceName`/`AccountName` so the rule can map entities. Keep it **alert-only**.

## 9. The custom detection is noisy

- **Symptom:** `Detect-MDELab-Pilot` floods with alerts.
- **Cause:** The underlying hunt wasn’t tuned to a small, explainable result before promotion.
- **Fix:** Disable it, tighten the Lab 4 query (more selective filters / thresholds), then recreate the
  alert-only rule. Never promote a noisy hunt.

## 10. Graph connection or permission errors

- **Symptom:** `Connect-MgGraph` fails, or a call returns 403.
- **Cause:** Missing modules, wrong cloud endpoint, unconsented scopes, or insufficient role.
- **Fix:** `Install-Module Microsoft.Graph`; connect with the correct `-Environment` for Government
  cloud; consent the read/hunt scopes in each script header; confirm the account holds a read/hunt
  role (R4). *Verify the correct endpoints for your cloud.*


---


# Best Practices — Workshop: Microsoft Defender for Endpoint

Keep-it-clean guidance for turning an MDE workshop into a durable investigation-and-response skill
that stays sharp over time.

## Investigate, don’t just triage

- **Always read the story.** Before closing an alert, walk the **incident graph** and the **alert
  story** (process tree) and open the **device timeline**. Establish root cause and blast radius —
  the summary card is a headline, not the investigation.
- **Answer a question with the timeline.** "What did this machine do between X and Y?" is a timeline
  query, not a guess. Practise reconstructing sequences until it is fast.
- **Re-hunt after every incident.** A new indicator (hash, IP, filename, command line) is a new query
  — run it across all devices, not just the one that alerted.

## Roll out ASR the safe way

- **Audit first, always.** Put a new ASR rule in **audit** (`ASR-Lab-AuditOnly-Pilot` is the pattern),
  read the `DeviceEvents` audit entries, and understand what it **would** block before enforcing.
- **Enforce by ring, with rollback.** Move a clean rule to **block** in stages (lab devices → a pilot
  ring → broadly), watching for breakage, and know how to revert. Enforcing is an **operations
  decision**, not a switch you flip in class.
- **Exclude narrowly.** When a rule blocks something legitimate, add a **specific** exclusion, not a
  blanket one — and record why.

## Respond deliberately, through approvals

- **Read-only Live Response by default.** Use `processes`, `dir`, `fileinfo`, `getfile` to gather
  evidence. Reserve change commands (`run`, `remediate`, `putfile`) for real incidents under the SOC’s
  approvals — never as a workshop reflex.
- **Right action, right approval.** Isolate contains a device but disrupts the user; stop-and-quarantine
  removes a file; collect-package preserves evidence. Match the action to the scenario and know how to
  reverse it (release from isolation).
- **Never execute production response in a class.** Teach and gate the actions; perform them only in a
  real incident.

## Turn hunts into durable coverage — carefully

- **Alert-only first.** Promote a hunt to a custom detection (`Detect-MDELab-Pilot`) only once it is
  quiet and accurate, and keep it **alert-only** until proven. A noisy detection trains the team to
  ignore alerts.
- **Version your queries.** Keep the endpoint KQL library in source control so hunts are reviewable and
  portable — the same discipline the Sentinel detection-as-code solution applies.

## Run it as a program, not a one-off class

- **Practice keeps the skill.** Schedule recurring investigation drills and rotate who leads the hunt
  of the week.
- **Feed the hunt library.** Hand tuned endpoint queries to the **Threat Hunting hunt-library**
  solution so they join the maintained, operated program.
- **Re-run for new hires.** The take-home runbook and knowledge-check make onboarding a new analyst
  repeatable.

## Where to go next

With the team able to investigate and respond on the endpoint, the natural next steps in this catalog
are:

- **Microsoft Defender for Endpoint — onboarding accelerator / optimization** — ensure the deployment
  itself is complete and tuned (the platforms this workshop drives).
- **Advanced KQL for SecOps workshop** — deepen the query language this workshop applies to endpoint
  tables, and extend hunting across Sentinel.
- **Microsoft Defender XDR onboarding** — bring identity, email, and cloud-app signal into the same
  incident so endpoint threats correlate with the whole kill chain.
- **Threat Hunting hunt-library** — adopt and operate a curated, maintained hunt program built on the
  skill this workshop gives you.


---


# Deliverables Summary — Workshop: Microsoft Defender for Endpoint

Everything included in this workshop, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page framing: the "onboarded-but-under-driven EDR" problem, the enablement solution (concepts + labs + runbook + knowledge-check), and the boundary (skills product; read-only/preview-first; uses an onboarded MDE, does not deploy it). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how MDE works (EDR model, incident graph & alert story, device timeline, ASR, Live Response, response actions, endpoint advanced hunting), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (MDE onboarded with devices reporting, P1-vs-P2 plan, a pilot lab device group, split read/hunt vs instructor roles, a read-only posture, the toolchain) — layered on the shared `global-requirements-defender.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | The guided labs: assess readiness, create the cohort + lab device group, load the KQL lab pack, run Labs 1–8 (console/EDR model → investigate an incident → device timeline → endpoint hunting → ASR audit → read-only Live Response → response-action walkthrough → alert-only detection), then capstone + knowledge-check, then operationalize — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates covering environment readiness (MDE onboarded, P2 features) and skills landed (investigate an incident, ASR audit-only, Live Response read-only, alert-only detection, knowledge-check), referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (no devices/empty tables, schema drift, P1-vs-P2 feature gaps, ASR not auditing, Live Response unavailable, detection not alert-only, connection errors) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Investigate-don’t-triage, roll-out-ASR-safely, respond-deliberately-through-approvals, turn-hunts-into-durable-coverage, run-it-as-a-program — plus where to go next in the catalog. |

## Lab pack + PowerShell helpers (5)

All helpers are **read-only or preview-first**, authenticate **interactively** (no credentials in
code), and use **Microsoft.Graph** (security — advanced hunting via `runHuntingQuery`).
Government-cloud tenants pass the matching environment — *verify endpoints for your cloud*.

| File | Type | What it does |
| --- | --- | --- |
| **`WSMDE-Labs.kql`** | KQL lab pack | The runnable, progressive endpoint query library — one labeled section per hunting lab (encoded-PowerShell, process→network correlation, per-device rollup, ASR audit events, logon anomalies) plus the capstone candidate. The core take-home artifact. |
| **`WSMDE-Discovery.ps1`** | Read-only | Inventories readiness: onboarded device count, endpoint-table freshness, and whether Live Response / advanced features are enabled. Changes nothing. |
| **`WSMDE-RunLab.ps1`** | Read-only | Runs a chosen hunting-lab query (`-Lab <n>`) from the pack via Graph and returns the rows — so learners can execute a lab from PowerShell as well as the portal. |
| **`WSMDE-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines and scores the knowledge-check `Check-MDELab-Pilot`: readiness, lab queries resolve, ASR audit-only, detection alert-only. |
| **`WSMDE-Report.ps1`** | Read-only | Reports cohort progress and per-lab data availability (rows returned per lab); exports to CSV as workshop evidence. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Learner cohort group:** `Grp-MDEWorkshop-Cohort`
- **Pilot lab device group:** `Grp-MDE-LabDevices-Pilot`
- **Shared saved-query set:** `Hunt-MDELab-Pilot`
- **ASR lab config (audit):** `ASR-Lab-AuditOnly-Pilot`
- **Custom detection (capstone):** `Detect-MDELab-Pilot` (alert-only)
- **Knowledge-check:** `Check-MDELab-Pilot`

## What this workshop deliberately does NOT do

- It does **not** onboard or tune MDE — that is the **MDE onboarding accelerator** and **optimization**
  catalog solutions. This workshop **uses** an onboarded MDE.
- It does **not** execute production response — Live Response uses **read-only** commands, ASR lab
  rules run in **audit**, the capstone detection is **alert-only**, and response actions are
  **taught and gated**, not fired against production.
- It does **not** decide **which ASR rules to enforce, which detections to promote, or acceptable
  false-positive rates** — those are security-leadership determinations; the workshop provides the
  skill, the labs, and the data.
- It does **not** invent plan, feature, or schema facts — where availability may differ by plan
  (P1/P2) or cloud (GCC/GCC High) it says **verify in your tenant**.

## How it is delivered

This workshop is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the
documentation as a formatted Word document and PDF, plus the endpoint KQL lab pack and all four
PowerShell helpers, in a single ZIP (`WSMDE-Complete-Solution.zip`) — yours to keep and re-run for
every new cohort.
