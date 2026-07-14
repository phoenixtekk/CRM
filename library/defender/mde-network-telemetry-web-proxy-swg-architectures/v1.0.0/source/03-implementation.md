# 3. Implementation — Defender for Endpoint Network Telemetry in Web Proxy / SWG Architectures

This is a **read-only assessment**. Nothing here changes the SWG, the SWG agent, the endpoints, or the tenant. Follow the steps in order. Every object you create is a **document, sample, or case** — named with the convention **`<Purpose> – <Scope> – <Stage>`** and reused verbatim in later steps, the Testing Guide, and the scripts. Portal navigation paths are current as of authoring — *if a menu has moved, confirm the current path in the Defender portal.*

**Objects you will create (names are fixed — reuse exactly):**
- `MDEPROXY Device Sample – Proxy Ring – Assess` — the representative behind-the-SWG device set.
- `MDEPROXY Proxy Address Set – Tenant – Assess` — the loopback/proxy addresses used to classify destinations.
- `MDEPROXY Telemetry Baseline – Proxy Ring – Pilot` — the measured completeness/obfuscation baseline.
- `MDEPROXY Feature-Impact Matrix – Tenant – Validate` — features mapped to the proxy behavior.
- `MDEPROXY XFF Clarification – Tenant – Validate` — the X-Forwarded-For write-up.
- `MDEPROXY Remediation Plan – Tenant – Expand` — the supported-topology options for the change owners.
- `MDEPROXY Advisory Case – Microsoft – Expand` — the Severity C support ticket.
- `MDEPROXY Assessment Report – Tenant – Validate` — the compiled evidence package.

---

## Stage 1 — Assess (environment + sample)

### Step 1.1 — Confirm the read-only prerequisites
Confirm **R1–R7** from the Requirements Guide. In `security.microsoft.com` → **Hunting → Advanced hunting**, run `DeviceNetworkEvents | take 1` to confirm P2 + hunting access.

### Step 1.2 — Run read-only discovery
On the assessment workstation:
```
powershell -ExecutionPolicy Bypass -File .\MDEPROXY-Discovery.ps1
```
It connects read-only (`ThreatHunting.Read.All`), reports the signed-in context and MDE plan hints, lists onboarded devices, checks **`DeviceNetworkEvents` freshness**, and reports **which network Advanced Hunting tables are populated** (`DeviceNetworkEvents`, `DeviceEvents`, `DeviceInfo`, `DeviceProcessEvents`). Confirm the tables are fresh before measuring.

### Step 1.3 — Identify the SWG steering mode (read-only)
From your **own** endpoint/SWG configuration (not asserted here):
- Windows system proxy: `netsh winhttp show proxy` and the WinINET/PAC settings.
- The PAC URL / file, and whether it points traffic at a **local listener** (e.g. `127.0.0.1:<port>`).
- The SWG agent's **tunnel mode** (route-based tunnel vs system-proxy/loopback) and any **steering exclusions**, read from the agent/console.

Record the mode in `MDEPROXY Remediation Plan – Tenant – Expand` (Stage 5). *Confirm the mode's exact behavior against current vendor documentation — this assessment measures the effect, not the cause.*

### Step 1.4 — Define the device sample
Create **`MDEPROXY Device Sample – Proxy Ring – Assess`** — a representative set of behind-the-SWG devices (by Defender device group, device tag, or an explicit device-name list), covering your OS mix and sites. Keep it small enough to reason about, representative enough to trust.

### Step 1.5 — Assemble the proxy address set
Create **`MDEPROXY Proxy Address Set – Tenant – Assess`** — the loopback/proxy addresses (from Step 1.3): loopback (`127.0.0.0/8`, `::1`), the agent's local listener IP(s), and any private proxy IP. This set classifies a connection's `RemoteIP` as **obscured (proxy/loopback)** vs **true remote**. Document every address you include so the classification is defensible.

---

## Stage 2 — Configure (measurement parameters)

### Step 2.1 — Set the measurement window and thresholds
Decide the lookback window (default 7 days, within the hunting retention — *verify current retention*) and the **obfuscation threshold** that constitutes a finding (e.g. "≥ X% of outbound connections resolve to the proxy address set"). Record these in the report header.

