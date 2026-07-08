# Executive Summary — AI Prompt/Response Governance & Usage Monitoring (Microsoft Purview)

Sensitive data now flows into and out of AI. Employees paste confidential material into Microsoft 365
Copilot and other AI apps, and receive responses that surface sensitive content — and most organizations
have **no visibility into what is in those prompts and responses, and no policy governing them**. That is
both a compliance gap and a data-risk exposure. This solution closes it inside Microsoft Purview: it stands
up **usage monitoring of AI prompts and responses** (what AI was used, by whom, and which interactions
touched sensitive data) and the **policy that governs that content** — **Communication Compliance** scoped
to AI/Copilot interactions and **DLP for Copilot/AI** — so sensitive data in AI is seen, evidenced, and
governed.

This is a complete, deploy-it-today package written for a competent Purview / compliance administrator,
using only the Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph — no
third-party tooling. Because monitoring people's prompts is HR- and privacy-sensitive and policy changes are
high-impact, every policy is built with **privacy-by-design (anonymization), strict role separation**, and
is **piloted in a limited/test scope** before it is enforced or expanded.

## What you get
- A plain-language Solution Overview of what this monitors and governs, the availability/licensing caveat for
  these evolving AI-governance features, the privacy-by-design and role-separation posture, and the boundary
  between technical method and HR/legal determination.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — licensing, least-privilege
  roles with separation of duties, auditing, Communication Compliance readiness, the DLP Copilot location,
  DSPM for AI, in-scope AI apps/population, and pilot discipline.
- An Implementation Guide of precise, ordered portal and PowerShell steps: baseline AI usage, design the
  policy set with stakeholders, create the Communication-Compliance AI policy (pilot-scoped, anonymized),
  create DLP for AI in test mode, optionally stage risky-AI-usage monitoring, validate, expand to enforce,
  and review on a recurring cadence.
- Five PowerShell scripts for scope/health checking, governance-config discovery, AI usage monitoring, safe
  governance configuration (read-only or `-WhatIf` / test mode by default), and validation/evidence.
- Testing and Troubleshooting guides, with an explicit privacy gate and enforcement gate, for a confident,
  safe rollout.

## What this delivers
A monitored baseline of AI prompt/response usage, an evidence record of which interactions touch sensitive
data, a Communication-Compliance policy detecting sensitive/risky AI content under anonymization, a
DLP-for-AI policy keeping labeled content out of AI processing, and a validated rollout — piloted in a
limited/test scope and expanded only after the gate passes — that governs AI content rather than merely
observing it.

## The deployment model
Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).

## Outcome
AI prompt/response risk made visible and governed — usage monitored, sensitive interactions evidenced, and
Communication-Compliance + DLP-for-AI policy piloted and enforced under privacy-by-design — so data in AI is
defensible. Feature availability is flagged to verify in your tenant; HR, regulatory, records, and legal
determinations remain with your governance functions.
