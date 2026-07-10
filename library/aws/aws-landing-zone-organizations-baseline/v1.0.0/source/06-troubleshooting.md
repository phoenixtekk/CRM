# Troubleshooting — AWS Landing Zone & Organizations Baseline

The common failure modes, each as **symptom → cause → fix**. Most issues are org-mode, SCP scope, or
logging-delivery permissions — not a broken service.

---

## 1. `terraform plan` / SCP resources fail — "not available in consolidated billing"

- **Symptom:** SCP or policy resources error; the org rejects attaching an SCP.
- **Cause:** AWS Organizations is in **consolidated-billing-only** mode, not **All features**.
- **Fix:** Enable **All features** from the management account (R1). This requires member-account
  consent — plan for it. Confirm with `aws organizations describe-organization` → `FeatureSet: ALL`.

## 2. The wrapper refuses to run — "you are the ROOT user"

- **Symptom:** `AWSLZ-Deploy.sh` exits refusing to proceed.
- **Cause:** **Working as designed.** You are authenticated as **root**, which is the top AWS breach
  vector and must never run automation (G2).
- **Fix:** Assume a **scoped deployment role / Identity Center permission set / OIDC identity** and
  re-run. Confirm with `aws sts get-caller-identity` (the ARN must be an assumed role).

## 3. An SCP locked out the management or security account

- **Symptom:** After attaching an SCP broadly, admins can't perform needed actions (even in the
  management/security accounts).
- **Cause:** A broad **deny** SCP was attached to an OU/root **without exempting** the management,
  security-tooling, or break-glass principals.
- **Fix:** SCPs are pilot-first for exactly this reason. **Detach** the SCP from the affected OU (or
  add a scoped exemption via `aws:PrincipalArn` / `exempt_account_ids`), re-plan, re-apply. Never
  attach broad denies to the org root without exemptions.

## 4. Region-lockdown SCP is blocking legitimate global-service calls

- **Symptom:** IAM, CloudFront, Route 53, or support calls are denied after `SCP-RegionLockdown-
  Guardrail` is attached.
- **Cause:** Global services operate in a single region (often `us-east-1`) and must be **exempted**
  from the region condition.
- **Fix:** Confirm the `NotAction` exemptions in the region-lockdown SCP cover the global services you
  use (IAM, STS, Organizations, CloudFront, Route 53, support, WAF, budgets). *Verify the current set
  of global services for your needs.*

## 5. Organization CloudTrail won't deliver to the log bucket

- **Symptom:** `Trail-Org-CloudTrail` exists but no objects land in `org-log-archive-<id>`.
- **Cause:** The S3 **bucket policy** doesn't grant the CloudTrail service (and org path) write
  access, or the **KMS key policy** doesn't grant CloudTrail encrypt permission.
- **Fix:** Add the CloudTrail delivery bucket policy (with the organization-id path) and the KMS key
  policy statements CloudTrail requires. The `main.tf` marks these as add-them steps — *verify the
  current required policy statements for org trails*.

## 6. AWS Config aggregator shows nothing

- **Symptom:** `Config-Org-Aggregator` exists but aggregates no data.
- **Cause:** Per-account **Config recorders** aren't enabled, or the aggregator authorization/role
  isn't in place; and aggregation is best read from the **delegated-admin** account.
- **Fix:** Enable Config recorders via the account baseline; confirm the aggregator role and
  organization authorization; read the aggregator from the delegated-admin/security account.

## 7. Control Tower and Terraform are fighting over the same objects

- **Symptom:** Drift, or resource conflicts, on log-archive/audit accounts, guardrails, or Account
  Factory.
- **Cause:** Both **Control Tower** and this **Terraform** baseline are trying to own the same
  landing-zone objects (R2).
- **Fix:** Choose one path. If Control Tower is in use, scope this package's Terraform to **add-on**
  SCPs and account baseline only, and let Control Tower own the OUs/logging/vending it manages. Do not
  delete Control-Tower-owned resources out from under it.

## 8. `terraform init` fails on the backend / state is local

- **Symptom:** `init` errors on the S3 backend, or state is sitting on the laptop.
- **Cause:** The remote-state backend (S3 + DynamoDB) isn't provisioned or the backend block isn't
  filled in (R6).
- **Fix:** Bootstrap the encrypted, versioned S3 bucket + DynamoDB lock table first, fill in the
  `backend "s3"` block in `main.tf`, and `terraform init`. **Never** run the foundation on local
  state.

## 9. A vended account isn't baselined

- **Symptom:** A new account lacks SCPs, logging, password policy, or default encryption.
- **Cause:** The account was created **outside** the vending path, or the vending template is missing
  a baseline step.
- **Fix:** Re-apply the baseline to the account and **fix the vending template** so every future
  account inherits it. Prefer vending over hand-creating accounts.

## 10. Unexpected foundation cost

- **Symptom:** Bills climb after the landing zone goes in.
- **Cause:** CloudTrail **data events**, AWS **Config** recording volume, KMS, and S3 storage scale
  with accounts and activity.
- **Fix:** Right-size CloudTrail data-event selectors and Config rules, and review spend per account.
  *Verify current AWS pricing for your partition — pricing and free-tier terms change.* Cost
  thresholds and trade-offs are a customer FinOps decision.
