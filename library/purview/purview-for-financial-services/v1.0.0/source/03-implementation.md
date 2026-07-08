# 3. Implementation Guide — Microsoft Purview for Financial Services

Follow these steps **in order**, in the **Microsoft Purview portal** (`https://purview.microsoft.com`).
Portal paths are current at authoring — the portal evolves, so **verify the path in your tenant**; if a
node is absent it is usually **licensing** (Requirement 2.1).

> **Model:** Design the FS label taxonomy → publish it → auto-label NPI in **simulation** → build DLP
> in **audit** and tune (the DLP audit gate) before enforcing → set retention/records and apply
> **Preservation Lock only after records/legal sign-off** → stand up communication compliance on a
> **limited pilot** — piloting each on `Purview - FS Pilot Users` before you expand. Pattern:
> Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.

> **Determinations are deferred.** Retention periods, regulatory-record declarations, the supervision
> scheme, and any FINRA/SEC/GLBA applicability are **compliance/records/legal** decisions (Requirement
> 2.4). The steps below configure the mechanism; the owners supply the values.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Sensitivity labels | `Sensitivity Label - FS Public`, `Sensitivity Label - FS Internal`, `Sensitivity Label - FS Confidential (NPI/GLBA)`, `Sensitivity Label - FS Restricted (MNPI)` |
| Label policy | `Label Policy - FS Taxonomy - Pilot` |
| Auto-labeling policy | `Auto-Label - FS NPI (GLBA) - Simulation` |
| DLP policy | `DLP Policy - FS NPI and Financial - Test` (renamed to `... - Enforce` at the gate) |
| Retention labels | `Retention Label - FS Broker-Dealer Records (SEC 17a-4) - 6yr`, `Retention Label - FS Adviser Records (SEC 204-2) - 5yr` |
| Retention policy | `Retention Policy - FS Communications Supervision - 6 Year` |
| Communication-compliance policy | `Comm Compliance - FS Supervision (FINRA 3110) - Pilot` |
| Pilot group | `Purview - FS Pilot Users` |

## Step 1 — Design the FS label taxonomy (Assess/Design)
1. With the data owners and compliance, agree the labels and the protection each applies:
   - `Sensitivity Label - FS Public` — no protection; shareable externally (e.g. published disclosures).
   - `Sensitivity Label - FS Internal` — internal business data; no encryption.
   - `Sensitivity Label - FS Confidential (NPI/GLBA)` — encrypt; restrict to the organization; for
     customer nonpublic personal information (GLBA / Reg S-P).
   - `Sensitivity Label - FS Restricted (MNPI)` — encrypt; restrict to a **named group** (e.g. deal
     team / information-barrier segment); for material nonpublic information.
2. Record each label's meaning, protection, and who applies it (the taxonomy one-pager, Requirement 2.3).

## Step 2 — Create the sensitivity labels
1. Purview portal → **Information Protection → Sensitivity labels → Create a label**.
2. **Name and tooltip:** enter the label name (e.g. `Sensitivity Label - FS Confidential (NPI/GLBA)`)
   and a user-facing tooltip. **Next**.
3. **Scope:** select **Items** (files and emails). **Next**.
4. **Encryption:** **Configure encryption** for `FS Confidential (NPI/GLBA)` (permissions **All Users
   in <org>**) and `FS Restricted (MNPI)` (permissions a **named group**). Leave `FS Public` /
   `FS Internal` unencrypted. **Next**.
5. **Content marking:** add a header/footer/watermark if required (e.g. `CONFIDENTIAL — NPI`). **Next**.
6. **Auto-labeling for items:** leave off here (configured centrally in Step 4). **Next → Create**.
7. Repeat for each label **in sensitivity order** (`FS Public` → `FS Internal` → `FS Confidential
   (NPI/GLBA)` → `FS Restricted (MNPI)`). Label order sets priority.

