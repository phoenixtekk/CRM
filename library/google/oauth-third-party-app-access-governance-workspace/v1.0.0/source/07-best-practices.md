# Best Practices

Durable practices for keeping OAuth & third-party app access governed after the initial rollout.

## Governance & process

- **Vet before you trust.** Every new third-party app goes through `App-Vetting Workflow – Org-Wide –
  v1` *before* it is added to `Trusted Apps – Org-Wide – v1` or the Marketplace allowlist. "Trusted"
  is a decision with a named approver and a recorded rationale, never a default.
- **Default-deny the unknown.** Keep `Unverified-App Block – Org-Wide – v1` set to block unconfigured
  apps from sensitive/restricted scopes at minimum. New apps should have to earn access, not lose it.
- **Allowlist the Marketplace.** Keep Marketplace on allowlist-only. An open Marketplace is a
  continuous stream of un-vetted grants.
- **Least scope, not least app.** Prefer apps that request the narrowest scopes for the job. When two
  apps do the same task, favor the one that avoids restricted scopes (full Gmail/Drive/admin).

## Ongoing hygiene

- **Re-inventory on a schedule.** Run `oauth-app-inventory.py` monthly (or per your risk cadence).
  New HIGH-risk or UNKNOWN-scope apps are the signal to trigger vetting or revocation.
- **Review tokens, not just policy.** Policy governs *new* grants; **standing tokens persist** until
  revoked. Periodically run the risky-grant review (dry-run first) and revoke vetted-Blocked or
  abandoned grants via `Token Revocation – Risky-Grants – Runbook`.
- **Watch scope drift.** Google's restricted/sensitive scope classification changes; keep the
  scope-sensitivity reference current and treat any newly-restricted scope as a re-review trigger.
- **Correlate with sign-in and audit signals.** Cross-reference high-risk OAuth grants with the
  security investigation / audit logs; an unusual app + unusual sign-in together is a stronger signal
  than either alone.

## Safety & operations

- **Pilot every tightening.** Any change that could block a legitimate app (new unverified-app policy,
  Marketplace change, reclassifying an app to Limited/Blocked) goes to `App-Access Pilot – Pilot-OU –
  v1` first with the documented rollback ready.
- **Communicate revocations.** Revoking a grant forces re-consent; tell affected users why and what to
  re-authorize, so a security action doesn't read as an outage.
- **Keep evidence.** Retain the validation reports, revocation evidence logs, and vetting decision
  records — they are the audit trail that the surface is governed.
- **Automate safely.** Run the tools read-only/dry-run by default; require `--apply` (and approver
  sign-off) for writes and revocations. **Never** commit or export a service-account key — use ADC or
  workload identity, scoped to the minimum read-only APIs.

## Alignment

- **Tie trusted apps to business owners.** Every Trusted app should have a named business owner
  accountable for it; orphaned trusted apps are a review trigger.
- **Feed the joiner/mover/leaver process.** When a vendor relationship ends, Block the app and revoke
  its grants as part of offboarding — don't let a dead vendor keep a live token.
- **Verify edition-dependent controls.** Some app-access and security-center capabilities depend on
  the Workspace edition and Google's current rollout; confirm availability in your tenant rather than
  assuming a control exists.
