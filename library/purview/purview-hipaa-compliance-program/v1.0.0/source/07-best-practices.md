# 7. Best Practices — Microsoft Purview HIPAA Compliance Program

Operating principles for running a defensible, low-drama HIPAA program in Microsoft Purview. They extend
`global-requirements-purview.md` and the model **Assess → Design → Configure → Pilot (simulate/test) →
Validate → Expand**.

## Program & governance
- **The program measures; the determinations stay with your officers.** Compliance Manager scores and
  evidences; **applicability, required-vs-addressable choices, the risk-analysis outcome, and evidence
  adequacy** stay with the HIPAA **Security Officer**, **Privacy Officer**, and compliance/legal. Keep
  that boundary explicit in every artifact so a technical status is never mistaken for a compliance
  ruling.
- **Anchor to the risk analysis (§164.308(a)(1)).** The Security Rule requires a risk analysis; the
  Purview control map should trace back to it. Record the risk-analysis reference in `HIPAA Scope –
  Record` so each safeguard's presence is justified, not arbitrary.
- **Name the safeguard on every action.** Every improvement action carries its **mapped HIPAA safeguard**
  (§164.308/310/312/314/316) so the score reads as a HIPAA statement, not a generic checklist.
- **Evidence once, score many.** Lean on **shared/control mapping** — implement audit, MFA, DLP, labels,
  and retention once and let Compliance Manager credit them across HITECH, HITRUST, NIST, and your
  internal baseline. Track the *gap* between frameworks, not the overlap.

## Configuration discipline
- **Least-privilege, separated roles — always.** Administrators separated from contributors; the
  Security/Privacy Officer and auditors **read-only**. The evidence is only defensible if access to it was
  governed. Re-check with `CMPHIPAA-Discovery.ps1` after any joiner/leaver.
- **Pilot one assessment before the program.** Validate `HIPAA Assessment – HITECH – Pilot` end-to-end —
  mapping, ownership, evidence, automatic testing — before creating the production assessments. It proves
  the model and prevents an unmanageable action backlog.
- **Pilot every high-impact technical control in simulation/test first.** When a mapped action needs a
  *new* DLP for ePHI, a label with encryption, a retention policy, or tighter Conditional Access, deploy
  it in **simulation/test/disabled** mode under its own change control before enforcement — then evidence
  it here. Never switch on a high-impact control blind because the score wants a point.
- **Safe automation defaults.** The write-capable scripts default to **`-WhatIf`**; read the dry-run
  before `-Commit`. Never embed credentials — the scripts use interactive modern-auth sign-in.

## Evidence & audit-readiness
- **Automatic testing where eligible, manual evidence everywhere else — and know which is which.** Enable
  automatic testing for the technical safeguards it can read; for administrative/physical safeguards
  (training, BAAs, facility controls, policies) attach **manual** evidence with an owner and a date. A
  mixed record with a clear split prevents a false sense of coverage.
- **No false passes.** An action is **Implemented/Passed** only with proof. If `CMPHIPAA-Validation.ps1`
  shows the underlying control is absent, the safeguard scores as not-implemented — an inflated HIPAA
  score is worse than a low one in an OCR investigation.
- **The portal is authoritative; the scripts support it.** The score, assessments, and evidence store
  live in the **Purview portal**. Treat `HIPAA Posture – Report` as a management rollup, and export the
  authoritative record from Compliance Manager for auditors.
- **Keep the evidence current.** Re-test and re-evidence on a cadence; a year-old audit-config export is
  weak evidence. Schedule `CMPHIPAA-Report.ps1` and drive the annual **evaluation** (§164.308(a)(8)).

## HR/privacy-sensitive controls (Insider Risk & Communication Compliance)
- **Privacy-by-design, strict role separation, outcomes deferred.** Where the program maps a
  security-incident/monitoring safeguard to **Insider Risk Management** or **Communication Compliance**,
  configure them **privacy-first** (pseudonymization where available), separate the reviewer role, and
  defer all **case actions/outcomes** to HR/legal. This program evidences that the *capability* exists —
  never a case decision.

## Lifecycle & maintenance
- **Watch template and regulation updates.** Microsoft updates Compliance Manager templates; HIPAA/HITRUST
  guidance evolves. Review updates on a cadence and re-map affected safeguards.
- **Review owners on joiners/leavers.** Reassign action ownership and re-check role separation whenever
  the Security/Privacy Officer or an action owner changes.
- **Narrow scope safely.** Any assessment can be removed in the portal without touching tenant
  configuration; scope can be narrowed at any time. Nothing in this program enforces on the tenant, so
  rolling back the *measurement* is non-destructive — but do not remove the underlying technical controls
  that other frameworks also rely on.
