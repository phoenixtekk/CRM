# Best Practices — Keeping the Architecture Authoritative

Defining the target architecture is the easy half; keeping it **authoritative** across a multi-year,
multi-partner, 150k-user program is the hard half. These practices keep the blueprint the thing every
workstream conforms to instead of a document that drifts into irrelevance.

## 1. Make the ADR the currency of decisions

- **Every consequential decision becomes an ADR** (`GWARCH-ADR-DOMAIN-NN`, status
  Proposed/Accepted/Superseded). If a decision isn't in the log, it isn't a decision — it's a rumor.
- **Never edit a decision in place; supersede it.** A new ADR references the one it replaces. The
  history is the audit trail.
- **The ADR log is singular and current.** One log, owned by the ARB, is the authority — not slides,
  not email threads.

## 2. Govern by scope, everywhere (GWARCH-Scope discipline)

- Bind **every** policy — sharing, DLP, retention, Gemini access — to the named OU/group taxonomy, so
  new capabilities inherit governance by landing in the right scope.
- Treat a policy applied to an ad-hoc individual as a **defect**; refactor it onto a scope.
- Keep source-side group→target-scope mapping deterministic (`GWARCH-Set-ScopeTargeting.ps1`) so scope
  can't silently diverge between the M365 source and the Google target.

## 3. Identity-first, always

- Resolve identity ADRs before any dependent domain proceeds (GWARCH-P2). A late identity change
  invalidates downstream designs across four domains.
- Keep **break-glass admin access independent of the federated IdP** — verify it after every
  federation change. An IdP outage must never lock out administration of a 150k-user estate.

## 4. Keep coexistence on a leash

- Give **every** coexistence bridge (mail routing, directory, holds) a written sunset condition and an
  owner (GWARCH-P5). Review the list at every ARB.
- A "temporary" bridge past its sunset date is an escalation item, not a footnote.

## 5. Governance precedes AI — hold the line

- Do not let AI enablement outrun governance (GWARCH-P6). The Pattern AI-C gate is non-negotiable: no
  Gemini/agent access to a data class until that class's DLP/sharing/retention controls exist.
- Maintain a **preview-capability risk register.** Gemini Enterprise capabilities move fast and some
  are preview/rolling-out — mark each GA vs preview, carry a contingency, and **verify in tenant**
  rather than designing on a screenshot.
- Keep a complete **agent inventory** with owners; an ungoverned production agent is a governance
  breach, not a convenience.

## 6. Run the ARB as a conformance engine

- **Standing cadence, quorum, decision rights.** The ARB approves ADRs, grants exceptions (as
  exception ADRs), and owns the sunset list.
- **ARB hooks into the program:** wave gates (`05-testing.md`) feed the ARB; a wave doesn't advance
  Pilot→Expand without an ARB conformance sign-off. This is the enforcement mechanism that makes the
  blueprint authoritative rather than advisory.
- **Exceptions are visible and time-boxed.** Every deviation is an explicit, dated exception ADR with
  a remediation plan — never a silent divergence.

## 7. Re-baseline against reality on a cadence

- Re-run `GWARCH-Discovery.ps1` and `GWARCH-Validation.ps1` on a schedule so the architecture is
  measured against the *current* source estate, not the one it was drafted against (GWARCH-P8).
- Feed drift (new shadow identity sources, unscoped policies, expired coexistence bridges) back into
  the ADR log and the ARB as gaps to close.

## 8. Design for reversibility where it's cheap

- Prefer exportable formats and portable identity patterns (GWARCH-P7) so a future tooling change
  touches integration layers, not the whole estate. Record any deliberate one-way lock-in as an ADR
  with its rationale so it's a chosen risk, not an accident.

## 9. Keep the three surfaces coherent

The **compiled Target-Architecture document**, the **ADR log**, and the **built estate** must agree.
When the estate changes, the ADR log and document change with it (supersede, don't overwrite). A gap
between the three is exactly what erodes authority — close it before it compounds.

---

*Bottom line:* authority comes from **one owned end-state, one ADR log, scope-based governance, an ARB
that gates every wave, and periodic re-baselining against the real estate.* Hold those and the
architecture stays the thing the program conforms to — which is the entire point of owning it.
