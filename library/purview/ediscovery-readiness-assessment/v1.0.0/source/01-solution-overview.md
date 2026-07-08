# 1. Solution Overview — eDiscovery Readiness Assessment (Microsoft Purview)

## What this solution is (and is not)
This solution answers one question with evidence: **"If a legal hold or regulatory request landed
today, could we respond — completely, defensibly, and on time?"** It is a **readiness assessment** of
your Microsoft Purview eDiscovery capability across four domains — **roles, holds/preservation,
data-source scope, and process** — that produces a **readiness scorecard, a prioritized gap
register, and a remediation roadmap**, then **proves** the capability with a small, non-destructive
**readiness-proof pilot** on a test account.

> **This is an *assessment*, not the day-to-day operation of matters.** A separate Purview solution —
> **eDiscovery Administration** — covers running real matters end to end (case → search → hold →
> review → export, with KQL query design, review sets, analytics, and defensible export). This
> readiness assessment sits *before* that: it confirms you are configured, licensed, staffed, and
> rehearsed to run matters at all, and it fixes the gaps that would otherwise surface mid-litigation.
> Where operating a matter is in scope, use the eDiscovery Administration solution; this one makes you
> **ready** to.

## Why readiness is the risk
When a hold lands, the clock starts and the standard of conduct is **defensibility** — proof that
preservation was timely and complete. Organizations fail here not because Purview cannot do it, but
because of gaps that were invisible until tested:

- **Roles** granted through Global Administrator (over-privileged) or held by one person (no
  coverage), or nobody in **eDiscovery Manager/Administrator** at all.
- **Preservation** that silently is not working — the **unified audit log is off** (no defensibility
  evidence), **inactive/legacy mailboxes** are not covered, or retention and holds interact in ways
  nobody has verified.
- **Scope** blind spots — Teams messages (which live in mailboxes), M365 Group/Teams sites,
  OneDrive, unindexed or partially-indexed content — that make a collection incomplete.
- **Process** gaps — no matter-intake step, no legal sign-off gate, no naming standard, no
  change-control or evidence-pack routine — so the *first* real matter is improvised.

A readiness assessment surfaces these on a test account and a scorecard, not during discovery in a
live matter.

## The four readiness domains (the rubric)
Each domain is scored **Not Ready → Partial → Ready** with named, evidenced criteria:

1. **Roles & least privilege (R).** Are operators in **eDiscovery Manager**, with a small
   **eDiscovery Administrator** lead group, and **no standing Global Admin** used for matters? Is
   there **coverage** (more than one trained operator — no single point of failure)? Are compliance
   boundaries considered where separation is required?
2. **Holds & preservation (H).** Is the **unified audit log on** (the defensibility evidence)? Can a
   **hold actually preserve** — proven, not assumed? Are **inactive/legacy mailboxes**,
   **litigation-hold** state, and **retention-vs-hold interplay** understood and covered? Is there
   headroom for the number/size of holds you may need?
3. **Data-source scope & coverage (S).** Are all in-scope **workloads** discoverable — Exchange
   (including **Teams chat**, which lives in mailboxes), SharePoint, OneDrive, and **Teams/M365 Group
   sites and files**? Are **unindexed/partially-indexed** items and any third-party/imported data
   accounted for?
4. **Process & defensibility (P).** Is there a **matter-intake** step with a named **legal/records
   owner** who determines scope and holds; a **naming standard**; **change control** and **rollback**
   for holds/exports; and an **evidence-pack** routine (who keeps the audit trail and export
   reports)?

## How it works (the assessment model)
1. **Assess (read-only).** Inventory the current state — role membership, existing cases/holds, audit
   status, licensing signals, inactive mailboxes, retention holds, and workload coverage — with the
   included read-only scripts. Nothing changes.
2. **Design (the scorecard).** Score each domain against the rubric, record every gap in the **gap
   register** with severity and owner, and design the target state and remediation order.
3. **Configure/Remediate (simulation/test first).** Close gaps — add operators to the correct role
   groups, enable the audit log, stand up the naming standard and intake process — using the
   remediation script **dry-run (`-WhatIf`) by default**, committing only with an explicit switch.
4. **Pilot the readiness proof (non-destructive, on a test account).** Prove the capability end to
   end on a **scratch, non-sensitive test account**: create a **readiness-proof case**, place a
   **hold**, run a **scoped search**, confirm preservation, then **remove the proof hold**. This
   rehearses the muscle without touching real custodians — the "pilot in test" gate.
5. **Validate (pass/fail gates).** Re-run the validation script; every rubric gate must pass and the
   audit log must show the proof activity.
6. **Expand (operate).** With gaps closed and the proof passing, you are ready to run live matters —
   using the **eDiscovery Administration** solution — with legal owning every determination.

## The reference design (naming)
Everything created by the readiness proof is named to make it obvious it is a **rehearsal**, and is
removed at the end:
- Proof case: `eDiscovery Readiness – Proof – Pilot`
- Proof hold policy / rule: `Readiness Hold Policy – Proof – Pilot` / `Readiness Hold Rule – Proof – Pilot`
- Proof search: `Readiness Search – Proof – Pilot`
- Proof custodian: a **dedicated test account** (placeholder `readiness-pilot@contoso.com`), never a
  real person.

## What legal owns (and what this solution does not decide)
**Regulatory, records-retention, and legal determinations are deferred to your compliance, records,
privacy, and legal functions.** This solution supplies the **technical method and the evidence** —
whether roles are least-privilege, whether a hold preserves, whether scope is complete — but never
the legal call about what must be held, who is a custodian, what a retention schedule is, or whether
a regulatory obligation applies. The readiness proof runs on a **test account only**; it is a
capability rehearsal, not a real preservation.

## Benefits
- **Know before litigation, not during.** A defensible, evidenced answer to "are we ready?" — with a
  scorecard the business and legal can act on.
- **Fixes the invisible gaps.** Over-privileged roles, audit-off tenants, uncovered inactive
  mailboxes, and missing process — found on a test account, not mid-matter.
- **Least-privilege and safe.** Remediation is dry-run by default; the proof is non-destructive and
  self-cleaning; no Global Admin dependency.
- **A rehearsed muscle.** The team has actually placed a hold and run a search once, in test, before
  the stakes are real.

## Limitations (be honest with buyers)
- **Licensing-gated capability.** Content Search and eDiscovery (Standard) cases/holds are broadly
  available; **eDiscovery (Premium)** (custodians, review sets, analytics, structured export)
  requires **Microsoft 365 E5 / E5 eDiscovery and Audit** — the assessment reports which tier is
  available; **verify your licensing/tenant.** Readiness for *Premium* review workflows is flagged
  where the tier is absent.
- **The portal is evolving.** Microsoft unified the eDiscovery experience in the Purview portal
  (`purview.microsoft.com`); menu paths differ from older screenshots — paths are flagged **"verify
  in your tenant."**
- **Not a substitute for legal judgement.** The assessment evidences capability; scope, custodian,
  hold, and production decisions remain legal/records determinations.
- **Government clouds differ.** GCC High / DoD use different portal hosts (e.g. `*.office365.us`) and
  some features lag Commercial — **verify in your tenant.**

## The standard deployment model
> **Assess → Design → Configure → Pilot (readiness proof in test) → Validate → Expand.** Remediation
> is dry-run first; the readiness proof is non-destructive and runs on a dedicated test account; every
> gate is explicit pass/fail with a documented rollback (remove the proof hold, revert role changes).
