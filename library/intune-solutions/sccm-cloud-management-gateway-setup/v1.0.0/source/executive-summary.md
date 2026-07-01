# Executive Summary — Configuration Manager Cloud Management Gateway (CMG)

Intune Solutions

Your laptops left the building and never came back. Remote and hybrid Windows devices that used to
sit on the LAN now rarely touch the corporate network, so Configuration Manager can't reach them:
policy goes stale, software updates stall, inventory goes dark, and you can't tell a healthy device
from a dead one. A Cloud Management Gateway (CMG) fixes that — an Azure-hosted front door that lets
Configuration Manager manage internet-based clients securely, with no VPN and no inbound firewall
holes.

This is a complete, deploy-it-today package for standing up a CMG against your Configuration Manager
current branch site, written for an administrator with no prior CMG experience.

## What you get
- A plain-language Solution Overview of how a CMG works, the CMG plus connection point design, and
  token vs. PKI authentication.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — supported site
  version, Azure subscription, Entra app registrations, the server authentication certificate, the
  client auth model, Enhanced HTTP, and content design.
- An Implementation Guide of precise, ordered steps: Azure onboarding, creating the CMG cloud service,
  adding the connection point, enabling the management point and software update point for CMG
  traffic, and configuring clients for cloud management.
- Five PowerShell scripts for environment-readiness discovery, CMG/client connectivity validation, an
  internet-client health and reach report, safe client remediation, and a cloud-management settings
  helper.
- Testing and Troubleshooting guides with explicit pass/fail gates.

## What this delivers
A secure Azure front door — the `CMG – Internet Clients – Pilot` cloud service plus a CMG connection
point — that relays management traffic from internet clients to your on-premises management point and
software update point, authenticated by Microsoft Entra ID token or PKI, with no VPN and no inbound
firewall holes.

## The deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Internet-based Windows clients fully manageable from Configuration Manager — receiving policy,
software updates, and inventory over a secure Azure front door — deployable by a single administrator
and proven on a pilot before you scale.
