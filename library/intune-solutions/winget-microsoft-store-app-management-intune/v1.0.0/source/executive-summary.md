# Executive Summary — Winget & Microsoft Store App Management with Microsoft Intune

**White-label · Intune Solutions**

Most of the apps your users ask for every day are mainstream, publicly available Windows apps — a PDF
reader, a media player, a browser, common utilities. You should not have to hand-package each one, and
your users should not have to open a ticket to get one installed. Microsoft Intune deploys these two
ways: **Microsoft Store apps** (the modern, **winget-backed** Store app type, drawing on a large public
catalog) and **winget** for the long tail — with **assignment**, **updates**, and **Company Portal
self-service**. This is a complete, **deploy-it-today** package for standing up Store and winget app
management end to end, written for an administrator with no prior experience.

## What you get
- A plain-language **Solution Overview** of Microsoft Store (new) apps, winget for apps beyond the
  Store, Required vs. Available (self-service), updates, and how to **choose the right lane** versus the
  Enterprise App Catalog (curated prepackaged apps) and custom Win32.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite, including winget
  prerequisites and Company Portal.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order, built
  around two worked example apps — one Required, one self-service.
- Five **PowerShell scripts** for discovery, PASS/FAIL validation, install/update reporting, install
  testing, and a `-WhatIf`-gated assignment change.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A working Store + winget app-management practice — mainstream apps deployed **Required** for the
baseline, published **Available** in Company Portal for self-service, kept current through the
service-managed update path, and rolled out **pilot-first** so a bad assignment never reaches the whole
fleet at once.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.** The pilot ring is the gate.

## A note on accuracy
Microsoft's app catalog, the new Store app type, and update behavior change over time; this guide
describes the model confidently and flags the tenant-specific specifics (catalog availability, exact
navigation, update cadence, Government-cloud differences) to **verify against current Microsoft
documentation** before you promise them to users.

## Outcome
Mainstream Windows apps that install, self-serve, and update through Intune — without hand-packaging the
apps your users ask for every day — deployable by a single administrator and validated before fleet
rollout.
