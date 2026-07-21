# Executive Summary — Enterprise App Catalog Deployment in Microsoft Intune (Prepackaged Win32 Apps & Auto-Update)

**White-label · Intune Solutions**

Hand-packaging every Windows application — wrapping the installer, writing install/uninstall
commands, authoring a detection rule, then chasing each new version — is slow and never-ending.
Microsoft's **Enterprise App Catalog** changes that: it is a **curated set of prepackaged Windows
(Win32) apps** with install logic and detection **already built**, plus **update management** so
deployed catalog apps stay current without re-wrapping. You pick the app from the catalog, choose how
it installs and who gets it, turn on update management, and roll it out pilot-first.

This is a complete, **deploy-it-today** package for deploying applications from the Enterprise App
Catalog with Microsoft Intune, written for an administrator with no prior packaging experience.

> **Note — not Entra "Enterprise applications."** This solution covers the **Intune Enterprise App
> *Catalog*** (prepackaged Windows apps you deploy to devices). It is **not** the Entra ID
> "Enterprise applications" blade (app registrations, service principals, API permissions) — that is
> identity/OAuth governance, a separate discipline and product.

## What you get
- A plain-language **Solution Overview** of the Enterprise App Catalog, the three Windows-app lanes
  (catalog vs hand-packaged Win32 vs winget/Store), built-in detection, and update management.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order — add the
  catalog app, select it, confirm install behavior, verify the built-in detection, enable update
  management, assign a pilot ring, expand.
- Five **PowerShell scripts** for discovery, pass/fail validation, install/update reporting,
  on-device testing, and a `-WhatIf`-gated pilot assignment.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
A repeatable catalog-deployment method — pick a **prepackaged** app, deploy it with Microsoft's
**built-in detection**, keep it current with **update management**, and prove it on a **pilot ring**
before scaling — with the exact-navigation specifics flagged to **verify against current Microsoft
documentation** so the guide stays accurate as the portal evolves.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.** The pilot ring is the gate.

## Outcome
Common Windows applications that deploy predictably from a curated source and stay current
automatically — deployable by a single administrator and validated before fleet rollout.
