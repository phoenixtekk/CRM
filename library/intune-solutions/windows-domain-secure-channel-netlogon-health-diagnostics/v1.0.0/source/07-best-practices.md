# 7. Best Practices — Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

These practices keep the toolkit safe, repeatable, and effective — and, just as important, **prevent**
Event ID 5719 from recurring. They assume the diagnostics model in the Solution Overview: read-only
collection first, preview-first repair, IPv6 kept in a supported dual-stack configuration, run locally
or via Intune Proactive Remediations.

## Diagnose before you touch anything
- **Always run Discovery first.** Read the failing signal off the table; don't reset the secure channel
  on a hunch when the real cause is DNS or a blocked port.
- **Fix the network layer before repairing the trust.** If **DNS SRV** or **DC ports** are failing,
  correct those first — `Test-ComputerSecureChannel -Repair` and `nltest /sc_reset` cannot succeed with
  no DC path.

## Repair safely (preview-first)
- **Preview every change.** `NETLOGONDX-Remediation.ps1` **defaults to `-WhatIf`**. Read the plan, then
  re-run with `-WhatIf:$false` (or `-Force`) to apply.
- **Prefer repair over rejoin.** `Test-ComputerSecureChannel -Repair` / `nltest /sc_reset` fix the
  trust **without** deleting the computer object or re-enrolling — faster and less disruptive than
  unjoin/rejoin.
- **Supply credentials only when needed.** Pass `-Credential` for the secure-channel repair only if the
  device's current context can't authenticate; never hard-code credentials into a packaged script.

## Keep IPv6 in a supported configuration (never blanket-disable)
- **Leave IPv6 ENABLED.** The recommended `DisabledComponents` value is **`0x0`** (or absent) — full
  **dual-stack**. This is what Microsoft tests and supports.
- **Only correct invalid values.** Reset unsupported values (e.g. **`0xffffffff`**, **`0xff`**) back to
  **`0x0`**. The toolkit does exactly this and **never disables IPv6**.
- **Use supported non-default values deliberately.** If you must prefer IPv4, use **`0x20`** (prefer
  IPv4, IPv6 still enabled); **`0x11`** (disable IPv6 on non-tunnel + tunnel interfaces) only with a
  documented justification. Record *why* you chose it.
- **Know the blast radius.** Disabling IPv6 breaks **DirectAccess, Remote Assistance, and HomeGroup**
  and is **unsupported by Microsoft's testing** — never present "just disable IPv6" as a fix.
- **Remember the restart.** An IPv6 `DisabledComponents` change takes effect only after a **reboot**.

## Prevent recurrence (the boot-time race and drift)
- **Stop the NIC power-off.** Uncheck **"Allow the computer to turn off this device to save power"** on
  the network adapter (deploy via policy for the fleet) so the link is up when Netlogon starts.
- **Wait for the network at boot.** Enable the GPO **"Always wait for the network at computer startup
  and logon"** so early logon has a DC path — this eliminates most transient boot 5719s.
- **Pin domain members to internal AD DNS.** No public resolvers on domain members; the DC Locator
  depends on the internal SRV records.
- **Keep a healthy time hierarchy.** Domain members should sync from the domain (ultimately the PDC
  emulator), not `Local CMOS Clock`; replace failing CMOS batteries.

## Operate at scale with Proactive Remediations
- **Detection = Validation, Remediation = Remediation.** Package
  **`NETLOGONDX – Secure-Channel & Netlogon Health`** with Validation (exits `1` when unhealthy) as
  detection and Remediation as the fix; run as **SYSTEM**, **64-bit**.
- **Pilot first, expand in waves.** Assign to **`NETLOGONDX-Pilot`** first; only broaden after the
  Testing gate passes. Schedule detection **daily** so drift is caught early.
- **Measure with the CSV.** Harvest `NETLOGONDX-Report.csv` from devices to see coverage before and
  after a wave; only widen when *Without issues* matches the assigned devices.

## Keep evidence and change control
- **Bundle for escalation.** Run `NETLOGONDX-Collect.ps1` and attach the ZIP to any support case — it
  captures the events, `nltest`, `ipconfig`, `w32tm`, and IPv6 state, with **no secrets**.
- **Record what you changed and why.** Note the failing signal, the fix applied, and (for IPv6) the
  before/after value and justification for any non-default supported value.
- **Re-validate after OS updates.** Confirm the checks still pass and the IPv6 value holds after major
  Windows feature updates before widening further.
