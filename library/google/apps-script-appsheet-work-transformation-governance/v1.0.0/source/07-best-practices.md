# Best Practices — Safe Citizen Development

These practices keep Apps Script and AppSheet fast for the business while holding the enterprise
standard. They are written for both audiences: the **citizen developer** building a workflow and the
**IT/architecture** owner setting the guardrails. The governing idea: *make the safe path the easy
path.*

## Least scope, always

- Request the **narrowest OAuth scope** that does the job. Prefer per-file/`drive.file` over full
  Drive; prefer a specific Gmail scope over full mailbox access. Broad scopes are the single biggest
  Apps Script risk and the thing high-risk-scope restriction exists to stop.
- Treat any broad-scope request as an automatic **review trigger**, not a default.
- In AppSheet, connect only the **data the app needs** — narrow the source, don't wire the whole
  spreadsheet or database when a view will do.

## Internal-only by default; external sharing is a decision

- Default Apps Script web apps/add-ons to **execute-as the deploying user, access limited to the
  domain** — never "anyone, even anonymous" without explicit approval.
- Keep AppSheet sharing **inside the approved domain(s)**; external sharing is an exception that
  goes through review, not a builder's unilateral choice. The Core security setting or an Enterprise
  Plus policy should enforce this so it isn't left to memory.

## Require sign-in and know the user

- Every deployed AppSheet app should **require sign-in** (`[AuthRequired] = true`) so access is
  attributable and revocable. Anonymous apps have no audit trail.

## Owner of record on everything

- No automation ships without a **named owner** responsible for it — the person who fixes it, answers
  for its data access, and retires it when it's obsolete. Ownerless automation is future shadow IT.
- When an owner leaves, reassignment is part of offboarding.

## Build → Pilot → Production, never straight to prod

- Develop in **Build**, prove in **Pilot** (the scoped OU/group with real guardrails), then promote
  to **Production**. Don't test on live confidential data; mask or use sample data in Build.
- Record a **rollback** for every production automation — how to disable/revert it if it misbehaves.

## Reuse the governed baseline

- Start from **blessed templates and shared libraries** (Apps Script auth/least-scope helpers,
  approved AppSheet templates and connected-source patterns) instead of a blank canvas. Reuse is
  faster *and* safer because the baseline already meets the standard.

## Tier the review, don't gate everything

- Keep **Tier 0 self-serve** (personal, internal, non-confidential) genuinely frictionless so
  builders don't route around governance. Reserve review for **Tier 1** (shared/moderate) and
  **Tier 2** (broad scope / external / regulated). Over-gating breeds shadow IT; under-gating leaks
  data — tiering targets the risk.

## A one-page review checklist

For any Tier 1/2 automation, the reviewer confirms:

1. **Scope** — least-privilege OAuth scopes / narrowest connected source?
2. **Data** — what classification does it touch; is that approved?
3. **Sharing** — internal-only, or approved external with a reason?
4. **Sign-in** — required (AppSheet)?
5. **Owner** — named owner of record?
6. **Rollback** — documented way to disable/revert?

If all six are clean, it may be **marked deployed** (deploy-control policy enforces this in
AppSheet).

## Keep the inventory alive

- Run **Discovery + Report on a recurring cadence** (for example monthly) so new automations surface
  and get an owner and a review tier — governance is continuous, not a one-time project.
- Use the **Report** risk view to prioritize: broad-scope + external + confidential automations get
  attention first.

## Change under control; propagation takes time

- Org-wide app access control and AppSheet security changes affect real users' access — make them
  under **change control**, on a **pilot OU first**, and remember settings can take up to 24 hours to
  fully propagate. Use AppSheet **Warning** stage before **Error** to give builders a grace period.
