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
