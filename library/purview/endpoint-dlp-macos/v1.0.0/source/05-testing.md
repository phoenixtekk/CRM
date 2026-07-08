# 5. Testing Guide — Endpoint DLP for macOS (Microsoft Purview)

Run after the Macs are onboarded and the DLP policy is created **in test/simulation (Audit) mode**
(Implementation Phases 1–3), and again after each mode advance and expansion wave. Back each test with
**`DLPMac-Discovery.ps1`** / **`DLPMac-Validation.ps1`** / **`DLPMac-Report.ps1`** and the Purview
portal. **Use non-production test content** that matches the in-scope SIT — never real regulated data.

## Test 1 — Macs are onboarded and reporting
**Do:** Run **`DLPMac-Onboarding-Check.ps1`**; Purview portal → **Settings → Device onboarding →
Devices**.
**Expected:** The pilot Macs appear **onboarded/active**; the system/network extension is allowed and
Full Disk Access is granted on the device.

## Test 2 — DLP policy is Devices-scoped and in test/simulation mode
**Do:** Run **`DLPMac-Discovery.ps1`**.
**Expected:** `Endpoint DLP - macOS - Pilot` exists, targets the **Devices (Endpoint)** location
**only**, and **Mode = TestWithoutNotifications** (not `Enable`). Anything already in `Enable` is
flagged for review.

## Test 3 — The egress rule is present with the intended channels
**Do:** Run **`DLPMac-Validation.ps1`**.
**Expected:** Rule `macOS Egress - Sensitive Content` exists with the agreed **conditions** (SIT/label)
and the intended egress restrictions (cloud/browser, USB, network share, clipboard, print, restricted
apps), all at **Audit** for the pilot; the referenced restricted-app group `macOS - Restricted Apps`
exists.

## Test 4 — USB / removable media egress is audited
**Do:** On a pilot Mac, copy a test file (matching the SIT) to a USB drive.
**Expected:** An **audited** Endpoint DLP event for **copy to removable media** appears in Activity
Explorer / **`DLPMac-Report.ps1`**, attributed to the policy + rule. No block yet (Audit mode).

## Test 5 — Network-share copy is audited
**Do:** Copy the test file to a mounted network share.
**Expected:** An **audited** "copy to network share" event is recorded for the Mac.

## Test 6 — Cloud / browser upload is audited
**Do:** Upload the test file from an approved browser (Edge) and, if the Purview extension is deployed,
from Chrome/Firefox to a sensitive service domain.
**Expected:** An **audited** cloud-egress / unallowed-browser event appears. (If Chrome/Firefox produce
nothing, confirm the **Purview browser extension** — Requirement 2.8.)

## Test 7 — Clipboard and print are audited
**Do:** Copy sensitive test content to the clipboard (and paste elsewhere); print the test file.
**Expected:** **Audited** clipboard and print events are recorded (subject to current macOS support for
those channels).

## Test 8 — Restricted-app access is audited
**Do:** Open the test file with an app listed in `macOS - Restricted Apps`.
**Expected:** An **audited** "access by restricted app" event is recorded.

## Test 9 — Notifications appear in TestWithNotifications
**Do:** After passing Tests 4–8, advance the policy to **`TestWithNotifications`**
(`Set-DlpCompliancePolicy -Mode TestWithNotifications`) and repeat one egress action.
**Expected:** A **policy tip / notification** appears to the user on the Mac; still **no block**.

## Test 10 — Enforcement blocks the selected channel(s)
**Do:** After compliance/legal sign-off, set the chosen channel(s) to **Block** and the policy to
**`Enable`**; repeat the action for an enforced channel and for a non-enforced one.
**Expected:** The **enforced** channel is **blocked** (or blocked-with-override) and recorded;
non-enforced channels remain audited. **`DLPMac-Report.ps1`** shows the block/override events.

## Test 11 — Rollback reverts enforcement
**Do:** Set the policy back to **`TestWithoutNotifications`** and repeat the previously-blocked action.
**Expected:** The action is **no longer blocked** (silent simulation restored) on next sync —
confirming the documented rollback works.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Onboarding pass** | Tests 1–3 pass (Macs onboarded/reporting; policy Devices-scoped in test mode; rule present) |
| **Simulation pass** | Tests 4–8 pass (each in-scope channel produces an audited event on the Mac) |
| **Enforcement pass** | Tests 9–11 pass (notifications, then Block on selected channels, and rollback all behave as intended) |

> Do not enforce (Block / `Enable`) until the **Simulation pass** gate is green and compliance/records/
> legal have signed off the enforcement intent. Re-run Tests 4–8 in simulation for every expansion wave
> before advancing that wave's mode.
