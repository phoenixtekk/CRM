# 5. Testing Guide — Workspace ONE to Intune: Policy & Compliance Translation

Run these after the mapped policies apply to the pilot (Implementation Step 8) and again after each
expansion wave. The parity gate (Test 5) is the go/no-go for cutover.

## Test 1 — Source inventory is complete

Do: Run `WS1POL-Discovery.ps1` against the Workspace ONE source export and compare the normalized
list to the source console.

Expected: Every in-scope configuration profile and compliance policy, per platform, appears in the
inventory. No source object is missing.

## Test 2 — Mapped configuration deployed per platform

Do: In Intune, open `Devices > Configuration` and check each `Mapped Config - <Platform> - Pilot`
policy's Device status; or run `WS1POL-Report.ps1`.

Expected: Each platform's mapped configuration policy shows Succeeded on the pilot devices.

## Test 3 — Mapped compliance deployed per platform

Do: In Intune, open `Devices > Compliance`, check each `Mapped Compliance - <Platform> - Pilot`
policy's Device status; confirm pilot devices evaluate as expected.

Expected: Pilot devices report compliant under the translated rules, matching the source policy's
intent.

## Test 4 — Gap register fully decided

Do: Review `Policy Translation - All Platforms - Gap Register`.

Expected: Every source setting row has a decision (map / substitute / defer / accept-gap) with an
owner. No row is undecided.

## Test 5 — Parity gate (per platform)

Do: Run `WS1POL-Validation.ps1` to compare source inventory against deployed Intune policy per
platform.

Expected: For the platform under test, no setting is reported missing; effective values match; the
compliance policy gates the same access. This is the cutover gate.

## Test 6 — Conditional Access actually gates

Do: With a pilot device deliberately made noncompliant against a translated rule, attempt a
Conditional-Access-protected resource.

Expected: Access is blocked while noncompliant and restored when compliant — the compliance signal
reaches Conditional Access.

## Test 7 — No policy conflicts

Do: Run `WS1POL-Report.ps1` (per-device configuration state) and review for settings in conflict.

Expected: No setting reports a conflict on pilot devices. If any does, `WS1POL-Remediation.ps1`
(run with `-WhatIf` first) identifies the conflicting assignment.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 4 pass; Test 5 (parity) passes for the platform; Test 6 confirms gating |
| Expand pass | Tests 2, 3, 5, 7 pass for each wave on `Policy Scope - Production - Stage` |
