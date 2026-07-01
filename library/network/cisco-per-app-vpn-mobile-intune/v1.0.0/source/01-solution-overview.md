# Solution Overview

## What this solution does

This solution builds **Cisco Secure Client per-app VPN** for **iOS** and **Android** managed mobile
devices using **Microsoft Intune**. Instead of a device-wide tunnel that backhauls every packet the
phone sends, per-app VPN opens the Cisco Secure Client tunnel **only for the specific managed apps
you associate with it**. Everything else — personal browsing, streaming, other apps — goes direct
to the internet.

The result: your named business apps reach internal resources through the Cisco head-end, while the
rest of the device stays off the corporate tunnel. Less backhaul, less battery drain, fewer privacy
worries, and a smaller attack surface.

You deploy it the repeatable way — **Assess → Configure → Pilot → Validate → Expand** — pilot-first
and rollback-ready, with named objects reused verbatim at every step.

## The two moving parts (and the boundary between them)

Per-app VPN is a **partnership** between two control planes:

1. **Microsoft Intune (this solution's exact-detail scope).** Intune delivers the Cisco Secure
   Client app, a **VPN profile** configured for per-app mode, the managed apps, and the
   **association** that binds each app to the VPN profile. Intune also delivers the authentication
   material (a certificate profile or the chosen auth method) and assigns everything to your Entra
   groups. This is where you click.
2. **The Cisco head-end (deferred to Cisco docs).** The Cisco Secure Client mobile app connects to a
   Cisco VPN head-end (for example, a Cisco firewall/gateway with the remote-access VPN role, with
   policy typically brokered through Cisco ISE). The head-end's connection profile, address pools,
   split-tunnel/split-DNS rules, and any posture policy are configured **in Cisco's consoles** and
   are **deferred to Cisco's official documentation**. This solution names *what* you need from the
   head-end (a reachable connection entry / server address and a supported auth method) but does not
   fabricate Cisco menu paths.

> **Where they meet:** Intune's VPN profile carries the **connection name / server address** that
> points at the Cisco head-end and the **per-app rules**. The Cisco head-end must **accept** that
> connection and the chosen authentication. Get the head-end reachable and authenticating first
> (per Cisco docs); this solution wires the Intune side to it precisely.

## How per-app VPN works on iOS

On iOS (and iPadOS), per-app VPN is a native platform capability:

- Intune deploys a **VPN profile** of connection type **Cisco Secure Client** (formerly AnyConnect),
  configured for **per-app VPN** with **on-demand** enabled.
- You mark the profile to be used by specific **managed apps**. On iOS, apps must be
  **Intune-managed** (installed/managed by MDM) for the association to take effect — a personally
  installed copy of the same app will **not** use the tunnel.
- When the user launches an associated app, iOS **starts the Cisco Secure Client tunnel on demand**
  for that app's traffic and tears it down when the traffic stops. Traffic from unassociated apps
  never enters the tunnel.
- **Safari domain association** is available where you want specific web domains to trigger the tunnel
  inside Safari; the primary model here is app-to-VPN association.

**iOS requirement to know now:** reliable per-app VPN association is expected on **supervised**
devices (enrolled via **Automated Device Enrollment / ADE**, i.e. Apple Business Manager). Working
**APNs** (Apple Push Notification service) is required for Intune to manage iOS devices at all.

## How per-app VPN works on Android

On **Android Enterprise**, per-app VPN is expressed through Intune as an **app-based VPN**:

- Intune deploys a **VPN profile** of connection type **Cisco Secure Client** on the Android
  Enterprise management profile (typically **work profile** for BYOD, or **fully managed** for
  corporate-owned).
- The profile carries an **allow-list of package names** — the apps *permitted* to use the VPN — (or,
  alternatively, a block-list of apps to exclude). Only the allow-listed managed apps send traffic
  through the Cisco Secure Client tunnel.
- **Always-on / on-demand behavior** is set on the profile. Android's per-app VPN is enforced by the
  work-profile boundary plus the package allow-list, so apps outside the list route directly.

**Android requirement to know now:** the device must be enrolled in **Android Enterprise** (work
profile or fully managed) with **Managed Google Play** connected to Intune, so the Cisco Secure
Client app and your business apps are delivered as **managed** apps referenced by package name.

## On-demand behavior

"On-demand" means the tunnel is **not** a permanent always-connected device VPN. It is triggered by
the associated app:

- **iOS:** on-demand rules start the tunnel when an associated app needs the network and stop it when
  idle — the user does not manually connect.
- **Android:** the app-based VPN engages for allow-listed apps; you choose whether it behaves
  always-on (for those apps) or connects as needed.

Either way, the **user experience is invisible for the right apps and untouched for everything else**.

## The managed-app-to-VPN association (the heart of it)

The single most important concept: **an app only tunnels if it is both (a) managed by Intune and
(b) associated with the VPN profile.** Miss either half and you get one of the two classic failures —
the app doesn't tunnel (not associated / not managed), or *everything* tunnels (profile built
device-wide instead of per-app). This solution names the exact apps, associates them explicitly, and
validates that **only** those apps tunnel before expanding.

## Named objects this solution creates (reused verbatim)

| Object | Name | Where |
|---|---|---|
| iOS per-app VPN profile | `Cisco Per-App VPN – iOS` | Intune device configuration |
| Android per-app VPN profile | `Cisco Per-App VPN – Android` | Intune device configuration |
| Pilot targeting group | `PILOT – Per-App VPN Users` | Entra ID security group |
| Broad targeting group | `BROAD – Per-App VPN Users` | Entra ID security group |
| Certificate profile (if cert auth) | `Cisco Per-App VPN – User Cert` | Intune device configuration |

Managed apps are referenced by their real store/package identity and named consistently as
**"the associated managed apps"** throughout (you list yours in the implementation guide — e.g. an
internal line-of-business app, a managed browser, a mail/intranet client).

## Where Conditional Access fits

Per-app VPN scopes *network access* to specific apps; **Conditional Access (CA)** in Entra scopes
*identity access* to specific apps and enforces device compliance. They align: put the same audience
in `PILOT – Per-App VPN Users`, require **compliant, managed** devices in CA for the same business
apps, and require the Intune device-compliance signal — so the app that tunnels is also the app that
must come from a healthy, enrolled device. CA design detail is covered where it intersects the pilot;
the network scoping is what this solution builds.

## Outcome

At the end: named managed apps on iOS and Android open the Cisco Secure Client tunnel on demand to
reach internal resources, all other traffic stays direct, and you have discovery/validation/reporting
scripts plus a rollback to prove and maintain it — proven on `PILOT – Per-App VPN Users` before you
expand to `BROAD – Per-App VPN Users`.
