# 7. Best Practices — M365 & Azure Incident Response & Escalation Runbook (Government / GCC High edition)

These are the operating disciplines that make the runbook effective in practice on a **GCC High** tenant. They assume the named artifacts from §03 are in place and reused verbatim.

## Sovereign-cloud discipline (GCC High-specific)

- **Every URL is a `*.us` URL.** Bookmark the sovereign consoles (`portal.office365.us`, `entra.microsoft.us`, `admin.exchange.office365.us`, `admin.gov.teams.microsoft.us`, `intune.microsoft.us`, `security.microsoft.us`, `portal.azure.us`) and use them. A `*.com` habit sends you to a Commercial tenant that doesn't hold your client's data. Keep `gcc-high-parity-notes.md` one click away.
- **Always pass the US Gov environment in PowerShell.** `Connect-MgGraph -Environment USGov`, `Connect-AzAccount -Environment AzureUSGovernment`, `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh`. The most common "it won't connect" error mid-incident is a missing `-Environment USGov`. Consider setting `$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'` on responder workstations.
- **Know the parity gaps cold.** Do not build a step around a capability GCC High lacks: **no Threat Experts**, **AIR lags (verify)**, **no enterprise-IoT Defender**, **some Secure Score / MDVM items absent**. Re-verify these each quarter — Microsoft closes gaps, and a stale "not available" note is as harmful as a wrong URL.
- **Stay in-boundary.** Keep evidence, the war-room, and the system of record within approved in-scope services; the whole point of GCC High is that data doesn't leak to Commercial. The audit trail is part of the compliance posture, not overhead.

## Triage & prioritization

- **Service Health first, always — in `*.us`.** Run the **Microsoft Service Health Playbook – Diagnose – Platform** before any deep local diagnosis, in `portal.office365.us` and `portal.azure.us`. The cheapest minute in any incident is the one that tells you it's a Microsoft outage.
- **Prioritize by impact × risk × effort.** Take the highest-impact, lowest-risk, lowest-effort mitigation first. A 30-second workaround that restores 200 users beats a 2-hour "proper" fix while they wait.
- **Mitigate before you perfect.** Restore service first; do the elegant root-cause fix after. Record the mitigation and the resolution as separate timeline entries (they drive different metrics).
- **Sever the symptom from the cause.** "It works again" after a restart is a mitigation, not a root cause. Phase 7 is non-negotiable for P1/P2.

## Roles & coordination

- **Name the Incident Lead before diagnosis.** Even a one-person response names the Lead in the record. Diffuse ownership is how incidents drift.
- **Protect the engineers.** For P1/P2, route all client/stakeholder status requests through the **Communications Lead** so the people fixing the problem can fix the problem.
- **The Scribe is not optional under pressure.** A contemporaneous, timestamped timeline is what makes the RCA accurate and fast — and, in a regulated estate, what satisfies the audit.

## Client communication

- **Communicate early, even with little to say.** The Initial notification builds trust precisely because it goes out before you have answers. Silence is what erodes confidence.
- **Hold the cadence religiously.** Send the Update at every interval, including "still investigating, next update by HH:MM." Missing a promised update is its own incident.
- **Calm, factual, jargon-free.** Clients want impact, what you're doing, any workaround, and the next update time — not packet captures.
- **Never speculate publicly on cause** until you have evidence; preliminary cause goes in Resolution, confirmed cause goes in the Post-Incident summary.

## Diagnosis

- **Capture correlation IDs as you go** (message-trace IDs, sign-in request IDs, Resource Health correlation IDs). They are gold for a Microsoft escalation and worthless if you have to re-derive them.
- **Follow the named playbook in order.** The ordering encodes the fastest path to root cause for that workload; ad-hoc clicking is slower and skips checks.
- **Don't wait on features GCC High may not have.** If you expected AIR to have auto-investigated or a Threat Experts insight to appear and it hasn't, that's expected here — continue the **manual** playbook rather than stalling. Advanced hunting (KQL) in `security.microsoft.us` is available for GA features and is a strong manual tool.
- **Mind the dependency chain.** Teams leans on Exchange (calendar) and SharePoint (files); SharePoint/OneDrive lean on identity. Diagnose the dependency when the surface symptom doesn't add up.

## Escalation to Microsoft

- **Know your GCC High plan before the incident.** Re-confirm the **Microsoft Escalation Sheet – Incident – Escalate** entitlement periodically — *severity options and response are plan-dependent* and confirmed in the `*.us` support surface. Azure **Sev A** generally needs a paid Azure support plan; **Microsoft Unified** gives managed-service breadth.
- **The escalation is a support case — there is no Threat Experts lifeline in GCC High.** Open the case in the GCC High portal and attach the Phase-4 evidence; a case with correlation IDs and message traces moves far faster.
- **Escalate internally on a clock, too.** Define when the Incident Lead pulls in a senior engineer or management — don't let a stuck P1 stay quietly stuck.

## Remediation safety

- **`-WhatIf` by default, `-Apply` deliberately.** `INCIDENTG-Remediation.ps1` previews by default for a reason, and connects only to the **US Gov** endpoint. Read the preview; apply only the named, scoped action.
- **Act on named objects only.** Revoke *this* user's sessions; re-enable *this* connector. Never run a remediation broadly under incident pressure.
- **Emergency change still has a record and a back-out.** Define what may be done before approval and what may not (R12); log every change in the Incident Record — the change trail is a compliance artifact in GCC High.

## RCA → Permanent Fix loop

- **5-Whys to the real cause.** Stop at "the certificate expired" and you'll be back; ask why it expired un-noticed and you'll add the monitor that prevents recurrence.
- **Every RCA action has an owner and a date.** Actions without owners don't happen.
- **Convert fixes into controls.** A permanent fix is usually a new alert/monitor, a config hardening, a policy, or a runbook update — track it as a **Problem Record – Incident – Permanent Fix** to closure. Where the natural control would be a Secure Score / Defender Vulnerability Management recommendation that is **absent in GCC High**, track the control directly instead of citing a feature you don't have.
- **Feed the metrics.** Run `INCIDENTG-Report.ps1` after each incident; a falling MTTA/MTTR and falling repeat-incident count is the proof the program works.

## Program hygiene

- **Run a tabletop quarterly — and re-check parity while you do.** The §05 simulation keeps the team fluent and surfaces access gaps before a real P1 does; use the same cadence to re-verify the GCC High parity notes against Microsoft's current docs.
- **Keep access least-privilege and PIM-eligible.** Standing Global Admin for the whole team is an audit finding and a breach blast-radius; reader-first with eligible scoped admin is the target.
- **Keep the matrix and templates in sync with contracts.** When a client SLA changes, update the **Severity & Impact Matrix – Incident – Triage** the same day.
