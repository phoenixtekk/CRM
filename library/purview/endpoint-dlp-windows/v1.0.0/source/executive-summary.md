# Executive Summary — Endpoint DLP for Windows in Microsoft Purview

## The problem

Sensitive data leaves Windows laptops through **local** channels that server-side controls never
see: copied to a **USB stick**, sent to a **printer**, lifted through the **clipboard** into personal
webmail, dropped onto an **unmanaged network share**, or **uploaded** to a personal cloud account in
a browser. Email and SharePoint DLP are blind to all of it — these actions happen entirely on the
device. Left unaddressed, that is both a **compliance gap** and a direct **data-risk exposure**.

## The solution

This solution delivers **Microsoft Purview Endpoint DLP for Windows** end to end. It **onboards**
Windows devices so those on-device activities become visible to Purview, configures the endpoint
settings that define sanctioned USB devices / printers / shares / browsers / cloud domains, and
authors a policy with rules for the **five egress channels — USB, print, clipboard, network share,
and cloud egress** — keyed to your sensitive content (sensitivity labels and/or sensitive information
types). Crucially, every rule is **piloted in simulation/test mode first** — it records what it
*would* do without blocking anyone — validated on a small device ring, and only then moved to
**enforce**.

## How it works — the model

The delivery follows a disciplined, repeatable model with an explicit pass/fail gate at each step:

**Assess → Design → Configure → Pilot (simulation) → Validate → Expand (enforce).**

Because endpoint block actions stop work at the moment of the action, nothing is enforced until it
has been proven, in simulation, to see the right channels and act only on the right content — with a
one-command rollback available at all times.

## What you get

- A complete document set: Overview, Requirements, an ordered Implementation guide, Testing
  (pass/fail gates), Troubleshooting, Best Practices, and this summary.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph) — discovery,
  configuration (simulation, `-WhatIf` first), validation, reporting, and scope/health — all
  **read-only or preview by default, with no credentials in code.**
- A **defensibility evidence pack**: proof of what was configured, that each channel was validated in
  simulation before enforcement, and that enforcement behaves as designed.

## Scope and boundaries

- Endpoint DLP is **licensing-dependent** (typically Microsoft 365 E5 / E5 Compliance / E5
  Information Protection & Governance) and the Purview portal **evolves** — capability availability
  and exact paths are **verified against your licensing/tenant**, never assumed.
- **Regulatory, records, and legal determinations** — which data is sensitive, which channels must be
  blocked versus audited, and whether an action is a violation — remain with your **compliance,
  security, records, privacy, and legal** functions. This solution provides the **technical method
  and the evidence**, not the determination.

## The bottom line

A set of **uncontrolled local exfiltration paths** on Windows endpoints becomes a **monitored, then
enforced** control set in Microsoft Purview — **configured, piloted in simulation, validated, and
defensible.**
