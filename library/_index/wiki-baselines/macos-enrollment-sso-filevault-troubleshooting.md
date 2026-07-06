# macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

> **Version 1.0.0** · Category: Infrastructure · Solution code: MACDX

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

**White-label · Infrastructure Solutions**

When a Mac won't finish enrolling, won't sign in through Platform/Extensible SSO, throws a
SecureToken/FileVault error, is marked compliant yet still blocked, or locks a user out after
enrollment, the cause hides across three systems at once — the **Apple** enrollment profile, the
**Intune** policy, and the **Entra** identity. Technicians burn hours guessing which layer is at
fault, and too many stuck Macs get wiped when they needed a one-line fix.

This solution is a structured, symptom-driven **diagnostic playbook** plus tooling for the macOS +
Microsoft Intune stack. It models the signal path as layers — **ADE/enrollment → configuration
profiles → SSO → SecureToken/FileVault → compliance/Conditional Access** — and gives you a root-cause
tree that classifies the symptom, confirms each layer **top-down**, and reads the one authoritative
signal per layer, so you isolate the failing layer in minutes. It is written for a competent Intune
administrator or Mac technician who needs a proven method instead of trial and error.

## What you get
- A plain-language **Solution Overview** of the macOS-Intune signal path, the layered model behind the
  root-cause tree, the five failure classes, and the diagnose-then-resolve method.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite — Intune and
  Microsoft Graph read access, the Apple Business/School Manager vantage point, on-Mac diagnostic
  access, and device logs.
- A **Diagnostic Playbook** — the symptom tree with a branch for each class (ADE not assigned /
  enrollment stuck, SSO won't sign in, SecureToken/FileVault error, compliant-but-denied, user locked
  out) and the exact checks and fixes per branch.
- Five **PowerShell scripts** (Microsoft Graph SDK) for device discovery, per-layer validation, a
  fleet health and escrow-coverage report, safe Sync-based remediation, and a scope/target-group
  builder — read-only where it matters, with the two write-capable scripts defaulting to `-WhatIf`.
- **Testing** and **Troubleshooting** guides with explicit pass/fail gates, plus **Best Practices**
  for evidence-based escalation.

## What this delivers
A diagnostic capability your team keeps: every macOS ticket is triaged the same way — classified,
confirmed top-down, and resolved at the layer that actually failed — so Macs stop getting wiped on a
hunch and knowledge stops walking out the door. Pilot the playbook on real failures, prove it, then
make it the standard.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
The failing layer of a stuck Mac isolated in minutes — enrollment, SSO, SecureToken/FileVault, or
compliance — with a repeatable playbook and scripts you keep and reuse, validated on real failures
before you scale it across the support team.


---


# 1. Solution Overview — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

## What this solution is
A structured, symptom-driven method — a diagnostic playbook plus tooling — for troubleshooting the
**macOS + Microsoft Intune** stack when a Mac won't finish enrolling, won't sign in through
**Platform/Extensible SSO**, throws a **SecureToken/FileVault** error, is compliant but still denied
by **Conditional Access**, or locks a user out after enrollment. Instead of wiping the Mac on a
hunch, you read the signals the stack already produces — the **Automated Device Enrollment (ADE)**
assignment, the delivered **configuration profiles**, the SSO extension state, SecureToken/FileVault
status, and the compliance/Conditional-Access result — and follow a root-cause tree that isolates
the **one failing layer** in minutes. The result is a repeatable diagnose-then-resolve loop any
competent Intune administrator or Mac technician can run.

## The macOS + Intune signal path (the layered model)
A working, trusted Mac is the product of a chain of layers, each of which must succeed before the
next can. When something fails, it is almost always **one** layer — and the layers fail in a
predictable order, so you diagnose top-down:

1. **ADE / enrollment.** The Mac's serial is assigned to your MDM in **Apple Business Manager**
   (ABM) or **Apple School Manager** (ASM), which is synced to Intune's **enrollment program token**.
   During **Setup Assistant** the Mac contacts Apple, is handed to Intune, and enrolls with an
   **enrollment profile**. If the serial isn't assigned, or the token is expired, or the profile
   isn't set as default — enrollment never starts.
2. **Configuration profiles.** Once enrolled, Intune delivers the **device configuration profiles**
   the later layers depend on: the **SSO app extension** (Platform SSO or the Microsoft Enterprise
   SSO plug-in / Extensible SSO), the **compliance-supporting** settings, and any **FileVault**
   policy. Profiles are targeted by group; if the Mac isn't in the right group, or a profile shows
   **Error/Conflict**, the dependent layer above it can't work.
