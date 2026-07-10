# Executive Summary — Azure Landing Zone with Terraform

## The problem
Most Azure estates start the same way: someone creates a subscription, clicks resources into the portal,
and the organization is live. It doesn't scale. There is no management-group hierarchy to inherit policy,
no guardrails to stop resources landing in the wrong region or without tags, no consistent RBAC, and no
record of who changed what. Within months the environment has **drifted** — the portal no longer matches
anyone's intent — and every new subscription repeats the manual work. Governance, cost control, and
security all suffer because the foundation was never codified.

## The solution
This solution deploys an **Azure landing zone as code with Terraform** — a governed, versioned cloud
foundation you stamp out repeatably:
1. **Management group hierarchy + subscription vending** — a Cloud Adoption Framework-aligned hierarchy
   (Platform / Landing Zones / Sandbox / Decommissioned) so policy and RBAC **inherit** downward, and a
   repeatable pattern for placing new subscriptions.
2. **Azure Policy guardrails as code** — allowed regions, required tags, and security baselines assigned
   at the right scope in **audit/`Disabled` first**, then enforced (`Deny`) after validation.
3. **Identity & RBAC baseline + remote Terraform state** — least-privilege role assignments defined in
   code, with state stored in a locked, versioned Azure Storage backend (never on a laptop).
4. **Hub-spoke networking & DNS** — a connectivity hub with spokes, peering, and private DNS, ready for
   workloads.
5. **CI/CD pipeline (plan → approve → apply) with drift detection** — every change runs `terraform plan`
   for review, requires a manual approval before `apply`, and a scheduled plan flags drift.

Delivery follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model: discover the
current estate, author the modules, run **plan/what-if** against a **non-production** target first, prove
the gates, then promote to production behind an approval gate — never an unreviewed apply against prod.

## What's included
Full documentation (overview, requirements, ordered implementation, testing matrix, troubleshooting,
best practices) plus **five deployable artifacts**: a read-only **discovery** script, the core Terraform
(**`main.tf`**), a **validation** script (plan + policy-compliance), a **CI/CD pipeline** (`azure-
pipelines.yml`) with plan/apply approval and drift detection, and a **drift/governance report** script.
Everything is **plan/what-if-first and approval-gated**; no secrets live in code.

## Business value
- **Repeatable & governed** — stamp out subscriptions from the same code, with policy and RBAC inherited.
- **No drift** — state + a scheduled plan catch out-of-band changes before they compound.
- **Auditable** — every change is a reviewed pull request and an approved pipeline run.
- **Safe** — plan/what-if against non-prod, manual approval before any prod apply, and a clear rollback.

## Effort and boundary
A competent admin comfortable with Terraform and Azure can stand up the pilot landing zone (hierarchy,
state, baseline policy, one hub) in a few focused sessions, then expand. This guide provides the
**technical foundation and the automation**. Your organization's **naming/tagging standard, allowed
regions, RBAC model, and production change-approval process** are governance decisions the guide encodes
but does not decide for you.

> **Version note:** Terraform, the AzureRM/AzAPI providers, and any Azure landing-zone modules are
> **version-sensitive**. All provider and module versions in this solution are **pinned and flagged
> "verify"** — confirm current supported versions against the provider/module registries before you
> apply. *Verify current availability and version compatibility for your tenant.*
