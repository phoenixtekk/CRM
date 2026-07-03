# Executive Summary — Hybrid Identity with Active Directory & Microsoft Entra Connect (Government / GCC High)

## The problem

Deploying hybrid identity on a **Microsoft 365 U.S. Government GCC High** tenant is **not** the
Commercial process with a different sign-in page. GCC High is a physically and logically isolated
sovereign cloud with **different admin portals, different service endpoints, and a few feature
parity gaps**. Commercial steps applied to a GCC High tenant tend to fail **quietly** — the sync
engine cannot reach the right endpoints, or an admin configures the wrong (or an empty) tenant
through a Commercial portal. The result is wasted effort, delayed onboarding, and identity-plane
risk in an environment where a mistake breaks sign-in for everyone.

## The solution

This **Government (GCC High) edition** delivers hybrid identity between on-premises Active Directory
and a GCC High Entra ID tenant using **Microsoft Entra Connect Sync**, authored specifically for the
US sovereign cloud:

- **Correct sovereign portals and endpoints** throughout — `entra.microsoft.us`,
  `portal.office365.us`, `login.microsoftonline.us`, `graph.microsoft.us`, and the US Gov sync
  service instance.
- **The critical cloud-selection step** in Entra Connect (auto-detection via `*.windows.net`, or the
  manual `AzureInstance=4` + Custom install path) so the sync engine targets Azure Government, not
  Commercial.
- **An explicit Commercial-vs-GCC-High parity map** so you plan around the known gaps instead of
  discovering them in production.
- **Five PowerShell scripts** that connect to Microsoft Graph US Gov (`-Environment USGov`) to
  discover, validate, report, and safely remediate — change scripts default to `-WhatIf`.

## How it is delivered

A staged, gated model — **Assess → Configure → Pilot → Validate → Expand** — with break-glass
accounts prepared first and every change validated before the next. You prove the configuration on a
small named pilot before scaling to production in controlled waves.

## What is different in GCC High (the short version)

- **Portals/endpoints are `*.us`**, not `.com` — using Commercial URLs silently targets the wrong
  place.
- **Entra Connect must be pointed at the US Gov instance** during install, or sync fails.
- **All three sign-in methods (PHS, PTA, Federation) are available**, but a few peripheral features
  are not (e.g. My Staff, Entra threat-intelligence risk detection; HR-driven provisioning is
  partial).

Every claim in this solution is cited to Microsoft US Government documentation, or explicitly flagged
**"verify for GCC High"** where Microsoft has not published a definitive statement.

## The bottom line

Hybrid identity deployed correctly on GCC High — right portals, right endpoints, parity gaps handled
— proven on a pilot before you scale, at a fraction of consulting cost.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
