# Executive Summary — Vendor Technical Governance & Anti-Lock-In Playbook (Google + Systems Integrators)

White-label · Google

On a large Google Workspace and Gemini transformation, the people doing the work are usually not
your people. Google's delivery teams and one or more systems integrators drive the design, the
migration, and the integration build. Left ungoverned, this quietly erodes architectural control:
decisions get made inside vendor design documents, defaults get accepted under schedule pressure,
and proprietary shortcuts get baked in because they are the fastest path for the party being paid to
finish. The result is an estate the enterprise did not really design, cannot easily change, and
cannot affordably leave.

This is a complete, deploy-it-today playbook that makes the enterprise architect the **primary
technical counterpart** to those partners. It gives you a repeatable operating model to validate
vendor assumptions before they harden, review vendor designs against your target architecture, apply
an explicit anti-lock-in bar to every design, and keep a clean separation between **vendor execution
responsibility** and **enterprise architectural authority** — so partners deliver sustainable
solutions without fragmentation or lock-in.

## What you get
- A plain-language Solution Overview of the operating model between the enterprise architect and
  partners, where architectural authority sits, and the durable artifacts the method names and
  reuses (Target Architecture Baseline, Anti-Lock-In Criteria, Vendor Assumption Log, Design Review
  Record, Governance RACI, Vendor-Governance Runbook).
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide containing the vendor-design review method, the four-part **Anti-Lock-In
  Criteria** checklist (portability, data ownership, standards conformance, exit criteria), the
  **Governance RACI** that separates execution from authority, and the escalation path — in ordered
  steps.
- Five PowerShell scripts for design-register discovery, anti-lock-in conformance validation, a
  review/finding report, remediation-action recording, and a reviewer/pilot scope builder.
- Testing and Troubleshooting guides — governance and conformance gates, and how to handle
  non-conformant designs.

## What this delivers
A governed partner delivery model — every vendor design reviewed against a fixed anti-lock-in bar
and dispositioned by the enterprise, assumptions validated before they become constraints,
non-conformant designs escalated rather than waved through, and a clean, signed RACI keeping
execution and architectural authority separate — proven on a pilot design before it gates every
workstream.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Vendor execution that aligns to the target architecture — no long-term lock-in, no fragmentation —
with architectural control firmly held by the enterprise.
