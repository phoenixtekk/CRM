# 5. Testing Guide — Device Compliance Policies

Run after the pilot policy applies (Implementation Step 8) and after each production wave.

## Test 1 — Policy applied
**Do:** Intune → **Devices → Compliance →** `Compliance - Windows - Pilot` **→ Device status**.
**Expected:** Pilot devices listed; evaluation completed (no **Error**).

## Test 2 — Compliant device reports Compliant
**Do:** On a healthy pilot device, run `DCP-Validation.ps1`; check Intune → device → **Compliance**.
**Expected:** Device is **Compliant**; all required rules pass.

## Test 3 — Noncompliant device is caught
**Do:** On a test device, disable the firewall (or use a non-encrypted test VM) and force a sync.
**Expected:** The device flips to **Not compliant** for the failing rule after evaluation.

## Test 4 — Actions fire
**Do:** Leave a device noncompliant past the grace period.
**Expected:** The user receives the noncompliance email; the device is marked **Not compliant** on schedule.

## Test 5 — No policy conflicts
**Do:** Run `DCP-ConflictCheck.ps1`, and review Intune → device → **Device compliance** for conflicts.
**Expected:** No conflicting compliance settings from multiple policies.

## Test 6 — Conditional Access sees the signal (if configured)
**Do:** With a Report-only CA policy requiring compliant device, review **Entra → Sign-in logs → Conditional Access**.
**Expected:** Compliant devices satisfy the control; noncompliant devices would be blocked (report-only shows "would block").

## Test 7 — Tenant report
**Do:** Run **`DCP-TenantReport.ps1`**.
**Expected:** A compliance breakdown (Compliant / Not compliant / In grace) for the pilot group.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 (and 6 if CA configured) pass for the pilot group |
| **Wave pass** | Tests 1–3, 7 pass before the next wave |
