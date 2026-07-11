# Executive Summary — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

**White-label · Defender**

Cloud security posture management (CSPM) tells you what is **misconfigured**; it does not catch what is **actively attacking** a running workload. That is the job of Microsoft Defender for Cloud's **workload protection plans** — the cloud workload protection platform (**CWPP**) layer. Many tenants have turned on the free CSPM/Secure Score capabilities but left the workload plans **off**, so a brute-forced SQL server, a crypto-miner in an AKS pod, a malware upload to a storage account, or an anomalous Key Vault access goes undetected. This solution enables and tunes Defender for Cloud's **workload plans** — **Servers** (P1/P2, with Defender for Endpoint integration), **Containers** (AKS + registry scanning + runtime), **Databases** (Azure SQL, open-source, Cosmos DB), **Storage**, **Key Vault**, **App Service**, and **Resource Manager** — with **alert tuning**, suppression rules, and a **workload response workflow** — enabled first on a pilot subscription, validated, then expanded.

This is a complete, **deploy-it-today** package written for an administrator with no prior Defender for Cloud CWPP experience. It enables plans on a **pilot subscription first**, keeps any automated response **approval-gated**, and treats **cost** as a first-class consideration (workload plans are billed per protected resource).

## What you get
- A plain-language **Solution Overview** of the CSPM-vs-CWPP distinction and each workload plan.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite.
- An **Implementation Guide** of exact, ordered steps — enable plans on the pilot subscription, wire MDE integration and export, tune alerts, add a response workflow — pilot-first.
- Five **PowerShell scripts** (Az / Microsoft.Graph Security) plus **KQL** for readiness discovery, plan/coverage validation, alert & cost reporting, a `-WhatIf`-gated plan-enablement helper, and a workload-alert hunt.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
Active workload threat protection across **servers, containers, databases, storage, Key Vault, and App Service** — the CWPP layer on top of your CSPM posture — with alerts tuned to signal, a response workflow ready, and cost understood, enabled on a pilot subscription and expanded with confidence.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — enable plans on a pilot subscription, wire integration and export, tune alerts, validate a benign alert fires, then expand across subscriptions.

## Boundary
This solution is the **CWPP / workload-protection** layer of Defender for Cloud. It **complements**, and cross-references rather than duplicates, the catalog's **Defender for Cloud — CSPM & Secure Score** solution (posture management). Regulatory/records/legal determinations, production change approval, and incident-response decisions remain the customer's compliance, operations, and security functions; this guide provides the technical configuration.

## Effort
A competent administrator can enable and validate the pilot-subscription plans in a focused engagement, then expand across subscriptions on a controlled cadence. Rollout — and cost — scale with the number of protected resources (servers, databases, storage accounts, clusters).
