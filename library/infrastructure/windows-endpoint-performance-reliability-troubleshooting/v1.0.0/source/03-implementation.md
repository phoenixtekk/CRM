# Diagnostic Playbook

This is the heart of the solution: a **symptom tree** that turns a complaint into a measured cause and
a targeted fix. Start from the user's own words, pick the matching branch, run the measurement, read
it against the gate, and act. Every branch ends with a **re-measure** step so you prove the fix.

**The loop, every time:** Measure → Isolate → Fix → Re-measure.

Run the two collectors first so you have numbers in front of you:

- **WINPERF-Discovery.ps1** — quick, read-only fleet/device sweep of the signals.
- **WINPERF-Validation.ps1** — deep, per-device measurement (this is what each branch below reads).

If you have Intune **Endpoint analytics** (requirement R5), also open **Reports → Endpoint analytics →
Startup performance / Application reliability** to see how this device compares to the fleet baseline.

---

## Branch A — Slow boot ("it takes forever to turn on / get to the login screen")

**What to measure**

1. Boot duration from the Diagnostics-Performance log:
   `Get-WinEvent -LogName 'Microsoft-Windows-Diagnostics-Performance/Operational' -FilterXPath "*[System[(EventID=100)]]" -MaxEvents 5`
   — event **100** carries `BootTime` (total) and `MainPathBootTime` in milliseconds.
2. Slow contributors — same log, event IDs **101** (slow app), **102** (slow driver), **103** (slow
   service), **106** (slow background optimization), **109** (slow device).
3. Boot-critical disk — is the OS on an SSD or HDD? `Get-PhysicalDisk | Select MediaType, HealthStatus`.

**How to read it (pass/fail gate)**

- **PASS:** `BootTime` ≤ 60,000 ms (60 s) on an SSD device, and no repeated 102/103 slow warnings.
- **FAIL:** `BootTime` > 60 s, or the same driver (102) / service (103) appears slow across multiple
  boots.

**Isolate → fix**

- **Slow disk at boot** (HDD, or SSD `HealthStatus` not Healthy) → go to **Branch E (Storage health)**;
  the disk is the cause.
- **A specific driver stalls (102)** → note the driver name; update it (vendor / Windows Update /
  Intune driver policy). If a recently added driver, roll it back.
- **A specific service stalls (103)** → identify the service (`Get-Service the-service-name`); if it is a
  non-essential third-party auto-start, set it to **Automatic (Delayed Start)** or disable it. The
  safe, common case (trimming non-essential auto-start startup items) is handled by
  **WINPERF-Remediation.ps1 -Area Startup** (preview first with `-WhatIf`).
- **Too many auto-starts (many 101/103)** → trim startup services/apps (Remediation, Startup area).

**Re-measure:** reboot twice (the first reboot re-baselines), re-read event 100. Confirm `BootTime`
now meets the PASS gate.

---

## Branch B — Slow sign-in / profile ("it's slow from login to a usable desktop")

**What to measure**

1. Sign-in duration — from **Endpoint analytics → Startup performance** (it separates *core boot* from
   *sign-in* / *time to first responsive desktop*). If analytics is unavailable, use the User Profile
   Service log:
   `Get-WinEvent -LogName 'Microsoft-Windows-User Profile Service/Operational' -MaxEvents 40` and look
   for long gaps between profile-load start and finish.
2. Profile size — `Get-CimInstance Win32_UserProfile | Select LocalPath, @{n='SizeGB';e={...}}` (the
   Validation script computes this); a very large local profile slows load.
3. Startup-app count — inventory `HKCU/HKLM ...\Run`, the Startup folders, and scheduled logon tasks
   (the Validation script lists these).
4. Blocking logon scripts / policies — long-running GPO/Intune logon scripts.

**How to read it (pass/fail gate)**

- **PASS:** sign-in ≤ 30 s to a responsive desktop; profile a reasonable size for the environment;
  a manageable startup-app count (roughly ≤ 10 auto-start user apps as a working default — set your
  own from the fleet baseline).
- **FAIL:** sign-in > 30 s, an oversized/growing profile, or a large pile of startup apps.

**Isolate → fix**

- **Large or corrupt profile** → if roaming/FSLogix/OneDrive Known Folder Move is in play, check the
  container/sync health first. For a corrupt local profile, back up user data and recreate the profile
  (the Remediation script's **Profile** area handles the safe, reversible parts — clearing stale
  temp/cache within the profile — and flags a full profile rebuild for manual action).
- **Heavy startup apps** → disable non-essential ones (**Remediation -Area Startup**, preview first).
- **Blocking logon script/policy** → find the slow script from the User Profile Service / GroupPolicy
  logs and make it asynchronous or remove it.

**Re-measure:** sign the user out and back in; re-check sign-in duration against the PASS gate.

---

## Branch C — High CPU / RAM / disk ("it's slow while I'm working")

This branch measures **steady-state resource pressure** and names the top consumer. It samples over a
window so a momentary spike is not mistaken for a chronic problem.

**What to measure**

1. Sample counters over ~60 seconds (the Validation script does this):
   - CPU: `\Processor(_Total)\% Processor Time`
   - Memory: `\Memory\% Committed Bytes In Use`, `\Memory\Available MBytes`
   - Disk: `\PhysicalDisk(_Total)\% Disk Time`, `\PhysicalDisk(_Total)\Current Disk Queue Length`
2. Top consumers: `Get-Process | Sort CPU -Descending | Select -First 5` and
   `Get-Process | Sort WorkingSet -Descending | Select -First 5`.

