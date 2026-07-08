# 1. Solution Overview — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

## What this solution is
Generative AI is now inside the workday — Microsoft 365 Copilot, Copilot Studio agents, and consumer
tools like ChatGPT reached through the browser. Each of those interactions is a **data-flow**: a prompt
can contain sensitive content, and a response can surface data a user shouldn't see or paste somewhere
it shouldn't go. Microsoft Purview's **AI Hub / Data Security Posture Management for AI (DSPM for AI)**
is the control point that gives you **visibility, policies, and controls** over those AI interactions.

This solution stands up **AI governance from the DSPM-for-AI experience** in the Microsoft Purview
portal: it turns on the **visibility** into AI interactions (via unified audit and the DSPM-for-AI
activity views), applies the recommended **protective policies** — sensitivity-label protection so
Copilot honors your labels, a **DLP policy (piloted in test/simulation)** that keeps the most sensitive
labeled content out of AI processing, and the recommended **insider-risk and communication-compliance**
detections for risky AI usage — and confirms the **endpoint/browser signals** that surface sensitive
data pasted into consumer AI sites. Everything is piloted on a small ring, validated, then expanded,
using the Purview portal, Security & Compliance PowerShell, and Microsoft Graph.

> **Preview / evolving.** DSPM for AI is a **new and actively evolving** area of Purview; some
> capabilities are **in preview** and portal paths, policy names, and audit record types change. Every
> capability here is **cited or flagged "verify your licensing/tenant"** — none is invented.

## Why this matters
- **You can't govern what you can't see.** DSPM for AI surfaces *which* AI apps are used, *how many*
  interactions occur, and *whether sensitive data* appears in prompts/responses — the baseline for any
  policy.
- **Labels should follow data into AI.** Copilot honors sensitivity labels and their encryption — so a
  user only gets AI answers over content they're already entitled to, and labeled output stays labeled.
- **The most sensitive content may not belong in AI at all.** A DLP policy can keep specific labeled
  content **out of AI processing** — configured in **test/simulation first**, because blocking AI over
  content is high-impact.
- **Risky AI usage is an insider-risk and compliance signal.** Recommended detections flag risky prompts/
  responses for review — with **privacy-by-design and role separation**, and outcomes deferred to HR/legal.
- **Consumer AI is the quiet leak.** Sensitive data pasted into ChatGPT/other sites via the browser is a
  common exfiltration path; endpoint/browser signals surface it.

## What DSPM-for-AI governance configures (the levers)
| Lever | What it does | Where it is set |
|---|---|---|
| **AI visibility / audit** | Capture AI interactions (Copilot and more) for reporting and eDiscovery | Unified **audit** + DSPM-for-AI activity/reports in the Purview portal |
| **Sensitivity-label protection for Copilot** | Copilot honors labels + encryption (answers only over entitled content; output inherits labels) | Sensitivity labels + label policies (Copilot honors them) |
| **DLP for AI (protect labeled content)** | Keep specific labeled content out of AI processing | A **DLP policy** with the AI/Copilot scope — **piloted in test** first |
| **Insider risk for risky AI usage** | Detect risky AI interactions for review (privacy-by-design) | Insider Risk Management policy (portal one-click recommendation) |
| **Communication compliance for AI** | Detect sensitive/risky prompts and responses | Communication Compliance policy (portal one-click recommendation) |
| **Endpoint / browser signals** | Surface sensitive data going into consumer AI sites | Endpoint DLP + the Purview browser extension / device onboarding |

## Naming convention (used in every doc and script)
| Artifact | Name |
|---|---|
| Pilot ring group | `grp-ai-pilot@contoso.com` |
| DLP policy — protect labeled content from AI (pilot, test mode) | `AI-DLP-ProtectLabeled-Sim` |
| DLP rule | `AI-DLP-Rule-HighlyConfidential` |
| Insider-risk policy (portal recommendation) | `AI-IRM-RiskyAIUsage` |
| Communication-compliance policy (portal recommendation) | `AI-CC-PromptResponse` |
| Sensitivity label Copilot must honor | `Highly Confidential` |

## What you can control
- **Whether AI interactions are captured** (audit) and visible in DSPM-for-AI reports.
- **Which labeled content Copilot honors**, and which labeled content is **kept out of AI** (DLP).
- **Which risky AI patterns are detected** for insider-risk / communication-compliance review.
- **Whether consumer-AI data egress is surfaced** via endpoint/browser signals.
- **Rollout order** — pilot ring → broad — and rollback (set DLP back to simulation / disable a policy).

## Limitations (be honest with buyers)
- **DSPM for AI is new, partly preview, and evolving.** Capability availability, portal paths, policy
  names, and audit record types change — this solution flags each; **verify your licensing/tenant**.
- **Much of DSPM for AI is portal-driven ("one-click" recommendations).** Insider-risk and communication-
  compliance AI policies are configured in the portal; PowerShell coverage is limited. This solution
  scripts what is reliably scriptable (audit enablement, a test-mode DLP policy, discovery/validation/
  reporting) and gives exact portal steps for the rest — it does not invent cmdlets.
- **DLP over AI is high-impact — pilot in test/simulation.** A DLP policy that keeps content out of AI
  changes what Copilot can answer over; always run it in **test/simulation** first (this solution enforces
  that), then enforce.
- **Insider risk & communication compliance are HR/privacy-sensitive.** Configure with **privacy-by-
  design**, pseudonymization where applicable, and strict **role separation**; **outcomes are deferred to
  HR/legal** — this solution provides the technical method, not the case decision.
- **Endpoint/browser signals require onboarding.** Surfacing consumer-AI egress needs onboarded devices
  and the Purview browser extension — **verify device onboarding and extension support in your tenant**.
- **Determinations are deferred.** What AI usage is *acceptable*, which content must be *withheld* from
  AI, and any regulatory applicability are **governance/compliance/legal determinations** — this solution
  provides the configuration method and evidence.

## The standard deployment model
> Assess AI-governance readiness (audit, labels, licensing, onboarding) → design which content Copilot
> honors, which is withheld from AI, and which risky patterns are detected → configure visibility + a
> **test-mode DLP** scoped to a **pilot ring** and the portal one-click detections → validate that AI
> honors labels, the DLP policy simulates matches without blocking, and interactions are visible →
> **expand** (enforce DLP, widen scope) → operate (reports, review, evidence).
> Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**
