# 3. Implementation Guide — Microsoft Purview GDPR Compliance Program

Follow these steps **in order**, primarily in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and (for the managed DSR workflow) the **Microsoft Priva** portal.

> **Model:** Baseline the posture and roles, design the article-to-control map with
> compliance/privacy/legal, create the GDPR assessment and evidence register, wire the DSR method,
> and **pilot every high-impact technical control in simulation/test** before enforcing — validating
> each on `GDPR - Pilot Scope` before you expand. Pattern:
> **Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**

> **Determinations stay with the business.** GDPR applicability, lawful basis, ROPA (Art. 30) content,
> DPIA (Art. 35) outcomes, retention schedules, and evidence adequacy are **compliance/privacy/legal**
> calls. This guide configures the method and collects the evidence; it does not make the ruling.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| GDPR assessment (pilot → production) | `GDPR Assessment – Regulation – Pilot`, `GDPR Assessment – Regulation – Production` |
| Article → control map | `GDPR Control Map – Articles` |
| Action plan / evidence register | `GDPR Action Plan – Pilot`, `GDPR Evidence – Register` |
| Scope / owners record | `GDPR Scope – Record` |
| Role-separation evidence | `GDPR Roles – Separation Evidence` |
| Sensitivity label | `Sensitivity Label - Personal Data (GDPR) - All Users` |
| Auto-labeling policy | `Auto-Label - EU Personal Data - Pilot` |
| DLP policy | `DLP Policy - EU Personal Data - Audit` (renamed `... - Enforce` at the gate) |
| Retention label | `Retention Label - Personal Data - Storage Limitation` |
| DSR access search (content-search method) | `DSR - Data Subject Access - Search` |
| Posture report | `GDPR Posture – Report` |

## Step 1 — Baseline the posture and roles (Assess)
1. Confirm licensing (Requirement 2.1) and that the **GDPR** assessment template is available in
   Purview → **Compliance Manager → Assessment templates**.
2. Run `GDPR-Discovery.ps1` to capture the current state: existing labels, DLP policies (and mode),
   retention policies, the **EU personal-data sensitive-information types**, and the Purview **role
   groups** and their members.
3. Confirm least-privilege **role separation** (Requirement 2.2) and save the role snapshot as
   `GDPR Roles – Separation Evidence`.
4. **Gate:** licensing confirmed, GDPR template visible, roles separated. If the template is missing,
   re-check the plan (Requirement 2.1) before proceeding.

## Step 2 — Design the scope and the article-to-control map (Design)
1. With compliance/privacy (DPO), records, and legal, confirm the **scope** (workloads holding EU
   personal data, the EU SIT set) and record it as `GDPR Scope – Record`.
2. Build `GDPR Control Map – Articles` — map each in-scope GDPR obligation to the Purview control that
   evidences it. A common baseline:

   | GDPR obligation | Purview control (evidence) |
   |---|---|
   | Art. 5(1)(f) / 32 — integrity & confidentiality, security of processing | **Sensitivity labels** (+ encryption), **DLP** over EU personal data, access controls |
   | Art. 5(1)(e) — storage limitation | **Data lifecycle / retention** labels & policies; disposition review |
   | Art. 5(2) — accountability | **Audit** (unified audit log); Compliance Manager evidence register |
   | Art. 15 / 20 — access & portability | **DSR method**: Priva SRR or eDiscovery/content search |
   | Art. 17 — erasure | **DSR** locate + **retention/disposition** (execution deferred to privacy/legal) |
   | Art. 25 — data protection by design & default | **Default/mandatory labeling**, DLP defaults, retention defaults |
   | Art. 30 — records of processing | Documentation (ROPA is a legal artifact; Purview evidences the technical controls) |
   | Art. 33 / 34 — breach notification | **Audit**, DLP alerts, **Insider Risk** signals (where scoped) |

3. Applicability, lawful basis, and ROPA content are the stakeholders' determinations — capture the
   decisions, not assumptions.

## Step 3 — Create the pilot GDPR assessment (Configure)
1. Purview → **Compliance Manager → Assessments → Add assessment**.
2. Choose the **GDPR** template (and any overlay, e.g. **ISO 27701**, where entitled).
3. **Name:** `GDPR Assessment – Regulation – Pilot`. Assign the **group/scope** and create it.
4. The assessment now lists **improvement actions**, each with a score impact, an owner field, an
   implementation status, a test status, and an evidence slot.

## Step 4 — Build the action plan and evidence register
1. In `GDPR Assessment – Regulation – Pilot`, assign each improvement action an **owner** and a
   target date — this is `GDPR Action Plan – Pilot`.
2. Create the **evidence register** `GDPR Evidence – Register` — for each mapped control, record the
   owner, implementation status, test status, and the proof location (policy name, audit export,
   screenshot, or `GDPR-EvidenceReport.ps1` CSV).
3. Enable **automatic testing** where eligible: Purview → **Compliance Manager → Settings** → turn on
   automatic testing of Microsoft-managed actions (`GDPR Automatic Testing – Setting`). Only eligible
   actions auto-test; the rest are manual — verify availability.

