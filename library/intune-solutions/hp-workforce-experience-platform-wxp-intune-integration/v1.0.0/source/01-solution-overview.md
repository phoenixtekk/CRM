# 1. Solution Overview — HP Workforce Experience Platform (WXP) Integration with Microsoft Intune

## What this solution is
This solution **integrates the HP Workforce Experience Platform (WXP) with your Microsoft Intune
tenant**: it deploys the **HP WXP agent to Windows endpoints through Intune**, and it **connects the HP
WXP cloud platform to your Microsoft/Entra/Intune tenant** so WXP correlates your managed-device
inventory with its own telemetry. Once both halves are in place, the Windows devices you choose report
**hardware health, application performance, digital-experience (DEX) scores, security-posture signals,
and sustainability data** into HP WXP — and WXP can see which of those devices are Intune-managed.

## What HP WXP is (and its lineage — state this plainly)
**HP Workforce Experience Platform (WXP)** is HP's cloud **digital-employee-experience (DEX) and
endpoint analytics platform**. It is the current name for a product HP has **renamed repeatedly** — it
was **formerly HP TechPulse / HP Proactive Insights / HP Adaptive Endpoint Management**. If you have
existing HP endpoint reporting under any of those names, this is the same platform lineage.

WXP monitors and reports:

- **Device health & hardware telemetry** — battery health/wear, thermal behavior, SSD/drive health,
  memory, and component-level health signals that a software-only experience score cannot see.
- **Application performance & crashes** — app reliability, hangs, and crash analytics on the endpoint.
- **Digital-employee-experience (DEX) scores** — a composite view of how good the day-to-day experience
  actually is on each device.
- **Security-posture signals** — device security state indicators (surfaced for visibility; verify the
  exact signal set and any actioning in the HP WXP admin console).
- **Sustainability / carbon-footprint & device-lifecycle** reporting — energy/CO₂ estimates and
  device-age/lifecycle insight for refresh planning and ESG reporting.
- **Proactive/predictive support & self-heal** — WXP flags likely failures before they hit the user and
  can drive proactive remediation.

WXP supports **HP devices** and, **increasingly, non-HP Windows devices** — confirm current non-HP
coverage and any feature differences in HP's documentation for your subscription.

> **Scope, stated plainly.** This solution delivers **the integration method** — (1) deploy the WXP
> agent via Intune and (2) connect WXP to the Entra/Intune tenant — plus the operations to run it. It is
> **not** an HP WXP subscription (you supply that — see Requirements), it does **not** replace Microsoft
> Endpoint Analytics, and it does **not** rebuild the generic DEX-monitoring or Endpoint Analytics
> solutions in this catalog (it cross-references them). Everything HP-console-specific that HP may have
> renamed is flagged **verify in the HP WXP admin console / current HP documentation**.

## The two halves of the Intune integration
An HP WXP + Intune integration has **two distinct halves** — this package builds both, in order:

1. **Agent deployment via Intune (endpoint side).** WXP collects telemetry through an **agent installed
   on each Windows endpoint**. Rather than hand-installing it, you **package the HP-provided installer
   (MSI/EXE) as an Intune Win32 / line-of-business app**, inject your tenant's **company / enrollment
   code** (obtained from the HP WXP admin console) into the install command so the agent registers to
   *your* WXP tenant, set a detection rule, and assign it **Required** to your target devices. This is
   the same repeatable Win32-app pattern you already use for other agents.

2. **Tenant connector via Entra (cloud side).** WXP also connects **cloud-to-cloud** to your Microsoft
   tenant. From the **HP WXP admin console's Microsoft / Intune integration**, you initiate an **Entra
   app-registration / admin-consent** flow. Consenting creates an **enterprise application / service
   principal** in your tenant (this package refers to it as `HP Workforce Experience` — **the exact
   display name varies; verify it in your tenant**) that grants WXP **read access to your Intune/Entra
   device inventory via Microsoft Graph**. This lets WXP correlate its telemetry with your managed-device
   data and, where you enable it, surface or action against those devices.

You need **both** halves for the full picture: the agent produces the deep hardware/experience
telemetry; the connector ties that telemetry to your Intune-managed inventory.

## How it works, step by step
1. **Obtain WXP tenant details.** In the **HP WXP admin console**, confirm your subscription and obtain
   the **agent installer** and your **company / enrollment code** (the value that binds an installed
   agent to your WXP tenant — **name/location verify in the console**).
