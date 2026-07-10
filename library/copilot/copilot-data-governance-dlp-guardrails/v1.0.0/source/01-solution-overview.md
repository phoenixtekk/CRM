# 1. Solution Overview — Microsoft 365 Copilot Data Governance & DLP Guardrails

## What it is
A repeatable method to **govern the data boundary around Microsoft 365 Copilot** using Microsoft Purview:
sensitivity labels on Copilot-accessible content, **DLP for Microsoft 365 Copilot** to restrict labelled
or sensitive data from AI processing, guardrails on how prompts and responses are handled, and
audit / eDiscovery of Copilot interactions. Where the oversharing/SharePoint-permissions solution fixes
*who can reach what*, this solution governs *what Copilot is allowed to use and generate* — and it is
built **simulation-first** so nothing is blocked until it has been validated.

## How the technology works
- **Copilot honors information protection.** Sensitivity labels with **encryption / usage rights** are
  enforced at the item level — Copilot will not surface or summarize content a user cannot decrypt.
  Labels are therefore the primary governance lever, not just a classification tag.
- **DLP for Microsoft 365 Copilot** is a Data Loss Prevention location scoped to the **Copilot**
  experience: a policy conditioned on sensitivity labels (or sensitive information types) can keep the
  matching content **out of Copilot responses**. *(The Copilot DLP location and some behaviors are
  licensing-gated and/or in preview — verify current availability in your tenant.)*
- **Auto-labeling** closes label-coverage gaps at scale by applying a label when content matches agreed
  conditions — run in **simulation** first to size the impact before it labels anything.
- **Prompt / response guardrails** combine the above with organizational responsible-use policy: what
  Copilot may process, what it must exclude, and how generated content is handled.
- **Audit & eDiscovery.** Copilot prompts and responses are recorded in the **Purview unified audit log**
  and are discoverable via **eDiscovery** — the evidence trail for governance and investigations.
- **Automation** is PowerShell: **Security & Compliance PowerShell** (`Connect-IPPSSession`) for labels,
  auto-labeling, and DLP; **Microsoft Graph** for coverage discovery and audit queries; the **Purview
  portal** for the policy blades.

## The standard deployment model — Assess → Configure → Pilot → Validate → Expand
1. **Assess** — confirm scope, licensing (including DLP-for-Copilot availability), roles, connections;
   run read-only discovery for label coverage and sensitive content across the Copilot-accessible estate.
2. **Configure** — with compliance stakeholders, agree the default label, the "keep out of Copilot"
   labels/conditions, and the guardrails; stage the label policy, auto-labeling, and DLP-for-Copilot in
   **simulation/test**.
3. **Pilot** — publish to a **pilot ring**; auto-labeling in **simulation** (labels nothing yet),
   DLP-for-Copilot in **test/disabled** (blocks nothing yet).
4. **Validate** — review simulation/test matches for false positives; confirm audit/eDiscovery captures
   Copilot interactions; confirm no legitimate Copilot use is over-blocked.
5. **Expand** — only after the gate passes, move auto-labeling to **on** and DLP-for-Copilot to
   **enforce**, widen scope under change control, record the governance report, and stand up a recurring
   review.

## Scope
- Label-coverage discovery across the Copilot-accessible estate; sensitive-content picture.
- Sensitivity-label alignment (default labeling, auto-labeling in simulation) so Copilot-accessible
  content is correctly classified.
- DLP for Microsoft 365 Copilot to restrict labelled/sensitive data from AI processing — simulation-first.
- Prompt/response guardrails tied to responsible-use policy.
- Audit + eDiscovery of Copilot interactions.

## What is out of scope
- **Classification determinations** — what is "sensitive," acceptable for AI, or must be blocked — are
  the compliance/legal/records decision; this guide supplies the technical controls and evidence.
- **Designing the full sensitivity-label taxonomy and the broad DLP program** (endpoint/cloud/email) —
  delivered in the Purview information-protection and DLP solutions; referenced, not rebuilt, here.
- **Fixing SharePoint/OneDrive oversharing (access)** — delivered in the Copilot oversharing/SharePoint-
  permissions solution; this solution governs *use*, that one governs *access*.
- **Copilot licensing/enablement, identity, network/client readiness** — covered by the Copilot global
  requirements and the Entra solutions.

## Authentication & connections used
- **Security & Compliance PowerShell** (`Connect-IPPSSession`) — labels, auto-labeling, DLP policies.
- **Microsoft Graph PowerShell** (`Connect-MgGraph`, read scopes e.g. `AuditLog.Read.All`,
  `InformationProtectionPolicy.Read`) — coverage discovery and audit queries.
- **Microsoft Purview portal** (`https://purview.microsoft.com`) — Information Protection, DLP, Audit,
  and eDiscovery blades.
- **Roles:** Compliance Administrator / Compliance Data Administrator (or scoped Information Protection and
  DLP roles), and eDiscovery Manager for the audit/eDiscovery path. Reserve Global Administrator for
  tenant-wide changes only.

> The category-level prerequisites (tenant, Copilot licensing, Entra identity/MFA, admin roles, network/
> client readiness, governance policy) live in **`global-requirements-copilot.md`** — confirm those
> first; this solution's specific prerequisites are in doc 2.
