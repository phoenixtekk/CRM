# 7. Best Practices — Azure Kubernetes Service (AKS) Secure Baseline

- **Plan before every apply.** Run `terraform plan` (or `az deployment group what-if`) and read the resource list before you apply — on the non-prod cluster first, then production. A blind apply is how a networking change quietly takes the cluster offline.
- **Keep the API private.** Prefer a fully private cluster; if a public endpoint is genuinely unavoidable, lock it to **authorized IP ranges**. Plan the management path (peering / VPN / Bastion jumpbox) *before* you deploy, not after `kubectl` times out.
- **Bind groups, never people, and never cluster-admin by default.** Map **Entra security groups** to least-privilege Kubernetes roles; give developers **namespaced edit**, not cluster-admin. Disable local accounts so there is no shared `cluster-admin` kubeconfig to leak.
- **Audit before you deny, always.** Assign every Azure Policy for Kubernetes guardrail in **audit** first, understand the violations, exempt the legitimate exceptions, then flip the **same** assignment to **deny** on an approved gate. This prevents blocking a deployment real workloads depend on.
- **Name everything and reuse the name.** Use `<Purpose> – <Scope> – <Stage>` for the cluster, resource group, groups, identity, service account, and policy assignments, and reuse it verbatim across IaC, manifests, scripts, and rollback so the estate stays auditable.
- **Go secretless with workload identity.** Federate a **user-assigned managed identity** to a Kubernetes service account and grant it the **narrowest** Azure access it needs (e.g. one Key Vault, secrets-user only). No connection strings, no stored keys, nothing to leak through logs.
- **Turn on Defender for Containers and work the findings.** Enable the plan, act on **image-scan** and **node-hardening** recommendations, and track the secure score each cycle — a rising score is the evidence the baseline is holding.
- **Deny stops new, not running.** A deny policy blocks non-compliant workloads at admission; it does not fix what is already running. Remediate existing workloads separately.
- **Keep a rollback for every change.** `terraform destroy` of the non-prod stack, or setting a policy assignment back to **audit**, is the safety net — write it down before you make the change.
- **Non-prod, then production.** Prove the whole baseline on `AKS Cluster – Baseline – NonProd` before creating `AKS Cluster – Baseline – Prod` from the same code — the same deploy-once, repeat pattern that makes this repeatable.

## Where to go next
- **Azure Security Baseline & Governance** — put management-group-level Azure Policy guardrails and RBAC least-privilege around the whole subscription the cluster lives in.
- **Power Platform Secrets in Azure Key Vault** — the secretless pattern extended to the Key Vault the workload identity reads from.
- **Azure Virtual Desktop / Windows 365** — a governed, network-isolated management jumpbox for reaching the private API endpoint.
- Adjacent Azure Solutions in the catalog cover monitoring, cost governance, and network hardening that complement this baseline.
