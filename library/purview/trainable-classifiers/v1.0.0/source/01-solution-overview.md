# Solution Overview — Trainable Classifiers in Microsoft Purview

## What this solution delivers

Some content can't be found by keywords or patterns. A **contract** doesn't announce itself with a
regular expression; a **résumé**, a **source-code** file, or a **statement of work** is recognized by
its *shape and meaning*, not a fixed string. Pattern-based sensitive information types (SITs) miss
this whole class of data — and that leaves it unlabeled, un-governed, and unprotected. Left
unaddressed, that is both a **compliance gap** and a **data-risk exposure**.

This solution delivers **Microsoft Purview trainable classifiers** end to end — machine-learning
classifiers that recognize content **by example** rather than by pattern — and, crucially, **wires
them into the controls that act on classification**:

1. **Built-in (pre-trained) classifiers.** Microsoft ships ready-to-use classifiers (e.g. **Resumes**,
   **Source Code**, and others — **verify the current catalog for your tenant**) that work
   immediately with no training.
2. **Custom trainable classifiers.** For content specific to your organization, you **seed** the
   classifier with example documents, let it **train**, **test** it against a separate known set to
   measure accuracy, and **publish** it.
3. **Wiring to labels, DLP, and retention.** A classifier is only useful once something *acts* on it.
   This solution wires the published classifier into an **auto-labeling** policy (and shows how it is
   referenced by **DLP** and **retention**) so matching content is automatically labeled/protected/
   retained — deployed in **simulation** first, validated, then enforced.

The result is *classify content by meaning, not keywords* — seeded, trained, tested, wired, **piloted
in simulation**, validated, and defensible.

## The classifier lifecycle (how it actually works)

A custom trainable classifier follows a defined lifecycle in the Purview portal
(**Data classification → Classifiers → Trainable classifiers** — *verify path for your tenant*):

| Stage | What you do | Outcome |
|---|---|---|
| **Seed** | Point the classifier at a **SharePoint site of positive example documents** (Microsoft recommends a meaningful minimum number of samples — **verify the current minimum/recommended counts**). | The classifier learns what "positive" looks like. |
| **Train** | The service processes the seed content. | A candidate model. |
| **Test** | Provide a **separate test set** of items you have **pre-labeled** as match / non-match; review the classifier's predictions and its accuracy. | A measured model you can trust (or retrain). |
| **Publish** | Publish the classifier once accuracy is acceptable. | The classifier becomes **available as a condition** in auto-labeling, DLP, and retention. |
| **Wire & use** | Reference the classifier in an **auto-labeling / DLP / retention** policy — **in simulation first.** | Content is automatically labeled / protected / retained by *meaning*. |

> **The classifier is only half the job.** Publishing a classifier changes nothing on its own — it
> must be **wired into a control** (auto-labeling, DLP, or retention) to have an effect. This solution
> treats the wiring as a first-class deliverable, not an afterthought.

## What trainable classifiers are (and are not)

- **They are** ML classifiers that recognize content **by example/category** — good for the
  "recognizable by shape, not by string" content (contracts, resumes, source code, SOWs, financial
  statements) that SITs and keyword lists cannot reliably catch.
- **They are not** a replacement for **sensitive information types** or **exact data match**. Use SITs
  for well-structured identifiers (card numbers, national IDs) and classifiers for *categories of
  document*. They complement each other.
- **They are licensing-dependent.** Trainable classifiers and the controls they feed (auto-labeling,
  advanced DLP, retention) are premium capabilities (typically **Microsoft 365 E5** / **E5
  Compliance** / **E5 Information Protection & Governance**) — **verify capability availability and
  the built-in classifier catalog against your licensing/tenant**, and note the portal evolves (some
  classifiers/settings are newer or in preview). See `global-requirements-purview.md` §1.

## Simulate first — auto-labeling and DLP are high-impact

Auto-applying a **sensitivity label** (which may carry **encryption**) or a **DLP block** to content a
classifier matches is high-impact — an over-eager classifier could label or restrict the wrong
documents. Therefore:

- The classifier is **tested for accuracy before publishing**, and the control it feeds (auto-labeling
  / DLP) is deployed in **simulation/test mode first** — it **records what it *would* label/act on
  without changing anything** — validated on a pilot scope, and only then enforced.

> **Determinations are not yours to make.** *Which* label a category should receive, *whether* the
> classifier's accuracy is acceptable for a given use, and *whether* content is in scope are
> **compliance / records / data-owner** determinations — this solution delivers the technical method,
> the accuracy evidence, and the wiring, not the determination (see `global-requirements-purview.md`
> §5).

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure (seed/train/test/publish + wire) → Pilot (simulation) → Validate →
Expand (enforce).**

- **Assess** — confirm licensing, least-privilege roles, the seed/test content, the target label/DLP/
  retention control, the pilot scope, and stakeholder sign-off.
- **Design** — decide which built-in classifiers to use, which custom categories to build, the target
  label/action for each, and name every object.
- **Configure** — seed → train → **test (measure accuracy)** → publish the classifier(s), then **wire**
  into an auto-labeling (and/or DLP/retention) policy **in simulation**.
- **Pilot** — run the wired control in simulation; confirm matching content is *classified* and the
  control *would* act.
- **Validate** — run the pass/fail gates in `05-testing.md` (accuracy + wiring).
- **Expand** — publish/enforce and widen scope **only** after the gate passes; roll back per
  `03-implementation.md` if a gate fails.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing**
  (accuracy + wiring pass/fail gates), **Troubleshooting**, **Best Practices**, and a **Deliverables
  Summary** + **Executive Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph): a **Discovery**
  inventory of where classifiers can be wired (auto-labeling, DLP, retention, labels); a
  **Configure/Remediation** helper that builds the **wiring** (auto-labeling policy) in **simulation
  (`-WhatIf` first)**; a **Validation** checker; a **Reporting** rollup of policy modes and
  classification activity; and a **seed/scope health** helper — **read-only or `-WhatIf` by default;
  no credentials in code.**

> **Classifier creation is portal-driven.** Seeding, training, testing, and publishing a trainable
> classifier are done in the **Purview portal** — the scripts do **not** invent a cmdlet to create or
> publish a classifier; they automate the **wiring** (auto-labeling/DLP/retention) and the reporting
> around it, and remind you to confirm classifier status in the portal.

> **Sources.** Microsoft Learn — *Learn about trainable classifiers*, *Create a trainable classifier*,
> *Get started with trainable classifiers*, *Apply a sensitivity label to content automatically*
> (auto-labeling + simulation), and *Create a DLP policy / retention using a trainable classifier as a
> condition*. These capabilities are **licensing-dependent** and the Purview portal is **evolving** —
> **verify capability availability, the built-in catalog, minimum seed counts, portal paths, and
> cmdlet parameters against your licensing/tenant** rather than assuming.
