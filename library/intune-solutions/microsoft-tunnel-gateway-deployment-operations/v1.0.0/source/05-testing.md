# 5. Testing Guide — Microsoft Tunnel Gateway: Deployment, VPN Configuration & Ongoing Operations

Run after the pilot profiles apply (Implementation Step 8) and again before expanding. Use
`TUNGW-Discovery.ps1` (config inventory), `TUNGW-Validate.ps1` (per-device profile/config),
`TUNGW-Report.ps1` (fleet + server-health rollup), `TUNGW-HostPrereqCheck.sh` (host readiness), and
`TUNGW-HealthCheck.sh` (gateway health + logs).

## Test 1 — Gateway server is healthy in Intune
**Do:** Intune → **Tenant administration → Microsoft Tunnel Gateway → Health status / Servers**;
confirm the server(s) under `Tunnel Site – HQ – Prod`. Also run `TUNGW-HealthCheck.sh` on the host.
**Expected:** Server(s) report **healthy** with a recent check-in; the container/service is running;
CPU, memory, latency, and throughput are within normal range.

## Test 2 — TLS certificate valid and matches the FQDN
**Do:** `TUNGW-HostPrereqCheck.sh` reports the certificate not-after date; from a client network,
confirm the TLS certificate presented for `tunnel.contoso.com` is trusted and covers the FQDN.
**Expected:** Certificate is trusted, the FQDN is in the SAN, and expiry is comfortably in the future.

## Test 3 — VPN connection profile deployed
**Do:** Intune → **Devices → Configuration →** open `Tunnel VPN – iOS – Pilot` /
`Tunnel VPN – Android – Pilot` **→ Device status**; or run `TUNGW-Validate.ps1` for a pilot device.
**Expected:** Pilot devices show **Succeeded** (not Error/Pending); the profile targets
`Tunnel Devices – Pilot`.

## Test 4 — Client connects to the Tunnel
**Do:** On a pilot device with the Defender client installed, initiate the Tunnel VPN connection.
**Expected:** The VPN establishes and shows connected; no authentication or certificate errors.

## Test 5 — Internal resource reachable through an include route
**Do:** With the Tunnel connected, browse/ping an internal resource inside a configured **include
route** (e.g. an internal web app on `10.x.x.x`), and confirm internal DNS resolves its name.
**Expected:** The internal resource is reachable and its name resolves via the configured DNS servers.

## Test 6 — Split-tunnel routing behaves as configured
**Do:** With the Tunnel connected, check that traffic to a **non-included** destination (e.g. a public
site) egresses **directly**, not through the Tunnel (compare public IP with/without the Tunnel, or
trace the route).
**Expected:** Only include-route traffic goes through the gateway; everything else goes direct
(split tunnel). For a full-tunnel config, all traffic egresses via the corporate network instead.

## Test 7 — Conditional Access (report-only) evaluates as intended
**Do:** Entra → **Monitoring → Sign-in logs → Report-only** tab; find the pilot user's Tunnel-related
sign-in and inspect the `Tunnel Access – Compliant Devices – Report-Only` result.
**Expected:** The policy would **grant** for a compliant device and **block** a non-compliant one — no
unexpected blocks before you switch it to On.

## Test 8 — High availability failover (if HA deployed)
**Do:** With two+ servers behind the L4 load balancer, take one server out of rotation (or stop its
service) and reconnect a client; run `TUNGW-HealthCheck.sh` on the remaining server.
**Expected:** Clients still connect via the surviving server through the VIP; the healthy server
reports up; no client-visible outage beyond a reconnect.

## Test 9 — Fleet + health report
**Do:** Run `TUNGW-Report.ps1`.
**Expected:** A clear per-device VPN-profile deployment status across `Tunnel Devices – Pilot` /
`– Broad`, plus a server-health rollup for the Site.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–7 pass on `Tunnel Devices – Pilot` (Test 8 if HA is in the pilot) |
| **Broad pass** | Tests 1–9 pass after assigning `Tunnel Devices – Broad`, adding HA servers, and enforcing Conditional Access |
