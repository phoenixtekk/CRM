# Requirements

Confirm every item below **before** you start the Diagnostic Playbook. The category-level
prerequisites (Entra tenant, Intune subscription, enrolled devices, supported Windows baseline,
network access) are in `global-requirements-intune-solutions.md` and are assumed here. This file
covers what is specific to **diagnosing and fixing Win32 app removal**.

Each requirement is written as **Description / Why required / How to verify / How to implement if
missing.**

---

## R1. An Intune role that can read apps, assignments, and device install status

**Description:** An Entra/Intune role granting read access to **Apps**, their **Assignments**, their
**Properties** (Program, Detection rules, Return codes), and per-device **Device install status**.
**Intune Administrator** covers everything in this solution. For the read-only scripts,
**Help Desk Operator** — or a custom role with **Managed apps → Read** and **Organization → Read** —
is sufficient.

**Why required:** Every branch of the playbook begins by reading the app's uninstall command,
detection rules, return-code table, and the per-device state. Without app read rights the console
shows nothing and the scripts return empty results.

**How to verify:** Sign in to `https://intune.microsoft.com`. Go to
**Intune admin center > Apps > All apps**, open any Win32 app, and confirm you can open both
**Properties** and **Device install status**. Then go to
**Intune admin center > Tenant administration > Roles > All roles** and confirm your role assignment
is listed.

**How to implement if missing:** Go to
**Intune admin center > Tenant administration > Roles > All roles**, select **Help Desk Operator**,
select **Assignments**, click **Assign**, name the assignment `APPUNIN – Read Only Operators`, add
your account under **Admin Groups**, set the **Scope (Groups)** to the groups you support, and click
**Create**.

---

## R2. An Intune role that can modify apps and assignments (remediation only)

**Description:** Write access to apps and their assignments — **Intune Administrator**, or a custom
role granting **Managed apps → Read, Update, Assign**.

**Why required:** Fixing a removal failure means editing the app's **Uninstall command**, its
**Detection rules**, or its **Return codes**, and removing a conflicting **Required** assignment.
The read-only Discovery, Validation, Report, and LogParser scripts never need this; only
`APPUNIN-Remediation.ps1` does.

**How to verify:** Go to **Intune admin center > Apps > All apps > _<your app>_ > Properties**,
click **Edit** next to **Program**, and confirm the **Uninstall command** field is editable and the
**Review + save** button is available. Cancel without saving.

**How to implement if missing:** Go to
**Intune admin center > Tenant administration > Roles > All roles > Create**, choose **Windows
(Custom role)**, name it `APPUNIN – Removal Operators`, grant **Managed apps** → **Read**,
**Update**, **Assign**, click **Create**, then open the role and use **Assignments > Assign** to add
only the operators who will apply fixes.

---

## R3. Microsoft Graph PowerShell SDK access with the correct scopes

**Description:** Delegated Microsoft Graph permissions for the five scripts:

| Script | Scopes needed |
|---|---|
| `APPUNIN-Discovery.ps1` | *(none — runs locally on the device, no Graph)* |
| `APPUNIN-Validation.ps1` | `DeviceManagementApps.Read.All`, `Group.Read.All`, `DeviceManagementManagedDevices.Read.All` |
| `APPUNIN-Report.ps1` | `DeviceManagementApps.Read.All`, `DeviceManagementManagedDevices.Read.All` |
| `APPUNIN-LogParser.ps1` | *(none — parses log files, no Graph)* |
| `APPUNIN-Remediation.ps1` | `DeviceManagementApps.ReadWrite.All` |

**Why required:** The assignment-conflict detector must read every assignment on the app *and*
resolve group membership to see whether one device sits in both an install group and an uninstall
group. The reporter reads per-device uninstall state and error codes. The remediation script writes
the corrected uninstall command, detection rule, or assignment.

**How to verify:** Run `Get-Module Microsoft.Graph -ListAvailable` and confirm a version is listed.
Then run `Connect-MgGraph -Scopes "DeviceManagementApps.Read.All"`, sign in, and run
`Get-MgContext` — confirm the **Scopes** property contains the scope you requested.

**How to implement if missing:** Install the SDK with
`Install-Module Microsoft.Graph -Scope CurrentUser`. Each script calls `Connect-MgGraph` with the
scopes it needs and prompts for consent on first run. If your tenant blocks user consent, have a
Global Administrator grant admin consent once at
**Entra admin center > Applications > Enterprise applications > Microsoft Graph Command Line Tools >
Permissions > Grant admin consent**.

> **US Government tenants (GCC High / DoD):** the scripts accept a `-GraphEnvironment` parameter.
> Pass `-GraphEnvironment USGov` for GCC High or `-GraphEnvironment USGovDoD` for DoD, which makes
> the script call `Connect-MgGraph -Environment USGov` (or `USGovDoD`) and target
> `https://graph.microsoft.us` instead of `https://graph.microsoft.com`. The admin console is
> `https://endpoint.microsoft.us`. See the note at the end of this file.

---

## R4. Local administrator access to a representative failing device

**Description:** Local administrator rights (or the ability to run as **SYSTEM**) on at least one
enrolled Windows device that reproduces the removal failure.

**Why required:** The truth about a removal failure lives on the device, not in the console. You need
to read the uninstall registry keys, confirm whether the cached MSI still exists, run the uninstall
command by hand, and capture a verbose MSI log. `APPUNIN-Discovery.ps1` reads all of that and must
run elevated on the device.

**How to verify:** On the device, open PowerShell as administrator and run
`Test-Path 'C:\Windows\Installer'` (expect `True`) and
`Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'` (expect a list of keys).

