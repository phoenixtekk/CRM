# 7. Best Practices — Microsoft Purview ISO 27701 Compliance Program

- **Extend the ISMS, don't rebuild it.** ISO 27701 is the privacy extension of ISO 27001 — layer the
  PIMS assessment on the existing ISO 27001 assessment and **reuse** existing labels, DLP, and retention
  controls rather than creating parallel ones that conflict.
- **Record controller vs processor per activity.** ISO 27701's obligations differ by role — capture the
  determination in `ISO 27701 Scope – Record` and map the applicable controls accordingly. The
  determination is privacy/legal's; capture it, don't invent it.
- **Map every in-scope clause to a Purview control — and a piece of evidence.** `ISO 27701 Control Map –
  Clauses` plus `ISO 27701 Evidence – Register` are the heart of the program. Configuration without
  evidence is not a PIMS.
- **Detect PII accurately.** Use the built-in PII sensitive-information types and add a custom SIT for
  organization-specific PII; accurate detection is what makes labels, DLP, and DSRs trustworthy.
- **Simulate auto-labeling.** Always run `Auto-Label - PII - Pilot` in simulation and review matches
  before turning it on — it labels PII at scale and mistakes are user-visible.
- **Audit DLP before you enforce.** Run `DLP Policy - PII (PIMS) - Audit` in test mode, review matches,
  tune out false positives, and only then enforce. A blocked-work storm is the fastest way to lose trust
  in DLP.
- **Retention limitation with disposition review.** Set PII retention from the schedule (a records/legal
  determination), not a guess; use disposition review so nothing is auto-deleted unreviewed. Deletion is
  irreversible.
- **Wire and test a real DSR.** A PIMS must actually answer PII-principal rights — run a **test DSR** end
  to end and record it. Keep the produce/correct/erase **decision** with privacy/legal; the tooling
  locates and produces.
- **Separate privacy-sensitive roles.** Hold Insider Risk / Communication Compliance / Priva roles apart
  from configuration roles; capture `ISO 27701 Roles – Separation Evidence`. Separation of duties is a
  control.
- **Name every object by purpose and stage.** Use `<Purpose> - <Scope> - <Stage>` (rename `... - Audit`
  to `... - Enforce` at the gate) so the portal shows exactly where each control sits.
- **Evidence continuously, ahead of certification.** Work the mapped improvement actions in Compliance
  Manager as you configure, and refresh evidence on a cadence before management review — but remember the
  **certification decision is the external auditor's/organization's, not this solution's.**
- **Verify licensing and cloud.** Advanced controls, the ISO 27701 assessment template, and Priva need
  E5 / E5 Compliance / Priva licensing — **verify your licensing/tenant** rather than assuming a feature
  is present.
- **Document the objects and the rollback.** Record the control map, label/policy names, scopes, DSR
  method, and the rollback (revert DLP to audit; auto-labeling to simulation; disable a retention
  policy) for repeatability and change control.
