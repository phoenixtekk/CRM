# 1. Solution Overview — Remediation Playbook for Defender Security Optimization Assessments

## What this playbook is
This is the **remediation companion** to the Security Optimization Assessment (SOA) line for Microsoft Defender. The assessments are **read-only** — they enumerate configuration, score it against best practice, and produce a **prioritized, risk-ranked findings report**. This playbook takes that report and **closes the gaps**: for each finding category it provides a **pilot-first, preview-gated** remediation procedure, then **verifies** and **re-scores** to prove closure, with change-tracking and an evidence report.

It spans the finding categories across all five Defender products:
- **Defender for Cloud Apps** — connector/discovery coverage, app-governance/OAuth policies, session/access policies, alert hygiene.
- **Defender for Cloud** — Secure Score recommendations, plan coverage, regulatory-compliance mapping, agent/agentless coverage.
- **Defender for Endpoint** — onboarding/coverage, ASR/hardening, EDR settings, vulnerability remediation.
- **Defender for Identity** — sensor coverage, unresolved health alerts, recommended detections.
- **Defender for Office 365** — anti-phish/Safe Links/Safe Attachments policy hygiene, preset security policies.
- **Suite / XDR (cross-cutting)** — cross-pillar coverage, unified RBAC, incident correlation, suite Secure Score.

## Why a separate, gated playbook
Remediation is where risk lives. The assessment could never touch the tenant — that is what made it safe to run. Fixing a finding, by contrast, **changes configuration**: enabling a plan costs money, tightening a Conditional Access / session policy can lock users out, activating unified RBAC changes who can do what, and a response action can disrupt a user or device. So remediation must be **disciplined**:

- **Preview first.** Every change script defaults to **`-WhatIf` / simulation** — it shows exactly what *would* change and touches nothing until you pass an explicit apply switch.
- **Pilot first.** Apply to a small, named **pilot scope** (a pilot group, one subscription, a test policy) before any broad rollout.
- **Verify, then re-score.** After applying, confirm the specific control is now correct, then **re-run the relevant assessment score** to prove the finding is closed — the score is the objective proof.
- **Track and evidence.** Record what changed, when, by whom, and the before/after score, so the remediation is auditable.
- **Rollback ready.** Each remediation carries a rollback / break-glass note before it is applied.

## The remediation model (per finding)
For each finding the playbook follows the same loop:
1. **Ingest** the finding from the assessment's findings report (read-only).
2. **Map** it to its remediation procedure (the finding-to-remediation map in Section 3).
3. **Preview** the change with `-WhatIf` / simulation on the pilot scope.
4. **Apply** to the pilot scope (explicit apply switch; approval-gated for disruptive/response actions).
5. **Verify** the specific control is now correct.
6. **Re-score** by re-running the relevant assessment score to prove closure.
7. **Expand** the change across scope in stages, with rollback ready.
8. **Evidence** — record the change and before/after score in the remediation evidence report.

## What is in scope
- **Mapping** each assessment finding category (across the five products + suite) to a remediation procedure.
- **Applying** fixes **pilot-first**, **preview-gated**, with verification and re-score.
- **Producing** a change-tracked remediation evidence report proving closure.

## What is out of scope (and where it lives)
- **Producing the findings** — the Security Optimization Assessments (read-only) generate the backlog this playbook consumes.
- **Deep product build-outs** — the product-specific onboarding/optimization solutions (e.g. *Defender XDR Unified Onboarding*, *Defender for Cloud CSPM & Secure Score Remediation*, *EOP/MDO mail hygiene*, *Cloud App DLP*) go deeper than a single finding-fix; the playbook points to them for large gaps.
- **Production change-approval, risk-acceptance, regulatory, and incident-response decisions** — the customer's change-management, security, compliance, and SOC functions.

## Connections and authentication used
- **Microsoft Graph** (read for ingest/verify; **write scopes only where a specific remediation requires them**, e.g. policy configuration) and **Az** (for Defender for Cloud plan/coverage remediation). *Write scopes are requested only by the gated remediation step, never by ingest/verify/re-score.*
- The **Microsoft Defender portal** and **Azure portal** for the portal-driven remediations the scripts cannot fully automate.
- Roles: **read-only** (Security Reader / Reader) for ingest/verify/re-score; a **scoped admin** role (e.g. Security Administrator, or the specific product admin) **only** for the apply step, granted per the customer's change process.

## The standard deployment model
> **Assess** the finding (ingest from the report) → **Configure** the remediation and its pilot scope → **Pilot** the change (preview with `-WhatIf`/simulation, then apply to the pilot) → **Validate** by verifying the control and **re-scoring** to prove closure → **Expand** across scope in stages with rollback ready. Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, every change **preview/`-WhatIf` first**.
