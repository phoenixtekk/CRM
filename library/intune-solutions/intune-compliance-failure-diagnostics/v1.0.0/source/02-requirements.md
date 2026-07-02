# Requirements

The category-level prerequisites (Entra tenant, Intune subscription, enrollment, Windows
baseline, network access) are covered in **global-requirements-intune-solutions.md**.
Confirm those first. Below are the prerequisites **specific to diagnosing compliance
failures** — the roles, Graph read access, and device access you need to read per-setting
state, evaluation timing, and Conditional Access impact, and to remediate safely.

Each item is written as **Description / Why / Verify / Implement if missing.**

---

## R1. Role to read compliance policies and device state

**Description:** An Intune role that can **read** compliance policies, device compliance
state, and per-setting status across the fleet. **Intune Administrator** covers everything;
for a read-only operator, the built-in **Help Desk Operator** or a custom role with
**Device compliance policies: Read** and **Organization: Read** is enough for diagnosis.

**Why:** The whole method is reading per-setting failure reasons, grace configuration, and
device compliance state. Without read on compliance objects you cannot see *which* setting
failed.

**Verify:** Sign in to `https://intune.microsoft.com`. Open **Devices → Compliance** and
confirm the policy list loads; open any device → **Device compliance** and confirm you can
expand a policy to per-setting state.

**Implement if missing:** Entra → **Roles and administrators** → assign **Intune
Administrator** (or **Help Desk Operator** for read-only). For least privilege, Intune →
**Tenant administration → Roles → Create** a custom role granting **Device compliance
policies: Read** and assign it with a scope group.

---

## R2. Role to read Conditional Access and sign-in logs

**Description:** An Entra role that can **read** Conditional Access policies and **Sign-in
logs**. **Security Reader** grants both read-only; **Conditional Access Administrator** is
needed only if you will edit CA.

**Why:** The Conditional Access blast radius — *who* is blocked by a non-compliant device
and *which* CA policy did it — is read from CA policy definitions and the sign-in logs.
This is how you scope impact before touching anything.

**Verify:** Entra → **Protection → Conditional Access → Policies** lists policies; Entra →
**Monitoring & health → Sign-in logs** loads and can be filtered by user.

**Implement if missing:** Entra → **Roles and administrators** → assign **Security
Reader** to the operator (add **Conditional Access Administrator** only if remediation will
edit CA).

---

## R3. Microsoft Graph read access for the scripts

**Description:** The five PowerShell scripts use the **Microsoft Graph PowerShell SDK** and
sign in interactively with delegated permissions. The read/report scripts need
**DeviceManagementConfiguration.Read.All**, **DeviceManagementManagedDevices.Read.All**,
and **Policy.Read.All** (for Conditional Access). The remediation and scope-targeting
scripts additionally need the matching **.ReadWrite.All** scopes, but default to **-WhatIf**
so they only *read* until you explicitly commit.

**Why:** The scripts read per-setting compliance state, device state, and CA policies
directly from Graph so your diagnosis does not depend on hand-reading the console. The first
interactive sign-in raises an admin **consent** prompt for these scopes.

**Verify:** Run `Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"` and
confirm sign-in succeeds; `Get-MgContext` lists the scope. Then
`Get-MgDeviceManagementManagedDevice -Top 1` returns a device without an authorization
error.

**Implement if missing:** Install the SDK with
`Install-Module Microsoft.Graph -Scope CurrentUser`. On first `Connect-MgGraph`, an admin
must **Accept** the consent prompt (or a Global Administrator can pre-consent in Entra →
**Identity → Applications → Enterprise applications → Microsoft Graph Command Line Tools →
Permissions → Grant admin consent**).

---

## R4. PowerShell 7 with the Microsoft Graph SDK installed

**Description:** **PowerShell 7.x** (recommended) or Windows PowerShell 5.1 with the
**Microsoft.Graph** module available to the account running the scripts.

**Why:** The scripts are written against the Graph SDK cmdlets and paginate large result
sets; a current PowerShell avoids TLS and module-loading issues.

**Verify:** `$PSVersionTable.PSVersion` shows 7.x (or 5.1); `Get-Module Microsoft.Graph
-ListAvailable` returns the module.

**Implement if missing:** Install PowerShell 7 from the Microsoft Store or
`https://aka.ms/powershell`, then
`Install-Module Microsoft.Graph -Scope CurrentUser -Force`.

---

## R5. Access to at least one affected (non-compliant) device

**Description:** Local or remote (Intune remote-help / RDP) access to a device that is
currently reporting a compliance failure, plus local admin on it.

**Why:** Some failures (a real BitLocker-off, a stopped firewall, a Custom compliance
script returning a fail) are confirmed and fixed **on the device**, not in the console. You
also confirm the fix by forcing a sync and watching the state clear.

**Verify:** You can sign in to the affected device and open **Settings → Accounts → Access
work or school → <account> → Info**, which shows the managed-device sync status and a
**Sync** button.

**Implement if missing:** Arrange remote access (Intune **Remote Help**, RDP, or physical),
and ensure the operator has local administrator rights to inspect BitLocker, firewall,
Defender, and Custom compliance script output.

---

## R6. A pilot / target security group for staged remediation

**Description:** A Microsoft Entra security group (see global **G5**) used to pilot any
compliance-policy change or grace adjustment before it reaches the fleet.

**Why:** The cardinal rule of this solution is **never disable or loosen a compliance
policy fleet-wide** to fix one device. Staged changes go to a pilot group first; the
`Set-ScopeTargeting` script builds and validates that targeting and defaults to **-WhatIf**.

**Verify:** Entra → **Groups**; the pilot group (for example `Compliance-Diag-Pilot`)
exists and has the intended members.

**Implement if missing:** Entra → **Groups → New group → Security**, name it, add the
affected/test devices or users.

---

## Requirements summary

| # | Requirement | Read-only? | Needed for |
|---|-------------|-----------|-----------|
| R1 | Intune role: read compliance + device state | Yes | Diagnosis (per-setting state) |
| R2 | Entra role: read CA + sign-in logs | Yes | Conditional Access blast radius |
| R3 | Graph read scopes (Read.All) | Yes | All scripts (report/discovery/validation) |
| R4 | PowerShell 7 + Microsoft.Graph SDK | n/a | Running the scripts |
| R5 | Access to an affected device (local admin) | No | Confirming/fixing on-device failures |
| R6 | Pilot / target group | n/a | Safe staged remediation |
