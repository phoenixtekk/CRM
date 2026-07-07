# Best Practices

Durable practices for running Google Meet and Chat as a governed collaboration platform after the
initial configuration.

## Scope by OU and group deliberately

- Apply each control at the **narrowest scope** that satisfies policy. Keep a restrictive baseline at
  the top OU and grant exceptions (external Meet, external chat, recording) to **named configuration
  groups** rather than loosening whole OUs.
- Prefer **configuration groups** for cross-cutting exceptions (partner-facing teams, approved
  recorders) so membership — not OU placement — drives the exception, and membership stays auditable.
- Never leave a high-impact setting "Inherited" by accident. Confirm each OU shows the intended value.

## Keep external collaboration deliberate

- Default external Meet and external Chat to **restrictive**; open only to an **approved domain
  allowlist** (`Chat External Policy – Allowlisted Domains – Enforce`) reviewed on a schedule.
- Keep the **external-participant warning** on everywhere so users always know when outsiders are
  present.
- Re-review the allowlist quarterly with security; remove domains that are no longer needed.

## Govern recordings and transcripts centrally

- Direct all recordings, transcripts, and meeting notes to the governed **Recording Storage Shared
  Drive**, not personal My Drive, so access and retention apply uniformly.
- Restrict **who can record** to an approved group; recording is a data-creation event with retention
  and privacy implications.
- Apply retention to the Shared Drive so artifacts age out (or are held) per the records schedule.

## Make Chat eDiscovery-ready

- Set the **history default** to match the records policy and control whether users can change it per
  space.
- Maintain **Vault retention** rules per data type and OU, and rehearse **legal holds** so eDiscovery
  works when it is needed, not for the first time during a matter.
- Validate retention on a non-production OU before applying broadly — applied retention can be
  irreversible.

## Run a real spaces taxonomy

- Enforce a **naming convention** and **ownership** for spaces; every space should have an accountable
  owner and a clear type (team / project / cross-functional / external).
- Restrict space creation where the edition allows, and periodically prune orphaned or empty spaces.

## Contain third-party app risk

- Keep Chat apps on an **allowlist** with a documented request/approval path; review installed apps
  against the allowlist regularly.
- Treat a new bot with space-content access as a data-access grant — security-review before allowlisting.

## Operate the controls as living policy

- **Pilot-first, always.** Every change to external access, history, retention, or recording storage
  goes through the Pilot OU and the validation gates before fleet-wide rollout.
- **Baseline before you change.** Keep a current `Meet+Chat Baseline` so any change has a known
  rollback value.
- **Automate assessment, not just change.** Run the read-only assessment, usage, health, and validator
  tools on a schedule to catch **drift** (a setting quietly changed, a new unapproved app, an OU that
  slipped back to inherited defaults) between formal reviews.
- **Verify vendor-dependent features in your tenant.** Meet/Chat labels, Gemini note-taking, and
  edition-gated controls change; re-verify after Workspace updates rather than assuming last quarter's
  behavior.

## Keep automation safe and auditable

- Run tools **read-only or `--dry-run` by default**; require explicit `--apply` for any write, under
  change control.
- Use **least-privilege** OAuth/service-account scopes and store credentials via ADC / a secret store —
  never embed keys. Log what `--apply` changed for the audit trail.
