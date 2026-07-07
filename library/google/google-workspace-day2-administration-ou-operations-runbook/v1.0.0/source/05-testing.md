# Testing & Validation

These procedures prove the day-2 operations practice works before it is handed to BAU. They map
one-to-one to the pass/fail gates in `03-implementation.md` §Validate. Run every test against the
**pilot scope** first; re-run the relevant tests after each Expand batch. Each test states its
procedure and the **expected pass** vs. **fail** signal.

> Convention: tests reference the exact artifact names created during implementation
> (`OU – Corp/Standard-Users – Pilot`, `Baseline – OU Settings – Design`, `Admin Role – Help Desk –
> Corp`, `Alert – … – Enforce`, `Runbook – … – Production`).

---

## T1 — OU tree matches design (supports Gate G1)

- **Procedure:** Run `python ou_policy_assessment.py --output ou-tree-check.json` and compare the
  enumerated OU tree against the Design tree. Confirm each `OU – <path> – Baseline` exists with the
  intended parent.
- **Expected PASS:** every designed OU is present with the correct parent; the pilot users are in
  `OU – Corp/Standard-Users – Pilot` and no one else was moved.
- **FAIL:** a designed OU is missing, mis-parented, or extra users were moved. → Correct the OU
  structure in **Directory → Organizational units** and re-run.

## T2 — Settings baseline applied, zero drift (Gate G1)

- **Procedure:**
  ```
  python config_drift_detector.py --baseline ou-policy-baseline.json --scope Corp/Standard-Users/Pilot
  ```
- **Expected PASS:** the tool reports **0 drift** — every governance-critical setting on the pilot OU
  matches `Baseline – OU Settings – Design` (external sharing, 2SV enforcement, per-service on/off,
  etc.).
- **FAIL:** one or more settings differ (the tool prints `DRIFT: <setting> expected=<x> actual=<y>`).
  → Either correct the live setting to match the baseline, or, if the live value is intentionally
  correct, update `ou-policy-baseline.json` under change control. Re-run until 0 drift.

## T3 — Inheritance behaves as designed

- **Procedure:** Change a setting at a parent OU (in a change window) and confirm a child OU marked
  "inherit" follows it, while a child marked "override" does not. Re-run the drift detector on both.
- **Expected PASS:** inherited children reflect the parent change; overridden children retain their
  baseline value; drift detector remains 0 for both against the updated baseline.
- **FAIL:** an inherit child did not follow, or an override child changed unexpectedly. → Recheck the
  child OU's inherit/override state in the console; reconcile the baseline.

## T4 — Least-privilege delegation (Gate G2)

- **Procedure:** Run `python admin_role_auditor.py --output admin-role-audit-test.csv`. Also, signed
  in **as the pilot help-desk member**, attempt an in-scope action (reset a pilot user's password) and
  an out-of-scope action (change a security policy).
- **Expected PASS:** the auditor shows the pilot help-desk member holding only `Admin Role – Help Desk
  – Corp` and **no super-admin**; the super-admin count matches the known small number. The in-scope
  action succeeds; the out-of-scope action is **denied**.
- **FAIL:** the member has extra privileges/super-admin, or the out-of-scope action succeeds. →
  Tighten the custom role's privileges/scope in **Account → Admin roles** and re-run.

## T5 — Alerts fire on test events (Gate G3)

- **Procedure:** For each `Alert – <condition> – Enforce`, trigger a controlled test event:
  - `Alert – External-Sharing-Spike – Enforce` → externally share a pilot test document.
  - `Alert – Admin-Privilege-Change – Enforce` → assign then remove a test role.
  - `Alert – Suspicious-Login – Enforce` → follow Google's documented test guidance where available
    (**verify in your tenant**; some alerts cannot be safely simulated — confirm via a real prior
    event in logs instead).
- **Expected PASS:** each alert appears in **Security → Alert center** and notifies the security-ops
  group within its expected latency.
- **FAIL:** an alert did not appear or did not notify. → Recheck the alert rule and recipients; confirm
  the alert type is enabled for your edition.

## T6 — Health-check report generates from real data (Gate G3)

- **Procedure:**
  ```
  python health_check_report.py --days 7 --output health-check-test.html
  ```
- **Expected PASS:** the report renders with real Reports API data — login summary, admin-activity
  summary, external-sharing summary, and a top-risk section — for the last 7 days, with no API errors.
- **FAIL:** the tool errors (auth/scope/`403`) or the report is empty. → Confirm the R4 credential has
  the read-only Reports scope and the Reports API is enabled; see troubleshooting.

## T7 — Runbooks executed by delegated role (Gate G4)

- **Procedure:** Using the pilot help-desk role (not super-admin), execute:
  - `Runbook – User Onboarding – Production` on a new pilot test user.
  - `Runbook – User Offboarding – Production` on a departing pilot test user — first as a dry run:
    ```
    python ops_config_helper.py offboard --user pilot.leaver@example.com --dry-run
    ```
    then perform the documented console/API steps.
  - `Runbook – Access Request Handling – Production` for a Shared Drive access request.
  - one incident runbook (e.g. `Runbook – Incident: Data Exposure / Oversharing – Production`).
- **Expected PASS:** each runbook completes with its verification step green, performed **without
  super-admin**, and each touched artifact matches its runbook-named convention.
- **FAIL:** a step requires super-admin, the verification fails, or the runbook is ambiguous. → Fix the
  role scope or the runbook and re-run.

## T8 — Drift detection catches an unplanned change

- **Procedure:** Deliberately change one governed setting on the pilot OU **out of baseline** (e.g.
  turn on external link sharing). Run `config_drift_detector.py` for the pilot scope.
- **Expected PASS:** the detector reports exactly that one drift with `DRIFT: <setting>
  expected=<baseline> actual=<changed>`.
- **FAIL:** the change is not detected. → Confirm the setting is covered by the baseline schema; extend
  the baseline/tool coverage. Revert the test change afterward.

---

## Validation summary

| Gate | Test(s) | Pass condition |
|---|---|---|
| G1 — OU/policy applied | T1, T2, T3 | OU tree matches design; 0 drift vs. baseline; inheritance correct |
| G2 — Least-privilege | T4 | Delegated role only; no unexpected super-admin; out-of-scope denied |
| G3 — Monitoring live | T5, T6 | Every alert fired on its test event; health report renders from real data |
| G4 — Runbooks exercised | T7, T8 | Runbooks completed without super-admin; drift detector catches unplanned change |

All four gates must pass on the pilot before Expand. Re-run T2, T4, and T6 after each expansion batch.
