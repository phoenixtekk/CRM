# 7. Best Practices — A Defensible FedRAMP Program on Microsoft Purview

Operating principles for a control-and-evidence program that survives an assessment. Grounded in
Microsoft's public guidance and the **Assess → Design → Configure → Pilot (simulate/test) → Validate →
Expand (enforce)** model.

## Stay in your lane: configure the control, defer the determination
- **You implement and evidence controls; security/compliance decide the rules.** Which FedRAMP **baseline** applies (Low/Moderate/High), which **NIST 800-53** controls are in scope, whether a Purview object satisfies a control, and whether the tenant supports an **ATO** are **their** determinations. Capture them in the `Control Map – FedRAMP – Purview` register with named approvers — the register is your defensibility.
- Write findings as "the control is configured as specified and evidenced," never "the tenant is FedRAMP-compliant / authorized." **This solution asserts no certification or ATO.**

## Treat DLP enforcement as a one-way risk — simulate first
- Purview **DLP can block real user actions**. **Always build and validate DLP in test/simulation mode first** (`-Mode TestWithoutNotifications` / `TestWithNotifications`), confirm it matches the right controlled data with acceptable false positives, and switch to **`Enable` (enforce) only after the pilot passes and security/compliance sign off**.
- Review the DLP **simulation/overview** results before enforcing — tune conditions and exceptions in test so enforcement day is uneventful.

## Encryption changes access — pilot it deliberately
- A sensitivity **label with encryption** changes who can open controlled content and can affect downstream automation, guest access, and offboarding. Pilot on **benign content** first, confirm recovery/super-user and offboarding behavior, and understand the removal implications **before** wider application.
- Keep the label taxonomy minimal and named — `Protect – FedRAMP Controlled – Confidential` — so its meaning is unambiguous in the control map.

## Make evidence a first-class deliverable
- An assessor wants **control → configuration → proof**. Generate the `Evidence – FedRAMP Controls – Binder` regularly, not just at assessment time, so evidence is always current and gaps surface early.
- Retain the `-WhatIf` transcripts, before/after discovery outputs, and sign-offs — the *change history* of the control is itself evidence of a governed program.

## Audit is the AU evidence layer — keep it on and retained
- Ensure **unified audit logging** stays on (it can be disabled) and that the `Audit Retention – FedRAMP Evidence – LongTerm` policy keeps the evidence your compliance function requires for the baseline, at a verified duration and licensing tier.
- Treat "is auditing on and retaining?" as a **standing monitored control**, caught by the scheduled read-only chain.

## Track it in Compliance Manager against the FedRAMP template
- Use the **FedRAMP Moderate / High assessment template** in Compliance Manager as the single place improvement actions are tracked and scored, and cross-link each action to the implementing Purview object and its evidence. Baseline choice and template applicability are **security/compliance's** determination.

## Least-privilege everywhere, reviewed periodically
- Information Protection, DLP Compliance Management, Records/Retention, Audit, and Compliance Manager roles are **distinct and least-privilege**; reserve Global Administrator for one-time enablement. Review membership periodically — least-privilege is itself a FedRAMP (AC) expectation.

## Pilot every change, keep a rollback
- Enable, protect, and detect **pilot-first** in simulation/test/disabled mode; validate with the scorecard before expanding. Labels (pre-encryption), test-mode DLP, retention policies, and audit policies are reversible — record the exact rollback with every change. The consequential steps — **DLP enforcement** and **encryption application** — are gated behind explicit sign-off.

## Operate it as a program, not a project
- Schedule `CMPFEDRAMP-Discovery.ps1` → `CMPFEDRAMP-Validate.ps1` → `CMPFEDRAMP-Report.ps1` on a cadence so drift (a DLP policy disabled, a label unpublished, a narrowed scope, a lapsed license, audit turned off) is caught before an assessor finds it, and re-generate the evidence binder ahead of every assessment cycle. Hand the register, binder, and runbook to security/compliance as the standing procedure.
