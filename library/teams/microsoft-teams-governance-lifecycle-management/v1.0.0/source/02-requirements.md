# Requirements

These are the **solution-specific** prerequisites for Teams governance & lifecycle. They build **on top
of** the shared **Global Requirements — Microsoft Teams Solutions** (`global-requirements-teams.md`): a
licensed M365 tenant with Teams (GR-1), least-privilege admin roles (GR-2), the MicrosoftTeams + Graph
toolchain (GR-3), an identity/group/lifecycle source of truth (GR-4), a pilot scope + change control
(GR-5), and security/compliance/governance stakeholders (GR-6). Verify the shared six first, then the
items below. Each item: **Description / Why / Verify / Implement if missing**.

---

## 1. Microsoft Entra ID P1 for governance features (verify plan)

- **Description:** Microsoft Entra ID **P1** licensing covering every user who is a member of a governed
  group, which gates the M365 Groups **naming policy**, **expiration policy**, and **group sensitivity
  (container) labels**.
- **Why:** These three core controls will not apply — or will error — without P1 for the affected users.
  This is the most common blocker for a governance rollout.
- **Verify:** In the Microsoft 365 admin center → **Billing → Licenses**, confirm Entra ID P1 (or a suite
  that includes it, e.g. certain E-plans) is assigned to governed users. Flag Commercial vs Government —
  confirm availability in your cloud.
- **Implement if missing:** Acquire/assign Entra ID P1 to the users in scope before enabling naming,
  expiration, or container labels.

## 2. Microsoft Graph PowerShell (with beta directory-setting cmdlets)

- **Description:** The **Microsoft.Graph** and **Microsoft.Graph.Beta** PowerShell modules, in addition to
  the MicrosoftTeams module from GR-3. The `Group.Unified` directory settings (creation control, naming
  policy) are managed with the **beta** directory-setting cmdlets.
- **Why:** Creation control and the naming policy are stored as directory settings, exposed today through
  `Get-MgBetaDirectorySetting` / `Update-MgBetaDirectorySetting`. The lifecycle (expiration) policy uses
  `*-MgGroupLifecyclePolicy`.
- **Verify:** `Get-Module Microsoft.Graph.Beta -ListAvailable` returns a version; `Connect-MgGraph
  -Scopes "Directory.ReadWrite.All","Group.ReadWrite.All"` succeeds.
- **Implement if missing:** `Install-Module Microsoft.Graph`, `Install-Module Microsoft.Graph.Beta`;
  confirm modern-auth/MFA sign-in. (The legacy AzureAD/AzureADPreview modules are deprecated — use Graph.)

## 3. Directory-settings admin permissions (Group.Unified)

- **Description:** An admin identity able to read and write **directory settings** and group lifecycle —
  practically a role with the `Directory.ReadWrite.All` and `Group.ReadWrite.All` Graph scopes (e.g.
  **Groups Administrator** for lifecycle/naming, with **Global Administrator** only where a setting
  genuinely requires it).
- **Why:** Changing the `Group.Unified` template (creation control, naming) and creating a lifecycle
  policy are directory-level writes.
- **Verify:** `Get-MgBetaDirectorySetting` lists the tenant settings without an authorization error.
- **Implement if missing:** Have a Global Admin grant the least-privilege role/consent the required Graph
  scopes under change control.

## 4. Designated "group creators" security group

- **Description:** A **security group** (mail-enabled not required) whose members are the users permitted
  to create M365 Groups/Teams once open creation is turned off — named `Group Creators – Governed – Pilot`
  for the pilot and `Group Creators – Governed – Prod` for production.
- **Why:** Creation control works by setting `EnableGroupCreation = false` and pointing
  `GroupCreationAllowedGroupId` at exactly one security group. You must have that group first.
- **Verify:** The group exists in Entra ID and its `Id` (GUID) is known.
- **Implement if missing:** Create the security group and enroll the approved creators (service desk,
  governance team, or delegated owners) before applying creation control.

## 5. Purview compliance plan for retention (verify plan) + compliance owner

- **Description:** The **Microsoft Purview** licensing that enables **retention policies** for Teams
  (channel messages, chats) and the files in the backing SharePoint/OneDrive, plus a named **compliance/
  records owner** who sets the retention **schedule**.
- **Why:** Retention durations, records schedules, and legal-hold scope are **compliance determinations**,
  not technical defaults — this solution configures the mechanism, the owner sets the policy.
- **Verify:** `Connect-IPPSSession` (Security & Compliance PowerShell) connects; `Get-RetentionCompliancePolicy`
  runs. Confirm the plan covers Teams locations. Flag Commercial vs Government portal/URL differences.
- **Implement if missing:** Assign the compliance plan; identify the retention owner and capture the
  schedule before creating any retention policy.

## 6. Container sensitivity labels published (for classification)

- **Description:** **Microsoft Purview** container sensitivity labels (e.g. Public / Internal /
  Confidential) that are scoped to **Groups & sites** and **published** to the users who create teams,
  used as the classification mechanism.
- **Why:** Modern Teams/Groups classification uses **container labels** (the legacy `ClassificationList`
  is deprecated). Enabling `EnableMIPLabels = true` requires labels that already exist and are published.
- **Verify:** In Purview → **Information protection → Labels**, confirm labels scoped to "Groups & sites"
  exist and a label policy publishes them; `Get-Label` (Security & Compliance PowerShell) lists them.
- **Implement if missing:** With the compliance owner, create and publish container labels **before**
  turning on `EnableMIPLabels`.

## 7. Governance stakeholders & a naming/classification standard on paper

- **Description:** An agreed **naming standard** (prefix/suffix pattern + blocked words), **classification
  scheme** (which label for which data), **minimum-owners** rule, **expiration lifetime**, and **archival
  criteria** — signed off by the collaboration-governance stakeholders (extends GR-6).
- **Why:** The scripts and steps encode these decisions; configuring before the standard is agreed causes
  churn and user-facing disruption.
- **Verify:** A short written standard exists and names an approver.
- **Implement if missing:** Run a design workshop with governance/security/compliance to agree the
  standard before the Configure stage.
