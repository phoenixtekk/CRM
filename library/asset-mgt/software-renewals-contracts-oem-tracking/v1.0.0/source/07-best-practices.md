# 7. Best Practices — Software Renewals, Contracts & OEM Bundle Tracking

- One source of truth. Keep the `Contract & Entitlement Repository – All Products – Master` the
  single authoritative record; never let a renewal date live only in an inbox or a calendar invite.
- Lead time beats heroics. Arm the `Lead-Time Alert Rules – Renewals – Tiered` at T-120 / T-90 /
  T-60 / T-30 so high-value and long-notice renewals surface early enough to negotiate, not just to
  rubber-stamp.
- Mind the notice period. The cancellation/notice window must always sit inside an active alert tier;
  for any contract whose `NoticePeriodDays` exceeds 120, raise the earliest alert further out.
- Map bundles before you track parts. Record the `OEM Bundle Map – Vendor Bundles – Master` so a
  bundle is one renewal decision with one anchor — never track child entitlements as if they renew
  independently.
- Decide, don't drift. Every alert ends in a documented keep / change / consolidate / drop decision
  through the `Renewal Decision Workflow – Per Contract – Standard`; an auto-renew you reviewed is
  fine, an auto-renew nobody saw is the failure mode.
- Name an owner for every contract. Unrouted renewals stall; assign `Owner` and `ProcurementLiaison`
  in the repository and keep the routing groups current.
- Treat a deliberate lapse as a decision. Letting a contract drop is a valid outcome — but only when
  the workflow confirmed nothing in production depends on it.
- Pilot before portfolio. Prove one full cycle on a pilot product family and pass the gate before
  expanding; the process should be boring before it is broad.
- Reconcile cost every quarter. Use the cost rollup from `SWRENEW-Report.ps1` to find over-licensing,
  duplicate coverage inside bundles, and consolidation opportunities.
- Keep the repository honest. Re-run `SWRENEW-Validation.ps1` each cycle and close every renewal by
  advancing `RenewalDate`; a stale repository quietly becomes useless.
- Back up before you write. Always preview `SWRENEW-Remediation.ps1` with `-WhatIf` and keep the
  automatic CSV backup it creates, so repository edits are reversible.
