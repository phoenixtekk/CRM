# Troubleshooting — Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage

Common failures, each as **symptom → cause → fix**. Start with `SENTRULE-Discovery.ps1` (rules,
templates, watchlists), `SENTRULE-Coverage.ps1` (the ATT&CK map), and `SENTRULE-Report.ps1` (alert /
false-positive rates) — most issues here are visible in one of the three.

---

## An enabled rule never fires

- **Symptom:** A rule is Enabled but produces no alerts, even for activity you can see in the logs.
- **Cause:** The query targets a table with no data (the source is not connected), the KQL returns
  nothing over the rule's window, the threshold is set too high, or the lookback/frequency is wrong.
- **Fix:** Run the rule's KQL manually in **Logs** over the same window — confirm it returns rows
  (Gate 1 / R1). Lower the threshold or widen the window to confirm the logic, then re-tighten.
  Confirm the source table is populated (`<Table> | take 10`).

## A rule fires constantly (false-positive flood)

- **Symptom:** One rule dominates the alert/incident queue; analysts close it without reading.
- **Cause:** No allow-list/suppression for known-benign activity, threshold too low, or alerts not
  grouped so every event becomes its own incident.
- **Fix:** Apply tuning in order (Phase 3): allow-list the known-good source via
  `WL-AuthorizedAdminIPs-Tenant`; add `AR-Suppress-KnownScanners-Pilot`; raise the threshold; fix
  grouping. Change one thing at a time and re-measure with `SENTRULE-Report.ps1`.

## A rule template does not appear under Rule templates

- **Symptom:** A detection you expected is not in **Analytics → Rule templates**.
- **Cause:** The Content hub solution that carries it is not installed (**R3**), or it is a different rule
  type than expected (e.g. a Microsoft ML rule enabled elsewhere).
- **Fix:** Content hub → install the relevant solution; refresh **Rule templates**. For ML/anomaly
  detections, check **Analytics → Anomalies** / the Microsoft security rules — some are enabled, not
  authored. *Verify availability in your tenant.*

## The MITRE ATT&CK coverage view looks empty or wrong

- **Symptom:** Sentinel → **MITRE ATT&CK** shows little coverage, or `SENTRULE-Coverage.ps1` reports gaps
  you thought were covered.
- **Cause:** Enabled rules are **not tagged** with tactics/techniques, or the tags do not match the
  techniques the rule actually detects.
- **Fix:** Edit each rule → **Set rule logic / MITRE ATT&CK mapping** → tag the correct tactics and
  techniques. The coverage map is only as accurate as the rule tags. Re-run `SENTRULE-Coverage.ps1`.

## A watchlist reference errors in a rule

- **Symptom:** A rule query fails with a watchlist/`_GetWatchlist` error.
- **Cause:** The watchlist alias is wrong, the watchlist was deleted/renamed, or the SearchKey column
  does not match the join.
- **Fix:** Confirm the alias in **Watchlists**; use the exact alias in `_GetWatchlist('<alias>')`; ensure
  the join column exists and matches the SearchKey. Do not delete a watchlist a rule references without
  updating the rule first.

## NRT rule will not save / behaves like a scheduled rule

- **Symptom:** `Rule-NewAdminRole-Entra-Pilot` (NRT) cannot be created, or does not run near-real-time.
- **Cause:** NRT has restrictions (limited number of NRT rules, query-shape constraints, supported table
  set) that the query violates, or NRT is not available in this cloud/tenant.
- **Fix:** Simplify the query to the NRT constraints, or implement it as a frequent **scheduled** rule
  instead. *Verify current NRT limits/eligibility in your tenant.*

## False-positive rate looks fine but real incidents are missed

- **Symptom:** Low noise, but a known test/attack did not raise an incident.
- **Cause:** Over-tuning — the threshold was raised or the suppression widened so far that real activity
  is now excluded; or the rule is still in low-impact posture (**Create incidents = Disabled**).
- **Fix:** Re-check the incident-creation setting (promote per Phase 5 once trusted); back off the
  threshold/suppression; run an attack simulation and confirm the alert fires. Tuning is a balance, not a
  race to zero alerts.

## Promoted rule floods incidents after enabling incident creation

- **Symptom:** A rule was quiet in low-impact posture but floods the queue once **Create incidents** is
  enabled.
- **Cause:** Alert **grouping** was not configured, so each alert opens its own incident.
- **Fix:** Configure alert grouping (group by the key entity over a time window) so related alerts form a
  single incident; re-measure before re-promoting.

## PowerShell / export errors

- **Symptom:** A script errors on connect, on the workspace, or on export.
- **Cause:** Wrong subscription context, missing `Az.SecurityInsights`, insufficient Sentinel role, or
  (Gov cloud) the wrong environment endpoint.
- **Fix:** `Connect-AzAccount` + `Set-AzContext`; `Install-Module Az.SecurityInsights`; confirm Sentinel
  Contributor (author/export) or Reader (report/coverage); for Government cloud pass `-Environment
  AzureUSGovernment` (**R7**) — *verify endpoints for your cloud*.
