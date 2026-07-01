# 7. Best Practices — M365 & Azure Incident Response & Escalation Runbook

These are the operating disciplines that make the runbook effective in practice. They assume the named artifacts from §03 are in place and reused verbatim.

## Triage & prioritization

- **Service Health first, always.** Run the **Microsoft Service Health Playbook – Diagnose – Platform** before any deep local diagnosis. The cheapest minute in any incident is the one that tells you it's a Microsoft outage.
- **Prioritize by impact × risk × effort.** Take the highest-impact, lowest-risk, lowest-effort mitigation first. A 30-second workaround that restores 200 users beats a 2-hour "proper" fix while they wait.
- **Mitigate before you perfect.** Restore service first; do the elegant root-cause fix after. Record the mitigation and the resolution as separate timeline entries (they drive different metrics).
- **Sever the symptom from the cause.** "It works again" after a restart is a mitigation, not a root cause. Phase 7 is non-negotiable for P1/P2.

## Roles & coordination

- **Name the Incident Lead before diagnosis.** Even a one-person response names the Lead in the record. Diffuse ownership is how incidents drift.
- **Protect the engineers.** For P1/P2, route all client/stakeholder status requests through the **Communications Lead** so the people fixing the problem can fix the problem.
- **The Scribe is not optional under pressure.** A contemporaneous, timestamped timeline is what makes the RCA accurate and fast. Reconstructing it from memory afterward loses the truth.

## Client communication

- **Communicate early, even with little to say.** The Initial notification builds trust precisely because it goes out before you have answers. Silence is what erodes confidence.
- **Hold the cadence religiously.** Send the Update at every interval, including "still investigating, next update by HH:MM." Missing a promised update is its own incident.
- **Calm, factual, jargon-free.** Clients want impact, what you're doing, any workaround, and the next update time — not packet captures.
- **Never speculate publicly on cause** until you have evidence; preliminary cause goes in Resolution, confirmed cause goes in the Post-Incident summary.

## Diagnosis

- **Capture correlation IDs as you go** (message-trace IDs, sign-in request IDs, Resource Health correlation IDs). They are gold for a Microsoft escalation and worthless if you have to re-derive them.
- **Follow the named playbook in order.** The ordering encodes the fastest path to root cause for that workload; ad-hoc clicking is slower and skips checks.
- **Mind the dependency chain.** Teams leans on Exchange (calendar) and SharePoint (files); SharePoint/OneDrive lean on identity. Diagnose the dependency when the surface symptom doesn't add up.

## Escalation to Microsoft

- **Know your plan before the incident.** Re-confirm the **Microsoft Escalation Sheet – Incident – Escalate** entitlement periodically — *severity options and response are plan-dependent* and entitlements change. Azure **Sev A** generally needs a paid Azure support plan; **Microsoft Unified** gives managed-service breadth.
- **Escalate with evidence, not just symptoms.** Attach the diagnostic artifacts from Phase 4; a case with correlation IDs and message traces moves far faster.
- **Escalate internally on a clock, too.** Define when the Incident Lead pulls in a senior engineer or management — don't let a stuck P1 stay quietly stuck.

## Remediation safety

- **`-WhatIf` by default, `-Apply` deliberately.** `INCIDENT-Remediation.ps1` previews by default for a reason. Read the preview; apply only the named, scoped action.
- **Act on named objects only.** Revoke *this* user's sessions; re-enable *this* connector. Never run a remediation broadly under incident pressure.
- **Emergency change still has a record and a back-out.** Define what may be done before approval and what may not (R12); log every change in the Incident Record.

## RCA → Permanent Fix loop

- **5-Whys to the real cause.** Stop at "the certificate expired" and you'll be back; ask why it expired un-noticed and you'll add the monitor that prevents recurrence.
- **Every RCA action has an owner and a date.** Actions without owners don't happen.
- **Convert fixes into controls.** A permanent fix is usually a new alert/monitor, a config hardening, a policy, or a runbook update — track it as a **Problem Record – Incident – Permanent Fix** to closure. This is the Expand step that compounds reliability.
- **Feed the metrics.** Run `INCIDENT-Report.ps1` after each incident; a falling MTTA/MTTR and falling repeat-incident count is the proof the program works.

## Program hygiene

- **Run a tabletop quarterly.** The §05 simulation keeps the team fluent and surfaces access gaps before a real P1 does.
- **Keep access least-privilege and PIM-eligible.** Standing Global Admin for the whole team is an audit finding and a breach blast-radius; reader-first with eligible scoped admin is the target.
- **Keep the matrix and templates in sync with contracts.** When a client SLA changes, update the **Severity & Impact Matrix – Incident – Triage** the same day.
