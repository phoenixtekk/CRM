# 3. Implementation Guide — Microsoft Purview Administrator Training

Follow these steps **in order**, working in the **Microsoft Purview portal** (`purview.microsoft.com`),
the **Microsoft 365 admin center**, and **Security & Compliance PowerShell** / **Microsoft Graph** from
the training workstation.

> **Model:** Stand up the training program first (readiness → scope → baseline), then run the labs in
> sequence. **Every lab is scoped to `TRAIN-Pilot-Users` and runs in simulation/test/disabled mode
> first**, ends at a **pass/fail validation gate**, and has a **teardown**. Name every object exactly
> as shown (`TRAIN-…`), verbatim across the portal, scripts, and reports.

> **Training, not determination.** The label taxonomy, retention periods, and policy scopes below are
> **illustrative** so trainees can practice the mechanics. **Real** retention schedules, records file
> plans, legal holds, and insider-risk / communication-compliance **case outcomes** are
> **legal/records/privacy/HR determinations** — configure to *illustrative* values here and route real
> decisions to those functions.

> **Verify in your tenant.** Purview capability availability is **licensing-dependent** and portal
> paths **evolve**. Where a feature is unlicensed, run that lab as a **read-only walkthrough**. Confirm
> exact toggles for your tenant; defer volatile specifics to Microsoft's documentation — nothing here
> is invented.

---

## Phase A — Stand up the training program

### Step 1 — Readiness check (read-only)
1. From the training workstation, `Connect-IPPSSession` and `Connect-MgGraph` with the admin account.
2. Run `OPSTRAIN-Readiness.ps1`. It confirms connectivity, reports the connected **tenant**, the
   readable **role context**, whether the training scope group **`TRAIN-Pilot-Users`** exists, and
   **which Purview feature areas are readable** (labels, DLP, retention, auto-labeling, audit) — warning
   where a feature is not readable (likely **unlicensed** → that lab becomes a read-only walkthrough).
3. **Gate:** connectivity succeeds and the readiness report lists the feature areas your curriculum will
   cover. Resolve any missing module/role/license before continuing.

### Step 2 — Create the training scope group (`TRAIN-Pilot-Users`)
1. Preview first: `OPSTRAIN-LabScope.ps1` (default `-WhatIf`) shows what it would create/verify.
2. Apply: `OPSTRAIN-LabScope.ps1 -Commit` creates (or verifies) the **`TRAIN-Pilot-Users`** security
   group containing only **test accounts**, or confirm it in **Entra ID → Groups**.
3. **Gate:** `TRAIN-Pilot-Users` exists and contains only training/test accounts — **no real users.**

### Step 3 — Capture the lab baseline (read-only)
1. Run `OPSTRAIN-LabBaseline.ps1` to snapshot the current Purview configuration — existing labels, label
   policies, DLP policies/rules, retention policies, and auto-labeling policies — to a CSV baseline.
2. This is the **known-good "before"** state. Each lab's teardown returns the tenant to it, and
   `OPSTRAIN-LabValidate.ps1` diffs against it to confirm only `TRAIN-` objects were added.
3. **Gate:** the baseline CSV is written and reviewed; the team knows what existed before training.

---

## Phase B — Foundations

### Step 4 — Module 0: Portal orientation, roles & toolchain (read-only)
1. Tour the **Purview portal** (`purview.microsoft.com`): the solution catalog (Information Protection,
   Data Loss Prevention, Data Lifecycle Management, Records management, Insider Risk Management,
   Communication Compliance, Audit, eDiscovery, DSPM) and **Settings → Roles & scopes / Permissions**.
2. Have each trainee locate their assigned **least-privilege role group** and explain what it grants —
   and, for Modules 5–6, why analyst/investigator/admin roles must be **separated**.
3. Confirm the toolchain: `Connect-IPPSSession`, `Connect-MgGraph`, and `Get-Label` all succeed.
4. **Gate:** each trainee can navigate the portal, name their role and its least privilege, and connect
   both PowerShell endpoints. **Rollback:** none (read-only).

