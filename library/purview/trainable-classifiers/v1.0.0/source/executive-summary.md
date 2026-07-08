# Executive Summary — Trainable Classifiers in Microsoft Purview

## The problem

Some of an organization's most sensitive content can't be found by keywords or patterns. A
**contract**, a **résumé**, a **source-code** file, a **statement of work** — these are recognized by
their *shape and meaning*, not a fixed string, so pattern-based sensitive information types miss them
entirely. That leaves a whole class of important documents unlabeled, un-governed, and unprotected —
both a **compliance gap** and a **data-risk exposure**.

## The solution

This solution delivers **Microsoft Purview trainable classifiers** end to end — machine-learning
classifiers that recognize content **by example** rather than by pattern — and wires them into the
controls that act on classification:

- **Built-in classifiers** (e.g. Resumes, Source Code) work immediately, with no training.
- **Custom classifiers** are **seeded** with example documents, **trained**, **tested for accuracy**
  against a separate known set, and **published** only when accuracy is acceptable.
- The published classifier is **wired into an auto-labeling policy** (and can feed DLP and retention)
  so matching content is automatically labeled and protected — **deployed in simulation first**,
  validated, then enforced.

The critical discipline: a classifier is **tested for accuracy before it is published**, and the
control it feeds is **piloted in simulation** — it records what it *would* label without changing
anything — before any enforcement.

## How it works — the model

The delivery follows a disciplined, repeatable model with an explicit pass/fail gate at each step:

**Assess → Design → Configure (seed/train/test/publish + wire) → Pilot (simulation) → Validate →
Expand (enforce).**

Because auto-labeling can apply **encrypting** labels and DLP can block, nothing is enforced until the
classifier has passed an **accuracy gate** — on both a curated test set and a real-world simulation —
and the data owner has signed off.

## What you get

- A complete document set: Overview, Requirements, an ordered Implementation guide, Testing (accuracy
  + wiring pass/fail gates), Troubleshooting, Best Practices, and this summary.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph) — discovery,
  configuration of the **wiring** (simulation, `-WhatIf` first), validation, reporting, and
  scope/health — all **read-only or preview by default, with no credentials in code.** (Classifier
  creation itself is a portal action; the tools automate the wiring and reporting around it.)
- A **defensibility evidence pack**: measured accuracy, proof the classifier was published only after
  passing its threshold, that the wiring was validated in simulation, and that the label/action
  applies only to the right content.

## Scope and boundaries

- Trainable classifiers and the controls they feed (auto-labeling, advanced DLP, retention) are
  **licensing-dependent** (typically Microsoft 365 E5 / E5 Compliance / E5 Information Protection &
  Governance) and the Purview portal and built-in catalog **evolve** — capability availability, seed
  minimums, and exact paths are **verified against your licensing/tenant**, never assumed.
- **Regulatory, records, and legal determinations** — which label a category deserves, what accuracy
  is acceptable, and whether content is in scope — remain with your **compliance, records, privacy,
  and data-owner** functions. This solution provides the **technical method, the accuracy evidence,
  and the wiring**, not the determination.

## The bottom line

Content that keyword and pattern rules can't find becomes **classified by meaning** and automatically
labeled/protected in Microsoft Purview — **seeded, trained, tested, wired, piloted in simulation,
validated, and defensible.**
