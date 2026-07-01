# 2. Requirements Guide — Microsoft 365 Security Baseline & Audit Readiness

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-security.md`.

## 2.1 Microsoft 365 subscription with security workloads
**Description:** A Microsoft 365 tenant with Entra ID, Exchange Online, and the collaboration
services (Teams / SharePoint / OneDrive) active.
**Why:** The baseline hardens these services, so they must exist to configure.
**Verify:** `https://admin.microsoft.com` to Billing to Licenses shows an M365 plan; the service
health for Exchange, SharePoint, and Teams is active.
**Implement:** Assign Microsoft 365 Business Premium, E3, or E5 (or the relevant standalone plans).

## 2.2 Security / compliance licensing for Secure Score and Compliance Manager
**Description:** Licensing that surfaces Microsoft Secure Score and Microsoft Purview Compliance
Manager (Compliance Manager is included at a baseline level; premium assessment templates need E5 /
compliance add-ons).
**Why:** Secure Score measures posture and Compliance Manager holds the framework assessment and
improvement actions.
**Verify:** `https://security.microsoft.com` to Secure Score loads; `https://purview.microsoft.com`
to Compliance Manager loads and shows assessment templates.
**Implement:** Ensure E3/E5 or the compliance add-on is assigned so the required assessment
templates are available.

## 2.3 Administrative roles
**Description:** Least-privilege admin roles for the operator (Security Administrator plus the
service admin roles needed to change config, e.g. Exchange Administrator, SharePoint Administrator).
**Why:** Configuring the baseline and running the assessment requires elevated, scoped rights;
Global Administrator is reserved for tenant-wide changes.
**Verify:** Entra to Roles and administrators; confirm Security Administrator and the relevant
service-admin roles.
**Implement:** Assign Security Administrator and the specific service-admin roles; avoid granting
Global Administrator broadly.

## 2.4 A named target framework
**Description:** The recognized framework (or frameworks) the tenant is being assessed against, so
Compliance Manager maps to the right controls.
**Why:** Controls, evidence, and improvement actions are mapped to a specific framework; without a
named target the mapping is undirected.
**Verify:** The framework is documented in the baseline register and an assessment template for it
exists in Compliance Manager.
**Implement:** Confirm the target framework with the audit sponsor, then select its assessment
template in Compliance Manager (Requirement 2.2 gates availability).

## 2.5 A baseline owner and change control
**Description:** A named owner accountable for the baseline register and a change-control / rollback
process for security-impacting changes.
**Why:** Baseline changes can affect sign-in, mail flow, and sharing; a pilot gate and rollback are
mandatory, and the owner keeps the register authoritative.
**Verify:** The baseline register names an owner; a change ticket with approver, window, and
rollback exists for baseline changes.
**Implement:** Assign the owner; adopt the change-control process from `global-requirements-security.md`.

## 2.6 A pilot scope group
**Description:** A Microsoft Entra security group scoping the pilot population for
scoped-configuration changes (e.g. Conditional Access, DLP).
**Why:** Every change is piloted before tenant-wide expansion — especially anything touching sign-in
or mail flow.
**Verify:** Entra to Groups; the pilot scope group exists — run `M365SEC-Set-ScopeTargeting.ps1`.
**Implement:** Create the scope groups with `M365SEC-Set-ScopeTargeting.ps1` (or Entra to Groups to
New group).

## 2.7 Microsoft Graph PowerShell for discovery and reporting
**Description:** The Microsoft Graph PowerShell SDK on the operator workstation, with consent to the
read scopes the scripts use.
**Why:** The discovery, validation, and report scripts read Secure Score, secure-score control
profiles, and service configuration via Microsoft Graph.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; run
`M365SEC-Discovery.ps1`.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to the read scopes on
first connect.

---
## Checklist
- [ ] Microsoft 365 subscription with Entra / Exchange / collaboration services
- [ ] Security / compliance licensing for Secure Score + Compliance Manager
- [ ] Least-privilege admin roles (Security Administrator + service admins)
- [ ] A named target framework
- [ ] A baseline owner and change control
- [ ] Pilot scope group — `M365SEC-Set-ScopeTargeting.ps1`
- [ ] Microsoft Graph PowerShell installed — `M365SEC-Discovery.ps1`
