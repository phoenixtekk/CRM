# 2. Requirements Guide — Azure RMS / AIP → Built-in Unified Labeling Migration

Verify **every** requirement before configuring or cutting over. Each entry: **Description · Why ·
Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md`
(the six shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell +
Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot
scope with change control) — those are referenced here, not repeated.

## 2.1 Sensitivity-labeling licensing (labels + encryption)
**Description:** Licensing that covers **sensitivity labels and label-based encryption** — Azure
Information Protection P1/P2 (standalone or via **Microsoft 365 E3/E5** / E5 Compliance). Encryption,
custom permissions, and automatic/recommended labeling have specific plan requirements (Global
Requirement 1).
**Why:** Built-in labeling consumes the same labels the AIP add-in did; the labels and their protection
must be licensed for the target users, or the label simply won't apply after cutover.
**Verify:** Microsoft 365 admin center → `Billing → Licenses`; run `IPRMSMIG-Assess-Migration.ps1` — it
reports the relevant sensitivity-labeling SKUs via Graph. Confirm labels appear in the Purview portal.
**Implement:** Assign the required plan to the pilot ring **before** cutover; verify encryption features
against your plan — some are E5/E5-Compliance-only.

## 2.2 Least-privilege information-protection roles
**Description:** An account in **Information Protection Admin** (or **Compliance Administrator**) to
manage sensitivity labels and label policies, plus **Global Administrator** reserved only for one-time
actions (activating Azure RMS if it is off, consenting Graph scopes) — per Global Requirement 2.
**Why:** Label and policy configuration requires the matching Purview role; the migration itself needs no
broad admin beyond the reserved one-time steps.
**Verify:** Purview portal → `Settings → Roles & scopes → Role groups` (verify path) — confirm
membership in **Information Protection** / **Compliance Administrator**. `Connect-IPPSSession` succeeds.
**Implement:** Add the account to the least-privilege role group; reserve a named Global Administrator
for the Azure RMS activation and Graph-consent steps only.

## 2.3 Toolchain: S&C PowerShell + AIPService module + Graph
**Description:** A workstation with **ExchangeOnlineManagement** (`Connect-IPPSSession` for the label
cmdlets), the **AIPService** module (`Connect-AipService` for the Azure Rights Management protection
service and its templates), and the **Microsoft Graph** SDK — modern-auth / MFA admin (Global
Requirement 3).
**Why:** Labels and label policies are managed through S&C PowerShell; RMS activation and protection
templates through AIPService; licensing/user data through Graph. Every script uses these.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, AIPService, Microsoft.Graph.Authentication`;
`Connect-IPPSSession`, `Connect-AipService`, and `Connect-MgGraph` all succeed.
`IPRMSMIG-Assess-Migration.ps1` installs missing modules and reports connectivity.
**Implement:** `Install-Module ExchangeOnlineManagement`, `Install-Module AIPService`, and
`Install-Module Microsoft.Graph` (`-Scope CurrentUser`); confirm modern-auth sign-in.

## 2.4 Azure Rights Management (protection) is activated
**Description:** The **Azure Rights Management** service (the protection behind label encryption and
legacy RMS templates) is **activated** for the tenant.
**Why:** If the protection service is not activated, label-based encryption and departmental-template
protection cannot apply — the migration would drop protection silently.
**Verify:** Run `IPRMSMIG-Scope-Health.ps1` — it reports `Get-AipServiceConfiguration` `FunctionalState`
(expect `Enabled`). Purview/portal shows encryption available on labels.
**Implement:** If `Disabled`, activate as a one-time Global Admin action (`Enable-AipService` via the
AIPService module) under change control; confirm super-users are configured for recovery (2.8).

## 2.5 Supported Office builds for built-in labeling
**Description:** The in-scope Office apps are on a **build that supports built-in labeling** and the
specific features you use (encryption, co-authoring on encrypted files, custom permissions). Minimum
builds are feature-dependent.
**Why:** Built-in labeling and several parity features require minimum Office versions; cutting a user
over on too old a build breaks parity.
**Verify:** Confirm the Office channel/build for the pilot ring against Microsoft's current
built-in-labeling capabilities table (**verify — versions evolve**); record it in the scope map.
`IPRMSMIG-Test-Parity.ps1` takes the target build as input and flags features that need a newer one.
**Implement:** Update the pilot ring to a supported build before cutover; defer users on unsupported
builds until updated.

