# 3. Implementation Guide — Microsoft Purview for Retail

Follow these steps **in order**, in the **Microsoft Purview portal** (`https://purview.microsoft.com`).
Portal paths are current at authoring; the portal evolves — if a path differs, **verify against
Microsoft's current documentation**, do not guess.

> **Model:** Design a small retail label taxonomy, publish it, run auto-labeling in **simulation** to
> find where PAN and customer PII live, build PCI + PII DLP in **test/audit** and tune it (the **DLP
> audit gate**) before it **blocks**, then set retention and stand up the PCI-DSS compliance baseline —
> piloting each on `Purview - Retail Pilot` before you expand. Pattern:
> Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Sensitivity labels | `Sensitivity Label - Retail Public`, `Sensitivity Label - Retail Internal`, `Sensitivity Label - Customer PII - Confidential`, `Sensitivity Label - Cardholder Data - Restricted` |
| Label policy | `Label Policy - Retail Data Classification - Pilot` |
| Auto-labeling policy | `Auto-Label - PCI Cardholder Data - Simulation` |
| DLP policy (PCI) | `DLP Policy - Retail PCI Cardholder Data - Test` (renamed to `... - Enforce` at the gate) |
| DLP policy (PII) | `DLP Policy - Retail Customer PII - Test` (renamed to `... - Enforce` at the gate) |
| Retention label (payment) | `Retention Label - Payment Records - 18 Month` |
| Retention label (transaction) | `Retention Label - Customer Transaction Records - 7 Year` |
| Retention policy | `Retention Policy - Retail Baseline - 5 Year` |
| Compliance assessment | `Assessment - PCI-DSS - Retail Baseline` |
| Pilot scope group | `Purview - Retail Pilot` |

> **Retention periods are examples only.** `18 Month` / `7 Year` / `5 Year` are placeholders — the
> **actual retail records schedule and any PCI-DSS retention/minimization requirement are set by the
> compliance/records/legal function**, not by IT. Replace them with the approved values.

## Step 1 — Design the retail label taxonomy (Assess/Design)
1. With the data owners and compliance, agree the four labels and the protection each applies:
   - `Sensitivity Label - Retail Public` — marketing/public content; no protection; shareable externally.
   - `Sensitivity Label - Retail Internal` — internal retail/business data; no encryption.
   - `Sensitivity Label - Customer PII - Confidential` — customer personal data; encrypt, restrict to
     the organization.
   - `Sensitivity Label - Cardholder Data - Restricted` — any cardholder data (PAN); encrypt, restrict
     to a named group, marked so it is unmistakable and **should not be in M365 at all**.
2. Record each label's meaning, protection, and who applies it (the taxonomy from Requirement 2.4).

## Step 2 — Create the sensitivity labels
1. Purview portal → **Information Protection → Sensitivity labels → Create a label**.
2. **Name and tooltip:** enter the label name (for example `Sensitivity Label - Cardholder Data -
   Restricted`) and a user-facing tooltip. **Next**.
3. **Scope:** select **Items** (files and emails). **Next**.
4. **Encryption:** choose **Configure encryption** for `Customer PII - Confidential` (permit **All
   Users in <org>**) and `Cardholder Data - Restricted` (permit only a named restricted group). Leave
   `Retail Public` / `Retail Internal` without encryption. **Next**.
5. **Content marking:** add a header/footer/watermark where required (for example `RESTRICTED —
   CARDHOLDER DATA` on the cardholder-data label). **Next**.
6. **Auto-labeling for items:** leave off here (configured centrally in Step 4). **Next → Create the
   label**.
7. Repeat for each label, creating them in sensitivity order (`Retail Public` → `Retail Internal` →
   `Customer PII - Confidential` → `Cardholder Data - Restricted`). Label order sets priority.

## Step 3 — Publish the labels with a label policy
1. Purview portal → **Information Protection → Sensitivity labels → Label policies → Publish labels**.
2. **Choose labels to publish:** add all four taxonomy labels. **Next**.
3. **Assign to users and groups:** add `Purview - Retail Pilot` for the pilot. **Next**.
4. **Policy settings:** require a justification for downgrading a label; optionally require a label for
   new items. **Next**.
5. **Default label:** set a default (for example `Retail Internal`) if the org wants one. **Next**.
6. **Name:** `Label Policy - Retail Data Classification - Pilot`. **Next → Submit**.

## Step 4 — Configure auto-labeling in SIMULATION (find the data)
1. Purview portal → **Information Protection → Auto-labeling → Create auto-labeling policy**.
2. **Choose the information to label:** pick the **PCI Data Security Standard (PCI DSS)** template or
   **Custom**. **Next**.
3. **Name:** `Auto-Label - PCI Cardholder Data - Simulation`. **Next**.
4. **Locations:** select **Exchange email**, **SharePoint sites**, **OneDrive accounts** as needed;
   scope to pilot locations. **Next**.
5. **Rules:** set the condition to the **Credit Card Number** sensitive-information type and set the
   label to apply to `Sensitivity Label - Cardholder Data - Restricted`. **Next**.
6. **Test the policy first:** choose **Run policy in simulation mode** — do **not** turn it on.
   **Next → Create**. Review the simulation matches: **these show where PAN is sitting in M365** — the
   input to your PCI-scope and remediation decisions.

## Step 5 — Build the PCI DLP policy in TEST/AUDIT mode
1. Purview portal → **Data Loss Prevention → Policies → Create policy**.
2. **Category / template:** choose the **PCI Data Security Standard (PCI DSS)** template. **Next**.
3. **Name:** `DLP Policy - Retail PCI Cardholder Data - Test`. **Next**.
4. **Locations:** enable **Exchange email**, **SharePoint sites**, **OneDrive accounts**, **Teams chat
   and channel messages**, and **Devices** (endpoint DLP) as licensed. Scope to `Purview - Retail
   Pilot` where the location supports user scoping. **Next**.
