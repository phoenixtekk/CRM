# 1. Solution Overview — Windows Delivery Optimization (Bandwidth Savings & Peer Content Distribution)

## What Delivery Optimization is
Delivery Optimization (DO) is the **content-delivery engine built into Windows**. When a device needs
content from Microsoft, DO can source those bytes from **three** places in parallel — the Microsoft
CDN / original HTTP source, an **on-network cache** (Microsoft Connected Cache), and **peer devices**
that already have the content — then assembles the file from whichever sources respond fastest. The
result is that a given update or app crosses the internet **once per network** rather than once per
device, cutting WAN and internet bandwidth while keeping downloads fast and reliable.

This solution is the **delivery / bandwidth layer**. It does not change *what* content deploys or
*when* — it makes whatever your other solutions deploy arrive **efficiently**.

## Which content types Delivery Optimization can optimize
DO peer-caching and HTTP-caching apply to Microsoft-origin content, including:
- **Windows Update** — quality (monthly) updates, feature (annual) updates, and driver updates.
- **Microsoft Store** apps and app updates.
- **Microsoft 365 Apps** (Office) client updates.
- **Intune Win32 apps** (`.intunewin`) delivered by the Intune Management Extension.
- **Windows Autopilot / Enrollment Status Page (ESP)** content during provisioning.
- **Microsoft Defender** security-intelligence (definition) updates.

