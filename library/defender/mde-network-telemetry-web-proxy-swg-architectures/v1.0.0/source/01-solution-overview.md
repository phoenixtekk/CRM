# 1. Solution Overview — Defender for Endpoint Network Telemetry in Web Proxy / SWG Architectures

## What this solution is
This is a **read-only telemetry-impact assessment** for Microsoft Defender for Endpoint (MDE) running alongside a **secure web gateway (SWG) that steers endpoint traffic through a local listener before egress** — the "loopback-forward" or "system-proxy" pattern used by agents such as iboss, Zscaler Client Connector, and generic PAC/loopback proxies. It measures how much of your endpoint **destination telemetry** the proxy is obscuring, documents which Defender features that affects, clarifies the X-Forwarded-For (XFF) question, drafts a supported-topology remediation for your change owners, and gives you a Microsoft advisory support-ticket template to get the authoritative answers.

It does **not** change the proxy, the SWG agent, or the tenant. Every script and step here **samples, measures, and reports**.

## How the technology behaves (why destination telemetry is lost)
The MDE sensor records network activity **as the endpoint's own network stack sees it** — into `DeviceNetworkEvents` (and related fields on `DeviceEvents`), with fields like `RemoteIP`, `RemoteUrl`, `RemotePort`, and `RemoteIPType`. Those fields answer "what did this process connect to?"

When an SWG agent runs a **local loopback listener** and steers traffic to it (via a PAC file that points at `127.0.0.1:<port>`, a system-proxy setting, or a route/loopback tunnel the agent installs), the sequence becomes:

1. The application (browser, updater, tool) opens its connection to the **local listener** — e.g. `127.0.0.1`, `::1`, or the agent's local proxy IP — **not** the true remote server.
2. The SWG agent inspects/filters the request and then makes the **real** outbound connection to the true remote, off-box or via its own tunnel.
3. The MDE sensor, watching the endpoint's stack, records the connection the *application* made — so `RemoteIP` is the **loopback/proxy address** and `RemoteUrl` is missing or reflects the local listener, **not** the true remote destination.

The result: the sensor faithfully records a connection that is **technically accurate but analytically useless** for destination-based analysis — every app looks like it "talked to localhost." The true remote destination lives in the **SWG's** logs, not the endpoint's. This is why the problem is invisible: nothing is broken, the device is protected, the sensor reports — but the *destination dimension* of endpoint network telemetry is flattened to the proxy.

**Exactly how, and how much, depends on the SWG's mode** (route-based tunnel vs system-proxy/loopback, whether specific destinations are excluded from steering, whether TLS is decrypted locally). Vendor console internals and the precise per-mode behavior are **vendor-specific and version-specific — confirm against current vendor and Microsoft guidance; this solution measures the observed effect in your tenant rather than asserting the cause.**

## Where this matters in the Defender stack
Any signal that reads the endpoint's record of the **true remote destination** is exposed:

- **`DeviceNetworkEvents` completeness & fidelity** — hunts and investigations that pivot on `RemoteIP` / `RemoteUrl` / `RemotePort` see loopback/proxy values instead of real destinations; network path reconstruction during IR is degraded.
- **SmartScreen** — reputation checks on URLs/downloads. Where the endpoint stack only ever sees the local listener, the destination-visibility SmartScreen and Network Protection rely on can be affected — *confirm current behavior with Microsoft.*
- **Network Protection** — blocks connections to malicious IPs/domains/URLs, including custom indicators and web content filtering. If the endpoint's outbound connection is to the loopback listener, whether Network Protection evaluates the **true** remote or the loopback destination is topology-dependent — *confirm with Microsoft.*
- **Threat-intelligence / custom indicator matching** — endpoint matching of IP / URL / domain indicators depends on the sensor seeing the true remote; obscured destinations can prevent endpoint-layer matches — *confirm with Microsoft.*
- **`DeviceNetworkEvents`-dependent detections** — built-in analytics and any custom detection rule keyed on remote destination inherit the same blind spot.

This solution **measures the first** (completeness/obfuscation is directly observable in your data) and **documents the rest as a feature-impact matrix flagged for Microsoft confirmation** — it does not assert Microsoft's definitive answer on SmartScreen / Network Protection / TI behavior under this topology.

## The X-Forwarded-For (XFF) clarification (in brief)
`X-Forwarded-For` is a **server-side HTTP request header**: a proxy adds it so the **destination server** learns the original client's IP. It flows *forward* (proxy → server) and helps **server-side** attribution — the destination's logs, a WAF, the SWG's own records. It is **not** a mechanism that feeds the true remote destination back into the **endpoint's** MDE telemetry. Section 03 and the dedicated XFF clarification reason through what XFF does and does not restore for endpoint-originated telemetry — **explicitly framed "confirm current behavior with Microsoft," not asserted as Microsoft's definitive position.**

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand.** Assess the environment and scope the device sample; configure the measurement queries and thresholds; pilot the read-only measurement on the sample ring; validate the completeness/obfuscation findings and the feature-impact matrix against explicit gates; then expand the assessment across the estate and open the Microsoft advisory case. Every step is read-only.

