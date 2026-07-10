# Best Practices — AWS Landing Zone & Organizations Baseline

Keep-it-clean guidance for a governed AWS foundation that stays safe, reproducible, and current over
time.

## Treat the foundation as code, always

- **No console click-ops on the foundation.** OUs, SCPs, logging, and baseline changes go through
  `terraform plan` → review → apply (`AWSLZ-Deploy.sh`), in version control. A foundation changed by
  hand is a foundation no one can reproduce or audit.
- **Plan-first, non-prod-first.** Read every plan before applying, and apply to `Workloads-NonProd` /
  `Sandbox` before `Workloads-Prod`. The plan is your safety net — use it.
- **Protect the state like production data.** Remote, encrypted, versioned, locked state (R6) is the
  source of truth for the whole estate; losing it is an incident. Restrict who can touch the state
  backend.

## Guardrails prevent — keep them lean and exempt the exits

- **SCPs deny, they never grant.** Use them to remove the dangerous defaults (leave-org, root, bad
  regions, disabling security, unencrypted storage) — not as a permissions system.
- **Never lock yourself out.** Always **exempt the management and security-tooling accounts** (and
  break-glass roles) from broad denies before attaching to the org root. Test on a pilot OU first.
- **Fewer, clearer SCPs.** A handful of well-named guardrails (`SCP-…-Guardrail`) beat a sprawl of
  overlapping policies — SCP evaluation is order- and inheritance-sensitive, so keep it legible.
  *Verify SCP inheritance behavior for your org.*

## Centralize logging where the workloads can't reach it

- **Logs live in a separate Log-Archive account.** CloudTrail (`Trail-Org-CloudTrail`) and Config
  (`Config-Org-Aggregator`) must land **outside** the accounts they audit, encrypted with a CMK
  (`kms-org-logs`), so a workload compromise doesn't own the evidence.
- **Lock the log bucket down.** Versioning, object-lock where appropriate, a tight bucket policy, and
  no human write access — the archive is append-mostly and tamper-resistant.

## Vend accounts, don't hand-build them

- **Every new account is pre-baselined.** Placed in the right OU, with SCPs, logging, and the account
  baseline already applied by the vending path — never a snowflake configured after the fact.
- **Fix the template, not the account.** When a baseline gap appears, correct the vending template so
  every future account inherits the fix.

## Baseline every account the same way

- **Encode the minimums:** IAM password policy, default EBS/S3 encryption, no root access keys, root
  MFA, and the allowed-region posture. Consistency is the control.
- **Decide governance deliberately.** Which regions are allowed, the tagging standard, and the OU
  model are **cloud-governance decisions (R4/R5)** — the solution enforces what you set; it does not
  choose for you.

## Mind the cost of the foundation

- **The foundation is billable.** CloudTrail data events, Config recording, KMS, and S3 all cost
  money, and cost scales with accounts and activity. Right-size Config rules and CloudTrail data-event
  selectors, and review spend. *Verify current AWS pricing for your partition before you scale.*

## Where to go next

With the governed foundation in place, the natural next steps in this catalog are:

- **AWS Security Hub & GuardDuty Enablement** — turn on org-wide threat detection and
  posture-management now that there is a Security OU and delegated-admin account to own it.
- **AWS IAM Identity Center ↔ Entra SSO Federation** — replace static IAM users with federated,
  MFA-backed SSO across the accounts you just governed.
- **Workload landing zones / networking** — build VPC, Transit Gateway, and data-perimeter guardrails
  on top of the account structure.
- **Azure / GCP foundation solutions** — apply the same governed-foundation discipline to your other
  clouds for a consistent multi-cloud posture.
