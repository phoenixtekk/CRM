# 2. Requirements — Intune-as-Code (Graph & Terraform, CI/CD)

The category-wide prerequisites (target subscription/tenant with rights, IaC tooling, source control, CI/CD platform and service connection, remote state backend, secrets management, naming/tagging standards, and a non-production target) are covered once in **Global Requirements — DevOps** and are **not repeated here**. Confirm those first. Below are the prerequisites **specific to managing Intune as code**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Microsoft Intune licensed and in use
**Description:** An Intune-enabled tenant (Intune stand-alone, or via Microsoft 365 E3/E5 / EMS) with at least some enrolled devices or target groups.
**Why required:** You are exporting and managing Intune policies; without Intune licensing and objects there is nothing to codify.
**How to verify:** The **Intune admin center** (intune.microsoft.com) loads and shows **Devices** / **Configuration** / **Compliance**; users have Intune licenses.
**How to implement if missing:** Assign Intune licenses and complete basic tenant setup before codifying policy. *Verify current licensing SKUs and availability in your tenant.*

## R2. Entra app registration with Graph application permissions
**Description:** An Entra ID **app registration** (service principal) that Terraform and the PowerShell scripts authenticate as, with the Microsoft Graph **application** permissions to read and write Intune configuration, compliance, and app policies.
**Why required:** Non-interactive pipeline runs and scripts need an app identity with least-privilege Graph rights; delegated/interactive auth does not work in CI/CD.
**How to verify:** In **Entra ID → App registrations**, the app exists; under **API permissions** the required Graph application permissions (e.g. `DeviceManagementConfiguration.ReadWrite.All`, `DeviceManagementApps.ReadWrite.All`, `DeviceManagementManagedDevices.Read.All`) show **Granted** admin consent. *Verify the current minimum permission set.*
**How to implement if missing:** Register the app, add the Graph application permissions, and have a Global/Privileged Role Administrator grant **admin consent**. Store its credential in Key Vault / the pipeline secret store, never in code.

## R3. Terraform Microsoft Graph provider available and pinned
**Description:** The Terraform provider that manages Intune via Microsoft Graph, pinned to a specific version in the repo, plus the Terraform CLI (per Global Requirements G2).
**Why required:** The provider is the declarative engine; Intune resource coverage and schema change between provider versions, so it must be pinned for reproducibility.
**How to verify:** `terraform init` downloads the pinned provider and `terraform providers` lists it; the provider documents the Intune resources you need. *Verify the current provider name, version, and Intune resource coverage — the Microsoft Graph / Intune Terraform provider ecosystem is evolving and some endpoints are beta.*
**How to implement if missing:** Add the provider with a pinned version constraint in `versions.tf`, run `terraform init`, and confirm the resources you need are supported (fall back to the PowerShell/Graph path for unsupported types).

## R4. Microsoft.Graph PowerShell module
**Description:** The `Microsoft.Graph` PowerShell SDK (used for baseline export, backup, and drift reporting).
**Why required:** The export/backup/report scripts call Graph via the SDK to read the tenant to JSON.
**How to verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a supported version; `Connect-MgGraph` succeeds with the app credential. *Verify current module versions — cmdlet surfaces change between versions.*
**How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` and pin the version alongside the Terraform toolchain.

## R5. Remote Terraform state backend with locking
**Description:** A secure remote backend for Terraform state (Azure Storage container) with locking and versioning (this is Global Requirements G5 applied to Intune-as-code — called out here because state is central to plan/apply/drift).
**Why required:** State is how Terraform knows what it manages; local state is unsafe, unshareable, and makes drift detection unreliable. Losing state means Terraform tries to recreate existing policies.
**How to verify:** The `backend "azurerm"` block resolves and `terraform init` connects to the container; the container has versioning enabled.
**How to implement if missing:** Provision the storage account/container with encryption, versioning, and least-privilege access, and configure the backend before the first `apply`.

## R6. Development tenant or a designated pilot group
**Description:** Either a **development Intune tenant** for promotion testing, or — if none exists — a designated **pilot Entra group** in production that changes are assigned to first.
**Why required:** Policy changes affect real devices; dev→prod promotion and pilot-first rollout require a safe target before broad assignment.
**How to verify:** A dev tenant is reachable with its own app registration, **or** a pilot group (e.g. `Intune-Pilot – Devices – Ring0`) exists and is used as the first assignment target.
**How to implement if missing:** Obtain a dev tenant, or create the pilot group and make it the mandatory first assignment target in the code. *Which users/devices belong in the pilot ring is the customer's rollout decision.*

## R7. Backup location and change-approval process
**Description:** A storage location for the tenant policy **backup** (JSON export) and a defined **approval** step (Azure DevOps Environment check or GitHub Environment required reviewers) for the production apply.
**Why required:** Backup is the rollback for a bad change or accidental delete; approval is the control that keeps unreviewed changes out of production.
**How to verify:** The backup script writes to the location; the `Prod` environment lists required reviewers and a test run pauses at the gate.
**How to implement if missing:** Provision the backup location (secure, access-controlled) and configure the approval environment referenced by the pipeline's apply stage. *Who may approve production Intune changes is the customer's change-control decision.*
