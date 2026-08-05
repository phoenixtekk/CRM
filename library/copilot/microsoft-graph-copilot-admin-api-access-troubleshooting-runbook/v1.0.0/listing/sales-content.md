# Sales Content — Microsoft Graph Beta Copilot Admin API Troubleshooting Runbook (CPADMDX)

## The hook
Turn an ambiguous Copilot admin **403** into one named cause — and unblock it.

## The problem
You called a Microsoft Graph Copilot admin (beta) endpoint — most likely
`GET /beta/copilot/admin/catalog/packages/{id}` to read the agent catalog — and it came back blocked.
The body says *"Access is denied to the requested resource,"* or *"User context is required,"* or a
bare 404, and the preview documentation will not tell you which of a dozen unrelated causes is real:
missing scope, missing admin role, app-token-vs-user-token, ungranted consent, a preview that has not
reached your tenant, a cloud where the feature does not exist, a license prerequisite, a wrong path,
throttling, or a capability that is simply not there yet.

## Run it yourself — simpler, cheaper, proven
- **Simpler** — Step-0 fact-finding then Branches A–J that map your exact status + error text to one
  root cause; the 401-vs-403 and scope-vs-role distinctions made concrete; every artifact named
  (`CPADMDX-Diagnostics`, `CPADMDX-Findings.json`) and reused.
- **Cheaper** — one fixed price instead of an open consulting meter (~$1,500–$3,000/day comparable);
  reusable on the next preview-API investigation.
- **Tested** — Assess → Configure → Pilot → Validate → Expand, with five PASS/FAIL gates that prove the
  call now works *and* whether the data is actually exposed.

## What's inside
- **Solution Overview** — the `/beta/copilot/admin/*` surface (package catalog, policy settings, usage
  reports), the GA-vs-beta support posture, and the diagnostic model.
- **Requirements** — nine prerequisites (tooling, delegated admin, exact scopes
  `CopilotPackages.Read.All` / `CopilotPolicySettings.Read`, the **AI Administrator** role, consent,
  correct cloud, licensing, tenant flighting, evidence file), each Description/Why/Verify/Implement.
- **Diagnostic Runbook** — Step 0 plus **ten branches (A–J)**: 401 auth; app-only "user context
  required"; missing scope; ungranted consent; missing admin role; cloud not enabled (Global-only —
  GCC High/DoD excluded); license (Agent 365 — acknowledged and excluded); wrong path/version;
  throttling; genuine limitation.
- **5 read-only PowerShell scripts** (Graph, GET-only, `-Environment Global|USGov|USGovDoD`): preflight,
  endpoint probe/decoder, scope/role resolver, fallback tester, findings consolidator — none fabricate
  a beta response.
- **Testing & Troubleshooting** with five gates and the preview traps (throttling, flighting,
  undocumented-endpoint deprecation), plus **Best Practices** on beta-vs-GA dependency.

## Accuracy on a moving target
Every endpoint path, scope, admin role, license requirement, error meaning, and cloud-availability fact
verified against Microsoft Learn on the build date; every preview-volatile claim flagged *"verify
against current Microsoft documentation."* Where data is not exposed or beta cannot be relied on, the
runbook says so and points to the supported path — it never invents an endpoint or a response shape.

## Bottom line
A blocked Graph Copilot admin call turned into a single named cause and fixed — or, where beta cannot be
relied on, a proven supported alternative delivering the data you need — with a repeatable method and
scripts you keep and reuse.

## Tiers
- **Commercial** — $1,995.00
- **Non-Profit** — $1,197.00 (40% off; eligibility verified)
- **Government** — $1,695.75 (15% off; US Gov Graph aware; eligibility verified)

## Dedupe note (internal)
Sibling product **AGBINV** (Copilot Agent Builder — Inventory, Sharing, Governance & Export) owns the
agent inventory + sharing export deliverable. **CPADMDX** is the deep, general troubleshooting runbook
for the `/beta/copilot/admin/*` API surface itself; it references AGBINV for the export rather than
reproducing it.
