# 5. Testing Guide — Group Policy to Intune Settings Migration

Run after the pilot policies apply (Implementation Step 8) and again for each broad-ring wave. The
goal of testing is **parity**: Intune now enforces what the GPO used to, on the right devices, with
Intune as the winning authority.

## Test 1 — Settings catalog policy applied
**Do:** Intune → **Devices → Manage devices → Configuration →** `GPO Migration – Settings Catalog –
Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 2 — Imported ADMX policy applied
**Do:** Open `GPO Migration – Imported ADMX – Pilot` → **Device status**; confirm the imported ADMX
shows **Available** under **Import ADMX**.
**Expected:** Pilot devices show **Succeeded**; the ADMX import status is **Available**.

## Test 3 — Settings parity (GPO vs Intune)
**Do:** On a pilot device run `GPOM-Validation.ps1` (compares source GPO settings to the applied
Intune values).
**Expected:** Each migrated setting reports **match**; no migrated setting is **missing** or
**different**.

## Test 4 — MDM wins over GP in effect
**Do:** Run `GPOM-Validation.ps1` (reports `MDMWinsOverGP`), or check
`HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict`.
**Expected:** `MDMWinsOverGP` is enabled — where both GPO and Intune set a value, the Intune value
wins.

## Test 5 — Migration coverage + gaps
**Do:** Run `GPOM-Report.ps1`.
**Expected:** A coverage figure close to the Group Policy analytics readiness %, and a gap list that
matches the unsupported settings you handled in Step 6 (nothing unexpected).

## Test 6 — No conflicting double-authority
**Do:** Run `GPOM-Discovery.ps1` on a migrated device (flags settings still owned by a live GPO).
**Expected:** For migrated areas, the legacy GPO is scoped away (no competing GPO value), or
`MDMWinsOverGP` cleanly resolves it.

## Test 7 — Cloud reach (off-network)
**Do:** Take a pilot device off the corporate network and sync; re-run `GPOM-Validation.ps1`.
**Expected:** The Intune settings still apply off-network (the original GPO would not have) —
confirming the cloud-reach benefit.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass; parity confirmed and `MDMWinsOverGP` in effect on the pilot ring |
| **Broad pass** | Tests 1, 3, 5, 6 pass for the broad ring before legacy GPOs are scoped away from the fleet |
