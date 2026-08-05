# Best Practices

These are the practices that separate an agent governance model that *works* from one that becomes a
document nobody reads. They are drawn from the same operating-model discipline used for application
governance, adapted to the specific realities of business-user-built AI agents.

## Govern the sharing, not the building

The instinct is to lock down who can build agents. Resist over-tightening it. The productivity value
of Agent Builder comes from letting business users build; the *risk* comes from where those agents go
and what they reach. Put your strongest control on **org-wide sharing** and on the **org-catalog
publish gate**, and let building stay relatively open inside `AGBGOV – Agent Builders`. A model that
bans building will simply be bypassed; a model that reviews *sharing* is both safer and more welcome.

## Blocking is free — use it early, unblock later

The single most important operational habit: **any Agent Admin may block any agent immediately** on a
credible concern, with no meeting and no approval. Blocking is reversible. Treat it like a circuit
breaker, not a punishment. The organisations that get burned are the ones that require a change
request to block — turning a two-minute containment into a multi-hour exposure. Make "block first,
investigate second" an explicit, celebrated norm.

## Never delete as the first action

Deleting an agent is **permanent and irreversible**, and for maker-built agents only the maker can do
it. Always **block → notice period → delete**. The block is the safety; the notice period catches the
"actually, Finance still uses that every month" objection before it becomes an incident. Reserve
immediate deletion for agents that are both ownerless and demonstrably unused.

## Reassign before you orphan

When a maker leaves, their agents become ownerless — but many still deliver real value. Use the
admin center's **Agents without owners** view to triage: **reassign** a new owner where a business use
persists, and only retire the rest. An ownerless agent that is quietly reassigned keeps working; an
ownerless agent that is ignored becomes a shadow-agent risk.

## Make the register the source of truth for *accountability*, not inventory

Do not try to make the `AGBGOV – Agent Register` mirror every field the Agent Registry already holds.
The admin center is the technical inventory; the register exists to answer *who is accountable, what
was decided, and when is it next reviewed*. Keep it lean — owner, sponsor, reviewer, classification,
sharing scope, decision reference, review date — and let the scripts reconcile it against the
admin-center export.

## Tie the data review to the data, and reuse the Purview controls you already have

An agent's risk is a function of the **sensitivity of the sources it reads** and **how widely it is
shared**. Trigger the Data & Security Reviewer only when those cross a threshold (Confidential/
Restricted data, or org-wide sharing). Where a review finds a real data-processing concern, hand it
to the Copilot data-governance / DLP solution's controls (DLP for Microsoft 365 Copilot, sensitivity
labels) rather than inventing a new control here. Governance that reuses existing enforcement is
governance that sticks.

## Keep the ARB fast and cheap

A fortnightly, 45-minute board with a hard Tier 1 pre-approval rule is sustainable. A weekly
two-hour board is not, and a monthly board makes IT the bottleneck that drives users to share agents
around the gate. The Tier 1 standard-change rule (minor instruction tweaks, no source/data/sharing
change) typically removes the majority of the board's volume — protect it.

## Watch the "Agents at risk" signals — but don't rebuild those platforms

The Microsoft 365 admin center aggregates agent risk from Entra, Purview, and Defender — shadow
agents, ownerless agents, excessive-permission agents, sensitive-data-access, pending-approval. Put a
monthly review of that card on the Agent Admin's cadence. Your job in this model is to define *who
acts and when*; the detection is Microsoft's platforms' job. Do not attempt to reproduce those
signals in your own tooling.

## Treat review intervals shorter for agents than for apps

Agents drift faster than packaged applications — instructions get edited, sources get added, sharing
gets widened, all by business users, often without telling anyone. Do not exceed a 12-month review
interval for any tier, and review Tier 4 (regulated/critical) every 6 months. A lapsed review moves
the agent to `Deprecated` automatically.

## Announce the gate from the business, not from IT

When you make the intake form the only sanctioned route and tighten org-wide sharing, have the
**executive sponsor** send the announcement. A governance change announced by IT reads as a
restriction; the same change announced by the business sponsor reads as a standard. Adoption of the
model depends on this more than on any technical control.

## Government tenants: verify feature availability before you promise it

The operating model is identical in GCC / GCC High / DoD, but the **agent feature set is narrower and
evolving** and the `copilotPackages` Graph API is unavailable there. Seed and sweep from the Agent
Registry CSV export, and never promise a specific agent capability in a Government tenant without
first verifying its current availability against Microsoft's US-sovereign-cloud documentation.
