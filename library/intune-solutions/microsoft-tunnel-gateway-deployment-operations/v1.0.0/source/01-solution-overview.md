# 1. Solution Overview — Microsoft Tunnel Gateway: Deployment, VPN Configuration & Ongoing Operations

## What this solves
Intune-managed devices frequently need to reach resources that never leave the corporate network — an
internal line-of-business web app, a file server, an internal API, an on-premises service. Microsoft
Tunnel provides that path: a VPN gateway, managed through Intune, that terminates client VPN
connections and forwards traffic to your internal network. The catch is that the **Gateway itself** is
not a cloud service you toggle on — it is a **container that runs on a Linux server you own**. Someone
has to install it, give it a trusted TLS certificate, configure how it routes traffic, deploy the
client VPN profiles, make it survive a single-server failure, and keep it healthy for the long run.

This solution does all of that, end to end, and then hands you the runbook to operate it.

## How Microsoft Tunnel works (the parts you must understand)
Four moving pieces make up a working Tunnel deployment:

1. **The Tunnel Gateway (server side).** A Linux host runs a **container** (via Podman or Docker) that
   is the Microsoft Tunnel agent. It listens on a TLS port for incoming client connections, decrypts
   them, and forwards the traffic to your internal network according to the routing rules you set. The
   host is *yours* — an on-prem VM, a VM in your datacenter, or an IaaS VM — and it needs a network
   path to the internal resources you want to reach.

2. **Intune configuration objects (control plane).** In the Intune admin center you create a **Site**
   (the logical grouping that a public FQDN points at) and a **Server Configuration** (the routing and
   network settings — listener port, DNS servers, the client IP address pool, and the split/full-tunnel
   routes). The Server Configuration is assigned to the Site; when you install a Tunnel server it joins
   that Site and inherits the configuration.

3. **The client VPN connection profiles.** Intune pushes a **VPN profile** to enrolled devices telling
   them how to connect to the Tunnel (the Site FQDN, the connection type = Microsoft Tunnel, the
   authentication method, and per-app / on-demand options). The device-side VPN client is delivered by
   the **Microsoft Defender for Endpoint** app on the supported mobile platforms.

4. **Identity + Conditional Access.** Users authenticate to the Tunnel through Microsoft Entra ID, and
   you can gate access with a **Conditional Access** policy (for example, require a compliant device
   before the Tunnel connection is allowed).

A device connects → authenticates to Entra ID → the Tunnel Gateway accepts the TLS session → traffic
that matches the configured routes is forwarded to the internal network → everything else either goes
direct (split tunnel) or also through the Tunnel (full tunnel), per your Server Configuration.

## Client-platform support — stated honestly
The brief for this solution covers connection profiles for **Windows, iOS/iPadOS, Android, and
macOS**, so this package documents all four. Be aware of the real support matrix, because it decides
what will actually connect:

- **iOS/iPadOS and Android are the natively supported Microsoft Tunnel client platforms.** The device
  VPN client is provided by the **Microsoft Defender for Endpoint** app, and Intune ships a native
  **Microsoft Tunnel** VPN connection-profile type for these platforms.
- **Windows and macOS:** Microsoft's *device-tunnel* client support has historically centered on the
  two mobile platforms above. Native Microsoft Tunnel VPN client support for Windows/macOS is **not
  guaranteed** and has differed by scenario and over time. **Verify current Microsoft guidance for your
  tenant** before promising Windows/macOS Tunnel connectivity — the platform matrix and connection-type
  availability change. This package gives you the Windows/macOS connection-profile *procedure and the
  exact thing to verify*, and is explicit where support is conditional, rather than inventing a
  capability. If Windows/macOS clients are a hard requirement and native Tunnel support is unavailable,
  the "where to go next" section names the adjacent approaches.

