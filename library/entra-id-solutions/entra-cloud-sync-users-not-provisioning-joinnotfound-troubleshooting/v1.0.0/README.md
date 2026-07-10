# Troubleshooting Microsoft Entra Connect Cloud Sync — Users Skipped / Not Provisioned (JoinNotFound) — v1.0.0

| | |
|---|---|
| Category | Entra ID Solutions |
| Solution code | CLDSYNCDX |
| Commercial | $2,495.00 (`PTK-CLDSYNCDX-COMM-001`) |
| Non-Profit | $1,497.00 (`PTK-CLDSYNCDX-NPO-001`) |
| Government | $2,120.75 (`PTK-CLDSYNCDX-GOV-001`) |
| Branding | off (white-label) |

A read-only diagnostics toolkit for when **Microsoft Entra Connect cloud sync** is configured but creates no accounts &mdash; provision on demand shows Import / In scope / Match, then **"User was skipped, JoinNotFound."** Five PowerShell tools and a symptom &rarr; cause &rarr; fix matrix isolate the reason (already-exists / out-of-scope OU / disabled config / quarantine / deletion threshold / missing service principal / unhealthy agent) so provision on demand reaches **action = Create**.

Diagnostic model: **Collect &rarr; Analyze &rarr; Remediate &rarr; Verify** (a diagnostic adaptation of Assess &rarr; Configure &rarr; Pilot &rarr; Validate &rarr; Expand).

Next: build deliverables + hero, then `/publish-solution entra-cloud-sync-users-not-provisioning-joinnotfound-troubleshooting`.
