# Requirements

Before you can measure a Windows endpoint, you need to be able to *reach* its signals. This section
lists every prerequisite specific to performance and reliability troubleshooting. The **category-level
Global Requirements** (Entra tenant, Intune subscription, admin roles, enrollment, pilot group,
supported Windows, network access) are in **global-requirements-infrastructure.md** — confirm those
first, then the ones below.

Each requirement uses the same four-part format: **Description / Why / Verify / Implement if missing.**

---

## R1. Local administrator access on the endpoint (or Intune script/remediation delivery)

**Description:** Either interactive local-admin rights on the device under investigation, or the
ability to run PowerShell on it remotely via Intune (Platform scripts / Remediations) or a remote
tool.

**Why:** Reading event logs, performance counters, storage/SMART data, and profile information, and
applying any fix, requires elevation. Most of this solution's measurements need administrator context.

**Verify:** On the device, open **Windows PowerShell** as administrator and run:
`([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)`
— it returns `True`. For remote delivery, confirm in **Intune → Devices → Scripts and remediations**
that you can create and assign a script.

**Implement if missing:** Add your account to the device's local **Administrators** group (or use an
Entra role that grants it), or deliver the scripts through **Intune → Devices → Scripts and
remediations** (which runs as SYSTEM, an elevated context).

---

## R2. Windows Event Log access (Diagnostics-Performance, System, Application)

**Description:** Read access to the endpoint's event logs, specifically
**Microsoft-Windows-Diagnostics-Performance/Operational**, **System**, and **Application**.

**Why:** Boot/sign-in timing (event IDs 100–110), bugchecks (System ID 41 and 1001), and application
crashes/hangs (Application ID 1000/1002) all come from these logs. They are the primary evidence for
the Boot, Sign-in, and Stability branches.

**Verify:** On the device run
`Get-WinEvent -LogName 'Microsoft-Windows-Diagnostics-Performance/Operational' -MaxEvents 1` and
`Get-WinEvent -LogName System -MaxEvents 1` — both return an event without an access error.

**Implement if missing:** Run elevated (see R1). If the Diagnostics-Performance log is empty or
disabled, enable it: `wevtutil sl "Microsoft-Windows-Diagnostics-Performance/Operational" /e:true`,
then let the device go through a normal boot cycle so events are written.

---

## R3. Performance counter access

**Description:** The ability to read live Windows performance counters (Processor, Memory, PhysicalDisk,
System) via `Get-Counter`.

**Why:** The steady-state Resource branch measures CPU %, available/committed memory, and disk %
active time / queue length by sampling counters over a window. Without counter access you cannot
quantify "it's slow while I work."

**Verify:** Run `Get-Counter '\Processor(_Total)\% Processor Time' -MaxSamples 1` — it returns a
sample value.

**Implement if missing:** Ensure the **Performance Logs & Alerts** / **Performance Counter DLL Host**
services are not disabled, and that your account is in the local **Performance Monitor Users** group
(or is an administrator). If counters are corrupt, rebuild them: `lodctr /R` (elevated).

---

## R4. Storage / SMART health readability

**Description:** The Storage subsystem exposes physical-disk health, media type, and failure-prediction
(`Get-PhysicalDisk`, and the `MSStorageDriver_FailurePredictStatus` WMI class).

**Why:** The Storage-health branch must rule out a failing or worn drive and low free space — a
physical cause that makes boot, sign-in, and steady-state all slow and can cause crashes. This is the
layer you check early.

**Verify:** Run `Get-PhysicalDisk | Select FriendlyName, MediaType, HealthStatus` — it lists the
drive(s) with a **HealthStatus** (Healthy / Warning / Unhealthy). Then
`Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus` returns a
`PredictFailure` value on most physical hardware.

**Implement if missing:** Update the storage controller / disk drivers so the health APIs are populated.
On some virtual machines SMART is not surfaced — record "SMART unavailable (virtual)" rather than a
false pass. Ensure at least ~15% free space so cleanup and paging have room.

---

## R5. Intune Endpoint analytics (where available)

**Description:** **Endpoint analytics** enabled in Intune, providing **Startup performance** (boot +
sign-in timing) and **Application reliability** across the fleet.

**Why:** Endpoint analytics gives you a *fleet-wide, historical* view of boot and sign-in times and
crash-prone apps — the baseline you compare a single slow device against. It turns "is this device
slow?" into "is this device slow *relative to the fleet*?"

**Verify:** In **Intune → Reports → Endpoint analytics**, the **Startup performance** and
**Application reliability** tabs load with data. (Data appears a few days after onboarding.)

**Implement if missing:** In **Intune → Reports → Endpoint analytics → Settings**, enable Endpoint
analytics and choose the device scope (all Intune-managed devices, or a group). Wait for the initial
data collection. **Endpoint analytics requires the appropriate Intune/Windows Enterprise
licensing** — if it is unavailable in your tenant, this solution's per-device scripts still deliver
the same measurements locally; you simply lose the pre-built fleet baseline and read it from the
**WINPERF-Report.ps1** roll-up instead.

---

## R6. PowerShell 5.1+ and script execution

**Description:** Windows PowerShell 5.1 (built into supported Windows) or PowerShell 7, with a policy
that allows the solution's read-only scripts to run.

**Why:** All five scripts are PowerShell. Discovery, Validation, and Report are read-only; Remediation
and Set-ScopeTargeting default to a preview (`-WhatIf`) mode.

**Verify:** Run `$PSVersionTable.PSVersion` (expect 5.1 or higher) and `Get-ExecutionPolicy`.

**Implement if missing:** Run scripts with `powershell -ExecutionPolicy Bypass -File .\script.ps1`
(per-process, changes nothing permanently), or set a signed-script policy via Intune. When delivering
through Intune Remediations, execution policy is handled by the platform.

---

## R7. Microsoft Graph access for scope targeting (Set-ScopeTargeting only)

**Description:** The ability to sign in to Microsoft Graph with a scope that can read and manage Entra
group membership (`Group.ReadWrite.All` or equivalent), used only by **WINPERF-Set-ScopeTargeting.ps1**.

**Why:** The scope-targeting script builds and populates the pilot / rollout Entra security group used
to target measurement or remediation at a controlled set of devices. This keeps you piloting before
fleet-wide action, per the deployment model.

**Verify:** Run `Connect-MgGraph -Scopes 'Group.ReadWrite.All'` and confirm it connects with the
consented scope (the **Microsoft.Graph** PowerShell module must be installed:
`Get-Module Microsoft.Graph -ListAvailable`).

**Implement if missing:** Install the module — `Install-Module Microsoft.Graph -Scope CurrentUser` —
and have an Intune/Entra administrator consent to the `Group.ReadWrite.All` scope. The script defaults
to `-WhatIf`, so you can validate the plan before any group is changed.
