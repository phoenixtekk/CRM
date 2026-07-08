# 1. Solution Overview — AI Data-Exposure Assessment (Microsoft Purview)

## What this solution is
Before you turn on Microsoft 365 Copilot — or any enterprise AI that reads your tenant — you need one
answer: **what could it expose?** Copilot surfaces any content a user already has access to, so years of
over-shared, unlabeled files that "nobody ever found" become one prompt away. This solution is a
repeatable, self-guided **assessment** that answers the question with evidence: it **scopes what AI/Copilot
could access, measures the reachability, and quantifies the priority risks** into a ranked, defensible
**Exposure Risk Register** — using only the Microsoft Purview portal, Security & Compliance PowerShell
(`Connect-IPPSSession`), and Microsoft Graph, with no third-party tooling.

It is deliberately an **assessment**, not a remediation program. It produces the *measurement and the
evidence* — the exposure baseline, the ranked risks, and a validation that the recommended fix path works —
so an organization can make an informed, defensible decision about AI adoption. The one change it makes is
**piloted in simulation** (an auto-labeling policy that labels *nothing*, only reporting what it *would*
label) purely to prove the fix path; standing up an enforced reduction program is a separate follow-on.

## Why this matters
- **Exposure is invisible by default.** Sensitive data is scattered across SharePoint, OneDrive, Teams, and
  Exchange, much of it unlabeled and broadly shared. Nobody can say how much of it AI could reach — until
  it is measured.
- **Generative AI changes the blast radius.** A file "technically shared with everyone but never opened"
  is inert until Copilot can surface it to anyone with access. The assessment makes that reachability
  measurable *before* it becomes an incident.
- **A decision needs a baseline.** "Are we ready for Copilot?" is unanswerable without a quantified
  exposure picture. This solution delivers that baseline and a prioritized risk register you can defend.
- **The fix must be provable, not guessed.** Rather than assert "labeling will fix this," the assessment
  **validates the recommended remediation in simulation** — proving it would land on the right content
  without changing anything.

## What the assessment measures
- **AI access surface (Discovery)** — the sensitivity labels, label-publishing scope, DLP, and
  auto-labeling that *bound* what can be protected or kept out of AI. A thin taxonomy or narrow DLP scope
  is itself the first exposure finding.
- **Reachability (Assess)** — the two exposure signals: **oversharing** (SharePoint/OneDrive content shared
  organization-wide / with "everyone" / via anonymous links, which Copilot can surface to anyone with
  access) and **AI-interaction activity** from the unified audit log (what AI has actually touched, where
  Copilot is already in use).
- **Priority risk (Rank)** — a transparent, deterministic **exposure score** (reachability breadth × the
  sensitivity/lever signal) that sorts the broadly-shared, sensitive-data-likely, AI-reachable content to
  the top of the **Exposure Risk Register**.
- **Fix-path validation (Pilot in simulation)** — a single recommended remediation validated in
  **simulation mode** to confirm it would work, with no content changed and nothing enforced.

> **Feature availability & licensing — verify in your tenant.** DSPM for AI, auto-labeling, advanced DLP,
> and the site-access controls are **licensing-/plan-dependent** (commonly **Microsoft 365 E5** or the
> **E5 Compliance** add-on; some need **SharePoint Advanced Management** and/or a **Microsoft 365 Copilot**
> license) and the Purview portal is **actively evolving**. Treat the specific blades, cmdlets, and audit
> record types in this guide as a current-state map to **confirm against your own tenant**, never as
> guaranteed. This solution flags where to verify rather than asserting availability.

## The scope of "outcomes" (what this solution does and does not decide)
This solution delivers the **technical method and the evidence** — how to scope, measure, and rank AI data
exposure, and a validated fix path. It does **not** make **regulatory, records, or legal determinations**.
*Which* risks must be remediated, *what* AI-exposure level is acceptable, and any records/legal-hold
obligations are **deferred to your compliance, records, privacy, and legal functions**. You provide the
quantified exposure and the evidence; they own the determination.

## Naming convention (used in every doc and script)
Every artifact this solution creates or exports is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and portal so a reader can trace one artifact end to end.

| Artifact | Name |
|---|---|
| Scope/readiness export | `AIEXPOSE Scope Check – Estate – Assess` |
| AI access-surface inventory | `AI Access Scope – Estate – Discovery` |
| Sensitive-info-type scope export | `Sensitive Exposure – Estate – Assess` |
| AI/Copilot reachability report | `AI Reachability – Copilot – Assess` |
| Broad-access/oversharing export | `Oversharing Exposure – Sites – Assess` |
| Prioritized exposure risk register | `Exposure Risk Register – Estate – Rank` |
| Pilot fix-path validation (simulation) policy | `Exposure Remediation – Pilot – Simulation` |
| Recurring re-assessment cadence tag | `AI Exposure Re-Assessment – Estate – Recurring` |

## The standard deployment model
> Confirm scope → discover the AI access surface → measure reachability → rank the priority risks →
> validate the recommended fix in **simulation** → hand a defensible baseline + register to the governance
> functions → re-assess on a recurring cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
> Here "Expand (enforce)" is deliberately handed off — the assessment validates the fix path; enforcing it
> is a separate, change-controlled follow-on.
