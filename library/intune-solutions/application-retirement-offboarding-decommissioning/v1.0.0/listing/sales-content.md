# Sales Content — Application Retirement, Offboarding & Decommissioning (Microsoft Intune)

The end of the application lifecycle, done right in Microsoft Intune — decide, communicate, protect
the data, run a staged uninstall campaign (pilot to broad), reclaim licenses, clean up every leftover
artefact, and prove the app is genuinely gone with an audit-ready evidence pack.

## Pricing
- Commercial: $2,295.00 · Non-Profit: $1,377.00 (40% off) · Government: $1,950.75 (15% off)
- Discounted tiers require eligibility verification.

## The hook
Retire an app the right way — and prove it's actually gone. No surprise data loss. No "we cancelled
the license but it's still installed." No orphaned groups, scripts, or app-control rules left behind.

## Why it's different
Most retirements get the core mechanic wrong. This package is blunt about how Intune actually removes
software: the **Uninstall** intent runs the app's stored uninstall command, **Required beats
Uninstall** (so an old install assignment silently blocks removal), **deleting the app object
uninstalls nothing**, and completion is bounded by device check-in. Understanding this is the
difference between a clean decommission and weeks of "I assigned Uninstall and nothing happened."

## What's inside
- Solution Overview, Requirements, 15-step Implementation Guide, Testing (7 gates), campaign-level
  Troubleshooting, Best Practices, Executive Summary.
- 5 read-only-by-default PowerShell scripts: Discovery, ImpactAnalyzer, WaveReporter (status/plan/
  stragglers), ArtifactFinder, EvidenceExport. All support `-Environment USGov`/`USGovDoD`.

## Scope boundary
This product owns the retirement **process and campaign**. When a single device's uninstall genuinely
fails at the installer level, that is deep Win32 uninstall failure remediation (a separate discipline)
— here such a device is counted, contained, and escalated as a straggler, keeping the wave moving.

## Government
GCC High / DoD differ only in endpoints (portal.azure.us, login.microsoftonline.us,
manage.microsoft.us, graph.microsoft.us / dod-graph.microsoft.us) — documented inline; no separate
Government deliverable required. Public-sector buyers get 15% off (verified).

## Delivery
Downloadable Complete Solution Package (PDF + Word guide + all 5 scripts in a ZIP). Buy once, reuse
across unlimited devices and every future retirement.
