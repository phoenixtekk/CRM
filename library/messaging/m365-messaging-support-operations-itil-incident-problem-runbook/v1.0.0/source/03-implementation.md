# Implementation Guide

This guide stands up the messaging support operating model following the house model
**Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with explicit pass/fail
gates and a documented rollback. Every artifact — runbook, ticket category, priority level, escalation
path, KB structure, report — is **named** with the convention `<Purpose> – <Scope> – <Stage>` and that
exact name is reused in Testing, Troubleshooting, and the scripts.

> Because this rollout is **operational** (process, ticket categories, rota, metrics), it does not
> change any production mail-flow object. The rollback is therefore a **process rollback** (revert to
> the previously documented process and pause the new gates), defined at the end of this guide.

---

## Stage 0 — Assess (baseline the current support practice)

**Goal:** know where you are before changing anything.

1. Pull a recent **ticket export** (last full month) from the ITSM tool as CSV (per Requirement R1).
2. Run the Reporting script to compute the current baseline:
   `.\Get-MessagingSlaMetricsReport.ps1 -TicketCsv .\tickets-lastmonth.csv` — capture SLA attainment,
   FCR, CSAT, and reopen rate.
3. Run the recurring-incident analyzer to find your top repeat offenders:
   `.\Find-RecurringMessagingIncidents.ps1 -TicketCsv .\tickets-lastmonth.csv` — these become the first
   Problem candidates.
4. Inventory current tiers, tools, SLAs, on-call arrangement, and KB state.

**Assess artifacts:** `Baseline Metrics – Messaging Support – Assess`,
`Repeat-Incident Candidates – Messaging – Assess`.

---

## Stage 1 — Design (define the model)

### 1.1 Tiered responsibilities — L2 / L3 / L4

Define, in writing, what each tier owns for **messaging** work. Publish as the runbook
`Tier Responsibilities – Messaging – Design`.

| Tier | Owns (messaging) | Does NOT own |
|------|------------------|--------------|
| **L2 Messaging Support Analyst** | Mailbox access & permissions (full-access/send-as/send-on-behalf), shared/resource mailbox setup, single-user send/receive failures, quarantine release & junk questions, client mail profile (Outlook/OWA/mobile) connectivity, distribution-group membership, basic single-user mail-flow checks (message trace for one sender/recipient), out-of-office/forwarding. Owns the **incident record**; drives FCR. | Broad transport-rule / connector / hygiene-policy changes; hybrid config; DKIM/DMARC changes; problem/root-cause ownership. |
| **L3 Messaging Engineer** | Connectors, transport (mail-flow) rules, anti-spam/anti-phish/anti-malware policy, DKIM/DMARC, accepted domains, hybrid & Edge transport, archiving/retention config, org-wide message-trace analysis. **Technical lead on major incidents.** **Owns Problem records + root-cause.** | User-by-user password/identity resets (identity team); security-breach investigation (security IR). |
| **L4 Vendor / Escalation** | Microsoft support engagement for suspected service-side defects; third-party vendor support (gateway, archive, signature). **Engaged by L3**, not by users. | Day-to-day ticket handling. |

### 1.2 Escalation paths and criteria

Publish `Escalation Matrix – Messaging – Design`. Escalation is **criteria-based**, not effort-based —
an analyst escalates when a **defined condition** is met, not merely when "stuck".

- **L2 → L3 when any of:** the fix requires a change to a **connector / transport rule / hygiene policy /
  accepted domain / DKIM-DMARC / hybrid config**; the issue affects **more than one mailbox / a whole
  domain / the org**; message trace shows a **transport-side** failure L2 cannot resolve; or the agreed
  **L2 time-box** for the priority is exceeded.
- **L3 → L4 (Microsoft) when:** evidence points to a **service-side issue or product defect** (Service
  Health shows a related incident, or behavior contradicts documented product behavior and is
  reproducible), and L3 has collected the diagnostic bundle (message trace, timestamps, message IDs,
  affected recipients, `Get-` output).
- **L3 → L4 (third-party vendor) when:** the failure is isolated to a gateway/archive/signature product.
- **Cross-hand-off (not an escalation up the mail tier):** if the ticket is a **security incident**
  (see 1.5), hand off to **Security Incident Response**; if it is an **identity/directory** problem
  (AAD Connect sync, ADFS), hand to the identity team; if **DNS/network**, to those owners.

Every escalation must carry the **diagnostic bundle** (see the KB template in 3.4) so the receiving tier
does not restart triage.

### 1.3 Priority / severity matrix (mail-flow blast radius)

