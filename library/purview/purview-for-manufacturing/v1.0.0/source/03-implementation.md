# 3. Implementation Guide — Microsoft Purview for Manufacturing

Follow these steps **in order**, in the **Microsoft Purview portal** (`https://purview.microsoft.com`).
Portal paths and cmdlets are current at authoring; Purview evolves and features are licensing-/cloud-
dependent — **verify your licensing/tenant** and treat any absent feature as a plan/cloud gap
(Requirement 2.1), not a mistake in the steps.

> **Model:** Design a Manufacturing taxonomy (IP + CUI) → publish labels → add auto-labeling /
> custom classifiers in **simulation** → build DLP in **audit** and tune it (the **DLP audit gate**)
> before enforcing → set retention/records → track CMMC/800-171 in Compliance Manager — piloting each
> on `Purview - Manufacturing Pilot` before you expand. Pattern: **Assess → Design → Configure →
> Pilot (simulate/test) → Validate → Expand (enforce)**.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Sensitivity labels | `Sensitivity Label - MFG-Public`, `Sensitivity Label - MFG-Internal`, `Sensitivity Label - MFG-Confidential-IP`, `Sensitivity Label - MFG-CUI`, `Sensitivity Label - MFG-CUI-Export-Controlled` |
| Label policy | `Label Policy - Manufacturing Taxonomy - All Users` |
| Custom SIT | `SIT - MFG Part/Drawing Number` |
| Auto-labeling policy | `Auto-Label - CUI and Export-Controlled - Pilot` |
| DLP policy | `DLP Policy - Manufacturing IP and CUI - Audit` (renamed to `... - Enforce` at the gate) |
| Retention label | `Retention Label - Quality and Contract Records - 7 Year` |
| Retention policy | `Retention Policy - Manufacturing Baseline - 5 Year` |
| Compliance assessment | `Assessment - CMMC / NIST 800-171 - Manufacturing` |

## Step 1 — Design the Manufacturing taxonomy (Assess/Design)
1. With data owners **and** compliance/legal/export-control, agree the labels and the protection each
   applies. A Manufacturing-tailored starting set:
   - `Sensitivity Label - MFG-Public` — cleared for public release; no protection.
   - `Sensitivity Label - MFG-Internal` — internal business data; no encryption.
   - `Sensitivity Label - MFG-Confidential-IP` — designs/specs/BOMs/firmware; **encrypt**, restrict to
     the organization **and named partner domains** (Requirement 2.6).
   - `Sensitivity Label - MFG-CUI` — Controlled Unclassified Information; **encrypt**, restrict to
     authorized users; **CUI header/footer marking**.
   - `Sensitivity Label - MFG-CUI-Export-Controlled` — ITAR/EAR technical data; **encrypt**, restrict
     to authorized **U.S. persons / named recipients only**; export-control marking.
2. Record each label's meaning, protection, marking, and who applies it. **The CUI and export-control
   determinations are made by compliance/legal/export-control** — capture them, don't invent them.

## Step 2 — Create the sensitivity labels
1. Purview portal → **Information Protection → Sensitivity labels → Create a label**.
2. **Name and tooltip:** enter the label name (e.g. `Sensitivity Label - MFG-CUI`) and a user-facing
   tooltip. **Next**.
3. **Scope:** select **Items** (files and emails). **Next**.
4. **Encryption:** choose **Configure encryption** for `MFG-Confidential-IP`, `MFG-CUI`, and
   `MFG-CUI-Export-Controlled`; set permissions — for `MFG-Confidential-IP` allow the org **and** the
   named partner domains; for the CUI labels restrict to authorized users/recipients only. Leave
   `MFG-Public` / `MFG-Internal` unencrypted. **Next**.
5. **Content marking:** add a header/footer/watermark where required — e.g. `CUI` for `MFG-CUI` and an
   export-control banner for `MFG-CUI-Export-Controlled`. **Next**.
6. **Auto-labeling for items:** leave off here (configured centrally in Step 5). **Next → Create the
   label**.
