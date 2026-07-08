# 5. Testing Guide — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

Run after the kiosk + apps are assigned and at least one device is enrolled (Implementation Steps 7–9),
and again after each expansion wave. Back each test with **`COSU-Discovery.ps1`** /
**`COSU-Validation.ps1`** / **`COSU-Report.ps1`**.

## Test 1 — Enrollment profile + token are valid
**Do:** Run **`COSU-Discovery.ps1`**; check Intune → **Devices → Android → Corporate-owned dedicated
devices**.
**Expected:** `Android Dedicated - COSU - Pilot` exists with a **non-expired token**; QR code available.

## Test 2 — Device enrolls as dedicated (no user)
**Do:** Enroll a factory-reset pilot device by the chosen method (QR / afw#setup / NFC / zero-touch);
check Intune → **Devices**.
**Expected:** The device appears as **corporate-owned dedicated**, **no primary user / device owner**,
enrolled with the profile.

## Test 3 — Device lands in the dynamic device group
**Do:** Run **`COSU-Report.ps1`**; check Entra → **Groups → `Android Dedicated - Devices - Pilot`**.
**Expected:** The enrolled device is a member (dynamic rule on the enrollment profile name captured it).

## Test 4 — Kiosk apps installed (Required-to-device)
**Do:** Run **`COSU-Validation.ps1`**; on the device, look for the app(s).
**Expected:** Every managed Google Play app assigned **Required** to the group is **installed**; for
multi-app, the **Managed Home Screen** launcher is present.

## Test 5 — Device boots to the kiosk (single-app)
**Do:** Reboot a single-app device.
**Expected:** It launches **straight into the one allowed app**; the user cannot exit to a launcher,
settings, or any other app.

## Test 6 — Multi-app kiosk shows only the allowed set
**Do:** On a multi-app device, review the Managed Home Screen.
**Expected:** **Only** the curated apps appear; no other apps, no full settings; toggles limited to what
the kiosk policy allows (Wi-Fi/Bluetooth/volume as configured); session PIN/exit behaves as set.

## Test 7 — Only-allowed-apps report is clean
**Do:** Run **`COSU-Validation.ps1`**.
**Expected:** The kiosk **allow-list matches the apps assigned** to the device group — no app named in
the kiosk is missing an assignment, and no unexpected app is exposed. Any mismatch is listed to fix.

## Test 8 — Device restrictions hold
**Do:** On the device, attempt blocked actions (add a Google account, factory reset from settings, USB
file transfer, safe boot) per your policy.
**Expected:** Each blocked action is **prevented**; allowed actions still work.

## Test 9 — Device is remotely manageable
**Do:** From Intune, run **Sync** and a benign device action (e.g. **Restart**) on the pilot device.
**Expected:** The action reaches the device; **`COSU-Report.ps1`** shows a recent **last check-in** and
the device **compliant** (if a compliance policy is assigned).

## Test 10 — Fleet health + OEM/inventory breakdown
**Do:** Run **`COSU-Report.ps1`**.
**Expected:** A clear count of dedicated devices with compliance state, last check-in, OS version, and
manufacturer/model (OEM breakdown, e.g. Zebra/Samsung); no unexpected stale or non-dedicated devices in
the group.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Enrollment pass** | Tests 1–3 pass (profile/token valid; device enrolls dedicated; joins the group) |
| **Kiosk pass** | Tests 4–7 pass (apps installed; boots to kiosk; only allowed apps; report clean) |
| **Lockdown + management pass** | Tests 8–10 pass (restrictions hold; remotely manageable; fleet healthy) |

> Do not expand beyond the pilot until all three gates pass. Re-run Tests 4–10 after each wave.
