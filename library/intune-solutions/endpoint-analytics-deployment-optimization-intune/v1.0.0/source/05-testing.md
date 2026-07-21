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
