# Solution Overview

## The question this solves

You have people in your organization building **Copilot Agent Builder agents** — the lightweight
declarative agents users create inside Microsoft 365 Copilot — and you need two things a governance
owner always needs: a **complete inventory** of those agents (name, owner, when it was created and
last changed, whether it is published or blocked) and, for each one, **who it is shared with** (which
users and which groups). You tried to pull that from Microsoft Graph and the request was **blocked or
failed**, so you cannot tell whether the endpoint is wrong, your permissions are wrong, the feature is
not switched on in your tenant, or the data simply is not exposed.

This solution answers that question exactly, with a **supported, repeatable export method** you can run
on a schedule, and a **clear diagnostic** for why the Graph call fails and what to do about each cause.
It is scoped to **Agent Builder (declarative) agents only** — Copilot Studio agents are explicitly out
of scope (your Copilot Studio approval gates already govern those) — and it shows you how to **filter
the inventory to Agent Builder agents and exclude Copilot Studio** so the register stays clean.

## What a "Copilot Agent Builder agent" actually is

Agent Builder is the in-product builder inside Microsoft 365 Copilot (reachable from Copilot Chat →
**New agent**) that lets a user create a **declarative agent**: a name, instructions, starter prompts,
and optional knowledge sources (SharePoint files/folders, uploaded files, or web content). A
declarative agent reuses the Microsoft 365 Copilot orchestrator and models — it *declares* behavior and
knowledge rather than bringing its own model. These agents are **built for individuals and small teams**
and are shared with a link, not deployed across channels.

They are **not** the same as Copilot Studio agents. Copilot Studio is the standalone low-code maker
platform (`copilotstudio.microsoft.com`) that can build declarative agents *and* custom-engine agents,
publish them to many channels, and is governed through the Power Platform admin center. Both agent
types surface through some of the same admin and Graph surfaces, which is exactly why an inventory has
to be **filtered by the platform that built the agent** — otherwise you mix the two populations and the
register no longer means what you think it means.

## Where Agent Builder agents surface for an administrator

There are two administrator-facing surfaces, and this solution uses both:

1. **Microsoft 365 admin center → Agents.** The **Agent Registry** (Microsoft 365 admin center >
   **Agents** > **All agents** > **Registry**) is the central, no-code inventory of every agent
   available to your organization — Microsoft agents, external partner agents, agents *Published by
   your org*, and **agents *Shared by creator*** (the Agent Builder agents users have shared). It has an
   **Export** action that writes a CSV with 30-plus fields per agent (name, status, owner, publisher,
   platform, created/modified dates, and more). This is the **supported, no-extra-license** inventory
   path.
2. **Microsoft Graph — the Copilot Package Management API.** `GET /copilot/admin/catalog/packages`
   (list) and `GET /copilot/admin/catalog/packages/{id}` (per-agent detail) — the same API the
   customer tried. The **per-agent detail** call is the one that returns the granular
   **`allowedUsersAndGroups`** collection: the exact users and groups an agent is shared with. This is
   the programmatic, schedulable path, and it is the authoritative source for the **shared-with**
   detail.

## The beta endpoint reality (the direct answer)

The endpoint you tried — `GET /beta/copilot/admin/catalog/packages/{id}` — is **real, documented, and
the correct one** for per-agent detail, including sharing. It is the **Copilot Package Management API**.
The following facts are current as of this solution's build date and were verified against Microsoft
Learn; because the API moved from preview to release very recently, **treat version- and
tenant-rollout-specific behavior as volatile and verify against current Microsoft documentation**.

- **The namespace is correct.** The path is `/copilot/admin/catalog/packages` and
  `/copilot/admin/catalog/packages/{id}` — not `/admin/...` or `/solutions/...`. You had the right URL.
- **It is no longer beta-only.** Microsoft Learn now documents the API in **both `v1.0` and `beta`**.
  Prefer **`https://graph.microsoft.com/v1.0/copilot/admin/catalog/packages/{id}`** for production; the
  `beta` path still works and returns the same shape but carries the standard "subject to change"
  caveat. *(Verify against current Microsoft documentation — this GA'd recently and behavior is still
  settling.)*
- **The detail object DOES return sharing.** `GET .../packages/{id}` returns a `copilotPackageDetail`
  object whose **`allowedUsersAndGroups`** property is a collection of `{ resourceId, resourceType }`
  entries where `resourceType` is `user` or `group`. That is precisely the "who is this shared with"
  data you were looking for. The object also returns `acquireUsersAndGroups`, plus summary fields
  `availableTo` and `deployedTo` (each `all` / `some` / `none`).
- **The list call does NOT return the granular sharing list.** `GET .../packages` returns the summary
  `copilotPackage` objects — it tells you `availableTo`/`deployedTo` as `all`/`some`/`none` but **not**
  which users/groups. To get the recipients you must call `GET .../packages/{id}` **per agent**. That
  two-step (list → per-id) pattern is the core of the export method.
