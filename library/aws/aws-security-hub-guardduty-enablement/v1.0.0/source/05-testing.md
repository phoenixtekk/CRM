# 5. Testing — AWS Security Hub & GuardDuty Enablement

Run every gate below in the **non-production pilot account** and the **aggregation Region** before you auto-enable the organization or activate any automated response. Each gate has an explicit pass/fail. Reference the automation scripts by name where noted.

## Gate 1 — GuardDuty detector is enabled and analyzing
Procedure: In the Security account (aggregation Region) open **GuardDuty**. Confirm the pilot account's detector is enabled. Optionally run `AWSSEC-Validate.sh`.
Pass: The pilot account shows an **enabled** detector; `AWSSEC-Validate.sh` reports the detector enabled with the intended protection plans.
Fail: No detector, or disabled. Re-check delegated-admin registration and the Terraform apply (Troubleshooting T1).

## Gate 2 — Security Hub standards are producing findings
Procedure: Open **Security Hub -> Security standards**. Confirm **CIS AWS Foundations** and **AWS FSBP** are enabled and show a score/controls.
Pass: Both standards are enabled and controls are evaluating (pass/fail findings and a security score appear).
Fail: A standard is not enabled or shows no controls. See Troubleshooting T2. *Verify the standard is available in your Region/partition.*

## Gate 3 — GuardDuty findings reach Security Hub
Procedure: Generate GuardDuty **sample findings** in the pilot account (**GuardDuty -> Settings -> Sample findings** or `aws guardduty create-sample-findings`). Open **Security Hub -> Findings**.
Pass: The GuardDuty sample findings appear in the Security Hub findings queue (normalized to ASFF).
Fail: GuardDuty shows findings but Security Hub does not. Check that the GuardDuty integration is enabled in Security Hub (Troubleshooting T3).

## Gate 4 — Cross-Region / cross-account aggregation works
Procedure: In **Security Hub -> Settings -> Regions**, confirm the aggregation Region with linked Regions. Confirm a finding raised in a linked Region (or a second pilot account) is visible in the aggregation Region's queue. Run `AWSSEC-Report.sh`.
Pass: Findings from other Regions/accounts appear in the single aggregation queue; `AWSSEC-Report.sh` shows findings grouped across accounts/Regions.
Fail: Findings are stranded per-Region/account. Re-check the finding aggregator and delegated-admin scope (Troubleshooting T4).

## Gate 5 — High-severity notification fires (response path preview)
Procedure: With `enable_response = true` and `enable_auto_action = false`, re-trigger a **high/critical** sample finding. Watch your R7 SNS-subscribed endpoint.
Pass: A notification for the high-severity finding arrives; the EventBridge rule `SecFindings-HighSeverity – Org – Response` shows an invocation to `SecFindings-Notify – Org – Prod`. The Lambda automated action did **not** run.
Fail: No notification, or the automated action ran while it should have been off. See Troubleshooting T5.

## Gate 6 — Suppression rules remove known noise
Procedure: Create a Security Hub automation rule (e.g. `Suppress-CIS-1.20 – Sandbox – Prod`) for a known-accepted control finding. Refresh the findings queue.
Pass: Matching findings move to suppressed/archived and no longer clutter the active queue; the rule and its reason are recorded.
Fail: Findings remain active. Check the rule's filter criteria and order (Troubleshooting T6).

## Gate 7 — Automated action is safe and least-privilege (only if activating)
Procedure: Only if you are activating automated remediation (Stage E3): in the pilot, enable `enable_auto_action = true` for a **single, low-risk** finding type and trigger it. Review CloudTrail/Lambda logs.
Pass: The Lambda `SecFindings-AutoRespond – Org – Gated` performs only the agreed action, logs it, and holds least-privilege permissions; nothing else is touched.
Fail: The action is too broad, unlogged, or over-permissioned. Do not proceed to production until fixed (Troubleshooting T5).

---
When the applicable gates pass in the pilot, proceed to Expand (org-wide auto-enable, then — only after approval — activating the response path per finding type). Re-run Gate 1 and Gate 4 after each Expand wave.
