# 3. Implementation Guide — Microsoft Purview PCI-DSS Compliance Program

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and, where automated, via **Security & Compliance PowerShell**
(`Connect-IPPSSession`) and **Microsoft Graph**. Artifact names follow the Overview's naming and are
reused verbatim. **Portal paths, template/SIT availability, and cmdlets are plan-dependent and the
portal evolves — verify against your tenant. The cardholder-data DLP policy is deployed in
SIMULATION/TEST mode first and enforced only after validation.**

> **Model:** Assess readiness, design the control map + CDE scope + owners, configure least-privilege
> roles + the PCI-DSS assessment + the cardholder-data DLP (in simulation) + the label, validate the
> evidence, report, then move DLP to enforce and expand.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.**
> **Compliance Manager measures; DLP/labels enforce.** CDE scoping, SAQ applicability, and attestation
> adequacy are **QSA/compliance/legal determinations**, not decisions this guide makes.

---

## Step 1 — Baseline the score and assess readiness (Assess)
1. Confirm licensing (Requirement 2.1): portal → **Compliance Manager → Assessment templates**, the
   **PCI-DSS** template shows as available to create. **Verify entitlement with Microsoft licensing —
   do not assume.**
2. Run `CMPPCI-Discovery.ps1` (read-only). It reports: the licensing SKUs it can read; the membership
   of each Compliance role group (the `PCI Roles – Separation Evidence` snapshot) and any admin who is
   also a contributor; whether **unified audit logging** is enabled (Req 10); whether the **Credit Card
   Number** SIT is present (Req 3); and any existing Credit Card Number **DLP policy/label** and its
   mode. Note the current **Compliance Score** from the portal dashboard as your starting point.
3. **Pass/fail gate:** licensing confirmed for the PCI-DSS template, the role groups exist, audit
   logging state and the Credit Card Number SIT are known, and the baseline score is recorded. **Do not
   proceed** until the QSA/compliance owners (Requirement 2.2) have confirmed the PCI-DSS version, SAQ,
   and CDE scope. Fail → resolve before configuring.

## Step 2 — Design the control map, CDE scope, and owners (Design)
1. With the QSA/compliance owners, confirm the **PCI-DSS version/SAQ**, the **CDE boundary**, and the
   **in-scope requirements** (Requirement 2.2). CDE scoping and applicability are their determination.
2. Build the **Purview-to-requirement control map** (`PCI Control Map – Record`): Req 3 → cardholder
   DLP + label + classification; Req 7 → least-privilege roles; Req 10 → unified audit logging; Req 12
   → Compliance Manager evidence store; the remaining requirements (firewalls, segmentation, physical,
   anti-malware, testing) → **evidence links** to their owning systems.
3. Assign a **business owner** per requirement/action and record the scope as `PCI Scope – Record`
   (version, SAQ, CDE boundary, in-/out-of-scope requirements, owners).

## Step 3 — Assign roles with least-privilege separation (Configure — guardrails, Req 7)
1. Portal → `Settings → Roles & scopes → Permissions`: populate the role groups (Requirement 2.3):
   - **Compliance Manager Administrators / Compliance Administrator** → program owners / IT config
     (also configure DLP/labels/audit).
   - **Compliance Manager Assessors** → assessment leads who create assessments and set **test** status.
   - **Compliance Manager Contributors** → improvement-action **owners** who update actions/evidence.
   - **Compliance Manager Readers** → QSA / oversight / auditors, **read-only**.
2. Or manage membership with `CMPPCI-Set-Scope.ps1` — it composes `Add-RoleGroupMember` /
   `Remove-RoleGroupMember`, **runs with `-WhatIf` by default**, and prints exactly what it would
   change; add `-Commit` to apply. Grant the **minimum** role each person needs.
3. **Pass/fail gate:** each person holds the least-privilege role; administrators are separated from
   contributors; readers/auditors/QSA are read-only. Re-run `CMPPCI-Discovery.ps1` and confirm the
   `PCI Roles – Separation Evidence` snapshot. **Rollback:** remove any over-granted membership with
   `CMPPCI-Set-Scope.ps1 -Commit`.

## Step 4 — Enable and retain unified audit logging (Configure — Req 10)
1. Confirm **unified audit logging** is on: `Get-AdminAuditLogConfig | Select
   UnifiedAuditLogIngestionEnabled` → `True`. If not, enable it:
   `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true` (allow time to take effect).
2. Configure an **audit-retention policy** that meets your PCI-DSS version's Requirement 10 retention
   (Audit (Premium) enables longer/custom retention; verify entitlement — Requirement 2.1/2.4).
3. **Pass/fail gate:** audit ingestion is `True` and a retention policy meeting the requirement exists.
   `CMPPCI-Validation.ps1` confirms the state. Fail → enable logging / add the retention policy before
   claiming Req 10 evidence. **Rollback:** audit configuration changes are reversible in the portal /
   via `Set-AdminAuditLogConfig`, but keep logging **on** — disabling it fails Req 10.

## Step 5 — Create the PCI-DSS assessment and action plan (Configure — pilot-first)
1. Portal → **Compliance Manager → Assessments → Add assessment**: create
   `PCI Assessment – Baseline – Pilot` from the **PCI-DSS** template, in the agreed group. (The premium
   template requires the entitlement from Requirement 2.1.)
