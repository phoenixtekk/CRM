# 5. Testing Guide — Gemini Connector Strategy & Agent Development Framework

Run after the pilot connector is connected and the pilot agent reaches the **review gate**
(Implementation Steps 4 and 6), again after deploy (Step 7), and after each expansion cycle. These are
**boundary and guardrail conformance gates** — an agent or connector must not surface data a caller is
not entitled to. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names.

> **Preview note.** Some agent audience/registry surfaces are rolling out; where a test cannot be read
> via a stable API, perform it in the console and record the result — **verify in your tenant** rather
> than assume a pass.

## Test 1 — Connector is on the approved allow-list
**Do:** Run `GEMCONN-Validation.ps1 -ProjectId 'your-project-id' -ApprovedConnectorsPath .\approved-connectors.txt`.
**Expected:** Every connected data store appears on the allow-list; no unapproved connector is present.

## Test 2 — Data-access boundary present
**Do:** Run `GEMCONN-Validation.ps1`; or check **VPC Service Controls** and org policies in the console.
**Expected:** A service perimeter (`Data Access Boundary – Pilot Project – Prod`) and org policy
constraints cover the project — **PASS**; missing boundary is **WARN/fail**.

## Test 3 — Source ACLs are respected (the core boundary test)
**Do:** As **User A** (entitled to a document in the source) and **User B** (not entitled), issue the
same Gemini Enterprise query that would surface that document.
**Expected:** User A sees it; **User B does not** — Gemini respects the source ACL. If User B sees it,
identity mapping or the source ACL is wrong — fix before proceeding
([identity/access control](https://cloud.google.com/agentspace/agentspace-enterprise/docs/identity)).

## Test 4 — IAM least privilege
**Do:** Run `GEMCONN-Set-ScopeTargeting.ps1`; review the `discoveryengine.*` bindings.
**Expected:** `agentspaceAdmin` is held only by admins; users hold `agentspaceUser`; no unexpected broad
grants — least privilege confirmed.

## Test 5 — Agent registered and identity-bound
**Do:** Confirm the pilot agent is in the **Agent Registry** and has an **Agent Identity**; or note the
console state.
**Expected:** The agent is a governed, registered asset with a unique identity and audit trail — **PASS**.
*(If the registry/identity component is not yet available, record the process-enforced equivalent —
verify-in-tenant.)*

## Test 6 — Agent tools/connectors are the approved set only
**Do:** Inspect the agent's allowed tools/connectors (Agent Gateway / tool governance).
**Expected:** The agent can call **only** approved connectors from the Step 2 allow-list — no
unapproved source or tool is reachable.

## Test 7 — Agent evaluation gate passed
**Do:** Run **Gen AI Evaluation** (AutoRaters / User Simulator / online evaluation) and review results
([monitor an agent](https://docs.cloud.google.com/agent-builder/agent-engine/manage/monitoring)).
**Expected:** The agent meets the agreed quality/safety thresholds — the **review gate** passes before
deploy. A failing evaluation blocks deployment.

## Test 8 — Guardrails active (gateway + Model Armor)
**Do:** Submit a prompt-injection / data-exfiltration probe to the agent.
**Expected:** The **Agent Gateway** policy and **Model Armor** block or neutralize it; the attempt is
logged — the guardrail holds.

## Test 9 — Agent audience is bounded
**Do:** Confirm the deployed agent (`Agent Build – Pilot Project – Prod`) is shared only to its approved
Google Identity group; `GEMCONN-Validation.ps1` prompts this console check.
**Expected:** No agent is public or shared beyond its approved audience.

## Test 10 — Coverage-and-risk / drift report
**Do:** Run `GEMCONN-Report.ps1 -BaselinePath .\gemconn-baseline.json`.
**Expected:** A clear coverage-and-risk report — connectors by type, agent count, unapproved connectors,
boundary present, a risk tally, and drift versus the saved baseline.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Connector pass** | Tests 1–4 pass — connector approved, boundary present, **source ACLs respected**, IAM least privilege |
| **Agent review gate** | Tests 5–8 pass — registered + identity-bound, approved tools only, evaluation passed, guardrails active — *before* deploy |
| **Deploy pass** | Test 9 passes — audience bounded |
| **Expand pass** | Tests 1–10 pass on the pilot before approving/connecting the next connector or agent |
