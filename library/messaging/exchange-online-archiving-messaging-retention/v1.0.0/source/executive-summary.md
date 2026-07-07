# Executive Summary

## Outcome
Primary mailboxes stop hitting quota, unmanaged **PST** data is brought under service control, and mail
that must be preserved for legal or regulatory reasons is held so it cannot be lost — all without
deleting anything. Concretely: archive mailboxes and **auto-expanding archive** are enabled where the
plan allows, aged mail automatically **moves to the archive** via Messaging Records Management (MRM)
tags, historical PSTs are **imported into the archive**, and **litigation** and **In-Place/eDiscovery
holds** are applied where a preservation obligation exists.

## Approach
This is **Exchange Online Archiving (EOA)** implemented specifically — not a broad data-governance
program. It follows the house model **Assess → Design → Configure → Pilot → Validate → Expand**: the
current archive/hold posture and mailbox sizes are assessed, the archive tags/policy and hold scope are
designed, and everything is enabled against a small **pilot** scope first, validated against explicit
pass/fail gates (archives provisioned, move-to-archive working, PSTs ingested, holds enforced), and only
then expanded fleet-wide in controlled waves. Automation is delivered as five **Exchange Online
PowerShell (EXO V3)** / Microsoft Graph scripts that are read-only or `-WhatIf` by default, with no
stored credentials.

## Why it is low-risk
- **Nothing is deleted.** Move-to-archive relocates mail; it does not remove it. Held items cannot be
  purged.
- **Pilot-first with gates and a rollback.** Every change is validated on a small scope before broad
  rollout, and each step has a documented rollback (with the deliberate exception that auto-expanding
  archive is one-way and held mailboxes are never rolled back).
- **Licensing is verified up front.** Archiving and auto-expanding archive are plan-dependent; the
  solution checks entitlement before enabling rather than assuming it.
- **Legal stays in control of legal.** The solution applies the holds the legal/records owner
  determines; **it never decides what to preserve or for how long.**

## Boundary
Scoped to **email archiving and holds**. Broader Microsoft Purview work — DLP, sensitivity labels, and
cross-workload retention/records across SharePoint, OneDrive, and Teams — is a **separate product** and
is intentionally out of scope here.
