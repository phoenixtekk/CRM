# 3. Implementation Guide — Windows Delivery Optimization via the Intune Settings Catalog

Follow these steps **in order**. All Delivery Optimization settings live in the Intune **Settings
Catalog** under the category **Delivery Optimization**. You will build **one** policy, assign it to a
**Pilot** group, validate peering and savings, then expand to **Production**. Commercial portal is
`https://intune.microsoft.com`; US Government is `https://intune.microsoft.us` (see §3.9).

> **Naming convention used throughout (reuse these names verbatim):**
> Policy: **`DELOPT - Policy - Pilot`** → later cloned to **`DELOPT - Policy - Production`**.
> Groups: **`DELOPT - Devices - Pilot`**, **`DELOPT - Devices - Production`** (from §2.7).

---
## Step 1 — Assess: capture the baseline
1. On two or three pilot devices on the **same subnet**, run **`DELOPT-Preflight.ps1`** (confirms
   edition/build, `DoSvc` running, port 7680) and **`DELOPT-Get-Status.ps1`** (records current
   peer/HTTP/cache bytes). Keep these readings — they are your "before".
2. Note the **network topology**: how many sites/subnets, whether devices share a public IP, and
   whether an on-network cache (MCC) already exists. This drives the **Download Mode** and **group**
   choice in Step 3.

## Step 2 — Create the Delivery Optimization policy
1. In the Intune admin center, go to **Devices** → **Configuration** → **Create** → **New policy**.
2. **Platform:** **Windows 10 and later**. **Profile type:** **Settings catalog**. Click **Create**.
3. **Basics:** Name **`DELOPT - Policy - Pilot`**; Description *"Delivery Optimization — bandwidth
   savings & peer content distribution (pilot)."* Click **Next**.
4. On **Configuration settings**, click **+ Add settings**, and in the settings picker search
   **Delivery Optimization**. Select the **Delivery Optimization** category and add the settings in
   Steps 3–6 below.

## Step 3 — Set the Download Mode and scope the peer group
1. Add **Download Mode** (`DODownloadMode`). For a multi-subnet organization set it to **Group (2)** —
   the recommended mode; devices peer across VLANs/subnets within the same group. (For a single flat
   LAN, **LAN (1)** is sufficient; to disable peering but keep cache use, **HTTP Only (0)**.)
2. Add **Select the source of Group IDs** (`DOGroupIDSource`) and choose the source that matches how
   your networks are actually segmented:
   - **DHCP Option 234 (3)** — recommended when your DHCP scopes map to physical sites (each site's
     DHCP returns a distinct GUID → peer group = site). *Requires configuring DHCP Option 234 on each
     scope with a GUID — a network-team task; flag it if DHCP is not owned by you.*
   - **AD Site (1)** — for domain-joined/hybrid devices whose AD sites already model the physical topology.
   - **Microsoft Entra tenant ID (5)** — simplest, but makes the **entire tenant** one peer group; use
     only if that is genuinely what you want (small org, shared networks).
3. *(Optional, tighten peering)* Add **Select a method to restrict peer selection**
   (`DORestrictPeerSelectionBy`) = **Subnet (1)** to keep peers within a subnet, or **Local Peer
   Discovery / DNS-SD (2)** on Windows 11 for local-network discovery without the cloud service.
4. *(Optional, custom group)* Instead of a source, set a fixed **Group ID** (`DOGroupID`) to a GUID that
   is **identical on every device** meant to peer together (generate once with
   `[guid]::NewGuid()`). Do **not** set both a custom GroupID and rely on GroupIDSource for the same devices.

