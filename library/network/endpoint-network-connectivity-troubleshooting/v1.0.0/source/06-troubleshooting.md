# Troubleshooting

Two kinds of snags: (A) problems with the **method and the tools themselves**, and (B) a fast
**symptom → layer** lookup when you just need to jump to the right branch of the Playbook. For the
full per-layer checks, see the Diagnostic Playbook; for the pass/fail gates, see Testing.

## A. Tooling and method issues

**`Resolve-DnsName` / `Test-NetConnection` not recognized.**
These ship with Windows PowerShell 5.1+. Confirm with `$PSVersionTable.PSVersion` (see R5). On a
minimal/PowerShell-7-only host, `Test-NetConnection` lives in the Windows-only `NetTCPIP` module —
run the scripts under Windows PowerShell 5.1 if a cmdlet is missing.

**Scripts won't run — "running scripts is disabled on this system."**
Launch with the documented invocation:
`powershell -ExecutionPolicy Bypass -File .\NETDX-Discovery.ps1`. This bypasses policy for that one
process only and changes nothing permanently.

**Discovery/Validation report needs elevation.**
The core read-only checks do not require admin, but a few (e.g. reading some WinHTTP state) are richer
when elevated. Run from **Windows PowerShell (Admin)** for the fullest posture; otherwise the scripts
still run and note any field they could not read.

**`NETDX-Set-ScopeTargeting.ps1` fails at sign-in / "module not found."**
Install the Graph module (R6): `Install-Module Microsoft.Graph -Scope CurrentUser`. At run time it
requests `Group.ReadWrite.All` and `GroupMember.ReadWrite.All`; an admin may need to consent. If
consent is refused, keep it in `-WhatIf` and hand the previewed changes to a Graph-permitted admin.

**Remediation "did nothing."**
It defaults to **`-WhatIf`** — that is preview mode, by design. Review the previewed actions, then
re-run with `-WhatIf:$false` to apply. It only performs safe local resets; if the block is not local
(proxy/VPN/firewall), remediation intentionally cannot help — escalate with evidence instead.

**Validation shows every target failing at Gate 1 (DNS).**
Usually the endpoint's own resolver or a DNS-layer filter is down, not every target at once. Re-run a
single `Resolve-DnsName <FQDN> -Server 1.1.1.1` against a control resolver; if that succeeds, the
configured resolver/DNS filter is the shared cause (Branch A).

**Results differ between two runs.**
Connectivity is stateful — a VPN reconnected, a PAC changed, a cache populated. Re-run Discovery to
re-baseline (Best Practice 12) and note the network state (VPN up/down, on-site vs remote) with each
run.

## B. Symptom → layer quick lookup

| You observe… | Likely layer | Go to |
|--------------|--------------|-------|
| "Server not found," NXDOMAIN, or a wrong/sinkhole IP | **1 — DNS** | Playbook Branch A |
| Some sites work, others don't; `407`; wrong direct/proxy behavior | **2 — Proxy / PAC** | Playbook Branch B |
| Works off-VPN not on (or vice-versa); internal apps unreachable | **3 — VPN / split-tunnel** | Playbook Branch C |
| Name resolves but connection **times out** (silent) | **4 — IP:Port (firewall, upstream drop)** | Playbook Branch D |
| Name resolves but connection is **refused** (fast RST) | **4 — IP:Port (nothing listening / active reset)** | Playbook Branch D |
| Port opens but you get a block page / `403` / portal redirect | **5 — URL / category filter** | Playbook Branch E |
| TLS reset mid-handshake for one host only | **5 — inspecting/filtering gateway** | Playbook Branch E |
| Both the failing endpoint **and** the control fail | shared upstream / service | Gate 0 — escalate with target list |

## C. When the evidence points off the endpoint

Once a gate proves the block is **not** local (upstream firewall, PAC/proxy owned by the network team,
a VPN split-tunnel profile, a URL category policy), the endpoint side is done. Package the captured
evidence — Discovery posture, the first-failing-gate output, and the matching control result — and
escalate to the owning team. For the specific device's own configuration and logs (proxy, VPN
concentrator, firewall, secure web gateway), **defer to that vendor's official documentation and your
own console**; this toolkit's job is to prove which layer and which team, and it has done that.
