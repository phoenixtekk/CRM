# 6. Troubleshooting — Defender for Endpoint Network Telemetry in Web Proxy / SWG Architectures

Symptom → cause → fix for the common failures. This is a **read-only assessment**, so most "failures" are about **trusting the measurement** or **framing the deliverables**, not about a broken control. Nothing here changes the proxy or tenant.

---

## No DeviceNetworkEvents data (can't measure obfuscation at all)
**Symptom:** `MDEPROXY-Discovery.ps1` shows `DeviceNetworkEvents` = 0 rows, or `DeviceNetworkEvents | take 1` returns nothing.
**Likely causes:** Defender for Endpoint **P1** (advanced hunting / full network table not available); devices not onboarded or not yet warmed up; the account lacks `ThreatHunting.Read.All`; wrong Graph cloud environment.
**Fix:** Confirm **P2** (R1) and re-check the plan hints in discovery. Confirm the sample devices are onboarded and have reported for a few days (R2). Confirm the account is **Security Reader** with the read scope consented (R3). For GCC/DoD, pass `-Environment USGov`/`USGovDoD`. A genuinely empty table on P2 with onboarded, warmed-up devices is itself a finding — escalate as advisory ask #1.

## Obscured share comes back 0% but you expected obfuscation
**Symptom:** `MDEPROXY-Validate.ps1` reports 0% obscured though the SWG is clearly in loopback mode.
**Likely causes:** the **proxy address set is incomplete** — the real local listener IP isn't in it; the SWG is actually in a **route-based tunnel** mode (which *does* preserve true remote — a good result); or the window/sample missed the steered traffic.
**Fix:** Run `MDEPROXY-Hunt.kql` **Q3 (top RemoteIP values)** to reveal the actual local listener/proxy addresses, then add them to `-ProxyAddressSet` (R5) and re-measure. Confirm the steering mode (Step 1.3) — a true route-based tunnel legitimately shows low obfuscation; report that as the finding, not a failure. Widen the window or sample if traffic was sparse.

## Obscured share looks implausibly high (≈100% on everything)
**Symptom:** Every device and process shows ~100% obscured.
**Likely causes:** the address set is **too broad** (e.g. it includes an RFC1918 range that also covers legitimate internal destinations), so real internal traffic is misclassified as "proxy."
**Fix:** Tighten `MDEPROXY Proxy Address Set – Tenant – Assess` to only the loopback + the confirmed local-listener/proxy IPs; do not include broad private ranges unless they truly are the proxy. Re-run `MDEPROXY-Hunt.kql` Q3 to confirm the top destinations really are the proxy before trusting the number.

## RemoteUrl is missing but RemoteIP looks like a real remote
**Symptom:** High missing-`RemoteUrl` count, yet `RemoteIP` is not in the proxy set.
**Likely causes:** URL is only recorded for certain connection types/protocols; TLS without SNI capture; or the sensor recorded the connection without a resolvable URL — not necessarily proxy-related.
**Fix:** Treat missing-`RemoteUrl` as a **secondary** indicator, not proof of obfuscation; the primary metric is the `RemoteIP`-in-proxy-set share. Note the missing-URL figure in the report and add the URL-visibility question to advisory ask #5 (schema semantics).

## Completeness ratio is low but obfuscation is low too
**Symptom:** `Net/Proc` ratio is very low, yet the obscured share is small.
**Likely causes:** low network activity on those devices, aggressive dedup, or a warm-up gap — a low ratio alone does not prove flattened telemetry.
**Fix:** Corroborate with the obscured share and Q3 before concluding. Report the ratio as context, not as a standalone finding. Re-measure over a longer window if the sample is quiet.

## Feature enumeration returns nothing (indicators / detections empty)
**Symptom:** `MDEPROXY-FeatureImpact.ps1` lists no indicators or no detection rules.
**Likely causes:** the API path differs in your cloud (beta vs v1.0), the account lacks the indicator/detection read scope, or there genuinely are none configured.
**Fix:** The script tries both beta and v1.0 paths; if both fail, enumerate manually — **Settings → Endpoints → Indicators** (IP/URL/Domain) and **Hunting → Custom detection rules** (any KQL using `RemoteIP`/`RemoteUrl`/`RemotePort`). *Verify the current API path.* "None found" is a legitimate result — record it.

## The matrix or report asserts a Microsoft answer
**Symptom:** A reviewer flags that the feature-impact matrix or XFF section states Microsoft's definitive behavior (C-Test 1/C-Test 2 fail).
**Cause:** an open question was filled with an assumption before the advisory case returned.
**Fix:** Restore the **"Confirm with Microsoft"** cell to an open question; re-frame the XFF conclusion as *our reasoning, pending Microsoft*. Only replace the open items after `MDEPROXY Advisory Case – Microsoft – Expand` returns an authoritative answer, and cite the case number when you do.

## The remediation reads as an applied change
**Symptom:** `MDEPROXY Remediation Plan – Tenant – Expand` sounds like steps were executed (C-Test 3 fails).
**Cause:** options were written imperatively instead of as choices for the owners.
**Fix:** Re-write each option as an evaluate/verify choice with its **security tradeoff**, addressed to the network/security/architecture owners, flagged "verify against current Microsoft guidance." Confirm nothing was changed by this package — it never is.

## SWG steering mode can't be confirmed
**Symptom:** You can't tell whether the agent is route-based tunnel vs system-proxy/loopback (Step 1.3).
**Cause:** the mode lives in the SWG console/agent config, which is vendor-specific.
**Fix:** Read it from `netsh winhttp show proxy`, the PAC file, and the agent's own settings with the SWG owner; confirm the exact behavior against **current vendor documentation** (do not assert it). Regardless of the labelled mode, the **measured** obscured share (Q1) is the ground truth for the report.

## Sensor can reach the service, but you're still worried about connectivity
**Symptom:** You suspect the proxy is *also* blocking the sensor's own reporting.
**Cause:** that is a **connectivity** problem, not this telemetry-visibility assessment.
**Fix:** Use the **"Endpoint Network Connectivity Troubleshooting Toolkit"** (`NETDX`) for sensor-to-service reachability and the `NSSWG` line for SWG exclusions of the Defender service URLs. This solution assumes the sensor reports and focuses on **destination telemetry fidelity**.

## Advisory case gets bounced to a higher/lower severity
**Symptom:** Microsoft re-classifies the ticket.
**Cause:** Severity C (advisory) is correct for a how-does-it-behave / architecture-review question with no outage; a reclassification usually means the framing implied an incident.
**Fix:** Keep the five asks framed as **confirmation/architecture** questions (Step 5.3), attach `MDEPROXY Assessment Report – Tenant – Validate`, and keep it Severity C. If a genuine outage exists (sensor not reporting), that is a separate, higher-severity connectivity case.
