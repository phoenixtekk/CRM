# 5. Testing & Validation Guide — Application Retirement

Retirement is irreversible, so validation is not a formality — each gate must **pass** before the
next wave. Use the worked example `LegacyTrack Client` (code `APPRET-LGT`). Record every result in
the decision record / evidence pack.

## Gate 0 — Data preservation (before any uninstall)
**Purpose:** prove the one-way door is safe to open.
1. On a test device, install `LegacyTrack Client`, create representative data, then run the
   uninstall command manually.
2. Inspect `C:\ProgramData\`, `%LOCALAPPDATA%`, `%APPDATA%`, and the app's registry keys for what
   survives.
3. **PASS:** either the uninstall destroys nothing that must be kept, OR all required data has been
   exported and the export verified (open one exported file and confirm it is intact).
4. **FAIL:** required data is destroyed and not yet exported — stop; complete Step 6 export first.

## Gate 1 — Assignment intent is correct (before Wave 0 runs)
**Purpose:** prove the Uninstall intent will actually win.
1. Run `APPRET-Discovery.ps1 -AppName "LegacyTrack Client"`.
2. **PASS:** the app shows an **Uninstall** assignment targeting
   `APPRET-LGT – LegacyTrack Client – Uninstall – Wave 0 Pilot`, and **no Required/Available**
   assignment overlaps the same pilot devices, and the exempt group is excluded.
3. **FAIL:** a Required assignment still covers a pilot device (Required beats Uninstall) — remove it
   (Implementation Step 7.2) and re-check.

## Gate 2 — Pilot device uninstalled and detection is absent
**Purpose:** prove removal on a real device.
1. Sync a Wave 0 device; wait a check-in cycle.
2. Run `APPRET-WaveReporter.ps1 -AppName "LegacyTrack Client" -Action Status`.
3. On the device, confirm the app is gone (Start menu, `Program Files`, `appwiz.cpl`).
4. **PASS:** the device reports **Uninstalled / Not installed**, detection reports the app **absent**,
   AND the exported/checkpoint data (Gate 0) is still intact where you stored it.
5. **FAIL:** still installed → Gate 1 issue or a per-device installer failure (Troubleshooting).

## Gate 3 — No collateral breakage
**Purpose:** prove nothing that depended on the app broke.
1. Review the `APPRET-ImpactAnalyzer.ps1` dependency findings against the pilot devices.
2. On a pilot device, exercise any app or workflow that the ImpactAnalyzer flagged as dependent.
3. **PASS:** no dependent app tried to reinstall `LegacyTrack Client`; no user-facing workflow broke;
   the replacement app (if this is a migration) works.
4. **FAIL:** a dependent app is fighting the uninstall (it re-installs the app) → resolve the
   dependency (re-point or retire the dependent app) before expanding.

## Gate 4 — Wave completion threshold
**Purpose:** prove a wave is "done enough" to open the next.
1. After each wave's check-in cycle, run `APPRET-WaveReporter.ps1 -Action Status`.
2. **PASS:** the wave meets the completion threshold set in the decision record (e.g. ≥98% of
   *reachable* devices uninstalled) and every non-removed device is accounted for by
   `APPRET-WaveReporter.ps1 -Action Stragglers` (offline / decommissioned / escalated / exempt).
3. **FAIL:** unclassified installed devices remain → run Stragglers and disposition each before
   opening the next wave.

## Gate 5 — Artefacts removed
**Purpose:** prove decommission, not just uninstall.
1. Run `APPRET-ArtifactFinder.ps1 -AppName "LegacyTrack Client" -AppCode "APPRET-LGT"`.
2. **PASS:** the app object is deleted, the `APPRET-LGT` wave/exempt groups are deleted (or flagged
   SAFE and then deleted), no Conditional Access policy references the app's enterprise application,
   no enterprise application / app registration remains, and app-specific scripts are removed. WDAC /
   App Control and SCCM remnants confirmed removed manually.
3. **FAIL:** any artefact still references the app → clean it (Implementation Step 13) and re-run.

## Gate 6 — Evidence pack is complete and closure holds
**Purpose:** prove it, and prove it stays gone.
1. Run `APPRET-EvidenceExport.ps1 -AppName "LegacyTrack Client" -OutFolder .\APPRET-LGT-Evidence`.
2. **PASS:** `summary.txt` shows the app object NOT FOUND, residual installed accounted for, and
   remaining artefacts = 0; the data-export record and licence-reclamation numbers are attached; and
   two consecutive weekly post-retirement checks (Implementation Step 15) show zero installed and
   zero artefacts.
3. **FAIL:** the app reappears on a device, or an artefact returns → find the source (old image,
   lingering SCCM deployment, a missed Required assignment) and remediate before closing.

## Full-campaign regression check
Before declaring the campaign closed, walk Gates 0→6 once end to end for the whole install base — not
just the last wave. A retirement is complete only when the app is uninstalled fleet-wide, every
straggler is dispositioned, every artefact is gone, the evidence pack is compiled, and monitoring is
clean for the defined window.
