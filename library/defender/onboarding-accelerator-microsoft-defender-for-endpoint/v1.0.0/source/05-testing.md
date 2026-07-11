# 5. Testing Guide — Onboarding Accelerator: Microsoft Defender for Endpoint

Run these checks after the pilot onboarding (Steps 2–8) and again after each expansion wave. Each test has a **pass/fail gate**; do not enforce ASR/block mode more widely or expand until the pilot passes. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Pilot ring onboarded (all platforms)
**Procedure:** Run `MDEONB-Validate.ps1 -Check Onboarding`. In `security.microsoft.com` → **Assets → Devices**, confirm each pilot device from `MDE Device Group – Pilot Ring – Pilot` (Windows/macOS/Linux) is **Onboarded**.
**Pass:** Every pilot device is onboarded and reporting EDR signal.
**Fail:** A device stays "Can be onboarded" — see Troubleshooting *Device not onboarding*.

## Test 2 — Next-gen AV + EDR block mode
**Procedure:** Run `MDEONB-Validate.ps1 -Check EDR`. Confirm `MDE Next-Gen AV – Pilot Ring – Prod` is applied and **EDR in block mode** is on.
**Pass:** AV policy applied to the ring and block mode enabled.
**Fail:** Block mode off or AV policy not applied — see Troubleshooting *EDR/AV not applied*.

## Test 3 — ASR in audit, then block
**Procedure:** Run `MDEONB-Validate.ps1 -Check ASR` and `MDEONB-Report.ps1 -Section ASR`. Confirm `MDE ASR Rules – Pilot Ring – Audit` produced audit events, exclusions were reviewed, and `MDE ASR Rules – Pilot Ring – Block` is now blocking on the ring.
**Pass:** ASR ran in audit, exclusions were tuned, and block is enforced on the ring with no legitimate-app breakage.
**Fail:** ASR blocking before audit review, or breaking apps — revert to audit per Implementation Step 4.

## Test 4 — Tamper protection + web content filtering
**Procedure:** Run `MDEONB-Validate.ps1 -Check Config`. Confirm **Tamper Protection** is enforced and `MDE Web Content Filtering – Tenant – Prod` is active.
**Pass:** Tamper protection on; web content filtering categories enforced (P2).
**Fail:** Either off — re-apply per Implementation Step 5; *verify P2 for web content filtering.*

## Test 5 — Device groups + RBAC
**Procedure:** Run `MDEONB-Validate.ps1 -Check RBAC`. Confirm `MDE Device Group – Pilot Ring – Pilot` exists with automation **Semi — require approval**, and roles `MDE Security Reader – Tenant – Prod` / `MDE Security Operator – Tenant – Prod` are assigned.
**Pass:** Device group and roles exist; reader cannot take response actions, operator can; automation is approval-gated.
**Fail:** Flat permissions or wrong automation — re-apply per Implementation Step 6.

## Test 6 — Onboarding coverage + telemetry streaming
**Procedure:** Run `MDEONB-Hunt.ps1` to execute `MDE Onboarding Coverage – Tenant – Validate`. Confirm `DeviceInfo` shows pilot devices onboarded/healthy and `DeviceEvents` / `DeviceTvmSoftwareVulnerabilities` return rows.
**Pass:** Coverage and telemetry tables stream for the pilot ring.
**Fail:** A table empty — see Troubleshooting *No device telemetry*.

## Test 7 — A detection actually fires
**Procedure:** Run the Microsoft-provided safe **EDR detection test** on a pilot device; confirm the alert appears in **Incidents & alerts**. With block mode on, confirm an ASR-block event on a device.
**Pass:** The controlled test produces a visible MDE alert; ASR blocks the tested behavior.
**Fail:** No alert/block — see Troubleshooting *Detection does not fire*.

## Test 8 — TVM exposure baseline + AIR approval-gated
**Procedure:** Run `MDEONB-Report.ps1 -SaveBaseline`. Confirm a TVM exposure score/baseline is recorded and the pilot group's AIR automation level is **Semi — require approval**.
**Pass:** Exposure baseline captured; AIR approval-gated on the pilot.
**Fail:** No exposure data (allow warm-up) or automation higher than agreed — reset per Implementation Step 7 and confirm with the SOC.

---
### Exit gate
All eight tests pass on the pilot ring **before** you promote ASR/block mode more widely or expand onboarding (Implementation Step 9). Re-run Tests 1, 3, 6, 7, and 8 after each expansion wave and compare against the saved exposure baseline.
