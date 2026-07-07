# Solution Overview

## What this is

This solution designs and stands up the **enterprise network foundation** on Google Cloud Platform
for a large organization (80k–150k+ users) that is moving from Microsoft 365/Entra to Google
Workspace, adopting Google Cloud, and deploying Gemini Enterprise. It replaces the default, flat,
publicly reachable network posture with a **governed, private, perimeter-bounded** network:

- a **Shared VPC** topology (one host project owns the network; service projects attach to it),
- **private connectivity to Google APIs** — Private Google Access and Private Service Connect — so
  workloads never traverse the public internet to reach Cloud Storage, BigQuery, and other services,
- **hybrid connectivity patterns** (Cloud VPN / Cloud Interconnect / Network Connectivity Center)
  referenced at the design level for on-prem and multi-cloud reach,
- a **firewall and egress policy** built on hierarchical firewall policies, network firewall
  policies, and (where used) org-policy egress constraints, and
- **VPC Service Controls (VPC-SC) perimeters** that draw a logical boundary around Google-managed
  services so that **data cannot be copied out** of the trusted boundary — introduced **in dry-run
  (audit) mode first**, validated against real traffic, then **enforced**.

The result is a network where workloads connect to Google services **privately**, egress is
**explicitly controlled**, and API-level data exfiltration paths are **closed** — safe by design and
governed by policy rather than by ad-hoc firewall rules.

## How it works

The design layers four controls, each independently valuable and each verified before the next:

1. **Shared VPC topology.** A dedicated **host project** (`Net-Host – Prod – Shared-VPC`) owns the
   VPC network, subnets, routes, and firewall policies. Workload **service projects** are attached
   and consume shared subnets. This centralizes network administration with the network team while
   letting application teams deploy into their own projects — separation of duties without separate
   networks. Subnets are regional, sized with room to grow, and carry secondary ranges for GKE
   Pods/Services where container platforms are in scope.

2. **Private access to Google APIs.** **Private Google Access** is enabled per-subnet so VMs with
   only internal IPs reach Google APIs via `private.googleapis.com` / `restricted.googleapis.com`
   virtual IP ranges (the **restricted** VIP is the one that keeps traffic inside a VPC-SC
   perimeter). **Private Service Connect (PSC)** endpoints provide a private, org-owned IP for the
   Google APIs bundle, giving DNS you control and a clean path that composes with VPC-SC. Public
   egress to Google APIs is removed as a dependency.

3. **Firewall & egress policy.** A **hierarchical firewall policy** at the organization/folder level
   sets non-negotiable guardrails (deny-by-default egress, allow the Google API VIP ranges, deny
   known-bad ranges), and **network firewall policies** at the VPC level implement workload-specific
   allows. The default posture is **deny egress**; each allow is named and justified. This is the
   network-layer complement to the API-layer control below.

4. **VPC Service Controls perimeters.** A **service perimeter** (`Perimeter – Prod – v1`) enumerates
   the projects inside the boundary and the Google services it protects (for example Cloud Storage,
   BigQuery, and — verify current coverage for your services — the Vertex AI / Gemini APIs). Requests
   that would move protected data **across** the boundary (e.g. copying a bucket to a project outside
   the perimeter, or reading BigQuery from an unmanaged network) are denied. **Access levels**
   (Access Context Manager) describe the trusted conditions (corp IP ranges, managed device posture)
   under which ingress/egress is allowed. The perimeter is created in **dry-run mode** so it *logs*
   what it *would* block without denying anything, the logs are reviewed to find legitimate flows
   that need ingress/egress rules, and only then is it **enforced**.

## Reference design

```
Organization
 └── Folder: Network
      ├── Host project:  Net-Host – Prod – Shared-VPC   (owns VPC, subnets, firewall policy)
      │     └── VPC: vpc-prod-shared
      │           ├── subnet: sn-prod-use4   (Private Google Access ON; restricted VIP route)
      │           ├── subnet: sn-prod-euw1   (secondary ranges for GKE where in scope)
      │           └── PSC endpoint: psc-googleapis  → all-apis / vpc-sc bundle
      └── Service projects (attached):  App-A – Prod ,  Data-A – Prod  …

Access Context Manager
 └── Access Level: Access Level – Corp-Managed – v1   (corp IP ranges + device posture)

VPC Service Controls
 └── Service Perimeter: Perimeter – Prod – v1  (DRY-RUN → ENFORCED)
       restricted services:  storage, bigquery, aiplatform, … (verify coverage in your org)
       ingress/egress rules referencing Access Level – Corp-Managed – v1
```

Hybrid reach (Cloud VPN, Dedicated/Partner Interconnect, or Network Connectivity Center hubs) is
attached to the host VPC and is designed so on-prem sources that must reach protected services do so
**through** an ingress rule tied to the access level — never around the perimeter.

## Benefits

- **Exfiltration paths closed at the API layer.** VPC-SC denies data movement across the boundary
  even when a caller has valid IAM permissions — mitigating stolen-credential and misconfiguration
  data-loss scenarios that IAM alone cannot.
- **Private by default.** Workloads reach Google services over Google's backbone via the restricted
  VIP / PSC, not the public internet — smaller attack surface and cleaner compliance story.
- **Separation of duties.** Network is owned centrally (host project); apps deploy independently
  (service projects) without each team running its own network.
- **Change-safe.** Every perimeter and policy change lands in **dry-run/audit first**, with logs
  proving what it would block, so enforcement never silently breaks production.
- **Automatable and auditable.** The included Python tools assess exposure, provision the topology in
  dry-run, build perimeters in dry-run, and produce a validation report — read-only or dry-run by
  default, no secrets in code.

## Limitations & boundaries

- **VPC-SC protects Google-managed services, not your own VMs' data plane.** It governs access to the
  service APIs in its coverage list; it is not a host firewall or a DLP content scanner. Pair it with
  firewall policy, IAM least-privilege, and (separately) DLP.
- **Service coverage is version-dependent.** Which Google services VPC-SC supports, and whether a
  service is "supported/preview/unsupported," changes over time. This solution names representative
  services; **verify current VPC-SC coverage for your exact services in your organization** before
  relying on the perimeter for them (Gemini Enterprise / Vertex AI coverage in particular is
  evolving — confirm in-tenant).
- **IaC is at the pattern level.** Terraform / Cloud Foundation Toolkit blueprints are shown as
  representative patterns; provider/module internals are deferred to the tool's own documentation.
- **Regulatory determinations are deferred.** Data-residency, retention, and compliance *decisions*
  belong to the organization's security, legal, and compliance functions; this solution provides the
  technical method and the evidence.

## Deployment model

This solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
pilot-first, with explicit pass/fail gates and a documented rollback for every org-wide or
production-affecting change (the perimeter enforcement step above all). Nothing is enforced
org-wide until it has passed its gate in a named pilot scope and its dry-run logs have been reviewed.
