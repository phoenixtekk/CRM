# 2. Requirements Guide — Windows Delivery Optimization

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing (Intune)
**Description:** An Intune-bearing license (Intune Plan 1, in M365 E3/E5 or Business Premium).
Delivery Optimization itself is a **free, built-in Windows feature** — no separate DO license.
**Why:** Intune delivers the DO Settings Catalog policy and the Delivery Optimization report.
**Verify:** M365 admin center → **Billing → Licenses**; Intune portal loads.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Supported Windows edition and version
**Description:** Windows 10 (1809+) or Windows 11 — **Pro, Enterprise, or Education**.
**Why:** DO peer caching and the newer settings (GroupIDSource, absolute bandwidth, business-hours)
require a supported build; **Bypass mode is deprecated on Windows 11**. Home edition supports only
consumer peering, not enterprise DO policy.
**Verify:** `winver`; run **`DELOPT-Preflight.ps1`** (reports edition + build + the DO service state).
**Implement:** Upgrade to a supported build/edition; enroll the device in Intune.

## 2.3 Delivery Optimization service running (DoSvc)
**Description:** The **Delivery Optimization** service (`DoSvc`) must be running on each device.
**Why:** `DoSvc` is the client that performs peering, caching, and reporting; if it is disabled, DO
falls back to plain HTTP with no savings.
**Verify:** `Get-Service DoSvc`; run **`DELOPT-Preflight.ps1`**.
**Implement:** Set `DoSvc` startup to **Automatic (Delayed Start)** and start it; do not disable it via
a "debloat" script or third-party optimizer.

## 2.4 Peer connectivity — firewall / port 7680
**Description:** DO peers listen on **TCP 7680** for inbound peer connections on the local network.
**Why:** If host or network firewalls block **TCP 7680**, peers can't reach each other and every
device silently falls back to HTTP — no peering, no saving. (Group/LAN peering uses **7680**; the
legacy Internet download mode additionally uses **UDP 3544 / Teredo** — verify against current
Microsoft documentation for your scenario.)
**Verify:** From two devices on the same subnet, confirm **TCP 7680** is reachable between them; run
**`DELOPT-Get-Status.ps1`** after a download and check for non-zero **BytesFromPeers**.
**Implement:** Allow inbound **TCP 7680** on the Windows Firewall Domain/Private profiles and on any
network firewall between peering devices; do not block it on intra-site links.

## 2.5 Network access to Delivery Optimization cloud + content endpoints
**Description:** Outbound HTTPS to the DO cloud service and Microsoft content endpoints.
**Why:** DO uses the cloud service to discover peers and cache hosts, and pulls HTTP content/fallback
from Microsoft CDNs. Blocking these breaks peer discovery and downloads.
**Verify:** From a device, the DO endpoints resolve and are reachable on 80/443. Representative hosts
include `*.do.dsp.mp.microsoft.com`, `*.dl.delivery.mp.microsoft.com`, `*.emdl.ws.microsoft.com`,
`*.prod.do.dsp.mp.microsoft.com` — **verify the current endpoint list against Microsoft documentation**,
as it changes.
**Implement:** Allow the Delivery Optimization and Windows Update URL/IP ranges through the
proxy/firewall; where a proxy is present, ensure it does not strip the DO range/HTTP headers.

## 2.6 A single, non-conflicting delivery configuration
**Description:** DO policy is set from **one** authority — this Intune Settings Catalog policy — not a
leftover GPO, a ConfigMgr client setting, or a manual registry hack.
**Why:** Conflicting DO settings from multiple sources produce unpredictable download modes and
undo the group scoping.
**Verify:** Run **`DELOPT-Get-Policy.ps1`** (exports the effective Intune DO policy + assignments) and
**`DELOPT-Preflight.ps1`** (reads the applied on-device config); reconcile against any GPO.
**Implement:** Remove/disable conflicting GPO DO settings; if co-managed with ConfigMgr, decide which
authority owns client settings and align them.

## 2.7 Pilot and Production device groups
**Description:** Two Microsoft Entra security groups: **`DELOPT - Devices - Pilot`** and
**`DELOPT - Devices - Production`**.
**Why:** DO is rolled out pilot-first so peering and savings are validated on a small, same-network
set before the fleet.
**Verify:** Entra → **Groups**; both groups exist with the right members.
**Implement:** Entra → **Groups → New group → Security**; add a handful of same-site devices to Pilot.

## 2.8 (Recommended) A Delivery Optimization measurement baseline
**Description:** A "before" reading of peer/HTTP/cache bytes on the pilot devices.
**Why:** You can only prove savings against a baseline.
**Verify:** Run **`DELOPT-Get-Status.ps1`** / **`DELOPT-Report-Savings.ps1`** before enabling Group mode.
**Implement:** Capture the baseline during the Assess phase and keep it for the after-comparison.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Windows 10 1809+/11 Pro/Ent/Edu — `DELOPT-Preflight.ps1`
- [ ] Delivery Optimization service (`DoSvc`) running
- [ ] Peer port **TCP 7680** allowed between same-network devices
- [ ] DO cloud + content endpoints reachable (verify current list)
- [ ] No conflicting GPO/ConfigMgr DO settings — `DELOPT-Get-Policy.ps1`
- [ ] `DELOPT - Devices - Pilot` and `DELOPT - Devices - Production` groups created
- [ ] Baseline peer/HTTP/cache reading captured
