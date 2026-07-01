# 7. Best Practices — Windows Updates for Business

- **Use rings, always.** A small fast **Pilot** ring catches a bad update before it reaches the **Broad** fleet — the single most important practice.
- **Pin the feature version.** A Feature update profile prevents drift and keeps the fleet on a known, supported build; move it forward only after the pilot validates the new version.
- **Set realistic deadlines + active hours.** Patches must install on a schedule, but respect working hours and give a grace period to avoid surprise reboots.
- **One update authority.** Let Intune/WUfB own updates — remove leftover WSUS/GPO settings and, under co-management, set the update workload to Intune.
- **Keep an expedite path ready.** Pre-plan the expedite profile so a zero-day can ship in minutes, bypassing deferrals.
- **Tune Delivery Optimization.** Use LAN/peer caching and bandwidth caps so feature-update day doesn't saturate the WAN; stage large rollouts.
- **Communicate to users.** A short note about the deadline and restart behavior dramatically reduces tickets.
- **Watch the reports.** Track update status and OS-build inventory with `WUFB-ComplianceReport.ps1` (or Windows Update for Business reports) and chase laggards.
- **Don't over-defer.** Long deferrals leave devices exposed; keep quality-update deferrals short (0 pilot / ~7 broad).
- **Document the cadence.** Record ring deferrals, deadlines, and the target feature version for audits and repeatability.