**How to read it (pass/fail gate)**

- **CPU PASS:** average `% Processor Time` < 70% over the window with no single non-system process
  holding the CPU. **FAIL:** sustained ≥ 85%, or one app pinning a core continuously.
- **RAM PASS:** `% Committed Bytes In Use` < 80% and Available MBytes comfortably above zero.
  **FAIL:** committed ≥ 90% / available near zero (constant paging).
- **Disk PASS:** average `% Disk Time` < 80% and queue length < 2 sustained. **FAIL:** disk pinned at
  ~100% with a growing queue.

**Isolate → fix**

- **One process pins CPU** → identify it; update or reconfigure the app, or (if hung) end it. If it is
  a Windows/AV process peaking during a scan, confirm it settles after the scan.
- **Memory exhausted / leak** → find the process whose working set climbs without release; update or
  replace it. If all apps are legitimate and RAM is simply insufficient, record a **hardware RAM
  upgrade** recommendation with the measured evidence.
- **Disk pinned at 100%** → find the process driving I/O. If the drive itself is slow/failing, go to
  **Branch E (Storage health)**. If a background task (search indexing, backup, AV scan) is the cause,
  reschedule it.

**Re-measure:** after the fix, re-sample the counters over another 60 s window; confirm the failing
counter now meets its PASS gate.

---

## Branch D — Crashes / bugchecks ("it blue-screens" / "an app keeps dying")

Separate the two crash types — they have different causes and fixes.

**What to measure**

1. System crashes / bugchecks:
   `Get-WinEvent -LogName System -FilterXPath "*[System[(EventID=1001)]]"` — the **BugCheck** event
   (1001) records the **Stop code** and parameters. Event **41** (Kernel-Power) counts *unexpected*
   shutdowns (power loss / hard hang).
2. Application crashes/hangs:
   `Get-WinEvent -LogName Application -FilterXPath "*[System[(EventID=1000 or EventID=1002)]]"` —
   **1000** = application error (faulting module), **1002** = application hang.
3. Reliability history: `Get-CimInstance Win32_ReliabilityRecords` for a timeline and the reliability
   index trend (also visible in **Endpoint analytics → Application reliability**).

**How to read it (pass/fail gate)**

- **PASS:** no bugcheck (1001) in the last 14 days and no repeated same-app crash (1000/1002).
- **FAIL:** any bugcheck in the window, or the same faulting module/app crashing repeatedly.

**Isolate → fix**

- **Recurring bugcheck code** → map the **Stop code** to its cause (most bugchecks point to a driver
  or failing hardware). Note the faulting driver in the event; update or roll it back. If the code
  points to memory/storage, run hardware diagnostics and go to **Branch E**.
- **Same app keeps crashing** → note the **faulting module** in event 1000; update or repair the app
  (or its runtime, e.g. .NET / Visual C++ redistributable). Replace if unfixable.
- **Unexpected shutdowns (event 41 with no bugcheck)** → suspect power (battery/adapter/PSU) or thermal
  shutdown; investigate hardware/power and check for overheating.

**Re-measure:** after the fix, monitor for the crash-free window (the PASS gate) before closing.
Bugchecks are proven fixed only by absence over time.

---

## Branch E — Storage / SSD health (underlies A, B, C)

Rule this out early — a failing, worn, or full drive causes slow boot, slow sign-in, high disk %, and
crashes all at once.

**What to measure**

1. Physical health: `Get-PhysicalDisk | Select FriendlyName, MediaType, HealthStatus, OperationalStatus`.
2. Failure prediction (SMART):
   `Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus` — a
   `PredictFailure = True` is an early-warning that the drive is dying.
3. Free space: `Get-Volume | Select DriveLetter, FileSystemLabel, SizeRemaining, Size` — compute
   free %.
4. Media type: SSD vs HDD (`MediaType`) — is a device that *should* have an SSD still on an HDD?

**How to read it (pass/fail gate)**

- **PASS:** `HealthStatus = Healthy`, `PredictFailure = False`, free space ≥ 15% of the volume.
- **FAIL:** HealthStatus Warning/Unhealthy, PredictFailure True, or free space < 15%.

**Isolate → fix**

- **PredictFailure = True / HealthStatus not Healthy** → this is **hardware**. Back up the user's data
  immediately, then schedule a **drive replacement**. Do not "fix" a dying drive in software.
- **Nearly full (< 15% free)** → safe cleanup: clear Windows and user temp, empty recycle bin, clear
  browser/app caches, run the Storage Sense / cleanup tasks. **WINPERF-Remediation.ps1 -Area Temp**
  does the safe cleanup (preview with `-WhatIf` first, so you see the reclaimable space before
  deleting).
- **HDD where an SSD is expected** → record a **hardware refresh** recommendation with the measured
  boot/sign-in impact as justification.

**Re-measure:** re-run **WINPERF-Validation.ps1** and confirm free space / health now pass, and that
the boot/disk symptoms that pointed here have improved.

---

## After any branch — confirm and record

1. Re-run the branch's measurement and confirm it meets the **PASS** gate in **05 — Testing**.
2. If it still fails, you picked the wrong branch — return to the root-cause tree in
   **01 — Solution Overview** and follow the next-most-likely branch.
3. Record the device, the symptom, the measured cause, the fix, and the before/after numbers. This is
   your baseline for next time and feeds the fleet report (**WINPERF-Report.ps1**).
