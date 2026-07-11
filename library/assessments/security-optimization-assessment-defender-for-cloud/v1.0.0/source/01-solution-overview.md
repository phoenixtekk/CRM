# 1. Solution Overview — Security Optimization Assessment: Defender for Cloud

## What Defender for Cloud is
Microsoft Defender for Cloud is Azure's **cloud security posture management (CSPM)** and **cloud workload protection (CWPP)** service. For this assessment the relevant capabilities are:

- **Secure Score & recommendations** — a single score summarizing how your resources measure against a security baseline, driven by a prioritized list of **recommendations**.
- **Plan coverage** — Defender for Cloud has a free **foundational CSPM** tier plus paid plans: **Defender CSPM**, and workload plans for **Servers, Storage, SQL/Databases, Containers, App Service, Key Vault, Resource Manager, DNS, APIs**, etc. Each plan unlocks specific protections and assessable posture.
- **Regulatory-compliance dashboard** — maps your posture to standards (Microsoft cloud security benchmark and others you add), showing pass/fail per control.
- **Agent / agentless coverage** — machines are assessed via **agentless machine scanning** (Defender CSPM) and/or agents (Defender for Servers, the Azure Monitor Agent, and integration with Defender for Endpoint). Coverage gaps mean machines are unassessed.

Defender for Cloud also connects to **AWS and GCP** via connectors, extending the same posture model to a multicloud estate.

## Why this assessment matters
Most environments have Defender for Cloud **on but not optimized**: Secure Score has plateaued because nobody works the recommendations; paid plans are off on the subscriptions that host sensitive workloads; the compliance dashboard shows a standard nobody chose; and agentless scanning is enabled on one subscription but not the others, so machines silently go unassessed. None of this is obvious from the portal landing page — you have to **enumerate plans, score, recommendations, compliance mappings, and coverage, compare to the recommended baseline, and score it**.

That is what this assessment does. It is **read-only** — it changes nothing — and produces a **prioritized, risk-ranked findings report** across the four domains so remediation goes to the highest-risk gaps first.

## The four assessment domains and how they are scored
1. **Secure Score & recommendations** — What is the current score per subscription? Are high-impact and unhealthy recommendations being worked, or is there a large stale backlog?
2. **Plan coverage** — Which paid plans are enabled where? Are the plans that protect the actual workloads (Servers, Storage, SQL, Containers, etc.) on for the subscriptions that host them? *Plan availability/pricing — verify current.*
3. **Regulatory compliance posture** — Is the compliance dashboard enabled and mapped to the standard(s) the organization must meet? What is the pass rate? (Which standard applies is the compliance team's decision.)
4. **Agent / agentless coverage** — Are machines covered by agentless scanning and/or the required agents? Where are the coverage blind spots (unscanned VMs, subscriptions without agentless enabled)?

Each domain is scored against the **best-practice reference baseline** named in the Global Requirements (Microsoft cloud security benchmark / Secure Score guidance — *baselines evolve; verify against current Microsoft guidance*). Domain scores roll up into an overall posture score, and every gap becomes a finding with a **risk rank** (severity × exposure).

## What is in scope
- **Reading** Defender for Cloud configuration: plan tiers per subscription, Secure Score and recommendations, compliance assessments, and agent/agentless coverage — via Az and Azure Resource Graph.
- **Scoring** that configuration against the recommended baseline across the four domains.
- **Producing** a prioritized, risk-ranked findings report with a saved baseline for trending.

## What is out of scope (and where it lives)
- **Making changes / closing the gaps** — the **Remediation Playbook for Defender Security Optimization Assessments** (pilot-first, `-WhatIf`-gated).
- **First-time enablement and the remediation cadence** — the **Microsoft Defender for Cloud: CSPM & Secure Score Remediation** solution.
- **Cross-pillar (endpoint/identity/email/cloud-apps) suite posture** — the **Security Optimization Assessment — Microsoft Defender (Suite / XDR)** solution.
- **Regulatory, records, incident-response, and risk-acceptance decisions** — the customer's compliance/legal/SOC functions.

## Connections and authentication used
- The **Azure portal** → **Microsoft Defender for Cloud** for plans, Secure Score, recommendations, compliance, and coverage (for manual confirmation).
- **Az PowerShell** (`Az.Accounts`, `Az.Security`, `Az.ResourceGraph`, `Az.Resources`) for read-only discovery, validation, scoring, coverage analysis, and reporting; **Azure Resource Graph (KQL)** against `securityresources` for recommendations/coverage.
- Least-privilege roles: **Security Reader** (and **Reader** at the Azure scope) are sufficient for this read-only assessment (per Global Requirements G2).

## The standard deployment model
> **Assess** the current Defender for Cloud configuration (plans, Secure Score, recommendations, compliance, coverage) → **Configure** the assessment scope and baseline reference → **Pilot** the run on one subscription and review the findings → **Validate** the score and findings with the security owner → **Expand** across subscriptions and to AWS/GCP, re-running to trend. Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, entirely **read-only**.
