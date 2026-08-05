# Copilot Agent Governance & Operating Model (Declarative Agents — Build, Approve, Share, Retire)

**Slug:** `copilot-agent-governance-operating-model-declarative-agents`
**Category:** Copilot (`copilot`) · **Sol code:** `AGBGOV` · **Version:** v1.0.0
**Status:** generated · **Branding:** OFF (white-label) · **Version directive:** New
**gov_variant:** false (Government differences documented inline)

## What this is

The governance **operating model** for business-user-built **declarative agents** (Agent Builder /
Copilot Studio / SharePoint agents). It defines who may build a business agent, on what basis it
enters business use, who it may be shared with, who is accountable, and when it is retired — and
expresses each decision as an enforced control in the Microsoft 365 admin center (Copilot Control
System + Agent Registry).

Closes the specific gap: Copilot Studio agents already pass an admin publish-approval gate; an Agent
Builder declarative agent shared "Anyone in your organization" can reach the whole tenant with no
approval. This governs that.

## Pricing (T3 — Advanced)

| Tier | SKU | Price |
|---|---|---|
| Commercial | PTK-AGBGOV-COMM-001 | $2,495.00 |
| Non-Profit | PTK-AGBGOV-NPO-001 | $1,497.00 |
| Government | PTK-AGBGOV-GOV-001 | $2,120.75 |

## What's included

- **Source docs:** solution overview, requirements (+ category global requirements), 13-step
  implementation, testing (8 PASS/FAIL gates), troubleshooting, best practices, deliverables summary,
  executive summary.
- **5 PowerShell scripts** (read-only, `-Environment Global|USGov|USGovDoD`): AGBGOV-Discovery,
  AGBGOV-Validation, AGBGOV-Report, AGBGOV-Export-ApprovalEvidence, AGBGOV-Review-SharedAgents.
- **Deliverables:** AGBGOV-Solution.pdf, AGBGOV-Solution.docx, AGBGOV-Scripts.zip,
  AGBGOV-Complete-Solution.zip, AGBGOV-hero.png/.svg.
- **Listing:** bagisto-products.json (3 products), sales-content.md, hero.json.

## Scope boundary (dedupe)

- Deep inventory/sharing export + Graph endpoint diagnostic → sibling
  `copilot-agent-builder-inventory-sharing-governance-export` (referenced, not reproduced).
- Copilot data governance (labels/DLP/audit) → the Copilot data-governance / DLP guardrails solution.
- SharePoint oversharing remediation → the Copilot oversharing / SharePoint-permissions solution.
- How to build an agent → the maker's task in Agent Builder / Copilot Studio.

## Verified facts (Microsoft Learn, 2026-07-24)

Agent Builder sharing (Only you / Specific users / Anyone in your org); Copilot Control System agent
access + org-wide sharing controls (All users / Specific users or groups / No users); org-catalog
submit → admin approve/reject → "Built by your org"; Agent Registry (Agents > All agents > Registry)
block/reassign/export + Agents-without-owners / Unmanaged / Agents-at-risk; AI Administrator
least-privilege role; copilotPackages API `GET /copilot/admin/catalog/packages`
(`CopilotPackages.Read.All`, requires Microsoft Agent 365 licence, **Global only** — not GCC
High/DoD). Government: publishing agents to the org IS supported in GCCH/GCCM; agent feature set is
narrower/evolving — volatile specifics flagged "verify against current Microsoft documentation".

## Next step

Open `library\_index\INDEX.html` to review, then run `/publish-solution
copilot-agent-governance-operating-model-declarative-agents`.