### Step 2.2 — Stage the KQL query pack
Open `MDEPROXY-Hunt.kql` in **Advanced hunting**. It contains the read-only measurement queries used in Stage 3 (destination-obfuscation share, `DeviceNetworkEvents` completeness, table population, and network-dependent detection coverage). Confirm each query parses against your tenant's schema; adjust table/column names only if your schema differs.

---

## Stage 3 — Pilot (measure the sample, read-only)

### Step 3.1 — Measure destination obfuscation
Run:
```
powershell -ExecutionPolicy Bypass -File .\MDEPROXY-Validate.ps1 `
  -Sample "MDEPROXY Device Sample – Proxy Ring – Assess" `
  -ProxyAddressSet @('127.0.0.0/8','::1','<local-listener-ip>') `
  -Days 7
```
It measures, over the sample and window: the **share of outbound `DeviceNetworkEvents` whose `RemoteIP` falls in the proxy address set** (obscured) vs a true remote, the count of connections with **missing/empty `RemoteUrl`**, and the per-device distribution. It echoes the address set it used and writes `MDEPROXY Telemetry Baseline – Proxy Ring – Pilot`. **Read-only.**

### Step 3.2 — Measure `DeviceNetworkEvents` completeness and table population
Still read-only, `MDEPROXY-Validate.ps1 -Check Completeness` (and the `MDEPROXY-Hunt.kql` completeness queries) report: whether `DeviceNetworkEvents` is populated for each sample device, the ratio of network events to process events (a low ratio can indicate suppressed/flattened network telemetry), and which of the network tables return rows. Record gaps against the baseline.

### Step 3.3 — Enumerate network-dependent features and detections
Run:
```
powershell -ExecutionPolicy Bypass -File .\MDEPROXY-FeatureImpact.ps1 `
  -Sample "MDEPROXY Device Sample – Proxy Ring – Assess"
```
It enumerates, read-only: **custom detection rules** and **hunting queries** that reference `RemoteIP` / `RemoteUrl` / `RemotePort` (directly exposed to obfuscation), and the **custom TI indicators** of type **IP / URL / domain** (whose endpoint-layer matching depends on true-remote visibility). It also lists the portal-only checks for **Network Protection** and **SmartScreen** state. Output seeds the feature-impact matrix.

---

## Stage 4 — Validate (findings, matrix, XFF)

### Step 4.1 — Build the feature-impact matrix
Create **`MDEPROXY Feature-Impact Matrix – Tenant – Validate`** from the Stage 3 output. Use this structure — the **"Confirm with Microsoft"** column is mandatory and must not be pre-answered:

| Feature / signal | Depends on true-remote destination? | Observed effect in this tenant (from measurement) | Confirm with Microsoft |
|---|---|---|---|
| `DeviceNetworkEvents` (`RemoteIP`/`RemoteUrl`/`RemotePort`) | Yes — directly | **Measured**: % obscured to proxy/loopback; missing `RemoteUrl` count | Confirm authoritative `RemoteIP`/`RemoteUrl` semantics when a local proxy is present |
| Hunts / custom detections pivoting on remote destination | Yes — inherit the above | List of affected rules/queries (from `MDEPROXY-FeatureImpact.ps1`) | Confirm which built-in detections read endpoint remote-destination |
| SmartScreen (URL/download reputation) | Reputation on destination | Configuration state noted (portal check) | **Confirm** whether/how loopback-forward steering affects SmartScreen evaluation |
| Network Protection (IP/URL/domain block, web content filtering, custom indicators) | Yes — evaluates destination | Configuration state + indicator inventory noted | **Confirm** whether NP evaluates the true remote or the loopback destination under this topology |
| Threat-intelligence indicator matching (IP/URL/domain) | Yes — endpoint-layer match | Count of IP/URL/domain indicators that may not match | **Confirm** endpoint-layer TI matching behavior with a local proxy |

Fill the **"Observed effect"** column from your measurement; leave **"Confirm with Microsoft"** as the open question carried into the advisory case. **Do not invent Microsoft's answer.**

