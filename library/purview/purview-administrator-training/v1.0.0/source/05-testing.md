# 5. Testing Guide — Microsoft Purview Administrator Training

Run these checks after the labs are configured (Implementation Phases C–G) and again after teardown
(Step 16). Each check is a **validation gate** — a lab is only "passed" when its gate is met, and the
training is only "complete" when the tenant returns to the Step 3 baseline. Most gates are exercised by
`OPSTRAIN-LabValidate.ps1`; `OPSTRAIN-CompetencyReport.ps1` rolls them into the evidence report.

> **Training, not determination.** These tests confirm the *technical* state (object exists, correct
> mode, correct scope). Whether an *illustrative* taxonomy/period/scope would be *correct in
> production* is a records/legal/privacy determination — out of scope for the training gate.

> **Verify in your tenant.** Where a feature is unlicensed, its lab is a read-only walkthrough and its
> gate is "the trainee can navigate and explain it," not "the object exists."

## Test 1 — Readiness: connectivity, scope, and feature visibility
**Do:** Run `OPSTRAIN-Readiness.ps1`.
**Expected (PASS):** `Connect-IPPSSession`/`Connect-MgGraph` succeed; the report names the tenant, shows
`TRAIN-Pilot-Users` present, and lists the readable Purview feature areas. Any warned (unreadable/
unlicensed) feature is noted so its lab is planned as a walkthrough.

## Test 2 — Scope safety: training group contains only test accounts
**Do:** In **Entra ID → Groups** (or `Get-MgGroup` / `Get-MgGroupMember`), inspect `TRAIN-Pilot-Users`.
**Expected (PASS):** The group exists and contains **only** training/test accounts — **no real user.**
This gate protects every downstream lab.

## Test 3 — Lab 1 Labels: label published to the training scope only
**Do:** `OPSTRAIN-LabValidate.ps1 -Lab Labels`. Cross-check **Information Protection → Labels / Label
policies**.
**Expected (PASS):** `TRAIN-Label-Confidential` exists and `TRAIN-LabelPolicy-Pilot` publishes it to
`TRAIN-Pilot-Users` **only**; a test account sees the label in Office, no real user does.

## Test 4 — Lab 4 Auto-labeling: exists and is in SIMULATION (never enabled)
**Do:** `OPSTRAIN-LabValidate.ps1 -Lab AutoLabel`. Cross-check the policy `Mode`
(`Get-AutoSensitivityLabelPolicy`).
**Expected (PASS):** `TRAIN-AutoLabel-Sim` exists in a **simulation/test** mode and produced results;
**no item was actually labeled.** **FAIL if** the policy is enabled/enforcing.
*(Unlicensed → walkthrough; gate is "trainee can explain simulation vs enable.")*

## Test 5 — Lab 2 DLP: exists in TEST mode and enforced nothing
**Do:** `OPSTRAIN-LabValidate.ps1 -Lab DLP`. Cross-check `Get-DlpCompliancePolicy` `Mode`.
**Expected (PASS):** `TRAIN-DLP-PII-Sim` exists with `Mode` = a **test/simulation** value
(`TestWithoutNotifications`/`TestWithNotifications`), matched the synthetic content, and **blocked
nothing.** **FAIL if** `Mode` = `Enable` — a training DLP policy must never be left enforcing.

## Test 6 — Lab 3 Retention: exists, scoped, illustrative period
**Do:** `OPSTRAIN-LabValidate.ps1 -Lab Retention`. Cross-check `Get-RetentionCompliancePolicy` /
`Get-RetentionComplianceRule`.
**Expected (PASS):** `TRAIN-Retention-Pilot` (and `TRAIN-RetLabel-Illustrative`) exist, scoped to the
training locations, carrying the **illustrative** period; the trainee states the **real** schedule is a
records/legal determination.

## Test 7 — Modules 5–6: privacy controls and role separation (no real data)
**Do:** Observe the trainee in the **Insider Risk** and **Communication Compliance** walkthroughs.
**Expected (PASS):** The trainee enables **pseudonymization/anonymization**, demonstrates **separated**
analyst/investigator/admin roles, targets **no real employees**, and states that **case outcomes are
HR/legal's determination.** **FAIL if** any real user is targeted or role separation is bypassed.

## Test 8 — Module 7 Audit: search returns and exports
**Do:** `OPSTRAIN-LabValidate.ps1 -Lab Audit`. Cross-check the exported `TRAIN-Audit-Search` output.
**Expected (PASS):** An audit search over the window returns rows and exports; the trainee explains
Audit Standard vs Premium retention. *(No audit data → confirm the window/activity and licensing.)*

## Test 9 — Module 8 eDiscovery: training custodian on hold, search returns
**Do:** In **eDiscovery → `TRAIN-eDiscovery-Case`**, confirm the training custodian's hold status and run
a search.
**Expected (PASS):** The **training** custodian (a `TRAIN-Pilot-Users` account) shows **on hold** (allow
up to 24h) and a search returns; **no real custodian** is held. The trainee states a real hold is a
legal determination.

## Test 10 — Competency roll-up: every attempted lab PASSes or is documented
**Do:** `OPSTRAIN-LabValidate.ps1 -Lab All` then `OPSTRAIN-CompetencyReport.ps1`.
**Expected (PASS):** Every attempted lab shows **PASS**, or an explicit documented reason (e.g.
"unlicensed — walkthrough"). The report is the evidence the team is trained.

## Test 11 — Teardown: tenant returns to the Step 3 baseline
**Do:** After teardown, `OPSTRAIN-LabValidate.ps1 -Lab All` and compare to the `OPSTRAIN-LabBaseline.ps1`
baseline CSV.
**Expected (PASS):** **No `TRAIN-` object remains** except any retention object still inside its removal
window (logged). The tenant matches the baseline — training left it clean.

---

### Pass/fail summary
| # | Gate | PASS condition |
|---|---|---|
| 1 | Readiness | Connected; scope present; feature areas listed |
| 2 | Scope safety | `TRAIN-Pilot-Users` = test accounts only |
| 3 | Labels | Label published to training scope only |
| 4 | Auto-labeling | Exists in **simulation**, nothing labeled |
| 5 | DLP | Exists in **test** mode, nothing enforced |
| 6 | Retention | Exists, scoped, illustrative period |
| 7 | IRM/Comms | Pseudonymization + role separation, no real data |
| 8 | Audit | Search returns and exports |
| 9 | eDiscovery | Training custodian on hold, search returns |
| 10 | Competency | All attempted labs PASS or documented |
| 11 | Teardown | Tenant matches baseline |

Any FAIL is a stop-and-fix before the trainee is credited with that competency; the enforcement modes
(Tests 4 and 5) are the most important — a training policy must **never** be left enabled/enforcing.
