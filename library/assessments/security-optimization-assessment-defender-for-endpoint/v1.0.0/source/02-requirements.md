# 2. Requirements — Security Optimization Assessment: Defender for Endpoint

The category-wide prerequisites (the target tenant, least-privilege read-only assessor access, Graph/Az/management API access, licensing awareness, a defined scope and point-in-time baseline, the best-practice reference, secure output handling, and remediation ownership) are in the separate **Global Requirements — Assessments** file — read it first and do not repeat those here. Below are only the prerequisites **specific to assessing Defender for Endpoint**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Defender for Endpoint is deployed (even partially) in the tenant
**Description:** Microsoft Defender for Endpoint is provisioned and at least some devices are onboarded, so there is a live configuration to read.
**Why required:** The assessment scores an existing configuration; a tenant with MDE never provisioned has nothing to enumerate (that is a **deployment** engagement, not an assessment).
**How to verify:** Sign in to `security.microsoft.com` → **Assets → Devices**; confirm the device inventory is populated. If empty, MDE may not be provisioned.
**How to implement if missing:** If MDE is not provisioned at all, use the **DEFXDR** onboarding solution first. Partial coverage is fine and expected — measuring the coverage gap is the point.

## R2. Read access to the Defender for Endpoint API (Security Center)
**Description:** The MDE API (machines, security recommendations, exposure, and advanced hunting) must be reachable with a read-only identity — interactively (delegated) or via an app registration granted read-only application permissions.
**Why required:** Onboarding/sensor health, exposure, and KQL hunting posture come from this API, not from Graph alone.
**How to verify:** Run **`SOAMDE-Validate.ps1`** — it confirms it can read machines and run an advanced-hunting query with the current identity. In the portal, confirm you can open **Assets → Devices** and **Advanced hunting**.
**How to implement if missing:** Assign **Security Reader** (portal RBAC) to the assessor, or create an app registration with **read-only** MDE application permissions (`Machine.Read.All`, `SecurityRecommendation.Read.All`, `Vulnerability.Read.All`, `AdvancedHunting.Read.All`) and admin-consent them. *Verify current permission names and whether your tenant uses Defender unified RBAC.*

## R3. Advanced hunting enabled and queryable
**Description:** MDE **Advanced hunting** (the KQL interface over `DeviceInfo`, `DeviceEvents`, `DeviceTvmSecureConfigurationAssessment`, etc.) is available to the assessor.
**Why required:** Several coverage and hygiene checks (onboarding state, ASR events, secure-configuration assessment) are most accurate via KQL.
**How to verify:** In `security.microsoft.com` → **Hunting → Advanced hunting**, run `DeviceInfo | take 1`. If it returns a row, hunting is available.
**How to implement if missing:** Ensure the identity has the read role that includes advanced hunting, and that the tenant retains device data (retention affects how far back queries see). *Verify current retention and licensing for advanced hunting.*

## R4. The in-scope device population is defined
**Description:** A documented definition of *which devices* are in scope (all managed endpoints, a business unit, servers vs. workstations, a platform subset) and the **expected** device count from an authoritative source (Intune/AD/CMDB).
**Why required:** Onboarding coverage is only meaningful against an expected denominator — "1,900 onboarded" means nothing without "of how many?".
**How to verify:** You have an agreed device count/scope from Intune (`Devices → All devices`), Active Directory, or a CMDB to compare against MDE's inventory.
**How to implement if missing:** Export the expected device list before the run; **`SOAMDE-Coverage.ps1`** accepts an expected-count parameter so onboarding gaps are quantified, not guessed.

## R5. PowerShell modules for the read-only scripts
**Description:** PowerShell 7+ with the **Microsoft.Graph** modules (Authentication, Security, DeviceManagement) available for the scripts; the MDE API is called via Graph/REST with the read scopes.
**Why required:** The five automation artifacts are PowerShell and use these modules to collect configuration read-only.
**How to verify:** `Get-Module Microsoft.Graph.Authentication -ListAvailable` returns a version; `Connect-MgGraph` with read scopes succeeds.
**How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`. *Verify current module versions and required sub-modules.*

## R6. A named best-practice baseline for scoring
**Description:** The specific baseline the score is measured against — Microsoft's **security baselines for Defender for Endpoint**, **Microsoft Secure Score** endpoint recommendations, and/or your organization's approved standard.
**Why required:** A score is only meaningful against a stated reference; the report names it so results are defensible and comparable over time.
**How to verify:** The baseline is documented in the assessment scope and echoed in the report header. *Baselines evolve — verify against current Microsoft guidance at run time.*
**How to implement if missing:** Adopt the Microsoft security baseline + Secure Score endpoint recommendations as the default reference, and note any deliberate organizational deviations as accepted exceptions rather than findings.

## R7. Secure destination for the findings report
**Description:** A restricted location to store the HTML/CSV findings output, which is a map of your endpoint weaknesses.
**Why required:** The report is sensitive; it must not be left on a share or emailed broadly.
**How to verify:** A need-to-know location exists and access is limited to the security owners.
**How to implement if missing:** Provision a restricted location before the run; treat the output as confidential and share on a need-to-know basis. *Risk-acceptance of any finding is the customer's decision.*
