# Executive Summary — Entra ID Governance: Access Reviews & Entitlement Management

## The problem
Access sprawl is the default outcome in any growing tenant. Guests invited for one project stay
forever, employees accumulate group and app access as they change roles, and standing membership of
privileged and sensitive groups is never re-checked. When an auditor asks "who has access to this and
why — and who approved it," the honest answer is usually a spreadsheet assembled by hand the night
before. The cost is real: failed access recertifications, over-privileged accounts that widen the
breach blast radius, and IT time burned on manual joiner/mover/leaver tasks.

## The solution
This solution operationalizes **Microsoft Entra ID Governance** so access is **requested, approved,
time-bound, reviewed, and revoked automatically** across three levers:
1. **Entitlement management** — publish **access packages** (bundles of groups, apps, and SharePoint
   sites) in **catalogs**, governed by **approval and lifecycle policies**, so users request access and
   it is granted with an expiry instead of assigned by hand and left forever.
2. **Access reviews** — recurring recertification of **group members, application assignments, and
   guests**, with reviewers who approve or remove access and an auto-apply decision, producing the audit
   evidence recertification demands.
3. **Lifecycle workflows** — automated **joiner / mover / leaver** tasks (enable account, send welcome,
   remove group memberships, disable and revoke on exit) triggered by employee lifecycle attributes.

Delivery follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model: build and
prove one catalog, one access package, one review, and one workflow against a **pilot** group first,
confirm explicit pass/fail gates, then expand to the full scope — each step reversible.

## What's included
Full documentation (overview, requirements, ordered implementation, testing matrix, troubleshooting,
best practices) plus **five PowerShell (Microsoft Graph) tools** that inventory the current governance
posture, validate the named objects are in place, export audit/recertification evidence, report on stale
guest access, and preview lifecycle-workflow changes. Every tool is **read-only or `-WhatIf` by
default**, uses least-privilege Graph scopes, and stores **no credentials**.

## Business value
- **Least privilege maintained automatically** — access expires and is re-certified instead of
  accumulating.
- **Audit-ready** — every grant has a request, an approver, and a review decision on record.
- **Fewer manual tickets** — joiner/mover/leaver tasks and access requests are automated and delegated.
- **Repeatable and reversible** — a pilot-first, gated method with a documented rollback for every change.

## Effort and boundary
A competent identity admin can stand up the pilot (one catalog, package, review, and workflow) in a few
focused sessions, then expand in waves. This is a **technical implementation** guide: it provides the
controls and the automation. **Which** roles, groups, and guests must be reviewed, **how often**, and
**who** the approvers and reviewers are remain the customer's governance, security, and compliance
decisions.

> **Licensing note:** entitlement management, access reviews, and lifecycle workflows require **Microsoft
> Entra ID Governance** (or the features formerly covered by **Entra ID P2**). Lifecycle workflows and
> some entitlement-management capabilities are part of the **Entra ID Governance** SKU specifically.
> *Verify current licensing and feature availability in your tenant before you begin.*
