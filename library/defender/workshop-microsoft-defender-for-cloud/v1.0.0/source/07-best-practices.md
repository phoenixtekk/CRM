# 7. Best Practices & Where to Go Next — Workshop: Microsoft Defender for Cloud

## Running the workshop well
- **Teach against a pilot subscription, preview-first.** Every enable/Fix is rehearsed in `-WhatIf`; nothing changes production posture during training. Expand across the estate only through the customer's change process.
- **Read-only by default.** Attendees learn read-only; only the facilitator demonstrates a change, and only in `-WhatIf` / with approval on the pilot.
- **Use the sample-alerts action, not a real attack.** If the pilot is quiet, generate benign sample alerts in the portal for Lab 2 — never simulate a real attack against production.
- **Use consistent object names.** The `<Purpose> – <Scope> – <Stage>` convention keeps the take-home artifacts findable and reusable. Keep it.
- **Save the artifacts.** The three saved queries, the shortlist, the compliance export, and the ops-notes doc are the take-home runbook.

## Operating MDC well (the habits to instill)
- **Prioritize by real risk, not raw count.** Attack-path-linked and internet-exposed findings first; a long list of low-severity items is not an emergency. Secure Score is a trend to move, not a number to obsess over.
- **Make remediation a cadence, not a one-off.** Posture drifts as resources are created; review the score and recommendations on a schedule and track a shortlist you actually work.
- **Catch drift with continuous export.** Stream Secure Score/recommendations to a Log Analytics workspace/workbook (or Sentinel) so trend and regressions are visible.
- **Triage alerts with context.** Read severity + resource + MITRE + activity before escalating; hand the incident to the SOC with evidence.
- **Respect the approval gate.** Enabling paid plans, applying Fixes at scale, and accepting exemptions are cloud-ops/security/compliance decisions — the operator surfaces the data and the recommendation.
- **Mind cost, licensing, and preview.** Several Defender plans and Defender CSPM are **paid** per resource/subscription and version-dependent; *verify current pricing/availability in your tenant* before enabling at scale.

## Common anti-patterns to avoid
- Turning the workshop into a full CSPM rollout (that is the CSPM/Secure-Score program solution).
- Applying a **Fix** or enabling a paid plan across production "to show it works."
- Chasing Secure Score to 100% instead of prioritizing real risk and business context.
- Treating a compliance dashboard as a certification decision — that is the compliance team's call.

## Where to go next (adjacent catalog areas)
- **Defender for Cloud CSPM / Secure Score** — the full program: enable Defender CSPM, agentless scanning, governance rules, continuous export, and the remediation cadence at scale.
- **Microsoft Sentinel** — SIEM/SOAR to ingest MDC alerts and Secure Score for correlation, hunting, and automation.
- **Threat Hunting** — deeper cross-pillar KQL beyond the posture tables.
- **Identity / Zero Trust** — identity hardening that many top recommendations depend on.
- **Sibling Defender workshops** — Identity, Endpoint, Office 365, and Cloud Apps enablement workshops to round out the team's operating skills across the Defender suite.

The bottom line: a team that operates MDC with confidence — reading Secure Score and prioritizing by real risk, triaging workload alerts, reading compliance, and running a preview-first remediation cadence — using a runbook they keep and reuse.
