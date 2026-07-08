# 1. Solution Overview — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

## What this solution is
You cannot reduce data-security risk you cannot see. **Data Security Posture Management (DSPM)** in
Microsoft Purview is the place that *makes the risk visible* — it aggregates signals from your
sensitivity labels, Data Loss Prevention (DLP), auto-labeling, and Insider Risk configuration into a
single posture view, surfaces where **sensitive data** is exposed across the estate, and hands you
**recommendations** to close the gaps. **DSPM for AI** extends the same idea to generative AI: it shows
what Microsoft 365 Copilot and other AI apps can *access*, which **prompts and responses touch
sensitive data**, and gives you the **oversharing-reduction controls** (sensitivity labels, DLP, and
SharePoint access) to shrink that exposure before and during AI adoption.

This solution is a repeatable, self-guided way to **enable DSPM and DSPM for AI, read the posture, act
on the recommendations, and reduce Copilot/AI oversharing** — using only the Microsoft Purview portal,
Security & Compliance PowerShell (`Connect-IPPSSession`), and Microsoft Graph, with no third-party
tooling. Every high-impact change is **piloted in simulation/test first**.

## Why this matters
- **Risk is invisible by default.** Sensitive data is scattered across SharePoint, OneDrive, Teams, and
  Exchange, much of it unlabeled and over-shared. DSPM is the first view that quantifies it.
- **Generative AI changes the blast radius.** Copilot can surface any content a user already has access
  to. A file that was "technically shared with everyone but nobody ever found it" becomes one prompt
  away. DSPM for AI makes that exposure measurable *before* it becomes an incident.
- **Recommendations are only value once actioned.** DSPM proposes concrete fixes (turn on a label,
  extend DLP, restrict sharing). The worth is in working the recommendation queue, not admiring it.
- **Oversharing reduction is high-impact.** Broad-scope sharing changes, new DLP, and auto-labeling can
  disrupt real work if enforced blindly — so this solution pilots every reduction in
  simulation/test/disabled mode and validates before enforcing.

## What DSPM and DSPM for AI actually show
- **DSPM (posture & recommendations)** — an at-a-glance posture across data-security controls, trends of
  sensitive-data activity, and a prioritized **recommendations** list (e.g. label coverage gaps, DLP
  scope gaps, risky activity) with a status you work to completion.
- **Sensitive-data risk** — where labeled/unlabeled sensitive information lives and moves, so you can
  target labeling and DLP at the real exposure rather than guessing.
- **DSPM for AI — data access** — visibility into what Microsoft 365 Copilot and other AI apps can
  reach, including where broad/organization-wide access ("oversharing") makes sensitive content
  reachable by AI.
- **DSPM for AI — sensitive interactions** — reports of **prompts and responses** that reference
  sensitive data (sourced from Purview auditing), so you can see AI's actual contact with sensitive
  content, not just its theoretical reach.
- **DSPM for AI — oversharing controls** — the one-click/recommended policies to reduce exposure:
  sensitivity-label coverage, DLP for AI (keeping labeled content out of AI processing), and SharePoint
  site-access/sharing restrictions.

> **Feature availability & licensing — verify in your tenant.** DSPM and DSPM for AI are newer and
> **actively evolving** capabilities. Which reports, recommendations, and one-click policies appear —
> and whether a capability is included or needs **Microsoft 365 E5 / the E5 Compliance add-on** (and in
> some cases **SharePoint Advanced Management** for site-access controls, or an AI/Copilot license) —
> **depends on your licensing and tenant**. Treat the specific blades and policy names in this guide as
> a current-state map to confirm against your own portal, never as guaranteed. This solution flags
> where to verify rather than asserting availability.

## The scope of "outcomes" (what this solution does and does not decide)
This solution delivers the **technical method and the evidence** — how to enable DSPM/DSPM for AI, read
the posture, and configure the reduction controls. It does **not** make **regulatory, records, or legal
determinations**. Which data must be retained or restricted, what an acceptable AI-exposure level is,
and any records/legal-hold obligations are **deferred to your compliance, records, privacy, and legal
functions**. You provide the configuration and the evidence; they own the determination.

## Naming convention (used in every doc and script)
Every artifact this solution creates or exports is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and portal so a reader can trace one artifact end to end.

| Artifact | Name |
|---|---|
| Posture & controls inventory export | `DSPM Posture – Estate – Discovery` |
| Sensitive-data risk assessment export | `Sensitive-Data Risk – Estate – Assess` |
| AI/Copilot data-access + prompts report | `AI Exposure – Copilot – Assess` |
| SharePoint/OneDrive oversharing export | `Oversharing Report – Sites – Assess` |
| Recommendation/action tracker export | `DSPM Recommendations – Estate – Tracker` |
| Pilot auto-labeling (simulation) policy | `Auto-Label Sensitive – Pilot – Simulation` |
| Pilot DLP-for-AI (test) policy | `DLP for AI – Pilot – Test` |
| Pilot oversharing-reduction scope | `Oversharing Reduction – Pilot – Stage1` |
| Broad oversharing-reduction scope | `Oversharing Reduction – Broad – Stage2` |
| Recurring posture-review cadence tag | `DSPM Posture Review – Estate – Recurring` |

## The standard deployment model
> Enable and read the posture → assess sensitive-data and AI/Copilot exposure → act on recommendations
> → pilot every reduction in **simulation/test**, validate, then **expand to enforce** → review on a
> recurring cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
