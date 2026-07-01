# 7. Best Practices — WSUS to Windows Update for Business Migration

- **Inventory before you touch anything.** Capture the WSUS server pointer, the GPO update policy,
  and the existing approval groups with `WSUSM-Discovery.ps1` first — you can't safely remove an
  authority you haven't mapped.
- **Remove the WSUS pointer — it's the gate, not an afterthought.** A device that still has
  `WUServer`/`UseWUServer` set keeps scanning WSUS and ignores the Intune ring. The cutover isn't
  done until that pointer is gone and the device scans Microsoft.
- **Pilot the cutover before decommissioning WSUS.** Keep WSUS running during coexistence so nothing
  is left without an authority; only retire it after the fleet validates on WUfB.
- **Use rings, always.** A small fast `WUfB – Ring – Pilot` catches a bad update before it reaches
  the broad fleet — the single most important practice after the cutover.
- **Pin the feature version.** `WUfB – Feature Update – Target` prevents drift; move it forward only
  after the pilot validates the new version.
- **Set realistic deadlines + active hours.** Patches must install on a schedule, but respect working
  hours and give a grace period to avoid surprise reboots.
- **Tune Delivery Optimization to replace the WSUS cache.** Use LAN/peer caching and bandwidth caps
  so the first cloud feature-update day doesn't saturate the WAN now that WSUS no longer caches
  content.
- **Watch for `DoNotConnectToWindowsUpdateInternetLocations`.** This leftover GPO silently blocks the
  online scan even after WSUS is gone — confirm it is removed.
- **Communicate to users.** A short note about the new deadline and restart behavior dramatically
  reduces tickets during the cutover.
- **Watch the reports.** Track update status and OS-build inventory with `WSUSM-Report.ps1` and chase
  any device still reporting a WSUS source.
- **Name everything consistently.** Reuse the `<Purpose> – <Scope> – <Stage>` convention for every
  group and policy so the migration is auditable and repeatable.
