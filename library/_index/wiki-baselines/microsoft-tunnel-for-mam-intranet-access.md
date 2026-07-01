# Microsoft Tunnel for MAM — Mobile Access to Intranet Resources

> **Version 1.0.0** · Category: Intune · Solution code: TUNMAM

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Tunnel for MAM (Microsoft Intune)

Some corporate resources only live inside the network — an on-prem app, an internal API, a private
intranet site — and mobile users on personal (BYOD) phones can't reach them without a VPN you would
rather not install on someone's personal device. Microsoft Tunnel for MAM solves this: an app-level
VPN that routes traffic from MAM-protected Microsoft 365 and line-of-business apps to internal
resources, scoped to the app rather than the whole device.

This is a complete, deploy-it-today package for implementing the Microsoft Tunnel Gateway and Tunnel
for MAM with Microsoft Intune, written for an administrator who has not deployed Microsoft Tunnel
before.

## What you get
- A plain-language Solution Overview of the Linux-hosted Tunnel Gateway, the connector, split vs.
  full tunneling and DNS, and how app-level VPN differs from a device VPN.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — host,
  certificate, network, DNS, apps, and app protection policies.
- An Implementation Guide of precise, ordered steps: stand up the gateway, configure the server, site,
  and connector, create the Tunnel (MAM) configuration, target the MAM apps, and validate access.
- Five PowerShell scripts for readiness discovery, tunnel/app validation, usage and health
  reporting, safe remediation, and scope-group targeting.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
An app-scoped path from managed mobile apps to your intranet: a Microsoft Tunnel Gateway on a
supported Linux host, a server configuration with split-tunnel routes and internal DNS, a site and
connector linked to Intune, and Tunnel (MAM) configurations for iOS and Android that route only the
managed apps' traffic inward.

## The deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Managed mobile apps able to reach internal intranet resources through an app-scoped Microsoft Tunnel
for MAM rather than a whole-device VPN — deployable by a single administrator and proven on a pilot
before you scale.


---


# 1. Solution Overview — Microsoft Tunnel for MAM

## What Microsoft Tunnel for MAM is
Microsoft Tunnel is a VPN gateway solution for Microsoft Intune. The gateway runs as a container on
a supported Linux host, pairs with the Intune Tunnel/Certificate connector, and routes client
traffic into your internal network. There are two flavors:

- Standard Microsoft Tunnel is a device-level VPN for enrolled iOS/Android devices — all device
  traffic (or a defined split) can route through the tunnel.
- Microsoft Tunnel for MAM is an app-level VPN. It routes traffic only from MAM-protected
  (app-protection-policy managed) apps — Microsoft 365 apps such as Microsoft Edge and Outlook, plus
  line-of-business apps — to internal/intranet resources. The tunnel is scoped to the app, not the
  whole device.

Tunnel for MAM is the answer to a specific problem: a personal (BYOD) phone needs to reach an
internal-only resource — an on-prem web app, an internal API, a private intranet site — but you do
not want a full-device VPN on someone's personal device, and the device is not enrolled. Tunnel for
MAM lets the managed app reach in, and leaves the rest of the phone alone.

## How it works
1. A Microsoft Tunnel Gateway runs as a container (Docker or Podman) on a supported Linux
   host/VM. It holds a TLS server certificate and listens for VPN connections.
2. The Intune Tunnel (Certificate) connector links the gateway to your Intune tenant and brokers
   configuration, authentication, and health reporting.
3. In Intune you define a Server configuration (IP ranges, DNS servers, split-tunnel routes, port)
   and a Site (a logical grouping of one or more Tunnel servers) — servers join a site and inherit
   its server configuration.
4. A Microsoft Tunnel (MAM) configuration and the app protection policy tell the MAM-protected
   apps on iOS/Android which connection type to use and how to authenticate into the tunnel.
5. When a user opens a managed app (for example Microsoft Edge) and browses to an internal resource,
   the app — and only that app — establishes the tunnel to the gateway, which forwards the traffic to
   the internal network.
6. Health and usage are reported back to Intune (Tenant administration → Microsoft Tunnel Gateway →
   Health status), and per-app connectivity is validated on the client.

## Split tunnel vs. full tunnel, and DNS
- Split tunnel (recommended for MAM) routes only defined internal subnets through the tunnel;
  everything else (internet, Microsoft 365) goes direct. This minimizes what the app sends inward
  and keeps performance high.
