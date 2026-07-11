# Executive Summary — Workshop: Microsoft Defender for Cloud Apps

**White-label · Defender · Enablement / Training deliverable**

A licensed tool only pays off when the team can drive it. Many organizations turn on **Microsoft Defender for Cloud Apps (MDA)** — the cloud access security broker (CASB) in Microsoft Defender — then leave most of it unused because no one is confident with Cloud Discovery, app governance, or the policy engine. This is a **structured enablement workshop** that takes your admins and SOC analysts from "we have it" to "we operate it" — through concepts, **guided hands-on labs**, a **take-home runbook**, and a **knowledge-check**.

This is a training deliverable, not a deployment project. It assumes MDA is licensed and reachable — the *how-to-connect-every-app* work lives in the catalog's Cloud App DLP / onboarding solutions — and focuses on the **operating skills**: running **Cloud Discovery** to expose shadow IT, using **app governance** to watch OAuth apps and their API usage, assessing **OAuth app risk** and consent, building **session and access policies** (Conditional Access App Control), and reading **anomaly-detection** alerts. Every lab is **read-only or preview-first / report-only**, so a team can learn safely without disrupting users.

## What you get
- A plain-language **Solution Overview** of Defender for Cloud Apps — what a CASB does, how Cloud Discovery, app connectors, app governance, and the policy engine work, and the console/workflows an operator uses daily.
- A **Requirements Guide** covering the workshop-specific prerequisites (MDA licensing, a discovery data source, at least one connected app, app-governance enablement) with verify / implement-if-missing for each.
- An **Implementation Guide** that is the **facilitator + student runbook** — five guided labs, each with named objects, exact portal navigation, and explicit pass/fail checks.
- Five **lab-helper assets**: read-only PowerShell discovery/validation/report scripts (Microsoft Graph) plus a **KQL query pack** for advanced hunting over the `CloudAppEvents` table.
- A **Testing / knowledge-check** guide and a **Troubleshooting** guide.
- A **Best-Practices + where-to-go-next** guide that points to the adjacent catalog areas (Cloud App DLP, Conditional Access, threat hunting).

## What this delivers
A team that can **confidently operate Microsoft Defender for Cloud Apps**: they can run and read a Cloud Discovery report and rank shadow-IT apps, use app governance to spot a risky OAuth app, assess and (with approval) act on OAuth consent risk, author a **report-only** session/access policy before enforcing it, and triage an anomaly-detection alert — with a **runbook they keep** and reuse.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — delivered against a **pilot** scope, each skill validated with a pass/fail gate, then the team expands the practices to the full environment.

## Boundary
This workshop delivers the **technical enablement and the operating runbook**. Acceptable-use, data-classification, records, and app-sanctioning decisions belong to the customer's security, compliance, and business functions — the workshop teaches the controls, not the decision. Policies are taught **report-only / monitor-first**; blocking and session controls are **approval-gated**. Some MDA capabilities are **license-** or **preview-gated**; those facts are flagged **verify current availability in your tenant**.

## Effort
A competent facilitator can run the full workshop in a focused one- to two-day engagement against a pilot; the labs and runbook are then reusable to onboard new analysts. No enforcing policy is required to complete the workshop — the labs are report-only / preview-first.
