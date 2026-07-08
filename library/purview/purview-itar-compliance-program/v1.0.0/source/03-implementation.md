# 3. Implementation Guide — Microsoft Purview ITAR Compliance Program

Follow these steps **in order**, in the **Microsoft Purview portal** (`https://purview.microsoft.com`).
Portal paths and cmdlets are current at authoring; Purview evolves and features are licensing-/cloud-
dependent — **verify your licensing/tenant** and treat any absent feature as a plan/cloud gap
(Requirement 2.1), not a step error. **ITAR technical data generally requires GCC High** — confirm the
cloud with export-control/legal before placing any controlled data.

> **Model:** Baseline the posture and roles, design the export-control map and authorized-person model
> with export-control/legal, create the assessment and evidence register, add detection, and **pilot every
> high-impact control in simulation/test** before enforcing — validating each on `ITAR - Authorized
> Persons Pilot` before you expand. Pattern:
> **Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**

> **Determinations stay with export-control/legal.** ITAR applicability, USML classification, the
> U.S.-person determination, licenses/agreements (TAA, DSP-5, etc.), retention schedules, and any
> voluntary-disclosure decision are **export-control/legal** calls. This guide configures the method and
> collects evidence; it does not make the ruling.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Export-control assessment (pilot → production) | `ITAR Assessment – Export Control – Pilot`, `ITAR Assessment – Export Control – Production` |
| Control map | `ITAR Control Map – Export Controls` |
| Action plan / evidence register | `ITAR Action Plan – Pilot`, `ITAR Evidence – Register` |
| Scope / authorized-person record | `ITAR Scope – Record` |
| Role-separation evidence | `ITAR Roles – Separation Evidence` |
| Sensitivity label | `Sensitivity Label - ITAR Technical Data - Authorized US Persons` |
| Custom SIT | `SIT - ITAR/USML Markers` |
| Auto-labeling policy | `Auto-Label - ITAR Technical Data - Pilot` |
| DLP policy | `DLP Policy - ITAR Export-Controlled - Audit` (renamed `... - Enforce` at the gate) |
| Retention label | `Retention Label - Export Records - Retention` |
| Posture report | `ITAR Posture – Report` |

## Step 1 — Baseline the posture and roles (Assess)
1. Confirm licensing **and the sovereign cloud (GCC High)** (Requirement 2.1) and whether an
   **export-control / NIST SP 800-171** assessment template is available in Purview → **Compliance
   Manager → Assessment templates**.
2. Run `ITAR-Discovery.ps1` to capture the current state: existing labels, DLP policies (and mode),
   retention policies, the custom SIT, export-control SITs, and the Purview **role groups** and members.
3. Confirm least-privilege **role separation** and that access-bearing roles are held by **authorized
   U.S. persons** (Requirement 2.2); save the role snapshot as `ITAR Roles – Separation Evidence`.
4. **Gate:** licensing + cloud confirmed, a usable assessment template visible, roles separated. If the
   template is missing, plan to evidence against **NIST SP 800-171** / a custom assessment.

## Step 2 — Design the scope, authorized persons, and the control map (Design)
1. With export-control, legal, and program owners, confirm **what technical data is ITAR/USML-controlled**
   and the **authorized-U.S.-person list**; record both as `ITAR Scope – Record`.
2. Build `ITAR Control Map – Export Controls` — map each in-scope obligation to the Purview control that
   evidences it. A common baseline:

   | Export-control obligation | Purview control (evidence) |
   |---|---|
   | Protect technical data; prevent unauthorized/deemed export | **Sensitivity label** (encrypt + restrict to authorized U.S. persons), access controls |
   | Prevent export-controlled data reaching unauthorized recipients | **DLP** hard-block on recipient conditions; endpoint DLP (USB/print/upload) |
   | Detect technical data at scale | **Custom SIT** (`SIT - ITAR/USML Markers`) + auto-labeling (simulation first) |
   | Retain export records | **Data lifecycle / retention** labels; disposition review |
   | Accountability / audit | **Audit** (unified audit log); Compliance Manager evidence register |
   | Control baseline (where no ITAR template) | **NIST SP 800-171** assessment / custom assessment |

3. USML classification, the U.S.-person determination, and licenses/agreements are export-control/legal
   determinations — capture the decisions, not assumptions.

## Step 3 — Create the pilot assessment (Configure)
1. Purview → **Compliance Manager → Assessments → Add assessment**.
2. Choose an **ITAR / export-control** template where available, otherwise **NIST SP 800-171** (or a
   custom assessment) as the evidence baseline (**verify your tenant**).
3. **Name:** `ITAR Assessment – Export Control – Pilot`. Assign the **group/scope** and create it.
4. The assessment now lists **improvement actions**, each with a score impact, an owner field, an
   implementation status, a test status, and an evidence slot.

## Step 4 — Build the action plan and evidence register
1. In `ITAR Assessment – Export Control – Pilot`, assign each improvement action an **owner** and a target
   date — this is `ITAR Action Plan – Pilot`.
2. Create the **evidence register** `ITAR Evidence – Register` — for each mapped control, record the owner,
   implementation status, test status, and the proof location (policy name, audit export, screenshot, or
   `ITAR-EvidenceReport.ps1` CSV).
