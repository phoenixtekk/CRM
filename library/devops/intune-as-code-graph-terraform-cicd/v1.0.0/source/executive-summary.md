# Executive Summary — Intune-as-Code (Policy Management via Graph & Terraform, CI/CD)

**White-label · DevOps**

A click-managed Intune tenant drifts. Policies get edited in the portal with no record of who changed what or why, there is no clean way to review a change before it hits every device, "test" and "production" tenants slowly diverge, and there is no reliable backup — so a bad edit or an accidental delete is hard to undo. This solution manages **Intune as code**: existing policies are exported to source, defined as **Terraform / Microsoft Graph** in Git, and deployed through a **CI/CD pipeline** with review, approval, backup, dev→prod promotion, and drift detection.

This is a complete, **deploy-it-today** package for putting Intune under source control and a pipeline, written for an administrator who knows the Intune portal but has never exported policies to code, used the Terraform Graph provider, or run a policy-as-code pipeline.

## What you get
- A plain-language **Solution Overview** of the Intune-as-code model — baseline export, the policy-as-code repo, the CI/CD pipeline (validate → plan → review → deploy), dev→prod promotion, backup/restore, and drift detection.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite (category-wide ones live in the separate Global Requirements).
- An **Implementation Guide** of precise, ordered steps — register the app, export the current tenant to code, structure the repo, plan against **dev**, review, then promote to **prod** behind approval.
- Five IaC / automation artifacts: a **PowerShell Graph export/discovery** script, the core **Terraform (`main.tf`)** for Intune policies, a **PowerShell validation** script, an **`azure-pipelines.yml`** pipeline (validate → plan → approval → apply), and a **PowerShell backup / drift report**.
- **Testing** and **Troubleshooting** guides for a confident, non-disruptive rollout.

## What this delivers
Existing configuration, compliance, and app-protection policies **exported to code** as a versioned baseline; those policies defined and managed via the **Terraform Microsoft Graph provider** in Git; a **CI/CD pipeline** that runs `terraform plan` (the change preview), requires **review and approval**, then applies; a repeatable **dev→prod promotion** path; a **tenant backup/restore** workflow; and **drift detection** that flags portal edits made outside the pipeline — all proven against a **development tenant / test group** first.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — every change is plan-first (`terraform plan`), reviewed in a pull request, approval-gated, and piloted against a test group/dev tenant before production, with backup as the rollback.

## Outcome
An Intune tenant managed like software — every policy exported, versioned, reviewed, and promoted through CI/CD with backup and drift detection — instead of untracked portal edits and quietly diverging tenants, deployable by a single administrator and validated before you scale.
