# 1. Solution Overview — Windows Updates for Business

## What Windows Update for Business is
Windows Update for Business (WUfB) is Microsoft's cloud service for controlling how and when
Windows devices receive **quality updates** (monthly security/reliability patches) and **feature
updates** (annual OS versions). Managed through Microsoft Intune, it replaces WSUS for
cloud-managed devices: you define **update rings** that defer, schedule, and deadline updates, and
the devices pull updates directly from Microsoft with **Delivery Optimization** peer caching.

## How it works
1. An Intune **Update ring** sets quality- and feature-update **deferral** periods, **deadlines**,
   **active hours**, restart behavior, and the user experience.
2. Rings are assigned to groups in a **ring strategy** — a small **Pilot** ring updates first
   (short deferral), a **Broad** ring follows (longer deferral) once the pilot is healthy.
3. A **Feature update profile** pins the target OS version (e.g. Windows 11 23H2) so devices don't
   drift ahead or fall behind; you control the move to the next version.
4. **Expedited updates** push a specific critical/zero-day patch immediately, bypassing deferrals.
5. **Delivery Optimization** lets devices share update content on the LAN to save WAN bandwidth.
6. Update status is reported in Intune (and, optionally, Windows Update for Business reports).

## What you can control
- **Quality update deferral** (0–30 days) and **deadline** with grace period.
- **Feature update deferral** / **target version** (pin the OS build).
- **Active hours** and **auto-restart** behavior; user notifications and the option to pause.
- **Expedite** a named quality update for emergencies.
- **Driver updates** (approve/defer) and **Delivery Optimization** download mode/bandwidth.

## Benefits
- **Security** — devices stay patched on a predictable cadence; zero-days can be expedited.
- **Stability** — ring-based rollout catches a bad update on the pilot before it hits the fleet.
- **No version drift** — feature update profiles keep the fleet on a known, supported build.
- **Bandwidth-friendly** — Delivery Optimization reduces WAN load.
- **Visibility** — per-device and fleet-wide update status and feature-version inventory.

## Limitations (be honest with buyers)
- WUfB manages **Microsoft** updates (Windows + drivers + Microsoft Store); third-party app patching is separate.
- Rich Windows Update for Business **reports** need diagnostic data enabled and a Log Analytics workspace (optional add-on, noted in requirements).
- Feature updates are large; first rollout timing should account for bandwidth.
- Co-management with ConfigMgr/WSUS requires deciding which authority owns updates (avoid conflicts).

## The standard Phoenixtekk deployment model
> **Create Pilot + Broad update rings → add a feature update profile → assign by ring → validate on
> the pilot → expand to broad.** Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
