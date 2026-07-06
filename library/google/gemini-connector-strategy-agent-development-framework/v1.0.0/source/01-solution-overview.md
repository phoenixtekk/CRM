# 1. Solution Overview — Gemini Connector Strategy & Agent Development Framework

> **Vendor boundary.** Google's **Gemini Enterprise** (formerly *Google Agentspace*) and its
> **Agent Platform** (formerly *Vertex AI Agent Builder*) are **evolving and partly in preview**.
> Named capabilities below are **cited to Google's public documentation** where possible; anything not
> confirmable against a Google doc is flagged **"verify in your tenant."** Never treat a rolling-out
> feature as fixed — confirm it in the Google Cloud console and the
> [Gemini Enterprise release notes](https://docs.cloud.google.com/gemini/enterprise/docs/release-notes).

## What this is
This solution defines the **connector strategy** and the **agent-development framework** for Gemini
Enterprise: *which connectors are approved and where data-access boundaries apply*, and *a governed way
to build, review, deploy, and monitor agentic workflows*. It is deliberately distinct from a general
adoption/guardrails engagement — its two subjects are the **connectors that expose enterprise data** to
Gemini and the **agents that act on that data**, because both multiply quickly and both are risk
surfaces when built ad hoc.

## The two things being governed

### 1. Connectors (how Gemini Enterprise exposes data)
Gemini Enterprise reaches enterprise data through **connectors** that populate **data stores** in the
underlying Discovery Engine. Google documents four connector categories
([Introduction to connectors and data stores](https://docs.cloud.google.com/gemini/enterprise/docs/connectors/introduction-to-connectors-and-data-stores)):
- **Prebuilt connectors** — direct integrations to Google sources (e.g. Google Drive, Gmail, Calendar,
  Groups, Sites) and Google Cloud data (BigQuery, Cloud Storage, Cloud SQL, Spanner, Firestore,
  Bigtable, AlloyDB), plus named third-party sources (Microsoft SharePoint/OneDrive/Outlook/Entra ID,
  Atlassian Jira & Confluence — Cloud and Data Center, ServiceNow, Salesforce, Box, Dropbox, Slack,
  Notion, and more; Google states **"100+ connectors"** — the exact list and which support write
  **Actions** vs read-only is **verify-in-tenant**).
- **Custom connectors** — a Fetch → Transform → Sync pipeline for proprietary systems.
- **Self-hosted data sources** — customer-managed / on-prem sources reached via **Private Service
  Connect**.
- **Custom MCP-server data stores** — MCP-compliant internal/legacy tools and third-party systems.

**Where the boundary applies.** Indexed content **retains the source system's ACLs** — Gemini Enterprise
*"respects source permissions,"* so a user only sees results they are authorized to see in the origin
system, resolved through your identity provider
([Configure access controls](https://cloud.google.com/agentspace/agentspace-enterprise/docs/identity)).
For **custom** sources you attach ACL metadata (`acl_info`) to each document so the same query returns
different results per user. Around that, Google-documented boundary primitives apply: **VPC Service
Controls** perimeters and **VPC firewall** egress rules, **CMEK/EKM** encryption, **data residency**,
**Cloud Audit Logging**, and **IAM** roles
([security overview](https://docs.cloud.google.com/gemini/enterprise/docs/security-overview);
[IAM roles](https://docs.cloud.google.com/gemini/enterprise/docs/access-control) —
`discoveryengine.agentspaceAdmin`, `agentspaceUser`, `editor`, `viewer`).

### 2. Agents (what acts on the connected data)
Agents are built and run across a documented stack:
- **Agent Designer** — no-code/low-code builder inside Gemini Enterprise for single- and multi-step
  agents ([Agent Designer overview](https://docs.cloud.google.com/gemini/enterprise/docs/agent-designer)).
- **Agent Development Kit (ADK)** — code-first framework (Python/Java/Go/TypeScript) with `adk deploy`,
  and **Agent Garden** samples.
- **Agent Engine / Runtime** — managed runtime with Sessions, Memory Bank, and Code Execution
  ([Agent Engine overview](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)).
- **Governance components** (Gemini Enterprise Agent Platform): **Agent Registry** (approved-asset
  catalog), **Agent Identity** (cryptographic per-agent id + audit trail), **Agent Gateway** (central
  policy-enforcement point for tool calls, with **Model Armor** prompt-injection/data-leak defenses),
  **Agent Security Dashboard** (Security Command Center), and **Agent Sandbox**
  ([Agent Platform announcement](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform)).
  Availability of individual components is **verify-in-tenant**.
- **Protocols:** **A2A** (agent-to-agent) and **MCP** (agent-to-tool) — the same connectors and tool
  registry the connector strategy governs are what agents call.

## The governance model (how the pieces fit)
1. **Connector approval criteria** decide *which* sources may be connected and by whom — a named
   allow-list, each connector tied to a data-sensitivity classification and an owner.
2. **Data-access boundaries** decide *how far* a connected source and any agent over it can reach — ACL
   respect at the source, plus VPC Service Controls, IAM least privilege, and residency around it.
3. **The agent-development framework** applies four repeatable stages to every agentic workflow —
   **design → review → deploy → monitor** — so agents are registered, identity-bound, gateway-mediated,
   evaluated before release, and observed after.

## What you can control
- **Which connectors are approved** — an allow-list mapped to data classifications and owners.
- **Data-access boundary** — source-ACL respect, VPC Service Controls perimeter, IAM roles, residency.
- **Agent lifecycle guardrails** — registry entry, agent identity, gateway/tool policy, evaluation gate,
  audience/sharing scope, monitoring.
- **Scope** — the Google Cloud project(s) / location the strategy and framework apply to, pilot-first.

## Limitations (be honest with buyers)
- **Gemini Enterprise and the Agent Platform are evolving/preview.** Connector names, the agent
  governance components, console menu paths, and GA-vs-preview status **change** — every specific is
  cited or flagged, and must be confirmed in your tenant.
- **Respecting source ACLs depends on correct source permissions and identity mapping.** If the source's
  ACLs are wrong, or identity mapping is misconfigured, results can over- or under-expose — this is why
  boundary conformance is *tested*, not assumed.
- **Governing connectors does not clean up existing over-sharing** in the source systems; that is
  remediated at the source.
- This framework governs *how* agents and connectors are built and bounded; it does not replace the
  broader data-governance baseline, DLP, or the security stakeholders' policies it must satisfy.

## The standard deployment model
> **Assess** the connectors and agents in scope → **Configure** approval criteria, boundaries, and the
> agent framework on a pilot project → **Pilot** one approved connector and one agent → **Validate**
> boundary/guardrail conformance against pass/fail gates → **Expand** to more connectors and agents.
> Every production change is pilot-first, gated, and rollback-ready.
