# 5. Testing Guide — Microsoft Purview for Education (FERPA)

Run after the labels, DLP (Test), retention, and Compliance Manager posture are configured
(Implementation Steps 2–8), on the **pilot scope**, and again after each expansion wave. Back each test
with **`EDU-Discovery.ps1`** (inventory), **`EDU-Validation.ps1`** (policy-state checks), and
**`EDU-Report.ps1`** (activity/matches). **No test requires enforcing anything** — DLP stays in **Test**
and auto-labeling in **simulation** until the pilot passes.

## Test 1 — Compliance licensing + roles are sufficient
**Do:** Run **`EDU-Scope-Health.ps1`**.
**Expected:** The tenant exposes the capabilities each step needs (E5/E5 Compliance where required);
the operator holds the least-privilege Purview role groups. Any plan-gated/preview gap is flagged
**"verify your licensing/tenant."**

## Test 2 — The education label taxonomy exists and is published to the pilot
**Do:** Run **`EDU-Discovery.ps1`**; in an Office app signed in as a **pilot** user, open the
**Sensitivity** menu.
**Expected:** `EDU - Public`, `EDU - Internal`, `EDU - Student Record (FERPA)`, `EDU - Highly
Confidential` exist and are **offered to pilot users** (label policy `EDU - Label Policy - Pilot`
assigned to the pilot group); non-pilot users do **not** yet see them.

## Test 3 — Applying the Student Record label protects the file
**Do:** As a pilot user, apply `EDU - Student Record (FERPA)` to a test document.
**Expected:** The label's **protection applies** — content marking appears and (if configured)
encryption restricts access per the label. Downgrade prompts for justification if so configured.

## Test 4 — The `EDU - Student ID` SIT matches education-record content
**Do:** Run **`EDU-Discovery.ps1`** (lists custom SITs); in **Data classification → Sensitive info
types**, test `EDU - Student ID` against sample student-ID values and a non-matching value.
**Expected:** Real student-ID values **match** at the expected confidence; obvious non-matches do
**not**. False-positive rate is acceptable to the data owner.

## Test 5 — DLP is in Test mode with the education-record conditions
**Do:** Run **`EDU-Validation.ps1`**.
**Expected:** `EDU - FERPA Student Records - DLP - Pilot` exists, **mode = Test** (not Enforce), across
the intended locations, with conditions detecting education-record content (`EDU - Student ID` + name/SSN,
or the `EDU - Student Record (FERPA)` label).

## Test 6 — DLP catches a simulated education-record leak (in Test, blocks no one)
**Do:** As a pilot user, attempt to **share externally** a test document containing sample student-ID +
name content (synthetic data only). Then run **`EDU-Report.ps1`**.
**Expected:** The action **is not blocked** (Test mode) but a **policy tip / incident** is generated and
appears in the DLP activity/report — proving the rule *would* catch a real leak before you enforce.

## Test 7 — Auto-labeling simulation is accurate (if configured)
**Do:** If Step 6 was done, review the **auto-labeling simulation** results in the portal.
**Expected:** The simulation flags education-record documents for `EDU - Student Record (FERPA)` with
acceptable accuracy and **labels nothing** — you review before enabling.

## Test 8 — Retention label exists with the approved period and is published
**Do:** Run **`EDU-Validation.ps1`**; check **Data Lifecycle / Records Management → Retention labels**.
**Expected:** `EDU - Student Education Record` exists with the **records owner's approved** period and
disposition, published via `EDU - Retention - Student Records - Pilot` to the pilot locations. (The
period is a **records determination** — this test confirms it matches the signed-off schedule, not that
it is "correct" legally.)

## Test 9 — Audit is logging label/DLP/retention activity
**Do:** Run **`EDU-Discovery.ps1`** (audit state); in Purview → **Audit**, search for recent label/DLP
events from Tests 3 and 6.
**Expected:** Audit is **On** and the label-apply and DLP events are searchable — the evidence trail
exists (Premium retention if licensed).

## Test 10 — Compliance Manager posture is scored with evidence
**Do:** Open **Compliance Manager → `EDU - FERPA Posture`**.
**Expected:** The assessment shows a **score** with improvement actions; the configured labels/DLP/
retention/audit map to actions and evidence is attachable — a defensible, measured posture.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Foundation pass** | Tests 1–4 pass (licensing/roles; labels published to pilot; label protects; Student-ID SIT accurate) |
| **Protection pass** | Tests 5–8 pass (DLP in Test with correct conditions; catches simulated leak; auto-label simulation accurate; retention per approved schedule) |
| **Evidence pass** | Tests 9–10 pass (audit logging; Compliance Manager scored with evidence) |

> Do not expand beyond the pilot or move **DLP Test → Enforce** / labels tenant-wide until all three
> gates pass **and** change control approves. Re-run Tests 5–10 after each expansion wave.
