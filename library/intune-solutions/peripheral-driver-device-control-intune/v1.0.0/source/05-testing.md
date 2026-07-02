# Testing — Pass/Fail Gates

Testing confirms the solution works on the **pilot** before you expand, and confirms it still works on **production** after expansion. Each gate has an explicit **pass/fail** condition. Do not expand until all three gates **pass** on the pilot.

Run `PERIDEV-Validation.ps1` for the automated per-device view, and confirm each gate manually on at least one pilot device.

---

## Gate 1 — Driver current

**What it proves:** the approved driver update from `PERIDEV-DriverUpdates-Pilot` actually installed on pilot devices.

**How to test:**
1. On a pilot desktop, open **Device Manager** → find the device you approved a driver for → **Properties → Driver** tab.
2. Confirm the **Driver Version / Date** matches the version you approved in Intune.
3. In Intune, open `PERIDEV-DriverUpdates-Pilot` → the approved driver shows devices as **up to date / installed**.
4. Run `PERIDEV-Validation.ps1` and read the **Driver** column for the device.

**Pass:** the installed driver version equals the approved version on the pilot device(s), and Intune reports the driver installed.
**Fail:** the device still runs the old version after the make-available date and a sync, or the driver never appears — see Troubleshooting.

---

## Gate 2 — Printer mapped

**What it proves:** the printer delivered by `PERIDEV-Printers-Pilot` is available and usable on pilot devices.

**How to test:**
1. On a pilot desktop, open **Settings → Bluetooth & devices → Printers & scanners**.
2. Confirm the approved printer appears (Universal Print printers show as cloud printers; queue-mapped printers show by their queue name).
3. Print a **Windows test page** to that printer and confirm it prints.
4. Run `PERIDEV-Validation.ps1` and read the **Printer** column.

**Pass:** the printer is present and a test page prints successfully on the pilot device(s).
**Fail:** the printer is missing, shows an error, or the test page does not print — see Troubleshooting.

---

## Gate 3 — USB / removable-storage policy enforced

**What it proves:** `PERIDEV-DeviceControl-USB-Pilot` behaves as configured — auditing in the Audit phase, blocking in the Enforce phase — and the exception group still works.

**How to test (Audit phase):**
1. Insert a standard (non-approved) USB flash drive into a pilot desktop.
2. Confirm access is still allowed **and** an audit event is recorded (Defender device-control audit / event log).

**How to test (Enforce phase):**
1. Insert a standard (non-approved) USB flash drive into a pilot desktop.
2. Attempt to **write** a file to it. Confirm the write is **blocked** (and read allowed, or blocked, per your rule).
3. On a device in `SG-PERIDEV-USB-Exception`, insert an **approved** drive and confirm it works as intended.
4. Run `PERIDEV-Validation.ps1` and read the **DeviceControl** column.

**Pass:**
- Audit phase: non-approved drive is allowed and the access is audited.
- Enforce phase: non-approved drive is blocked per the rule, and an approved drive for `SG-PERIDEV-USB-Exception` still works.

**Fail:** a non-approved drive is not blocked in the Enforce phase, an approved drive is wrongly blocked, or no audit/block events appear — see Troubleshooting.

---

## Coverage check (before expanding)

Run `PERIDEV-Report.ps1` against `SG-PERIDEV-Pilot`. Confirm:
- Every pilot device is covered by the driver, printer, and device-control policies (no "not applied" gaps).
- No device reports an **error** state for any of the three policies.

**Pass:** 100% of pilot devices covered by all three policy areas with no error states.
**Fail:** any pilot device is missing a policy or in error — resolve before expanding.

---

## Post-expansion check (production)

After Stage 6 expansion, re-run `PERIDEV-Report.ps1` against `SG-PERIDEV-Production` and re-confirm Gates 1–3 on a sample of production devices. Coverage should trend toward 100% as devices sync.