## Step 3 — Publish the labels with a label policy
1. Purview portal → **Information Protection → Sensitivity labels → Label policies → Publish labels**.
2. **Choose labels to publish:** add all four. **Next**.
3. **Assign to users and groups:** add `Purview - FS Pilot Users` for the pilot. **Next**.
4. **Policy settings:** optionally require justification for downgrading a label and require a label
   for new items. **Next**.
5. **Default label:** optionally set `FS Internal` as default. **Next**.
6. **Name:** `Label Policy - FS Taxonomy - Pilot`. **Next → Submit**.

## Step 4 — Auto-label NPI in SIMULATION
1. Purview portal → **Information Protection → Auto-labeling → Create auto-labeling policy**.
2. **Choose the information to label:** pick the **U.S. Financial Data** / **U.S. Gramm-Leach-Bliley
   Act (GLBA)** template or **Custom** (verify template availability in your tenant). **Next**.
3. **Name:** `Auto-Label - FS NPI (GLBA) - Simulation`. **Next**.
4. **Locations:** select **Exchange email**, **SharePoint sites**, **OneDrive accounts** as needed;
   scope to pilot locations. **Next**.
5. **Rules:** define the condition (e.g. **U.S. Bank Account Number**, **ABA Routing Number**,
   **U.S. Social Security Number**, **Credit Card Number**) and set the label to apply to
   `Sensitivity Label - FS Confidential (NPI/GLBA)`. **Next**.
6. **Run the policy in simulation mode** — do **not** turn it on. **Next → Create**. Review simulation
   matches before turning it on.

## Step 5 — Build the DLP policy in AUDIT (test) mode
1. Purview portal → **Data Loss Prevention → Policies → Create policy**.
2. **Category / template:** choose **U.S. Gramm-Leach-Bliley Act (GLBA)** or **U.S. Financial Data**
   (or **Custom**). **Next**.
3. **Name:** `DLP Policy - FS NPI and Financial - Test`. **Next**.
4. **Locations:** enable **Exchange email**, **SharePoint sites**, **OneDrive accounts**, **Teams chat
   and channel messages**, and **Devices** (endpoint DLP) as licensed. Scope to `Purview - FS Pilot
   Users` where the location supports user scoping. **Next**.
5. **Rules:** match the financial sensitive-information types (e.g. **U.S. Bank Account Number**,
   **ABA Routing Number**, **SWIFT Code**, **U.S. Social Security Number**, **Credit Card Number**)
   and/or the label `Sensitivity Label - FS Confidential (NPI/GLBA)`. Set actions to **audit only**;
   enable **policy tips** for visibility but do **not** block. **Next**.
6. **Policy mode:** select **Run the policy in test mode** (with policy tips). **Next → Submit**. The
   policy now audits without blocking.

## Step 6 — Pilot and tune (the DLP audit gate)
1. Let the audit-mode policy run against `Purview - FS Pilot Users` for the agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
   `FS-Purview-Report.ps1` for a classification and DLP-event summary.
3. Tune the rules to remove false positives (raise confidence levels, require a minimum instance count,
   add exceptions).
4. **Gate:** only when the audit shows the policy matches real NPI/financial data and not routine work
   do you proceed to enforce (Step 7). If still noisy, keep tuning — do **not** enforce.

## Step 7 — Switch DLP to ENFORCE (after the gate)
1. Purview portal → **Data Loss Prevention → Policies →** open `DLP Policy - FS NPI and Financial -
   Test` → **Edit**.
2. Rename it `DLP Policy - FS NPI and Financial - Enforce` so the stage is visible.
3. **Rules:** change the action to **Block** (or **Block with override**) as the business requires;
   keep policy tips on. **Next**.
4. **Policy mode:** select **Turn the policy on**. **Next → Submit**. Enforcement applies to the pilot
   first; widen in Step 11.
5. **Rollback (if needed):** set the policy mode back to **Test mode** (audit) or turn the policy off.

