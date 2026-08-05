# 5. Testing & Validation — Delivery Optimization

Validate on the **Pilot** before expanding. Each test has an explicit **PASS/FAIL gate**. Do not
move to Production until every gate passes on same-network pilot devices.

## Test 1 — Policy applied
**Procedure:** Run **`DELOPT-Get-Policy.ps1`** (confirms the Intune policy + Pilot assignment) and, on
a pilot device, **`DELOPT-Preflight.ps1`** (reads the applied on-device DO config).
**PASS:** `DELOPT - Policy - Pilot` exists, is assigned to `DELOPT - Devices - Pilot`, and the device
reports the expected **Download Mode** (e.g. Group/2) and Group source.
**FAIL:** Policy missing/unassigned, or the device still shows the default LAN(1)/unconfigured mode →
re-check assignment and sync; see `06-troubleshooting.md`.

## Test 2 — Delivery Optimization service healthy
**Procedure:** On a pilot device, `Get-Service DoSvc`; run **`DELOPT-Preflight.ps1`**.
**PASS:** `DoSvc` is **Running** and startup is Automatic (Delayed Start).
**FAIL:** `DoSvc` stopped/disabled → DO can't peer; re-enable and start it.

## Test 3 — Peer connectivity (port 7680)
**Procedure:** From device B, test **TCP 7680** to device A on the same subnet
(`Test-NetConnection <A> -Port 7680`).
**PASS:** Port 7680 is open between the two devices.
**FAIL:** Port filtered/closed → peering will not occur; open **TCP 7680** on host/network firewalls.

## Test 4 — Peering actually happens (the core proof)
**Procedure:** Fully download a piece of Microsoft content on **device A** (a Store app update, a Win32
app, or a monthly update). Then initiate the **same** content on **device B** on the same subnet. Run
**`DELOPT-Get-Status.ps1`** on device B.
**PASS:** Device B shows **non-zero BytesFromPeers** (and/or BytesFromCacheServer if MCC is present) for
that download — content came from A, not the internet.
**FAIL:** BytesFromPeers = 0 and all bytes are BytesFromHttp → check Download Mode/group scoping, port
7680, and that both devices are in the same group; see `06-troubleshooting.md`.

## Test 5 — Group scoping is correct
**Procedure:** On device B, run **`DELOPT-Get-Status.ps1`**; confirm peers are only devices that
*should* be in the group (same site/subnet, per your GroupIDSource).
**PASS:** Peers are same-network devices only; devices in unrelated sites are **not** peering.
**FAIL:** Devices across the whole tenant are peering (over-broad, e.g. GroupIDSource=Entra tenant when
you wanted per-site), or same-site devices are **not** peering (over-narrow) → adjust `DOGroupIDSource`.

## Test 6 — Bandwidth caps respected
**Procedure:** During a large background download, observe the DO download rate (Task Manager / Resource
Monitor, or `Get-DeliveryOptimizationStatus` download rate) against your configured
`DOMaxBackgroundDownloadBandwidth`.
**PASS:** Background download rate stays at/under the configured cap; foreground content remains responsive.
**FAIL:** Rate exceeds the cap or foreground is starved → re-check that only one of absolute/percentage
is set per direction, and business-hours precedence.

## Test 7 — Savings measured vs. baseline
**Procedure:** Run **`DELOPT-Report-Savings.ps1`** across the pilot set and compare peer + cache bytes
vs. HTTP bytes against the Step-1 baseline.
**PASS:** A meaningful share of bytes now comes from **peers/cache** (a positive saving vs. baseline).
**FAIL:** No measurable shift from HTTP to peers/cache → peering isn't working (revisit Tests 3–5) or
there isn't enough shared content yet (repeat after more devices have common content).

## Test 8 — HTTP fallback safety
**Procedure:** On an **isolated** pilot device (no peers available), start a Microsoft download.
**PASS:** The download completes over HTTP — DO never blocks a download when peers/cache are unavailable.
**FAIL:** Download stalls → this is not expected for modes 0/1/2/3; check for Bypass(100) misconfig or a
broken proxy path.

---
## Exit criteria (all must be true before Production)
- [ ] Policy applied with the intended Download Mode + group (Test 1)
- [ ] `DoSvc` running (Test 2) and port 7680 open between peers (Test 3)
- [ ] **BytesFromPeers non-zero** on a second device for shared content (Test 4)
- [ ] Peer group scoped correctly — right devices only (Test 5)
- [ ] Bandwidth caps honored; foreground responsive (Test 6)
- [ ] Measured peer/cache saving vs. baseline (Test 7)
- [ ] HTTP fallback proven safe (Test 8)