**How to implement if missing:** Use **Intune admin center > Devices > Windows > Windows devices >
_<device>_ > ... > Collect diagnostics** to pull the logs remotely, or add your account to the local
Administrators group on a lab device that reproduces the failure. Create the evidence folder
`C:\ProgramData\APPUNIN\Evidence` on that device — every branch of the playbook writes its evidence
there.

---

## R5. Access to the Intune Management Extension logs

**Description:** Read access to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\` on the
failing device — specifically `IntuneManagementExtension.log`, `AppWorkload.log`, and
`AgentExecutor.log`.

**Why required:** These logs are the **only** place that records, in order: the intent the IME
resolved for the app, the pre-uninstall detection result, the exact uninstall command line that was
executed, the process exit code it returned, and the post-uninstall detection result. Graph tells you
*what* state the device is in; these logs tell you *why*.

**How to verify:** On the device, open
`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` (note:
`ProgramData` is hidden — type the full path into File Explorer's address bar). Confirm the file
exists and has entries from the last 24 hours.

**How to implement if missing:** If the folder is absent, the Intune Management Extension is not
installed — it installs automatically when a Win32 app or PowerShell script is assigned to the
device. Assign any Win32 app to the device, wait for a sync, and re-check. To collect the logs
without touching the device, use **Intune admin center > Devices > Windows > Windows devices >
_<device>_ > ... > Collect diagnostics**, then download the resulting package from the **Device
diagnostics** tab. Install **CMTrace** (or use Notepad) to read them.

---

## R6. The app's original packaging record — or the ability to reconstruct it

**Description:** The record of how the app was packaged: the **MSI ProductCode** (per version), the
silent uninstall switches for an EXE installer, the install context (per-machine vs per-user), and
where the source installer is archived.

**Why required:** Branches C and E of the playbook turn on knowing the *correct* uninstall command.
If the ProductCode drifted between versions, or the vendor's EXE uses a different switch for
uninstall than for install, you cannot author a correct uninstall command from the console alone.

**How to verify:** Go to **Intune admin center > Apps > All apps > _<your app>_ > Properties >
Program** and read the current **Uninstall command**. Then run `APPUNIN-Discovery.ps1` on a device
that still has the app, and compare the command to the `UninstallString` /
`QuietUninstallString` the installer actually registered. They must match.

**How to implement if missing:** Run `APPUNIN-Discovery.ps1` on any device that still has the app —
it resolves the real ProductCode, the registered uninstall string, and whether the cached MSI is
still present, which is enough to reconstruct a correct uninstall command. For EXE installers, get
the silent-uninstall switch from the vendor's documentation; do not guess it. Record the result in
the app's **Notes** field (**Properties > App information > Notes**) so it is never lost again.

---

## R7. A pilot device group and a change window

**Description:** The **Assigned** Entra security group `APPUNIN – Uninstall – Pilot` containing 3–10
representative devices, plus an agreed window in which software may disappear from those devices.

**Why required:** Removal is destructive and, for most business software, not trivially reversible —
user data, licences, and local configuration can go with it. Every fix in this playbook is proven on
the pilot group before it reaches `APPUNIN – Uninstall – Production`.

**How to verify:** Go to **Entra admin center > Groups > All groups** and confirm
`APPUNIN – Uninstall – Pilot` exists, that its **Membership type** is **Assigned**, and that it has
members.

**How to implement if missing:** Go to **Entra admin center > Groups > All groups > New group**. Set
**Group type** = **Security**, **Group name** = `APPUNIN – Uninstall – Pilot`, **Membership type** =
**Assigned**, add your pilot devices under **Members**, and click **Create**. Repeat to create
`APPUNIN – Uninstall – Production` and `APPUNIN – Uninstall – Exclusions`.

---

## R8. PowerShell 5.1 or PowerShell 7

**Description:** Windows PowerShell 5.1 (built into Windows) or PowerShell 7 on the operator
workstation and on the device.

**Why required:** All five scripts target 5.1+ syntax. `APPUNIN-Discovery.ps1` and
`APPUNIN-LogParser.ps1` run on the device with no external module dependency; the Graph scripts need
the SDK from R3.

**How to verify:** Run `$PSVersionTable.PSVersion` and confirm **5.1** or **7.x**.

**How to implement if missing:** Windows 10/11 ships with 5.1. Install PowerShell 7 from the
Microsoft Store or `winget install Microsoft.PowerShell`. Run the scripts with
`powershell -ExecutionPolicy Bypass -File .\<script-name>.ps1`.

---

## Government (GCC / GCC High / DoD) note

The removal behaviour documented in this solution — intent reconciliation, detection-gated uninstall,
exit-code mapping, the Windows Installer registry and cache layout, and the IME log paths — is
**Windows and Intune service behaviour and is the same in Government tenants**. What differs is
**where you connect**, not what you do:

| Surface | Commercial | US Government |
|---|---|---|
| Admin console | `https://intune.microsoft.com` | `https://endpoint.microsoft.us` |
| Microsoft Graph endpoint | `https://graph.microsoft.com` | `https://graph.microsoft.us` |
| `Connect-MgGraph` environment | `-Environment Global` (default) | `-Environment USGov` (GCC High) or `-Environment USGovDoD` (DoD) |
| Sign-in authority | `login.microsoftonline.com` | `login.microsoftonline.us` |

Every script in this package accepts `-GraphEnvironment Global | USGov | USGovDoD` and passes it
through to `Connect-MgGraph`. Wherever this documentation shows `https://intune.microsoft.com`,
Government operators substitute `https://endpoint.microsoft.us`; the blade names and navigation
paths are otherwise identical. Feature-availability timing in GCC High and DoD can lag Commercial —
**verify for GCC High** against Microsoft's US-sovereign-cloud documentation before assuming a newly
released Intune app feature is present in your tenant.
