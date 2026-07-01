# 5. Testing Guide — Endpoint Security Baselines

Run after the pilot baseline applies (Implementation Step 8) and after each production wave or version update.

## Test 1 — Profile assigned and applying
**Do:** Intune → **Endpoint security → Security baselines →** profile → **Device status**.
**Expected:** Pilot devices show **Succeeded** (not Error).

## Test 2 — No unresolved conflicts
**Do:** Review **Per-setting status** for **Conflict**; run `ESB-ConflictCheck.ps1`.
**Expected:** No settings in **Conflict** (each contested setting has one authoritative owner).

## Test 3 — Representative settings applied
**Do:** On a pilot device run `ESB-Validation.ps1` (checks a sample of hardened settings).
**Expected:** Sampled baseline settings are at the expected hardened values.

## Test 4 — No critical app/usability breakage
**Do:** Have pilot users run their core line-of-business apps for a day or two.
**Expected:** No baseline-induced breakage; capture and adjust any setting that blocks a required app.

## Test 5 — Compliance intact
**Do:** Intune → **Devices → Compliance**.
**Expected:** Devices remain **Compliant**.

## Test 6 — Version update flows cleanly
**Do:** When testing a baseline version change, review the **change summary** before applying.
**Expected:** You can see what changed and apply it without unexpected conflicts.

## Test 7 — Tenant report
**Do:** Run **`ESB-TenantReport.ps1`**.
**Expected:** Assignment and per-setting success summary for the pilot group.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; conflicts resolved; no critical app breakage |
| **Wave pass** | Tests 1–2, 5, 7 pass before the next wave |
