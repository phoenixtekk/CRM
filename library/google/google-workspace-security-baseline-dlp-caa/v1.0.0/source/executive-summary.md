# Executive Summary — Google Workspace Security Baseline, DLP & Context-Aware Access (CAA)

## The problem
A new or freshly-adopted Google Workspace tenant is **not secure by default at enterprise standard**.
Out of the box, two-step verification is optional, web sessions are effectively indefinite, Drive and
Gmail sharing is wide open, there is no Data Loss Prevention on sensitive content, and access is
granted from **any device on any network**. Each of those defaults is a direct path to account
takeover or data loss — and they persist silently until an incident exposes them.

## The solution
This solution establishes a repeatable **Google Workspace security posture** in three reinforcing
layers, deployed **pilot-first** and **rollback-ready**:

1. **Admin-console hardening baseline** — enforced 2-Step Verification (security key / passkey for
   privileged accounts), bounded reauthentication sessions, tightened Drive/Gmail sharing, and closed
   legacy authentication surfaces.
2. **Data Loss Prevention (DLP)** — named rules that scan **Drive** and **Gmail** for sensitive
   content (card numbers, national IDs, financial/health data, or custom detectors) and take a graded
   **audit → warn → block** action.
3. **Context-Aware Access (CAA)** — the Zero-Trust gate: access to apps is granted only from a
   **trusted context** (corporate network, managed/encrypted device, allowed region), simulated in
   **monitor mode** before it is enforced.

Together they move the tenant from *implicit trust* to **explicit, contextual, data-aware trust** —
verifying identity, device/context, and data on every access.

## How it is delivered
The engagement follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model with
explicit pass/fail gates and a documented rollback for every production change. Every control is
proven on a curated **pilot organizational unit** before it touches the fleet, then rolled out OU by
OU. Five PowerShell scripts (read-only discovery, validation, and reporting; safe default-`-WhatIf`
remediation and scope targeting) make the posture measurable and repeatable.

## Business outcome
- **Reduced account-takeover risk** — enforced phishing-resistant 2SV and bounded sessions.
- **Reduced data-loss risk** — DLP prevents sensitive content from being over-shared or emailed out,
  even by legitimately authenticated users.
- **Zero-Trust access** — CAA ensures corporate data opens only from trusted devices and networks.
- **Provable, auditable posture** — validation and coverage reporting show exactly what is enforced,
  where, and which exceptions are tracked.

## Scope note
The hardening baseline applies to **every** Workspace edition. **DLP for Drive/Gmail rule authoring
and Context-Aware Access are edition-gated** (Enterprise / Education tiers) and are flagged as such —
confirm your licensing covers the layers you intend to enforce.

**Bottom line:** a Google Workspace tenant hardened to enterprise standard — baseline, DLP, and
Context-Aware Access enforcing Zero-Trust — proven on a pilot before you scale.
