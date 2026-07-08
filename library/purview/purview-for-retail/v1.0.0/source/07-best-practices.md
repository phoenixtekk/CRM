# 7. Best Practices — Microsoft Purview for Retail

- **Keep cardholder data out of M365 — don't try to make M365 PCI-compliant.** The right retail posture
  is that Exchange, SharePoint, OneDrive, Teams, and endpoints stay **out** of PCI-DSS scope. Use DLP to
  **block PAN** from landing there; keep the certified cardholder-data environment separate. Purview
  reduces the chance of stray PAN, it does not certify M365 for cardholder data.
- **Audit DLP before you enforce.** The single most important practice: run both the PCI and PII
  policies in test/audit, review the matches, tune out false positives (order numbers that resemble a
  PAN, internal PII in HR content), and only then switch to block. A false block at a checkout or
  fulfilment desk is the fastest way to lose trust in DLP.
- **Simulate auto-labeling first.** Run `Auto-Label - PCI Cardholder Data - Simulation` and treat the
  results as your **PAN discovery map** — it shows where cardholder data is actually sitting in M365 so
  it can be removed and the scope kept small. Only turn it on after the simulation is clean.
- **Block PAN outright; override PII by exception.** Cardholder data generally has no legitimate reason
  to move through M365 — block it. Customer PII does move for legitimate retail operations — prefer
  block-with-override (with business justification) so staff aren't stopped from doing real work.
- **Minimize payment-data retention.** PCI-DSS favors keeping cardholder data to a minimum. Set
  `Retention Label - Payment Records - 18 Month` (or the compliance-approved period) short and dispose
  defensibly — over-retention of payment data is itself a finding.
- **Keep the taxonomy small and retail-legible.** Four labels store, e-commerce, and head-office staff
  can reason about beats a dozen nobody uses. Name each plainly and give a clear tooltip; make the
  `Cardholder Data - Restricted` label unmistakable.
- **Tune with confidence levels and instance counts.** Reduce false positives by raising the match
  confidence on the Credit Card Number SIT and requiring a minimum instance count rather than a single
  hit.
- **Name every object by purpose and stage.** Use `<Purpose> - <Scope> - <Stage>` (for example rename
  `DLP Policy - Retail PCI Cardholder Data - Test` to `... - Enforce` at the gate) so the portal shows
  exactly where each policy is in its lifecycle.
- **Pilot retention before it deletes.** Retention deletion is irreversible; validate
  `Retention Policy - Retail Baseline - 5 Year` on `Purview - Retail Pilot` first, and use disposition
  review for records so nothing is auto-deleted unreviewed.
- **Evidence PCI controls continuously.** Track the classification, DLP, and retention controls in
  `Assessment - PCI-DSS - Retail Baseline` and report coverage with `RETAIL-Report.ps1` — auditors want
  evidence the controls operate, not just that they exist.
- **Defer the determinations.** PCI scope, applicable requirements, records schedules, and retention
  periods are compliance/QSA/records/legal decisions. Configure and evidence; don't decide.
