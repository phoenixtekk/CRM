# Best Practices

Durable practices for building and extending the Google Cloud landing zone. These outlast the initial
build — apply them every time a new folder, project, guardrail, or workload team onboards.

## Hierarchy & naming

- **Folders are trust boundaries, projects are attributable units.** Model folders by
  environment/trust (Common, Production, Non-Production, Bootstrap), not by team org chart — teams
  churn, environments don't. Put an org policy where you want it inherited by everything beneath.
- **Decide naming before you build, enforce it forever.** Keep the `<Purpose> – <Scope> – <Stage>`
  name grammar and the `env` / `owner` / `cost-center` / `data-class` label set fixed. Run the
  naming/label helper in CI so a non-conforming project can't land.
- **One purpose per project.** Never co-locate logging, billing export, and networking in a shared
  "misc" project — the foundation projects (`Logging – Common – Prod`, `Billing-Export – Common –
  Prod`, `Networking-Host – Shared-VPC – Prod`) each exist so IAM and blast radius stay separable.

## Guardrails (Organization Policy)

- **Pilot every guardrail before org-wide apply.** Apply to `Landing Zone – Pilot`, prove the denial
  behavior (Testing §T2), then promote to the Organization node. High-blast-radius changes are never
  applied blind.
- **Prefer preventive over detective.** An org policy that *prevents* external IPs or service-account
  keys is worth more than a finding that reports them after the fact.
- **Verify constraint availability, don't assume it.** The set of Organization Policy constraints and
  their allow/deny semantics evolve — check each against the current constraints reference for your
  organization before enforcing, and record the version you validated against.
- **Keep a documented rollback for every enforced constraint** so the rollback owner can revert a
  single scope quickly.

## IAM & identity

- **Grant to groups, never to people.** Bind roles to `gcp-*` Google groups and manage membership in
  the directory, ideally provisioned from the enterprise IdP so joiner/mover/leaver flows update
  access automatically.
- **Least privilege at the narrowest scope.** Grant network admin on the host project, not the
  Organization; grant developer roles on the environment folder, not org-wide.
- **Protect break-glass.** Retain a super-admin out-of-band, MFA-protected, alarmed on sign-in, and
  excluded from daily operations. Audit its use.
- **No service-account keys.** Enforce `iam.disableServiceAccountKeyCreation` and use Workload
  Identity Federation / attached service accounts. Never download, commit, or store an exported key.

## Logging, billing & cost

- **One authoritative audit trail.** Keep the aggregated org sink (`org-audit-sink-common-prod`)
  writing to a dedicated logging project with tight IAM and appropriate retention; treat it as
  security-owned and tamper-evident.
- **Attribute cost by construction.** Because billing exports to BigQuery and every project carries
  `cost-center`/`owner` labels, FinOps can attribute spend without after-the-fact tagging projects.
- **Set budgets and alerts early.** Add budget alerts per environment folder so runaway spend
  surfaces before the invoice.

## Networking

- **Consume the Shared VPC, don't rebuild it.** Workload teams attach as service projects and get
  granted specific subnets — no team owns the network. This keeps firewall policy and egress
  centralized and auditable.
- **Custom-mode VPC, no default network.** Enforce `compute.skipDefaultNetworkCreation` so no project
  silently gets an unmanaged default network.

## Change management & automation

- **Everything through the seed identity, dry-run first.** Provision via the CI/Workload-Identity
  identity from the seed project; run every tool without `--apply` first and inspect the plan.
- **Keep IaC at the pattern level, source-of-truth in one place.** Terraform / Cloud Foundation
  Toolkit blueprints express the pattern; keep state in the seed project's state bucket, version the
  baseline (`Org Policy Baseline – Org – v1`), and bump the version when it changes.
- **Re-validate after every wave.** Run `gcp_landing_zone_validate.py` after each Expand wave — the
  landing zone is a living foundation, and drift (a manually created project, a removed constraint)
  should be caught by the report, not by an incident.

## Boundaries to respect

- **Defer legal/regulatory determinations.** Data-residency law, records-retention duty, and legal
  hold are decided by legal/records/compliance; you provide the technical controls (region
  constraints, retention, export) and the evidence.
- **Treat tier/preview features as verify-first.** SCC tiers, BeyondCorp Enterprise, VPC Service
  Controls behaviors, and Gemini Enterprise features are version-dependent — confirm current
  availability in your organization before you design a dependency on them.
