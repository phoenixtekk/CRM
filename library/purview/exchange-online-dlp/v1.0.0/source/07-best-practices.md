# Best Practices — Exchange Online DLP

Field-tested guidance for running Exchange Online DLP well. It complements — does not replace — the
implementation steps and the pass/fail gates.

## Deploy the way the house model says — simulate, then enforce

- **Never enforce a scenario you have not validated in simulation.** The single most common cause of a
  DLP incident is a **Block** or **Encrypt** rule moved to enforce without a simulation pass. Every
  scenario goes **simulation (Test) → validate → enforce**, one at a time.
- **Small pilot ring first.** Scope the rules to a handful of pilot senders (`SG-DLPEXO-Pilot`) before
  the whole tenant. It is far cheaper to find a false positive on ten senders than ten thousand.
- **Enforce one scenario at a time.** Do not flip external-block, encrypt, and escalate to enforce
  together. Enforce the highest-risk scenario first (often SIT→external block), validate, then the
  next.
- **Keep a rollback ready.** `Set-DlpCompliancePolicy -Mode TestWithNotifications` (back to simulation)
  or `-Mode Disable` stops enforcement instantly — know the command before you enforce.

## Key the rules on *sensitive* content and the right recipient scope

- **Condition on SITs and/or sensitivity labels**, not "all mail." A policy that blocks *any* external
  message generates noise and workarounds; one that acts on **classified/labeled** content is
  defensible and proportionate.
- **Tune SIT confidence and instance count** deliberately. A low count is usually a **warn/notify**
  (policy tip, allow override); a high count is a **block**. Set the thresholds with the data owners,
  not by guesswork, and raise confidence to cut false positives before you enforce.
- **Lead with sensitivity labels where they exist** — a label is an explicit business decision about
  sensitivity and travels with the message/attachment. Fall back to SITs where labels are not yet
  adopted, and add label conditions as labeling matures.
- **Scope by recipient.** External egress is the primary risk; treat internal as **visibility/audit**
  unless policy says otherwise.

## Maintain the trusted-partner exception deliberately

- **The partner-domain exception is what lets you block the bad path without blocking the business.**
  Keep the list current (`partner.contoso.com` and peers) and **review it on a schedule** — a stale or
  missing exception is both a false-positive source and, if over-broad, a bypass.
- **Whether a domain is "trusted" is a business/compliance decision** — capture it in writing (R4),
  don't add domains ad hoc to silence a ticket.

## Use policy tips as user education, not just enforcement

- **Write clear policy-tip text** that tells the sender *what* matched and *what to do* (remove the
  data, encrypt, or override with justification). A good tip prevents the incident and the support
  ticket.
- **Prefer warn-with-override for low-severity scenarios** so a legitimate business need is not hard
  blocked — the override is logged as evidence and surfaces genuine needs that may belong in an
  exception.
- **Confirm tip rendering per Outlook client** (desktop / web / mobile) — support varies; do not assume
  every client shows the tip identically.

## Reconcile with Exchange mail-flow (transport) rules

- **DLP and transport rules coexist and both act in transport.** Before enforcing, review transport
  rules (`Get-TransportRule`) for any that already block/encrypt/redirect on content or recipient, and
  **decide which control owns each behavior** — two controls stamping encryption or one deleting mail
  before DLP evaluates causes confusing double-actions or silent pre-emption.
- **Prefer Purview DLP as the strategic home** for content-based data-loss control across the estate;
  keep transport rules for mail-routing/hygiene concerns DLP does not cover.

## Operate it, don't set-and-forget

- **Review DLP activity regularly** and roll up with `DLPEXO-Report.ps1`. Rising matches on a scenario
  are a signal to review scope, tuning, or user education — not automatically a reason to block harder.
- **Watch override / justification trends.** A scenario that is constantly overridden may be mis-scoped
  or may indicate a genuine business flow that belongs in the partner exception, not a block.
- **Version and name policies clearly.** Move from `DLPEXO-Pilot` to a production `DLPEXO-Exchange` as
  you exit pilot; keep a change log of scope, threshold, and action changes.
- **Re-validate after portal changes.** The Purview portal and DLP condition/action options evolve;
  re-run `DLPEXO-Validate.ps1` after Microsoft feature updates and confirm nothing regressed.

## Keep the roles and determinations where they belong

- **Least privilege, split duties.** DLP authoring and Exchange mail-flow administration are different
  roles — do not fold them into one over-privileged account.
- **Determinations stay with the owners.** *Which* data is sensitive, *which* scenarios to block or
  encrypt, *whether* a domain is trusted, and *whether* a message is a violation are **compliance /
  security / privacy / legal** calls. You provide the configuration and the evidence, not the judgement
  (see `global-requirements-purview.md` §5).
- **Communicate before you enforce.** Policy tips and user notice reduce friction and support the
  lawful, transparent operation of a data-loss control; surprise blocks generate tickets and
  workarounds.

## Security & handling of the tooling

- **Read-only / `-WhatIf` by default.** Run the provided scripts in their safe default first; only add
  `-Commit` when you intend to write, under change control.
- **No secrets in code.** The scripts use interactive modern-auth (`Connect-IPPSSession`); never
  hardcode credentials, tokens, or app secrets.
- **Least-privilege connections.** Connect with the least-privilege role that the task needs, not a
  standing Global Administrator session.
