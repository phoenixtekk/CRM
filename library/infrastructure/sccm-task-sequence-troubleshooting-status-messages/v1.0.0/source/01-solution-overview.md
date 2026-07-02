# 1. Solution Overview — SCCM Task Sequence Troubleshooting & Status Message Analysis

## What this solution is
A structured method — a runbook plus tooling — for troubleshooting **Configuration Manager task
sequences** that fail during OS deployment (OSD). Instead of re-imaging on a hunch, you read the
signals Configuration Manager already produces: task-sequence deployment **states**, **status
message IDs** and their severities, the `smsts.log` (which moves per phase), and the step
**exit code**. Those signals point to one of a small set of **failure classes**, each with a known
fix. The result is a repeatable diagnose-then-resolve loop any deployment engineer can run.

## How a task sequence reports what happened
1. A task sequence is a deployment (advertisement) targeted at a **collection**. Each device's run
   produces a **deployment status** — commonly `In Progress`, `Success`, `Failed`, `Error`, or
   `Unknown` — visible under Monitoring and per-deployment in the console.
2. As it runs, each step raises **status messages** to the management point. Status messages carry
   a numeric **Message ID** and a **severity** (Informational, Warning, Error). Reading the right
   IDs tells you which step failed and why.
3. Every step also returns an **exit code**. `0` (and often `3010`, "success, reboot required") is
   success; a non-zero code is the failing step's error — the single most important number to
   capture, because it usually maps directly to a root cause.
4. The full detail lives in `smsts.log`. Its **location changes by phase** (WinPE vs. full OS),
   which is why so many people read the wrong log and stay stuck.

## Status messages that matter (IDs and severity)
Task-sequence execution reports through the Task Sequence Engine. The IDs you will read most:

| Message ID | Severity | Meaning |
|---|---|---|
| `11123` | Informational | The task sequence started (advertisement began execution). |
| `11124` | Error | The task sequence **failed**; the message includes the failing step and an exit/error code. |
| `11127` | Informational | The task sequence **completed successfully**. |
| `11170` | Error | A task-sequence action failed to run (engine-level step failure). |
| `11171` | Informational | A task-sequence action completed. |
| `10804` / `10805` | Info/Error | Content (package/application) download progress and failures on the client. |

Content distribution and application deployment raise their own message classes (for example the
`10000`-range for software distribution and app-install evaluation). Read the **Error**-severity
message closest in time to the failure, then confirm the detail in `smsts.log`.

## Where `smsts.log` lives — by phase
The log path depends on where the task sequence is when it fails:

| Phase | `smsts.log` location |
|---|---|
| WinPE, before the disk is formatted | `x:\windows\temp\smstslog\smsts.log` |
| WinPE, after a disk is available | `x:\smstslog\smsts.log` or `<drive>:\_SMSTaskSequence\Logs\Smstslog\smsts.log` |
| Full OS, during the task sequence (client not yet installed) | `c:\_SMSTaskSequence\Logs\Smstslog\smsts.log` |
| Full OS, after the ConfigMgr client is installed | `c:\windows\ccm\logs\smsts.log` |
| After the task sequence ends (success or fail) | `c:\windows\ccm\logs\smsts.log` (final resting place on a client) |

Read it with **CMTrace** (or OneTrace) so you can follow the timeline and filter on error lines.
Search for the last `Failed`/`error`/`0x` line — the entries just above it name the step and reason.

## The common failure classes
Almost every OSD failure falls into one of these, and each has a diagnostic tell and a fix:

- **Content / distribution point** — a package or application isn't on a DP the client can reach, or
  the DP is unhealthy. Tell: content-download errors (for example `0x80070002`, `0x87D00607`).
- **Drivers** — a driver package injected via Apply Driver Package or Auto Apply Drivers is wrong for
  the model, causing a bugcheck or a device that won't network. Tell: failure right after driver steps.
- **Network / PXE** — no PXE response, wrong boot image / architecture, or the client can't reach the
  MP/DP (missing NIC driver in the boot image, VLAN/DHCP option issues). Tell: fails in WinPE early.
- **Application / package install** — an app's installer returns a non-zero exit code or detection
  fails. Tell: exit code from the installer (for example `1603`, `1618`).
- **Reboot / continuation** — the task sequence doesn't resume after a restart (boot order, BitLocker,
  or the engine losing its state). Tell: log stops at a Restart step.
- **Task-sequence variables / logic** — a condition, collection variable, or missing variable sends
  the sequence down the wrong path or skips a required step. Tell: a step is skipped or runs wrongly.

## Common exit codes → likely root cause
| Exit code (dec / hex) | Class | Likely cause |
|---|---|---|
| `0` / `0x0` | — | Success. |
| `3010` / `0xBC2` | — | Success, **reboot required** (not a failure). |
| `2` / `0x80070002` | Content | File not found — content missing on the DP, or a wrong path/name. |
| `-2147024891` / `0x80070005` | Permissions | Access denied — network access account, share ACLs, or rights. |
| `1603` / `0x643` | App install | Fatal error during MSI installation (per the app's own log). |
| `1618` / `0x652` | App install | Another install is in progress — serialize installs / add a retry. |
| `1620` / `0x654` | App install | Installer package could not be opened (corrupt/incomplete content). |
| `-2147467259` / `0x80004005` | Generic | Unspecified failure — read `smsts.log` for the real inner error. |
| `2278886630` / `0x87D00607` | Content | Content download failed / not found on any DP. |
| `2278887145` / `0x87D00269` | Client/policy | Software distribution/policy error — check MP/policy retrieval. |

Always map the code, then confirm the cause in `smsts.log` — the exit code narrows the search; the
log confirms it.

## The diagnose → resolve method
> **1. Identify the failed run** (deployment state + status message ID `11124`/`11170`). **2. Get the
> exit code** from the status message. **3. Open the right `smsts.log` for the phase** and read up
> from the last error. **4. Classify** the failure (content / driver / network / app / reboot /
> variable). **5. Apply the class fix.** **6. Re-run and confirm** (`11127` / exit `0`). **7. Record**
> the ID, code, cause, and fix so the next person is faster.

## The standard deployment model
> **Assess** the failing OSD → **Configure** access to status message queries and logs → **Pilot**
> the runbook on real failures → **Validate** the diagnoses and fixes → **Expand** it to the whole
> deployment team. repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
