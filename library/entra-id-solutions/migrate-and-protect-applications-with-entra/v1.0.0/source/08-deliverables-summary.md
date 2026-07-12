# 8. Deliverables Summary — Migrate & Protect Applications with Entra

## What you receive
A complete, self-guided package to **migrate application authentication to Microsoft Entra** and protect
every app it moves — retiring **AD FS** relying parties onto **Entra SSO**, publishing on-prem web apps
without a VPN via **Application Proxy** (or GSA Private Access), automating account lifecycle with **SCIM**,
and wrapping every migrated app in **Conditional Access** and **access reviews** — with a discovery-driven
migration plan and a reversible cutover per app.

### Documentation
- **Executive Summary** — the problem (stranded AD FS / on-prem / bespoke-SSO apps), the four migration
  tracks, the outcome, the boundary (distinct from the SAML App Integration Factory), and the licensing gate.
- **Solution Overview** — how AD FS→Entra SSO, App Proxy publishing, and SCIM provisioning fit together, the
  building blocks (enterprise app → SSO/assignments/provisioning; connector group → published app; CA;
  access review), scope, and what's out of scope (SSO-at-scale and CA baseline are separate solutions).
- **Requirements Guide** — migration-specific prerequisites (licensing incl. App Proxy/Governance/Private
  Access, the app-admin role, AD FS relying-party inventory, on-prem app URLs, a connector host, SCIM
  endpoint/token, pilot group + app owners, cutover/rollback control, the Graph toolchain), each with
  Verify / Implement, on top of the category global requirements.
- **Implementation Guide** — ordered steps: assess + plan → recreate AD FS app in Entra → App Proxy
  connectors → publish on-prem app → SaaS + SCIM → Conditional Access → access review → validate → cut over
  AD FS (kept as rollback) → expand, with **every object named** using the
  `ENTAPPMIG – <Purpose> – <Scope> – <Stage>` convention.
- **Testing & Validation** — the gates (AD FS app on Entra with claims parity, published app without VPN,
  SCIM provision/deprovision, Conditional Access) as a pass/fail matrix, automated checks, and reference
  **KQL** for sign-in evidence.
- **Troubleshooting** — symptom → root-cause → fix for the common failures (SAML mismatch, missing claims,
  App Proxy 500s, KCD/SSO failures, SCIM errors, cutover sign-in breakage, CA lockout).
- **Best Practices** — usage-driven planning, safe AD FS cutover, pre-auth publishing, SCIM deprovisioning,
  CA + reviews, change safety, and where to go next.

### PowerShell tools (Microsoft Graph) — safe by default
| Script | Purpose | Default mode |
|--------|---------|--------------|
| **`ENTAPPMIG-Discovery.ps1`** | Inventory AD FS relying parties (AD FS server), AD FS application activity, Entra enterprise apps, and App Proxy connector groups (baseline + migration progress) | Read-only |
| **`ENTAPPMIG-Validate.ps1`** | Check each named §3 object exists and is wired (SSO config + pilot assigned; App Proxy pre-auth = Entra; SCIM enabled/scoped; CA targets apps, excludes break-glass); flag gaps | Read-only |
| **`ENTAPPMIG-Provisioning.ps1`** | Report SCIM provisioning status + recent sync results; preview an on-demand provision | Read / `-WhatIf` |
| **`ENTAPPMIG-Report.ps1`** | Export sign-in evidence for the migrated apps (Graph sign-in logs + optional KQL): who, which app, CA result | Read-only |
| **`ENTAPPMIG-Cutover.ps1`** | Pre-cutover readiness summary (config, assignments, CA coverage); preview-only by default | Read / `-WhatIf` |

All scripts use `Connect-MgGraph` with **least scopes**, contain **no credentials or secrets**, and any
change/remediation defaults to a **`-WhatIf` preview** gated behind an explicit `-Commit`.

## Outcomes
- **AD FS retired** — relying parties migrated to Entra SSO, app-by-app, with a reversible cutover.
- **On-prem apps reachable without a VPN** — published through Entra with pre-authentication.
- **Provisioning automated** — SCIM creates, updates, and **deprovisions** accounts.
- **Every migrated app protected** — Conditional Access enforced and access recertified on a schedule.
- A **pilot-first**, gated, reversible rollout with a documented rollback for every cutover.

## Assumptions & boundaries
- **Licensing** covers in-scope users — **P1** (App Proxy + CA), **Governance/P2** (access reviews),
  **Private Access** add-on if publishing via GSA — *verify current SKU coverage and preview status*.
- The **app inventory** (AD FS relying parties, on-prem URLs, SCIM endpoints) is provided by the customer.
- **SSO onboarding at scale** (the SAML App Integration Factory) and **CA baseline design** are **separate
  adjacent solutions**; this is the AD FS-migration + on-prem-publishing track.
- **Which apps migrate in which wave**, cutover windows, and app-owner sign-off are the customer's
  change-management decisions.

> Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the full documentation set plus
> all five PowerShell tools in a single ZIP, yours to keep and reuse on every migration wave.
