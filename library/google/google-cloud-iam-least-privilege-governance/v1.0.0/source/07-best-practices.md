# 7. Best Practices — Google Cloud IAM & Least-Privilege Governance

Durable practices that keep the least-privilege model true after the project ends. These are the
habits that stop role sprawl and exported keys from creeping back.

## Roles
- **Predefined-first, custom-by-exception.** Reach for a predefined role every time; author a custom
  role only when no predefined role fits, and keep the custom-role count small — each one is a
  permission list you now own as services evolve.
- **Never grant primitive roles.** `roles/owner` and `roles/editor` are the finding, not the fix.
  Keep exactly one audited, time-bound, IAM-Conditioned **break-glass** path and treat any other
  primitive grant as an incident.
- **Bind at the highest level that is still correct — and no higher.** Platform roles at the
  Organization/folder, application roles on the app's own folder/project. Over-broad *scope* is as
  much a finding as an over-broad *role*.
- **Use IAM Conditions to narrow, not to compensate.** A condition tightens an already-appropriate
  role (resource prefix, tag, time); it is not a way to make a too-powerful role "safe."

## Principals
- **Humans as groups, always.** Bind roles to Google Groups sourced from the IdP so joiner/mover/leaver
  is a membership change. Direct `user:` bindings are the seed of sprawl — allow them only as documented,
  time-boxed exceptions.
- **One workload, one service account, least privilege.** Do not share a service account across
  workloads, and do not reuse a high-privilege SA for a low-privilege job. Disable the **default**
  service accounts' automatic Editor grant
  (`constraints/iam.automaticIamGrantsForDefaultServiceAccounts`).
- **Prefer impersonation over keys for human-to-SA.** When a human needs to act as a service account,
  grant `roles/iam.serviceAccountTokenCreator` and impersonate (`--impersonate-service-account`) — a
  short-lived token, not a downloaded key.

## Kill exported keys
- **Enforce `iam.disableServiceAccountKeyCreation` org-wide** once migrated — this is the single most
  effective guardrail. A key that cannot be created cannot be leaked.
- **Workload Identity Federation for every external/federated caller.** CI/CD, other clouds, on-prem,
  partner integrations — all get short-lived federated tokens, never a static key. Map the **narrowest**
  external attribute (specific repo, specific branch, specific AWS role) that identifies the workload.
- **Treat any surviving user-managed key as a live secret** — rotate on a short cadence until it is
  eliminated, and alert on `keys create` in Cloud Audit Logs.

## Guardrails
- **Domain-Restricted Sharing on.** `iam.allowedPolicyMemberDomains` scoped to your customer IDs stops
  accidental external grants at the door.
- **Dry-run every org-policy change first.** Apply constraints in `dryRunSpec`, review the logged
  violations, then enforce. Never enforce a new constraint at the Organization node without a dry-run
  window.
- **Version and name your policy set** (`IAM Guardrails – Org – v1`) and manage it as code
  (Terraform / Cloud Foundation Toolkit) so guardrails are reviewable and reproducible.

## Review as a cadence
- **Attest bindings quarterly.** Drive the review from **IAM Recommender** (unused / over-granted
  roles) and **Policy Analyzer**; every binding is confirmed by an owner or trimmed. An un-reviewed
  binding is an expired binding.
- **Act on Recommender.** Over time, adopt its safe least-privilege recommendations rather than letting
  them accumulate — the whole point is to *converge* on least privilege, not just measure the gap.
- **Log and alert on IAM changes.** Route `SetIamPolicy`, `keys create`, and org-policy changes from
  Cloud Audit Logs to your SIEM so drift is visible between reviews.

## Tooling discipline
- **Everything read-only or dry-run by default.** The provided tools apply only with an explicit
  `--apply`; keep that discipline in anything you add.
- **ADC only — no key files.** Run tooling under user ADC, an attached service account, or WIF. Never
  set `GOOGLE_APPLICATION_CREDENTIALS` to a downloaded key or commit one to a repo.
- **Manage IAM as code where you can.** Bindings and policies expressed in Terraform / CFT are
  reviewable, diffable, and roll back cleanly — far safer than click-ops at the Organization node.
