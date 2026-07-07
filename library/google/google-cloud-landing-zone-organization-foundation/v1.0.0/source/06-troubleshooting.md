# Troubleshooting

Common failure modes when building the landing zone and how to resolve them. Symptoms are grouped by
stage; the named artifacts (`Org Policy Baseline – Org – v1`, `Landing Zone – Pilot`, the foundation
projects) match the Implementation and Testing sections.

---

## Access & permissions

**`PERMISSION_DENIED` creating folders/projects or setting org policy.**
The identity lacks Organization-level authority. Confirm it holds
`roles/resourcemanager.organizationAdmin` (and, for guardrails, `roles/orgpolicy.policyAdmin`; for
project creation, `roles/resourcemanager.projectCreator`) at the Organization node:
`gcloud organizations get-iam-policy "$ORG_ID"`. Prefer running through the seed CI identity (R1)
with these roles rather than a human account.

**`gcloud` acts on the wrong resource / silently no-ops.**
Your active config points elsewhere. Check `gcloud config list` and re-set
`gcloud config set project <seed-project-id>`. All examples assume `$ORG_ID`, `$BILLING_ACCOUNT`,
and `$SEED_PROJECT` are exported (Implementation top).

## Hierarchy & projects (Gate C1 / Test T1)

**`gcp_hierarchy_provisioner.py --apply` fails with `Project ID already exists`.**
Project IDs are globally unique across all of GCP. Choose a distinct ID (the display *name* can stay,
e.g. `Logging – Common – Prod`, but the ID must be unique) and update the plan JSON.

**Projects created but `billingEnabled=false`.**
The billing link step failed (often missing `roles/billing.user` on the billing account for the
identity). Grant it, then `gcloud billing projects link <project-id> --billing-account="$BILLING_ACCOUNT"`.
Re-run Test T1 to confirm.

**Folder created twice / duplicated names.**
Folder display names are not unique. The provisioner checks for an existing folder by display name on
`--apply` and skips it; if you created folders manually as well, delete the empty duplicate
(`gcloud resource-manager folders delete <folder-id>`) and re-run.

## Org-policy guardrails (Gate C2 / Test T2)

**A disallowed action still succeeds on the pilot.**
The constraint isn't enforced at the pilot scope, or its name/semantics differ in your org. Confirm
with `gcloud org-policies describe <constraint> --folder=<PILOT_FOLDER_ID>`, then re-run
`gcp_org_policy_guardrails.py --scope folders/<PILOT_FOLDER_ID> --apply`. **List constraints**
(e.g. `compute.vmExternalIpAccess`, `gcp.resourceLocations`, `iam.allowedPolicyMemberDomains`) need
explicit allow/deny values authored in a policy YAML — a boolean-style enforce won't apply them.
**Verify the exact constraint name and type in your organization** against the current Organization
Policy constraints reference.

**`iam.allowedPolicyMemberDomains` locks out a legitimate identity.**
This domain-restricted-sharing constraint denies members outside your customer ID(s). If a needed
Google-managed service account or partner domain is blocked, add its customer ID to the allow list
(update the value and re-apply), or scope an exception at a lower node. Test on the pilot before org
promotion.

**Guardrail promotion to the Organization broke an existing workload.**
This is why the model is pilot-first with a rollback owner (R6). Revert the single constraint at the
org scope: `gcloud org-policies delete <constraint> --organization="$ORG_ID"`, restore the prior
state from the tool's change log, then re-pilot with the exception encoded before re-promoting.

## IAM baseline (Gate C3 / Test T3)

**Test T3 reports `user:` bindings at the foundation scope.**
Someone was granted a role directly instead of via a group. Move them into the correct `gcp-*` group
and remove the direct binding (`gcloud … remove-iam-policy-binding … --member="user:…"`). The
break-glass super-admin is the only expected individual identity and must stay out-of-band and
alarmed — it should not appear in routine role bindings.

**Group binding has no effect (members can't do the thing).**
Confirm the group exists in Cloud Identity (R4) and the user is a member; group membership changes can
take a short time to propagate. Also confirm the role was granted at a scope that covers the resource
(e.g. network admin on the host project, not just the folder).

## Logging (Gate C4 / Test T4)

**Sink created but no logs arrive in `Project: Logging – Common – Prod`.**
The sink's **writer service account** lacks write permission on the destination. Get the writer
identity from `gcloud logging sinks describe org-audit-sink-common-prod --organization="$ORG_ID"` and
grant it `roles/logging.bucketWriter` (log bucket) or dataset write (BigQuery) on the destination.
Confirm `includeChildren=true` and that the log filter matches (`logName:"cloudaudit.googleapis.com"`).

**Data Access logs missing.**
Admin Activity logs are always on, but **Data Access** audit logs are off by default and configured
per service — enable them where policy requires (they can be high-volume). **Verify the current Data
Access log configuration path in your organization.**

## Billing export (Gate C5 / Test T6)

**No `gcp_billing_export_*` table after configuring.**
Billing export to BigQuery is configured in the **Console** (Billing → Billing export), not via a
`gcloud` enable command, and the first rows can take up to ~24h. Confirm the export targets the
`billing_export` dataset in `Project: Billing-Export – Common – Prod` and that the BigQuery API is
enabled there. **Verify the current export path in your organization.**

## Shared VPC (Gate C6 / Test T5)

**Service project can't use the shared subnet.**
Two things must both be true: the service project is **associated** to the host
(`gcloud compute shared-vpc associated-projects add <svc> --host-project=networking-host-shared-vpc-prod`)
and the workload group/identity has `roles/compute.networkUser` on the specific subnet. Grant subnet
use, then re-run Test T5.

**Instance creation on the shared subnet is denied for an external IP.**
That's the guardrail working — `compute.vmExternalIpAccess` denies external IPs. Create the instance
with `--no-address` (as Test T5 shows). If a workload genuinely needs egress, use Cloud NAT on the
host, not an external IP.

## Tooling

**A Python tool prints the plan but changes nothing.**
That's the safe default — the provisioner and guardrail tools are **dry-run unless `--apply`** is
passed. Re-run with `--apply` after reviewing the plan (pilot scope first for guardrails).

**`gcloud CLI not found on PATH`.**
Install the Google Cloud SDK and ensure `gcloud` is on `PATH`; the tools shell out to it. For
`--scan-organization` and any live call, the environment must be authenticated (`gcloud auth login`
or ADC). The tools use ADC / the environment — **never** supply a downloaded service-account key.

**Validation report FAILs a check you believe is fine.**
The report checks *presence/enforcement*, not intent. Open the HTML report's Detail column for the
exact reason, cross-check with the matching manual test (T1–T7), and remember that some checks (billing
export rows, Data Access logs) are flagged verify-in-your-organization because they are
Console-configured or version-dependent.
