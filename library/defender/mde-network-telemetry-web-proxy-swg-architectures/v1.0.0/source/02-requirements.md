# 2. Requirements — Defender for Endpoint Network Telemetry in Web Proxy / SWG Architectures

The category-level prerequisites (tenant, Defender licensing, admin roles, onboarding reach, service-endpoint network access, a pilot ring, Log Analytics workspace where used, and response governance) are in the separate **Global Requirements — Defender** file published with this solution. **Do not repeat them; confirm them there first.** This section lists only the prerequisites **specific to this read-only telemetry assessment**. Each item: **Description / Why required / How to verify / How to implement if missing.**

---

## R1. Defender for Endpoint P2 with Advanced Hunting available
**Description:** MDE **P2** so `DeviceNetworkEvents` and the advanced-hunting API are available.
**Why required:** The entire measurement runs over advanced-hunting tables via Graph Security; P1 does not expose the full hunting surface this assessment reads. *Verify current plan-to-feature mapping and availability in your tenant.*
**How to verify:** In `security.microsoft.com` → **Hunting → Advanced hunting**, run `DeviceNetworkEvents | take 1`. Rows return on P2.
**How to implement if missing:** Assign Defender for Endpoint P2 (often bundled in M365 E5 / E5 Security) to the assessed devices' users/devices, then allow warm-up before measuring.

## R2. Onboarded devices behind the SWG, with warmed-up telemetry
**Description:** A population of MDE-onboarded devices that actually sit **behind the loopback/forward SWG** and have been reporting for long enough to fill the hunting window.
**Why required:** You can only measure obfuscation on devices whose traffic the proxy steers; freshly onboarded devices have no history to sample.
**How to verify:** Run `MDEPROXY-Discovery.ps1` — it reports onboarded devices, `DeviceNetworkEvents` freshness, and which network tables are populated. Confirm the sample devices are the ones running the SWG agent.
**How to implement if missing:** Onboard the devices (cross-reference the `MDEFULL` / `DEFXDR` onboarding solutions), confirm the SWG agent is active on them, and allow reporting warm-up (commonly a few days) before assessing.

## R3. Security Reader (read-only) access to advanced hunting
**Description:** The **Security Reader** role (or higher) for the account running the scripts, with consent to the read-only Graph scopes.
**Why required:** All measurement is read-only advanced hunting; no configuration role is needed to run the assessment. Keeping to Security Reader enforces the read-only posture.
**How to verify:** Sign in and run `DeviceNetworkEvents | take 1` in Advanced hunting; run `MDEPROXY-Discovery.ps1` and confirm it connects with `ThreatHunting.Read.All`.
**How to implement if missing:** Assign **Security Reader** in Entra → **Roles and administrators**; grant admin consent to the read scopes (`ThreatHunting.Read.All`, `SecurityEvents.Read.All`, `Organization.Read.All`) on first `Connect-MgGraph`.

## R4. Identification of the SWG agent and its steering mode
**Description:** Know **which** SWG is in play (iboss, Zscaler Client Connector, generic PAC/loopback) and **how** it steers — route-based tunnel vs system-proxy/loopback, and whether specific destinations are excluded.
**Why required:** The steering mode determines whether — and how much — destination telemetry is obscured, and it frames the remediation options. This is read from **your own** configuration; vendor internals are not asserted here.
**How to verify:** From the SWG agent/console (read-only) and endpoint config: check the system proxy / PAC (`netsh winhttp show proxy`, the PAC URL, the agent's tunnel mode). Note the local listener address(es).
**How to implement if missing:** Work with the network/SWG owner to document the current mode and the loopback/proxy address set. *Confirm the mode's exact behavior against current vendor documentation — this solution measures the effect rather than asserting the cause.*

## R5. The loopback / proxy address set for destination classification
**Description:** The list of addresses the SWG uses locally — loopback (`127.0.0.0/8`, `::1`), any link-local/private proxy IP, and the agent's local listener IP/port — used to classify a `RemoteIP` as "obscured (proxy/loopback)" vs "true remote."
**Why required:** The obfuscation measurement classifies each connection's destination against this set; an incomplete set understates the impact.
**How to verify:** Confirm the address set with the SWG owner and pass it to `MDEPROXY-Validate.ps1` (`-ProxyAddressSet`); the script echoes the set it used so the classification is reviewable.
**How to implement if missing:** Derive the set from the PAC/system-proxy/agent config (R4). Default to loopback + RFC1918 as a conservative starting set, then refine with the SWG owner. *Document any address you include so the report is defensible.*

## R6. Microsoft Graph PowerShell modules (Microsoft.Graph)
**Description:** The `Microsoft.Graph` PowerShell modules (Authentication + Security) on the workstation running the scripts.
**Why required:** The `.ps1` scripts call `POST /security/runHuntingQuery` and read context via Graph.
**How to verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication`. The scripts also install on first run.
**How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` (the scripts do this automatically on first run if absent).

## R7. A device sample definition (the assessment ring)
**Description:** A named, representative set of behind-the-SWG devices to measure first — the object **`MDEPROXY Device Sample – Proxy Ring – Assess`** used throughout the guide, scripts, and tests.
**Why required:** The pattern is pilot-first: measure a representative ring, validate the findings, then expand across the estate. It also bounds the hunting queries.
**How to verify:** Confirm the device list (by device name / device group / tag) exists and matches the SWG-steered population; `MDEPROXY-Discovery.ps1 -Sample` echoes it.
**How to implement if missing:** Define the sample by an existing Defender device group or device tag (e.g. devices tagged for the SWG rollout), or supply an explicit device-name list to the scripts. Keep it representative of OS mix and site.

## R8. A Microsoft support entitlement for the advisory case
**Description:** A support plan that lets you open a Microsoft **advisory (Severity C)** case for Defender for Endpoint.
**Why required:** The authoritative answers (affected tables/fields, XFF behavior for endpoint telemetry, supported coexistence topology) come from Microsoft via the advisory case — this solution supplies the template, not the answers.
**How to verify:** In `admin.microsoft.com` → **Support → New service request** (or the Defender portal's **Help → Support**), confirm you can open a case for the Defender/Endpoint product.
**How to implement if missing:** Confirm the tenant's support entitlement (Unified/Premier/Professional). *Advisory (Sev C) is appropriate — this is a how-does-it-behave / architecture-review question, not a production outage.*

## R9. (Optional) Log Analytics / SIEM export for longer-window analysis
**Description:** Where you need to look **beyond** the advanced-hunting retention window, a continuous export of the device tables to Log Analytics / your SIEM.
**Why required:** Advanced-hunting retention is limited (*verify current retention*); a SIEM export lets you measure obfuscation over a longer period or historically.
**How to verify:** Confirm a streaming API / continuous export of `DeviceNetworkEvents` exists and is queryable (cross-reference the `WSKQL` advanced-KQL solution for the query patterns).
**How to implement if missing:** This is optional — the in-portal window is sufficient for the standard assessment. Configure continuous export only if longer-window analysis is required.
