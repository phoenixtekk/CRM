# Executive Summary — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

## The problem
Generative AI is already in the workday — Microsoft 365 Copilot, Copilot Studio agents, and consumer
tools like ChatGPT reached through the browser. Every interaction is a data flow: a prompt can carry
sensitive content, and a response can surface data a user shouldn't see or move it somewhere it shouldn't
go. Most organizations have **no visibility** into this and **no policy** over it. Left unaddressed,
ungoverned AI usage is a compliance gap and a data-risk exposure — sensitive data can leave through a
channel no existing control is watching.

## The solution
A complete, self-guided configuration of **AI governance from the DSPM-for-AI experience** in Microsoft
Purview. It turns on **visibility** into AI interactions, ensures Copilot **honors your sensitivity
labels** (so AI only answers over content a user is entitled to and labeled output stays labeled), applies
a **DLP policy — piloted in test/simulation** — that keeps the most sensitive labeled content out of AI
processing, and enables the recommended **insider-risk and communication-compliance** detections for risky
AI usage, configured **privacy-by-design**. Optional endpoint/browser signals surface sensitive data going
into consumer AI sites. Everything is piloted on a small ring, validated, then enforced, using the Purview
portal, Security & Compliance PowerShell, and Microsoft Graph — no third-party tooling.

## How it works
The engagement follows one disciplined model: **Assess → Design → Configure → Pilot (simulate) → Validate
→ Expand (enforce).** Assess audit, labels, licensing, and onboarding; design which content Copilot honors,
which content is withheld from AI, and which risky patterns are detected; configure visibility plus a
**test-mode DLP** scoped to a **pilot ring** and the portal one-click detections; validate that AI honors
labels, the DLP policy simulates matches without blocking, and interactions are visible; then enforce and
widen scope. Because DLP over AI is high-impact, **simulation is the safety gate** — every scriptable write
is previewed with `-WhatIf` first. Five tools — read-only or `-WhatIf` by default — automate discovery,
configuration (audit enablement + a test-mode DLP-for-AI policy + mode changes), validation, reporting, and
a readiness/health check; the portal-driven detections come with exact portal steps.

## What is delivered
- Six implementation documents (Overview, Requirements, Implementation, Testing, Best Practices, Troubleshooting) plus this summary.
- Five PowerShell tools: posture assessment, a configuration/remediation helper (audit + test-mode DLP-for-AI + mode changes), effective-settings validation, activity/evidence reporting, and a readiness/health helper.
- A named, gated, reversible rollout with explicit pass/fail criteria and privacy-by-design guidance at every step.

## Business outcome
AI usage that is **visible, labeled, and governed** — Copilot answers only over content users are entitled
to, the most sensitive content is kept out of AI, risky patterns are surfaced for review, and consumer-AI
egress can be seen. The governance is configured, piloted, validated, and defensible — at a fraction of the
cost of a bespoke consulting engagement.

## Important boundaries
What AI usage is *acceptable*, which content must be *withheld* from AI, and the adjudication of any
flagged interaction are **determinations owned by your governance, compliance, privacy, HR, and legal
functions** — this solution provides the technical configuration, detection method, and evidence, not the
determination; insider-risk and communication-compliance **outcomes are deferred to HR/legal**. DSPM for AI
is **new, partly in preview, and actively evolving** — capability availability, portal paths, policy names,
and audit record types are **licensing-/tenant-dependent** and are flagged "verify your licensing/tenant,"
never assumed or invented. Much of DSPM for AI is portal-driven; the scripts cover what is reliably
scriptable and point to the portal for the rest.
