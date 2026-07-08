# 7. Best Practices — A Defensible SOX Program in Microsoft Purview

Operating principles for keeping the SOX-aligned Purview controls trustworthy and their evidence
audit-ready. Grounded in Microsoft's public guidance and the **Assess → Design → Configure → Pilot
(simulate) → Validate → Expand** model.

## Treat evidence as the deliverable, not the control
- An auditor tests whether a control **operated over the period** — that needs an **artifact**. Configure each Purview control so it *produces* evidence (an in-force policy, an audit trail, a simulation report), and store the evidence runbooks so the artifact is reproducible on demand.
- **The audit trail is not retroactive.** Enable unified audit logging before the review period, and treat "is audit on?" as a **standing monitored control** — the scheduled discovery/validate chain catches it being turned off between audits.

## Map controls to objectives explicitly — and keep the map current
- The backbone of a SOX program is the **control-to-objective map** (Purview control → ITGC objective). Maintain it in **Compliance Manager** (or a custom assessment) so leadership and the external auditor see the same rollup.
- Purview covers **classification, DLP, retention, and the M365 audit trail** — it does **not** replace ERP/application access controls, SoD tooling, or change-management systems. Show the boundary clearly so the auditor knows what Purview does and doesn't evidence.

## Pilot every high-impact control — DLP in simulation, always
- **DLP goes into simulation/test mode first.** Simulation gives you exposure evidence (what *would* have been blocked) with zero disruption — invaluable for both scoping and the audit narrative. Move to enforce only after the pilot passes and the exposure is reviewed.
- Publish labels and retention to a **finance-ring pilot** before tenant-wide; validate with the readiness report before expansion. Every change is reversible — record the exact rollback with it.

## Classify deliberately, then let protection key off the label
- One clear label for financial reporting data (`Financial – SOX Reporting – Confidential`) lets DLP, retention, and monitoring all reference the same classification — simpler to explain and to audit than scattered ad-hoc rules.
- Where licensed, use **auto-labeling in simulation** to find financial data at scale before you trust the classification — verify the simulation before enabling.

## Retention: configure to the schedule, never invent one
- SOX record-retention periods (including audit-workpaper retention under §802) and which data is financially relevant are **records/legal determinations**. Configure retention to their schedule; the scripts take the period as a parameter and never assume one.
- Keep **disposition and file-plan** decisions with records management — this program configures retention and produces evidence, it does not decide the schedule or dispose of records.

## Segregation of duties — on the ERP *and* on Purview itself
- SoD is a SOX control that also applies to the controls' own administration: the person who **configures** a Purview control should not be the sole party who **reviews its evidence**. Assign least-privilege role groups and separate configure-vs-review.
- Access to the audit log and to control configuration is itself sensitive — review role membership periodically, and remember configuration changes are themselves logged (that's the change-management evidence).

## Watch the gotchas that undermine SOX evidence
- **Ingestion latency** — recent activity isn't searchable immediately; widen the window before concluding an event is absent.
- **Search truncation** — `Search-UnifiedAuditLog` caps results; page (`ReturnLargeSet`) and keep windows short so evidence is never silently incomplete.
- **UTC timestamps** — audit `CreationDate` is UTC; normalize when correlating with ERP, sign-in, or change-management logs so the timeline holds up.
- **License lapse** — advanced DLP/auto-labeling/long-term audit retention/Compliance Manager depend on E5/E5-Compliance; a lapse silently degrades a control. The scheduled scope check flags it.

## Monitor for drift between audits
- Schedule the read-only `PURVSOX-Discovery.ps1` → `PURVSOX-Validate.ps1` → `PURVSOX-EvidenceReport.ps1` chain so a control flipping off, a policy being removed, DLP dropping to disabled, or a role change is caught early — not discovered during the audit.
- Re-run the evidence runbooks when the external auditor requests a period, and keep the `-WhatIf` transcripts and simulation reports as the change record.

## Verify against your tenant — Purview evolves
- Capability availability, portal paths, Compliance Manager templates, and accepted `RetentionDuration` values are **licensing-/tenant-dependent and change over time**. Confirm against your entitlements and current Microsoft documentation before standardizing any automation or promising a capability.
