# Executive Summary — SharePoint & OneDrive Lifecycle Policies: Microsoft Purview

SharePoint and OneDrive fill up and never empty. Sites accumulate a decade of documents; departed
employees' OneDrive accounts linger indefinitely; the same file exists in five versions across three
libraries. Some of that content **must be kept** for a regulatory or business period; much of it **should
be cleaned up** once it ages out — and doing neither is the default. That is both a compliance gap (you
can't prove you keep what you must) and a standing risk (you're holding stale, discoverable content you no
longer need). This solution closes that gap with **Microsoft Purview Data Lifecycle Management** —
retention policies for SharePoint and OneDrive that retain content on schedule and clean it up when it
ages out — configured, piloted, validated, and defensible.

This is a complete, do-it-today package written for an administrator implementing a content lifecycle for
the first time. It delivers the capability end-to-end — from reading existing policies and coverage,
through translating the retention schedule into rules and creating the policy **retain-only** on a limited
pilot, to observing the Preservation Hold Library, validating, and only then enabling deletion as a
deliberate, approved step — with every policy, rule, and scope named once and reused everywhere. Because
deletion after its window is **irreversible**, the guide never deletes on its own: it starts retain-only
and gates cleanup behind an explicit, separate action. Because capability availability (e.g. adaptive
scopes) is licensing-dependent and the portal is evolving, the guide cites the method and flags every
capability "verify your licensing/tenant."

## What you get
- A plain-language Solution Overview of retention policies — retain, retain-then-delete, delete-only, and
  static vs adaptive scopes — and how location policies differ from item-level retention labels.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: retention licensing
  (E3 baseline; E5 for adaptive scopes), the least-privilege records role, the S&C PowerShell toolchain,
  the retention schedule translated to rules, the in-scope locations and scope method, a limited pilot
  scope with change control, and Preservation Hold Library / eDiscovery-hold awareness.
- An Implementation Guide of precise, ordered steps: assess, design the schedule, create the policy
  retain-only on the pilot, pilot and observe the hold library, validate, **enable deletion deliberately**,
  then expand.
- Five PowerShell tools — Discovery, a prerequisite/health helper, a safe Configuration/Remediation tool
  (`-WhatIf` by default; delete behind its own explicit action), Validation, and Reporting — built on
  Security & Compliance PowerShell, **read-only or `-WhatIf` by default with no credentials in code**.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
SharePoint and OneDrive on a lifecycle from Purview: in-scope content retained for the schedule and
cleaned up when it ages out — proven on a limited pilot in retain-only mode before any deletion.

## The deployment model
Assess → Design → Configure (**retain-only**) → Pilot → Validate → Expand (**enable deletion
deliberately**) — with a pilot gate before the estate and deletion enabled only after validation and
approval.

## Outcome
The content-hoarding blind spot closed — the right content kept for the right period and the rest cleaned
up on schedule — with the schedule and the keep/delete determination left to the records, compliance, and
legal owners who make it, and no content ever deleted before it was deliberately approved.
