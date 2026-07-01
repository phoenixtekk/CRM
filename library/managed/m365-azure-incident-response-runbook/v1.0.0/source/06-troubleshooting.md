# 6. Troubleshooting — M365 & Azure Incident Response & Escalation Runbook

Failure modes you hit while *running* the runbook (not the incidents themselves), grouped by phase, each with a likely cause and a fix. For the incidents themselves, use the per-workload **Diagnostic Playbooks – Incident – Diagnose** in §03 (A6).

---

## Access & visibility (Detect / Diagnose)

**Symptom: a responder can't open Service health / sign-in logs / message trace.**
- *Cause:* missing reader/admin role (R3–R7). *Fix:* assign **Global Reader** / **Service Support Administrator** (Service health), **Reports/Security Reader** (sign-in logs), **Exchange Administrator** or custom RBAC (message trace), **Monitoring Reader** (Azure). Re-run `INCIDENT-Validation.ps1`.

**Symptom: `Connect-ExchangeOnline` or `Connect-MgGraph` fails for a responder.**
- *Cause:* module not installed, or the account lacks consent/role. *Fix:* `Install-Module ExchangeOnlineManagement, Microsoft.Graph -Scope CurrentUser`; confirm the role (R5/R4); for Graph, ensure the requested scopes are consented.

**Symptom: Identity Protection / Risky sign-ins blade is empty or hidden.**
- *Cause:* **Entra ID P2** not licensed (R4). *Fix:* license P2, or document that risk-based diagnosis is unavailable and rely on raw sign-in logs.

**Symptom: Azure Monitor has no historical data at incident time.**
- *Cause:* diagnostic settings weren't sending logs to Log Analytics before the incident (R7/G4). *Fix:* enable diagnostic settings now with adequate retention; you cannot retroactively create history.

## Service Health discrimination (Triage)

**Symptom: hours spent diagnosing a tenant fault that was actually a Microsoft outage.**
- *Cause:* skipped the **Microsoft Service Health Playbook – Diagnose – Platform** (A6.1). *Fix:* enforce Service-Health-first in Phase 2; check **both** `admin.microsoft.com → Health → Service health` **and** `portal.azure.com → Service Health`.

**Symptom: Service health shows nothing but users are clearly impacted.**
- *Cause:* localized/region issue not yet posted, or a tenant-specific cause. *Fix:* don't wait for Microsoft to post — proceed to the workload playbook; capture correlation IDs to escalate if it proves Microsoft-side.

## Triage & roles

**Symptom: incidents get mis-prioritized or response is inconsistent.**
- *Cause:* matrix targets not aligned to SLAs, or no Incident Lead named (R11/A3). *Fix:* sync the **Severity & Impact Matrix – Incident – Triage** to contracts; require an Incident Lead before diagnosis.

**Symptom: engineers swamped with status requests, can't focus on the fix.**
- *Cause:* no Communications Lead routing comms. *Fix:* for P1/P2, always name a Communications Lead (A3); route all status questions through them.

## Communication

**Symptom: client complains they were "left in the dark."**
- *Cause:* missed the cadence or never sent the Initial notification. *Fix:* set the cadence reminder at triage; send the Initial even with no answers yet; send "no change" updates on schedule (A4, R11).

**Symptom: client confused or alarmed by an update.**
- *Cause:* internal jargon or premature speculation on cause. *Fix:* use the templates verbatim; state impact, action, workaround, and next-update time only; keep cause out until evidenced.

## Escalation to Microsoft

**Symptom: can't set the severity you expected when opening a case.**
- *Cause:* the severity is **plan-dependent** (R8) — e.g. Azure **Sev A** needs a paid Azure support plan. *Fix:* correct the **Microsoft Escalation Sheet – Incident – Escalate** to reflect what your plan actually permits; if you need faster response, acquire **Microsoft Unified** / an Azure support plan.

**Symptom: Microsoft case stalls or bounces back for "more info."**
- *Cause:* opened with symptoms only. *Fix:* attach the Phase-4 evidence (correlation IDs, message traces, sign-in error codes, Resource Health statements); reference the affected resource/region precisely.

## Remediation

**Symptom: `INCIDENT-Remediation.ps1` didn't change anything.**
- *Cause:* it defaults to `-WhatIf` (by design). *Fix:* review the preview, then re-run with `-Apply`. Never add `-Apply` blindly.

**Symptom: a remediation made things worse / hit the wrong object.**
- *Cause:* ran broadly instead of on a named object, or skipped the emergency-change rule (R12). *Fix:* always target a named object; follow the back-out in the Incident Record; record the change.

## RCA → Permanent Fix loop

**Symptom: the same incident keeps recurring.**
- *Cause:* fixes stopped at mitigation; no permanent fix tracked. *Fix:* enforce Phase 7 — complete the **RCA Template – Incident – Review** with 5-Whys and open a **Problem Record – Incident – Permanent Fix** with an owner and date.

**Symptom: RCA is late, thin, or missing.**
- *Cause:* no contemporaneous timeline (Scribe role skipped) or no agreed window. *Fix:* keep the Scribe's timeline live during the incident; set an RCA SLA (e.g. ≤5 business days for P1) and gate closure on the RCA existing.

**Symptom: MTTA/MTTR can't be computed.**
- *Cause:* missing Detected/Acknowledged/Resolved timestamps in the Incident Record. *Fix:* make those fields mandatory in the **Incident Record Template – Incident – Lifecycle** (A2); re-run `INCIDENT-Report.ps1`.
