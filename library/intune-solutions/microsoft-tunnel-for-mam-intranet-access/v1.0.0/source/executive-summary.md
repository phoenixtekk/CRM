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
