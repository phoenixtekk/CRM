# 5. Testing Guide — Netskope Secure Web Gateway (SWG)

Run after the pilot scope is steered (Implementation Step 10) and again after expanding to broad.

## Test 1 — Client deployed and steering active
**Do:** On a pilot device run `NSSWG-Validation.ps1` (checks the client/service and steering state).
**Expected:** The Netskope client is installed and running and steering is active.

## Test 2 — Decryption certificate trusted
**Do:** `NSSWG-Validation.ps1`, or check **Trusted Root Certification Authorities** on the device.
**Expected:** `Decryption Certificate – Managed Devices – Production` is present and trusted; HTTPS
sites load without certificate errors through the gateway.

## Test 3 — Categorization and block action
**Do:** From a pilot device, browse a site in a category you set to **block** in
`Web Filtering Policy – All Users – Production` (use a known test category, not a live malicious site).
**Expected:** The request is blocked and the gateway block/notification page is shown.

## Test 4 — Coach (warn) action
**Do:** Browse a site in a category set to **coach**.
**Expected:** The user sees the coaching/warning page and can proceed per policy.

## Test 5 — Allowed traffic flows normally
**Do:** Browse normal business sites in allowed categories.
**Expected:** Sites load normally; the activity appears in the tenant's web logs.

## Test 6 — Decryption bypass honored
**Do:** Open an app/site on the decryption bypass list (certificate-pinned or sensitive category).
**Expected:** The flow works without inspection errors (not decrypted).

## Test 7 — On/off-network consistency
**Do:** Repeat Tests 3 and 5 with the device off the corporate network (e.g. on a home/hotspot link).
**Expected:** The same block/allow behavior applies off-network as on-network.

## Test 8 — Coverage and activity report
**Do:** Run `NSSWG-Report.ps1`.
**Expected:** Steered scope groups are listed and pilot web activity (per-category counts) is present,
confirming traffic is flowing through the gateway.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–7 pass on `Web Steering – Pilot – Stage 1`; no user-impacting breakage; rollback rehearsed |
| **Broad pass** | Tests 1–3, 5, 8 pass for `Web Steering – Broad – Stage 2` after expansion |
