# Requirements — AWS Landing Zone & Organizations Baseline

These are the **solution-specific** prerequisites for building the governed foundation. The
**category baseline** — a management/root-capable account, a least-privilege deployment identity (no
long-lived root), AWS CLI + Terraform + Git, source control + CI/CD with OIDC, Terraform remote
state, region/tagging standards, an IdP for federation where required, and a non-production
account + change control — is covered once in **`global-requirements-aws.md`** (**G1–G8**). Read that
first; the items below layer on top of it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. AWS Organizations enabled (all-features mode) from the management account

- **Description:** AWS Organizations is enabled in **"All features"** mode (not just consolidated
  billing) from the **management (payer)** account, so that **SCPs** and delegated administration are
  available.
- **Why required:** SCPs, OU policy, and org-wide CloudTrail require All-features Organizations. In
  consolidated-billing-only mode, SCPs cannot be attached.
- **How to verify:** `aws organizations describe-organization` returns `FeatureSet: ALL`. Or run
  `AWSLZ-Discovery.sh`, which reports the org feature set.
- **How to implement if missing:** From the management account, enable Organizations and, if
  currently billing-only, enable **All features** (this requires member-account consent — plan for
  it). *Verify current enablement steps.*

## R2. A landing-zone approach decision (Control Tower vs Terraform)

- **Description:** A decision on **how** the landing zone is delivered — **AWS Control Tower**
  (managed) or the **Terraform** baseline in this package — since the two set up OUs/logging/vending
  differently and are not trivially mixed.
- **Why required:** Control Tower manages some of the same objects (log-archive/audit accounts,
  guardrails, Account Factory) that the Terraform baseline would otherwise own; deploying both over
  the same org causes conflicts.
- **How to verify:** Confirm which path is chosen and, if Control Tower is already set up, that this
  package's Terraform is scoped to **complement** (not duplicate) it.
- **How to implement if missing:** Choose one. This package delivers the **Terraform** path with
  Control Tower noted as the managed alternative; if you adopt Control Tower, use this package's SCPs
  and baseline as **add-ons** to Control Tower's, not replacements. *Verify current Control Tower
  availability and region support in your partition.*

## R3. Dedicated core accounts (log-archive, security tooling)

- **Description:** A **Log-Archive** account (tamper-resistant central logging) and a **Security-
  Tooling / Audit** account, separate from the management account and from workloads.
- **Why required:** Centralized, tamper-resistant logging requires the logs to live **outside** the
  workload accounts they audit; mixing them defeats the control.
- **How to verify:** The accounts exist (or Control Tower's equivalents do) and are placed in the
  **Security** OU. `AWSLZ-Discovery.sh` lists accounts and their OU placement.
- **How to implement if missing:** Vend the Log-Archive and Security-Tooling accounts (Control Tower
  Account Factory, or the Terraform baseline) and place them in the Security OU.

## R4. An agreed OU model and region-allow list

- **Description:** A short, written decision on the **OU structure** (e.g. Security / Infrastructure /
  Workloads-Prod / Workloads-NonProd / Sandbox) and the **allowed AWS regions** the SCP region-lockdown
  guardrail will enforce.
- **Why required:** The OU model determines where SCPs apply and where accounts land; the region-allow
  list is enforced by an SCP and must match real operational and data-residency needs.
- **How to verify:** Confirm the OU model and region list are documented and owned by cloud
  governance.
- **How to implement if missing:** Facilitate a short session to agree the OU model and allowed
  regions. *Which regions are allowed is a governance/data-residency decision — the solution enforces
  the list you set, it does not choose it for you.*

## R5. A tagging and naming standard

- **Description:** A tagging standard (owner, cost-center, environment, data-classification) and
  naming conventions applied to OUs, accounts, SCPs, and resources.
- **Why required:** Cost allocation, guardrail targeting, and Config rules all depend on consistent
  tags and names; the named objects in this build (SCPs, trail, aggregator) follow the convention.
- **How to verify:** A documented standard exists; `AWSLZ-Report.sh` flags untagged/misnamed core
  resources.
- **How to implement if missing:** Define the standard and encode it in the Terraform variables and,
  later, tag policies / Config rules.

## R6. Terraform remote state ready and encrypted (foundation-critical)

- **Description:** The **remote state backend** (S3 state bucket + DynamoDB lock table, encrypted and
  versioned) from category **G5**, provisioned **before** the landing-zone apply.
- **Why required:** The landing zone is foundational; losing or corrupting its state is a serious
  incident. Remote, locked, versioned, encrypted state is mandatory here, not optional.
- **How to verify:** The state bucket/table exist, are encrypted and versioned, and the backend
  config in `main.tf`/`backend.tf` points at them. `terraform init` succeeds.
- **How to implement if missing:** Provision the S3 + DynamoDB backend first (a small bootstrap), then
  configure the backend and `terraform init`. Never run the landing zone on local state.

## R7. The IaC toolchain, pinned

- **Description:** **Terraform CLI** (pinned version), the **AWS provider** (pinned version), **AWS
  CLI v2**, and **Git**, on the workstation/CI, authenticating via an **assumed role / permission set
  / OIDC** — never static admin keys (category G2–G3).
- **Why required:** Version drift breaks reproducibility of a foundation everything else depends on;
  pinned versions keep plans deterministic.
- **How to verify:** `terraform version`, `aws --version`, `git --version` return the pinned/supported
  builds; `aws sts get-caller-identity` shows an **assumed role**, not root. *Verify current provider/
  CLI versions.*
- **How to implement if missing:** Install and **pin** the toolchain in the repo (`required_version`,
  `required_providers`), and configure role assumption / OIDC. For GovCloud, use the matching
  partition endpoints — *verify partition-specific configuration*.
