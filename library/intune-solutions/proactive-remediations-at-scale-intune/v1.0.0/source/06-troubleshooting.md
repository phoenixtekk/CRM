# 6. Troubleshooting — Proactive Remediations at Scale (Detection & Remediation Script Packs for Microsoft Intune)

Work top-down: confirm the pair **runs at all** (agent + context), then the **exit-code contract** is
read correctly, then that remediation **acts once and stops** (no loop / no over-apply), then
**output visibility**, and finally **licensing**. Most issues are a script that ran in the wrong
context (so it "did nothing"), or an exit code the console interpreted differently than you intended.

> Portal paths and column labels below follow the common **Reports → Endpoint analytics →
> Remediations** experience and Microsoft Graph **beta** endpoints; both change over time and by cloud
> — **verify against current Microsoft documentation** for your tenant.

## The script doesn't run at all (no status reported)
- **Intune Management Extension missing/unhealthy.** IME executes the pair on-device; if it isn't
  installed or is broken, nothing runs and no status returns. Confirm the **Microsoft Intune
  Management Extension** service is present and running (Requirements §R4); assigning any Intune
  PowerShell script/Win32 app installs IME.
- **Not assigned / not yet scheduled.** Confirm `PROREM – Service Health – w32time – Pilot` is
  assigned to `PILOT – Remediations – Devices` with a schedule (Implementation §6) and allow a cycle.
  Run `PROREM-Validate.ps1`.
- **Signing/execution policy blocked it.** If your org enforces script signing, an unsigned pack
  fails to run. Sign the scripts or set the run/signing options Microsoft documents for your case
  (Requirements §R5) — **verify current behavior**.

## The script runs but "does nothing" (wrong run context)
- **System-vs-user mismatch.** A remediation that edits `HKLM`/a service must run as **system**; one
  that edits `HKCU`/the user profile must run in the **logged-on user's** context. The wrong context
  runs successfully but changes nothing on the intended target. Set **Run this script using the
  logged-on credentials** to match what the pair touches (Requirements §R6, Implementation §3/§5), and
  re-test.
- **64-bit vs 32-bit.** A pair touching 64-bit locations must run in **64-bit PowerShell**; check the
  package's run-as-64-bit option. **Verify the current option/behavior with Microsoft.**
- **No signed-in user for a user-context pair.** A user-context script has nothing to act on when no
  one is logged in — expected; it will act at next run with a user present.

## Exit code misread as failure (or success)
- **Detection contract confusion.** Detection must use **`exit 0` = healthy** and **`exit 1` = issue
  found**. If your detection exits non-zero on a *healthy* device, the console runs remediation
  needlessly; if it exits 0 on an *affected* device, remediation never runs. Re-check the exit paths
  in `Detect-ServiceHealth-w32time.ps1` (or `PROREM-Detect-Template.ps1`).
- **Remediation reporting "failed" wrongly.** A remediation that fixed the device must **`exit 0`**; a
  non-zero exit is reported as *Remediation failed* even if the device is now fine. Ensure the acting
  path ends in `exit 0` and only genuine failures `exit 1`.
- **Unhandled terminating error.** An uncaught exception exits non-zero and looks like a failure —
  wrap risky operations in `try/catch` and set a deliberate exit code (the templates do this).

## Remediation loops or over-applies (fix won't hold / churns the fleet)
- **The fix isn't holding.** If the same devices report *Issue remediated* (or recur) every cycle,
  something re-breaks the condition after the fix, or the fix addressed a symptom, not the cause.
  **Pause the assignment**, inspect the on-device log (`C:\ProgramData\Remediations\`), and fix the
  root cause before re-enabling. `PROREM-Report.ps1` shows the recurring/not-remediated trend.
- **Detection over-fires.** An overly broad detection flags healthy devices, so remediation keeps
  acting. Tighten the detection condition to exactly the wrong state.
- **Not idempotent.** A remediation that changes something every run (instead of only when needed)
  causes thrash. Confirm the "already healthy → no change → exit 0" path (Testing §Test 6).
- **Guardrail:** you caught none of this at scale if you piloted — this is what the **preview + pilot
  ring** (Implementation §6/§8) exist for. Unassign to stop instantly; keep a **revert** remediation
  for impactful changes.

## Output is truncated or missing in the console
- **Size/format limits.** The console captures a limited amount of script output; very large output is
  **truncated**, and reporting is on a **delay**. Keep script output to a short, meaningful line and
  rely on the **on-device log** (`C:\ProgramData\Remediations\`) for full detail — the templates write
  both. **Verify current output-size limits against Microsoft's documentation.**
- **Reporting delay mistaken for "no result".** Status can lag the actual run; allow the reporting
  interval before concluding a device didn't report.

## The Remediations experience is unavailable (licensing/entitlement gap)
- **Missing entitlement.** If **Reports → Endpoint analytics → Remediations** is absent or blocked,
  the tenant likely lacks the Proactive Remediations entitlement — **do not assume a specific SKU;
  verify the current licensing requirement with Microsoft** (Requirements §R1) for your subscription
  and cloud (Commercial vs. GCC/GCC High/DoD may differ).
- **Endpoint Analytics not enabled.** Proactive Remediations lives inside Endpoint Analytics; if
  analytics isn't onboarded, complete the parent solution first (Requirements §R2).

## Useful checkpoints
- **Intune:** Reports → Endpoint analytics → **Remediations** → the package → **Device status**
  (detection/remediation status + pre/post output); the package **Properties** (run-as context,
  signing, 64-bit); **Assignments** (groups + schedule).
- **On device:** the **Intune Management Extension** service; the remediation **log** under
  `C:\ProgramData\Remediations\`.
- **Scripts:** `PROREM-Discovery.ps1` (what's deployed + run-status roll-up), `PROREM-Validate.ps1`
  (pilot gate), `PROREM-Report.ps1` (success-fail trend / loop detection). All read-only.
