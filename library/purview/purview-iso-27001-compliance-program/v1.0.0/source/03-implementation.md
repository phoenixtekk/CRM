# 3. Implementation Guide — Microsoft Purview ISO 27001 Compliance Program

This is the exact, ordered procedure to stand up an ISO 27001-aligned Purview program: map the in-scope
Annex A controls to Purview capabilities, stand up the Compliance Manager assessment spine, configure the
supporting technical controls **in simulation/test first**, validate the evidence, then enforce and
expand. Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent
features and evolving portal paths are flagged "verify your licensing/tenant"** and are never asserted
for your tenant. Do the phases in order. Each phase names its artifacts (from the Overview naming table),
states a **pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch and never leave a policy in enforce. No credentials are stored in
> code. **Compliance Manager itself has no broad public API** — assessments, improvement actions, and
> evidence upload are done in the **portal**; the scripts assess readiness, roles, and technical evidence.

> **Determinations deferred.** The **SoA** (which Annex A controls apply), the **risk treatment**, the
> **retention schedule / records file plan**, the **management-system clauses (4–10)**, and the
> **certification** itself are ISMS / risk / records / legal / certification-body decisions. This guide
> configures and proves the technical controls and produces the evidence; capture those determinations
> from the responsible functions before each phase that depends on them.

---

