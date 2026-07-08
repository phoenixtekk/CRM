# Executive Summary — Exchange Online DLP in Microsoft Purview

## The problem

Email is the top channel through which sensitive data leaves an organization — a list of card numbers
or national IDs attached to a message, a *Confidential* contract forwarded to an outside party, a
spreadsheet sent to a personal address. Left unaddressed, outbound email carrying regulated or
classified data is both a **compliance gap** and a direct **data-risk exposure**, and by default there
may be **nothing inspecting it** before it leaves.

## The solution

This solution delivers **Microsoft Purview Data Loss Prevention (DLP) for Exchange Online** end to end.
It inventories what already exists, then authors one Exchange DLP policy with rules covering the core
email scenarios — **sensitive information to external recipients** (warned at low volume, blocked at
high volume), **sensitivity-labeled mail to external recipients** (encrypted), and **sensitive
information to internal recipients** (audited) — each keyed to your sensitive content (sensitive
information types and/or sensitivity labels) and to the right recipient scope, with a **trusted-partner
exception** so sanctioned business flows are not disrupted, and **policy tips** that guide the sender at
the moment of *Send*. Crucially, every rule is **piloted in simulation/test mode first** — it records
what it *would* do without blocking or encrypting anyone — validated on a small sender ring, and only
then moved to **enforce**.

## How it works — the model

The delivery follows a disciplined, repeatable model with an explicit pass/fail gate at each step:

**Assess → Design → Configure → Pilot (simulation) → Validate → Expand (enforce).**

Because a DLP block stops a real message and an encrypt action changes how it is delivered, nothing is
enforced until it has been proven, in simulation, to match the right mail and act only on the right
content — with a one-command rollback available at all times.

## What you get

- A complete document set: Overview, Requirements, an ordered Implementation guide, Testing (pass/fail
  gates), Troubleshooting, Best Practices, and this summary.
- **Five PowerShell tools** (Security & Compliance PowerShell) — discovery, configuration (simulation,
  `-WhatIf` first, writes gated by `-Commit`), validation, reporting, and scope/health — all
  **read-only or preview by default, with no credentials in code.**
- A **defensibility evidence pack**: proof of what was configured, that each scenario was validated in
  simulation before enforcement, and that enforcement behaves as designed.

## Scope and boundaries

- DLP is **licensing-dependent** (advanced conditions/actions and message encryption may require
  Microsoft 365 E5 / E5 Compliance and enabled Purview Message Encryption) and the Purview portal
  **evolves** — capability availability and exact paths/parameters are **verified against your
  licensing/tenant**, never assumed.
- Exchange DLP **coexists with Exchange mail-flow (transport) rules**; overlaps are reconciled so the
  two controls do not conflict.
- **Regulatory, records, and legal determinations** — which data is sensitive, which scenarios must be
  blocked versus audited, whether a recipient domain is trusted, and whether a message is a violation —
  remain with your **compliance, security, records, privacy, and legal** functions. This solution
  provides the **technical method and the evidence**, not the determination.

## The bottom line

**Unmonitored outbound email** becomes a **monitored, then enforced** control set in Microsoft
Purview — **configured, piloted in simulation, validated, and defensible.**
