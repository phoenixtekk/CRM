# Global Requirements — SharePoint Online & OneDrive Solutions

These requirements apply to **every** solution in the **SharePoint** category (SharePoint Online
architecture & provisioning, external sharing, OneDrive for Business, migration to SPO, permissions,
search, and records/retention). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every SharePoint solution).** The **SharePoint admin center**, the
> **Microsoft 365 admin center**, the **SharePoint Online Management Shell** and **PnP PowerShell**,
> and **Microsoft Graph** are authored at exact, current click-by-click / cmdlet detail from Microsoft's
> public documentation. Where a capability, setting, or portal path is **plan- or version-dependent**
> (storage limits, sharing controls, Syntex/records features, Commercial vs Government cloud), it is
> **cited or flagged "verify in your tenant"** — never invented. **Third-party migration and governance
> tools** (e.g. ShareGate, Migration Manager, AvePoint) are integrated at the pattern level; their
> consoles are deferred to the vendor's docs. Automation is **PowerShell** (SPO Management Shell / PnP /
> Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with SharePoint Online / OneDrive and licensing
- **Description:** A Microsoft 365 tenant with **SharePoint Online** and **OneDrive for Business** and
  the licensing the capability requires (e.g. an E-plan for advanced records/retention, Syntex where used).
- **Why required:** All site, sharing, OneDrive, and records configuration depends on the right plan.
- **How to verify:** In the M365 admin center confirm the SharePoint/OneDrive subscription and add-ons.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Administrative access (least-privilege SharePoint roles)
- **Description:** Access with the least-privilege role the solution names — typically **SharePoint
  Administrator** (and Global Administrator only where genuinely required, e.g. tenant-wide sharing).
- **Why required:** Tenant/site settings, sharing, provisioning, and records changes require the role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. SharePoint Online Management Shell / PnP + Graph toolchain
- **Description:** A workstation with the **SharePoint Online Management Shell** and/or **PnP
  PowerShell** (and Graph PowerShell where used), modern-auth / MFA-capable admin sign-in (PnP app
  registration where required).
- **Why required:** Configuration, automation, and the provided scripts run through SPO/PnP/Graph.
- **How to verify:** `Connect-SPOService` / `Connect-PnPOnline` succeeds; modules installed.
- **How to implement if missing:** Install the modules; register the PnP app where needed; confirm sign-in.

## 4. Information architecture & identity/group source of truth
- **Description:** A defined **information-architecture** intent (hub/site structure, taxonomy) and the
  identity/group source (Entra ID groups, M365 Groups backing team sites) that drives access.
- **Why required:** Provisioning, permissions, search, and governance key off the IA and groups.
- **How to verify:** Confirm the intended hub/site structure and which groups model is authoritative.
- **How to implement if missing:** Define the IA and group model (often the Architecture solution) first.

## 5. A pilot scope and change control
- **Description:** A **pilot site collection / hub / user set** to validate on before tenant-wide
  rollout, and a **change-control** process for production changes (sharing, permissions, retention,
  migration cutover are high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; tenant-wide sharing/permission/retention changes are high-impact.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

## 6. Security, compliance & records stakeholders
- **Description:** Engagement with the **security, compliance/records, and data-governance** stakeholders
  whose policies the configuration must satisfy (external sharing, permissions, retention/records,
  sensitivity).
- **Why required:** Sharing, permission, and records settings must align to enterprise policy.
- **How to verify:** Confirm the applicable policies and named approvers.
- **How to implement if missing:** Identify the owners and capture requirements before configuring governance.

*The deployment model across every SharePoint solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (SPO Management Shell / PnP / Graph) — never with
hardcoded credentials or secrets in code.*
