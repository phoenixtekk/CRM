# Executive Summary — Sensitivity Labeling for Power BI & Microsoft Fabric: Microsoft Purview

Analytics is where classified data is at its most concentrated — and its most portable. A Power BI report
or a Microsoft Fabric item can join HR, finance, and customer data in one place, and then a user clicks
**Export to Excel** and the data leaves in a spreadsheet that carries no protection at all. You cannot
claim your analytics estate is governed when a download strips the classification. This solution closes
that gap: it applies **Microsoft Purview sensitivity labels** to Power BI/Fabric content and makes those
labels **flow with the data** — inherited from labeled sources, carried into exports with their
encryption — configured, piloted, validated, and defensible.

This is a complete, do-it-today package written for an administrator enabling analytics labeling for the
first time. It reuses your existing Purview sensitivity labels — not a BI-only set — and delivers the
capability end-to-end: from reading the current labels and the Power BI/Fabric information-protection
tenant settings, through publishing labels to creators and enabling labeling/inheritance/export
restriction, to piloting on a real workspace and expanding — with every label, policy, group, and pilot
scope named once and reused everywhere, and every change proven on a pilot before the estate is touched.
Because the analytics information-protection surface is **evolving**, the guide cites the method and flags
every capability "verify your licensing/tenant" rather than asserting a setting or entitlement as
permanent.

## What you get
- A plain-language Solution Overview of analytics labeling — artifact labeling, source inheritance, and
  export inheritance — and how Power BI/Fabric honor your existing Purview labels.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: the sensitivity-label
  entitlement plus Power BI Pro/PPU (or a capacity), least-privilege Purview and Power BI/Fabric roles,
  the S&C PowerShell + Power BI toolchain, the information-protection tenant settings, a delegation group
  and pilot workspace, published labels, labeled sources for inheritance, and stakeholders with change
  control.
- An Implementation Guide of precise, ordered steps: assess labels and tenant settings, design the intent
  and map, publish labels to a pilot, enable the tenant settings (labeling + source + export inheritance),
  **pilot on real content**, validate against the gate, then expand with mandatory labeling.
- Five PowerShell tools — Discovery, a prerequisite/health helper, a safe Configuration/Remediation tool
  (`-WhatIf` by default), Validation, and Reporting — built on Security & Compliance PowerShell and
  read-only Power BI PowerShell, **read-only or `-WhatIf` by default with no credentials in code**.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
Analytics content and its exports protected from Purview: Power BI/Fabric artifacts labeled, labels
inherited from labeled sources and carried into Excel/PowerPoint/PDF exports with their encryption —
validated on a pilot before you scale.

## The deployment model
Assess → Design → Configure → **Pilot (real workspace)** → Validate → Expand — with a pilot gate before
the estate, and mandatory labeling turned on only after validation.

## Outcome
The analytics export blind spot closed — a labeled report produces a labeled, still-protected export —
with the determination of which content is sensitive, and any regulatory/records obligation on the data
it surfaces, left to the owners who make it.
