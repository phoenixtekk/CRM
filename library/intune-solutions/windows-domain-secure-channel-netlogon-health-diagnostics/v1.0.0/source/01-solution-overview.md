# 1. Solution Overview — Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

## What this solution is
This solution is a **diagnostics toolkit** — five endpoint PowerShell scripts plus a complete method —
that pinpoints and repairs the root cause of **Netlogon Event ID 5719** and a **broken domain secure
channel** on domain-joined Windows devices, and restores **IPv6 to a recommended configuration**. The
scripts run **locally on the affected device** (elevated) or **at scale under SYSTEM via Microsoft
Intune Proactive Remediations**. They are **read-heavy by design**: four of the five change nothing;
only the remediation script makes changes, and it **defaults to `-WhatIf`** (preview) until you
explicitly apply.

> **Scope, stated plainly.** This is an **endpoint diagnostics toolkit** for the *client* side of the
> domain trust — the sibling of our endpoint performance/diagnostics toolkits. It is **not** a
> configuration baseline, **not** a domain-controller build guide, and **not** an Active Directory
> health tool for the DCs themselves. It resolves two specific availability findings on Windows
> endpoints: **Event ID 5719 (Netlogon)** and **"set IPv6 to a recommended configuration."**

## What Event ID 5719 actually means
NETLOGON logs **Event ID 5719** — *"This computer was not able to set up a secure session with a domain
controller… There are currently no logon servers available to service the logon request"* — whenever
the device cannot establish the authenticated **secure channel** it needs to a domain controller (DC).
The message is a **symptom with several distinct causes**. This toolkit walks the full root-cause tree
rather than guessing.

## The root-cause tree (what Discovery checks, and why)
1. **DNS / DC locator.** The device finds DCs by resolving **SRV locator records** —
   `_ldap._tcp.dc._msdcs.<domain>` — against **internal AD DNS**. If the NIC points at a public
   resolver (8.8.8.8) or the wrong DNS server, the DC Locator fails and 5719 follows. *Discovery
   resolves the SRV record and reports the client's DNS servers.*
2. **Secure channel / trust password.** Each domain member holds a **machine account password** that
   must match the copy in AD. It falls out of sync when a device is **restored from a snapshot/image**,
   **cloned without sysprep**, or **left off the domain longer than the machine-password age**. Then
   `Test-ComputerSecureChannel` returns **False**. *Discovery runs that test and `nltest /sc_query`.*
3. **Time skew (Kerberos).** Kerberos rejects tickets when the client clock is more than **5 minutes**
   off the DC. A drifted clock (dead CMOS battery, wrong time source) breaks authentication and logs
   5719. *Discovery reads `w32tm` state and measures the offset against a located DC.*
4. **Network path & firewall.** The secure channel needs the DC reachable on **88 (Kerberos)**,
   **135 (RPC endpoint mapper)**, **389 (LDAP)**, and **445 (SMB)**. A firewall/VLAN/segmentation
   change silently blocks them. *Discovery TCP-probes all four against the located DC.*
5. **DC reachability.** The subnet may map to an **AD site with no DC**, or a **VPN/DirectAccess**
   tunnel may not be up at boot, so no DC answers the locator. *Discovery reports the located DC (or
   none) and port results.*
6. **NIC / power-management race at boot.** A classic **transient** 5719: the network adapter isn't up
   when Netlogon starts, often because **"Allow the computer to turn off this device to save power"**
   is enabled on the NIC, or **"Always wait for the network at computer startup and logon"** is not
   set. *Best Practices covers preventing this; Discovery captures the boot-time 5719 pattern.*
7. **IPv6 invalidly disabled.** Windows domain networking is built and tested as **dual-stack**. An
   **invalid** `DisabledComponents` value (see below) can break name resolution and DC location and is
   a common, self-inflicted cause. *Discovery reads and classifies the value.*

## The IPv6 finding — keep it enabled, fix invalid values only
The registry value **`HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\DisabledComponents`**
(DWORD) tunes IPv6. This toolkit takes the **Microsoft-supported** position:

