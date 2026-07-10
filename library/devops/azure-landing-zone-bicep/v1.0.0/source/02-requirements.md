# 2. Requirements — Azure Landing Zone with Bicep

The category-wide prerequisites (target subscription/tenant with rights, IaC tooling, source control, CI/CD platform and service connection, remote state / deployment backend, secrets management, naming/tagging/region standards, and a non-production target) are covered once in **Global Requirements — DevOps** and are **not repeated here**. Confirm those first. Below are the prerequisites **specific to a Bicep landing zone**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Tenant-root (or intermediate) management-group access
**Description:** The identity deploying the hierarchy can create and assign at the management-group scope — ideally an **intermediate** management group under the tenant root, not the tenant root itself.
**Why required:** The landing zone is deployed *at* management-group scope; without rights there, the hierarchy, policy, and role assignments cannot be created.
**How to verify:** In the portal go to **Management groups** and confirm you can see the hierarchy; run `az account management-group list`. Confirm your identity has **Owner** or **Contributor + User Access Administrator** at the target management group.
**How to implement if missing:** A Global Administrator must first enable management groups (**Management groups → Start using management groups**) and grant your identity the required role at the intermediate group. *Elevating access at tenant root is the customer's governance decision.*

## R2. Bicep CLI at a supported version
**Description:** The Bicep CLI (bundled with a current Azure CLI, or installed standalone) at a version that supports deployment stacks and the `.bicep` features used here.
**Why required:** Older Bicep builds transpile differently and may not support `az stack` / deployment-stack commands.
**How to verify:** Run `az bicep version` and `az version`. *Verify current supported versions — Bicep and the Azure CLI update frequently.*
**How to implement if missing:** Run `az bicep upgrade` (or install the standalone Bicep CLI) and pin the version in the repo (`bicepconfig.json` / a tool-version file).

## R3. Deployment-stacks availability in the target environment
**Description:** **Azure deployment stacks** available in the subscription/management group and Azure environment (Commercial, or a Government/sovereign cloud) you are targeting.
**Why required:** The solution deploys and rolls back through deployment stacks; if the feature or its API version is not available, you fall back to standard `az deployment mg/sub create`.
**How to verify:** Run `az stack mg list` (or `az stack sub list`) against the target scope; if the command errors as unrecognized, upgrade the CLI. *Verify deployment-stacks availability and the exact API version in your tenant/cloud — some features are in preview or region-limited.*
**How to implement if missing:** Upgrade the Azure CLI; if stacks are unavailable in your cloud, use the provided pipeline's standard-deployment fallback path (documented in the Implementation Guide).

## R4. Resource providers registered
**Description:** The ARM resource providers the landing zone uses — at minimum `Microsoft.Authorization` (policy/RBAC), `Microsoft.Management` (management groups), `Microsoft.Network` (VNets, firewall, private DNS), and `Microsoft.Resources`.
**Why required:** A deployment against an unregistered provider fails with a `MissingSubscriptionRegistration`-style error.
**How to verify:** `az provider list --query "[?registrationState=='Registered'].namespace"` on each target subscription.
**How to implement if missing:** `az provider register --namespace Microsoft.Network` (repeat per provider); registration is asynchronous — re-check until `Registered`.

## R5. Address-space plan for hub-spoke (non-overlapping)
**Description:** A reserved, **non-overlapping** IP address plan — a CIDR block for the hub VNet and distinct blocks per spoke — that does not collide with on-premises or other Azure networks.
**Why required:** VNet peering fails or routes incorrectly when address spaces overlap; this cannot be fixed after workloads land without re-addressing.
**How to verify:** Confirm the chosen hub/spoke CIDRs against your IPAM / existing network inventory; the discovery script lists existing VNet ranges.
**How to implement if missing:** Allocate the ranges from your IPAM before deploying the network module; encode them as parameters in the Bicep, never as hard-coded literals.

## R6. Naming and tagging convention encoded as parameters
**Description:** The organization's naming convention and required tags (per Global Requirements G7) expressed as Bicep parameters/variables so every resource is named and tagged consistently.
**Why required:** Policy will enforce naming/tags; inconsistent names break governance, cost allocation, and the deny guardrails.
**How to verify:** The repo has a `parameters/` file (or `.bicepparam`) defining prefixes, environment codes, and the required tag set.
**How to implement if missing:** Capture the convention as parameters before first deploy; the Implementation Guide names every object with the `<Purpose> – <Scope> – <Stage>` convention.

## R7. Pipeline approval gate and reviewer group
**Description:** A named group of approvers and a configured **environment approval** (Azure DevOps *Environment* checks, or a GitHub *Environment* with required reviewers) that the production stage must pass.
**Why required:** No production apply runs without human approval after the `what-if` review; this is the control that makes IaC safe.
**How to verify:** The `Prod` environment in the pipeline platform lists required reviewers; a test run pauses at the gate.
**How to implement if missing:** Create the environment, add the reviewer group, and reference it from the production stage (shown in `azure-pipelines.yml`). *Who may approve production changes is the customer's change-control decision.*
