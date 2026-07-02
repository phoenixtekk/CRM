# Solution Overview

## The problem: "it works on my machine"

A user reports that an application, website, or cloud service "won't load," "times out," or "can't
connect." One endpoint fails while an identical one nearby works fine. The instinct is to guess —
restart the app, reboot, blame the Wi-Fi — and hope. Guessing wastes time and, worse, hides the real
cause so it comes back tomorrow.

This solution replaces guessing with a **repeatable, layered root-cause method**. It is
**vendor-neutral** and **endpoint-side**: everything is tested and proven from the affected Windows
device (or from a comparable known-good device beside it), so you isolate exactly which layer is
blocking the traffic before you escalate to a network, proxy, VPN, or firewall team.

## The endpoint-to-service path

Every connection from a managed Windows endpoint to a service crosses a **stack of layers**. Traffic
must succeed at each one, in order, or the connection fails. When something "can't connect," the block
lives in exactly one of these layers — your job is to find which one:

```
[ Endpoint app ]
      |  1. Name resolution (DNS)          "what IP is this name?"
      v
[ Resolver / DNS server ]
      |  2. Proxy decision (PAC / system proxy) "do I go direct or through a proxy?"
      v
[ Proxy (explicit or PAC-selected) ]        (may be bypassed for some destinations)
      |  3. VPN / tunnel routing            "is this destination inside the tunnel or split out?"
      v
[ VPN client / split-tunnel rules ]
      |  4. IP + Port reachability          "can a TCP/UDP session open to host:port?"
      v
[ Firewall / IP + Port filter ]
      |  5. URL / category filter           "is this URL or category allowed?"
      v
[ URL / web filter ]
      v
[ Service ]  <- success
```

Read it top to bottom. A failure at an **earlier** layer masks everything below it: if a name won't
resolve (layer 1), you never even get to test the port (layer 4). That is why the method always works
**from the top down** — resolve the name first, then route, then reach the port, then the URL.

## The layered root-cause model

Each layer has a distinct **question**, a distinct **symptom** when it fails, and a distinct **check**
that proves it. This is the heart of the toolkit:

| # | Layer | Question it answers | Typical failure symptom | The check that proves it |
|---|-------|---------------------|-------------------------|--------------------------|
| 1 | **DNS (name resolution)** | What IP does this name map to? | "Name won't resolve" / NXDOMAIN / wrong IP | `Resolve-DnsName`, `nslookup` against the configured and a known-good resolver |
| 2 | **Proxy / PAC** | Direct, or through a proxy? Which one? | Connects for some sites, not others; wrong route | Read system + WinHTTP proxy, evaluate the PAC verdict for the URL |
| 3 | **VPN / split-tunnel** | Is the destination inside or outside the tunnel? | Works off-VPN but not on (or vice-versa); internal-only apps unreachable | Compare routing table and interface with VPN up vs down |
| 4 | **IP : Port (firewall)** | Can a TCP/UDP session open to host:port? | Name resolves but connection times out / refused | `Test-NetConnection -Port`, raw TCP connect to the resolved IP |
| 5 | **URL / category filter** | Is this URL or web category allowed? | Port opens but request returns a block page / 403 / reset mid-TLS | Fetch the URL and inspect the response vs a known-allowed URL |

**The single most important habit:** isolate one layer at a time, top to bottom, and **prove** the
verdict with a check whose output you can save as evidence. When you can say "the name resolved to
`203.0.113.10`, the TCP session to `203.0.113.10:443` refused, but the same port to a control host
succeeded," you have not guessed — you have proven the block is at the firewall/port layer and you can
escalate with proof.

## What "vendor-neutral" means here

The blocking device at layer 2, 3, 4, or 5 might be any vendor's proxy, VPN concentrator, firewall,
or secure web gateway. This toolkit does **not** tell you which buttons to press in a specific
vendor's console — those screens change and differ per product. Instead it proves, from the endpoint,
**which layer** is responsible, so you hand a precise, evidence-backed finding to whoever owns that
device. Where a vendor console is genuinely required (for example, to see why a URL category is
blocked or to read a proxy's own logs), the playbook says so and defers to **that vendor's official
documentation and your own console**.

## Where the scripts fit

Five PowerShell scripts operationalize the method so you run the same checks the same way every time:

- **NETDX-Discovery.ps1** — captures the endpoint's connectivity posture: DNS servers, system and
  WinHTTP proxy, PAC URL, VPN/interface state, and default routes. Read-only.
- **NETDX-Validation.ps1** — for a list of target endpoints, tests each layer per target: name
  resolves, IP:port reachable, URL returns an allowed response. Read-only.
- **NETDX-Report.ps1** — rolls validation results into a connectivity-coverage report (which targets
  pass, which fail, and at which layer). Read-only.
- **NETDX-Remediation.ps1** — applies **safe, local, reversible** resets (flush DNS cache, reset
  route cache, clear a stale WinHTTP proxy) with `-WhatIf` on by default. Never touches network gear.
- **NETDX-Set-ScopeTargeting.ps1** — builds/maintains a pilot Entra group for staged testing via
  Microsoft Graph, `-WhatIf` on by default.

Use Discovery to see the posture, Validation to test each target, Report to summarize, Remediation
only for safe local resets, and Set-ScopeTargeting to scope a pilot before wider testing.
