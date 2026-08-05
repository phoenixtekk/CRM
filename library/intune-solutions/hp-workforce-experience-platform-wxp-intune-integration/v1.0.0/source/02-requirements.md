# 2. Requirements — HP Workforce Experience Platform (WXP) Integration with Microsoft Intune

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to integrating **HP
Workforce Experience Platform (WXP)** with Intune — the **agent-via-Intune** half and the
**Entra/Intune tenant-connector** half.

> **Scope reminder.** These requirements are for **integrating** WXP with Intune: deploying the WXP
> agent through Intune and connecting WXP to the Entra/Intune tenant. They assume you already have (or
> will supply) an **HP WXP subscription** — this package does not provide it. HP has renamed this
> platform repeatedly (**TechPulse / Proactive Insights / Adaptive Endpoint Management → Workforce
> Experience Platform**), so console-specific values are flagged **verify in the HP WXP admin console**.

## R1. Active HP Workforce Experience Platform (WXP) subscription
**Description:** A valid **HP WXP subscription/entitlement** for the devices you intend to onboard
(edition, seat count, and any non-HP-device coverage).
**Why:** WXP is a licensed HP cloud platform; the agent and connector only function against an active
WXP tenant. This package is the integration method, not the subscription.
**Verify:** Sign in to the **HP WXP admin console** and confirm an active subscription and available
seats. *(The console URL and exact edition names — **verify with HP / in the console**.)*
**Implement:** Obtain or activate an HP WXP subscription through your HP account team or reseller.
**Confirm the edition covers your device platforms and any non-HP Windows devices — verify with HP.**

## R2. Access to the HP WXP admin console (administrator)
**Description:** Administrative access to the HP WXP admin console to obtain the agent installer and the
**company / enrollment code**, and to initiate the Microsoft/Intune connection.
**Why:** Both integration halves start in the WXP console — you download the agent and read the
enrollment code there, and you launch the Entra admin-consent flow from there.
**Verify:** You can sign in to the HP WXP admin console with an administrator role and see device/admin
settings. *(Role names — **verify in the console**.)*
**Implement:** Have your HP WXP account owner grant you an administrator role in the WXP console.

