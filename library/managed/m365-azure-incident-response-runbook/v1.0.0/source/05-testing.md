# 5. Testing — M365 & Azure Incident Response & Escalation Runbook

The runbook is validated with a **tabletop / simulated incident** (a controlled "game day"), not by waiting for a real P1. Each test below has an explicit **PASS/FAIL gate**. The overall acceptance gate is: **a simulated incident is triaged correctly, comms are sent on cadence, diagnosis reaches a real root cause, an RCA is produced, and a permanent fix is logged.** Run the full sequence at least once before relying on the runbook, and re-run after any major change to the estate or team.

> Run readiness checks (T1–T2) with `scripts\INCIDENT-Validation.ps1` and capture the simulation evidence in a real **Incident Record Template – Incident – Lifecycle** flagged `SIMULATION`.

---

## T1. Responder readiness — roles & access *(gate)*

- **Action:** Run `scripts\INCIDENT-Validation.ps1`. Independently spot-check that a responder can open: **M365 admin → Health → Service health**, **Entra → Monitoring → Sign-in logs**, **Exchange admin → Mail flow → Message trace**, **Azure → Service Health** and a resource's **Resource health**, and **Defender → Incidents** (R3–R7).
- **PASS:** Validation returns **PASS** on roles, log access, and the consoles all load for the responder account.
- **FAIL:** Any console denies access or Validation reports a missing role → fix via the cited Requirement before continuing.

## T2. Support-plan & escalation readiness *(gate)*

- **Action:** From the **Microsoft Escalation Sheet – Incident – Escalate**, confirm the recorded Microsoft entitlement matches what the portals show. Begin (do **not** submit) a support request in **Azure → Help + support → Create a support request** and in **M365 → Support → Help & support**; observe the **severity** options offered.
- **PASS:** Entitlement is documented and the severity options the runbook claims are the ones actually offered (plan-dependent reality matches the sheet).
- **FAIL:** The sheet over-states available severity or the entitlement is unknown → correct the sheet / acquire the plan (R8).

## T3. Triage correctness *(gate)*

- **Action:** Present 3 scripted scenarios (e.g. "all users can't sign in"; "one mailbox delayed"; "Teams calls failing for one site"). The responder classifies each with the **Severity & Impact Matrix – Incident – Triage** and names the **Incident Lead** (and, for P1/P2, Comms Lead + Scribe).
- **PASS:** All three are classified to the expected severity with correct response/cadence targets, and roles are named before diagnosis.
- **FAIL:** A scenario is mis-prioritized or no Incident Lead is named → re-train on A1/A3; refine the matrix wording.

## T4. Service Health discrimination *(gate)*

- **Action:** In the simulation, require the responder to run the **Microsoft Service Health Playbook – Diagnose – Platform** *before* deep diagnosis and state whether the cause is Microsoft-side or tenant-side.
- **PASS:** The responder checks both **M365 Health → Service health** and **Azure → Service Health** and correctly states is-this-Microsoft-or-us before diving in.
- **FAIL:** The responder skips Service Health and begins local diagnosis → enforce A6.1-first in Phase 2.

## T5. Communication on cadence *(gate)*

- **Action:** During the simulation, the Communications Lead sends the **Initial** notification within the severity's response target and an **Update** at each cadence interval, using **Client Comms Templates – Incident – Communicate** (to an internal test recipient).
- **PASS:** Initial sent within target; at least two cadence Updates sent on time; tone is factual and jargon-free.
- **FAIL:** Late/missing comms or improvised wording → fix the cadence reminder and template usage (A4, R11).

## T6. Diagnosis reaches root cause *(gate)*

- **Action:** Seed a diagnosable fault scenario (or replay a past incident). The responder follows the matching **Diagnostic Playbook – Incident – Diagnose** and produces a stated **root cause** with supporting evidence (trace ID, sign-in error code, Resource Health statement).
- **PASS:** A genuine root cause (the *why*) is reached with cited evidence — not merely "restarted it and it works."
- **FAIL:** Diagnosis stops at the symptom → review the relevant A6 playbook; confirm log access (R4–R7).

## T7. Remediation safety *(gate)*

- **Action:** Run `scripts\INCIDENT-Remediation.ps1` against a named non-production object **without** `-Apply`; then with `-Apply` in a sanctioned test.
- **PASS:** Default run makes **no change** and prints the intended action (`-WhatIf`); `-Apply` performs only the named, scoped action and it is logged in the Incident Record (R12).
- **FAIL:** The script changes anything without `-Apply`, or acts beyond the named object → stop; correct before live use.

## T8. RCA produced *(gate)*

- **Action:** After the simulated resolution, complete the **RCA Template – Incident – Review** from the Incident Record timeline, including a 5-Whys root cause and corrective actions with owners/dates.
- **PASS:** A complete RCA exists within the agreed window with a real root cause and owned corrective actions.
- **FAIL:** RCA missing, late, or root-cause-free → enforce Phase 7; refine the template (A7).

## T9. Permanent fix logged *(gate — overall)*

- **Action:** For at least one corrective action, open a **Problem Record – Incident – Permanent Fix** with an owner and due date and link it to the RCA and incident. Run `scripts\INCIDENT-Report.ps1` and confirm MTTA/MTTR computed.
- **PASS:** A Problem Record exists for the permanent control, the loop is closed (incident → RCA → permanent fix), and the metrics report generates.
- **FAIL:** No permanent fix tracked (the incident can recur) or metrics don't compute → the overall gate fails; do not certify the runbook until closed.

---

## Acceptance gate (overall)

The runbook **passes** when, in a single end-to-end simulation, **all of T1–T9 PASS**: readiness confirmed, triage correct, Service Health checked, comms on cadence, diagnosis reaching root cause, safe remediation, a produced RCA, and a logged permanent fix — with MTTA/MTTR captured. Record the simulation Incident Record and the Validation/Report CSVs as the certification evidence.
