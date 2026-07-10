# Executive Summary — Azure Kubernetes Service (AKS) Secure Baseline (Microsoft Azure)

**White-label · Azure Solutions**

A default AKS cluster is a soft target: a **public API server** reachable from the internet, **broad Kubernetes RBAC**, **no admission policy**, and application secrets sitting in environment variables. This solution replaces that default with an **AKS secure baseline** deployed **as code** — a private cluster, Entra ID identity mapped to least-privilege Kubernetes RBAC, Azure Policy for Kubernetes (Gatekeeper) guardrails, workload identity for secretless pod-to-Azure auth, and Microsoft Defender for Containers with image scanning and node hardening.

This is a complete, **deploy-it-today** package for standing up a production-grade AKS baseline, written for an administrator with no prior Terraform, Bicep, or Kubernetes-security experience. Every deploy is **plan / what-if first** and proven on a **non-production** cluster before it touches anything real.

## What you get
- A plain-language **Solution Overview** of private cluster networking, Entra ID + Kubernetes RBAC, Azure Policy (Gatekeeper), workload identity, and Defender for Containers.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, ordered steps — Terraform/Bicep plan → deploy the private cluster → apply Kubernetes RBAC and policy manifests → wire workload identity → enable Defender — non-prod first.
- Real **Infrastructure-as-Code**: a Terraform configuration for the cluster, kubectl **YAML** manifests for RBAC / policy / workload identity, and three **Az PowerShell** helpers for discovery, validation, and posture reporting.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
A **private AKS cluster** (private API server, Azure CNI, internal ingress) defined in code, **Entra ID authentication** with **Azure RBAC for Kubernetes** granting least-privilege access by group, **Azure Policy for Kubernetes** guardrails enforced through Gatekeeper (baseline/restricted Pod Security, no privileged containers, approved registries only), **workload identity** so pods authenticate to Azure with a federated token instead of a stored secret, and **Microsoft Defender for Containers** scanning images and hardening nodes — all validated on a non-production cluster first.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a **plan / what-if gate** before every apply and a documented rollback (`terraform destroy` of the non-prod stack / policy set to audit).

## Outcome
Kubernetes running securely on Azure — a private, policy-guardrailed cluster with least-privilege identity and secretless pod auth — instead of an internet-exposed default cluster, deployable by a single administrator and validated before you scale to production.
