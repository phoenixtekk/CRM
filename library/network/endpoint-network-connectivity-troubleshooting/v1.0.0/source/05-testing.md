# Testing

Testing here is not a separate phase after a "deployment" — it *is* the method. Each gate below is a
**pass/fail check that maps to one layer** of the endpoint-to-service path. Run them top to bottom;
the first gate that fails names the responsible layer and points you to the matching branch of the
Diagnostic Playbook. Record every result as evidence.

> **How to read this:** a **PASS** means that layer is not the block — proceed down. The **first
> FAIL** is your root cause layer. You should never have two layers "failing" at once from a single
> test run, because an upstream fail prevents the downstream check from being meaningful.

## Gate 0 — Control comparison (isolation gate)

| | |
|---|---|
| **Check** | Same target reached from the known-good control endpoint (R2). |
| **PASS** | Control reaches it; failing endpoint does not → problem is endpoint-local, continue. |
| **FAIL** | Control **also** fails → problem is shared/upstream or the service; stop endpoint triage, escalate with the target list. |
| **Layer** | Not a single layer — this gate decides *whether* to walk the endpoint's stack at all. |

## Gate 1 — DNS resolution

| | |
|---|---|
| **Check** | `Resolve-DnsName <FQDN>` (configured resolver) and `-Server 1.1.1.1` (control resolver). |
| **PASS** | Both resolve to the same, correct IP. |
| **FAIL** | Configured resolver errors/NXDOMAINs or returns a wrong/sinkhole IP while the control resolver succeeds. |
| **Responsible layer** | **Layer 1 — DNS.** Go to Playbook Branch A. |

## Gate 2 — Proxy / PAC routing

| | |
|---|---|
| **Check** | `netsh winhttp show proxy` + WinINET settings + PAC verdict for the URL, compared to the intended path (R4). |
| **PASS** | The endpoint's proxy decision for the target matches intent (correct proxy, or correctly `DIRECT`). |
| **FAIL** | A stale/wrong proxy is set, or the PAC returns the wrong verdict, or a `407` blocks the request. |
| **Responsible layer** | **Layer 2 — Proxy / PAC.** Go to Playbook Branch B. |

## Gate 3 — VPN / split-tunnel routing

| | |
|---|---|
| **Check** | `Find-NetRoute -RemoteIPAddress <resolved IP>` with VPN up vs down; confirm VPN interface state. |
| **PASS** | The target IP routes through the intended interface (tunnel for internal, physical for direct). |
| **FAIL** | An internal target routes out the physical NIC (split-tunnel gap) or the VPN interface is not up. |
| **Responsible layer** | **Layer 3 — VPN / split-tunnel.** Go to Playbook Branch C. |

## Gate 4 — IP : Port reachability

| | |
|---|---|
| **Check** | `Test-NetConnection <host> -Port <port>`, the resolved IP directly, and the same port to a control host. |
| **PASS** | `TcpTestSucceeded : True` to the target host/IP. |
| **FAIL** | Timeout (silent drop → upstream firewall) or refused (RST → nothing listening / active reset), while the control-host port succeeds. |
| **Responsible layer** | **Layer 4 — IP / Port firewall.** Go to Playbook Branch D. |

## Gate 5 — URL / category access

| | |
|---|---|
| **Check** | `Invoke-WebRequest <URL>` inspected for status code, redirect, block-page body, and TLS behavior, vs a known-allowed control URL. |
| **PASS** | The URL returns the expected allowed response (e.g. 200 / expected redirect), like the control URL. |
| **FAIL** | Block page, `403`, redirect to a filtering portal, or mid-TLS reset for that URL while the control URL passes. |
| **Responsible layer** | **Layer 5 — URL / category web filter.** Go to Playbook Branch E. |

## Bulk gate — coverage across a target list

When validating many targets at once (R3 CSV), each row runs Gates 1, 4, and 5 (and reports proxy/VPN
posture from Discovery). `NETDX-Report.ps1` summarizes:

- **Overall pass rate** — how many targets are fully reachable.
- **First-failing-layer breakdown** — how many failures are DNS vs port vs URL, so you can see whether
  one layer (e.g. a firewall change) explains most failures.
- **Per-target detail** — the exact gate each failing target stopped at.

A clean run is **all targets PASS at every applicable gate**. Any FAIL is actionable: it names the
target, the gate, and therefore the layer and the team to escalate to.

## Evidence to keep from a test run

For each incident, retain: the Discovery output (posture), the per-gate command output that produced
the first FAIL, and the matching control result (control endpoint / control resolver / control host /
control URL). That set is the proof that the block is at the named layer.
