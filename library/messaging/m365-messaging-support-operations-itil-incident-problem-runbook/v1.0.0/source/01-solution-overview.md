# Solution Overview

## What this is

This is a **messaging-specific support-operations runbook** for a team that supports Microsoft 365
messaging — Exchange Online and/or Exchange **hybrid** (on-premises Exchange + Active Directory +
Azure AD Connect) — at **Level 2, Level 3, and Level 4**. It defines *how the support practice runs*:
who owns what across L2–L4, how issues escalate cleanly, how **ITIL incident management** and
**problem management** are applied to mail issues, how on-call and service-availability handling work,
how the team is measured (SLA, First-Call-Resolution, CSAT, reopen rate), and how the knowledge base
and coaching keep quality high. The outcome is a support team that delivers **to SLA with a positive
customer experience** through consistent operations rather than firefighting.

**Scope boundary — read this first.** This runbook is scoped to **messaging support operations**. It is
deliberately distinct from, and does **not** replace:

- A **general desktop / end-user-computing support runbook** (device, OS, general Office apps, printing,
  identity/password). This runbook covers mail-specific work — mailboxes, mail flow, connectors,
  hygiene, client mail connectivity, distribution/shared/resource mailboxes, archiving/retention as
  they surface in tickets.
- **Security incident response** (a confirmed breach, business email compromise as a *security event*,
  data-loss investigation, forensics, legal hold for litigation). When a messaging ticket is found to be
  a **security incident**, this runbook's job is to **recognize it and hand off** to the security
  incident-response process — it defines the trigger and the handoff, not the security investigation
  itself.

Where those adjacent processes touch messaging, this runbook names the **handoff**, not the other
team's internal steps.

## How it works — the messaging support operating model

The operating model has five interlocking parts. Each is defined in the Implementation Guide and named
with the house convention `<Purpose> – <Scope> – <Stage>`.

1. **Tiered responsibilities and escalation (L2–L4).** Clear ownership of what each tier does for mail
   issues and the exact criteria and path to escalate — so an issue moves up (or across to a vendor or
   an adjacent team) without bouncing.
2. **ITIL incident management for messaging.** A single, consistent lifecycle for a mail issue —
   *identify → log → categorize → prioritize → diagnose → resolve → close* — with a severity/priority
   matrix that reflects **mail-flow blast radius** (one mailbox vs a domain vs the whole org).
3. **ITIL problem management for messaging.** When incidents recur or a major incident lands, a
   **problem record** drives **root-cause analysis** and a permanent fix, with a **known-error** entry
   and workaround captured until the fix ships.
4. **On-call and service-availability handling.** A rota and paging discipline for after-hours major
   incidents, plus a defined way to consume Microsoft's **Service Health Dashboard** and **message-center
   advisories** so the team can tell *"Microsoft-side service issue"* from *"our misconfiguration"* fast.
5. **Quality and knowledge.** SLA governance, **First-Call-Resolution (FCR)**, **CSAT**, and
   **reopen-reduction** practices, backed by a living **knowledge base (KB)** and a **coaching /
   onboarding** workflow so new analysts ramp and quality compounds.

## The reference model

```
                         ┌──────────────────────────────────────────┐
   User / ticket  ─────► │  L1  (service desk — out of scope here;   │
                         │       creates ticket, first contact)      │
                         └───────────────┬──────────────────────────┘
                                         ▼
          ┌───────────────────────────────────────────────────────────┐
          │  L2 Messaging  — owns most mail tickets end to end:        │
          │  mailbox/permissions, single-user mail flow, client        │
          │  connectivity, quarantine release, basic transport checks. │
          │  Runs the incident lifecycle. First-Call-Resolution focus. │
          └───────────────┬───────────────────────────────────────────┘
             escalate on defined criteria │
                                          ▼
          ┌───────────────────────────────────────────────────────────┐
          │  L3 Messaging Engineering — connectors, transport rules,   │
          │  hygiene/anti-phish policy, hybrid mail flow, DKIM/DMARC,   │
          │  archiving/retention, major-incident technical lead,       │
          │  owns Problem records + root-cause.                        │
          └───────────────┬───────────────────────────────────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
   ┌────────────────────┐   ┌────────────────────────────────────────┐
   │ L4 / Vendor        │   │ Adjacent handoffs (defined, not owned): │
   │ Microsoft support  │   │  • Security Incident Response (BEC/     │
   │ + 3rd-party gateway│   │    breach)                              │
   │/archive/signature  │   │  • Identity / directory team (AAD       │
   │ vendor support     │   │    Connect, ADFS)                       │
   └────────────────────┘   │  • Networking/DNS owners                │
                            └─────────────────────────────────────────┘
```

