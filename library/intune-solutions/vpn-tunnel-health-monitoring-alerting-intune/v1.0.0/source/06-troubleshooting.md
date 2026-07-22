# 6. Troubleshooting — VPN Tunnel Health Monitoring & Alerting in Microsoft Intune (Scheduled Connectivity Health Checks, Telemetry & Alerts)

Work top-down: confirm the check **runs at all** (agent + context), then that it reports the **right
verdict** (no false red/green), then that **telemetry** reaches Log Analytics, then that **alerts**
fire, and finally use the **Triage runbook** to route a genuine red signal to the layer — and the
product — that owns the fix. Remember: this is a **read-only monitor**; it never changes the tunnel, so
"fixing" always happens in another product.

> Portal paths, the Log Analytics data path, Azure Monitor alert wiring, and Microsoft Graph **beta**
> endpoints below change over time and by cloud — **verify against current Microsoft documentation** for
> your tenant. Per-vendor VPN client detection specifics must be verified against the **vendor's**
> documentation.

## The check reports a false RED (device is actually healthy)
- **Wrong VPN type or profile name.** If `$VpnType` or `$ExpectedProfileName` doesn't match the device's
  actual VPN, `ProfilePresent`/`TunnelConnected` read false on a healthy device. Set them to match the
  deployed VPN and re-run `VPNHEALTH-Detect-TunnelHealth.ps1` locally.
- **Probe target unreachable *by design*.** `$TestRouteTarget` or `$TestDnsName` points at something a
  healthy device genuinely can't reach (wrong host, not published through the tunnel, or a split-tunnel
  exclusion). Choose an internal target that a healthy tunnel *should* reach.
- **Run-context mismatch.** A **user**-tunnel or user-store certificate read from **system** context (or
  vice-versa) reads nothing and looks failed. Match the package's **Run this script using the logged-on
  credentials** to what the check touches (Requirements §R7).
- **Third-party adapter/service name wrong.** For `ThirdParty`, the `$ThirdPartyAdapter` must match the
  vendor's actual adapter/service name — **verify with the vendor's documentation**; a near-miss reads
  as "not present".
- **Cert match too narrow/broad.** If `$CertSubjectMatch`/`$CertIssuerMatch` doesn't select the real VPN
  auth certificate, `CertValid` fails on a healthy device. Confirm the cert's subject/issuer in the
  device store (Requirements §R11).

## The check reports a false GREEN (device is actually broken)
- **Probe target too lenient.** A `$TestRouteTarget` that is reachable *without* the tunnel (e.g. also
  routable on the local LAN) passes even when the tunnel is down. Pick a target only reachable **through**
  the tunnel so the route signal means what you think.
- **Cert window too short.** A certificate expiring in, say, 20 days still passes if `$CertWarningDays`
  is set below that. Set the warning window to at least your renewal lead time.
- **Checking the wrong connection.** On Always On, a **device** tunnel can be healthy while the **user**
  tunnel is down (or vice-versa). Monitor each as its own `$VpnType`/profile so neither masks the other.

## The script doesn't run at all (no status reported)
- **Intune Management Extension missing/unhealthy.** IME executes the check on-device; if it isn't
  installed or is broken, nothing runs and no status returns. Confirm the **Microsoft Intune Management
  Extension** service is present and running (Requirements §R6); assigning any Intune PowerShell
  script/Win32 app installs IME.
- **Not assigned / not yet scheduled.** Confirm `VPNHEALTH – Tunnel Health – Detect – Pilot` is assigned
  to `PILOT – VPN Health – Devices` with a schedule (Implementation §Step 5) and allow a cycle. Run
  `VPNHEALTH-Validate.ps1`.
- **Signing/execution policy blocked it.** If your org enforces script signing, an unsigned check fails
  to run. Sign the script or set the run/signing options Microsoft documents for your case — **verify
  current behavior**.
- **Wrong run context for the data it reads.** A check that reads user-context VPN state assigned as
  system may run but read nothing (looks like a failure). Set the context per Requirements §R7.

## Telemetry isn't arriving in Log Analytics
- **Data path not wired / wrong table.** Whether Proactive Remediations output is natively queryable in
  Log Analytics, and via which table/connector, is **verify-with-Microsoft**. Confirm the data path from
  Implementation §Step 7 is actually configured for your tenant/cloud, and that the KQL uses the **real**
  table name your data lands in (the shipped KQL uses a **placeholder** table name — replace it).
- **Reporting/ingestion delay mistaken for "no data".** Both Intune reporting and Log Analytics ingest on
  a delay; allow the interval before concluding nothing arrived. Cross-check with `VPNHEALTH-Report.ps1`
  (`-Source Graph`) or the on-device logs (`-Source Local`) which don't depend on the workspace.
- **Workspace scope/permissions.** Confirm `LA – Endpoint – VPNHealth` exists and the query is scoped to
  it, and that whatever identity/agent ships the data has permission to write to it.

