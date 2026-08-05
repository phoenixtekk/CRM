# 2. Requirements — Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network, Windows baseline) are
covered once in the **Global Requirements — Intune Solutions** document; the items here are specific to
running this **endpoint diagnostics toolkit** for domain secure-channel / Netlogon health.

> **Scope reminder.** These requirements are for running **endpoint PowerShell** on **domain-joined
> Windows devices** — locally or via **Intune Proactive Remediations**. They deliberately do **not**
> include building or diagnosing the domain controllers themselves.

## R1. Domain-joined Windows devices
**Description:** The target devices are joined to an on-premises Active Directory domain (hybrid-joined
is fine; the secure channel is the AD machine-account trust).
**Why:** Event ID 5719 and the secure channel only exist on **AD domain-joined** members; the scripts
short-circuit and report "not domain-joined" otherwise.
**Verify:** On the device run `(Get-CimInstance Win32_ComputerSystem).PartOfDomain` — it returns
**True**; or `systeminfo` shows the **Domain**.
**Implement:** Join the device to the domain (**Settings → Accounts → Access work or school**, or
`Add-Computer`) if it should be a member; Entra-only (AAD-joined, no on-prem AD) devices are out of
scope for the secure-channel checks.

## R2. Local administrator / SYSTEM execution context
**Description:** The scripts run **elevated** locally, or as **SYSTEM** when deployed via Proactive
Remediations.
**Why:** Reading the System event log, querying the secure channel, resetting time, and writing the
IPv6 registry value require elevation.
**Verify:** Launch PowerShell **as administrator** (locally); for Proactive Remediations the platform
runs the scripts as SYSTEM by default.
**Implement:** Right-click **Run as administrator** for local runs; for at-scale runs use the Proactive
Remediations packaging in the Implementation Guide (which runs as SYSTEM).

## R3. Windows PowerShell 5.1+ with in-box modules
**Description:** Windows PowerShell **5.1** (or PowerShell 7) with the in-box `DnsClient` cmdlets
(`Resolve-DnsName`), CIM, and `Microsoft.PowerShell.Archive` (`Compress-Archive`).
**Why:** The toolkit uses **only in-box** Windows capabilities — no modules to install on endpoints —
so it runs unchanged under Proactive Remediations.
**Verify:** `$PSVersionTable.PSVersion` shows 5.1+; `Get-Command Resolve-DnsName, Compress-Archive`
resolve.
**Implement:** These ship with Windows 10/11 and Windows Server 2016+. Ensure the device meets the
supported Windows baseline (Global Requirement **G6**).

## R4. In-box domain tooling present (`nltest`, `w32tm`)
**Description:** The built-in **`nltest.exe`** and **`w32tm.exe`** utilities are available on the
device.
**Why:** Discovery/Validation use `nltest /sc_query` and `/dsgetdc` to view the DC-locator/secure
channel and `w32tm` to read and resync time.
**Verify:** `where.exe nltest` and `where.exe w32tm` both return a path under `System32`.
**Implement:** Both ship in Windows by default; if `nltest` is missing on a client SKU, install the
**RSAT: Active Directory** feature, or rely on the secure-channel and DNS checks that do not need it.

## R5. Network path to a domain controller (for repair)
**Description:** The device can reach a DC on **88 (Kerberos)**, **135 (RPC EPM)**, **389 (LDAP)**, and
**445 (SMB)**.
**Why:** Diagnosis works offline, but **repair** (`Test-ComputerSecureChannel -Repair`,
`nltest /sc_reset`, `w32tm /resync`) requires a reachable DC. Blocked ports are themselves a common
5719 cause.
**Verify:** Run `NETLOGONDX-Discovery.ps1` and read the **DC ports reachable (88/135/389/445)** line,
or `Test-NetConnection <dc> -Port 389`.
**Implement:** On-network, unblock those ports to the DCs / correct the VLAN/firewall; off-network,
connect the corporate VPN/DirectAccess before repairing. Do **not** block AD ports between members and
DCs.

## R6. Correct internal DNS on the device NIC
**Description:** The device's DNS servers are the **internal AD DNS** servers that host the domain's
SRV locator records.
**Why:** The DC Locator finds DCs via `_ldap._tcp.dc._msdcs.<domain>`; a NIC pointed at a public
resolver cannot resolve it, causing 5719.
**Verify:** `Get-DnsClientServerAddress`; and `Resolve-DnsName _ldap._tcp.dc._msdcs.<domain> -Type SRV`
returns DC targets (Discovery reports this).
**Implement:** Set the NIC (or DHCP scope) to the internal AD DNS servers; remove public resolvers from
domain members. Re-run `ipconfig /registerdns` after correcting.

## R7. Intune Proactive Remediations available (for at-scale runs)
**Description:** An Intune plan that includes **Proactive Remediations** (Endpoint analytics) —
Windows Enterprise E3/E5, Windows 365 Enterprise, or equivalent — for fleet-wide detection/remediation.
**Why:** At scale, `NETLOGONDX-Validation.ps1` is the **detection** script and
`NETLOGONDX-Remediation.ps1` the **remediation** script; this needs the Proactive Remediations feature
and enrolled devices (Global Requirement **G4**).
**Verify:** Intune admin center → **Reports → Endpoint analytics → Proactive remediations** is
available.
**Implement:** Assign a qualifying license and onboard Endpoint analytics. Local runs do **not** need
this — you can triage a single device with the scripts alone.

## R8. A place to collect output and escalation bundles
**Description:** The on-device folder **`C:\ProgramData\NETLOGONDX`** (created automatically) and a way
to retrieve files from endpoints for fleet roll-up / escalation.
**Why:** Report writes a per-device CSV and Collect writes an escalation ZIP there; you gather them to
measure coverage and to attach to support cases.
**Verify:** After a run, the folder contains `NETLOGONDX-Report.csv` and/or a
`NETLOGONDX-Collect-*.zip`.
**Implement:** Use your existing endpoint file-collection method (Intune device query/collection,
config-manager, or manual) to retrieve the artifacts. Nothing sensitive is written into the bundle.

## R9. Pilot device and pilot group
**Description:** At least one affected/representative domain-joined pilot device, and (for at-scale) the
**`NETLOGONDX-Pilot`** Entra security group.
**Why:** Every solution is validated on a pilot before fleet rollout, and the Remediation script is
proven in `-WhatIf` preview first.
**Verify:** The pilot device is enrolled (G4) and domain-joined (R1); the pilot group exists (Global
Requirement **G5**).
**Implement:** Create the **`NETLOGONDX-Pilot`** security group (Entra → **Groups → New group →
Security**) and add the pilot device(s); assign the Proactive Remediations package to it first.
