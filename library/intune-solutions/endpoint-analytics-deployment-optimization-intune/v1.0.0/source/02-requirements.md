# 2. Requirements — Endpoint Analytics Deployment & Optimization in Microsoft Intune

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, supported OS, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to standing up
**Endpoint Analytics**, getting devices to report telemetry, baselining, and interpreting the scores.

> **Licensing, feature availability, and national-cloud specifics change.** Where this document names a
> license, a portal path, or a service endpoint, treat it as a starting point and **verify against
> current Microsoft documentation** for your plan and cloud (Commercial vs. GCC / GCC High / DoD)
> before you rely on it.

## R1. An Endpoint Analytics–capable license
**Description:** A Microsoft license/plan that includes **Endpoint Analytics** for your managed devices.
**Why:** Endpoint Analytics is a licensed Intune capability; without an entitling plan the node is
unavailable or limited.
**Verify:** In the Intune admin center, open **Reports → Endpoint analytics** and confirm the node
loads and is not blocked by a licensing message. **Verify the exact entitling SKUs against current
Microsoft documentation** — do not assume a specific bundle grants it.
**Implement:** Assign the entitling license (commonly delivered via Microsoft 365 / Intune plans —
**confirm the current requirement with Microsoft**) to the devices/users in scope, then re-open the node.

## R2. Devices enrolled / co-managed in Intune
**Description:** The Windows devices you want scored are **Intune-enrolled** or **co-managed**
(Configuration Manager + Intune).
**Why:** Endpoint Analytics collects its telemetry through the Intune management channel; only managed
devices report scores. (Co-managed devices can be onboarded via Configuration Manager — **verify the
current co-management onboarding path against Microsoft documentation**.)
**Verify:** Intune → **Devices → All devices**; the target Windows devices appear and are managed.
**Implement:** Enroll the devices in Intune (or onboard the Configuration Manager collection for
co-management) before expecting scores. See Global Requirement **G4**.

## R3. Supported, current Windows edition/version
**Description:** A supported Windows edition and version on the devices in scope.
**Why:** Startup performance, Work-From-Anywhere, and resource metrics assume a supported, patched
Windows build; unsupported builds report partial or no data and drag the WFA score down.
**Verify:** Intune → **Devices → (device) → Hardware** shows the edition/version; or check
**Settings → System → About** on the device. **Confirm the currently supported Windows versions for
Endpoint Analytics against Microsoft documentation.**
**Implement:** Bring devices to a supported Windows version with your update policy before baselining.

## R4. The Endpoint Analytics data-collection policy
**Description:** An Endpoint Analytics **data-collection policy** created in Intune and **assigned** to
the device group in scope.
**Why:** This policy is what tells enrolled devices to **collect and submit** the experience telemetry
that produces the scores. No assigned data-collection policy → no data → blank scores.
**Verify:** Intune → **Reports → Endpoint analytics → Settings** (data collection) shows collection
configured and assigned to your scope group. **Confirm the current Settings/blade name against Microsoft
documentation** (portal wording changes).
**Implement:** Create and assign it in Implementation §3 (**named `EPA – Data Collection – Pilot`**),
or run `ENDPTAN-Set-DataCollection.ps1` (defaults to `-WhatIf`).

## R5. A scoped device group (pilot, then fleet)
**Description:** A Microsoft Entra security group of the Windows devices to collect from — a small
**pilot** group first, then a **fleet** group.
**Why:** The data-collection policy is assigned to a group; piloting to a small group first proves data
flows and lets you read a baseline before you turn on the whole estate.
**Verify:** Entra → **Groups**; `EPA – Pilot Devices` exists with the pilot devices as members.
**Implement:** Create it in Implementation §2. (See Global Requirement **G5** for the pilot-group pattern.)

## R6. Telemetry / diagnostic data settings permit collection
**Description:** Windows **diagnostic data** settings on the devices allow Endpoint Analytics to collect
what it needs.
**Why:** Endpoint Analytics depends on Windows telemetry; if diagnostic data is turned off or set below
the level the feature requires, devices will not report complete scores.
**Verify:** Check the device's diagnostic-data configuration (via your configuration profiles or
**Settings → Privacy & security → Diagnostics & feedback**). **Confirm the exact diagnostic-data level
Endpoint Analytics requires against current Microsoft documentation** — do not hard-code a level.
**Implement:** Assign a configuration profile that sets diagnostic data to the level Microsoft currently
documents for Endpoint Analytics, to the same scope group.

## R7. Network access to the analytics/telemetry endpoints
**Description:** Outbound HTTPS from managed devices to the Microsoft **Intune** service endpoints
**and** the **Windows diagnostic-data / Endpoint Analytics telemetry endpoints**.
**Why:** Devices submit their experience telemetry to Microsoft's service; if the telemetry endpoints
are blocked at the proxy/firewall, scores stay blank even though the policy is assigned.
**Verify:** From a managed device, confirm reachability of the Microsoft telemetry/diagnostic endpoints
and the Intune endpoints. **Get the current endpoint list from Microsoft's published documentation** —
the diagnostic-data endpoints are a distinct set from the core Intune URLs.
**Implement:** Allow the Microsoft-published diagnostic-data + Intune endpoint ranges through
proxy/firewall. See Global Requirement **G7**.

## R8. Administrative rights to Endpoint Analytics
**Description:** An operator with rights to read Endpoint Analytics reports and to create/assign the
data-collection and configuration policies.
**Why:** Enabling data collection and creating policies requires Intune administrative permissions;
reading scores requires at least reporting access.
**Verify:** Sign in to Intune and confirm you can open **Reports → Endpoint analytics** and create
policies under **Devices → Configuration**.
**Implement:** Assign the operator **Intune Administrator** (or a suitable Endpoint Analytics/reporting
role — **verify the current role names and scopes against Microsoft documentation**). See Global
Requirement **G3**.

## R9. (If co-managed) Configuration Manager onboarding for Endpoint Analytics
**Description:** For **co-managed** devices, the Configuration Manager side is onboarded to Endpoint
Analytics.
**Why:** Co-managed devices can contribute Endpoint Analytics data via Configuration Manager; this
requires the ConfigMgr environment to be connected/onboarded.
**Verify:** In the Configuration Manager console, confirm Endpoint Analytics onboarding is configured.
**Confirm the current co-management onboarding steps and prerequisites against Microsoft documentation.**
**Implement:** Onboard Configuration Manager to Endpoint Analytics per Microsoft's current guidance
(cloud attach / co-management), then confirm the collection is reporting.

## R10. National-cloud confirmation (GCC / GCC High / DoD)
**Description:** If you operate in a **US-sovereign / national cloud**, confirm Endpoint Analytics
availability, feature parity, and the correct portal/service endpoints for that cloud.
**Why:** Feature availability, rollout timing, and endpoint URLs can differ between Commercial and
Government clouds; a Commercial procedure can be wrong for GCC High/DoD.
**Verify:** Confirm the Endpoint Analytics feature set and the correct admin portal
(e.g. `endpoint.microsoft.us` for some Government tenants) **against Microsoft's US-sovereign-cloud
documentation** — do not assume Commercial parity.
**Implement:** Use the national-cloud portal and endpoint set Microsoft documents for your cloud;
where a capability is delayed or absent, note it and plan around it. **Verify before each deployment.**
