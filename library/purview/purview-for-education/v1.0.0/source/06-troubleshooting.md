# 6. Troubleshooting Guide — Microsoft Purview for Education (FERPA)

Symptom → likely root cause → fix. Use **`EDU-Discovery.ps1`** (inventory), **`EDU-Validation.ps1`**
(policy state), **`EDU-Report.ps1`** (activity/matches), and **`EDU-Scope-Health.ps1`** (licensing/
roles) to confirm before and after each fix. Where a capability is **plan-gated or the portal path is
version-dependent, verify your licensing/tenant / against current Microsoft guidance** rather than
assuming.

## A. Licensing & roles

### A capability (advanced DLP, auto-label simulation, records management, premium assessment) isn't visible
- **Plan-gated.** These require **E5 / E5 Compliance** (some are preview). **Fix:** run
  **`EDU-Scope-Health.ps1`**; assign/purchase the licensing (Requirement 2.1), or use the E3-level
  baseline for now. **Verify your licensing/tenant** for preview features.

### "You don't have permission" creating a label / DLP / retention policy
- **Missing Purview role group.** Labels need **Information Protection**; DLP needs **Compliance
  Administrator/Data Administrator**; retention needs **Records Management**. **Fix:** assign the
  least-privilege role group (Requirement 2.2); confirm in **Roles & scopes → Permissions**.

## B. Sensitivity labels

### Pilot users don't see the education labels in Office
- **Label policy not assigned / still propagating.** Publishing via `EDU - Label Policy - Pilot` can
  take time to reach clients. **Fix:** confirm the pilot group is on the policy (**`EDU-Validation.ps1`**);
  wait the publish window; have the user sign out/in.
- **User not in the pilot group.** **Fix:** add them to the pilot group or confirm scope; non-pilot
  users are **not** meant to see the labels yet.

### Applying `EDU - Student Record (FERPA)` doesn't protect the file
- **Label has no protection configured.** A label without encryption/marking classifies but doesn't
  protect. **Fix:** edit the label → set **encryption + content marking** (Requirement 2.5 / Step 2);
  re-apply.
- **Client cache.** **Fix:** wait for the label refresh / restart the Office app.

## C. Sensitive information type (student ID)

### DLP/auto-label misses obvious education-record documents
- **`EDU - Student ID` SIT pattern too narrow / wrong.** **Fix:** in **Data classification → Sensitive
  info types**, test `EDU - Student ID` against real sample formats; broaden the regex/keywords and
  confidence; **`EDU-Discovery.ps1`** confirms the SIT exists.
- **Relying on a built-in "FERPA" SIT that doesn't exist.** There is **no universal FERPA SIT** — you
  must use `EDU - Student ID` + built-in SITs. **Fix:** build/confirm the custom SIT (Step 3).

### Too many false positives
- **Confidence/proximity too loose.** **Fix:** raise the confidence level and require a nearby keyword
  ("student ID", "SID"); increase the instance count; re-test in Test mode before enforcing.

## D. Data Loss Prevention

### DLP isn't blocking external sharing of student records
- **Policy is in Test mode — by design.** In Test, DLP **detects but does not block**. **Fix:** this is
  expected during the pilot; review matches in **`EDU-Report.ps1`**, and only move **Test → Enforce**
  after the pilot passes and change control approves (Implementation Step 9).
- **Location not covered / device not onboarded.** Endpoint DLP needs devices **onboarded**. **Fix:**
  confirm locations in **`EDU-Validation.ps1`**; onboard devices (Requirement 2.3) for endpoint
  coverage.

### DLP is blocking legitimate teaching/registrar work
- **Conditions too broad / enforced too early.** **Fix:** set the policy back to **Test**
  (**`EDU-Validation.ps1`** flags enforcing policies), tune the education-record conditions, and
  re-validate before re-enforcing. Roll back first, tune second.

### No DLP matches at all in Test
- **Conditions don't match your content, or SIT is off.** **Fix:** confirm the rule uses
  `EDU - Student ID` + name/SSN **or** the `EDU - Student Record (FERPA)` label (**`EDU-Validation.ps1`**);
  test with synthetic student-record content (Testing Test 6).

## E. Auto-labeling

### Auto-labeling isn't applying `EDU - Student Record (FERPA)`
- **Still in simulation — by design.** Simulation **labels nothing**. **Fix:** review simulation
  results; enable only after they're accurate (and licensing supports it — **verify your
  licensing/tenant**).

## F. Retention & records

### Retention label isn't available to apply / not appearing on sites
- **Label policy not published to the location / propagation delay.** **Fix:** confirm
  `EDU - Retention - Student Records - Pilot` targets the pilot locations (**`EDU-Validation.ps1`**);
  allow propagation time.

### Wrong retention period / disposition
- **Period was set without the records owner's sign-off.** Retention is a **records determination**.
  **Fix:** correct the label to the **approved** period/disposition; **note that content already
  retained stays retained for the period** even after a label change — engage the records owner. **Do
  not invent periods.**

### Content was deleted that should have been kept (or vice-versa)
- **Disposition/label mismatch with the schedule.** **Fix:** review the label's retain/delete settings
  against the signed-off schedule with records management; use **disposition review** so deletions
  require human sign-off. Escalate as a **records incident** — this is a governance matter, not just a
  config fix.

## G. Audit & evidence

### Label/DLP/retention activity isn't searchable in Audit
- **Audit off, or event still indexing.** **Fix:** confirm Audit is **On** (Purview → **Audit**;
  **`EDU-Discovery.ps1`** reports state); allow indexing latency; confirm **Premium** retention if you
  need older events (licensing).

### Compliance Manager score isn't moving
- **Improvement actions not worked / evidence not attached.** **Fix:** in `EDU - FERPA Posture`, complete
  the improvement actions and attach the configured labels/DLP/retention/audit as evidence.

---
## Escalation checklist
1. `EDU-Scope-Health.ps1` — licensing sufficient, operator holds the right Purview role groups?
2. `EDU-Discovery.ps1` — labels, `EDU - Student ID` SIT, DLP (and mode), retention labels, audit all present?
3. `EDU-Validation.ps1` — DLP in **Test** (nothing accidentally enforcing), label policy targets the pilot, retention period matches the signed-off schedule, DLP conditions reference the education-record signal?
4. `EDU-Report.ps1` — DLP matches/incidents as expected in Test; label usage and retention coverage sane?
5. Still stuck → capture the symptom and **verify against current Microsoft guidance / your tenant** (Purview paths and plan-gating evolve); route **records/legal/privacy determinations** to the governance owners — they are not technical fixes.
