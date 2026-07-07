# Executive Summary

In an Exchange/Microsoft 365 **hybrid** environment, mail flow breaks in ways that are hard to trace:
messages leave via the wrong connector, an accepted domain typed incorrectly silently NDRs users still
hosted on-premises, centralized mail transport sends outbound the long way through on-prem, or a pair
of transport rules forms a routing loop. The result is intermittent, mysterious mail loss that costs
hours of investigation and erodes trust in the platform.

This solution converts that mystery into a **named, testable architecture** and a **repeatable
trace-to-root-cause method**. It maps hybrid mail flow end to end — the connector types (inbound/
outbound, on-prem↔EXO hybrid, partner) and when to use each, accepted domains and their routing types
(authoritative vs internal relay), routing topologies, the centralized-mail-transport decision, and
controlled transport rules — then provides a **layered diagnostic** (message trace → message headers →
queues/SMTP logs) that resolves "where did the message go?" in minutes, with evidence.

**Approach.** Delivery follows a pilot-first model — **Assess → Design → Configure → Pilot → Validate →
Expand** — with explicit pass/fail gates and a documented rollback at every step. Nothing changes for
everyone at once: the design is proven on a named pilot scope, validated against clear criteria
(mail routes correctly inbound/outbound/internal-relay, no loops, traces clean), and only then
expanded to production. Every connector, accepted domain, and transport rule is named with a consistent
convention and reused across testing, troubleshooting, and automation.

**Why it is low-risk.** Mail-flow, connector, DNS, and transport-rule changes are high-impact to
production mail, so the solution is engineered to protect it: a read-only baseline before any change, a
pilot gate before expansion, and per-change rollback. The five included PowerShell tools (Exchange
Online PowerShell V3 / Microsoft Graph) are **safe by default** — read-only or `-WhatIf` unless an
explicit apply/commit switch is passed — use modern authentication, and contain **no credentials or
secrets in code**. Vendor detail is taken from Microsoft's public documentation; version-, plan-, and
Government-cloud-dependent behavior is cited or flagged for tenant verification rather than assumed.

**Outcome.** Hybrid mail flow that **routes correctly and is diagnosable**: connectors of the right
type, accepted domains typed to reality, transport rules controlled and loop-free, the centralized-
transport decision made on purpose, and a repeatable method to trace any message to root cause — at a
fraction of the cost of an open-ended consulting engagement.