## Step 5 — Configure the personal-data protection controls (pilot in simulation/test)
> Each high-impact control below is **referenced** by the program and evidenced here; it is piloted in
> **simulation/test** on `GDPR - Pilot Scope` before enforcement. Where the organization already runs
> the GDPR DLP pack or a label taxonomy, **reuse and evidence** it rather than re-creating it.

1. **Sensitivity label.** Purview → **Information Protection → Sensitivity labels → Create a label** →
   `Sensitivity Label - Personal Data (GDPR) - All Users` (scope **Items**; configure encryption if
   the classification requires it). Publish it to `GDPR - Pilot Scope` via a label policy.
2. **Auto-labeling (simulation).** **Information Protection → Auto-labeling → Create** →
   `Auto-Label - EU Personal Data - Pilot`; condition = the **EU personal-data sensitive-information
   types** (Requirement 2.4); apply the label above; choose **Run policy in simulation mode** — do
   **not** turn it on. Review matches before activating.
3. **DLP in audit.** **Data Loss Prevention → Policies → Create** → `DLP Policy - EU Personal Data -
   Audit`; locations = Exchange, SharePoint, OneDrive, Teams, Devices (as licensed), scoped to
   `GDPR - Pilot Scope`; rule matches the EU personal-data SITs and/or the label; action = **audit
   only** (policy tips on, no block); **Run the policy in test mode**.
4. **Retention (storage limitation).** **Data Lifecycle Management → Retention labels → Create** →
   `Retention Label - Personal Data - Storage Limitation` (duration/end action **from the retention
   schedule** — a records/legal input, not a guess); use **disposition review** so nothing is
   auto-deleted unreviewed. Publish/auto-apply to the pilot scope.

## Step 6 — Pilot and tune (the audit gate)
1. Let the audit-mode DLP and simulation auto-labeling run against `GDPR - Pilot Scope` for the agreed
   window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** / **Activity explorer** and the
   auto-labeling **Simulation**; run `GDPR-EvidenceReport.ps1` for a coverage + DLP-event summary.
3. Tune out false positives (confidence levels, instance counts, exceptions).
4. **Gate:** only when the audit shows the controls match real EU personal data and not routine work
   do you promote to enforce (Step 8). If still noisy, keep tuning — do not enforce.

## Step 7 — Wire the DSR (data-subject-request) method
1. **If Priva is licensed:** Priva portal → **Subject Rights Requests → Create request** — configure
   the request type (access/export/tag for follow-up), the data subject, and the connectors; use it
   as the managed locate-review-produce workflow.
2. **If Priva is not licensed:** use Purview **eDiscovery (Standard/Premium)** / content search as the
   locate method — create a content search `DSR - Data Subject Access - Search` keyed on the data
   subject's identifiers across the in-scope workloads, review the results, and export.
3. Document the **DSR runbook**: intake → verify identity → locate (`DSR - Data Subject Access -
   Search` or Priva SRR) → review → privacy/legal decision → produce/erase → record in
   `GDPR Evidence – Register`. **Erasure/production decisions remain privacy/legal** — the tooling
   locates and produces, it does not decide.

## Step 8 — Promote high-impact controls to enforce (after the gate)
1. **DLP → enforce.** Open `DLP Policy - EU Personal Data - Audit` → **Edit**; rename to
   `DLP Policy - EU Personal Data - Enforce`; change the action to **Block** (or **Block with
   override**) as the business requires; **Turn the policy on** for the pilot scope first.
2. **Auto-labeling → on.** After the simulation is clean, turn `Auto-Label - EU Personal Data - Pilot`
   on (out of simulation).
3. **Rollback (if needed):** set the DLP policy back to **Test mode**, turn auto-labeling back to
   simulation, or disable the retention policy. Deletion is irreversible — validate first.

## Step 9 — Validate
1. Complete the Testing Guide against `GDPR - Pilot Scope`.
2. Run `GDPR-Validation.ps1` (label published, DLP present + mode, retention present, audit on) and
   `GDPR-EvidenceReport.ps1` (classification + DLP-event coverage; audit sample).
3. Run a **test DSR** end to end (Step 7 method) and record it in `GDPR Evidence – Register`.
4. **Gate:** all pass/fail gates in the Testing Guide met; evidence recorded for each mapped control.

## Step 10 — Report and expand
1. Produce `GDPR Posture – Report` from Compliance Manager (score, per-action status, evidence) plus
   the `GDPR-EvidenceReport.ps1` coverage output.
2. Promote the assessment to `GDPR Assessment – Regulation – Production`; widen the label policy, the
   DLP enforce policy, and the retention policy from `GDPR - Pilot Scope` to broader groups (or **All
   users / All locations**) once the pilot passes.
3. Re-validate each expansion with `GDPR-Validation.ps1` and `GDPR-EvidenceReport.ps1`; run the
   maintenance cadence (re-score, re-test, refresh evidence) on a defined schedule.

---
### Order of operations
`Baseline + roles → scope + article map → GDPR assessment (pilot) → action plan + evidence register →
personal-data controls (simulation/audit) → audit gate → DSR method wired → enforce (after gate) →
validate + test DSR → report + expand`
