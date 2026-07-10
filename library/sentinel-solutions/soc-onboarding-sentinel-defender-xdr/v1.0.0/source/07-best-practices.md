# 7. Best Practices — SOC Onboarding: Microsoft Sentinel + Defender XDR Unified Incidents

- **Pilot the unified queue before cut-over.** Connect one or two Defender workloads and a small cohort, confirm sync works and duplicates are gone, then move the whole SOC — never switch everyone at once.
- **Turn off the Microsoft incident-creation rules, don't delete them.** Disabling de-duplicates the queue while keeping a one-click rollback; deleting throws away that safety net.
- **Let the connector's synced incident be the single source of truth.** With incident sync on, work incidents in Sentinel (or the unified Defender portal) — not in two places — and rely on bi-directional sync to keep status aligned.
- **Keep Defender's severity unless you have a reason to override.** Defender XDR severity is already correlated across workloads; only remap it in the automation rule where your SOC's priority scheme genuinely differs, and encode that scheme once.
- **Assign an owner on arrival.** An automation rule that assigns owner and priority tag on creation is what turns a pile of incidents into a workable, sortable queue — no incident should sit unowned.
- **Make the hand-off a ritual, not an afterthought.** End every shift by clearing untriaged incidents, adding a hand-off comment per open incident, and re-assigning to the next shift; run the report so nothing older than the SLA is dropped.
- **Name every object to the convention.** Use `<Purpose> - <Scope> - <Stage>` for the workspace, connector instance, automation rule, and RBAC scope, and reuse the names verbatim — it makes the SOC's configuration auditable and repeatable.
- **Right-size RBAC.** Give analysts `Microsoft Sentinel Responder`, leads `Microsoft Sentinel Contributor`, and stakeholders `Microsoft Sentinel Reader`; prefer eligible (PIM) activation over standing access.
- **Lean on correlation.** Let Sentinel's Fusion and alert-grouping stitch related alerts into multi-stage incidents rather than triaging each alert alone — it is the point of unifying the queue.
- **Keep response decisions with the SOC.** The pipeline delivers a clean, correlated, prioritized queue; classification, containment, and remediation verdicts remain the analysts' call, recorded in the incident.

## Where to go next

- **Detection engineering / custom analytics** — author Sentinel analytics rules and hunting queries on top of the unified queue.
- **SOAR / automation playbooks** — extend automation rules with Logic App playbooks for enrichment and response actions (pilot/simulate before enforcing any response).
- **Audit telemetry onboarding** — feed Entra ID and Intune audit logs into the same workspace so identity and device signal enriches correlation.
- **Threat intelligence and hunting** — add TI feeds and proactive hunting to the same Sentinel foundation.