- Full tunnel routes all of the managed app's traffic through the gateway. Simpler routing, heavier
  gateway load, more egress to design.
- DNS matters: the server configuration's DNS servers (and optional DNS suffix search / proxy /
  Private DNS) must resolve the internal names the app will request, or the app reaches the tunnel
  but cannot find the resource.

## What you can control
- The Linux host and container runtime, the TLS server certificate, and the listening port.
- Server configuration: internal IP address ranges, DNS servers and suffixes, split vs. full tunnel
  routes, server port, and split DNS.
- Site membership — which Tunnel servers belong to which site.
- Which MAM apps (iOS/Android) are in scope, via app protection policy targeting and the Tunnel (MAM)
  configuration.
- Which users/groups get the configuration — a pilot group first, the broad population later.

## Benefits
- Reach internal resources from managed apps without putting a VPN on the whole (personal) device.
- App-scoped — only MAM-protected apps tunnel; the rest of the device is untouched, which suits BYOD.
- No device enrollment required — Tunnel for MAM works with app protection policies (MAM-WE).
- Split tunneling keeps performance high and exposure low.
- Central health and usage reporting in Intune.

## Limitations (be honest with buyers)
- Tunnel for MAM supports a defined set of client apps (notably Microsoft Edge on iOS/Android and
  apps built on the Intune App SDK / wrapped LOB apps); it is not every app on the phone.
- The gateway requires a supported Linux host, a container runtime, outbound/inbound network paths,
  and a TLS certificate — real infrastructure with real operational duties (patching, cert renewal).
- Tunnel for MAM has platform-specific prerequisites and app-config requirements on iOS and Android;
  the two platforms are configured separately.
- The tunnel only reaches resources the gateway host can reach and DNS can resolve — network and DNS
  design is part of the job, not an afterthought.

## The standard deployment model
> Stand up the Tunnel Gateway → configure the server, site, and connector → create the Tunnel (MAM)
> configuration and target the MAM apps → validate a managed app reaching an internal resource →
> pilot, then expand. This is the repeatable way: Assess → Configure → Pilot → Validate → Expand.


---


# 2. Requirements Guide — Microsoft Tunnel for MAM

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
Description: Microsoft Intune Plan 1 (included in Microsoft 365 E3/E5 and Business Premium), plus
Microsoft Entra ID for Conditional Access if used.
Why: Microsoft Tunnel and app protection policies are delivered by Intune; a licensed tenant is
required to configure the gateway, connector, and MAM policies.
Verify: Microsoft 365 admin center → Billing → Licenses; confirm Intune-bearing licenses on the
in-scope users.
Implement: Assign Microsoft 365 E3/E5 or Business Premium (Intune included) to the pilot users.

## 2.2 Supported Linux host for the Tunnel Gateway
Description: A physical or virtual Linux host running a Microsoft-supported distribution and a
container engine (Docker CE or Podman), with sufficient CPU/RAM/disk per Microsoft sizing guidance.
Why: The Tunnel Gateway runs only as a container on Linux; it is the VPN endpoint the managed apps
connect to.
Verify: On the host run `cat /etc/os-release`, `docker --version` (or `podman --version`), and
confirm the distro/version and container engine are on Microsoft's supported list; run
`TUNMAM-Discovery.ps1` to confirm the server later appears in Intune.
Implement: Provision a supported Linux VM, install Docker CE or Podman, and apply current OS
patches before installing the gateway.

## 2.3 TLS server certificate for the gateway
Description: A TLS certificate (with private key) whose subject/SAN matches the public FQDN clients
use to reach the Tunnel Gateway, from a CA the clients trust.
Why: The gateway presents this certificate to establish the encrypted tunnel; a mismatched or
untrusted certificate breaks every connection.
Verify: Confirm the certificate FQDN matches the gateway's published name and that the issuing CA
chain is trusted on iOS/Android; check the not-after (expiry) date.
Implement: Obtain a certificate (public CA or an enterprise PKI trusted by the devices) for the
gateway FQDN, export it with its private key and full chain, and stage it for the install script.

