# Executive Summary — Enterprise DLP Assessment & Strategy (Microsoft Purview)

## The problem
Data Loss Prevention projects fail in a predictable way: the team writes DLP policies before it knows what
sensitive data the organization holds, where it lives, or how it moves — then switches those policies to
enforce and floods the business with false positives until DLP is switched off. **DLP without a data map
produces noise, not protection.** Left unaddressed, the result is both a compliance gap (no defensible view
of sensitive-data exposure) and a data-risk exposure (leaks that no one can see).

## The solution
Do the assessment **before** the enforcement. This solution delivers, in **Microsoft Purview**, a **DLP
posture assessment**, a **sensitive-data discovery** exercise, and a **prioritized DLP rollout strategy** —
using only the Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph. It baselines
what DLP exists today, uses **Content Explorer** to map where sensitive data **rests** across Exchange,
SharePoint, OneDrive, and Teams, stands up **one monitor-only DLP policy in SIMULATION mode** (Microsoft's
built-in test mode — zero user impact) to measure how sensitive data **moves**, then ranks data categories
by real **exposure** and produces a **simulation-first, ringed rollout roadmap**. Crucially, it **enforces
nothing**: the only Purview object created is a simulation policy that can be deleted in one step.

## What it delivers
- A **DLP posture baseline** — every existing policy, its mode, and the sensitive-information-type and label
  coverage in the tenant.
- A **sensitive-data map** — where each candidate data category rests (Content Explorer) and how much of it
  moves and is shared externally (simulation baseline + Activity Explorer), reconciled.
- A **ranked exposure view** — data categories prioritized by prevalence, external-sharing exposure, and
  movement volume, with the weighting recorded.
- A **prioritized DLP rollout roadmap** — for each category: the detector, the location, the action
  progression (audit → tip → justify → block), the pilot ring, and the order — every step simulation-first,
  gated, and reversible, with detector gaps captured as a build backlog.
- **Five PowerShell tools** (posture baseline, Content Explorer data scan, readiness/non-enforcement
  validation, simulation-baseline helper, exposure/movement report) — read-only or `-WhatIf` by default, no
  credentials in code.

## Business outcomes
- **Know what to protect before writing a policy** — priorities set by measured exposure, not guesswork, so
  the eventual enforcement project targets the real risk first.
- **Zero business disruption during the assessment** — the only policy created is in simulation; no user is
  ever blocked or tipped, and it is instantly removable.
- **A defensible compliance position** — a documented posture, a sensitive-data map, and a ratified roadmap,
  instead of an empty DLP blade.
- **A de-risked enforcement project** — the data map, movement report, ranked exposure, detector backlog,
  and simulation-first roadmap are the complete input to a DLP enforcement engagement.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
Discovery depth is **licensing-/plan-dependent** — Content Explorer, Activity Explorer, on-demand
classification, trainable classifiers, and DSPM require **E5 / E5 Compliance** and some are in **preview**
(verify your tenant). This solution provides the **assessment, the discovery evidence, and the recommended
roadmap**; *which* data categories are ultimately in scope, *which* classifiers legally apply, and the
**enforced action per category** are **compliance, privacy, and legal determinations**, ratified alongside
the delivered evidence. The assessment feeds an enforcement project — it is not itself an enforced control.
