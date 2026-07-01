# 5. Testing Guide — Microsoft Tunnel for MAM

Run after the pilot configuration applies (Implementation Step 9) and after any change to the server
configuration, site, or Tunnel (MAM) configuration.

## Test 1 — Gateway server healthy
Do: Intune → Tenant administration → Microsoft Tunnel Gateway → Health status (and Servers under
`Tunnel Site – Intranet – Prod`); on the host run `mst-cli server show`.
Expected: The server shows Healthy in Intune and the container is running on the host.

## Test 2 — Connector connected
Do: Intune → Tenant administration → Microsoft Tunnel Gateway → Servers → open the server; on the
host run `mst-cli agent info`. Or run `TUNMAM-Validation.ps1`.
Expected: The connector reports connected/healthy to Intune.

## Test 3 — MAM configuration delivered to the app
Do: On a pilot device open the managed app (Microsoft Edge); run `TUNMAM-Discovery.ps1` to confirm
the Tunnel (MAM) app configuration and app protection policy target the pilot user.
Expected: The app is managed and shows the tunnel connection is available.

## Test 4 — Managed app reaches the internal resource
Do: In the managed app, browse to an internal-only FQDN within a split-tunnel Include route.
Expected: The internal resource loads inside the managed app.

## Test 5 — App scoping holds (only the app tunnels)
Do: On the same device, open the same internal FQDN in a non-managed browser or app.
Expected: The non-managed app cannot reach the internal resource — confirming the tunnel is
app-scoped, not device-wide.

## Test 6 — Split tunnel / DNS correct
Do: In the managed app, load an external (internet) site and an internal site; from the gateway host
resolve the internal FQDN.
Expected: Internet traffic goes direct (not through the tunnel), the internal name resolves, and the
internal resource is reachable only for the defined routes.

## Test 7 — Usage and health report
Do: Run `TUNMAM-Report.ps1`.
Expected: A clear report of Tunnel sites/servers, health, and MAM configuration coverage across the
targeted groups.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–5 pass on the pilot group — server Healthy, managed app reaches the internal resource, non-managed app does not |
| Broad pass | Tests 1–4, 7 pass for the broad group before full rollout |
