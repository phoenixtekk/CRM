# Diagnostic Playbook — the Win32 App Removal Failure Tree

This is the core of the solution: a **branch-based diagnostic tree for the uninstall path**. Start
from what you observe, follow the one branch that matches, run the exact checks, apply the exact fix,
then re-validate against the gates in `05-testing.md`.

**Golden rule of removal:** Intune resolves the app's **intent** first (`Required` beats
`Uninstall`), then it lets **detection** decide whether the uninstall command runs *and* whether the
removal is judged successful. So the order of causes is: **Intent → Detection (pre) → Uninstall
command → Install context → Exit-code mapping → Detection (post) → Reporting.** Find the *first* one
that is wrong; everything after it is a symptom, not a cause.

Work **one branch at a time**. Never edit the uninstall command before you have confirmed the intent
and the detection rule, because in most tickets the command line was fine all along.

---

## Step 0 — Establish the facts (always do this first)

You need three facts before you touch anything: the **reported** state, the **actual** on-device
state, and every **assignment** that touches this app.

1. **Read the reported state in Intune.** Go to
   **Intune admin center > Apps > All apps > _<your app>_ > Device install status**. Find the
   affected device and note the exact **Status** text: *Uninstall failed*, *Pending*, *Not
   installed*, *Installed*, or *Unknown*. Also open **Apps > All apps > _<your app>_ > Overview** and
   note the **Uninstall failed** count — one device or the whole fleet points at different causes.

2. **Read the same state from Graph.** Run `APPUNIN-Validation.ps1 -AppNameLike "<your app>"`. It
   returns, per device, the `installState` (`uninstallFailed`, `notInstalled`, `installed`,
   `pendingInstall`, `unknown`), the `installStateDetail`, and the raw `errorCode`. This is faster
   and more precise than the console for triage across many devices.

3. **List every assignment on the app — this is the step people skip.** Run
   `APPUNIN-Validation.ps1` with `-CheckConflicts`, or go to
   **Intune admin center > Apps > All apps > _<your app>_ > Properties > Assignments**. Write down
   every group under **Required**, **Available for enrolled devices**, and **Uninstall**, and note
   whether your failing device (or its primary user) is in more than one of them. **A device in both
   a Required group and an Uninstall group is Branch A — stop here and go there.**

4. **Read the on-device truth.** On the failing device, in an elevated PowerShell, run
   `APPUNIN-Discovery.ps1`. It reports, for the target app: the real **ProductCode**, the registered
   **UninstallString** and **QuietUninstallString**, whether the app is registered under **HKLM**
   (per-machine) or **HKCU** (per-user), whether the cached MSI still exists in `C:\Windows\Installer`,
   and whether the app's processes/services are currently running. Save the output to
   `C:\ProgramData\APPUNIN\Evidence`.

5. **Open the IME logs.** On the device, open
   `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` and
   `AppWorkload.log`, or run `APPUNIN-LogParser.ps1`. Search for the app's **display name** or its
   **application id (GUID)**. In pipeline order you will see: the intent the IME resolved, the
   pre-uninstall detection result, the uninstall command line, the returned exit code, and the
   post-uninstall detection result. That sequence tells you which branch you are in.

Now pick the branch that matches your symptom.

| If you observe… | Go to |
|---|---|
| Uninstall does nothing, no error, device stays *Installed* | **Branch A** (intent conflict) — check first |
| Uninstall reported *success* but the app is still on the device | **Branch B** (detection said "gone" — it lied) |
| Uninstall runs every cycle / never reports done, app *is* gone | **Branch C** (detection still matches after removal) |
| *Uninstall failed (1605)* | **Branch D** (wrong/stale ProductCode) |
| *Uninstall failed (1603 / other non-zero)* from an EXE or MSI | **Branch E** (wrong uninstall command / switches) |
| Removal works for some users, not others; app under `HKCU` | **Branch F** (per-user vs per-machine / SYSTEM context) |
| *Uninstall failed (1618)*, file-in-use, or needs a reboot | **Branch G** (app running / reboot pending) |
| Superseded app won't come off during an upgrade | **Branch H** (supersedence uninstall command) |
| Device state *Unknown*, never reports, or app object was deleted | **Branch I** (reporting / lifecycle) |

