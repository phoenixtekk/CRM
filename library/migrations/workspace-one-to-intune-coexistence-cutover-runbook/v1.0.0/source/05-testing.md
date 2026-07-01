# 5. Testing Guide — Workspace ONE to Intune Coexistence & Cutover Runbook

Run these tests as the `Go/No-Go Checklist – Cohort – Validate`. They apply **per cohort**: once
before cutover (the pre-cutover gate, Implementation Step 4) and again after cutover (the validate
gate, Implementation Step 7). A cohort only proceeds when every gate in the relevant stage passes;
any failure triggers the `Rollback Plan – Cohort – Validate`.

## Pre-cutover gate (before Step 5)

### Test 1 — Cohort group is correct
**Do:** Entra → **Groups →** the cohort group → **Members**; or run `WS1COEX-Validation.ps1`.
**Expected:** Membership matches the intended cohort exactly — no extra or missing devices/users.

### Test 2 — Conditional Access is cohort-scoped
**Do:** Entra → **Protection → Conditional Access**; check every compliance/enrollment policy.
**Expected:** Each such policy includes the **cohort group**, not **All users**. No tenant-wide
"require compliant device" is active during coexistence.

### Test 3 — Target enrollment channel active
**Do:** Confirm the relevant connector/cert/token shows **Active** for the cohort's platform; run `WS1COEX-Validation.ps1`.
**Expected:** Apple APNs / ABM-ADE, managed Google Play, or Windows automatic enrollment is **Active**.

### Test 4 — No double-targeting for the cohort
**Do:** Compare Intune app/profile assignments for the cohort against still-active Workspace ONE assignments `[WS1 — see VMware docs]`.
**Expected:** The same app/profile/certificate is not delivered by both platforms to this cohort at once.

## Post-cutover gate (after Step 5)

### Test 5 — Devices are Intune-managed and compliant
**Do:** Run `WS1COEX-Report.ps1` for the cohort, or Intune → **Devices → All devices**.
**Expected:** Cohort devices are enrolled in Intune and report **compliant**.

### Test 6 — No longer dual-managed
**Do:** Run `WS1COEX-Report.ps1`; review the management-state column.
**Expected:** Cohort devices show **Intune-only** — not dual-managed (Workspace ONE assignment/enrollment removed) `[WS1 — see VMware docs]`.

### Test 7 — No Conditional Access lockout
**Do:** With a pilot user in the cohort, confirm sign-in to a Conditional-Access-protected app succeeds; check Entra → **Sign-in logs**.
**Expected:** The compliant Intune device satisfies the cohort-scoped policy; no unexpected block.

### Test 8 — Rollback proven (pilot cohort only)
**Do:** On the pilot cohort, run `WS1COEX-Remediation.ps1 -WhatIf` then execute the rollback once, and confirm with `WS1COEX-Report.ps1`.
**Expected:** The cohort returns to Workspace ONE management with no user lockout; state matches pre-cutover.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pre-cutover go** | Tests 1–4 pass for the cohort |
| **Post-cutover go** | Tests 5–7 pass for the cohort |
| **Pilot complete** | Tests 1–8 pass, including a proven rollback (Test 8) |
| **No-go → rollback** | Any gate fails → execute `Rollback Plan – Cohort – Validate`, then diagnose before retry |