---

## Phase C — Information protection labs

### Step 5 — Lab 1: Sensitivity label + label policy (scoped pilot)
1. **Purview portal → Information Protection → Labels → Create a label**: create
   **`TRAIN-Label-Confidential`** (illustrative — display name, tooltip; optional encryption/marking left
   as a discussion point, not enforced in the training tenant).
2. **Information Protection → Label policies → Publish label**: create policy **`TRAIN-LabelPolicy-Pilot`**
   publishing `TRAIN-Label-Confidential` **only to `TRAIN-Pilot-Users`**.
3. Validate: `OPSTRAIN-LabValidate.ps1 -Lab Labels` confirms the label exists and is published to the
   training scope (via `Get-Label` / `Get-LabelPolicy`).
4. **Pass/fail gate:** `TRAIN-Label-Confidential` exists and `TRAIN-LabelPolicy-Pilot` publishes it to
   `TRAIN-Pilot-Users` only. A test account sees the label in Office; no real user does.
5. **Teardown:** remove the label policy then the label (portal, or note in the teardown log) to return
   to baseline.

### Step 6 — Lab 4: Auto-labeling in simulation mode (E5 — verify licensing)
*(Run Lab 4 with Lab 1 because it applies the Lab 1 label; sequence it here.)*
1. **Information Protection → Auto-labeling → Create policy**: create **`TRAIN-AutoLabel-Sim`** that
   applies `TRAIN-Label-Confidential` based on an **illustrative** condition (e.g. a synthetic sensitive
   info type), scoped to `TRAIN-Pilot-Users` locations only.
2. **Set the policy to run in *simulation* mode** — do **not** turn it on. (Auto-labeling supports a
   simulation/"test" mode; `Get-AutoSensitivityLabelPolicy` shows the `Mode`.)
3. Let simulation run, then review the **simulation results** in the portal (matched items, no label
   actually applied).
4. Validate: `OPSTRAIN-LabValidate.ps1 -Lab AutoLabel` confirms `TRAIN-AutoLabel-Sim` exists and is in a
   **simulation/test** mode (never enabled).
5. **Pass/fail gate:** the policy exists in **simulation** mode and produced results; **no item was
   actually labeled.** **Teardown:** delete `TRAIN-AutoLabel-Sim`.
6. **If auto-labeling is unlicensed:** run as a read-only walkthrough of the portal experience.

---

## Phase D — Data Loss Prevention lab

### Step 7 — Lab 2: DLP policy in test / simulation mode (no enforcement)
1. **Purview portal → Data Loss Prevention → Policies → Create policy**: create **`TRAIN-DLP-PII-Sim`**
   with an **illustrative** rule (e.g. detect a synthetic PII sensitive info type) across a limited set
   of locations, scoped to `TRAIN-Pilot-Users` where the workload supports scoping.
2. **Set the policy mode to *Test* (simulation)** — choose **"Test it out first"** (test with or without
   notifications). Do **not** select *Turn it on / enforce*. In PowerShell this is
   `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` (modes: `TestWithoutNotifications`,
   `TestWithNotifications`, `Enable`, `Disable`).
3. Generate a test match with a synthetic-PII document in a training account, then review **DLP alerts /
   simulation results** — matches are detected, **nothing is blocked**.
4. Validate: `OPSTRAIN-LabValidate.ps1 -Lab DLP` confirms `TRAIN-DLP-PII-Sim` exists and its `Mode` is a
   **test/simulation** value (asserts it is **not** `Enable`).
5. **Pass/fail gate:** the policy exists in **test** mode, matched the synthetic content, and **enforced
   nothing.** The trainee can explain how they would move to enforcement and what the blast radius would
   be. **Teardown:** delete `TRAIN-DLP-PII-Sim` (never leave it enabled).
6. **If advanced DLP is unlicensed:** author a basic policy in test mode, or walk through read-only.

