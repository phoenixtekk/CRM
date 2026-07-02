# 5. Testing Guide — Intune Device Configuration & Policy Troubleshooting

Each test is a **pass/fail gate** that confirms a specific layer's fix actually worked. Run the test
for the branch you resolved in the Diagnostic Playbook (document 3). A fix isn't "done" until its
gate passes on both the affected device and — where relevant — a known-good device.

## Test 1 — Assignment reaches the device (Branch A)
**Do:** Intune → **Devices → Configuration →** policy → **Device status**; and run
**`INTCFG-Discovery.ps1`**.
**Pass:** The affected device now appears in the policy's device list (no longer **Not applicable**),
and Discovery lists the device's group under the policy's **Included** assignments with no
overriding **Exclude**.
**Fail:** Device still absent, or still in an Excluded group → return to Branch A.

## Test 2 — Filter includes the device (Branch D)
**Do:** Devices → **Filters →** `INTCFG-Filter-Windows-Corporate` → **Preview devices (Evaluate)**.
**Pass:** For an **Include**-mode filter the affected device **is** in the matched set (for
**Exclude** mode it is **not**).
**Fail:** Device on the wrong side of the filter → return to Branch D and correct the rule/mode.

## Test 3 — Device has checked in (Branch E)
**Do:** Devices → **All devices →** device → **Last check-in**; and run **`INTCFG-Validation.ps1`**
on the device.
**Pass:** Last check-in is **recent** (after the assignment change) and Validation reports MDM
enrollment **healthy**.
**Fail:** Stale check-in or unhealthy enrollment → return to Branch E; run
**`INTCFG-Remediation.ps1 -WhatIf:$false`** to force sync.

## Test 4 — Setting applied on the device (Branch B)
**Do:** Policy → **Per-setting status** for the device; confirm the actual value on the device
(registry/UI/`INTCFG-Validation.ps1`).
**Pass:** The setting shows **Succeeded** **and** the observed value on the device matches the policy.
**Fail:** Succeeded in Intune but wrong value → suspect conflict (Test 5); error code → Test 6.

## Test 5 — No conflict on the setting (Branch C)
**Do:** Run **`INTCFG-Report.ps1`**; check the policy's **Per-setting status**.
**Pass:** The setting appears in **exactly one** assigned policy (no overlap in the report) and shows
no **Conflict** state.
**Fail:** Setting still owned by more than one assigned policy → return to Branch C and remove the
duplicate.

## Test 6 — CSP error cleared (Branch F)
**Do:** Policy → **Per-setting status →** the previously failing setting; confirm on the device via
**`INTCFG-Validation.ps1`** / the MDM report.
**Pass:** The setting no longer reports an **error code**; it is **Succeeded** or a justified **Not
applicable**.
**Fail:** Same or new error code → recheck the code meaning in Branch F.

## Test 7 — Known-good device still healthy (regression)
**Do:** Confirm the comparison device that was already **Succeeded** stays **Succeeded** after your
change; run **`INTCFG-Report.ps1`** tenant-wide.
**Pass:** No previously-working device regressed; no new conflicts introduced.
**Fail:** A change broke another device/policy → review the assignment/filter/conflict you edited.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Isolation confirmed** | The single failing layer is identified; the matching test above **passes** on the affected device |
| **No regression** | Test 7 passes — no previously-working device or policy was broken by the fix |
| **Report clean** | `INTCFG-Report.ps1` shows the target setting owned by one policy, device status **Succeeded**, no conflict |
