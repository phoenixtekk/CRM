# 5. Testing Guide — Azure Security Baseline & Governance

Run after the audit-stage assignment applies (Implementation Step 7) and again after moving to deny (Step 8) and after each expansion cycle. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names.

## Test 1 — Guardrail initiative assigned (audit)
**Do:** `portal.azure.com` → **Policy** → **Assignments** → confirm `Security Baseline Guardrails – Pilot MG – Audit` at the pilot scope; or run `AZSEC-Validation.ps1`.
**Expected:** The assignment is present at the management-group node with every guardrail effect set to **Audit**.

## Test 2 — Compliance state populated
**Do:** **Policy** → **Compliance** → open the assignment (run a scan if needed); or run `AZSEC-Report.ps1`.
**Expected:** A per-policy compliant/non-compliant breakdown appears — the audit picture is visible, nothing is blocked.

## Test 3 — RBAC is least privilege
**Do:** Run `AZSEC-Validation.ps1`; or **Access control (IAM)** → **Role assignments** on the pilot subscription.
**Expected:** The custom role `Resource Operator LeastPriv – Pilot Sub – Prod` exists and is assigned; standing **Owner** assignments are reduced to only those justified.

## Test 4 — Secure-config baseline present
**Do:** Run `AZSEC-Report.ps1`; or inspect the initiative's included policies.
**Expected:** Encryption-required, public-access-restricted, secure-transfer, allowed-locations, and allowed-SKU controls all appear in the baseline.

## Test 5 — Defender for Cloud posture
**Do:** **Microsoft Defender for Cloud** → **Secure score** and **Recommendations**; or run `AZSEC-Report.ps1`.
**Expected:** A secure score is reported for the pilot subscription and top recommendations are listed; regulatory-compliance mapping is visible.

## Test 6 — Audit does not block (audit stage)
**Do:** Create a resource that violates a guardrail (e.g. a storage account with public blob access) in the pilot scope.
**Expected:** Creation **succeeds** but the resource shows as **non-compliant** — audit reports, it does not block.

## Test 7 — Deny blocks (after the gate)
**Do:** After Step 8, re-attempt the same violating-resource creation.
**Expected:** Creation is **blocked** by `Security Baseline Guardrails – Pilot MG – Deny`; a compliant resource still creates successfully.

## Test 8 — Drift report
**Do:** Run `AZSEC-Report.ps1`.
**Expected:** A clear governance-posture report — assignments, per-policy compliance, secure score, top recommendations, and drift versus the captured baseline.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Audit pass (pre-deny)** | Tests 1–6 pass; the audit picture is understood and exemptions are in place |
| **Deny pass** | Test 7 passes — a violating resource is blocked and a compliant one still creates |
| **Expand pass** | Tests 1–5, 8 pass on the broader scope before the next expansion |
