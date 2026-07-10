# 1. Solution Overview — Azure Landing Zone with Bicep

## What an Azure landing zone is
An **Azure landing zone** is a pre-built, governed foundation you deploy *before* you put workloads in Azure. Instead of one flat subscription, you get a **management-group hierarchy** (a tree that lets one control apply to many subscriptions), **policy guardrails** that keep every subscription compliant, an **identity and RBAC baseline** so access is least-privilege from day one, and a **hub-spoke network** that gives workloads a consistent, centrally-controlled connectivity model. This solution builds that landing zone as **Bicep** — Microsoft's native, declarative infrastructure-as-code language that compiles to Azure Resource Manager (ARM) — so the entire foundation is code in Git, not clicks in a portal.

## How Bicep works
Bicep is a domain-specific language for describing Azure resources. You write `.bicep` files that declare *what* you want (a management group, a policy assignment, a virtual network); the Bicep CLI transpiles them to ARM JSON; and Azure deploys them idempotently — running the same file twice converges to the same state rather than creating duplicates. Two features make it safe for a landing zone:

- **`what-if`** — before any deployment, `az deployment ... what-if` shows exactly which resources will be **created, modified, or deleted**. Nothing is applied until you have read the preview.
- **Deployment stacks** — a deployment stack is a managed grouping of resources deployed from Bicep. It tracks everything it created, can **deny** out-of-band changes to those resources (drift protection), and can be **updated or deleted as a unit** — which is your rollback.

Because Bicep targets ARM directly, there is **no third-party state file and no separate provider to manage** — the deployed Azure resources are the source of truth, and Azure itself stores deployment history.

## What the landing zone contains
1. **Management-group hierarchy** — a root intermediate group with child groups (for example `Platform`, `Landing Zones`, `Sandbox`, `Decommissioned`) so one policy or role assignment covers many subscriptions from a single point.
2. **Azure Policy and initiatives as Bicep** — policy definitions and initiative (policy set) *assignments* declared in `.bicep` and assigned at management-group scope, in **audit** effect first and promoted to **deny** on a controlled gate.
3. **Identity / RBAC baseline** — custom role definitions and least-privilege role assignments as Bicep, removing standing Owner in favor of scoped, purpose-built access (and PIM-eligible assignments where Entra ID P2 is licensed — *verify current availability in your tenant*).
4. **Hub-spoke networking and DNS** — a central **hub** virtual network (gateway subnet, a firewall/`AzureFirewallSubnet`, shared services) and **spoke** VNets peered to it, plus **private DNS zones** for private-endpoint name resolution.
5. **Deployment stacks + CI/CD** — the whole thing deployed via deployment stacks through an **Azure DevOps or GitHub Actions** pipeline that runs `what-if`, requires approval, then deploys.

## What you can control
- **Hierarchy shape** — which management groups exist and which subscriptions sit under each.
- **Guardrail effect** — audit (report) or deny (block) per policy/initiative, moved on a gate.
- **Least-privilege access** — custom roles, removal of standing Owner, scope-narrowed assignments.
- **Network topology** — hub address space, spoke count and ranges, peering, firewall subnet, private DNS zones.
- **Rollout scope** — non-production management group first, production only after validation and approval.

## Limitations (be honest with buyers)
- A landing zone governs *how* resources are created; it does not migrate or re-home resources that **already exist** outside it — those are brought under management separately.
- **Deployment stacks** and some policy effects/features may be in preview or vary by region and by Azure environment (Commercial vs. Government) — *verify current availability in your tenant before relying on them.* The specific ARM API versions in `main.bicep` are marked to verify.
- Certain capabilities require licensing — for example **PIM** for eligible role assignments needs **Entra ID P2** — *verify current availability in your tenant.*
- Moving guardrails to **deny** can block legitimate deployments; this is exactly why the model pilots in audit against a non-production scope first and keeps a rollback.
- This is the platform foundation; it does not replace workload security, backup, or patching.

## Authentication and connections used
- **Azure CLI / Az PowerShell** signed in as an identity with **Owner** (or Owner + User Access Administrator) at the deployment scope, for local `what-if` and discovery.
- A **CI/CD service connection** to Azure using **workload identity federation (OIDC)** — no stored secret — scoped to the deployment target (per Global Requirements G4).
- **Microsoft Graph / Entra** is touched only for role and PIM assignment; the network and policy work is pure ARM.

## The standard deployment model
> **Assess the current estate (subscriptions, existing policy/RBAC/network) → configure the Bicep repo, hierarchy, policy, identity, and network modules → pilot by deploying to a non-production management group with policy in audit → validate with what-if, the testing script, and a policy-compliance pass → expand to production behind pipeline approval, then promote guardrails to deny.** The repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, what-if-first and approval-gated, with deployment-stack rollback.