## 2.4 Network paths and firewall
Description: Inbound access from clients to the gateway on the configured TLS port (default TCP/UDP
443), and outbound from the gateway host to the internal resources plus to Microsoft Tunnel service
endpoints.
Why: Clients must reach the gateway; the gateway must reach both Intune (for the connector) and the
internal resources it forwards traffic to.
Verify: From the internet reach the gateway FQDN on the chosen port; from the gateway host reach the
internal target and Microsoft's Tunnel/Intune endpoints; run `TUNMAM-Validation.ps1` for the
Intune-side health signal.
Implement: Open the inbound tunnel port to the gateway, allow the gateway host outbound to internal
targets and to Microsoft's published Intune/Tunnel URLs and IP ranges through the firewall/proxy.

## 2.5 Internal DNS resolution
Description: DNS servers reachable from the gateway that resolve the internal names the managed apps
will request, plus the correct DNS suffix(es).
Why: A managed app can reach the tunnel yet still fail if the internal hostname does not resolve.
Verify: From the gateway host resolve the internal resource FQDN; confirm the same DNS servers are
set in the server configuration.
Implement: Set the internal DNS servers and DNS suffix search list in the Tunnel server
configuration; ensure split DNS is configured if only some names should resolve through the tunnel.

## 2.6 MAM client apps in scope
Description: The specific MAM-protected apps that must reach the intranet — Microsoft Edge on
iOS/Android, and any Intune App SDK / wrapped line-of-business apps — installed on the target
devices.
Why: Tunnel for MAM routes traffic only from supported, policy-managed apps; unsupported apps cannot
use the app tunnel.
Verify: Confirm each in-scope app is a supported Tunnel-for-MAM client and is deployed to the pilot
users; run `TUNMAM-Discovery.ps1` to list the app protection / MAM configuration.
Implement: Deploy the supported apps (for iOS, publisher Microsoft Corporation — Microsoft Edge
bundle ID `com.microsoft.msedge`; for Android, package `com.microsoft.emmx`) and confirm each LOB app
is Intune App SDK enabled.

## 2.7 App protection policies (MAM)
Description: iOS and Android app protection policies targeting the in-scope apps and pilot users.
Why: The Tunnel (MAM) configuration is delivered alongside app protection; without an APP the apps
are not managed and cannot be configured for the tunnel.
Verify: Intune → Apps → App protection policies; confirm an iOS and an Android policy targets the
apps and the pilot group.
Implement: Create app protection policies for iOS and Android targeting the in-scope apps and the
pilot group before adding the tunnel configuration.

## 2.8 Pilot group
Description: A Microsoft Entra security group of pilot users for the MAM tunnel configuration and
app protection policies.
Why: The tunnel is validated on a pilot before broad rollout.
Verify: Entra → Groups; the pilot group exists with the intended members.
Implement: Entra → Groups → New group → Security; add the pilot users. Name it
`Tunnel MAM Users – Pilot – Ring1`.

---
## Checklist
- [ ] Intune licensing assigned to in-scope users
- [ ] Supported Linux host with Docker/Podman ready
- [ ] TLS server certificate (FQDN match, trusted chain) staged
- [ ] Inbound tunnel port open; gateway outbound to internal + Microsoft endpoints
- [ ] Internal DNS resolves the target names from the gateway
- [ ] Supported MAM apps deployed to pilot users
- [ ] iOS + Android app protection policies targeting the apps
- [ ] Pilot Entra group created — `Tunnel MAM Users – Pilot – Ring1`


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** Phoenixtekk solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every Phoenixtekk solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The Phoenixtekk deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Microsoft Tunnel for MAM

Follow these steps in order. Intune steps are in the Microsoft Intune admin center
(`https://intune.microsoft.com`); the gateway install runs on the Linux host.

> Model: stand up the Tunnel Gateway on Linux, define a Server configuration and a Site, install the
> gateway/connector, then create the Tunnel (MAM) configuration and target the MAM apps. Validate one
> managed app reaching one internal resource on the pilot before you expand.

Named objects (create with these exact names and reuse them verbatim):

| Object | Name |
|---|---|
| Pilot Entra group | `Tunnel MAM Users – Pilot – Ring1` |
| Broad Entra group | `Tunnel MAM Users – Production – Broad` |
| Server configuration | `Tunnel Server Config – Intranet – Prod` |
| Site | `Tunnel Site – Intranet – Prod` |
| iOS app protection policy | `App Protection – iOS – Prod` |
| Android app protection policy | `App Protection – Android – Prod` |
| iOS Tunnel (MAM) app config | `Tunnel MAM Config – iOS – Prod` |
| Android Tunnel (MAM) app config | `Tunnel MAM Config – Android – Prod` |

