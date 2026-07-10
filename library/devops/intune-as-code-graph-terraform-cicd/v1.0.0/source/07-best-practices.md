# 7. Best Practices — Intune-as-Code (Graph & Terraform, CI/CD)

## Keep it clean
- **Stop editing managed policies in the portal.** Once a policy is code, every change goes through Git and the pipeline. Portal edits become drift the pipeline will fight — the operating-model change is the whole point.
- **Plan is a gate, not a formality.** Read every `terraform plan` before approving. An unexpected **destroy** on a policy you did not intend to remove means **stop** and reconcile — usually a rename or stale state.
- **Backup before every production apply.** The pre-apply backup is your rollback. A restore point must always exist before Intune changes reach real devices.
- **Pilot ring first, always.** Assign new/changed policies to `Intune-Pilot – Devices – Ring0` first; widen assignments in code only after the ring is healthy. Never assign a new policy straight to All Devices/All Users.
- **Start scoped, expand coverage.** Don't try to codify the entire tenant on day one. Bring a few configuration, compliance, and app-protection policies under code, prove the loop, then add more.
- **Pin the toolchain.** Pin the Terraform CLI and the Graph provider version in `versions.tf`, and the `Microsoft.Graph` module version. Provider/schema drift silently changes behavior. *Verify current versions and Intune resource coverage periodically.*
- **Separate dev and prod state.** Use distinct workspaces (`intune – Dev – Workspace` / `intune – Prod – Workspace`) and a locked remote backend so environments never cross-contaminate.
- **Least-privilege app.** Grant the automation SPN only the Graph permissions it needs; store its credential in Key Vault / the pipeline secret store; prefer workload identity federation over a stored secret.
- **Mind unsupported settings and beta endpoints.** Where the Terraform Graph provider does not model a policy type, manage it via the PowerShell/Graph export-and-apply path and document it — don't force an unsupported resource. *Verify whether an endpoint is beta before depending on it.*
- **Run drift detection on a schedule.** A periodic no-change `terraform plan` surfaces anyone who bypassed the pipeline; act on drift (reconcile or revert) rather than letting it accumulate.

## Governance and decisions that belong to the customer
- **Production change approval**, who may approve, and the promotion cadence are the customer's **change-control** decisions — the solution provides the technical gate.
- **Pilot-ring membership** (which users/devices are Ring0) is the customer's rollout decision.
- **Which settings each policy enforces** (security baseline strictness, compliance thresholds, app-protection rules) belongs to the customer's security/endpoint function; the code **implements** those choices.

## Where to go next
Once Intune-as-code is live, adjacent catalog areas extend it:
- **DevOps** — the sibling *Azure Landing Zone with Bicep* / *…with Terraform* solutions to bring the surrounding Azure platform under the same code-and-pipeline discipline.
- **Intune / Endpoint** — configuration, compliance, and app-deployment solutions whose policies you can now manage as code instead of by hand.
- **Security / Identity** — Conditional Access and compliance-driven access solutions that consume the compliance signals these coded policies produce.
- **Backup / resilience** — extend the JSON backup into a scheduled, retained tenant-configuration backup with tested restore runbooks.
