# Executive Summary — Cloud-First Autopilot Zero-Touch Provisioning (Microsoft Intune)

Phoenixtekk Workplace Marketplace · Intune Solutions

Provisioning a new Windows PC the old way is slow and hands-on: a technician images the machine,
domain-joins it, installs apps, applies policy, and babysits every build. The modern path is
cloud-first — Microsoft Entra join plus Windows Autopilot — so a device provisions itself the moment
it is powered on and connected to the internet. Apps and policy arrive during enrollment, the
Enrollment Status Page holds the desktop until the device is ready, and the technician does almost
nothing. Domain join is added afterward only when a specific app or resource genuinely requires it —
never by default.

This is a complete, deploy-it-today package for standing up cloud-first, near zero-touch provisioning
with Microsoft Intune, written for an administrator with no prior Autopilot experience.

## What you get
- A plain-language Solution Overview of the cloud-first model: Entra join, Autopilot, the Enrollment
  Status Page, provisioning-time apps and policy, and why this beats hybrid-by-default.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click Intune steps in the required order — register
  devices, build the Autopilot profile, configure the ESP and provisioning-time apps, then pilot,
  validate, and expand.
- A clear decision path for adding domain join later, only when a named app or resource requires it.
- Five PowerShell scripts for readiness discovery, per-device provisioning validation, a
  provisioning-success and technician-touch report, safe remediation of failed provisioning, and an
  Autopilot target-group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A near zero-touch provisioning model: a dynamic Autopilot device group, a user-driven, Entra-joined
deployment profile, an Enrollment Status Page that blocks until apps and policy land, and the core
app/baseline set delivered at enrollment — so technicians only unbox and power on. The rare device
that truly needs on-premises resources gets domain join added afterward on a documented, evidence-led
decision path.

## The Phoenixtekk deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Windows devices that provision themselves on power-on — Entra-joined via Autopilot, apps and policy
applied at enrollment, domain join only where truly required — cutting technician effort to almost
nothing and proven on a pilot before you scale.
