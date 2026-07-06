# Solution Overview

## What this solution is

This is a **runbook library and enablement kit** — a set of standardized, step-by-step
procedures for managing and supporting **Intune-managed Macs**, plus the training and
feature-evaluation guidance that keeps a support team consistent over time. Instead of every
technician improvising (or the knowledge living in one engineer's head), each common macOS task
and problem category gets a single repeatable path: **triage tree → checks → resolution →
escalation gate → evidence to collect**.

The goal is simple: any technician, at any skill level, can pick up a Mac ticket or a Mac
onboarding task, follow the matching runbook, and either complete it the same way every other
technician would, or escalate it with the right evidence already attached. macOS work gets
**owned end to end** instead of bounced or improvised.

This library is deliberately **white-label and vendor-neutral**. It documents the Microsoft
Intune, Microsoft Entra, and Apple Business Manager (ABM) steps at exact click-by-click detail.
Where a third-party product (a specific SSO extension, a specific line-of-business app, an MDM
migration tool) is involved, the runbook tells you *what* to check and *when* to hand off to that
vendor's own documentation, rather than guessing at another product's internals.

> **A note on macOS specifics:** macOS management has moving parts Windows does not — Automated
> Device Enrollment (ADE) driven by Apple Business Manager, FileVault and its **SecureToken /
> bootstrap token** model, Platform SSO, VPP app licensing, and local-account nuances. Where a
> step depends on a fast-changing Apple or Intune behavior, the runbook flags it and points you to
> the vendor documentation to confirm before relying on it. **Flagged as uncertain:** exact menu
> paths in Apple Business Manager and the Intune admin center change periodically — confirm the
> current path in the console if a label has moved.

## The macOS support operating model

Every runbook in this library follows the same five-stage operating model. Learn it once and it
applies to every category.

1. **Intake** — Capture the ticket or task cleanly. Who is the user, which Mac (Intune device
   name / serial), what exactly is happening or is being requested, when did it start, and how
   many people are affected (one user, one device, one location, or the whole Mac fleet). Scope
   decides everything downstream.
2. **Triage** — Use the runbook's **triage tree** to classify the issue into a category and a
   likely cause branch. Triage answers: *which runbook applies, and which branch of it?*
3. **Diagnose** — Run the runbook's **checks** in order. Each check is a read-only observation
   (a signal in Intune, Entra, ABM, or on the Mac) that confirms or rules out a cause. You stop
   when a check identifies the cause.
4. **Resolve or Escalate** — If the identified cause has a **resolution** in the runbook, apply
   it (least-disruptive fix first). If the cause is past the runbook's **escalation gate** — it
   needs rights you don't have, changes that affect others, or another team's system (and, on a
   Mac, anything that risks FileVault data) — escalate.
5. **Document** — Record what you observed, what you did, and the outcome, using the runbook's
   **evidence to collect** list. Good documentation is what lets the next technician (or the
   escalation target) continue without redoing your work — and it feeds the enablement loop
   (see Best Practices).

```
  INTAKE  ->  TRIAGE  ->  DIAGNOSE  ->  RESOLVE ── or ──> ESCALATE
    |          (tree)     (checks)    (fix)              (gate)
    +----------------------- DOCUMENT (evidence) -------------------+
```

## How it maps to an Intune-managed Mac fleet

On an Intune-managed Mac fleet, the technician has four sources of truth, and every runbook draws
on them in the same order:

- **Microsoft Intune admin center** (`https://intune.microsoft.com`) — the Mac's management
  state: enrollment, compliance, assigned configuration profiles and apps, hardware inventory,
  and remote actions such as **Sync**, **Restart**, **Rotate FileVault key**, and
  **Collect diagnostics**.
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) — the identity side: the user
  account, group memberships (which drive policy/app targeting), sign-in logs, Conditional Access,
  and device registration state.
- **Apple Business Manager** (`https://business.apple.com`) — the Apple side of enrollment: which
  Macs are assigned to the Intune MDM server, VPP app licenses (**Apps and Books**), and the ADE
  token. This is unique to Apple platforms and has no Windows equivalent.
- **The Mac itself** — reached through an approved remote-control tool (with user consent) or
  read-only signals; local tools such as **System Settings → General → Device Management**,
  the **Company Portal** app, **Console.app**, and Terminal commands like `profiles status`,
  `fdesetup status`, and `dsmemberutil`.

Because targeting on this fleet is **group-based**, a recurring diagnostic question across almost
every runbook is: *is this Mac/user in the right Entra group to receive the profile or app in
question?* The runbooks make that check explicit rather than assuming it.

## How the runbooks are structured

Every runbook in the Runbook Library uses the same fixed anatomy so a technician always knows
where to look:

- **Scope / symptoms** — the user-visible symptoms or the task this runbook covers, and what it
  does *not* cover (with a pointer to the correct runbook).
- **Triage tree** — a short branching decision that narrows the issue to a probable cause path
  and tells you which checks to run first.
- **Checks** — an ordered list of read-only observations. Each check names exactly where to click
  and what a healthy vs. unhealthy result looks like.
- **Resolution** — the fix (or the setup steps) for each identified cause/branch, least-disruptive
  first, written as click-to-implement steps.
- **Escalation gate** — the explicit line: what conditions mean *stop and escalate*, to whom, and
  what to hand over. On a Mac this includes anything that risks FileVault data loss.
- **Evidence to collect** — the specific artifacts (screenshots, IDs, log names, command output,
  timestamps) to attach to the ticket regardless of outcome.

## Keeping the library current with Intune and Apple changes

macOS management changes faster than Windows: Apple ships a major macOS release yearly (and drops
support for MDM commands and hardware on its own cadence), and Intune's macOS feature set is
updated continuously. This library is built to be **maintained**, not frozen:

- **Watch the release notes.** Track the Intune "What's new" and Apple's macOS/ABM release notes.
  When a menu moves, a command is deprecated, or a new capability lands (e.g. a new Platform SSO
  mode), update the affected runbook.
- **Re-verify on each major macOS release.** Before the fleet adopts a new macOS version, re-run
  the Testing gates for enrollment, FileVault, SSO, and compliance on a pilot Mac.
- **Feed corrections back.** When a technician finds a step that no longer matches the console,
  the correction goes into the runbook so the next technician benefits (see Best Practices —
  Feature evaluation and Keeping the library healthy).

The remaining documents build on this overview: **Requirements** (what a technician needs before
using the library), the **Runbook Library** itself (the categorized runbooks), **Testing**
(pass/fail gates that prove each runbook works), **Troubleshooting** (cross-cutting edge cases),
and **Best Practices** (documentation, training, and feature evaluation).