7. Repeat for each label, creating them in sensitivity order
   (`MFG-Public` → `MFG-Internal` → `MFG-Confidential-IP` → `MFG-CUI` →
   `MFG-CUI-Export-Controlled`). Label order sets priority.

## Step 3 — Publish the labels with a label policy
1. Purview portal → **Information Protection → Sensitivity labels → Label policies → Publish labels**.
2. **Choose labels to publish:** add all five taxonomy labels. **Next**.
3. **Assign to users and groups:** add `Purview - Manufacturing Pilot` for the pilot. **Next**.
4. **Policy settings:** require a **justification for downgrading** a label and (optionally) **require
   a label** for new items — important for IP/CUI hygiene. **Next**.
5. **Default label / mandatory labeling:** set a default (for example `MFG-Internal`) if the org wants
   one. **Next**.
6. **Name:** `Label Policy - Manufacturing Taxonomy - All Users`. **Next → Submit**.

## Step 4 — Build the custom sensitive-information type (IP detection)
1. Purview portal → **Data classification → Classifiers → Sensitive info types → Create sensitive info
   type**.
2. **Name:** `SIT - MFG Part/Drawing Number`. **Next**.
3. **Pattern:** add a **primary element** as a **regular expression** matching your part/drawing-number
   format (from Requirement 2.4), optionally with **supporting keywords** (e.g. `drawing`, `rev`,
   `assembly`, `BOM`). Set a **confidence level** and **character proximity**. **Next → Create**.
4. Test it with **Test** using sample content before relying on it. (For CUI, also confirm whether the
   built-in **CUI trainable classifier / CUI SITs** are available in your plan/cloud — **verify your
   tenant** — and prefer them where present.)

## Step 5 — Configure auto-labeling in SIMULATION
1. Purview portal → **Information Protection → Auto-labeling → Create auto-labeling policy**.
2. **Choose the information to label:** pick **Custom** (to use `SIT - MFG Part/Drawing Number` and/or
   the CUI classifier). **Next**.
3. **Name:** `Auto-Label - CUI and Export-Controlled - Pilot`. **Next**.
4. **Locations:** select **SharePoint sites**, **OneDrive accounts**, and **Exchange email** as needed;
   scope to pilot locations. **Next**.
5. **Rules:** condition = `SIT - MFG Part/Drawing Number` (and/or the CUI classifier); set the label to
   apply — `Sensitivity Label - MFG-Confidential-IP` for IP, `Sensitivity Label - MFG-CUI` for CUI
   matches. **Next**.
6. **Test the policy first:** choose **Run policy in simulation mode** — do **not** turn it on. **Next
   → Create**. Review simulation matches (Step 7 / Testing) before turning it on.

## Step 6 — Build the DLP policy in AUDIT mode
1. Purview portal → **Data Loss Prevention → Policies → Create policy**.
2. **Category / template:** choose **Custom** (Manufacturing IP/CUI is not a stock template). **Next**.
3. **Name:** `DLP Policy - Manufacturing IP and CUI - Audit`. **Next**.
4. **Locations:** enable **Exchange email**, **SharePoint sites**, **OneDrive accounts**, **Teams chat
   and channel messages**, and **Devices** (endpoint DLP) as licensed. Scope to
   `Purview - Manufacturing Pilot` where the location supports user scoping. **Next**.
5. **Rules:** add rules that match:
   - the label `Sensitivity Label - MFG-CUI` **or** `Sensitivity Label - MFG-Confidential-IP`,
   - `SIT - MFG Part/Drawing Number`, and
   - export-control indicators (the **ITAR / EAR** sensitive-information types where available — **verify
     your tenant**), with a **recipient condition** blocking send to domains outside the trusted
     partner list (Requirement 2.6).
   Set actions to **audit only** — enable **policy tips** for visibility but do **not** block. For
   endpoint rules, audit **copy to USB / removable media, print, and upload to unallowed browsers**.
   **Next**.
6. **Policy mode:** select **Run the policy in test mode** (policy tips on). **Next → Submit**. The
   policy now audits without blocking.

