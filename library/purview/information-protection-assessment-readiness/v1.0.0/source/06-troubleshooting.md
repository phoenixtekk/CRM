# 6. Troubleshooting Guide — Information Protection Assessment & Readiness (Microsoft Purview)

Symptom → likely root cause → fix. Use **`IPASSESS-ScopeHealth.ps1`** (sessions/readability),
**`IPASSESS-Discovery.ps1`** (estate), **`IPASSESS-Validation.ps1`** (scoring), and
**`IPASSESS-Report.ps1`** (gap register/roadmap) to confirm before and after each fix. Where a capability
or portal path is **licensing-gated or evolving, verify against current Microsoft guidance / your
tenant** rather than assuming.

## A. Connectivity & access

### `Get-Label` / `Get-DlpCompliancePolicy` errors with "not recognized" or an auth prompt
- **Not connected to Security & Compliance PowerShell.** These cmdlets come from the S&C session, not
  Exchange Online or Graph. **Fix:** `Connect-IPPSSession` with a modern-auth/MFA admin; re-run
  **`IPASSESS-ScopeHealth.ps1`** — it confirms the session before you run Discovery.
- **ExchangeOnlineManagement module missing/old.** `Connect-IPPSSession` ships in that module. **Fix:**
  `Install-Module ExchangeOnlineManagement` (or `Update-Module`), then reconnect.

### The scripts return far fewer objects than the portal shows
- **Insufficient read role.** Labels need **Information Protection Reader/Analyst**; DLP visibility needs
  **Compliance Data Administrator / Global Reader**. Without them a cmdlet may return an empty set rather
  than error. **Fix:** assign the least-privilege **reader** role groups (Requirement 2.2) and re-run.
- **Scoped administration.** An administrative unit / scoped role can hide objects. **Fix:** confirm the
  operator's scope in **Roles & scopes**; assess with a suitably scoped reader.

## B. Licensing-gated visibility

### Auto-labeling reads as "not available" / `Get-AutoSensitivityLabelPolicy` errors
- **Capability is E5-gated.** Service-side auto-labeling requires **E5 / E5 Compliance**. **Fix:** this is
  a **valid finding**, not a script bug — **`IPASSESS-ScopeHealth.ps1`** and **`IPASSESS-Discovery.ps1`**
  record it as **not available — verify your licensing/tenant**. Put licensing in the roadmap only if the
  capability is actually required; do **not** score it as a configuration gap.

### DSPM / advanced DLP options aren't in the portal
- **Not licensed or in preview.** DSPM and some advanced DLP features are **E5**-class and partly in
  **preview**. **Fix:** confirm the subscription; treat absent features as **not available — verify your
  licensing/tenant**, and don't assert them in the findings.

## C. Discovery accuracy

### A label's encryption/marking settings look wrong in the CSV
- **Reading a summary vs. the full label object.** Some protection settings live in advanced/label
  properties. **Fix:** cross-check with `Get-Label -Identity "<name>" | Format-List Encryption*,
  ApplyContentMarking*, ApplyWaterMarking*, ContentType` and Purview → **Information Protection →
  Labels**; the Discovery CSV mirrors these fields (Testing Test 3).
- **Label scope (`ContentType`) confusion.** A label scoped to **Sites/Groups** won't behave like a
  File/Email label. **Fix:** read the `Scope=` field in the CSV; a container label with no file/email
  scope is expected, not a defect.

### Content explorer shows coverage the scripts don't
- **By design.** The scripts inventory policy **configuration**; per-item label distribution lives in
  **Content explorer** (its own **Content Viewer/List Viewer** roles). **Fix:** read coverage in the
  portal and record the counts for the scorecard — the scripts don't scrape per-item content.

## D. Scoring & the roadmap

### Every workload scores FAIL for DLP even though DLP exists
- **In-scope workload list doesn't match reality.** Validation compares DLP coverage to the workloads you
  passed. **Fix:** pass the correct `-InScopeWorkloads` (Requirement 2.4); a workload out of scope
  shouldn't be scored. Re-run **`IPASSESS-Validation.ps1`**.
- **Policies genuinely stuck in Test.** All-Test scores **WARN** ("nothing enforced"). **Fix:** that is a
  real finding — it becomes a quick-win roadmap item (move toward pilot/enforce as follow-on).

### The scorecard feels subjective / stakeholders disagree
- **Baseline targets not agreed.** A gap is the distance to the **target**, and the default baseline may
  not fit the org. **Fix:** tune the targets (`-InScopeWorkloads`, `-HighTierLabelPattern`, and the
  baseline mapping) with compliance/security (Requirement 2.5), then re-run so the score reflects the
  agreed baseline.

### A gap has no clear owner
- **Owner-function not attributed.** Every gap row carries an **OwnerFunction**
  (compliance/records/security). **Fix:** confirm the named stakeholder (Requirement 2.7); the assessment
  **attributes** the determination, it does not make it.

## E. The simulation pilot

### `IPASSESS-PilotRemediation.ps1` didn't create anything
- **Ran with `-WhatIf` (the default).** The script previews unless you add **`-Commit`**. **Fix:** confirm
  the previewed action, then re-run with `-Commit`.
- **A policy of the same name exists.** The script refuses to collide with an existing
  `Information Protection - Pilot - Simulation`. **Fix:** review/remove the existing one
  (`Remove-AutoSensitivityLabelPolicy "Information Protection - Pilot - Simulation"`) and re-run.

### The simulation policy exists but shows no would-be matches
- **No rule yet, or SIT conditions too narrow.** The policy needs a matching **rule**
  (`New-AutoSensitivityLabelRule`) with your sensitive-info-type conditions, and simulation takes time to
  evaluate. **Fix:** add the rule, wait for the simulation to run, then review results in the portal
  (Information Protection → Auto-labeling → the policy → **Simulation**).

### I'm worried the pilot enforced something
- **Simulation enforces nothing by design.** `Mode = TestWithoutNotifications` applies **no label** to any
  content. **Fix:** run **`IPASSESS-Validation.ps1 -CheckPilot`** — it confirms the object is in a
  simulation mode; if `Mode` is **not** a Test mode, investigate (this engagement must not enforce). To be
  safe, remove the pilot: `Remove-AutoSensitivityLabelPolicy "Information Protection - Pilot - Simulation"`.

### Rollback — did anything change?
- **Read-only steps changed nothing; the simulation labeled nothing.** **Fix:** delete the simulation
  policy (and unpublish `Information Protection - Label Policy - Pilot` if you piloted a publish); re-run
  **`IPASSESS-Discovery.ps1`** — the estate should match the pre-pilot baseline (Testing Test 9).

---
## Escalation checklist
1. `IPASSESS-ScopeHealth.ps1` — S&C (and Graph) connected; which capabilities are readable vs. not
   available (licensing)?
2. `IPASSESS-Discovery.ps1` — labels (with encryption/marking/scope), label policies, DLP (Mode/Workload),
   auto-labeling (Mode), SITs all captured?
3. `IPASSESS-Validation.ps1` — six dimensions scored against the **agreed** baseline; `-InScopeWorkloads`
   correct?
4. `IPASSESS-Report.ps1` — gap register + roadmap generated; each gap has an owner-function?
5. `IPASSESS-PilotRemediation.ps1 -CheckPilot` (via Validation) — pilot object in **simulation**, nothing
   enforced?
6. Still stuck → capture the symptom and **verify current Microsoft guidance / your tenant** for the
   licensing-gated or evolving capability (auto-labeling, DSPM, DLP simulation) before finalizing the
   finding.
