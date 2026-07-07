# Solution Overview

## What this is

This solution builds the **Google Cloud landing zone**: the secure, governed foundation that every
later workload lands on. It is the first thing a large enterprise should stand up when it adopts
Google Cloud Platform (GCP) — before any application team creates its first production project.

A landing zone is not a single service you turn on. It is a *coherent set of foundational decisions*
made once, applied consistently, and enforced by policy:

- a **resource hierarchy** — the Organization at the root, then **folders** (by environment and
  business function), then **projects** (the unit of billing, IAM, and API enablement);
- **organization policies** — preventive guardrails that constrain what any project below them can
  do (allowed regions, no external IPs by default, no service-account key creation, etc.);
- a **least-privilege IAM baseline** delivered through **Cloud Identity / Workspace groups**, so
  access is granted to *groups by role*, never to individuals ad hoc;
- **centralized audit logging** aggregated into a dedicated logging project, plus **billing export**
  to BigQuery so cost is attributable from day one;
- a **shared-network landing pattern** (Shared VPC) so workload projects consume vetted, centrally
  governed networking instead of each team building its own;
- a **naming and labeling convention** so every folder, project, and resource is identifiable,
  attributable, and queryable.

The enterprise context this is written for: an organization of **80,000–150,000+ users** moving off
Microsoft 365 / Entra onto **Google Workspace + Google Cloud Platform**, and adopting Gemini
Enterprise. Automation here is **Python** (the `gcloud` CLI and Google Cloud Client Libraries),
not PowerShell.

## How it works — the reference design

The landing zone is built top-down against the GCP resource hierarchy:

```
Organization (the enterprise domain, e.g. example.com)
├── Folder: Common          → shared platform services
│   ├── Project: Logging – Common – Prod        (aggregated audit-log sink target)
│   ├── Project: Billing-Export – Common – Prod (BigQuery billing export dataset)
│   └── Project: Networking-Host – Shared-VPC – Prod (Shared VPC host project)
├── Folder: Production       → live workloads
│   └── (workload service projects attach to the Shared VPC host)
├── Folder: Non-Production   → dev / test / staging
└── Folder: Bootstrap        → the seed project that provisions the above (IaC state, CI identity)
```

Reference-design decisions this solution makes and names:

1. **Hierarchy.** Folders represent *environment and trust boundary* (Common, Production,
   Non-Production, Bootstrap); projects represent *a single deployable/attributable unit*. This
   keeps org-policy inheritance predictable — a guardrail set on `Folder: Production` applies to
   every project beneath it.
2. **Guardrails via Organization Policy.** A baseline set of org-policy constraints is applied at
   the Organization node (inherited everywhere) and, where a folder needs to relax or tighten, at
   the folder. The baseline set is named `Org Policy Baseline – Org – v1` and includes commonly
   recommended constraints such as `iam.disableServiceAccountKeyCreation`,
   `compute.vmExternalIpAccess`, `compute.skipDefaultNetworkCreation`, `gcp.resourceLocations`,
   `iam.allowedPolicyMemberDomains` (domain-restricted sharing), and
   `storage.uniformBucketLevelAccess`. Exact constraint availability and behavior is
   version-dependent — **verify each constraint in your organization** against the current
   Organization Policy constraints reference before enforcing.
3. **IAM baseline through groups.** Access is modeled as **roles granted to Google groups**, never
   to named users. A small set of foundation groups (e.g. `gcp-organization-admins`,
   `gcp-billing-admins`, `gcp-network-admins`, `gcp-security-admins`, `gcp-logging-viewers`) is
   created in the Google Admin console / Cloud Identity, and bound to purpose-built roles at the
   Organization or folder scope. A **break-glass super-admin** is retained out-of-band, audited,
   and MFA-protected, and is *not* used for day-to-day work.
4. **Centralized logging.** An **aggregated log sink** at the Organization node routes audit logs
   (Admin Activity is always on; Data Access is enabled where policy requires) to a sink target in
   `Project: Logging – Common – Prod` — typically a log bucket or a BigQuery dataset — so security
   has one authoritative, tamper-evident audit trail.
5. **Billing export.** The billing account exports **standard usage cost** (and, where enabled,
   detailed/pricing exports) to a BigQuery dataset in `Project: Billing-Export – Common – Prod`, so
   FinOps can attribute spend by folder, project, and label.
6. **Shared-network landing.** A **Shared VPC host project** (`Project: Networking-Host – Shared-VPC
   – Prod`) owns the VPC, subnets, routes, and firewall policy; workload (service) projects are
   *attached* to it and granted use of specific subnets. Teams get networking without owning the
   network. (VPC Service Controls perimeters, if in scope, are a separate solution that builds on
   this host.)
7. **Naming & labeling.** Every artifact follows `<Purpose> – <Scope> – <Stage>` for human-facing
   names and a normalized `env` / `owner` / `cost-center` / `data-class` **label** set for
   machine-queryable attribution. A helper tool in this solution generates and validates both.

## The deployment model — Assess → Design → Configure → Pilot → Validate → Expand

Every change in this solution follows the house model, pilot-first, with explicit pass/fail gates and
a documented rollback for anything org-wide:

- **Assess** — inventory the current Organization, any existing projects, IAM, and billing (the
  read-only assessment tool).
- **Design** — agree the hierarchy, naming/labeling convention, guardrail set, group model, and the
  pilot scope with platform, security, network, and FinOps owners.
- **Configure** — build the hierarchy, apply guardrails, set the IAM baseline, wire logging and
  billing export, and stand up the Shared VPC — **dry-run first**, then apply.
- **Pilot** — validate on a single named pilot folder/project (`Landing Zone – Pilot`) before
  touching the whole Organization.
- **Validate** — run the validation report; every gate must pass (hierarchy present, guardrails
  enforced, logs flowing, billing exporting, Shared VPC attachable).
- **Expand** — onboard remaining folders/projects and workload teams onto the proven pattern.

## Benefits

- **Consistency & attributability** — every workload lands into the same governed shape; cost and
  access are attributable by construction, not reconstructed later.
- **Preventive security** — org policies stop misconfiguration *before* it happens (no external IPs,
  no service-account keys, region-locked resources), rather than detecting it after.
- **Least-privilege at scale** — group-based IAM means access reviews and joiner/mover/leaver
  changes happen in one place (the group), not across thousands of bindings.
- **One audit trail, one cost ledger** — centralized logging and billing export give security and
  FinOps authoritative, org-wide sources of truth.
- **Faster, safer onboarding** — new teams attach to the Shared VPC and inherit guardrails in
  minutes, with no bespoke networking or policy per team.

## Limitations & boundaries

- This is the **foundation**, not the workloads. It does not deploy applications, GKE clusters, data
  platforms, or Gemini Enterprise itself — it makes the place those land.
- **VPC Service Controls, BeyondCorp Enterprise, and Security Command Center Premium/Enterprise
  tiers** are referenced as the next layer and are separate solutions; tier-specific features are
  version-dependent — **verify availability in your organization**.
- **Infrastructure-as-Code** (Terraform / the Cloud Foundation Toolkit blueprints) is presented at
  the *pattern* level with representative snippets; module internals defer to the tool's own docs.
  The provided automation is Python over `gcloud` / Cloud Client Libraries.
- **Regulatory and legal determinations** (data-residency law, records-retention duty, legal hold)
  are deferred to the organization's legal, records, and compliance functions; this solution
  supplies the technical method (region constraints, log retention, export) and the evidence.
- Exact console navigation and constraint/feature availability change over time; where a step is
  version- or preview-dependent it is flagged **"verify in your organization"** rather than
  asserted.