---

## Branch A — Uninstall does nothing, no error (assignment intent conflict)

**Symptom:** You assigned the app with **Uninstall**, but it stays on the device and Intune keeps
reporting it **Installed**. There is **no error** anywhere. Retrying and re-syncing change nothing.

**Why it happens:** The device (or its primary user) is in **two** assignment scopes for the same
app — a **Required** (install) group *and* an **Uninstall** group — usually through different nested
groups. When the IME reconciles the intents for a single app, **`Required` wins over `Uninstall`.**
The app is therefore kept installed, and the uninstall command is never run. This is the single most
common root cause of "uninstall does nothing," and it is invisible in the per-device status blade.

**Checks:**

1. Run `APPUNIN-Validation.ps1 -AppNameLike "<your app>" -CheckConflicts`. It lists every assignment
   on the app, resolves group membership, and flags any device that lands in both an install intent
   and an uninstall intent.
2. Confirm manually: **Apps > All apps > _<your app>_ > Properties > Assignments**. Read the groups
   under **Required** and **Available**, and the groups under **Uninstall**. Then, for the failing
   device, check **Devices > Windows > Windows devices > _<device>_ > Groups** (and the primary
   user's group memberships) to see whether it is in a group on both sides. Watch for **nested**
   groups — a device can be in a Required group *transitively*.
3. In `IntuneManagementExtension.log`, search the app id: a line resolving the app to intent
   **`Required`** (or `EnforceInstall`) when you expected `Uninstall` confirms the conflict.

**Exact fix:**

1. Decide which intent is correct. To remove the app, the device must be **only** in an Uninstall
   scope.
2. Remove the device from the conflicting **Required**/**Available** group, **or** add it to an
   exclusion. Go to **Apps > All apps > _<your app>_ > Properties > Assignments > Edit**, and under
   **Required** add `APPUNIN – Uninstall – Exclusions`… no — instead, under **Required** click the
   group and use **Edit assignment**, then remove the failing device's group, or add the device to a
   group listed under the Required assignment's own **Excluded groups**. The cleanest pattern:
   maintain removal through the dedicated **Assigned** group `APPUNIN – Uninstall – Production` and
   ensure that group's devices are **not** members of any Required/Available group for this app.
3. Do **not** rely on the same group appearing under both Required and Uninstall — remove the
   Required assignment for the devices you want cleaned.
4. Click **Review + save**.

**Re-validate:** Force a sync on the device (**Branch-agnostic sync**, see the end of this file), wait
a cycle, then re-run `APPUNIN-Validation.ps1`. The device should move to **Not installed**. Confirm
in the log that the IME now resolves the app to intent **Uninstall** and runs the command.

---

## Branch B — Uninstall reported success, but the app is still there (detection said "gone" pre-emptively)

**Symptom:** Intune reports the app **Not installed / uninstall succeeded**, but the software is
plainly still on the device. The log shows the IME **never ran the uninstall command** — it went
straight to "not detected, nothing to remove."

**Why it happens:** The IME evaluates detection **before** running the uninstall. If the detection
rule returns **not detected** — because it points at the wrong file, an old version string, a
per-user path that SYSTEM cannot see, or a registry value that a prior partial removal already
cleared — the IME concludes there is nothing to remove and reports success **without touching the
app**. The removal never happened.

**Checks:**

1. Read the detection rule: **Apps > All apps > _<your app>_ > Properties > Detection rules**. Note
   the rule type (MSI / File / Registry / Custom script) and its exact target.
2. On the device, verify the rule against reality with `APPUNIN-Discovery.ps1`:
   - **MSI ProductCode** — does the code the rule expects actually appear under
     `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall` (or the WOW6432Node view)? If the app
     was upgraded, the installed ProductCode may differ from the one in the detection rule.
   - **File** — does the file exist at the exact path the rule checks, including
     `Program Files` vs `Program Files (x86)`, and does the **version operator** still match?
   - **Registry** — does the key/value exist, and is the **32-bit registry view** checkbox set to
     match where the app actually writes?
   - **Custom script** — run it manually **as SYSTEM** (`PsExec -s -i powershell`) and confirm it
     prints to STDOUT and exits 0 only when the app is present.
3. In the log, find the pre-uninstall detection line for the app id. If it says *not applicable /
   not detected* and there is **no** uninstall command line after it, this is your branch.

**Exact fix:** Correct the detection rule so it **truthfully reports the app as present** while the
app is installed. Detection must match the software's real footprint — author it from
`APPUNIN-Discovery.ps1` output, not from vendor docs. Save with **Review + save**. Now the next cycle
will detect the app, run the uninstall command, and actually remove it.

**Re-validate:** Sync, wait a cycle, re-run `APPUNIN-Validation.ps1`, and confirm on the device that
the software is genuinely gone (Gate 1 in `05-testing.md`) — not merely that Intune says so.

---

## Branch C — Uninstall runs forever / never reports done (detection still matches after removal)

**Symptom:** The app **is** removed on the device, but Intune reports **Uninstall failed** or keeps
**re-running the uninstall** on every 8-hour cycle. The log shows a **success** exit code from the
uninstall command, followed by a **detection = detected** line.

**Why it happens:** After the uninstall command returns success, the IME re-runs the **same detection
rule**. The removal is only reported successful when detection now returns **not detected**. If the
uninstaller leaves a harmless remnant that the detection rule still matches — a registry key under
`Uninstall`, a leftover DLL, a config folder, or a version operator that is too loose ("greater than
or equal to 1.0") — detection still says **detected**, so Intune believes the removal failed and
tries again indefinitely.

**Checks:**

1. On the device, after the uninstall has run, use `APPUNIN-Discovery.ps1` to see what the
   uninstaller left behind — the exact leftover key/file the detection rule is still catching.
2. Compare that remnant to the detection rule (**Properties > Detection rules**). A file rule that
   points at a log or config file the uninstaller does not delete is the classic case.
3. In the log, confirm the sequence: uninstall command → exit **0** → detection **detected** → status
   **failed**. That proves detection, not the uninstaller, is the problem.

**Exact fix:** Make the detection rule test the **primary artifact the uninstaller actually removes**
— usually the app's main EXE with a version operator, or the MSI ProductCode — **not** a remnant the
uninstaller leaves behind. Options, in order of preference:
- Repoint the detection rule at the executable/ProductCode that *is* removed.
- If you must use a registry rule, target the specific value the uninstaller clears, and set the
  operator so it fails once the app is gone.
- As a last resort, add a small step to the removal to delete the specific remnant (see Branch E's
  wrapper approach), then keep detection pointed at it.

Save with **Review + save**.

**Re-validate:** Sync, wait a cycle, re-run `APPUNIN-Validation.ps1` **twice** (two cycles) — the
state must settle on **Not installed** and **stay there** on the second cycle (no re-attempt). That
stability is Gate 4.

---

## Branch D — "Uninstall failed (1605)" (wrong or stale MSI ProductCode)

**Symptom:** Intune reports **Uninstall failed** with code **1605**. The log shows the uninstall
command `msiexec /x {GUID} /qn` ran and Windows Installer returned **1605**.

**Why it happens:** **1605 = "This action is only valid for products that are currently installed."**
The **ProductCode GUID** in your uninstall command does not match any product Windows Installer knows
about on this device. This happens when the app was **upgraded** and the new version shipped a
**different ProductCode** (a "major upgrade"), while the Intune uninstall command still carries the
**old** ProductCode — or when the app was installed by a different mechanism and never registered
that ProductCode at all.

> **ProductCode drift is normal.** A vendor changes the ProductCode on major-version upgrades but
> keeps the same `UpgradeCode`. An uninstall command hard-coded to v3's ProductCode fails with 1605
> against a device now running v4.

**Checks:**

1. On the device, run `APPUNIN-Discovery.ps1`. It lists the **actual installed ProductCode(s)** for
   the app from the registry, and the `UninstallString` each registered. Compare the ProductCode in
   your Intune **Uninstall command** to the one actually installed.
2. Note that different devices may carry **different** ProductCodes if they are on different versions
   — a single hard-coded GUID cannot remove all of them.
3. Confirm 1605 in the log against the exact `msiexec /x {GUID}` line.

**Exact fix (choose one):**

- **If the fleet is on a single version:** update **Properties > Program > Uninstall command** to the
  **correct current ProductCode** — `msiexec /x {CORRECT-GUID} /qn /norestart`. **Review + save.**
- **If devices span multiple versions:** do **not** hard-code a single GUID. Set the uninstall
  command to a small wrapper that **resolves the ProductCode by UpgradeCode (or DisplayName) at run
  time** and then calls `msiexec /x`. `APPUNIN-Remediation.ps1` can generate this wrapper and set it
  as the uninstall command. Example logic the wrapper uses:
  ```powershell
  # Resolve the installed ProductCode for the app, then uninstall it silently.
  $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
          'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
  $app = Get-ItemProperty $keys -ErrorAction SilentlyContinue |
         Where-Object { $_.DisplayName -like 'Contoso LOB Suite*' } | Select-Object -First 1
  if ($app.PSChildName -match '^\{[0-9A-Fa-f-]{36}\}$') {
      Start-Process msiexec.exe -ArgumentList "/x $($app.PSChildName) /qn /norestart" -Wait
  }
  ```

**Re-validate:** Sync, wait a cycle, re-run `APPUNIN-Validation.ps1`. The 1605 must be gone and the
state must move to **Not installed** across devices on every version.

---

## Branch E — "Uninstall failed (1603 / other non-zero)" (wrong uninstall command or EXE switches)

**Symptom:** Intune reports **Uninstall failed** with **1603** (fatal MSI error) or a vendor-specific
non-zero code. The log shows the uninstall command ran and returned that code.

**Why it happens:** The uninstall command itself is wrong for this installer:
- **EXE installers** frequently use a **different silent switch for uninstall than for install** —
  e.g. install is `setup.exe /S` but uninstall is `uninstall.exe /S` or
  `setup.exe /uninstall /quiet`. Reusing the install switches (or omitting the silent switch, so the
  uninstaller shows UI that SYSTEM cannot interact with, then times out) fails.
- **Quoting/escaping errors** — a path with spaces that is not quoted, or nested quotes mangled in
  the command field, so the wrong executable or arguments are passed.
- **1603** specifically is a generic fatal MSI failure — a custom action failed, a file was locked,
  or the uninstall needed rights it did not have.

**Checks:**

1. Read **Properties > Program > Uninstall command** and compare it to the registered
   `QuietUninstallString` from `APPUNIN-Discovery.ps1`. Prefer the vendor's documented **silent**
   uninstall switch.
2. **Reproduce by hand on the device, as SYSTEM.** Use `PsExec -s -i cmd`, then run the exact
   uninstall command. Watch whether it (a) shows a UI dialog (means the silent switch is wrong),
   (b) errors immediately (means the path/switch is wrong), or (c) succeeds (means the problem is
   context — go to Branch F/G).
3. For **1603** from MSI, re-run with **verbose logging**:
   `msiexec /x {GUID} /qn /norestart /l*v C:\ProgramData\APPUNIN\Evidence\uninstall.log`, then open
   the log and search bottom-up for **"return value 3"** — the line just above it names the failing
   action.

**Exact fix:**
- Set **Uninstall command** to the **correct silent uninstall** string for this installer, quoting
  any path with spaces: e.g. `"C:\Program Files\Contoso\uninstall.exe" /S` or
  `"%ProgramFiles%\Contoso\setup.exe" /uninstall /quiet /norestart`.
- If the vendor uninstaller cannot run truly silently, wrap it: package a tiny PowerShell that calls
  the uninstaller and forces the silent flags, and set **that** as the uninstall command.
- For 1603 caused by a locked file or a leftover custom action, resolve the specific action from the
  verbose log (often a running process — go to Branch G) and retry.

**Re-validate:** Reproduce the corrected command by hand as SYSTEM first (must exit **0**), then set
it in Intune, sync, and confirm **Not installed** via `APPUNIN-Validation.ps1`.

---

## Branch F — Works for some, fails for others (per-user vs per-machine / SYSTEM context)

**Symptom:** The same Uninstall assignment removes the app from some devices/users but not others.
The app is registered under **HKCU** on the failing machines, or was installed "for the current user."

**Why it happens:** Win32 app uninstall commands run in the **Install behavior** context set on the
app — **System** or **User**. A **per-user** app (registered under
`HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall`, installed into the user's profile) is
**invisible to SYSTEM**: when the IME runs the uninstall as SYSTEM, it cannot see the per-user
registration or the per-user ProductCode, so removal does nothing or fails. Conversely a per-machine
app cannot be removed by a user-context command that lacks rights. The mismatch between where the app
is registered and the context the uninstall runs in is the root cause.

**Checks:**

1. Run `APPUNIN-Discovery.ps1` — it reports whether the app is registered under **HKLM**
   (per-machine) or **HKCU** (per-user), and under which user's hive.
2. Read **Properties > Program > Install behavior** — **System** or **User**.
3. In the log, a SYSTEM-context uninstall of a per-user app shows detection/uninstall finding
   nothing because it is looking in the machine hive.

**Exact fix:**
- If the app is genuinely **per-user**, the uninstall must run in **User** context, **or** the
  command must enumerate loaded user hives and uninstall per user. Simplest correct path: set
  **Install behavior = User** so the command runs in the signed-in user's context and can see the
  `HKCU` registration. (Note: user-context Win32 apps only act when that user is signed in.)
- If the app should be **per-machine**, the real fix is upstream — repackage/reinstall it
  per-machine so a SYSTEM uninstall can remove it fleet-wide; a per-user install can never be cleanly
  removed for all users by a single SYSTEM command.
- For a one-time cleanup of an existing per-user install, `APPUNIN-Remediation.ps1` can generate a
  SYSTEM wrapper that loads each user hive (`reg load`) and runs the per-user uninstall string —
  flag this as advanced and test on the pilot first.

**Re-validate:** Confirm removal on a device of each affected context (a per-user-install machine and
a per-machine machine) before expanding.

---

## Branch G — "Uninstall failed (1618)", file-in-use, or reboot required (app running / pending reboot)

**Symptom:** Intune reports **Uninstall failed (1618)**, or the verbose MSI log shows *files in use*,
or removal only succeeds after a reboot. The app has a **running process** or a **loaded service** at
uninstall time.

**Why it happens:**
- **1618 = "Another installation is already in progress."** Windows Installer serializes; if another
  MSI transaction (or the app's own updater) is mid-flight, the uninstall cannot get the installer
  mutex and fails. It usually succeeds on the next attempt.
- **Files/services in use** — the app's EXE, a tray helper, or a Windows service is running, so the
  uninstaller cannot delete the files and either fails (1603) or requires a reboot to complete
  (**3010** soft-reboot, **1641** hard-reboot).

**Checks:**

1. Run `APPUNIN-Discovery.ps1` — it lists the app's **running processes** and **services** on the
   device at the moment you check.
2. Read the exit code: **1618** (retry), **3010** (success, reboot needed to finish), **1641**
   (success, uninstaller initiated a reboot).
3. In the verbose MSI log, search for **"in use"** / the specific file the uninstaller could not
   remove.

**Exact fix:**
- **For 1618:** map **1618** in **Properties > Return codes** as **Retry** (not Failure). Intune
  will re-attempt on the next cycle when the installer mutex is free. Do not treat 1618 as a real
  failure.
- **For files in use:** ensure the uninstall command **stops the app first**. Wrap the uninstall so
  it stops the app's service and kills its processes before calling the uninstaller — e.g.
  `Stop-Service 'ContosoSvc' -Force; Stop-Process -Name 'Contoso*' -Force; & msiexec /x {GUID} /qn`.
  `APPUNIN-Remediation.ps1` generates this wrapper.
- **For reboot codes:** map **3010** and **1641** as **success (soft/hard reboot)** in
  **Properties > Return codes** so a legitimate reboot-to-finish is not reported as a failure, and
  let the machine reboot to complete file deletion.

**Re-validate:** After the fix (and a reboot where required), sync and confirm the state settles on
**Not installed** and stays there.

---

## Branch H — Superseded app won't come off during an upgrade (supersedence uninstall command)

**Symptom:** You configured **supersedence** with **Uninstall previous version = Yes**, but the old
app stays installed, or the new app is blocked because the old one won't leave. The log references the
**superseded** app id and a failing uninstall.

**Why it happens:** Supersedence with "uninstall previous version" runs the **superseded (old) app's
own Uninstall command**. If that old app object's uninstall command is wrong — a stale ProductCode
(Branch D), the wrong EXE switch (Branch E), or a running-process problem (Branch G) — the
supersedence removal fails, and depending on settings the new app may not install. The failure is in
the **old** app's definition, which people forget to look at because they are focused on the new one.

**Checks:**

1. Identify the superseded app: **Apps > All apps > _<new app>_ > Properties > Supersedence** — note
   the older app it references and whether **Uninstall previous version** is **Yes**.
2. Open the **superseded (old)** app and diagnose **its** Uninstall command exactly as in Branches
   C–G — read **its** Program > Uninstall command, test it by hand on a device, decode its exit code.
3. Confirm the supersedence chain is **a single hop** — chains deeper than one hop are unsupported and
   stall; run `APPUNIN-Validation.ps1 -CheckConflicts` which also reports supersedence depth.

**Exact fix:** Correct the **superseded app's** Uninstall command (apply the matching branch: D for
ProductCode, E for switches, G for running processes). Flatten any supersedence chain deeper than one
hop. Then let the new app's supersedence re-run.

**Re-validate:** On a pilot device that has the old version, assign the new (superseding) app and
confirm the old one is removed and the new one installs, with detection settling correctly for both.

---

## Branch I — Device never reports / state "Unknown" / app object deleted mid-removal (reporting & lifecycle)

**Symptom:** The device shows **Unknown** or never updates its uninstall status; or you **deleted the
app object** in Intune to "force" removal and now the software is stranded on devices with no way to
target it.

**Why it happens:**
- **Stale check-in.** The device has not synced — the IME reports removal status only on its cycle or
  a manual sync. A device that is offline, powered off, or has a broken IME never reports, so the
  console shows **Unknown** or a stale state.
- **App object deleted before removal completed.** Deleting the Win32 app in Intune removes the
  **assignment and the ability to target it** — it does **not** uninstall the app from devices that
  had it. Any device that had not yet processed the Uninstall intent when you deleted the object is
  now **orphaned**: the software stays, and there is no app object left to assign an Uninstall intent
  to. This is a common self-inflicted wound.

**Checks:**

1. Confirm the device's last check-in: **Devices > Windows > Windows devices > _<device>_** — read
   **Last check-in time**. If it is days old, the device is not reporting, not failing.
2. Run `APPUNIN-Report.ps1` — it summarizes, per app, how many devices are `notInstalled`,
   `uninstallFailed`, `pendingInstall`, and `unknown`, so you can separate genuine failures from
   non-reporting devices.
3. For a deleted app object, check whether the software is still present on devices with
   `APPUNIN-Discovery.ps1` — if it is, you have orphaned installs.

**Exact fix:**
- **For stale check-in:** force a sync (see below) or have the user connect the device; if the IME is
  broken, restart the **Microsoft Intune Management Extension** service or re-sync from
  **Devices > _<device>_ > ... > Sync**. Give it a full cycle before judging it failed.
- **For a deleted app object / orphaned installs:** **re-create the Win32 app** with the same package
  and, crucially, a **correct Uninstall command and detection rule**, assign it as **Uninstall** to
  `APPUNIN – Uninstall – Production`, and let the IME remove it properly. Do **not** delete an app
  object as a removal method — always assign **Uninstall** and confirm removal *before* deleting the
  object.

**Re-validate:** `APPUNIN-Report.ps1` should show the `unknown`/`uninstallFailed` counts fall to zero
as devices check in and process the correctly-configured Uninstall intent.

---

## After any fix — force a sync and re-validate the whole removal

Do not stop at the branch you fixed. On the device, force a sync one of these ways:

- **On the device:** Settings > **Accounts** > **Access work or school** > (the work account) >
  **Info** > **Sync**.
- **From Intune:** **Devices > Windows > Windows devices > _<device>_ > ... > Sync**.
- **From the toolkit:** `APPUNIN-Remediation.ps1 -AppNameLike "<your app>" -Action Resync` (defaults
  to `-WhatIf`; add `-WhatIf:$false` to apply).

Wait a full cycle, then run `APPUNIN-Validation.ps1` and walk the four gates in `05-testing.md`. Only
when all four pass on `APPUNIN – Uninstall – Pilot` should you move the Uninstall assignment to
`APPUNIN – Uninstall – Production`.
