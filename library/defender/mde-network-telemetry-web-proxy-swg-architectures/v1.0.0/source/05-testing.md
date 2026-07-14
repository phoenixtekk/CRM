# 5. Testing Guide — Defender for Endpoint Network Telemetry in Web Proxy / SWG Architectures

Because this solution is a **read-only assessment**, "testing" means confirming the **measurement is trustworthy and the deliverables are complete and honestly framed** — not that a control was enforced. Every test has a **pass/fail gate**; do not present the assessment as conclusive until the gates pass. Objects are referenced by the exact names from the Implementation Guide; scripts by name.

---

## Part A — Assessment readiness

### A-Test 1 — Read-only access and tables available
**Procedure:** Run `MDEPROXY-Discovery.ps1`. Confirm it connects with `ThreatHunting.Read.All`, `DeviceNetworkEvents | take 1` returns rows (P2), and the network tables (`DeviceNetworkEvents`, `DeviceEvents`, `DeviceInfo`, `DeviceProcessEvents`) are populated and fresh.
**Pass:** connects read-only; P2 confirmed; network tables fresh. **Fail:** no rows / P1 only / stale — see Troubleshooting *No DeviceNetworkEvents data* and confirm R1/R2.

### A-Test 2 — Sample is representative and behind the SWG
**Procedure:** Confirm `MDEPROXY Device Sample – Proxy Ring – Assess` covers the OS mix and sites, and that each sample device actually runs the SWG agent (Step 1.3/1.4).
**Pass:** the sample matches the behind-the-SWG population. **Fail:** sample includes non-steered devices or misses a platform — redefine per Step 1.4.

### A-Test 3 — Proxy address set is complete and documented
**Procedure:** Confirm `MDEPROXY Proxy Address Set – Tenant – Assess` lists the loopback, local-listener, and proxy addresses derived from the actual config (R4/R5); `MDEPROXY-Validate.ps1` echoes the set it used.
**Pass:** every classifying address is documented and justified. **Fail:** the set is a guess or the script echoes a different set — rebuild from the real PAC/system-proxy/agent config.

---

## Part B — Measurement validity

### B-Test 1 — Destination-obfuscation measured
**Procedure:** Run `MDEPROXY-Validate.ps1 -Sample "MDEPROXY Device Sample – Proxy Ring – Assess" -ProxyAddressSet <set> -Days 7`. Confirm `MDEPROXY Telemetry Baseline – Proxy Ring – Pilot` records the **% of outbound `DeviceNetworkEvents` whose `RemoteIP` is in the proxy address set**, the missing-`RemoteUrl` count, and the per-device distribution.
**Pass:** a numeric obfuscation share and completeness figure are recorded for the sample. **Fail:** empty/zero across all devices — confirm the address set (A-Test 3) and window; a true 0% means no obfuscation (a valid, reportable finding).

### B-Test 2 — Completeness and table population measured
**Procedure:** Run `MDEPROXY-Validate.ps1 -Check Completeness` and the `MDEPROXY-Hunt.kql` completeness queries. Confirm the network-to-process event ratio and per-table population are recorded per device.
**Pass:** completeness metrics recorded; any empty table flagged. **Fail:** no completeness data — re-run; if a table is empty, note it as a finding, not a script error.

### B-Test 3 — Feature/detection enumeration produced
**Procedure:** Run `MDEPROXY-FeatureImpact.ps1`. Confirm it lists custom detections/hunts referencing `RemoteIP`/`RemoteUrl`/`RemotePort` and the IP/URL/domain TI indicators, plus the portal-only NP/SmartScreen checks.
**Pass:** a concrete list of exposed rules and indicators is produced (or an explicit "none found"). **Fail:** the enumeration errors out — correct the query/scope and re-run.

### B-Test 4 — Results are reproducible
**Procedure:** Re-run `MDEPROXY-Validate.ps1` with the same parameters. Confirm the obfuscation share is stable within a small tolerance (traffic varies; the order of magnitude should hold).
**Pass:** consecutive runs agree in magnitude. **Fail:** wild swings — check the window is long enough and the sample is stable.

---

## Part C — Deliverable integrity (honest framing)

### C-Test 1 — Feature-impact matrix keeps the "Confirm with Microsoft" column open
**Procedure:** Open `MDEPROXY Feature-Impact Matrix – Tenant – Validate`. Confirm the **"Observed effect"** column is filled from measurement and the **"Confirm with Microsoft"** column states the open question — **not** an invented Microsoft answer.
**Pass:** measured effects present; Microsoft-authoritative items remain open questions. **Fail:** any cell asserts Microsoft's definitive position without the case — remove the assertion; it is not yet confirmed.

### C-Test 2 — XFF clarification is correctly framed
**Procedure:** Read `MDEPROXY XFF Clarification – Tenant – Validate`. Confirm it explains XFF as **server-side**, reasons about endpoint telemetry, and **explicitly defers to Microsoft** ("confirm current behavior with Microsoft").
**Pass:** XFF explained as server-side; endpoint conclusion framed as our reasoning pending Microsoft. **Fail:** it asserts Microsoft's answer — re-frame per Step 4.2.

### C-Test 3 — Remediation is a plan of options, not an applied change
**Procedure:** Read `MDEPROXY Remediation Plan – Tenant – Expand`. Confirm every option is flagged "verify against current Microsoft guidance," records the security tradeoff, and is addressed to the customer's owners — and that **nothing was applied** by this package.
**Pass:** options only, verify-flagged, tradeoffs noted, no change applied. **Fail:** an option reads as done or asserts support without the verify flag — correct it.

### C-Test 4 — Advisory case template complete
**Procedure:** Open `MDEPROXY Advisory Case – Microsoft – Expand`. Confirm it is Severity C and includes all five asks (validate-telemetry, document-feature-impact, XFF, architecture-review, advanced-hunting-schema) with the assessment report attached.
**Pass:** all five asks present; Sev C; report attached. **Fail:** an ask missing or wrong severity — complete per Step 5.3.

### C-Test 5 — Report compiled and read-only guarantee intact
**Procedure:** Run `MDEPROXY-Report.ps1`. Confirm `MDEPROXY Assessment Report – Tenant – Validate` contains the measurement summary, matrix, XFF section, and open questions — and that no script or step changed the proxy or tenant.
**Pass:** report complete; read-only guarantee holds. **Fail:** missing sections — re-run the relevant validate step first.

**Assessment exit gate:** all of Part A and Part B pass (trustworthy measurement) and all of Part C passes (honestly framed, Microsoft-deferred deliverables) before the assessment is presented as conclusive or the advisory case is closed against. Re-run Parts A–B after any SWG mode change, connector upgrade, or once Microsoft's advisory answer returns, to re-measure the delta.
