# 1. Solution Overview — AI Prompt/Response Governance & Usage Monitoring (Microsoft Purview)

## What this solution is
People now paste and receive sensitive data through AI — Microsoft 365 Copilot and other AI apps — and
most organizations have **no visibility into what is in those prompts and responses** and **no policy
governing them**. This solution closes that gap inside Microsoft Purview. It stands up **usage monitoring
of AI prompts and responses** (what AI was used, by whom, and which interactions touched sensitive data)
and the **policy that governs that content** — **Communication Compliance** scoped to AI/Copilot
interactions and **Data Loss Prevention (DLP) for Copilot/AI** — so sensitive data flowing into and out
of AI is *seen*, *evidenced*, and *governed*, not left blind.

This is a repeatable, self-guided way to **monitor AI prompt/response usage and wire the governing
policy** using only the **Microsoft Purview portal** (`https://purview.microsoft.com`), **Security &
Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling. Because
Communication Compliance and DLP changes are high-impact (and Communication Compliance is HR- and
privacy-sensitive), **every policy is piloted in a limited/test/simulation scope first**, validated, and
only then expanded.

## What this monitors and governs (the two questions)
- **Usage monitoring — *what has AI touched?*** The prompt/response activity of Microsoft 365 Copilot and
  other AI apps, sourced from **Purview auditing** (`CopilotInteraction` records) and the **DSPM for AI**
  interaction reports: who used AI, which app, and which prompts/responses referenced **sensitive data**
  (sensitivity-labeled or sensitive-information-type content). This is the evidence baseline.
- **Governing policy — *what happens when a prompt/response contains sensitive data?*** Two Purview levers:
  - **Communication Compliance** — a policy that **detects sensitive or risky content in AI/Copilot
    prompts and responses** for review (data-leak / offensive-language / sensitive-info classifiers),
    routed to trained reviewers under strict role separation and privacy-by-design.
  - **DLP for Microsoft 365 Copilot / AI** — a DLP policy whose **Copilot/AI location** keeps
    sensitivity-labeled content out of AI processing (or restricts it), so the most sensitive material is
    governed at the point AI would consume it.
  - *(Optional, verify availability)* **Insider Risk Management** has a **risky-AI-usage** indicator/
    template to surface anomalous AI use — referenced where licensed and in preview in your tenant.

> **Feature availability & licensing — verify in your tenant.** AI-governance capabilities in Purview are
> **new and actively evolving**. Whether **Communication Compliance can monitor Copilot/AI interactions**,
> whether **DLP exposes a Microsoft 365 Copilot location**, whether **DSPM for AI** and the
> **`CopilotInteraction`** audit record are present, and whether each is included or needs **Microsoft
> 365 E5 / the E5 Compliance add-on** (and a **Microsoft 365 Copilot** license for AI activity to exist)
> **depend on your licensing and tenant**. Treat every blade, policy location, and record type named here
> as a current-state map to **confirm in your own portal**, never as guaranteed. This solution flags where
> to verify rather than asserting availability.

## Privacy-by-design and role separation (Communication Compliance is HR/privacy-sensitive)
Monitoring people's AI prompts and responses is **HR- and privacy-sensitive**. This solution builds the
capability with:
- **Privacy-by-design / pseudonymization** — enable Communication Compliance **anonymization** so
  usernames are shown as system-generated aliases during review; only de-anonymize under a defined,
  approved process.
- **Strict role separation** — separate **Communication Compliance Administrators** (configure policy),
  **Analysts** (triage, pseudonymized), and **Investigators** (full detail, gated). No single person both
  configures and investigates.
- **Least data, defined retention** — scope policies to the in-scope population and purpose; do not
  over-collect.

## The scope of "outcomes" (what this solution does and does not decide)
This solution delivers the **technical method and the evidence** — how to monitor AI prompt/response usage
and configure the governing Communication-Compliance and DLP policy. It does **not** make **HR, regulatory,
records, or legal determinations**: which AI usage is *acceptable*, what a policy match *means* for an
individual, disciplinary or records/legal-hold actions on a Communication-Compliance case, and regulatory
applicability are **deferred to your HR, compliance, privacy, and legal functions**. You provide the
configuration and the evidence; they own the determination.

## Naming convention (used in every doc and script)
Every artifact this solution creates or exports is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and portal so a reader can trace one artifact end to end.

| Artifact | Name |
|---|---|
| AI usage / prompt-response monitoring export | `AI Usage – Copilot – Monitor` |
| Governance-config inventory export | `AI Governance Config – Estate – Discovery` |
| Sensitive AI-interaction report | `Sensitive AI Interactions – Estate – Assess` |
| Communication-compliance AI policy | `AI Interactions – Copilot – CommCompliance` |
| Pilot DLP-for-AI (Copilot) policy | `AI Prompt DLP – Copilot – Test` |
| Broad DLP-for-AI (Copilot) policy scope | `AI Prompt DLP – Copilot – Enforce` |
| Optional insider-risk AI-usage policy (preview) | `Risky AI Usage – Pilot – Monitor` |
| Pilot scope (ring of users) | `AI Governance – Pilot – Ring1` |
| Broad scope | `AI Governance – Broad – Stage2` |
| Validation evidence export | `AI Governance Validation – Estate – Evidence` |
| Recurring usage-review cadence tag | `AI Usage Review – Estate – Recurring` |

## The standard deployment model
> Baseline AI usage and existing governance config → assess which prompts/responses touch sensitive data
> → design the Communication-Compliance + DLP-for-AI policy with privacy-by-design → pilot each policy in a
> **limited/test/simulation** scope → validate the matches and the evidence → **expand to enforce/broaden**
> → review AI usage on a recurring cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