2. Build the **improvement-action plan** (`PCI Action Plan – Pilot`): assign each action an **owner**,
   **target date**, and **implementation status** in the portal; for out-of-scope-for-Purview
   requirements, record the **evidence link** to the owning system.
3. Use `CMPPCI-Configuration.ps1` (`-WhatIf` default; `-Commit` writes local tracking artifacts) to
   validate the plan and write `PCI Action Plan – Pilot` / `PCI Evidence – Register` from the
   owner-provided list. Compliance Manager has no broad write API, so **assignments and evidence upload
   happen in the portal**, driven by these artifacts.
4. **Pass/fail gate:** the pilot assessment exists with an owner and a visible score, and every action
   has an owner, target date, status, and evidence source/link. Fail → complete the plan before
   configuring the data controls. **Rollback:** an assessment can be removed in the portal without
   affecting tenant configuration.

## Step 6 — Configure the cardholder-data DLP in SIMULATION and publish the label (Configure — Req 3)
1. **Create the DLP policy in simulation/test mode** — this is high-impact, so it starts non-enforcing.
   Use `CMPPCI-Configuration.ps1` (`-WhatIf` default): with `-Commit` it creates `DLP-PCI-CardholderData`
   via `New-DlpCompliancePolicy -Mode TestWithNotifications` (simulation) across the in-scope workloads
   and the rule `DLP-PCI-CardholderData-Rule` via `New-DlpComplianceRule` matching the **Credit Card
   Number** SIT (Requirement 2.5/2.6). **Simulation mode audits/notifies but does not block.**
2. **Publish the sensitivity label** `Label-PCI-CardholderData` for cardholder data (portal →
   **Information Protection → Labels**) and a label policy scoped to `SG-PCI-Pilot`; where entitled,
   plan **auto-labeling** on the Credit Card Number SIT (its own pilot). Label authoring is
   portal-managed; the script reports label presence.
3. **Pass/fail gate:** `DLP-PCI-CardholderData` exists in **simulation mode** with the Credit Card
   Number rule, and `Label-PCI-CardholderData` is published to the pilot scope. Confirm with
   `CMPPCI-Validation.ps1`. Fail → correct the policy/rule/label before validating. **Rollback:** the
   DLP policy is non-enforcing in simulation; it can be disabled/removed with `Set-DlpCompliancePolicy`
   / `Remove-DlpCompliancePolicy` with no user impact.

## Step 7 — Validate the evidence behind the controls (Pilot → Validate)
1. Run the Testing Guide (`05-testing.md`). Confirm: the pilot assessment shows a score; each action's
   implementation and test status is set with **evidence**; audit logging is on and retained (Req 10);
   the **DLP simulation is matching** test PAN in the pilot scope (Req 3) without blocking; the label is
   published; role separation holds (Req 7). `CMPPCI-Validation.ps1` (read-only) is the cross-check.
2. **Review the DLP simulation results** in the portal (policy → **Simulation/Overview**): confirm it
   catches genuine cardholder data and tune out false positives **before** enforcing. Do **not** mark
   Req 3 implemented on simulation alone — note it as *piloted, pending enforcement*.
3. Run `CMPPCI-Report.ps1` for the `PCI Posture – Report` (score inputs, control-to-evidence map, audit
   state, DLP mode + simulation summary, role separation, licensing).
4. **Pass/fail gate:** the pilot assessment is owned, evidenced, and tested; audit logging validated;
   DLP simulation validated and tuned; label published; posture report accurate. Fail → complete
   evidence/testing and re-validate.

## Step 8 — Move DLP to enforce and expand to the full requirement set (Expand)
1. **Only after Step 7 passes**, move `DLP-PCI-CardholderData` from simulation to **enforce** under
   change control: `CMPPCI-Set-Scope.ps1` (or `Set-DlpCompliancePolicy -Mode Enable`) with `-WhatIf`
   first, then `-Commit`, and expand the policy scope beyond `SG-PCI-Pilot` as agreed. Watch the first
   enforcement window for legitimate-workflow impact.
2. With the QSA/compliance owners, create `PCI Assessment – Production` (or extend the pilot to the full
   requirement set) and complete the action plan/evidence for every in-scope requirement, leaning on
   **control mapping** so shared controls (audit, access) score across frameworks — the incremental
   effort is the *gap*.
3. Stand up the **maintenance cadence**: periodic re-test/re-evidence, review of role membership
   (joiners/leavers), watch for **PCI-DSS version updates** and Microsoft **template updates**, re-run
   `CMPPCI-Validation.ps1` and `CMPPCI-Report.ps1` on a schedule for the posture trend.
4. **Pass/fail gate:** the DLP is enforcing without disrupting legitimate payment operations, the full
   in-scope set is owned and evidenced, audit logging is retained, and a recurring review is scheduled.
   **Rollback:** revert the DLP to simulation with `Set-DlpCompliancePolicy -Mode TestWithNotifications`
   if enforcement causes unacceptable impact; any assessment can be removed in the portal.

---

### What this guide does NOT decide
- **How the CDE is scoped, which SAQ/version applies, and whether the evidence satisfies PCI-DSS** — a
  **QSA / compliance / legal determination**. This guide configures the controls, the assessment, the
  action plan, and the evidence, and produces the score and posture; scope and attestation belong to
  those functions.
- **The requirements Purview cannot implement** — firewalls, network segmentation, physical security,
  anti-malware, and vulnerability/penetration testing are **separate systems**; here they are tracked as
  **evidence links** in Compliance Manager, not configured.
