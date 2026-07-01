# 3. Implementation Guide — Microsoft Purview: DLP, Sensitivity Labels & Retention

Follow these steps **in order**, in the **Microsoft Purview portal** (`https://purview.microsoft.com`).

> **Model:** Design a small label taxonomy, publish it, add auto-labeling, build DLP in audit and
> tune it (the DLP audit gate) before enforcing, then set retention/records — piloting each on
> `Purview - Pilot Users` before you expand. Pattern: Assess → Configure → Pilot → Validate → Expand.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Sensitivity labels | `Sensitivity Label - Public - All Users`, `Sensitivity Label - General - All Users`, `Sensitivity Label - Confidential - All Users`, `Sensitivity Label - Highly Confidential - All Users` |
| Label policy | `Label Policy - Sensitivity Taxonomy - All Users` |
| Auto-labeling policy | `Auto-Label - Confidential Financial - Pilot` |
| DLP policy | `DLP Policy - Financial and PII - Audit` (renamed to `... - Enforce` at the gate) |
| Retention label | `Retention Label - Financial Records - 7 Year` |
| Retention policy | `Retention Policy - M365 Baseline - 5 Year` |

## Step 1 — Design the label taxonomy (Assess)
1. With the data owners, agree 3–5 labels and the protection each applies. A common starting set:
   - `Sensitivity Label - Public - All Users` — no protection; shareable externally.
   - `Sensitivity Label - General - All Users` — internal business data; no encryption.
   - `Sensitivity Label - Confidential - All Users` — encrypt; restrict to the organization.
   - `Sensitivity Label - Highly Confidential - All Users` — encrypt; restrict to a named group.
2. Record each label's meaning, protection, and who applies it. This one-pager is the taxonomy from
   Requirement 2.3.

## Step 2 — Create the sensitivity labels
1. Purview portal → **Information Protection → Sensitivity labels → Create a label**.
2. **Name and tooltip:** enter `Sensitivity Label - Confidential - All Users` and a user-facing
   tooltip. **Next**.
3. **Scope:** select **Items** (files and emails). **Next**.
4. **Encryption:** choose **Configure encryption** for `Confidential` / `Highly Confidential`; set
   permissions (for example **All Users in <org>** for `Confidential`). Leave `Public` / `General`
   without encryption. **Next**.
5. **Content marking:** add a header/footer/watermark if required (for example `CONFIDENTIAL`).
   **Next**.
6. **Auto-labeling for items:** leave off here (configured centrally in Step 4). **Next → Create the
   label**.
7. Repeat for each label in the taxonomy, creating them in sensitivity order
   (`Public` → `General` → `Confidential` → `Highly Confidential`). Label order sets priority.

## Step 3 — Publish the labels with a label policy
1. Purview portal → **Information Protection → Sensitivity labels → Label policies → Publish labels**.
2. **Choose labels to publish:** add all four taxonomy labels. **Next**.
3. **Assign to users and groups:** add `Purview - Pilot Users` for the pilot. **Next**.
4. **Policy settings:** optionally require a justification for downgrading a label and require a label
   for new items. **Next**.
5. **Default label / mandatory labeling:** set a default (for example `General`) if the org wants one.
   **Next**.
6. **Name:** `Label Policy - Sensitivity Taxonomy - All Users`. **Next → Submit**.

## Step 4 — Configure auto-labeling
1. Purview portal → **Information Protection → Auto-labeling → Create auto-labeling policy**.
2. **Choose the information to label:** pick a template (for example **Financial**) or **Custom**.
   **Next**.
3. **Name:** `Auto-Label - Confidential Financial - Pilot`. **Next**.
4. **Admin units / locations:** select **Exchange email**, **SharePoint sites**, **OneDrive
   accounts** as needed. Scope to pilot locations. **Next**.
5. **Rules:** define the condition (for example the **Credit Card Number** and **U.S. / EU sensitive
   information types**) and set the label to apply to `Sensitivity Label - Confidential - All Users`.
   **Next**.
6. **Test the policy first:** choose **Run policy in simulation mode** — do not turn it on yet.
   **Next → Create**. Review the simulation matches before turning the policy on.

