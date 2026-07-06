# 5. Testing Guide — macOS Endpoint Management Baseline (Microsoft Intune)

Run after the pilot objects apply (Implementation Step 10), and again after any baseline change.
Reuse the **exact** object names from the Implementation Guide.

## Test 1 — Baseline configuration profile applied to the pilot
**Do:** Intune → **Devices → macOS → Configuration →** `macOS Baseline – Config – Pilot` **→ Device
status** (and **Per setting status**).
**Expected:** Pilot Macs show **Succeeded**; per-setting status shows the baseline settings applied
with no conflicts.

## Test 2 — Restrictions policy applied
**Do:** Intune → **Devices → macOS → Configuration →** `macOS Baseline – Restrictions – Pilot` **→
Device status**.
**Expected:** Pilot Macs show **Succeeded**; the agreed restrictions (e.g. AirDrop, content caching)
are in effect on the Mac.

## Test 3 — Software-update policy applied
**Do:** Intune → **Devices → macOS → Configuration →** `macOS Baseline – Software Update – Pilot` **→
Device status**; on a pilot Mac confirm **System Settings → General → Software Update** reflects the
managed behaviour.
**Expected:** **Succeeded**; automatic download/install and the minimum-OS/deadline settings are
present.

## Test 4 — Settings present on the device
**Do:** On a pilot Mac (or from an admin workstation) run `MACBASE-Validation.ps1`.
**Expected:** The script reports the Mac's baseline objects as **applied**/succeeded with no drift
flagged.

## Test 5 — Compliance policy evaluates the device
**Do:** Intune → **Devices → macOS → Compliance →** `macOS Baseline – Compliance` **→ Device status**;
or on the Mac check **Company Portal**.
**Expected:** Pilot Macs evaluate **Compliant** against the agreed rules (e.g. minimum OS version,
FileVault on, firewall on).

## Test 6 — Custom `.mobileconfig` profile applied (if used)
**Do:** Intune → `macOS Baseline – Custom – Pilot` **→ Device status**; on the Mac confirm via
**System Settings → Privacy & Security → Profiles**.
**Expected:** The custom profile shows **Succeeded** and the payload is present on the Mac.

## Test 7 — Workflow soak (the baseline did not break the business)
**Do:** Pilot users run their real apps and daily workflows for several business days (login window,
screen-saver/password prompts, any restricted feature they legitimately use, the update deadline).
**Expected:** No workflow breakage. Any breakage is traced to a specific setting and handled by
adjusting it or rolling back (Implementation Step 10.6).

## Test 8 — Fleet posture and drift report
**Do:** Run `MACBASE-Report.ps1` (optionally with `-CsvPath`).
**Expected:** A clear per-object breakdown of device states and a drift count; pilot Macs appear
succeeded/compliant.

## Test 9 — Remediation dry-run (safe by default)
**Do:** Run `MACBASE-Remediation.ps1 -PolicyNameLike "macOS Baseline"` (no `-WhatIf:$false`).
**Expected:** With `-WhatIf` (the default), the script **lists** the drifted Macs and the sync actions
it *would* issue — and makes **no** change — proving the remediation path before you ever apply it.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–7 pass; no unresolved workflow breakage on the pilot |
| **Production pass** | Tests 1–5 and 8 pass for `macOS Baseline – Production Devices` after each rollout wave |
| **Change pass** | After any baseline change: Tests 1–7 re-pass on the pilot before promoting to production |
