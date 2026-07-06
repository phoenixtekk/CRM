# Executive Summary

## The opportunity and the risk

Google Workspace gives every team two ways to redesign work at speed: **Apps Script** (automation
and add-ons across Gmail, Drive, Sheets, and the Workspace APIs) and **AppSheet** (no-code apps and
workflow automation on top of your data). They let the business rebuild a workflow in hours instead
of quarters. Left ungoverned, the same speed produces **shadow IT** — scripts and apps that read and
move corporate data on broad OAuth scopes, share outside the organization, and have no owner, no
review, and no rollback.

## What this solution establishes

A **work-transformation governance model** that keeps the speed and removes the exposure. It targets
the three places the risk actually concentrates — **data access** (OAuth scopes and connected
sources), **sharing** (who can run an automation and see its data), and **app access itself** (can
users build/run these at all) — and channels each with a layered control:

- **Admin guardrails (the floor).** In the Google Admin console: Apps Script **app access control**
  (trusted/limited/blocked and high-risk OAuth-scope restriction) and the **AppSheet** security
  setting or **Enterprise Plus governance policies** (require sign-in, restrict external sources,
  block external sharing, control who can deploy, and data region).
- **Approval & review pattern (the process).** A tiered review — low-risk automations self-serve;
  shared, broad-scope, or regulated builds go through a named reviewer against a one-page checklist
  before they can be marked deployed.
- **Environment & sharing standards (the structure).** Named **Build → Pilot → Production**
  environments, internal-only sharing defaults, an owner of record on every artifact, a rollback
  path, and a reuse baseline of blessed templates and shared libraries.

## How it's delivered

Self-guided and pilot-first, following **Assess → Configure → Pilot → Validate → Expand** with
explicit pass/fail gates and documented rollback. Seven guides plus five PowerShell scripts —
read-only **Discovery**, **Validation**, and **Report** for inventory, conformance, and risk; a
default-preview (`-WhatIf`) **Remediation** helper; and a **Set-ScopeTargeting** scope helper — turn
"we have Apps Script and AppSheet out there somewhere" into a governed, inventoried, reviewed
capability.

## The bottom line

Business-led workflow automation that is fast **and** safe — Apps Script and AppSheet governed with
guardrails, approvals, and standards — deployed to a pilot first and rollback-ready. Citizen and pro
developers redesign workflows to enterprise standard, at a fraction of the cost of bespoke
consulting, without turning speed into shadow IT.
