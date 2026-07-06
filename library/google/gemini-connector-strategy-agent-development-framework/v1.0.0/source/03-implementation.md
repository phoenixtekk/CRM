# 3. Implementation Guide — Gemini Connector Strategy & Agent Development Framework

Follow these steps **in order**. Connector work is done in the **Google Cloud console**
(`https://console.cloud.google.com`, Gemini Enterprise / Agentspace admin area) and confirmed with the
`GEMCONN-*` scripts; agent work is done in **Agent Designer** or **ADK + Agent Engine**. Objects are
named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Approve → bound → build under guardrails → validate → expand. Do it on a **pilot project**
> (one connector, one agent) first. Keep a rollback for every change. **Preview note:** exact console
> menu paths and the GA-vs-preview status of Agent Platform components are **verify-in-tenant** — the
> steps name the documented area and tell you to confirm it in your console.

## Naming (set once, reuse verbatim)
- Connector approval record: `Connector Approval – Pilot Project – Prod`
- Data-access boundary (perimeter): `Data Access Boundary – Pilot Project – Prod`
- Agent under development: `Agent Build – Pilot Project – Design`
- Agent released: `Agent Build – Pilot Project – Prod`

## Part A — Connector strategy

### Step 1 — Confirm scope and inventory what exists
1. Run `GEMCONN-Set-ScopeTargeting.ps1 -ProjectId 'your-project-id'` to confirm the project, the
   Discovery Engine resource-path prefix, the Gemini Enterprise IAM bindings, and whether a boundary
   exists.
2. Run `GEMCONN-Discovery.ps1 -ProjectId 'your-project-id'` for the current connectors (data stores) and
   agents. Treat any empty result as **verify-in-tenant** (preview surface), not "none".

### Step 2 — Define the connector approval criteria
1. Write the **approval criteria** each connector must meet before it is connected. A workable baseline:
   - a **named business owner** and use case;
   - a **data classification** (public / internal / confidential / restricted) for the source, from the
     scheme in Requirements §2.4;
   - **source ACLs verified correct** (Gemini respects them — bad ACLs over-expose);
   - **identity mapping confirmed** for the source's users
     ([identity](https://cloud.google.com/agentspace/agentspace-enterprise/docs/identity));
   - a **sync cadence** decision (full/incremental/identity — Google documents identity sync as often as
     every 30 minutes).
2. Record each approved connector in the allow-list `Connector Approval – Pilot Project – Prod` (one
   data-store id per line — the format `GEMCONN-Validation.ps1 -ApprovedConnectorsPath` consumes).

### Step 3 — Set the data-access boundary
1. Confirm/define a **VPC Service Controls** perimeter covering the project
   (`Data Access Boundary – Pilot Project – Prod`) so connectors and agents cannot exfiltrate beyond it
   ([security overview](https://docs.cloud.google.com/gemini/enterprise/docs/security-overview);
   [VPC-SC with Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform/machine-learning/general/vpc-service-controls)).
2. Set **IAM** to least privilege — grant `discoveryengine.agentspaceAdmin` only to admins,
   `agentspaceUser` to users who need it, and use **app-level IAM** to restrict users to specific apps
   ([app access controls](https://docs.cloud.google.com/gemini/enterprise/docs/iam-policy-for-apps)).
3. Record the **residency** requirement and confirm **VPC firewall** egress limits where required.
4. Run `GEMCONN-Validation.ps1 -ProjectId 'your-project-id' -ApprovedConnectorsPath .\approved-connectors.txt`
   — confirms boundary present, org policies present, and connectors on the allow-list.

### Step 4 — Connect the pilot connector
1. In the Gemini Enterprise / Agentspace admin area of the console, create the **data store** for the
   one approved pilot source (prebuilt, custom, self-hosted via Private Service Connect, or custom MCP
   server as applicable). *Confirm the exact menu path in your console — it is verify-in-tenant.*
2. Run the initial sync and confirm **identity sync** is on so ACLs propagate.
3. Run `GEMCONN-Discovery.ps1` — the new connector should appear; run `GEMCONN-Report.ps1 -SaveBaseline`
   to capture the pre-expansion baseline.

## Part B — Agent-development framework (design → review → deploy → monitor)

### Step 5 — Design (register + identity)
1. Build the pilot agent (`Agent Build – Pilot Project – Design`) in **Agent Designer** (no-code) or
   **ADK** (code-first)
   ([Agent Designer](https://docs.cloud.google.com/gemini/enterprise/docs/agent-designer)).
2. Register it in the **Agent Registry** so only governed, approved agents/tools are discoverable, and
   confirm it gets an **Agent Identity** (cryptographic id → audit trail)
   ([Agent Platform](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform)).
   *If a component is not yet available in your tenant, enforce the equivalent by process and flag it.*
3. Restrict the tools/connectors the agent may call to the **approved** set (tool governance / Agent
   Gateway); the same allow-list from Step 2 governs what the agent can reach.

### Step 6 — Review (evaluate before release)
1. Test the agent in **Preview / playground** and run **Gen AI Evaluation** — AutoRaters, a User
   Simulator, and online evaluation
   ([monitor an agent](https://docs.cloud.google.com/agent-builder/agent-engine/manage/monitoring)).
2. Confirm **guardrails**: **Agent Gateway** policy + **Model Armor** (prompt-injection / data-leak
   defense) apply, and boundary tests (Testing Guide) pass — an agent must not surface data the caller
   is not entitled to.
3. This is the **review gate**: do not deploy until evaluation and boundary conformance pass.

### Step 7 — Deploy (bounded audience)
1. Deploy via **Agent Engine** (or publish in Gemini Enterprise) as `Agent Build – Pilot Project – Prod`.
2. **Share only to the approved audience** — if the admin enables sharing, owners can share to Google
   Identity groups; never leave an agent shared broadly
   ([share an agent](https://docs.cloud.google.com/gemini/enterprise/docs/agent-designer/share-agent)).
3. Run `GEMCONN-Validation.ps1` — confirm the agent's audience is within scope (audience read is
   preview / verify-in-tenant; the script prompts a console check).

### Step 8 — Monitor
1. Use **Agent Engine observability** — dashboards for token consumption, latency, error rates, and tool
   calls, plus OpenTelemetry traces (Cloud Trace/Monitoring/Logging)
   ([monitor an agent](https://docs.cloud.google.com/agent-builder/agent-engine/manage/monitoring)).
2. Watch the **Agent Security Dashboard** (Security Command Center) for anomaly/threat detection where
   available.
3. Run `GEMCONN-Report.ps1 -BaselinePath .\gemconn-baseline.json` each cycle to track connector/agent
   coverage-and-risk drift.

## Step 9 — Validate on the pilot, then expand
1. Run the **Testing Guide** — boundary/guardrail conformance must pass on the pilot connector and agent.
2. Only then **expand**: approve the next connectors against the same criteria, connect them, and build
   the next agents through the same design→review→deploy→monitor stages.
3. Re-validate each cycle with `GEMCONN-Validation.ps1` and track drift with `GEMCONN-Report.ps1`.

---
### Order of operations
`Confirm scope → define approval criteria → set boundary → connect pilot connector → design agent (register + identity) → review (evaluate + guardrails gate) → deploy (bounded audience) → monitor → validate → expand`
