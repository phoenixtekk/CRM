# 1. Solution Overview — Azure Kubernetes Service (AKS) Secure Baseline

## What the AKS secure baseline is
The AKS secure baseline is a **hardened, production-grade way to run Kubernetes on Azure**, expressed as infrastructure-as-code so it is repeatable and auditable rather than hand-clicked. It combines five capabilities into one cluster:

- **Private cluster networking** — the Kubernetes API server has a **private endpoint** (no public IP), the cluster uses **Azure CNI** networking inside your virtual network, and application traffic enters through an **internal ingress** rather than a public load balancer.
- **Entra ID + Kubernetes RBAC** — cluster sign-in uses **Microsoft Entra ID**, and access is authorized with **Azure RBAC for Kubernetes**, so an Entra group maps to a least-privilege Kubernetes role instead of everyone sharing the cluster-admin credential.
- **Azure Policy for Kubernetes (Gatekeeper)** — the Azure Policy add-on installs the **Gatekeeper** admission controller, which enforces guardrails at deploy time (no privileged pods, approved registries only, Pod Security baseline/restricted, resource limits required).
- **Workload identity (federated)** — pods authenticate to Azure services with a **federated Entra token** exchanged for a managed identity, so there are **no secrets or connection strings** stored in the pod.
- **Microsoft Defender for Containers** — continuous **image scanning**, runtime threat detection, and **node hardening** recommendations across the cluster.

## Why this matters
A cluster created with defaults is exposed on several fronts at once. The API server answers on a public IP, so it is discoverable and brute-forceable. Kubernetes RBAC is broad — a single kubeconfig with cluster-admin gets shared around. There is no admission policy, so anyone who can deploy can run a privileged container, pull an image from any registry, or mount the host filesystem. And applications hold Azure secrets in environment variables, which leak through logs, crash dumps, and `kubectl describe`. The secure baseline closes all of these by construction: the API is private, identity is Entra-backed and least-privilege, policy blocks the dangerous deployment at admission, and pods carry no secret to leak. Because the whole cluster is defined as code, you prove it once on a non-production cluster, then apply the same definition to production with a plan/what-if gate.

## How it works
1. An **Infrastructure-as-Code plan** (Terraform `plan` or Bicep `what-if`) describes the cluster and is reviewed **before** anything is created — no blind apply.
2. The IaC deploys a **private AKS cluster** into an existing virtual network subnet: private API endpoint, Azure CNI, a system node pool with host-based OS, Entra integration, Azure RBAC for Kubernetes, the Azure Policy add-on, OIDC issuer, and workload-identity enabled.
3. **Kubernetes RBAC** is applied from **YAML manifests** — namespaces, and `RoleBinding`/`ClusterRoleBinding` objects that map **Entra group object IDs** to least-privilege roles (namespace developer, cluster viewer) instead of cluster-admin.
4. **Azure Policy for Kubernetes** initiatives are assigned to the cluster in **audit** first (Gatekeeper reports violations without blocking), then moved to **deny** once the picture is clean.
5. **Workload identity** is wired: a **user-assigned managed identity** is created, a **federated credential** ties it to a Kubernetes **service account**, and pods that use that service account get an Azure token with **no stored secret**.
6. **Microsoft Defender for Containers** is enabled on the subscription so images are scanned and nodes are assessed for hardening, and findings feed the Defender for Cloud secure score.

## What you can control
- **Network exposure** — private vs public API, authorized IP ranges (if a public endpoint is unavoidable), Azure CNI address space, and internal vs public ingress.
- **Identity and access** — which Entra groups map to which Kubernetes roles, and whether local (cluster-admin) accounts are disabled.
- **Admission guardrails** — which Azure Policy for Kubernetes initiatives apply, and whether each is in **audit** or **deny**.
- **Workload identity** — which managed identity a service account federates to, and which Azure resources (Key Vault, Storage, SQL) that identity may reach.
- **Threat protection** — Defender for Containers coverage and which image-scan / node-hardening findings you remediate first.

## Limitations (be honest with buyers)
- A **private cluster** means the API server is only reachable from inside the virtual network (or a peered network / VPN / Bastion jumpbox). You must plan management connectivity — CI/CD runners and admin workstations need a network path to the private endpoint.
- **Azure Policy for Kubernetes** and **workload identity** availability, add-on versions, and some Pod Security features move between GA and preview — *verify current availability and API/add-on versions in your tenant and region before you rely on them.*
- **Microsoft Defender for Containers** is a **paid plan** billed per vCore/resource; the free posture view is limited. *Verify current pricing in your subscription.*
- A **deny** policy blocks *new* non-compliant workloads at admission; it does not reconfigure workloads already running — those are remediated separately.
- The baseline hardens the platform. It does not replace application security, image supply-chain controls upstream of the cluster, patching cadence, or backup of stateful workloads.

## Auth and connections used
- **Microsoft Entra ID** — cluster authentication (Entra-integrated AKS) and the identity behind Azure RBAC for Kubernetes and workload identity.
- **Azure Resource Manager** — the Terraform/Bicep provider and Az PowerShell operate against ARM with **Owner** or scoped **Contributor + RBAC Administrator** on the target resource group/subscription.
- **Kubernetes API (private endpoint)** — `kubectl` applies the RBAC and policy manifests over the private endpoint using an Entra token.
- **OIDC federation** — the cluster's OIDC issuer plus an Entra federated credential back workload identity token exchange.

## The standard deployment model
> **Assess prerequisites → plan the IaC (terraform plan / bicep what-if) → deploy the private cluster (non-prod) → apply Kubernetes RBAC + policy (audit) + workload identity → enable Defender for Containers → validate on the non-prod cluster → move policy to deny → expand to production.** repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with a **plan/what-if gate** before every apply and a documented rollback.
