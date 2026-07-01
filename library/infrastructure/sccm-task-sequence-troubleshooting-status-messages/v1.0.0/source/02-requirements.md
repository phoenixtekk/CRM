# 2. Requirements Guide — SCCM Task Sequence Troubleshooting & Status Message Analysis

Verify **every** requirement before you rely on the runbook. Each entry: **Description · Why ·
Verify · Implement-if-missing.** Category-wide prerequisites are in
`global-requirements-infrastructure.md`.

## 2.1 Configuration Manager console access
**Description:** The Configuration Manager console connected to your primary site, on a current build.
**Why:** You diagnose deployment state, status messages, and task-sequence deployments from the console.
**Verify:** Launch the console; it connects and shows **Software Library**, **Monitoring**, and **Assets and Compliance**.
**Implement:** Install the console from `<CMinstall>\tools\ConsoleSetup` (or Software Center) and point it at the site server.

## 2.2 Read access to task sequences and deployments
**Description:** An RBAC role that grants read on task sequences, deployments, and status messages (for example **Read-only Analyst**, or **OS Deployment Manager** for changes).
**Why:** You must see the task-sequence deployments, their targeted collections, and the status messages they raise.
**Verify:** Console → **Software Library → Operating Systems → Task Sequences** lists sequences; **Monitoring → Deployments** shows OSD deployments.
**Implement:** Administration → **Security → Administrative Users**; assign a role scoped to the relevant collections.

## 2.3 Configuration Manager PowerShell module
**Description:** The ConfigurationManager PowerShell module (ships with the console).
**Why:** The discovery, validation, report, and targeting scripts use `Get-CM*` cmdlets against the site.
**Verify:** In the console, use the top-left dropdown → **Connect via Windows PowerShell ISE**, or run `Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"` — no error.
**Implement:** Install the console (2.1); the module is at `<console>\bin\ConfigurationManager.psd1`. Run scripts from a session with the site drive (`PS XYZ:\>`).

## 2.4 Status message queries (Monitoring workspace)
**Description:** Access to **Monitoring → System Status → Status Message Queries**, plus the ability to save custom queries.
**Why:** Status message queries are how you pull the task-sequence execution messages (IDs `11124`, `11170`, `11127`) for a device or collection.
**Verify:** Console → **Monitoring → System Status → Status Message Queries** opens and you can run the built-in queries.
**Implement:** Granted by the RBAC role in 2.2; confirm the operator can create and save a query.

## 2.5 WMI / CIM access to the site's SMS provider
**Description:** Read access to the `root\SMS\site_<code>` WMI namespace (the SMS provider) from the operator's workstation.
**Why:** The report script queries the `SMS_StatusMessage` class (and related classes) to summarize failures and exit codes.
**Verify:** Run `Get-CimInstance -Namespace "root\SMS\site_<code>" -ClassName SMS_StatusMessage -ComputerName <SMSProvider> -Filter "MessageID=11124"` — returns rows or an empty set, not an access error.
**Implement:** The RBAC role in 2.2 grants provider access; ensure the account can reach the SMS Provider server over WMI (firewall/DCOM).

## 2.6 Log access on the client and in WinPE
**Description:** The ability to read `smsts.log` at every phase path (WinPE and full OS) and a log viewer.
**Why:** Status messages point at the step; `smsts.log` confirms the exact reason. You must be able to open the phase-correct log.
**Verify:** On a failed client, `c:\windows\ccm\logs\smsts.log` exists (or the `_SMSTaskSequence` path); in WinPE, press **F8** at a command prompt and browse `x:\windows\temp\smstslog`.
**Implement:** Enable command-line support (F8) on the boot image (**Software Library → Boot Images → Properties → Customization → Enable command support (testing)**); install **CMTrace/OneTrace** for reading logs.

## 2.7 Exit-code / status-message references
**Description:** A reference for Windows/MSI exit codes and Configuration Manager status message IDs.
**Why:** Mapping a captured exit code to a root cause is faster with a reference than by memory.
**Verify:** You have the exit-code and status-ID tables (this solution's Overview, §1) to hand.
**Implement:** Use the tables in `01-solution-overview.md`; the report script also prints the codes it finds.

## 2.8 A reproducible failure to pilot on
**Description:** At least one real, current task-sequence failure (a device or collection) to run the runbook against.
**Why:** The runbook is validated by diagnosing actual failures — not by reading it.
**Verify:** Console → **Monitoring → Deployments** shows an OSD deployment with a `Failed`/`Error` device.
**Implement:** Use a currently failing build; if none exists, re-run a known-bad task sequence on a test device to generate one.

---
## Checklist
- [ ] Configuration Manager console connects to the site
- [ ] RBAC read on task sequences, deployments, and status messages
- [ ] ConfigurationManager PowerShell module imports
- [ ] Status Message Queries accessible in Monitoring
- [ ] WMI/CIM access to `root\SMS\site_<code>` (SMS_StatusMessage)
- [ ] `smsts.log` readable at WinPE + full-OS paths; F8 enabled; CMTrace available
- [ ] Exit-code / status-ID reference on hand
- [ ] A real failure identified to pilot the runbook on
