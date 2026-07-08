# 5. Testing & Validation Guide — Financial / FINRA Communications Compliance (Microsoft Purview)

Run these after configuring the guardrails (Step 2), building the policy in simulation (Steps 4–5),
exercising the review workflow (Step 6), and configuring the evidence layer (Step 7) — and again after
each tuning change and **before** any expansion. Every test is **safe and read-only or contained to the
pilot group**; the point is to prove the three pillars — **lexicons (detection)**, **review (workflow)**,
and **evidence (retention/recordkeeping)** — plus **privacy** and **role separation** work before broad
rollout. Use test communications inside the **`FINRA Supervised – Pilot`** population **only**.
**Outcomes remain a supervisory-principal / Compliance determination — these tests validate the
mechanism, not the verdict.**

Each test states **Do · Expected · On fail**. Record the result of each in the pilot sign-off.

---

## A. Role separation and privacy (guardrails)

### Test 1 — Role separation is in place
- **Do:** Run `CCFIN-Discovery.ps1`; review the `FINRA Supervision Roles – Evidence` snapshot.
- **Expected:** Policy-builders (**Admin**) are separated from designated principals (**Analysts**) and
  investigators (**Investigators**); **Viewers** are oversight-only; **no reviewer supervises
  themselves**. No one is silently both Admin **and** Analyst/Investigator unless Compliance explicitly
  accepted it.
- **On fail:** Correct membership (Implementation Step 2) before proceeding.

### Test 2 — Privacy option is in effect
- **Do:** Portal → `Settings → Communication Compliance`; confirm the agreed **privacy option**
  (pseudonymized usernames if required). Open a surfaced item as a reviewer.
- **Expected:** The review experience reflects the agreed setting; the supervised population **excludes**
  `FINRA Excluded – Privacy`.
- **On fail:** Set the privacy option / fix scope.

## B. Scope (supervised population)

### Test 3 — Supervised population is the approved set and exclusions hold
- **Do:** Run `CCFIN-EvidenceCheck.ps1` (or `CCFIN-Report.ps1`) and inspect the policy's supervised
  users/groups and exclusions.
- **Expected:** Scope equals the approved `FINRA Supervised – Pilot` (**not "everyone"**); members of
  `FINRA Excluded – Privacy` are not supervised.
- **On fail:** Tighten scope (Implementation Step 2).

### Test 4 — Policy is correctly composed (lexicons attached)
- **Do:** Run `CCFIN-Validation.ps1`; review the policy/rule inventory for
  `FINRA Supervision – Pilot – Simulation` / `FINRA Conduct Rule – Pilot`.
- **Expected:** The policy is scoped to the pilot group, has the intended **designated-principal
  reviewers**, the selected **regulated-conduct classifiers**, the **`FINRA Lexicon – Conduct`**
  dictionary, the sensitive info types, the conditions, and the **risk-based sampling percentage**, and
  is in **simulation/pilot** mode.
- **On fail:** Correct via `CCFIN-Configuration.ps1` (re-run with `-Commit`).

## C. Lexicons (detection)

### Test 5 — A regulated-conduct message surfaces (true positive)
- **Do:** From a pilot user, send a test communication that should match a selected classifier and/or a
  `FINRA Lexicon – Conduct` term (e.g. a guarantee/"can't lose" phrase or a selling-away term). Allow
  processing time.
- **Expected:** A matching item appears for the policy in Communication Compliance, visible to the
  assigned designated principals.
- **On fail:** Check classifier/lexicon/condition selection and channel coverage.

### Test 6 — A clean message does NOT surface (false-positive check)
- **Do:** From a pilot user, send an ordinary, non-violating business message.
- **Expected:** No item is raised.
- **On fail:** Tune the lexicon/classifiers/conditions (Implementation Step 8) — do **not** widen scope.

### Test 7 — All in-scope channels are covered
- **Do:** From a pilot user, send matching test content across each in-scope channel (Teams, Exchange,
  Viva Engage, and any connected source). Confirm data connectors are healthy in the portal.
- **Expected:** Matches surface from each in-scope channel; no in-scope channel is silently missing.
- **On fail:** Fix the missing channel / connector (Requirement 2.5) before expanding.

## D. Review (workflow)

### Test 8 — A designated principal can work an item end-to-end
- **Do:** As an **Analyst** designated principal, open a surfaced test item; examine it in context; apply
  a **remediation action** — tag (compliant/questionable/non-compliant), add a note, resolve, notify, or
  **escalate**.
- **Expected:** The principal can triage and action the item; the action is recorded.
- **On fail:** Check Analysts role membership and reviewer assignment.

### Test 9 — Escalation reaches an Investigator; Viewer sees no content
- **Do:** Escalate the test item to an **Investigator**; separately sign in as a **Viewer**.
- **Expected:** The Investigator receives the escalation with context; the Viewer sees reports/dashboards
  but **no message content**.
- **On fail:** Correct Investigator/Viewer role membership.

### Test 10 — The reviewer trail is defensible
- **Do:** Run `CCFIN-Report.ps1` for `FINRA Supervision Rollup – Evidence`; confirm reviewer identity,
  timestamp, and disposition are captured for the test items, and cross-check the unified audit log.
- **Expected:** Who reviewed what, when, and with what disposition is recorded — the reasonable-
  supervision evidence.
- **On fail:** Confirm auditing is enabled and reviewer actions are being logged.

## E. Evidence (retention / recordkeeping)

### Test 11 — Supervised communications are retained for the approved period
- **Do:** Run `CCFIN-EvidenceCheck.ps1`; review coverage of `FINRA Comms Records – 17a-4` against the
  supervised scope.
- **Expected:** The supervised communications are covered by retention for the **Compliance/Records-
  approved** period across the in-scope workloads.
- **On fail:** Extend retention coverage (Implementation Step 7) under Compliance/Records approval.

### Test 12 — Immutability is in effect where required (tamper-evident)
- **Do:** Run `CCFIN-EvidenceCheck.ps1`; check whether `FINRA Comms Records – 17a-4` has
  **Preservation Lock** (`RestrictiveRetention`) where the records decision requires it.
- **Expected:** Where required, the retention policy is **locked** (cannot be shortened/disabled/deleted)
  and the tool reports it as immutable. Where **not** required, it is intentionally unlocked.
- **On fail:** If the records decision requires immutability and it is missing, apply the lock **only**
  with written Compliance/Records approval (Step 7); **never** apply it to satisfy a test.

### Test 13 — Report pack is examiner-ready
- **Do:** Run `CCFIN-Report.ps1` to produce the supervision-activity rollup and the policy/role/retention
  inventory.
- **Expected:** A coherent evidence pack — policy configuration, role separation, supervised scope,
  review activity, and retention/immutability status — suitable to demonstrate the program.
- **On fail:** Resolve the missing element and re-run.

---

## Pilot exit criteria (all must pass before expansion)
1. Role separation and privacy in effect (Tests 1–2).
2. Supervised scope is the approved set; exclusions hold (Tests 3–4).
3. True positives surface; clean messages don't; all in-scope channels covered (Tests 5–7).
4. Designated-principal review, escalation, and Viewer-no-content all work; reviewer trail is defensible
   (Tests 8–10).
5. Evidence retention covers the approved period; immutability is in effect where required; the report
   pack is examiner-ready (Tests 11–13).

*Passing these validates the **mechanism and the evidence**. Whether any surfaced communication is a
**violation**, and what **action** follows, remain determinations for the firm's designated supervisory
principals, Compliance, and Legal.*
