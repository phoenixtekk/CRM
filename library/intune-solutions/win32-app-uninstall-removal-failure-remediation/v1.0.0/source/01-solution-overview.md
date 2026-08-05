# Solution Overview

## The problem this solves

You assigned a Win32 app in Microsoft Intune with the **Uninstall** intent. The app does not come
off. Intune reports **Uninstall failed**, or **Failed (1605)**, or the device sits at **Pending**
forever, or — worst of all — Intune reports the app as **Installed** even though you asked for it to
be removed and it *is* still there. Someone re-assigns it, someone else deletes the app object, and a
week later the software is still on 400 machines.

Removal is not "install, backwards." It is its own delivery path with its own failure modes, and
almost every one of them is invisible in the Intune console. This solution is a **branch-based
diagnostic playbook for the uninstall path specifically** — how Intune actually processes an
Uninstall intent, why detection rules govern removal just as tightly as they govern installation,
what the uninstall command line really has to be, and how to prove the software is gone.

## Scope — what this solution covers, and what it does not

**In scope (the removal path):**

- The **Uninstall assignment intent** on Win32 apps, and how the Intune Management Extension (IME)
  acts on it.
- **Assignment intent conflict** — a device targeted with **Required** (install) *and* **Uninstall**
  through two different groups. This is the single most common root cause of "uninstall does
  nothing."
- **Detection rules on the removal path** — the two opposite failure modes they cause.
- The **uninstall command line**: MSI **ProductCode** drift between versions, stale ProductCodes,
  EXE silent-uninstall switches, quoting/escaping errors, and uninstall strings read out of the
  registry.
- **Install context** — per-machine (`HKLM`) vs per-user (`HKCU`), and SYSTEM vs user execution.
- The **missing or corrupt Windows Installer cache** (`C:\Windows\Installer`) and what to do when the
  original installer no longer exists anywhere.
- Apps that **cannot be removed while running** — file-in-use, locked services, pending reboot.
- **Uninstall-specific exit codes** (0, 1605, 1614, 1618, 1641, 3010, 1603, 1612, 1639 and friends)
  and which of them must be re-mapped in the app's **Return codes** table.
- **Supersedence-driven** uninstall failure — the superseded app's own uninstall command is wrong.
- Devices that **never report**, stale check-in, and the app object deleted **before** removal
  completed.
- **IME log reading** (`IntuneManagementExtension.log`, `AppWorkload.log`, `AgentExecutor.log`) —
  exactly what to search for on the uninstall path.
- **Last-resort removal** paths, and how to **prove** the app is actually gone.

**Out of scope (deliberately):** install-path diagnosis — "Not applicable," requirement-rule
failures, content download failures, dependency resolution, and Enrollment Status Page blocks. Those
are the *install* pipeline. This solution starts where the install pipeline ends.

## How Intune actually processes an Uninstall intent

Understanding this sequence is what makes the playbook work. The IME is the agent that runs Win32
app work on Windows; it polls Intune roughly **every 8 hours**, and on device check-in, sync, or
service restart.

1. **Intent resolution.** The IME receives the full list of Win32 app assignments that apply to this
   device and this user. Each assignment carries an intent: **Required**, **Available**, or
   **Uninstall**. If more than one assignment targets the same app for the same device, **the
   intents are reconciled — and `Required` (install) wins over `Uninstall`.** A device in both an
   install group and an uninstall group therefore keeps the app, silently, forever. Nothing errors.
2. **Detection evaluation — BEFORE the uninstall runs.** The IME evaluates the app's **detection
   rules** first. If detection says the app is **not present**, there is nothing to remove: the IME
   marks the app as uninstalled/not installed and **never runs the uninstall command line at all**.
3. **Uninstall execution.** If detection says the app **is** present, the IME runs the app's
   **Uninstall command** — from `Properties > Program > Uninstall command` — in the app's configured
   **Install behavior** context (**System** or **User**). The IME captures the process **exit code**.
