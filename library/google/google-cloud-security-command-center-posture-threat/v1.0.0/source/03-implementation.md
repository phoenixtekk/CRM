# Implementation

Follow these steps in order. They implement the reference design using the house model —
**Assess → Design → Configure → Pilot → Validate → Expand** — pilot-first, with pass/fail
gates and a rollback for every org-wide change. Every artifact is **named** with the
`<Purpose> – <Scope> – <Stage>` convention and reused verbatim in later steps, testing, and
scripts.

> **Verify your edition throughout.** Command surfaces, service IDs, and detector names below are
> **edition- and version-dependent**. Before running any step, confirm the exact `gcloud scc`
> subcommands, service identifiers, and detector names against Google's **current** SCC docs and
> your active edition. Where a command flag differs in your tenant, use the one your `--help`
> reports — do not assume.

Placeholders: `ORG_ID` (organization numeric ID), `SECOPS_PROJECT` (the SecOps project from
Requirements §4), `PILOT_FOLDER` (the pilot folder/project set).

---

## Stage 1 — Assess (read-only)

### 1.1 Confirm org, edition, and access
- Confirm the Organization: `gcloud organizations list` → record `ORG_ID`.
- Open **Security Command Center → Settings** and record the **active edition** and the list of
  **enabled services** (posture / vulnerability / threat). Cross-check the included detectors
  against Google's current SCC editions documentation.
- Confirm your account holds `roles/securitycenter.admin` at the org (Requirements §2):
  `gcloud organizations get-iam-policy ORG_ID`.

### 1.2 Inventory current SCC coverage
- Run the assessment tool (read-only) to snapshot enabled services, existing notification configs,
  and finding volume by severity/category:
  ```
  python scripts/scc_coverage_assessment.py --organization ORG_ID --out reports/scc-coverage.json
  ```
- **Gate A (Assess):** you have a documented edition, enabled-service list, current finding
  baseline, and confirmed admin access. If the edition lacks a service the design assumes,
  resolve (upgrade or drop that service from scope) before proceeding.

---

## Stage 2 — Design

### 2.1 Define the posture baseline
- From the assessment output, agree the enabled **posture detectors** and their intended
  mute/exception rules. Record this as **Posture Baseline – Corp – v1** (the enabled detectors +
  documented exceptions with justification and owner).

### 2.2 Design notifications & export topology
- Decide the destinations (SIEM via Pub/Sub pull/push, ticketing webhook, BigQuery) per
  Requirements §5. The plumbing:
  - **Finding Export Topic – SecOps – v1** — the Pub/Sub topic in `SECOPS_PROJECT`.
  - **Finding Notification – Org – v1** — the SCC notification config that publishes to that topic.

