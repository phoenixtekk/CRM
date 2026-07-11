# 3. Implementation Guide — Technical Blocker Mitigation: Defender for Cloud

Follow these steps **in order**. This is a **diagnostic loop**, not a build: you assess to pinpoint the blocker, apply one targeted documented fix (change-approved, since enabling paid plans has cost impact), re-test the affected scope, and only then resume the rollout. All scripts are **read-only**; every *fix* is a manual step you apply deliberately. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Assess (pinpoint) → Configure (fix) → Pilot (re-test affected scope) → Validate (confirm working) → Expand (resume rollout). Enabling paid plans and remediation stay change-approved and customer-owned throughout.

## Naming (set once, reuse verbatim)
- Affected subscription/connector scope: `MDC Blocker Triage – Affected Scope – Diagnose`
- Support bundle output: `MDC Support Bundle – <case> – Escalate`
- Discovery snapshot file: `MDC-blocker-discovery.json`
- Coverage snapshot file: `MDC-coverage.json`

## Step 1 — Assess: pinpoint the blocker (read-only)
1. Sign in with `Connect-AzAccount` to the correct tenant as **Security Reader / Reader**.
2. Run `TBMMDC-Discovery.ps1`. It captures the signal chain per subscription in `MDC-blocker-discovery.json`: **Defender plan states** (`Get-AzSecurityPricing` — On/Free per plan), **auto-provisioning / agent** settings, **security connectors** (AWS/GCP) and their status, and whether the **Microsoft cloud security benchmark** policy is assigned and assessments exist.
3. Assemble `MDC Blocker Triage – Affected Scope – Diagnose` from the subscriptions/connectors showing the symptom.
4. Read the snapshot top-down against the signal chain (Overview §"How signal actually works") and identify the **earliest broken link**:
   - Plan shows Free / will not enable → **plan-enablement blocker**
   - Plan On but machines report no data → **coverage blocker**
   - Connector not connected / not syncing → **AWS/GCP connector blocker**
   - Coverage fine but Secure Score / assessments empty → **policy/assessment blocker**

## Step 2 — Assess: analyze agent / agentless coverage (read-only)
1. Run `TBMMDC-Coverage.ps1`. It reports, for the affected scope, which machines are covered by an agent/extension vs agentless scanning, and flags **coverage gaps** (machines a paid plan covers that report no data).
2. Note whether the gap is an **agent provisioning** problem (auto-provisioning off / workspace unreachable) or an **agentless** enablement problem — they have different fixes.

## Step 3 — Configure: apply the one targeted fix (manual, documented, change-approved)
Apply **only** the fix for the blocker you identified. Each is a deliberate, change-approved manual step — the scripts never make these changes.

- **Plan not enabling:** In **Defender for Cloud → Environment settings → [subscription] → Defender plans**, set the required plan to **On** and save. If it reverts, check for an **Azure Policy / deny** or a management-group setting overriding it, and the registering **resource providers**. *Enabling a paid plan has cost impact — change-approved.* *Verify current plan names/pricing.*
- **Agent / agentless coverage gap:** Turn on **auto-provisioning** of the required agent/extension (or fix the workspace linkage the agent points at), or enable **agentless scanning** in the plan settings. Confirm the affected machines pick up the extension. (See `global-requirements-defender.md` G7 for the workspace.)
- **AWS / GCP connector failure:** In **Environment settings → Add/select the connector**, re-run onboarding — correct the **CloudFormation** (AWS) role/permissions or the **Terraform / gcloud** service account (GCP), and confirm the connector returns to **connected / syncing**. *Verify current multicloud onboarding requirements.*
- **Recommendations not populating:** Confirm the **Microsoft cloud security benchmark** policy assignment exists and is evaluating at the affected scope; trigger/await a compliance evaluation. Confirm the registering resource providers and that assessments have had time to populate.

## Step 4 — Pilot: re-test the fix on the affected scope only
1. Apply the fix to the subscription/connector in `MDC Blocker Triage – Affected Scope – Diagnose` only — not the whole estate.
2. Give plan enablement, provisioning, connector sync, and assessment evaluation time (these populate over hours).
3. Move to validation before touching any other subscription/connector.

## Step 5 — Validate: confirm the blocker is cleared
1. Run `TBMMDC-Validate.ps1`. It re-checks the affected scope: plan **On**, coverage reporting, connector **connected**, and assessments/recommendations present — pass/fail per link.
2. Re-run `TBMMDC-Coverage.ps1` to confirm the coverage gap closed.
3. Run `TBMMDC-Report.ps1` for the before/after evidence (including Secure Score movement where relevant).
4. Complete the **Testing Guide** for the blocker class before expanding.

## Step 6 — Expand: resume the stalled rollout
1. With the affected scope green, enable the plan / provisioning / connector across the remaining subscriptions and connectors in waves (change-approved).
2. Re-run `TBMMDC-Validate.ps1` after each wave and compare with `TBMMDC-Report.ps1`.
3. If a subscription re-introduces the symptom, return to Step 1 for that scope — policy or provider registration can differ per subscription.

## Step 7 — Escalate (only if it is a service issue, not your config)
1. If the plan is set On, provisioning/agentless is enabled, the connector role is correct, and the policy is assigned, but the blocker persists, it may be a Microsoft service issue.
2. Run `TBMMDC-SupportBundle.ps1` to assemble `MDC Support Bundle – <case> – Escalate` — the discovery snapshot, the coverage analysis, the affected scope, and timestamps.
3. Open a Microsoft support case, attach the bundle, and reference the escalation criteria in the Troubleshooting Guide. *Incident-response and cost decisions remain the customer's; this is a service-support escalation.*

---
### Order of operations
`Assess (discovery + coverage) → identify earliest broken link → apply the one change-approved fix → re-test the affected scope → validate working → resume rollout → escalate with a bundle only if it is a service issue`
