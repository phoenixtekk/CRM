# 2. Requirements Guide — Microsoft Teams Apps & Integration Governance

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant + Teams licensing, least-privilege Teams
roles, the MicrosoftTeams/Graph toolchain, identity/group source of truth, a pilot scope + change
control, and security/compliance stakeholders) are in `global-requirements-teams.md` — this guide adds
only the **app-governance-specific** prerequisites.

## 2.1 Teams Administrator role (app management)
**Description:** An account with the **Teams Administrator** role (Global Administrator only where genuinely required, e.g. granting admin consent to app permissions).
**Why:** App permission/setup policies, org-wide app settings, and the Manage apps page are gated by the Teams Administrator role; reviewing/revoking consented Graph permissions in Entra needs a privileged identity role.
**Verify:** Sign in to the Teams admin center (`https://admin.teams.microsoft.com`) → `Teams apps → Manage apps` and `Permission policies` / `Setup policies` load and are editable. (Builds on `global-requirements-teams.md` §2.)
**Implement:** Have a Global Admin assign **Teams Administrator** under change control; reserve Global Administrator for consent-granting actions only.

## 2.2 MicrosoftTeams PowerShell module (current)
**Description:** The **MicrosoftTeams** PowerShell module installed on the admin workstation, signed in with modern auth / MFA.
**Why:** The permission-policy, setup-policy, and assignment cmdlets (`*-CsTeamsAppPermissionPolicy`, `*-CsTeamsAppSetupPolicy`, `Grant-Cs*`) ship in this module; the provided scripts depend on it.
**Verify:** `Connect-MicrosoftTeams` succeeds and `Get-CsTeamsAppPermissionPolicy` returns the Global policy. (Builds on `global-requirements-teams.md` §3.)
**Implement:** `Install-Module MicrosoftTeams -Scope CurrentUser`; run `Connect-MicrosoftTeams`.

## 2.3 Microsoft Graph read scopes for app + consent inventory
**Description:** Delegated Graph scopes for read: `AppCatalog.Read.All` (Teams app catalog), `TeamworkAppSettings.Read.All` where used, `Directory.Read.All`, `Application.Read.All`, and `DelegatedPermissionGrant.Read.All` / `AppRoleAssignment.Read.All` to read consented permissions.
**Why:** The Discovery and Consent-review scripts read the Teams app catalog, installed apps, and each app's delegated (`oauth2PermissionGrants`) and application (`appRoleAssignments`) permissions from Graph.
**Verify:** Run `TEAMSAPPS-Discovery.ps1` (read-only) — it connects with the read scopes and reports if consent is missing.
**Implement:** Consent at first `Connect-MgGraph`; where admin consent is required an admin approves the scopes once in Entra (`Identity → Applications → Enterprise applications`).

## 2.4 A pilot user group for policy assignment
**Description:** A named group/user set — `App Governance Pilot – Users – Pilot` — to receive the tightened app permission and setup policies before any org-wide change.
**Why:** App policy changes are high-impact (a blocked app disappears from users); the house model validates on a pilot before expanding.
**Verify:** The pilot group exists (Entra security group or an explicit user list) and members are known.
**Implement:** Create the pilot group and populate it with a representative, tolerant user set (per `global-requirements-teams.md` §5).

## 2.5 A vetting criteria and register
**Description:** Agreed **risk criteria** for approving an app (publisher/Publisher Attestation & Microsoft 365 Certification status, requested Graph permissions, data residency, where it stores data) captured in the **App Vetting Register** — `App Vetting Register – Apps – AllStages`.
**Why:** "Vetted" must be objective; the allow/block lists and the workflow key off documented criteria, not case-by-case opinion.
**Verify:** The register exists (a list/spreadsheet or an intake form) with columns for app name, publisher, certification status, requested permissions, decision, and reviewer.
**Implement:** Define the criteria with your security/app-governance stakeholders (`global-requirements-teams.md` §6) and stand up the register/intake form before configuring allow lists.

## 2.6 High-risk Graph permission list (review baseline)
**Description:** A documented list of **high-impact Graph permissions** that trigger deeper review when an app requests/holds them (e.g. `Mail.Read`/`Mail.ReadWrite`, `Files.Read.All`/`Files.ReadWrite.All`, `Chat.Read.All`, `Directory.ReadWrite.All`, `Sites.FullControl.All`, `full_access_as_app`).
**Why:** The consent-review report risk-flags apps against this list; without it, "risky" is undefined.
**Verify:** The list is recorded and referenced by `TEAMSAPPS-ConsentReport.ps1` (it ships with a sensible default set you can extend).
**Implement:** Start from the script's default high-risk set, adjust with your security stakeholders, and record it alongside the vetting criteria.

## 2.7 (Confirm) Cloud environment and app availability
**Description:** Confirmation of your cloud environment — **Commercial vs Government (GCC/GCC High/DoD)** — because available store apps, portal URLs (`admin.teams.microsoft.com` vs `admin.teams.microsoft.us`), and third-party app availability differ.
**Why:** Portal paths and the set of installable third-party apps are environment-dependent; scripting against the wrong endpoint or assuming an app exists will fail.
**Verify:** Confirm the tenant's cloud instance in the M365 admin center; note the correct admin portal URL for your environment.
**Implement:** Record the environment and substitute the correct portal URLs; **verify plan/cloud-dependent app availability in your tenant** before building allow lists.

---
## Checklist
- [ ] Teams Administrator role confirmed (Global Admin reserved for consent grants)
- [ ] MicrosoftTeams PowerShell module installed; `Connect-MicrosoftTeams` works
- [ ] Graph read scopes consented (catalog + directory + permission-grant read)
- [ ] `App Governance Pilot – Users – Pilot` group created and populated
- [ ] Vetting criteria agreed; `App Vetting Register – Apps – AllStages` stood up
- [ ] High-risk Graph permission baseline recorded
- [ ] Cloud environment (Commercial vs Government) confirmed; portal URLs noted
