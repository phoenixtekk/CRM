# 5. Testing — Security Optimization Assessment: Defender for Endpoint

Because this is a **read-only** assessment, "testing" means two things: proving the assessor truly has **read-only** access (and no write access), and proving the **numbers the report shows are accurate** (they reconcile with the Defender portal). Run these gates in order; each has an explicit **pass/fail**.

## Gate 1 — Read-only access proven (run `SOAMDE-Validate.ps1`)
**Procedure:** Run `SOAMDE-Validate.ps1` with the assessor identity.
**Pass:** It reports success on all of — Graph connect with read scopes; MDE machine list readable; a trivial advanced-hunting query (`DeviceInfo | take 1`) returns; and it confirms **no write/manage scope** is present on the token.
**Fail:** Any read fails (fix access per R2/R3) **or** a write scope is detected (the assessor is over-privileged — reduce to Security Reader before proceeding; an assessment must not hold write access).

## Gate 2 — Discovery completeness (run `SOAMDE-Discovery.ps1`)
**Procedure:** Run discovery against the scope file; inspect the run folder.
**Pass:** Raw outputs exist for every area — devices/onboarding, next-gen protection, EDR block mode, ASR, tamper protection, web/network protection, delivery policies, exposure/Secure Score — and the device count is within a small margin of **Assets → Devices** in the portal.
**Fail:** An area file is empty or the device count is far from the portal. An empty area usually means a missing read permission or that the feature is unlicensed — record which, and re-run after fixing (an unlicensed feature is itself a finding, not a test failure).

## Gate 3 — Coverage denominators are real (run `SOAMDE-Coverage.ps1`)
**Procedure:** Run coverage with the **expected device count** (R4).
**Pass:** Onboarding coverage is expressed as a fraction of the *expected* population (not just of already-onboarded devices), and the gap list names the missing/inactive devices. ASR/tamper coverage percentages are produced with explicit device lists.
**Fail:** Coverage is computed against onboarded devices only (denominator wrong) — supply the expected count and re-run, or onboarding gaps will be understated.

## Gate 4 — Scoring is defensible (run `SOAMDE-Assess.ps1`)
**Procedure:** Run the scoring pass; open the scorecard CSV.
**Pass:** Every check has a **Pass/Partial/Fail/N-A** result, a **severity** on each non-pass, the **baseline name** stamped in, and the weighted posture score computes. N-A is used (not Fail) for genuinely unlicensed/inapplicable features.
**Fail:** Checks are unscored, severities missing, or unlicensed features scored as Fail rather than N-A (flag them as N-A findings instead).

## Gate 5 — Report reconciles with the portal (run `SOAMDE-Report.ps1`)
**Procedure:** Generate the report, then spot-check the **top three** findings against the portal.
**Pass:** Each spot-checked finding matches the portal (e.g. an ASR rule the report shows as "Audit" reads Audit in the endpoint security policy; a device the report shows as "Inactive" shows Inactive under Devices). Findings are sorted High → Low with evidence and a remediation pointer.
**Fail:** A spot-checked finding does not match the portal — investigate before delivery (usually a stale cache or a scope mismatch; re-run discovery). A findings report must be trustworthy to be actionable.

## Gate 6 — Repeatability (trend)
**Procedure:** Re-run the full sequence against the same scope file into a new dated run folder.
**Pass:** The two runs are comparable (same checks, same baseline), so the posture score can be trended and remediation progress is visible.
**Fail:** Scope or baseline drifted between runs — pin them in the scope file so trends are valid.

> These gates test the **assessment**, not the tenant's security. A low posture score is a *successful* assessment (it found real gaps); the failure conditions above are about the assessment's own accuracy and read-only guarantee.
