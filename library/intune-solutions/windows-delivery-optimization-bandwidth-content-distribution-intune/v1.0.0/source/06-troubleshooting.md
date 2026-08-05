# 6. Troubleshooting — Delivery Optimization

Symptom → likely cause → fix. Run **`DELOPT-Preflight.ps1`** and **`DELOPT-Get-Status.ps1`** first to
gather the on-device facts.

## No peering — every device downloads over HTTP (BytesFromPeers = 0)
**Likely causes & fixes:**
- **Port 7680 blocked.** Host or network firewall blocks the peer listening port. Test
  `Test-NetConnection <peer> -Port 7680`; allow **inbound TCP 7680** on the Domain/Private profile and
  on intra-site network firewalls.
- **Wrong Download Mode.** Devices are on **HTTP Only (0)** or **Simple (99)**, or on **LAN (1)** across
  different subnets. Set **Group (2)** (with a group source) to peer across subnets; confirm with
  `DELOPT-Preflight.ps1`.
- **`DoSvc` not running.** The Delivery Optimization service is stopped/disabled (often by a "debloat"
  script). Set it to **Automatic (Delayed Start)** and start it.
- **No shared content yet.** Peers can only share content they already have. Ensure device A fully
  downloaded the item before device B requests the **same** item; retry Test 4.
- **DO cloud service unreachable.** Peer discovery needs the DO cloud endpoints on 80/443. Verify the
  endpoint list (it changes) and that the proxy isn't stripping them.

## Devices peer with the wrong set (group scoped incorrectly)
- **Over-broad (whole tenant peering):** `DOGroupIDSource` = **Entra tenant ID (5)** makes every device
  one group. Switch to **DHCP Option 234 (3)** or **AD Site (1)** for per-site peering.
- **Over-narrow (same-site devices don't peer):** `DORestrictPeerSelectionBy` = **Subnet (1)** on a site
  with several subnets, or a mismatched custom `DOGroupID`. Loosen to the site level or fix the GroupID
  so it is identical on all intended peers.
- **DHCP Option 234 not set / wrong:** Group source is DHCP but the scope has no (or a malformed) Option
  234 GUID → DO falls back to default grouping. Have the network team set Option 234 correctly per scope.

## Savings don't appear in reports
- **Baseline missing or too early.** Compare against the Step-1 baseline; savings only show once devices
  share content. Re-run `DELOPT-Report-Savings.ps1` after more devices have common items.
- **Intune Delivery Optimization report lag/data.** The report needs devices reporting in; allow time
  and confirm devices are checking in. Cross-check with on-device `Get-DeliveryOptimizationStatus`.
- **Peering actually failing.** If on-device BytesFromPeers is 0, the "no peering" section above is the
  real problem — reports can't show a saving that isn't happening.

## Conflicting configuration / policy not applying
- **Two authorities.** A leftover **GPO** or **ConfigMgr** client setting is fighting the Intune policy.
  Run `DELOPT-Get-Policy.ps1` (Intune side) and compare to on-device config; remove conflicting GPO DO
  settings or align co-management.
- **Assignment/sync.** Policy exists but the device shows defaults → confirm the device is in
  `DELOPT - Devices - Pilot`, force a sync, and re-check. Settings Catalog conflicts (same setting set by
  two profiles) show as an error in the device's policy status — resolve the duplicate.

## Bandwidth caps not respected / foreground starved
- **Both absolute and percentage set** for the same direction, or **business-hours** settings overriding
  as designed. Set only one of absolute/percentage per direction; remember business-hours settings take
  precedence over the percentage values.
- **Foreground throttled too hard.** Raise `DOMaxForegroundDownloadBandwidth` (or leave `0` = dynamic) so
  interactive content stays responsive; keep the hard cap on **background** only.

## Bypass (100) side-effects on Windows 11
- **Content fails to download / DO bypassed.** `DODownloadMode` = **100 (Bypass)** is **deprecated on
  Windows 11** and routes around DO via BITS. Change to **0** (disable peering) or **99** (offline); do
  not use 100 on Win11.

## US Government specifics
- **Endpoints unreachable in GCC High / DoD.** Sovereign clouds use US-government DO/content endpoints.
  Verify the current endpoint list and allow the correct US-gov ranges; configure policy from
  `https://intune.microsoft.us` and Graph via `Connect-MgGraph -Environment USGov` (or `USGovDoD`).
  **Verify for GCC High** where a specific endpoint's parity is uncertain.
