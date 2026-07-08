# Executive Summary — Microsoft Purview SOX Compliance Program

## The problem
The Sarbanes-Oxley Act holds leadership accountable for the integrity of financial reporting — and, in
practice, for the **IT general controls** around the data and systems that produce it: who can access
financial data, how change is controlled, whether activity is logged, and whether records are retained.
When an external auditor tests those controls, the recurring failure isn't that the controls are
absent — it's that they were never **mapped to a tool**, never **configured consistently**, and there
is **no evidence** to hand over. Several of those artifacts naturally live in Microsoft Purview, but
only if someone deliberately makes them exist.

## The solution
A complete, self-guided **SOX-aligned program built inside Microsoft Purview**. It **maps** the
relevant ITGC objectives — access to programs and data, change management, IT operations, segregation
of duties, records retention — to concrete Purview controls; **configures** those controls (a
financial-data **sensitivity label**, a **DLP policy piloted in simulation**, a **retention policy**
for SOX records, **unified audit** with a retention policy scoped to financial-data access, and
least-privilege **roles**); rolls them up in **Compliance Manager**; and produces the **audit evidence**
an ICFR review will ask for. Five safe-by-default PowerShell tools (read-only or `-WhatIf` until you
commit) do the scoping, discovery, configuration, validation, and evidence reporting.

## What you get
- **A control map, made concrete** — each Purview control tied to the ITGC objective it evidences, maintained in Compliance Manager.
- **The evidence foundation confirmed** — unified audit logging on, so financial-data access and control changes are captured (audit is not retroactive — this happens first).
- **Financial data classified and protected** — one clear label, a DLP policy that runs in **simulation** to show exposure before it ever blocks, and a retention policy set to your records schedule.
- **Evidence runbooks** — the exact searches for the auditor's recurring requests: who accessed financial data, who changed a control, who was granted access — with a paged search tool that never silently truncates.
- **Proven readiness** — a control-to-evidence scorecard that confirms each control operates and its artifact is producible, before the auditor asks.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate) →
Validate → Expand** — with DLP and every high-impact control **piloted in simulation/test on a finance
ring** before tenant-wide enforcement, and pass/fail gates and documented rollback at every step.

## Boundaries
The advanced controls (content-aware DLP, auto-labeling, long-term audit retention, Compliance Manager
templates) are **licensing-/plan-dependent** — E5 or the E5 Compliance add-on — and the Purview portal
is **actively evolving**; capabilities and paths are cited or flagged **"verify your licensing/tenant,"**
never assumed. This is **not an audit or an attestation**: **SOX control-design adequacy,
operating-effectiveness conclusions, materiality, record-retention schedules, and legal holds are
deferred to your management, internal-audit, records, and legal functions** — the solution provides the
technical method and the evidence, not the determination.

## The bottom line
A SOX-aligned Purview program **mapped, configured, piloted, and validated** — with the audit evidence
ready before you need it, so an ICFR review finds **controls and artifacts, not gaps**.
