# Best Practices

Practices that keep the archiving strategy healthy, cost-effective, and defensible over time. They
extend the category Global Requirements and the pilot-first delivery model.

## Strategy and scope

- **Tier by access frequency, not by guesswork.** Base the move-to-archive age on real telemetry
  (mailbox growth, how far back users actually search) from the Discovery report, not a round number.
- **Separate "move" from "delete" completely.** Archiving (move-to-archive) reduces primary-store
  cost and is low-risk; **disposition (delete) is a records/legal decision** and irreversible. Ship
  archiving first; only add deletion once records/compliance has approved a schedule (R5).
- **Right-size auto-expanding archive.** Enable auto-expanding archive **only** for users whose
  archive will exceed the base quota — it is **irreversible** and adds background processing. Prefer
  per-mailbox enablement over the org-wide switch during rollout.

## Change discipline

- **Always pilot on test mailboxes first.** Never make a production user the first ring. Archiving
  moves data and is hard to reverse; a bad age threshold on production is expensive to unwind.
- **Gate every write behind `-Commit`.** Run every script in `-WhatIf` first, read the plan, then
  commit. Keep the default read-only.
- **One change per ring, validated before the next.** Enable archives, assign the policy, run MFA,
  validate — then widen scope. Do not stack changes across rings.
- **Document the rollback before you change anything.** For each step know the reverse action and its
  limits (disconnected archives are kept 30 days; auto-expanding cannot be disabled; already-moved
  items do not come back).

## Operations and monitoring

- **Understand the Managed Folder Assistant cadence.** MFA is asynchronous and throttled; archiving
  is not instant. Use `Start-ManagedFolderAssistant` to force a pilot mailbox, but expect the
  org-wide work cycle to process at its own pace.
- **Report on adoption and reduction, not just configuration.** Track archive item growth and
  primary-store reduction over time (`Export-ArchiveReport.ps1`) — that is the value evidence and the
  early-warning signal if MFA stalls.
- **Watch for hold interactions.** Litigation hold, In-Place Hold, and Purview retention can keep
  content beyond the archive move; that is correct behavior. Never disable a hold to make archiving
  "look cleaner."
- **Re-baseline periodically.** Re-run Discovery quarterly; mailbox growth and usage patterns drift,
  and the age threshold may need tuning.

## Governance and defensibility

- **Keep records/compliance/legal in the loop.** The retention timeline and any disposition are their
  determinations; capture named sign-off and store it with the change evidence.
- **Least privilege, no standing Global Admin.** Use Recipient Management / Retention Management
  scoped roles; reserve Global Administrator for the specific org-wide actions that require it.
- **No secrets in automation.** The scripts use interactive modern-auth (`Connect-ExchangeOnline` /
  `Connect-IPPSSession` / `Connect-MgGraph`) — never embed credentials, tokens, or app secrets.
- **Treat plan/portal detail as verify-first.** Archiving entitlements, auto-expanding archive, and
  **Microsoft 365 Archive** tiering are licensing-/billing-gated and evolving — confirm availability
  and paths against current Microsoft documentation for your tenant before relying on them.
- **Retain the evidence trail.** Baseline + post-change statistics, policy definitions, MFA/validation
  output, and sign-off together make the archiving strategy auditable and defensible.
