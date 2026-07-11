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
