# Executive Summary — Microsoft Purview HIPAA Compliance Program

## The problem
"Are we HIPAA-compliant?" has no defensible answer without a **scored, control-by-control map** and the
**evidence** to back it. HIPAA's Security Rule is a set of Administrative, Physical, and Technical
safeguards; left unmapped, the organization's posture is a guess — a compliance gap and a data-risk
exposure that surfaces at the worst time, in an OCR investigation, a business-associate audit, or a breach.

## The solution
A **HIPAA-aligned compliance program built inside Microsoft Purview**. It maps the HIPAA Security Rule
safeguards (with HITECH/Breach-Notification and, where scoped, **HITRUST CSF**) to the Microsoft Purview
technical controls that satisfy them — **Audit**, **sensitivity labels**, **DLP for ePHI**, **retention**,
**sensitive information types**, and, where scoped, **Insider Risk** and **Communication Compliance** — and
measures the whole program with **Compliance Manager**. The result is a **Compliance Score**, a safeguard →
control map, an improvement-action plan with owners, and an **audit-ready evidence register**: configured,
piloted where high-impact, validated, and defensible. It uses only the Microsoft Purview portal, Security &
Compliance PowerShell, and Microsoft Graph — no third-party tooling.

## How it works
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.** Baseline the posture and
role/licensing readiness; design the assessment, ePHI scope, and safeguard map with the HIPAA officers;
assign least-privilege separated roles; create the HITECH pilot assessment and build the action plan and
evidence register; enable automatic testing where eligible; validate the technical evidence behind each
safeguard — piloting any new high-impact control in simulation/test first; then expand to the full program
and run a maintenance cadence, leaning on shared controls so you **evidence once and score many**.

## What you get
- A **scored HIPAA program** in Compliance Manager with a safeguard → Purview control map.
- An **auditor-ready evidence register** — owner, status, test date, and proof per safeguard.
- **Least-privilege role separation** proven and snapshotted.
- **Five PowerShell tools** (read-only or `-WhatIf` by default; no secrets) for discovery, plan/evidence
  structuring, technical validation, posture reporting, and role scope.
- Full documentation: requirements, step-by-step implementation with pass/fail gates and rollback, a
  testing guide, troubleshooting, and best practices.

## The boundary (why this is honest)
Compliance Manager **measures; it does not enforce**. Whether a safeguard **applies**, how each
**addressable** specification is met, the outcome of your **risk analysis**, and whether the evidence
**satisfies** the obligation are **compliance, privacy, and legal determinations** — this program provides
the technical method and the proof, not the ruling. Premium templates and several controls are
**E5 / E5 Compliance-gated**; availability is verified against your licensing, never assumed. High-impact
technical changes are piloted in **simulation/test** under change control.

## Bottom line
Meet HIPAA with a Purview-backed program — control mapping, configured controls, and audit evidence —
delivered, validated, and defensible in Microsoft Purview, at a fraction of the cost of a bespoke
consulting engagement.
