# 5. Testing — M365 & Azure Incident Response & Escalation Runbook (Government / GCC High edition)

The runbook is validated with a **tabletop / simulated incident** (a controlled "game day") on the **GCC High** tenant, not by waiting for a real P1. Each test below has an explicit **PASS/FAIL gate**. The overall acceptance gate is: **a simulated incident is triaged correctly, comms are sent on cadence, diagnosis reaches a real root cause using the `*.us` consoles, an RCA is produced, and a permanent fix is logged.** Run the full sequence at least once before relying on the runbook, and re-run after any major change to the estate, the team, or **Microsoft's GCC High feature parity** (the gaps close over time).

> Run readiness checks (T1–T2) with `scripts\INCIDENTG-Validation.ps1` (it connects with `-Environment USGov`) and capture the simulation evidence in a real **Incident Record Template – Incident – Lifecycle** flagged `SIMULATION`.

---

## T1. Responder readiness — roles & access (sovereign consoles) *(gate)*

- **Action:** Run `scripts\INCIDENTG-Validation.ps1`. Independently spot-check that a responder can open: **M365 admin (`portal.office365.us`) → Health → Service health**, **Entra (`entra.microsoft.us`) → Monitoring → Sign-in logs**, **Exchange admin (`admin.exchange.office365.us`) → Mail flow → Message trace**, **Azure (`portal.azure.us`) → Service Health** and a resource's **Resource health**, and **Defender (`security.microsoft.us`) → Incidents** (R3–R7).
- **PASS:** Validation returns **PASS** on roles, log access, and the **`*.us`** consoles all load for the responder account.
- **FAIL:** Any console denies access, a `*.com` URL was used by habit, or Validation reports a missing role → fix via the cited Requirement before continuing.

## T2. Support-plan & escalation readiness (GCC High) *(gate)*

- **Action:** From the **Microsoft Escalation Sheet – Incident – Escalate**, confirm the recorded Microsoft entitlement matches what the portals show. Begin (do **not** submit) a support request in **Azure (`portal.azure.us`) → Help + support → Create a support request** and in **M365 (`portal.office365.us`) → Support → Help & support**; observe the **severity** options offered. Confirm the sheet does **not** list Threat Experts as an escalation path.
- **PASS:** Entitlement is documented against the GCC High support surface and the severity options the runbook claims are the ones actually offered (plan-dependent reality matches the sheet); no unavailable capability (Threat Experts) is listed as a lifeline.
- **FAIL:** The sheet over-states available severity, references a Commercial support path, cites Threat Experts, or the entitlement is unknown → correct the sheet / acquire the plan (R8).

## T3. Triage correctness *(gate)*

- **Action:** Present 3 scripted scenarios (e.g. "all users can't sign in"; "one mailbox delayed"; "Teams calls failing for one site"). The responder classifies each with the **Severity & Impact Matrix – Incident – Triage** and names the **Incident Lead** (and, for P1/P2, Comms Lead + Scribe).
- **PASS:** All three are classified to the expected severity with correct response/cadence targets, and roles are named before diagnosis.
- **FAIL:** A scenario is mis-prioritized or no Incident Lead is named → re-train on A1/A3; refine the matrix wording.

## T4. Service Health discrimination (sovereign) *(gate)*

- **Action:** In the simulation, require the responder to run the **Microsoft Service Health Playbook – Diagnose – Platform** *before* deep diagnosis and state whether the cause is Microsoft-side or tenant-side — using the **`*.us`** consoles.
- **PASS:** The responder checks both **M365 (`portal.office365.us`) Health → Service health** and **Azure (`portal.azure.us`) → Service Health** and correctly states is-this-Microsoft-or-us before diving in.
- **FAIL:** The responder skips Service Health, or checks the Commercial consoles, → enforce A6.1-first (in `*.us`) in Phase 2.

## T5. Communication on cadence *(gate)*

- **Action:** During the simulation, the Communications Lead sends the **Initial** notification within the severity's response target and an **Update** at each cadence interval, using **Client Comms Templates – Incident – Communicate** (to an internal test recipient).
- **PASS:** Initial sent within target; at least two cadence Updates sent on time; tone is factual and jargon-free.
- **FAIL:** Late/missing comms or improvised wording → fix the cadence reminder and template usage (A4, R11).

## T6. Diagnosis reaches root cause (no waiting on absent features) *(gate)*

- **Action:** Seed a diagnosable fault scenario (or replay a past incident). The responder follows the matching **Diagnostic Playbook – Incident – Diagnose** in the **`*.us`** consoles and produces a stated **root cause** with supporting evidence (trace ID, sign-in error code, Resource Health statement).
- **PASS:** A genuine root cause (the *why*) is reached with cited evidence — reached **manually**, without stalling to wait for Automated investigation (AIR) or a Threat Experts note that GCC High may not provide.
- **FAIL:** Diagnosis stops at the symptom, or the responder waits on an AIR/Threat-Experts capability that isn't available in GCC High → review the relevant A6 playbook and `gcc-high-parity-notes.md`; confirm log access (R4–R7).

## T7. Remediation safety (US Gov endpoints) *(gate)*

- **Action:** Run `scripts\INCIDENTG-Remediation.ps1` against a named non-production object **without** `-Apply` (it connects with `-Environment USGov`); then with `-Apply` in a sanctioned test.
- **PASS:** Default run makes **no change** and prints the intended action (`-WhatIf`); `-Apply` performs only the named, scoped action against the **US Gov** endpoint and it is logged in the Incident Record (R12).
- **FAIL:** The script changes anything without `-Apply`, acts beyond the named object, or connects to a Commercial endpoint → stop; correct before live use.

## T8. RCA produced *(gate)*

- **Action:** After the simulated resolution, complete the **RCA Template – Incident – Review** from the Incident Record timeline, including a 5-Whys root cause and corrective actions with owners/dates.
- **PASS:** A complete RCA exists within the agreed window with a real root cause and owned corrective actions.
- **FAIL:** RCA missing, late, or root-cause-free → enforce Phase 7; refine the template (A7).

## T9. Permanent fix logged *(gate — overall)*

- **Action:** For at least one corrective action, open a **Problem Record – Incident – Permanent Fix** with an owner and due date and link it to the RCA and incident. Run `scripts\INCIDENTG-Report.ps1` and confirm MTTA/MTTR computed.
- **PASS:** A Problem Record exists for the permanent control, the loop is closed (incident → RCA → permanent fix), and the metrics report generates. (Where a Secure Score / MDVM item would be the natural control but is absent in GCC High, the control is tracked directly.)
- **FAIL:** No permanent fix tracked (the incident can recur) or metrics don't compute → the overall gate fails; do not certify the runbook until closed.

---

## Acceptance gate (overall)

The runbook **passes** when, in a single end-to-end simulation on the GCC High tenant, **all of T1–T9 PASS**: readiness confirmed in the `*.us` consoles, triage correct, Service Health checked, comms on cadence, diagnosis reaching root cause manually, safe remediation against US Gov endpoints, a produced RCA, and a logged permanent fix — with MTTA/MTTR captured. Record the simulation Incident Record and the Validation/Report CSVs as the certification evidence.
