# Deliverables Summary

Everything included in the **Endpoint Network Connectivity Troubleshooting Toolkit** and how each
piece is used.

## Documentation

| Document | What it gives you |
|----------|-------------------|
| **Solution Overview** | The endpoint-to-service path (DNS → proxy/PAC → VPN → firewall/URL filter → service) and the layered root-cause model behind the whole method. |
| **Requirements Guide** | Each prerequisite as Description / Why / Verify / Implement — endpoint access, a control device, exact test targets, expected path, PowerShell, Graph module, and reset permissions. |
| **Diagnostic Playbook** | The symptom tree and the exact per-layer checks: name won't resolve, resolves-can't-connect, proxy/PAC misroute, VPN split-tunnel gap, IP:Port blocked, URL category blocked. |
| **Testing Guide** | Pass/fail gates, one per layer, that name the responsible layer on the first failure. |
| **Troubleshooting Guide** | Fixes and reads for the method's own snags (the tools themselves, not the network) plus fast layer-by-layer symptom lookups. |
| **Best Practices** | The habits for repeatable triage and evidence-based escalation. |
| **Global Requirements — Network** | The category-level prerequisites shared by all Network solutions. |

## PowerShell scripts

All scripts carry a standard header documenting **PURPOSE**, **HOW TO RUN**, and **EXPECTED RESULTS**.
Discovery, Validation, and Report are **read-only**. Remediation and Set-ScopeTargeting default to
**`-WhatIf`** (preview) so nothing changes until you explicitly confirm.

| Script | Role | Read-only? |
|--------|------|-----------|
| **NETDX-Discovery.ps1** | Capture the endpoint's connectivity posture: DNS servers, system + WinHTTP proxy, PAC URL, VPN/interface state, default routes. | Yes |
| **NETDX-Validation.ps1** | For each target in a CSV, test the layers: name resolves, IP:port reachable, URL returns an allowed response. | Yes |
| **NETDX-Report.ps1** | Roll validation results into a connectivity-coverage report (pass rate, first-failing-layer breakdown, per-target detail). | Yes |
| **NETDX-Remediation.ps1** | Safe, local, reversible resets only: flush DNS cache, reset route cache, clear a stale WinHTTP proxy. Never touches network gear. | No (`-WhatIf` default) |
| **NETDX-Set-ScopeTargeting.ps1** | Build/maintain a pilot Entra security group via Microsoft Graph for staged testing. | No (`-WhatIf` default) |

## How the pieces work together

1. **Discovery** on the failing endpoint records the posture (evidence baseline).
2. The **Playbook** walks the symptom tree; **Testing** gates name the responsible layer.
3. **Validation** + **Report** apply the same checks in bulk across a target list.
4. **Remediation** fixes only local causes, safely and reversibly.
5. **Set-ScopeTargeting** scopes a pilot before fleet-wide validation.

The result of any incident is a proven root-cause layer with saved evidence — ready to fix locally or
escalate to the owning team.
