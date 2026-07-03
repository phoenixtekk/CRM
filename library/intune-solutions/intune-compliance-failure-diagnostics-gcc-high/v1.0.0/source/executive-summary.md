# Executive Summary — Intune Compliance-Failure Diagnostics & Remediation (Government / GCC High)

## The problem
On a **US sovereign-cloud (GCC High)** tenant, an Intune device that reports **Not compliant** — or
**Not evaluated**, or **In grace period** — blocks Conditional Access and locks the user out of
Microsoft 365. Diagnosing that failure on GCC High is **not** the Commercial process with a different
sign-in: the admin portals, service endpoints, and Microsoft Graph all live on **`*.us`** domains, and
several compliance-relevant capabilities behave differently from — or are absent versus — the
Commercial cloud. Follow Commercial steps and the fixes fail **silently**: you sign into the wrong
portal, allow the wrong endpoint through the proxy, or script against the Commercial Graph, and the
device never turns compliant.

## The solution
A **symptom-driven Diagnostic Playbook** plus five **US Gov Graph** PowerShell scripts that take a
novice-to-intermediate admin from *the symptom the user reports* to *the exact GCC High blade and safe
fix* — with every Commercial-vs-GCC High difference called out where it changes the diagnosis:

- **Diagnostic Playbook (symptom tree).** Branches for **Not evaluated**, **In grace period**, **Not
  compliant** (per-setting: BitLocker/Secure Boot/Code Integrity, OS version, Defender AV, device
  threat level/MTD, password/encryption, custom rules), **Compliant-but-blocked** (Conditional
  Access), and **stale/missing** devices — each ending in a GCC High blade and a validation step.
- **Five scripts, all on US Gov Graph** (`Connect-MgGraph -Environment USGov`): Discovery, Validation,
  Report (read-only), and Remediation + Set-ScopeTargeting (**default `-WhatIf`**).
- **Cited GCC High parity reference** documenting every difference from Microsoft's own US Government
  documentation, with anything unconfirmed flagged **"verify for GCC High"** — never invented.

## What's different on GCC High (the parity gaps that matter)
- **All portals/endpoints are `*.us`** — `intune.microsoft.us`, `portal.azure.us`,
  `login.microsoftonline.us`, `graph.microsoft.us`; devices check in via `*.manage.microsoft.us` /
  `*.dm.microsoft.us`, which **must not be SSL-inspected**.
- **Feature gaps that change a diagnosis:** classic **Windows Autopilot** unavailable; **Cloud PKI**
  and **Remote Help** planned-not-available; **MTD** works only for vendors present in Gov; **some
  newer DHA capabilities** planned (core BitLocker/Secure Boot/Code Integrity rules do work); most
  **Windows update workflows** unavailable; **no in-place migration** from Commercial.
- **Scripting must use `-Environment USGov`** or it silently queries the Commercial cloud.

## Business value
- **Faster time-to-compliant.** A repeatable symptom→fix path replaces trial-and-error on an
  unfamiliar sovereign cloud, restoring Microsoft 365 access blocked by Conditional Access.
- **No silent failures.** The right portals, endpoints, and Graph environment are baked in, so fixes
  actually land instead of appearing to.
- **Safe by design.** Read-only discovery, preview-first remediation (`-WhatIf`), and a mandatory
  pilot prevent a compliance change from blocking an entire fleet at once.
- **Audit-ready.** Cited parity notes and before/after script evidence support a FedRAMP
  High-accredited (GCC High/DoD) operating posture.

## Bottom line
**Intune compliance failures diagnosed and remediated correctly on GCC High** — right `*.us` portals,
right endpoints, parity gaps handled — proven on a pilot before you scale.
