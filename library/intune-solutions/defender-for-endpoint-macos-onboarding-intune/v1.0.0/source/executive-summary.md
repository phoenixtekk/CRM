# Executive Summary — Microsoft Defender for Endpoint for macOS (Deployment & Onboarding via Intune)

Deploying **Microsoft Defender for Endpoint (MDE) on macOS** is not the one-click app push it looks
like. macOS deliberately blocks security software from loading its system extensions, reading the
whole disk, and filtering network traffic until an administrator has *explicitly approved* each of
those capabilities. Push the installer and the onboarding package before those approvals are in place
and the agent installs but sits **silently degraded** — extensions not running, real-time protection
off, no EDR sensor — while the portal shows a reassuring "onboarded" tick. Whole Mac fleets have been
"onboarded" this way and protected nothing. This package deploys and onboards MDE for macOS through
**Microsoft Intune** the way macOS actually requires: the five required approval profiles **first**,
then the app and the onboarding package, then a health check that proves the agent is genuinely
working — deployed pilot-first and rollback-ready.

This is a complete, **deploy-it-today** package written for an administrator with no prior
MDE-for-macOS experience.

## What you get
- A plain-language **Solution Overview** of the MDE-for-macOS deployment model — system extensions,
  Full Disk Access (PPPC/TCC), the network filter, background service management, notifications, and
  the onboarding blob delivered via Intune — and exactly why the order matters.
- A **Requirements Guide** with why / verify / implement-if-missing for every prerequisite — MDE
  licensing, the Apple MDM Push (APNs) certificate, macOS enrollment, the onboarding package, and the
  Microsoft-published extension identifiers — plus a consistent object-naming convention.
- An **Implementation Guide** of precise, click-by-click Intune steps: build the five named capability
  profiles first, gate on them applying, deploy the Microsoft Defender app, deploy the onboarding
  profile, validate `mdatp` health on a pilot, and expand — with a rollback note.
- Five **PowerShell scripts** for readiness discovery, per-device validation, fleet posture and drift
  reporting, safe remediation, and safe scope widening.
- **Testing** and **Troubleshooting** guides — including the classic "onboarded but not protecting"
  failure — plus **Best Practices** centered on the extension-approval order.

## What this delivers
A **correctly onboarded, genuinely healthy** Microsoft Defender for Endpoint deployment across the Mac
fleet: the system-extension, Full Disk Access, network-filter, background-service, and notification
approvals in place *before* onboarding, the agent proven healthy (extensions running, real-time
protection on, active in the Microsoft Defender portal), and a documented rollback.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with the invariant rule: **profiles first,
onboarding second, validation third.**

## Outcome
Every Mac protected by Defender for Endpoint — the required approvals in the right order, a clean
onboarding, and a proven-healthy agent — deployable by a single administrator and validated on a pilot
before fleet rollout.