- **L2 (Messaging Support Analyst)** — the front line for mail tickets. Resolves the common,
  well-documented issues from the KB (mailbox access/permissions, shared/resource mailbox setup,
  single-user send/receive failures, quarantine/junk questions, client profile issues, distribution
  group membership). Owns the **incident record** and drives First-Call-Resolution.
- **L3 (Messaging Engineer)** — deep Exchange/EOP/Defender/hybrid work: connectors, transport
  (mail-flow) rules, anti-spam/anti-phish/anti-malware policy, DKIM/DMARC, accepted domains, hybrid and
  Edge transport, archiving/retention. Acts as **technical lead on major incidents** and **owns Problem
  records** and root-cause analysis.
- **L4 (Vendor / Escalation)** — Microsoft support (via the M365 admin center **Support** experience or
  Premier/Unified) for suspected service-side or product defects, and third-party vendor support for
  gateway/archive/signature products. L4 is *engaged by* L3, not by users directly.

## Benefits

- **Predictable SLA delivery** — a single incident lifecycle and a mail-aware priority matrix mean
  tickets are handled consistently and to time.
- **Fewer repeat incidents** — problem management converts recurring pain into permanent fixes and
  known-error workarounds.
- **Clean escalation** — explicit L2→L3→L4 criteria stop the "hot-potato" bouncing that frustrates
  users and burns time.
- **Faster "is it us or Microsoft?" calls** — a disciplined way to read the Service Health Dashboard and
  advisories shortens major-incident triage.
- **Higher CSAT and FCR** — reopen-reduction and knowledge practices raise both the numbers and the felt
  experience.
- **Faster onboarding** — a KB + coaching workflow ramps new analysts and preserves institutional
  knowledge.

## Limitations and boundaries

- This is an **operating-model and process** solution with supporting automation — it does **not**
  configure your mail hygiene, connectors, or authentication (those are separate messaging solutions);
  it defines how the **support team operates** the running service.
- It assumes a **ticketing / ITSM tool** exists (or is stood up per Requirements). It is **tool-agnostic**
  — it defines the process and metrics, not a specific ITSM product's clicks. ITSM-vendor consoles are
  deferred to that vendor's own documentation.
- The included PowerShell tools are **read-only or `-WhatIf` by default** and support triage,
  reporting, and health checks. They are **operational aids**, not a replacement for the ITSM tool or
  for Microsoft's own portals.
- **Security incident response is out of scope** (see boundary above) — this runbook recognizes and
  hands off, it does not investigate.
- **Commercial vs Government cloud:** portal URLs and some endpoints differ on **GCC / GCC High / DoD**
  (e.g. `*.office365.us`, `admin.exchange.microsoft.us`, Graph `graph.microsoft.us`). Where a step or
  script names a URL/endpoint, government-cloud equivalents are flagged — **verify the correct
  sovereign-cloud endpoint for your tenant**.

## Deployment model

Even though this is a process runbook, it is rolled out with the same house model used for every
messaging change, because standing up on-call, escalation, and metrics **touches production support**:

**Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with explicit pass/fail gates
and a documented rollback.

- **Assess** — inventory current tickets, tools, tiers, SLAs, and pain (repeat incidents, reopen rate).
- **Design** — define L2–L4 responsibilities, escalation criteria, the priority matrix, on-call rota,
  and the metric targets.
- **Configure** — build the runbooks, ticket categories/priorities, KB structure, and the reporting.
- **Pilot** — run the new model on a **named pilot scope** (one queue / one region / one shift) for a
  defined window.
- **Validate** — measure against the **pass/fail gates** (SLA attainment, escalation-accuracy, reopen
  rate, CSAT) before expanding.
- **Expand** — roll to the full team; keep improving via problem management and coaching.

The **rollback** for this rollout is documented in the Implementation Guide: because the change is
operational (process, categories, rota), rollback means reverting to the previously documented
process/queue configuration and pausing the new gates — no production mail-flow object is changed by
adopting the runbook itself.
