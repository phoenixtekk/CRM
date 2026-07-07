# Best Practices

Durable practices for keeping Teams external collaboration enabled **and** governed.

## Govern the three surfaces separately — never conflate them

- **External access (federation), guest access, and shared channels are different controls.** Locking
  one down does not govern the others. Review all three on every posture check; the discovery script
  reports them together for exactly this reason.
- Prefer an **allow-list** federation model (only approved domains) over an open-federation-with-blocks
  model for regulated or high-sensitivity tenants. Remember allow-list and block-list are mutually
  exclusive.

## Make external connections deliberate

- Keep the **cross-tenant access Default** conservative — **block B2B direct connect by default** and
  enable it **per named partner** (`Cross-Tenant Partner – <Partner> – <Stage>`). Shared channels
  should be a decision, not an accident.
- Set **guest-invite restrictions** to least privilege (specific roles), and scope **guest domains** in
  Entra external collaboration settings — do not rely on Teams guest toggles alone.

## Treat guests as time-limited by default

- Every guest should be covered by a **recurring access review** with **auto-remove** on non-approval —
  that is the expiration mechanism. Owner-review beats admin-review because owners know who still needs
  access.
- Run the **stale-guest exposure report** on a schedule even where reviews are licensed — it is the
  independent check that no guest slips past the review scope.
- Where Entra ID Governance/P2 is **not** licensed, replace automation with a **documented monthly
  manual removal runbook** driven by the exposure report — never "no lifecycle".

## Let classification drive control

- Use **container sensitivity labels** so a team's external-sharing/guest posture comes from its
  **label**, not per-team configuration drift. Name labels by intent
  (`Sensitivity Label – Ext-Collab – Prod`) and publish them, don't just create them.

## Change safely

- **Pilot first, always.** External/cross-tenant/lifecycle changes are tenant-wide and high-impact.
  Assign named policies to a pilot group, validate the pass/fail gates, then Expand.
- **Dry-run by default.** Run the config script with `-WhatIf`; apply only with `-Commit` inside a
  change window with a named rollback owner.
- **Capture a baseline before every change** (`posture-baseline.json`) so rollback is deterministic —
  reapply the captured values, don't improvise.

## Keep it least-privilege and secret-free

- Use least-privilege roles split across Teams admin (policies) and Entra Identity Governance
  (reviews/cross-tenant); reserve Global Admin for the rare step that needs it.
- **No stored credentials in automation.** Connect with modern-auth `Connect-MicrosoftTeams` /
  `Connect-MgGraph` interactively or via a managed identity — never hardcode secrets.

## Coordinate with the partner and with governance

- Shared channels / direct connect require **both tenants** to allow the connection — confirm the
  partner's side before troubleshooting your own.
- **Domain allow/block lists, permitted classifications, review cadence, and retention are policy
  determinations** owned by security/compliance/records — the technical controls implement them; keep
  the sign-off current when the policy changes.

## Cloud awareness

- Confirm the correct **portal URLs and feature availability for your cloud** (Commercial vs GCC /
  GCC-High / `*.office365.us`) before configuring — do not assume commercial paths. Flag anything
  plan- or cloud-dependent as **"verify in your tenant"** in your runbooks.
