# Executive Summary — SOC Onboarding: Microsoft Sentinel + Defender XDR Unified Incidents — Government (GCC High)

**Sentinel Solutions**

> **Government (GCC High) edition.** This is the US Government national-cloud edition for public-sector
> and defense-industrial-base tenants — the same method as the commercial version, adapted for
> **Microsoft Sentinel + Defender XDR in Azure Government / GCC High** (`portal.azure.us`,
> `security.microsoft.us`, `login.microsoftonline.us`, `graph.microsoft.us`) and the FedRAMP High / DoD
> IL4–IL5 / CMMC context. Connector, incident-sync, and unified-experience availability in GCC High/DoD
> can lag or differ from commercial; each such point is flagged **"verify against current Microsoft
> Government documentation"** (see `gcc-high-parity-notes.md`).

Most security teams run Microsoft Sentinel and Microsoft Defender XDR as two separate consoles. The result is predictable: the same attack shows up as an incident in both places, analysts hop between portals, related identity, endpoint, email, and cloud signals never get stitched together, and two different severity schemes make it impossible to agree on what to work first. This solution connects Defender XDR to Sentinel, turns on incident synchronization, removes the duplicate incidents, and gives the SOC a single, correlated, prioritized queue with one triage workflow and a clean shift hand-off.

This is a complete, deploy-it-today package for onboarding a SOC onto a unified Sentinel + Defender XDR incident queue, written for an administrator with no prior SIEM experience.

## What you get

- A plain-language Solution Overview of how Defender XDR and Sentinel connect, how incident sync and de-duplication work, and how correlation stitches identity, endpoint, email, and cloud signals into one incident.
- A Requirements Guide with verify / implement-if-missing for every solution-specific prerequisite.
- An Implementation Guide of precise, click-by-click portal steps in the required order — connect Defender XDR, enable incident sync, suppress duplicate incident creation, align severity/priority/ownership, and scope RBAC.
- An analyst **triage workflow and shift hand-off runbook** the SOC can adopt on day one.
- Five PowerShell scripts for readiness discovery, connector/sync validation, a duplicate-and-coverage report, an incident-queue health report, and a workspace/RBAC scoping helper.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers

A unified incident queue: the Microsoft Defender XDR connector connected to `Security Telemetry - SOC - Workspace`, incident synchronization on so Defender XDR incidents and their status flow both ways, the separate Microsoft incident-creation rules turned off so no duplicate incidents are raised, an automation rule aligning severity/priority/ownership on arrival, and RBAC scoped so analysts see one prioritized list — validated on a pilot before the whole SOC is switched over.

## The standard deployment model

`Assess -> Configure -> Pilot -> Validate -> Expand`, with a pilot gate that confirms sync works and duplicates are gone before the team moves off the old two-console workflow.

## Boundary

This solution unifies and operationalizes the incident queue. Incident-response *determinations* — how to classify, contain, and remediate a given incident, and what is a true or false positive — remain the SOC's decision; the guide provides the technical wiring and the triage/hand-off process, not the response verdicts.

## Outcome

One correlated, prioritized incident queue across identity, endpoint, email, and cloud — no duplicates, one severity scheme, clear ownership, and a repeatable triage and hand-off routine — proven on a pilot before full SOC cut-over.