## R3. HP WXP agent installer and enrollment code
**Description:** The **HP WXP agent installer** (MSI/EXE) and your tenant's **company / enrollment code**
(the value that binds an installed agent to *your* WXP tenant).
**Why:** The agent is what produces endpoint telemetry; the enrollment code registers each install to
your tenant. Without the code, agents install but do not report to your WXP tenant.
**Verify:** In the HP WXP admin console, locate the agent download and the enrollment/company code.
*(Exact menu location, installer filename, and the code's label — **verify in the console**.)*
**Implement:** Download the current agent installer from the WXP console and copy the enrollment code.
Record the **exact install and uninstall command lines** the vendor specifies (including how the
enrollment code is passed) — you will place these in the Intune Win32 app (Implementation Phase 2).

## R4. Windows endpoints enrolled in Intune
**Description:** The target devices are **Windows 10/11 endpoints enrolled in and managed by Intune**
(Global Requirement G4/G6).
**Why:** The agent is deployed as an Intune **Win32 app**, which only reaches enrolled, managed Windows
devices; the connector correlates against Intune-managed inventory.
**Verify:** Intune admin center (`https://intune.microsoft.com`) → **Devices → All devices**; the device
is listed, **managed**, and **compliant**.
**Implement:** Enroll the devices (Autopilot / Entra join + automatic enrollment). Device enrollment
itself is covered by the enrollment solutions and the Global Requirements.

## R5. Win32 app packaging tooling
**Description:** The **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`) to wrap the HP WXP
agent installer into an `.intunewin` package.
**Why:** Intune deploys Win32 apps from `.intunewin` packages; you must wrap the HP installer once.
**Verify:** You have `IntuneWinAppUtil.exe` available on your admin workstation.
**Implement:** Download the **Microsoft Win32 Content Prep Tool** from Microsoft's official GitHub
release and place it on your packaging workstation.

## R6. A reliable detection rule value for the agent
**Description:** A **detection method** that tells Intune the agent is installed — typically the
installed **MSI product code**, or a **file/registry** footprint of the agent.
**Why:** Without a correct detection rule, Intune cannot tell "installed" from "needs install," causing
repeated installs or false failures.
**Verify:** On a reference device where the agent is installed, confirm the MSI product code (or the
file path / registry key + version) that uniquely indicates the agent is present.
**Implement:** Install the agent once on a reference device, capture the product code (e.g. from
`Get-Package` / the uninstall registry) or the agent's install path, and use that as the Win32
detection rule. **Verify the exact value on your reference device — do not assume a product code.**

## R7. Entra Global Administrator for the connector consent
**Description:** A **Global Administrator** to grant admin consent when connecting HP WXP to the tenant.
**Why:** The WXP→Intune connection uses an Entra app-registration / admin-consent flow that grants WXP
read access to your device inventory; tenant-wide admin consent requires Global Administrator.
**Verify:** Entra (`https://entra.microsoft.com`) → **Roles and administrators** → confirm a
**Global Administrator** is available to perform the one-time consent.
**Implement:** Assign/schedule a Global Administrator to complete the consent step (Implementation
Phase 3). Reserve Global Administrator for this tenant-wide action.

## R8. HP WXP enterprise application / service principal (created by consent)
**Description:** The **enterprise application / service principal** that the admin-consent flow creates
in your tenant to represent HP WXP (this package refers to it as **`HP Workforce Experience`** — **the
exact display name varies; verify in your tenant**).
**Why:** This service principal is what holds the Graph permissions WXP uses to read your
Intune/Entra device inventory; its presence confirms the cloud connection was consented.
**Verify:** Entra → **Enterprise applications**; an application representing HP WXP exists after
consent. Or run `HPWXP-Discovery.ps1` with `-ConnectorAppName` set to the name shown in your tenant.
**Implement:** Complete the admin-consent flow from the HP WXP console (Implementation Phase 3); the
service principal is created on consent. **Confirm the display name in your tenant and pass it to the
scripts via `-ConnectorAppName`.**

## R9. Network access for the agent and the WXP cloud endpoints
**Description:** Outbound HTTPS from endpoints to the **HP WXP service endpoints**, plus the standard
Microsoft cloud endpoints (Global Requirement G7).
**Why:** The agent uploads telemetry to WXP; the connector talks cloud-to-cloud to Microsoft Graph.
Blocked endpoints mean no telemetry or a failed connection.
**Verify:** From a pilot device network, the agent can reach the HP WXP service URLs. *(The exact WXP
network endpoint URLs — **verify in HP's current documentation**; do not assume specific hostnames.)*
**Implement:** Allow HP's published WXP service URLs through proxy/firewall, and Microsoft's published
Microsoft 365/Intune/Graph URL ranges. **Do not TLS-inspect** endpoints the vendor lists as
inspection-sensitive.

## R10. Pilot group and pilot devices
**Description:** An Entra security group (`HP WXP - Pilot Devices`, Global Requirement G5) with at least
one enrolled Windows pilot device.
**Why:** Every solution is validated on a pilot before fleet rollout; the agent app is assigned to this
group first.
**Verify:** Entra → **Groups**; `HP WXP - Pilot Devices` exists and contains the pilot device(s).
**Implement:** Entra → **Groups → New group → Security**, name it **`HP WXP - Pilot Devices`**, and add
your pilot device(s) or their users.

## R11. (Awareness) Existing Microsoft Endpoint Analytics — keep it
**Description:** Awareness that WXP **complements**, and does not replace, Microsoft Endpoint Analytics.
**Why:** WXP adds hardware/sustainability/proactive-support telemetry; Endpoint Analytics remains the
Microsoft-native startup/reliability score. Removing Endpoint Analytics to "avoid overlap" would lose
the Microsoft-native signal.
**Verify:** Intune → **Reports → Endpoint analytics** is enabled (see the *Endpoint Analytics Deployment
& Optimization* solution).
**Implement:** Keep Endpoint Analytics enabled; run both. No change is required here — this is a
positioning reminder, not a configuration step.
