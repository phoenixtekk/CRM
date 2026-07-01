# 7. Best Practices — Tier-1 Publisher License & Audit-Risk Management

- Pilot one publisher first. Prove the whole process — scope, metric, mapping, position, register —
  on the publisher with the clearest contracts before you take on the others. The artifacts are
  reusable, so the second publisher is far faster than the first.
- Map deployment to the metric, not to installs. The licensable unit is processor cores, value
  units, named users, or documents — never the raw install count. Always state the metric before you
  count.
- Get virtualization topology right. For Oracle Processor and IBM PVU, hosts and clusters — not just
  guests — can be pulled into scope. A wrong topology assumption is the most common cause of a wrong
  position; record host, cores, and cluster for every processor-counted product.
- Never assume sub-capacity / lower-cost counting. Claim reduced counting only where the publisher's
  prerequisite (for example a deployed, reporting measurement tool) is genuinely met; otherwise count
  full capacity. Assuming it is the most expensive mistake on the worksheet.
- Watch the options and add-ons. Oracle options and management packs, and unlicensed user types or
  engines, are quietly enabled and counted later. Treat every option as licensable until proven
  entitled.
- Calculate your position before the auditor does. The only point with leverage is before the audit.
  Know the gap, decide remediate / acquire / accept, and act while it is still your choice.
- Give every exposure item an owner and a disposition. A shortfall with no owner is a future
  settlement; record it in the exposure register and track it to closure.
- Remediate safely. Run remediation in `-WhatIf` first, get owner approval, and make changes through
  your normal change process — then re-validate so the register reflects reality.
- Control where high-risk software runs. Isolate processor-counted software so unrelated hosts are
  not dragged into scope, and gate new installs through intake so exposure cannot silently return.
- Keep the audit evidence pack current. Maintain contracts, position worksheet, mapping, register,
  and sub-capacity proof as a standing pack — hand an auditor a worksheet, not open access.
- Re-validate on a cadence. Renewals, mergers, and big infrastructure changes shift your position;
  re-run the cycle at least at each renewal so the position stays defensible.
- Defer exact terms to the contract and publisher. Summaries guide the method; rates, core factors,
  user categories, and definitions are governed by your agreements — confirm there, do not assume.
