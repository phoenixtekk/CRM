# Executive Summary — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

**Sentinel Solutions**

Your identity and device platforms already generate exactly the audit signal a security operations team needs — sign-ins, directory changes, device compliance and enrollment events. By default that signal is siloed inside Entra ID and Intune, short-retained, and invisible to your SIEM, so nothing can alert on it and an auditor cannot see it. This solution wires that telemetry into Microsoft Sentinel: diagnostic settings and a data connector route the logs into a Log Analytics workspace, retention is set for compliance, and baseline analytics rules turn the raw stream into actionable alerts.

This is a complete, deploy-it-today package for streaming Entra ID and Intune audit telemetry into Microsoft Sentinel, written for an administrator with no prior SIEM experience.

## What you get

- A plain-language Solution Overview of the pipeline — Entra ID and Intune diagnostic logs to a Log Analytics workspace to Microsoft Sentinel — and the log categories, retention, and baseline analytics that make it useful.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click portal steps in the required order.
- Five PowerShell scripts for telemetry-readiness discovery, ingestion/connector validation, a log-coverage and retention report, safe remediation of missing diagnostic settings, and a workspace/RBAC scoping helper.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers

A working telemetry pipeline — Entra ID diagnostic settings and the Entra ID data connector feeding a Log Analytics workspace, Intune audit telemetry routed in, the relevant log categories (sign-in, audit, device/compliance) flowing, retention set to a compliance-appropriate window, and baseline analytics rules enabled — validated on a pilot before you scale.

## The standard deployment model

`Assess -> Configure -> Pilot -> Validate -> Expand`, with a pilot gate that validates ingestion before expansion.

## Outcome

Identity and device audit telemetry centralized in Microsoft Sentinel — retained for compliance and ready to alert on — so nothing in Entra ID or Intune happens unseen, proven on a pilot before you scale.
