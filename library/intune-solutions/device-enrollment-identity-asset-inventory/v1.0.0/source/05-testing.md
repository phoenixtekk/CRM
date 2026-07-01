# 5. Testing Guide — Device Enrollment, Identity Association & Asset Inventory

Run after the pilot enrolls (Implementation Step 9) and after each reconciliation cycle.

## Test 1 — Automatic enrollment works
**Do:** Join a pilot Windows device to Entra ID with a scoped user; wait for the policy cycle.
**Expected:** The device appears in Intune → **Devices → All devices** within minutes; status shows
managed.

## Test 2 — Enrollment restrictions enforce
**Do:** Attempt to enroll a platform/ownership type you set to **Block**
(`Enrollment Restriction – Supported Platforms – Production`).
**Expected:** Enrollment is refused for the blocked type; allowed types enroll normally.

## Test 3 — Enrollment status page gates first sign-in
**Do:** Run an Autopilot pilot device through OOBE.
**Expected:** `Enrollment Status Page – Corporate Windows – Production` shows progress and blocks the
desktop until setup completes.

## Test 4 — Primary user is correct
**Do:** Intune → **Devices → All devices →** pilot device → **Properties → Primary user**; or run
`ENROLLID-Validation.ps1`.
**Expected:** Primary user = the daily user for assigned devices; **None** for shared devices in
`Enrollment – Shared Devices – Production`.

## Test 5 — Inventory reconciles
**Do:** Run `ENROLLID-Report.ps1 -ExpectedCsv <list>`.
**Expected:** A reconciliation showing matched devices and gaps — stale, duplicate, missing primary
user, and not-yet-enrolled.

## Test 6 — Discovery posture is clean
**Do:** Run `ENROLLID-Discovery.ps1`.
**Expected:** Enrollment method, restriction summary, and primary-user coverage reported with no
unexpected blockers.

## Test 7 — Remediation is safe and effective
**Do:** Run `ENROLLID-Remediation.ps1` (it runs `-WhatIf` by default); review the planned changes,
then re-run with `-WhatIf:$false` on an approved item.
**Expected:** With `-WhatIf` it only previews; when committed it fixes the targeted primary-user /
stale record without touching anything else.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; reconciliation (Test 5) shows pilot devices matched with correct owners |
| **Production pass** | Tests 1–6 pass for the broad scope; remediation (Test 7) verified safe before fleet use |
