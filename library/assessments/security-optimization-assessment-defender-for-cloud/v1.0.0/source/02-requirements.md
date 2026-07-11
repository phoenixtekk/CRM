# 2. Requirements — Security Optimization Assessment: Defender for Cloud

The category-wide prerequisites (the target tenant/subscription, read-only assessor access, Graph/Az access, licensing, scope/baseline, output handling, remediation ownership) are documented once in **`global-requirements-assessments.md`** — read that first. This section lists only the prerequisites **specific to assessing Defender for Cloud**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Azure subscription(s) in scope with Defender for Cloud registered
**Description:** One or more Azure subscriptions where Defender for Cloud is registered (the `Microsoft.Security` resource provider).
**Why required:** Plans, Secure Score, recommendations, and coverage are per-subscription; there is nothing to enumerate without a registered subscription.
**How to verify:** `Get-AzContext` shows a subscription; in the portal, **Microsoft Defender for Cloud** loads and shows the subscription under **Environment settings**.
**How to implement if missing:** Ensure the subscription exists and `Microsoft.Security` is registered (`Get-AzResourceProvider -ProviderNamespace Microsoft.Security`). Record any unregistered subscription as a **coverage finding**.

## R2. Read-only roles: Security Reader + Reader at scope
**Description:** **Security Reader** (Defender for Cloud read) and **Reader** at the subscription/management-group scope.
**Why required:** The assessment must prove it changes nothing; these read-only roles are sufficient for every script here.
**How to verify:** Entra → **Roles and administrators** for Security Reader; Azure → subscription **Access control (IAM)** for Reader. Confirm you can view (not edit) **Environment settings** and recommendations.
**How to implement if missing:** Assign **Security Reader** and **Reader**. Do **not** grant Security Admin/Contributor/Owner for the assessment itself.

## R3. Az PowerShell modules and Resource Graph access
**Description:** `Az.Accounts`, `Az.Security`, `Az.ResourceGraph`, `Az.Resources` installed and reachable, with network access to Azure endpoints.
**Why required:** The scripts collect plan tiers, Secure Score, recommendations, and coverage through Az and Azure Resource Graph (KQL).
**How to verify:** `Connect-AzAccount` succeeds and `SOAMDC-Discovery.ps1` runs; `Search-AzGraph -Query "securityresources | limit 1"` returns without error.
**How to implement if missing:** `Install-Module Az -Scope CurrentUser`. Ensure the assessor identity can reach `management.azure.com`.

## R4. Awareness of the paid-plan landscape (do not assume misconfiguration)
**Description:** Understanding that Defender CSPM and the workload plans (Servers, Storage, SQL, Containers, etc.) are **paid** and enabled per subscription.
**Why required:** A plan being off is a **coverage finding**, not necessarily a defect — the finding is "enable this plan to gain the protection/posture," which the customer decides.
**How to verify:** In **Environment settings → Defender plans** per subscription, note which plans are On/Off. *Plan-to-feature mapping and pricing change — verify current.*
**How to implement if missing:** Record off-plans as coverage findings with the caveat that enabling them has a cost the customer must accept.

## R5. Compliance-standard context
**Description:** Knowledge of which regulatory standard(s) the organization must meet (so the compliance-domain score is meaningful).
**Why required:** The regulatory-compliance posture is scored against the standard the organization actually needs — which standard applies is the compliance team's determination, not the assessment's.
**How to verify:** **Regulatory compliance** in Defender for Cloud shows the enabled standards; confirm with the compliance owner which are required.
**How to implement if missing:** If no standard is mapped, record it as a finding ("enable and map the required standard") and note that the *choice* of standard is deferred to compliance/legal.

## R6. A defined assessment scope and a secure output location
**Description:** An agreed scope (which subscriptions/management groups and clouds) and a secure place to store the findings report and the saved baseline.
**Why required:** Scope keeps the score comparable across runs; the findings report is sensitive (Global Requirements G5, G7).
**How to verify:** The scope is documented; a restricted location exists for `SOAMDC-*.json` outputs and the findings report.
**How to implement if missing:** Agree the scope with the security owner before running; create a restricted output location and point the scripts at it.
