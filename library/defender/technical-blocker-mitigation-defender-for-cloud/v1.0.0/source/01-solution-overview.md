# 1. Solution Overview — Technical Blocker Mitigation: Defender for Cloud

## What this solution is
This is a **diagnostic and troubleshooting playbook** for a **stalled Microsoft Defender for Cloud rollout**. It assumes you have started enabling plans, provisioning agents, or onboarding AWS/GCP, and hit a wall — a plan that will not stay on, machines with no data, a multicloud connector that never syncs, or an empty Secure Score. Its job is to answer three questions quickly and in order:

1. **Which blocker do I actually have?** (read-only discovery of plan, coverage, connector, and assessment state — not guesswork)
2. **What is the exact, documented fix?** (a targeted manual step, applied deliberately)
3. **Is the plan / coverage / connector / recommendations now working?** (verification before you resume)

It targets the four blocker classes that stall almost every Defender for Cloud deployment:

- **Plan not enabling** — a Defender plan (Servers, Storage, Containers, Defender CSPM, etc.) will not turn on for a subscription, or silently reverts to **Free**, so paid protections never apply.
- **Agent / agentless coverage gaps** — machines the plan covers report **no data** because the agent (Azure Monitor Agent / the Defender extension) is not provisioned, or **agentless scanning** is not enabled, leaving blind spots.
- **AWS / GCP connector failures** — a **multicloud connector** never finishes onboarding (the CloudFormation / Terraform role or permissions are wrong) or stops syncing, so AWS/GCP resources are unassessed.
- **Recommendations not populating** — **Secure Score** and assessments stay empty because the **Microsoft cloud security benchmark** policy assignment is missing/failing or assessment data is not flowing.

## How Defender for Cloud signal actually works (so you can find the break)
Defender for Cloud has a signal chain, and a blocker is always a break in one specific link:

1. **Plan enablement** — the required **Defender plans** are set to **On** (Standard) at the subscription (or connector) scope. *Verify current plan names/pricing in your tenant.*
2. **Coverage** — covered resources are instrumented: **agents** (auto-provisioning of the Azure Monitor Agent / Defender extension) and/or **agentless scanning** are enabled so machines and services actually report.
3. **Multicloud connectors** — **AWS/GCP connectors** are onboarded with the correct roles/permissions and are **syncing**, so non-Azure resources are in scope.
4. **Policy / assessment layer** — the **Microsoft cloud security benchmark** (Azure Policy) is assigned and evaluating, feeding **assessments** and **Secure Score**.
5. **Verification** — plans show **On**, coverage shows machines reporting, connectors show **connected**, and assessments/recommendations populate with a Secure Score you can trend.

Find the earliest broken link and you have found the blocker. Discovery reports the state of each link so you are not guessing.

## The standard deployment model (applied to a blocker)
> **Assess → Configure → Pilot → Validate → Expand.**
> **Assess** — run read-only discovery and coverage analysis to pinpoint the earliest broken link. **Configure** — apply the single documented fix for that blocker (a manual portal/CLI step, change-approved, not a script action). **Pilot** — re-test on the **affected subscription / connector** only. **Validate** — confirm the plan / coverage / connector / recommendations work. **Expand** — resume the stalled rollout across the remaining subscriptions and connectors.

## Scope
- Diagnosing and clearing the four blocker classes above for a stalled Defender for Cloud rollout.
- Read-only discovery, agent/agentless coverage analysis, validation, status reporting, and a support-ready bundle.
- Documented manual fixes for each blocker, applied affected-scope-first and change-approved.
- Clear escalation criteria and the exact data to collect when the root cause is a Microsoft service issue.

## Out of scope
- **A full CSPM / Secure Score remediation engagement** — that is the adjacent *Defender for Cloud — CSPM & Secure Score* solution; this one unblocks a rollout already in progress.
- **Remediating individual recommendations** — clearing findings and hardening resources is the customer's change-approved work; here recommendations are diagnosed only for whether they *populate*.
- **Cost / plan-selection decisions** — enabling paid plans has cost impact; that decision is the customer's finance/ops function.
- **Licensing determinations** — the guide tells you *which* plan a capability needs and how to verify it; enabling it is the customer's decision.

## Connections and authentication used
- **Microsoft Defender for Cloud** in the Azure portal (`portal.azure.com` → Defender for Cloud) — plans, coverage, connectors, recommendations, Secure Score.
- **Az PowerShell** (`Az.Accounts`, `Az.Security`, `Az.Resources`, `Az.PolicyInsights`) for read-only discovery, coverage, validation, and reporting; ARM REST reads for multicloud connectors.
- **AWS / GCP** onboarding artifacts (CloudFormation / Terraform roles) as the connector trust — read-only status checks here.
- Least-privilege roles: **Security Reader** / **Reader** on the subscriptions for all read-only diagnostics; **Security Admin** / **Owner-delegated** roles only to apply a fix (enable a plan, provisioning, or a connector).
