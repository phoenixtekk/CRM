# Global Requirements — AWS (category-level)

These requirements apply to every solution in the AWS category (foundation and security on Amazon Web
Services). Published once at the category level so listings stay small. Confirm before deploying any AWS
solution. Each entry: Description / Why / Verify / Implement-if-missing.

> AWS changes create real, billable resources across accounts. Everything runs plan/what-if first through
> version control, in a non-production account before production, with least-privilege credentials — never
> long-lived root or admin keys on a laptop.

## G1. AWS account(s) with management/root access to the org
Description: An AWS management (payer) account, or Owner-equivalent rights to create Organizations resources.
Why: Landing-zone, Organizations, SCP, and delegated-admin actions operate at the org/management scope.
Verify: `aws sts get-caller-identity` succeeds; the identity can access AWS Organizations.
Implement: Obtain the management account (or delegated rights) before org-level changes.

## G2. Least-privilege deployment identity (no long-lived root)
Description: An IAM role / IAM Identity Center permission set (or OIDC-federated CI identity) with scoped rights — not root, not static admin keys.
Why: Root and long-lived admin keys are the top AWS breach vector; automation should assume a scoped role.
Verify: Deployments run as an assumed role; root MFA is on and root keys do not exist.
Implement: Create a scoped deployment role / permission set; enable root MFA; delete any root access keys.

## G3. AWS CLI and IaC tooling
Description: AWS CLI v2, Terraform CLI (pinned), and Git installed.
Why: The solutions deliver Terraform + AWS CLI; version drift breaks reproducibility.
Verify: `aws --version`, `terraform version`, `git --version` return supported builds. *Verify current provider/CLI versions.*
Implement: Install and pin the toolchain; record versions in the repo.

## G4. Source control + CI/CD
Description: A Git repository and a pipeline (GitHub Actions / GitLab CI / CodePipeline) with OIDC federation to AWS.
Why: Plan/apply must be reviewed and run through an auditable pipeline, not locally.
Verify: The pipeline can assume an AWS role via OIDC and run `terraform plan`.
Implement: Configure the repo and OIDC trust; scope the CI role.

## G5. Terraform remote state
Description: A remote state backend (S3 + DynamoDB lock, or Terraform Cloud).
Why: Local state is unsafe and unshareable; remote state with locking prevents corruption.
Verify: The state bucket/table (or TFC workspace) exists and is access-controlled and encrypted.
Implement: Provision the S3 state bucket + DynamoDB lock table with encryption and versioning.

## G6. Region and tagging standards
Description: Approved AWS regions, a tagging standard, and naming conventions.
Why: Governance, cost allocation, and SCP/Config rules depend on consistent regions/tags.
Verify: A documented standard exists and is encoded in modules/policy.
Implement: Define the standard; enforce via tag policies and Config rules.

## G7. Identity provider for federation (where required)
Description: Microsoft Entra ID (or another IdP) available to federate AWS IAM Identity Center.
Why: SSO/SCUM federation solutions need the IdP side configured.
Verify: Entra admin access to create an enterprise app (SAML + SCIM). *Verify current IAM Identity Center feature availability.*
Implement: Ensure Entra rights (see the catalog's Entra solutions) before federating.

## G8. Non-production account + change control
Description: A non-production account/OU to validate against, and a production change-approval process.
Why: Every change is validated in non-prod and approved before production apply.
Verify: A non-prod account exists; the pipeline requires approval before prod stages.
Implement: Provision a non-prod account and add manual approval gates. *Production change approval is the customer's operational decision.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.
