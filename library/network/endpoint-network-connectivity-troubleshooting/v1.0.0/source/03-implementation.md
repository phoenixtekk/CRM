# Diagnostic Playbook

This is the working method: a **symptom tree** that isolates a connectivity failure to exactly one
layer, with the **exact checks per layer** and how to read each result. Work **top to bottom** — an
earlier layer failing masks everything below it. At every step, **save the output as evidence**; the
goal is not just to fix it but to *prove* which layer is responsible.

> **Golden rule:** change one thing, test one thing, prove one layer. Never restart the app and reboot
> and swap the cable all at once — you learn nothing.

## Step 0 — Baseline and control (always do this first)

1. On the **failing** endpoint, open **Windows PowerShell (Admin)**.
2. Capture the posture: run `.\NETDX-Discovery.ps1`. This records DNS servers, system + WinHTTP proxy,
   PAC URL, VPN/interface state, and default routes into a JSON/CSV file you keep as evidence.
3. On the **known-good control** endpoint (R2), open the same target service and confirm it works.
4. Decide the split:
   - **Control also fails** → the problem is upstream/shared or the service itself. Skip endpoint
     config; escalate with the target list and the fact that multiple endpoints fail.
   - **Only the failing endpoint fails** → continue down the tree; the block is in this endpoint's
     path.

## The symptom tree

Pick the branch that matches what you observe, then run that layer's checks.

```
Can't reach the service?
├─ Does the NAME resolve?                         ── NO ──► Branch A: DNS
│    │ YES
│    ▼
├─ Is the route/proxy/VPN decision correct?
│    ├─ Wrong proxy / PAC verdict?               ──────► Branch B: Proxy / PAC
│    ├─ On VPN but internal target unreachable?  ──────► Branch C: VPN / split-tunnel
│    │ route looks right
│    ▼
├─ Does IP:PORT open (name resolved, still no connect)? NO ─► Branch D: IP / Port (firewall)
│    │ YES
│    ▼
└─ Does the URL return an ALLOWED response?       ── NO ──► Branch E: URL / category filter
```

---

## Branch A — Name won't resolve (DNS, layer 1)

**Symptom:** "Server not found," NXDOMAIN, `Resolve-DnsName` errors, or the name resolves to an
obviously wrong IP (e.g. a captive-portal or sinkhole address).

**Checks (run on the failing endpoint):**

1. Resolve against the **configured** resolver:
   `Resolve-DnsName app.example.com` (replace with your target FQDN).
2. Resolve against a **known-good public** resolver to compare:
   `Resolve-DnsName app.example.com -Server 1.1.1.1`
3. See which resolvers the endpoint is actually using:
   `Get-DnsClientServerAddress -AddressFamily IPv4`
4. Check for a stale/poisoned cache or a hosts-file override:
   `Get-DnsClientCache | Where-Object Entry -like "*example.com*"` and open
   `C:\Windows\System32\drivers\etc\hosts`.

**Read the result:**
- Configured resolver fails **but** public resolver succeeds → the endpoint's DNS server (or a
  DNS-layer filter) is the block. Evidence: the two differing outputs.
- Both fail → the name genuinely does not resolve anywhere (typo, decommissioned host, or the
  authoritative zone is down) — verify the FQDN with the app owner.
- Resolves to a wrong/sinkhole IP → a DNS filter or hosts entry is redirecting it; note the returned
  IP as evidence.
- Stale cache entry → see remediation (safe local flush) below.

**Prove & escalate:** name resolution is layer 1; if it fails only via the configured resolver, hand
the two `Resolve-DnsName` outputs to whoever owns DNS/DNS-filtering.

---

## Branch B — Resolves but wrong proxy / PAC misroute (layer 2)

**Symptom:** Some sites work and others don't; a site that should go direct is trying a proxy (or vice
versa); intermittent depending on network; `407 Proxy Authentication Required`.

**Checks (on the failing endpoint):**

1. System (WinINET) proxy for the user:
   `Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'`
   (look at `ProxyEnable`, `ProxyServer`, `AutoConfigURL`).
2. WinHTTP proxy (used by services and many system components):
   `netsh winhttp show proxy`
3. If a **PAC** is in use, fetch and read it:
   download the `AutoConfigURL` and inspect the `FindProxyForURL` logic for your target host — does it
   return `DIRECT` or a proxy for that URL?
4. Compare against the **intended** path from R4.

**Read the result:**
- A proxy is set that should not be (or a stale `ProxyServer` remains) → the endpoint is misrouting;
  this is a layer-2 block. A safe local clear of a stale WinHTTP proxy is in remediation.
- PAC returns the wrong verdict for the URL → the PAC file (owned by the proxy/network team) is
  misrouting; capture the URL and the PAC's verdict and escalate to the PAC owner.