3. Enable **automatic testing** where eligible (Purview → **Compliance Manager → Settings**). Only
   eligible actions auto-test; the rest are manual — verify availability.

## Step 5 — Configure the technical-data controls (pilot in simulation/test)
> Each high-impact control below is piloted in **simulation/test** on `ITAR - Authorized Persons Pilot`
> before enforcement. Where the organization already runs an export-control label/DLP pack, **reuse and
> evidence** it rather than re-creating it.

1. **Sensitivity label.** Purview → **Information Protection → Sensitivity labels → Create a label** →
   `Sensitivity Label - ITAR Technical Data - Authorized US Persons` (scope **Items**; **configure
   encryption** restricting to **authorized U.S. persons / named recipients only**; add an
   **export-control header/footer marking**). Publish it to `ITAR - Authorized Persons Pilot` via a label
   policy.
2. **Custom SIT.** **Data classification → Classifiers → Sensitive info types → Create** →
   `SIT - ITAR/USML Markers` (regex for your USML/export-control markings + supporting keywords; set
   confidence/proximity). **Test** with real and decoy samples.
3. **Auto-labeling (simulation).** **Information Protection → Auto-labeling → Create** →
   `Auto-Label - ITAR Technical Data - Pilot`; condition = `SIT - ITAR/USML Markers` (and/or export-control
   SITs); apply the label above; choose **Run policy in simulation mode** — do **not** turn it on.
4. **DLP in audit.** **Data Loss Prevention → Policies → Create** → `DLP Policy - ITAR Export-Controlled -
   Audit`; locations = Exchange, SharePoint, OneDrive, Teams, Devices (as licensed), scoped to
   `ITAR - Authorized Persons Pilot`; rules match the label and/or `SIT - ITAR/USML Markers`, with a
   **recipient condition** flagging sends to **unauthorized/foreign recipients** (Requirement 2.5); action
   = **audit only** (policy tips on, no block); **Run the policy in test mode**. Audit endpoint actions
   (copy to USB, print, browser upload).
5. **Retention (export records).** **Data Lifecycle Management → Retention labels → Create** →
   `Retention Label - Export Records - Retention` (duration/end action **from the retention schedule** —
   Requirement 2.6); use **disposition review**. Publish/auto-apply to the pilot scope.

## Step 6 — Pilot and tune (the audit gate)
1. Let the audit-mode DLP and simulation auto-labeling run against `ITAR - Authorized Persons Pilot` for
   the agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** / **Activity explorer** and the
   auto-labeling **Simulation**; run `ITAR-EvidenceReport.ps1` for a coverage + DLP-event summary.
3. Tune out false positives (SIT confidence/proximity, instance counts, authorized-recipient exceptions).
4. **Gate:** only when the audit shows the controls match real technical data and correctly flag
   unauthorized recipients — without blocking authorized program work — do you promote to enforce
   (Step 7). If still noisy, keep tuning — do not enforce.

## Step 7 — Promote to enforce (after the gate)
1. **DLP → enforce.** Open `DLP Policy - ITAR Export-Controlled - Audit` → **Edit**; rename to
   `DLP Policy - ITAR Export-Controlled - Enforce`; set the recipient rule to **hard-block** sends to
   unauthorized/foreign recipients (keep authorized recipients as exceptions); enforce endpoint actions as
   the business requires; **Turn the policy on** for the pilot scope first.
2. **Auto-labeling → on.** After the simulation is clean, turn `Auto-Label - ITAR Technical Data - Pilot`
   on (out of simulation).
3. **Rollback (if needed):** set the DLP policy back to **Test mode**, turn auto-labeling back to
   simulation, or disable the retention policy. **Note:** for ITAR, under-blocking is an unauthorized-
   export risk — prefer keeping the recipient hard-block on and tuning exceptions, not disabling.

## Step 8 — Validate
1. Complete the Testing Guide against `ITAR - Authorized Persons Pilot`.
2. Run `ITAR-Validation.ps1` (label published, DLP present + mode, retention present, audit on) and
   `ITAR-EvidenceReport.ps1` (classification + DLP-event coverage; audit sample).
3. **Gate:** all pass/fail gates in the Testing Guide met; evidence recorded for each mapped control.

## Step 9 — Report and expand
1. Produce `ITAR Posture – Report` from Compliance Manager (score, per-action status, evidence) plus the
   `ITAR-EvidenceReport.ps1` coverage output.
2. Promote the assessment to `ITAR Assessment – Export Control – Production`; widen the label policy, the
   DLP enforce policy, and the retention policy from the pilot to the full authorized-person scope once
   the pilot passes. **Never widen beyond authorized U.S. persons** — that is the whole point.
3. Re-validate each expansion with `ITAR-Validation.ps1` and `ITAR-EvidenceReport.ps1`; run the
   maintenance cadence (re-score, re-test, refresh evidence) on a defined schedule. **Applicability, USML
   classification, and any disclosure decision remain export-control/legal determinations.**

---
### Order of operations
`Baseline + roles + cloud → scope + authorized persons + control map → assessment (pilot) → action plan +
evidence register → technical-data controls (custom SIT, simulation/audit) → audit gate → enforce
(hard-block unauthorized) → validate → report + expand (authorized persons only)`
