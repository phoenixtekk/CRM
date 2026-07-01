# 5. Testing Guide — Dynamic Device Targeting in Intune

Run after the pilot assignment applies (Implementation Step 6) and after any taxonomy, group, or
filter change.

## Test 1 — Dynamic group membership evaluated
Do: Entra -> `Groups` -> open `Corp Devices – Windows – Pilot` -> `Members`; or run
`DYNTGT-Discovery.ps1`.
Expected: The expected pilot devices are present; the membership rule shows the intended query.

## Test 2 — Membership rule accuracy
Do: Confirm a device that should match is a member and a device that should not is absent (change an
attribute on a test device and re-check after evaluation).
Expected: Membership tracks the rule — matching devices in, non-matching devices out.

## Test 3 — Filter defined and valid
Do: Intune -> `Tenant administration -> Filters`; open `OS Version – Windows 11 – Include`.
Expected: The filter exists, targets the correct platform, and its rule syntax validates.

## Test 4 — Effective targeting on the assignment
Do: Open the policy/app `Assignments`, confirm the group and filter (include/exclude) are set; run
`DYNTGT-Validation.ps1` for a pilot device.
Expected: The device's group membership and filter result produce the intended effective targeting;
the policy/app shows applied on matching devices only.

## Test 5 — Exclusion carve-out works
Do: Apply a corporate assignment with `Ownership – Personal – Exclude` in Exclude mode; check a BYOD
device.
Expected: The BYOD device is excluded from that assignment; corporate devices still receive it.

## Test 6 — Coverage and drift
Do: Run `DYNTGT-Report.ps1`.
Expected: A per-audience coverage summary and a drift list (in-scope devices missing the assignment,
or devices matched by no targeting group).

## Test 7 — Reuse across a second assignment
Do: Attach the same group + filter to a second policy/app; confirm it targets identically.
Expected: Assign-once behavior — the same effective audience with no new group created.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-5 pass; effective targeting on the pilot matches intent |
| Broad pass | Tests 4, 6, 7 pass for the broad audience before wider reuse |
