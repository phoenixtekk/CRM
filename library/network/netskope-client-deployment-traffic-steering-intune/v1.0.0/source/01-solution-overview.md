# 1. Solution Overview — Netskope Client Deployment & Traffic Steering at Scale (Intune)

## What this solution is
A SASE/SSE platform enforces policy in the cloud, but traffic only reaches that cloud if an endpoint
agent — the Netskope client — is installed, healthy, enrolled to your tenant, and steering the right
traffic. This solution is the repeatable way to deliver that agent and its steering configuration to
a large managed fleet using Microsoft Intune: you package the client once, deploy it through Intune,
push consistent steering and exception configuration, validate client health, and roll out in safe
rings to thousands of endpoints.

The Netskope console internals (tenant settings, steering-profile screens, exception object names)
change over time and are deferred to the official Netskope documentation and your tenant. What this
solution owns end to end is the Intune side: packaging, deployment, assignment, health validation,
and the ringed large-scale rollout.

## Why it matters (the why lives here)
- Coverage is the whole game. A SASE policy that a device never touches is no policy at all; the
  client must be on every in-scope endpoint, healthy, and enrolled to your tenant.
- Hand rollouts stall. Manual installs miss machines, apply inconsistent steering, and accumulate
  one-off exceptions nobody can audit — leaving silent coverage gaps.
- Steering and exceptions affect live traffic. Inline steering and SSL inspection sit in the path of
  real user traffic; a wrong exception (or a missing one) either breaks a business app or quietly
  bypasses protection. Both must be deliberate and consistent.
- Scale needs rings. Pushing a traffic-steering agent to thousands of devices at once is how an
  outage happens. A small pilot ring proves health and steering before each larger ring inherits it.

## How it works
1. The Netskope client installer is wrapped as an Intune app (the client app artifact), configured
   for unattended install with your tenant-enrollment method, and assigned to device groups.
2. Steering and exception configuration is delivered so every device steers the same traffic and
   honors the same exception list — applied consistently rather than per-machine.
3. Client health is validated on each device (installed, running, enrolled to the right tenant,
   steering active) and reported across the fleet from Intune.
4. Rollout is ringed: a small pilot ring installs first, then progressively larger rings, each
   gated on the prior ring's health and steering being clean.
5. Deployment status, failures, and exception coverage are reported so laggards and broken clients
   are found and remediated rather than left silently unprotected.

## What you configure (named artifacts, reused verbatim throughout)
- Client app: `Netskope Client – Windows – Production` — the packaged Intune app that installs and
  tenant-enrolls the client.
- Steering config: `Steering Profile – Corporate – Production` — the traffic-steering definition
  delivered to managed devices (authored in the Netskope tenant; deferred to Netskope docs).
- Exception list: `Steering Exceptions – Business Apps – Production` — the bypass/exception set that
  keeps named business applications working under inline steering.
- Rollout rings: `Rollout Ring – Pilot – Stage1`, `Rollout Ring – Early – Stage2`,
  `Rollout Ring – Broad – Stage3` — the progressively larger waves of the deployment.
- Groups: `Device Group – Pilot – Stage1`, `Device Group – Early – Stage2`,
  `Device Group – Broad – Stage3` — the Entra security groups each ring is assigned to.

## Benefits
- Coverage at scale — the client lands on every in-scope device through Intune, not by hand.
- Consistent steering — one steering config and one exception list applied fleet-wide, not per machine.
- Apps keep working — a deliberate, named exception list prevents inline steering from breaking
  business apps.
- Safe rollout — ringed waves with a pilot gate catch problems on a few devices, not thousands.
- Visibility and recovery — per-device deployment status and health, with safe remediation for
  failed or unhealthy clients.

## Limitations (be honest with buyers)
- Netskope tenant configuration (steering profiles, exception objects, enrollment method, SSL/decrypt
  certificates) is authored in the Netskope console and is deferred to the official Netskope
  documentation — this solution wires the Intune delivery and validation around it.
- The client packaging specifics (silent-install switches, enrollment token/SSO method) are
  vendor-version-dependent; the steps name what to set and defer the exact switches to Netskope docs.
- Steering changes affect live traffic; a change window and rollback path are required (global G7).
- Client-health validation reads device-side state and Intune deployment status; deep steering
  analytics live in the Netskope console.

## The standard deployment model
> Package and stage the client app -> deliver steering + exception config -> validate client health ->
> ring the rollout -> pilot, validate, expand. The model: Assess -> Configure -> Pilot -> Validate -> Expand.