## The alert doesn't fire
- **Query returns nothing for the seeded cohort.** Run the alert's KQL directly in `LA – Endpoint –
  VPNHealth`; if it returns no rows for the seeded failure, the alert can't fire. Fix the query/table
  name first (see telemetry above).
- **Threshold/grouping set for single devices, not cohorts.** If the rule requires a large cohort but you
  seeded one device, it won't trigger. For testing, lower the threshold; for production, set it so a real
  cohort (or a cert-expiry window) triggers without alerting on every transient.
- **Action group not attached / wrong target.** `ALERT – VPN Tunnel Health – Degraded` must have a valid
  action group (email/Teams/ITSM). Confirm it, and send a test notification.
- **Evaluation cadence.** Scheduled-query alerts evaluate on an interval; allow at least one evaluation
  window. Exact rule type, cadence, and options are **verify-with-Microsoft** for your cloud.

## Per-VPN-type detection nuance
- **Microsoft Tunnel** — client state is surfaced via the Microsoft Defender for Endpoint client on the
  supported platforms; if the profile/connection isn't enumerable the way the script expects, **verify
  the current client and its status surface against Microsoft's documentation**, and lean on the
  reachability/route/DNS/cert signals which are technology-agnostic.
- **Always On VPN (device vs user)** — enumerate device-tunnel and user-tunnel connections **separately**;
  a user tunnel only exists/reads when a user is signed in — an offline device legitimately shows the
  user tunnel absent. Interpret accordingly, don't alert on "no user tunnel while logged off".
- **Third-party (e.g. Cisco Secure Client)** — presence/state come from the vendor's adapter/service; the
  exact names and status API are **vendor-specific — verify against the vendor's documentation**. If the
  vendor exposes no scriptable status, rely on the reachability/route/DNS/cert signals as the health
  proxy.

## Triage runbook — from a red signal to the layer that owns the fix
This monitor **does not fix**; it tells you **where** to fix. Map the red signal to the responsible layer,
then use the product that owns that fix (referenced, not reproduced here):

| Red signal | Most likely layer | Where to fix (product to use) |
|---|---|---|
| `ProfilePresent=False` (adapter/profile missing) | **VPN profile / deployment** | The VPN's **deployment** product — **"Microsoft Tunnel Gateway — Deployment, VPN Configuration & Ongoing Operations"**, the **Windows Always On VPN** product(s), or **"Cisco Secure Client (AnyConnect) VPN Deployment via Microsoft Intune"** — re-push/repair the profile. |
| `TunnelConnected=False` (won't establish), single device | **Device / client** | Reactive break/fix on the device — **"Endpoint Network Connectivity Troubleshooting Toolkit (DNS, Proxy, VPN, IP/Port/URL Filtering)"**. |
| `TunnelConnected=False` across a **cohort** on one gateway | **Gateway / head-end (server side)** | Gateway-**server** health — **"Microsoft Tunnel Gateway — Deployment, VPN Configuration & Ongoing Operations"** (it OWNS server-side health; this monitor defers to it). For a third-party head-end, the vendor/appliance owner. |
| `GatewayReachable=False` | **Gateway / network path** | Gateway-server health (Tunnel Gateway product) or your **network/firewall** owner; confirm the head-end is up and the path/ports are open. |
| `RouteThroughTunnel=False` (tunnel up, internal target unreachable) | **Routing / split-tunnel config** | The VPN **deployment** product's routing/Server Configuration (e.g. include-routes on Microsoft Tunnel) — fix the routes. |
| `DnsThroughTunnel=False` | **DNS / VPN DNS config** | The VPN **deployment** product's DNS settings, then deep DNS diagnosis with the **Connectivity Troubleshooting Toolkit**. |
| `CertValid=False` — near expiry or expired | **Certificate / PKI (SCEP/PKCS)** | Renew/re-provision via the certificate pipeline the VPN uses (the **deployment** product's SCEP/PKCS configuration); this is the highest-value early warning — act inside the window. |

If you decide a detected condition warrants **automated** remediation, author it deliberately as its own
Proactive Remediation with the safety discipline of **"Proactive Remediations at Scale — Detection &
Remediation Script Packs for Microsoft Intune"** — never by adding a fix to this read-only monitor.

## Scripts section
- **Connect-MgGraph scopes.** `VPNHEALTH-Discovery.ps1`, `VPNHEALTH-Validate.ps1`, and
  `VPNHEALTH-Report.ps1` are **read-only** and request `DeviceManagementConfiguration.Read.All`;
  `VPNHEALTH-Deploy-HealthCheck.ps1` requests `…ReadWrite.All` + `Group.Read.All` **only** when run with
  `-Execute` (its default dry-run uses read scopes). If a call returns nothing, confirm consent to the
  scope and that the account has the Intune role (Global Requirements G3).
- **Exact-name matching.** The Graph scripts match objects by **exact display name** — reuse
  `VPNHEALTH – Tunnel Health – Detect – Pilot`, `PILOT – VPN Health – Devices`, and the other object
  names **verbatim**. A renamed object won't be found; pass `-PackageName`/`-PilotGroupId` to override.
- **Read-only nature.** The device check and all three Graph query scripts make **no** changes. The only
  state-changer, `VPNHEALTH-Deploy-HealthCheck.ps1`, changes **Intune objects only** (the monitoring
  package + assignment), **never a VPN**, and **defaults to `-WhatIf`** — it prints the plan and changes
  nothing until you re-run with `-Execute`. It always deploys the package **detection-only** (no
  remediation), preserving the read-only-monitoring guarantee.
- **Beta endpoints.** Proactive Remediations = `deviceManagement/deviceHealthScripts` on the Graph
  **beta** endpoint; run states / detection output property names can change — **verify against current
  Microsoft documentation** if a script returns nothing.