3. **SSO (Platform SSO / Extensible SSO).** With the extension profile delivered and the
   **Company Portal** (or Microsoft **Authenticator**/**Intune** app for the plug-in) installed and
   registered, the user signs in with their Entra ID identity. **Platform SSO** additionally binds
   the local account to Entra. If the extension isn't registered, the app isn't installed, or the
   method (password / secure-enclave key / smart card) is misconfigured, sign-in fails here.
4. **SecureToken / FileVault.** On Apple Silicon and modern macOS, a user needs a **SecureToken** (or
   the volume-owner **Bootstrap Token**, escrowed to Intune) to be enabled for FileVault and to
   unlock the disk at boot. Intune can escrow the **FileVault personal recovery key**. If the first
   account never gained SecureToken, or the Bootstrap Token wasn't escrowed, FileVault enablement or
   a user's disk-unlock fails.
5. **Compliance / Conditional Access.** Intune evaluates the Mac against the **compliance policy**;
   the result flows to Entra ID, where **Conditional Access** decides whether the identity on that
   device may reach a resource. A Mac can be perfectly enrolled and still be **denied** — because it
   is non-compliant, or because a CA policy (device state, app, grant control) blocks it.

> **Read the model top-down.** A failure at a lower layer (SSO, FileVault, CA) is very often caused
> by a missing or errored artifact **above** it (an unassigned serial, an undelivered profile). The
> playbook always confirms the higher layer before blaming the lower one.

## The five failure classes (symptoms)
Almost every "stuck Mac" ticket is one of these. Each has a diagnostic tell and a branch in the
Diagnostic Playbook (§3):

- **ADE not assigned / enrollment stuck.** Setup Assistant shows no **Remote Management** screen, or
  enrollment hangs / errors. Tell: the serial isn't assigned to the MDM in ABM/ASM, the enrollment
  program token is expired, or no default enrollment profile is set.
- **SSO won't sign in.** The Platform/Extensible SSO prompt never appears, loops, or rejects the
  Entra credential. Tell: the SSO extension profile isn't delivered/registered, the required app
  (Company Portal / Authenticator) isn't installed, or the extension configuration is wrong.
- **SecureToken / FileVault error.** FileVault won't enable, a user can't unlock the disk at boot, or
  the recovery key isn't escrowed. Tell: the account lacks SecureToken, the Bootstrap Token wasn't
  escrowed to Intune, or the FileVault profile is in Error.
- **Compliant but denied.** The device shows **Compliant** in Intune yet the user is still blocked
  from a resource. Tell: a Conditional-Access policy (device state, sign-in risk, app control) is
  denying — or the compliance signal hasn't reached Entra yet.
- **User locked out after enrollment.** Enrollment succeeded but the user can't log in / is prompted
  for an unknown password, or the local account is out of sync with Entra. Tell: Platform SSO
  account binding, a FileVault-enabled account mismatch, or a mobile-account/password issue.

## The signals you read (and where)
| Layer | Primary signal | Where you read it |
|---|---|---|
| ADE / enrollment | Serial assignment, token expiry, default profile | ABM/ASM; Intune → **Devices → Enrollment → Enrollment program tokens** |
| Profiles | Profile assignment + per-device state (`Succeeded`/`Error`/`Conflict`) | Intune → **Devices → Configuration**; device → **Device configuration** |
| SSO | Extension delivered/registered; app installed | Device profile state; on-Mac `Profiles` pane / `app-sso` diagnostics |
| SecureToken / FileVault | SecureToken holder, Bootstrap Token escrow, recovery key escrow | On-Mac `sysadminctl`/`fdesetup`; Intune device → **Recovery keys** |
| Compliance / CA | Compliance state; CA policy result; sign-in log | Intune device → **Compliance**; Entra → **Sign-in logs** / **Conditional Access** |

## The diagnose → resolve method
> **1. Classify the symptom** into one of the five classes. **2. Confirm the layer above** the
> symptom is healthy (top-down) — assignment, then profile, then app/extension. **3. Read the layer's
> signal** (the table above) to find the failing artifact. **4. Apply the branch fix** from the
> Playbook (§3). **5. Re-check the signal** and confirm the symptom is gone. **6. Record** the
> symptom, the failing layer, the cause, and the fix so the next ticket is faster.

## The standard deployment model
> **Assess** the failing Mac and its symptom class → **Configure** the read access and vantage points
> (Graph read, device logs, ABM/ASM) → **Pilot** the playbook on real failures → **Validate** the
> diagnoses and fixes → **Expand** it to the whole support team. Repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# Global Requirements — Infrastructure Solutions (category-level)

These requirements apply to **every** solution in the **Infrastructure** category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying *any* Infrastructure solution. Each entry: Description · Why · Verify · Implement-if-missing.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID (Azure AD) tenant.
Why: It is the identity backbone for Microsoft 365, Entra ID, and Intune-managed infrastructure — including device sign-in, group targeting, and shared cloud resources.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Microsoft 365 / Intune subscription
Description: A Microsoft 365 plan that includes Microsoft Intune and the cloud service the solution relies on.
Why: Intune delivers configuration, deployment, and policy targeting; the bundled Microsoft 365 services back the cloud capability being deployed.
Verify: `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
Description: Appropriate Entra / Intune admin roles for the operator.
Why: Creating cloud service settings, policies, and deployments requires elevated rights.
Verify: Entra → **Roles and administrators**; confirm **Intune Administrator** (plus any service-specific admin role the solution calls out).
Implement: Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
Description: Targeted Windows devices are enrolled and manageable.
Why: Deployments and policies only reach enrolled, Entra-joined devices.
Verify: Intune → **Devices → All devices**; the device appears and is **compliant**.
Implement: Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
Description: A Microsoft Entra security group for the pilot population (users or devices).
Why: Every solution is piloted before fleet rollout — the pilot is the gate.
Verify: Entra → **Groups**; the pilot group exists.
Implement: Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
Description: Windows 10 21H2+ or Windows 11 with current updates.
Why: Modern Intune and Microsoft 365 cloud features assume a patched, supported OS.
Verify: `winver`, or Intune → device → **Hardware**.
Implement: Deploy update rings or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
Why: Enrollment, policy sync, authentication, and the cloud service traffic depend on these endpoints.
Verify: From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
Implement: Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through the proxy/firewall.

---
The repeatable deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# 3. Diagnostic Playbook — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

This is the runbook. It takes a stuck Mac, classifies the symptom, and drives it to the failing layer
and a fix. Console work is in the **Microsoft Intune admin center** (`https://intune.microsoft.com`);
on-device checks run in **Terminal** on the affected Mac (admin); the scripts run from a PowerShell
session with the **Microsoft.Graph.Authentication** module signed in with the read scopes (§2.2).

> **Method:** Classify the symptom → confirm the layer **above** it is healthy (top-down) → read the
> layer's signal → apply the branch fix → re-check → record. Name every artifact you create with
> `<Purpose> – <Scope> – <Stage>` and reuse the names (e.g. `macOS SSO Fix – Pilot – Triage`).

## Step 0 — Classify the symptom and gather context
1. Ask the one question that picks the branch: **where does it stop?**
   - No Remote Management / enrollment never finishes → **Branch A (ADE/enrollment)**.
   - Enrolled, but the SSO prompt never works → **Branch B (SSO)**.
   - FileVault won't enable or a user can't unlock the disk → **Branch C (SecureToken/FileVault)**.
   - Device shows Compliant but a resource is blocked → **Branch D (compliant but denied)**.
   - Enrolled, but the user can't log in / password is wrong → **Branch E (locked out)**.
2. Get the device context first — run `MACDX-Discovery.ps1` to list the macOS device, its enrollment
   state, ownership, compliance, last check-in, and OS build. This confirms which layer the device
   has reached and gives you the device id the other scripts use.

---

## Branch A — ADE not assigned / enrollment stuck
**Tell:** Setup Assistant shows no **Remote Management** screen, or enrollment hangs/errors.
**Diagnose top-down (Apple assignment → Intune token → profile):**
1. **Serial assigned in Apple.** In **Apple Business Manager / School Manager → Devices**, search the
   Mac's serial. Confirm it is assigned to **your** MDM server (the Intune server). If it isn't
   there, the device was never bought through / added to ABM/ASM — no ADE is possible.
2. **Token healthy in Intune.** Intune → **Devices → Enrollment → Enrollment program tokens**. Confirm
   the token's **expiry is in the future** and a **default enrollment profile** is set. Run
   `MACDX-Validation.ps1 -Check Enrollment` to read the token/profile summary via Graph.
3. **Profile assigned to the device.** In the token → **Profiles** and **Devices**, confirm the Mac's
   serial has an enrollment profile assigned (not just the default). Re-sync ABM/ASM
   (**Sync**) if the serial is new.
4. **On the Mac.** After erase, at Setup Assistant, or via `sudo profiles renew -type enrollment`
   (macOS reaches out again). `profiles status -type enrollment` should report it is enrolled / has a
   configuration waiting.

**Fix:**
- Serial not assigned → have the reseller/Apple assign it, or add it to ABM/ASM and **Sync** to Intune.
- Token expired → **renew** the token (download a new one from ABM/ASM, upload to Intune).
- No default profile → set a **default enrollment profile** on the token and assign it to the serial.
- Stuck mid-enrollment → erase and re-run Setup Assistant, or `sudo profiles renew -type enrollment`.

**Confirm:** The Mac reaches **Remote Management** and appears in Intune → **Devices → macOS** as
enrolled. Re-run `MACDX-Validation.ps1`.

---

## Branch B — SSO won't sign in (Platform SSO / Extensible SSO)
**Tell:** The Platform/Extensible SSO prompt never appears, loops, or rejects the Entra credential.
**Diagnose top-down (profile delivered → app installed → extension registered → method correct):**
1. **Extension profile delivered.** Intune → device → **Device configuration**; the **SSO app
   extension** (Platform SSO or the Microsoft Enterprise SSO / Extensible SSO) profile shows
   **Succeeded**, not Error/Conflict. Run `MACDX-Validation.ps1 -Check Profiles` to list per-device
   profile states via Graph.
2. **Required app installed.** The extension needs its companion app present and run once:
   **Company Portal** (Platform SSO / Company Portal-based registration) or Microsoft
   **Authenticator** (Extensible SSO plug-in). Confirm the app is assigned (Intune → **Apps → macOS**)
   and installed on the Mac.
3. **Extension registered on the Mac.** In Terminal: `app-sso platform -s` (Platform SSO) shows the
   registration/state; `app-sso -l` lists SSO extensions. For Extensible SSO, **System Settings →
   Profiles** shows the SSO extension profile installed.
4. **Method correct.** Confirm the configured Platform SSO **authentication method** (Password,
   Secure Enclave key, or Smart Card) matches what the user has and what the profile specifies; a
   Secure-Enclave-key config with no registered key loops.

**Fix:**
- Profile in Error/Conflict → resolve the conflicting profile / re-assign; confirm the Mac is in the
  target group (`MACDX-Set-ScopeTargeting.ps1`, `-WhatIf` by default).
- App missing → assign/install Company Portal or Authenticator; open it once to register.
- Not registered → have the user complete registration in Company Portal; `sudo profiles renew` to
  re-pull the extension; re-run after check-in.
- Wrong method → align the profile's Platform SSO method with the user's capability; re-deploy.

**Confirm:** The user signs in through SSO and `app-sso platform -s` shows a registered/logged-in
state. Re-run `MACDX-Validation.ps1 -Check Profiles`.

---

## Branch C — SecureToken / FileVault error
**Tell:** FileVault won't enable, a user can't unlock the disk at boot, or the recovery key isn't escrowed.
**Diagnose top-down (SecureToken holder → Bootstrap Token escrow → FileVault profile → key escrow):**
1. **SecureToken holder.** On the Mac: `sysadminctl -secureTokenStatus theusername` for the affected user
   and the first admin. A user with **ENABLED** SecureToken can be a FileVault user; a user with
   **DISABLED** cannot enable/unlock FileVault.
2. **Bootstrap Token escrowed.** `profiles status -type bootstraptoken` shows whether the Bootstrap
   Token is escrowed to the MDM. Modern Apple-silicon FileVault relies on the Bootstrap Token; if it
   was never escrowed, MDM-driven enablement and additional-user grants fail.
3. **FileVault profile state.** Intune → device → **Device configuration**; the FileVault
   (Endpoint security → Disk encryption) policy shows **Succeeded**. Run
   `MACDX-Validation.ps1 -Check FileVault`.
4. **Recovery key escrowed.** Intune → device → **Recovery keys** shows a stored **personal recovery
   key**. `MACDX-Report.ps1` includes an escrow-coverage count across the fleet. `fdesetup status`
   on the Mac shows whether FileVault is On.

**Fix:**
- User lacks SecureToken → grant it from a SecureToken-holder admin:
  `sysadminctl -secureTokenOn theusername -password userpassword -adminUser adminname -adminPassword adminpassword`
  (run on the Mac; substitute the real account names and passwords).
- Bootstrap Token not escrowed → `sudo profiles install -type bootstraptoken` (or re-enroll) to
  escrow it; confirm with `profiles status -type bootstraptoken`.
- FileVault profile in Error → fix the assignment/settings and re-deploy; ensure the target account
  holds SecureToken first.
- Key not escrowed → rotate/re-escrow the personal recovery key via the FileVault policy; confirm it
  appears under **Recovery keys**.

**Confirm:** `fdesetup status` shows FileVault On for the intended user, the recovery key is visible
under **Recovery keys** in Intune, and the user unlocks the disk at boot. Re-run
`MACDX-Validation.ps1 -Check FileVault`.

---

## Branch D — Compliant but denied
**Tell:** Intune shows the Mac **Compliant**, yet the user is blocked from a resource (M365, etc.).
**Diagnose top-down (compliance signal → Entra sign-in log → Conditional Access policy):**
1. **Compliance is real and current.** Intune → device → **Compliance**; the policy shows
   **Compliant** with a recent evaluation. Run `MACDX-Validation.ps1 -Check Compliance` — it names any
   non-compliant setting. A device that flipped compliant seconds ago may not have propagated yet.
2. **Read the actual block.** Entra → **Sign-in logs** → filter to the user and the time of the block
   → open the failed sign-in → **Conditional Access** tab. It names the **policy** that applied and
   the **grant control** that failed (e.g. *Require device to be marked as compliant*, *Require
   approved app*, *Require hybrid Entra join*).
3. **Device identity match.** Confirm the device Entra ID in the sign-in log matches the compliant
   Intune device — a second/duplicate device record, or a browser not using the SSO extension, can
   present as a *different* (non-compliant/unknown) device to CA.

**Fix:**
- Signal lag → wait for propagation, or force a device **Sync** (`MACDX-Remediation.ps1 -Action Sync`,
  `-WhatIf` by default) and re-test after check-in.
- CA grant the Mac can't meet → adjust the policy scope/exclusion or give the Mac the required state
  (e.g. ensure the SSO extension is delivering device compliance to the browser — Branch B).
- Duplicate/stale device object → reconcile the duplicate Entra device record so CA evaluates the
  compliant one.

**Confirm:** The same sign-in now shows **Success** with the CA policy **Satisfied** in Entra
Sign-in logs.

---

## Branch E — User locked out after enrollment
**Tell:** Enrollment succeeded, but the user can't log in, is prompted for an unknown password, or the
local account is out of sync with Entra.
**Diagnose top-down (account model → Platform SSO binding → FileVault account → password sync):**
1. **Which account model.** Determine whether the Mac uses **Platform SSO** account binding (local
   account linked to Entra), a **mobile account**, or a plain local admin. `app-sso platform -s` and
   `dscl . -read /Users/theusername` show the account state.
2. **Platform SSO binding health.** If Platform SSO is in use, confirm the extension is registered and
   the user completed sign-in (Branch B) — a half-bound account can reject the Entra password locally.
3. **FileVault account match.** If FileVault is On, the login/unlock account must be a
   SecureToken-holding, FileVault-enabled user (Branch C). A user who isn't FileVault-enabled can't
   unlock at boot even with the right password.
4. **Password sync.** With Platform SSO password mode, a recent Entra password change must sync; the
   user may need to sign in with the **previous** local password once, then the extension syncs.

**Fix:**
- Half-bound Platform SSO → re-register via Company Portal; `sudo profiles renew` and re-run sign-in.
- FileVault account mismatch → grant SecureToken and add the user to FileVault (Branch C).
- Password out of sync → follow the Platform SSO password-sync path (sign in local, let it sync); as a
  last resort an admin resets the local password from a SecureToken holder.
- No admin available on the box → use the escrowed **personal recovery key** (Intune → **Recovery
  keys**) to unlock, then repair the account.

**Confirm:** The user logs in and unlocks the disk with their Entra credential (or synced password),
and `app-sso platform -s` shows a healthy registered state.

---

## Step 9 — Record the resolution
Capture the symptom class, the failing layer, the signal you read, the root cause, and the fix in
your runbook log (name it `macOS Failure Log – <Site> – Runbook`). This is what makes the next
ticket minutes instead of hours.

## Step 10 — Validate and expand
1. Run the full loop on **at least two** distinct real failures (ideally different branches); confirm
   each was isolated to the correct layer and resolved. Complete the **Testing Guide** (§5).
2. Save the scripts, the recorded resolutions, and the on-Mac command cheat-sheet where the team
   works. Make this the standard triage path for macOS tickets; re-validate as macOS versions and the
   SSO method change.

---
### Order of operations
`Classify symptom → confirm layer above (top-down) → read the layer's signal → apply branch fix →
re-check the signal → record → validate on real failures → expand`


---


# 5. Testing Guide — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

Run these after you have read access set up and have piloted the playbook on a real failure
(Diagnostic Playbook §3). These tests prove the toolkit actually isolates and resolves the failing
layer — not that the doc reads well. Each test maps to a symptom branch.

## Test 1 — Device context is visible (Discovery)
**Do:** Run `MACDX-Discovery.ps1` (optionally `-DeviceName device-name-or-serial`).
**Expected:** The macOS device is listed with enrollment state, ownership, compliance, OS build, and
last check-in — read-only, with no attempt to change the tenant. PASS if it connects with the read
scopes and lists devices; FAIL if sign-in or scopes are missing.

## Test 2 — Enrollment / ADE state (Branch A)
**Do:** Run `MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check Enrollment`; cross-check
Intune → **Devices → Enrollment → Enrollment program tokens**.
**Expected:** The script reports the enrollment token's expiry and whether a default profile is set,
consistent with the portal; a stuck device is shown as not-enrolled with the reason class visible.

## Test 3 — SSO extension state (Branch B)
**Do:** Run `MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check Profiles`; on the Mac run
`app-sso platform -s`.
**Expected:** The SSO app-extension profile state (`Succeeded`/`Error`/`Conflict`) matches the portal,
and the on-Mac registration state agrees. A failing SSO device shows the profile not `Succeeded` or
the extension not registered.

## Test 4 — SecureToken / FileVault state (Branch C)
**Do:** Run `MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check FileVault`; on the Mac run
`sysadminctl -secureTokenStatus theusername` and `fdesetup status`.
**Expected:** The FileVault profile state and recovery-key escrow reported by the script match Intune
→ device → **Recovery keys**; the on-Mac SecureToken/FileVault status agrees. A failing device shows
no escrowed key or a SecureToken-DISABLED account.

## Test 5 — Compliance / Conditional Access (Branch D)
**Do:** Run `MACDX-Validation.ps1 -DeviceName device-name-or-serial -Check Compliance`; open Entra →
**Sign-in logs → Conditional Access** for the blocked sign-in.
**Expected:** The script names any non-compliant setting; the sign-in log names the CA policy and the
grant control that denied. A "compliant but denied" case shows Compliant in Intune yet a failed CA
grant in Entra.

## Test 6 — Fleet report and escrow coverage
**Do:** Run `MACDX-Report.ps1`.
**Expected:** A clean summary — counts by enrollment/compliance state, stale (not-checked-in) macOS
devices, OS-version spread, and FileVault recovery-key escrow coverage — reconciling with the Intune
portal for your scope.

## Test 7 — Safe remediation preview (default -WhatIf)
**Do:** Run `MACDX-Remediation.ps1 -DeviceName device-name-or-serial -Action Sync` **without**
`-WhatIf:$false`.
**Expected:** It prints the intended safe action (device Sync) and makes **no** change (PREVIEW MODE).
Re-running with `-WhatIf:$false` on a pilot device issues the Sync and reports success.

## Test 8 — Scope targeting preview (default -WhatIf)
**Do:** Run `MACDX-Set-ScopeTargeting.ps1 -GroupName pilot-group-name -DeviceName device-name-or-serial`
**without** `-WhatIf:$false`.
**Expected:** It prints the intended group and membership change and makes **no** change. With
`-WhatIf:$false` on a pilot group it creates the group if needed and adds the device.

## Test 9 — Re-check after fix (any branch)
**Do:** After applying a branch fix, re-run the matching `MACDX-Validation.ps1 -Check ...` and the
on-Mac command for that layer.
**Expected:** The signal that was failing now reads healthy (enrolled / SSO registered / FileVault On
+ key escrowed / CA satisfied), and the symptom is gone.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Read pass** | Tests 1–6 pass read-only: device context, per-branch state, and the fleet report reconcile with the Intune portal and Entra sign-in logs |
| **Safety pass** | Tests 7–8 pass: Remediation and Set-ScopeTargeting default to `-WhatIf` and make no change until `-WhatIf:$false` |
| **Resolution pass** | Test 9 passes on **two** distinct real failures (Playbook §3, Step 10): each was isolated to the correct layer and the re-check reads healthy |


---


# 6. Troubleshooting Guide — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

This is the formal troubleshooting section for the **toolkit and its tooling** — what to do when the
diagnostic process itself misbehaves (Graph sign-in fails, a device isn't found, an on-Mac command is
denied, escrow reads empty). For diagnosing the *Mac failure* itself, follow the Diagnostic Playbook
(§3) and its five branches.

## A. Microsoft Graph sign-in / scope errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or module missing | `Microsoft.Graph.Authentication` not installed | `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser`, then retry |
| `Authorization_RequestDenied` on a read | The consented scopes don't include the one the check needs | Reconnect with the read scopes in §2.2; an admin may need to consent |
| Remediation/Targeting write is refused | Missing write scope | Reconnect adding `DeviceManagementManagedDevices.PrivilegedOperations.All` (Sync) or `Group.ReadWrite.All`/`GroupMember.ReadWrite.All` (targeting) |
| Wrong tenant | Cached context points elsewhere | `Disconnect-MgGraph`, then reconnect with `-TenantId your-tenant-id` |

## B. Device not found by the scripts
- The scripts match macOS managed devices by **device name or serial** (substring). If nothing
  matches, confirm the device is enrolled (Intune → **Devices → macOS**) and try the **serial** — a
  freshly enrolled Mac may not have its friendly name yet.
- If `MACDX-Discovery.ps1` lists the device but `-DeviceName` in another script misses it, use a more
  specific substring (the full serial) so it isn't ambiguous.

## C. On-Mac commands are denied or "command not found"
| Symptom | Cause | Remediation |
|---|---|---|
| `sysadminctl`/`fdesetup` "not permitted" | Not running as an admin, or SecureToken-holder needed | Run in Terminal as a local admin; SecureToken grants need a SecureToken-holding admin's credentials |
| `app-sso platform -s` returns nothing | Platform SSO not configured / older macOS | Confirm the SSO method is Platform SSO and macOS supports it (§2.8); for Extensible SSO check **System Settings → Profiles** instead |
| `profiles status -type bootstraptoken` "not escrowed" | Bootstrap Token was never escrowed | `sudo profiles install -type bootstraptoken` or re-enroll (Playbook Branch C) |

## D. Profile shows Error/Conflict in Intune but you can't tell why
- Two profiles setting the **same** payload differently produce a **Conflict** — find the second
  profile targeting the device and reconcile them; the Mac's group membership tells you which
  profiles apply (`MACDX-Set-ScopeTargeting.ps1` preview shows current membership).
- For an **Error**, read the Mac's MDM log: `log show --predicate 'subsystem == "com.apple.ManagedClient"' --last 1h`
  or Console.app for the `mdmclient`/`profiles` entry that names the failing payload.

## E. Recovery keys / escrow reads empty
- Intune → device → **Recovery keys** blank while `fdesetup status` shows FileVault On → the
  **personal recovery key** wasn't escrowed. Rotate/re-escrow via the FileVault (Disk encryption)
  policy; the key appears after the next check-in.
- `MACDX-Report.ps1` escrow coverage shows 0 → confirm the FileVault policy is assigned and the
  reading account has `DeviceManagementConfiguration.Read.All` / `DeviceManagementManagedDevices.Read.All`.

## F. "Compliant but denied" doesn't resolve
- If Intune shows Compliant but Entra keeps denying, the block is a **Conditional Access** decision,
  not an Intune one — read the CA tab in the **Sign-in log**, not the compliance blade. The named
  policy + grant control is the actual cause (Playbook Branch D).
- A browser that doesn't use the SSO extension can present as a different/unknown device to CA even
  though the OS is compliant — confirm the SSO extension is delivering device state (Branch B).

## G. Remediation / targeting "made no change"
- Both `MACDX-Remediation.ps1` and `MACDX-Set-ScopeTargeting.ps1` default to **`-WhatIf`** — that is
  by design. They only act when you re-run with **`-WhatIf:$false`**. The `[PREVIEW MODE]` banner tells
  you no change was made.
- A Sync issued but nothing changed on the Mac → allow a few minutes for the device to check in, then
  re-run `MACDX-Validation.ps1` for that layer.

## H. Diagnostics quick reference
```powershell
# Confirm the Graph context and scopes the scripts will use
Get-MgContext | Select-Object Account, TenantId, Scopes

# List macOS managed devices (read-only), newest check-in first
Invoke-MgGraphRequest -Method GET `
  -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'" |
  Select-Object -ExpandProperty value |
  Select-Object deviceName, serialNumber, complianceState, osVersion, lastSyncDateTime |
  Sort-Object lastSyncDateTime -Descending | Select-Object -First 20
```
```bash
# On the affected Mac (Terminal, as admin) — the four layer signals
sudo profiles status -type enrollment          # ADE / enrollment (Branch A)
app-sso platform -s                            # Platform SSO registration (Branch B)
sysadminctl -secureTokenStatus theusername     # SecureToken holder (Branch C)
sudo profiles status -type bootstraptoken      # Bootstrap Token escrow (Branch C)
fdesetup status                                # FileVault On/Off (Branch C)
```

## I. When to escalate
If the layer signal is read correctly, the branch fix is applied, and the symptom persists, collect:
the Company Portal **diagnostic report**, the Mac's MDM log
(`log collect --last 2h` / Console.app), the Intune device page, and the Entra **Sign-in log** for
the failed CA case. Open a Microsoft support case with the symptom class, the failing layer, and the
exact signal you captured — and, for an Apple-side ADE assignment issue, engage Apple/ABM support with
the serial and the assigned MDM server.


---


# 7. Best Practices — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

Evidence-based escalation: every recommendation below shortens the path from symptom to the failing
layer, and keeps you from acting on a guess.

- **Diagnose top-down, always.** A lower-layer symptom (SSO, FileVault, CA) is usually caused by a
  missing or errored artifact **above** it (an unassigned serial, an undelivered profile). Confirm the
  higher layer is healthy before you blame the lower one — it is the single biggest time-saver.
- **Classify the symptom first.** The one question "**where does it stop?**" picks the branch. Naming
  the class (ADE / SSO / FileVault / compliant-but-denied / locked-out) before touching anything keeps
  the investigation on rails.
- **Read the signal; don't infer it.** Each layer has an authoritative signal — the enrollment token,
  the per-device profile state, `sysadminctl`/`fdesetup` on the Mac, the Entra sign-in log's CA tab.
  Read the actual signal rather than assuming from the symptom.
- **Trust the Mac for token state.** SecureToken and Bootstrap-Token status are authoritative **on the
  device** (`sysadminctl`, `profiles status -type bootstraptoken`). Graph confirms escrow and profile
  delivery; the local commands confirm the token itself.
- **Escrow the recovery key before you need it.** Verify FileVault **personal recovery key** escrow in
  Intune (and `MACDX-Report.ps1` coverage) proactively — the key is what unlocks a locked-out Mac in
  Branch E. Missing escrow turns a five-minute fix into a wipe.
- **Keep the enrollment token current.** An expired Apple enrollment program token stops **all** new
  ADE enrollments tenant-wide. Track the expiry and renew ahead of time; set and verify a default
  enrollment profile.
- **Preview before you change.** Run `MACDX-Remediation.ps1` and `MACDX-Set-ScopeTargeting.ps1` in
  their default `-WhatIf` mode, read the intended action, then re-run with `-WhatIf:$false`. The safe
  actions here (Sync, add-to-group) are deliberately the least-disruptive; never reach for a wipe as a
  first move.
- **Separate "compliant" from "allowed".** Intune decides compliance; **Conditional Access** decides
  access. When a compliant Mac is denied, read the CA tab of the Entra sign-in log — that names the
  policy and grant control actually blocking, so you fix the right thing.
- **Confirm the SSO method matches the device.** Platform SSO password vs. Secure-Enclave-key vs.
  smart-card each has different device prerequisites; a mismatch loops sign-in. Verify macOS supports
  the method you configured before deploying it fleet-wide.
- **Record every resolution.** A short log of symptom → failing layer → signal → cause → fix compounds:
  the second occurrence should be minutes, not hours, and it is what lets you hand the runbook to the
  rest of the team.
- **Pilot on real failures.** Validate the playbook on at least two distinct failures — ideally
  different branches — before making it the team standard. Assign once, repeat everywhere.
- **Escalate with evidence, not a story.** When a fix doesn't hold, escalate with the captured
  signal — Company Portal diagnostics, the MDM log, the Intune device page, the Entra CA sign-in — and
  the exact layer/class. Evidence-based tickets get resolved; "it won't enroll" tickets bounce.


---


# 8. Deliverables Summary — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The macOS + Intune signal path (ADE/enrollment → profiles → SSO → SecureToken/FileVault → compliance/CA), the layered model, the five failure classes, and the diagnose-then-resolve method |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing — Intune + Graph read access, ABM/ASM vantage point, on-Mac diagnostic access, device logs |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Diagnostic Playbook | The symptom tree: classify → confirm the layer above → read the signal → branch fix, across all five branches (ADE/enrollment, SSO, SecureToken/FileVault, compliant-but-denied, locked-out) |
| 5. Testing Guide | Validation procedures with pass/fail gates, one per branch |
| 6. Troubleshooting Guide | Troubleshooting the toolkit itself (Graph sign-in, device lookup, on-Mac commands, escrow reads) |
| 7. Best Practices | Evidence-based escalation and field-proven recommendations |

## PowerShell scripts (Microsoft Graph SDK)
| Script | What it does |
|---|---|
| `MACDX-Discovery.ps1` | Lists macOS managed devices with enrollment state, ownership, compliance, OS build, and last check-in (read-only) |
| `MACDX-Validation.ps1` | Per-device, per-layer state check (`-Check Enrollment/Profiles/FileVault/Compliance`): enrollment/token, SSO-extension profile state, FileVault + recovery-key escrow, named non-compliant settings (read-only) |
| `MACDX-Report.ps1` | Fleet summary — enrollment/compliance mix, stale devices, OS-version spread, FileVault recovery-key escrow coverage (read-only) |
| `MACDX-Remediation.ps1` | Safe remediation helper (`-WhatIf` by default): issue a device **Sync** to re-pull policy and re-evaluate; never wipes/resets/retires |
| `MACDX-Set-ScopeTargeting.ps1` | Pilot/target-group builder (`-WhatIf` by default): ensure an Entra security group exists and add the device so a missing profile/app flows to it |

## What the buyer receives
- This playbook as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP (Graph SDK; read-only Discovery/Validation/Report;
  Remediation and Set-ScopeTargeting default to `-WhatIf`).
- A repeatable process following the standard model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
The failing layer of a stuck Mac isolated in minutes — enrollment, SSO, SecureToken/FileVault, or
compliance — by classifying the symptom, confirming top-down, and reading the one authoritative
signal per layer. A repeatable diagnostic capability the team keeps and reuses, validated on real
failures before it scales out.