## Step 1 — Create the groups
1. Entra → Groups → New group → Security → `Tunnel MAM Users – Pilot – Ring1` (a few pilot users).
   Create.
2. Create `Tunnel MAM Users – Production – Broad` (the broader population). Create.

## Step 2 — Create the Server configuration
1. Intune → Tenant administration → Microsoft Tunnel Gateway → Server configurations → Create.
2. Name: `Tunnel Server Config – Intranet – Prod`. Next.
3. IP address range: the client VPN address pool (a private subnet not colliding with your network).
4. DNS servers: your internal DNS servers. DNS suffix search: your internal domain suffix(es).
5. Split tunneling: add Include routes for only the internal subnets the apps must reach (recommended
   for MAM). Leave the rest excluded so non-internal traffic goes direct.
6. Server port: `443` (must be open inbound to the gateway). Next → Create.

## Step 3 — Create the Site
1. Intune → Tenant administration → Microsoft Tunnel Gateway → Sites → Create.
2. Name: `Tunnel Site – Intranet – Prod`.
3. Public IP address or FQDN: the public FQDN clients use (must match the TLS certificate).
4. Server configuration: select `Tunnel Server Config – Intranet – Prod`. Create.

## Step 4 — Install the Tunnel Gateway on the Linux host
1. Intune → Tenant administration → Microsoft Tunnel Gateway → Servers → Create → download the
   installation script and note the site to join (`Tunnel Site – Intranet – Prod`).
2. On the supported Linux host, stage the TLS certificate (with private key and full chain) where the
   script expects it, then run the Microsoft installation script (`mstunnel-setup`) as root. It pulls
   the gateway container (Docker/Podman) and installs the connector agent.
3. During setup, sign in with an Intune administrator when prompted (this registers the connector),
   and select the site `Tunnel Site – Intranet – Prod` so the server inherits
   `Tunnel Server Config – Intranet – Prod`.
4. After install, verify on the host with `mst-cli server show` (and `mst-cli agent info`), then in
   Intune confirm Servers shows the new server Healthy under the site.

## Step 5 — Create the iOS/Android app protection policies (if not already present)
1. Intune → Apps → App protection policies → Create policy → iOS/iPadOS.
2. Name: `App Protection – iOS – Prod`. Target the in-scope apps (include Microsoft Edge, bundle ID
   `com.microsoft.msedge`, and any LOB apps). Assign to `Tunnel MAM Users – Pilot – Ring1`. Create.
3. Repeat for Android: Create policy → Android → `App Protection – Android – Prod` (include Microsoft
   Edge, package `com.microsoft.emmx`, and LOB apps). Assign to `Tunnel MAM Users – Pilot – Ring1`.
   Create.

## Step 6 — Create the Tunnel (MAM) configuration — iOS
1. Intune → Apps → App configuration policies → Add → Managed apps.
2. Name: `Tunnel MAM Config – iOS – Prod`. Under Public apps, add the in-scope iOS apps (Microsoft
   Edge and any LOB apps).
3. In settings, enable the Microsoft Tunnel connection: select the site
   `Tunnel Site – Intranet – Prod` (and per-app VPN / connection type as prompted). Set the DNS/proxy
   values if your environment needs them.
4. Assignments → add `Tunnel MAM Users – Pilot – Ring1`. Create.

## Step 7 — Create the Tunnel (MAM) configuration — Android
1. Intune → Apps → App configuration policies → Add → Managed apps.
2. Name: `Tunnel MAM Config – Android – Prod`. Add the in-scope Android apps (Microsoft Edge and any
   LOB apps).
3. Enable the Microsoft Tunnel connection and select the site `Tunnel Site – Intranet – Prod`; set
   DNS/proxy values as needed.
4. Assignments → add `Tunnel MAM Users – Pilot – Ring1`. Create.

## Step 8 — Apply on a pilot device
1. On a pilot iOS/Android device, sign in to Microsoft Edge (or the LOB app) with the pilot user and
   complete the app-protection enrollment prompt; install the Microsoft Defender / Tunnel client if
   the platform prompts for it (Tunnel for MAM uses the tunnel client component).
2. Let policy apply, then confirm the app shows the tunnel is available (the managed app prompts to
   connect when reaching an internal route).

## Step 9 — Validate a managed app reaching an internal resource
1. In the managed app (for example Microsoft Edge), browse to an internal-only resource FQDN that is
   inside a split-tunnel Include route.
