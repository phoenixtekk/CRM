# 8. Deliverables Summary — Entra Global Secure Access (Internet & Private Access)

## What you receive
A complete, self-guided package to deploy **Microsoft Entra Global Secure Access** — Microsoft's Security
Service Edge (SSE). It stands up the **GSA client**, **Private Access connectors**, and the three traffic
forwarding profiles (**Microsoft**, **Internet Access / SWG**, **Private Access / ZTNA**), wires them to
**Conditional Access + Continuous Access Evaluation**, and turns on traffic logging — so internet and SaaS
traffic is inspected, internal apps are reachable **per-app without a VPN**, and every flow is identity-
conditioned and logged.

### Documentation
- **Executive Summary** — the problem (backhauled VPN, flat access, blind egress), the solution (SSE:
  Microsoft/Internet/Private profiles under identity), the outcome, the boundary, and the licensing gate.
- **Solution Overview** — how the client, forwarding profiles, and connectors fit together, the building
  blocks (connector group → published app → segments; filtering policy → security profile; CA + CAE),
  scope, and what's out of scope (CA baseline design and app-auth migration are separate solutions).
- **Requirements Guide** — GSA-specific prerequisites (licensing incl. Internet/Private Access add-ons,
  the GSA admin role, pilot devices + client channel, connector host, private-app segments, internal DNS,
  a Log Analytics workspace, the Graph/Az toolchain), each with Verify / Implement, on top of the category
  global requirements.
- **Implementation Guide** — ordered steps: assess → activate + Microsoft profile → client to pilot →
  connectors → publish private app → Internet Access + web filter → Conditional Access → traffic logging →
  validate → expand and retire the VPN, with **every object named** using the
  `ENTGSA – <Purpose> – <Scope> – <Stage>` convention.
- **Testing & Validation** — the gates (Microsoft traffic, private app without VPN + no flat access,
  internet filtering, CA + CAE) as a pass/fail matrix, automated checks, and reference **KQL** for the
  traffic logs.
- **Troubleshooting** — symptom → root-cause → fix for the common failures (client not connecting, private
  app unreachable, DNS mismatch, over-filtering, CA lockout, no logs).
- **Best Practices** — pilot-first rollout, tight app segments, connector HA, minimal-then-tighten
  filtering, CA/CAE conditioning, logging, and where to go next.

### PowerShell tools (Microsoft Graph / Az) — safe by default
| Script | Purpose | Default mode |
|--------|---------|--------------|
| **`ENTGSA-Discovery.ps1`** | Inventory GSA activation, forwarding profiles, connector groups, published private apps + segments, filtering policies, and CA-for-GSA (baseline posture) | Read-only |
| **`ENTGSA-Validate.ps1`** | Check each named §3 object exists and is wired (profiles on; app has segments + pilot assigned; filter linked to security profile; CA targets GSA, excludes break-glass); flag gaps | Read-only |
| **`ENTGSA-ConnectorHealth.ps1`** | Report Private Access connector groups and connector health/status before testing ZTNA reachability | Read-only |
| **`ENTGSA-Report.ps1`** | Run KQL against Log Analytics to export traffic evidence — top destinations, allowed vs blocked, per-user private-app access | Read-only (KQL) |
| **`ENTGSA-TrafficLogs.ps1`** | Focused KQL for blocked/denied flows and Private Access connection outcomes; optional CSV export | Read-only (KQL) |

All scripts use `Connect-MgGraph` / `Connect-AzAccount` with **least scopes**, contain **no credentials or
secrets**, and any change/remediation defaults to a **`-WhatIf` preview** gated behind an explicit
`-Commit`.

## Outcomes
- **VPN replaced by per-app ZTNA** — sessions reach only entitled apps; no flat network access.
- **Internet/SaaS traffic inspected** — a Secure Web Gateway with content filtering instead of blind egress.
- **Identity-conditioned network access** — Conditional Access + CAE applied to traffic, not just apps.
- **Full visibility** — every flow logged to Log Analytics and queryable for audit and IR.
- A **pilot-first**, gated, reversible rollout with a documented rollback and a VPN fallback.

## Assumptions & boundaries
- **Licensing** covers the in-scope users — Microsoft profile on **P1**; **Internet/Private Access** on the
  **Entra Suite** or add-ons — *verify current SKU coverage and preview status*.
- The **private apps** to publish and the **internet categories** to block are provided by the customer.
- **CA baseline design** (Zero Trust Conditional Access) and **app-auth migration** (AD FS → Entra SSO,
  App Proxy web publishing) are **separate adjacent solutions**.
- The **VPN-retirement timeline** and change approvals are the customer's network/security decisions.

> Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the full documentation set plus
> all five PowerShell tools in a single ZIP, yours to keep and reuse on every rollout.
