# 8. Deliverables Summary — Android Enterprise Connection & Managed Google Play Setup

Everything included in this solution, and how the pieces fit together.

## Documentation
- **Solution Overview** — what the foundation is, the two mutually-exclusive managed Google Play binding
  models (account enterprise vs Google Workspace EMM), the four Android Enterprise enrollment models and
  when to use each, and an honest note on the evolving AMAPI transition.
- **Requirements Guide** — the solution-specific prerequisites (binding decision, org-owned Google owner
  account, role model, enrollment-restriction plan, device supply, endpoint reachability, Graph toolchain),
  building on the shared Android **Global Requirements**.
- **Implementation Guide** — ordered steps: assess, scope groups, connect managed Google Play, confirm app
  sync, configure the Android enrollment platform restriction, create the FM / COPE / COSU enrollment
  profiles, pilot-enroll one device per model, validate, expand — each artifact named, pilot-first, with
  pass/fail gates and rollback.
- **Testing & Validation Guide** — Gates A–D (binding healthy, restrictions enforce intended models, each
  model enrolls correctly, reporting reconciles) with pass criteria and an AMAPI re-validation watch.
- **Troubleshooting Guide** — symptom → root-cause → fix for binding, app sync, "can't add a Google
  account," per-model enrollment failures, restriction mis-scope, and AMAPI-related uncertainty.
- **Best Practices** — binding/ownership, restriction discipline, model-to-ownership matching, pilot &
  change control, the AMAPI "verify, don't assume" rule, OEM layering, and automation/security hygiene.
- **Executive Summary** — the business case for getting the foundation right the first time.

## PowerShell (Microsoft Graph) tools — 5 scripts
All are safe-by-default (read-only, or `-WhatIf` unless `-Apply`), use interactive delegated `Connect-MgGraph`
with least scopes, and contain **no** hardcoded credentials or secrets.

| Script | Purpose | Safety |
| --- | --- | --- |
| **ANDROIDENT-Discovery.ps1** | Assess the managed Google Play connection (bind status, app sync, owner), the Android enrollment platform restrictions, and existing corporate-owned enrollment profiles. | Read-only |
| **ANDROIDENT-Set-ScopeTargeting.ps1** | Create the pilot/prod scope groups and the per-model groups; report the enrollment-restriction assignment. | Default `-WhatIf`; `-Apply` to change |
| **ANDROIDENT-Set-EnrollmentRestrictions.ps1** | Configure the Android enrollment platform restriction (allow the intended models, block the rest). | Default `-WhatIf`; `-Apply` to change |
| **ANDROIDENT-New-EnrollmentProfile.ps1** | Create a corporate-owned enrollment profile per model (fully managed / corporate-owned work profile / dedicated). | Default `-WhatIf`; `-Apply` to change |
| **ANDROIDENT-Report.ps1** | Android Enterprise readiness + per-model enrollment coverage (ownership/management), restriction and profile inventory. | Read-only |

## What is deferred (by design)
- The **managed Google Play sign-in** (Google-hosted account binding) and **Google Admin console** actions
  → Google's official documentation.
- **OEM specifics** (Samsung Knox, Zebra, etc.) and **third-party apps** → the vendor's docs (pattern
  level here).
- **AMAPI / web / account-driven enrollment and re-enrollment behavior** → verify against current
  Microsoft guidance / your tenant (flagged throughout, never asserted from memory).

## Outcome
A correct Android Enterprise foundation in Intune — **managed Google Play bound**, **enrollment models
configured**, **restrictions enforced**, validated on a pilot — so devices enrol the right way and app
delivery, compliance, and per-model lockdown build on it without rework.
