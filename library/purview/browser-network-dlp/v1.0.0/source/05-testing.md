# 5. Testing Guide — Browser & Network DLP (Microsoft Purview)

Run after building the readiness assessment and after each configuration step. Every test is safe
(read-only or a `-WhatIf` preview) except the deliberate **sensitive-upload attempt on a pilot device**,
which is expected and controlled. Validate on `Browser & Network DLP Pilot Ring – Stage1` **in
simulation/test mode** before enforcing anything tenant-wide.

## Test 1 — Endpoint DLP is licensed and available
**Do:** Run `DLPBROWSER-Assess-Readiness.ps1`; compare against `Billing → Licenses` and confirm
**Data Loss Prevention → Endpoint DLP settings** appears in the Purview portal (verify path).
**Expected:** An Endpoint DLP–bearing SKU (E5 / E5 Compliance / E5 IP&G) is reported present, and the
Endpoint DLP settings surface is visible — browser & network DLP is available on this plan.

## Test 2 — Devices are onboarded and browsers are covered
**Do:** Run `DLPBROWSER-Get-EndpointHealth.ps1`; on a pilot device confirm the Microsoft Purview browser
extension is enabled in Chrome/Firefox and Edge native coverage applies.
**Expected:** Pilot-ring devices report onboarded to Purview; the extension is active in Chrome/Firefox;
Edge is confirmed natively covered. Any gap is recorded as a hand-off item, not silently ignored.

## Test 3 — Policy dry-run makes no changes
**Do:** Run `DLPBROWSER-New-DlpPolicy.ps1 -WhatIf`; afterward run
`Get-DlpCompliancePolicy -Identity 'Browser & Network DLP – Devices – Pilot'`.
**Expected:** The dry-run prints the exact `New-DlpCompliancePolicy`/`New-DlpComplianceRule` it *would*
run and the reverse command; the policy does **not** yet exist (or is unchanged) — `-WhatIf` changed
nothing.

## Test 4 — Policy is created in simulation/test mode (not enforcing)
**Do:** After `-Commit -Mode TestWithoutNotifications`, run `DLPBROWSER-Test-Validation.ps1`.
**Expected:** The policy exists with `Mode = TestWithoutNotifications`, scoped to the **Devices**
location and the pilot ring, with the rule conditioned on the intended labels/SITs — it is evaluating,
**not blocking or notifying** users.

## Test 5 — Sensitive upload to a restricted domain is detected in simulation
**Do:** From a pilot device, upload sensitive **test** content (matching the policy condition) to a
domain in `Unsanctioned & Personal Cloud – Domain Group` through a covered browser.
**Expected:** In simulation the upload is **allowed to proceed** (test mode doesn't block) but is
**recorded** — it surfaces in `Data classification → Activity explorer` and via
`DLPBROWSER-Report-Activity.ps1` as a would-be match against the domain group.

## Test 6 — Non-sensitive upload and sanctioned destination do not match
**Do:** From a pilot device, upload **non-sensitive** content, and upload sensitive test content to a
**sanctioned** destination not in the domain group.
**Expected:** Neither produces a policy match — the condition (labels/SITs) and the destination scope
(domain group) are working, so the policy isn't over-matching.

## Test 7 — Unallowed browser control steers correctly
**Do:** On a pilot device, attempt the sensitive upload from a browser designated **unallowed** (no
extension coverage).
**Expected:** The unallowed-browser control behaves per the design (access to sensitive items steered/
prevented in that browser), confirming coverage comes only from Edge / extension-equipped browsers.

## Test 8 — Evidence is captured in the audit log
**Do:** Run `DLPBROWSER-Report-Activity.ps1` over the test window; cross-check the Purview audit search
(`Audit → Search`, verify path).
**Expected:** `Browser & Network DLP – Egress – Report` lists the endpoint egress events (would-be
blocks/warns/audits) with device, destination, and action — the control is evidenced and defensible.

## Test 9 — Enforcement transition is controlled
**Do:** Only after Tests 1–8 pass on the ring: run `DLPBROWSER-New-DlpPolicy.ps1 -Enforce -WhatIf`, then
`-Enforce`; escalate the domain group's action from Audit to Warn/Block per design.
**Expected:** The policy moves to `Mode = Enable`; a subsequent sensitive upload is **warned (override +
justification)** or **blocked** per the destination's action — enforcement matches what simulation
predicted, with no surprises.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Simulation pass** | Tests 1–8 pass on `Browser & Network DLP Pilot Ring – Stage1` in **test/simulation** mode: licensed, devices onboarded + browsers covered, policy created in test mode, sensitive uploads detected (not over-matching), unallowed-browser steering works, evidence captured |
| **Enforcement pass** | Test 9 passes: after stakeholder sign-off, the policy moves to enforce and the escalated Warn/Block actions behave exactly as simulation predicted, expanded ring-by-ring |
