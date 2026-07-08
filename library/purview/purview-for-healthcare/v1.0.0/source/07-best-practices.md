# 7. Best Practices — Microsoft Purview for Healthcare (HIPAA/PHI)

- **Keep the PHI taxonomy small.** Three to five labels clinicians and staff can actually reason about
  beats a dozen nobody uses. Name each label plainly (`Confidential - PHI`, `Highly Confidential - PHI
  Restricted`) and give it a clear tooltip.
- **Apply minimum-necessary in the label permissions.** Scope `Highly Confidential - PHI Restricted`
  to a **named care-team / role group**, not all users — the label's encryption permissions are where
  the HIPAA minimum-necessary principle becomes a technical control.
- **Pilot encryption against clinical apps first.** Label encryption can break legacy EHR/PACS
  integrations and must never impede continuity of care. Test the inventoried clinical apps
  (Requirement 2.6) and agree emergency ("break-glass") access **before** enforcing encryption broadly.
- **Simulate PHI auto-labeling.** Always run `Auto-Label - PHI Health Records - Pilot` in simulation
  and review matches before turning it on — it labels PHI at scale and mistakes are visible to users.
- **Audit DLP before you enforce.** The single most important practice: run every DLP policy in
  test/audit, review matches, tune out false positives (referral, billing, care-coordination flows),
  and only then enforce. Erroneously blocking clinicians is a **patient-care risk**, not just a help
  desk ticket. Prefer **block-with-override** so a justified clinical action can proceed.
- **Tune with confidence levels and instance counts.** Reduce false positives by raising match
  confidence and requiring a minimum count of PHI instances rather than a single hit.
- **Name every object by purpose and stage.** Use `<Purpose> - <Scope> - <Stage>` (rename
  `DLP Policy - PHI HIPAA - Audit` to `... - Enforce` at the gate) so the portal shows exactly where
  each policy sits in its lifecycle — useful evidence in a HIPAA audit.
- **Set retention from the records schedule, never a guess.** Medical-record retention is a
  **records/legal determination** (state law, often longer for minors). Implement the schedule your
  records/privacy function supplies; capture the source so the schedule is defensible. Keep the
  HIPAA-documentation 6-year retention (§164.316) distinct from clinical-record retention.
- **Use disposition review for PHI records.** Retention disposal is irreversible; route records to
  disposition review so PHI is never auto-deleted unreviewed, and pilot on `Purview - PHI Pilot Users`
  before widening.
- **Keep insider-risk and communication-compliance strictly role-separated.** These are HR/privacy
  sensitive — apply privacy-by-design and pseudonymization where available, and **defer case outcomes
  to HR/legal**. This solution provides the technical method and evidence, not the determination.
- **Report coverage regularly and keep it as HIPAA evidence.** Track PHI labeled-item and DLP-event
  coverage with `PHI-Report.ps1`, chase gaps (unlabeled PHI locations, services with no DLP), and
  retain the reports as part of your compliance documentation.
- **Document the objects and the rollback.** Record the PHI taxonomy, policy names, scopes, the
  records-schedule source, and the rollback (revert DLP to audit; disable a retention policy) for
  repeatability and change control.
