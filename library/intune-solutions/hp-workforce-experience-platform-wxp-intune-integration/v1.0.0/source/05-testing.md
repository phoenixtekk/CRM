# 5. Testing & Validation — HP Workforce Experience Platform (WXP) Integration with Intune

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device / HP WXP
admin-console steps for the end-to-end result.

> **What "pass" means here:** the `HP WXP Agent - Pilot` Intune app installs on pilot devices, those
> devices **report telemetry into the HP WXP admin console**, and the **tenant connector** (`HP
> Workforce Experience`) is consented so WXP correlates your Intune inventory. This solution is the
> **integration method**; it does not provision the WXP subscription and does not replace Endpoint
> Analytics.

## Test 1 — Integration readiness
**Procedure:** Run `HPWXP-Discovery.ps1` (pass `-AppName` / `-ConnectorAppName` to match your tenant).
**Pass:** The HP WXP agent Win32 app is **present and assigned**, and the HP WXP **connector service
principal** is present.
**Fail:** Missing app, no assignment, or no connector service principal → resolve before piloting.
Re-run with the correct `-AppName` / `-ConnectorAppName` first (HP-renamed names vary) before treating a
FAIL as real.

## Test 2 — Agent app assignment
**Procedure:** Run `HPWXP-Validation.ps1 -AppName "HP WXP Agent - Pilot"` (optionally `-GroupId` of
`HP WXP - Pilot Devices`), or check **Apps → Windows → HP WXP Agent - Pilot → Properties → Assignments**.
**Pass:** `HP WXP Agent - Pilot` is assigned **Required** to `HP WXP - Pilot Devices` and to no
unintended broad group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment (Implement
Step 7 / `HPWXP-Set-ScopeTargeting.ps1`).

## Test 3 — Agent installed on the pilot device
**Procedure:** On the pilot device force an Intune sync; then Intune → **Apps → Windows → HP WXP Agent -
Pilot → Device install status** (or `HPWXP-Validation.ps1`).
**Pass:** The pilot device shows **Installed**.
**Fail:** **Failed / Pending** → check the install command and enrollment code (Step 6), the detection
rule value (Step 4/6), and that the device is enrolled and syncing (R4).

## Test 4 — Detection rule behaves (no reinstall loop)
**Procedure:** After the app shows Installed, force another sync and re-check install status.
**Pass:** The app **stays Installed** and does **not** reinstall on each sync.
**Fail:** Repeated installs / flip-flopping status → the **detection rule** does not match the installed
agent; correct the detection value (MSI product code or file/registry) against the reference device
(Step 6, R6).

## Test 5 — Device reports telemetry into HP WXP
**Procedure:** In the **HP WXP admin console**, locate the pilot device and confirm it is reporting.
**Pass:** The pilot device **appears in the WXP console and shows telemetry** (hardware/experience data
begins to populate — allow for first-report delay per HP's documentation).
**Fail:** Device installed the agent (Test 3) but does **not** appear in WXP → the agent likely did not
register to your tenant; verify the **enrollment code** was passed on the install command (Step 6) and
that the device can reach the **WXP service endpoints** (R9). **Verify expected first-report timing in
HP's documentation** before calling it a failure.

## Test 6 — Tenant connector consented and correlating
**Procedure:** Entra → **Enterprise applications**; find the HP WXP application (`HP Workforce
Experience` or the name shown in your tenant). Confirm in the **HP WXP admin console** that the
Microsoft/Intune connection is **connected/healthy** and lists your Intune-managed devices.
**Pass:** The connector service principal exists (created by admin consent) and WXP shows your
Intune-managed devices correlated with its telemetry.
**Fail:** No service principal / connection unhealthy → re-run the admin-consent flow as a Global
Administrator (Implement Step 9) and confirm the exact permissions on the consent screen.

## Test 7 — Agent-coverage report
**Procedure:** Run `HPWXP-Report.ps1` (optionally `-CsvPath`).
**Pass:** The report lists the pilot device(s) as **Installed = Yes**; counts match the assigned group.
**Fail:** Devices missing from coverage → run `HPWXP-Remediation.ps1` (`-WhatIf` first) to fix the
assignment, then re-sync stragglers.

## Test 8 — Endpoint Analytics unaffected (negative test)
**Procedure:** Intune → **Reports → Endpoint analytics**; confirm it still reports as before.
**Pass:** Microsoft **Endpoint Analytics is unchanged** — this solution **adds** HP WXP alongside it and
does not disable or replace the Microsoft-native score.
**Fail:** If Endpoint Analytics stopped reporting, an unrelated change is present — this integration does
not touch Endpoint Analytics (R11); investigate separately.

## Acceptance gate
Proceed to **Expand** only when Tests 1–7 pass on at least one pilot device (agent installed, detection
stable, device reporting into WXP, connector consented and correlating), Test 8 confirms Endpoint
Analytics is unaffected, and a reviewer confirms the pilot device's hardware/experience telemetry is
visible in the HP WXP admin console.
