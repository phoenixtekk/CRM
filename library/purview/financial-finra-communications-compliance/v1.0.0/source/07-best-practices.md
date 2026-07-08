# 7. Best Practices — Financial / FINRA Communications Compliance (Microsoft Purview)

Operating guidance for a defensible, examinable communications-supervision program. These practices sit
on top of the shared Purview category requirements and the Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand model. **None of them changes who owns the determination:** what
constitutes a violation, which rules apply, the retention schedule, and any supervisory/disciplinary
action are **Compliance, Records, Legal, and designated-supervisory-principal** decisions.

## Program design
- **Anchor everything to the WSPs.** The Written Supervisory Procedures are the authority for *who* is
  supervised, *what* is reviewed, at *what sampling rate*, and *by whom*. Configure Purview to the WSPs;
  if the tool can't express a WSP requirement, fix the WSP or the design — don't quietly diverge.
- **Treat the three pillars as one program.** Lexicons without review produce alerts nobody actions;
  review without evidence isn't defensible; evidence without detection preserves noise. Keep detection,
  the designated-principal workflow, and immutable retention in lockstep.
- **Scope to the registered/covered population, not "everyone."** Over-scoping is a privacy and
  employment/works-council risk and dilutes reviewer attention; under-scoping is a supervision gap.
  Re-confirm the population with Compliance on a schedule as people change roles.

## Role separation and privacy
- **Separate builders, reviewers, investigators, and oversight** using the four Communication Compliance
  role groups; **never let a reviewer supervise themselves.** Avoid the combined role group outside a
  tiny pilot.
- **Make separation evidence-able.** Run `CCFIN-Discovery.ps1` on a schedule and keep the
  `FINRA Supervision Roles – Evidence` snapshot; separation you can't demonstrate is separation you don't
  have.
- **Configure privacy before the first policy runs.** Use pseudonymized usernames where Privacy/Legal or
  a works council requires it, and confirm a documented lawful basis/notice. Reviewer over-reach is
  itself a compliance and trust risk.

## Lexicons and detection tuning
- **Start narrow and tune down noise, not up.** Begin with the highest-value classifiers and a focused
  `FINRA Lexicon – Conduct`, then refine conditions and sampling. Widening scope to "catch more" without
  tuning buries reviewers and degrades the program.
- **Keep the lexicon a living, Compliance-owned artifact.** Guarantees, selling-away, outside-business,
  and complaint language evolve; review the term lists with Compliance periodically and version them.
- **Verify classifier availability — don't assume.** Regulated-conduct trainable classifiers are
  plan-dependent and **some are in preview**; confirm each in your tenant and flag preview classifiers to
  Compliance for a risk decision before relying on them.
- **Right-size the sampling rate to reviewer capacity** as set by the WSPs. A rate the principals can't
  actually keep up with is a supervision gap on paper *and* in practice.

## Review workflow
- **Make the reviewer trail complete and timely.** Disposition (compliant/questionable/non-compliant),
  notes, escalations, and resolution are the reasonable-supervision evidence; a backlog of unreviewed
  items is a finding. Monitor queue age.
- **Escalate to Investigators, decide with Compliance/Legal.** Principals surface and disposition;
  genuine potential violations go to Investigators and then to Compliance/Legal for the determination and
  any action. Keep that handoff explicit.
- **Coach on context.** Train principals to review flagged messages **in thread context**, not in
  isolation — a keyword match is a prompt to look, not a verdict.

## Evidence and recordkeeping
- **Get the records decision in writing before touching retention.** The period and whether to apply
  **Preservation Lock** are Compliance/Records decisions. **Preservation Lock is irreversible** — a
  locked policy cannot be shortened, disabled, or deleted, only broadened.
- **Pilot retention unlocked, lock deliberately.** Validate coverage with an **unlocked** policy first;
  apply the lock only once the schedule is confirmed and approved. The scripts refuse to lock by default
  and require an explicit switch plus `-Commit`.
- **Keep detection scope and evidence scope aligned.** When you expand supervision, extend the evidence
  retention to match — supervising a channel you don't preserve is a recordkeeping gap.
- **Preserve the supervision *and* the review activity.** Both the underlying communications and the
  fact/record of review are examinable; ensure auditing is on and the activity rollup is retained.

## Change control and rollout
- **Always pilot in simulation/test first.** Supervision and retention are high-impact; never enable
  firm-wide blind. Expand in rings, re-validating each with the full test set.
- **Rollback plan per stage — and know what can't roll back.** Role/scope/policy changes and *unlocked*
  retention are reversible; a *locked* retention policy is not. Gate the lock on written approval
  precisely because it's one-way.
- **Re-validate after every change.** Re-run the Testing guide after tuning, after adding a channel, and
  before each expansion ring. Keep the results as pilot/expansion sign-off evidence.

## Operations
- **Schedule the read-only tools.** Run `CCFIN-Discovery.ps1`, `CCFIN-Validation.ps1`,
  `CCFIN-EvidenceCheck.ps1`, and `CCFIN-Report.ps1` on a cadence to catch drift (separation collapse,
  scope creep, retention gaps, review backlog) early.
- **No credentials in code or automation.** The scripts use interactive/modern-auth
  `Connect-IPPSSession` / `Connect-MgGraph`; keep secrets out of scripts, scheduled tasks, and logs.
- **Review the program with Compliance on a fixed cadence** — lexicon terms, sampling, population,
  channels, and retention schedule — and record the review. A supervision program is examined on whether
  it is *maintained*, not just whether it was once configured.

*Bottom line: keep the three pillars in lockstep, keep separation and evidence demonstrable, pilot every
change in simulation, and leave every verdict and records decision with Compliance, Records, Legal, and
the firm's designated supervisory principals.*
