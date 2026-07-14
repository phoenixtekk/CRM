# 6. Troubleshooting Guide + Operations Runbook — Microsoft Tunnel Gateway

Use `TUNGW-Discovery.ps1` (config inventory), `TUNGW-Validate.ps1` (per-device profile/config),
`TUNGW-Report.ps1` (fleet + server-health rollup), `TUNGW-HostPrereqCheck.sh` (host readiness), and
`TUNGW-HealthCheck.sh` (gateway health + `--collect` log bundle). Portal labels, `mst-cli` subcommands,
ports, and endpoints change — treat **[verify current Microsoft guidance]** items as re-checkable.

## The core scenario — "the client won't connect to the Tunnel"
Work this tree top to bottom; the cause is almost always in the first four rungs.

1. **Is the gateway server healthy?**
   - Intune → **Microsoft Tunnel Gateway → Health status**; run `TUNGW-HealthCheck.sh` on the host. If
     the container/service is down or the server is unhealthy, no client connects. See section A.

2. **Is the TLS certificate valid, trusted, and matching the FQDN?**
   - An expired, untrusted, or wrong-FQDN certificate is the most common "it worked yesterday" cause.
     `TUNGW-HealthCheck.sh` prints days-remaining; confirm the client trusts the chain and the FQDN is
     in the SAN. See section B.

3. **Is the client app installed and is a Tunnel VPN profile assigned + applied?**
   - The mobile client is the **Microsoft Defender for Endpoint** app — confirm it is installed. Then
     confirm the VPN profile (`Tunnel VPN – iOS – Pilot` / `Tunnel VPN – Android – Pilot`) is assigned
     to the device's group and shows **Succeeded** (`TUNGW-Validate.ps1`). See section C.

4. **Can the client reach the FQDN + listener port, and can the gateway reach internal resources?**
   - DNS must resolve `tunnel.contoso.com` to the gateway/VIP; the inbound listener port (default 443)
     must be open end to end; the gateway host must route to the internal include ranges. See section D.

5. **Is authentication succeeding (Entra or certificate)?**
   - Check Entra sign-in logs for the user; for certificate auth confirm the client cert deployed and
     the trusted root is present. See section E.

6. **Is Conditional Access blocking?**
   - If a CA policy (`Tunnel Access – Compliant Devices – Report-Only`) moved to **On**, a
     non-compliant device is blocked by design. Check the Entra sign-in **Conditional Access** result.
     See section F.

## A. Gateway server unhealthy / container down
| Symptom | Cause | Fix |
|---|---|---|
| Server shows unhealthy in Intune | Container/service stopped, or lost outbound to Microsoft | `TUNGW-HealthCheck.sh`; confirm the `mstunnel` service and container are running and the host reaches `login.microsoftonline.com` / `graph.microsoft.com` / `manage.microsoft.com`. Restart the service only per your change process |
| Server never appears after install | Registration/enrolment didn't complete | Re-run the install/registration step signed in with the required Intune role; confirm the server joined `Tunnel Site – HQ – Prod` |
| Health degrades under load | Under-sized host / full tunnel saturating the gateway | Check CPU/memory/throughput in Intune health; add an HA server (Step 10) or switch to split tunnel; re-verify sizing **[verify current Microsoft guidance]** |

## B. TLS certificate problems
- **Expired:** `TUNGW-HealthCheck.sh` reports EXPIRED — rotate the certificate on the host (historically
  `mst-cli tls_cert` update — **[verify current subcommand]**) and confirm clients reconnect.
- **Untrusted chain:** clients fail TLS because they don't trust the issuer. For an internal CA, deploy
  the root via an Intune **Trusted certificate** profile to the device group. Public-CA certs are
  already trusted.
- **FQDN mismatch:** the SAN must contain the exact name clients use (`tunnel.contoso.com`). Reissue the
  certificate with the correct SAN if it does not.
- **Cert files in the wrong place/format:** the installer expects a specific file layout/format —
  **[verify current Microsoft guidance]** and re-place the full-chain + key.

## C. Client app missing or VPN profile not applied
- **Defender app not installed:** the VPN profile has nothing to drive. Confirm the **Microsoft
  Defender for Endpoint** app is assigned and installed on the device before troubleshooting the profile.
- **Profile Error/Pending:** confirm the device is enrolled and in `Tunnel Devices – Pilot`/`– Broad`,
  the profile platform matches the device, and force a sync. `TUNGW-Validate.ps1` shows the per-device
  apply state and the Site/routing it resolves to.
- **Windows/macOS profile "does nothing":** confirm native Microsoft Tunnel client support currently
  exists for that platform in your cloud — **[verify current Microsoft guidance]**. If it does not, the
  profile cannot connect; use the adjacent approach in Best Practices rather than forcing it.

