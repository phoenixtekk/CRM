# Testing & Validation

Run these procedures against **Pilot Scope – Prod-Ready – v1** first (Stage 4/5), then re-confirm
after org-wide expansion. Each test states the procedure and an explicit **pass/fail** signal.
These map to the gates in `03-implementation.md`.

> **Verify your edition.** Service and detector names below are edition-dependent; confirm the
> exact identifiers in your tenant before asserting a test's expected result.

---

## Test 1 — SCC edition and services are as designed
- **Procedure:** In **Security Command Center → Settings**, confirm the active edition and that the
  posture / vulnerability / threat services in **Posture Baseline – Corp – v1** are enabled. Cross-run:
  `python scripts/scc_coverage_assessment.py --organization ORG_ID --out reports/scc-coverage.json`.
- **Pass:** every service the design assumes is enabled and included in the edition.
- **Fail:** a designed service is missing or not in the edition → resolve (upgrade or de-scope)
  before continuing.

## Test 2 — Notification config publishes findings
- **Procedure:** Confirm **Finding Notification – Org – v1** exists and targets
  **Finding Export Topic – SecOps – v1**:
  `gcloud scc notifications describe finding-notification-org-v1 --organization=ORG_ID`
  (verify subcommand). Create/allow a test finding in the pilot scope (see Test 4), then pull:
  `gcloud pubsub subscriptions pull finding-export-secops-v1-sub --project=SECOPS_PROJECT --auto-ack --limit=5`.
- **Pass:** the finding is delivered as a Pub/Sub message with the expected finding JSON.
- **Fail:** no message → check the config filter, the topic IAM binding for the SCC notification
  service account, and that the finding matches the config's `--filter`.

## Test 3 — SIEM / downstream ingestion works
- **Procedure:** Confirm the SIEM (or downstream consumer) received and parsed the same finding via
  its subscription/connector. Check the SIEM's search UI or the consumer's logs.
- **Pass:** the finding appears in the SIEM with fields mapped per the ingestion contract
  (Requirements §5).
- **Fail:** message published to Pub/Sub but absent in SIEM → check the subscription/connector,
  consumer service-account permissions, and field mapping.

## Test 4 — Posture detector fires on a real misconfiguration
- **Procedure:** In a **throwaway pilot project**, create a deliberately misconfigured,
  **non-sensitive** resource (e.g. a firewall rule opening a port to `0.0.0.0/0` on a test VPC).
  Wait for the next posture scan.
- **Pass:** SCC raises the corresponding posture finding (correct category + severity) within the
  scan window. **Delete the test resource afterward.**
- **Fail:** no finding after the scan window → confirm the posture service is enabled for that
  project and not muted by **Posture Baseline – Corp – v1**.

## Test 5 — Mute rules behave as designed
- **Procedure:** For one documented exception in the baseline, confirm its mute rule suppresses the
  matching finding (finding shows as muted, not surfaced to the export filter if the filter excludes
  muted). Run:
  `python scripts/scc_posture_check.py --organization ORG_ID --baseline config/posture-baseline-corp-v1.yaml --out reports/posture-drift.json`.
- **Pass:** intended exceptions are muted; nothing outside the exception list is muted (no drift).
- **Fail:** an un-approved finding is muted, or an approved exception is not → correct the mute config.

## Test 6 — Finding remediation closes the finding
- **Procedure:** Remediate the misconfiguration from Test 4 (delete the offending firewall rule).
  Wait for the next scan.
- **Pass:** SCC transitions the finding to `INACTIVE` (remediated) on rescan.
- **Fail:** finding stays `ACTIVE` after rescan → confirm the resource was actually fixed and the
  scan completed.

## Test 7 — Triage & SLA report reflects reality
- **Procedure:** Run
  `python scripts/scc_triage_sla_report.py --organization ORG_ID --runbook config/triage-runbook-secops-v1.yaml --out reports/triage-sla.html`
  and review.
- **Pass:** the report lists active findings with correct severity, computed SLA due dates,
  owner (per the runbook matrix), and an at-risk/breached flag; the closed test finding is excluded
  from the active queue.
- **Fail:** wrong owner mapping, missing findings, or incorrect SLA math → fix the runbook mapping
  or the tool inputs and re-run.

## Test 8 — Least-privilege access holds
- **Procedure:** Confirm SCC roles are bound to the intended groups (not blanket Owner) and that a
  triager can edit finding state but cannot change org policy:
  `gcloud organizations get-iam-policy ORG_ID`.
- **Pass:** admins hold `securitycenter.admin`, triagers hold finding-editor/viewer roles, no
  unnecessary broad grants.
- **Fail:** over-broad grants present → remediate with the Organization Administrator.

## Test 9 — Rollback works
- **Procedure:** In a controlled test, disable **Finding Notification – Org – v1** and confirm the
  export stream stops without losing findings in SCC; re-enable and confirm the stream resumes.
- **Pass:** export stops/starts cleanly on config change; finding data in SCC is unaffected.
- **Fail:** findings lost or stream cannot be restored → investigate before relying on the rollback.

---

**Overall exit criteria (all must pass to Expand):** Tests 1–4 and 6–7 pass on the pilot scope
(coverage as designed, notifications delivered, SIEM ingesting, detector fires, remediation
closes, triage/SLA report correct), Test 8 confirms least privilege, and Test 9 confirms a clean
rollback.
