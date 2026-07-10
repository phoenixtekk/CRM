# 8. Deliverables Summary — Azure Landing Zone with Terraform

## What you receive
A complete, self-guided package to deploy an **Azure landing zone as code with Terraform** — a
Cloud Adoption Framework-aligned management-group hierarchy with subscription vending, Azure Policy
guardrails as code, an identity/RBAC baseline with locked remote state, hub-spoke networking and DNS, and
a CI/CD pipeline that runs **plan → approve → apply** with **drift detection**. Everything is
**plan/what-if first, non-prod first, and approval-gated**, with no secrets in code.

### Documentation
- **Executive Summary** — the problem (click-ops + drift), the solution (five landing-zone components),
  the outcome, the boundary, and the version-pinning note.
- **Solution Overview** — how Terraform, remote state, management groups, policy inheritance, and OIDC
  CI/CD fit together; the components built; scope and out-of-scope (workloads and standards decisions).
- **Requirements Guide** — landing-zone-specific prerequisites (elevated root rights, pinned
  provider/module versions, the state backend, an OIDC service connection, naming/tag/region standards, a
  non-prod target, and the Az toolchain), each with Verify / Implement, on top of the category globals.
- **Implementation Guide** — ordered steps: assess → bootstrap state → author + pin Terraform → plan/apply
  to non-prod (policy in audit) → wire the pipeline → validate → promote to Deny + vend prod, with
  **every object named** using the `<purpose>-<scope>-<stage>` convention.
- **Testing & Validation** — the four gates (clean/reviewed plan, state locking, policy inheritance in
  audit, pipeline approval + drift detection) as a pass/fail matrix, with the evidence to capture.
- **Troubleshooting** — symptom → root-cause → fix for the common failures (init/backend, state lock,
  provider drift, policy Deny blocking, MG rights, pipeline OIDC, peering, drift).
- **Best Practices** — plan-first, state discipline, audit-before-Deny, subscription vending, hub-spoke,
  secretless CI/CD, version pinning, and where to go next.

### Deployable artifacts — plan/what-if first, no secrets
| Artifact | Purpose | Default mode |
|----------|---------|--------------|
| **`IACTF-Discovery.ps1`** | Inventory the management-group hierarchy, subscriptions, policy assignments, and RBAC; confirm root rights | Read-only |
| **`main.tf`** | The core Terraform: management groups, policy assignments (audit-first), RBAC baseline, Log Analytics, hub-spoke VNets + peering, and the `azurerm` remote-state backend — provider/module versions **pinned & flagged verify** | Declarative (plan before apply) |
| **`IACTF-Validate.ps1`** | Pre/post-apply checks: backend reachability + locking, `terraform plan` in detailed-exitcode (drift) mode, provider-pin check | Plan-only / read-only |
| **`azure-pipelines.yml`** | CI/CD: `plan` on PR → **manual approval** → `apply`, plus a scheduled `plan` for **drift detection**; OIDC (secretless) auth | Plan → approve → apply |
| **`IACTF-Report.ps1`** | Governance report: Azure Policy **compliance state** per assignment/scope + drift summary (resources changed outside Terraform) | Read-only |

All PowerShell helpers are **read-only / plan-only**; the pipeline gates every `apply` behind a **manual
approval**; authentication is via **CLI/OIDC** — **no credentials or secrets live in the artifacts**.

## Outcomes
- A **governed, versioned** Azure foundation deployed from code — repeatable across subscriptions.
- **No drift** — remote state + a scheduled plan catch out-of-band changes.
- **Inherited guardrails** — policy and RBAC assigned once, inherited by every subscription below.
- **Auditable** — every change is a reviewed PR and an approved pipeline run, with a compliance report.
- A **pilot-first**, gated, reversible rollout (revert + apply) with a documented rollback.

## Assumptions & boundaries
- Provider/module **versions are pinned and flagged "verify"** — confirm current versions before applying.
- The **state backend** is bootstrapped once (outside the pipeline) before the first `init`.
- **Standards** (naming, tags, regions, RBAC model, prod change-approval) are the customer's decisions,
  encoded by the guide.
- **Workload** architecture inside landing zones and deep firewall/ExpressRoute design are out of scope.

> Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the full documentation set plus
> all five deployable artifacts (Terraform, pipeline, and PowerShell helpers) in a single ZIP, yours to
> keep and reuse on every rollout.
