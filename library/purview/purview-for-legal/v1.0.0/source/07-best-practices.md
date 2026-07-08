# 7. Best Practices — A Defensible Legal Program on Microsoft Purview

Operating principles for a Legal-tailored control-and-evidence program that protects privilege, governs
matter records, and survives an audit or a matter. Grounded in Microsoft's public guidance and the
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** model.

## Stay in your lane: configure the control, defer the determination
- **You implement and evidence controls; legal/records decide the rules.** What is privileged, how matters map to content, retention durations and disposition triggers, and whether a matter is under **legal hold** are **their** determinations. Capture them in the `Control Map – Legal – Purview` register with named approvers — the register is your defensibility.
- Write findings as "the control is configured as specified and evidenced," never "the firm is protected" or "privilege is preserved."

## Legal holds and eDiscovery are legal's — provide the method, not the decision
- **Never create, scope, or release a legal hold** as part of this work. The program **references** hold coverage read-only (`Get-CaseHoldPolicy`) so legal can see it, but hold decisions have legal consequences and belong to the legal function in eDiscovery.
- Coordinate: make sure retention/disposition does not silently dispose of content the legal function needs held — surface the interaction, let legal decide the hold.

## Always pilot DLP in simulation — enforcement blind is worse than nothing
- **Build `DLP – Legal Privileged – Simulate` in test/simulation mode** and review its matches before enforcing. A DLP policy that blocks legal's routine sharing on day one trains people to work around it and can disrupt a live matter.
- Tune for **over-matching** as much as under-matching: legitimate sharing with co-counsel, courts, and clients must have modeled exceptions **before** you switch to Enable. Match criteria (labels, sensitive info types, exceptions) are **legal's determination** — you operationalize what they define.

## Treat encryption labels — and regulatory records — as one-way doors
- An **encryption** sensitivity label can render content unreadable to intended external recipients (co-counsel, courts). Set the decryption/permission scope to **legal's approved design**, pilot with **benign** content, and confirm external-sharing paths still work.
- A **regulatory-records** label is **immutable and cannot be removed**, and its retention **cannot be shortened** — by design. Use it only where the records schedule requires, pilot with a **non-regulatory** label first, and apply it only under **explicit legal/records sign-off**. When in doubt, stop.

## Protection is (mostly) not retroactive
- Labels, DLP, and retention act **from application forward**. Configure now; content that was never labeled or captured is not reached. This is the strongest argument for building the program before a matter or audit, not during one.

## Make evidence a first-class deliverable
- An auditor or opposing party wants **control → configuration → proof**. Generate the `Evidence – Legal Controls – Binder` regularly, not just at audit time, so evidence is always current and gaps surface early.
- Retain the `-WhatIf` transcripts, the DLP **simulation match report**, before/after discovery outputs, and sign-offs — the *change history* of the control is itself evidence of a governed program.

## Audit is the evidence layer — keep it on and retained
- Ensure **unified audit logging** stays on (it can be disabled) and that `Audit Retention – Legal Evidence – LongTerm` keeps the evidence your legal function requires — label changes, DLP matches, file/mail activity — at a verified duration and licensing tier.
- Treat "is auditing on and retaining?" as a **standing monitored control**, caught by the scheduled read-only chain.

## Least-privilege everywhere, and keep eDiscovery with legal
- Information Protection, DLP, Records/Retention Management, Audit, and Compliance Manager roles are **distinct and least-privilege**; reserve Global Administrator for one-time enablement. Keep **eDiscovery/legal-hold roles with the legal function** — access to holds and case content is legally sensitive. Review membership periodically.

## Pilot every change, keep a rollback (except where you can't)
- Publish labels, run DLP, and trial retention **pilot-first** in simulation/test/disabled mode; validate with the scorecard before expanding. Label policies, DLP-in-simulation, non-regulatory retention labels, and audit policies are reversible — record the exact rollback with every change.
- The deliberate exceptions are the **encryption** behavior (already-encrypted content stays encrypted) and the **regulatory-records** label (meant to be irreversible) — pilot both with benign content and gate the regulatory label hardest of all.

## Operate it as a program, not a project
- Schedule `INDLEGAL-Discovery.ps1` → `INDLEGAL-Validate.ps1` → `INDLEGAL-Report.ps1` on a cadence so drift (a DLP policy slipped back to test, an unpublished label, a narrowed retention scope, a lapsed license, audit turned off) is caught before an auditor or opponent finds it, and re-generate the evidence binder ahead of audits and matters. Hand the register, binder, and runbook to legal/records as the standing procedure.
