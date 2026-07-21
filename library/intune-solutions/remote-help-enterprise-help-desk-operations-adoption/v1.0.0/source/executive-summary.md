# Executive Summary — Remote Help for the Enterprise Help Desk (Operations, Unattended Access & Adoption)

**White-label · Intune Solutions**

Deploying Remote Help is the easy part; **running it as a help-desk capability** is where the value
is won or lost. Once the app is enabled and installed, an enterprise still needs the operating
model: who can help whom, when unattended access is appropriate and how it is governed, how a
session fits the ticket and escalation workflow, how usage and outcomes are measured, and how end
users learn to trust and request help. This package delivers that operating model.

> **Prerequisite:** this solution **assumes Remote Help is already deployed** — see the separate
> **Remote Help** solution (slug `remote-help`), which covers enable, app deployment, and the base
> security model. This package is the **operations and adoption layer on top** and does **not**
> repeat that setup.

This is a complete, self-guided package written for an administrator who has Remote Help deployed
but has not yet turned it into a governed, measured, widely-used help-desk service.

## What you get
- A **Solution Overview** of the operating model and exactly what it adds vs. the base deployment.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (base
  deployment, tier definition, RBAC rights, licensing, unattended governance, ticketing, reporting).
- An **Implementation Guide** of precise, ordered steps: tier agent groups, scope groups, per-tier
  RBAC roles, unattended-access governance, role assignment with scope, the session-to-ticket
  workflow, KPI reporting, a pilot, and an adoption campaign — every object named and reused.
- Five **PowerShell scripts** for discovery, validation, KPI reporting, scope-proofing, and a
  `-WhatIf`-gated role/scope assigner.
- **Testing** (PASS/FAIL) and **Troubleshooting** guides for confident rollout.

## What this delivers
Help-desk **tiers mapped to Remote Help RBAC roles and scope** so agents help exactly the right
users and no more; **governed, guard-railed unattended access** owned by a single tier; a
**session-to-ticket workflow** with tier escalation; **usage/outcome/adoption KPI reporting**; and an
**adoption campaign** that gets end users requesting help and agents using the tool — piloted, then
expanded.

## Verify-with-Microsoft note
Remote Help's role/permission names, portal navigation, and — critically — whether and how
**unattended access** is offered change over time. This guide governs the *practice* and names every
object you create; it flags Microsoft-owned capability specifics to **verify against current
Microsoft documentation** rather than asserting them.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Remote Help operating as a real help-desk capability — right-scoped roles, governed unattended
access, a traceable session-to-ticket workflow, outcome reporting, and genuine adoption.
