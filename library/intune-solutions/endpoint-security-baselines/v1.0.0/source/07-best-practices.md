# 7. Best Practices — Endpoint Security Baselines

- **Always pilot.** Baselines change many settings at once; pilot to catch app/usability impact before fleet rollout.
- **Start from the latest version.** Create profiles from the newest baseline so you begin at current recommendations.
- **One owner per setting.** Decide whether the baseline or a dedicated solution (BitLocker, Firewall, ASR) owns a given control — never both — to avoid conflicts.
- **Resolve conflicts immediately.** A setting in Conflict is effectively unmanaged; use `ESB-ConflictCheck.ps1` and consolidate.
- **Change settings surgically.** When a baseline setting breaks an app, adjust that one setting — don't discard the whole baseline.
- **Retire overlapping GPOs.** Don't run a legacy GPO and an Intune baseline against the same control.
- **Track versions.** When Microsoft ships a new baseline version, review the change summary, pilot it, then update.
- **Layer, don't duplicate.** Use the baseline for broad hardening and the dedicated solutions for areas you want explicit, reportable control over.
- **Document deviations.** Record every setting you changed from Microsoft's recommendation and why — for audits and future updates.
- **Monitor continuously.** Use `ESB-TenantReport.ps1` to keep per-setting success high across the fleet.
