# 3. Implementation Guide — SCCM Task Sequence Troubleshooting & Status Message Analysis

Follow these steps **in order**. This is the runbook: it takes a failed task-sequence deployment and
drives it to a root cause and a fix. Console work is in the **Configuration Manager console**;
scripts run from a **ConfigurationManager PowerShell** session (site drive `PS XYZ:\>`).

> **Model:** Assess the failure → configure the queries and log access → pilot the runbook on a real
> failure → validate the diagnosis and fix → expand it to the deployment team. Name every artifact
> you create with `<Purpose> – <Scope> – <Stage>` and reuse the names.

## Step 1 — Assess: confirm the deployment state
1. Console → **Monitoring → Deployments**. Find the task-sequence deployment; note **Success**,
   **In Progress**, **Error**, and **Unknown** counts.
2. Open the deployment → **View Status** → the **Error** and **In Progress** tabs list the failing
   devices. Record the device name(s) and the last state.
3. Alternatively run `SCCMTS-Discovery.ps1` to list task-sequence deployments and their recent
   per-device states from the site.

## Step 2 — Configure: create the status message query
1. Console → **Monitoring → System Status → Status Message Queries → Create Status Message Query**.
2. **Name:** `TS Execution Errors – OSD – Triage` (reuse this exact name). **Edit Query Statement →
   Show Query Language** and target the task-sequence engine messages for the device/time window:
   filter **Message ID** in (`11123`, `11124`, `11127`, `11170`, `11171`) and set the machine name /
   date prompt.
3. **OK → Run**. When prompted, enter the failing device and a time range covering the run.
4. Read the results newest-first: `11124` (or `11170`) is the failure and carries the **failing step
   name** and an **exit/error code**. `SCCMTS-Discovery.ps1` returns the same messages if you prefer
   script output.

## Step 3 — Capture the exit code
1. From the `11124`/`11170` message, record the **step name** and the **exit code** (decimal and
   hex). This is the key that narrows the search.
2. Map it against the exit-code table in `01-solution-overview.md` (or run `SCCMTS-Report.ps1`, which
   summarizes failures and breaks them down by exit code across the collection).

## Step 4 — Open the phase-correct `smsts.log`
1. Determine the phase from where the sequence failed (WinPE vs. full OS) — the status message time
   and step name tell you.
2. Open the matching log with **CMTrace**:
   - WinPE (pre-format): `x:\windows\temp\smstslog\smsts.log` (press **F8** in WinPE to get a prompt).
   - WinPE (disk available): `<drive>:\_SMSTaskSequence\Logs\Smstslog\smsts.log`.
   - Full OS, client not yet installed: `c:\_SMSTaskSequence\Logs\Smstslog\smsts.log`.
   - Full OS, client installed / after completion: `c:\windows\ccm\logs\smsts.log`.
3. Search up from the last `Failed`/`error`/`0x...` line. The entries just above it name the action,
   the command, and the inner reason. That is your root cause.

## Step 5 — Classify the failure
Using the exit code (Step 3) and the log detail (Step 4), assign the failure to a class:
`Content/DP`, `Drivers`, `Network/PXE`, `Application install`, `Reboot/continuation`, or
`Task-sequence variables/logic` (see §1 for each class's tell).

## Step 6 — Apply the class fix
- **Content / DP:** Confirm the package/app is distributed to a DP the client reaches
  (**Monitoring → Distribution Status → Content Status**); redistribute if `Failed`; validate the DP.
  Check the boundary/boundary-group so the client selects a reachable DP.
- **Drivers:** Replace the wrong driver package; scope Apply Driver Package by model with a WMI
  condition, or fix Auto Apply Drivers categories. Re-distribute the driver package.
- **Network / PXE:** Add the correct NIC driver to the **boot image** and update DPs; verify the boot
  image architecture matches the hardware; confirm DHCP/PXE (IP Helpers or options) and PXE responder.
- **Application install:** Read the app's own installer log for the exit code (for example `1603`,
  `1618`); fix the install command/switches or detection; add a serialize/retry for `1618`.
- **Reboot / continuation:** Fix boot order so the OS disk boots; suspend BitLocker during the build;
  ensure the Restart Computer step targets the right OS/WinPE.
- **Variables / logic:** Correct the step **condition**, collection/task-sequence variable, or the
  missing variable that steered the run; re-check with the variable listing.

## Step 7 — Re-run and confirm success
1. Re-deploy / re-run the task sequence on the piloted device (or clear the last run so it re-evaluates
   — see `SCCMTS-Remediation.ps1`, which is `-WhatIf` by default).
2. Confirm success: status message **`11127`** and step exit code **`0`** (or `3010`), and the
   deployment shows **Success**. Run `SCCMTS-Validation.ps1` to confirm the deployment state for the
   device/collection.

## Step 8 — Record the resolution
1. Capture the status ID, exit code, class, root cause, and fix in your runbook log (name it
   `OSD Failure Log – <Site> – Runbook`). This is what makes the next diagnosis faster.

## Step 9 — Validate the runbook (pilot gate)
1. Run the full loop (Steps 1–8) on **at least two** real, different failures. Confirm each was
   diagnosed to the correct step and exit code and resolved. Complete the **Testing Guide**.

## Step 10 — Expand to the deployment team
1. Save the status message query, the scripts, and the recorded resolutions where the team works.
2. Make this the standard triage path for OSD failures; re-validate periodically as boot images,
   drivers, and apps change.

---
### Order of operations
`Assess state → Status message query → Capture exit code → Read phase-correct smsts.log →
Classify → Fix by class → Re-run + confirm 11127/0 → Record → Validate on real failures → Expand`
