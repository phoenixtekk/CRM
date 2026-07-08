# 7. Best Practices — Microsoft Purview GDPR Compliance Program

- **Map before you build.** Start from `GDPR Control Map – Articles` — decide which Purview control
  evidences each in-scope obligation *first*, so every configuration traces to a GDPR article and no
  obligation is left unmapped. Evidence once, score many via Compliance Manager's shared controls.
- **Keep determinations with the business.** Applicability, lawful basis, ROPA (Art. 30) content,
  DPIA (Art. 35) outcomes, retention schedules, and erasure decisions are **compliance/privacy/legal**
  calls. Configure the method and collect the proof; never let the tool make the ruling.
- **Separate the sensitive roles.** Give Insider Risk and Communication Compliance to **different**
  owners than the general operator, and keep everything least-privilege. The separation is both a
  control and GDPR accountability evidence — capture it in `GDPR Roles – Separation Evidence`.
- **Simulate and audit before you enforce.** Run auto-labeling in **simulation** and every DLP policy
  in **test/audit** first; review matches, tune false positives with confidence levels and instance
  counts, and only then promote to enforce. A blocked-work storm is the fastest way to lose trust.
- **Name every object by purpose and stage.** Use `<Purpose> – <Scope> – <Stage>` (rename
  `DLP Policy - EU Personal Data - Audit` to `... - Enforce` at the gate) so the portal shows exactly
  where each control is in its lifecycle and the docs, scripts, and evidence all agree.
- **Wire the DSR method before a request arrives.** Decide Priva SRR vs eDiscovery/content search up
  front, write the intake→locate→review→decide→produce runbook, and run a **test DSR** so the
  one-month clock (Art. 15/17/20) never starts on an untested process.
- **Retention from a schedule, not a guess.** Set `Retention Label - Personal Data - Storage
  Limitation` durations from the records/legal schedule, use **disposition review** so nothing is
  auto-deleted unreviewed, and record the schedule source so storage-limitation (Art. 5(1)(e)) is
  defensible.
- **Keep audit on and evidence current.** Unified audit logging underpins accountability (Art. 5(2))
  and breach investigation (Art. 33). Refresh `GDPR Evidence – Register` on a cadence with
  `GDPR-EvidenceReport.ps1` so the posture report reflects reality, not a point-in-time snapshot.
- **Verify licensing before assuming a gap.** The GDPR template, premium controls, and Priva SRR are
  plan-/tenant-gated and the portal evolves — if a capability is absent, confirm the plan with
  `GDPR-Discovery.ps1` and Requirement 2.1 before concluding the tenant lacks it.
- **Re-score on a schedule and after change.** Re-run the assessment, re-test eligible actions, and
  refresh evidence periodically and after any tenant change, so `GDPR Posture – Report` stays audit-
  ready rather than a one-off deliverable.
