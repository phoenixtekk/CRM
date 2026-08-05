# Enterprise Application Management Governance & Operating Model (Microsoft Endpoint / Intune)

## Stop asking "who owns this app, and who said we could deploy it?"

Most teams can package and deploy an application. Almost none can say **who owns it, who approved it,
on what evidence, and who supports it.** So the estate quietly fills with orphaned apps assigned to
groups nobody maintains, apps never security-reviewed, apps deployed past their licence, and apps
kept alive by one engineer who "just knows how it works." Better tooling does not fix this — the
missing capability is not technical, it is an **operating model**.

This package is that model: named roles, a controlled front door, a review board that can actually
say no, published standards, ringed change control, and a support model with real escalation — with
every governance decision expressed as a concrete object inside Intune and Entra so the platform
enforces it, not a slide deck that sits in a folder.

## Run it yourself — simpler, cheaper, and proven

You do **not** need a consultant. The package hands you the field-tested operating model as
**self-guided, click-by-click documentation** a competent admin and their leadership can stand up end
to end, backed by ready-to-run PowerShell that reads and measures your real estate.

- **Simpler** — fourteen ordered steps with full navigation paths; every role, group, scope tag, and
  forum is named exactly and reused through testing and troubleshooting.
- **Cheaper** — one fixed price instead of an open meter; comparable governance consulting runs well
  into the thousands per day. It is reusable as a permanent capability your team keeps.
- **Tested** — a pilot-first method (Assess → Configure → Pilot → Validate → Expand) with eight
  explicit pass/fail gates, so you prove the model on one business unit before committing the estate.

## What's inside

- **Ownership & RACI** — four named accountabilities per app (Application Owner, Technical Owner,
  Security Reviewer, Deployment Engineer), the Application Register schema, and the escalation rules
  that make them real.
- **Intake & the Application Review Board** — a controlled front door with return criteria, and a
  standing forum with defined cadence, quorum, evidence packs, and four binding decision types, plus
  a standard-change rule that removes 60–80% of the board's volume.
- **Standards & risk-tiered change** — a published definition of "approved," security-review and
  licensing criteria, a naming standard, a four-tier change classification matrix, deployment rings,
  approval-free rollback, and a Change Advisory Board interface.
- **Operational support model** — an L1/L2/L3 split defined by action not seniority, severity-based
  SLAs, and a runbook standard that makes support an organisational asset instead of one person's
  memory.
- **Platform integration** — how the model plugs into Intune scope tags, a least-privilege custom
  role, Entra ring groups, and your security stack (App Control / WDAC, Defender for Endpoint, App
  Protection). The interface, not a rewrite of their configuration.
- **Five PowerShell scripts** — read-only estate discovery & gap analysis, model validation, a
  monthly governance scorecard, an approval-evidence exporter for audit, and a gated (`-WhatIf`)
  remediation script that stamps ownership and scope tags onto the existing estate.

## Deliberate scope

This is the **governance anchor** product. It does not re-teach packaging mechanics, third-party
patching, or install troubleshooting — it describes how governance plugs into those and into your
security controls. That focus is what lets it go deep on the operating model rather than repeating
configuration you can get elsewhere.

## Works for Commercial and Government tenants

The process, roles, decision rights, and artefacts are identical for Commercial and US Government
(GCC / GCC High / DoD) tenants; only the portal and Graph URLs differ, and every script accepts a
`-GraphEnvironment USGov` switch for the sovereign endpoints.

## The repeatable way

Every solution follows the same repeatable shape, so each rollout feels familiar and low-risk — buy
once, reuse the model across every business unit and every future application.

## The bottom line

Every application in your estate owned, approved on recorded evidence, ringed, supported, and
measured — a governed operating model built on the Intune and Entra platform you already run, that
your team keeps and reuses.

## Pricing

| Tier | Price | SKU |
|---|---|---|
| Commercial | $2,995.00 | `PTK-APPOPS-COMM-001` |
| Non-Profit (40% off, verified) | $1,797.00 | `PTK-APPOPS-NPO-001` |
| Government (15% off, verified) | $2,545.75 | `PTK-APPOPS-GOV-001` |

*Non-Profit and Government pricing is gated to verified organisations.*