---

## Phase E — Data lifecycle & records lab

### Step 8 — Lab 3: Retention policy/label against an illustrative schedule
1. **Purview portal → Data Lifecycle Management → Retention policies → New**: create
   **`TRAIN-Retention-Pilot`** with an **illustrative** period (e.g. "retain 7 years then review" — a
   *training value, not a real schedule*), scoped to a limited location set / `TRAIN-Pilot-Users`.
2. **Records management → Retention labels → Create a label**: create **`TRAIN-RetLabel-Illustrative`**
   (do **not** mark it a *record* / *regulatory record* in a shared tenant — discuss what that would do).
3. Validate: `OPSTRAIN-LabValidate.ps1 -Lab Retention` confirms `TRAIN-Retention-Pilot` exists
   (`Get-RetentionCompliancePolicy`) and its rule (`Get-RetentionComplianceRule`) carries the
   illustrative period.
4. **Pass/fail gate:** the retention policy/label exists, scoped and with the **illustrative** period;
   the trainee can explain why the **real** schedule is a records/legal determination, not theirs.
5. **Teardown:** remove `TRAIN-Retention-Pilot` and `TRAIN-RetLabel-Illustrative`. *(Note: retention
   objects can take time to fully remove — record this as a real operational lesson.)*

---

## Phase F — HR/privacy-sensitive labs (policy-model walkthroughs)

> **Modules 5 and 6 use NO real employee data.** They are taught as **policy-model walkthroughs** with
> **privacy-by-design**, **pseudonymization/anonymization where the feature supports it**, and **strict
> role separation** (analyst vs investigator vs admin). All case **outcomes** are **HR/legal
> determinations** — the administrator configures the technical policy, never decides a case.

### Step 9 — Module 5: Insider Risk Management (limited scope, portal)
1. **Purview portal → Insider Risk Management**: review **Settings** — turn on/observe **anonymization
   (pseudonymized usernames)** as a privacy control, and note the **role separation** (Insider Risk
   Management Admin vs Analysts vs Investigators).
2. Walk a **policy template** (e.g. data theft / data leaks) at a **limited, illustrative** scope — do
   **not** target real employees; discuss triggering events and the HR/legal review path.
3. **Gate:** the trainee can (a) enable pseudonymization, (b) explain the separated roles, and (c) state
   that **case outcomes are HR/legal's determination**, not the administrator's. **Rollback:** leave no
   policy targeting real users; revert settings changed for the walkthrough.
4. *(Insider Risk configuration is primarily portal-driven; the provided scripts do not write IRM policy —
   they only report readable status. Do not invent IRM write cmdlets.)*

### Step 10 — Module 6: Communication Compliance (limited scope, portal)
1. **Purview portal → Communication Compliance**: review **role separation** (Analyst vs Investigator vs
   Admin) and **privacy controls** (pseudonymization of monitored users where supported).
2. Walk a **policy template** against a **training-only** scope — never real communications — and discuss
   the review workflow and escalation to HR/legal.
3. **Gate:** the trainee can configure role separation and privacy controls and articulate that
   **remediation outcomes are HR/legal's**, not the administrator's. **Rollback:** no policy over real
   users; revert walkthrough settings.

---

## Phase G — Audit, eDiscovery, DSPM

### Step 11 — Module 7 / Lab 7: Audit search & export (read-only)
1. **Purview portal → Audit** (or `Search-UnifiedAuditLog`): run **`TRAIN-Audit-Search`** for an
   illustrative activity over a short window and **export** the results as evidence.
2. Discuss **Audit Standard vs Premium** retention differences (**verify licensing**).
3. Validate: `OPSTRAIN-LabValidate.ps1 -Lab Audit` confirms an audit search returned rows for the window.
4. **Gate:** the trainee runs a search, exports evidence, and explains the Standard/Premium difference.
   **Rollback:** none (read-only).