Applied here:
1. **Assess.** Confirm MDE plan/tables, identify the SWG agent and its steering mode (from your own config, not asserted), and scope a representative device sample.
2. **Configure.** Set the sample device group, the measurement window, and the loopback/proxy address set used to classify destinations.
3. **Pilot.** Run the read-only measurement on the sample ring — completeness of `DeviceNetworkEvents`, share of connections whose `RemoteIP` is loopback/proxy vs true remote, and which network tables are populated.
4. **Validate.** Confirm the findings against pass/fail gates, build the feature-impact matrix, and finalize the XFF clarification.
5. **Expand.** Roll the assessment across the estate, draft the supported-topology remediation for the change owners, and open the Microsoft advisory case to confirm the authoritative behavior.

## Scope
- **Read-only measurement** of `DeviceNetworkEvents` completeness and **destination obfuscation** (loopback/proxy vs true remote) across a device sample, and of which network Advanced Hunting tables are populated.
- A **feature-impact matrix** mapping SmartScreen, Network Protection, threat-intelligence indicator matching, and `DeviceNetworkEvents`-dependent detections to the proxy behavior — flagged for Microsoft confirmation.
- An **XFF clarification** — what XFF is, why it is server-side, and what it does/doesn't restore for endpoint telemetry (confirm-with-Microsoft framing).
- A **supported-topology remediation** — proxy mode, exclusions, and connector/deployment options for a supported MDE + SWG coexistence, authored as a plan for the customer's change process and flagged "verify against current Microsoft guidance."
- A **Microsoft advisory support-ticket template** (Severity C) with the exact validate-telemetry / document-feature-impact / XFF / architecture-review / advanced-hunting-schema asks.

## What is out of scope (cross-reference, don't duplicate)
- **Sensor-to-service connectivity** (can the MDE sensor reach the Defender cloud through the proxy; DNS/proxy/VPN reachability) — the **"Endpoint Network Connectivity Troubleshooting Toolkit"** (`NETDX`). *That is connectivity; this is telemetry visibility.*
- **Deploying, steering, and operating the SWG itself** — the **Netskope** line (`NSSWG` SWG deployment, `NSCASB` CASB, SSL/TLS inspection, traffic steering) and the SASE/SSE blueprint. This solution treats the SWG as a given and measures its telemetry effect.
- **The full MDE stand-up, tuning, and enablement** — the comprehensive **"Microsoft Defender for Endpoint"** solution (`MDEFULL`).
- **Cross-pillar XDR onboarding** (Identity, Office 365, Cloud Apps, Cloud) — **"Microsoft Defender XDR — Unified Onboarding"** (`DEFXDR`).
- **Changing SWG steering, applying the remediation, or accepting a telemetry tradeoff** — those are **decisions for the customer's network, security, and architecture owners**; this guide supplies the evidence and the options only.
- **Microsoft's authoritative determinations** — affected tables/fields, XFF behavior for endpoint telemetry, and the supported coexistence topology — are obtained via the advisory case, **not asserted here.**

## Connections and authentication used
- **Advanced hunting via Microsoft Graph Security** (`Microsoft.Graph` PowerShell modules, `POST /security/runHuntingQuery`) for all read-only measurement over `DeviceNetworkEvents`, `DeviceEvents`, `DeviceInfo`, `DeviceProcessEvents`, `AlertInfo`, `AlertEvidence`. Least-privilege scope: **`ThreatHunting.Read.All`** (plus `SecurityEvents.Read.All` and `Organization.Read.All` for context). No write scopes are used.
- The **unified Defender portal** (`security.microsoft.com` → **Hunting → Advanced hunting**, **Settings → Endpoints → Indicators / Advanced features**, **Assets → Devices**, **Custom detection rules**) for the manual enumeration steps (indicators, Network Protection state, custom detections) that are read-only checks.
- **Your SWG console** (iboss / Zscaler / other) is referenced **read-only** for identifying the steering mode and loopback/proxy address set — *its internals are vendor-specific; confirm against current vendor documentation.* This package never changes it.
- Least-privilege roles: **Security Reader** is sufficient for the read-only advanced-hunting and portal checks; no configuration role is required to run the assessment. Government-cloud tenants pass the matching Graph environment — *verify endpoints for your cloud.*

## Limitations (be honest with buyers)
- Advanced hunting and full `DeviceNetworkEvents` require **Defender for Endpoint P2** — *verify current plan-to-feature mapping and availability in your tenant.*
- This assessment **measures the observed telemetry effect**; it does **not** assert *why* a given SWG mode produces it (vendor-specific) or Microsoft's definitive feature behavior (confirm via the advisory case).
- Advanced-hunting tables retain a **limited window** (commonly ~30 days — *verify current retention*); the measurement reflects that window, not all history.
- Destination classification relies on the **loopback/proxy address set you provide** — an incomplete set understates obfuscation; the scripts make the set explicit and reviewable.
- The **remediation is a plan**, not an applied change — SWG mode changes trade filtering coverage against endpoint visibility and are a **customer decision** executed through their own change process.
- Restoring endpoint destination visibility does **not** replace the SWG's own logs, the sensor's connectivity, patching, or the SOC's investigation — it restores one dimension of endpoint network telemetry.