## Step 8 — Create retention labels for FS books-and-records
1. Purview portal → **Data Lifecycle Management → Retention labels → Create a label**.
2. Create `Retention Label - FS Broker-Dealer Records (SEC 17a-4) - 6yr` and
   `Retention Label - FS Adviser Records (SEC 204-2) - 5yr` (period and applicability **as supplied by
   records/legal**, Requirement 2.4). **Next**.
3. **Retention settings:** **Retain items for** the agreed period, **Start of the retention period**
   based on when items were created/labeled, then the end action: **Delete**, **Retain only**, or —
   where the record must be immutable — **Mark items as a regulatory record** (records management).
   **Next → Create**.
   > **Regulatory record is effectively permanent for its retention period and cannot be un-marked.**
   > Only declare it where the records/legal owner confirms it is required.

## Step 9 — Create the retention/supervision policy (and Preservation Lock only after sign-off)
1. Purview portal → **Data Lifecycle Management → Retention policies → New retention policy**.
2. **Name:** `Retention Policy - FS Communications Supervision - 6 Year`. **Next**.
3. **Locations:** enable **Exchange mailboxes**, **SharePoint sites**, **OneDrive accounts**, and
   **Teams** as required by the record set. Scope to `Purview - FS Pilot Users` for the pilot. **Next**.
4. **Retention settings:** **Retain items for** the agreed period, then the agreed end action. **Next →
   Submit**. The policy starts **unlocked** and scoped to the pilot.
5. **Preservation Lock (immutability for SEC 17a-4(f) / FINRA 4511(c) / CFTC 1.31):** apply **only
   after** the records/legal owner signs off the schedule (Requirement 2.8), using
   `Set-RetentionCompliancePolicy -Identity "<name>" -RestrictiveRetention $true`.
   > **This is effectively irreversible** — once locked you cannot shorten the period, remove
   > locations, or disable the policy. There is **no rollback**. Do not lock during the pilot.
6. For records requiring reviewed disposition, configure **Records Management → File plan** and enable
   **disposition review** so deletions are reviewed, not automatic.

## Step 10 — Stand up communication compliance on a LIMITED pilot
1. Confirm the **role separation** from Requirement 2.2 (Admin / Analyst / Investigator held by
   different people) and privacy settings (**pseudonymization on**).
2. Purview portal → **Communication Compliance → Policies → Create policy** → choose a template such as
   **Monitor for regulatory compliance** (or **Detect money laundering / stock manipulation / gifts &
   entertainment** as the supervision scheme requires, Requirement 2.4). **Next**.
3. **Name:** `Comm Compliance - FS Supervision (FINRA 3110) - Pilot`.
4. **Users/scope:** scope to `Purview - FS Pilot Users` only for the pilot. Set the **review
   percentage** low to start. Apply the **lexicon/conditions** supplied by compliance. **Next → Submit**.
5. Route pseudonymized alerts to the **Analyst** role for triage; escalate to **Investigator** only per
   the firm's process. *Any case outcome is a compliance/HR/legal determination — the tool provides the
   evidence, not the decision.*

## Step 11 — Validate, then expand
1. Complete the Testing Guide against `Purview - FS Pilot Users`.
2. Run `FS-Purview-Validation.ps1` (labels published, DLP present, retention present, comms policy
   present) and `FS-Purview-Report.ps1` (classification + DLP-event coverage).
3. Widen scope: republish `Label Policy - FS Taxonomy - Pilot`, the DLP enforce policy, the retention
   policy, and the communication-compliance policy from `Purview - FS Pilot Users` to broader groups
   (or **All users / All locations**) once the pilot passes. Turn auto-labeling on (out of simulation)
   after its simulation is clean. Apply **Preservation Lock** only after records/legal sign-off.
4. Re-validate each expansion with `FS-Purview-Validation.ps1` and `FS-Purview-Report.ps1`.

---
### Order of operations
`FS taxonomy → labels → label policy → auto-label NPI (simulation) → DLP (audit) → audit gate → DLP (enforce) → retention labels/records → retention policy → (Preservation Lock after sign-off) → communication compliance (pilot) → validate → expand`