### Step 12 — Module 8 / Lab 8: eDiscovery case + hold on a training custodian (E5 — verify)
1. **Purview portal → eDiscovery → Cases → Create**: create **`TRAIN-eDiscovery-Case`**.
2. Add a **training custodian** (a `TRAIN-Pilot-Users` test account) and place a **hold**; run a search
   in the case. **Never** a real custodian.
3. **Gate:** the case exists, the **training** custodian shows **on hold** (allow up to 24h), and a search
   returns. The trainee can explain that a **real** legal hold is a legal determination.
   **Teardown:** release the hold and close/delete `TRAIN-eDiscovery-Case`.
4. **If eDiscovery Premium is unlicensed:** perform a Standard case, or walk through read-only.

### Step 13 — Module 9: DSPM & classification analytics (read-only)
1. **Purview portal → DSPM** (Data Security Posture Management) and the **classification / content
   explorer / activity explorer** analytics: read the posture and classification picture (**verify
   licensing/preview**).
2. **Gate:** the trainee can read and interpret the posture/classification analytics and name one action
   they would recommend. **Rollback:** none (read-only).

---

## Phase H — Validate competence and operationalize

### Step 14 — Validate the full curriculum (pass/fail per lab)
1. Run `OPSTRAIN-LabValidate.ps1 -Lab All` to check every lab's expected object/state in one pass, and
   `OPSTRAIN-CompetencyReport.ps1` to roll the results (plus each trainee's created `TRAIN-` objects and
   completed gates) into a **competency/progress report**.
2. **Gate:** every attempted lab shows **PASS** at its validation, or an explicit, documented reason
   (e.g. "unlicensed — walkthrough only"). The report is the **evidence** the team is trained.

### Step 15 — Module 10: Turn the labs into operational runbooks
1. Convert each lab into a **runbook** for the recurring work (see Best Practices), e.g.:
   - **Weekly DLP alert triage** (review `TRAIN-DLP-PII-Sim`-style alerts → in production, real policy).
   - **Monthly label-coverage review** (`OPSTRAIN-LabBaseline.ps1` / `OPSTRAIN-CompetencyReport.ps1`
     re-run against production scope, read-only).
   - **Retention exception & records requests** → routed to records/legal.
   - **Audit search request handling** (`TRAIN-Audit-Search` pattern).
   - **Change-control for any new label/DLP/retention policy** — scope-first, simulate-first,
     validate-before-enforce.
2. Capture the **RACI** (who configures vs who determines) with the compliance/records/privacy/HR/legal
   stakeholders (Requirement 2.7).
3. **Gate:** the runbooks exist, are assigned owners, and route every real determination to the right
   governance function.

### Step 16 — Teardown & leave the tenant clean
1. Run `OPSTRAIN-LabValidate.ps1 -Lab All` after teardown and compare to the Step 3 baseline: **only**
   the baseline objects should remain — **no `TRAIN-` object left behind** (except any retention object
   still in its removal window, which is logged).
2. **Gate:** the tenant matches the baseline (plus documented, in-progress retention removals). Training
   is complete and the environment is clean.

---

## Rollback summary
| Lab | Teardown |
|---|---|
| 1 Labels | Delete `TRAIN-LabelPolicy-Pilot`, then `TRAIN-Label-Confidential` |
| 4 Auto-labeling | Delete `TRAIN-AutoLabel-Sim` (was only ever in simulation) |
| 2 DLP | Delete `TRAIN-DLP-PII-Sim` (never leave enabled) |
| 3 Retention | Delete `TRAIN-Retention-Pilot` / `TRAIN-RetLabel-Illustrative` (allow removal window) |
| 5 IRM / 6 Comms | Remove any walkthrough policy; revert settings; no real users targeted |
| 7 Audit / 9 DSPM | None (read-only) |
| 8 eDiscovery | Release hold; close/delete `TRAIN-eDiscovery-Case` |

Each lab's pass/fail gate and teardown are how the training stays **safe, evidenced, and reversible**.
