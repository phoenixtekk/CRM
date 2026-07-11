# Executive Summary — Architecture Service: Microsoft Defender for Cloud

**White-label · Defender**

Rolling **Microsoft Defender for Cloud** across many subscriptions and clouds **without a design** produces exactly the problems it is meant to prevent: **inconsistent coverage** (some subscriptions protected, others not), **RBAC sprawl** (nobody sure who can change what), **no multicloud plan** (AWS/GCP posture as an afterthought), and **cost surprises** (paid plans switched on ad-hoc). This solution is an **architecture / design service**, not a single-subscription deployment: it delivers a **reference design** for Defender for Cloud at scale — a **management-group/subscription onboarding model**, a **plan-enablement strategy**, **multicloud (AWS/GCP) connectors**, an **RBAC and governance model**, **continuous-export/SIEM integration**, and a **cost model** — plus a **reference Bicep skeleton** you deploy **what-if first**.

This is a complete, **design-it-right-the-first-time** package. It gives an administrator or architect the blueprint and the infrastructure-as-code skeleton to enable Defender for Cloud **consistently** through the management-group hierarchy so new subscriptions inherit protection automatically — every deployment **plan/what-if first** and approval-gated.

## What you get
- A plain-language **Solution Overview** of Defender for Cloud at scale — the MG/subscription model, CSPM vs workload plans, multicloud connectors, RBAC, continuous export, and the cost drivers.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite (a management-group hierarchy, deployment identity, cost inputs).
- A **Design & Implementation Guide** that produces the reference architecture and rolls it out in waves — enable plans at management-group scope, wire RBAC and governance, connect AWS/GCP, and stand up continuous export/SIEM — deployed with the included Bicep, **what-if first**.
- A **reference Bicep skeleton** (`main.bicep`) that enables Defender plans at scale, plus PowerShell for read-only discovery, validation, and a **coverage + cost** report — the IaC artifacts, not just prose.
- A **decision/design record** so the architecture and its tradeoffs are documented.
- **Testing** and **Troubleshooting** guides for a confident, staged rollout.

## What this delivers
A **scalable, documented Defender for Cloud architecture**: plans enabled **consistently** at management-group scope so coverage is uniform and new subscriptions inherit it; a **clean RBAC model** (who reads posture, who enables plans, who governs exemptions); **AWS/GCP connectors** for multicloud coverage; **continuous export** to a Log Analytics workspace and the SIEM; and a **cost model** that makes the paid-plan spend predictable **before** you roll out — all captured as a design record and a Bicep skeleton.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — design the reference, validate it on a pilot management group / subscription with `what-if`, then expand in waves across the hierarchy and to AWS/GCP.

## Boundary
This solution delivers the **reference architecture, the IaC skeleton, and the cost model** — the *design*. Which regulatory standards apply, what the organization's risk appetite and exemption policy are, and whether a given cost is acceptable are the **customer's compliance, security, and finance functions'** determinations. Automated response and any production apply stay **what-if/approval-gated**. Plan pricing, plan availability, and multicloud connector requirements are **version-dependent** and flagged **verify current availability in your tenant**.

## Effort
An architect or administrator can produce the reference design and validate it on a pilot management group in a focused engagement, then expand wave by wave. The Bicep skeleton makes each subsequent wave a reviewed, what-if-first deployment rather than portal clicking. Multicloud connectors and workload plans scale the effort with estate size.
