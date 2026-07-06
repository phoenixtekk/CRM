# 5. Testing & Validation — Regulated Google Workspace: Assured Controls, ITAR & DFARS

Test each control **against the required posture** (the target region and policy legal/compliance
approved in requirement 2.2 / Implementation Step 0), on the **pilot scope first**, with an explicit
**pass/fail** gate before expansion. Testing confirms the **technical configuration and evidence** —
it does **not** constitute a legal determination of ITAR/DFARS compliance (that sign-off is
legal/compliance's, per Implementation Step 6.4).

> Run the read-only scripts (`GWREG-Discovery.ps1`, `GWREG-Validation.ps1`, `GWREG-Report.ps1`) to
> gather evidence; confirm the same state in the Admin console. Where a check depends on
> add-on/edition, treat a "cannot read" result as **"verify in your tenant,"** not a pass.

## Test 1 — Data-region residency
- **What:** Data at rest for the pilot OU is set to the required region (e.g. **United States**).
- **How:** Admin console → **Data → Compliance → Data regions** shows the pilot OU on the required
  region; **Data-regions advanced reporting** confirms in-region residency. `GWREG-Validation.ps1`
  reports residency = target.
- **Pass:** Region = required target for all pilot users; advanced reporting confirms.
- **Fail:** Region is No Preference/wrong, or reporting shows out-of-region data → remediate (Step 7),
  allowing for Google's migration schedule.

## Test 2 — Access Management policy
- **What:** The required Access-Management policy (**U.S. staff only** or **CJIS / IRS 1075-authorized
  only**) is applied to the pilot OU, and the OU is Assured Controls-licensed.
- **How:** Admin console → **Data → Compliance → Access Management** shows the required policy on the
  pilot OU. `GWREG-Validation.ps1` reports the policy vs. required.
- **Pass:** Policy matches the approved requirement; OU is licensed.
- **Fail:** Policy is **No preference**/wrong, or OU is unlicensed (policy silently does not apply) →
  remediate / fix licensing.

## Test 3 — Access Approvals
- **What:** "Require Google staff to request approval before viewing data" is enabled for the pilot OU.
- **How:** Admin console → **Data → Compliance → Access Approvals** shows the box checked;
  `GWREG-Validation.ps1` reports enabled.
- **Pass:** Enabled for the pilot scope.
- **Fail:** Unchecked → enable and re-test.

## Test 4 — Access Transparency evidence
- **What:** Google-staff access is logged and reviewable.
- **How:** Admin console reporting → **Access Transparency log events** returns events (or is confirmed
  active). If a support interaction occurred, it appears with the Access-Approvals approval.
- **Pass:** Access Transparency is active and queryable; approvals are visible.
- **Fail:** No access-transparency surface / not queryable → **verify in your tenant** and confirm the
  add-on entitlement.

## Test 5 — Client-Side Encryption (only if relied upon)
- **What:** CSE is enabled for the required services on the controlled OU (if legal relies on the ITAR
  e2ee carve-out).
- **How:** Admin console → **Data → Compliance → Client-side encryption**; controlled services show CSE
  on for the OU. `GWREG-Validation.ps1` reports CSE state.
- **Pass:** CSE on for the required services/OU, key service connected.
- **Fail / N/A:** If legal does not require CSE, mark **N/A**; if required and off → enable and re-test.

## Test 6 — Compliance-evidence exports
- **What:** Policy-compliance log events, data-regions advanced reporting, and compliance data exports
  are available and routed to the evidence destination (requirement 2.8).
- **How:** Confirm the exports/log events are produced; `GWREG-Report.ps1` compiles the coverage
  report.
- **Pass:** Evidence is produced and retained per requirement.
- **Fail:** Missing evidence surface → enable the bundled feature (verify entitlement).

## Test 7 — Functional / no-regression on the pilot
- **What:** Controlled-data pilot users can still work; cross-region processing changes and CSE have not
  broken essential workflows.
- **How:** Pilot users confirm Gmail/Drive/Docs/Calendar/Meet function; note any lost functionality from
  disabling cross-region processing or from CSE.
- **Pass:** Users productive; any tradeoffs are known and accepted by the stakeholders.
- **Fail:** Broken workflow → adjust advanced-settings/CSE scope and re-test.

## Test 8 — Coverage & sign-off gate (pilot exit)
- **What:** All required controls pass across the pilot **and** legal/compliance has reviewed the
  evidence and signed off.
- **How:** `GWREG-Validation.ps1` = all required controls pass; `GWREG-Report.ps1` coverage attached;
  legal/compliance sign-off recorded.
- **Pass:** Proceed to Expand (Implementation Step 8).
- **Fail:** Remediate and re-validate; do **not** expand on a technical pass without the legal sign-off.

---
## Pass/fail summary
| # | Test | Pass criterion |
|---|---|---|
| 1 | Data-region residency | Region = required target; reporting confirms |
| 2 | Access Management | Required policy applied; OU licensed |
| 3 | Access Approvals | Enabled for pilot scope |
| 4 | Access Transparency | Active, queryable; approvals visible |
| 5 | CSE (if relied upon) | On for required services/OU, or N/A |
| 6 | Compliance-evidence exports | Produced and retained |
| 7 | Functional / no-regression | Pilot users productive; tradeoffs accepted |
| 8 | Coverage & sign-off gate | All required pass + legal/compliance sign-off |
