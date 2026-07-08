# 7. Best Practices — Microsoft Purview: DLP, Sensitivity Labels & Retention

- **Keep the taxonomy small.** Three to five labels people can actually reason about beats a dozen
  nobody uses. Name each label plainly and give it a clear tooltip.
- **Publish before you protect.** Roll labels out with `Label Policy - Sensitivity Taxonomy - All
  Users` to a pilot first; confirm they appear and behave before adding encryption for everyone.
- **Simulate auto-labeling.** Always run an auto-labeling policy in simulation
  (`Auto-Label - Confidential Financial - Pilot`) and review matches before turning it on — it labels
  content at scale and mistakes are visible to users.
- **Audit DLP before you enforce.** This is the single most important practice: run every DLP policy
  in test/audit mode, review the matches, tune out false positives, and only then switch to enforce.
  A blocked-work storm is the fastest way to lose trust in DLP.
- **Tune with confidence levels and instance counts.** Reduce false positives by raising the match
  confidence and requiring a minimum count of sensitive instances rather than a single hit.
- **Name every object by purpose and stage.** Use the `<Purpose> - <Scope> - <Stage>` convention
  (for example rename `DLP Policy - Financial and PII - Audit` to `... - Enforce` at the gate) so the
  portal shows exactly where each policy is in its lifecycle.
- **Pilot retention on a scope first.** Retention deletion is irreversible; validate
  `Retention Policy - M365 Baseline - 5 Year` on `Purview - Pilot Users` before widening, and use
  disposition review for records so nothing is auto-deleted unreviewed.
- **Match retention to a real schedule.** Set durations from a records schedule or legal requirement,
  not a guess; capture the source so the schedule is defensible in an audit.
- **Report coverage regularly.** Track labeled-item and DLP-event coverage with `PURVIEW-Report.ps1`
  and chase gaps (unlabeled sensitive locations, services with no DLP).
- **Document the objects and the rollback.** Record the label taxonomy, policy names, scopes, and the
  rollback (revert DLP to audit; disable a retention policy) for repeatability and change control.
