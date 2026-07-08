# 5. Testing & Validation — Microsoft Purview NIST 800-53 Compliance Program

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**. Tests
are read-only or use simulation/test-mode policies — no production data is altered and no user is blocked
during validation. Do not declare a family "evidenced" until its gate passes for the pilot scope, then
re-confirm on expand.

> **Remember:** these gates prove the **technical control is configured and evidenced** — they do **not**
> constitute an authorization. **Whether the evidence is sufficient and whether the system is authorized to
> operate are the assessor's / Authorizing Official's determinations — deferred.** Audit-based evidence is
> **not retroactive**.

## Gate 1 — Licensing, roles, and toolchain are in place
- **Method:** `CMPNIST-Scope.ps1` — Graph licensing read, endpoint connectivity, role-gated read checks.
- **Pass:** an E5 / E5 Compliance-bearing plan is present; `Connect-IPPSSession`, `Connect-ExchangeOnline`,
  and `Connect-MgGraph` succeed; the NIST SP 800-53 template is listable in Compliance Manager.
- **Fail:** assign the licensing (Requirement 2.1) / role group (2.2); install the modules (2.3); retest.

## Gate 2 — Compliance Manager NIST 800-53 assessment exists
- **Method:** Purview portal → `Compliance Manager → Assessments` — confirm `NIST 800-53 – Rev5 – Assessment`
  from the NIST SP 800-53 Rev. 5 template, with improvement actions and an initial score.
- **Pass:** the assessment exists, scoped to the in-scope boundary, with improvement actions visible.
- **Fail:** create it (Implementation Step 2); confirm the premium template is licensed/available.

## Gate 3 — Unified audit logging on (AU family foundation)
- **Method:** `CMPNIST-Discovery.ps1`, or `Get-AdminAuditLogConfig | FL UnifiedAuditLogIngestionEnabled`.
- **Pass:** `UnifiedAuditLogIngestionEnabled = True` (org mailbox auditing on).
- **Fail:** enable via `CMPNIST-Set-ControlPolicy.ps1 -EnableUnifiedAudit -Commit` (Step 4); allow activation
  time; note it is not retroactive; retest.

## Gate 4 — Audit-evidence retention policy exists and is correct
- **Method:** `CMPNIST-Discovery.ps1` retention section (`Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** `Control Evidence – NIST AU – Audit Retention` exists with the agreed duration and a unique
  priority.
- **Fail:** create/correct with `CMPNIST-Set-ControlPolicy.ps1` (Step 4); verify the `RetentionDuration` value
  and licensing.

## Gate 5 — Control-support DLP policy exists in SIMULATION mode
- **Method:** `CMPNIST-Discovery.ps1` DLP section (`Get-DlpCompliancePolicy` → `Mode`).
- **Pass:** `Control Evidence – NIST SC-MP – DLP (Simulation)` exists with `Mode = TestWithoutNotifications`,
  scoped to `NIST Pilot – Control Set – Stage1` — detecting, **not blocking**.
- **Fail:** create it in simulation (Step 5, `-Commit`); confirm the workloads and pilot scope; retest.

## Gate 6 — DLP simulation is detecting the expected (benign) matches
- **Method:** in the Purview portal, open the DLP policy's **simulation/overview** and generate benign test
  content matching the rule (e.g. a document with the in-scope information type) in the pilot scope; confirm
  the policy records matches without user impact.
- **Pass:** simulation shows matches for the test content; no user was blocked.
- **Fail:** confirm the rule's information-type/label conditions (Requirement 2.4) and pilot scope; allow for
  policy-propagation latency before concluding.

## Gate 7 — AC/SC label & encryption evidence is present
- **Method:** `CMPNIST-Discovery.ps1` label section (`Get-Label`, `Get-LabelPolicy`).
- **Pass:** at least one sensitivity label with encryption/usage rights is published to the pilot (evidencing
  AC-3/SC-28), or the gap is recorded in the map and assigned.
- **Fail:** publish/reference the label from the labeling workstream, or record the gap explicitly; retest.

## Gate 8 — Per-family evidence validation is green
- **Method:** `CMPNIST-Validate.ps1` against `NIST 800-53 – Control-to-Purview – Map`.
- **Pass:** every **Purview-covered** family reports its evidence present (audit + retention, DLP present +
  mode, labels published, retention configured, assessment referenced); every **deferred** family is marked
  deferred.
- **Fail:** address the named missing item for the red family and re-run.

## Gate 9 — Control-evidence report generates and artifacts attach
- **Method:** `CMPNIST-Report.ps1` → `NIST 800-53 – Control Evidence – Report`; then attach artifacts to the
  Compliance Manager improvement actions.
- **Pass:** the report generates with a row per in-scope family and status; each Purview-covered control has
  an attached artifact per your evidence requirement (2.8).
- **Fail:** regenerate; attach the missing artifact; confirm evidence-handling requirements.

## Gate 10 — (On expand) enforcement is live and drift-monitored
- **Method:** after the pilot passes, `CMPNIST-Set-ControlPolicy.ps1 -DlpPolicyName "…" -SetMode Enable -Commit`;
  confirm `Mode = Enable`; confirm the scheduled Discovery→Validate→Report chain runs.
- **Pass:** the DLP control enforces for the agreed scope; the monitoring cadence catches drift.
- **Fail:** re-check the mode change and scope; schedule the read-only chain.

## Evidence to retain
- `CMPNIST-Scope.ps1`, `CMPNIST-Discovery.ps1`, and `CMPNIST-Validate.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every audit-retention and DLP change (simulation → enforce).
- The DLP **simulation** results demonstrating detection without blocking.
- `NIST 800-53 – Control Evidence – Report` and the artifacts attached to each improvement action.
- The pilot scope and change approvals (Requirements 2.7/2.8).

> Evidence **sufficiency**, control **applicability**, and the **authorization determination (ATO)** are
> **compliance/security/AO decisions** — these gates prove the technical configuration works and is
> evidenced, not that the control set is complete or the system is authorized.
