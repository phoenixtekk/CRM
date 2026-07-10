# 1. Solution Overview — Microsoft Defender for Cloud: CSPM & Secure Score Remediation

> **Government (GCC High) edition.** This is the US Government national-cloud edition for public-sector and defense-industrial-base (DIB) tenants running in **Microsoft Azure Government / GCC High**. It mirrors the commercial method exactly, adapted for the sovereign cloud: the Azure Government portal (`portal.azure.us`), the GCC High Defender/unified-security portal (`security.microsoft.us`), Azure Government sign-in (`login.microsoftonline.us`), and PowerShell targeting the US Gov cloud (`Connect-AzAccount -Environment AzureUSGovernment`). Feature and plan parity in GCC High/DoD can **lag commercial** — every availability/pricing/preview claim must be **verified against current Microsoft Government documentation** (see `gcc-high-parity-notes.md`).

## What Microsoft Defender for Cloud (CSPM) is
Microsoft Defender for Cloud is Azure's **cloud security posture management (CSPM)** and workload-protection service. Its posture-management side continuously assesses your cloud resources against a security baseline and expresses the result as a single **Secure Score**, a set of prioritized **recommendations**, a **regulatory-compliance** view, and — with the paid **Defender CSPM** plan — **agentless scanning**, **attack-path analysis**, and **cloud security graph** risk hunting. It has two posture tiers:

- **Foundational CSPM** — free, on by default for Azure subscriptions. Provides Secure Score, security recommendations, and asset inventory.
- **Defender CSPM** — a paid plan that adds agentless machine/vulnerability scanning, **attack-path analysis**, the cloud security graph (risk hunting), governance rules at scale, and data-aware posture.

Defender for Cloud also connects to **AWS and GCP** via connectors, so one posture view and one prioritized recommendation list can span a multicloud estate.

## Why this matters
Most cloud breaches trace back to a **misconfiguration** — public storage, an over-permissive network rule, an unencrypted disk, a missing MFA requirement — not a zero-day. The problem is that teams have no *continuous* view of those misconfigurations; they surface at audit time or after an incident. Defender for Cloud turns that into a live, scored, prioritized picture: it tells you exactly what is wrong, ranks it by real risk (an **attack path** that chains an internet-exposed VM to a privileged identity to sensitive data is worse than an isolated low-severity finding), and lets you track a **Secure Score** that trends upward as you remediate. The goal is a managed posture with a **remediation cadence** that measurably raises the score — not a static, once-a-year audit — proven on a pilot subscription before it is applied everywhere.

## How it works
1. **Foundational CSPM** is confirmed on the pilot subscription and the starting **Secure Score** is recorded.
2. **Defender CSPM** (paid) is enabled on the pilot subscription to unlock **agentless scanning**, **attack-path analysis**, and risk hunting. *Plan availability and pricing — verify current in your tenant.*
3. **Agentless machine scanning** turns on so VMs and disks are assessed for vulnerabilities and misconfigurations without installing an agent.
4. The **regulatory-compliance dashboard** is enabled and mapped to the standard(s) the organization must meet (the *choice* of standard is the compliance team's).
5. **Recommendations are worked in priority order** — highest-impact and attack-path-linked items first, using the built-in **Fix** action where offered — and the Secure Score is tracked each cycle.
6. **Governance rules** assign owners and due dates to recommendations, and **exemptions** record justified, time-bound exceptions (never silent suppression).
7. **Continuous export** streams recommendations and Secure Score to a **Log Analytics workspace** and a **workbook** for long-term trending and reporting.
8. **AWS/GCP connectors** extend the same posture model to multicloud, at a high level.

## What you can control
- **Posture tier** — foundational CSPM (free) vs Defender CSPM (paid) per subscription/connector.
- **Agentless scanning** — on/off and scope for VM/disk vulnerability and misconfiguration assessment.
- **Remediation priority** — which recommendations and attack paths to fix first, and the cadence.
- **Governance** — owners, due dates, and grace periods via governance rules; justified exemptions with expiry.
- **Reporting** — continuous export destinations (Log Analytics/workbook) and the compliance standards displayed.
- **Scope** — which subscriptions and which clouds (Azure/AWS/GCP) are covered.

## Limitations (be honest with buyers)
- **Defender CSPM, agentless scanning, and several plans are paid** per resource/subscription; foundational CSPM (free) gives Secure Score and recommendations only. *Verify current plan pricing and availability in your tenant.*
- Secure Score and recommendations are **not instantaneous** — assessments take time to populate after enabling; allow a warm-up window.
- A recommendation being "Fixed" reflects the current assessment; posture **drifts** as new resources are created — this is why the cadence and continuous export matter.
- Multicloud (AWS/GCP) coverage here is **high-level posture**; deep per-cloud workload protection is a larger, separate effort. **In GCC High/DoD, multicloud connectors, agentless scanning, data-aware posture, and specific Defender plans may be delayed or unavailable — verify against current Microsoft Government documentation before assuming a feature is present.**
- CSPM reduces misconfiguration risk; it does not replace patching, backup, identity hardening, or the security team's risk decisions.

## Connections and authentication used (GCC High / Azure Government)
- The **Azure Government portal** (`https://portal.azure.us`) → **Microsoft Defender for Cloud** for plans, Secure Score, recommendations, attack paths, compliance, governance, and export. The unified-security/Defender portal in GCC High is **`https://security.microsoft.us`**.
- Sign-in / token host: **`login.microsoftonline.us`** (Azure Government).
- **Az PowerShell** (`Az.Accounts`, `Az.Security`, `Az.ResourceGraph`, `Az.Resources`) for read-only discovery, validation, reporting, and Resource Graph (KQL) hunting — connect with **`Connect-AzAccount -Environment AzureUSGovernment`** so every call targets the US Gov cloud.
- A **Log Analytics workspace** as the continuous-export destination (per `global-requirements-defender.md` G7).
- **AWS/GCP connectors** for multicloud posture.
- Least-privilege roles: **Security Reader** for read-only work, **Security Admin** (or Owner/Contributor at scope) for enabling plans and governance.

## The standard deployment model
> **Assess current posture (plans, Secure Score, recommendations) → configure (enable Defender CSPM, agentless scanning, compliance dashboard) → pilot on one subscription → validate remediation raises Secure Score → expand across subscriptions and to AWS/GCP.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, every change preview/`-WhatIf` first.
