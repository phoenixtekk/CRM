# 7. Best Practices — Assessing a Microsoft Purview Tenant

Operating principles for producing a Purview assessment that is trustworthy, actionable, and repeatable.
Grounded in Microsoft's public guidance and the **Assess → Design → Configure → Pilot → Validate →
Expand** model.

## Assess the whole estate, not one capability at a time
- The value of a *tenant* assessment is the cross-capability view — DLP without labels, labels without retention, Insider Risk without reviewers. Always run the full inventory, even for capabilities you assume are fine; the surprises are usually in the ones nobody looks at.
- Distinguish **not licensed**, **licensed-but-empty**, and **configured**. "Insider Risk is licensed but has zero policies" is a headline finding, not an omission — record it explicitly.

## Read-only first; never let a permission gap look like a coverage gap
- Preflight roles and endpoints (`PURVASSESS-Scope.ps1`) **before** assessing. A capability that returns nothing because your account lacks the reader role is a false "gap" — the most common way an assessment misleads.
- Prefer **reader** roles for the assessment; grant **write** roles only for the specific quick-win capability you're remediating, under change control, and remove them after.

## Be honest about what PowerShell can and can't read
- Several capabilities — **Insider Risk configuration, DSPM/DSPM for AI, Compliance Manager scoring, the Unified Catalog** — are **portal-driven** with limited or no stable PowerShell surface. Flag them **"portal-only — review manually"** with the exact portal location. **Never invent a cmdlet** to manufacture a reading.
- Purview features are **licensing-dependent and the portal evolves**. Where a value can't be confirmed, write **"verify your licensing/tenant"** rather than asserting it. An honest "review manually" beats a confident wrong number.

## Prioritize by risk, and make the priorities mean something
- Use a fixed, agreed scheme — **P1** (critical exposure / enforced-but-risky), **P2** (coverage gap / drift), **P3** (optimization) — and apply it consistently so the register is a plan, not a list.
- The point of the assessment is *which three things to fix first*. Resist the urge to present fifty equal findings; the readout should lead with the P1s.

## Every fix is simulation/test/pilot-first — even the "safe" ones
- Moving a DLP policy's mode, enabling a retention policy, or taking auto-labeling to simulation are all reversible, but they are tenant-impacting. Apply them **`-WhatIf` first**, scoped to `Purview Assessment – Remediation Pilot – Stage1`, validate, then expand.
- **Never move a policy straight to enforce** as part of an assessment. The assessment's job is to *find and safely stabilize*, not to launch enforcement; full enforcement is a governed build step with its own pilot.
- Record the **prior state and the exact rollback** with every change so a questioned fix can be backed out cleanly (`-Revert -Commit`).

## Keep the governance line bright
- Whether a retention duration is **correct**, whether a DLP rule **satisfies** a regulation, whether an Insider Risk policy **should exist** — these are **compliance/records/privacy/legal determinations**. Record them as findings **for the owner to decide**; the assessment supplies the evidence, not the verdict.
- **Insider Risk & Communication Compliance** are HR/privacy-sensitive — review **configuration hygiene and role separation only** (are reviewers assigned, is scope appropriate, is privacy-by-design/pseudonymization in place), never case content.

## Make it a baseline you can re-run
- The first assessment is the baseline; the value compounds when you **re-run it on a cadence** (e.g. quarterly). Schedule the read-only chain and track the **P1/P2 trend** — a falling count is the objective measure that the estate is improving.
- Keep the register and scorecard as living artifacts owned by the compliance function, not a one-off PDF. Feed the non-remediated findings into implementation engagements as a governed backlog.

## Least-privilege, evidenced, reversible
- Read with the minimum role; write only where and when a fix requires it.
- Evidence every finding with its source (which cmdlet/portal read produced it) so it's defensible and reproducible.
- Keep every change reversible and recorded — the assessment should leave the tenant **more stable and better understood**, never surprised.