Publish `Priority Matrix – Messaging – Design`. Priority is driven by **blast radius + business impact**,
because a mail issue's severity is defined by *how much mail it stops*.

| Priority | Definition (messaging) | Example |
|----------|------------------------|---------|
| **P1 / Critical** | Org-wide or domain-wide mail flow down, or inbound/outbound mail failing for a large population; major security-relevant mail event in progress. | No mail in or out for the tenant; accepted domain not delivering. |
| **P2 / High** | A department, site, or shared business mailbox affected; a connector or transport rule misbehaving for a group; delayed mail queues building. | A partner inbound connector rejecting; a distribution list not delivering. |
| **P3 / Medium** | Single-user send/receive problem, mailbox-permission issue, client connectivity for one user. | One user can't send externally; full-access permission not applied. |
| **P4 / Low** | Cosmetic / how-to / non-blocking request. | "How do I set an auto-reply?"; signature question. |

Attach **response** and **resolution** SLA targets per priority (from Requirement R6) to this matrix.

### 1.4 On-call and service-availability handling

Publish `On-Call Runbook – Messaging – Design`.

- **Rota:** primary + secondary per period (from R4), paging order, and the *"page on P1, and on P2 that
  is trending to P1"* trigger. Business-hours issues follow the normal queue; after-hours **P1/P2** page
  on-call.
- **Service-availability first step (every suspected outage):** before deep troubleshooting, **check
  Microsoft service health**. Two paths:
  - Portal: M365 admin center → **Health → Service health** (Government: `admin.microsoft.us`), and the
    **Message center** for advisories/changes. **Verify the correct URL for your cloud.**
  - Script: `.\Get-ServiceHealthTriage.ps1` (reads the Service Communications API via Graph) to list
    active **Exchange Online** service issues and advisories in one place.
- **The rule:** if Service Health shows a **matching active incident**, the ticket is annotated
  *"Microsoft-side — tracking MS incident <ID>"*, communications go out, and the team **monitors**
  rather than chasing a local root cause. If Service Health is **green**, treat it as a local issue and
  proceed with local diagnosis. This single discipline is the fastest "is it us or Microsoft?" gate.

### 1.5 Security hand-off trigger (recognize, don't investigate)

Publish `Security Handoff – Messaging – Design`. If a messaging ticket shows any of: reported/suspected
**business email compromise** (unexpected mailbox rules, mass external forwarding, mailbox sending spam),
credential compromise, confirmed data exfiltration via mail, or an in-progress phishing campaign that is
succeeding — **do not investigate as a support incident.** Capture the immediate facts, apply only the
**agreed containment step the security team pre-authorizes** (if any — e.g. do not delete evidence), and
**hand off to Security Incident Response** with the record ID. Document the handoff on the incident.

---

## Stage 2 — Configure (build the model in the tools)

### 2.1 Ticket categories, priorities, and assignment groups (ITSM tool)

In the ITSM tool, create the **categories** (mirror the KB structure in 3.4): *Mailbox & Permissions*,
*Mail Flow (single user)*, *Mail Flow (transport/connector)*, *Hygiene / Quarantine / Anti-Phish*,
*Client Connectivity*, *Distribution/Shared/Resource*, *Archiving/Retention*, *Service Availability*,
*Security Handoff*. Create the **priorities** P1–P4 from the Priority Matrix with their SLA timers.
Create **assignment groups** `Messaging-L2` and `Messaging-L3`. Name this configuration record
`Ticket Taxonomy – Messaging – Configure`.

> Use the KB/runbook config helper to generate a **starter taxonomy + KB skeleton** as JSON/Markdown to
> import or copy into your tools: `.\New-MessagingRunbookConfig.ps1 -OutputPath .\runbook-config`.

### 2.2 Incident-management lifecycle

Publish `Incident Lifecycle – Messaging – Configure`, a single flow every mail incident follows:
**Identify → Log → Categorize (2.1) → Prioritize (Priority Matrix) → Diagnose → Resolve → Close**, with:
- **Log** — always create the record (even for FCR-at-first-contact) so metrics are complete.
- **Diagnose** — start from the KB article for the category; for suspected outages run the
  service-availability first step (1.4) **before** local diagnosis.
- **Resolve** — apply the fix at the correct tier; record the resolution and the KB article used.
- **Close** — set closure code, confirm with the user where the SLA requires it, and record CSAT.

### 2.3 Problem-management lifecycle

