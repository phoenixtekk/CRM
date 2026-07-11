# 7. Best Practices — Remediation Playbook for Defender Security Optimization Assessments

Field-proven guidance for remediating safely and proving the gaps actually closed.

## Preview before you touch anything
- Always run the remediation in **`-WhatIf` / simulation** first and read exactly what would change. If a remediation cannot be previewed, do not apply it. Preview is free and catches surprises before they hit users.

## Pilot before you enforce
- Apply to a small, **named pilot scope** first (pilot group, one subscription, a test policy). For monitor-capable controls (Conditional Access App Control session/access, ASR rules, DLP), run in **monitor/audit** mode, watch, then move to **enforce** only when the pilot is clean.
- Keep a **break-glass account excluded** from every access/CA/session/RBAC tightening — this is the single most important habit; it prevents a bad change from locking everyone out.

## Change under approval, on the customer's authority
- **Production change-approval, risk-acceptance, and remediation priority are the customer's decisions.** The playbook supplies the technical fix; it does not authorize changing production. Disruptive controls and response actions are **approval-gated** — require the explicit confirmation.
- Grant the apply role **just-in-time (PIM)**, scoped and time-bound — never remediate from standing Global Admin.

## Re-score is the proof, not the apply
- A change applied is not a gap closed. **Re-run the relevant assessment score** and show the domain/overall score rise versus the pre-change baseline. Allow warm-up — Secure Score and Defender assessments take time to reflect a change.
- If a verified change does not move the score, the change may not affect the scored control — investigate before claiming closure.

## Keep read and write separated
- Ingest, verify, and re-score run **read-only** (Security Reader / Reader). Only `SOAREM-Remediate.ps1 -Apply` needs write. This separation preserves the audit story: everything except the deliberate apply changed nothing.

## Track everything for audit
- Record what changed, when, by whom, the monitor→enforce stage, and the before/after score in the **evidence report**. Store it securely (R7 / Global Requirements G7). This is what proves the backlog closed.

## Remediate by risk, in stages
- Work the highest-risk findings first (the report already ranks them), but remediate **one category at a time** through the full loop so you can attribute a score movement to a specific fix.

## Know when to hand off to a deeper solution
- A single finding-fix is not a product build-out. If a finding is really a **whole dark pillar** or a large gap, point to the deeper solution (e.g. *Defender XDR Unified Onboarding*, *Defender for Cloud CSPM & Secure Score Remediation*, *EOP/MDO mail hygiene*, *Cloud App DLP*) rather than forcing it through a single remediation.

## Where to go next (adjacent catalog areas)
- **Security Optimization Assessments** (Cloud Apps / Cloud / Suite-XDR / Endpoint / Identity / Office 365) — the read-only assessments that produce the backlog this playbook closes; re-run them to trend.
- **The product onboarding/optimization solutions** — for large gaps a single remediation cannot cover.
- **SOC Onboarding (Sentinel + Defender XDR)** and **Threat Hunting (KQL)** — to operationalize monitoring once the posture is remediated.
