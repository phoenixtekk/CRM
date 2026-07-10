# Implementation — AWS Landing Zone & Organizations Baseline

This is the exact, ordered build. Every object you create is **named** with a consistent convention
and the same name is reused in later steps, testing, and the IaC. Everything is **plan-first**:
`terraform plan` (or a Control Tower preview) precedes every apply, and you apply to a
**non-production scope before production**.

> **Before you start:** enable Organizations in **All features** mode (R1), provision the encrypted
> **remote state** backend (R6), and authenticate as an **assumed role — never root** (category
> G2). This guide delivers the **Terraform** landing-zone path; if you use **AWS Control Tower**, use
> these SCPs and the account baseline as **add-ons** to Control Tower's, not replacements (R2).

**Named objects created in this guide (verbatim — reused everywhere):**

| Object | Name | What it is |
| --- | --- | --- |
| OU | `Security` | Log-archive + security-tooling accounts |
| OU | `Infrastructure` | Shared services / networking |
| OU | `Workloads-Prod` | Production workload accounts |
| OU | `Workloads-NonProd` | Non-production workload accounts (pilot scope) |
| OU | `Sandbox` | Experimentation, tight guardrails (pilot scope) |
| Account | `Log-Archive` | Tamper-resistant central log destination |
| Account | `Security-Tooling` | Audit / security services (delegated admin) |
| SCP | `SCP-DenyLeaveOrg-Guardrail` | Deny an account leaving the organization |
| SCP | `SCP-DenyRootActions-Guardrail` | Deny root-user actions |
| SCP | `SCP-RegionLockdown-Guardrail` | Deny actions outside allowed regions |
| SCP | `SCP-ProtectSecurityServices-Guardrail` | Deny disabling CloudTrail/Config/GuardDuty |
| SCP | `SCP-RequireEncryption-Guardrail` | Deny creating unencrypted storage |
| Org CloudTrail | `Trail-Org-CloudTrail` | Org-wide API activity trail → Log-Archive |
| Config aggregator | `Config-Org-Aggregator` | Org-wide Config aggregation |
| Log bucket | `org-log-archive-<mgmt-account-id>` | Central, versioned, encrypted log bucket |
| Log KMS key | `kms-org-logs` | CMK encrypting the central logs |

---

## Phase 0 — Assess (read-only, changes nothing)

### Step 0.1 — Confirm identity and org state

1. Confirm you are an **assumed role**, not root:

   ```
   aws sts get-caller-identity
   ```

   The `Arn` should be an assumed role / permission set — **not** the root user.
2. Run the discovery helper:

   ```
   ./AWSLZ-Discovery.sh
   ```

   It reports: the org **feature set** (expect `ALL` — R1), existing **OUs and accounts** and their
   placement, existing **SCPs**, whether an **organization CloudTrail** and **AWS Config** already
   exist, and whether a **Log-Archive** account is present. **Read-only** — it only calls `describe`/
   `list` APIs.

### Step 0.2 — Confirm remote state and toolchain

1. `terraform version`, `aws --version`, `git --version` return the pinned/supported builds (R7).
2. `terraform init` succeeds against the **remote state** backend (R6) — S3 + DynamoDB lock,
   encrypted and versioned.

---

## Phase 1 — Configure (author the baseline as code; nothing applied yet)

### Step 1.1 — Set the variables

1. Open `main.tf` (and its `variables`/`terraform.tfvars`) and set:
   - `allowed_regions` — your agreed region-allow list (R4).
   - `tags` — your tagging standard (R5).
   - `management_account_id`, and the email addresses for the `Log-Archive` and `Security-Tooling`
     accounts.
2. Confirm the OU names match the table above (or your agreed model, R4).

### Step 1.2 — Review the plan (no apply)

1. Generate and **read** the plan — this is the single most important review gate:

   ```
   ./AWSLZ-Deploy.sh plan
   ```

   `AWSLZ-Deploy.sh` wraps `terraform init/plan/apply` and is **plan-first**: `plan` never changes
   anything. Confirm the plan will create the OUs, the two core accounts, `Trail-Org-CloudTrail`, the
   `org-log-archive-<id>` bucket + `kms-org-logs`, `Config-Org-Aggregator`, and the five SCPs — and
   nothing unexpected (no deletions of existing infrastructure).
