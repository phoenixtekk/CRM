# 2. Requirements Guide — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

Verify **every** requirement before you rely on the playbook. Each entry: **Description · Why ·
Verify · Implement-if-missing.** Category-wide prerequisites are in
`global-requirements-infrastructure.md` — note that the global list is Windows-centric; the
macOS-specific vantage points below are what make the difference on a Mac ticket.

## 2.1 Intune console access (Microsoft Intune admin center)
**Description:** Sign-in to `https://intune.microsoft.com` on a current tenant, with the workloads for **Devices**, **Enrollment**, **Configuration**, and **Compliance** visible.
**Why:** Enrollment tokens, configuration-profile state, compliance results, and recovery-key escrow are all read from the Intune admin center.
**Verify:** `https://intune.microsoft.com` loads; **Devices → macOS** lists Macs, and **Devices → Enrollment** is reachable.
**Implement:** Assign a licensed Intune plan (Global Requirements G2) and an admin role (2.3).

## 2.2 Microsoft Graph read access (for the scripts)
**Description:** The **Microsoft.Graph.Authentication** PowerShell module and the ability to consent to read-only Graph scopes.
**Why:** The Discovery, Validation, and Report scripts query Graph read-only for managed macOS devices, profile states, compliance states, and recovery-key metadata. Remediation and Set-ScopeTargeting additionally need write/privileged scopes.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns the module; `Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All'` completes and `Get-MgContext` shows your account.
**Implement:** `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser`. Read scopes used: `DeviceManagementManagedDevices.Read.All`, `DeviceManagementConfiguration.Read.All`, `DeviceManagementServiceConfig.Read.All`, `Directory.Read.All`. Write scopes (Remediation/Targeting only): `DeviceManagementManagedDevices.PrivilegedOperations.All`, `Group.ReadWrite.All`, `GroupMember.ReadWrite.All`.

## 2.3 Administrative roles for macOS management
**Description:** **Intune Administrator** (or a scoped custom role granting read on devices/configuration/compliance and the specific actions you use), plus a reader for Entra sign-in logs.
**Why:** Reading enrollment/profile/compliance state and issuing safe device actions (Sync) requires elevated Intune rights; diagnosing "compliant but denied" requires reading Entra **Sign-in logs**.
**Verify:** Entra → **Roles and administrators** shows your account with **Intune Administrator**; you can open Entra → **Sign-in logs**.
**Implement:** Assign **Intune Administrator**; add a **Security Reader** (or Reports Reader) for sign-in logs. Reserve Global Administrator for tenant-wide changes only.

## 2.4 Apple enrollment vantage point (ABM / ASM)
**Description:** Access to **Apple Business Manager** (or Apple School Manager) for the organization, or a named contact who has it.
**Why:** "ADE not assigned / enrollment stuck" is diagnosed by confirming the Mac's **serial** is assigned to your MDM server in ABM/ASM and that the **enrollment program token** in Intune is current. That assignment lives in Apple's portal, not Intune.
**Verify:** Sign in to `https://business.apple.com` → **Devices**; you can search a serial and see its assigned **MDM Server**. In Intune → **Devices → Enrollment → Enrollment program tokens**, the token shows a future expiry and a set **default enrollment profile**.
**Implement:** Obtain an ABM/ASM administrator or Device Enrollment Manager role; if you cannot get it, identify the person who can and include them in the runbook. Renew the token before expiry (2.7).

## 2.5 On-device diagnostic access (the failing Mac)
**Description:** Physical or remote (admin) access to the affected Mac, with an admin account and Terminal, plus the ability to read the on-Mac state.
**Why:** SecureToken/FileVault status and SSO-extension registration are read **on the Mac** with built-in tools — Graph can confirm escrow and profile delivery, but the local token state is authoritative on the device.
**Verify:** On the Mac you can run, as admin: `sysadminctl -secureTokenStatus theusername`, `fdesetup status`, `profiles status -type enrollment`, and `app-sso platform -s` (Platform SSO) — each returns output, not "command not found"/permission errors.
**Implement:** Ensure an admin account exists on the Mac (or use a remote-support tool that grants an admin shell); document the built-in commands in your runbook so any technician can run them.

## 2.6 Device logs and diagnostics
**Description:** The ability to collect macOS enrollment/MDM logs and, where needed, the **Company Portal** / SSO extension diagnostics.
**Why:** When a profile shows `Error` in Intune, the reason is often in the Mac's MDM log; when SSO loops, the SSO extension log names the failing step.
**Verify:** On the Mac, **Console.app** shows `mdmclient`/`profiles` activity, or `log show --predicate 'subsystem == "com.apple.ManagedClient"' --last 1h` returns entries; Company Portal → **Help → Save diagnostic report** produces a bundle.
**Implement:** Enable technician access to Console/`log`; teach the Company Portal diagnostic-report path; keep a folder for collected logs per ticket.

## 2.7 Current enrollment program token and profiles
**Description:** A non-expired Apple enrollment program token in Intune, a set default enrollment profile, and the required macOS configuration profiles (SSO extension, FileVault, compliance-supporting) published and assigned.
**Why:** An expired token stops all new ADE enrollments tenant-wide; a missing default profile means devices enroll without your settings; undelivered profiles break the SSO and FileVault layers.
**Verify:** Intune → **Devices → Enrollment → Enrollment program tokens** → token expiry is in the future and a **default profile** is assigned; **Devices → Configuration** lists the SSO-extension, FileVault, and compliance-supporting profiles with a macOS platform and a group assignment.
**Implement:** Renew the token from ABM/ASM before expiry; set a default enrollment profile; publish and assign the SSO-extension (Platform/Extensible SSO), FileVault, and compliance-supporting profiles to the pilot group.

## 2.8 Supported macOS baseline
**Description:** A supported macOS version on the affected devices (Apple's current and two prior major releases are the safe target; Platform SSO requires macOS 13+ / 14+ features).
**Why:** SecureToken/Bootstrap-Token behavior and Platform SSO differ by macOS major version; diagnosing on an unsupported build wastes time.
**Verify:** On the Mac, `sw_vers`; in Intune, device → **Hardware → Operating system**.
**Implement:** Update macOS to a supported release before deep troubleshooting; confirm the SSO method you use is supported on that version.

## 2.9 A reproducible failure to pilot on
**Description:** At least one real, current failing Mac (or a device you can re-run through Setup Assistant) for each symptom class you intend to validate.
**Why:** The playbook is validated by diagnosing actual failures — not by reading it.
**Verify:** Intune → **Devices → macOS** shows a device in the failing state (not enrolled, non-compliant, profile in Error, etc.), or you have a wipeable test Mac.
**Implement:** Use a currently failing device; if none exists, erase-and-reenroll a spare Mac to reproduce an enrollment/SSO/FileVault symptom safely.

---
## Checklist
- [ ] Intune admin center loads; macOS devices, Enrollment, Configuration, Compliance visible
- [ ] `Microsoft.Graph.Authentication` installed; read scopes consented; `Get-MgContext` works
- [ ] Intune Administrator role assigned; Entra Sign-in logs readable
- [ ] ABM/ASM access (or a named contact); enrollment token current with a default profile
- [ ] Admin/Terminal access to the failing Mac; built-in diagnostic commands run
- [ ] macOS MDM/SSO logs and Company Portal diagnostics collectable
- [ ] SSO-extension, FileVault, and compliance-supporting profiles published and assigned
- [ ] Supported macOS baseline confirmed for the SSO method in use
- [ ] A real failure identified (per symptom class) to pilot the playbook on
