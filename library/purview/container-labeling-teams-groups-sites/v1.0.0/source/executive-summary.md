# Executive Summary — Container Labeling (Teams, Groups & Sites)

Most organizations protect the **file** and ignore the **container**. A sensitivity label on a document
controls that document — but the Microsoft Team, Microsoft 365 Group, or SharePoint site it lives in was
created with whatever defaults the creator clicked: public or private, guests allowed or not, external
sharing wide open, and downloadable to any personal laptop. That container is the real perimeter, and
left ungoverned it is both a compliance gap and a data-risk exposure. This solution closes that gap using
**container sensitivity labels** in Microsoft Purview.

It gives you a repeatable way to govern **privacy** (Public vs Private), **guest access** (whether owners
may add external users), **external sharing** (how broadly a labeled site may be shared), and
**unmanaged-device access** (full / web-only / blocked, via Microsoft Entra Conditional Access) for
Teams, Groups, and Sites — configured, **piloted on a small ring in test first**, validated against
pass/fail gates, and reported for coverage. Everything uses only the Microsoft Purview portal, the
Microsoft 365 / Entra admin centers, Security & Compliance PowerShell, Microsoft Graph, and the
SharePoint Online Management Shell.

This is a complete, deploy-it-today package written for a competent M365/compliance administrator, built
around a clean three-tier taxonomy — **General**, **Confidential**, and **Highly Confidential** — each
mapping to concrete privacy, guest, sharing, and device settings.

## What you get
- A plain-language Solution Overview of container labels and the three-tier taxonomy.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — including the
  licensing that gates the unmanaged-device control (Entra ID P1) and the one-time tenant enablement.
- An Implementation Guide of precise, ordered portal + PowerShell + Graph + SharePoint steps, with labels
  applied **pilot-first** and each label, policy, and container named.
- Five PowerShell scripts: container discovery, a configuration/remediation helper (`-WhatIf` by default,
  handling both one-time enablement and label application), a validation checker, a coverage report, and
  a prerequisite/health helper.
- Testing and Troubleshooting guides for a confident, safe rollout.

## What this delivers
Teams, Groups, and Sites labeled to a governed posture: Private where they should be, guest access
controlled by label, external sharing tightened per tier, and confidential content web-only or blocked
from unmanaged devices — validated on a pilot ring before the estate, and evidenced by a coverage report.

## The deployment model
Assess → Design → Configure → Pilot → Validate → Expand.

## Scope boundary
This solution governs the **container**, not the files inside it — file/email classification and
encryption are the subject of the dedicated file sensitivity-labeling solution, commonly deployed
alongside this one. The unmanaged-device access control is **licensing-dependent (Entra ID P1) — verify
against your plan.** Which data warrants which tier, and who may be a guest, are decided by the
organization's compliance, data-owner, privacy, and legal functions — this solution provides the
technical method and the evidence, not the determination.

## Outcome
Govern the container, not just the file — Teams, Groups, and Sites protected by named sensitivity labels
controlling privacy, guests, sharing, and device access, delivered, validated, and defensible in
Microsoft Purview.