## 2.6 Current labeling estate inventoried (labels, policies, templates)
**Description:** A read inventory of the existing **sensitivity labels**, **label policies** (and their
advanced settings), and **Azure RMS / protection templates** — the estate that must survive with parity
(Global Requirement 4).
**Why:** You cannot prove parity against an estate you haven't enumerated; this is the migration's
baseline.
**Verify:** Run `IPRMSMIG-Assess-Migration.ps1` — it lists labels (`Get-Label`), policies
(`Get-LabelPolicy`), and RMS templates (`Get-AipServiceTemplate`), and writes
`AIP/RMS Inventory – Migration – Assess`.
**Implement:** Produce the inventory before designing the parity map; if labels are missing from the
unified store, resolve that (2.7) before cutover.

## 2.7 Labels present in the unified store (no classic-only labels)
**Description:** All labels the add-in showed are present and published in the **unified labeling store**
(Microsoft Purview), not stranded in a legacy/classic configuration.
**Why:** Built-in labeling reads only the unified store; a label that exists only in a legacy location
will disappear for users after cutover.
**Verify:** `Get-Label` / `Get-LabelPolicy` return every expected label and it is scoped to the pilot
users; `IPRMSMIG-Test-Parity.ps1` resolves the effective label set for a pilot user.
**Implement:** Publish any missing label in the Purview portal and add it to the pilot users' label
policy; run `Execute-AzureADLabelSync` (via `IPRMSMIG-Scope-Health.ps1 -Commit`) so protection picks up
label changes.

## 2.8 Azure RMS super-users configured (recovery)
**Description:** **Super-users** are configured in the Azure Rights Management service so protected
content remains recoverable during and after the migration.
**Why:** If protection or a template is mis-mapped, super-user access is the safety net for recovering
encrypted content; it must exist before you change protection behaviour.
**Verify:** `IPRMSMIG-Scope-Health.ps1` reports super-user feature state and members
(`Get-AipServiceSuperUserFeature` / `Get-AipServiceSuperUser`).
**Implement:** Enable the super-user feature and add the named recovery account(s) as a one-time,
audited action before cutover — membership determined with security/records stakeholders.

## 2.9 Office client-policy delivery mechanism
**Description:** A way to deliver the **Office client policy** that enables built-in labeling and
disables the AIP add-in — **Group Policy** (Office ADMX) or the **Microsoft 365 Apps admin center**
(Cloud Policy) — scoped so it can target the pilot ring first.
**Why:** The cutover is driven by client policy; without a ring-scoped delivery mechanism you cannot
pilot, only flip everyone at once.
**Verify:** Confirm you can target a policy to the `AIP Migration Pilot Ring – Stage1` group. The exact
setting names / registry values are **flagged "verify against current Office ADMX"** in the
Implementation Guide.
**Implement:** Prepare a GPO or Cloud Policy configuration scoped to the pilot ring group; do not apply
tenant-wide until the ring passes validation.

## 2.10 Stakeholders, pilot ring, and change control
**Description:** Engagement with **compliance, records, privacy, security, and information-protection**
stakeholders (Global Requirement 5); a defined **pilot ring** (`AIP Migration Pilot Ring – Stage1`) and
a **change-control** window for each cutover (Global Requirement 6).
**Why:** The cutover changes classification and protection behaviour for real users and touches legacy
RMS templates whose applicability is a records/compliance call.
**Verify:** Named approvers recorded; the pilot ring group exists and is targetable; a change window and
rollback path are agreed.
**Implement:** Identify owners; define the ring; agree change control and rollback before the first
cutover. Determinations about which legacy templates still apply are the stakeholders' to make.

---
## Checklist
- [ ] Sensitivity-labeling licensing (labels + encryption) confirmed for the pilot ring
- [ ] Information Protection / Compliance Administrator access; Global Admin reserved for one-time steps
- [ ] ExchangeOnlineManagement + AIPService + Microsoft Graph installed; all three connections succeed
- [ ] Azure Rights Management activated (`FunctionalState = Enabled`)
- [ ] Pilot ring on a supported Office build for the features in use
- [ ] Labels, label policies, and RMS templates inventoried (`AIP/RMS Inventory – Migration – Assess`)
- [ ] All add-in labels present/published in the unified store and scoped to pilot users
- [ ] Azure RMS super-users configured for recovery
- [ ] Ring-scoped Office client-policy delivery (GPO or Cloud Policy) prepared
- [ ] Stakeholders named; `AIP Migration Pilot Ring – Stage1` defined; change control + rollback agreed
