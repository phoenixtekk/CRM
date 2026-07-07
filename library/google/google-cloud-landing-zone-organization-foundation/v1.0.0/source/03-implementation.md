# Implementation

Build the landing zone top-down against the resource hierarchy, following the house model
**Assess → Design → Configure → Pilot → Validate → Expand**. Every artifact is named with the
`<Purpose> – <Scope> – <Stage>` convention and that exact name is reused in later steps, testing,
troubleshooting, and the Python tools. **Configure steps are dry-run first, then applied.** Anything
that touches the Organization node is proven on `Landing Zone – Pilot` before Expand.

Throughout, set your identifiers once and reuse them:

```bash
export ORG_ID="123456789012"                 # from: gcloud organizations list
export BILLING_ACCOUNT="ABCDEF-123456-GHIJKL" # from: gcloud billing accounts list
export SEED_PROJECT="bootstrap-seed-prod"     # R1
```

> All `gcloud` shown is current public CLI syntax; where a constraint or feature is version-dependent
> it is flagged **verify in your organization**. Prefer running provisioning through the CI identity
> (R1) over a human account.

---

## Stage 1 — Assess (read-only)

**Goal:** know exactly what exists before you change anything.

1. **Confirm the Organization and access.**
   ```bash
   gcloud organizations describe "$ORG_ID"
   gcloud organizations get-iam-policy "$ORG_ID" \
     --flatten="bindings[].members" --format="table(bindings.role, bindings.members)"
   ```
   Confirm the account (or CI identity) holds `roles/resourcemanager.organizationAdmin` and the
   roles R1 lists.

2. **Inventory the current estate.** Run the assessment tool from this solution:
   ```bash
   python scripts/gcp_org_assessment.py --organization "$ORG_ID" --output org-assessment.json
   ```
   It enumerates folders, projects, existing org policies, billing linkage, and top-level IAM
   (read-only) and writes a baseline report. **Gate A1:** you can account for every existing project
   (owner, environment, whether it belongs in the new hierarchy).

3. **Confirm billing.** `gcloud billing accounts list` shows the account OPEN; note the ID.

---

## Stage 2 — Design

**Goal:** agree the shape once, in writing.

1. **Draft the naming/labeling convention** with the helper:
   ```bash
   python scripts/gcp_naming_label_helper.py --emit-standard --output naming-standard.json
   ```
   This produces the `<Purpose> – <Scope> – <Stage>` name grammar and the label key set
   (`env`, `owner`, `cost-center`, `data-class`). Review and adjust with stakeholders.

2. **Agree the hierarchy** (Common / Production / Non-Production / Bootstrap folders and the
   foundation projects listed in the Overview reference design) and the **guardrail set**
   `Org Policy Baseline – Org – v1` with security. **Gate D1:** the design document is signed off by
   platform, security, network, and FinOps owners, and `Landing Zone – Pilot` is named (R6).

---

## Stage 3 — Configure (dry-run first, then apply)

Build in this order so inheritance and dependencies resolve cleanly. For each provisioning tool, run
**without `--apply` first** (dry-run prints the planned actions), inspect, then re-run with `--apply`.

### 3a. Build the folder/project hierarchy

1. **Create the top-level folders.**
   ```bash
   for F in Common Production Non-Production Bootstrap; do
     gcloud resource-manager folders create --display-name="$F" --organization="$ORG_ID"
   done
   gcloud resource-manager folders list --organization="$ORG_ID"
   ```

2. **Provision the foundation projects** with the provisioner (dry-run, then apply). It creates,
   under the right folders, the named projects and links billing:
   - `Project: Logging – Common – Prod`
   - `Project: Billing-Export – Common – Prod`
   - `Project: Networking-Host – Shared-VPC – Prod`
   - `Project: Bootstrap – Seed – Prod` (if not already created in R1)
   ```bash
   # dry-run (default: prints plan, changes nothing)
   python scripts/gcp_hierarchy_provisioner.py \
     --organization "$ORG_ID" --billing-account "$BILLING_ACCOUNT" --plan hierarchy-plan.json
   # apply
   python scripts/gcp_hierarchy_provisioner.py \
     --organization "$ORG_ID" --billing-account "$BILLING_ACCOUNT" --plan hierarchy-plan.json --apply
   ```
   **Gate C1:** every named project exists under the correct folder and is linked to billing
   (`gcloud billing projects describe <project-id>`).

### 3b. Apply organization-policy guardrails — **pilot first**

1. **Apply `Org Policy Baseline – Org – v1` to `Landing Zone – Pilot` only.** Use the guardrail
   applier in dry-run, review, then apply scoped to the pilot folder:
   ```bash
   python scripts/gcp_org_policy_guardrails.py --scope "folders/<PILOT_FOLDER_ID>" \
     --baseline org-policy-baseline-v1.yaml            # dry-run
   python scripts/gcp_org_policy_guardrails.py --scope "folders/<PILOT_FOLDER_ID>" \
     --baseline org-policy-baseline-v1.yaml --apply
   ```
   The baseline includes constraints such as `iam.disableServiceAccountKeyCreation`,
   `compute.vmExternalIpAccess`, `compute.skipDefaultNetworkCreation`, `gcp.resourceLocations`,
   `iam.allowedPolicyMemberDomains`, and `storage.uniformBucketLevelAccess`. **Verify each
   constraint's exact name and behavior in your organization** against the current Organization
   Policy constraints reference before enforcing — some are boolean, some are list constraints with
   allow/deny values.

2. **Pilot gate — Gate C2:** on the pilot, confirm the guardrails are *enforced* and that expected
   actions are correctly denied (see Testing §T2), e.g. attempting to create a VM with an external
   IP in the pilot project is denied.

