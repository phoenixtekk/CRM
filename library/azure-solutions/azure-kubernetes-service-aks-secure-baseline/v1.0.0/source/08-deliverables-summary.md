# 8. Deliverables Summary — Azure Kubernetes Service (AKS) Secure Baseline

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the AKS secure baseline is — private networking, Entra + Kubernetes RBAC, Azure Policy (Gatekeeper), workload identity, Defender for Containers; benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — plan the IaC, deploy the private cluster, apply RBAC + policy (audit→deny), wire workload identity, enable Defender |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## Infrastructure-as-Code & scripts
| File | What it does |
|---|---|
| `AKSSEC-Discovery.ps1` | Read-only Az PowerShell discovery — subscription, VNet/subnet capacity, existing clusters, and Defender for Containers plan; a readiness picture before you deploy |
| `AKSSEC-main.tf` | Terraform for the private AKS cluster — private API endpoint, Azure CNI, Entra + Azure RBAC for Kubernetes, Azure Policy add-on, OIDC issuer + workload identity, and the user-assigned managed identity + federated credential. **Deploy plan-first** (`terraform plan` before `apply`) |
| `AKSSEC-baseline.yaml` | kubectl manifests — the `app-baseline` namespace, least-privilege RBAC bindings mapping Entra groups to roles, and the workload-identity service account for secretless pod-to-Azure auth |
| `AKSSEC-Validate.ps1` | Confirms private API, Azure RBAC, the policy add-on/Gatekeeper, OIDC issuer, and workload identity are all in place |
| `AKSSEC-Report.ps1` | Baseline posture report — private-API state, RBAC, policy assignments and compliance, workload-identity/OIDC, and Defender coverage with top findings |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- The **Terraform** configuration, **YAML** manifests, and three **Az PowerShell** scripts in a single ZIP — delivered as a **Complete Solution Package (PDF + Word + scripts)**.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand** — with a plan/what-if gate before every apply and a documented rollback.

## Outcome
Kubernetes running securely on Azure — a private, policy-guardrailed cluster with Entra least-privilege identity, secretless workload identity, and Defender for Containers — proven on a non-production cluster before it carries production workloads.
