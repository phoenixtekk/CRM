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