## Step 5 — Build the DLP policy in AUDIT mode
1. Purview portal → **Data Loss Prevention → Policies → Create policy**.
2. **Category / template:** choose a template (for example **Financial** or **Privacy**) or
   **Custom**. **Next**.
3. **Name:** `DLP Policy - Financial and PII - Audit`. **Next**.
4. **Locations:** enable **Exchange email**, **SharePoint sites**, **OneDrive accounts**, **Teams
   chat and channel messages**, and **Devices** (endpoint DLP) as licensed. Scope to
   `Purview - Pilot Users` where the location supports user scoping. **Next**.
5. **Rules:** add a rule that matches the sensitive-information types (for example **Credit Card
   Number**, **U.S. Social Security Number**) and/or the label
   `Sensitivity Label - Confidential - All Users`. Set actions to **audit only** — enable **policy
   tips** for visibility but do **not** block. **Next**.
6. **Policy mode:** select **Run the policy in test mode** (turn on policy tips in test mode).
   **Next → Submit**. The policy now audits without blocking.

## Step 6 — Pilot and tune (the DLP audit gate)
1. Let the audit-mode policy run against `Purview - Pilot Users` for the agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** and in **Activity explorer**; run
   `PURVIEW-Report.ps1` for a classification and DLP-event summary.
3. Tune the rules to remove false positives (adjust confidence levels, instance counts, and
   exceptions).
4. **Gate:** only when the audit shows the policy matches real sensitive data and not routine work do
   you proceed to enforce (Step 7). If it is still noisy, keep tuning — do not enforce.

## Step 7 — Switch DLP to ENFORCE (after the gate)
1. Purview portal → **Data Loss Prevention → Policies →** open `DLP Policy - Financial and PII -
   Audit` → **Edit**.
2. Rename it to `DLP Policy - Financial and PII - Enforce` so the stage is visible.
3. **Rules:** change the action from audit to **Block** (or **Block with override**) as the business
   requires; keep policy tips on. **Next**.
4. **Policy mode:** select **Turn the policy on**. **Next → Submit**. Enforcement now applies to the
   pilot scope first; widen the scope in Step 10.
5. **Rollback (if needed):** set the policy mode back to **Test mode** (audit) or turn the policy off.

## Step 8 — Create retention labels
1. Purview portal → **Data Lifecycle Management → Retention labels → Create a label**.
2. **Name:** `Retention Label - Financial Records - 7 Year`. **Next**.
3. **Retention settings:** **Retain items for** 7 years, then **Start of the retention period** based
   on when items were created (or labeled). Choose the end action: **Delete**, or **Mark as a record**
   (records management) if the item must be immutable. **Next → Create**.

## Step 9 — Create a retention policy (baseline)
1. Purview portal → **Data Lifecycle Management → Retention policies → New retention policy**.
2. **Name:** `Retention Policy - M365 Baseline - 5 Year`. **Next**.
3. **Locations:** enable **Exchange mailboxes**, **SharePoint sites**, **OneDrive accounts**, and
   **Teams** as required. Scope to `Purview - Pilot Users` for the pilot. **Next**.
4. **Retention settings:** **Retain items for** 5 years then decide whether to delete or retain only.
   **Next → Submit**.
5. For regulatory records, configure **Records Management → File plan** to publish record labels and
   set **disposition review** so deletions are reviewed, not automatic.

## Step 10 — Validate, then expand
1. Complete the Testing Guide against `Purview - Pilot Users`.
2. Run `PURVIEW-Validation.ps1` (labels published, DLP present, retention present) and
   `PURVIEW-Report.ps1` (classification + DLP-event coverage).
3. Widen scope: republish `Label Policy - Sensitivity Taxonomy - All Users`, the DLP enforce policy,
   and the retention policy from `Purview - Pilot Users` to broader groups (or **All users** /
   **All locations**) once the pilot passes. Turn auto-labeling on (out of simulation) after its
   simulation is clean.
4. Re-validate each expansion with `PURVIEW-Validation.ps1` and `PURVIEW-Report.ps1`.

---
### Order of operations
`Taxonomy → labels → label policy → auto-labeling (simulation) → DLP (audit) → audit gate → DLP (enforce) → retention labels → retention policy/records → validate → expand`