## Step 7 — Pilot and tune (the DLP audit gate)
1. Let the audit-mode policy run against `Purview - Manufacturing Pilot` for the agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
   `PURVIEW-MFG-Report.ps1` for a classification and DLP-event summary. Review the auto-labeling
   **simulation** results too.
3. Tune to remove false positives — adjust the SIT confidence/proximity, instance counts, and
   exceptions (e.g. legitimate supplier domains).
4. **Gate:** only when the audit shows the policy matches real IP/CUI/export-controlled data and not
   routine engineering work do you proceed to enforce (Step 8). If it is still noisy, keep tuning —
   **do not enforce**.

## Step 8 — Switch DLP to ENFORCE (after the gate)
1. Purview portal → **Data Loss Prevention → Policies →** open `DLP Policy - Manufacturing IP and CUI -
   Audit` → **Edit**.
2. Rename it to `DLP Policy - Manufacturing IP and CUI - Enforce` so the stage is visible.
3. **Rules:** change the action to **Block** (or **Block with override** for internal recipients) as
   the business requires; keep the export-control rule as **hard block**. Keep policy tips on. **Next**.
4. **Policy mode:** select **Turn the policy on**. **Next → Submit**. Enforcement applies to the pilot
   scope first; widen in Step 11.
5. **Rollback (if needed):** set the policy mode back to **Test mode** (audit) or turn the policy off.

## Step 9 — Create retention labels (quality / contract / CUI records)
1. Purview portal → **Data Lifecycle Management → Retention labels → Create a label**.
2. **Name:** `Retention Label - Quality and Contract Records - 7 Year`. **Next**.
3. **Retention settings:** **Retain items for** the period from your records schedule (Requirement 2.8;
   7 years shown as a placeholder — **the schedule is a records/compliance determination**), start of
   period based on when items were created (or labeled). End action: **Delete**, or **Mark as a
   record** (records management) where the item must be immutable (e.g. CUI/contract records). **Next →
   Create**.

## Step 10 — Create a retention policy + records file plan
1. Purview portal → **Data Lifecycle Management → Retention policies → New retention policy**.
2. **Name:** `Retention Policy - Manufacturing Baseline - 5 Year`. **Next**.
3. **Locations:** enable **Exchange mailboxes**, **SharePoint sites**, **OneDrive accounts**, and
   **Teams** as required. Scope to `Purview - Manufacturing Pilot` for the pilot. **Next**.
4. **Retention settings:** retain for the baseline period from the schedule, then delete or retain-only.
   **Next → Submit**.
5. For regulatory/CUI records, configure **Records Management → File plan** to publish record labels and
   enable **disposition review** so deletions are reviewed, not automatic. **File-plan content and
   schedules are records/compliance determinations.**

## Step 11 — Track CMMC / NIST 800-171, then validate and expand
1. Purview portal → **Compliance Manager → Assessments → Add assessment**; select the **CMMC** /
   **NIST SP 800-171** template (availability varies by plan/cloud — **verify your tenant**) and name
   it `Assessment - CMMC / NIST 800-171 - Manufacturing`. Work the **improvement actions** that map to
   the labels/DLP/retention/audit you configured; capture the evidence.
2. Complete the Testing Guide against `Purview - Manufacturing Pilot`; run `PURVIEW-MFG-Validation.ps1`
   (labels published, DLP present, retention present) and `PURVIEW-MFG-Report.ps1` (coverage).
3. **Expand:** republish `Label Policy - Manufacturing Taxonomy - All Users`, the DLP **Enforce**
   policy, and the retention policy from the pilot to broader groups (or **All users** / **All
   locations**) once the pilot passes. Turn auto-labeling **on** (out of simulation) only after its
   simulation is clean.
4. Re-validate each expansion with `PURVIEW-MFG-Validation.ps1` and `PURVIEW-MFG-Report.ps1`.

---
### Order of operations
`Taxonomy (IP+CUI) → labels → label policy → custom SIT → auto-labeling (simulation) → DLP (audit) →
audit gate → DLP (enforce) → retention labels → retention policy/records → CMMC/800-171 in Compliance
Manager → validate → expand`
