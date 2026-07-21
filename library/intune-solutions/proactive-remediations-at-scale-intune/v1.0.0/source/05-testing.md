# 5. Testing & Validation — Proactive Remediations at Scale (Detection & Remediation Script Packs for Microsoft Intune)

Validate against the **pilot ring** (`PILOT – Remediations – Devices`) before expanding. Each test has
an explicit **PASS/FAIL** gate. Use the included PowerShell scripts (Microsoft Graph) for tenant-side
checks and the on-device / console steps for behavior. The worked example is the
**`PROREM – Service Health – w32time – Pilot`** package built in Implementation.

> **Seed the issue first.** On one pilot device, deliberately break the target condition so detection
> has something to find: set the **Windows Time service (`w32time`)** to **Disabled** (or stop it).
> This "seeded issue" device is your positive test; leave at least one pilot device healthy as the
> negative test.

## Test 1 — Package is present, assigned, and reporting
**Procedure:** Run `PROREM-Discovery.ps1`, then `PROREM-Validate.ps1`.
**PASS:** `PROREM – Service Health – w32time – Pilot` exists, is assigned to
`PILOT – Remediations – Devices`, has a schedule, and is returning run status (devices reporting).
**FAIL:** Missing / unassigned / no status → fix the assignment and schedule (Implementation §5–6),
confirm the Intune Management Extension is healthy (Requirements §R4), then re-run.

## Test 2 — Detection correctly flags the seeded issue (and only it)
**Procedure:** After a detection cycle, open the package → **Device status** in the console.
**PASS:** The **seeded** device reports **With issue** (detection exited non-zero) and the **healthy**
pilot device reports **Without issue** (detection exited zero). Detection did **not** change either
device (it is read-only).
**FAIL:** Seeded device shows *Without issue* → detection logic or run context is wrong (Requirements
§R6). Healthy device shows *With issue* → detection is over-firing; tighten the condition.

## Test 3 — A bad remediation is caught in dry-run (preview) — before it can act
**Procedure:** With the **preview** remediation assigned (Implementation §6), read the seeded device's
remediation **output/log** (`C:\ProgramData\Remediations\`) and the console's pre/post output columns.
**PASS:** The preview log shows **exactly the intended minimal change** it *would* make (set `w32time`
to Automatic and start it) and **no device was actually changed** — the service is still Disabled
after the preview run. If the preview log revealed a wrong or over-broad action, it is caught **here**,
with zero fleet impact.
**FAIL:** The preview changed the device (it is not truly dry-run), or the log shows an unintended
action → fix the remediation before proceeding. **This gate is the safety net; do not skip it.**

## Test 4 — Remediation fixes the seeded issue
**Procedure:** Flip the remediation to its **acting** version (Implementation §8) and let a cycle run.
**PASS:** On the seeded device, the remediation reports **Issue remediated** (exit 0); on the device,
`w32time` is now **Automatic** and **Running**. The healthy pilot device was **never remediated**
(detection kept it out).
**FAIL:** *Remediation failed* → check run context/permissions (system vs user, Requirements §R6) and
the log. Healthy device got remediated → detection/exit-code contract is wrong (Test 2).

## Test 5 — Re-detection proves the fix held
**Procedure:** Let the **next** detection cycle run; re-read **Device status** and export with
`PROREM-Report.ps1`.
**PASS:** The previously seeded device now reports **Without issue** on re-detection — evidence the
fix worked and **held**. The success/failure trend in the CSV shows "with issue" dropping to zero for
the pilot.
**FAIL:** The device flips back to *With issue* every cycle → the fix isn't holding (something re-
breaks it) or detection over-fires → investigate the loop (Troubleshooting) **before** widening.

## Test 6 — Idempotency (no thrash on healthy devices)
**Procedure:** Over several cycles, watch an already-healthy pilot device.
**PASS:** Detection keeps it **Without issue** and remediation **never runs** on it; running the
remediation manually on a fixed device makes **no further change** and still exits 0.
**FAIL:** Remediation runs repeatedly on a healthy device → detection isn't idempotent or the fix
isn't idempotent → correct before Expand.

## Acceptance gate
Proceed to **Expand** (production waves) only when **Tests 1–6 pass**: the package is assigned and
reporting, **detection flags only the seeded issue**, a **bad remediation would be caught in
preview**, the **acting remediation fixes the issue**, **re-detection proves it held**, and the pair
is **idempotent** with no thrash. Anything less stays in the pilot ring until it passes.
