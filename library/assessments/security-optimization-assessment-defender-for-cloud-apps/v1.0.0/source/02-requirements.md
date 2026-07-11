# 2. Requirements — Security Optimization Assessment: Defender for Cloud Apps

The category-wide prerequisites (the target tenant, read-only assessor access, Graph/Az access, licensing, scope/baseline, output handling, remediation ownership) are documented once in **`global-requirements-assessments.md`** — read that first. This section lists only the prerequisites **specific to assessing Defender for Cloud Apps**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Defender for Cloud Apps is provisioned in the tenant
**Description:** Defender for Cloud Apps (the cloud-apps area of the Microsoft Defender portal) is active for the tenant being assessed.
**Why required:** There is no configuration to enumerate or score if the service has never been provisioned.
**How to verify:** Sign in to `security.microsoft.com` → **Cloud apps** → **Cloud discovery**. If the area loads with a dashboard (rather than a "get started" splash), the service is active.
**How to implement if missing:** Confirm a qualifying license is assigned (see R2) and open **Cloud apps** once to initialize the service. First-time onboarding is out of scope here — use the *Onboarding Accelerator — Microsoft Defender for Cloud Apps* solution. Record "service not provisioned" as a coverage finding rather than skipping silently.

## R2. Licensing for Defender for Cloud Apps (and app governance)
**Description:** The licenses/plans that enable Defender for Cloud Apps and, separately, **app governance**.
**Why required:** Some assessment domains only exist when the plan is enabled — e.g. app governance policies are only assessable when app governance is licensed and turned on.
**How to verify:** In the Microsoft 365 admin center confirm the plan that includes Defender for Cloud Apps is assigned; in the Defender portal check whether **App governance** appears under **Cloud apps**. *License-to-feature mapping changes — verify current entitlements in your tenant.*
**How to implement if missing:** Note any unlicensed capability as a **coverage gap finding** (a genuine posture gap), not an omission. Do not assume a feature is misconfigured when it is simply unlicensed — the finding is "license/enable to gain this control."

## R3. Read-only Security Reader / Global Reader access
**Description:** A read-only role sufficient to enumerate Cloud Apps configuration and the OAuth apps in the directory.
**Why required:** The assessment must prove it changes nothing; read-only roles are sufficient for every script here.
**How to verify:** Entra admin center → **Roles and administrators** → confirm your account holds **Security Reader** and/or **Global Reader**. Confirm you can open **Cloud apps → Policies** and view (not edit) them.
**How to implement if missing:** Assign **Security Reader** (or **Global Reader**). Do **not** grant write/admin roles for the assessment itself.

## R4. Microsoft Graph read scopes consented
**Description:** The read-only Graph scopes the scripts use — Security read (e.g. `SecurityEvents.Read.All`) and directory/application read (e.g. `Application.Read.All`, `Directory.Read.All`) for OAuth-app enumeration.
**Why required:** The discovery, validation, scoring, OAuth-audit, and reporting scripts collect configuration and posture through Graph.
**How to verify:** Run `Connect-MgGraph -Scopes "SecurityEvents.Read.All","Application.Read.All","Directory.Read.All"` and confirm it succeeds; then `SOAMCA-Discovery.ps1` should run without a permissions error. *Verify current scope names and consent requirements.*
**How to implement if missing:** Have an administrator consent the read-only scopes (delegated or app-only). Never request write scopes for this assessment.

## R5. Cloud discovery data source context
**Description:** Knowledge of how (or whether) cloud discovery is being fed — automated log upload, Defender for Endpoint integration, or manual snapshot uploads.
**Why required:** "Discovery coverage" is a scored domain; you must know the ingestion method to judge whether it is continuous versus one-off.
**How to verify:** **Cloud apps → Cloud discovery → Settings** (data sources / automatic log upload) and **Settings → Microsoft Defender for Endpoint integration**. Note which are configured.
**How to implement if missing:** Nothing to change for the assessment — simply **record the current ingestion method** so the scoring reflects it. Continuous ingestion scores higher than manual snapshots; no source at all is a finding.

## R6. A defined assessment scope and a secure output location
**Description:** An agreed scope (which apps/users/connectors are in scope) and a secure place to store the findings report and the saved baseline.
**Why required:** Scope keeps the score comparable across runs; the findings report is a map of your weaknesses and must be handled as sensitive (Global Requirements G5, G7).
**How to verify:** The scope is written down; a restricted folder/location exists for `SOAMCA-*.json` outputs and the findings report.
**How to implement if missing:** Agree the scope with the security owner before running; create a restricted output location. The scripts default to writing JSON outputs in the working directory — point them at the secure location.
