# 5. Testing & Validation — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

This is the **acceptance gate**. Run every test on the **pilot device** (Implementation Phase E)
before expanding, and re-run the unit-specific tests on a sample device after each unit in Phase F.
Each test has an explicit **PASS / FAIL** condition. The rollout may expand only when **all tests
PASS** (or are justified N/A).

> The PowerShell tool **`EPICWS-Validation.ps1`** automates Tests 1–5; the **clinical print tests**
> (Tests 7–9) and the **Imprivata tap test** (Test 6) require a person at the device because they
> confirm an Epic workflow lands on a physical printer. Tools report device/printer state only — never
> patient data (G4).

---

## Test 1 — Standardization baseline applied
**Goal:** The `EPIC – Clinical Workstations – Baseline` settings-catalog profile applied.
**Steps:** Intune → **Devices → All devices →** device → **Device configuration**; and run
`EPICWS-Validation.ps1`.
**PASS:** Profile status **Succeeded**; the validation script reports the baseline settings present.
**FAIL:** Profile **Error/Conflict**, or settings not present → resolve conflict (often the security
baseline, R8) and re-sync.

## Test 2 — Power & display behavior correct
**Goal:** The workstation does not sleep / turn off display contrary to clinical policy.
**Steps:** Confirm `EPIC – Clinical Workstations – Power & Display` is **Succeeded**; on the device
check `powercfg /q` (or the script's power read) for never-sleep and the agreed display timeout.
**PASS:** Sleep disabled, hibernate disabled, display timeout = the clinically agreed value.
**FAIL:** Device sleeps or display times out off-policy → correct the profile and re-test.

## Test 3 — Unit printers present in the correct order
**Goal:** The wristband/label, script, and document printers for the unit are installed.
**Steps:** Run `EPICWS-Validation.ps1 -Unit <UNIT>`; or `Get-Printer` on the device.
**PASS:** All three printer classes present, named to the unit's mapping, in **wristband → script →
document** order.
**FAIL:** A printer missing or mis-ordered → re-check the Step 8/9 deployment for that unit and
re-sync.

## Test 4 — Default printer equals the unit default
**Goal:** The default printer is `<UNIT_DEFAULT_PRINTER>` for this unit.
**Steps:** Run `EPICWS-Validation.ps1 -Unit <UNIT> -ExpectedDefault "<UNIT_DEFAULT_PRINTER>"`; or
`Get-CimInstance Win32_Printer | ? Default`.
**PASS:** Default printer = `<UNIT_DEFAULT_PRINTER>`.
**FAIL:** Wrong default → re-apply Step 10 for the unit and re-test.

## Test 5 — Clinical peripherals recognized
**Goal:** The scanner, signature pad, and badge/proximity reader are installed and recognized.
**Steps:** Run `EPICWS-Validation.ps1` (peripheral driver/service checks); confirm Device Manager
shows no unknown device for these peripherals.
**PASS:** Each in-scope peripheral's driver/service present; no unknown device.
**FAIL:** A peripheral unrecognized → confirm its Win32 app shows **Installed** (Step 7) and the
device is connected; re-deploy/re-test.

## Test 6 — Badge reader feeds SSO (only if using Imprivata, R12)
**Goal:** The deployed badge/proximity reader is consumed by Imprivata for tap behavior.
**Steps:** With the Imprivata agent running, tap an enrolled badge at the device.
**PASS:** The tap behaves as configured (logon / fast-user-switch) and tap-to-launch into Epic works.
**FAIL:** Reader recognized (Test 5) but tap does nothing → engage the separate Imprivata solution. If
not using Imprivata, mark **N/A** (Test 5 still governs reader recognition).

## Test 7 — Epic wristband prints to the wristband printer
**Goal:** A real Epic wristband print job lands on the wristband/label printer.
**Steps:** From Epic on the device, print a test wristband to the workflow's wristband queue
(`<EPIC_QUEUE_WRISTBAND>` via `<EPS_SERVER>`).
**PASS:** The wristband prints on the unit's **wristband/label** printer, correctly formatted.
**FAIL:** Wrong printer or no output → re-check the Epic queue→printer mapping (R7) with your Epic team
and the printer deployment.

## Test 8 — Epic script/prescription prints to the script printer
**Goal:** A script/prescription job lands on the script printer.
**Steps:** From Epic, print a test script to `<EPIC_QUEUE_SCRIPT>`.
**PASS:** The script prints on the unit's **prescription/script** printer.
**FAIL:** Wrong printer → re-verify mapping (R7) and deployment; re-test.

## Test 9 — Epic document prints to the document printer / default
**Goal:** A general document job lands on the document printer (the unit default).
**Steps:** From Epic, print a test document to `<EPIC_QUEUE_DOC>` (and a no-queue-specified print to
confirm it uses the default).
**PASS:** The document prints on the unit's **document** printer; default-routed jobs use
`<UNIT_DEFAULT_PRINTER>`.
**FAIL:** Wrong printer/default → re-verify Steps 8–10 and mapping; re-test.

## Test 10 — Repeatability across form factors
**Goal:** A fixed workstation **and** a WOW in the same unit produce identical results.
**Steps:** Repeat Tests 1–9 on one of each form factor.
**PASS:** Both devices present the same baseline, printers, default, and recognized peripherals.
**FAIL:** Divergence → reconcile group membership/assignment so both are in the same unit/population
groups; re-test.

---

## Acceptance gate (must hold before Phase F expansion)
- [ ] **T1** Baseline profile **Succeeded** / settings present
- [ ] **T2** Power/display per clinical policy (never-sleep, agreed display timeout)
- [ ] **T3** Unit printers present, correct order
- [ ] **T4** Default printer = `<UNIT_DEFAULT_PRINTER>`
- [ ] **T5** Scanner + signature pad + badge reader recognized
- [ ] **T6** Badge tap feeds SSO (or N/A)
- [ ] **T7** Wristband → wristband printer
- [ ] **T8** Script → script printer
- [ ] **T9** Document → document printer; default-routed → unit default
- [ ] **T10** Fixed workstation and WOW identical

`EPICWS-Validation.ps1` must report **PROVISIONED**, and Tests 6–10 must PASS (or be justified N/A),
before any device in patient care is added in Phase F.
