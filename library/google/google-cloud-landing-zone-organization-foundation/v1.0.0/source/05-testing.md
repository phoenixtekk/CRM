# Testing & Validation

Each test states its procedure and the **expected pass/fail signal**. Run the pilot tests (§T1–T6) on
`Landing Zone – Pilot` before org-wide apply; re-run the full set during Stage 5 — Validate and after
each Expand wave. The `gcp_landing_zone_validate.py` tool automates most of these into a single
report — the manual procedures below let you confirm any individual gate.

---

## T1 — Hierarchy is present and correctly nested (Gate C1)

- **Procedure:**
  ```bash
  gcloud resource-manager folders list --organization="$ORG_ID"
  gcloud projects list --filter="parent.id=<FOLDER_ID>" --format="table(projectId,parent.id)"
  gcloud billing projects describe logging-common-prod
  ```
- **Pass:** the four folders (Common, Production, Non-Production, Bootstrap) exist; each foundation
  project sits under its intended folder; each is linked to `$BILLING_ACCOUNT` (billingEnabled =
  true).
- **Fail:** a folder or project is missing, mis-parented, or not billing-linked → re-run
  `gcp_hierarchy_provisioner.py` (dry-run to see the diff, then `--apply`).

## T2 — Org-policy guardrails are enforced (Gate C2)

- **Procedure (on the pilot):** attempt an action a guardrail should deny.
  ```bash
  # Should be DENIED if compute.vmExternalIpAccess is enforced
  gcloud compute instances create test-ext-ip --zone=us-east1-b \
    --project=<pilot-service-project> --address=  # request an external IP
  # Confirm the constraint is set at the scope
  gcloud org-policies describe compute.vmExternalIpAccess --folder=<PILOT_FOLDER_ID>
  ```
- **Pass:** the disallowed action is rejected with a policy-violation error, and
  `gcloud org-policies describe` shows the constraint enforced at the pilot scope.
- **Fail:** the action succeeds → the constraint is not applied/inherited; re-run
  `gcp_org_policy_guardrails.py --scope folders/<PILOT_FOLDER_ID> --apply` and re-test before any
  org-wide promotion. **Verify each constraint name/behavior in your organization** — some are list
  constraints needing explicit deny values.

## T3 — IAM baseline is group-based, no user bindings at foundation scope (Gate C3)

- **Procedure:**
  ```bash
  gcloud organizations get-iam-policy "$ORG_ID" \
    --flatten="bindings[].members" \
    --format="value(bindings.members)" | grep -i '^user:' || echo "no user bindings"
  ```
  (Repeat for the Common folder and each foundation project.)
- **Pass:** no `user:` members at the Organization / Common-folder / foundation-project scope — only
  `group:` (and required `serviceAccount:`) members. `gcp-organization-admins` holds
  `roles/resourcemanager.organizationAdmin`.
- **Fail:** any `user:` binding appears → replace it with the appropriate group membership. The
  break-glass super-admin is expected to exist but must be out-of-band, MFA-protected, and alarmed —
  not used for routine bindings.

## T4 — Centralized audit logging is flowing (Gate C4)

- **Procedure:**
  ```bash
  gcloud logging sinks describe org-audit-sink-common-prod --organization="$ORG_ID"
  # generate an auditable event, then read it back from the destination bucket
  gcloud logging read 'logName:"cloudaudit.googleapis.com"' \
    --project=logging-common-prod --limit=5 --freshness=1h
  ```
- **Pass:** the sink exists with `includeChildren=true`, its writer identity has write access to the
  destination, and recent audit entries are readable in `Project: Logging – Common – Prod`.
- **Fail:** no entries → check the sink writer identity has `roles/logging.bucketWriter`/dataset
  write on the destination, and that the log filter matches. Data Access logs must be explicitly
  enabled per service — **verify in your organization**.

## T5 — Shared VPC is attachable and usable (Gate C6)

- **Procedure:**
  ```bash
  gcloud compute shared-vpc get-host-project <pilot-service-project>
  gcloud compute networks subnets list --project=networking-host-shared-vpc-prod
  # from the service project, create a resource on the shared subnet
  gcloud compute instances create lz-smoke-vm --zone=us-east1-b \
    --project=<pilot-service-project> \
    --network-interface=subnet=projects/networking-host-shared-vpc-prod/regions/us-east1/subnetworks/lz-subnet-prod-use1,no-address
  ```
- **Pass:** the service project reports the correct host; the instance is created on the shared subnet
  **with no external IP** (consistent with the guardrail).
- **Fail:** attachment or subnet-use fails → confirm the service project is associated and the
  workload group has `roles/compute.networkUser` on the subnet.

## T6 — Billing export is populated (Gate C5)

- **Procedure:** in BigQuery (`Project: Billing-Export – Common – Prod`), query the export dataset:
  ```sql
  SELECT COUNT(*) AS rows, MAX(usage_end_time) AS latest
  FROM `billing-export-common-prod.billing_export.gcp_billing_export_v1_*`;
  ```
- **Pass:** the `gcp_billing_export_*` table exists and `rows > 0` with a recent `latest` (export
  begins within ~24h of configuration).
- **Fail:** no table/rows after 24–48h → re-check the Console billing-export configuration points at
  the correct project/dataset. **Verify the current export path in your organization.**

## T7 — Naming/labeling conforms (continuous)

- **Procedure:**
  ```bash
  python scripts/gcp_naming_label_helper.py --validate \
    --standard naming-standard.json --scan-organization "$ORG_ID"
  ```
- **Pass:** every folder/project name matches the `<Purpose> – <Scope> – <Stage>` grammar and every
  project carries the required label keys (`env`, `owner`, `cost-center`, `data-class`).
- **Fail:** the tool lists each non-conforming resource and the expected form → correct names/labels
  and re-scan.

## T8 — Full validation report (Stage 5 gate)

- **Procedure:** run `gcp_landing_zone_validate.py` (see Implementation Stage 5).
- **Pass:** the HTML report shows **PASS** on all checks (hierarchy, guardrails, IAM baseline, log
  sink, billing export, Shared VPC). This is the gate to proceed to Expand.
- **Fail:** any check FAILs → resolve using the matching test above; do not Expand until the report
  is all-green.
