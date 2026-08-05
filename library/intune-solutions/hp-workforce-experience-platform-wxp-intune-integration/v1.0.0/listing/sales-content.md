# Sales Content — HP Workforce Experience Platform (WXP) Integration with Microsoft Intune

## Hook
**See the hardware, not just the score.** Integrate HP Workforce Experience Platform (WXP) with
Microsoft Intune — deploy the WXP agent through Intune and connect WXP to your Entra/Intune tenant, so
every Windows device you choose reports hardware, experience, and sustainability telemetry correlated
with your managed inventory.

## The problem
Intune and Endpoint Analytics report on startup, reliability, and apps — but they are **blind to the
hardware itself**: a battery degrading toward failure, thermal throttling, an SSD nearing end of life, a
component fault a software score never sees. **HP WXP** — the cloud DEX/analytics platform *formerly HP
TechPulse / Proactive Insights / Adaptive Endpoint Management* — closes that gap with hardware-level
telemetry, app-crash analytics, DEX scores, security signals, proactive/predictive support, and
sustainability / carbon-footprint reporting across HP and (increasingly) non-HP Windows devices. The
catch teams hit: the integration has **two halves** — deploy the agent *via Intune* **and** wire the
*Entra/Intune tenant connector* — and most never do both cleanly.

## Run it yourself — simpler, cheaper, and proven
- **Simpler** — exact, ordered Intune/Entra/WXP-console steps with full navigation paths; every object
  you create (the Win32 app `HP WXP Agent - Pilot`, the group `HP WXP - Pilot Devices`) is named and
  reused through testing and troubleshooting.
- **Cheaper** — one fixed price, not an open consulting meter; reusable on every wave and every new
  device fleet.
- **Tested** — a pilot-first method (**Assess → Configure → Pilot → Validate → Expand**) with explicit
  pass/fail gates and read-only validation scripts.

## What's inside
- **Solution Overview, Requirements, Implementation, Testing, Troubleshooting, Best Practices** — the
  complete click-by-click guide, honest about the specifics: the agent packaged as a Required Intune
  Win32 app with the enrollment code injected, the Entra admin-consent connector, and how WXP
  *complements* Microsoft Endpoint Analytics (cross-referenced, not rebuilt).
- **5 PowerShell scripts (Microsoft Graph)** — Discovery, Validation, Report (read-only), plus
  Remediation and Set-ScopeTargeting (default to `-WhatIf` preview). HP-renamed names are parameterized
  so you match your tenant.

## The repeatable way
Every solution follows the same repeatable shape, so each deployment feels familiar and low-risk — buy
once, reuse the playbook for the next wave and the next project.

## The bottom line
Every Windows device you choose reports hardware, experience, and sustainability telemetry into HP WXP,
correlated with your Intune inventory — deployed and proven on a pilot before you scale, without a
consulting engagement.

*An HP WXP subscription is a prerequisite you supply (edition/entitlements — verify with HP). Because HP
renamed this platform repeatedly, console paths, the agent filename, Graph scopes, the connector app
name, and network URLs are flagged "verify in the HP WXP admin console / your tenant" throughout — never
invented.*

*Delivered as a Word document and PDF, plus all PowerShell scripts in a single ZIP — yours to keep and
reuse across unlimited devices.*