## Phase 0 — Connect and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   Connect-MgGraph -Scopes 'Organization.Read.All','Policy.Read.All','InformationProtectionPolicy.Read' -NoWelcome
   ```
2. **Run the posture assessment** (delivered script #1, read-only):
   ```powershell
   .\ISO27001-Discovery.ps1 -CsvPath .\ISO27001-Posture.csv
   ```
   It reports whether **unified audit logging** is on, existing **DLP / label / retention** objects and
   their **mode** (simulation/test vs enforce vs disabled), and **licensing** signals that gate the ISO
   template and advanced controls.
3. **Confirm licensing** (Req 2.1) — E5 / E5 Compliance (or the premium-assessment add-on) so the
   **ISO/IEC 27001** template is available in Compliance Manager and advanced DLP/labeling/Audit Premium
   function. **Verify in the admin center and in Compliance Manager → Assessment templates.**
4. **Capture the Compliance Manager baseline.** In **Purview → Compliance Manager**, record the current
   **Compliance Score** on the included **Data Protection Baseline** as the starting posture.

**Pass/fail gate:** you have a written baseline (audit state, existing controls + modes, licensing
confirmed, ISO template visible, current score).
**Rollback:** none (read-only).

---

## Phase 1 — Map the in-scope Annex A controls to Purview (Design)

Do **not** decide applicability — take it from the **SoA** (Req 2.2). Map only the **in-scope,
applicable** Annex A controls that Purview can satisfy or evidence.

5. **Build the control map** `ISO27001 Control Map – AnnexA-to-Purview`. For each in-scope Annex A control
   from the SoA, record: the **control ID/title**, the **Purview capability** that satisfies/evidences it,
   whether the evidence is **full or partial**, the **owner**, and the **evidence type**. Use the
   Overview mapping table as the starting point (A.5.12/5.13 → labels; A.8.12 → DLP; A.8.10/5.33 →
   retention; A.8.15/8.16 → audit; A.8.24/5.14 → encryption). **Flag controls Purview does not cover**
   (organizational/people/physical) as out of scope for this program.
6. **Confirm the classification intent, DLP channels, and records requirements** (Req 2.6) that the
   technical controls will implement — the label scheme, the DLP-covered locations, and the
   retention/disposition settings. *The retention **schedule** and records **file plan** are
   records/legal determinations — you configure what they specify.*

**Pass/fail gate:** every in-scope, applicable Annex A control maps to a named Purview capability (or is
explicitly marked out-of-Purview), with an owner and evidence type; the map is signed off by the ISMS
function.
**Rollback:** none (design artifact).

---

## Phase 2 — Stand up the Compliance Manager assessment spine (Configure — guardrails)

7. **Assign Compliance Manager roles with separation** (Req 2.3). In **Purview → Settings → Roles &
   scopes**, populate **Compliance Manager Administrators / Assessors / Contributors / Readers**
   least-privilege; snapshot the membership as `ISO27001 Roles – Separation Evidence`. **Verify the exact
   role-group names in your tenant.**
8. **Create the ISO assessment.** In **Compliance Manager → Assessments → Add assessment**, select the
   **ISO/IEC 27001** premium template (verify it is available — Req 2.1) and create
   `ISO27001 Assessment – Baseline – Pilot` (start with one assessment to pilot the workflow), then, once
   proven, `ISO27001 Assessment – Annex A – Production`.
9. **Build the improvement-action / evidence plan** `ISO27001 Action Plan – Evidence`. For each
   improvement action tied to an in-scope control, assign an **owner**, a **target date**, an
   **implementation status**, and a **test status**, and note the **evidence** it will carry. Where a
   Compliance Manager action maps to a technical control you will configure in Phases 3–4, link them.
10. **Enable automatic testing where available.** Compliance Manager can auto-test **eligible** actions
    from Microsoft 365 signals — enable it so technical actions self-update. Availability is
    plan/action-dependent — **verify**.

**Pass/fail gate:** the ISO assessment exists, roles are separated and snapshotted, and every in-scope
control has an owned, dated improvement action with a defined evidence type.
**Rollback:** remove the pilot assessment / action-plan entries (no tenant configuration changed by
Compliance Manager).

---

## Phase 3 — Configure the supporting technical controls in SIMULATION/TEST (Configure — no user impact)

Build each high-impact control in **simulation/test/disabled** mode first. These provide the evidence for
the mapped Annex A controls.

11. **Sensitivity-label scheme (A.5.12 Classification, A.5.13 Labelling) — `ISO27001 Label –
    Classification – Pilot`.**
    Portal: **Information Protection → Labels** — create the label taxonomy the classification scheme
    requires (e.g. *Public / Internal / Confidential / Highly Confidential*), with protection
    (encryption/marking) where A.8.24 requires. Publish via a **label policy** scoped to the **pilot
    ring** only, **without** making labeling mandatory initially. Verify auto-labeling availability
    against your plan.
12. **DLP policy for data leakage (A.8.12) — `ISO27001 DLP – Data Leakage – Simulation`.**
    Portal: **Data loss prevention → Policies → Create policy** → locations (Exchange, SharePoint,
    OneDrive, Teams, and **Devices** if endpoint DLP is licensed/onboarded) → conditions on the relevant
    SITs/labels → **Policy mode: Run the policy in simulation mode**. Do **not** enforce yet.
13. **Retention & disposition (A.8.10 Information deletion, A.5.33 Protection of records) — `ISO27001
    Retention – Records – Simulation`.**
    Portal: **Data lifecycle management** (retention policies) and **Records management** (retention
    labels / disposition) — configure the retention/deletion the records requirements specify, applied to
    a **pilot scope** first, with **disposition review** where records must be reviewed before deletion.
    *The retention schedule/file plan is a records/legal determination — configure what it specifies.*
14. **Confirm cryptography and information-transfer evidence (A.8.24, A.5.14).** Confirm
    **encryption/message encryption** state (e.g. label-applied encryption, Purview Message Encryption for
    email) — this is largely a configuration/evidence confirmation, not a high-impact toggle.
15. **Confirm logging/monitoring evidence (A.8.15/8.16).** Confirm **unified audit** (Req 2.5) is on and
    capturing label/DLP/retention activity — the `ISO27001 Audit – Logging – Evidence` source.
16. **Verify the configuration** with the config helper (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\ISO27001-Config.ps1 -Control DLP -PolicyName 'ISO27001 DLP – Data Leakage – Simulation' -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script never leaves a policy in enforce.

**Pass/fail gate:** labels published to the pilot ring, DLP in **simulation**, retention applied to the
pilot scope, and audit/encryption evidence confirmed — script #1/#2 report each policy in a
simulation/test/disabled mode, correctly scoped.
**Rollback:** unpublish the label policy, delete the simulation DLP policy, and remove the pilot retention
policy — simulation/test scopes have no broad user impact, so removal is clean.

---

## Phase 4 — Validate the evidence and enforce in a pilot ring (Pilot → Validate)

17. **Collect the technical evidence** (delivered script #3, read-only) into the evidence register:
    ```powershell
    .\ISO27001-ControlEvidence.ps1 -ControlMap .\ISO27001-ControlMap.csv -CsvPath .\ISO27001-Evidence.csv
    ```
    It confirms, per mapped control, the technical state (audit enabled; DLP policies + mode; labels +
    label policy; retention policies; and, via Graph, licensing/Conditional-Access signals) and produces
    `ISO27001 Evidence – Register`.
18. **Validate against the pass/fail gates** (see Testing) — each mapped control's technical state matches
    what the assessment claims; attach the evidence to the Compliance Manager improvement action and set
    **test status/date**.
19. **Enforce the piloted controls for the ring.** Move `ISO27001 DLP – Data Leakage – Simulation` to
    **enforce (policy tips + allow-override)** for `ISO27001 Pilot Ring – Stage1`; make the label policy
    **mandatory** for the ring where the scheme requires it; confirm the pilot retention/disposition
    behaves as specified. Confirm enforcement is **ring-only** (script #1 reports mode + scope).
20. **Scope helper** (delivered script #5, `-WhatIf` by default) to confirm/adjust the pilot ring:
    ```powershell
    .\ISO27001-Set-Scope.ps1 -PolicyName 'ISO27001 DLP – Data Leakage – Simulation' -RingGroup 'ISO27001 Pilot Ring – Stage1' -WhatIf
    ```

**Pass/fail gate:** every in-scope control has collected evidence in the register with owner/date/test
status; the piloted controls are enforced **for the ring only** and behave as designed; nothing enforced
outside the ring.
**Rollback:** set any enforced policy back to **simulation/test** (single setting) and revert the label
policy to non-mandatory — immediate, non-destructive.

---

## Phase 5 — Expand, report, and operate (Expand → Continual improvement)

21. **Expand enforcement** from the ring to the full intended population once the pilot gate passes,
    keeping documented exclusions; add the remaining in-scope Annex A controls and their assessments
    (`ISO27001 Assessment – Annex A – Production`).
22. **Report control coverage and score posture** (delivered script #4, read-only):
    ```powershell
    .\ISO27001-Report.ps1 -ControlMap .\ISO27001-ControlMap.csv -CsvPath .\ISO27001-Coverage.csv
    ```
    It rolls up mapped-control coverage, evidence gaps (controls with no collected evidence), and the
    logging/monitoring evidence pull — the audit-ready coverage view.
23. **Operationalize the continual-improvement cadence (ISO Clause 10).** Schedule re-testing and
    re-evidencing of controls, review improvement-action owners and overdue actions, refresh the evidence
    register, and watch for **assessment-template / standard updates** (e.g. ISO revisions). Re-tune DLP
    false positives and label/retention scope as data and behavior drift.
24. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence for the program record.

**Pass/fail gate:** enforcement live across the intended scope; every in-scope control mapped, configured,
evidenced (owner/date/test status), and rolled up in the coverage report; the maintenance cadence is
running.
**Rollback:** any policy can be returned to **simulation/test** at any time as an immediate,
non-destructive safety switch; individual controls can be disabled without affecting others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/audit, capture score | Posture CSV | Baseline + ISO template confirmed | n/a (read-only) |
| 1 Design | Map in-scope Annex A (from SoA) → Purview | Control map | Every applicable control mapped/owned | n/a (design) |
| 2 Configure spine | Roles (separation), ISO assessment, action/evidence plan | Assessment, action plan, roles snapshot | Assessment + owned actions exist | Remove pilot assessment |
| 3 Configure controls | Labels/DLP/retention in **simulation/test**; confirm audit/crypto | Label/DLP/retention pilot objects | All in sim/test, correct scope | Unpublish/delete pilot objects |
| 4 Validate/Pilot | Collect evidence, enforce to ring | Evidence register, pilot ring | Evidence complete; ring-only enforce | Back to simulation/test |
| 5 Expand/Operate | Broaden scope, report coverage, run cadence | Coverage report, production assessment | Full-scope enforce, coverage evidenced | Simulation/test / disable |
