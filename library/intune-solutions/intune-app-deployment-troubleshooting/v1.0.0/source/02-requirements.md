# Requirements

Before you run the Diagnostic Playbook or the scripts, confirm the items below. The
**category-level global requirements** (Entra tenant, Intune subscription, enrolled devices,
supported Windows baseline, network access) are listed in
`global-requirements-intune-solutions.md` and are assumed here. This file covers the requirements
specific to **troubleshooting app deployments**.

Each requirement is written as **Description / Why / Verify / Implement if missing.**

---

## R1. Intune role that can read apps and device install status

**Description:** An Entra/Intune role that grants read access to **Apps**, their **assignments**,
and per-device **install status**. **Intune Administrator** covers everything in this solution;
**Help Desk Operator** or a custom role with **Managed apps → Read** and **Organization → Read**
is enough for the read-only Discovery, Validation, and Report scripts.

**Why:** Every diagnostic step reads app configuration and install/detection state. Without app read
rights the console shows nothing and the scripts return empty results.

**Verify:** Sign in to `https://intune.microsoft.com`, open **Apps → All apps**, and open any app's
**Device install status**. If you can see the app list and per-device status, you have read access.
For roles: Intune → **Tenant administration → Roles → All roles** and confirm your assignment.

**Implement:** Intune → **Tenant administration → Roles → All roles** → select **Help Desk Operator**
(or **Intune Administrator** for remediation) → **Assignments → Assign** → add your account and a
scope group. Assign remediation rights (R2) only to the operators who will run fixes.

---

## R2. Intune role that can modify apps and assignments (remediation only)

**Description:** A role with **write** access to apps and assignments — **Intune Administrator** or a
custom role with **Managed apps → Read/Update/Assign**.

**Why:** The Remediation and Set-ScopeTargeting scripts change assignments (for example, adding a
pilot group) and, when you approve it, trigger re-attempts. The read-only scripts never need this.

**Verify:** In Intune, open an app → **Properties → Assignments → Edit**. If you can add a group and
save, you have write access.

**Implement:** Assign **Intune Administrator**, or build a custom role
(**Tenant administration → Roles → Create**) granting **Managed apps** Read, Update, and Assign, and
assign it to the remediation operators only.

---

## R3. Microsoft Graph read access for the scripts

**Description:** Delegated Microsoft Graph permissions for the PowerShell scripts:
`DeviceManagementApps.Read.All` and `DeviceManagementManagedDevices.Read.All` for the read-only
scripts, plus `DeviceManagementApps.ReadWrite.All` for Remediation and Set-ScopeTargeting.

**Why:** The scripts read app definitions, assignments, and per-device install/detection state
through Graph. Remediation writes assignments, so it needs the ReadWrite scope.

**Verify:** Run any read-only script; at the first `Connect-MgGraph` prompt, sign in and **consent**
to the listed scopes. If it returns app data, access is working. You can also confirm granted
delegated permissions in Entra → **Enterprise applications → Microsoft Graph Command Line Tools →
Permissions**.

**Implement:** Install the SDK — `Install-Module Microsoft.Graph -Scope CurrentUser`. Each script
calls `Connect-MgGraph` with the scopes it needs; an Intune Administrator can consent on first use.
If your tenant requires admin consent for the Graph Command Line Tools app, have a Global
Administrator grant it once.

---

## R4. Device log access (Intune Management Extension logs)

**Description:** The ability to read the Intune Management Extension logs on an affected Windows
device, at
`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\` — chiefly
`IntuneManagementExtension.log` and `AppWorkload.log`.

**Why:** These logs are the **only** place that records the exact requirement result, download path,
install command line, returned exit code, and detection result. Graph reports the *state*; the logs
explain *why*.

**Verify:** On a device with the app assigned, open
`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`. If the file
exists and shows recent entries, you have log access. (`CMTrace` or `Notepad` both open it.)

**Implement:** Get local admin or remote-file access to a sample failing device, or collect the logs
through **Intune → Devices → the device → Collect diagnostics**, which packages the Management
Extension logs for download. Keep the folder path 'your-log-path' handy for the playbook.

---

## R5. A representative failing device (or device group)

**Description:** At least one enrolled device that reproduces the failure, ideally in a small
**pilot** security group.

**Why:** Diagnosis and validation both need a device whose real state you can read in Graph and whose
logs you can open. Fixing against a live fleet without a control device makes it impossible to prove
the fix worked.

**Verify:** Intune → **Devices → All devices**; confirm the device is present, **compliant**, and
recently synced (**last check-in** within a day).

**Implement:** Add a sample device to a pilot group (Entra → **Groups**), assign the app to that
group, and use `INTAPPDX-Set-ScopeTargeting.ps1` to manage the pilot targeting safely.

---

## R6. PowerShell 5.1+ or PowerShell 7 with the Microsoft Graph SDK

**Description:** A workstation running Windows PowerShell 5.1 or PowerShell 7 with the
**Microsoft.Graph** module installed.

**Why:** All five scripts use the Microsoft Graph PowerShell SDK.

**Verify:** Run `$PSVersionTable.PSVersion` (expect 5.1 or 7.x) and `Get-Module Microsoft.Graph
-ListAvailable` (expect a version to be listed).

**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Run the scripts with
`powershell -ExecutionPolicy Bypass -File .\<script-name>.ps1`.
