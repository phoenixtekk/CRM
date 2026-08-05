# 6. Troubleshooting — Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

Work top-down: run **Discovery** first, then read the failing signal and fix its cause. Most 5719 cases
are one of **DNS, secure channel, time, blocked ports, no DC path, the boot-time NIC race, or an
invalid IPv6 value** — Discovery tells you which. Each symptom below gives the **likely cause** and the
**fix**. (Prevention lives in Best Practices.)

> **Before you start:** confirm this is a *client-side* secure-channel problem. If **every** domain
> member on a subnet fails at once, suspect the **DCs / DNS / network** (a DC or AD-DNS outage), not
> each endpoint — this toolkit diagnoses endpoints, not the domain controllers.

## Symptom: Event ID 5719 keeps appearing, but Validation says HEALTHY
**Likely cause:** A **boot-time race** — the NIC (or Wi-Fi/VPN) isn't up when Netlogon starts, so the
first secure-session attempt fails and logs 5719, then succeeds moments later.
**Fix:**
1. Confirm the 5719 events cluster at **startup** (Discovery lists event times).
2. Disable NIC power-off: **Device Manager → (NIC) → Properties → Power Management →** uncheck
   **"Allow the computer to turn off this device to save power."**
3. Set the GPO **Computer Configuration → Administrative Templates → System → Logon → "Always wait for
   the network at computer startup and logon" = Enabled.**
4. These transient boot 5719s are cosmetic once logon succeeds; the controls above stop them.

## Symptom: `Test-ComputerSecureChannel` returns False (trust broken)
**Likely cause:** The machine-account password is out of sync — device restored from a **snapshot/
image**, **cloned** without sysprep, or **off the domain longer than the machine-password age**.
**Fix:**
1. Ensure a DC is reachable (Discovery **DC ports** all open — R5).
2. Run `NETLOGONDX-Remediation.ps1` (preview), then `-WhatIf:$false` — it runs
   `Test-ComputerSecureChannel -Repair`, falling back to `nltest /sc_reset:<domain>`.
3. If repair needs credentials, add `-Credential (Get-Credential)`.
4. Re-run `NETLOGONDX-Validation.ps1`; the secure-channel check should read PASS. Avoid the old
   "unjoin/rejoin" ritual — repair/reset is faster and keeps the computer object.

## Symptom: DNS SRV records do not resolve (DC Locator fails)
**Likely cause:** The NIC points at a **public/wrong DNS server**, or the domain SRV records are
missing.
**Fix:**
1. Discovery shows the client DNS servers and the `_ldap._tcp.dc._msdcs.<domain>` result.
2. Set the NIC (or DHCP) to the **internal AD DNS** servers only (R6); remove public resolvers from
   domain members.
3. `ipconfig /flushdns; ipconfig /registerdns`, then re-run Discovery.
4. If internal DNS still lacks the SRV records, that is a **DC/DNS-side** issue (escalate with the
   Collect bundle).

## Symptom: Clock skew — time is more than 5 minutes off
**Likely cause:** Drifted clock (dead CMOS battery, wrong/blocked time source) breaks Kerberos.
**Fix:**
1. Run the remediation (`-WhatIf:$false`) — it starts Windows Time and runs `w32tm /resync /force`.
2. Confirm the source: `w32tm /query /status` should show the domain hierarchy (not `Local CMOS
   Clock`).
3. Ensure UDP/123 to the time source is allowed; replace the CMOS battery if the clock keeps drifting.

## Symptom: A DC port shows "blocked" (88/135/389/445)
**Likely cause:** Firewall/VLAN/segmentation change, host firewall, or the device is off-network.
**Fix:**
1. From the device, confirm with `Test-NetConnection <dc> -Port 389` (repeat for 88/135/445).
2. Unblock those ports to the DCs, or connect the corporate VPN/DirectAccess if off-network (R5).
3. Re-run Discovery; repair only after the ports are open — a secure-channel reset cannot reach a
   blocked DC.

## Symptom: IPv6 value flagged INVALID / unsupported
**Likely cause:** `DisabledComponents` is set to an unsupported value such as **`0xffffffff`** (or the
blanket-disable **`0xff`**) — often a copy-pasted "disable IPv6" tweak.
**Fix:**
1. Run the remediation (preview, then `-WhatIf:$false`) — it resets the value to **`0x0`** (IPv6
   enabled, dual-stack) and **never disables IPv6**.
2. **Restart** the device for the change to take effect, then re-run Validation.
3. Do not re-apply a "disable IPv6" fix: it breaks **DirectAccess / Remote Assistance / HomeGroup** and
   is **unsupported by Microsoft testing**. If you have a genuine need to prefer IPv4, use the supported
   **`0x20`** (prefer IPv4, IPv6 still enabled) — the toolkit leaves that value untouched.

## Symptom: Remediation says "Preview only" and changed nothing
**Likely cause:** Expected — the script **defaults to `-WhatIf`**.
**Fix:** Re-run with `-WhatIf:$false` (or `-Force`) to apply. In a Proactive Remediations package,
ensure the packaged remediation copy applies under SYSTEM (not left in preview).

## Symptom: Works on one device, not another
**Likely cause:** The failing device differs on one signal (DNS, ports, time, or IPv6).
**Fix:**
1. Run Discovery on **both** and compare the tables — the difference is the cause.
2. Fix the specific failing signal per the sections above, then re-validate.

## Symptom: Proactive Remediations shows "Issues detected" but never remediates
**Likely cause:** Detection exits `1` (correctly) but the packaged remediation is still previewing, or
context/architecture is wrong.
**Fix:**
1. Confirm the package uses **Run as SYSTEM = Yes** and **64-bit PowerShell = Yes**.
2. Confirm the packaged **remediation** script applies (not `-WhatIf`).
3. Check the device is reachable to a DC (repair needs a DC path — R5).

## Escalation checklist
Before opening a Microsoft support case, run **`NETLOGONDX-Collect.ps1`** and attach the ZIP. It
contains: the relevant System-log events (NETLOGON / Time-Service / Kerberos), `nltest /sc_query`,
`/dsgetdc`, `/dclist`, `ipconfig /all`, the client DNS list, the SRV-record result, `w32tm` status and
configuration, the secure-channel state, and the IPv6 `DisabledComponents` value — with **no
credentials or secrets**.
