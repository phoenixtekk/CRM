# Executive Summary — Microsoft Purview Automation Framework

## The problem
Microsoft Purview administration done by hand does not scale and does not repeat. Different admins create
policies differently, DLP and retention rules drift from what was designed, a label that should exist is
quietly missing, and when an auditor asks to see every policy and its current state the answer is a manual
scavenger hunt across an evolving portal. Manual Purview operations are a **compliance gap and a data-risk
exposure** — hard to reproduce, hard to review, hard to prove.

## The solution
A **configuration-as-code automation framework** for Purview operations. A single **declarative desired-
state config** describes the DLP policies, sensitivity labels, and retention policies the organization
intends to run; **PowerShell tooling** then **discovers** current tenant state, **deploys** the config
**into simulation/test/unpublished mode first**, **validates** deployed state against the config (drift
detection), and **reports** a policy inventory and coverage scorecard as evidence. Five safe-by-default
PowerShell tools (read-only or `-WhatIf` until you commit; nothing enforces without a separate, deliberate
`-Enforce -Commit`) run the health check, discovery, deployment, validation, and reporting. It uses only the
Purview portal, Security & Compliance PowerShell, and Microsoft Graph — no third-party tooling, no secrets.

## What you get
- **Policy as reviewable code** — DLP, label, and retention policies defined in a config file that is versionable, reviewable in change control, identical across pilot and production, and rebuildable after a mistake.
- **Safe-by-default deployment** — everything lands in DLP **test/simulation mode**, labels **unpublished**, retention **pilot-scoped** on deploy; **enforcement is a separate, explicit, committed action**.
- **Drift caught, not discovered late** — scheduled desired-state validation turns a silently edited or disabled policy into a reported difference.
- **Evidence on demand** — a policy inventory and coverage scorecard produced by script, not assembled by hand before every audit.
- **A repeatable operating rhythm** — a scheduled read-only chain (discover → validate → report) so posture stays known between changes.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate) →
Validate → Expand (enforce)** — deploying **pilot-first** into test/unpublished mode on a bounded scope,
with pass/fail gates and documented rollback before anything enforces tenant-wide.

## Boundaries
The framework **carries** compliance decisions faithfully and **proves** they landed; it does **not make**
them. *Which* sensitive info types, *which* retention duration, *which* labels, and whether a policy is
legally adequate are **deferred to compliance, records, privacy, and legal**. Microsoft Purview is
**licensing-/plan-dependent** (advanced DLP, auto-labeling, and several retention features require E5 / E5
Compliance; some are preview) and **actively evolving** — capabilities and cmdlet parameters, notably DLP
simulation/mode values, are cited or flagged **"verify your licensing/tenant,"** never invented. Records-
management, insider-risk, and communication-compliance objects are **out of automated scope**.

## The bottom line
Purview operations that are **repeatable, reversible, and evidenced** — policy defined as code, deployed in
simulation first, validated for drift, and reported on demand — so the compliance posture is **defensible,
not a manual scramble.**