2. **Package the agent as an Intune Win32 app.** Wrap the installer with the Microsoft Win32 Content
   Prep Tool into an `.intunewin`, then add it in Intune as **Windows app (Win32)** named
   `HP WXP Agent - Pilot`, with the install command carrying your enrollment code, a matching uninstall
   command, and a **detection rule** (installed MSI product code, or the agent's file/registry
   footprint — **verify the exact detection value on a reference device**).
3. **Assign the agent Required to the pilot group.** Assign `HP WXP Agent - Pilot` **Required** to the
   `HP WXP - Pilot Devices` Entra security group so it installs automatically on pilot devices.
4. **Connect WXP to the tenant.** From the HP WXP admin console's Microsoft/Intune integration, run the
   **Entra admin-consent** flow (a Global Administrator consents once) to create the `HP Workforce
   Experience` enterprise application granting Graph read access to your device inventory.
5. **Devices report into WXP.** Pilot devices install the agent, register to your WXP tenant, and begin
   reporting hardware/experience/sustainability telemetry; the connector correlates them with your
   Intune inventory.
6. **Validate, then expand.** Confirm install coverage and the connection with the included scripts,
   then widen the app assignment in waves.

## How WXP complements Microsoft Endpoint Analytics and generic DEX monitoring
- **Microsoft Endpoint Analytics** remains the **Microsoft-native** DEX signal — startup performance,
  reliability, Work-From-Anywhere, and (with connectors) app reliability, computed from Intune-managed
  devices. It is software/OS-centric. *(See the catalog's **Endpoint Analytics Deployment &
  Optimization** solution — this package does not rebuild it.)*
- **HP WXP adds what Endpoint Analytics does not**: **hardware-level telemetry** (battery/thermal/SSD
  and component health), **sustainability/CO₂** and lifecycle reporting, and **cross-vendor proactive
  support / self-heal** driven by HP's fleet intelligence.
- **Generic DEX monitoring** (see the catalog's **Endpoint Health & Digital Experience Monitoring**
  solution) provides a vendor-neutral health/experience view. WXP is the **HP-specific** DEX layer with
  hardware depth.
- **Many organizations run both Endpoint Analytics and WXP** — Endpoint Analytics for the
  Microsoft-native score, WXP for hardware/sustainability/proactive support. This solution positions WXP
  as an **addition** to your existing Microsoft-native monitoring, not a replacement.

## Benefits
- **See the hardware, not just the score** — battery, thermal, SSD, and component health that
  Endpoint Analytics cannot surface, so you replace failing devices before they fail the user.
- **Sustainability & lifecycle reporting** — energy/CO₂ and device-age insight for ESG reporting and
  refresh planning.
- **Deployed the Intune way** — the agent ships as a standard **Required Win32 app**; no manual touch,
  and reversible by unassigning the app.
- **Correlated with your inventory** — the Entra connector ties WXP telemetry to your Intune-managed
  devices for a single, correlated view.
- **Proactive/predictive support** — WXP's fleet intelligence flags likely failures and can drive
  self-heal, reducing tickets.

## Limitations (be honest with buyers)
- **HP WXP subscription required.** This package is the **integration method**; you must have an active
  **HP WXP subscription/entitlement** (edition, seat count, non-HP coverage — **verify with HP**). It
  does not include or provision the WXP subscription.
- **Windows-first agent.** The agent-via-Intune half targets **Windows** endpoints. Confirm platform
  coverage (and any macOS/mobile capability) in HP's current documentation.
- **HP-renamed specifics vary.** The **console menu names, agent installer filename, enrollment-code
  label, connector app display name, Graph scopes granted, and WXP network endpoint URLs** reflect a
  fast-renamed product — **verify each against the HP WXP admin console / current HP documentation and
  your tenant** before fleet rollout. This package flags them rather than asserting them as fixed.
- **Not a replacement for Endpoint Analytics.** WXP complements Microsoft-native monitoring; keep
  Endpoint Analytics if you rely on the Microsoft score.
- **Connector requires Global Admin consent.** The Entra admin-consent step is a one-time
  **Global Administrator** action.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **The HP WXP agent is deployed to Windows endpoints as a Required Intune Win32 app carrying the
> tenant's enrollment code, and the HP WXP platform is connected to the Entra/Intune tenant via an
> admin-consented enterprise application — deployed pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