### 2.3 Define the triage operating model
- Produce **Triage Runbook – SecOps – v1**: the **ownership matrix** (owner by
  project/service/category) and the **severity → SLA table**, e.g.:

  | Severity | Target acknowledgement | Target remediation SLA |
  |----------|------------------------|------------------------|
  | Critical | 1 hour                 | 24 hours               |
  | High     | 4 hours                | 3 business days        |
  | Medium   | 1 business day         | 14 days                |
  | Low      | 3 business days        | 30 days (or accept)    |

  (Adjust to the organization's risk policy — this table is a starting point, not a mandate.)

- **Gate B (Design):** posture baseline, export topology, and triage runbook are documented and
  signed off by SecOps + application owners; **Pilot Scope – Prod-Ready – v1** is named.

---

## Stage 3 — Configure (dry-run first, then apply)

> All write steps are **dry-run by default** in the provided tools. Review the dry-run plan, then
> re-run with `--apply` under change control.

### 3.1 Enable required APIs
```
gcloud services enable securitycenter.googleapis.com pubsub.googleapis.com \
  --project=SECOPS_PROJECT
```
(Add `cloudfunctions.googleapis.com` / `bigquery.googleapis.com` if used.)

### 3.2 Create the export topic — Finding Export Topic – SecOps – v1
```
gcloud pubsub topics create finding-export-secops-v1 --project=SECOPS_PROJECT
gcloud pubsub subscriptions create finding-export-secops-v1-sub \
  --topic=finding-export-secops-v1 --project=SECOPS_PROJECT
```
Grant the SCC notification service account publish rights on the topic (SCC uses a per-org
service account of the form `service-org-ORG_ID@gcp-sa-scc-notification.iam.gserviceaccount.com`
— **verify the exact service-account address for your org** in the Console before binding):
```
gcloud pubsub topics add-iam-policy-binding finding-export-secops-v1 \
  --project=SECOPS_PROJECT \
  --member="serviceAccount:service-org-ORG_ID@gcp-sa-scc-notification.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"
```

### 3.3 Create the notification config — Finding Notification – Org – v1
Publish active findings to the topic. Use the config helper (dry-run first):
```
python scripts/scc_notify_export_setup.py \
  --organization ORG_ID --project SECOPS_PROJECT \
  --topic finding-export-secops-v1 \
  --config-id finding-notification-org-v1 \
  --filter 'state="ACTIVE"'                # tune the filter to your baseline
  # dry-run by default; add --apply to create
```
This wraps `gcloud scc notifications create` (verify the exact subcommand/flags for your edition).
Scope the `--filter` to the categories/severities you want streamed (e.g. exclude muted or
low-severity noise at the export edge if the SIEM prefers).

### 3.4 Apply the posture baseline — Posture Baseline – Corp – v1
- Enable/disable posture detectors to match the baseline and apply the agreed **mute rules** for
  documented exceptions. Check drift first (read-only), then apply mutes with the guardrail tool:
  ```
  python scripts/scc_posture_check.py --organization ORG_ID \
    --baseline config/posture-baseline-corp-v1.yaml --out reports/posture-drift.json
  ```
  Create mute rules for accepted exceptions (dry-run first):
  ```
  python scripts/scc_notify_export_setup.py --organization ORG_ID \
    --mute-config config/posture-mutes-corp-v1.yaml   # add --apply to create mute rules
  ```
  (Wraps SCC mute-config APIs — verify subcommands for your edition.)

- **Gate C (Configure):** notification config exists and publishes to the topic; the subscription
  receives a test finding; the posture baseline + mutes are applied; no unintended detector was
  disabled.

---

## Stage 4 — Pilot (validate on Pilot Scope – Prod-Ready – v1)

### 4.1 Generate representative findings in the pilot scope
- Confirm SCC is surfacing findings for `PILOT_FOLDER`. If needed, create a **deliberately
  misconfigured, non-sensitive test resource** in a pilot project (e.g. a firewall rule opening a
  port to `0.0.0.0/0` on a throwaway VPC) to prove the posture detector fires. **Remove it after
  the test.**

### 4.2 Confirm end-to-end flow
- Verify the finding: appears in the Console, is **published to the topic**, and is **received by
  the SIEM/subscription**. Pull a message to confirm delivery:
  ```
  gcloud pubsub subscriptions pull finding-export-secops-v1-sub \
    --project=SECOPS_PROJECT --auto-ack --limit=5
  ```

### 4.3 Run one triage cycle
- Assign the finding to its owner per **Triage Runbook – SecOps – v1**, remediate the test
  misconfiguration, and confirm SCC marks the finding `INACTIVE` on the next scan.
- Generate the SLA/triage report:
  ```
  python scripts/scc_triage_sla_report.py --organization ORG_ID \
    --runbook config/triage-runbook-secops-v1.yaml --out reports/triage-sla.html
  ```

- **Gate D (Pilot):** a pilot finding was surfaced → routed → exported → owned → remediated →
  closed within SLA, end-to-end. If any leg fails, fix and re-run the pilot; **do not expand**.

---

## Stage 5 — Validate

- Run the full validation suite in `05-testing.md` against the pilot scope. Confirm every gate
  passes: coverage as designed, notifications delivered, export ingested by the SIEM, posture
  baseline enforced, and the triage report shows findings owned with SLA tracking.

---

## Stage 6 — Expand (org-wide)

- Once all gates pass, extend scope from `PILOT_FOLDER` to the Organization: the notification
  config is already org-scoped, so expansion is primarily (a) confirming all folders/projects are
  in SCC scope, (b) applying the posture baseline org-wide, and (c) onboarding remaining owners to
  the triage runbook.
- Communicate the change, then monitor finding volume for a noise spike; tune mutes as needed.

### Rollback (documented, for any org-wide change)
- **Notifications/export:** delete or disable the notification config to stop the stream —
  `gcloud scc notifications delete finding-notification-org-v1 --organization=ORG_ID` (verify
  subcommand); findings remain in SCC, only the export stops.
- **Posture mutes:** mute rules are reversible — delete the mute config to un-mute; no finding data
  is lost.
- **Service enablement:** disabling an SCC service stops new findings from it but is a
  configuration change, not data loss — re-enable to resume. Record every change so it can be
  reverted cleanly.
- **Test resources:** ensure any deliberately misconfigured pilot test resource (§4.1) is deleted.
