# 7. Best Practices — A Defensible FINRA/SEC Program on Microsoft Purview

Operating principles for a control-and-evidence program that survives an examination. Grounded in
Microsoft's public guidance and the **Assess → Design → Configure → Pilot (simulate/test) → Validate →
Expand (enforce)** model.

## Stay in your lane: configure the control, defer the determination
- **You implement and evidence controls; compliance/records/legal decide the rules.** Which obligations apply, retention durations, supervisory scope and lexicons, and whether a configuration satisfies FINRA Rule 4511/3110, SEA Rule 17a-4, or the SEC Marketing/Books-and-Records rules are **their** determinations. Capture them in the `Control Map – FINRA/SEC – Purview` register with named approvers — the register is your defensibility.
- Write findings as "the control is configured as specified and evidenced," never "the firm is compliant."

## Treat regulatory records as one-way doors
- A **regulatory record** label is **immutable and cannot be removed**, and its retention **cannot be shortened or disabled** — by design. **Pilot with a non-regulatory records label first**, prove behavior, and apply the regulatory label only under **explicit compliance sign-off** and on the approved scope.
- Verify the **exact** records/regulatory-records behavior in **your** tenant before wider application; when in doubt, stop — irreversibility is unforgiving.

## Records preservation is (mostly) not retroactive
- Labels and policies preserve **from application forward**. Configure now; every deferred day is history you cannot recreate. This is the strongest argument for building the program before an exam, not during one.
- Know the **17a-4 options**: the amended rule permits both a traditional **WORM** approach and an **audit-trail alternative** — which one your configuration relies on, and whether it meets the rule (including any third-party/undertaking requirements), is a **legal determination**. Verify with counsel.

## Build supervision privacy-first, and separate the roles
- **Communication Compliance reads employees' communications** — build it with **privacy-by-design**: minimize scope to covered persons, enable **pseudonymization** where the tenant supports it, honor employee-notice/works-council obligations, and keep **reviewers strictly separated** from configurers.
- **Always start in test mode.** Prove the policy surfaces the right items to the right reviewers before enforcing, and **never action a real item as part of implementation** — case outcomes are **HR/legal's**.
- Keep conditions/lexicons owned by compliance; you operationalize what they define, you don't invent supervisory criteria.

## Make evidence a first-class deliverable
- An examiner wants **control → configuration → proof**. Generate the `Evidence – FINRA/SEC Controls – Binder` regularly, not just at exam time, so evidence is always current and gaps surface early.
- Retain the `-WhatIf` transcripts, before/after discovery outputs, and sign-offs — the *change history* of the control is itself evidence of a governed program.

## Audit is the evidence layer — keep it on and retained
- Ensure **unified audit logging** stays on (it can be disabled) and that the `Audit Retention – FINRA/SEC Evidence – LongTerm` policy keeps the evidence your compliance function requires, at a verified duration and licensing tier.
- Treat "is auditing on and retaining?" as a **standing monitored control**, caught by the scheduled read-only chain.

## Least-privilege everywhere, reviewed periodically
- Records Management, Communication Compliance (Admin/Analyst/Investigator/Viewer), Audit, and Compliance Manager roles are **distinct and least-privilege**; reserve Global Administrator for one-time enablement. Review membership periodically — access to supervision and records is itself sensitive.

## Pilot every change, keep a rollback (except where you can't)
- Enable, retain, and supervise **pilot-first** in simulation/test/disabled mode; validate with the scorecard before expanding. Non-regulatory labels, retention policies, audit policies, and test supervision policies are reversible — record the exact rollback with every change.
- The one deliberate exception is the **regulatory-records** label: it is *meant* to be irreversible. Its "rollback" is not applying it until sign-off is complete — so gate it hardest of all.

## Operate it as a program, not a project
- Schedule `CMPFINRA-Discovery.ps1` → `CMPFINRA-Validate.ps1` → `CMPFINRA-Report.ps1` on a cadence so drift (a disabled policy, a narrowed scope, a lapsed license, audit turned off) is caught before an examiner finds it, and re-generate the evidence binder ahead of every exam cycle. Hand the register, binder, and runbook to compliance as the standing procedure.
