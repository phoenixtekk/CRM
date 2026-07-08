# 3. Implementation Guide — Microsoft Purview ISO 27701 Compliance Program

Follow these steps **in order**, primarily in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and (for the managed DSR workflow) the **Microsoft Priva** portal.
Portal paths and cmdlets are current at authoring; Purview evolves and features are licensing-/cloud-
dependent — **verify your licensing/tenant** and treat any absent feature as a plan/cloud gap
(Requirement 2.1), not a step error.

> **Model:** Baseline the posture and roles, design the clause-to-control map with
> compliance/privacy/legal, create the ISO 27701 assessment and evidence register, wire the DSR method,
> and **pilot every high-impact technical control in simulation/test** before enforcing — validating
> each on `ISO 27701 - Pilot Scope` before you expand. Pattern:
> **Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**

> **Determinations stay with the business.** ISO 27701 applicability, PIMS scope, the controller/
> processor determination, retention schedules, DPIA/lawful-basis outcomes, evidence adequacy, and the
> **certification decision** are **compliance/privacy/legal** calls. This guide configures the method
> and collects evidence; it does not make the ruling and is not a certification.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| ISO 27701 assessment (pilot → production) | `ISO 27701 Assessment – PIMS – Pilot`, `ISO 27701 Assessment – PIMS – Production` |
| Clause → control map | `ISO 27701 Control Map – Clauses` |
| Action plan / evidence register | `ISO 27701 Action Plan – Pilot`, `ISO 27701 Evidence – Register` |
| Scope / role record | `ISO 27701 Scope – Record` |
| Role-separation evidence | `ISO 27701 Roles – Separation Evidence` |
| Sensitivity label | `Sensitivity Label - PII (PIMS) - All Users` |
| Auto-labeling policy | `Auto-Label - PII - Pilot` |
| DLP policy | `DLP Policy - PII (PIMS) - Audit` (renamed `... - Enforce` at the gate) |
| Retention label | `Retention Label - PII - Retention Limitation` |
| DSR access search (content-search method) | `DSR - PII Principal Access - Search` |
| Posture report | `ISO 27701 Posture – Report` |

## Step 1 — Baseline the posture and roles (Assess)
1. Confirm licensing (Requirement 2.1) and that the **ISO 27701** assessment template is available in
   Purview → **Compliance Manager → Assessment templates**.
2. Run `ISO27701-Discovery.ps1` to capture the current state: existing labels, DLP policies (and mode),
   retention policies, the **PII sensitive-information types**, whether an **ISO 27001** assessment
   already exists (reuse), and the Purview **role groups** and their members.
3. Confirm least-privilege **role separation** (Requirement 2.2); save the role snapshot as
   `ISO 27701 Roles – Separation Evidence`.
4. **Gate:** licensing confirmed, ISO 27701 template visible, roles separated. If the template is
   missing, re-check the plan (Requirement 2.1) before proceeding.

## Step 2 — Design the scope and the clause-to-control map (Design)
1. With compliance/privacy (DPO), records, and legal, confirm the **PIMS scope** and the **controller/
   processor** role per processing activity; record it as `ISO 27701 Scope – Record`.
2. Build `ISO 27701 Control Map – Clauses` — map each in-scope PIMS requirement to the Purview control
   that evidences it. A common baseline:

   | ISO 27701 area (PIMS) | Purview control (evidence) |
   |---|---|
   | PII protection / security of processing (extends ISO 27001 A.8, A.5) | **Sensitivity labels** (+ encryption), **DLP** over PII, access controls |
   | Retention limitation & secure disposal | **Data lifecycle / retention** labels & policies; disposition review |
   | Accountability & logging | **Audit** (unified audit log); Compliance Manager evidence register |
   | PII principal rights (access / correction / erasure) | **DSR method**: Priva SRR or eDiscovery/content search |
   | Privacy by design & default | **Default/mandatory labeling**, DLP defaults, retention defaults |
   | Records of PII processing | Documentation (a legal artifact; Purview evidences the technical controls) |
   | Controller/processor-specific duties | Recorded per role in the map; evidenced by the applicable controls |

3. Applicability, scope, controller/processor role, and records content are the stakeholders'
   determinations — capture the decisions, not assumptions. **Reuse existing ISO 27001 controls**
   (Requirement 2.5) rather than duplicating them.

## Step 3 — Create the pilot ISO 27701 assessment (Configure)
1. Purview → **Compliance Manager → Assessments → Add assessment**.
2. Choose the **ISO 27701** template (layered on your **ISO 27001** assessment where present).
3. **Name:** `ISO 27701 Assessment – PIMS – Pilot`. Assign the **group/scope** and create it.
4. The assessment now lists **improvement actions**, each with a score impact, an owner field, an
   implementation status, a test status, and an evidence slot.

## Step 4 — Build the action plan and evidence register
1. In `ISO 27701 Assessment – PIMS – Pilot`, assign each improvement action an **owner** and a target
   date — this is `ISO 27701 Action Plan – Pilot`.
2. Create the **evidence register** `ISO 27701 Evidence – Register` — for each mapped control, record the
   owner, implementation status, test status, and the proof location (policy name, audit export,
   screenshot, or `ISO27701-EvidenceReport.ps1` CSV).
3. Enable **automatic testing** where eligible: Purview → **Compliance Manager → Settings** → turn on
   automatic testing of Microsoft-managed actions. Only eligible actions auto-test; the rest are manual
   — verify availability.

