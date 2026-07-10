# 3. Implementation Guide — Azure Kubernetes Service (AKS) Secure Baseline

Follow these steps **in order**. The cluster is deployed by **Infrastructure-as-Code** (Terraform in this guide — the Bicep `what-if` flow is equivalent), then RBAC, policy, and workload identity are applied with `kubectl`. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Everything runs **plan / what-if first** and on the **non-production** cluster first. Assign Azure Policy for Kubernetes in **audit**, prove the baseline, then move the **same** assignment to **deny** on an approved gate. Keep a rollback (`terraform destroy` of the non-prod stack / policy back to audit) for every change.

## Naming (set once, reuse verbatim)
- Non-prod cluster: `AKS Cluster – Baseline – NonProd`
- Production cluster: `AKS Cluster – Baseline – Prod`
- Resource group: `AKS RG – Baseline – NonProd`
- Entra admin group: `AKS Admins – Baseline – Prod`
- Entra developer group: `AKS Developers – Baseline – Prod`
- Application namespace: `app-baseline`
- Workload identity managed identity: `AKS Workload Identity – Baseline – NonProd`
- Kubernetes service account (federated): `wi-app-baseline`
- Policy assignment (audit stage): `AKS Guardrails – NonProd – Audit`
- Policy assignment (deny stage): `AKS Guardrails – NonProd – Deny`

## Step 1 — Assess and set variables
1. Run `AKSSEC-Discovery.ps1` to capture the subscription, VNet/subnet capacity, existing clusters, and Defender plan — this is your pre-change baseline.
2. Open the Terraform variables file (`AKSSEC-main.tf` header / a `terraform.tfvars` you create) and set: resource group `AKS RG – Baseline – NonProd`, region, existing **VNet/subnet IDs**, the **Entra admin group object ID** (`AKS Admins – Baseline – Prod`), and node sizing.
3. Confirm the operator workstation has a **network path to the private API endpoint** (peering / VPN / jumpbox) — the later `kubectl` steps depend on it.

## Step 2 — Plan the IaC (the gate)
1. `az login`, then `terraform init` in the script folder.
2. Run `terraform plan -out aksbaseline.plan`. **Review every resource** it will create: the private AKS cluster, the OIDC issuer, workload identity, the Azure Policy add-on, and the role assignments. **Nothing is created yet.**
3. (Bicep equivalent: `az deployment group what-if` — review the same resource set.)
4. Only continue when the plan matches intent and the change is approved.

## Step 3 — Deploy the private non-prod cluster
1. Run `terraform apply aksbaseline.plan`. This creates `AKS Cluster – Baseline – NonProd` with: **private API endpoint** (`private_cluster_enabled = true`), **Azure CNI**, **Entra integration + Azure RBAC for Kubernetes** (`azure_rbac_enabled = true`, local accounts disabled), **Azure Policy add-on** (`azure_policy_enabled = true`), **OIDC issuer** and **workload identity** enabled.
2. When apply completes, confirm outputs (cluster name, OIDC issuer URL, node resource group).
3. Run `AKSSEC-Validate.ps1` — it confirms private API, Azure RBAC, the policy add-on, OIDC, and workload identity are all on.

## Step 4 — Connect over the private endpoint
1. `az aks get-credentials --resource-group "<AKS RG – Baseline – NonProd>" --name "<AKS Cluster – Baseline – NonProd>"`.
2. Because Entra + Azure RBAC is enabled, `kubelogin convert-kubeconfig -l azurecli` prepares the kubeconfig for Entra sign-in.
3. From a workstation **on the cluster's network**, run `kubectl get nodes` — it should list the node pool. (If it times out, you are not on a network that can reach the private endpoint — see Troubleshooting.)

## Step 5 — Apply Kubernetes RBAC (least privilege)
1. Edit `AKSSEC-baseline.yaml` and replace the placeholder Entra **group object IDs** with `AKS Admins – Baseline – Prod` and `AKS Developers – Baseline – Prod`.
2. `kubectl apply -f AKSSEC-baseline.yaml` creates the `app-baseline` namespace, a `ClusterRoleBinding` mapping the admin group to a scoped admin role, and a namespaced `RoleBinding` mapping the developer group to an **edit** role in `app-baseline` only — **not** cluster-admin.
3. Confirm no user holds the local cluster-admin credential (local accounts were disabled in Step 3).

