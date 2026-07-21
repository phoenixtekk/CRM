# 5. Testing & Validation — Anomaly Detection & Application Reliability with Endpoint Analytics

Validate the reliability practice against a **pilot scope** (`Reliability – Pilot`) before you widen it
to the fleet. Each test has an explicit **pass/fail gate**. Use the included PowerShell scripts
(Microsoft Graph) for the scripted checks and the Endpoint Analytics reports for the read-and-interpret
tests.

> **Navigation and feature specifics — verify against current Microsoft documentation.** Report names,
> blade paths, and anomaly-detection availability change and can differ by cloud. The *tests* below are
> about the practice (is the signal present, correctly identified, correctly interpreted); confirm the
> exact portal locations in your own tenant.

## Test 1 — Reliability signals are populated
**Procedure:** Run `ENDPTREL-Discovery.ps1`; open **Endpoint analytics → Application reliability** and
the **device reliability / restart** report.
**Pass:** Application reliability and device/restart signals return data with a device count consistent
with your scope (not empty, not a handful of devices). `ENDPTREL-Discovery.ps1` reports data present.
**Fail:** Signals empty or thin → finish the **parent** Endpoint Analytics solution (enable + data
collection) and allow the reporting window to fill before continuing. *(Data latency/minimum population
— verify against current Microsoft documentation.)*

## Test 2 — Pilot readiness gate
**Procedure:** Run `ENDPTREL-Validate.ps1 -PilotGroupName 'Reliability – Pilot'`.
**Pass:** Application-reliability data present, device/restart data present, the `Reliability – Pilot`
group exists, and anomaly detection responds (anomalies **or** an explicit "no anomalies"). Overall
verdict READY.
**Fail:** Any hard check FAIL → resolve it. An anomaly-detection **WARN** (unavailable/preview) is
acceptable — proceed with the application- and device-reliability portions.

## Test 3 — A known bad app is correctly identified
**Procedure:** Pick an app you know is failing (a seeded/known bad app, or the worst app in the report)
and run `ENDPTREL-Test-Signal.ps1 -AppNameLike '<app>'`. Cross-check against **Application reliability**.
**Pass:** The signal is **DETECTED** and attributable to that app; the crash/hang counts and affected-
device count match what the report shows.
**Fail:** NOT DETECTED for an app you know is failing → confirm the app is in the reporting scope and
the reliability data is current (Test 1); verify the Graph resource path against current Microsoft
documentation.

## Test 4 — Bad app vs. bad rollout is separated correctly
**Procedure:** For the app from Test 3, inspect the **version** breakdown in Application reliability.
**Pass:** You can state which it is with evidence — **bad version/rollout** (one version bad, prior
version clean, spike began right after that version deployed) **or** **bad app** (all versions crash
across a broad, mixed population) — and you have identified the correct owner (deployment owner vs. app
owner).
**Fail:** The two cannot be distinguished → widen the observation window, confirm the version dimension
is available, and re-read before routing (routing the wrong owner wastes the loop).

## Test 5 — A restart trend is correctly attributed
**Procedure:** In the **device reliability / restart** report, examine the unexpected-restart trend and
identify a rise (fleet-wide or model-scoped). Line its start time up against your change calendar.
**Pass:** The rise is attributed to a plausible cause with evidence — **fleet-wide after an OS update**
→ update owner; **single hardware model** → driver/firmware owner — including the cohort and the start
time.
**Fail:** The spike can't be attributed → check whether the cohort is too small (high variance), widen
the window, and confirm restart data is current before acting.

## Test 6 — An anomaly is correctly interpreted (true signal)
**Procedure:** With anomaly detection available, open the **anomaly** view and pick an anomaly. Read the
metric, the cohort, and the start time; cross-check it against the underlying report (Test 3 or Test 5).
**Pass:** The anomaly corresponds to a **real movement** in application reliability or restart analytics,
correlates with a change event, affects a meaningful cohort, and **persists** across a data refresh —
i.e. it is a **true signal** worth triaging, and you routed it (Test 8).
**Fail:** The "anomaly" has no corresponding movement in the underlying data → treat as suspect; see
Test 7.

## Test 7 — A false signal is correctly rejected
**Procedure:** For any anomaly that looks transient (tiny cohort, coincides with a reporting gap, no
underlying movement), watch it across the next data refresh.
**Pass:** The transient signal **fades** on refresh and is correctly **not** actioned — no remediation
effort spent, noted as a false lead. You can articulate *why* it was false (variance / reporting gap /
no underlying movement).
**Fail:** A false signal was escalated into a remediation → tighten the "confirm it's real" step
(persistence + underlying-movement cross-check) before routing anomalies.

## Test 8 — Triage routes to the right owner and closes the loop
**Procedure:** For a confirmed signal, create the handoff item `Reliability Handoff – <App|Driver|Update>
– <Version>`, route it to the owner, and — where scriptable — hand the fix to the **automated-fix
companion** (Proactive Remediations at Scale). After the fix, re-read the report and re-run
`ENDPTREL-Test-Signal.ps1`.
**Pass:** The signal routed to the correct owner with evidence; where scriptable, the fix was handed to
the companion (not fixed by hand); and after the fix the signal **recovers** (crashes/hangs fall,
restart trend flattens, or the anomaly clears) — `ENDPTREL-Test-Signal.ps1` now returns NOT DETECTED at
problem levels.
**Fail:** The signal doesn't recover → re-open the handoff, confirm the fix reached the affected cohort,
and re-verify.

## Test 9 — The review cadence and export work end to end
**Procedure:** Run `ENDPTREL-Report.ps1` and confirm it writes `Reliability Review – <YYYY-MM>.csv` with
Application, Device, and Anomaly sections. Confirm the `Reliability – Review Scope` group exists (create
it with `ENDPTREL-Set-ReviewScope.ps1 -Commit` if needed).
**Pass:** The CSV is written with the three sections and the review scope group exists; the review can
run on a schedule against it.
**Fail:** Export empty or the group missing → resolve data availability (Test 1) and create the scope
group before relying on the cadence.

## Acceptance gate
Proceed from **Pilot** to **Expand** only when Tests 1–8 pass (Test 9 confirms the cadence is
operable): reliability signals are populated, a known bad app and a restart trend are **correctly
identified**, an anomaly is **correctly interpreted vs. a false signal**, and at least one confirmed
signal has been **routed and verified to recover**.