> **Do not confuse this with the MAM Tunnel.** The catalog's *"Microsoft Tunnel for MAM"* products are
> the **app-level** tunnel for **unenrolled** devices (mobile application management). **This** solution
> is the **device tunnel** for **enrolled** devices and the **gateway build + operations** behind it.
> Same gateway technology family, different client scope. Use the MAM product for BYOD app access; use
> this one to stand up and run the gateway.

## Split tunnel vs full tunnel — the routing decision
Your **Server Configuration** decides how much traffic goes through the Tunnel:

- **Split tunnel (recommended default):** only traffic destined for the **include routes** (your
  internal CIDR ranges) goes through the Tunnel; everything else (internet, cloud SaaS) goes direct.
  Lower load on the gateway, better user experience, smaller blast radius. You define **include routes**
  for the internal ranges and optionally **exclude routes** to carve out subnets that should *not* go
  through the Tunnel.
- **Full tunnel:** all device traffic is routed through the Tunnel. Use only when a policy genuinely
  requires all traffic to egress through the corporate network; it puts far more load on the gateway
  and makes capacity planning and monitoring more important.

The routing decision, the client IP address pool, the DNS servers, and the listener port all live in
the Server Configuration and are covered step-by-step in the Implementation Guide.

## Scope — what this solution covers
- Linux host prerequisites and readiness checking for the Tunnel Gateway.
- Container runtime (Podman/Docker) and the Microsoft Tunnel agent install.
- TLS server certificate preparation and placement.
- Intune **Site** + **Server Configuration** (listener, DNS, client address pool, split/full-tunnel
  routes).
- **Per-platform VPN connection profiles** (iOS/iPadOS, Android, plus Windows/macOS with the verified
  caveats), per-app VPN and on-demand options, and the Defender client app.
- **Conditional Access** integration (require compliant device before Tunnel).
- **High availability / scale-out** (multiple servers per Site behind a load balancer) and an
  **upgrade** strategy.
- **Monitoring, health checks, and an operations & troubleshooting runbook** for ongoing support.

## Out of scope (deferred to the customer or another product)
- **The MAM / app-level tunnel for unenrolled devices** — use the catalog's *Microsoft Tunnel for MAM*
  products.
- **Building your internal network, firewall, and DNS** — this solution consumes an existing internal
  network and tells you exactly which paths and ports the gateway needs; your network team owns the
  firewall/routing changes.
- **Your PKI / certificate authority** — you supply a valid TLS server certificate and (if you choose
  certificate-based client auth) a working SCEP/PKCS pipeline; standing up a CA is a separate effort.
- **Regulatory, data-residency, and acceptable-use determinations** — the guide provides the technical
  controls; classification and policy decisions belong to your security/compliance functions.
- **Load-balancer product selection and licensing** — the guide states the L4/TCP passthrough
  requirement; the specific appliance/service is yours to choose.

## Authentication and connections used
- **Microsoft Entra ID** — user authentication to the Tunnel and the identity backbone.
- **Microsoft Intune** — Site, Server Configuration, VPN connection profiles, app deployment,
  Conditional Access.
- **Microsoft Graph (PowerShell)** — the read-only discovery/validation/reporting scripts read Tunnel
  configuration and device state via documented `deviceManagement` endpoints. Some Tunnel resources are
  on the Graph **beta** endpoint; the scripts note this where used — *verify current Graph coverage*.
- **The Linux host root/sudo context** — the Tunnel install and the host-side shell scripts run on the
  gateway server; the install registers the server with Intune using an interactive Intune-admin
  sign-in.

## The standard deployment model
> **Assess** the host, network, certificate, and licensing → **Configure** the Site, Server
> Configuration, install the gateway, and build the connection profiles → **Pilot** on a small device
> group with split tunnel and report-only Conditional Access → **Validate** connectivity, routing,
> health, and CA → **Expand** to the fleet, add HA servers, and enforce Conditional Access.
> Pattern: **Assess → Configure → Pilot → Validate → Expand.**
