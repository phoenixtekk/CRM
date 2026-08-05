# Executive Summary

## The situation

Your organisation has given business users the ability to build their own AI agents. Inside
Microsoft 365 Copilot, a non-technical employee can use **Agent Builder** to create a declarative
agent in minutes — point it at SharePoint sites, Teams chats, or public websites for knowledge, and
then share it with a colleague, a team, or the **entire organisation**, with no code and, in most
tenants, with no visibility for IT or Security.

That capability is a genuine productivity gain. It is also an ungoverned surface. Agents built this
way accumulate as **ownerless** (the creator left), **unreviewed** (shared more widely than intended,
over data nobody assessed), and **shadow** (running with no registry entry and no accountable owner).
The platform's own approval gates help for Copilot Studio agents — but a declarative **Agent Builder**
agent shared with *"Anyone in your organization"* can reach the whole tenant **with no approval at
all**. That specific gap is what this solution closes.

## What this solution delivers

This is a **governance operating model** — the organisational policy layer for business-process
agents. It is deliberately *not* a technical export tool and *not* a data-governance product; it
defines **who may build a business agent, on what basis it is allowed into business use, who it may be
shared with, who is accountable afterwards, and when it is retired** — and it expresses each of those
decisions as a concrete, enforced control in the Microsoft 365 admin center.

It provides, ready to adopt:

- A **four-role accountability model** (Agent Owner, Business Sponsor, Data & Security Reviewer, Agent
  Admin) with a RACI matrix and escalation rules.
- An **intake and approval gate** and a standing **Agent Review Board**, closing the org-wide-sharing
  gap.
- A published **standards document** (data-and-sharing review criteria, naming, supportability) and a
  **sharing policy** with periodic access review.
- A full **lifecycle and retirement** process — including the block-then-delete discipline that makes
  retirement safe and evidenced.
- **Five read-only Microsoft Graph PowerShell scripts** to baseline the estate, validate the
  governance gates, produce a trendable scorecard, assemble approval evidence, and flag broadly-shared
  agents for review.
- The exact **admin-center enforcement steps** (Copilot Control System agent access and sharing
  controls; Agent Registry block/reassign/publish), verified against Microsoft Learn on the build
  date.

## How it connects to what you already own

The model **references, rather than rebuilds**, your existing Copilot controls: it triggers the
Copilot data-governance / DLP guardrails and the SharePoint oversharing remediation where a data
review demands them, and it consumes the deep agent inventory/export from its sibling product. It
watches the admin center's **"Agents at risk"** signals (aggregated from Microsoft Entra, Purview, and
Defender) and defines who acts on them — without reconfiguring those platforms.

## Why run it yourself

The package is self-guided, click-by-click documentation a novice administrator can follow end to
end, plus tested scripts and every governance artefact pre-named. You do not need a consultant to
stand up agent governance: you need the operating model, the exact admin surfaces, and the discipline
of a pilot-first rollout — all of which are here.

## The outcome

Within two board cycles you move from an unknown, ungoverned agent estate to a measured one: every
business agent owned, sensitive agents reviewed, org-wide shares approved, ownerless agents reassigned
or retired, and a monthly scorecard that proves the model is working. The delta between the Step 1
baseline and the first steady-state scorecard is your business case — fewer ownerless agents, fewer
unreviewed org-wide shares, and a defensible audit trail for every approval.

*The governance process is identical for Commercial and US Government (GCC / GCC High / DoD) tenants;
only portal URLs and agent feature availability differ, and both are documented inline. Agent admin
surfaces evolve quickly — volatile specifics are flagged "verify against current Microsoft
documentation."*