- **IPv6 must remain ENABLED.** The recommended value is **`0x0`** (or the value simply **absent**) —
  full **dual-stack**. Do **not** disable IPv6.
- **Supported, only with justification:** **`0x20`** (prefer IPv4 while IPv6 stays enabled) and
  **`0x11`** (disable IPv6 on non-tunnel + tunnel interfaces). Use these deliberately, not by accident.
- **Invalid / unsupported:** values such as **`0xffffffff`** (and the blanket-disable **`0xff`**) set
  bits Microsoft **does not test**. They are the ones to **correct back to `0x0`**.
- **Why not just disable it:** disabling IPv6 breaks **DirectAccess**, **Remote Assistance**, and
  **HomeGroup**, and Microsoft **does not test** Windows with IPv6 disabled — so it is unsupported.

The Remediation script only ever **corrects invalid values to `0x0`**; it leaves supported values
untouched and **never disables IPv6**.

## How you run it (local, or at scale via Proactive Remediations)
- **On one device (triage):** run `NETLOGONDX-Discovery.ps1` elevated to see the whole picture, then
  `NETLOGONDX-Remediation.ps1` (preview first, then `-WhatIf:$false`) to repair, and
  `NETLOGONDX-Validation.ps1` to confirm.
- **Across the fleet (at scale):** package **`NETLOGONDX-Validation.ps1` as the DETECTION script** and
  **`NETLOGONDX-Remediation.ps1` as the REMEDIATION script** in an Intune **Proactive Remediations**
  script package, assigned to a pilot group first. Detection exits `1` on any unhealthy signal, which
  triggers remediation; Report/Collect gather evidence. All scripts use **in-box Windows commands only**
  — no modules to install on endpoints.

## Named objects you create (and reuse)
- **`C:\ProgramData\NETLOGONDX`** — the on-device output folder every script writes to (Discovery JSON,
  Report CSV/TXT, Collect ZIP). Referenced by name throughout.
- **`NETLOGONDX – Secure-Channel & Netlogon Health`** — the Proactive Remediations script package
  (detection = Validation, remediation = Remediation).
- **`NETLOGONDX-Pilot`** — the Entra security group you assign the package to first.

## Benefits
- **One pass, real answer.** Discovery replaces a scavenger hunt across Event Viewer, `nltest`,
  `w32tm`, DNS, and the registry with a single, ordered report.
- **Safe by default.** Four read-only scripts; the only script that changes anything previews first.
- **Local or at scale.** The same scripts triage one device or run fleet-wide via Proactive
  Remediations.
- **Correct IPv6 posture.** Restores the supported dual-stack default without the unsupported
  "just disable IPv6" mistake.
- **Escalation-ready.** One command bundles everything a support case needs.

## Limitations (be honest with buyers)
- **Domain-joined Windows endpoints only.** The scripts short-circuit on non-domain devices. They do
  not diagnose the domain controllers themselves (use AD/DC health tooling for that).
- **Repairs need connectivity to a DC.** `Test-ComputerSecureChannel -Repair` / `nltest /sc_reset`
  require the device to reach a DC and (in some cases) domain credentials; a device with no DC path
  can be diagnosed but not repaired until the path is restored.
- **IPv6 changes need a restart** to take effect.
- **Values can evolve.** Event IDs, `nltest` output, and the `DisabledComponents` bit meanings reflect
  current Microsoft documentation — **verify them for your OS build** rather than assuming.

## The standard diagnostics model
This solution uses **one** repeatable model across our catalog:

> **On a domain-joined Windows endpoint, collect every secure-channel / Netlogon signal read-only,
> diagnose the specific root cause of Event ID 5719, repair it safely (preview-first), keep IPv6 in a
> supported dual-stack configuration, then validate and prevent recurrence — locally or via Intune
> Proactive Remediations.**

Every step follows the repeatable pattern: **Assess → Diagnose → Repair → Validate → Prevent.**
