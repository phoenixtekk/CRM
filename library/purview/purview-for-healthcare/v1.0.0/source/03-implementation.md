# 3. Implementation Guide — Microsoft Purview for Healthcare (HIPAA/PHI)

Follow these steps **in order**, in the **Microsoft Purview portal** (`https://purview.microsoft.com`).
Portal paths are current at authoring time but Purview evolves — if a menu differs, **verify against
Microsoft's documentation and your tenant**.

> **Model:** Design a small PHI taxonomy, publish it, add auto-labeling **in simulation**, build DLP in
> **audit** and tune it (the DLP audit gate) before enforcing, then set retention/records **from your
> records schedule** — piloting each on `Purview - PHI Pilot Users` before you expand. Pattern:
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
> Regulatory/records/legal determinations are **deferred** — you implement the schedule and
> classification your compliance/records/privacy/legal functions supply.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Sensitivity labels | `Sensitivity Label - Public - All Users`, `Sensitivity Label - Internal - All Users`, `Sensitivity Label - Confidential - PHI - All Users`, `Sensitivity Label - Highly Confidential - PHI Restricted - All Users` |
| Label policy | `Label Policy - Healthcare PHI Taxonomy - All Users` |
| Auto-labeling policy | `Auto-Label - PHI Health Records - Pilot` |
| DLP policy | `DLP Policy - PHI HIPAA - Audit` (renamed to `... - Enforce` at the gate) |
| Retention label | `Retention Label - HIPAA Documentation - 6 Year` |
| Retention label (clinical) | `Retention Label - Medical Records - Schedule-Defined` |
| Retention policy | `Retention Policy - Healthcare Baseline - Schedule-Defined` |

## Step 1 — Design the PHI label taxonomy (Assess → Design)
1. With the Privacy/Security Officer and data owners, agree a **small** taxonomy and the protection
   each label applies. A common healthcare starting set:
   - `Sensitivity Label - Public - All Users` — no protection; shareable externally (patient
     education, marketing).
   - `Sensitivity Label - Internal - All Users` — internal business data; no encryption.
   - `Sensitivity Label - Confidential - PHI - All Users` — **encrypt**; restrict to the organization;
     apply a PHI marking.
   - `Sensitivity Label - Highly Confidential - PHI Restricted - All Users` — **encrypt**; restrict to
     a **named care-team / role group** per the **minimum-necessary** principle.
2. Record each label's meaning, protection, and who applies it (the one-pager from Requirement 2.4).
   Decide, with clinical IT, how encryption interacts with clinical apps and emergency access
   (Requirement 2.6) **before** enabling encryption.

