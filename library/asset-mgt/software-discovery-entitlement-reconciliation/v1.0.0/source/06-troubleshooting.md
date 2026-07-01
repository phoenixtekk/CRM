# 6. Troubleshooting Guide — Software Discovery & Entitlement Reconciliation

Use `SWDISC-Discovery.ps1` and `SWDISC-Validation.ps1` to confirm inputs, `SWDISC-Report.ps1` for the
position, and `SWDISC-Remediation.ps1` (default `-WhatIf`) for safe normalization-map fixes.

## A. Discovery returns no installed software
| Symptom | Cause | Remediation |
|---|---|---|
| Inventory file is empty | Software inventory not enabled on the source | Configuration Manager: enable Software/Hardware inventory + Asset Intelligence on the scoped collection. Intune: confirm `Apps > Monitor > Discovered apps` is populated |
| Intune path returns nothing | Missing Graph scope | Connect with `DeviceManagementManagedDevices.Read.All`; re-run `SWDISC-Discovery.ps1` |
| Configuration Manager path errors | SMS Provider/WMI not reachable | Confirm the console/cmdlets are installed and the `root\sms\site_<code>` namespace is reachable with a read role |
| Flexera rows missing | Export not placed where the script expects | Produce the installed-software export from the Flexera console and place it at the expected path; the script consumes the export, it does not call Flexera |

## B. Rows do not normalize to a SKU
| Symptom | Cause | Remediation |
|---|---|---|
| Many unresolved rows in validation | Normalization map missing rules | Add rules to the `Normalization Map – SKU Vocabulary – Configure`; queue fixes and apply with `SWDISC-Remediation.ps1` |
| Same product appears as several SKUs | Edition/version suffixes not collapsed | Add rules that map edition/patch variants to one canonical SKU |
| Title resolves to the wrong SKU | Over-broad alias rule | Tighten the matching rule (publisher + title + edition), re-run `SWDISC-Validation.ps1` |

## C. Reconciliation ledger looks wrong
| Symptom | Cause | Remediation |
|---|---|---|
| SKUs show installs but zero entitled | Entitlement register uses a different SKU vocabulary | Align register SKUs to the normalization map vocabulary so they join |
| Counts doubled for one product | Same install reported by two sources | Confirm the merge deduplicates on device plus SKU |
| Over-deployment false positive | Licensing metric not recorded (e.g. per-core) | Record the metric in the entitlement register; reconcile against the metric, not a raw count |

## D. Exceptions never shrink
- Each cycle, triage the `Exception Register – Unmatched & Edge Cases – Validate`: add a normalization
  rule, record a missing entitlement, or flag a true gap — then re-run `SWDISC-Report.ps1` so resolved
  items leave the register.

## E. Remediation made no change
- `SWDISC-Remediation.ps1` defaults to `-WhatIf` (preview only). Re-run with `-WhatIf:$false` to
  commit, then confirm with `SWDISC-Validation.ps1`.

## F. When to escalate
If discovery returns data, all rows normalize, the entitlement register shares the SKU vocabulary, and
the ledger still disagrees with a known true-up, capture the inventory file, the normalization map,
and the entitlement register, and review with procurement against the contract terms (downgrade
rights, metric, edition coverage) before declaring a compliance gap.