5. **Rules:** keep the template rule matching the **Credit Card Number** SIT (optionally also the
   `Cardholder Data - Restricted` label). Set actions to **audit only** — enable **policy tips** for
   visibility but do **not** block. **Next**.
6. **Policy mode:** select **Run the policy in test mode** (with policy tips). **Next → Submit**. The
   policy now audits PAN movement without blocking.

## Step 6 — Build the customer-PII DLP policy in TEST/AUDIT mode
1. Purview portal → **Data Loss Prevention → Policies → Create policy**.
2. **Template:** choose the country **PII / Personal Data** template relevant to your customers (or
   **Custom**). **Next**.
3. **Name:** `DLP Policy - Retail Customer PII - Test`. **Next**.
4. **Locations:** enable the same locations as Step 5; scope to `Purview - Retail Pilot`. **Next**.
5. **Rules:** match the relevant country PII SITs and/or the `Customer PII - Confidential` label; set
   actions to **audit only** with policy tips. **Next**.
6. **Policy mode:** **Run the policy in test mode**. **Next → Submit**.

## Step 7 — Pilot and tune (the DLP audit gate)
1. Let both test-mode policies run against `Purview - Retail Pilot` for the agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
   `RETAIL-Report.ps1` for a classification and DLP-event summary by workload.
3. Tune the rules to remove false positives (raise confidence, require a higher instance count, add
   exceptions for legitimate patterns such as order numbers that resemble a PAN).
4. **Gate:** only when the audit shows the policies match real PAN / customer PII and not routine retail
   work do you proceed to enforce (Step 8). If still noisy, keep tuning — do **not** enforce.

## Step 8 — Switch DLP to ENFORCE / BLOCK (after the gate)
1. Purview portal → **Data Loss Prevention → Policies →** open `DLP Policy - Retail PCI Cardholder
   Data - Test` → **Edit**. Rename it to `DLP Policy - Retail PCI Cardholder Data - Enforce`.
2. **Rules:** change the PCI rule action to **Block** (PAN should not move through M365 at all —
   block outright, not block-with-override, unless the business defines a controlled exception).
   Keep policy tips on. **Next**.
3. **Policy mode:** **Turn the policy on**. **Next → Submit**.
4. Repeat for the PII policy → rename to `DLP Policy - Retail Customer PII - Enforce`; set **Block with
   override** (or Block) per the business decision; **Turn the policy on**.
5. Enforcement now applies to the pilot scope first; widen the scope in Step 12.
6. **Rollback (if needed):** set the policy mode back to **Test mode** (audit) or turn the policy off.

## Step 9 — Create retention labels (retail records + payment minimization)
1. Purview portal → **Data Lifecycle Management → Retention labels → Create a label**.
2. Create `Retention Label - Customer Transaction Records - 7 Year`: **Retain items for** 7 years from
   creation, then **Delete** (or **Mark as a record** if immutability is required). **Create**.
3. Create `Retention Label - Payment Records - 18 Month`: a **short** retention that supports PCI-DSS
   **data minimization** — keep only as long as the business/legal requirement demands, then delete.
   **Create**.
4. **Replace the durations** with the compliance/records-approved values (Requirement 2.3).

## Step 10 — Create a retention policy (baseline)
1. Purview portal → **Data Lifecycle Management → Retention policies → New retention policy**.
2. **Name:** `Retention Policy - Retail Baseline - 5 Year`. **Next**.
3. **Locations:** enable **Exchange mailboxes**, **SharePoint sites**, **OneDrive accounts**, and
   **Teams** as required. Scope to `Purview - Retail Pilot` for the pilot. **Next**.
4. **Retention settings:** **Retain items for** 5 years then delete or retain-only per the schedule.
   **Next → Submit**.
5. For regulatory records, configure **Records Management → File plan** and enable **disposition
   review** so deletions are reviewed, not automatic.

## Step 11 — Stand up the PCI-DSS compliance baseline (evidence)
1. Purview portal → **Compliance Manager → Assessments → Add assessment**. Choose the **PCI-DSS**
   template (premium template — **verify your licensing/tenant**; requires E5 Compliance).
2. **Name:** `Assessment - PCI-DSS - Retail Baseline`. Assign the in-scope group/product. **Create**.
3. Work the improvement actions that map to the Purview controls configured above (classification,
   DLP, retention) and record evidence. **The PCI-DSS applicability and control ownership are
   determined by compliance/QSA** — Compliance Manager tracks and evidences, it does not certify.

## Step 12 — Validate, then expand
1. Complete the Testing Guide against `Purview - Retail Pilot`.
2. Run `RETAIL-Validation.ps1` (labels published, both DLP policies present, retention present) and
   `RETAIL-Report.ps1` (classification + DLP-event coverage).
3. Widen scope: republish `Label Policy - Retail Data Classification - Pilot`, the two DLP enforce
   policies, and the retention policy from `Purview - Retail Pilot` to broader groups (or **All users**
   / **All locations**) once the pilot passes. Turn auto-labeling on (out of simulation) only after its
   simulation is clean.
4. Re-validate each expansion with `RETAIL-Validation.ps1` and `RETAIL-Report.ps1`.

---
### Order of operations
`Taxonomy → labels → label policy → auto-label (simulation) → PCI DLP (audit) + PII DLP (audit) → audit gate → DLP (enforce/block) → retention labels → retention policy/records → PCI Compliance Manager → validate → expand`
