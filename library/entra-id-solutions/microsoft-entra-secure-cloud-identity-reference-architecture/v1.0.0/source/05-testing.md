# 5. Testing Guide — Microsoft Entra: Secure Cloud Identity Reference Architecture

Because this is a **design deliverable**, "testing" validates two things: (1) the **evidence base** the
scripts produced during Assess is complete and read-only, and (2) the **design artifacts** — the
Architecture Design Document, the Decision Record, and the Roadmap — are complete, defensible, and
gated. Scripts are referenced by name; all reads are read-only.

## Test 1 — Assess evidence is complete
Do: Confirm `ENTARCH-Discovery.ps1`, `ENTARCH-IdentityInventory.ps1`,
`ENTARCH-PrivilegedAccessReview.ps1`, and `ENTARCH-Report.ps1` all ran and their output is saved as the
Assess appendix of `Identity Architecture - Enterprise - Design`.
Expected: Topology, licensing, the three identity types, privileged access, and posture (MFA / legacy
auth / risk) are all documented. No script made any change (read-only).

## Test 2 — Every existing control is classified
Do: Review the Assess appendix.
Expected: Each existing identity control (Conditional Access policy, PIM config, governance, sync,
break-glass) is tagged **adopt**, **adjust**, or **replace** — nothing is left unclassified, so the
design stays gap-only.

## Test 3 — The Decision Record covers all six domains
Do: Review `Decision Record - Identity Architecture - Design`.
Expected: Every domain (Topology, Identity Model, Zero Trust, Privileged Access, Governance,
Hybrid/Connectivity) has at least one `ADR-0nn`. No domain is missing a decision or an owner.

## Test 4 — Each ADR is complete and defensible
Do: Spot-check each `ADR-0nn`.
Expected: Each has Context / Decision / Rationale / Consequences / License-or-preview caveat / Build
cross-reference, and a named accountable owner. Open questions are recorded as `Proposed`, not invented.

## Test 5 — License and preview dependencies are flagged
Do: Search the Design Document and Decision Record for every feature that needs P2, Entra ID
Governance, Global Secure Access, or Verified ID, or that is in preview.
Expected: Each is explicitly flagged with *verify current availability in your tenant*, and any decision
depending on an unheld license is either a roadmap prerequisite or has a documented P1-only alternative.

## Test 6 — Break-glass standard is in the design
Do: Review the privileged access domain and run `ENTARCH-PrivilegedAccessReview.ps1`.
Expected: The design mandates two cloud-only break-glass accounts; the script confirms they exist (or
the design records creating them as `Phase 0 - Foundation`).

## Test 7 — The blueprint validates against the tenant
Do: Run `ENTARCH-Validate.ps1`.
Expected: PASS/WARN lines for break-glass presence, the mandated design groups (present or roadmap),
the assumed licensing, and any All-users CA policy without exclusions the design must reconcile. Every
WARN is either resolved or captured as a roadmap prerequisite.

## Test 8 — Every domain has a build cross-reference
Do: Review the Design Document domain by domain.
Expected: Each domain names the implementation solution that builds it (`ENTZTCA`, `ENTIDP`, `ENTPIM`,
`ENTPAW`, `ENTIGA`, `ENTGSA`, `ENTAPPMIG`, `HYBID`) — the roadmap is concrete builds, not aspirations.

## Test 9 — The roadmap is phased and gated
Do: Review `Roadmap - Identity Foundation - Phased`.
Expected: Phases 0–5 each list their builds and an explicit **gate to enter** (accepted ADRs / license
confirmed). No phase can start before its design decisions are accepted and validated.

## Test 10 — Decision Record is frozen and living
Do: Confirm the Expand stage completed.
Expected: Every reviewed `ADR` is `Accepted` / `Rejected` / `Superseded` (none left `Proposed` at
hand-off), and the record is under version control so future deviations add a superseding `ADR` rather
than drifting silently.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Assess pass | Tests 1–2 pass; posture evidence complete and read-only; every existing control classified adopt/adjust/replace |
| Design pass | Tests 3–6 pass; all six domains decided, each `ADR` complete with owner and license/preview caveat; break-glass mandated |
| Validate & roadmap pass | Tests 7–10 pass; blueprint validated against the tenant; every domain has a build cross-reference; roadmap phased and gated; Decision Record frozen |
