# 6. Troubleshooting — AWS Security Hub & GuardDuty Enablement

Symptom -> cause -> fix for the failures you are most likely to hit. Work in the non-production pilot account and the aggregation Region; never troubleshoot by enabling broad automated actions in production.

## T1. A member account has no GuardDuty detector after enablement
Symptom: `AWSSEC-Discovery.sh` / the console shows some accounts without an enabled detector.
Cause: Delegated administration was not registered, auto-enable is off, or an SCP blocks the service-linked role.
Fix: In the management account confirm the **Security account** is registered as the GuardDuty delegated administrator, and in the delegated admin confirm **auto-enable for the organization** is on (set via `AWSSEC-guardduty-securityhub.tf`). Check that no SCP denies `guardduty:*` or the service-linked role creation. Re-run the plan/apply and `AWSSEC-Validate.sh`.

## T2. A Security Hub standard won't enable or shows no controls
Symptom: CIS AWS Foundations or AWS FSBP is missing, greyed out, or shows zero controls.
Cause: The standard/control set is not available in that Region/partition, Security Hub isn't fully enabled there, or Config (which many controls depend on) is off.
Fix: Confirm Security Hub is enabled in that Region and that **AWS Config** is recording (many controls require Config). *Verify the standard and its controls are available in your Region/partition* — availability differs between commercial and GovCloud. Re-enable the standard via Terraform.

## T3. GuardDuty findings don't appear in Security Hub
Symptom: GuardDuty shows findings but the Security Hub findings queue does not include them.
Cause: The GuardDuty-to-Security Hub integration is not accepted/enabled, or the accounts are managed by different delegated admins.
Fix: In **Security Hub -> Integrations**, confirm **Amazon GuardDuty** is enabled (accepting findings). Ensure the **same Security account** is the delegated administrator for **both** services so findings flow into the same hub. Re-trigger a sample finding (Gate 3).

## T4. Findings are stranded per-Region or per-account
Symptom: You must switch Region/account to see findings; there is no single queue.
Cause: The finding aggregator isn't configured, the aggregation Region has no linked Regions, or cross-account collection isn't set in the delegated admin.
Fix: In **Security Hub -> Settings -> Regions** (in the aggregation Region), configure the **finding aggregator** and link the in-scope Regions. Confirm the delegated admin manages all member accounts. Re-run `AWSSEC-Report.sh` (Gate 4).

## T5. The response path misbehaves (no notification, or the action ran when it shouldn't)
Symptom: A high-severity finding produced no SNS notification, or the Lambda automated action ran while it was supposed to be off.
Cause: The EventBridge rule is disabled or its pattern doesn't match; the SNS subscription is unconfirmed; or `enable_auto_action` was left true.
Fix: Confirm the rule `SecFindings-HighSeverity – Org – Response` is **enabled** (`enable_response = true`) and its event pattern matches high/critical Security Hub findings. Confirm the SNS subscription on `SecFindings-Notify – Org – Prod` is **confirmed** (recipients must click the confirmation email). For a runaway action, set `enable_auto_action = false`, plan-first, apply, and review the Lambda's CloudTrail logs. Keep the Lambda least-privilege.

## T6. Suppression rule doesn't mute the findings
Symptom: Findings you created a suppression rule for are still in the active queue.
Cause: The automation-rule filter criteria don't match the finding fields, or rule ordering/precedence is wrong.
Fix: Re-check the automation rule's criteria against the actual finding's fields (control ID, resource, account). Confirm the rule is enabled and ordered correctly. Name it to convention (`Suppress-<control> – <scope> – Prod`) and record the reason. Re-test (Gate 6).

## T7. Terraform plan wants to recreate detectors/hubs you already had
Symptom: `terraform plan` shows it will create GuardDuty detectors or Security Hub accounts that already exist (from a prior manual enablement).
Cause: Pre-existing, manually enabled resources are not in Terraform state, so Terraform plans to create its own and may collide.
Fix: Import the existing detector/hub into Terraform state (`terraform import`) rather than recreating, or disable the manual resources and let Terraform own them under the delegated-admin model. Reconcile the R8 baseline before org-wide apply. Always review the plan first.

## T8. Unexpected cost after enabling at scale
Symptom: GuardDuty/Security Hub spend is higher than expected after org-wide enablement.
Cause: High-traffic accounts, many enabled protection plans, or high finding-ingestion volume across many Regions.
Fix: Review which **protection plans** are on and whether they match each account's workloads; disable plans you don't need. Confirm your Region scope (R5) is intentional. *Verify current pricing per Region/partition* and use AWS cost tooling to attribute spend by account/service.
