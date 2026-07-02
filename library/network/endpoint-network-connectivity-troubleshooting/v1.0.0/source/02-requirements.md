# Requirements

Before you run the diagnostic method, confirm the items below. These are **in addition to** the
category-level prerequisites in *Global Requirements — Network* (see
`global-requirements-network.md`). Each requirement is written as **Description / Why / Verify /
Implement if missing** so a competent-but-novice technician can confirm each one by clicking.

> This is endpoint-side **troubleshooting**. You do not need to own or reconfigure the proxy, VPN, or
> firewall to use this toolkit — you need enough access to *observe* the endpoint and *know what it
> should be reaching*. Where a change on network gear is required, this toolkit produces the evidence
> to hand to that team.

## R1. Access to the affected endpoint
**Description:** Interactive or remote access to the Windows device that is failing, as a user who can
open an elevated PowerShell prompt.
**Why:** The whole method proves the block *from the endpoint*. You must run local checks (DNS, proxy,
routing, port tests) on the machine that is actually failing — not on your own working machine.
**Verify:** Sign in to the device (RDP, Intune remote help, or in person). Right-click **Start →
Windows PowerShell (Admin)** and confirm it opens with "Administrator" in the title bar.
**Implement if missing:** Arrange remote access (Intune → **Devices → Remote help**, or your remote
support tool). If the user cannot elevate, have them run the read-only Discovery/Validation scripts,
which do not require elevation for their core checks.

## R2. A known-good control endpoint
**Description:** A second, comparable device on the same or a similar network that **can** reach the
target service.
**Why:** Isolation needs a control. "Both fail" points to the service or a shared upstream layer;
"only this one fails" points to the endpoint's own config (DNS, proxy, VPN, local firewall). Without a
control you cannot separate "the service is down" from "this endpoint is misconfigured."
**Verify:** From the control device, confirm it reaches the target service (open the app / URL).
**Implement if missing:** Use any nearby working device — a colleague's machine, a spare, or a VM on
the same network segment. Note whether it is on the same subnet/VLAN/VPN state as the failing one.

## R3. The exact test targets (name, IP, port, URL)
**Description:** A written list of what the endpoint is *supposed* to reach: the DNS name(s), the
expected IP or IP range, the TCP/UDP port(s), and the full URL(s) of the failing service.
**Why:** You cannot test reachability without knowing the destination. "The app is broken" is not a
target; `app.example.com`, `443`, `https://app.example.com/health` is. Precise targets make each
layer's pass/fail unambiguous.
**Verify:** For each service, you can state its FQDN, expected port, and a URL you can request. The
`NETDX-Validation.ps1` script consumes exactly this list (a CSV of `Name,Host,Port,Url`).
**Implement if missing:** Get the targets from the app vendor's connectivity/firewall documentation,
the service's admin portal, or by capturing them on the known-good control endpoint (see the Playbook
for how to observe what a working device connects to).

## R4. Knowledge of the expected network path
**Description:** Awareness of whether the endpoint is *supposed* to go **direct**, **through a
proxy/PAC**, or **through a VPN tunnel** to reach each target, and the expected proxy host / PAC URL /
VPN profile name if any.
**Why:** A "wrong route" is only wrong relative to what was intended. To judge the proxy and VPN
layers you must know the intended behavior — e.g. "this internal app must go through the VPN tunnel"
or "internet traffic should egress via the corporate proxy `your-proxy-host:8080`."
**Verify:** You can state, per target, the intended path (direct / proxy / VPN) and the expected proxy
or VPN identifiers. Discovery reports the *actual* posture so you can compare.
**Implement if missing:** Ask the network/proxy/VPN owner for the intended egress design, or read the
managed proxy/VPN configuration profile pushed by Intune (Intune → **Devices → Configuration**).

## R5. PowerShell 5.1+ (Windows PowerShell) on the endpoint
**Description:** Windows PowerShell 5.1 (built into Windows 10/11) or PowerShell 7+, able to run the
included scripts.
**Why:** The scripts use standard cmdlets (`Resolve-DnsName`, `Test-NetConnection`,
`Get-NetRoute`, `netsh`) available on managed Windows.
**Verify:** In PowerShell run `$PSVersionTable.PSVersion` and confirm the major version is 5 or
higher.
**Implement if missing:** Windows PowerShell 5.1 ships with Windows; if it is somehow absent, install
it via **Settings → Apps → Optional features**, or install PowerShell 7 from the Microsoft Store.

## R6. Microsoft Graph PowerShell module (only for scope targeting)
**Description:** The `Microsoft.Graph` PowerShell module, needed **only** for
`NETDX-Set-ScopeTargeting.ps1` (building a pilot Entra group).
**Why:** Scope targeting creates/updates an Entra security group of pilot devices via Graph; the other
four scripts do not need it.
**Verify:** Run `Get-Module Microsoft.Graph -ListAvailable`. If it returns nothing, install it.
**Implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`. The scope-targeting
script requests the `Group.ReadWrite.All` and `GroupMember.ReadWrite.All` delegated scopes at sign-in.

## R7. Permission to run reset actions (only for remediation)
**Description:** Local admin rights on the endpoint and organizational approval to run **safe, local**
resets (flush DNS cache, reset route cache, clear a stale local proxy setting).
**Why:** `NETDX-Remediation.ps1` performs only local, reversible actions, but they still touch the
endpoint's networking state, so they run with `-WhatIf` on by default and should be approved.
**Verify:** You can open an elevated PowerShell prompt (see R1) and change control permits a local
reset on the affected device.
**Implement if missing:** Obtain local admin and a change approval, or keep the remediation script in
`-WhatIf` (preview) mode and hand the previewed actions to whoever is authorized.