2. Commit the code and the plan output for review/approval (category G4/G8).

---

## Phase 2 — Pilot (apply to a non-production scope first)

### Step 2.1 — Apply the org structure and central logging

1. Apply the OUs, core accounts, CloudTrail, Config, and bucket/KMS — but **hold the SCP attachments
   to production OUs**:

   ```
   ./AWSLZ-Deploy.sh apply
   ```

   `AWSLZ-Deploy.sh apply` **re-plans, shows the plan, and requires an explicit typed confirmation**
   before it applies. It will not apply unattended.
2. Confirm `Trail-Org-CloudTrail` is delivering to the `Log-Archive` account and `Config-Org-
   Aggregator` is aggregating.

### Step 2.2 — Attach SCPs to the non-prod / sandbox OUs first

1. Attach the five guardrail SCPs to the **`Workloads-NonProd`** and **`Sandbox`** OUs only (leave
   `Workloads-Prod` unattached until validated). SCPs are **deny** rules — attaching to a pilot OU
   lets you observe impact without risking production.
2. Re-run `./AWSLZ-Deploy.sh plan` to preview the attachment, then `apply` with confirmation.

### Step 2.3 — Vend one test account

1. Vend a single **test account** into `Sandbox` (Terraform account resource, or Control Tower
   Account Factory if you chose that path). Confirm it lands **pre-baselined**: in the right OU, with
   the SCPs applied, logging flowing, and the account baseline (password policy, default encryption)
   set.

---

## Phase 3 — Validate

1. Run the validation helper:

   ```
   ./AWSLZ-Validate.sh
   ```

   It checks the pass/fail gates in `05-testing.md`: org is All-features, the OUs exist, the SCPs are
   attached to the pilot OUs, `Trail-Org-CloudTrail` is logging to `Log-Archive`, Config is
   recording/aggregating, and the account baseline is applied on the test account. It also runs
   **guardrail probes** (read-only) confirming a denied action (e.g. an unapproved-region call) is
   actually **denied** and an allowed action is allowed.
2. Run the posture report and review with governance:

   ```
   ./AWSLZ-Report.sh
   ```

   It summarizes accounts by OU, SCP attachments, logging status, and baseline compliance. Do not
   expand until the gates pass.

---

## Phase 4 — Expand

1. **Attach SCPs to the remaining OUs.** Once validated on non-prod/sandbox, extend the SCP
   attachments to `Workloads-Prod`, `Infrastructure`, and `Security` (mind that overly-broad denies
   can lock out the management/security accounts — **exempt them appropriately**). Plan → review →
   apply as always.
2. **Turn on account vending for real.** Use the vending path to create new accounts pre-baselined,
   instead of hand-building them.
3. **Institutionalize plan → review → apply.** Every future change to OUs, SCPs, logging, or baseline
   goes through `terraform plan`, review, and approval — never console click-ops.
4. **Set the stage for the next layers.** With the foundation governed, deploy the companion
   *Security Hub & GuardDuty* and *IAM Identity Center ↔ Entra SSO* solutions across the org.

---

## Rollback / safe-off

- **Because everything was plan-first and non-prod-first**, most missteps are caught in `plan` before
  they apply. Keep every apply small and reviewed.
- **SCP too aggressive (locked something out):** detach the SCP from the affected OU (or add a
  scoped exemption) and re-apply. Never attach a broad deny to the org root without an exemption for
  the management/security accounts.
- **Terraform-managed objects:** `terraform destroy` (scoped, plan-first) removes what Terraform
  created — but **do not destroy central logging or accounts casually**; log-archive and accounts are
  foundational. Treat destroy as a deliberate, reviewed action.
- **Control Tower path:** use Control Tower's own decommission/guardrail-disable flows for objects it
  manages; do not delete Control-Tower-owned resources out from under it.
- **Remote state** is your source of truth and rollback point — protect and version it (R6).