3. **Promote to the Organization node** only after the pilot passes:
   ```bash
   python scripts/gcp_org_policy_guardrails.py --scope "organizations/$ORG_ID" \
     --baseline org-policy-baseline-v1.yaml            # dry-run
   python scripts/gcp_org_policy_guardrails.py --scope "organizations/$ORG_ID" \
     --baseline org-policy-baseline-v1.yaml --apply
   ```

### 3c. Set the least-privilege IAM baseline (groups → roles)

1. **Confirm the foundation groups exist** (R4). Bind roles to *groups*, at the narrowest scope that
   works:
   ```bash
   # Example: network admins get network admin only on the Shared VPC host project
   gcloud projects add-iam-policy-binding networking-host-shared-vpc-prod \
     --member="group:gcp-network-admins@example.com" --role="roles/compute.networkAdmin"
   # Example: security gets org-wide log/SCC viewing at the org node
   gcloud organizations add-iam-policy-binding "$ORG_ID" \
     --member="group:gcp-security-admins@example.com" --role="roles/logging.viewer"
   ```
   Grant `roles/resourcemanager.organizationAdmin` only to `gcp-organization-admins`, and keep the
   **break-glass super-admin** out of daily use (MFA, audited, alarmed on login).

2. **Gate C3:** no role is bound to an individual user in the foundation; the assessment/validation
   tool reports zero user-member bindings at the Organization and Common folder scopes.

### 3d. Wire centralized audit logging

1. **Create the aggregated org-level log sink** into `Project: Logging – Common – Prod`:
   ```bash
   gcloud logging sinks create org-audit-sink-common-prod \
     "logging.googleapis.com/projects/logging-common-prod/locations/global/buckets/org-audit" \
     --organization="$ORG_ID" --include-children \
     --log-filter='logName:"logs/cloudaudit.googleapis.com"'
   ```
   Grant the sink's writer identity `roles/logging.bucketWriter` on the destination. **Admin
   Activity** audit logs are always on; enable **Data Access** logs where policy requires (they can
   be high-volume — scope by service). **Verify Data Access log configuration in your organization.**

2. **Gate C4:** logs appear in the destination (see Testing §T4).

### 3e. Enable billing export to BigQuery

1. In the Cloud Console, go to **Billing → Billing export → BigQuery export** and configure
   **Standard usage cost** export into a dataset (e.g. `billing_export`) in
   `Project: Billing-Export – Common – Prod`. (Billing export to BigQuery is configured in the
   Console; there is no direct `gcloud` enable command — **verify the current path in your
   organization**.)
2. **Gate C5:** a `gcp_billing_export_*` table appears in the dataset within ~24h and rows accrue.

### 3f. Stand up the Shared VPC landing pattern

1. **Enable the host project** and create the VPC/subnets in `Project: Networking-Host – Shared-VPC –
   Prod`:
   ```bash
   gcloud compute shared-vpc enable networking-host-shared-vpc-prod
   gcloud compute networks create lz-vpc-shared-prod --subnet-mode=custom \
     --project=networking-host-shared-vpc-prod
   gcloud compute networks subnets create lz-subnet-prod-use1 \
     --network=lz-vpc-shared-prod --region=us-east1 --range=10.10.0.0/20 \
     --project=networking-host-shared-vpc-prod
   ```
2. **Attach a service project** (start with the pilot) and grant subnet use to a workload group:
   ```bash
   gcloud compute shared-vpc associated-projects add <pilot-service-project> \
     --host-project=networking-host-shared-vpc-prod
   ```
   **Gate C6:** the pilot service project can create a resource on the shared subnet (see Testing
   §T5).

---

## Stage 4 — Pilot (already threaded above) → Stage 5 — Validate

Run the validation report; **every gate must pass**:
```bash
python scripts/gcp_landing_zone_validate.py --organization "$ORG_ID" \
  --logging-project logging-common-prod \
  --billing-project billing-export-common-prod \
  --host-project networking-host-shared-vpc-prod \
  --report landing-zone-validation.html
```
The report checks: hierarchy present and correctly nested; `Org Policy Baseline – Org – v1` enforced;
IAM baseline has no user-member bindings at foundation scope; the org audit sink is writing;
billing export dataset is populated; and the Shared VPC is attachable. **Validation gate:** a PASS on
all checks is required before Expand.

---

## Stage 6 — Expand

Onboard the remaining folders/projects and workload teams onto the proven pattern: create service
projects under `Folder: Production` / `Folder: Non-Production`, attach them to the Shared VPC, bind
the appropriate `gcp-<env>-developers` group, and confirm they inherit `Org Policy Baseline – Org –
v1`. Re-run the validation report after each wave.

---

## Rollback (documented, org-wide changes)

The rollback owner (R6) reverts in reverse dependency order. Key reverts:

- **Org policy:** restore prior policy or delete the enforced constraint at the scope it was set:
  ```bash
  gcloud org-policies delete <constraint> --organization="$ORG_ID"      # or --folder=<PILOT_FOLDER_ID>
  ```
  Because guardrails were **piloted before org-wide apply**, the highest-risk revert is a single
  folder, not the whole Organization.
- **Log sink:** `gcloud logging sinks delete org-audit-sink-common-prod --organization="$ORG_ID"`.
- **Shared VPC attachment:** `gcloud compute shared-vpc associated-projects remove <project> \
  --host-project=networking-host-shared-vpc-prod`.
- **IAM binding:** remove with `remove-iam-policy-binding` mirroring the add.
- **Projects/folders** created in error can be **shut down** (`gcloud projects delete`, recoverable
  within the 30-day window) / folders deleted once empty.

Each provisioning tool's `--apply` run writes a change record (what it changed, prior value) so the
rollback owner has the exact prior state to restore.
