# 2. Requirements Guide — Application Retirement, Offboarding & Decommissioning

Verify **every** requirement before you begin a retirement campaign. Each entry:
**Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Throughout this solution we use a **worked example** so every rule and object is concrete. We are
retiring a fictional line-of-business app:

- **App display name (as it appears in Intune):** `LegacyTrack Client`
- **Installer type:** Windows Installer (MSI), `LegacyTrackSetup.msi`, MSI product code
  `{2F1A9C44-7B3E-4E22-9C51-1A2B3C4D5E6F}`
- **Vendor status:** end of support reached; replaced by a SaaS product, so this is an **EOL/EOS +
  redundancy** retirement.
- **Retirement code:** `APPRET-LGT` (a short token you invent per campaign; used in every object name
  below so a whole campaign's objects sort together and are easy to clean up).

Replace the names, code, and product code with your own app's values.

## 2.1 Intune role with app and assignment write access
**Description:** An operator account holding **Intune Administrator** (or a custom role with
**Managed apps** and **Assignment** read/write).
**Why:** The campaign edits app assignments (adds Uninstall, removes Required), edits groups, and
finally deletes the app object.
**Verify:** Entra → **Roles and administrators** → confirm **Intune Administrator** on your account.
**Implement:** Assign the role (G3). Reserve Global Administrator for the app-object deletion step
only if your custom role cannot delete apps.

## 2.2 Microsoft Graph PowerShell SDK and read scopes
**Description:** The **Microsoft Graph PowerShell SDK** installed, with consent to the read scopes
`DeviceManagementApps.Read.All`, `DeviceManagementManagedDevices.Read.All`,
`DeviceManagementConfiguration.Read.All`, and `Group.Read.All`.
**Why:** The five scripts in this package read install base, assignments, dependencies, group
membership, and leftover artefacts from Graph. Read-only scopes are enough for discovery, reporting,
and evidence; the two gated scripts request write scopes only when you confirm an action.
**Verify:** In PowerShell run `Get-Module -ListAvailable Microsoft.Graph.Authentication`; run
`Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All'` and confirm it connects.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. On first connect, a Global
Administrator may need to grant admin consent for the scopes.

## 2.3 The app must exist as an Intune app object with a WORKING uninstall command
**Description:** The app you are retiring is present in Intune → **Apps**, and — critically — its
**uninstall command line** (Win32) or **product code** (MSI/LOB) is correct and silent.
**Why:** The **Uninstall** intent runs *this stored command* on the device. If the app was created
years ago with a wrong or interactive uninstall string, every uninstall will fail. If the software
was installed **outside Intune** (SCCM, a script, a user), there is no app object to target — you
must create one.
**Verify:** Intune → **Apps → All apps** → open `LegacyTrack Client` → **Properties → Program** and
read the **Uninstall command**. For the worked example it must be
`msiexec /x {2F1A9C44-7B3E-4E22-9C51-1A2B3C4D5E6F} /qn /norestart`. Test that command manually on one
clean device and confirm exit code `0`, `1605`, or `3010`.
**Implement:** If the command is wrong, correct it in the app's **Program** tab before starting. If
no Intune app object exists for software you need to remove, create a **Windows app (Win32)** whose
package is a tiny placeholder and whose **uninstall command** is the app's real silent uninstall
string, plus a **detection rule** that matches the installed app (so Intune can report it as present,
then absent). Name it `APPRET-LGT – LegacyTrack Client – Uninstall Shim`.

## 2.4 A reliable detection rule that proves presence and absence
**Description:** A deterministic detection rule (MSI product code, a versioned file, or a registry
value) that is TRUE when the app is installed and FALSE when it is gone.
**Why:** The Uninstall intent's success/failure reporting, and your evidence pack, both depend on
detection flipping from present to absent. A guessed rule produces false "removed" or false
"failed" results.
**Verify:** Intune → app → **Properties → Detection rules**. For the worked example: **MSI** rule on
product code `{2F1A9C44-7B3E-4E22-9C51-1A2B3C4D5E6F}`.
**Implement:** Capture the app's MSI product code, or an installed file + version
(e.g. `C:\Program Files\LegacyTrack\lt.exe`, version `8.4.0`), or its uninstall registry key, and set
exactly one authoritative detection rule.

## 2.5 An install-base and usage evidence source
**Description:** Two distinct facts before you retire: **how many devices have the app** (install
base) and **whether anyone still uses it** (utilisation).
**Why:** Install base bounds the campaign size and comes from Intune. Utilisation justifies the
retirement and does **not** come from Intune — install state is not usage. You need a real usage
signal to defend a "low utilisation" trigger and to find active users who need warning.
**Verify:** Run `APPRET-Discovery.ps1` for the install base. For usage, confirm you can obtain at
least one of: the vendor/admin console's active-user report, licence-server or activation logs, the
app's **Enterprise application** sign-in logs in Entra (if it uses SSO), or an endpoint
analytics/telemetry export.
**Implement:** If you have no usage signal at all, treat the retirement as **evidence-incomplete**:
extend the grace period, deploy a "this app is being retired" notice, and use the grace period itself
as the usage probe (who complains = who uses it).

## 2.6 A named owner and an approver for the decision
**Description:** A business owner who is accountable for the app, and an approver empowered to sign
off its removal.
**Why:** Retirement is a decision, not a task. Removing an app nobody will vouch for causes the
outage that stops the next campaign getting approved.
**Verify:** The decision record (see Implementation Step 2) has a named owner and approver, both
real people, before Wave 0.
**Implement:** If no owner can be found, that *is* evidence for retirement — but the approver must
then be a senior IT/security stakeholder who explicitly accepts the risk in writing.

## 2.7 Data-handling determination (the irreversibility check)
**Description:** A per-app finding of **what the uninstall destroys** and **what data must be
preserved** before removal (exports, licence keys, local databases, user documents, config).
**Why:** This is the one-way door. Many uninstallers wipe `%ProgramData%\<vendor>` and per-user app
data. If data lives only there and is under a retention obligation, you must export it first.
**Verify:** On a test device, install the app, create representative data, run the uninstall command,
and inspect what survives under `C:\ProgramData\`, `%LOCALAPPDATA%`, `%APPDATA%`, and the registry.
Record the result.
**Implement:** If the uninstall destroys data you must keep, script or perform the export **before**
Wave 0 and record it in the evidence pack. If retention is uncertain, get a written retention
decision from data/records owners — never guess.

## 2.8 Wave security groups (assigned, not dynamic)
**Description:** Entra **security groups**, membership type **Assigned**, one per wave, plus one
exclusion group.
**Why:** A retirement must have a blast radius you chose. **Assigned** groups give you exact,
auditable control over which devices uninstall this cycle; a dynamic rule could sweep the whole
fleet in one sync. The exclusion group protects documented exemptions.
**Verify:** Entra → **Groups**; confirm the wave groups exist as **Assigned** security groups (see
Implementation Step 5 for the exact names).
**Implement:** Create them per Step 5. Populate device membership from the `APPRET-Discovery.ps1`
install-base export.

## 2.9 Knowledge of every artefact the app touches
**Description:** An inventory of the tenant objects that reference this app: its assignments,
dependency/supersedence links, the Entra groups used to target it, any **detection or requirement
scripts**, **WDAC / App Control for Business** rules, **Conditional Access** policies that name the
app's enterprise application, and any **Configuration Manager (SCCM)** deployment if the app was
co-managed.
**Why:** Deleting the app but leaving its groups, app-control rules, and CA references behind is not
decommissioning — it is hiding the evidence. Orphaned app-control rules in particular can silently
block or allow things long after the app is gone.
**Verify:** Run `APPRET-ArtifactFinder.ps1`; it lists objects that reference the app or its target
groups.
**Implement:** Build the artefact list before Wave 0 so cleanup at the end is a checklist, not an
archaeology dig.

## 2.10 A supersedence/replacement readiness check (redundancy & EOL retirements only)
**Description:** When retirement means migrating to a **replacement app**, that replacement is
already packaged, deployed, and validated on the target devices.
**Why:** If you remove the old app before the new one is proven, you create an outage. Supersedence
with **Uninstall previous version = Yes** ties the two together so a device is never left with
neither.
**Verify:** Intune → **Apps**; the replacement app (e.g. the SaaS client `LegacyTrack Cloud Agent`)
reports **Installed** on the pilot devices.
**Implement:** Deploy and validate the replacement first (a normal app-deployment exercise), then
configure supersedence in Implementation Step 8.