## Step 6 — Assign Azure Policy for Kubernetes in audit
1. `portal.azure.com` → **Policy** → **Definitions** → filter category **Kubernetes**. Select the built-in **initiative** for cluster pod security baseline/restricted plus the individual guardrails you need (no privileged containers, allowed images/registries only, resource limits required, no host path/namespace).
2. **Assign** at the **cluster's resource-group scope**. **Assignment name:** `AKS Guardrails – NonProd – Audit`. Set every effect to **audit**.
3. Gatekeeper reports violations without blocking. Give it time to sync, then review **Policy → Compliance**.
4. Run `AKSSEC-Report.ps1` to capture the audit-stage compliance picture.

## Step 7 — Wire workload identity (secretless pod auth)
1. Confirm the IaC created the user-assigned managed identity `AKS Workload Identity – Baseline – NonProd` and its **federated credential** pointing at the cluster's OIDC issuer + the service account `system:serviceaccount:app-baseline:wi-app-baseline`.
2. In `AKSSEC-baseline.yaml`, the `ServiceAccount` **`wi-app-baseline`** carries the annotation `azure.workload.identity/client-id: <managed identity client id>` and the sample pod carries the label `azure.workload.identity/use: "true"`. Set the client ID and `kubectl apply -f AKSSEC-baseline.yaml`.
3. Grant the managed identity **least-privilege** access to the target Azure resource (e.g. **Key Vault Secrets User** on one vault) — do **not** grant broad rights.
4. Deploy the sample workload; it should read the Azure resource using the **federated token** with **no secret** in the pod spec.

## Step 8 — Enable Microsoft Defender for Containers
1. `portal.azure.com` → **Microsoft Defender for Cloud** → **Environment settings** → the subscription → enable the **Containers** plan (agreed in requirements).
2. Confirm the Defender extension/agent deploys to the cluster (it installs automatically for the plan).
3. **Defender for Cloud** → **Recommendations** — review **image-scan** findings for your registry and **node-hardening** recommendations; remediate the highest-severity first.
4. Run `AKSSEC-Report.ps1` to capture Defender coverage and top findings alongside the policy compliance picture.

## Step 9 — Validate on the non-prod cluster
1. Run `AKSSEC-Validate.ps1` → private API, Azure RBAC, policy add-on, OIDC, workload identity all confirmed.
2. Complete the **Testing Guide** — the deny-blocks-privileged test in **audit** should *report* but not block yet.
3. Only proceed to the gate when every non-prod test passes.

## Step 10 — Move policy from audit to deny (the gate)
1. **Gate:** proceed only when the audit picture is clean (violations understood, legitimate exceptions exempted) and the change is approved.
2. **Policy** → **Assignments** → duplicate `AKS Guardrails – NonProd – Audit` as `AKS Guardrails – NonProd – Deny`, or edit it, setting each guardrail **effect** to **deny**.
3. Re-run the Testing Guide privileged-pod test — Gatekeeper must now **reject** the deployment at admission; a compliant workload still deploys.
4. **Rollback:** if deny blocks legitimate work, set the effect back to **audit** (or remove the deny assignment) — running workloads are unaffected.

## Step 11 — Expand to production
1. Re-run the IaC targeting the production resource group/VNet to create `AKS Cluster – Baseline – Prod` (same definition, prod variables) — **plan first**.
2. Apply the RBAC manifests with the same Entra groups, and assign the **validated** policy initiative (in the effect stage you proved) at the prod cluster scope.
3. Wire workload identity for prod (a prod managed identity + federated credential) and enable Defender for Containers on the prod scope.
4. Re-validate each cluster with `AKSSEC-Validate.ps1` and track posture/drift with `AKSSEC-Report.ps1`.

---
### Order of operations
`Assess → terraform plan (gate) → deploy private non-prod cluster → connect over private endpoint → apply Kubernetes RBAC → assign policy (audit) → wire workload identity → enable Defender → validate → move policy to deny (gate) → expand to prod`
