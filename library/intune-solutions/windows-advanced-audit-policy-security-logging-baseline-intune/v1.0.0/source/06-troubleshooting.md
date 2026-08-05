# 6. Troubleshooting — Windows Advanced Audit Policy & Security Logging Baseline

Work top-down: confirm the **profile is applied**, then the **force-subcategory override is on**, then
the **individual subcategories**, then the **log**. The overwhelming majority of "it says applied but
nothing is audited" cases are the override being off (`SCENoApplyLegacyAuditPolicy = 0`) or a legacy
basic-audit policy fighting the advanced one. Each symptom below gives the **likely cause** and the
**fix**.

> **Before you start:** decide which problem you have. "Nothing is being audited" is an *override /
> conflict* problem. "Events are audited but I can't find them in my SIEM" is a *forwarding* problem —
> that is the separate *Entra ID & Intune Audit Telemetry to Microsoft Sentinel* solution, not this
> baseline.

## Symptom: The profile never appears / shows no status on the device
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in **`Win Audit Policy - Pilot Devices`** and the profile is **assigned**
   (`WINAUDIT-Validation.ps1`).
2. Force a sync (**Settings → Accounts → Access work or school → Info → Sync**) and wait a check-in.
3. Check **Devices → Configuration → `Win Audit Policy - Baseline - Pilot` → Device status** for an
   error.

## Symptom: Device status is "Succeeded" but `auditpol` shows nothing changed
**Likely cause:** The **force-subcategory override is off** — advanced subcategories are being ignored.
**This is the most common failure.**
**Fix:**
1. On the device (elevated): `reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v
   SCENoApplyLegacyAuditPolicy`. If it is `0x0` or missing, the override is off.
2. Confirm the profile sets **"Audit: Force audit policy subcategory settings … to override audit
   policy category settings" = Enabled** (Implementation Step 6a).
3. Find and remove any **legacy basic Audit Policy** (the nine categories) still applied by GPO or a
   third-party tool (R5) — a basic policy re-disables the override. Re-sync and re-check.

## Symptom: Profile shows "Error" / "Conflict" in Device status
**Likely cause:** A second configuration profile sets the same audit settings or the override to a
different value.
**Fix:**
1. Run `WINAUDIT-Discovery.ps1` and review **Devices → Configuration** for other profiles touching
   auditing or `SCENoApplyLegacyAuditPolicy`.
2. Ensure only **one** profile owns the audit baseline for a given device; remove or re-scope the
   duplicate so a device is not targeted by two.

## Symptom: 4688 Process Creation events appear but have no command line
**Likely cause:** Command-line process auditing not applied.
**Fix:**
1. Confirm the profile includes **Administrative Templates → System → Audit Process Creation → Include
   command line in process creation events = Enabled** (Step 6c).
2. Re-sync; new 4688 events (created *after* the setting applies) will carry the **Process Command
   Line** field — existing events are not retroactively updated.

## Symptom: A specific subcategory isn't auditing what you expect
**Likely cause:** Wrong value in the profile, the override is off (see above), or the subcategory
doesn't exist on that Windows build.
**Fix:**
1. On the device: `auditpol /get /category:*` and compare against the recommended table (Step 6b).
2. If one subcategory is wrong, correct its value in `Win Audit Policy - Baseline - Pilot` and re-sync.
3. If the subcategory is missing entirely (e.g. Group Membership / PNP Activity on an old build),
   confirm the device meets the supported baseline (R2).

## Symptom: The Security log fills up / events disappear within hours
**Likely cause:** Log too small for the enabled volume, or retention set to "do not overwrite."
**Fix:**
1. Confirm **Specify the maximum log file size (KB)** is set (Step 6d) — 196608 KB baseline, larger if
   you forward on a schedule.
2. Set retention to **overwrite events as needed (oldest first)** so a full log never blocks new
   auditing.
3. If a specific host is still overrun, it is likely a high-volume subcategory (Detailed File Share,
   Filtering Platform Connection, Process Creation on a build host) — dial that subcategory down on a
   **server** variant of the profile (Best Practices) and forward to a SIEM rather than retaining
   locally.

## Symptom: Too many events / SIEM ingestion cost spiked after rollout
**Likely cause:** A high-volume subcategory enabled fleet-wide (often Filtering Platform Connection or
Detailed File Share at Success).
**Fix:**
1. Identify the noisy Event IDs (5156/5157 = Filtering Platform Connection; 5145 = Detailed File Share).
2. Set those subcategories back to the baseline default (Filtering Platform Connection = **No
   Auditing** on workstations; Detailed File Share = **Failure**) in the profile, and re-sync.
3. Keep the high-value, lower-volume subcategories on; only enable the loud ones where you are actively
   investigating.

## Symptom: Works on some devices, not others
**Likely cause:** Group membership, unsupported build, or a per-device legacy audit conflict.
**Fix:**
1. Confirm affected devices are in the assigned group (`WINAUDIT-Report.ps1`).
2. Confirm each device meets the supported build (R2) and shows `SCENoApplyLegacyAuditPolicy = 1`.
3. Re-run `WINAUDIT-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping, then re-sync
   the stragglers.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or on an unsupported build.
**Fix:**
1. Run `WINAUDIT-Report.ps1` to list which devices lack the applied baseline.
2. Run `WINAUDIT-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R1) and build (R2).

## Escalation checklist
Before opening a Microsoft support case, collect: the `WINAUDIT-Discovery.ps1` output, the profile's
Device status export, the on-device `auditpol /get /category:*` output, the `SCENoApplyLegacyAuditPolicy`
registry value, a sample of the expected Security events (4624/4688 with command line), the Windows
build, and whether any legacy basic-audit GPO is still applied (isolates a policy conflict from a
device-side issue).
