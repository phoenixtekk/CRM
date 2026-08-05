# 6. Troubleshooting Guide — Application Management Current-State Assessment & Modernization Roadmap

Assessments fail differently from deployments. Nothing breaks in production — instead the *evidence*
comes up short, a stakeholder won't engage, or the tenant access is narrower than promised. Each entry
below is **Symptom → Cause → Resolution**, and the guiding rule throughout is the same: when evidence is
missing, record it honestly as a gap. Never invent a score to fill a hole.

## Access and connection

### `Connect-MgGraph` fails or the scripts return no data
**Symptom:** A script throws "Not connected," or returns zero apps despite the tenant clearly having
apps.
**Cause:** No Graph session, missing read scopes, or (common) the account has the **Intune
Administrator** role but the delegated Graph scopes were never consented; or the tenant is Government and
the Commercial endpoint was used.
**Resolution:** Run `Connect-MgGraph` with the six read scopes from Requirement 2.2 and confirm with
`Get-MgContext` that they are present and end in `.Read.All`. For a Government tenant, add
`-Environment USGov` (GCC High) or `-Environment USGovDoD` (DoD). If your tenant requires admin consent
for delegated permissions, have a Global Administrator consent once. Re-run
`APPASMT-Estate-Inventory.ps1 -WhatIfAccessCheck`.

### A whole dimension reads as empty / "insufficient evidence"
**Symptom:** `APPASMT-Maturity-Evidence.ps1` marks D5 (app control) or D9 (migration debt) as
"Insufficient Evidence — could not read."
**Cause:** The assessor account cannot read that object type — usually a scoped RBAC assignment or a
missing scope (e.g. `DeviceManagementConfiguration.Read.All` for app-control policies), or the feature
is genuinely absent/unlicensed.
**Resolution:** Confirm the scope is consented and the **Read Only Operator** assignment is scoped to
All (not a subset). If access is correct and the object still isn't there, the capability really is
absent — score the dimension L1 with the evidence "no policy present," **not** "Insufficient Evidence."
The two are different findings: one says "we can't see it," the other says "it isn't there." Only use
"Insufficient Evidence" when you genuinely could not read.

### The customer will only grant a scoped or time-limited role
**Symptom:** The assessor is given Read Only Operator scoped to one business unit, or access for 48
hours only.
**Cause:** Reasonable customer caution on a first engagement.
**Resolution:** Accept it and **record the scope limit in the charter and on every affected score.** A
scorecard built on one business unit is valid for that unit — say so explicitly; do not present it as
tenant-wide. For time-limited access, run all five scripts first (they are fast and read-only) to
capture the Evidence Pack while access lasts; interviews and artifact review need no tenant access and
can follow.

## Data quality and scoring

### The install-status or version-drift numbers look implausibly low
**Symptom:** `APPASMT-Install-Health.ps1` shows almost no failures, or no version drift, on an estate
you expect to be messy.
**Cause:** The `installSummary` beta endpoint can lag or return partial data, and the version-drift
normalization strips version tokens from display names — apps whose names don't embed a version won't be
grouped.
**Resolution:** Treat the script output as a **signal, not a verdict.** Corroborate with the Intune
portal (**Apps → Monitor → App install status**) for a sample, and with the version column in
`APPASMT-Estate-Inventory.csv`. Where naming is inconsistent enough that drift can't be detected
automatically, that inconsistent naming is itself a D2 (Packaging Standards) finding.

### Interview answers contradict the technical data
**Symptom:** Engineering says "we always deploy in rings," but `APPASMT-Assignment-Analysis.ps1` shows
apps assigned to All Devices.
**Cause:** The intended process and the actual practice have diverged — the single most common (and
valuable) assessment finding.
**Resolution:** Do **not** quietly pick a side. Record the contradiction as a finding against D3, cite
both the interview and the script output, and let the readout surface it. The gap between belief and
reality is exactly what the assessment exists to reveal.

### Two assessors score the same dimension differently
**Symptom:** A review of the `APPASMT – Scoring Sheet` finds inconsistent levels for the same evidence.
**Cause:** The evidence table in Implementation Step 5 was applied loosely — someone awarded a level on
partial evidence.
**Resolution:** Re-apply the rule: a level requires **all** of its evidence; partial evidence scores the
level below. Reconcile against the table, not against each other's opinion. If the table itself is
ambiguous for this tenant, tighten the wording in the charter's model annex and re-score consistently.

## Stakeholders and scope

### A key stakeholder won't engage or keeps cancelling
**Symptom:** The service-desk lead or an app owner never makes the interview, so D8 (Support) or D1
(Governance) has no interview evidence.
**Cause:** Competing priorities, or the role is genuinely unstaffed.
**Resolution:** Escalate through the sponsor named in the charter — engagement is the sponsor's to
enforce. If the role is unstaffed ("no one actually owns app security review"), that absence **is the
finding** — record it against the dimension with "role unstaffed" as the evidence and a governance
finding in the register. Do not leave the dimension blank; an unstaffed function is a low maturity
score, honestly evidenced.

### The customer pushes to expand scope mid-assessment
**Symptom:** "While you're in there, can you also assess configuration profiles / compliance / drivers?"
**Cause:** The assessment is surfacing value and the customer wants more.
**Resolution:** Hold the charter. Note the request as a candidate for a **follow-on** engagement and
keep this assessment to the nine application-management dimensions. Scope creep is the most common way an
assessment misses its readout date. Capture the extra appetite; don't absorb it silently.

### A finding clearly needs deep implementation detail the customer asks you to include
**Symptom:** "Can you just put the packaging-standard steps / the retirement runbook / the WDAC config
in the report?"
**Cause:** The customer wants the fix, not just the diagnosis.
**Resolution:** Keep the boundary. The report states the remediation **direction and effort**; the
detailed build is a separate workstream (governance operating model, packaging standards, retirement
program, uninstall remediation, or monitoring/reporting — each its own engagement). Record the demand as
a strong signal to sequence that workstream early in the roadmap, and offer it as the natural next step.

## Reporting integrity

### The roadmap has findings with no wave, or waves with impossible ordering
**Symptom:** A finding appears in no wave, or a Wave 3 strategic item is scheduled before the Wave 2
foundational item it depends on.
**Cause:** The sequencing step (Implementation Step 8) skipped a dependency or a finding.
**Resolution:** Re-run the Testing Guide Tests 6–7: every gap → a finding, every finding → exactly one
wave, every dependency drawn. Fix the ordering so no item starts before its prerequisite. A roadmap that
violates its own dependencies is not executable and will be rejected in the readout.

### The executive summary is missing an element
**Symptom:** The sponsor asks a question the summary should have answered (usually "what's the total
effort?" or "what do we start Monday?").
**Cause:** The one-page summary omitted one of the five mandatory elements.
**Resolution:** Confirm all five are present (Testing Guide Test 8): overall band, the three
highest-risk findings, the key dependency, the Wave 1 quick wins, and the headline effort. The executive
summary is the only page many sponsors read — it must stand alone.
