# Solution Overview — AWS Landing Zone & Organizations Baseline

## What this is

A complete, self-guided method for standing up a **governed, multi-account AWS foundation** — AWS
Organizations with an OU hierarchy, a landing zone with account vending, Service Control Policies
(SCPs) as preventive guardrails, centralized CloudTrail and AWS Config in a dedicated log-archive
account, and an account baseline — delivered as **real Infrastructure-as-Code** (Terraform + AWS CLI)
that runs **plan-first and approval-gated**.

It is the **foundation** layer of an AWS estate. Everything above it — workload platforms, networking,
security-finding triage, identity federation — assumes this governed base exists and builds on it.

## How the technology works (the mental model)

- **AWS Organizations.** The service that groups multiple AWS accounts under one **management (payer)
  account** for consolidated billing and central governance. It is the container that makes
  multi-account governance possible.
- **Organizational Units (OUs).** Folders within the organization that group accounts so policy can
  be applied to a whole group. A standard hierarchy separates concerns: a **Security** OU (log
  archive, security tooling), an **Infrastructure** OU (shared services, networking), a **Workloads**
  OU (production and non-production), and a **Sandbox** OU (experimentation with tight guardrails).
- **Landing zone.** The opinionated, governed baseline applied across the org. Two paths:
  - **AWS Control Tower** — a **managed** landing zone that sets up OUs, a log-archive and audit
    account, guardrails, and **Account Factory** vending through a console/API. Lower effort, less
    customization. *Verify current Control Tower feature availability and region support.*
  - **Terraform landing zone** — the org, OUs, SCPs, logging, and baseline defined as **code** (this
    package's `main.tf`), optionally with **Account Factory for Terraform (AFT)** for vending. More
    control, fully version-controlled. This package delivers the Terraform path and notes Control
    Tower as the managed alternative.
- **Account vending.** The repeatable process of creating a new account **pre-baselined** — placed in
  the right OU, with logging, guardrails, and the account baseline already applied — instead of
  hand-building each one.
- **Service Control Policies (SCPs).** Organization policies that set the **maximum available
  permissions** for accounts in an OU. SCPs are **preventive guardrails**: they *deny* actions
  regardless of what an account's own IAM allows (e.g. deny leaving the org, deny root-user actions,
  deny unapproved regions, deny disabling CloudTrail/Config/GuardDuty). An SCP does not *grant*
  anything — it only bounds. *SCP inheritance and evaluation are order-sensitive — verify behavior.*
- **Centralized CloudTrail + AWS Config.** An **organization CloudTrail** records API activity across
  every account into one **log-archive account**; **AWS Config** records resource configuration and
  compliance and aggregates it centrally. Putting the record in a separate, locked-down account makes
  it **tamper-resistant**.
- **Account baseline.** The minimum secure defaults applied to every account: an **IAM password
  policy**, **default EBS/S3 encryption**, **root MFA / no root keys**, and an **allowed-region**
  posture — encoded so every account starts the same way.

## The standard deployment model

Every solution in this program follows the same five stages:

1. **Assess.** Discover the current org, accounts, OUs, existing SCPs, and whether CloudTrail/Config
   already exist (run `AWSLZ-Discovery.sh`). Confirm management access and a least-privilege deploy
   role (category G1–G2).
2. **Configure.** Author the baseline **as code**: OUs, the log-archive account, the organization
   CloudTrail, Config + aggregator, the SCPs (in a **staging/attached-but-permissive** posture
   first), and the account baseline — in `main.tf`, against remote state (G5).
3. **Pilot.** Apply to a **non-production scope first** — attach SCPs to a **non-prod / sandbox OU**
   in a monitoring-friendly way, and vend one test account — using **`terraform plan` before every
   apply** (`AWSLZ-Deploy.sh` is plan-first and approval-gated).
4. **Validate.** Confirm the guardrails **deny what they should** and **allow what they should**,
   logs land in the log-archive account, and the baseline is applied (run `AWSLZ-Validate.sh`,
   `AWSLZ-Report.sh`).
5. **Expand.** Attach the SCPs to the remaining OUs, enable account vending for real, and institute
   the plan → review → apply loop for every future change.

## Scope — what this solution covers

- **AWS Organizations + OU hierarchy** — the multi-account structure and account placement.
- **Landing zone + account vending** — Terraform baseline (Control Tower as the managed alternative)
  and a repeatable way to create pre-baselined accounts.
- **Service Control Policies (SCPs)** — preventive guardrails denying the dangerous defaults.
- **Centralized CloudTrail + AWS Config + a log-archive account** — tamper-resistant central logging.
- **Account baseline** — IAM password policy, default encryption, allowed-region posture, root
  hygiene.

## Out of scope (handled elsewhere)

- **Security-finding detection and triage** — GuardDuty and Security Hub enablement/triage is the
  companion *AWS Security Hub & GuardDuty Enablement* solution (this foundation makes it deployable
  org-wide).
- **Identity federation** — federating **IAM Identity Center** with Entra ID (SSO/SCIM) is the
  companion *AWS IAM Identity Center ↔ Entra SSO Federation* solution.
- **Networking / transit / data-perimeter** — VPC design, Transit Gateway, and network guardrails are
  separate workload-platform work.
- **Workload landing zones and application accounts' internals** — this builds the governed base, not
  the applications on it.
- **The governance decisions** — which regions are allowed, the tagging standard, the OU model
  specifics, and every production apply approval are **the customer's cloud-governance/operations
  determinations**; this solution provides the technical guardrails and the code.

## Authentication and connections used

- **AWS Organizations / Control Tower** from the **management (payer) account**, or delegated-admin
  rights, for org, OU, SCP, and landing-zone actions.
- **Terraform** (pinned provider/CLI — *verify current versions*) with the **AWS provider**, against
  **remote state** (S3 + DynamoDB lock, category G5), authenticating via an **assumed IAM role /
  Identity Center permission set / OIDC-federated CI identity** — **never long-lived root or static
  admin keys** (category G2).
- **AWS CLI v2** for the read-only discovery, validation, and reporting helpers.
- Everything is **plan-first**: `terraform plan` (or Control Tower preview) precedes every apply, run
  through the pipeline (category G4) with approval. GovCloud uses a different partition and endpoints
  — *verify partition-specific behavior, feature availability, and pricing for your cloud*.
