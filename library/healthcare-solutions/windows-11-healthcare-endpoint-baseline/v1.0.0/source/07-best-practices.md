# 7. Best Practices — Windows 11 Healthcare Endpoint Baseline

- Pilot before you scale, always. Assign the baseline to a small clinical pilot, validate, and only
  then expand — the single most important practice for devices used in patient care.
- One authoritative source per setting. Let the referenced security baseline own security settings
  and the settings catalog own the rest; do not set the same value in two places or they will
  conflict.
- Name everything to a convention. Use the `<Purpose> – <Scope> – <Stage>` naming from the
  Implementation Guide so any operator can read the fleet at a glance and reproduce it.
- Separate clinical from corporate. Shared clinical devices need always-awake power and a
  maintenance-window update ring; corporate laptops need battery saving and standard updates — keep
  them in distinct groups and profiles.
- Keep shared clinical devices awake. Set plugged-in sleep and display-off to Never so no PC sleeps
  mid-encounter; confirm this is acceptable for any battery-only clinical device.
- Align updates to maintenance windows. Set update-ring active hours and restart behavior to the
  approved clinical maintenance windows so patches never interrupt care.
- Review security baseline updates. Microsoft revises the baseline over time; review the diff before
  adopting a new version rather than auto-upgrading.
- Watch for drift. Run `W11HC-Report.ps1` on a cadence and chase any device that lags the baseline;
  remediate with `W11HC-Remediation.ps1`.
- Document the baseline. Record the object names, assignments, and key settings for audits and for
  the next operator — the baseline is only repeatable if it is written down.
- Keep a rollback ready. Note the prior validated assignments before each change so a failed baseline
  change can be reverted quickly.
