# 1. Solution Overview — SOC Onboarding: Microsoft Sentinel + Defender XDR Unified Incidents

## What this solution is

Microsoft Defender XDR (the Microsoft 365 Defender family: Defender for Endpoint, Defender for Office 365, Defender for Identity, and Defender for Cloud Apps) detects and correlates threats across endpoint, email, identity, and SaaS, and raises its own **incidents** in the Defender portal. Microsoft Sentinel is Microsoft's cloud-native SIEM/SOAR, running on a Log Analytics workspace, which raises incidents from its own analytics rules across every connected source. Run separately, the two produce overlapping and duplicated incidents.

This solution connects the two: the **Microsoft Defender XDR data connector** streams Defender XDR incidents and alerts into Sentinel and keeps their status synchronized, the duplicate-creating rules are turned off, and the SOC works one queue. Optionally, Sentinel can be onboarded into the unified security operations experience in the Defender portal so both live behind one pane of glass. *Verify current availability of the unified Defender + Sentinel experience in your tenant.*

## How the connection works

1. Defender XDR generates incidents and alerts from its workloads (endpoint, email, identity, cloud apps), each already correlating the related alerts into a single incident.
2. The **Microsoft Defender XDR data connector** in Sentinel, with **incident synchronization** enabled, streams those incidents into Sentinel as Sentinel incidents and streams the underlying alerts into the workspace tables (for example `SecurityAlert`, `SecurityIncident`).
3. **Bi-directional sync** keeps the incident's status, owner, and classification aligned between the Defender portal and Sentinel — close it in one, it closes in the other.
4. To avoid duplicates, the separate **Microsoft incident-creation rules** (the older per-product rules that make a *second* Sentinel incident from each Defender alert) are turned **off**, so the connector's synced incident is the single source of truth.
5. Sentinel **automation rules** run on incident creation to align severity/priority, assign an owner or team, and tag the incident — so every incident lands in the queue already prioritized and owned.
6. Sentinel's built-in **Fusion** correlation and **alert-grouping** can further stitch related alerts (for example a risky sign-in followed by endpoint malware) into one multi-stage incident across sources.

## The objects this solution creates (named to convention)

Every created object is named `<Purpose> - <Scope> - <Stage>` and reused verbatim throughout the guide, testing, and scripts:

- Workspace (destination): `Security Telemetry - SOC - Workspace`
- Defender XDR connector instance: `Microsoft Defender XDR - SOC - Pilot`
- Automation rule (severity/owner/tag alignment): `Incident Alignment - SOC - Pilot`
- Analyst assignment group / RBAC scope: `Microsoft Sentinel Responder - SOC - Pilot`

## What you can control

- Whether Defender XDR incidents and/or the raw alerts stream into Sentinel, and whether sync is bi-directional.
- Which Microsoft incident-creation rules stay off (de-duplication) versus any you deliberately keep.
- The severity/priority mapping and the ownership/tagging applied on arrival (automation rule).
- The triage workflow and shift hand-off routine the analysts follow (the runbook).
- The RBAC scope: who can read, triage, and respond in the workspace.

## Why this matters (the business case)

- **One queue** — analysts work a single prioritized list instead of reconciling two consoles.
- **No duplicates** — turning off the redundant incident-creation rules ends the "same incident twice" noise that wastes triage time.
- **Correlation** — identity, endpoint, email, and cloud signals are stitched into one incident, so multi-stage attacks are seen whole instead of as scattered fragments.
- **Aligned priority and ownership** — one severity scheme and automatic assignment mean the team agrees on what to work first and who owns it.
- **Clean hand-offs** — a documented triage and shift hand-off runbook keeps nothing dropped between shifts.

## Limitations (be honest with buyers)

- The Defender XDR connector requires the relevant Defender workloads to be licensed and generating incidents; it does not create detections that your Defender licensing does not produce.
- Sync behavior and the unified Defender + Sentinel portal experience evolve; *verify current availability and behavior in your tenant.*
- This solution unifies and operationalizes the queue; it is not a detection-engineering or custom-analytics program (those build on this foundation).
- Incident-response verdicts (true/false positive, containment, remediation) remain the SOC's decision — the guide provides the wiring and workflow, not the response determination.

## The standard deployment model

> Confirm the workspace and Sentinel, connect Defender XDR and enable incident sync, suppress the duplicate incident-creation rules, add the severity/ownership automation rule, adopt the triage/hand-off runbook, validate on a pilot that sync works and duplicates are gone, then expand to the full SOC. Standard pattern: `Assess -> Configure -> Pilot -> Validate -> Expand`.