> Content that is not Microsoft-origin (e.g. a third-party vendor's own download server) is not peer-cached
> by DO. Verify the current supported-content list against Microsoft documentation as it evolves.

## How it works — the peer-to-peer + cloud/HTTP model
1. A download begins (an update, a Store or Win32 app, an M365 Apps update, or ESP content).
2. The DO client contacts the **DO cloud service** to discover eligible **peers** (other devices with
   the same content on the same network / group) and any configured **cache server**.
3. DO downloads **parts** of the file **in parallel** from peers, the cache server, and the HTTP
   source, honoring your **bandwidth** and **cache** policy, and reassembles the complete file.
4. If peers and cache cannot supply the content, DO **falls back to the HTTP source** automatically —
   a download never fails just because peering is unavailable.
5. Bytes served from peers or an on-network cache **do not cross the internet**, which is the saving.

## Download Mode — the primary decision (values verified against Microsoft Learn)
`DODownloadMode` dictates which sources a client may use:

| Mode | Value | What it does | Typical use |
|---|---|---|---|
| **HTTP Only** | `0` | No peering. HTTP from the CDN/original source or a Connected Cache. | Peering not wanted; still allows cache. |
| **LAN** | `1` *(default)* | Peers on the **same local network** (same public IP; same subnet by default on Win11). | Single-site / flat LANs. |
| **Group** | `2` | Peers across **internal subnets** within the same **group** (AD site, domain, or custom GroupID). **Recommended** for most orgs with multiple subnets/VLANs. | Multi-subnet offices, VLANs. |
| **Internet** | `3` | Adds **internet** peer sources. | Roaming / distributed fleets (with caution). |
| **Simple** | `99` | Disables DO cloud services entirely (offline); HTTP only, no peering. | Isolated / offline networks. |
| **Bypass** | `100` | **Deprecated in Windows 11** — bypasses DO and uses BITS. Do **not** configure on Win11; use `0` to disable peering or `99` for offline. | Legacy only. |

**Group mode (2)** is the recommended option for most multi-subnet organizations because it lets
devices in different VLANs or remote offices peer with one another — provided the **group is scoped
correctly** (below).

## Scoping peer groups correctly — GroupID / GroupIDSource
In **Group** mode, which devices are allowed to peer together is set by `DOGroupIDSource` (verified values):
- `1` = **AD Site**  ·  `2` = **Authenticated domain SID**  ·  `3` = **DHCP Option 234**  ·
  `4` = **DNS Suffix**  ·  `5` = **Microsoft Entra tenant ID**.
- Or set a specific custom group with `DOGroupID` (a GUID identical on every device in the group).

Scoping matters: an Entra-tenant-ID group (`5`) makes *every* device in the tenant one giant peer
group — appropriate only if they share networks; **DHCP Option 234** (`3`) or **AD Site** (`1`) keeps
peering to devices that actually sit on the same physical network, which is usually what you want.
`DORestrictPeerSelectionBy` can further limit peers to the same **subnet** (`1`) or use **Local Peer
Discovery / DNS-SD** (`2`).

## Bandwidth controls (verified names)
- **Percentage throttling:** `DOPercentageMaxForegroundBandwidth` / `DOPercentageMaxBackgroundBandwidth`
  (default `0` = dynamic).
- **Absolute throttling (KB/s):** `DOMaxForegroundDownloadBandwidth` / `DOMaxBackgroundDownloadBandwidth`
  — Microsoft recommends the **absolute** options for low-bandwidth sites.
- **Business hours:** `DOSetHoursToLimitForegroundDownloadBandwidth` /
  `DOSetHoursToLimitBackgroundDownloadBandwidth` limit differently during vs. outside business hours
  (and take precedence over the percentage settings when both are set).
- **Upload cap to internet peers:** `DOMonthlyUploadDataCap` (default **20 GB**; `0` = unlimited).
- **Minimum background QoS:** `DOMinBackgroundQoS` (default **20 MB/s**) — the floor below which DO
  pulls from HTTP to keep the download moving.
- **Foreground** = interactive/blocking (a user waiting on a Store app); **background** = deferrable
  (a monthly update). Throttle background hard, foreground gently.

## Cache controls (verified names)
- `DOMaxCacheSize` — cache as a **percent** of disk (default **20%**); `DOAbsoluteMaxCacheSize` — a hard
  **GB** cap (overrides the percentage).
- `DOMaxCacheAge` — how long content is retained (default **259,200 s = 3 days**; `0` = unlimited).
- `DOMinFileSizeToCache` — minimum file size to peer-cache (default **50 MB**).
- `DOModifyCacheDrive` — relocate the cache (e.g. to a data drive) if the OS drive is tight.
- `DOMinRAMAllowedToPeer` (default **4 GB**) / `DOMinDiskSizeAllowedToPeer` (default **32 GB**) — hardware
  floors below which a device won't peer.

## Microsoft Connected Cache (MCC) — decision-level only
MCC is an **on-premises or cloud cache node** that DO peers to: it downloads Microsoft content once
and serves it to your devices over the LAN, so even the **first** device on a site pulls from the
cache rather than the internet. DO points at it with `DOCacheHost` (static FQDN/IP list) or
`DOCacheHostSource` (dynamic via **DHCP Option 235**). **When an org needs it:** large sites where the
number of *distinct* files (not just peer copies) makes even one internet copy costly, or sites where
peering alone leaves too much HTTP traffic. **This solution covers MCC at the decision/pointer level
only** — it names the settings and tells you when to consider it. **The full MCC-node deployment
(standing up and operating a cache server) is deferred to a separate future product** and is not
authored here.

## Monitoring & proving savings
- **On-device cmdlets:** `Get-DeliveryOptimizationStatus` (per-download source breakdown — peer vs.
  HTTP vs. cache bytes) and `Get-DeliveryOptimizationPerfSnap` (rolled-up performance/efficiency).
- **Intune report:** *Reports → Delivery Optimization* aggregates bandwidth-saving across the fleet.
- The saving is read as **BytesFromPeers + BytesFromCacheServer** relative to **BytesFromHttp**.

## Benefits
- **Bandwidth & cost** — the same update/app crosses the internet once per network, not once per device.
- **Faster provisioning** — Autopilot/ESP and app installs pull from peers/cache instead of a congested WAN.
- **No new infrastructure required** to start — peer caching is built into Windows; MCC is optional.
- **Measurable** — peer/cache/HTTP byte counts prove the saving to the business.
- **Safe** — automatic HTTP fallback means a download never fails when peers/cache are unavailable.

## Limitations (be honest with buyers)
- DO optimizes **delivery**, not **what/when**: it does not choose or schedule updates (that is WUfB),
  patch third-party apps, or package Win32 apps.
- Peering only helps where devices **share a network**; fully-remote single-user devices see little peer benefit.
- Peering across subnets requires **Group** mode with a correctly-scoped group; a wrong GroupIDSource
  either isolates devices or over-broadens the group.
- **Firewall/port** blocks (peer listening port **TCP 7680**) stop peering silently — devices fall back to HTTP.
- Full first-copy elimination on a site needs **MCC** (a separate engagement), not peering alone.
- **Bypass (100)** is deprecated on Windows 11 — don't use it.

## The standard deployment model
> **Assess the network and content sources → configure the DO Settings Catalog policy (download mode,
> group, bandwidth, cache) → assign to a Pilot → validate peering + savings with the cmdlets/report →
> expand to Production.** The repeatable way: **Assess → Configure → Pilot → Validate → Expand.**
