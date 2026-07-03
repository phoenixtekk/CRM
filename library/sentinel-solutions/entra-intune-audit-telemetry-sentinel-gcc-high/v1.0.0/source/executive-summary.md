# Executive Summary — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

**Sentinel Solutions · US Sovereign Cloud (GCC High)**

Your identity and device platforms already generate exactly the audit signal a security operations team needs — sign-ins, directory changes, device compliance and enrollment events. By default that signal is siloed inside Entra ID and Intune, short-retained, and invisible to your SIEM, so nothing can alert on it and an auditor cannot see it. This solution wires that telemetry into Microsoft Sentinel — but for the **US sovereign cloud**: diagnostic settings and a data connector route the logs into a Log Analytics workspace **in Azure Government**, retention is set for compliance, and baseline analytics rules turn the raw stream into actionable alerts.

This is the **Government (GCC High) edition**. It is not the Commercial guide with a different sign-in — the sovereign admin URLs differ (`portal.azure.us`, `entra.microsoft.us`, `intune.microsoft.us`, `security.microsoft.us`), the endpoints differ (`login.microsoftonline.us`, `graph.microsoft.us`, `-Environment USGov`/`AzureUSGovernment`), and some Sentinel capabilities lag or are absent versus Commercial. Those differences are called out throughout so a GCC High tenant is configured correctly — not with Commercial steps that silently fail.

## What you get

- A plain-language Solution Overview of the pipeline — Entra ID and Intune diagnostic logs to a Log Analytics workspace to Microsoft Sentinel in Azure Government — with an explicit **Commercial vs GCC High — what's different** section.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, using the `.us` sovereign portals.
- An Implementation Guide of precise, click-by-click Gov-portal steps in the required order, with GCC-High caveats inline at the step where they matter.
- A cited **GCC High parity reference** so no Commercial-only feature is promised on a Gov tenant.
- Five PowerShell scripts (all targeting US Gov endpoints) for telemetry-readiness discovery, ingestion/connector validation, a log-coverage and retention report, safe remediation of missing diagnostic settings, and a workspace/RBAC scoping helper.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers

A working telemetry pipeline inside Azure Government — Entra ID diagnostic settings and the Entra ID data connector feeding a Log Analytics workspace, Intune audit telemetry routed in from `intune.microsoft.us`, the relevant log categories (sign-in, audit, device/compliance) flowing, retention set to a compliance-appropriate window (CMMC / DFARS / FedRAMP), and baseline analytics rules enabled — validated on a pilot before you scale.

## The standard deployment model

`Assess -> Configure -> Pilot -> Validate -> Expand`, with a pilot gate that validates ingestion before expansion.

## Outcome

Identity and device audit telemetry centralized in Microsoft Sentinel inside the US sovereign boundary — retained for compliance and ready to alert on — so nothing in Entra ID or Intune happens unseen, proven on a pilot before you scale.