## Step 2 — Create the sensitivity labels
1. Purview portal → **Information Protection → Sensitivity labels → Create a label**.
2. **Name and tooltip:** enter `Sensitivity Label - Confidential - PHI - All Users` and a clear
   user-facing tooltip (for example "Protected health information — do not share outside the
   organization"). **Next**.
3. **Scope:** select **Items** (files and emails). **Next**.
4. **Encryption:** choose **Configure encryption** for the two PHI labels; set permissions (for
   example **All Users in <org>** for `Confidential - PHI`, and a **named care-team group** for
   `Highly Confidential - PHI Restricted`). Leave `Public` / `Internal` without encryption. **Next**.
5. **Content marking:** add a header/footer/watermark for the PHI labels (for example `PHI —
   CONFIDENTIAL`). **Next**.
6. **Auto-labeling for items:** leave off here (configured centrally in Step 4). **Next → Create the
   label**.
7. Repeat for each label in sensitivity order (`Public` → `Internal` → `Confidential - PHI` →
   `Highly Confidential - PHI Restricted`). Label order sets priority.

## Step 3 — Publish the labels with a label policy
1. Purview portal → **Information Protection → Sensitivity labels → Label policies → Publish labels**.
2. **Choose labels to publish:** add all four taxonomy labels. **Next**.
3. **Assign to users and groups:** add `Purview - PHI Pilot Users` for the pilot. **Next**.
4. **Policy settings:** optionally require a justification for downgrading a label and require a label
   for new items. **Next**.
5. **Default label / mandatory labeling:** set a default (for example `Internal`) if the org wants
   one. **Next**.
6. **Name:** `Label Policy - Healthcare PHI Taxonomy - All Users`. **Next → Submit**.

## Step 4 — Configure auto-labeling for PHI (SIMULATION only)
1. Purview portal → **Information Protection → Auto-labeling → Create auto-labeling policy**.
2. **Choose the information to label:** pick the **Medical and health** category / **U.S. Health
   Insurance Act (HIPAA)** template, or **Custom**. **Next**.
3. **Name:** `Auto-Label - PHI Health Records - Pilot`. **Next**.
4. **Admin units / locations:** select **Exchange email**, **SharePoint sites**, **OneDrive
   accounts** as needed; scope to pilot locations. **Next**.
5. **Rules:** define the condition using the health/PHI sensitive-information types (for example the
   HIPAA template, **ICD-9-CM / ICD-10-CM**, **U.S. Social Security Number**) and set the label to
   apply to `Sensitivity Label - Confidential - PHI - All Users`. **Next**.
6. **Simulate first:** choose **Run policy in simulation mode** — **do not turn it on**. **Next →
   Create**. Review the simulation matches (Testing Test 3) before ever turning the policy on.
   *Pass/fail:* the simulation must show it matches real PHI and not routine content before you expand.

## Step 5 — Build the DLP policy in AUDIT mode
1. Purview portal → **Data Loss Prevention → Policies → Create policy**.
2. **Category / template:** choose **Medical and health records → U.S. Health Insurance Act (HIPAA)**
   (or **Custom**). **Next**.
3. **Name:** `DLP Policy - PHI HIPAA - Audit`. **Next**.
4. **Locations:** enable **Exchange email**, **SharePoint sites**, **OneDrive accounts**, **Teams chat
   and channel messages**, and **Devices** (endpoint DLP) as licensed. Scope to
   `Purview - PHI Pilot Users` where the location supports user scoping. **Next**.
5. **Rules:** add a rule matching the PHI sensitive-information types (the HIPAA set) and/or the label
   `Sensitivity Label - Confidential - PHI - All Users`. Set actions to **audit only** — enable
   **policy tips** for visibility but do **not** block. **Next**.
6. **Policy mode:** select **Run the policy in test mode** (with policy tips). **Next → Submit**. The
   policy now audits PHI sharing without blocking clinical work.

## Step 6 — Pilot and tune (the DLP audit gate)
1. Let the audit-mode policy run against `Purview - PHI Pilot Users` for the agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
   `PHI-Report.ps1` for a PHI classification + DLP-event summary.
3. Tune the rules to remove false positives (adjust confidence levels, instance counts, exceptions —
   for example legitimate referral or billing flows).
4. **Gate:** only when the audit shows the policy matches real PHI exposure and not routine care
   coordination do you proceed to enforce (Step 7). If it is still noisy, keep tuning — **do not
   enforce**. Blocking clinicians erroneously is a patient-care risk.

## Step 7 — Switch DLP to ENFORCE (after the gate)
1. Purview portal → **Data Loss Prevention → Policies →** open `DLP Policy - PHI HIPAA - Audit` →
   **Edit**.
2. Rename it to `DLP Policy - PHI HIPAA - Enforce` so the stage is visible.
3. **Rules:** change the action from audit to **Block** (or **Block with override** so clinicians can
   proceed with a business justification) as the business requires; keep policy tips on. **Next**.
4. **Policy mode:** select **Turn the policy on**. **Next → Submit**. Enforcement applies to the pilot
   scope first; widen it in Step 11.
5. **Rollback (if needed):** set the policy mode back to **Test mode** (audit) or turn the policy off.

## Step 8 — Create retention labels (from your records schedule)
1. Purview portal → **Data Lifecycle Management → Retention labels → Create a label**.
2. **HIPAA documentation label:** `Retention Label - HIPAA Documentation - 6 Year`. HIPAA §164.316(b)
   requires required policies/documentation to be retained **6 years** from creation or last effective
   date; set **Retain items for** 6 years then choose the end action (**Delete** or **Mark as a
   record**). **Next → Create**.
3. **Clinical-records label:** `Retention Label - Medical Records - Schedule-Defined`. **Set the
   duration from your records schedule / state law — do NOT guess** (medical-record retention varies by
   state and is often longer for minors; this is a **records/legal determination**, deferred). Choose
   **Mark as a record** with **disposition review** for immutable clinical records. **Next → Create**.

## Step 9 — Create a retention policy (baseline)
1. Purview portal → **Data Lifecycle Management → Retention policies → New retention policy**.
2. **Name:** `Retention Policy - Healthcare Baseline - Schedule-Defined`. **Next**.
3. **Locations:** enable **Exchange mailboxes**, **SharePoint sites**, **OneDrive accounts**, and
   **Teams** as required. Scope to `Purview - PHI Pilot Users` for the pilot. **Next**.
4. **Retention settings:** set the duration and end action **from your records schedule** (not a
   default). **Next → Submit**.
5. For regulatory records, configure **Records Management → File plan** to publish the record labels
   and set **disposition review** so PHI is reviewed, not auto-deleted. The **file plan and schedule
   are a records/legal determination — deferred**; you publish what they define.

## Step 10 — (Optional, E5) Reduce PHI exposure to Copilot / AI
1. If licensed for **DSPM / DSPM for AI**, review Purview → **DSPM for AI** to see where PHI-labeled
   content is exposed to Microsoft 365 Copilot and other AI. **Verify your licensing/tenant** —
   availability and portal paths evolve.
2. Use the PHI-restricted label and its encryption/permissions to keep restricted PHI out of AI
   grounding per the minimum-necessary principle. Pilot before broad enforcement.

## Step 11 — Validate, then expand
1. Complete the Testing Guide against `Purview - PHI Pilot Users`.
2. Run `PHI-Validation.ps1` (labels published, DLP present, retention present) and `PHI-Report.ps1`
   (PHI classification + DLP-event coverage).
3. Widen scope: republish `Label Policy - Healthcare PHI Taxonomy - All Users`, the DLP enforce
   policy, and the retention policy from `Purview - PHI Pilot Users` to broader groups (or **All
   users** / **All locations**) once the pilot passes. Turn auto-labeling on (out of simulation) only
   after its simulation is clean and clinical-app/encryption testing (Requirement 2.6) passes.
4. Re-validate each expansion with `PHI-Validation.ps1` and `PHI-Report.ps1`.

---
### Order of operations
`PHI taxonomy → labels → label policy → auto-labeling (simulation) → DLP (audit) → audit gate → DLP (enforce) → retention labels/records (from schedule) → (E5) DSPM for AI → validate → expand`
