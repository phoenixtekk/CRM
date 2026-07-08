# 3. Implementation Guide — Microsoft Purview for Education (FERPA)

Follow these steps **in order**. **Purview portal** navigation and **Security & Compliance PowerShell /
Graph** cmdlets are given from Microsoft's public documentation. Where a capability is **plan-gated or
in preview**, the step flags **"verify your licensing/tenant."** **Regulatory/records/legal
determinations** (FERPA applicability, retention periods, file plans, legal holds) are the institution's
governance calls — this guide configures the **method**, not the determination.

Consoles used:
- **Microsoft Purview portal** — `https://purview.microsoft.com`
- **Microsoft 365 admin center** — `https://admin.microsoft.com` (licensing/roles)
- **Security & Compliance PowerShell** — `Connect-IPPSSession` (ExchangeOnlineManagement module)
- **Microsoft Graph** — reporting/read helpers

> **Model:** Configure labels, DLP (**Test/simulation**), retention, and Compliance Manager; **pilot in
> simulation/test** on the pilot scope; validate against pass/fail gates; then **enforce and expand** in
> waves. **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**

> **Artifact names (use verbatim; names/periods are placeholders to confirm with governance owners):**
> labels `EDU - Public` / `EDU - Internal` / `EDU - Student Record (FERPA)` / `EDU - Highly
> Confidential`; label policy `EDU - Label Policy - Pilot`; custom SIT `EDU - Student ID`; DLP policy
> `EDU - FERPA Student Records - DLP - Pilot` (**Test** mode); retention label `EDU - Student Education
> Record`; retention/label policy `EDU - Retention - Student Records - Pilot`; Compliance Manager
> assessment `EDU - FERPA Posture`.

> **Risk + rollback (read first):** Labels, DLP, and retention are **high-impact**. **Nothing enforces
> in this guide until validated.** DLP is created in **Test** mode; auto-labeling runs in **simulation**;
> labels publish to a **pilot scope** first; retention is applied only after the records owner confirms
> the schedule. **Rollback:** a DLP policy in **Test** blocks no one — to revert, set it back to Test or
> **disable/delete** it; to unpublish labels, **remove the label policy** (or the pilot group from it) —
> the labels remain but stop being offered; auto-labeling **simulation** applies nothing until you
> turn it on. **Retention, once applied, preserves content and is harder to reverse — do not apply
> retention until the records owner has signed off the period** (a retention *label* can be unpublished,
> but content already retained stays retained for the period). Pilot everything on a **small** scope
> first.

---

## Phase 1 — Assess and prepare (no changes)

### Step 1 — Baseline the tenant and confirm licensing/roles
1. Run **`EDU-Scope-Health.ps1`** — it reports the compliance licensing the tenant exposes, the
   operator's Purview role-group membership (where readable), and the in-scope workloads, and flags
   gaps against the Requirements Guide. **Verify your licensing/tenant** for any preview capability.
2. Run **`EDU-Discovery.ps1`** — read-only inventory of existing sensitivity labels, label policies,
   DLP policies (and their mode), retention labels/policies, custom SITs, and audit state, so you build
   **on** the current tenant rather than duplicating.
3. Confirm the education-record **data map** and the **records schedule** with the records/privacy/legal
   owners (Requirements 2.3, 2.7). **Do not invent retention periods.**

---

## Phase 2 — Classification foundation (labels + SIT)

### Step 2 — Create the education sensitivity-label taxonomy
1. Purview → **Information Protection → Sensitivity labels → Create a label** (or `New-Label` in S&C
   PowerShell). Create, in order (parent labels first if you use sublabels):
   - `EDU - Public` — no protection; marking optional.
   - `EDU - Internal` — internal-only; header/footer marking.
   - `EDU - Student Record (FERPA)` — **encryption + content marking** (e.g. "FERPA — Student Record");
     scope to files/emails (and containers if used for student-data sites/Teams).
   - `EDU - Highly Confidential` — strongest encryption/marking for the most sensitive records.
2. Set each label's **protection** (encryption, content marking, container settings) per the taxonomy
   approved in Requirement 2.5. Keep protection **minimal for the pilot** and tighten later.
3. Prefer automation? **`EDU-Set-Configuration.ps1 -Area Labels`** creates the label set via S&C
   PowerShell — default **`-WhatIf`**; add **`-Commit`** to write.

### Step 3 — Build the custom `EDU - Student ID` sensitive information type
1. Purview → **Data classification → Sensitive info types → Create sensitive info type** (or
   `New-DlpSensitiveInformationType`). Name it `EDU - Student ID`; define the **pattern** (regex +
   supporting keywords) that matches **your** student-identifier format, with a confidence level and
   proximity to keywords (e.g. "student ID", "SID").
2. **Test** it against sample values in the create flow; tune to minimize false positives.
3. This SIT plus built-in SITs (names, U.S. SSN, etc.) become the **education-record** condition your
   DLP and (optionally) auto-labeling use. There is **no universal built-in FERPA SIT** — this is the
   education-specific signal you provide.

