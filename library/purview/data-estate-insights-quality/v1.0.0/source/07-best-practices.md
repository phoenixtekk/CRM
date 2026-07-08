# 7. Best Practices — Data Estate Insights & Data Quality (Microsoft Purview)

- Baseline before you tune. Capture `DGI-Insights-Baseline` first, then measure every change against
  it. A quality or coverage number only means something relative to where you started — an unbaselined
  estate has no story to tell leadership.
- Pilot data-quality scoring on one data product. Data Quality reads live data and consumes compute;
  prove the rules, the score, the runtime, and the cost on `DGI-DataProduct-Pilot` before you point
  scoring at the estate or schedule it. One-time first, scheduled only after a scope validates.
- Measure critical data elements, not everything. Rules bind to the columns that matter
  (`DGI-CDE-<name>`). Scoring every column produces noise and cost; a small, agreed CDE set per data
  product produces a score the business will actually act on.
- Thresholds are the owner's call, not a technical default. Let the data owner set the pass threshold
  per dimension (completeness ≥ 98%, etc.). The solution measures against the threshold; it does not
  decide what "good" is — that is a business determination.
- One rule, one dimension, one intent. Name rules `DGI-DQ-Rule-<Dimension>-<CDE>` so a score maps to a
  clear question (is `Email` conformant? is `CustomerID` unique?). Compound rules produce scores nobody
  can act on.
- Never put a secret in a rule, scan, or script. Use the account's managed identity or an Azure Key
  Vault–stored credential for the data-quality connection, granted least read on the source — this is
  both the secure pattern and what keeps the provided scripts secret-free.
- Treat a data-quality scan as reading real data. Unlike a classification scan, DQ profiling reads
  actual values. Run it least-privilege, on a bounded scope, with the owner's privacy agreement — and
  record that it reads live data so nobody is surprised.
- The score is evidence, not a verdict. The solution produces a measured score; whether a low score is
  a compliance issue and what remediation follows is the owner's/steward's determination. Keep that
  separation explicit so a red score is never mistaken for a compliance ruling.
- Wire health tracking so coverage doesn't rot. Use `DGINSIGHT-Scope-Health.ps1` (and health controls
  where available) to catch data products without owners, CDEs without rules, and stale scans — a
  governed estate degrades quietly without a coverage check.
- Verify licensing, preview status, and portal paths as you go. Data Estate Insights / analytics /
  Health management and Data Quality are evolving and consumption-/plan-gated, and parts may be in
  preview. Confirm current availability, naming, API versions, and pricing in Microsoft's docs and the
  portal rather than assuming a path, an endpoint, or a price is permanent.
