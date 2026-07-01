# 7. Best Practices — Software Discovery & Entitlement Reconciliation

- **Pilot on one source first.** Prove the pipeline on a single discovery source or product family
  before merging all sources — it surfaces normalization gaps cheaply and is the single most
  important practice.
- **One SKU vocabulary, everywhere.** The `Normalization Map – SKU Vocabulary – Configure` and the
  `Entitlement Register – Systems of Record – Configure` must use the same canonical SKUs, or the
  reconciliation join silently drops rows.
- **Never drop an unmatched install.** Every install that resolves to no SKU goes into the
  `Exception Register – Unmatched & Edge Cases – Validate` for a decision — exceptions are signal, not
  noise.
- **Treat the normalization map as a living asset.** Add a rule for each new product family as it
  appears; a stale map is the top cause of a noisy, untrustworthy ledger.
- **Deduplicate across sources.** When two sources report the same product on the same device, count
  it once — confirm the merge keys on device plus SKU.
- **Record the licensing metric.** Per-core, per-processor, and per-user-with-downgrade SKUs only
  reconcile correctly when the entitlement register stores the metric, not just a count.
- **Keep discovery read-only.** Discovery, validation, and reporting never change source systems;
  only `SWDISC-Remediation.ps1` writes, and it defaults to `-WhatIf`.
- **Reconcile on a cadence.** Run the pipeline each cycle and after every renewal or true-up so the
  position never drifts from reality.
- **Defer Flexera internals to the vendor.** Consume the Flexera installed-software export; do not
  reverse-engineer its recognition or API — its setup is the vendor's documentation, not this method.
- **Document the artifacts.** Record where each named artifact lives and who owns each exception
  decision, so the pipeline is repeatable and audit-ready.
