# Executive Summary — Sensitivity Label Taxonomy Design (Microsoft Purview)

## The problem
Sensitivity labels are how Microsoft Purview classifies and protects content — but a **bad taxonomy
breaks adoption and trust**. Too many labels and users guess or ignore them; too few and the labels
don't reflect real sensitivity; inconsistent names produce sprawl no one can maintain. Worse, the
taxonomy is **expensive to change after publish** — existing content keeps the label it was stamped
with, so a rushed design has to be lived with or painfully rebuilt. Left unaddressed, this is a
compliance gap and a data-risk exposure: the investment in Purview fails to deliver classified,
protected content.

## The solution
A complete, self-guided way to **design a sensitivity label taxonomy users will actually use** — and to
build it so it doesn't have to be rebuilt. It delivers a workable **tier structure** (the right number
of tiers, with sublabels for nuance), a **stable naming convention** (immutable internal names,
plain-language display names and tooltips), and a **protection/marking mapping** — which labels encrypt
(rights by group), which mark, and with what header/footer/watermark. The designed taxonomy is then
configured in the tenant, **published to a pilot ring**, and validated before broad rollout. It uses
only the Microsoft Purview portal and Security & Compliance PowerShell — no third-party tooling.

## How it works
The engagement follows one disciplined model: **Assess → Design → Configure → Pilot (test) → Validate →
Expand.** Assess the current label posture and catch name collisions and sprawl; **design** the tiers,
sublabels, naming convention, and protection mapping with the governance owners and get them signed off;
build the parent tiers and top-level labels, then the protected sublabels per the mapping — each
previewed with `-WhatIf` before commit; publish to a **pilot ring**; validate structure, marking, and
that encryption actually enforces; then expand to broad publish. Five PowerShell tools — read-only or
`-WhatIf` by default — automate discovery, configuration, validation, reporting, and health checks.

## What is delivered
- Six implementation documents (Overview, Requirements, Implementation, Testing, Best Practices,
  Troubleshooting) plus this summary — including the naming convention and the protection/marking
  mapping template.
- Five Security & Compliance PowerShell tools: posture/collision discovery, taxonomy + publish config
  helper, design-conformance validation, taxonomy/mapping reporting, and a scope/health helper.
- A named, gated, reversible rollout with explicit pass/fail criteria at every step.

## Business outcome
A label taxonomy that **users adopt because it's clear** — the right number of tiers, sublabels that say
who content is for, a naming convention that prevents sprawl, and protection applied exactly where it's
needed and proven to enforce before it reaches everyone. Classification that sticks, at a fraction of
the cost of a bespoke consulting engagement — and a foundation the rest of the Purview program (DLP,
auto-labeling, retention, container labeling) builds on.

## Important boundaries
The **tier count, the final label names, which tiers encrypt, and the rights model** are
**determinations owned by your security, compliance, records, and legal functions** — this solution
provides the design method, the mapping template, and the technical configuration and evidence, not the
determination. Sensitivity labeling and label-based encryption are broadly licensed, but some advanced
behaviors are plan-gated (E5 / E5 Compliance) and the Purview portal is evolving — availability and
paths are flagged "verify your licensing/tenant," never assumed.
