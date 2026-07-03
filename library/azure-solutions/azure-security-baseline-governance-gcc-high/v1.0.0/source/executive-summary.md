# Executive Summary — Azure Security Baseline & Governance (Government / GCC High)

## The situation

Deploying a security baseline and governance guardrails on an **Azure Government / GCC High** tenant is not the same task as doing it in Commercial Azure. Azure Government is a **physically isolated US sovereign cloud** with its own portal (`portal.azure.us`), its own management endpoints (`management.usgovcloudapi.net`, `login.microsoftonline.us`, `graph.microsoft.us`), and a set of **feature-parity gaps** versus Commercial. Teams that reuse Commercial runbooks on a Gov tenant hit wrong URLs, features that appear missing, and silent failures — with real compliance and export-control consequences (FedRAMP High, ITAR/EAR data residency).

## What this solution does

It delivers a **pilot-first, click-to-implement deployment** of the core Azure governance guardrails, authored specifically for the sovereign cloud:

- A named **management-group hierarchy** so policy and least-privilege RBAC apply by inheritance.
- A **least-privilege RBAC** model replacing broad standing `Owner`/`Contributor` grants.
- An assigned **Azure Policy security-baseline initiative** enforcing secure configuration (deny public storage, require encryption, **Allowed Locations pinned to US Gov regions**, audit diagnostics).
- **Microsoft Defender for Cloud** enabled with only the **Gov-available plans**, plus Secure Score and the regulatory-compliance dashboard.
- **Centralized audit logging** to a Gov-region Log Analytics workspace as FedRAMP-grade evidence.

Every object is named once and reused verbatim, and every step is executed against the correct `*.us` sovereign endpoints.

## Why it is credible

The solution is built on **cited Microsoft Azure Government documentation**, not assumption. The Commercial-vs-Gov differences — endpoints, PowerShell environment switches (`-Environment AzureUSGovernment` / `USGov`), region names, and the specific Defender for Cloud plans that are **Not Available** in Gov (App Service, Cosmos DB, Foundry/AI, adaptive network hardening, legacy VA, AWS/GCP connectors, recommendation exemption rules) — are documented with source links in `gcc-high-parity-notes.md`. Where Microsoft's docs do not confirm a Gov specific, the solution states the Commercial path and flags it **"verify for Azure Government"** rather than inventing a fact.

## How it is delivered

- **Documentation:** overview (with an explicit Commercial-vs-Gov section), requirements, ordered implementation, testing, troubleshooting, best practices, and a parity reference.
- **Five PowerShell scripts** targeting US Gov endpoints: Discovery, Validation, and Report (read-only); Remediation and Set-ScopeTargeting (default to `-WhatIf`).
- **Method:** Assess → Configure → Pilot → Validate → Expand, with a pass/fail gate at each stage and a rehearsed rollback.

## The outcome

A GCC High tenant with governance guardrails **correctly deployed on the right cloud** — right portals, right endpoints, parity gaps handled — proven on a pilot subscription before scaling, with audit evidence in hand. Self-guided and repeatable, at a fraction of bespoke consulting cost.
