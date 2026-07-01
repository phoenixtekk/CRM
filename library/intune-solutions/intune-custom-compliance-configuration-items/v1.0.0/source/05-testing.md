# 5. Testing Guide — Intune Custom Compliance & Configuration Items (Scripted)

Run after the pilot policy applies (Implementation Step 9) and after any change to the detection
script, JSON rule, or config item.

## Test 1 — Script + rule pairing is valid
Do: On your workstation run `CUSTCOMP-Validation.ps1 -ScriptPath <script.ps1> -RulePath <rule.json>`.
Expected: Reports valid JSON, and every setting name in the rule is produced by the script (no mismatch).

## Test 2 — Detection script runs on device
Do: On a pilot device run `CUSTCOMP-Discovery.ps1`.
Expected: The device-side values the detection script reads are shown (registry value, app version) as valid JSON.

## Test 3 — Config item applied
Do: Intune → `Devices → Configuration →` `SecuritySetting – Config Item – Pilot` → Device status.
Expected: Pilot devices show Succeeded; the target setting is present on the device.

## Test 4 — Custom compliance evaluates
Do: Intune → `Devices → Compliance →` `Custom Compliance – Windows – Pilot` → Device status.
Expected: Pilot devices show a custom-compliance result (compliant when the rule passes).

## Test 5 — A failing rule turns the device noncompliant
Do: On a test device, make one checked value fail (e.g. remove the setting), sync, and re-evaluate.
Expected: The device turns noncompliant on the custom rule and the user sees the remediation message.

## Test 6 — Conditional Access effect
Do: With the CA policy in Report-only, review `Sign-in logs → Conditional Access` for a noncompliant device.
Expected: The report-only result shows the "require compliant device" grant would block that device.

## Test 7 — Fleet report
Do: Run `CUSTCOMP-Report.ps1`.
Expected: A per-device custom-compliance status across the assigned group.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–4 pass; Test 5 shows a failing rule turns the device noncompliant with the message |
| Broad pass | Tests 4, 6, 7 pass; the Conditional Access effect is confirmed before moving CA to On |