2. Confirm the page loads only in the managed app and only for the internal name — a non-managed
   browser on the same phone should not reach it.
3. Run `TUNMAM-Validation.ps1` for the Intune-side health signal and `TUNMAM-Report.ps1` for usage.
   Complete the Testing Guide.

## Step 10 — Pilot gate and expand
1. Pilot gate: only proceed if the Testing Guide passes for the pilot group (server Healthy, managed
   app reaches the internal resource, non-managed apps do not).
2. Expand: add `Tunnel MAM Users – Production – Broad` to the app protection policies and the Tunnel
   (MAM) configurations (`Tunnel MAM Config – iOS – Prod` / `Tunnel MAM Config – Android – Prod`).
3. Rollback: remove the broad group's assignment from the Tunnel (MAM) configurations to revert to
   pilot-only without deleting the gateway. Re-validate each ring with `TUNMAM-Report.ps1`.

---
### Order of operations
`Groups → Server configuration → Site → Install gateway/connector → App protection policies → Tunnel (MAM) config iOS → Tunnel (MAM) config Android → Apply → Validate → Expand`


---


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


---


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


---


# 7. Best Practices — Microsoft Tunnel for MAM

- Pilot before you expand. Validate one managed app reaching one internal resource on
  `Tunnel MAM Users – Pilot – Ring1` before assigning `Tunnel MAM Users – Production – Broad` — the
  single most important practice.
- Prefer split tunneling. Route only the internal subnets the apps must reach; leave internet and
  Microsoft 365 traffic direct. It keeps performance high and exposure low.
- Get DNS right first. Most "the app connects but the page won't load" issues are DNS — make sure the
  server configuration's DNS servers and suffixes resolve the internal names from the gateway host.
- Match the certificate to the FQDN. The TLS certificate subject/SAN must match the public gateway
  FQDN and chain to a CA the devices trust; track its expiry and renew ahead of time.
- Keep the app list intentional. Only supported Tunnel-for-MAM apps can tunnel (Microsoft Edge and
  Intune App SDK / wrapped LOB apps); confirm each LOB app is SDK-enabled before adding it.
- Configure iOS and Android separately. The two platforms have distinct app-config and client
  requirements; test each on real devices, not just one.
- Name objects consistently. Use `<Purpose> – <Scope> – <Stage>` for every group, server config,
  site, and MAM config, and reuse the names verbatim — it makes audits and rollback obvious.
- Size and patch the host. Follow Microsoft's CPU/RAM/throughput sizing, keep the Linux host and
  container engine patched, and monitor the gateway container's resource use.
- Watch health continuously. Check Microsoft Tunnel Gateway → Health status and run
  `TUNMAM-Report.ps1` on a cadence; chase unhealthy servers before users notice.
- Keep a rollback ready. To revert, remove the broad group from the Tunnel (MAM) configurations
  rather than deleting the gateway — pilot stays working while you investigate.
- Document the design. Record the address pool, DNS servers, split routes, ports, site membership,
  and target FQDN for repeatability and audits.


---


# 8. Deliverables Summary — Microsoft Tunnel for MAM

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Tunnel for MAM is, gateway/connector, split vs. full tunnel, DNS, app-level vs. device VPN, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: gateway install, server config, site, connector, Tunnel (MAM) config, app targeting |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `TUNMAM-Discovery.ps1` | Reports Tunnel sites, servers, and server configurations plus the app protection / Tunnel (MAM) configuration and targeting (Microsoft Graph, read-only) |
| `TUNMAM-Validation.ps1` | Checks per-server tunnel health and confirms the MAM configuration reaches the targeted groups (Microsoft Graph, read-only) |
| `TUNMAM-Report.ps1` | Tunnel usage + health report across sites/servers and MAM coverage (Microsoft Graph, read-only) |
| `TUNMAM-Remediation.ps1` | Safe remediation of unhealthy/misassigned Tunnel MAM config (default `-WhatIf`) |
| `TUNMAM-Set-ScopeTargeting.ps1` | Adds/updates the pilot or broad group assignment on the Tunnel (MAM) configurations |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess → Configure → Pilot → Validate → Expand.

## Outcome
Managed mobile apps reaching internal intranet resources through an app-scoped Microsoft Tunnel for
MAM — not a whole-device VPN — proven on a pilot before you scale.
