# Executive Summary — SASE / SSE Architecture & Design Blueprint

## The situation

Most organizations did not *decide* on an edge-security architecture — they accumulated one. A secure
web gateway was bought to satisfy an audit finding; a Zero Trust access tool was added when VPN
buckled; a cloud-app discovery product arrived with a different team; SSL inspection was switched on
in one place and not another. The result is a set of overlapping, inconsistently configured edge
controls that are expensive to license, hard to operate, and impossible to reason about as a whole.
Policy lives in several consoles, identity is wired in differently to each, and nobody can answer the
simple question: *for this user, on this device, going to this destination, which control decides, and
why?*

The remedy is not another point product. It is a **coherent reference architecture** that ties the
edge services together under one model, with **identity as the control plane**, a **phased adoption
roadmap** so the move is staged rather than disruptive, and a **target operating model** that names
who runs it and how success is measured.

## The solution

This blueprint delivers exactly that — a repeatable, vendor-aligned design for a Secure Access Service
Edge / Security Service Edge estate that unifies five capability areas:

- **Secure Web Gateway (SWG)** — inline inspection and policy for web and SaaS traffic.
- **Zero Trust Network Access (ZTNA)** — identity- and device-aware access to private applications,
  replacing broad VPN network access.
- **Cloud Access Security Broker (CASB)** — visibility and control over sanctioned and unsanctioned
  cloud applications (inline and, where applicable, API-based).
- **SSL/TLS inspection** — the decryption foundation that makes the other controls effective, with a
  governed exception model.
- **Data-protection-adjacent controls (DLP-adjacent)** — content-aware policy hooks positioned in the
  architecture (the deep DLP build is a separate program; here it is *designed in*, not detailed).

These are bound together by **identity** (Microsoft Entra ID) as the single control plane for who a
user is, what device they are on, and which policy applies — and delivered through a phased roadmap
proven on a **pilot phase** before any expansion.

## What you get

- A plain-language **Solution Overview** of the SASE/SSE model and *why* it beats piecemeal edge security.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (Netskope tenant
  and modules, Entra ID identity, endpoint management, network/egress inputs, executive sponsorship).
- An **Implementation Guide** that names the **reference architecture**, the **policy model**, the
  **roadmap phases**, and the **operating-model roles**, then walks Assess → Configure → Pilot →
  Validate → Expand with an explicit pilot-phase gate.
- Five **PowerShell scripts** for current-state edge/identity discovery, architecture-readiness
  validation, a capability-coverage and gap report, safe remediation of configuration gaps, and a
  phase-scope group builder.
- **Testing** and **Troubleshooting** guides with pass/fail gates, plus field-proven **Best Practices**.

## The standard deployment model

**Assess → Configure → Pilot → Validate → Expand** — with a hard pilot-phase gate before expansion.

## The outcome

One coherent SASE/SSE architecture — SWG, ZTNA, CASB, SSL inspection, and identity-based policy
designed as a single operating model with a phased roadmap — replacing piecemeal edge security, with
a named operating model and measurable KPIs, proven on a pilot phase before you scale.
