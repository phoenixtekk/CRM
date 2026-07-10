# 5. Testing Guide — Azure Kubernetes Service (AKS) Secure Baseline

Run after the non-prod deploy (Implementation Step 9), again after moving policy to deny (Step 10), and after each expansion. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names, and the scripts are `AKSSEC-Discovery.ps1`, `AKSSEC-Validate.ps1`, `AKSSEC-Report.ps1`.

## Test 1 — API server is private
**Do:** `az aks show -g "<AKS RG – Baseline – NonProd>" -n "<AKS Cluster – Baseline – NonProd>" --query apiServerAccessProfile.enablePrivateCluster`; or run `AKSSEC-Validate.ps1`.
**Expected:** Returns **true**. The API server has a private endpoint; a `kubectl` call from *off* the cluster network times out (this is the point).

## Test 2 — Entra + Azure RBAC for Kubernetes
**Do:** From a workstation on the cluster network, `kubectl get nodes` as a member of `AKS Admins – Baseline – Prod`; then as a member of `AKS Developers – Baseline – Prod`.
**Expected:** The admin sign-in triggers Entra auth and lists nodes; the developer can act **only** inside `app-baseline` and is denied cluster-wide admin. No one uses a local cluster-admin credential (local accounts disabled).

## Test 3 — Least-privilege RBAC bindings present
**Do:** `kubectl get clusterrolebinding,rolebinding -A | grep baseline`; or run `AKSSEC-Validate.ps1`.
**Expected:** The admin `ClusterRoleBinding` and the `app-baseline` developer `RoleBinding` exist and reference the Entra **group object IDs** — not individual users, not cluster-admin for developers.

## Test 4 — Azure Policy add-on / Gatekeeper healthy
**Do:** `kubectl get pods -n gatekeeper-system`; **Policy → Compliance** for `AKS Guardrails – NonProd – Audit`; or run `AKSSEC-Validate.ps1`.
**Expected:** Gatekeeper pods are running and the audit-stage assignment shows a per-constraint compliant/non-compliant breakdown.

## Test 5 — Audit reports, does not block (audit stage)
**Do:** Deploy a deliberately non-compliant pod (privileged, or an image from a disallowed registry) into `app-baseline`.
**Expected:** The pod **is created** but shows as **non-compliant** in Policy compliance — audit reports, it does not block.

## Test 6 — Workload identity is secretless
**Do:** Deploy the sample workload using service account `wi-app-baseline` (label `azure.workload.identity/use: "true"`) and have it read the granted Azure resource (e.g. a Key Vault secret).
**Expected:** The workload authenticates with a **federated token** and reads the resource with **no secret / connection string** in the pod spec. `kubectl describe pod` shows no injected secret credential.

## Test 7 — Defender for Containers scanning
**Do:** **Microsoft Defender for Cloud → Recommendations**; or run `AKSSEC-Report.ps1`.
**Expected:** The Containers plan is enabled, images show scan results, and node-hardening recommendations are listed for the cluster.

## Test 8 — Deny blocks (after the gate)
**Do:** After Step 10, re-deploy the privileged / disallowed-registry pod from Test 5.
**Expected:** Gatekeeper **rejects** the deployment at admission with a policy message; a compliant pod still deploys successfully.

## Test 9 — Posture report
**Do:** Run `AKSSEC-Report.ps1`.
**Expected:** A clear baseline report — private-API state, Azure RBAC, RBAC bindings, policy assignments and compliance, workload-identity/OIDC state, and Defender coverage with top findings.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Non-prod pass (pre-deny)** | Tests 1–7 pass; the audit picture is understood and exceptions exempted |
| **Deny pass** | Test 8 passes — a privileged/disallowed pod is blocked and a compliant one still deploys |
| **Expand pass** | Tests 1–4, 6, 9 pass on the production cluster before it carries real workloads |
