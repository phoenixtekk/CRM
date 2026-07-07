# Solution Overview

## What this is

This solution configures and tunes **Microsoft 365 mail hygiene** so that malicious and unwanted
mail is blocked while legitimate mail flows without being wrongly quarantined. It covers the two
layers of the Microsoft cloud email-security stack:

- **Exchange Online Protection (EOP)** — included with every Exchange Online mailbox. Provides
  **anti-malware**, **anti-spam** (including bulk and high-confidence spam handling), **connection
  filtering** (IP Allow/Block lists), and **anti-spoofing / spoof intelligence**, plus **outbound
  spam** controls.
- **Microsoft Defender for Office 365** — a **licensed add-on** (Plan 1 or Plan 2, or bundled in
  Microsoft 365 E5 / E5 Security). Adds **anti-phishing** (impersonation and mailbox-intelligence
  protection), **Safe Links** (time-of-click URL protection), and **Safe Attachments** (detonation
  of attachments in a sandbox). Plan 2 additionally provides Threat Explorer, Automated
  Investigation & Response (AIR), and Attack Simulation Training.

> **PLAN / LICENSING IS DECISIVE — VERIFY BEFORE YOU START.** Which controls you can configure
> depends entirely on licensing. EOP anti-spam/anti-malware/anti-spoof is available to all Exchange
> Online tenants. **Anti-phishing impersonation protection, Safe Links, and Safe Attachments require
> Defender for Office 365 (Plan 1 or Plan 2).** Do **not** assume a control exists — confirm your
> plan in the Microsoft 365 admin center under **Billing > Licenses** and verify capability in your
> own tenant before designing around it. Where this document describes a Defender for Office 365
> feature, it is flagged as such.

The solution delivers the reference design, the exact ordered implementation (portal paths **and**
Exchange Online PowerShell cmdlets), validation procedures with pass/fail gates, troubleshooting,
durable best practices, and **five PowerShell tools** (EXO V3 / Microsoft Graph) that assess,
help configure, validate, and report on the hygiene posture — all read-only or `-WhatIf` by default.

## How it works — the hygiene stack

Inbound mail is evaluated in layers before it reaches the mailbox:

1. **Connection filtering (EOP)** — the IP Allow / IP Block lists and the safe-list. Evaluated
   first, at the connection.
2. **Anti-malware (EOP)** — malware filtering and the common-attachments filter; malware is
   quarantined.
3. **Anti-spam / anti-spoof (EOP)** — content filtering assigns a **spam confidence level (SCL)**
   and **bulk complaint level (BCL)**; spoof intelligence evaluates unauthenticated senders spoofing
   your domains or others. Verdicts: spam, high-confidence spam, phishing, high-confidence phishing,
   bulk. Each verdict has an **action** (move to Junk, quarantine, etc.).
4. **Anti-phishing (Defender for Office 365)** — impersonation protection (user and domain),
   mailbox intelligence, and spoof intelligence tuning.
5. **Safe Attachments (Defender for Office 365)** — attachments are detonated in a sandbox
   (Dynamic Delivery / Block / Replace).
6. **Safe Links (Defender for Office 365)** — URLs are wrapped and checked at time of click.

**Quarantine** holds messages that policies quarantine; a **quarantine policy** controls what
recipients can do (view, request release, release, block sender) and whether they receive
**quarantine notifications**. The **Tenant Allow/Block List (TABL)** is the supported way to allow
or block specific senders, domains, URLs, and file hashes tenant-wide.

### Preset security policies vs custom

Microsoft ships two **preset security policies** with recommended, Microsoft-maintained settings:

- **Standard protection** — recommended baseline for most organizations.
- **Strict protection** — more aggressive; more mail quarantined, higher protection.

Presets cover EOP (anti-spam/malware/spoof) and, where licensed, Defender for Office 365
(anti-phish/Safe Links/Safe Attachments) together, applied to the users/groups/domains you scope.
The alternative is **custom policies**, which you tune manually. This solution defaults to a
**preset-first** approach (fewer moving parts, Microsoft keeps them current) and uses **custom
policies only where a specific requirement is not met by a preset** — for example a mail-flow rule
exception or a tuned bulk threshold.

## Reference design (the model this solution deploys)

- **Baseline:** Apply the **Standard** preset security policy to a **pilot scope** first, then
  expand. Escalate specific groups (executives, finance, high-risk roles) to **Strict** where the
  organization accepts more aggressive quarantining.
- **Quarantine policy:** Use the built-in `DefaultFullAccessWithNotificationPolicy` (recipients get
  notifications and can request release) as the default; reserve admin-only release for
  high-confidence phishing/malware.
- **Allow/Block:** Manage exceptions **only** through the **Tenant Allow/Block List** — never by
  disabling filters or using broad mail-flow-rule bypasses.
- **Authentication foundation:** SPF, DKIM, and DMARC on all sending domains so spoof intelligence
  and anti-phishing have authenticated signals to reason about (email authentication is a
  prerequisite — see Requirements).
- **Naming convention:** every custom artifact is named `<Purpose> – <Scope> – <Stage>`, e.g.
  `Anti-Spam – Inbound – Pilot`, `Anti-Phish – Exec – Prod`, `Quarantine – Notify – Prod`.

## Benefits

- **Fewer threats delivered** — phishing, spoofing, malware, and malicious links/attachments are
  blocked at Microsoft-recommended (or stricter) levels.
- **Fewer false positives** — quarantine is governed, allow/block is deliberate, and bulk/spam
  thresholds are tuned to the organization, so legitimate mail is not lost.
- **Maintainable** — preset policies stay current automatically; custom drift is minimized.
- **Auditable** — allow/block entries, quarantine actions, and policy scope are all reviewable and
  reportable (the provided scripts produce these reports).
- **Low-risk rollout** — pilot-first with explicit gates and a documented rollback.

## Limitations / scope boundaries

- **Defender for Office 365 features require the license.** Without Plan 1/2 you get EOP only; this
  is flagged throughout. **Verify your plan.**
- **Not a replacement for email authentication.** SPF/DKIM/DMARC setup is a prerequisite, not the
  subject of this solution (it is the foundation hygiene relies on).
- **Third-party gateways** (a hygiene gateway or connector-based third-party filter in front of EOP)
  are integrated at the pattern level only — their consoles are deferred to the vendor's docs, and
  **Enhanced Filtering for Connectors (skip listing)** is noted where a third-party sits in front.
- **Commercial vs Government cloud:** portal URLs and some endpoint availability differ on
  **GCC / GCC High / DoD** (e.g. `security.microsoft.com` vs `security.microsoft.us`, and certain
  Defender for Office 365 features roll out later or differently). Where setup materially differs,
  it is flagged — **do not assume Commercial paths are universal**.
- This solution tunes **hygiene**; it does not cover mailbox migration, connectors for hybrid mail
  routing, or archiving (separate solutions).

## Deployment model

The house model is **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with
explicit pass/fail gates and a documented rollback at each stage. Mail hygiene changes are
**high-impact to production mail** (a mis-tuned policy can quarantine legitimate business mail), so
every change is staged on a pilot scope, validated against the gates in the Testing section, and
only then expanded — with the rollback ready.
