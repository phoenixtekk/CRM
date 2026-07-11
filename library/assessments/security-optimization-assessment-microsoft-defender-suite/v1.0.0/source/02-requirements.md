# 2. Requirements — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

The category-wide prerequisites (the target tenant, read-only assessor access, Graph/Az access, licensing, scope/baseline, output handling, remediation ownership) are documented once in **`global-requirements-assessments.md`** — read that first. This section lists only the prerequisites **specific to assessing the Defender suite**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Microsoft Defender XDR portal is active
**Description:** The unified Microsoft Defender portal (`security.microsoft.com`) is active for the tenant, with at least one pillar onboarded.
**Why required:** The suite assessment reads unified incidents, Secure Score, and RBAC from this portal; there must be a suite to assess.
**How to verify:** Sign in to `security.microsoft.com`; confirm **Incidents**, **Secure score**, and **Settings** load.
**How to implement if missing:** Confirm licensing (R2) and onboard at least one pillar. First-time unified onboarding is out of scope — use the *Microsoft Defender XDR Deployment — Unified Onboarding* solution. Record a dark suite as a finding.

## R2. Licensing across the five pillars
**Description:** The licenses/plans for endpoint, identity, email/collaboration, cloud apps, and cloud (e.g. Defender for Endpoint P1/P2, Defender for Identity, Defender for Office 365 P1/P2, Defender for Cloud Apps, Defender for Cloud plans).
**Why required:** A pillar's posture is only assessable when its plan is licensed and enabled; unlicensed pillars are coverage findings.
**How to verify:** In the Microsoft 365 admin center / billing, confirm which pillar plans are assigned. *License-to-feature mapping changes — verify current entitlements.*
**How to implement if missing:** Record any unlicensed pillar as a **coverage-gap finding** ("license/onboard to gain this pillar"), not an omission.

## R3. Read-only Security Reader / Global Reader access (and RBAC read)
**Description:** A read-only role sufficient to enumerate per-pillar configuration, unified RBAC role assignments, incidents, and Secure Score.
**Why required:** The assessment must prove it changes nothing; read-only roles are sufficient for every script here.
**How to verify:** Entra → **Roles and administrators** for Security Reader / Global Reader. Confirm you can view (not edit) **Settings → Permissions & roles** and the incident queue.
**How to implement if missing:** Assign **Security Reader** and/or **Global Reader**. Do **not** grant write/admin roles for the assessment.

## R4. Microsoft Graph read scopes consented (Security + RoleManagement)
**Description:** Read-only Graph scopes — Security read (e.g. `SecurityEvents.Read.All`) and role/directory read (e.g. `RoleManagement.Read.Directory`, `RoleManagement.Read.All`, `Directory.Read.All`) for the unified-RBAC audit.
**Why required:** The discovery, validation, scoring, RBAC-audit, and reporting scripts collect configuration through Graph.
**How to verify:** `Connect-MgGraph -Scopes "SecurityEvents.Read.All","RoleManagement.Read.Directory","Directory.Read.All"` succeeds and `SOAXDR-Discovery.ps1` runs. *Verify current scope names.*
**How to implement if missing:** Have an administrator consent the read-only scopes. Never request write scopes for this assessment.

## R5. Az access for the cloud pillar
**Description:** Az PowerShell (`Az.Accounts`, `Az.Security`) reachable so the cloud pillar's plan/coverage signal can be read.
**Why required:** Cross-pillar coverage includes the cloud pillar (Defender for Cloud); reading it requires Az.
**How to verify:** `Connect-AzAccount` succeeds; the discovery script's cloud-pillar section returns without error.
**How to implement if missing:** `Install-Module Az -Scope CurrentUser`. If Azure is genuinely not in use, record the cloud pillar as "not applicable" rather than a gap — note it in the scope.

## R6. A defined assessment scope and a secure output location
**Description:** An agreed scope (which pillars, which role assignments, which subscriptions) and a secure place to store the findings report and the saved baseline.
**Why required:** Scope keeps the score comparable; the findings report is sensitive (Global Requirements G5, G7).
**How to verify:** The scope is documented; a restricted location exists for `SOAXDR-*.json` outputs and the report.
**How to implement if missing:** Agree the scope with the security owner before running; create a restricted output location and point the scripts at it.
