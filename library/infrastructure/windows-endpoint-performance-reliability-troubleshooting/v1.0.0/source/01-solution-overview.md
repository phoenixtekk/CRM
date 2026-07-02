# Solution Overview

## The problem this solves

"My computer is slow." "It keeps crashing." "It takes forever to log in." These are the tickets no
one can quantify. They get closed with a reboot, a reimage, or a shrug — and they come back. This
solution replaces guesswork with a **measure-first root-cause method**: you turn a vague complaint
into a measured cause and a targeted fix, on an enterprise, Intune-managed Windows fleet.

The core discipline is simple and repeatable: **measure it → isolate it → fix it.** You never change
anything until a signal tells you what is actually wrong, and you re-measure to confirm the fix
worked.

## The performance & reliability model

Every Windows endpoint moves through the same lifecycle each day. Slowness or instability lives in
one (or more) of these stages. The model gives you a place to look for every complaint:

1. **Boot** — from power-on to the sign-in screen. The OS loads the kernel, drivers, and services.
   Slow boot usually means a slow disk, a stalling driver, or too many auto-start services.
2. **Sign-in / profile** — from entering credentials to a usable desktop. The user profile loads,
   Group Policy / Intune policy applies, logon scripts and startup apps run, and (for roaming/FSLogix
   or OneDrive) the profile container mounts. Slow sign-in usually means a large or corrupt profile,
   heavy startup apps, or a policy/script that blocks.
3. **Steady-state resource use** — the desktop is up and the user is working. Here you measure
   **CPU, memory (RAM), and disk** pressure. A runaway process, a memory leak, or a disk pinned at
   100% makes everything feel slow.
4. **Stability** — does the machine stay up? Crashes come in two flavors: **application crashes**
   (one app dies, logged as Application Error / .NET Runtime / AppHang) and **system crashes /
   bugchecks** (the blue screen / Stop error — the whole OS goes down, a memory dump is written).
5. **Storage / SSD health** — underlying all of the above. A failing or worn drive, a nearly full
   disk, or a drive with no free space for paging makes boot, sign-in, and steady-state all slow, and
   can cause crashes. This is a physical layer you must rule out early.

## Signals to measure

Each stage has concrete, measurable signals. This solution's scripts collect them; the playbook tells
you which one to read for which symptom.

| Stage | Primary signals | Where it comes from |
|-------|-----------------|---------------------|
| Boot | Boot duration; time to sign-in screen; slow-service / slow-driver warnings | Event log **Diagnostics-Performance/Operational** (event IDs 100–110); Intune **Endpoint analytics → Startup performance** where available |
| Sign-in / profile | Sign-in duration; profile size; number of startup apps; slow logon events | Endpoint analytics; **User Profile Service** log; `Win32_UserProfile`; startup app inventory |
| Resource — CPU | % processor time; top processes by CPU | Performance counters; `Get-Process` / `Get-Counter` |
| Resource — RAM | Committed / available memory; top processes by working set; page-file pressure | `Get-Counter` memory counters; `Get-Process` |
| Resource — Disk | Disk % active time; disk queue length; free space | Performance counters; `Get-Volume` |
| Stability | Bugcheck (Stop) events; app-crash / app-hang events; unexpected-shutdown count; reliability index | Event log **System** (ID 41, 1001), **Application** (1000, 1002); `Win32_ReliabilityRecords` |
| Storage health | SMART / predict-failure status; drive wear; free-space %; media type (SSD/HDD) | `Get-PhysicalDisk` (`HealthStatus`, `MediaType`); `MSStorageDriver_FailurePredictStatus`; `Get-Volume` |

## The root-cause tree

Start from the symptom the user reports, then follow the branch to a measured cause. The full
click-by-click measurements live in **03 — Diagnostic Playbook**; this is the map.

```
"It's slow" / "it crashes"
│
├── Slow to turn on / reach login  ───────────►  BOOT branch
│      measure boot duration + slow-service/driver events
│         ├─ slow disk at boot        → Storage health branch
│         ├─ a service/driver stalls  → disable/update that service or driver
│         └─ too many auto-starts     → trim startup services
│
├── Slow from login to usable desktop  ───────►  SIGN-IN / PROFILE branch
│      measure sign-in duration + profile size + startup-app count
│         ├─ large/corrupt profile    → profile remediation
│         ├─ heavy startup apps       → trim startup apps
│         └─ blocking script/policy   → fix the logon script / policy
│
├── Slow while working  ────────────────────►  RESOURCE branch
│      measure CPU / RAM / disk over a window; find the top consumer
│         ├─ one process pins CPU     → update/replace/kill that app
│         ├─ memory exhausted/leak    → add RAM / fix leaking app
│         └─ disk pinned at 100%      → Storage health branch / trim disk I/O
│
├── It crashes / blue-screens  ──────────────►  STABILITY branch
│      read bugcheck + app-crash events; count unexpected shutdowns
│         ├─ recurring bugcheck code  → map Stop code → driver/hardware → update/replace
│         ├─ one app keeps crashing   → update/repair/replace that app
│         └─ heat / power loss        → hardware / power investigation
│
└── (underlies everything) Disk full / drive failing  ──►  STORAGE HEALTH branch
       read SMART/predict-failure + free space + drive wear
          ├─ predict-failure = true   → back up + replace drive (hardware)
          ├─ nearly full               → safe cleanup (temp, caches)
          └─ HDD where SSD expected    → note for hardware refresh
```

## How you work through it

The whole solution follows one loop, applied per device and per fleet:

**Assess → Measure → Isolate → Fix → Re-measure.**

1. **Assess** — confirm you can read the endpoint's signals (see **02 — Requirements**).
2. **Measure** — run **WINPERF-Discovery.ps1** (fleet signals) and **WINPERF-Validation.ps1**
   (one device, deep) to collect the numbers.
3. **Isolate** — follow the root-cause tree in **03 — Diagnostic Playbook** to the branch the numbers
   point to.
4. **Fix** — apply the targeted fix. For the safe, common causes (startup bloat, temp-file disk
   pressure, profile issues) use **WINPERF-Remediation.ps1** (which defaults to a preview / `-WhatIf`
   mode so you see what it would do before it does it).
5. **Re-measure** — re-run Validation and confirm the signal moved past the pass gate in
   **05 — Testing**. If it did not, you isolated the wrong branch — go back to step 3.

A slow or crashing endpoint becomes a measured cause and a targeted fix — with an evidence-based
method and scripts you keep and reuse.
