# 7. Best Practices — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

- **Pilot the ingestion first.** Route a minimal category set (`SignInLogs`, `AuditLogs`) to the workspace and confirm data is arriving before enabling high-volume categories — the single most important practice for controlling cost and avoiding surprises.
- **Scope categories deliberately.** Non-interactive, service-principal, and managed-identity sign-in logs are valuable but high-volume; add them only when the budget and the use case justify them.
- **Plan retention before you connect.** Retention drives a large share of cost; set interactive vs long-term/archive per table to your compliance requirement, not by default.
- **Name every object to the convention.** Use `<Purpose> - <Scope> - <Stage>` for the workspace, diagnostic setting, analytics rules, and RBAC scope, and reuse the names verbatim — it makes the pipeline auditable and repeatable.
- **Avoid double ingestion.** Before adding a diagnostic setting, check the source is not already routing the same categories elsewhere; you pay to ingest data twice if it is.
- **Use the connector and the diagnostic setting together.** The diagnostic setting routes the data; the connector registers the source and unlocks the matching baseline rule templates — enable both.
- **Start analytics from templates.** Enable baseline rule templates first, tune severity, and watch for noise before authoring custom rules.
- **Right-size RBAC.** Give analysts `Microsoft Sentinel Reader` and operators `Microsoft Sentinel Contributor`; avoid broad standing access and prefer eligible (PIM) activation.
- **Watch the volume report.** Re-run the coverage/volume report each cycle (`SENTLOG-Report.ps1`) so ingestion stays within budget and gaps in coverage are caught.
- **Document the pipeline.** Record which categories are routed, the retention per table, and the enabled rules for audits and repeatability.
