# 6. Troubleshooting Guide — Microsoft Tunnel for MAM

Use `TUNMAM-Discovery.ps1` / `TUNMAM-Validation.ps1` for the Intune-side state and
`TUNMAM-Report.ps1` for health and usage; `TUNMAM-Remediation.ps1` (default `-WhatIf`) for safe fixes.
On the Linux host use `mst-cli server show` and `mst-cli agent info`.

## A. Server or connector unhealthy
| Symptom | Cause | Remediation |
|---|---|---|
| Server shows Unhealthy in Intune | Container stopped, host reboot, or expired token | On the host confirm the gateway container is running (`docker ps` / `podman ps`); check `mst-cli server show`; restart the container/service; re-run setup if the connector token lapsed |
| Connector not connected | Host cannot reach Intune/Tunnel endpoints | Confirm outbound HTTPS from the host to Microsoft's Intune/Tunnel URLs; check proxy/firewall; `mst-cli agent info` |
| Certificate errors on connect | TLS cert FQDN mismatch, expired, or untrusted chain | Reissue/replace the cert so subject/SAN matches the gateway FQDN and chains to a device-trusted CA; re-stage and re-run setup |

## B. Managed app can't reach the internal resource
| Symptom | Cause | Remediation |
|---|---|---|
| App connects but page won't load | DNS can't resolve the internal name, or the route isn't included | Confirm the server configuration's DNS servers/suffixes resolve the name from the gateway; add the internal subnet to the split-tunnel Include routes |
| App never prompts to tunnel | Tunnel (MAM) config not delivered or app not managed | Run `TUNMAM-Discovery.ps1`; confirm the app protection policy and Tunnel (MAM) config target the user and include the app; re-sign-in to the managed app |
| Only some apps reach in | App not a supported Tunnel-for-MAM client / not SDK-enabled | Confirm the app is Microsoft Edge or an Intune App SDK / wrapped LOB app; add it to the app config and app protection policy |

## C. Non-managed apps unexpectedly reach internal resources
- This should not happen with Tunnel for MAM (it is app-scoped). If it does, confirm no standard
  device-level Microsoft Tunnel VPN profile is also assigned to the device, and that the device is not
  reaching the resource over another network path (Wi-Fi on the internal LAN).

## D. Split tunnel / routing issues
- Internet traffic slow or routed inward → tighten the split-tunnel Include routes to only internal
  subnets; verify internet loads direct in the managed app (Test 6).
- Internal resource reachable but on the wrong path → confirm the Include route and DNS suffix match
  the resource's subnet and name.

## E. iOS vs. Android differences
- A config that works on one platform can fail on the other — the platforms are configured
  separately. Confirm both `Tunnel MAM Config – iOS – Prod` and `Tunnel MAM Config – Android – Prod`
  exist, target the pilot group, and include the platform's app IDs (`com.microsoft.msedge` on iOS,
  `com.microsoft.emmx` on Android).

## F. Diagnostics quick reference (Linux host)
```bash
docker ps                 # confirm the gateway container is running (or: podman ps)
mst-cli server show       # gateway server status
mst-cli agent info        # connector/agent status
nslookup <internal-fqdn>  # confirm internal DNS resolution from the host
```
Intune-side: run `TUNMAM-Discovery.ps1` and `TUNMAM-Validation.ps1`.

## G. When to escalate
If the server is Healthy, the connector is connected, the cert is valid, DNS resolves from the host,
and a supported managed app still cannot reach an included internal resource, collect the gateway
logs (`mst-cli` diagnostics) and the Intune Tunnel health details and open a Microsoft support case.
