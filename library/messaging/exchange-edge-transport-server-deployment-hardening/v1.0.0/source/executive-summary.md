# Executive Summary — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

## Outcome

A perimeter **Edge Transport** tier that is **correct and secure**: subscribed to the Exchange
organization via a healthy **EdgeSync** relationship, with scoped **connectors** and **accepted
domains**, first-layer **anti-spam / connection filtering**, a hardened **OS and enforced TLS**, and
**no open relay** — validated by controlled inbound and outbound mail flow before any production
cutover. The result is a hardened front door to the messaging estate that complements, rather than
duplicates, cloud hygiene (EOP / Defender for Office 365).

## Approach

The solution follows a disciplined, pilot-first model — **Assess → Design → Configure → Pilot →
Validate → Expand** — with **named artifacts**, explicit **pass/fail gates**, and a documented
**rollback**. It deploys the Edge role on a standalone hardened perimeter host, creates and imports
the **Edge Subscription** (letting EdgeSync auto-provision the internet connectors), configures the
connector / accepted-domain / hygiene / TLS posture, and proves secure mail flow on a **test mail
path** before cutting production MX. Five PowerShell tools support the work: read-only readiness
discovery, a safe (`-WhatIf`) configuration helper, an open-relay + TLS validator, an anti-spam /
connection-filter report, and a scope/health helper — all read-only or dry-run by default, with no
credentials in code.

## Why it is low-risk

- **Pilot-first with hard gates.** Nothing touches production MX until EdgeSync is healthy, the
  open-relay hole is provably closed, TLS is enforced, and pilot mail flows both ways.
- **Reversible.** A recorded baseline and a documented MX/subscription rollback mean any failed gate is
  recoverable within the change window.
- **Safe-by-default tooling.** Every provided script defaults to read-only or `-WhatIf`; writes require
  an explicit switch, and there are no stored secrets.
- **Version-honest.** Exchange Server behavior is version- and CU-dependent; the guide flags every such
  point as "verify for your version" rather than assuming, so the operator applies the correct steps
  for their exact build — and for Government (GCC/GCC High/DoD) cloud endpoints where hybrid touch
  points differ.

**Bottom line:** a hardened, validated perimeter Edge Transport tier — EdgeSync healthy, no open relay,
TLS enforced, mail flowing — delivered with a repeatable, low-risk procedure and supporting automation.
