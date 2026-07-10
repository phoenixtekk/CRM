# 2. Requirements — AWS Security Hub & GuardDuty Enablement

The AWS category prerequisites (management/root access, least-privilege deployment identity, AWS CLI + Terraform toolchain, source control + CI/CD with OIDC, remote state, region/tagging standards, an identity provider, and a non-production account with change control) are published once in **Global Requirements — AWS** and are not repeated here. Confirm those first. Below are the prerequisites **specific to enabling GuardDuty and Security Hub org-wide**. Each item: Description / Why required / How to verify / How to implement if missing.

## R1. AWS Organizations enabled with all features
Description: The environment must be an AWS organization with **all features** enabled.
Why required: Delegated administration and org-wide auto-enable for GuardDuty and Security Hub require Organizations with all features.
How to verify: `aws organizations describe-organization` returns `"FeatureSet": "ALL"`; the console shows "All features."
How to implement if missing: Enable all features from the management account, or deploy the AWS landing-zone solution first. *One-way action approved by the org owner.*

## R2. A dedicated Security account to be the delegated administrator
Description: A member account (not the management account) designated to run security operations — the **Security account**.
Why required: AWS best practice is to delegate GuardDuty and Security Hub administration out of the management account; the delegated admin auto-enables and manages all members.
How to verify: The account exists in Organizations and you can register it as a delegated administrator for both services.
How to implement if missing: Create/designate a Security account (often in a "Security" OU) before configuring the services.

## R3. Trusted access / service-linked permissions for both services
Description: GuardDuty and Security Hub must be allowed to operate across the organization (trusted access), and each account gets a service-linked role.
Why required: Org-wide enablement and cross-account finding collection depend on trusted access being enabled from the management account.
How to verify: In the management account the delegated-admin registration for `guardduty.amazonaws.com` and `securityhub.amazonaws.com` succeeds; service-linked roles are created on enablement.
How to implement if missing: Register the delegated administrators (which enables trusted access) per the Implementation Guide; do not block the service-linked roles with SCPs.

## R4. A chosen finding-aggregation Region
Description: One AWS Region selected as the **aggregation Region** where all Security Hub findings are consolidated.
Why required: A single aggregation Region gives one queue for all accounts/Regions; picking it up front avoids re-linking later.
How to verify: The Region is in your approved-Regions list (Global Requirements G6) and Security Hub is available there. *Verify current Region/partition availability.*
How to implement if missing: Choose an aggregation Region aligned to data residency before enabling standards.

## R5. Region scope decision (which Regions to protect)
Description: A decision on which Regions GuardDuty and Security Hub run in (all enabled Regions vs a defined subset).
Why required: Both services are per-Region; cost and coverage depend on how many Regions you enable. Attackers use unused Regions, so unused Regions still need at least detection.
How to verify: A documented list of in-scope Regions exists.
How to implement if missing: The customer's security owners decide the Region scope; default to enabling detection in all Regions you can operate and centralizing findings in the aggregation Region.

## R6. GuardDuty protection-plan and standards selection (customer decision)
Description: A decision on which GuardDuty protection plans (S3, EKS, Malware, Lambda, RDS, etc.) and which Security Hub standards/controls to enable.
Why required: Each protection plan and standard has cost and coverage implications; enabling everything blindly creates noise and spend.
How to verify: A short decision record lists the protection plans and standards (CIS AWS Foundations, AWS FSBP at minimum) and any intentionally disabled controls with reasons.
How to implement if missing: The customer's security owners select the plans/standards. *This scope-and-cost determination is the customer's decision; the solution implements the selection, not the policy.* *Verify current protection plans, standards, controls, and pricing.*

## R7. Notification target and response-action policy (for the gated response)
Description: An email/endpoint to subscribe to the SNS topic, and a decision on whether the response is **notify-only** or **notify + automated action**.
Why required: The response path routes high-severity findings; you need a destination, and automated actions must be an explicit, approved choice.
How to verify: A distribution list/endpoint exists for notifications; a decision record states whether automated remediation is permitted and for which finding types.
How to implement if missing: Provide the notification endpoint. Keep automated actions **disabled** until validated in preview and approved. *Whether automated remediation may act on production is the customer's operational/change-control decision.*

## R8. Baseline of current security-service state
Description: A read of whether GuardDuty/Security Hub are already partially enabled anywhere, and any existing standards/detectors.
Why required: Enabling on top of partial existing configuration can conflict; you must know the starting point.
How to verify: Run the provided `AWSSEC-Discovery.sh` to report detector/hub state, standards, and delegated-admin status per account/Region.
How to implement if missing: Generate the baseline before Configure; reconcile any pre-existing detectors/hubs into the delegated-admin model.

---
Once R1–R8 are confirmed alongside the AWS Global Requirements, proceed to the Implementation Guide. Everything is done non-production first, and the automated-response path stays in preview until validated.
