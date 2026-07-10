# 2. Requirements — Microsoft 365 Copilot Data Governance & DLP Guardrails

The category-level prerequisites (Microsoft 365 tenant and workloads, Copilot licensing, Entra ID
identity/MFA, administrative roles, network/client readiness, and governance/responsible-use policy) are
covered once in **`global-requirements-copilot.md`** — confirm those first and do not repeat them here.
Below are the prerequisites **specific to this data-governance/DLP solution**. Each: **Description / Why
required / How to verify / How to implement if missing.**

## 2.1 Microsoft Purview information-protection & DLP licensing — verify
- **Description:** The Purview plan that unlocks sensitivity labels, auto-labeling, and DLP (commonly
  E5 / E5 Compliance or equivalent), plus the **DLP for Microsoft 365 Copilot** capability.
- **Why required:** Labeling, auto-labeling, and DLP-for-Copilot are the core controls; some are
  plan-gated and some are in preview.
- **How to verify:** Purview portal → **Information Protection** and **Data Loss Prevention** render and
  allow policy creation; confirm the **Microsoft 365 Copilot** location is offered when creating a DLP
  policy. *(DLP-for-Copilot availability/behavior is licensing-dependent and may be in preview — verify
  in your tenant.)*
- **How to implement if missing:** Acquire the required Purview plan; where DLP-for-Copilot is not
  present, govern via label **encryption/usage rights** (honored by Copilot) as the interim equivalent and
  note DLP-for-Copilot as pending.

## 2.2 Compliance / Information Protection roles
- **Description:** Compliance Administrator / Compliance Data Administrator (or scoped Information
  Protection Admin and DLP Compliance roles), and eDiscovery Manager for the audit/eDiscovery path.
- **Why required:** Creating labels, auto-labeling, and DLP policies and running eDiscovery require these
  roles.
- **How to verify:** Purview portal → **Roles & scopes** (or Entra **Roles and administrators**) shows the
  operator holds them.
- **How to implement if missing:** Assign least-privilege compliance roles for the task; reserve Global
  Administrator for tenant-wide changes.

## 2.3 PowerShell — Security & Compliance PowerShell and Microsoft Graph
- **Description:** The Exchange Online management module (for `Connect-IPPSSession`) and `Microsoft.Graph`
  installed on the operator workstation.
- **Why required:** The bundled scripts manage labels/auto-labeling/DLP via Security & Compliance
  PowerShell and query coverage/audit via Graph.
- **How to verify:** `Get-Module ExchangeOnlineManagement,Microsoft.Graph -ListAvailable`; the discovery
  script reports which are present.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
  `Install-Module Microsoft.Graph -Scope CurrentUser`. PowerShell 7+ recommended.

## 2.4 Published sensitivity-label taxonomy (baseline)
- **Description:** A published sensitivity-label set in Purview (even minimal), ideally with a defined
  "highly confidential / do-not-use-in-AI" tier.
- **Why required:** DLP-for-Copilot and default/auto-labeling condition on labels; without a taxonomy
  there is nothing to enforce against.
- **How to verify:** Purview portal → **Information Protection → Labels** shows published labels.
- **How to implement if missing:** Publish a baseline taxonomy first (see the Purview information-
  protection / sensitivity-label solutions). This solution *applies and enforces* labels around Copilot;
  it does not design the taxonomy.

## 2.5 Auditing enabled (Copilot interactions)
- **Description:** Purview unified audit logging enabled so Copilot prompts/responses are recorded.
- **Why required:** The audit/eDiscovery guardrail and the validation evidence depend on the audit trail.
- **How to verify:** Purview portal → **Audit** shows recording is on; `Search-UnifiedAuditLog` returns
  Copilot interaction events.
- **How to implement if missing:** Enable auditing (**Audit** → *Start recording user and admin
  activity*); allow time for backfill before relying on it.

## 2.6 Defined pilot ring and simulation window
- **Description:** A **pilot ring** of users for the label policy and DLP-for-Copilot, and an agreed
  **simulation/test window** before enforcement.
- **Why required:** Every enforcing control is piloted in simulation/test first; you must know the pilot
  population and how long simulation runs before you evaluate.
- **How to verify:** A documented pilot user group and a recorded simulation window.
- **How to implement if missing:** Define the pilot cohort (e.g. the Copilot pilot users) and agree the
  window (commonly aligned to a review cadence) with stakeholders.

## 2.7 Compliance-stakeholder engagement (classification determinations)
- **Description:** Named compliance/records/privacy/legal stakeholders who own the classification and
  acceptable-AI-use determinations.
- **Why required:** *What is "sensitive," acceptable for AI, or must be blocked* is their decision, not the
  admin's; the technical controls implement their determinations.
- **How to verify:** Stakeholders identified and available for the design step; determinations recorded.
- **How to implement if missing:** Engage them before Configure; do not invent classification rules —
  record their decisions and implement them.

## 2.8 Responsible-use / acceptable-AI-use policy (referenced)
- **Description:** An organizational position on acceptable Copilot use and data handling (from the
  category governance requirement).
- **Why required:** The prompt/response guardrails operationalize this policy; without it, "acceptable"
  is undefined.
- **How to verify:** A documented AI-use policy exists (global requirement G8).
- **How to implement if missing:** Adopt the policy (a compliance/legal determination) and map its rules
  to the technical guardrails here.
