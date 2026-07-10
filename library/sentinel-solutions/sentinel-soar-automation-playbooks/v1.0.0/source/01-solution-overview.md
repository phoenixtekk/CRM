# 1. Solution Overview — Microsoft Sentinel SOAR: Automation Rules & Playbooks (Logic Apps)

## What this is

A SOAR (Security Orchestration, Automation, and Response) layer for Microsoft Sentinel. It automates the repetitive first minutes of every incident — assignment, tagging, context enrichment, notification, and ticketing — and adds a set of **response actions** (disable a user, isolate a device, block an IP) that are deliberately kept behind an **approval gate** and a **simulate-first** dry run. The goal is machine-speed handling of routine toil with humans in the loop for anything that changes production.

## How the technology works

Microsoft Sentinel gives you two building blocks:

- **Automation rules** — lightweight, no-code rules that run when an incident (or alert) is created or updated. A rule can set severity, assign an owner, add tags, change status, and — most importantly — **run one or more playbooks**. Automation rules are the trigger and the ordering logic; they are evaluated in priority order.
- **Playbooks** — an Azure **Logic App** (Consumption or Standard) that starts from a Sentinel trigger (`Microsoft Sentinel incident` or `Microsoft Sentinel alert`) and runs a sequence of connector actions: query a threat-intel source, look up a user in Entra ID, post an Adaptive Card to Microsoft Teams, send an email, create a ticket, or call Microsoft Defender to isolate a device. Playbooks are where the real work happens.

An incident flows like this: **analytics rule creates an incident → automation rule fires → automation rule assigns/tags the incident and calls the enrichment, notify, and ticketing playbooks → (optionally) an analyst reviews the enriched incident and, if containment is warranted, triggers the response playbook, which pauses for an approval before it does anything disruptive.**

Playbooks authenticate with a **managed identity** (preferred) or an API connection. The managed identity is granted the least-privilege roles the playbook needs (for example, Microsoft Sentinel Responder to change an incident, and the relevant Defender/Graph permission to isolate a device), so there are no stored credentials in the workflow.

## The standard deployment model

This solution follows the same five-stage model as every solution in this program:

`Assess -> Configure -> Pilot -> Validate -> Expand`

- **Assess** — confirm Sentinel is onboarded, incidents are being created, and you have rights to create Logic Apps and grant the managed identity its roles.
- **Configure** — build the four playbooks (enrichment, notify, ticketing, response) and the automation rule, all named per the convention below. Keep the response playbook in **simulate mode**.
- **Pilot** — scope the automation rule to a small, safe slice (for example, one analytics rule or one severity) and confirm enrichment, notification, and ticketing run cleanly on real incidents. Run the response playbook only in simulate mode.
- **Validate** — verify the pass/fail gate: enrichment adds context, notifications arrive, tickets open, run history is clean, and every response action is proven simulate-first and approval-gated.
- **Expand** — widen the automation rule scope, add more triggers/severities, and only then — with change approval — enable a real (non-simulated) response action for a specific, well-understood scenario.

## Naming convention

Every object created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim throughout the guide, testing, and scripts:

- Automation rule: `Auto-Triage - New Incidents - Pilot`
- Enrichment playbook (Logic App): `Enrichment - Incident - Pilot`
- Notification playbook: `Notify - Teams-Email - Pilot`
- Ticketing playbook: `Ticketing - Incident - Pilot`
- Response playbook (approval-gated, simulate-first): `Response - Contain - Pilot`
- Managed identity role assignment: `Sentinel Responder - Playbook MI - Pilot`

## Scope

- Sentinel automation rules that auto-assign, tag, and trigger playbooks by analytics rule and/or severity.
- Four Logic App playbooks: incident enrichment, Teams + email notification, ticketing, and approval-gated response.
- Response actions — disable user (Entra ID), isolate device (Microsoft Defender for Endpoint), block IP (a firewall/NSG or threat-intel indicator) — each **simulate-first** and **approval-gated**.
- Managed identity and API-connection security for the playbooks.
- A pilot-first rollout with a safe/simulate mode before any enforced action.

## What is out of scope

- The analytics rules that create the incidents in the first place (covered by the *Sentinel Analytics Rules & MITRE ATT&CK Coverage* solution in this catalog).
- Data ingestion and connectors (covered by *Deploy Microsoft Sentinel — Workspace & Connectors* and *Entra ID & Intune Audit Telemetry to Sentinel*).
- The **decision** of which response actions your organization permits, on whom, and under what authority — that is a security-operations and change-control determination for the customer to own; this guide provides the technical controls, not the policy.
- Third-party SOAR platforms; this solution is native Sentinel + Logic Apps.

## Authentication and connections used

- **Managed identity** on each playbook (system-assigned), granted least-privilege roles: **Microsoft Sentinel Responder** on the workspace/resource group (to update incidents), plus the specific permission each response action needs (for example, the Microsoft Defender for Endpoint machine-isolation permission, or an Entra ID role/Graph permission to disable a user).
- **API connections** for the Teams, Office 365 Outlook, and any ticketing connector, authorized once and reused. Where a managed-identity-based connector is available, prefer it over a stored credential.

## Benefits

- Faster mean-time-to-respond on routine incidents; analysts start on an already-enriched, already-ticketed incident.
- Consistent handling — the same enrichment and notification on every incident, every time.
- Safety by design — nothing disruptive runs without a simulate-first dry run and an explicit approval.

## Limitations and honest constraints

- Logic Apps (Consumption) bill per action/execution; high incident volume has a (modest) cost — size it in the pilot.
- Some connectors (for example, certain ticketing or firewall connectors) are in preview or require a specific license/premium tier — *verify current availability in your tenant* before you depend on one.
- Response actions depend on the target platform being present and licensed (for example, device isolation requires Microsoft Defender for Endpoint onboarded); *verify current availability in your tenant*.
