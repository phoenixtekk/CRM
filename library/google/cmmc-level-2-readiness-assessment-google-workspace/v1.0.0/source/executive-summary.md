# Executive Summary

## Outcome

Your organization holds **Controlled Unclassified Information (CUI)** on Google Workspace and must reach
**CMMC Level 2** — the **110 security requirements of NIST SP 800-171** — to remain eligible for DoD
work. This solution takes the tenant from *controls-unmapped, boundary-undefined, no-evidence* to
**assessment-ready**: the CUI boundary is defined and enforced, the applicable NIST 800-171 controls are
mapped to concrete Workspace configuration, the controls are applied and **evidenced**, and the
**System Security Plan (SSP)** and **Plan of Action & Milestones (POA&M)** are complete — the exact
posture a **C3PAO** expects to find at the start of a Level 2 assessment.

## Approach

A **CUI-boundary-first, control-family-driven** playbook on the house model **Assess → Design →
Configure → Pilot → Validate → Expand**:

1. **Define the CUI boundary** — a dedicated **`CUI – Boundary – Org`** organizational unit that fixes
   assessment scope.
2. **Map all 14 NIST 800-171 families** to real Workspace mechanisms (context-aware access, 2-step
   verification, DLP, Vault retention, audit-log export, data-region/encryption, admin separation) in a
   single **control-map matrix**.
3. **Configure, pilot, and evidence** each control against the boundary — pilot-first, with pass/fail
   gates and a documented rollback for every high-impact change.
4. **Generate the SSP and POA&M** from the completed control map, for the compliance owner to review and
   own.

Five read-only **Python tools** (Google Admin SDK / Reports / Drive APIs) do the measuring: a
control-status assessment, an evidence collector/exporter, a CUI-boundary exposure checker, an SSP/POA&M
draft generator, and a scope/config helper.

## Why it is low-risk

- **Pilot-first with rollback.** Every enforcing control (DLP, sharing, context-aware access, 2SV) is
  proven on a pilot group before fleet enforcement; each has a one-lookup rollback scoped to the
  boundary OU — never the whole tenant.
- **Read-only, safe-by-default tooling.** The tools require only least-privilege read-only scopes; they
  cannot change the posture they measure, and no credentials or keys live in code.
- **Evidence-driven, not asserted.** Control status is *measured* from the live tenant, so the SSP and
  POA&M reflect reality, not optimism.

## The boundary we hold

This engagement delivers **readiness** — control mapping, configuration method, and evidence, plus the
SSP and POA&M. It does **not** produce a CMMC assessment result, decide NIST 800-171
applicability/scoping, interpret ITAR/DFARS, or represent you before a C3PAO. Those determinations
remain with your **assessor, compliance officer, and legal counsel**. The result is a tenant that is
**configured, evidenced, and assessment-ready** — at a fraction of open-ended readiness-consulting cost.
