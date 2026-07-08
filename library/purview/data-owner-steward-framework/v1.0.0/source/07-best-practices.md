# 7. Best Practices — Data-Owner & Steward Framework (Microsoft Purview)

- **Exactly one Accountable party per activity — no exceptions.** The single most common failure of a
  RACI is two people sharing accountability, which is the same as nobody owning it. Every activity row
  names exactly one A; if you cannot name one, the activity has no owner and the gap is real.
- **Separate the Data Owner from the Data Custodian.** The business **Data Owner** decides intent
  (classification, retention, access); the IT/compliance **Custodian / Control Owner** operates the
  control (the label, the DLP policy, the retention policy). Conflating them is how "IT owns compliance"
  — a known anti-pattern — creeps back in. Name both.
- **Assign from least privilege, not from Global Admin.** Add stewards to the specific built-in role group
  or governance-domain role their function needs; reserve Global Administrator for the rare tenant-wide
  action. Broad admin "to get unblocked" undermines the accountability you are building.
- **Keep the sensitive roles named, minimal, and separate.** Insider Risk, Communication Compliance, and
  eDiscovery see sensitive employee content — their assignments are minimal, named, separate from general
  stewardship, and confirmed with HR/privacy/legal. *Who* may hold them is their determination, not a
  technical default.
- **Always dry-run assignments.** Run `DGSTEWARD-Set-Stewardship.ps1 -WhatIf` and read every line before
  `-Commit`; the script prints the exact reverse command for each change so rollback is trivial.
- **Pilot on a bounded domain before the estate.** Prove the RACI, the assignments, and the cadence on one
  or two governance domains / a small asset set first. A framework is cheap to fix on a ring and expensive
  to fix estate-wide.
- **Ownership without a cadence decays — schedule it and give it an owner.** Re-certify owned assets on
  the agreed interval, chase unowned/overdue items every cycle, and produce the accountability report. The
  Data Steward runs the cadence; the Data Owner is Accountable for it running.
- **Record a last-reviewed and review-by date on every owned item.** "Overdue" is only computable if the
  dates exist. Write them into the object's metadata where it is writable, or track them in the assignment
  matrix where it is not.
- **Own the controls, not just the data.** A label, a DLP policy, a retention policy, and a governance
  domain each need an owner and a steward, the same as a data asset. An unowned control drifts silently.
- **Treat portal paths and the Data Governance API as provisional.** The Purview portal — especially the
  Unified Catalog / Data Governance experience — is actively evolving and partly in preview; verify each
  path and API version in your own tenant rather than trusting a screenshot or a version from last
  quarter. Do not assume a cmdlet or API that you have not confirmed exists.
- **The framework records decisions; it does not make them.** *What* an asset is classified as, *what* its
  retention/records schedule is, *whether* a regulation applies, and *who may* hold a sensitive role are
  determinations for compliance, records, privacy, and legal. Assign accountability for operating those
  decisions; defer the decisions themselves.