Publish `Problem Lifecycle – Messaging – Configure`. A **Problem record** is opened when either:
(a) the recurring-incident analyzer or the team flags **repeat incidents** over threshold, or
(b) a **major incident (P1/P2)** closes and requires root-cause. The lifecycle:
**Detect → Log Problem → Investigate & Diagnose (root-cause) → Raise Known-Error + Workaround → Fix
(via change control) → Verify → Close**, with:
- **Root-cause** documented (the "5 whys" or equivalent) — the *permanent* cause, not the symptom.
- **Known-Error record + Workaround** published to the KB immediately so L2 can mitigate recurrences
  while the fix is pending.
- **Fix** implemented under **change control** (mail-flow/connector/policy changes are high-impact).
- **Verify** the fix stopped the recurrence (re-run the analyzer next period).

### 2.4 KB and coaching/onboarding workflow

Publish `KB Structure – Messaging – Configure` (categories mirror 2.1; each article carries
**owner + next-review date + version**) and `Coaching Onboarding – Messaging – Configure`:
- **KB article template** (per category): Symptom → Preconditions/scope → Diagnostic steps (portal +
  EXO PowerShell) → Resolution → When to escalate (with the **diagnostic bundle** to attach) → Related
  Known-Errors.
- **Onboarding path** for a new analyst: shadow → reverse-shadow → solo-with-review over a defined ramp;
  a checklist of the core KB articles and the tools (including the five scripts) they must run.
- **Coaching loop:** periodic **ticket-quality reviews** and **reopen reviews** (why did it reopen?),
  feeding corrections back into the KB.

### 2.5 Metrics and reporting

Publish `Metrics Report – Messaging – Configure`. Define the four managed metrics and how each is
computed from the ticket export, then schedule `Get-MessagingSlaMetricsReport.ps1` to run against a
periodic export:
- **SLA attainment** — % of tickets meeting response and resolution targets per priority.
- **First-Call-Resolution (FCR)** — % resolved at first contact without escalation/reopen.
- **CSAT** — average satisfaction on closed tickets.
- **Reopen rate** — % of closed tickets reopened within the window (a lagging quality signal).

---

## Stage 3 — Pilot (prove it on a named scope)

1. Choose the **pilot scope** (`Support Pilot – <Queue/Region/Shift> – Pilot`) — one queue, one region,
   or one shift — per Requirement (global) R6.
2. Run the full model on the pilot scope for a **defined window** (e.g. 2–4 weeks): new categories,
   priority matrix, incident + problem lifecycles, on-call trigger, KB template, and reporting.
3. Hold **daily stand-ups** on the pilot queue; open Problem records for any repeat incident.

---

## Stage 4 — Validate (pass/fail gates)

Do not expand until the pilot meets the gates. Record results in `Validation Gates – Messaging –
Validate`.

**Pass/fail gates (all must pass):**
- **G1 — SLA attainment** for the pilot scope ≥ the agreed target (from R6).
- **G2 — Escalation accuracy** ≥ target: sampled escalations met the L2→L3 criteria (no premature or
  missed escalations) — the escalation matrix is being followed.
- **G3 — Reopen rate** for the pilot ≤ baseline (from Stage 0) — quality did not regress.
- **G4 — Problem loop working:** at least the top repeat-incident candidate from Stage 0 has a Problem
  record with a documented root-cause (or a Known-Error + workaround if the fix is pending).
- **G5 — Coverage:** every pilot ticket category has a current KB article; CSAT captured on closed
  pilot tickets.

If any gate fails, **stay in Pilot**, fix the cause (e.g. tune the priority matrix, clarify an
escalation criterion, add missing KB), and re-measure.

---

## Stage 5 — Expand

1. Roll the validated model to the **full messaging support team**.
2. Move the reporting from pilot-scope to team-wide; set the recurring cadence (weekly ops review,
   monthly metric review).
3. Keep the **continual-improvement loop** running: recurring-incident analysis → Problem records →
   root-cause fixes → KB updates → coaching. Reopen and repeat-incident trends should decline over time.

---

## Rollback (process rollback)

Because adopting this runbook changes **process and tool configuration**, not production mail flow, the
rollback is:

1. **Pause the new gates** and revert the ITSM tool's categories/priorities/assignment groups to the
   previously documented configuration (keep a pre-change export of the taxonomy so this is a restore,
   not a rebuild).
2. Revert to the **previously documented** escalation and on-call arrangement.
3. Keep any **Problem records / KB articles** already created (they are additive and harmless).
4. Record the rollback reason as a Problem input so the next attempt improves.

No connector, transport rule, hygiene policy, DNS record, or authentication setting is created or
changed by adopting this runbook, so there is nothing to un-configure on the mail platform itself.