### Step 4.2 — Author the XFF clarification
Create **`MDEPROXY XFF Clarification – Tenant – Validate`** using the section below verbatim as its basis. Keep the confirm-with-Microsoft framing intact.

> **X-Forwarded-For (XFF) — what it is, and what it does / does not restore for endpoint telemetry**
>
> **What XFF is.** `X-Forwarded-For` is an **HTTP request header** added by a forward or reverse proxy so that the **destination server** can learn the **original client's IP address** even though the connection reaching it comes from the proxy. It is a **server-side** attribution mechanism: it flows *forward*, from proxy toward the destination, and it is read by the **destination server, its load balancer, WAF, or application logs** — and by the SWG's own logs.
>
> **The direction that matters here.** The telemetry problem in this solution is on the **endpoint** side: the MDE sensor records the connection the *application* made — to the **local loopback listener** — so the endpoint's `DeviceNetworkEvents` shows the proxy/loopback as `RemoteIP` and often has no true `RemoteUrl`. XFF addresses the **opposite** direction of the flow (letting the *far* server identify the *client*); it is carried **inside the request the SWG sends onward**, not injected back into the endpoint's own network-stack records.
>
> **What XFF therefore does.** It restores **client-IP visibility at the destination and in server-side logs** — useful for the SWG's records, the destination's logs, and any server-side investigation. It is genuinely valuable, but for **server-side** attribution.
>
> **What XFF does not (appear to) do for endpoint telemetry.** Because XFF is a header in the outbound request rather than a feedback path into the endpoint sensor, it is **not expected to repopulate the true remote destination into the endpoint's `DeviceNetworkEvents`** (`RemoteIP` / `RemoteUrl`). In other words, XFF helps the *server* know the *client*; it does not, on its face, help the *endpoint* record the *true server*. **This is our reasoning about the mechanism, not Microsoft's definitive statement — confirm the current behavior with Microsoft** (it is one of the explicit asks in the advisory case, Step 5.3). Do **not** present this as Microsoft's confirmed position until the case returns.

### Step 4.3 — Compile the assessment report
Run:
```
powershell -ExecutionPolicy Bypass -File .\MDEPROXY-Report.ps1 `
  -BaselinePath ".\MDEPROXY-telemetry-baseline.json"
