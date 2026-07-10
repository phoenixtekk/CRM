# 7. Best Practices — Azure Landing Zone with Terraform

## Plan-first, always
- **Never `apply` without reading the `plan`.** The what-if is the safety mechanism — review it in a pull
  request, confirm no unexpected destroys, and only then apply. Use `-detailed-exitcode` in CI so a
  non-empty plan is a signal, not a surprise.
- **Non-prod before prod.** Prove every change against `mg-sandbox` / a sandbox subscription first;
  production `apply` is always behind a **manual approval** gate.

## State discipline
- **Remote state, always locked.** Keep state in the `azurerm` backend with blob-lease locking and
  versioning; never local, never committed. One state per environment/scope to limit blast radius.
- **Least-privilege state access.** Only the deploy identity gets **Storage Blob Data Contributor** on the
  state account; state can contain sensitive values, so treat it like a secret store.
- **Never hand-edit in the portal to fix drift.** Correct the code and re-apply — portal edits widen the
  gap between state and reality and are exactly what drift detection is meant to catch.

## Guardrails (policy) as code
- **Audit before Deny.** Assign guardrails (allowed-regions, required-tags, security baseline) in
  **`Audit`/`Disabled`** first, confirm nothing legitimate is flagged (`IACTF-Report.ps1`), then promote
  to **`Deny`** one assignment at a time. A premature `Deny` blocks real deployments.
- **Assign at the right scope.** Put broad guardrails high (root / platform) so they **inherit**; scope
  workload-specific policy to the landing-zone MG. Don't assign the same policy at multiple scopes.
- **Parameterize from the standard.** Allowed regions and required tags come from your governance standard
  via variables — keep the standard in one place, referenced by both policy and module defaults.

## Hierarchy & subscription vending
- **CAF-aligned, but lean.** Keep the hierarchy shallow and purposeful (Platform / Landing Zones / Sandbox
  / Decommissioned); don't over-nest.
- **Vend subscriptions through code.** Place new subscriptions into the correct MG via the vending pattern
  so baseline policy, RBAC, and networking are inherited from day one — no click-ops onboarding.
- **Target groups, not people, for RBAC.** Assign roles to Entra groups; manage membership separately.
  Keep role assignments least-privilege and in code.

## Networking
- **Hub-spoke with peering.** Central connectivity in the hub; workloads in spokes peered to it. Reserve
  address space deliberately; don't overlap ranges (peering will fail).
- **Private DNS centrally.** Manage private DNS zones in the connectivity scope and link spokes, so name
  resolution is consistent.

## Pipeline & drift
- **Secretless CI/CD.** Authenticate with **workload identity federation (OIDC)** — no service-principal
  secrets in variables. Scope the service connection to the deployment target only.
- **Schedule drift detection.** A scheduled `plan` that fails on a non-empty result surfaces out-of-band
  changes early; reconcile by re-applying the code, not by editing the portal.
- **One change, one PR, one approval.** Small, reviewed changes keep plans readable and rollbacks trivial.

## Version safety
- **Pin and lock everything.** Pin Terraform, providers, and modules; commit `.terraform.lock.hcl`.
  Upgrade versions **deliberately** in their own PR with a reviewed plan — never let CI float versions.
  *Verify current supported versions against the registry before upgrading.*

## Change safety
- **Pilot-first, gated, reversible** — prove the four gates on non-prod before production.
- **Rollback = revert + apply.** Your Git history is the rollback path; revert the commit and apply the
  prior known-good state. Set a bad `Deny` back to `Audit` and re-apply.
- **High-impact = change control.** Root management-group changes, subscription vending, and version
  upgrades get their own change window and review.

## Hygiene
- **No secrets in code.** Backend auth via CLI/OIDC; any runtime secrets come from **Key Vault**, never
  the repo. Enable secret scanning on the repo.

## Where to go next (adjacent catalog areas)
- **Azure Security Baseline & Governance** — deepen the policy/Defender-for-Cloud posture on the landing
  zone this builds.
- **Entra ID Governance — Access Reviews & Entitlement Management** — govern who gets the RBAC roles the
  landing zone defines.
- **Zero Trust — Conditional Access Baseline** — control the sign-in conditions for access to the cloud
  control plane.
