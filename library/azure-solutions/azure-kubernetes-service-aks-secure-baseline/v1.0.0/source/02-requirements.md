# 2. Requirements Guide — Azure Kubernetes Service (AKS) Secure Baseline

Verify **every** requirement before deploying. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md` (tenant, admin roles, licensing, connectivity, change control, rollback) and are not repeated here. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim.

## 2.1 An Azure subscription with sufficient rights
**Description:** A subscription under your Entra tenant, and an operating account with **Owner** (or **Contributor** + **Role Based Access Control Administrator**) on the target resource group / subscription.
**Why:** Creating the cluster, assigning Azure RBAC for Kubernetes, and creating role assignments for the managed identity all require rights to write resources *and* role assignments.
**Verify:** `portal.azure.com` → **Subscriptions → Access control (IAM)**; run `AKSSEC-Discovery.ps1`.
**Implement-if-missing:** Assign the minimum roles at the narrowest scope; prefer **PIM eligible** activation over standing access.

## 2.2 A virtual network and subnet for the cluster
**Description:** An existing **virtual network** with a dedicated **subnet** sized for Azure CNI (one IP per pod plus nodes), and a plan for management connectivity to the **private** API endpoint.
**Why:** A private, CNI-networked cluster lives inside your VNet; the subnet must have enough address space, and admins/CI need a network path (peering, VPN, Bastion, or a private DNS-resolving jumpbox) to reach the private API.
**Verify:** `portal.azure.com` → **Virtual networks** → confirm the subnet and free address count; `AKSSEC-Discovery.ps1` reports VNet/subnet capacity.
**Implement-if-missing:** Create/resize a subnet with headroom (size for max pods × max nodes); stand up a peered management network, VPN, or a jumpbox VM that can resolve the private endpoint.

## 2.3 Entra ID groups for cluster access (least privilege)
**Description:** Entra **security groups** that map to Kubernetes roles — at minimum a **cluster admin** group and a **namespace developer** group; capture their **object IDs**.
**Why:** Azure RBAC for Kubernetes and the RBAC manifests bind **Entra groups**, not individuals, to least-privilege roles — this is what replaces a shared cluster-admin kubeconfig.
**Verify:** `entra.microsoft.com` → **Groups** → confirm the groups and copy each **Object ID**; `AKSSEC-Discovery.ps1` echoes the IDs you supply.
**Implement-if-missing:** Create the groups (e.g. `AKS Admins – Baseline – Prod`, `AKS Developers – Baseline – Prod`) and add members; record the object IDs for the RBAC manifests.

## 2.4 IaC tooling and Kubernetes CLI on the operator workstation
**Description:** **Terraform** (or the **Bicep**/Azure CLI toolchain), **Az PowerShell** (Az.Accounts, Az.Aks, Az.Resources, Az.Security), **Azure CLI** with the `aks-preview` extension where a feature requires it, and **kubectl** + **kubelogin**.
**Why:** The cluster is deployed by IaC and the RBAC/policy/workload-identity objects are applied with `kubectl`; `kubelogin` is required for Entra-integrated cluster sign-in.
**Verify:** `terraform version`, `az version`, `kubectl version --client`, `kubelogin --version`; `AKSSEC-Validate.ps1` checks tool presence.
**Implement-if-missing:** Install Terraform / Azure CLI / Az PowerShell / kubectl / kubelogin; register the `aks-preview` extension only if a chosen feature is still preview.

## 2.5 Azure Policy for Kubernetes add-on available
**Description:** The **Azure Policy add-on** for AKS (Gatekeeper) and the **Microsoft.PolicyInsights** / **Microsoft.ContainerService** resource providers registered on the subscription.
**Why:** The add-on installs Gatekeeper and lets Azure Policy initiatives enforce admission guardrails; the providers must be registered before the add-on installs.
**Verify:** `az provider show -n Microsoft.PolicyInsights` and `Microsoft.ContainerService` show **Registered**; `AKSSEC-Validate.ps1` checks provider + add-on state.
**Implement-if-missing:** `az provider register --namespace Microsoft.PolicyInsights` (and `Microsoft.ContainerService`); the add-on is enabled by the IaC (`azure_policy_enabled = true`). *Verify current add-on availability in your region.*

## 2.6 Workload identity / OIDC prerequisites
**Description:** The cluster's **OIDC issuer** and **workload identity** enabled, plus a **user-assigned managed identity** the pods will federate to, and a decision on which Azure resources that identity may reach.
**Why:** Workload identity exchanges the cluster's OIDC token for an Entra token tied to the managed identity — this is what makes pod-to-Azure auth **secretless**.
**Verify:** After deploy, `az aks show ... --query oidcIssuerProfile.enabled` and `securityProfile.workloadIdentity.enabled` return `true`; `AKSSEC-Validate.ps1` confirms both.
**Implement-if-missing:** The IaC sets `oidc_issuer_enabled = true` and `workload_identity_enabled = true` and creates the managed identity; grant that identity least-privilege access to the target resource (e.g. Key Vault secrets user). *Verify current workload-identity GA status in your region.*

## 2.7 Microsoft Defender for Containers plan decision
**Description:** A decision to enable **Microsoft Defender for Containers** on the subscription (image scanning, runtime detection, node hardening).
**Why:** Image-scan findings, runtime alerts, and node-hardening recommendations come from this Defender plan; it is **paid** per resource.
**Verify:** `portal.azure.com` → **Microsoft Defender for Cloud → Environment settings → Containers** plan status; `AKSSEC-Discovery.ps1` reports the plan tier.
**Implement-if-missing:** Enable the Containers plan on the in-scope subscription. *Verify current pricing before enabling.*

## 2.8 Change control, non-prod cluster, and rollback
**Description:** An approved change window, a named **non-production** cluster to prove the baseline on first, and a documented rollback before any production apply or policy move to deny.
**Why:** IaC applies and deny policies can disrupt real workloads; the plan/what-if gate, a non-prod-first proof, and a rollback are the safety net (per `global-requirements-azure-solutions.md` G5/G6).
**Verify:** An approved change record, the non-prod cluster name, and a written back-out exist.
**Implement-if-missing:** Define the non-prod cluster (`AKS Cluster – Baseline – NonProd`), capture the current state (`AKSSEC-Report.ps1`), and write the rollback (`terraform destroy` of the non-prod stack / set policy assignments to **audit**).

---
## Checklist
- [ ] Subscription + Owner (or Contributor + RBAC Administrator) — `AKSSEC-Discovery.ps1`
- [ ] VNet + CNI-sized subnet + management path to the private API
- [ ] Entra admin & developer groups (object IDs captured)
- [ ] Terraform / Az PowerShell / Azure CLI / kubectl / kubelogin installed — `AKSSEC-Validate.ps1`
- [ ] Microsoft.PolicyInsights + Microsoft.ContainerService registered; Azure Policy add-on available
- [ ] OIDC issuer + workload identity + user-assigned managed identity plan
- [ ] Defender for Containers plan decision made
- [ ] Change window, non-prod cluster, and rollback documented
