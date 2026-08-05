# 5. Testing & Validation — Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

Validate against a **pilot device** (and the **`NETLOGONDX-Pilot`** group) before expanding. Each test
has an explicit **pass/fail gate**. Use the included endpoint PowerShell scripts for the checks; the
device-level steps confirm the real user-facing behavior.

> **What "pass" means here:** the toolkit correctly *identifies* the root cause of Event ID 5719,
> *repairs* it safely, leaves **IPv6 in a supported configuration**, and reports **HEALTHY**. This is a
> diagnostics toolkit — it does not enroll devices or change how they are joined.

## Test 1 — Discovery collects every signal
**Procedure:** Run `NETLOGONDX-Discovery.ps1` elevated on the pilot device.
**Pass:** The table shows a line for **each** signal — 5719 events, secure channel, DC locator, DNS
SRV, time sync, DC ports (88/135/389/445), IPv6 `DisabledComponents` — and
`C:\ProgramData\NETLOGONDX\NETLOGONDX-Discovery.json` is written.
**Fail:** Any signal missing/errors out → confirm elevation (R2) and that `nltest`/`w32tm` resolve
(R4).

## Test 2 — Validation gate and exit code
**Procedure:** Run `NETLOGONDX-Validation.ps1`; then check the exit code (`$LASTEXITCODE`).
**Pass:** On a healthy device, **OVERALL: HEALTHY** and exit code **0**. On a device with a known
issue, the failing check(s) are listed and exit code is **1**.
**Fail:** Exit code does not reflect health (e.g. 0 while a check reads FAIL) → re-run elevated and
capture output for Collect.

## Test 3 — Secure-channel repair (preview then apply)
**Procedure:** On a device with a broken secure channel (`Test-ComputerSecureChannel` = False), run
`NETLOGONDX-Remediation.ps1` (preview), then `-WhatIf:$false`.
**Pass:** Preview reports it **would** repair and changes nothing; apply runs
`Test-ComputerSecureChannel -Repair` (or falls back to `nltest /sc_reset`) and a follow-up
`Test-ComputerSecureChannel` returns **True**.
**Fail:** Repair errors → confirm a DC is reachable on 88/135/389/445 (R5) and supply `-Credential`.

## Test 4 — Time re-sync
**Procedure:** On a device with clock skew, run the remediation (`-WhatIf:$false`), then re-run
Validation.
**Pass:** `w32tm /resync` succeeds, the measured offset drops **below 5 minutes**, and the **Time in
sync** check reads PASS.
**Fail:** Offset still high → confirm the Windows Time service is running and the domain time hierarchy
is healthy; check the time source in `w32tm /query /status`.

## Test 5 — DNS DC-locator resolution
**Procedure:** Run Discovery and read the **DNS resolves domain SRV records** line; compare the
client's DNS servers to the internal AD DNS.
**Pass:** `_ldap._tcp.dc._msdcs.<domain>` resolves to DC targets and the NIC uses internal AD DNS.
**Fail:** Not resolved / public resolver in use → correct NIC DNS (R6), then
`ipconfig /flushdns; ipconfig /registerdns` and re-test.

## Test 6 — IPv6 recommended configuration
**Procedure:** On a device with an **invalid** value (set `DisabledComponents = 0xffffffff` on a lab
device), run Discovery, then the remediation (preview, then `-WhatIf:$false`), then reboot and re-run
Validation.
**Pass:** Discovery flags the value **INVALID/unsupported**; remediation resets it to **`0x0`**
(never disabling IPv6); after reboot the **IPv6 not invalidly disabled** check reads PASS.
**Expected variance:** a **supported** value (`0x20` or `0x11`) is reported as acceptable and is
**left unchanged** — that is correct, not a failure.
**Fail:** Remediation disables IPv6 or changes a supported value → it must not; re-confirm you are on
the shipped script.

## Test 7 — DC port reachability
**Procedure:** Run Discovery and read the **DC ports reachable (88/135/389/445)** line.
**Pass:** All four ports show **open** to the located DC (or the specific blocked port is correctly
reported).
**Fail:** A port shows **blocked** unexpectedly → verify firewall/VLAN rules to the DCs (R5), then
re-test.

## Test 8 — Report and escalation bundle
**Procedure:** Run `NETLOGONDX-Report.ps1`, then `NETLOGONDX-Collect.ps1`.
**Pass:** `NETLOGONDX-Report.csv` (one row) and `NETLOGONDX-Report.txt` are written with an OVERALL
verdict; Collect produces `NETLOGONDX-Collect-<host>-<timestamp>.zip` containing the events, `nltest`,
`ipconfig`, `w32tm`, and IPv6 artifacts — with **no credentials/secrets**.
**Fail:** Missing artifacts → confirm write access to `C:\ProgramData\NETLOGONDX` (R8).

## Test 9 — Proactive Remediations at scale
**Procedure:** Deploy the **`NETLOGONDX – Secure-Channel & Netlogon Health`** package (detection =
Validation, remediation = Remediation) to the **`NETLOGONDX-Pilot`** group; wait for a detection cycle.
**Pass:** Endpoint analytics → the package → **Device status** shows healthy devices as *Without
issues* and previously-broken devices moving to *Issues remediated*.
**Fail:** Devices stuck in *Issues detected* → open a device, confirm SYSTEM context and 64-bit
PowerShell in the package settings, and that the packaged remediation applies (not left in preview).

## Test 10 — No enrollment/join change (negative test)
**Procedure:** Confirm the device is still domain-joined and enrolled exactly as before, after running
the toolkit.
**Pass:** Domain membership and Intune enrollment are **unchanged**; the toolkit only diagnosed/repaired
the secure channel, time, DNS use, and IPv6 value.
**Fail:** Any join/enrollment change → the toolkit does not do this; investigate other tooling.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass on the pilot device, Test 9 confirms the Proactive
Remediations package behaves at scale, and Test 10 confirms enrollment/join is unchanged.