### Step 4 — Publish the labels to the pilot scope
1. Purview → **Information Protection → Label policies → Publish label** (or `New-LabelPolicy`). Name it
   `EDU - Label Policy - Pilot`; **assign it to the pilot user group** (Requirement 2.10).
2. Set policy options for the pilot (e.g. a **default label** of `EDU - Internal`, **not mandatory**
   yet, allow users to justify downgrades). **Mandatory labeling is an enforcing change — defer it to
   the expand phase.**
3. **Pass/fail gate:** pilot users see the four labels in Office apps within the publish window
   (typically up to a few hours). Validate with the Testing Guide before widening.

---

## Phase 3 — DLP in Test/simulation

### Step 5 — Create the FERPA-oriented DLP policy in Test mode
1. Purview → **Data Loss Prevention → Policies → Create policy** (or `New-DlpCompliancePolicy` +
   `New-DlpComplianceRule`). Name it `EDU - FERPA Student Records - DLP - Pilot`.
2. **Locations:** Exchange, SharePoint, OneDrive, Teams, and **Devices** (endpoint DLP — only if devices
   are onboarded, Requirement 2.3). Scope to the **pilot** where the location supports scoping.
3. **Conditions (education-record detection):** content contains `EDU - Student ID` **AND** (a name SIT
   or U.S. SSN), **OR** the file/email carries the `EDU - Student Record (FERPA)` label. Tune counts and
   confidence to your false-positive tolerance.
4. **Actions:** restrict sharing **outside the organization**, notify the user with a **policy tip**,
   and generate an **incident report** — but set the policy **status to Test** (with or without policy
   tips). **Do not enforce.**
5. Automate with **`EDU-Set-Configuration.ps1 -Area DLP`** — it creates the policy in **Test** mode by
   default; it will **not** enable enforcement even with `-Commit` (enforcement is a deliberate,
   separate, out-of-band change in Step 9).
6. **Pass/fail gate:** the policy exists in **Test**; **`EDU-Validation.ps1`** confirms mode = Test and
   the rule conditions are present.

### Step 6 — (Optional) Auto-labeling in simulation
1. If licensed (**E5**, verify), Purview → **Information Protection → Auto-labeling → Create policy** to
   auto-apply `EDU - Student Record (FERPA)` where education-record content is detected (using the
   `EDU - Student ID` SIT). **Run it in simulation** — it labels **nothing** until you review results
   and turn it on.
2. Let simulation accumulate matches; review the simulated items for accuracy before ever enabling.

---

## Phase 4 — Retention & records (schedule-driven)

### Step 7 — Configure student-record retention (per the approved schedule)
1. **Only after the records owner signs off the schedule** (Requirement 2.7). Purview → **Data
   Lifecycle Management** (or **Records Management** if declaring records) → **Retention labels →
   Create a label** `EDU - Student Education Record`; set the **retention period and disposition** to
   the **records owner's approved values** (placeholder here — do **not** invent).
2. **Publish** the label via a **retention label policy** `EDU - Retention - Student Records - Pilot` to
   the pilot SharePoint/OneDrive/Exchange locations, **or** apply it via an **auto-apply retention
   policy** keyed on the education-record condition (Step 5 logic). Use **disposition review** where
   records management requires human sign-off before deletion.
3. **Pass/fail gate:** the retention label exists with the approved period and is published to the pilot;
   **`EDU-Validation.ps1`** confirms it. Remember retention **preserves content** — confirm the period
   before applying broadly.

---

## Phase 5 — Posture, validate, and expand

### Step 8 — Stand up the Compliance Manager posture
1. Purview → **Compliance Manager → Assessments → Add assessment**; choose the **education/FERPA**
   template if licensed (else the **Data Protection Baseline**), name it `EDU - FERPA Posture`.
2. Work the **improvement actions** the assessment lists, attaching evidence (the labels/DLP/retention
   you configured, plus Audit). This produces the **defensible, scored** posture.

### Step 9 — Validate the pilot, then expand to enforce (waves)
1. Complete the **Testing Guide** pilot gates: labels visible, DLP catching in Test (review the
   simulated/Test matches), retention applied on the pilot, auto-label simulation accurate, audit
   logging.
2. **Only after the gates pass and change control approves**, expand:
   - Create production twins (`EDU - Label Policy - Prod`, `EDU - FERPA Student Records - DLP - Prod`,
     `EDU - Retention - Student Records - Prod`) or widen the pilot policies.
   - **Turn DLP from Test → Enforce** for the production scope (this is the deliberate enforcing change).
   - Publish labels tenant-wide (and consider **mandatory** labeling once staff are trained).
   - Turn **auto-labeling** from simulation → on, after reviewing simulation results.
3. Re-run **`EDU-Validation.ps1`** and **`EDU-Report.ps1`** after each wave; validate before widening.

---
### Order of operations
`Baseline (Scope-Health + Discovery) → create labels → build EDU - Student ID SIT → publish labels to
pilot → DLP in Test (education-record conditions) → (auto-label simulation) → retention per approved
schedule → Compliance Manager posture → validate pilot gates → expand: DLP Test→Enforce, labels
tenant-wide, auto-label on — in waves, validating each`
