# 6. Troubleshooting Guide — Azure Kubernetes Service (AKS) Secure Baseline

Use `AKSSEC-Discovery.ps1` for the pre-deploy picture, `AKSSEC-Validate.ps1` for the five baseline controls, and `AKSSEC-Report.ps1` for posture and drift. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names.

## A. `terraform apply` / IaC failures
| Symptom | Cause | Remediation |
|---|---|---|
| Apply fails on role assignment (`AuthorizationFailed`) | Operating account lacks rights to *write role assignments* | Grant **Owner** or **Contributor + Role Based Access Control Administrator** at the scope; re-run `terraform plan` then `apply` |
| Subnet / CNI address errors | Subnet too small for Azure CNI (IPs = maxPods × maxNodes + nodes) | Resize the subnet or lower `max_pods`/node count; re-plan. Confirm capacity with `AKSSEC-Discovery.ps1` |
| Provider / feature not found | `Microsoft.ContainerService` / `Microsoft.PolicyInsights` not registered, or a preview feature not enabled in the region | `az provider register --namespace Microsoft.ContainerService` (and PolicyInsights); *verify the feature/add-on is available in your region* |
| Version error on `kubernetes_version` / provider | Pinned version no longer offered | Set a currently supported AKS version and provider version; re-plan |

## B. `kubectl` can't reach the cluster (private API)
| Symptom | Cause | Remediation |
|---|---|---|
| `kubectl get nodes` times out | You are **not on the cluster's network** — the API is private by design | Run from a workstation with a network path to the private endpoint (VNet peering, VPN, or a Bastion/jumpbox that resolves the private DNS zone) |
| `Unable to connect ... dial tcp` on the private FQDN | Private DNS zone not resolvable from your location | Ensure the private DNS zone is linked to your management VNet, or use the jumpbox inside the cluster VNet |
| Auth prompt loops / `error: You must be logged in` | Entra-integrated cluster needs kubelogin | `kubelogin convert-kubeconfig -l azurecli` after `az aks get-credentials`; sign in as a member of `AKS Admins – Baseline – Prod` |

## C. Access denied for the right people
| Symptom | Cause | Remediation |
|---|---|---|
| A developer can't act in `app-baseline` | Not a member of `AKS Developers – Baseline – Prod`, or the `RoleBinding` uses the wrong object ID | Confirm group membership; verify the `RoleBinding` subject is the **group object ID**; re-apply `AKSSEC-baseline.yaml` |
| Everyone is blocked, even admins | Local accounts disabled and Azure RBAC role not assigned in Azure | Assign the Entra admin group the **Azure Kubernetes Service RBAC Cluster Admin** role at the cluster scope; confirm with `AKSSEC-Validate.ps1` |
| Developer has cluster-wide power | Developer group bound to `cluster-admin` instead of namespaced `edit` | Fix the manifest — developers get a namespaced `RoleBinding` to `edit`, not a `ClusterRoleBinding` |

## D. Azure Policy for Kubernetes / Gatekeeper
| Symptom | Cause | Remediation |
|---|---|---|
| Compliance shows blank | Gatekeeper hasn't synced yet | Allow time (constraints sync on an interval); confirm `kubectl get pods -n gatekeeper-system` are running; re-check **Policy → Compliance** |
| A non-compliant pod deploys anyway | Assignment is still in **audit** | Expected in the audit stage — audit reports, it does not block. Move to `AKS Guardrails – NonProd – Deny` only after the gate |
| Deny blocks a legitimate workload | Guardrail too broad for one case | Create a scoped, justified, time-boxed **Exemption** for that resource — do not weaken the policy for everyone. If urgent, roll the effect back to **audit** |
| Gatekeeper pods not present | Azure Policy add-on not enabled | Confirm `azure_policy_enabled = true` in the IaC; `AKSSEC-Validate.ps1` reports the add-on state |

## E. Workload identity not working (pod can't reach Azure)
- Confirm the **federated credential** subject exactly matches `system:serviceaccount:app-baseline:wi-app-baseline` and the **issuer** is the cluster's OIDC issuer URL.
- Confirm the `ServiceAccount` annotation `azure.workload.identity/client-id` holds the **managed identity client id** (Terraform output `workload_identity_client_id`) and the pod carries the label `azure.workload.identity/use: "true"`.
- Confirm the managed identity has **least-privilege access** to the target resource (e.g. Key Vault Secrets User) — a token that can't read the resource looks like an auth failure.
- *Verify workload-identity GA status and the correct annotation keys for your cluster version.*

## F. Defender for Containers has no findings
- Confirm the **Containers** plan is enabled on the subscription (**Environment settings**) and the Defender agent/extension deployed to the cluster.
- Image-scan and node-hardening results appear on Defender's own cadence — allow time after enabling; re-run `AKSSEC-Report.ps1` to capture coverage and top findings.

## G. Diagnostics quick reference
```powershell
Get-AzContext | Select-Object Subscription, Tenant
Get-AzAksCluster -ResourceGroupName '<rg>' -Name '<cluster>' | Select-Object Name, `
    @{n='PrivateAPI';e={$_.ApiServerAccessProfile.EnablePrivateCluster}}, DisableLocalAccounts
az provider show -n Microsoft.PolicyInsights --query registrationState -o tsv
```
```bash
kubectl get pods -n gatekeeper-system
kubectl get clusterrolebinding,rolebinding -A | grep baseline
kubectl describe sa wi-app-baseline -n app-baseline
```

## H. When to escalate
If the cluster reports the baseline controls (private API, Azure RBAC, policy add-on, OIDC, workload identity) via `AKSSEC-Validate.ps1`, Gatekeeper pods are healthy, the federated credential matches, and either policy compliance or Defender findings still do not populate after the normal evaluation window, collect `AKSSEC-Report.ps1` output plus the cluster and assignment details and open a Microsoft support case.
