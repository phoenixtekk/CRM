# Executive Summary — HP Workforce Experience Platform (WXP) Integration with Microsoft Intune

IT teams running Microsoft Intune already have startup, reliability, and application data through
**Endpoint Analytics** — but they are **blind to what the hardware itself is telling them**: a battery
degrading toward failure, thermal throttling, an SSD nearing end of life, or a component fault that a
device experience score never sees. **HP's Workforce Experience Platform (WXP)** — the cloud
digital-employee-experience (DEX) and endpoint analytics platform **formerly known as HP TechPulse /
HP Proactive Insights / HP Adaptive Endpoint Management** — closes that gap by adding **hardware-level
telemetry**, application-crash and performance analytics, DEX scoring, security-posture signals,
proactive/predictive support with self-heal, and **sustainability / carbon-footprint and
device-lifecycle** reporting across HP and (increasingly) non-HP Windows devices.

This solution is the **method to integrate HP WXP with your Microsoft Intune tenant end to end** — so a
single administrator can deploy the agent and wire the tenant connection without a consulting
engagement. It has **two halves, and this package does both**:

- **Deploy the HP WXP agent through Intune.** Package the HP-provided installer as an Intune
  **Win32/line-of-business app** (`HP WXP Agent - Pilot`), inject your tenant's company/enrollment code
  from the HP WXP admin console into the install command, and assign it **Required** to a pilot group
  (`HP WXP - Pilot Devices`) — so devices onboard to WXP automatically, the Intune way.
- **Connect HP WXP to your Microsoft/Entra/Intune tenant.** From the HP WXP admin console's
  Microsoft/Intune integration, run the **Entra app-registration / admin-consent** flow that grants WXP
  read access to your Intune/Entra device inventory (Microsoft Graph), so WXP correlates managed-device
  data with its own telemetry — and, where enabled, surfaces and actions it.

**How it fits what you already run.** WXP **complements Microsoft Endpoint Analytics** rather than
replacing it: Endpoint Analytics stays the Microsoft-native startup/reliability/Work-From-Anywhere
score; WXP adds HP hardware telemetry, sustainability/CO₂, and cross-vendor proactive support. Many
organizations run both. This package **cross-references** the existing *Endpoint Analytics Deployment &
Optimization* and *Endpoint Health & Digital Experience Monitoring* solutions — it does **not** rebuild
them.

The package delivers the complete, field-tested method — written so a competent admin can follow it end
to end:

- **Agent-via-Intune, done right.** Exact steps to build the named Win32 app, inject the enrollment
  code, set a reliable detection rule, and assign it **Required** to the pilot group — deployed
  pilot-first and reversible by unassigning the app.
- **Tenant connector, done right.** The Entra admin-consent flow initiated from the HP WXP console,
  what the resulting enterprise application (`HP Workforce Experience`) is for, and how to verify the
  connection reports devices back into WXP.
- **Validate with scripts.** Five ready-to-run PowerShell scripts (Microsoft Graph) confirm the agent
  app is present and assigned, report per-device install coverage, check for the connector service
  principal, and remediate gaps safely.

Because HP renamed this product repeatedly, **console paths, the agent installer filename, Graph
permission scopes, the connector application's display name, and network endpoint URLs vary** — this
package flags each of those **"verify in the HP WXP admin console / current HP documentation"** or
**"verify in your tenant"** rather than inventing specifics. An **HP WXP subscription/licensing is a
prerequisite you supply** (edition and entitlements — verify with HP).

**Outcome:** every Windows device you choose reports hardware, experience, and sustainability telemetry
into HP WXP, correlated with your Intune inventory — deployed and proven on a pilot before you scale,
following the standard repeatable shape: **Assess → Configure → Pilot → Validate → Expand.**