```
It compiles **`MDEPROXY Assessment Report – Tenant – Validate`** — the measurement summary (obfuscation %, completeness, table population), the feature-impact matrix, the XFF clarification, and the open questions for Microsoft. **Read-only; it only reads the saved measurement outputs.**

---

## Stage 5 — Expand (estate assessment + remediation plan + advisory case)

### Step 5.1 — Expand the measurement across the estate
Re-run `MDEPROXY-Validate.ps1` and `MDEPROXY-FeatureImpact.ps1` against a broader device set (or your continuous-export/SIEM copy for a longer window, R9). Compare against `MDEPROXY Telemetry Baseline – Proxy Ring – Pilot` to confirm the sample was representative.

### Step 5.2 — Draft the supported-topology remediation (plan only)
Create **`MDEPROXY Remediation Plan – Tenant – Expand`** as a set of **options for the customer's network/security/architecture owners** — this package does **not** apply any of them. **Flag every option "verify against current Microsoft guidance"** and record the security tradeoff.

Options to document (verify each against current Microsoft and vendor guidance — do not assert):
1. **Steering mode.** Evaluate whether the SWG can run in a **route-based / tunnel mode** where the endpoint's network stack still egresses to the **true remote** (better endpoint telemetry) instead of a **system-proxy / loopback** mode that flattens destinations to the local listener. *Confirm the exact per-mode behavior with the vendor and Microsoft.*
2. **Steering exclusions.** Where telemetry fidelity matters most, evaluate **excluding specific destinations from local steering** so their true remote is visible to the sensor — weighed against the SWG filtering coverage lost. **Security tradeoff — customer decision.**
3. **Service-endpoint exclusions.** Ensure the **Defender/MDE service URLs** are not broken by SWG interception/decryption (this is connectivity, cross-reference `NETDX`) — separate from, but adjacent to, the telemetry question.
4. **Connector / integration deployment.** Evaluate the vendor's documented **MDE integration/connector** and any supported deployment option that preserves endpoint destination visibility. *Vendor internals are vendor-specific; confirm the supported option with Microsoft and the vendor.*
5. **Compensating visibility.** Where a mode change is not acceptable, document **compensating controls** — e.g. correlating the SWG's own destination logs with endpoint telemetry in the SIEM (cross-reference `WSKQL` / `DEFXDR`) — as an interim measure, clearly labeled as a workaround, not a Microsoft-supported restoration.

Present these as options with tradeoffs; the **choice and the change belong to the customer's owners**.

### Step 5.3 — Open the Microsoft advisory case
Create **`MDEPROXY Advisory Case – Microsoft – Expand`** in `admin.microsoft.com` → **Support → New service request** (or Defender portal **Help → Support**), product **Microsoft Defender for Endpoint**, **Severity C (advisory)**. Use the template below verbatim, attaching `MDEPROXY Assessment Report – Tenant – Validate`.

> **Title:** Advisory — Endpoint network telemetry (DeviceNetworkEvents) obfuscation with a loopback/forward SWG proxy: confirm affected tables, feature impact, XFF applicability, and supported coexistence topology
>
> **Severity:** C (advisory / how-does-it-behave; no production outage)
>
> **Environment:** Defender for Endpoint P2. Endpoints run a secure web gateway agent (`<iboss / Zscaler Client Connector / generic PAC-loopback>`) that steers outbound traffic through a **local loopback listener** before egress. Attached assessment (`MDEPROXY Assessment Report – Tenant – Validate`) shows a measured **`<X>%`** of outbound `DeviceNetworkEvents` resolving to loopback/proxy addresses rather than true remote destinations, and **`<N>`** connections with missing `RemoteUrl`.
>
> **We are requesting Microsoft to confirm (do not want us to assume):**
> 1. **Validate telemetry impact** — Confirm which Advanced Hunting tables and fields (`DeviceNetworkEvents.RemoteIP` / `RemoteUrl` / `RemotePort`, related `DeviceEvents`) are affected when endpoint traffic is steered through a local loopback proxy before egress, and whether this is expected behavior.
> 2. **Document feature impact** — Confirm the impact, under this topology, on **SmartScreen**, **Network Protection** (including web content filtering and custom IP/URL/domain indicators), and **threat-intelligence indicator matching** at the endpoint layer. Does Network Protection / TI matching evaluate the **true remote** or the **loopback** destination?
> 3. **XFF applicability** — Confirm whether **X-Forwarded-For** (or any equivalent mechanism / SWG integration) restores the **true remote destination into endpoint `DeviceNetworkEvents`**, or whether XFF only aids **server-side** client attribution and does **not** repopulate endpoint telemetry.
> 4. **Architecture review** — Confirm the **supported MDE + SWG coexistence topology**: which SWG steering mode(s) / exclusions / connector options are supported and preserve endpoint destination telemetry, and any Microsoft guidance on the tradeoffs.
> 5. **Advanced-hunting schema** — Confirm the **authoritative semantics** of `RemoteIP` / `RemoteUrl` (and how to distinguish a proxied connection from a direct one in the schema) when a local proxy is present, so our hunts and detections can be written correctly.
>
> **Attachments:** `MDEPROXY Assessment Report – Tenant – Validate` (measurement, feature-impact matrix, XFF reasoning, sample scope).

### Step 5.4 — Record and hand off
Record the case number on `MDEPROXY Advisory Case – Microsoft – Expand`, attach Microsoft's response to `MDEPROXY Assessment Report – Tenant – Validate` when it returns, and **update the feature-impact matrix's "Confirm with Microsoft" column and the XFF clarification with Microsoft's authoritative answer** — replacing the open questions with confirmed behavior. Hand `MDEPROXY Remediation Plan – Tenant – Expand` to the network/security/architecture owners for the change decision.

---

**Read-only guarantee.** No step above modifies the SWG, the agent, the endpoints, or the tenant. The only artifacts produced are documents, a measured baseline, a report, and a support case. Any topology change is executed by the customer's own change process, outside this package.
