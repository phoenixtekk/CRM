# 2. Requirements — Remediation Playbook for Defender Security Optimization Assessments

The category-wide prerequisites (the target tenant, assessor access, Graph/Az access, licensing, scope/baseline, output handling, remediation ownership) are documented once in **`global-requirements-assessments.md`** — read that first. This section lists only the prerequisites **specific to remediation**. Because this playbook **makes changes**, the prerequisites include change-control items the read-only assessments did not need. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. A completed assessment findings report to remediate
**Description:** A findings report from one of the Defender Security Optimization Assessments (SOAMCA / SOAMDC / SOAXDR / the endpoint/identity/office siblings), with findings prioritized by risk.
**Why required:** The playbook remediates *specific findings*; without a report there is nothing to close (and no baseline to re-score against).
**How to verify:** You hold a `Findings Report - <product> - Validate.json` (or equivalent) with ranked findings and their remediation pointers.
**How to implement if missing:** Run the relevant Security Optimization Assessment first (read-only) to produce the backlog, then return here.

## R2. Production change-approval process and a named change window
**Description:** The customer's change-management approval for the remediations, and an agreed change window for the pilot and the rollout.
**Why required:** This playbook changes production configuration; **production change-approval is the customer's decision**, not the playbook's. Disruptive/response actions are approval-gated.
**How to verify:** A change ticket / approval exists naming the findings to remediate, the pilot scope, and the window.
**How to implement if missing:** Do not apply any change until approval exists. The preview (`-WhatIf`) and ingest steps are safe to run beforehand to prepare the change record.

## R3. A named pilot scope with rollback / break-glass
**Description:** A small, named pilot scope for each remediation (e.g. a pilot user group, one subscription, a test policy) plus a documented rollback and a break-glass account preserved from any tightening.
**Why required:** Pilot-first limits blast radius; rollback/break-glass ensures a bad change can be undone and never locks everyone out.
**How to verify:** The pilot scope is defined; a break-glass account is excluded from any access/CA/session tightening; the rollback step for each remediation is written down.
**How to implement if missing:** Create a pilot group and confirm a break-glass account is excluded before applying anything disruptive.

## R4. Least-privilege read roles for ingest/verify/re-score
**Description:** **Security Reader / Reader** (read-only) for the ingest, verify, and re-score steps.
**Why required:** Most of the loop is read-only; only the apply step needs write. Keeping read and write separated proves the non-apply steps changed nothing.
**How to verify:** You can run `SOAREM-Discovery.ps1` (ingest) and `SOAREM-Rescore.ps1` with read-only roles.
**How to implement if missing:** Assign Security Reader / Reader for the read steps.

## R5. A scoped admin role for the apply step ONLY
**Description:** A **scoped admin** role sufficient for the specific remediation (e.g. Security Administrator for policy changes, the relevant product admin, or Contributor at an Azure scope for plan enablement) — granted per the customer's change process, ideally **just-in-time (PIM)**.
**Why required:** The `-WhatIf`-gated remediation step needs write access to apply a change; it should be scoped and time-bound, not standing Global Admin.
**How to verify:** The apply role is granted for the change window and removed after; `SOAREM-Remediate.ps1 -Apply` can perform the specific change.
**How to implement if missing:** Request the minimal scoped role for the window via PIM; do not use standing Global Admin. Never grant write roles to the ingest/verify/re-score steps.

## R6. Write scopes for the specific remediation (only where required)
**Description:** The Graph/Az write scopes a *specific* remediation needs (e.g. a policy-write scope) — requested only by `SOAREM-Remediate.ps1`, never by ingest/verify/re-score.
**Why required:** Applying a configuration change requires the matching write scope; keeping it isolated to the apply script preserves the read-only guarantee of the rest.
**How to verify:** `SOAREM-Remediate.ps1` in `-WhatIf` mode lists the scope it *would* need; it only requests write when you pass `-Apply`.
**How to implement if missing:** Consent the specific write scope for the apply step per the change process; keep it minimal.

## R7. A secure location for the evidence report
**Description:** A restricted place to store the change-tracked remediation evidence report (before/after scores, what changed, when, by whom).
**Why required:** The evidence report is both sensitive and auditable (Global Requirements G7).
**How to verify:** A restricted location exists for `SOAREM-*.json` outputs and the evidence report.
**How to implement if missing:** Create a restricted location and point the scripts at it.
