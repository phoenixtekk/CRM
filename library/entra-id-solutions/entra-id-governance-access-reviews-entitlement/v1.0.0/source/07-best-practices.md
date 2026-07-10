# 7. Best Practices — Entra ID Governance: Access Reviews & Entitlement Management

## Entitlement management (catalogs & packages)
- **Delegate with catalogs.** Give resource owners **catalog owner** rights on their own catalog instead
  of tenant-wide governance roles — least privilege, and the people who know the access own the packages.
- **Package the job, not the resource.** Build access packages around a **role/task** ("Sales LOB
  access") that bundles the groups/apps/sites needed, so one request grants everything — cleaner than one
  package per group.
- **Always time-bound.** Set an **expiry** on every assignment policy; permanent access is how sprawl
  returns. Use **review-on-renewal** so continued access is re-justified, not auto-extended.
- **Separate employee and guest policies** on the same package — different requestor scope, approver, and
  a **shorter expiry for guests**. Never let external users self-approve; require an **internal sponsor**.

## Access reviews
- **Auto-apply, but pilot the fallback.** Enable **auto-apply** so decisions actually take effect, but on
  the first cycle set "if reviewers don't respond" to **No change** and review manually; switch to
  **Remove access** once reviewers are trained. An unanswered review shouldn't silently strip access on
  day one.
- **Right reviewer, right cadence.** Group/app owners review their own resources; managers review their
  reports; guests are reviewed by their **sponsor**. Match frequency to sensitivity — privileged and
  guest access quarterly (or more), routine access semi-annually.
- **Show recommendations and require justification** so reviewers make informed, defensible decisions —
  and so the decision record is audit-quality.

## Lifecycle workflows
- **Start on-demand, then schedule.** Prove joiner/leaver tasks by running them **on-demand** against
  test users before enabling **attribute-driven** (`employeeHireDate` / `employeeLeaveDateTime`)
  scheduling for the whole population.
- **Leaver = disable + revoke + remove.** An offboarding workflow should **remove group/package
  assignments**, **disable the account**, and **revoke sessions** — deprovisioning that leaves standing
  access or live tokens is the classic gap.
- **Keep tasks idempotent and scoped.** Scope every workflow tightly (start with `ENTIGA-Pilot`) and keep
  high-impact tasks (disable/revoke) in the **leaver** workflow only.

## Guest governance
- **Front-door guests through packages.** Prefer governed **access package requests** (with an internal
  sponsor and expiry) over ad-hoc guest invites, so every external grant is time-bound and reviewable.
- **Review stale guests routinely.** Run `ENTIGA-GuestReview.ps1` to surface guests with old/absent
  sign-ins and feed them into the guest access review — remove those no longer needed.

## Change safety
- **Pilot-first, always** — prove the four gates on `ENTIGA-Pilot` before expanding.
- **Auto-apply and leaver tasks change real access** — treat them like production changes: staged
  rollout, a documented rollback, and (for leaver) a change window.
- **Keep a rollback ready** — narrow a policy back to the pilot, set a review to **No change**, or
  **disable** a workflow to stop it; re-request/re-approve to restore removed access.
- **Least privilege for the operators** — run day-to-day governance as **Identity Governance
  Administrator**; reserve Global Administrator for initial setup only.

## Hygiene
- **No secrets in automation.** Scripts authenticate interactively via `Connect-MgGraph` with least
  read scopes — never embed credentials or tokens.
- **Document per package:** resources, approver, expiry, and the review that recertifies it.

## Where to go next (adjacent catalog areas)
- **Entra ID Governance — PIM & Access Reviews** — just-in-time **privileged role** activation and
  role-assignment reviews (this solution governs resource/app access; PIM governs directory roles).
- **Zero Trust — Conditional Access Baseline** — enforce the sign-in conditions under which any of this
  access can be used.
- **Enterprise App & Service Principal Governance** — govern the apps and workload identities that access
  packages grant into.
