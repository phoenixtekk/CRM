# Executive Summary — Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

Domain-joined Windows devices intermittently fail to log on, drop mapped drives, or lose Group Policy —
and the System log fills with **Netlogon Event ID 5719: "There are currently no logon servers available
to service the logon request."** Behind that one message hides a small set of very different root
causes: a **broken secure channel** (the machine account/trust password out of sync), **DNS** that can
no longer locate a domain controller, **clock skew** that breaks Kerberos, **blocked network ports** to
the DCs, **no reachable DC** on the subnet at boot, a **NIC/power-management race** that drops the link
before Netlogon starts — and, surprisingly often, an **invalidly disabled IPv6 stack**. This toolkit
finds which one it is and fixes it, on one device or ten thousand.

**A diagnostics toolkit, not a config baseline.** This package is **read-heavy endpoint PowerShell**
that runs **locally on the affected Windows device** or **at scale via Intune Proactive Remediations**.
It follows the repeatable diagnostics arc — **Assess → Diagnose → Repair → Validate → Prevent** — and
resolves the two recurring **availability findings** it is built around: **Event ID 5719 (Netlogon)**
and **"set IPv6 to a recommended configuration."**

The five scripts are deliberately safe by default:

- **`NETLOGONDX-Discovery.ps1`** — collects the whole picture in one pass: recent 5719 and related
  secure-channel events, `Test-ComputerSecureChannel`, `nltest /sc_query` and `/dsgetdc`, DNS SRV
  resolution of the DC locator records, `w32tm` time state, DC port reachability (88/135/389/445), and
  the IPv6 `DisabledComponents` registry value. **Read-only.**
- **`NETLOGONDX-Validation.ps1`** — a hard pass/fail gate (and a ready-made Proactive Remediations
  **detection** script): secure channel healthy, time in sync, DNS resolves DCs, IPv6 not invalidly
  disabled. **Read-only.**
- **`NETLOGONDX-Report.ps1`** — a readable + CSV health summary for fleet roll-up. **Read-only.**
- **`NETLOGONDX-Remediation.ps1`** — repairs the secure channel (`Test-ComputerSecureChannel -Repair`,
  falling back to `nltest /sc_reset`), resyncs time, and **corrects an invalid IPv6 `DisabledComponents`
  back to the recommended value**. **Defaults to `-WhatIf`** — it previews every change and modifies
  nothing until you pass `-WhatIf:$false`.
- **`NETLOGONDX-Collect.ps1`** — bundles the logs and command output into one ZIP for escalation.
  **Read-only.**

**On IPv6, the guidance is explicit and correct:** IPv6 should stay **ENABLED** (the dual-stack
default). The toolkit **never disables IPv6** — it identifies **invalid** `DisabledComponents` values
(such as `0xffffffff`) and corrects them back to a **supported** value (`0x0` default, or `0x20`/`0x11`
only with justification). Disabling IPv6 outright breaks **DirectAccess, Remote Assistance, and
HomeGroup** and is **not covered by Microsoft's testing**.

The package delivers the complete, field-tested method — written so a single administrator can follow
it end to end — with exact steps to run the toolkit locally or deploy it via Proactive Remediations for
at-scale detection and remediation, plus testing and troubleshooting guides with clear pass/fail gates.

**Outcome:** the real cause of Event ID 5719 identified and repaired on any domain-joined Windows
device, IPv6 restored to a supported configuration, and a repeatable health check you can run on the
whole fleet — without a consulting engagement and without touching how devices are enrolled.
