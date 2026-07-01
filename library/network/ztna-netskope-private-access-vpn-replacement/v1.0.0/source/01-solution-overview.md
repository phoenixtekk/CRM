# 1. Solution Overview — Zero Trust Network Access (ZTNA) with Netskope Private Access

## What ZTNA / Netskope Private Access is
Zero Trust Network Access (ZTNA) replaces the legacy remote-access VPN. Instead of placing a user
*on the network* and trusting everything they can reach, ZTNA brokers access to one private
application at a time, after checking *who* the user is and *what state* their device is in. Netskope
Private Access is the ZTNA service that implements this: lightweight `publishers` (connectors) are
deployed next to your private apps, each private app is published as a named object, and an access
policy decides — per identity, per group, per device posture — exactly which apps each user may
reach. The network itself is never exposed.

## Why this matters (the *why* lives here)
A VPN hands the user a route into the corporate network. Once connected, a compromised laptop or a
stolen credential can scan and pivot across everything that route reaches — the classic attacker
on-ramp. VPN concentrators are also a scaling and performance bottleneck (all traffic hairpins
through them) and they are hard to govern (access is by subnet, not by app or identity). ZTNA inverts
the model: there is no inbound route to expose, apps are invisible until policy grants them, and
access is least-privilege by default — a user reaches only the specific apps their identity and
device posture entitle them to, and nothing else. That is the reason to make the switch; the rest of
this package is the repeatable way to do it safely.

## How it works
1. A `publisher` (connector) is deployed inside each network segment that hosts private apps. It
   makes an *outbound* connection to the Netskope cloud — no inbound firewall ports are opened.
2. Each private app (an internal web app, an RDP/SSH host, a file share, a thick-client service) is
   published as a named private-application object that maps to its internal host(s) and port(s).
3. The Netskope client on the endpoint steers traffic for published apps to the nearest Netskope
   point of presence, which brokers the session to the right `publisher`.
4. An access policy evaluates the user's identity and group (from Entra ID) and the device posture
   (managed, compliant, certificate present, etc.) and grants or denies the specific app.
5. Because brokering is per-app and identity/posture-gated, the user reaches only entitled apps —
   the network is never routable end to end.
6. The VPN and ZTNA run side by side during a coexistence window, then the VPN is cut over and
   retired once the published app set is proven.

## What you can control
- Which private apps are published, and the exact internal hosts/ports each one maps to.
- Which identities and Entra ID groups may reach each app (least-privilege, per-app access).
- Device posture conditions that gate access (managed/compliant device, certificate, OS state).
- Where `publishers` are placed (per site / per segment) for performance and resilience.
- The coexistence-then-cutover schedule that retires the VPN once apps are proven.

## How this differs from a VPN
- VPN grants network reachability (a route to a subnet); ZTNA grants application access (one app).
- VPN trusts the connection; ZTNA re-checks identity and posture for every app, every time.
- VPN exposes a public concentrator; ZTNA `publishers` dial out, so nothing is exposed inbound.
- VPN access is hard to audit by app; ZTNA access maps cleanly to named apps and named groups.

## Limitations (be honest with buyers)
- Some legacy or non-TCP applications need specific handling; inventory and test each app before
  cutover rather than assuming parity with the VPN.
- ZTNA brokers private-app access; it is not a full secure web gateway by itself (web/SaaS traffic
  is a separate Netskope capability outside this solution's scope).
- The exact Netskope console screens and menu paths change over time and are deferred to the
  official Netskope documentation and your tenant — this guide names the step and the artifact, and
  you confirm the precise control in your console.

## The standard deployment model
> Assess the app inventory and prerequisites, configure `publishers` and private apps and policy,
> pilot with a small group, validate access and posture, then expand and cut over from the VPN.
> Deployment model: Assess to Configure to Pilot to Validate to Expand.
