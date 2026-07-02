# Solution Overview — Microsoft Purview DLP, Sensitivity Labels & Retention (Government / GCC High)

## What this solution delivers

This is the **Government (GCC High)** edition of the Microsoft Purview information-protection
solution. It walks a competent-but-novice administrator through deploying three Purview pillars on a
**US sovereign-cloud (GCC High)** tenant, the repeatable way:

1. **Sensitivity labels + label policies (+ auto-labeling)** — classify and, where appropriate,
   encrypt content so protection travels with the data.
2. **Data Loss Prevention (DLP)** across Exchange, SharePoint, OneDrive, Teams, and endpoints —
   detect and control the movement of sensitive information, **starting in audit and tuning before
   you enforce**.
3. **Retention labels & policies and records management** — keep what must be kept, dispose of what
   must go, on a defensible schedule.

Together these turn an **ungoverned data estate** (unclassified data, DLP noise, no retention,
compliance gaps) into a **governed** one: data that is **labeled, protected, and retained** — proven
on a pilot before you scale.

## Why GCC High is a different solution, not a re-login

Microsoft Purview in **GCC High is not the Commercial portal with a different sign-in.** Two things
differ in ways that break Commercial runbooks:

- **The portals and endpoints are different sovereign-cloud hosts** — you administer Purview at
  `compliance.microsoft.us` (rolling to `purview.microsoft.us`), sign in at
  `login.microsoftonline.us`, and your scripts must target **US Gov Graph endpoints**
  (`Connect-MgGraph -Environment USGov`). Point a Commercial runbook at `compliance.microsoft.com`
  and you are in the wrong cloud.
- **Feature parity lags Commercial.** Several Purview capabilities that are generally available in
  Commercial are, in GCC High, in preview, "in development", or "on the engineering backlog" — i.e.
  **not present**. Following Commercial steps that assume those features will silently fail: the menu
  or option simply is not there.

This edition calls out the correct GCC High portals/endpoints at each step, and flags the parity
gaps **where they matter**, so a government tenant is configured correctly. The full parity reference
lives in `gcc-high-parity-notes.md` and is cited throughout.

## The Purview information-protection model (how the pieces fit)

- **Sensitivity labels** are the classification taxonomy (e.g. `Public`, `General`,
  `Confidential`, `Confidential \ CUI`). A **label policy** publishes labels to users/groups and sets
  behavior (default label, mandatory labeling, downgrade justification). **Auto-labeling** applies a
  label without user action, based on conditions (built-in sensitive information types, Exact Data
  Match, keyword dictionaries, or trainable classifiers).
- **DLP policies** watch for sensitive content (the same SITs/EDM/classifiers) as it is stored,
  shared, or exfiltrated, and take actions (audit, notify, block, restrict) across M365 locations
  and managed endpoints. A **sensitivity label can itself be a DLP condition** — label once, enforce
  everywhere.
- **Retention labels / policies** govern how long content lives and what happens at end of life
  (retain, then delete; delete only; or declare a **record** with a locked retention). **Records
  management** adds file plan, disposition review, and proof of disposal for regulated content.

The design principle across all three is **assign once, repeat everywhere**: a small, well-named
taxonomy drives labeling, DLP, and retention consistently, instead of one-off policies per team.

## Commercial vs GCC High — what's different

*(Doc-confirmed from Microsoft's "Plan for Microsoft Purview — GCC High deployments" service
description unless flagged. See `gcc-high-parity-notes.md` for the full table and citations.)*

**Portals & endpoints (always different):**

| Purpose | Commercial | GCC High |
| --- | --- | --- |
| Sign-in | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us` |
| Purview / compliance | `compliance.microsoft.com` | `compliance.microsoft.us` (→ `purview.microsoft.us`) |
| Security portal | `security.microsoft.com` | `security.microsoft.us` |
| Entra admin | `entra.microsoft.com` | `entra.microsoft.us` |
| Graph (scripts) | `graph.microsoft.com` (`-Environment Global`) | `graph.microsoft.us` (`-Environment USGov`) |

**Feature parity gaps that change how you design (GCC High status in parentheses):**

- **Named entity SITs and their policy-authoring templates** are **not available** (*on engineering
  backlog*). Build DLP/auto-label conditions from **built-in SITs, Exact Data Match, keyword
  dictionaries, and regex SITs** instead.
- **Auto-labeling for Office *mobile* clients** is **not available** (*on engineering backlog*).
  Client-side auto-labeling on Windows/Mac/web and service-side auto-labeling for
  EXO/SPO/OneDrive **are** available.
- **Applying a "default label" to unlabeled files in a SharePoint library**, and **default label on
  documents being edited**, are **not available** (*in development*). Plan default-labeling around
  what is GA (label policy default label for users; service-side auto-labeling).
- **Granular Conditional Access via sensitivity labels for SPO sites** is **not available** (*on
  engineering backlog*). Verify container/site-label behavior separately for GCC High.
- **Auto-applying *retention/records* labels with trainable classifiers** is **not available**
  (*in development*), and **"apply retention label action at end of retention period"** is **not
  available** (*on engineering backlog*). Trainable classifiers **do** work for **client-side
  auto-labeling** of sensitivity labels (GA).
- **Records-management Power Automate integration** and several **Graph APIs (records, eDiscovery
  export, Teams export)** are **not available** (*in development / backlog*).
- **Adaptive Protection** (Insider Risk → dynamic DLP) is **rolling out to Gov clouds** (GCC/GCC
  High/DoD), not long-established — **verify it is present in your tenant** before designing on it.
- **DSPM for AI** is available but **"Browse to URL" policy cannot be created** in GCC-H; only
  supported AI sites apply.
- **Microsoft Priva** (Privacy Risk Management, Subject Rights Requests) is **not available**
  (*in development*).

Where a specific classifier, SIT, or option is not visible in `compliance.microsoft.us`, treat it as
a **GCC High parity gap, not a permissions problem** — re-check the parity table before troubleshooting.

## The standard deployment model

Every step in this solution follows the same repeatable model, with an explicit **pass/fail gate**
between phases:

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm licensing (Gov G3/G5), roles, portal access, and which features are actually
  available in your GCC High tenant (the parity check).
- **Configure** — design the label taxonomy and build labels, label policy, DLP policies (in
  **audit/test** mode), and retention labels/policies. Name every object verbatim.
- **Pilot** — publish to a **named pilot group** only.
- **Validate** — run the pass/fail gates in `05-testing.md` against the pilot.
- **Expand** — widen scope group-by-group only after the gate passes.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting** (with GCC-High-specific gotchas), **Best Practices**, and a
  **Deliverables Summary** + **Executive Summary**.
- A **GCC High parity notes** reference (`gcc-high-parity-notes.md`) with per-feature status and
  Microsoft citations.
- **Five PowerShell scripts** (Graph SDK, US Gov endpoints): Discovery, Validation, Report,
  Remediation, and Set-ScopeTargeting — read-only tools default to read-only; change tools default
  to `-WhatIf`.

> **Sources:** Microsoft Learn — *Plan for Microsoft Purview — GCC High deployments*
> (`.../plan-for-microsoft-purview-gcc-high-deployments`); *Microsoft Purview service description*;
> *Adaptive Protection* docs; MSPortals.io US Government portals. Full citations in
> `gcc-high-parity-notes.md`.
