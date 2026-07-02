# Solution Overview

## What this solution is

This is a **runbook library** — a set of standardized, step-by-step diagnostic-to-resolution
procedures for the desktop issues a Tier-1/Tier-2 technician handles on an **Intune-managed
Windows fleet**. Instead of every technician improvising, the library gives each common problem
category a single repeatable path: **triage tree → checks → resolution → escalation gate →
evidence to collect**.

The goal is simple: any technician, at any skill level, can pick up a ticket, follow the matching
runbook, and either resolve the issue the same way every other technician would, or escalate it
with the right evidence already attached. Problems get **owned end to end** instead of bounced
between tiers.

This library is deliberately **white-label and vendor-neutral**. It documents the Microsoft
Intune, Microsoft Entra, and Windows steps at exact click-by-click detail. Where a third-party
product (a specific antivirus console, a specific VPN client, a specific line-of-business app) is
involved, the runbook tells you *what* to check and *when* to hand off to that vendor's own
documentation, rather than guessing at another product's internals.

## The support operating model

Every runbook in this library follows the same five-stage operating model. Learn it once and it
applies to every category.

1. **Intake** — Capture the ticket cleanly. Who is the user, which device (Intune device name /
   serial), what exactly is happening, when did it start, and how many people are affected
   (one user, one device, one location, or the whole fleet). Scope decides everything downstream.
2. **Triage** — Use the runbook's **triage tree** to classify the issue into a category and a
   likely cause branch. Triage answers: *which runbook applies, and which branch of it?*
3. **Diagnose** — Run the runbook's **checks** in order. Each check is a read-only observation
   (a signal in Intune, Entra, or on the device) that confirms or rules out a cause. You stop
   when a check identifies the cause.
4. **Resolve or Escalate** — If the identified cause has a **resolution** in the runbook, apply
   it (least-disruptive fix first). If the cause is past the runbook's **escalation gate** — it
   needs rights you don't have, changes that affect others, or another team's system — escalate.
5. **Document** — Record what you observed, what you did, and the outcome, using the runbook's
   **evidence to collect** list. Good documentation is what lets the next technician (or the
   escalation target) continue without redoing your work.

```
  INTAKE  ->  TRIAGE  ->  DIAGNOSE  ->  RESOLVE ── or ──> ESCALATE
    |          (tree)     (checks)    (fix)              (gate)
    +----------------------- DOCUMENT (evidence) -------------------+
```

## How it maps to an Intune-managed fleet

On an Intune-managed fleet, the technician has three sources of truth, and every runbook draws on
them in the same order:

- **Microsoft Intune admin center** (`https://intune.microsoft.com`) — the device's management
  state: enrollment, compliance, assigned policies and apps, hardware inventory, and (with the
  right licensing) endpoint analytics and remote actions like **Sync**, **Restart**, and
  **Collect diagnostics**.
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) — the identity side: the user
  account, group memberships (which drive policy/app targeting), sign-in logs, and device join
  state.
- **The device itself** — reached through **Remote Help** (attended) or read-only signals; local
  tools such as **Settings → Accounts → Access work or school**, **Event Viewer**, **dsregcmd**,
  and the **Company Portal** app.

Because targeting on this fleet is **group-based**, a recurring diagnostic question across almost
every runbook is: *is this device/user in the right Entra group to receive the policy or app in
question?* The runbooks make that check explicit rather than assuming it.

## How the runbooks are structured

Every runbook in the Runbook Library uses the same fixed anatomy so a technician always knows
where to look:

- **Scope / symptoms** — the user-visible symptoms this runbook covers, and what it does *not*
  cover (with a pointer to the correct runbook).
- **Triage tree** — a short branching decision that narrows the issue to a probable cause path
  and tells you which checks to run first.
- **Checks** — an ordered list of read-only observations. Each check names exactly where to click
  and what a healthy vs. unhealthy result looks like.
- **Resolution** — the fix for each identified cause, least-disruptive first, written as
  click-to-implement steps.
- **Escalation gate** — the explicit line: what conditions mean *stop and escalate*, to whom, and
  what to hand over.
- **Evidence to collect** — the specific artifacts (screenshots, IDs, log names, timestamps) to
  attach to the ticket regardless of outcome.

The remaining documents build on this overview: **Requirements** (what a technician needs before
using the library), the **Runbook Library** itself (the categorized runbooks), **Testing**
(pass/fail gates that prove each runbook works), **Troubleshooting** (cross-cutting edge cases),
and **Best Practices** (how to keep triage consistent, evidence complete, and escalations clean).
