# 7. Best Practices — A Defensible FERPA Program on Microsoft Purview

Operating principles for a control-and-evidence program that survives an audit. Grounded in Microsoft's
public guidance and the **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand
(enforce)** model.

## Stay in your lane: configure the control, defer the determination
- **You implement and evidence controls; compliance/registrar/records/legal decide the rules.** What is an education record, who is an eligible student or a school official with legitimate educational interest, which disclosures are permitted, retention durations, and whether a configuration satisfies FERPA (34 CFR Part 99) are **their** determinations. Capture them in the `Control Map – FERPA – Purview` register with named approvers — the register is your defensibility.
- Write findings as "the control is configured as specified and evidenced," never "the institution is FERPA-compliant." This solution makes **no certification claim**.

## Classify first — you can't protect what you can't see
- Education-record protection stands on **classification**. Invest in the right **sensitive information types / trainable classifiers** and the **sensitivity label** before DLP and retention, so those controls have a reliable signal to key off.
- Tune classification in the **pilot**: measure false positives/negatives on benign test content and refine before enforcement. Match-logic adequacy is a compliance/registrar decision — you operationalize what they define.

## Treat DLP as a one-way lever — pilot in simulation, enforce under sign-off
- An enforced DLP policy can **block legitimate educational work** if mis-scoped. **Always build `DLP – FERPA Education Records – Simulate` in simulation mode**, validate matches and false-positive rate, encode the **permitted-disclosure exceptions** (to the student, to school officials, under consent), and switch to enforce only under **explicit compliance/registrar sign-off** on the approved scope.
- Choose the enforcement action deliberately — **block, block-with-override, or notify** — and set clear **policy tips** so users understand why an action fired. Keep a documented rollback (revert to simulation) with every enforcement change.

## Protection is (mostly) not retroactive
- Labels, DLP, and retention act **from application/enable forward**. Configure now; deferring leaves education-record exposure and history you cannot recreate. This is the strongest argument for building the program before an audit, not during one.

## Make evidence a first-class deliverable
- An auditor wants **control → configuration → proof**. Generate the `Evidence – FERPA Controls – Binder` regularly, not just at audit time, so evidence is always current and gaps surface early.
- Retain the `-WhatIf` transcripts, before/after discovery outputs, and sign-offs — the *change history* of the control is itself evidence of a governed program.

## Audit is the access-evidence layer — keep it on and retained
- Ensure **unified audit logging** stays on (it can be disabled) and that the `Audit Retention – FERPA Evidence – LongTerm` policy keeps the evidence of who accessed/disclosed education records, at a verified duration and licensing tier.
- Treat "is auditing on and retaining?" as a **standing monitored control**, caught by the scheduled read-only chain.

## Least-privilege everywhere, reviewed periodically
- Information Protection, DLP, Records/Retention Management, Audit, and Compliance Manager roles are **distinct and least-privilege**; reserve Global Administrator for one-time enablement. Review membership periodically — access to student-record controls is itself sensitive.

## Pilot every change, keep a rollback
- Publish labels, enable DLP (simulation), apply retention, and extend audit **pilot-first** in simulation/test/disabled mode; validate with the scorecard before expanding. Every control here is reversible — record the exact rollback with every change, and never move DLP to enforcement outside the pilot without sign-off.

## Operate it as a program, not a project
- Schedule `CMPFERPA-Discovery.ps1` → `CMPFERPA-Validate.ps1` → `CMPFERPA-Report.ps1` on a cadence so drift (a DLP policy reverted to simulation or disabled, a narrowed label scope, a lapsed license, audit turned off) is caught before an auditor finds it, and re-generate the evidence binder ahead of every audit cycle. Hand the register, binder, and runbook to compliance/registrar as the standing procedure.
