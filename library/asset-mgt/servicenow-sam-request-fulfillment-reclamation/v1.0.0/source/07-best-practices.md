# 7. Best Practices — ServiceNow SAM Request Fulfillment & License Reclamation Workflow

- Make every request a catalog item. Replace email and chat with `Software Request – Standard – Intake`
  and `Software Request – Restricted – Intake` so every ask is tracked, routed, and measured — the single
  most important practice.
- Check entitlement before you fulfill. Always run `Entitlement Check – Software – Entitlement` before
  allocation so you never over-allocate beyond the purchased pool.
- Reclaim on a schedule, not by hope. `License Reclamation – Unused – Reclamation` running on a cadence
  is what stops license leakage; manual reclamation never happens.
- Start reclamation in report-only. Validate `Reclaim Rule – Inactive User – Reclamation` and
  `Reclaim Rule – No Usage 90d – Reclamation` candidates with the SAM owner before enforcing removal —
  earns trust and avoids reclaiming an active user's license.
- Tune the inactivity window per product. 90 days is a sane default; long-cycle or seasonal tools need a
  longer window, high-cost SaaS a shorter one.
- Keep the entitlement-match rule deterministic. Define exactly which entitlement a request consumes when
  several exist (edition / version / cost-center) so fulfillment and reporting are repeatable.
- Staff every approval and fulfillment group. An unstaffed `Approval Group – Restricted Software – Triage`
  or `Fulfillment Group – Software – Fulfillment` stalls the whole queue.
- Add a grace period and notification before removal. Warn the assignee before reclaiming so a still-needed
  license can be retained — reduces re-request churn.
- Measure with one KPI set. Track `KPI Set – Request & Reclamation – Reporting` (time-to-fulfill,
  reclaimed units, pool utilization) every cycle and chase the laggards.
- Pilot, then expand. Prove the workflow on `Pilot Scope – First Product Family – Pilot` before publishing
  catalog items fleet-wide.
- Document the cadence. Record reclamation windows, approval rules, and the entitlement-match logic for
  audits and repeatability.
