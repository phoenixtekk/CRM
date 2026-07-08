# 7. Best Practices — Microsoft Purview for Financial Services

- **Defer the determinations, own the mechanism.** Configure the labels, DLP, retention/records, and
  supervision precisely — but take the record set, retention periods, regulatory-record declarations,
  and the supervision scheme from **compliance, records, privacy, and legal**. Capture the source for
  each so the configuration is defensible in an exam.
- **Keep the taxonomy small and FS-meaningful.** Three to five labels people can reason about beats a
  dozen nobody uses. Make `FS Confidential (NPI/GLBA)` and `FS Restricted (MNPI)` distinct and give
  each a plain tooltip so users know NPI from MNPI.
- **Simulate auto-labeling for NPI.** Always run `Auto-Label - FS NPI (GLBA) - Simulation` in
  simulation and review matches before turning it on — it labels customer data at scale and mistakes
  are visible to users.
- **Audit DLP before you enforce.** The single most important practice: run every DLP policy in
  test/audit, review matches, tune out false positives, then enforce. A blocked-work storm on
  advisers/traders is the fastest way to lose trust in DLP.
- **Tune with confidence levels and instance counts.** Reduce false positives on financial
  sensitive-info types (bank account, routing, SSN, card) by raising match confidence and requiring a
  minimum instance count rather than a single hit.
- **Treat Preservation Lock as one-way.** A locked retention policy **cannot** be shortened, unscoped,
  or disabled — it is the immutability mechanism Microsoft positions for SEC 17a-4(f) / FINRA 4511(c) /
  CFTC 1.31, but there is **no rollback**. Lock **only** after records/legal sign-off, never during the
  pilot, and never to "tidy up."
- **Separate the communication-compliance roles.** Admin (configure), Analyst (triage pseudonymized
  alerts), Investigator (resolve) must be **different people** — privacy-by-design and role separation
  protect both employees and the firm. Keep pseudonymization on and start the review percentage low.
- **Name every object by purpose and stage.** Use `<Purpose> - <Scope> - <Stage>` (e.g. rename
  `DLP Policy - FS NPI and Financial - Test` to `... - Enforce` at the gate) so the portal shows where
  each policy sits in its lifecycle.
- **Report coverage regularly.** Track labeled-item, DLP-event, and DLP service coverage with
  `FS-Purview-Report.ps1` and chase gaps (unlabeled NPI locations, workloads with no DLP, mailboxes
  outside the retention policy).
- **Verify licensing before you promise a capability.** Auto-labeling at rest, endpoint DLP, records
  management, communication compliance, and Audit (Premium) are E5 / E5 Compliance features and the
  portal evolves — confirm with `FS-Purview-Discovery.ps1` and **verify your tenant** rather than
  assuming a node exists.
- **Document the objects and the rollback.** Record the label taxonomy, policy names, scopes, and the
  rollback (revert DLP to audit; disable the unlocked retention policy; disable the supervision policy)
  — and note explicitly that a **locked** retention policy has no rollback.