4. **Exit-code mapping.** The returned code is mapped through the app's **Return codes** table to
   Success, Failure, Soft reboot, Hard reboot, or Retry. An unmapped code defaults to **Failure**
   even when the removal actually worked.
5. **Detection evaluation — AFTER the uninstall.** The IME re-runs the **same detection rules**.
   Removal is only reported successful when detection now returns **not detected**. If detection
   still matches — a leftover registry key, a leftover file, an over-broad version operator — Intune
   treats the removal as failed and **retries the uninstall on every cycle, indefinitely**.
6. **Reporting.** The device reports status back; it appears under the app's **Device install
   status** blade and in Graph as an `installState` of `uninstallFailed`, `notInstalled`,
   `installed`, `pendingInstall`, or `unknown`.

**The two facts that explain most uninstall tickets:**

> **Detection is the gate on both ends of the removal.** It decides whether the uninstall command
> runs *at all*, and it decides whether the removal is judged successful. A detection rule that is
> wrong in one direction makes uninstall a no-op; wrong in the other direction, it makes uninstall an
> infinite retry loop.

> **Required beats Uninstall.** Intent conflicts do not raise an error anywhere in the console. You
> must go looking for them.

## The diagnostic model

Three moves, always in this order:

1. **Establish the facts (Step 0).** Determine the *reported* state, the *actual* on-device state,
   and every assignment that touches this app. Never start fixing before you know all three; most
   wasted hours come from fixing a command line when the real problem was an assignment.
2. **Pick the one branch that owns your symptom.** The playbook in `03-implementation.md` is a set of
   labelled branches (A–I). Each branch gives **symptom → why it happens → the exact fix → how to
   re-validate**. Work one branch at a time.
3. **Prove removal, then expand.** Removal is only "done" when the app is gone from the device *and*
   Intune agrees it is gone *and* it does not come back on the next cycle. The gates in
   `05-testing.md` enforce all three.

## The objects this solution creates

These exact names are used consistently in every step, test, and script in this package:

| Object | Exact name | What it is |
|---|---|---|
| Entra security group (**Assigned**) | `APPUNIN – Uninstall – Pilot` | The small pilot group that receives the Uninstall assignment first. |
| Entra security group (**Assigned**) | `APPUNIN – Uninstall – Production` | The fleet group that receives the Uninstall assignment after the pilot passes. |
| Entra security group (**Assigned**) | `APPUNIN – Uninstall – Exclusions` | Devices explicitly excluded from removal (break-fix, executives, lab). |
| Intune device filter | `APPUNIN – Windows Only` | Filter used on the Uninstall assignment so it applies only to Windows 10/11 devices. |
| Evidence folder (on device) | `C:\ProgramData\APPUNIN\Evidence` | Where you save the verbose MSI log and the discovery output for the failing device. |

## The standard deployment model

This solution follows the same model as every solution in this category:
**Assess → Configure → Pilot → Validate → Expand.** For a removal campaign that means: establish the
facts, correct the app object, prove removal on `APPUNIN – Uninstall – Pilot`, then move the
assignment to `APPUNIN – Uninstall – Production`.

## What is in this solution

- **This overview** — how the Uninstall intent is processed and the diagnostic model.
- **Requirements** (`02-requirements.md`) — roles, Graph scopes, device access, each with a verify
  step and a fix if missing.
- **Diagnostic Playbook** (`03-implementation.md`) — Step 0 plus branches **A–I**, the core of the
  package.
- **Testing** (`05-testing.md`) — the four pass/fail removal gates.
- **Troubleshooting** (`06-troubleshooting.md`) — problems with the method, scripts, and access.
- **Best practices** (`07-best-practices.md`) — how to author apps so removal works the first time.
- **Deliverables summary** (`08-deliverables-summary.md`) and the **executive summary**.
- **Five PowerShell scripts** — Discovery, Validation, Report, LogParser, and Remediation.