- **Why your call was blocked or failed** is almost always one of four things, and Troubleshooting
  gives you a decision tree that tells them apart: (a) the token is **missing the `CopilotPackages.Read.All`
  scope** or admin consent; (b) the signed-in identity **lacks a qualifying admin role**; (c) the
  **Microsoft Agent 365 licensing/entitlement** prerequisite the current docs state for this API is not
  met; or (d) the **API is not yet rolled out/enabled for your tenant** (it released tenant-by-tenant).
  A `403` points at (a)/(b)/(c); a `404` points at (d) or a wrong URL; a `401` is a token problem.

> **On Agent 365 (you told us you already ruled this out).** We acknowledge that. Note honestly,
> though, that the **current** Microsoft Learn pages for both the list and detail calls state: *"Access
> to the Package Management API requires a Microsoft Agent 365 license."* Earlier preview guidance
> implied a Copilot admin feature flag was enough. Because this changed as the API released, we treat
> the entitlement as a **must-verify** item in Requirements rather than asserting a single answer — and
> we give you a **no-Agent-365 fallback** (the admin center Registry export) so you can produce the
> inventory today regardless of how that entitlement resolves in your tenant.

## The supported export approach (what you build)

The solution delivers **two coherent paths to the same governance register**, and tells you when to use
each:

- **Path A — Microsoft 365 admin center (no code, no extra Graph entitlement).** Open the Agent
  Registry, **filter by Platform** to isolate *Microsoft 365 Copilot Agent Builder* agents (excluding
  Copilot Studio), and **Export to CSV**. This gives you the inventory columns (name, owner, status,
  dates, platform). It is the fastest way to a defensible inventory and it always works for an
  administrator.
- **Path B — Microsoft Graph Package Management API (repeatable, scriptable, includes granular
  sharing).** Connect with `CopilotPackages.Read.All`, **list** packages filtered to the Agent Builder
  platform and the `declarativeAgent` element type, then **call the per-id detail** for each to read
  **`allowedUsersAndGroups`**, and **resolve** those user/group object IDs to display names. Export to
  CSV/JSON and schedule it. This is the path that gives you the **shared-with** detail programmatically.

Both paths converge on one artifact you own and maintain: the **`Agent Builder Governance Register`** —
a spreadsheet/CSV with one row per Agent Builder agent, the sharing recipients resolved to names, and
review columns (owner-confirmed, sharing-approved, action). Testing proves the register is complete and
the sharing is accurate; Best Practices makes the export **recurring**.

## What is honestly available today, and what is not

- **Available:** a complete Agent Builder agent inventory (both paths); each agent's owner, status,
  created/modified dates, platform, and publish state; and — via Path B's per-id detail — the
  **users and groups an agent is shared with** (`allowedUsersAndGroups`).
- **Partial / verify:** the **Agent 365 entitlement** requirement for Path B, and the **tenant rollout**
  of the API, are both moving targets — Requirements and Troubleshooting tell you how to confirm your
  tenant's state rather than assuming.
- **Not exposed (be honest):** the Package API surfaces the **allowed** users/groups (the intended
  audience), not a runtime log of *who actually opened or ran* the agent — usage/telemetry is a
  different data source (Copilot usage reporting / audit logs) and is out of scope here. The register
  answers **"who can this agent reach,"** not **"who used it last Tuesday."**

## Government cloud

The Copilot Package Management API (Path B) is documented as available in the **Global** service only —
it is **not** available in **US Government L4 (GCC High)** or **US Government L5 (DoD)**, and not in
China (21Vianet). For those clouds, **Path A (admin center Registry export)** is the method, subject to
Agent Builder itself being available in that cloud — which has parity gaps you must verify. The scripts
still accept `-Environment Global|USGov|USGovDoD` and route Graph to `graph.microsoft.us` /
`dod-graph.microsoft.us`, but they will report clearly if the Package API is not present in that cloud
rather than fabricating a result. Requirements R7 and Troubleshooting T7 carry the detail. **Do not
assume GCC High parity — verify for GCC High.**

## Deployment model

The solution follows the standard model: **Assess → Configure → Pilot → Validate → Expand.** You
confirm prerequisites and pick a path, run a **preflight** that decodes exactly why (or that) Graph
works for you, export a **pilot** slice and reconcile it against the admin center, then widen to the
whole tenant and schedule the recurring export.

## What is in this solution

- **This overview** — what Agent Builder agents are, the surfaces, the beta-endpoint reality, and the
  two-path export approach.
- **Requirements** (`02-requirements.md`) — admin roles, exact Graph scopes, the Agent 365 entitlement
  reality, and tenant feature prerequisites, each with Description / Why / Verify / Implement-if-missing.
- **Implementation** (`03-implementation.md`) — the ordered build: connect, enumerate, filter to Agent
  Builder, resolve sharing, export, schedule.
- **Testing** (`05-testing.md`) — the pass/fail gates that prove the inventory is complete and the
  sharing is accurate.
- **Troubleshooting** (`06-troubleshooting.md`) — the blocked/failed-request decision tree.
- **Best practices** (`07-best-practices.md`), **deliverables summary** (`08-deliverables-summary.md`),
  and the **executive summary**.
- **Five PowerShell scripts** — preflight/failure-decoder, inventory export, sharing export, Agent
  Builder filter, and the governance-register report generator.
