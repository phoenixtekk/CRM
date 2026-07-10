# 1. Solution Overview — Intune-as-Code (Graph & Terraform, CI/CD)

## What Intune-as-code is
**Intune-as-code** is the practice of defining your Microsoft Intune configuration — device configuration profiles, compliance policies, and app-protection/app-configuration policies — as **files in Git** rather than as clicks in the Intune admin center, and deploying them through a **CI/CD pipeline** instead of by hand. The configuration lives in **Terraform** using the **Microsoft Graph provider** (Terraform talks to the same Microsoft Graph API the portal uses), so every policy is versioned, reviewed in a pull request, previewed with `terraform plan`, and applied only after approval. The result is an Intune tenant you can review, promote from test to production cleanly, back up, and audit.

## How it works
1. **Baseline export.** Before writing anything new, the current tenant is **exported to code** — existing configuration, compliance, and app policies are read from Graph and captured as the starting point, so you begin from reality, not a blank slate.
2. **Policy-as-code repo.** Policies are expressed as Terraform resources (the Microsoft Graph provider) and committed to Git. Terraform keeps a **state file** in a secure remote backend (per Global Requirements G5) recording what it manages.
3. **Plan is the preview.** `terraform plan` shows exactly what will be **created, changed, or destroyed** in Intune before anything is applied — the equivalent of a what-if.
4. **Review and approval.** Changes arrive as pull requests; the pipeline runs `validate` and `plan` and posts the plan for review; a human approves before `apply`.
5. **Dev→prod promotion.** The same code is applied first to a **development tenant (or a pilot group in production)**, validated, then promoted to production behind an approval gate — so test and prod stay in lock-step instead of drifting.
6. **Backup / restore.** A scheduled export captures the tenant's policies as JSON so a bad change or accidental delete can be restored.
7. **Drift detection.** A periodic `terraform plan` (with no code change) reveals any **portal edit made outside the pipeline** — drift — so it can be reconciled back into code or reverted.

## Two ways to talk to Graph
- **Terraform Microsoft Graph provider** — the declarative core; policies as code with plan/apply and state. *Verify the current provider name and version — the Microsoft Graph / Intune Terraform provider ecosystem is evolving; confirm the provider and Intune resource support in your environment before relying on it.*
- **PowerShell + Microsoft Graph SDK** — used here for the **baseline export**, **backup**, and **drift reporting** (reading the tenant to JSON), which is often simpler than modeling every legacy policy in Terraform on day one. *Verify current `Microsoft.Graph` PowerShell module versions.*

## What you can control
- **Which policies are code** — start with a scoped set (a few configuration + compliance + app-protection policies), then expand coverage.
- **Assignment targets** — pilot group first, then broader groups; assignments are part of the code.
- **Promotion path** — dev tenant / pilot group → production, gated by approval.
- **Backup cadence** — how often the tenant is exported to JSON.
- **Drift response** — reconcile portal changes into code, or revert them to match code.

## Limitations (be honest with buyers)
- **Not every Intune setting is modeled** by the Terraform Graph provider yet, and some Graph endpoints are **beta**. Where a policy type is unsupported, manage it via the PowerShell/Graph export-and-apply path and note it. *Verify current provider resource coverage and whether an endpoint is beta before depending on it.*
- **App-protection and app-configuration policies** depend on app-registration and, for some scenarios, specific licensing — *verify current licensing and availability in your tenant.*
- `terraform destroy` and delete operations **remove real policies** from the tenant — this is why plan-first, review, approval, and backup are mandatory.
- A **development tenant** is ideal for promotion testing; where one is not available, pilot against a **test group** in production and expand assignments carefully.
- Managing Intune as code changes the operating model — admins must stop editing in the portal for managed policies, or drift detection will constantly flag their edits.

## Authentication and connections used
- An **Entra app registration** (service principal) with the required **Microsoft Graph application permissions** (e.g. `DeviceManagementConfiguration.ReadWrite.All`, `DeviceManagementApps.ReadWrite.All`) granted admin consent — used by both Terraform and the PowerShell scripts. *Verify the current minimum permission set.*
- A **CI/CD service connection** using **workload identity federation (OIDC)** where possible, or the app registration's credential stored in the pipeline secret store / Key Vault (Global Requirements G4/G6) — never in code.
- A **remote Terraform state backend** (Azure Storage) with locking (Global Requirements G5).

## The standard deployment model
> **Assess (export the current tenant to code as a baseline) → configure the repo, provider, and a scoped set of policies as Terraform → pilot by planning/applying to a dev tenant or a test group with backup taken first → validate with the plan, the testing script, and a policy-assignment check → expand by promoting to production behind approval and widening assignments, with drift detection running on a schedule.** The repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, plan-first and approval-gated, with backup/restore as rollback.
