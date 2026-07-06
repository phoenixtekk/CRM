# Solution Overview

## Apps Script & AppSheet Work-Transformation Governance

Google Workspace ships two of the most powerful low-friction automation platforms in the
enterprise: **Apps Script** (script-based automation and add-ons across Gmail, Drive, Sheets,
Docs, Calendar, and the Workspace APIs) and **AppSheet** (no-code apps and workflow automation
built directly on Sheets, databases, and connected data sources). Both let a business team
redesign a workflow in hours instead of quarters — and both, ungoverned, become **shadow IT**:
scripts and apps that read and move corporate data, run on broad OAuth scopes, and share outside
the organization with no review, no owner of record, and no rollback plan.

This solution establishes a **work-transformation governance model** for Apps Script and AppSheet
so that citizen developers (business users) and pro developers (IT/engineering) can redesign
workflows **safely and to a repeatable enterprise standard**. It is not a lockdown — it is a set of
guardrails, an approval and review pattern, and environment/sharing standards that channel the
speed of these platforms without exposing data.

### Where the risk actually is

Governance is only useful if it targets the real exposure. For Apps Script and AppSheet, the risk
concentrates in three places:

1. **Data access (OAuth scopes and connected sources).** An Apps Script project runs with the
   authorizing user's OAuth grants; a broad scope (for example, full Drive or full Gmail) lets the
   script read or move anything that user can. AppSheet apps connect to Sheets, Cloud SQL, and
   third-party sources and inherit that data. The guardrail question is: *what data can this
   automation touch, and did anyone approve that reach?*

2. **Sharing (who can run it, who can see the data).** Apps Script web apps and add-ons can be
   deployed "anyone with the link" or shared org-wide; AppSheet apps can be shared to external
   users or entire domains. Uncontrolled sharing is the fastest path from a helpful internal tool
   to a data-leakage incident.

3. **App and script access itself (can users even build/run these).** At the platform level, the
   Google Admin console controls whether Apps Script projects and AppSheet apps can access
   Workspace data at all, whether they must be **trusted/limited/blocked**, and — for AppSheet —
   whether sign-in, external sources, and external sharing are permitted. This is the outermost
   guardrail and the one IT owns directly.

### How governance channels it

The model layers three controls so that speed and safety coexist:

- **Admin guardrails (platform).** In the Google Admin console, IT sets **app access control** for
  Apps Script (trusted/limited/blocked, OAuth-scope restriction for high-risk Gmail/Drive scopes)
  and the **AppSheet security setting** or **AppSheet governance policies** (require sign-in,
  restrict external data sources, restrict external sharing, control who can mark an app as
  deployed, and data region). These are the non-negotiable floor.

- **Approval & review pattern (process).** A lightweight, tiered review: low-risk automations
  (personal-scope, internal-only) self-serve; medium/high-risk automations (broad scopes, shared,
  or touching regulated data) go through a named reviewer against a checklist before they are
  marked deployed. AppSheet's *"only certain people can mark apps as deployed"* policy and Apps
  Script's deployment control make this enforceable, not just aspirational.

- **Environment & sharing standards (structure).** Named environments — **Build** (draft/dev),
  **Pilot** (a scoped OU/group), and **Production** — with agreed sharing defaults (internal-only
  unless approved), owner-of-record on every artifact, and a rollback path. Reuse is explicit:
  shared libraries/templates for Apps Script, and a small set of blessed AppSheet templates and
  connected-source patterns, so builders start from a governed baseline instead of a blank canvas.

### Deployment model

Like every solution in this library, deployment follows **Assess → Configure → Pilot → Validate →
Expand**, with explicit pass/fail gates and a documented rollback for any production change:

- **Assess** the current estate — inventory existing Apps Script projects and AppSheet apps, their
  scopes, owners, and sharing (the Discovery script).
- **Configure** the admin guardrails and the review/environment standard.
- **Pilot** on a named OU/group, proving builders can still ship and that guardrails hold.
- **Validate** against conformance gates (the Validation script) before expanding.
- **Expand** to the wider organization once the pilot passes.

### What this solution delivers

Seven guides (overview, requirements, implementation, testing, troubleshooting, best practices, and
deliverables summary) plus five supporting PowerShell scripts — a read-only **Discovery** inventory,
a **Validation** guardrail-conformance check, a **Report** on automation coverage and risk, a
default-`-WhatIf` **Remediation** helper, and a **Set-ScopeTargeting** scope helper. Together they
turn "we have Apps Script and AppSheet somewhere out there" into a governed, inventoried, and
reviewed capability that the business can use at speed.

> **Bottom line:** Business-led workflow automation that is fast *and* safe — Apps Script and
> AppSheet governed with guardrails, approvals, and standards — not shadow IT.
