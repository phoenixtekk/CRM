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
