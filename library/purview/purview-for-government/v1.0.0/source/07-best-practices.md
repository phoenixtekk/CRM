# 7. Best Practices — A Defensible Government Program on Microsoft Purview

Operating principles for a control-and-evidence program that survives a CJIS audit, a CMMC assessment, or an
ITAR review. Grounded in Microsoft's public guidance and the **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)** model.

## Stay in your lane: configure the control, defer the determination
- **You implement and evidence controls; compliance/security/records/legal decide the rules.** Which data is
  CJI/CUI/ITAR, which CMMC level applies, retention durations, ITAR access constraints, and whether a
  configuration satisfies the CJIS Security Policy, CMMC / NIST SP 800-171, or the ITAR are **their**
  determinations. Capture them in `Control Map – Gov – Purview` with named approvers — the register is your
  defensibility.
- Write findings as "the control is configured as specified and evidenced," never "the agency is compliant" or
  "authorized." This solution makes **no certification/ATO claim.**

## Verify everything against YOUR cloud
- GCC, GCC High, and DoD differ from commercial (and from each other) in feature availability, portal paths,
  and PowerShell/Graph endpoints. **Never assume** a capability or path shown here exists in your cloud —
  confirm it, and record your cloud's `-ConnectionUri` / `-Environment` in the runbook.
- ITAR and CUI workloads frequently **require** GCC High or higher. Confirm the tenant is in the required
  cloud **before** relying on any control for those obligations — that placement itself is often a
  determination.

## Treat DLP as high-impact: simulate, then enforce
- **Always create DLP and endpoint DLP in simulation/test mode.** A block set too broadly can halt legitimate
  mission work; a block set too narrowly lets controlled data leave. Run simulation, review matches with
  `INDGOV-Report.ps1`, tune conditions, and only then enforce — on the approved scope, under change control.
- Keep the **conditions and sensitive-info types owned by security/compliance** — you operationalize what they
  define; you don't invent what counts as CJI/CUI/ITAR.
- Endpoint DLP only works on **onboarded devices** with the right licensing/cloud — verify onboarding before
  claiming device egress is controlled.

## Encrypting labels change access — pilot access outcomes first
- An encrypting label binds protection to the file but also **changes who can open it**. For **ITAR**, the
  U.S.-person access constraint is a **legal** requirement, not a default. Pilot each label on non-production
  content, confirm authorized users can open and out-of-scope/external users cannot, and only then broaden the
  publish policy.
- Confirm downstream impact (co-authoring, external sharing, third-party tools) before wide rollout — an
  encrypting label can break workflows if published blind.

## Make evidence a first-class deliverable
- An auditor/assessor wants **control → configuration → proof**. Generate `Evidence – Gov Controls – Binder`
  and the DLP simulation-match summary regularly, not just at assessment time, so evidence is current and gaps
  surface early.
- Retain the `-WhatIf` transcripts, before/after discovery outputs, and sign-offs — the *change history* of
  the control is itself evidence of a governed program.

## Audit is the evidence layer — keep it on and retained
- Ensure **unified audit logging** stays on (it can be disabled) and that `Audit Retention – Gov Evidence –
  LongTerm` keeps the evidence CJIS/CMMC audit-log requirements call for, at a verified duration and licensing
  tier for your cloud.
- Treat "is auditing on and retaining?" as a **standing monitored control**, caught by the scheduled read-only
  chain.

## Least-privilege everywhere, and separate who reads matches/evidence
- Information Protection, DLP Compliance Management, Records Management, Audit, and Compliance Manager roles are
  **distinct and least-privilege**; reserve Global Administrator for one-time enablement. **DLP matches and
  audit evidence can contain controlled data** — restrict who may read them, separate from the configuring
  admin, and review membership periodically.

## Pilot every change, keep a rollback
- Publish labels, run DLP/endpoint DLP, and apply retention **pilot-first** in simulation/test on
  `Gov Pilot – Controlled Data – Stage1`; validate with the scorecard before expanding. Simulation DLP,
  pilot-scoped label policies, retention, and audit policies are reversible — record the exact rollback with
  every change. (Content already encrypted by a label retains protection — verify decryption/access recovery
  in your tenant.)

## Operate it as a program, not a project
- Schedule `INDGOV-Discovery.ps1` → `INDGOV-Validate.ps1` → `INDGOV-Report.ps1` on a cadence so drift (a DLP
  policy back in simulation or disabled, an unpublished label, a lapsed license, audit turned off, a device
  off-boarded) is caught before an assessor finds it, and re-generate the evidence binder ahead of every
  assessment cycle. Hand the register, binder, and runbook to compliance as the standing procedure.
