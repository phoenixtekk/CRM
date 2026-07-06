# 7. Best Practices — Gemini Connector Strategy & Agent Development Framework

Field-proven practices for expanding Gemini Enterprise capability **under control** — approved
connectors, enforced boundaries, and a governed agent framework — rather than an ungoverned sprawl.

- **Approve connectors against a classification, not a request.** Every connector gets a named owner, a
  data classification, and verified source ACLs before it is connected. An allow-list you can validate
  against (`GEMCONN-Validation.ps1 -ApprovedConnectorsPath`) is the difference between a strategy and a
  pile of ad-hoc integrations.
- **Trust the source ACL — but verify it.** Gemini *respects source permissions*, so a connected source
  is only as safe as its own ACLs and your identity mapping. Test with an entitled and an unentitled
  user (Testing Guide Test 3) on every connector; bad ACLs over-expose the moment they are indexed.
- **Bound before you build.** Put the **VPC Service Controls** perimeter, IAM least privilege, and
  residency in place *before* connecting a production source or exposing an agent — the boundary is what
  stops a connector or agent reaching further than approved.
- **Least privilege on the Gemini roles.** Grant `agentspaceAdmin` sparingly, `agentspaceUser` to those
  who need it, and use app-level IAM to scope users to specific apps. Admin is not a default.
- **Register every agent; bind an identity.** An agent that isn't in the **Agent Registry** with an
  **Agent Identity** is an ungoverned actor with no audit trail. Registration + identity is the entry
  price for any agent that touches enterprise data.
- **Gate on evaluation, always.** Run **Gen AI Evaluation** and boundary conformance *before* deploy — a
  no-code agent is as capable of leaking data as a coded one. Design → **review (gate)** → deploy →
  monitor; never skip the review gate.
- **Route tool calls through the gateway.** Let the **Agent Gateway** (with **Model Armor**) mediate what
  tools and connectors an agent may call, restricted to the same approved allow-list — one policy point,
  not per-agent trust.
- **Share to a group, never to everyone.** Deploy agents to a named Google Identity group audience; a
  broadly shared agent is the fastest path to accidental exposure (Testing Guide Test 9).
- **Monitor after deploy.** Watch token consumption, latency, error rates, tool calls, and traces in
  Agent Engine observability, and the Agent Security Dashboard for anomalies. An agent's risk is a
  living thing, not a launch-day checkbox.
- **Pilot one connector and one agent, then expand.** Prove the whole model — approval, boundary,
  design→review→deploy→monitor — on a narrow pilot before scaling; the same repeatable pattern is what
  keeps expansion governed.
- **Treat every preview specific as verify-in-tenant.** Connector names, Agent Platform components, and
  console paths are evolving. Cite Google's docs, confirm in your console and the release notes, and
  never build a control on an assumption about a rolling-out feature.
- **Keep a rollback for every change.** Disabling a connector (`GEMCONN-Remediation.ps1 -Action
  DisableConnector`) or unpublishing an over-shared agent must be a written, ready step before you make
  the change.
