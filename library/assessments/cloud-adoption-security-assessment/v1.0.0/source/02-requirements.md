# 2. Requirements — Cloud Adoption Security Assessment

The category-wide prerequisites (the target tenant, read-only assessor access, Graph/Az API access,
licensing, scope/baseline, output handling, remediation ownership) are published once in
**Global Requirements — Assessments** — read that first. This page lists only the prerequisites
**specific to this whole-estate assessment**. Each item: **Description / Why required / How to verify /
How to implement if missing.**

> Everything here is read-only. If any item can only be satisfied with write/admin access, that is a
> signal you have over-scoped the identity — an assessment needs to *read* configuration, nothing more.

## R1. Security Reader (or Global Reader) across Microsoft 365 / Entra
**Description:** A directory role that can read identity, Conditional Access, Secure Score, and Defender
configuration tenant-wide — **Security Reader** is the least-privilege fit; **Global Reader** also works.
**Why required:** The identity, endpoint, data, app, and Secure Score portions of the assessment read
these blades via Graph; without the role the discovery scripts return empty or access-denied.
**How to verify:** Entra admin center → **Roles and administrators** → confirm your account holds
**Security Reader** or **Global Reader**. Then run `CLDSEC-Validate.ps1` — it confirms the effective read scopes.
**How to implement if missing:** Have a Privileged Role Administrator assign **Security Reader**. Do **not**
grant a write/admin role for the assessment — read-only is the point.

## R2. Azure **Reader** at every in-scope subscription (and Security Reader on Defender for Cloud)
**Description:** The Azure RBAC **Reader** role at each subscription (or management group) in scope, plus
**Security Reader** for Microsoft Defender for Cloud posture.
**Why required:** The infrastructure and network pillars, and the Defender for Cloud Secure Score, are read
through Azure Resource Manager; missing Reader means those pillars cannot be scored.
**How to verify:** `portal.azure.com` → the subscription → **Access control (IAM)** → **View my access** →
confirm **Reader**. `CLDSEC-Validate.ps1` also checks `Connect-AzAccount` succeeds and lists in-scope subs.
**How to implement if missing:** Have an Owner/User Access Administrator assign **Reader** at the
subscription or management-group scope. Assign at the highest common scope so all in-scope subs are covered.

## R3. Microsoft Graph read scopes consented
**Description:** Delegated read scopes for the Graph calls the scripts make — for example
`SecurityEvents.Read.All`, `Policy.Read.All`, `Directory.Read.All`, `IdentityRiskEvent.Read.All`,
`DeviceManagementConfiguration.Read.All`. *Verify the current scope names and least-privilege set for your tenant.*
**Why required:** Graph enforces per-scope consent; without the read scopes, Secure Score, Conditional
Access, and Defender configuration calls fail with `Authorization_RequestDenied`.
**How to verify:** Run `Connect-MgGraph -Scopes <list>` and accept the consent prompt; `Get-MgContext`
shows the granted scopes. `CLDSEC-Validate.ps1` reports which required scopes are present.
**How to implement if missing:** Consent the read scopes at sign-in (delegated), or have an admin grant
tenant-wide admin consent for the read-only scope set. Never request write scopes for this assessment.

## R4. PowerShell 7+ with the Microsoft.Graph, Az, and (optional) Defender modules
**Description:** PowerShell 7 or later with **Microsoft.Graph**, **Az.Accounts / Az.Resources /
Az.Security / Az.Network**, and — where you assess Defender for Endpoint directly — the relevant Defender
API access. *Verify current module versions.*
**Why required:** All five scripts are PowerShell and depend on these modules; version drift is the most
common cause of a script that "does nothing".
**How to verify:** `$PSVersionTable.PSVersion` ≥ 7; `Get-Module Microsoft.Graph,Az.Accounts -ListAvailable`.
**How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` and
`Install-Module Az -Scope CurrentUser`. Use a maintained PowerShell 7.x build.

## R5. A defined, documented assessment scope
**Description:** A written scope — which subscriptions, which Defender/M365 products, which user and device
population, and the pillar weighting if you deviate from the default — agreed before the run.
**Why required:** Scope keeps the maturity score bounded and comparable run-to-run; an undocumented scope
makes the score impossible to defend or trend.
**How to verify:** The scope document exists and names the subscriptions/products; the assessment records
the run date and scope in the report header.
**How to implement if missing:** Agree the scope with the security owner before running. Start narrow
(one business unit / one subscription) for the pilot, then expand.

## R6. Microsoft Secure Score enabled and populated
**Description:** Microsoft Secure Score active in the Microsoft Defender portal with control profiles
populated (it populates automatically once the relevant products are licensed and reporting).
**Why required:** Secure Score is a core anchor for the identity/endpoint/app pillar scores and the
highest-impact-actions list; an empty Secure Score removes that signal.
**How to verify:** `security.microsoft.com` → **Secure Score** shows a current score and improvement
actions. `CLDSEC-SecureScore.ps1` returns the score and control profiles.
**How to implement if missing:** Ensure the products (Entra, Defender, Intune) are licensed and reporting;
Secure Score populates within a day or two. Note an absent Secure Score itself as a finding.

## R7. (Optional) Sentinel / Advanced Hunting read access for corroborating KQL
**Description:** Reader access to a **Microsoft Sentinel** workspace or **Advanced Hunting** in the Defender
portal, if you want to corroborate posture with the supplied read-only KQL (e.g. legacy-auth sign-ins).
**Why required:** The KQL is optional corroboration; without it the assessment still scores from
configuration, but you lose the live-signal cross-check.
**How to verify:** You can open Advanced Hunting (`security.microsoft.com` → **Hunting**) or the Sentinel
Logs blade and run a query. *Verify current portal location and licensing.*
**How to implement if missing:** Grant **Microsoft Sentinel Reader** / Advanced Hunting read access, or
skip the KQL corroboration — it is optional, not required, for the score.

## R8. A secure destination for the findings report
**Description:** A restricted-access location to store the exported findings (CSV/JSON/report), which
contains a detailed map of your weaknesses.
**Why required:** The report is sensitive by nature; storing it loosely turns your assessment into an
attacker's shopping list.
**How to verify:** A restricted SharePoint/Teams site or secured file share exists and access is limited to
the security owners.
**How to implement if missing:** Provision a restricted destination before running; share findings on a
need-to-know basis. *Risk-acceptance of any finding remains the customer's decision.*
