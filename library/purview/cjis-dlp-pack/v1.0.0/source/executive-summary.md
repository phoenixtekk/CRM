# Executive Summary — CJIS DLP Pack (Microsoft Purview)

Criminal Justice Information — criminal history record information, identity-history and biometric
references, NCIC/III query returns, and the case data derived from them — must be protected to the FBI
**CJIS Security Policy**. In a Microsoft 365 tenant, the control that stops CJI from leaking out through
email, SharePoint/OneDrive sharing, Teams, and endpoints (USB, print, cloud upload) is **Data Loss
Prevention**. Most organizations either have no CJI DLP at all, or a generic policy that over-matches and
gets ignored — and, either way, no **evidence** to show a CJIS assessor. This solution delivers CJI DLP in
**Microsoft Purview** the right way: detection tuned to CJI, a policy piloted in **simulation/test** before
it ever blocks, validated against pass/fail gates, and backed by continuous evidence.

It gives you a repeatable way to define a **CJI detection** set (a custom sensitive information type /
keyword dictionary, supporting identity SITs, and — where licensed — Exact Data Match), author a **DLP
policy** across the in-scope M365 workloads, **pilot it in simulation** so you can tune it without
disrupting case work, **validate** it, then **enforce** it — using only the Microsoft Purview portal,
Security & Compliance PowerShell, and Microsoft Graph.

This is a complete, deploy-it-today package for the CJI DLP control, written for a competent
M365/compliance administrator working under a CJIS program.

## What you get
- A plain-language Solution Overview of CJI DLP in Purview, the detection approach, coverage, and the
  phased simulate-first model.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, including which DLP
  surfaces your licensing actually unlocks.
- An Implementation Guide of precise, ordered portal + PowerShell + Graph steps, with the policy piloted
  in simulation first and every policy, rule, and classification named.
- Five PowerShell scripts: a read-only assessment/baseline, a simulation-first policy tool (`-WhatIf` by
  default, `-Commit` to write, `-PromoteToEnforce` to enforce, `-Disable` to roll back), a validation
  gate-check, a Graph-based evidence report, and a scope/health helper.
- Testing and Troubleshooting guides for a confident, safe rollout.

## What this delivers
CJI detection tuned to catch real criminal-justice information without flagging routine work; a DLP policy
protecting CJI across Exchange, SharePoint, OneDrive, and Teams (and endpoints where licensed); a clean
simulation pilot before any enforcement; validated pass/fail gates; and a continuously refreshed evidence
artifact — policy in force, what it detects, matches and admin actions — that stands up in a CJIS audit.

## The deployment model
Assess → Design → Configure (**simulate**) → Pilot & tune → Validate → Expand (**enforce**).

## Scope boundary
This solution delivers and evidences the **DLP control** — one control within the broader CJIS Security
Policy. Whether a given data element *is* CJI, the CJI retention schedule, the CJIS audit conclusions,
personnel screening / access authorization, and the FIPS-validated encryption and physical-media controls
required elsewhere are **deferred to your CJIS Systems Officer / Terminal Agency Coordinator, compliance,
records, and legal** functions. This pack provides the technical method and evidence, not the CJIS
determination.

## Outcome
CJI Data Loss Prevention stood up the right way in Microsoft Purview — detection tuned, policy piloted in
simulation and validated, enforcement reversible and recorded, and the evidence to prove the control is
live and defensible.
