# 1. Solution Overview — WSUS to Windows Update for Business Patch Modernization

## What this solution is
This is a **migration**: it retires **WSUS** (Windows Server Update Services) and moves Windows
patching to **Windows Update for Business** (WUfB), managed entirely from **Microsoft Intune**.
Instead of approving updates on an on-premises server that only reaches devices on the corporate
network, you define **update rings** in Intune that defer, schedule, and deadline updates; devices
then pull patches **directly from Microsoft** with **Delivery Optimization** peer caching —
wherever they are. The end state is a cloud-managed patch program and **decommissioned WSUS
servers**.

## Why move off WSUS (read this first)
WSUS is a maintenance tax with real failure modes, which is *why* this migration is worth doing:
- **A server to own.** WSUS itself must be patched, backed up, and monitored; its content store
  bloats and periodically needs cleanup, and the SUSDB/WID database can corrupt.
- **LAN-only reach.** Approvals only flow to devices that can reach the WSUS server. Remote and
  hybrid workers fall behind and quietly drift out of compliance.
- **Manual approvals.** Someone has to approve, decline, and supersede updates every cycle —
  human effort that scales badly and stalls when that person is out.
- **No single source of truth.** Patch status lives on the WSUS console, separate from Intune,
  so the fleet is hard to report on.
Windows Update for Business removes all of this: no server, no approvals, no LAN dependency, and a
single Intune-based report.

## How the target state works
1. An Intune **Update ring** sets quality- and feature-update **deferral** periods, **deadlines**,
   **active hours**, restart behavior, and the user experience.
2. Rings are assigned to groups in a **migration ring strategy** — a small **Pilot** ring cuts over
   first (short deferral), then a **Broad** ring follows once the pilot is healthy.
3. A **Feature update policy** pins the target OS version (e.g. Windows 11 23H2) so devices don't
   drift ahead or fall behind.
4. **Delivery Optimization** lets devices share update content on the LAN to save WAN bandwidth —
   replacing the role WSUS used to play as a local content cache.
5. Devices scan **Microsoft** (not the WSUS server); update status is reported in Intune.

## The coexistence-then-cutover plan
The migration runs in this order so devices are never left without a patch authority:
1. **Inventory** the current WSUS approvals, the WSUS server pointer, and the GPO/registry update
   policy on devices.
2. **Design** the migration rings and **create** the WUfB update ring policies in Intune.
3. **Pilot:** assign the rings to a small pilot group and **remove the conflicting WSUS/GPO update
   policy from those devices** so they scan Microsoft.
4. **Validate** that pilot devices scan Microsoft (not WSUS) and patch on schedule.
5. **Expand** to the broad ring, removing the WSUS/GPO policy fleet-wide.
6. **Decommission WSUS** only after the fleet is validated on WUfB.

## The conflicting settings being removed
Two update authorities fight and stall updates, so the WSUS-era policy must be removed before a
device will scan Microsoft. These are the specific GPO settings (and the registry values they write)
to remove:
- **Specify intranet Microsoft update service location** — writes `WUServer` and `WUStatusServer`
  under `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`, and `UseWUServer` under
  `...\WindowsUpdate\AU`. This is what points a device at WSUS.
- **Do not connect to any Windows Update Internet locations** — writes
  `DoNotConnectToWindowsUpdateInternetLocations`; it blocks the device from scanning Microsoft even
  after WSUS is gone.
Removing these (and any related GPO update policy) lets the device scan Microsoft and obey the
Intune update ring instead.

## What you can control after migration
- **Quality update deferral** (0–30 days) and **deadline** with grace period.
- **Feature update deferral** / **target version** (pin the OS build).
- **Active hours** and **auto-restart** behavior; user notifications and the option to pause.
- **Driver updates** (approve/defer) and **Delivery Optimization** download mode/bandwidth.

## Benefits
- **No server to maintain** — the WSUS host, content store, and SUSDB are retired.
- **Patch anywhere** — devices update from Microsoft on or off the corporate network.
- **Stability** — ring-based rollout catches a bad update on the pilot before it hits the fleet.
- **No version drift** — feature update policies keep the fleet on a known, supported build.
- **Bandwidth-friendly** — Delivery Optimization replaces the WSUS local cache.
- **Visibility** — per-device and fleet-wide update status from one Intune report.

## Limitations (be honest with buyers)
- WUfB manages **Microsoft** updates (Windows + drivers + Microsoft Store); third-party app patching
  is separate.
- Rich Windows Update for Business **reports** need diagnostic data enabled and a Log Analytics
  workspace (optional, noted in requirements).
- Feature updates are large; the first cloud rollout timing should account for bandwidth now that
  WSUS no longer caches content locally.
- During coexistence, a device with the old WSUS pointer still present will not scan Microsoft —
  removing that pointer is the gating step, not an afterthought.

## The deployment model
> **Inventory WSUS → design + create WUfB rings in Intune → remove conflicting WSUS/GPO policy on
> the pilot → validate devices scan Microsoft → expand → decommission WSUS.** Pattern:
> **Assess → Configure → Pilot → Validate → Expand**, with a **pilot gate before WSUS decommission**.