## Step 5 — Configure the personal-data protection controls (pilot in simulation/test)
> Each high-impact control below is **referenced** by the program and evidenced here; it is piloted in
> **simulation/test** on `ISO 27701 - Pilot Scope` before enforcement. Where the organization already
> runs a PII DLP pack or a label taxonomy (or an ISO 27001 control), **reuse and evidence** it rather
> than re-creating it.

1. **Sensitivity label.** Purview → **Information Protection → Sensitivity labels → Create a label** →
   `Sensitivity Label - PII (PIMS) - All Users` (scope **Items**; configure encryption if the
   classification requires it). Publish it to `ISO 27701 - Pilot Scope` via a label policy.
2. **Auto-labeling (simulation).** **Information Protection → Auto-labeling → Create** →
   `Auto-Label - PII - Pilot`; condition = the **PII sensitive-information types** (Requirement 2.4);
   apply the label above; choose **Run policy in simulation mode** — do **not** turn it on.
3. **DLP in audit.** **Data Loss Prevention → Policies → Create** → `DLP Policy - PII (PIMS) - Audit`;
   locations = Exchange, SharePoint, OneDrive, Teams, Devices (as licensed), scoped to
   `ISO 27701 - Pilot Scope`; rule matches the PII SITs and/or the label; action = **audit only**
   (policy tips on, no block); **Run the policy in test mode**.
4. **Retention (retention limitation).** **Data Lifecycle Management → Retention labels → Create** →
   `Retention Label - PII - Retention Limitation` (duration/end action **from the retention schedule** —
   Requirement 2.6, a records/legal input, not a guess); use **disposition review** so nothing is
   auto-deleted unreviewed. Publish/auto-apply to the pilot scope.

## Step 6 — Pilot and tune (the audit gate)
1. Let the audit-mode DLP and simulation auto-labeling run against `ISO 27701 - Pilot Scope` for the
   agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** / **Activity explorer** and the
   auto-labeling **Simulation**; run `ISO27701-EvidenceReport.ps1` for a coverage + DLP-event summary.
3. Tune out false positives (confidence levels, instance counts, exceptions).
4. **Gate:** only when the audit shows the controls match real PII and not routine work do you promote
   to enforce (Step 8). If still noisy, keep tuning — do not enforce.

## Step 7 — Wire the DSR (PII-principal-request) method
1. **If Priva is licensed:** Priva portal → **Subject Rights Requests → Create request** — configure the
   request type (access/export/tag for follow-up), the data subject, and the connectors; use it as the
   managed locate-review-produce workflow.
2. **If Priva is not licensed:** use Purview **eDiscovery (Standard/Premium)** / content search — create
   a content search `DSR - PII Principal Access - Search` keyed on the principal's identifiers across the
   in-scope workloads, review, and export.
3. Document the **DSR runbook**: intake → verify identity → locate (`DSR - PII Principal Access -
   Search` or Priva SRR) → review → privacy/legal decision → produce/correct/erase → record in
   `ISO 27701 Evidence – Register`. **Erasure/production decisions remain privacy/legal.**

## Step 8 — Promote high-impact controls to enforce (after the gate)
1. **DLP → enforce.** Open `DLP Policy - PII (PIMS) - Audit` → **Edit**; rename to
   `DLP Policy - PII (PIMS) - Enforce`; change the action to **Block** (or **Block with override**) as
   the business requires; **Turn the policy on** for the pilot scope first.
2. **Auto-labeling → on.** After the simulation is clean, turn `Auto-Label - PII - Pilot` on (out of
   simulation).
3. **Rollback (if needed):** set the DLP policy back to **Test mode**, turn auto-labeling back to
   simulation, or disable the retention policy. Deletion is irreversible — validate first.

## Step 9 — Validate
1. Complete the Testing Guide against `ISO 27701 - Pilot Scope`.
2. Run `ISO27701-Validation.ps1` (label published, DLP present + mode, retention present, audit on) and
   `ISO27701-EvidenceReport.ps1` (classification + DLP-event coverage; audit sample).
3. Run a **test DSR** end to end (Step 7 method) and record it in `ISO 27701 Evidence – Register`.
4. **Gate:** all pass/fail gates in the Testing Guide met; evidence recorded for each mapped control.

## Step 10 — Report and expand
1. Produce `ISO 27701 Posture – Report` from Compliance Manager (score, per-action status, evidence)
   plus the `ISO27701-EvidenceReport.ps1` coverage output.
2. Promote the assessment to `ISO 27701 Assessment – PIMS – Production`; widen the label policy, the DLP
   enforce policy, and the retention policy from `ISO 27701 - Pilot Scope` to broader groups (or **All
   users / All locations**) once the pilot passes.
3. Re-validate each expansion with `ISO27701-Validation.ps1` and `ISO27701-EvidenceReport.ps1`; run the
   maintenance cadence (re-score, re-test, refresh evidence) on a defined schedule ahead of management
   review / certification. **The certification decision is the auditor's/organization's, not this
   solution's.**

---
### Order of operations
`Baseline + roles → scope + role + clause map → ISO 27701 assessment (pilot) → action plan + evidence
register → PII controls (simulation/audit) → audit gate → DSR method wired → enforce (after gate) →
validate + test DSR → report + expand`
