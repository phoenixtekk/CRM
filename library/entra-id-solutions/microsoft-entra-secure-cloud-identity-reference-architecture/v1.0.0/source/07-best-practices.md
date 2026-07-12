# 7. Best Practices — Microsoft Entra: Secure Cloud Identity Reference Architecture

- Design before you build, always. The whole value of this deliverable is that topology, identity
  model, access, privileged access, and governance are decided on purpose and recorded — before a
  single policy is created. A tenant that builds first and designs never is exactly the ad-hoc estate
  this solution exists to prevent.
- Ground every decision in evidence. Run the read-only Assess scripts and the posture KQL first; each
  `ADR-0nn` should cite the current-state finding it responds to. Design from data, not assumption.
- Keep it gap-only. Where an existing control is sound, tag it **adopt** and record why — do not
  redesign what already works. The architecture targets the gaps, and the roadmap sequences only the
  builds the tenant actually needs.
- Record the rationale, not just the choice. A Decision Record's worth is the *why* and the
  *consequences* — an auditor, a board, or the next architect must be able to see what was decided,
  why, and what it depends on. A decision with no rationale is not defensible.
- Let the owners own the determinations. Tenant topology, what counts as "privileged," data-residency
  and regulatory constraints, external-collaboration posture, and change-approval are
  security/compliance/business decisions — the architect frames the options; the named owner decides,
  and the `ADR` attributes them. Never invent an answer where an owner has not decided; record the open
  question as `Proposed`.
- Be honest about licensing and preview. Risk-based Conditional Access and PIM need **Entra ID P2**;
  entitlement management and lifecycle need **Entra ID Governance**; **Global Secure Access** and
  **Verified ID** are separately licensed and partly in preview. Flag every dependency with *verify
  current availability in your tenant*, and either make license acquisition a roadmap prerequisite or
  design a documented interim alternative.
- Make break-glass sacrosanct in the design. Two cloud-only emergency accounts, excluded from
  Conditional Access, monitored — the design mandates them as the anti-lockout guarantee behind every
  future build, even though the builds implement the exclusions.
- Design privileged access as tiers with no standing admin. Tier 0/1/2 separation, PIM eligibility
  instead of permanent roles, phishing-resistant auth for admins, and PAWs for Tier 0/1 work — this is
  the highest-leverage part of the architecture; get it decided early (`Phase 3`).
- Prefer cloud-native over hybrid where feasible. If the source of authority can be cloud-only, the
  design is simpler and the attack surface smaller; only carry hybrid coexistence where the business
  genuinely needs on-prem AD as master, and record why.
- Number and name everything consistently. `ADR-0nn <Decision> - <Domain>`, `Phase n - <Theme>`, and
  `<Purpose> - <Scope> - <Stage>` for the objects the builds will create — a self-documenting design
  the builds inherit without reinterpretation.
- Cross-reference every domain to its build. The roadmap must be a concrete, ordered list of the
  implementation solutions to deploy (`ENTZTCA`, `ENTIDP`, `ENTPIM`, `ENTPAW`, `ENTIGA`, `ENTGSA`,
  `ENTAPPMIG`, `HYBID`) — not a set of good intentions.
- Keep the Decision Record living. When a future build needs to deviate, add a **superseding** `ADR`
  rather than editing history or drifting silently. The record's integrity is what keeps the
  architecture true over years.
- Re-assess on a cadence. Re-run the read-only Assess scripts periodically; an architecture is a living
  design — new identity types, new licenses, and preview-to-GA transitions all warrant a superseding
  decision.

## Where to go next
The roadmap this blueprint produces hands each phase to a build solution:
- **Zero Trust Conditional Access Baseline (`ENTZTCA`)** and **Identity Protection & Advanced
  Conditional Access (`ENTIDP`)** — build the Zero Trust access design (Domain 3).
- **Privileged Identity Management / PIM (`ENTPIM`)** and **Privileged Access Workstation / PAW
  (`ENTPAW`)** — build the privileged access model (Domain 4).
- **Identity Governance: Access Reviews & Entitlement (`ENTIGA`)** — build the governance model
  (Domain 5).
- **Hybrid Identity: AD + Entra Connect (`HYBID`)**, **Migrate & Protect Applications with Entra
  (`ENTAPPMIG`)**, and **Global Secure Access (`ENTGSA`)** — build hybrid coexistence, app identity,
  and secure connectivity (Domains 1 and 6).
- **External Identities / B2B Cross-Tenant** and **Enterprise App & Service Principal Governance** —
  build the external and workload identity decisions (Domain 2).
