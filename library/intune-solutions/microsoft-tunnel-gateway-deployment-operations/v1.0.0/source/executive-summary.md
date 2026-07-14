# Executive Summary — Microsoft Tunnel Gateway: Deployment, VPN Configuration & Ongoing Operations

**Intune Solutions**

Microsoft Tunnel gives Intune-managed devices a VPN path to on-premises and internal resources — but
the Gateway that terminates those connections is a **Linux container service** that has to be
installed, TLS-secured, configured, scaled, and kept healthy over time. Most teams can stand up a
single test server; far fewer get to a **production** gateway that is highly available, monitored, and
supportable a year later. This package takes you the whole distance.

This is a complete, **deploy-it-today** solution written for a competent administrator with no prior
Microsoft Tunnel experience. It installs the Tunnel Gateway end to end (Linux host + container
runtime + the Microsoft Tunnel agent), secures it with a TLS server certificate, configures the
**Server Configuration and Site** in Intune (listener port, DNS, split-tunnel vs full-tunnel routes,
client address pool), delivers the **per-platform VPN connection profiles** through Intune, sets up
**high availability and scale-out**, and hands over a **monitoring + operations & troubleshooting
runbook** for ongoing support.

## Scope boundary — read this first
This solution is the **device-tunnel Tunnel *Gateway*** — the server-side deployment and operations of
the Linux gateway plus the enrolled-device VPN connection profiles. It is **deliberately distinct**
from the catalog's **"Microsoft Tunnel for MAM — Mobile Access to Intranet Resources"** products,
which are **MAM-app-client** scoped (unenrolled/BYOD app-level tunnel). If you need app-level access on
unmanaged devices, use that product; if you need to **build and run the gateway** for enrolled devices,
this is the one. The two are complementary — cross-referenced, not duplicated.

## What you get
- A plain-language **Solution Overview** — how the Tunnel Gateway works, the split-tunnel vs
  full-tunnel decision, the client-platform support reality (iOS/iPadOS + Android are the natively
  supported Tunnel clients; Windows/macOS caveats stated honestly), and the standard deployment model.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite
  (Linux host, container runtime, TLS certificate, outbound endpoints, client app), beyond the
  category-wide Intune prerequisites.
- An **Implementation Guide** of exact, ordered steps — Site, Server Configuration, host install, TLS,
  per-platform connection profiles, Conditional Access — every object named and reused.
- Five **automation scripts**: three read-only PowerShell (Microsoft Graph) for discovery, validation,
  and fleet/health reporting, plus two Linux shell scripts for host prerequisite checking and
  gateway health + log collection. A KQL query is included for monitoring.
- **Testing** and a **Troubleshooting + Operations Runbook** for ongoing support (server health, cert
  expiry, connectivity, common failures).

## What this delivers
A **production Microsoft Tunnel Gateway** — installed on a supported Linux host, TLS-secured,
configured with the right routing model, fronting a Site that can scale to multiple servers behind a
load balancer — giving managed devices secure VPN access to internal resources, with connection
profiles deployed by platform, Conditional Access applied, monitoring in place, and a repeatable ops
runbook for the team that keeps it running.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Managed devices reach internal resources through a Tunnel Gateway you **own and can operate** — highly
available, monitored, and supported — proven on a pilot group before you scale to the fleet.
