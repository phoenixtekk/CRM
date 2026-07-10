# 3. Implementation — AWS Security Hub & GuardDuty Enablement

Follow these steps in order. You work in the **AWS Management Console** as an assumed least-privilege role (never root), moving between the **management account** (for delegated-admin registration) and the **Security account** (for day-to-day configuration). Every object uses the `<Purpose> – <Scope> – <Stage>` convention from the Overview and is reused in Testing, Troubleshooting, and the scripts. **Do the pilot in a non-production account and one Region before you auto-enable the organization or activate any automated response.**

> Portal navigation paths, standard names, control IDs, GuardDuty finding types, and pricing change and vary by Region/partition. Use the console search bar if a path has moved, and *verify current standards, controls, finding types, and pricing before enabling at scale.*

---

## Stage A — Assess

### Step A1. Baseline the current state
1. Sign in as your assumed deployment role. Run `AWSSEC-Discovery.sh` (read-only). It reports, per account and Region: whether a GuardDuty detector exists, whether Security Hub is enabled, which standards are on, and the current delegated-administrator registrations.
2. Note the **management account ID**, the **Security account ID** (R2), your chosen **aggregation Region** (R4), and the **pilot non-production account ID**.

### Step A2. Confirm decisions are recorded
1. Confirm the Region scope (R5), the GuardDuty protection plans + standards selection (R6), and the notification target + response-action policy (R7) are documented. These drive the configuration variables.

---

## Stage B — Configure (delegated admin + org enablement, plan-first)

### Step B1. Register the delegated administrators (management account)
1. In the **management account**, open **Amazon GuardDuty -> Settings -> Accounts** (or **Organizations** view) and register the **Security account** as the GuardDuty **delegated administrator**.
2. Open **AWS Security Hub -> Settings -> General** and register the **Security account** as the Security Hub **delegated administrator**.
3. Registration enables trusted access for both services. From here, switch to the **Security account** for the remaining steps.

### Step B2. Enable org-wide with Terraform (plan-first)
1. Use `AWSSEC-guardduty-securityhub.tf` (AWS provider). Set the input variables: aggregation Region, in-scope Regions, protection plans, standards (CIS + FSBP), and **auto-enable = true**.
2. Run **plan-first** through your pipeline/remote state (Global Requirements G4/G5): `terraform plan`. Confirm it will:
   - Create/enable the GuardDuty **organization configuration** with **auto-enable for new accounts**.
   - Enable **Security Hub** with **auto-enable**, subscribe the **CIS AWS Foundations** and **AWS FSBP** standards.
   - Configure the **finding aggregator** pointing at the aggregation Region.
3. **Apply against the pilot non-production account and aggregation Region only** for the pilot (target the pilot resources / use a pilot workspace). Full org auto-enable is applied in Expand after the gates pass.

### Step B3. Prepare the response path in preview (gated, disabled)
1. Use the **separate**, gated `AWSSEC-response.tf`. It defines:
   - EventBridge rule `SecFindings-HighSeverity – Org – Response` matching high/critical Security Hub findings.
   - SNS topic `SecFindings-Notify – Org – Prod` (subscribe your R7 endpoint).
   - Optional Lambda `SecFindings-AutoRespond – Org – Gated`.
2. Keep the gating variable **`enable_response = false`** and **`enable_auto_action = false`** for the pilot. With these false, `terraform plan` shows the rule/topic/Lambda as **created but disabled** (rule state DISABLED, Lambda not targeted). Apply only the notification scaffolding; **do not** enable the rule or the automated action yet.

---

## Stage C — Pilot (non-production account, one Region)

### Step C1. Confirm enablement and generate a finding
1. In the **Security account**, aggregation Region, open **GuardDuty** and confirm the pilot account's detector is **enabled**.
2. Generate GuardDuty **sample findings** (**GuardDuty -> Settings -> Sample findings**, or `aws guardduty create-sample-findings`) in the pilot account.
3. Open **Security Hub -> Findings** and confirm the sample GuardDuty findings and the CIS/FSBP control findings appear.

### Step C2. Confirm aggregation
1. In **Security Hub -> Settings -> Regions** (finding aggregation), confirm the aggregation Region shows linked Regions and that findings from the pilot Region are visible in the aggregation Region's queue.

### Step C3. Preview the response path (no live action)
1. Temporarily enable **only the notification** by setting `enable_response = true` while keeping `enable_auto_action = false`, plan-first, and apply in the pilot.
2. Re-trigger a high-severity sample finding and confirm the SNS notification arrives at your endpoint. The Lambda automated action stays **off**.

Proceed to the Testing Guide and pass every gate before Expand.

---

## Stage D — Validate

Run the Testing Guide (`05-testing.md`): detector enabled, standards producing findings, GuardDuty findings reaching Security Hub, cross-Region/cross-account aggregation, the high-severity notification firing, and suppression rules working. Record pass/fail. Do not expand until all gates pass.

---

## Stage E — Expand (org-wide) and activate response

### Step E1. Auto-enable the organization
1. With the gates passed, apply `AWSSEC-guardduty-securityhub.tf` at full scope (auto-enable across all member accounts and in-scope Regions), plan-first and after change approval, one Region/wave at a time if you prefer.
2. Re-run `AWSSEC-Validate.sh` after each wave to confirm every member account has a detector and Security Hub enabled with the standards on.

### Step E2. Tune the queue with suppression rules
1. Triage the initial burst of findings. For known-accepted controls, create Security Hub **automation (suppression) rules** named `Suppress-<control> – <scope> – Prod` (e.g. `Suppress-CIS-1.20 – Sandbox – Prod`) so the queue reflects real risk. Record the reason for each suppression.

### Step E3. Activate the response path (after approval)
1. Only after notification is proven and the response-action policy (R7) is approved, decide per finding type whether to move from **notify-only** to **notify + automated action**.
2. If automated action is approved, set `enable_auto_action = true` for the **specific, low-risk finding types** you have agreed (e.g. isolate on a confirmed pattern), plan-first, and apply. Keep the Lambda's actions least-privilege and logged.

> Whether automated remediation may act on production, and for which finding types, is the customer's operational/change-control decision — activate it deliberately, per finding type, with a rollback and full logging. Never enable blanket auto-remediation on first rollout.
