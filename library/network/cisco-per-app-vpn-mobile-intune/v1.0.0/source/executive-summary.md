# Executive Summary

## The problem

A device-wide mobile VPN backhauls **everything** a phone does — personal browsing, streaming, other
apps — through the corporate network. That drains battery, adds latency, worries users about privacy,
and expands what the corporate tunnel is responsible for. It is all-or-nothing when the business only
needs *some* apps to reach internal resources.

## The solution

Build **Cisco Secure Client per-app VPN** for **iOS** and **Android** through **Microsoft Intune** so
that **only the named managed business apps** open the tunnel — on demand — and everything else stays
direct. Intune delivers the client, the VPN profile, the authentication material, and the
**app-to-VPN association**; the Cisco head-end (configured per Cisco's own documentation) terminates
the tunnel.

## How it's delivered

The repeatable model — **Assess → Configure → Pilot → Validate → Expand** — with explicit pass/fail
gates and named, reused objects (`Cisco Per-App VPN – iOS`, `Cisco Per-App VPN – Android`,
`PILOT – Per-App VPN Users`). It ships pilot-first and rollback-ready: prove that the right apps
tunnel and everything else stays direct on a small pilot before touching the fleet.

## What's included

- **Step-by-step guides** to build the per-app VPN profile for iOS and Android, associate the named
  managed apps, assign to a pilot, validate, and expand.
- **Five PowerShell scripts** (Microsoft Graph): readiness discovery, per-device validation, a
  coverage report, safe remediation of mis-scoped apps (preview-by-default), and a targeting-group
  builder.
- **Testing and troubleshooting** with clear gates — *managed apps tunnel; other traffic direct* — and
  best practices for the managed-app model.

## Scope boundary

The Intune, Entra, and certificate side is documented at exact click-by-click detail. The **Cisco
Secure Client mobile app and the Cisco VPN head-end** (gateway/firewall remote-access role, typically
with Cisco ISE) are **deferred to Cisco's official documentation** — this solution consumes the
head-end's server address and auth method rather than fabricating Cisco menu paths.

## The bottom line

Only the business apps that need it tunnel to internal resources on managed mobiles — scoped by
Intune, powered by Cisco Secure Client, and proven on a pilot before you scale. Self-guided, tested,
and a fraction of the cost of a consulting engagement.