- `407` → the proxy is in the path and demanding auth the endpoint isn't supplying; that is expected
  proxy behavior — confirm credentials/SSO with the proxy owner (defer to that vendor's console).

**Prove & escalate:** capture `netsh winhttp show proxy`, the WinINET values, and the PAC verdict for
the specific URL. That trio proves whether the endpoint is choosing the wrong path.

---

## Branch C — VPN / split-tunnel gap (layer 3)

**Symptom:** Internal-only apps are unreachable while on VPN (or *only* reachable on VPN); works at
the office but not remote; some corporate ranges route out to the internet instead of the tunnel.

**Checks (on the failing endpoint, VPN connected):**

1. Confirm the VPN interface is up:
   `Get-NetAdapter | Where-Object Status -eq 'Up'` and
   `Get-NetIPInterface -ConnectionState Connected`.
2. Look at the route for the target IP (from Branch A's resolved IP):
   `Find-NetRoute -RemoteIPAddress 10.20.30.40` — which interface does it choose, the VPN or the
   physical NIC?
3. List the full routing table to see split-tunnel scope:
   `Get-NetRoute -AddressFamily IPv4 | Sort-Object -Property RouteMetric`.
4. Repeat step 2 **with the VPN disconnected** to compare.

**Read the result:**
- Target IP routes out the **physical NIC** while on VPN, but the app is internal → it is a
  **split-tunnel gap**: that destination range is not included in the tunnel. This is a layer-3 config
  on the VPN profile (owned by the VPN team). Capture the two `Find-NetRoute` outputs (VPN up vs down)
  as proof.
- VPN interface is **not up** at all → the tunnel didn't establish; that is a VPN-client problem, not
  routing — defer to your VPN vendor's client documentation.
- Target routes correctly through the tunnel but still fails → the block is *below* VPN; drop to
  Branch D.

**Prove & escalate:** the pair of `Find-NetRoute` results (tunnel up vs down) plus the target IP
proves whether the split-tunnel scope omits the destination.

---

## Branch D — IP:Port blocked (firewall, layer 4)

**Symptom:** The name resolves (Branch A passed) and the route looks right, but the connection **times
out** (silent drop) or is **refused** (RST). "Connecting…" that never completes.

**Checks (on the failing endpoint):**

1. Test the exact host and port:
   `Test-NetConnection app.example.com -Port 443 -InformationLevel Detailed`
2. Test the **resolved IP** directly (removes DNS from the equation):
   `Test-NetConnection 203.0.113.10 -Port 443`
3. Test the **same port to a control host** you know is open, to prove it isn't a local block:
   e.g. `Test-NetConnection www.microsoft.com -Port 443`
4. Rule out the **local** Windows firewall:
   `Get-NetFirewallProfile | Select-Object Name, Enabled` and check for a rule blocking the app
   (`Get-NetFirewallRule -Enabled True -Direction Outbound`).

**Read the result:**
- `TcpTestSucceeded : False` with a **timeout** → traffic is being **silently dropped** — classic
  network firewall / IP filter block between the endpoint and the service. A drop (no response) points
  upstream, not to the local host.
- **Refused** (fast RST) → something answered and rejected — often the service isn't listening on that
  port, or a device is actively resetting. Confirm the port with the app owner.
- Control host on the **same port succeeds** but the target fails → the port itself isn't locally
  blocked; the block is specific to the target's IP/port at an upstream firewall/IP filter.
- Local Windows firewall has a matching outbound block rule → that is the block, and it's local
  (fixable on the endpoint per your policy).

**Prove & escalate:** the three `Test-NetConnection` results (target host, target IP, control host)
together prove the block is at the IP:port layer and whether it is local or upstream. Hand them to the
firewall owner (defer to that vendor's console for the specific rule).

---

## Branch E — URL / category blocked (web filter, layer 5)

**Symptom:** The port opens (Branch D passed) but the request returns a **block page**, a `403`, a
redirect to a filtering portal, or the TLS session is **reset mid-handshake**. Only *certain URLs* on
an otherwise-reachable host fail.

**Checks (on the failing endpoint):**

1. Request the URL and inspect the response:
   `Invoke-WebRequest https://app.example.com/health -UseBasicParsing -MaximumRedirection 0`
   — note the status code, any redirect `Location`, and whether the body is a filter block page.
2. Compare with a **known-allowed** URL on a benign category to confirm general web access works.
3. Inspect the returned certificate / TLS behavior: an unexpected certificate issuer on the response
   can indicate an inspecting/blocking web gateway in the path.
4. If your organization runs a secure web gateway or URL filter, note the **block/observed category**
   shown on the block page (it usually names the category and a request ID).

**Read the result:**
- Returns a **filter block page / 403 / redirect to a portal** → a URL or category filter is blocking
  it (layer 5). Capture the status code, the block-page text, and any request/transaction ID.
- **TLS reset mid-handshake** for one host but not others → a filtering/inspection device is
  terminating that specific destination.
- Known-allowed control URL also fails → the problem is broader than one URL (drop back up the tree).

**Prove & escalate:** the block-page text (with category + request ID) plus the passing control URL
proves a category/URL policy is responsible. Escalate to whoever owns the web filter / secure web
gateway and **defer to that vendor's console** to see and adjust the category policy.

---

## After you isolate: safe local remediation

Only for blocks that are **local to the endpoint** (stale DNS cache, stale route cache, stale WinHTTP
proxy) run `.\NETDX-Remediation.ps1`. It defaults to **`-WhatIf`** (preview only). Review the
previewed actions, then re-run with `-WhatIf:$false` (and, if your policy requires, `-Confirm`) to
apply. It never touches proxy, VPN, or firewall hardware — those are escalated with the evidence you
captured.

## Rolling it up across many targets

To test a whole connectivity list at once (e.g. all the endpoints a new SaaS app needs), feed the R3
target CSV to `.\NETDX-Validation.ps1`, then summarize with `.\NETDX-Report.ps1` for a
pass/fail-by-layer coverage view — the same method, applied in bulk.
