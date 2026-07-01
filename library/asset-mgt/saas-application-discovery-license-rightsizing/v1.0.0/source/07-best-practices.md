# 7. Best Practices — SaaS Application Discovery & License Right-Sizing

- Pilot first, always. Right-size one well-understood scope before the fleet — it proves the dormancy
  threshold is right and catches wrongful reclaims before they reach real users.
- Default to WhatIf. Never let a reclaim run unattended; review the candidate list with the owner, then
  perform the seat change in the app's own console.
- Map every app to an owner. An app with no owner is an app nobody will approve decisions for — fill the
  `Owner Map – SaaS – Mapped` gaps before reclaiming anything.
- Rank by spend. Review the highest-cost apps first; that is where right-sizing returns the most.
- Pick a defensible dormancy window. 30 days catches the most waste but risks seasonal users; 60 to 90
  days is safer for tools used intermittently. Document the choice.
- Confirm downgrades in the app. Sign-in data proves authentication, not feature use — verify a
  downgrade candidate in the vendor's admin console before moving their plan.
- Catch non-SSO sprawl. Sign-in logs miss apps bought outside SSO; reconcile against expense/procurement
  data so the inventory is complete.
- Consolidate overlaps deliberately. When two apps do the same job, migrate users to one and retire the
  other — do not just trim seats on both.
- Make it recurring. A one-time clean-up decays; `Review Cadence – SaaS – Recurring` keeps sprawl from
  creeping back.
- Keep it traceable. Name every artifact with `<Purpose> – <Scope> – <Stage>` and reuse the names, so
  any decision can be traced from inventory to register to action for audit.
