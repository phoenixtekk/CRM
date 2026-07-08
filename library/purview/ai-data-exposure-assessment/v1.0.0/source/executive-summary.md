# Executive Summary — AI Data-Exposure Assessment (Microsoft Purview)

Before you turn on Microsoft 365 Copilot — or any enterprise AI that reads your tenant — one question
decides whether you are ready: **what could it expose?** Copilot surfaces any content a user already has
access to, so years of over-shared, unlabeled files that "nobody ever found" become one prompt away. This
solution is a repeatable, self-guided **assessment** that answers the question with evidence: it scopes
what AI/Copilot could access, measures the reachability, and quantifies the priority risks into a ranked,
defensible **Exposure Risk Register** — using only the Microsoft Purview portal, Security & Compliance
PowerShell, and Microsoft Graph, no third-party tooling.

It is deliberately an assessment, not a remediation program. It delivers the *measurement and the
evidence* so an organization can make an informed, defensible decision about AI adoption. The single change
it makes is **piloted in simulation** — an auto-labeling policy that labels *nothing*, only proving the
recommended fix would land on the right content. Standing up an enforced reduction program is a separate,
change-controlled follow-on.

## What you get
- A plain-language Solution Overview of what the assessment measures — the AI access surface, reachability,
  priority risk, and fix-path validation — the availability/licensing caveat for these evolving features,
  and the boundaries between assessment and remediation, and between technical method and legal/records
  determination.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — licensing,
  least-privilege roles, auditing, the labels + DLP baseline, Copilot/AI in scope, the sharing signal, and
  simulation discipline.
- An Implementation Guide of precise, ordered portal and PowerShell steps: confirm scope, discover the
  access surface, measure reachability, rank the priority risks, validate the fix in simulation, validate
  the evidence, hand off the baseline, and set a re-assessment cadence.
- Five PowerShell scripts for scope/health checking, access-surface discovery, reachability reporting,
  risk-register ranking, and safe fix-path validation (read-only or `-WhatIf`/simulation by default —
  never enforcing).
- Testing and Troubleshooting guides, with an explicit simulation validation gate, for a confident, safe
  assessment.

## What this delivers
A measured AI-access-surface inventory, a reachability report of what Copilot/AI could reach and — where
AI is in use — what it has touched, a scored and ranked **Exposure Risk Register** of the priority risks,
and a **simulation-validated** recommended fix path — every step read-only or simulation, changing no
content — so the exposure picture is defensible and the fix decision is de-risked.

## The deployment model
Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce, handed off as a follow-on).

## Outcome
AI data exposure made visible, quantified, and defensible — the access surface inventoried, reachability
measured, priority risks ranked, and the recommended fix validated in simulation — so an organization can
decide on AI adoption with evidence rather than hope. Feature availability is flagged to verify in your
tenant; regulatory, records, and legal determinations remain with your governance functions.