## D. Networking — FQDN, port, or internal routing
| Symptom | Cause | Fix |
|---|---|---|
| Client can't reach the gateway at all | DNS or inbound port | `nslookup tunnel.contoso.com` resolves to the gateway/VIP; confirm the listener port (default 443) is open from client networks to the gateway/VIP end to end |
| Connects but no internal resource works | Include routes / gateway routing | Confirm the internal CIDRs are in the Server Configuration **include routes**, and the gateway host can actually route to them (`TUNGW-HostPrereqCheck.sh --internal <ip>`) |
| Internal names don't resolve | DNS servers not set | Set the internal **DNS servers** (and suffix) in the Server Configuration |
| Client-pool collision | Client address pool overlaps internal range | Change the client IP address range so it does not overlap any include route |
| HA: some connections fail | Load balancer terminating TLS or bad health probe | The LB must be **L4/TCP passthrough** (never terminate TLS); fix the health probe so only healthy servers receive traffic |

## E. Authentication failures
- **Entra auth:** check Entra → **Sign-in logs** for the user; resolve MFA/licensing/user-state issues
  there. Confirm the user has the Tunnel/Intune license.
- **Certificate auth:** confirm the client certificate (`Tunnel Client Cert – SCEP – Pilot`) deployed
  and the **trusted root** (`Trusted Root – Org CA – Mobile`) is present on the device; a missing chain
  or an un-issued client cert fails auth silently. Validate via the SCEP/PKCS solution's checks.

## F. Conditional Access blocking
- If `Tunnel Access – Compliant Devices – Report-Only` was switched to **On**, a **non-compliant**
  device is blocked by design. Confirm in the Entra sign-in **Conditional Access** result.
- Before enforcing, always review the **report-only** results (Test 7) so you don't lock out working
  devices. Roll back to report-only if enforcement caused unexpected blocks, remediate compliance, then
  re-enforce.

## G. Diagnostics quick reference
```powershell
# Tenant-side inventory (Sites, Server Configs, servers/health, Tunnel VPN profiles) — read-only
.\TUNGW-Discovery.ps1
# Per-device VPN profile state + resolved Site/routing — read-only
.\TUNGW-Validate.ps1 -DeviceName 'iPad-Pilot-01'
# Fleet profile status + server-health rollup + KQL — read-only
.\TUNGW-Report.ps1
```
```bash
# Host readiness before install — read-only
./TUNGW-HostPrereqCheck.sh --cert /etc/mstunnel/private/site.pem --port 443 --internal 10.10.0.10 --fqdn tunnel.contoso.com
# Running-gateway health + optional log bundle — read-only
./TUNGW-HealthCheck.sh --collect
```
In Intune, check **Tenant administration → Microsoft Tunnel Gateway → Health status** (server health)
and **Devices → Configuration → (VPN profile) → Device status** (per-device result).

---

# Operations Runbook (ongoing support)

Run this cadence to keep a production Tunnel Gateway healthy. Everything here is read-only except the
explicitly gated maintenance actions, which follow your change process.

## Daily
- **Server health:** `TUNGW-Report.ps1` (server-health rollup) or Intune health status — every server
  in each Site should be **healthy** with a recent check-in.
- **Profile deployment:** scan `TUNGW-Report.ps1` for any spike in **Error** on the Tunnel VPN profiles.

## Weekly
- **Certificate expiry:** `TUNGW-HealthCheck.sh` on each server — act on any WARN (default: <30 days).
- **Capacity:** review CPU/memory/throughput/connection counts in Intune health; if trending high, plan
  an HA server or move from full to split tunnel.
- **Conditional Access:** confirm the enforced Tunnel CA policy result looks normal (no surprise blocks).

## Monthly / as needed
- **Certificate rotation:** rotate well before expiry (historically `mst-cli tls_cert` update —
  **[verify current subcommand]**); validate clients reconnect (Tests 2, 4, 5).
- **Server upgrades (rolling):** upgrade **one server at a time** so the Site stays up; after each,
  confirm it returns healthy (`TUNGW-HealthCheck.sh`). If automatic upgrades are enabled, verify the
  maintenance window and post-upgrade health.
- **Log collection for escalation:** `TUNGW-HealthCheck.sh --collect` produces a log tarball to attach
  to a Microsoft support case; review it before sharing (it may contain host/network detail).
- **Re-verify drift items:** re-check the **[verify current Microsoft guidance]** items (supported
  distro/version, runtime, ports, endpoint list, client-platform matrix) before each new rollout wave.

## When to escalate
If the server is healthy, the certificate is valid and trusted, DNS + listener port + internal routing
are confirmed, the client app is installed, the VPN profile shows **Succeeded**, and authentication +
Conditional Access are passing — but clients still cannot use internal resources — collect a log bundle
(`TUNGW-HealthCheck.sh --collect`) and the `TUNGW-Validate.ps1` output and engage **Microsoft support**
with the gateway/agent version and the exact symptom.