## Step 4 — Apply bandwidth controls
Choose **absolute** limits for low-bandwidth branch sites (Microsoft's recommendation), or
**percentage** for headroom-based control. Do not set both absolute and percentage for the same
direction.
1. Add **Maximum background download bandwidth (in KB/s)** (`DOMaxBackgroundDownloadBandwidth`) and set
   a value that protects the WAN for **background** (deferrable) content — e.g. a conservative cap on a
   small branch circuit. Background = monthly updates and similar.
2. Add **Maximum foreground download bandwidth (in KB/s)** (`DOMaxForegroundDownloadBandwidth`) and set
   a **higher/looser** value (or leave `0` = dynamic) so **foreground** (a user waiting on a Store or
   Win32 app) stays responsive.
3. *(Alternative to absolute)* **Maximum background download bandwidth (percentage)**
   (`DOPercentageMaxBackgroundBandwidth`) and **…foreground (percentage)**
   (`DOPercentageMaxForegroundBandwidth`), `0`–`100`.
4. *(Business-hours shaping)* Add **Set hours to limit background download bandwidth**
   (`DOSetHoursToLimitBackgroundDownloadBandwidth`) to throttle harder **during** business hours and
   relax **outside** them (foreground equivalent:
   `DOSetHoursToLimitForegroundDownloadBandwidth`). When set, these take precedence over the
   percentage values.
5. Add **Monthly upload data cap** (`DOMonthlyUploadDataCap`) — leave the **20 GB** default for most,
   or lower it where upload to internet peers must be constrained (`0` = unlimited). *(Uploads to
   internet peers only apply when Download Mode is **Internet (3)**.)*
6. *(Optional)* **Minimum background QoS** (`DOMinBackgroundQoS`, default **20 MB/s**) — the speed floor
   below which DO supplements peers with HTTP so a background download still completes promptly.

## Step 5 — Size the peer cache
1. Add **Max cache size** (`DOMaxCacheSize`) — percent of disk, default **20%** — or **Absolute max
   cache size (in GBs)** (`DOAbsoluteMaxCacheSize`) for a hard GB cap (the GB cap **overrides** the
   percentage). A larger cache means more content is available to peers.
2. Add **Max cache age** (`DOMaxCacheAge`) — seconds content is retained (default **259,200 = 3 days**;
   set higher, or `0` = unlimited, so peers don't re-download recurring content).
3. *(Optional)* **Minimum peer caching content file size** (`DOMinFileSizeToCache`, default **50 MB**) —
   lower it if you want smaller apps to peer-cache.
4. *(Optional)* **Modify cache drive** (`DOModifyCacheDrive`) — relocate the cache to a data drive (e.g.
   `D:`) if the OS drive is tight.
5. *(Optional, hardware floors)* **Minimum RAM allowed to peer** (`DOMinRAMAllowedToPeer`, default **4
   GB**) and **Minimum disk size allowed to peer** (`DOMinDiskSizeAllowedToPeer`, default **32 GB**).

## Step 6 — (Decision-level) point at Microsoft Connected Cache, if you have one
*Only if an MCC node already exists on your network* — standing up MCC is a separate future engagement,
not part of this deployment:
1. Add **Cache server hostname** (`DOCacheHost`) = the MCC node's FQDN/IP (comma-separate multiple), **or**
2. Add **Cache server hostname source** (`DOCacheHostSource`) = **DHCP Option 235 (1)**, or **Force (2)**
   to override a static `DOCacheHost`. *(Requires DHCP Option 235 configured with the cache host — a
   network-team task.)*
3. Leave both **unset** if you have no cache node; DO peering + HTTP still work fully without MCC.

## Step 7 — Finish and assign to Pilot
1. Click **Next** through **Scope tags** (add one if your org uses them).
2. On **Assignments**, under **Included groups** add **`DELOPT - Devices - Pilot`**. Click **Next**.
3. Review and click **Create**.
4. Trigger a sync (**Devices → Sync**, or on a device *Settings → Accounts → Access work or school →
   Info → Sync*) and allow policy to apply.

## Step 8 — Validate on the Pilot (gate before expanding)
1. Run **`DELOPT-Get-Policy.ps1`** to confirm the policy and its **Pilot** assignment exist in Intune.
2. On two pilot devices on the **same subnet**, run **`DELOPT-Preflight.ps1`** to confirm the applied
   Download Mode/Group.
3. Trigger real content on **device A** (e.g. a Store app update or a Win32 app install), let it
   complete, then start the **same** content on **device B**. Run **`DELOPT-Get-Status.ps1`** on device
   B — **BytesFromPeers** should be **non-zero** (B pulled from A).
4. Run **`DELOPT-Report-Savings.ps1`** across the pilot set and compare peer/cache vs. HTTP bytes to
   your Step 1 baseline. **Do not expand until peering is proven** (see the pass/fail gates in
   `05-testing.md`).

## Step 9 — Expand to Production
1. In Intune, open **`DELOPT - Policy - Pilot`**, use **Duplicate**, and name the copy
   **`DELOPT - Policy - Production`** (or simply add the Production group to the existing policy).
2. Reconcile any values you adjusted during the pilot (bandwidth caps, cache size, group source).
3. On **Assignments**, add **`DELOPT - Devices - Production`** (and, when confident, remove the Pilot
   from the pilot-only policy to avoid double assignment).
4. Roll out in waves; after each wave re-run **`DELOPT-Report-Savings.ps1`** to confirm savings scale.

---
## 3.9 US Government (GCC / GCC High / DoD) notes
- Use the **US Gov portals**: Intune `https://intune.microsoft.us`, Entra `https://portal.azure.us`,
  and Microsoft Graph `https://graph.microsoft.us` (scripts: `Connect-MgGraph -Environment USGov`, or
  `USGovDoD` for DoD).
- The **Settings Catalog Delivery Optimization settings are the same**; the setting names/values in
  Steps 3–6 are identical. The difference is the **admin endpoint** you configure them from.
- **DO/MCC cloud-endpoint reachability may differ** in sovereign clouds — the DO cloud service and
  content CDNs use US-government service endpoints; confirm the current endpoint list and that your
  proxy/firewall allows them. **Verify for GCC High** before assuming parity of any specific endpoint.
