# 7. Best Practices — BeyondCorp Enterprise: Zero-Trust Access

Durable practices for running and expanding BeyondCorp Enterprise zero-trust access after the pilot.

## Policy design
- **Define access levels once, reference everywhere.** Keep a small, well-named set (e.g.
  `Access Level – Corp-Managed – v1`, `Access Level – Trusted-Network – v1`) rather than a bespoke
  condition per app. Fewer, reusable levels are easier to reason about and audit.
- **Always condition IAP bindings on an access level.** An IAP binding without a `--condition` enforces
  identity but not context — that is not zero trust. Treat an unconditioned binding as a defect (the
  guardrail check flags it).
- **Prefer device + identity + network together** over any single attribute. Network (IP/geo) alone is
  the flat-trust model you are replacing; identity alone ignores the "what."
- **Use CEL custom access levels for combined logic**, and keep the CEL expressions in version control
  so changes are reviewable and revertible.

## Rollout discipline
- **Pilot-first, gate-driven.** Never enable enforcement or retire a VPN path without passing the
  deny/allow gate (05-testing T2–T5) and the guardrail check (T7). Keep the documented rollback ready
  before every enforcement change.
- **Retire VPN paths per resource, not all at once.** Move an app/VM behind IAP, validate, then remove
  only that path. This keeps blast radius small and rollback simple.
- **Version access-level names as policy hardens** (`– v1` → `– v2`, `– Pilot` → `– Prod`) and update
  bindings deliberately rather than mutating a live level in place.

## Keep the two products distinct
- **BeyondCorp Enterprise (this solution) protects your apps/VMs/GCP**, in the **Google Cloud
  Console**; **Workspace Context-Aware Access protects Google Workspace apps**, in the **Google Admin
  console**. Document which surface owns which control so they are not conflated, even though they can
  share device signals.

## Device signals & licensing
- **Confirm the device-signal source and its license tier before relying on it.** Richer device-trust
  signals may require Chrome Enterprise Premium / endpoint-verification enrollment — **verify in your
  organization** and re-verify at renewal, since tiers and signals change.
- **Degrade gracefully:** if a device signal is temporarily unavailable, know whether your access level
  fails open or closed and make that an explicit, tested decision (default to fail-closed for sensitive
  apps).

## Operations, monitoring & evidence
- **Treat IAP and Cloud Audit Logs as the source of truth** for who reached what, from what context.
  Route allow/deny events to your SIEM and alert on unexpected denies (possible mis-scoped level) and
  unexpected allows (possible over-broad binding).
- **Re-run the guardrail check on a schedule**, not just at rollout, to catch drift (a new unconditioned
  binding, an SSH firewall opened for troubleshooting and left open, a broad principal added).
- **Review access-level membership and bindings periodically** with the security stakeholders; remove
  access that is no longer needed (least privilege per app).

## Least privilege for administrators
- Grant `roles/accesscontextmanager.policyAdmin` and `roles/iap.admin` narrowly to the people who
  configure zero trust; keep org-super-admin as audited break-glass only.
- Automate with **Application Default Credentials / short-lived tokens** — never export service-account
  keys to disk or embed secrets in scripts (the provided tools follow this).

## Governance & scope
- **Maintain a living inventory** of what is behind IAP, which access levels apply, and which VPN paths
  remain (export it with `bce_scope_config_helper.py`). Zero-trust coverage is a program, not a
  one-time project — track expansion against the remaining VPN-dependent apps.
- **Defer legal/records/compliance determinations** to those functions; provide the technical control
  and the log evidence, not the legal interpretation.
